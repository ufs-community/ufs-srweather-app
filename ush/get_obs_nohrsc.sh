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
# NOHRSC  snow accumulation observations
# ----------
# If data is available on disk, it must be in the following
# directory structure and file name conventions expected by verification
# tasks:
#
# {NOHRSC_OBS_DIR}/{YYYYMMDD}/sfav2_CONUS_{AA}h_{YYYYMMDD}{HH}_grid184.grb2
#
# where AA is the 2-digit accumulation duration in hours: 06 or 24
#
# METplus is configured to verify snowfall using 06- and 24-h accumulated
# snowfall from 6- and 12-hourly NOHRSC files, respectively.
#
# If data is retrieved from HPSS, it will automatically staged by this
# this script.
#-----------------------------------------------------------------------
#

# The time interval (in hours) at which the obs are available on HPSS
# must divide evenly into 24.  Otherwise, different days would have obs
# available at different hours-of-day.  Make sure this is the case.
remainder=$(( 24 % NOHRSC_OBS_AVAIL_INTVL_HRS ))
if [ ${remainder} -ne 0 ]; then
  print_err_msg_exit "\
The obs availability interval NOHRSC_OBS_AVAIL_INTVL_HRS must divide evenly
into 24 but doesn't:
  NOHRSC_OBS_AVAIL_INTVL_HRS = ${NOHRSC_OBS_AVAIL_INTVL_HRS}
  24 % NOHRSC_OBS_AVAIL_INTVL_HRS = ${remainder}"
fi

# Accumulation period to use when getting obs files.  This is simply (a
# properly formatted version of) the obs availability interval.
accum_obs_fmt=$( printf "%d" "${NOHRSC_OBS_AVAIL_INTVL_HRS}" )

# The day (in the form YYYMMDD) associated with the current task via the
# task's cycledefs attribute in the ROCOTO xml.
yyyymmdd_task=${PDY}

# Seconds since some reference time that the DATE_UTIL utility uses of
# the day of the current task.  This will be used below to find hours
# since the start of this day.
sec_since_ref_task=$(${DATE_UTIL} --date "${yyyymmdd_task} 0 hours" +%s)
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
#
#-----------------------------------------------------------------------
#
# Obs files will be obtained by extracting them from the relevant 24-hourly
# archives.  Thus, we need the sequence of archive hours over which to
# loop.  In the simplest case, this sequence will be "0 24".  This will
# be the case if the observation retrieval times include all hours of the
# task's day and if none of the obs files for this day already exist on
# disk.  In other cases, the sequence we loop over will be a subset of
# "0 24", e.g. just "0" or just "24".
#
# To generate this sequence, we first set its starting and ending values
# as well as the interval.
#
#-----------------------------------------------------------------------
#

# Sequence interval must be 24 hours because the archives are 24-hourly.
arcv_hr_incr=24

# Initial guess for starting archive hour.  This is set to the archive
# hour containing obs at the first obs retrieval time of the day.
hh_first=$(echo ${obs_retrieve_times_crnt_day[0]} | cut -c9-10)
hr_first=$((10#${hh_first}))
arcv_hr_start=$(( hr_first/arcv_hr_incr ))
arcv_hr_start=$(( arcv_hr_start*arcv_hr_incr ))

# Ending archive hour.  This is set to the archive hour containing obs at
# the last obs retrieval time of the day.
hh_last=$(echo ${obs_retrieve_times_crnt_day[-1]} | cut -c9-10)
hr_last=$((10#${hh_last}))
if [[ ${hr_last} -eq 0 ]]; then
  arcv_hr_end=24
else
  arcv_hr_end=$(( hr_last/arcv_hr_incr ))
  arcv_hr_end=$(( arcv_hr_end*arcv_hr_incr ))
fi

# Check whether any obs files already exist on disk in their processed
# (i.e. final) locations.  Here, by "processed" we mean after any renaming
# and rearrangement of files that this script may do to the "raw" files,
# i.e. the files as they are named and arranged within the archive (tar)
# files on HPSS.  If so, adjust the starting archive hour.  In the process,
# keep a count of the number of obs files that already exist on disk.
num_existing_files=0
for yyyymmddhh in ${obs_retrieve_times_crnt_day[@]}; do
  yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
  hh=$(echo ${yyyymmddhh} | cut -c9-10)

  # Set the full path to the final processed obs file (fp_proc).
  sec_since_ref=$(${DATE_UTIL} --date "${yyyymmdd} ${hh} hours" +%s)
  lhr=$(( (sec_since_ref - sec_since_ref_task)/3600 ))
  eval_METplus_timestr_tmpl \
    init_time="${yyyymmdd_task}00" \
    fhr="${lhr}" \
    METplus_timestr_tmpl="${OBS_DIR}/${OBS_NOHRSC_ASNOW_FN_TEMPLATE}" \
    outvarname_evaluated_timestr="fp_proc"

  if [[ -f ${fp_proc} ]]; then
    num_existing_files=$((num_existing_files+1))
    print_info_msg "
File already exists on disk:
  fp_proc = \"${fp_proc}\""
  else
    hr=$((10#${hh}))
    arcv_hr_start=$(( hr/arcv_hr_incr ))
    arcv_hr_start=$(( arcv_hr_start*arcv_hr_incr ))
    print_info_msg "
File does not exist on disk:
  fp_proc = \"${fp_proc}\"
Setting the hour (since 00) of the first archive to retrieve to:
  arcv_hr_start = \"${arcv_hr_start}\""
    break
  fi
done

# If the number of obs files that already exist on disk is equal to the
# number of obs files needed, then there is no need to retrieve any files.
num_obs_retrieve_times_crnt_day=${#obs_retrieve_times_crnt_day[@]}
if [[ ${num_existing_files} -eq ${num_obs_retrieve_times_crnt_day} ]]; then

  print_info_msg "
All obs files needed for the current day (yyyymmdd_task) already exist
on disk:
  yyyymmdd_task = \"${yyyymmdd_task}\"
Thus, there is no need to retrieve any files."
  exit

# If the number of obs files that already exist on disk is not equal to
# the number of obs files needed, then we will need to retrieve files.
# In this case, set the sequence of hours corresponding to the archives
# from which files will be retrieved.
else

  arcv_hrs=($(seq ${arcv_hr_start} ${arcv_hr_incr} ${arcv_hr_end}))
  arcv_hrs_str="( "$( printf "%s " "${arcv_hrs[@]}" )")"
  print_info_msg "
At least some obs files needed needed for the current day (yyyymmdd_task)
do not exist on disk:
  yyyymmdd_task = \"${yyyymmdd_task}\"
The number of obs files needed for the current day (which is equal to the
number of observation retrieval times for the current day) is:
  num_obs_retrieve_times_crnt_day = ${num_obs_retrieve_times_crnt_day}
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
# retrieved.  The NOHRSC data on HPSS are archived by day, with the
# archive for a given day containing 6-hour as well as 24-hour grib2
# files.  The four 6-hour files are for accumulated snowfall at 00z
# (which represents accumulation over the last 6 hours of the previous
# day), 06z, 12z, and 18z, while the two 24-hour files are at 00z (which
# represents accumulation over all 24 hours of the previous day) and 12z
# (which represents accumulation over the last 12 hours of the previous
# day plus the first 12 hours of the current day).
#
# Here, we will only obtain the 6-hour files.  In other workflow tasks,
# the values in these 6-hour files will be added as necessary to obtain
# accumulations over longer periods (e.g. 24 hours).  Since the four
# 6-hour files are in one archive and are relatively small (on the order
# of kilobytes), we get them all with a single call to the retrieve_data.py
# script.
#
#-----------------------------------------------------------------------
#

# Whether to move the files or copy them from their raw to their processed
# locations.
#mv_or_cp="mv"
mv_or_cp="cp"
# Whether to remove raw observations after processed directories have
# been created from them.
remove_raw_obs="${REMOVE_RAW_OBS_NOHRSC}"
# If the raw directories and files are to be removed at the end of this
# script, no need to copy the files since the raw directories are going
# to be removed anyway.
if [[ $(boolify "${remove_raw_obs}") == "TRUE" ]]; then
  mv_or_cp="mv"
fi

# Base directory that will contain the archive subdirectories in which
# the files extracted from each archive (tar) file will be placed.  We
# refer to this as the "raw" base directory because it contains files
# as they are found in the archives before any processing by this script.
basedir_raw="${OBS_DIR}/raw_${yyyymmdd_task}"

for arcv_hr in ${arcv_hrs[@]}; do

  print_info_msg "
arcv_hr = ${arcv_hr}"

  # Calculate the time information for the current archive.
  yyyymmddhh_arcv=$(${DATE_UTIL} --date "${yyyymmdd_task} ${arcv_hr} hours" +%Y%m%d%H)
  yyyymmdd_arcv=$(echo ${yyyymmddhh_arcv} | cut -c1-8)
  hh_arcv=$(echo ${yyyymmddhh_arcv} | cut -c9-10)

  # Directory that will contain the files retrieved from the current archive
  # file.  We refer to this as the "raw" archive directory because it will
  # contain the files as they are in the archive before any processing by
  # this script.
  arcv_dir_raw="${basedir_raw}/${yyyymmdd_arcv}"

  # Check whether any of the obs retrieval times for the day associated with
  # this task fall in the time interval spanned by the current archive.  If
  # so, set the flag (do_retrieve) to retrieve the files in the current
  # archive.
  arcv_contents_yyyymmddhh_start=$(${DATE_UTIL} --date "${yyyymmdd_arcv} ${hh_arcv}" +%Y%m%d%H)
  hrs=$((arcv_hr_incr - 1))
  arcv_contents_yyyymmddhh_end=$(${DATE_UTIL} --date "${yyyymmdd_arcv} ${hh_arcv} ${hrs} hours" +%Y%m%d%H)
  do_retrieve="FALSE"
  for (( i=0; i<${num_obs_retrieve_times_crnt_day}; i++ )); do
    obs_retrieve_time=${obs_retrieve_times_crnt_day[i]}
    if [[ "${obs_retrieve_time}" -ge "${arcv_contents_yyyymmddhh_start}" ]] && \
       [[ "${obs_retrieve_time}" -le "${arcv_contents_yyyymmddhh_end}" ]]; then
      do_retrieve="TRUE"
      break
    fi
  done

  if [[ $(boolify "${do_retrieve}") != "TRUE" ]]; then

    print_info_msg "
None of the times in the current day (or hour 00 of the next day) at which
obs need to be retrieved fall in the range spanned by the current ${arcv_hr_incr}-hourly
archive file.  The bounds of the data in the current archive file are:
  arcv_contents_yyyymmddhh_start = \"${arcv_contents_yyyymmddhh_start}\"
  arcv_contents_yyyymmddhh_end = \"${arcv_contents_yyyymmddhh_end}\"
The times at which obs need to be retrieved are:
  obs_retrieve_times_crnt_day = ($(printf "\"%s\" " ${obs_retrieve_times_crnt_day[@]}))"

  else

    # Make sure the raw archive directory exists because it is used below as
    # the output directory of the retrieve_data.py script (so if this directory
    # doesn't already exist, that script will fail).  Creating this directory
    # also ensures that the raw base directory (basedir_raw) exists before we
    # change location to it below.
    mkdir -p ${arcv_dir_raw}

    # The retrieve_data.py script first extracts the contents of the archive
    # file into the directory it was called from and then moves them to the
    # specified output location (via the --output_path option).  Note that
    # the relative paths of obs files within archives associted with different
    # days may be the same.  Thus, if files with the same archive-relative
    # paths are being simultaneously extracted from multiple archive files
    # (by multiple get_obs tasks), they will likely clobber each other if the
    # extracton is being carried out into the same location on disk.  To avoid
    # this, we first change location to the raw base directory (whose name is
    # obs-day dependent) and then call the retrieve_data.py script.
    cd ${basedir_raw}

    # Pull obs from HPSS.  This will get all the obs files in the current
    # archive and place them in the raw archive directory.
    cmd="
    python3 -u ${USHdir}/retrieve_data.py \
      --debug \
      --file_set obs \
      --config ${PARMdir}/data_locations.yml \
      --cycle_date ${yyyymmddhh_arcv} \
      --data_stores hpss \
      --data_type NOHRSC_obs \
      --output_path ${arcv_dir_raw} \
      --summary_file retrieve_data.log"

    print_info_msg "CALLING: ${cmd}"
    $cmd || print_err_msg_exit "Could not retrieve obs from HPSS."

    # Loop over the raw obs files extracted from the current archive and
    # generate from them the processed obs files.  
    #
    # For NOHRSC obs, this consists of simply copying or moving the files from
    # the raw archive directory to the processed directory, possibly renaming
    # them in the process.
    for hrs in $(seq 0 ${NOHRSC_OBS_AVAIL_INTVL_HRS} 23); do
      yyyymmddhh=$(${DATE_UTIL} --date "${yyyymmdd_arcv} ${hh_arcv} ${hrs} hours" +%Y%m%d%H)
      yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
      hh=$(echo ${yyyymmddhh} | cut -c9-10)
      # Create the processed obs file from the raw one (by moving, copying, or
      # otherwise) only if the time of the current file in the current archive
      # also exists in the list of obs retrieval times for the current day.
      if [[ ${obs_retrieve_times_crnt_day[@]} =~ ${yyyymmddhh} ]]; then

        # The raw file name needs to be the same as what the retrieve_data.py
        # script called above ends up retrieving.  The list of possibile templates
        # for this name is given in parm/data_locations.yml, but which of those
        # is actually used is not known until retrieve_data.py completes.  Thus,
        # that information needs to be passed back by the script and used here. 
        # For now, we hard-code the file name here.
        fn_raw="sfav2_CONUS_${accum_obs_fmt}h_${yyyymmddhh}_grid184.grb2"
        fp_raw="${arcv_dir_raw}/${fn_raw}"

        # Set the full path to the final processed obs file (fp_proc) we want to
        # create.
        sec_since_ref=$(${DATE_UTIL} --date "${yyyymmdd} ${hh} hours" +%s)
        lhr=$(( (sec_since_ref - sec_since_ref_task)/3600 ))
        eval_METplus_timestr_tmpl \
          init_time="${yyyymmdd_task}00" \
          fhr="${lhr}" \
          METplus_timestr_tmpl="${OBS_DIR}/${OBS_NOHRSC_ASNOW_FN_TEMPLATE}" \
          outvarname_evaluated_timestr="fp_proc"
        mkdir -p $( dirname "${fp_proc}" )

        ${mv_or_cp} ${fp_raw} ${fp_proc}

      fi
    done

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
