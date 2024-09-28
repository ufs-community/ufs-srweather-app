#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
for sect in user platform verification ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done

set -u
#set -x
#
#-----------------------------------------------------------------------
#
# This script performs several important tasks for preparing data for
# verification tasks. Depending on the value of the environment variable
# OBTYPE=(CCPA|MRMS|NDAS|NOHRSC), the script will prepare that particular data
# set.
#
# If data is not available on disk (in the location specified by
# CCPA_OBS_DIR, MRMS_OBS_DIR, NDAS_OBS_DIR, or NOHRSC_OBS_DIR respectively),
# the script attempts to retrieve the data from HPSS using the retrieve_data.py
# script. Depending on the data set, there are a few strange quirks and/or
# bugs in the way data is organized; see in-line comments for details.
#
#
# NDAS (NAM Data Assimilation System) conventional observations
# ----------
# If data is available on disk, it must be in the following
# directory structure and file name conventions expected by verification
# tasks:
#
# {NDAS_OBS_DIR}/{YYYYMMDD}/prepbufr.ndas.{YYYYMMDDHH}
#
# Note that data retrieved from HPSS and other sources may be in a
# different format: nam.t{hh}z.prepbufr.tm{prevhour}.nr, where hh is
# either 00, 06, 12, or 18, and prevhour is the number of hours prior to
# hh (00 through 05). If using custom staged data, you will have to
# rename the files accordingly.
#
# If data is retrieved from HPSS, it will be automatically staged by this
# this script.
#
#-----------------------------------------------------------------------
#

# The time interval (in hours) at which the obs are available on HPSS
# must divide evenly into 24.  Otherwise, different days would have obs
# available at different hours-of-day.  Make sure this is the case.
remainder=$(( 24 % NDAS_OBS_AVAIL_INTVL_HRS ))
if [ ${remainder} -ne 0 ]; then
  print_err_msg_exit "\
The obs availability interval NDAS_OBS_AVAIL_INTVL_HRS must divide evenly
into 24 but doesn't:
  NDAS_OBS_AVAIL_INTVL_HRS = ${NDAS_OBS_AVAIL_INTVL_HRS}
  mod(24, NDAS_OBS_AVAIL_INTVL_HRS) = ${remainder}"
fi

# The day (in the form YYYMMDD) associated with the current task via the
# task's cycledefs attribute in the ROCOTO xml.
yyyymmdd_task=${PDY}

# Base directory in which the daily subdirectories containing the NDAS
# prepbufr files will appear after this script is done.  We refer to this
# as the "processed" base directory because it contains the files after
# all processing by this script is complete.
basedir_proc=${OBS_DIR}
#
#-----------------------------------------------------------------------
#
# Get the list of all the times in the current day at which to retrieve
# obs.  This is an array with elements having format "YYYYMMDDHH".
#
#-----------------------------------------------------------------------
#
array_name="OBS_RETRIEVE_TIMES_${OBTYPE}_${yyyymmdd_task}"
eval obs_retrieve_times_crnt_day=\( \${${array_name}[@]} \)





# If there are no observation retrieval times on the day of the current
# task, exit the script.
num_obs_retrieve_times_crnt_day=${#obs_retrieve_times_crnt_day[@]}
if [[ ${num_obs_retrieve_times_crnt_day} -eq 0 ]]; then
  print_info_msg "
None of the observation retrieval times fall within the day associated
with the current task (yyyymmdd_task):
  yyyymmdd_task = \"${yyyymmdd_task}\"
Thus, there is no need to retrieve any obs files."
  exit
fi

# Obs files will be obtained by extracting them from the relevant 6-hourly
# archives.  Thus, we need the sequence of archive hours over which to
# loop.  In the simplest case, this sequence will be "6 12 18 24".  This
# will be the case if the observation retrieval times include all hours
# of the task's day and if none of the obs files for this day already
# exist on disk.  In other cases, the sequence we loop over will be a
# subset of "6 12 18 24".
#
# To generate this sequence, we first set its starting and ending values
# as well as the interval.

# Sequence interval must be 6 hours because the archives are 6-hourly.
arcv_hr_incr=6

# Initial guess for starting archive hour.  This is set to the archive 
# hour containing obs at the first observation retrieval time of the day.
hh_first=$(echo ${obs_retrieve_times_crnt_day[0]} | cut -c9-10)
hr_first=$((10#${hh_first}))
arcv_hr_start=$(( (hr_first/arcv_hr_incr + 1)*arcv_hr_incr ))

# Ending archive hour.  This is set to the archive hour containing obs at
# the last observation retrieval time of the day.
hh_last=$(echo ${obs_retrieve_times_crnt_day[-1]} | cut -c9-10)
hr_last=$((10#${hh_last}))
arcv_hr_end=$(( (hr_last/arcv_hr_incr + 1)*arcv_hr_incr ))

# Check whether any obs files already exist on disk.  If so, adjust the
# starting archive hour.  In the process, keep a count of the number of
# obs files that already exist on disk.
num_existing_files=0
for yyyymmddhh in ${obs_retrieve_times_crnt_day[@]}; do
  yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
  hh=$(echo ${yyyymmddhh} | cut -c9-10)
  day_dir_proc="${basedir_proc}"
  fn_proc="prepbufr.ndas.${yyyymmddhh}"
  fp_proc="${day_dir_proc}/${fn_proc}"
  if [[ -f ${fp_proc} ]]; then
    num_existing_files=$((num_existing_files+1))
    print_info_msg "
File already exists on disk:
  fp_proc = \"${fp_proc}\""
  else
    hr=$((10#${hh}))
    arcv_hr_start=$(( (hr/arcv_hr_incr + 1)*arcv_hr_incr ))
    print_info_msg "
File does not exist on disk:
  fp_proc = \"${fp_proc}\"
Setting the hour (since 00) of the first archive to retrieve to:
  arcv_hr_start = \"${arcv_hr_start}\""
    break
  fi
done

# If the number of obs files that already exist on disk is equal to the
# number of files needed, then there is no need to retrieve any files.
num_needed_files=$((num_obs_retrieve_times_crnt_day))
if [[ ${num_existing_files} -eq ${num_needed_files} ]]; then
  print_info_msg "
All obs files needed for the current day (yyyymmdd_task) already exist
on disk:
  yyyymmdd_task = \"${yyyymmdd_task}\"
Thus, there is no need to retrieve any files."
  exit
# Otherwise, will need to retrieve files.  In this case, set the sequence
# of hours corresponding to the archives from which files will be retrieved.
else
  arcv_hrs=($(seq ${arcv_hr_start} ${arcv_hr_incr} ${arcv_hr_end}))
  arcv_hrs_str="( "$( printf "%s " "${arcv_hrs[@]}" )")"
  print_info_msg "
At least some obs files needed needed for the current day (yyyymmdd_task)
do not exist on disk:
  yyyymmdd_task = \"${yyyymmdd_task}\"
The number of obs files needed is:
  num_needed_files = ${num_needed_files}
The number of obs files that already exist on disk is:
  num_existing_files = ${num_existing_files}
Will retrieve remaining files by looping over archives corresponding to
the following hours (since 00 of this day):
  arcv_hrs = ${arcv_hrs_str}
"
fi
#
#-----------------------------------------------------------------------
#
# At this point, at least some obs files for the current day need to be
# retrieved.  Thus, loop over the relevant archives that contain obs for
# the day given by yyyymmdd_task and retrieve files as needed.
#
#-----------------------------------------------------------------------
#

# Whether to move or copy files from raw to processed directories.
#mv_or_cp="mv"
mv_or_cp="cp"
# Whether to remove raw observations after processed directories have
# been created from them.
remove_raw_obs="${REMOVE_RAW_OBS_NDAS}"
# If the raw directories and files are to be removed at the end of this
# script, no need to copy the files since the raw directories are going
# to be removed anyway.
if [[ $(boolify "${remove_raw_obs}") == "TRUE" ]]; then
  mv_or_cp="mv"
fi

# Base directory that will contain the daily subdirectories in which the
# NDAS prepbufr files retrieved from archive (tar) files will be placed.
# We refer to this as the "raw" base directory because it contains files
# as they are found in the archives before any processing by this script.
basedir_raw="${basedir_proc}/raw_${yyyymmdd_task}"

for arcv_hr in ${arcv_hrs[@]}; do

  print_info_msg "
arcv_hr = ${arcv_hr}"

  # Calculate the time information for the current archive.
  yyyymmddhh_arcv=$(${DATE_UTIL} --date "${yyyymmdd_task} ${arcv_hr} hours" +%Y%m%d%H)
  yyyymmdd_arcv=$(echo ${yyyymmddhh_arcv} | cut -c1-8)
  hh_arcv=$(echo ${yyyymmddhh_arcv} | cut -c9-10)

  # Directory that will contain the NDAS prepbufr files retrieved from the
  # current 6-hourly archive file.  We refer to this as the "raw" quarter-
  # daily directory because it will contain the files as they are in the
  # archive before any processing by this script.
  qrtrday_dir_raw="${basedir_raw}/${yyyymmddhh_arcv}"

  # Check whether any of the observation retrieval times for the day
  # associated with this task fall in the time interval spanned by the
  # current archive.  If so, set the flag (do_retrieve) to retrieve the
  # files in the current
  # archive.
  yyyymmddhh_qrtrday_start=$(${DATE_UTIL} --date "${yyyymmdd_arcv} ${hh_arcv} 6 hours ago" +%Y%m%d%H)
  yyyymmddhh_qrtrday_end=$(${DATE_UTIL} --date "${yyyymmdd_arcv} ${hh_arcv} 1 hours ago" +%Y%m%d%H)
  do_retrieve="FALSE"
  for (( i=0; i<${num_obs_retrieve_times_crnt_day}; i++ )); do
    retrieve_time=${obs_retrieve_times_crnt_day[i]}
    if [[ "${retrieve_time}" -ge "${yyyymmddhh_qrtrday_start}" ]] && \
       [[ "${retrieve_time}" -le "${yyyymmddhh_qrtrday_end}" ]]; then
      do_retrieve="TRUE"
      break
    fi
  done

  if [[ $(boolify "${do_retrieve}") == "TRUE" ]]; then

    # Make sure the raw quarter-daily directory exists because it is used
    # below as the output directory of the retrieve_data.py script (so if
    # this directory doesn't already exist, that script will fail).  Creating
    # this directory also ensures that the raw base directory (basedir_raw)
    # exists before we change location to it below.
    mkdir -p ${qrtrday_dir_raw}

    # The retrieve_data.py script first extracts the contents of the archive
    # file into the directory it was called from and then moves them to the
    # specified output location (via the --output_path option).  In order to
    # avoid other get_obs_ndas tasks (i.e. those associated with other days)
    # from interfering with (clobbering) these files (because extracted files
    # from different get_obs_ndas tasks to have the same names or relative
    # paths), we change location to the base raw directory so that files with
    # same names are extracted into different directories.
    cd ${basedir_raw}

    # Pull NDAS data from HPSS.  This will get all 7 obs files in the current
    # archive and place them in the raw quarter-daily directory, although we
    # will make use of only 6 of these (we will not use the tm00 file).
    cmd="
    python3 -u ${USHdir}/retrieve_data.py \
      --debug \
      --file_set obs \
      --config ${PARMdir}/data_locations.yml \
      --cycle_date ${yyyymmddhh_arcv} \
      --data_stores hpss \
      --data_type NDAS_obs \
      --output_path ${qrtrday_dir_raw} \
      --summary_file retrieve_data.log"

    print_info_msg "CALLING: ${cmd}"
    $cmd || print_err_msg_exit "Could not retrieve obs from HPSS."

    # Create the processed NDAS prepbufr files.  This consists of simply
    # copying or moving (and in the process renaming) them from the raw
    # quarter-daily directory to the processed directory.  Note that the
    # tm06 files contain more/better observations than tm00 for the
    # equivalent time, so we use those.
    for hrs_ago in $(seq --format="%02g" 6 -1 1); do
      yyyymmddhh=$(${DATE_UTIL} --date "${yyyymmdd_arcv} ${hh_arcv} ${hrs_ago} hours ago" +%Y%m%d%H)
      yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
      hh=$(echo ${yyyymmddhh} | cut -c9-10)
      if [[ ${obs_retrieve_times_crnt_day[@]} =~ ${yyyymmddhh} ]]; then
        fn_raw="nam.t${hh_arcv}z.prepbufr.tm${hrs_ago}.nr"
        fp_raw="${qrtrday_dir_raw}/${fn_raw}"
        day_dir_proc="${basedir_proc}"
        mkdir -p ${day_dir_proc}
        fn_proc="prepbufr.ndas.${yyyymmddhh}"
        fp_proc="${day_dir_proc}/${fn_proc}"
        ${mv_or_cp} ${fp_raw} ${fp_proc}
      fi
    done

  else

    print_info_msg "
None of the current day's observation retrieval times fall in the range
spanned by the current 6-hourly archive file.  The bounds of the current
archive are:
  yyyymmddhh_qrtrday_start = \"${yyyymmddhh_qrtrday_start}\"
  yyyymmddhh_qrtrday_end = \"${yyyymmddhh_qrtrday_end}\"
The observation retrieval times are:
  obs_retrieve_times_crnt_day = ($(printf "\"%s\" " ${obs_retrieve_times_crnt_day[@]}))"

  fi

done
#
#-----------------------------------------------------------------------
#
# Clean up raw obs directories.
#
#-----------------------------------------------------------------------
#
if [[ $(boolify "${remove_raw_obs}") == "TRUE" ]]; then
  print_info_msg "Removing raw obs directories..."
  rm -rf ${basedir_raw} || print_err_msg_exit "\
Failed to remove raw obs directories."
fi