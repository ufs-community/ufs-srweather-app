#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task " " ${GLOBAL_VAR_DEFNS_FP}

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

# Create an array-valued counterpart of MRMS_FIELDS.  MRMS_FIELDS is an
# environment variable created in the ROCOTO XML.  It is a scalar variable
# because there doesn't seem to be a way to pass a bash array from the 
# XML to the task's script.
mrms_fields=($(printf "%s" "${MRMS_FIELDS}"))

# Loop over the fields (REFC and RETOP) and set the file base name 
# corresponding to each.
fields_in_filenames=()
levels_in_filenames=()
for field in ${mrms_fields[@]}; do
  # Set field-dependent parameters needed in forming grib2 file names.
  if [ "${field}" = "REFC" ]; then
    fields_in_filenames+=("MergedReflectivityQCComposite")
    levels_in_filenames+=("00.50")
  elif [ "${field}" = "RETOP" ]; then
    fields_in_filenames+=("EchoTop")
    levels_in_filenames+=("18_00.50")
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

# Base directory in which the daily subdirectories containing the MRMS
# grib2 files will appear after this script is done.  We refer to this
# as the "processed" base directory because it contains the files after
# all processing by this script is complete.
basedir_proc=${OBS_DIR}

# The environment variable OUTPUT_TIMES_ALL set in the ROCOTO XML is a
# scalar string containing all relevant forecast output times (each) in
# the form YYYYMMDDHH) separated by spaces.  It isn't an array of strings
# because in ROCOTO, there doesn't seem to be a way to pass a bash array
# from the XML to task's script.  To have an array-valued variable to
# work with, here, we create the new variable output_times_all that is
# the array-valued counterpart of OUTPUT_TIMES_ALL.
output_times_all=($(printf "%s" "${OUTPUT_TIMES_ALL}"))

# List of times (each of the form YYYYMMDDHH) for which there is forecast
# output for the current day.  We extract this list from the full list of
# all forecast output times (i.e. from all cycles).
output_times_crnt_day=()
if [[ ${output_times_all[@]} =~ ${yyyymmdd_task} ]]; then
  output_times_crnt_day=( $(printf "%s\n" "${output_times_all[@]}" | grep "^${yyyymmdd_task}") )
fi

# If there are no forecast output times on the day of the current task,
# exit the script.
num_output_times_crnt_day=${#output_times_crnt_day[@]}
if [[ ${num_output_times_crnt_day} -eq 0 ]]; then
  print_info_msg "
None of the forecast output times fall within the day associated with the
current task (yyyymmdd_task):
  yyyymmdd_task = \"${yyyymmdd_task}\"
Thus, there is no need to retrieve any obs files."
  exit
fi

# Check whether any obs files already exist on disk.  If so, adjust the
# starting archive hour.  In the process, keep a count of the number of
# files that already exist on disk.
num_existing_files=0
num_mrms_fields=${#mrms_fields[@]}
for (( i=0; i<${num_mrms_fields}; i++ )); do
  for yyyymmddhh in ${output_times_crnt_day[@]}; do
    yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
    hh=$(echo ${yyyymmddhh} | cut -c9-10)
    day_dir_proc="${basedir_proc}/${yyyymmdd}"
    fn_proc="${fields_in_filenames[$i]}_${levels_in_filenames[$i]}_${yyyymmdd}-${hh}0000.grib2"
    fp_proc="${day_dir_proc}/${fn_proc}"
    if [[ -f ${fp_proc} ]]; then
      num_existing_files=$((num_existing_files+1))
      print_info_msg "
File already exists on disk:
  fp_proc = \"${fp_proc}\""
    else
      break
    fi
  done
done

# If the number of obs files that already exist on disk is equal to the
# number of files needed, then there is no need to retrieve any files.
num_needed_files=$((num_output_times_crnt_day*num_mrms_fields))
if [[ ${num_existing_files} -eq $((num_needed_files)) ]]; then
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
The number of obs files needed is:
  num_needed_files = ${num_needed_files}
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

# Whether to move or copy files from raw to processed directories.
#mv_or_cp="mv"
mv_or_cp="cp"
# If the raw directories and files are to be removed at the end of this
# script, no need to copy the files since the raw directories are going
# to be removed anyway.
if [[ "${REMOVE_RAW_OBS}" == "TRUE" ]]; then
  mv_or_cp="mv"
fi

# Base directory that will contain the daily subdirectories in which the
# MRMS grib2 files retrieved from archive (tar) files will be placed.
# We refer to this as the "raw" base directory because it contains files
# as they are found in the archives before any processing by this script.
basedir_raw="${basedir_proc}/${yyyymmdd_task}/raw"

# Time associated with the archive.  MRMS data have daily archives that
# have the hour-of-day set to "00".
yyyymmddhh_arcv="${yyyymmdd_task}00"

# Directory that will contain the MRMS grib2 files retrieved from the
# current 6-hourly archive file.  We refer to this as the "raw" quarter-
# daily directory because it will contain the files as they are in the
# archive before any processing by this script.
day_dir_raw="${basedir_raw}/${yyyymmdd_task}"

# Make sure the raw quarter-daily directory exists because it is used
# below as the output directory of the retrieve_data.py script (so if
# this directory doesn't already exist, that script will fail).  Creating
# this directory also ensures that the raw base directory (basedir_raw)
# exists before we change location to it below.
mkdir -p ${day_dir_raw}

# The retrieve_data.py script first extracts the contents of the archive
# file into the directory it was called from and then moves them to the
# specified output location (via the --output_path option).  In order to
# avoid other get_obs_ndas tasks (i.e. those associated with other days)
# from interfering with (clobbering) these files (because extracted files
# from different get_obs_ndas tasks to have the same names or relative
# paths), we change location to the base raw directory so that files with
# same names are extracted into different directories.
cd ${basedir_raw}

# Pull MRMS data from HPSS.  This will get all 7 obs files in the current
# archive and place them in the raw quarter-daily directory, although we
# will make use of only 6 of these (we will not use the tm00 file).
cmd="
python3 -u ${USHdir}/retrieve_data.py \
  --debug \
  --file_set obs \
  --config ${PARMdir}/data_locations.yml \
  --cycle_date ${yyyymmddhh_arcv} \
  --data_stores hpss \
  --data_type MRMS_obs \
  --output_path ${day_dir_raw} \
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

# Loop through all hours of the day associated with the task.  For each
# hour, find the gzipped grib2 file in the raw daily directory that is
# closest in time to this hour.  Then gunzip the file and copy it (in the
# process renaming it) to the processed location.
for hr in $(seq 0 1 23); do
  yyyymmddhh=$(${DATE_UTIL} --date "${yyyymmdd_task} ${hr} hours" +%Y%m%d%H)
  if [[ ${output_times_crnt_day[@]} =~ ${yyyymmddhh} ]]; then
    for (( i=0; i<${num_mrms_fields}; i++ )); do
      python ${USHdir}/mrms_pull_topofhour.py \
        --valid_time ${yyyymmddhh} \
        --outdir ${basedir_proc} \
        --source ${basedir_raw} \
        --product ${fields_in_filenames[$i]}
    done
  fi
done
#
#-----------------------------------------------------------------------
#
# Clean up raw directories.
#
#-----------------------------------------------------------------------
#
if [[ "${REMOVE_RAW_OBS}" == "TRUE" ]]; then
  print_info_msg "Removing raw directories and files..."
  rm -rf ${mrms_basedir_raw} || print_err_msg_exit "\
Failed to remove raw directories and files."
fi
