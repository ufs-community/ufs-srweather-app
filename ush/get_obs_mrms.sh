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
# MRMS (Multi-Radar Multi-Sensor) radar observations
# ----------
# If data is available on disk, it must be in the following
# directory structure and file name conventions expected by verification
# tasks:
#
# {MRMS_OBS_DIR}/{YYYYMMDD}/[PREFIX]{YYYYMMDD}-{HH}0000.grib2,
#
# Where [PREFIX] is MergedReflectivityQCComposite_00.50_ for reflectivity
# data and EchoTop_18_00.50_ for echo top data. If data is not available
# at the top of the hour, you should rename the file closest in time to
# your hour(s) of interest to the above naming format. A script
# "ush/mrms_pull_topofhour.py" is provided for this purpose.
#
# If data is retrieved from HPSS, it will automatically staged by this
# this script.
#
#-----------------------------------------------------------------------
#

# The time interval (in hours) at which the obs are available on HPSS
# must divide evenly into 24.  Otherwise, different days would have obs
# available at different hours-of-day.  Make sure this is the case.
remainder=$(( 24 % MRMS_OBS_AVAIL_INTVL_HRS ))
if [ ${remainder} -ne 0 ]; then
  print_err_msg_exit "\
The obs availability interval MRMS_OBS_AVAIL_INTVL_HRS must divide evenly
into 24 but doesn't:
  MRMS_OBS_AVAIL_INTVL_HRS = ${MRMS_OBS_AVAIL_INTVL_HRS}
  24 % MRMS_OBS_AVAIL_INTVL_HRS = ${remainder}"
fi

# Create an array-valued counterpart of MRMS_FIELDS.  MRMS_FIELDS is an
# environment variable created in the ROCOTO XML.  It is a scalar variable
# because there doesn't seem to be a way to pass a bash array from the 
# XML to the task's script.
mrms_fields=($(printf "%s" "${MRMS_FIELDS}"))

# Loop over the fields (REFC and RETOP) and set the file base name 
# corresponding to each.
fields_in_filenames=()
levels_in_filenames=()
obs_mrms_fp_templates=()
for field in ${mrms_fields[@]}; do
  # Set field-dependent parameters needed in forming grib2 file names.
  if [ "${field}" = "REFC" ]; then
    fields_in_filenames+=("MergedReflectivityQCComposite")
    levels_in_filenames+=("00.50")
    obs_mrms_fp_templates+=("${OBS_DIR}/${OBS_MRMS_REFC_FN_TEMPLATE}")
  elif [ "${field}" = "RETOP" ]; then
    fields_in_filenames+=("EchoTop")
    levels_in_filenames+=("18_00.50")
    obs_mrms_fp_templates+=("${OBS_DIR}/${OBS_MRMS_RETOP_FN_TEMPLATE}")
  else
    print_err_msg_exit "\
Invalid field specified:
  field = \"${field}\"
Valid options are 'REFC', 'RETOP'."
  fi
done

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

# Check whether any obs files already exist on disk.  If so, adjust the
# starting archive hour.  In the process, keep a count of the number of
# obs files that already exist on disk.
num_existing_files=0
num_mrms_fields=${#mrms_fields[@]}
for yyyymmddhh in ${obs_retrieve_times_crnt_day[@]}; do
  for (( i=0; i<${num_mrms_fields}; i++ )); do

    yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
    hh=$(echo ${yyyymmddhh} | cut -c9-10)

    sec_since_ref=$(${DATE_UTIL} --date "${yyyymmdd} ${hh} hours" +%s)
    lhr=$(( (sec_since_ref - sec_since_ref_task)/3600 ))
    eval_METplus_timestr_tmpl \
      init_time="${yyyymmdd_task}00" \
      fhr="${lhr}" \
      METplus_timestr_tmpl="${obs_mrms_fp_templates[$i]}" \
      outvarname_evaluated_timestr="fp_proc"

    if [[ -f ${fp_proc} ]]; then
      num_existing_files=$((num_existing_files+1))
      print_info_msg "
File already exists on disk:
  fp_proc = \"${fp_proc}\""
    else
      print_info_msg "
File does not exist on disk:
  fp_proc = \"${fp_proc}\"
Will attempt to retrieve all obs files."
      break 2
    fi

  done
done

# If the number of obs files that already exist on disk is equal to the
# number of obs files needed (which is num_mrms_fields times the number
# of obs retrieval times in the current day), then there is no need to
# retrieve any files.
num_obs_retrieve_times_crnt_day=${#obs_retrieve_times_crnt_day[@]}
if [[ ${num_existing_files} -eq $((num_mrms_fields*num_obs_retrieve_times_crnt_day)) ]]; then

  print_info_msg "
All obs files needed for the current day (yyyymmdd_task) already exist
on disk:
  yyyymmdd_task = \"${yyyymmdd_task}\"
Thus, there is no need to retrieve any files."
  exit
# Otherwise, will need to retrieve files.
else
  print_info_msg "
At least some obs files needed needed for the current day (yyyymmdd_task)
do not exist on disk:
  yyyymmdd_task = \"${yyyymmdd_task}\"
The number of obs files needed for the current day (which is equal to the
number of observation retrieval times for the current day) is:
  num_obs_retrieve_times_crnt_day = ${num_obs_retrieve_times_crnt_day}
The number of obs files that already exist on disk is:
  num_existing_files = ${num_existing_files}
Will retrieve remaining files.
"
fi
#
#-----------------------------------------------------------------------
#
# At this point, at least some obs files for the current day need to be
# retrieved.
#
#-----------------------------------------------------------------------
#

# Whether to move the files or copy them from their raw to their processed
# locations.
#mv_or_cp="mv"
mv_or_cp="cp"
# Whether to remove raw observations after processed directories have
# been created from them.
remove_raw_obs="${REMOVE_RAW_OBS_MRMS}"
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

# Time associated with the archive.  MRMS data have daily archives that
# have the hour-of-day set to "00".
yyyymmddhh_arcv="${yyyymmdd_task}00"

# Directory that will contain the files retrieved from the current archive
# file.  We refer to this as the "raw" archive directory because it will
# contain the files as they are in the archive before any processing by
# this script.
#
# Note:
# Normally, arcv_dir_raw should consist of basedir_raw and a subdirectory
# that depends on the archive date, e.g.
#
#   arcv_dir_raw="${basedir_raw}/${yyyymmddhh_arcv}"
#
# but since for MRMS data there is only one archive per day, that directory
# is redundant, so simplicity we set arcv_dir_raw to just basedir_raw.
arcv_dir_raw="${basedir_raw}"

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
  --data_type MRMS_obs \
  --output_path ${arcv_dir_raw} \
  --summary_file retrieve_data.log"

print_info_msg "CALLING: ${cmd}"
$cmd || print_err_msg_exit "Could not retrieve obs from HPSS."
#
#-----------------------------------------------------------------------
#
# Loop over the 24 hour period starting with the zeroth hour of the day
# associated with this task and ending with the 23rd hour.
#
#-----------------------------------------------------------------------
#

# Loop over the raw obs files extracted from the current archive and
# generate from them the processed obs files.  
#
# For MRMS obs, the raw obs consist of gzipped grib2 files that are
# usually a few minutes apart in time.  However, because forecast data
# is available at most every hour, the SRW App configuration parameter
# MRMS_OBS_AVAIL_INTVL_HRS is set to 1 hour instead of a few minutes.
# Below, we loop over the whole day using this 1-hourly interval.  For
# each hour of the day, we call the script mrms_pull_topofhour.py to find
# the gzipped grib2 file in the raw archive directory that is closest in
# time to the hour and unzip it in a temporary directory.  We then copy
# or move it to the processed directory, possibly renaming it in the
# process.
for hr in $(seq 0 ${MRMS_OBS_AVAIL_INTVL_HRS} 23); do
  yyyymmddhh=$(${DATE_UTIL} --date "${yyyymmdd_task} ${hr} hours" +%Y%m%d%H)
  yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
  hh=$(echo ${yyyymmddhh} | cut -c9-10)
  # Create the processed obs file from the raw one (by moving, copying, or
  # otherwise) only if the time of the current file in the current archive
  # also exists in the list of obs retrieval times for the current day.
  if [[ ${obs_retrieve_times_crnt_day[@]} =~ ${yyyymmddhh} ]]; then
    for (( i=0; i<${num_mrms_fields}; i++ )); do

      # First, select from the set of raw files for the current day those that
      # are nearest in time to the current hour.  Unzip these in a temporary
      # subdirectory under the raw base directory.
      #
      # Note that the script we call to do this (mrms_pull_topofhour.py) assumes
      # a certain file naming convention.  That convention must match the names
      # of the files that the retrieve_data.py script called above ends up
      # retrieving.  The list of possibile templates for these names is given
      # in parm/data_locations.yml, but which of those is actually used is not
      # known until retrieve_data.py completes.  Thus, that information needs
      # to be passed back by retrieve_data.py and then passed to mrms_pull_topofhour.py.
      # For now, we hard-code the file name here.
      python ${USHdir}/mrms_pull_topofhour.py \
        --valid_time ${yyyymmddhh} \
        --source ${basedir_raw} \
        --outdir ${basedir_raw}/topofhour \
        --product ${fields_in_filenames[$i]} \
        --no-add_vdate_subdir

      # Set the name of and the full path to the raw obs file created by the
      # mrms_pull_topofhour.py script.  This name is currently hard-coded to
      # the output of that script.   In the future, it should be set in a more
      # general way (e.g. obtain from a settings file).
      fn_raw="${fields_in_filenames[$i]}_${levels_in_filenames[$i]}_${yyyymmdd_task}-${hh}0000.grib2"
      fp_raw="${basedir_raw}/topofhour/${fn_raw}"

      # Set the full path to the final processed obs file (fp_proc) we want to
      # create.
      sec_since_ref=$(${DATE_UTIL} --date "${yyyymmdd} ${hh} hours" +%s)
      lhr=$(( (sec_since_ref - sec_since_ref_task)/3600 ))
      eval_METplus_timestr_tmpl \
        init_time="${yyyymmdd_task}00" \
        fhr="${lhr}" \
        METplus_timestr_tmpl="${obs_mrms_fp_templates[$i]}" \
        outvarname_evaluated_timestr="fp_proc"
      mkdir -p $( dirname "${fp_proc}" )

      mv ${fp_raw} ${fp_proc}

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
