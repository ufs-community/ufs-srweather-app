#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
for sect in user platform ; do
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
# CCPA (Climatology-Calibrated Precipitation Analysis) precipitation accumulation obs
# ----------
# If data is available on disk, it must be in the following
# directory structure and file name conventions expected by verification
# tasks:
#
# {CCPA_OBS_DIR}/{YYYYMMDD}/ccpa.t{HH}z.01h.hrap.conus.gb2
#
# If data is retrieved from HPSS, it will be automatically staged by this
# script.
#
# Notes about the data and how it's used for verification:
#
# 1. Accumulation is currently hardcoded to 01h. The verification will
# use MET/pcp-combine to sum 01h files into desired accumulations.
#
# 2. There is a problem with the valid time in the metadata for files
# valid from 19 - 00 UTC (or files under the '00' directory). This is
# accounted for in this script for data retrieved from HPSS, but if you
# have manually staged data on disk you should be sure this is accounted
# for. See in-line comments below for details.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Below, we will use the retrieve_data.py script to retrieve the CCPA
# grib2 file from a data store (e.g. HPSS).  Before doing so, note the
# following:
#
# * The daily archive (tar) file containing CCPA obs has a name of the
#   form
#
#     [PREFIX].YYYYMMDD.tar
#
#   where YYYYMMDD is a given year, month, and day combination, and
#   [PREFIX] is a string that is not relevant to the discussion here
#   (the value it can take on depends on which of several time periods
#   YYYYMMDD falls in, and the retrieve_data.py tries various values
#   until it finds one for which a tar file exists).  Unintuitively, this
#   archive file contains accumulation data for valid times starting at
#   hour 19 of the PREVIOUS day (YYYYMM[DD-1]) to hour 18 of the current
#   day (YYYYMMDD).  In other words, the valid times of the contents of
#   this archive file are shifted back by 6 hours relative to the time
#   string appearing in the name of the file.  See section "DETAILS..."
#   for a detailed description of the directory structure in the CCPA
#   archive files.
#
# * We call retrieve_data.py in a temporary cycle-specific subdirectory
#   in order to prevent get_obs_ccpa tasks for different cycles from
#   clobbering each other's output.  We refer to this as the "raw" CCPA
#   base directory because it contains files as they are found in the
#   archives before any processing by this script.
#
# * In each (cycle-specific) raw base directory, the data is arranged in
#   daily subdirectories with the same timing as in the archive (tar)
#   files (which are described in the section "DETAILS..." below).  In
#   particular, each daily subdirectory has the form YYYYMDD, and it may
#   contain CCPA grib2 files for accumulations valid at hour 19 of the
#   previous day (YYYYMM[DD-1]) to hour 18 of the current day (YYYYMMDD).
#   (Data valid at hours 19-23 of the current day (YYYYMMDD) go into the
#   daily subdirectory for the next day, i.e. YYYYMM[DD+1].)  We refer
#   to these as raw daily (sub)directories to distinguish them from the
#   processed daily subdirectories under the processed (final) CCPA base
#   directory (basedir_proc).
#
# * For a given cycle, some of the valid times at which there is forecast
#   output may not have a corresponding file under the raw base directory
#   for that cycle.  This is because another cycle that overlaps this cycle
#   has already obtained the grib2 CCPA file for that valid time and placed
#   it in its processed location; as a result, the retrieveal of that grib2
#   file for this cycle is skipped.
#
# * To obtain a more intuitive temporal arrangement of the data in the
#   processed CCPA directory structure than the temporal arrangement used
#   in the archives and raw directories, we process the raw files such
#   that the data in the processed directory structure is shifted forward
#   in time 6 hours relative to the data in the archives and raw directories.
#   This results in a processed base directory that, like the raw base
#   directory, also contains daily subdirectories of the form YYYYMMDD,
#   but each such subdirectory may only contain CCPA data at valid hours
#   within that day, i.e. at valid times YYYYMMDD[00, 01, ..., 23] (but
#   may not contain data that is valid on the previous, next, or any other
#   day).
#
# * For data between 20180718 and 20210504, the 01h accumulation data
#   (which is the only accumulation we are retrieving) have incorrect
#   metadata under the "00" directory in the archive files (meaning for
#   hour 00 and hours 19-23, which are the ones in the "00" directory).
#   Below, we use wgrib2 to make a correction for this when transferring
#   (moving or copying) grib2 files from the raw daily directories to
#   the processed daily directories.
#
#
# DETAILS OF DIRECTORY STRUCTURE IN CCPA ARCHIVE (TAR) FILES
# ----------------------------------------------------------
#
# The daily archive file containing CCPA obs is named
#
#   [PREFIX].YYYYMMDD.tar
#
# This file contains accumulation data for valid times starting at hour
# 19 of the PREVIOUS day (YYYYMM[DD-1]) to hour 18 of the current day
# (YYYYMMDD).  In particular, when untarred, the daily archive file
# expands into four subdirectories:  00, 06, 12, and 18.  The 06, 12, and
# 18 subdirectories contain grib2 files for accumulations valid at or
# below the hour-of-day given by the subdirectory name (and on YYYYMMDD).
# For example, the 06 directory contains data valid at:
#
#   * YYYYMMDD[01, 02, 03, 04, 05, 06] for 01h accumulations;
#   * YYYYMMDD[03, 06] for 03h accumulations;
#   * YYYYMMDD[06] for 06h accumulations.
#
# The valid times for the data in the 12 and 18 subdirectories are
# analogous.  However, the 00 subdirectory is different in that it
# contains accumulations at hour 00 on YYYYMMDD as well as ones BEFORE
# this time, i.e. the data for valid times other than YYYYMMDD00 are on
# the PREVIOUS day.  Thus, the 00 subdirectory contains data valid at
# (note the DD-1, meaning one day prior):
#
#   * YYYYMM[DD-1][19, 20, 21, 22, 23] and YYYYMMDD00 for 01h accumulations;
#   * YYYYMM[DD-1][19] and YYYYMMDD00 for 03h accumulations;
#   * YYYYMMDD00 for 06h accumulations.
#
#-----------------------------------------------------------------------
#

# CCPA accumulation period to consider.  Here, we only retrieve data for
# 1-hour accumulations.  Other accumulations (03h, 06h, 24h) are obtained
# by other tasks in the workflow that add up these hourly values.
accum="01"

# The day (in the form YYYMMDD) associated with the current task via the
# task's cycledefs attribute in the ROCOTO xml.
yyyymmdd_task=${PDY}

# Base directory in which the daily subdirectories containing the CCPA
# grib2 files will appear after this script is done.  We refer to this as
# the "processed" base directory because it contains the files after all
# processing by this script is complete.
basedir_proc=${OBS_DIR}

# The environment variable FCST_OUTPUT_TIMES_ALL set in the ROCOTO XML is
# a scalar string containing all relevant forecast output times (each in
# the form YYYYMMDDHH) separated by spaces.  It isn't an array of strings
# because in ROCOTO, there doesn't seem to be a way to pass a bash array
# from the XML to the task's script.  To have an array-valued variable to
# work with, here, we create the new variable fcst_output_times_all that
# is the array-valued counterpart of FCST_OUTPUT_TIMES_ALL.
fcst_output_times_all=($(printf "%s" "${FCST_OUTPUT_TIMES_ALL}"))

# List of times (each of the form YYYYMMDDHH) for which there is forecast
# APCP (accumulated precipitation) output for the current day.  We start
# constructing this by extracting from the full list of all forecast APCP
# output times (i.e. from all cycles) all elements that contain the current
# task's day (in the form YYYYMMDD).
fcst_output_times_crnt_day=()
if [[ ${fcst_output_times_all[@]} =~ ${yyyymmdd_task} ]]; then
  fcst_output_times_crnt_day=( $(printf "%s\n" "${fcst_output_times_all[@]}" | grep "^${yyyymmdd_task}") )
fi
# If the 0th hour of the current day is in this list (and if it is, it
# will be the first element), remove it because for APCP, that time is
# considered part of the previous day (because it represents precipitation
# that occurred during the last hour of the previous day).
if [[ ${#fcst_output_times_crnt_day[@]} -gt 0 ]] && \
   [[ ${fcst_output_times_crnt_day[0]} == "${yyyymmdd_task}00" ]]; then
  fcst_output_times_crnt_day=(${fcst_output_times_crnt_day[@]:1})
fi
# If the 0th hour of the next day (i.e. the day after yyyymmdd_task) is
# one of the output times in the list of all APCP output times, we include
# it in the list for the current day because for APCP, that time is
# considered part of the current day (because it represents precipitation 
# that occured during the last hour of the current day).
yyyymmdd00_task_p1d=$(${DATE_UTIL} --date "${yyyymmdd_task} 1 day" +%Y%m%d%H)
if [[ ${fcst_output_times_all[@]} =~ ${yyyymmdd00_task_p1d} ]]; then
  fcst_output_times_crnt_day+=(${yyyymmdd00_task_p1d})
fi

# If there are no forecast APCP output times on the day of the current
# task, exit the script.
num_fcst_output_times_crnt_day=${#fcst_output_times_crnt_day[@]}
if [[ ${num_fcst_output_times_crnt_day} -eq 0 ]]; then
  print_info_msg "
None of the forecast APCP output times fall within the day (including the
0th hour of the next day) associated with the current task (yyyymmdd_task):
  yyyymmdd_task = \"${yyyymmdd_task}\"
Thus, there is no need to retrieve any obs files."
  exit
fi

# Obs files will be obtained by extracting them from the relevant 6-hourly
# archives.  Thus, we need the sequence of archive hours over which to
# loop.  In the simplest case, this sequence will be "6 12 18 24".  This
# will be the case if the forecast output times include all hours of the
# task's day and if none of the obs files for this day already exist on
# disk.  In other cases, the sequence we loop over will be a subset of
# "6 12 18 24".
#
# To generate this sequence, we first set its starting and ending values
# as well as the interval.

# Sequence interval must be 6 hours because the archives are 6-hourly.
arcv_hr_incr=6

# Initial guess for starting archive hour.  This is set to the archive 
# hour containing obs at the first forecast output time of the day.
hh_first=$(echo ${fcst_output_times_crnt_day[0]} | cut -c9-10)
hr_first=$((10#${hh_first}))
arcv_hr_start=$(ceil ${hr_first} ${arcv_hr_incr})
arcv_hr_start=$(( arcv_hr_start*arcv_hr_incr ))

# Ending archive hour.  This is set to the archive hour containing obs at
# the last forecast output time of the day.
hh_last=$(echo ${fcst_output_times_crnt_day[-1]} | cut -c9-10)
hr_last=$((10#${hh_last}))
if [[ ${hr_last} -eq 0 ]]; then
  arcv_hr_end=24
else
  arcv_hr_end=$(ceil ${hr_last} ${arcv_hr_incr})
  arcv_hr_end=$(( arcv_hr_end*arcv_hr_incr ))
fi

# Check whether any obs files already exist on disk.  If so, adjust the
# starting archive hour.  In the process, keep a count of the number of
# obs files that already exist on disk.
num_existing_files=0
for yyyymmddhh in ${fcst_output_times_crnt_day[@]}; do
  yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
  hh=$(echo ${yyyymmddhh} | cut -c9-10)
  day_dir_proc="${basedir_proc}/${yyyymmdd}"
  fn_proc="ccpa.t${hh}z.${accum}h.hrap.conus.gb2"
  fp_proc="${day_dir_proc}/${fn_proc}"
  if [[ -f ${fp_proc} ]]; then
    num_existing_files=$((num_existing_files+1))
    print_info_msg "
File already exists on disk:
  fp_proc = \"${fp_proc}\""
  else
    hr=$((10#${hh}))
    arcv_hr_start=$(ceil ${hr} ${arcv_hr_incr})
    arcv_hr_start=$(( arcv_hr_start*arcv_hr_incr ))
    print_info_msg "
File does not exists on disk:
  fp_proc = \"${fp_proc}\"
Setting the hour (since 00) of the first archive to retrieve to:
  arcv_hr_start = \"${arcv_hr_start}\""
    break
  fi
done

# If the number of obs files that already exist on disk is equal to the
# number of files needed, then there is no need to retrieve any files.
num_needed_files=$((num_fcst_output_times_crnt_day))
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
remove_raw_obs="${REMOVE_RAW_OBS_CCPA}"
# If the raw directories and files are to be removed at the end of this
# script, no need to copy the files since the raw directories are going
# to be removed anyway.
if [[ $(boolify "${remove_raw_obs}") == "TRUE" ]]; then
  mv_or_cp="mv"
fi

# Base directory that will contain the daily subdirectories in which the
# CCPA grib2 files retrieved from archive (tar) files will be placed.
# We refer to this as the "raw" base directory because it contains files
# as they are found in the archives before any processing by this script.
basedir_raw="${basedir_proc}/${yyyymmdd_task}/raw"

for arcv_hr in ${arcv_hrs[@]}; do

  print_info_msg "
arcv_hr = ${arcv_hr}"

  # Calculate the time information for the current archive.
  yyyymmddhh_arcv=$(${DATE_UTIL} --date "${yyyymmdd_task} ${arcv_hr} hours" +%Y%m%d%H)
  yyyymmdd_arcv=$(echo ${yyyymmddhh_arcv} | cut -c1-8)
  hh_arcv=$(echo ${yyyymmddhh_arcv} | cut -c9-10)

  # Directory that will contain the CCPA grib2 files retrieved from the
  # current 6-hourly archive file.  We refer to this as the "raw" quarter-
  # daily directory because it will contain the files as they are in the
  # archive before any processing by this script.
  qrtrday_dir_raw="${basedir_raw}/${yyyymmddhh_arcv}"

  # Check whether any of the forecast APCP output times for the day associated
  # with this task fall in the time interval spanned by the current archive.
  # If so, set the flag (do_retrieve) to retrieve the files in the current
  # archive.
  yyyymmddhh_qrtrday_start=$(${DATE_UTIL} --date "${yyyymmdd_arcv} ${hh_arcv} 5 hours ago" +%Y%m%d%H)
  yyyymmddhh_qrtrday_end=${yyyymmddhh_arcv}
  do_retrieve="FALSE"
  for (( i=0; i<${num_fcst_output_times_crnt_day}; i++ )); do
    output_time=${fcst_output_times_crnt_day[i]}
    if [[ "${output_time}" -ge "${yyyymmddhh_qrtrday_start}" ]] && \
       [[ "${output_time}" -le "${yyyymmddhh_qrtrday_end}" ]]; then
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
    # avoid other get_obs_ccpa tasks (i.e. those associated with other days)
    # from interfering with (clobbering) these files (because extracted files
    # from different get_obs_ccpa tasks to have the same names or relative
    # paths), we change location to the base raw directory so that files with
    # same names are extracted into different directories.
    cd ${basedir_raw}

    # Pull CCPA data from HPSS.  This will get all 6 obs files in the current
    # archive and place them in the raw quarter-daily directory.
    cmd="
    python3 -u ${USHdir}/retrieve_data.py \
      --debug \
      --file_set obs \
      --config ${PARMdir}/data_locations.yml \
      --cycle_date ${yyyymmddhh_arcv} \
      --data_stores hpss \
      --data_type CCPA_obs \
      --output_path ${qrtrday_dir_raw} \
      --summary_file retrieve_data.log"

    print_info_msg "CALLING: ${cmd}"
    $cmd || print_err_msg_exit "Could not retrieve obs from HPSS."

    # Create the processed CCPA grib2 files.  This usually consists of just
    # moving or copying the raw files to their processed location, but for
    # times between 20180718 and 20210504 and hours-of-day 19 through the
    # end of the day (i.e. hour 0 of the next day), it involves using wgrib2
    # to correct an error in the metadata of the raw file and writing the
    # corrected data to a new grib2 file in the processed location.
    for hrs_ago in $(seq 5 -1 0); do
      yyyymmddhh=$(${DATE_UTIL} --date "${yyyymmdd_arcv} ${hh_arcv} ${hrs_ago} hours ago" +%Y%m%d%H)
      yyyymmdd=$(echo ${yyyymmddhh} | cut -c1-8)
      hh=$(echo ${yyyymmddhh} | cut -c9-10)
      if [[ ${fcst_output_times_crnt_day[@]} =~ ${yyyymmddhh} ]]; then
        fn_raw="ccpa.t${hh}z.${accum}h.hrap.conus.gb2"
        fp_raw="${qrtrday_dir_raw}/${fn_raw}"
        day_dir_proc="${basedir_proc}/${yyyymmdd}"
        mkdir -p ${day_dir_proc}
        fn_proc="${fn_raw}"
        fp_proc="${day_dir_proc}/${fn_proc}"
        hh_noZero=$((10#${hh}))
        # CCPA files for 1-hour accumulation have incorrect metadata in the files
        # under the "00" directory from 20180718 to 20210504.  After the data is
        # pulled, reorganize into correct yyyymmdd structure.
        if [[ ${yyyymmdd} -ge 20180718 && ${yyyymmdd} -le 20210504 ]] && \
           [[ (${hh_noZero} -ge 19 && ${hh_noZero} -le 23) || (${hh_noZero} -eq 0) ]]; then
          wgrib2 ${fp_raw} -set_date -24hr -grib ${fp_proc} -s
        else
          ${mv_or_cp} ${fp_raw} ${fp_proc}
        fi
      fi
    done

  else

    print_info_msg "
None of the current day's forecast APCP output times fall in the range
spanned by the current 6-hourly archive file.  The bounds of the current
archive are:
  yyyymmddhh_qrtrday_start = \"${yyyymmddhh_qrtrday_start}\"
  yyyymmddhh_qrtrday_end = \"${yyyymmddhh_qrtrday_end}\"
The forecast output times for APCP are:
  fcst_output_times_crnt_day = ($(printf "\"%s\" " ${fcst_output_times_crnt_day[@]}))"

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
