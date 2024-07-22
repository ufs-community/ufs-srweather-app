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
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
set -x
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
# Create and enter top-level obs directory (so temporary data from HPSS won't collide with other tasks)
mkdir -p ${OBS_DIR}
cd ${OBS_DIR}

# Set log file for retrieving obs
logfile=retrieve_data.log

# PDY and cyc are defined in rocoto XML...they are the yyyymmdd and hh for initial forecast hour respectively
iyyyy=$(echo ${PDY} | cut -c1-4)
imm=$(echo ${PDY} | cut -c5-6)
idd=$(echo ${PDY} | cut -c7-8)
ihh=${cyc}

echo
echo "HELLO GGGGGGGG"
iyyyymmddhh=${PDY}${cyc}
echo "iyyyymmddhh = ${iyyyymmddhh}"

# Unix date utility needs dates in yyyy-mm-dd hh:mm:ss format
unix_init_DATE="${iyyyy}-${imm}-${idd} ${ihh}:00:00"

# This awk expression gets the last item of the list $FHR
fcst_length=$(echo ${FHR}  | awk '{ print $NF }')

if [[ ${OBTYPE} == "NDAS" ]]; then
  vdate_last=$($DATE_UTIL -d "${unix_init_DATE} ${fcst_length} hours" +%Y%m%d%H)
  vhh_last=$(echo ${vdate_last} | cut -c9-10)
  hours_to_add=$(( vhh_last + 6 - (vhh_last % 6) ))
  fcst_length_rounded_up=$(( fcst_length + hours_to_add ))
#  vdate_last_rounded_up=$($DATE_UTIL -d "${unix_init_DATE} ${fcst_length_rounded_up} hours" +%Y%m%d%H)
  fcst_length=${fcst_length_rounded_up}
fi

# Make sure fcst_length isn't octal (leading zero)
fcst_length=$((10#${fcst_length}))

current_fcst=0
while [[ ${current_fcst} -le ${fcst_length} ]]; do

echo
echo "HELLO GGGGGGGG"
echo "current_fcst = ${current_fcst}"

  # Calculate valid date info using date utility
  vdate=$($DATE_UTIL -d "${unix_init_DATE} ${current_fcst} hours" +%Y%m%d%H)
  #unix_vdate=$($DATE_UTIL -d "${unix_init_DATE} ${current_fcst} hours" "+%Y-%m-%d %H:00:00")
  vyyyymmdd=$(echo ${vdate} | cut -c1-8)
  vhh=$(echo ${vdate} | cut -c9-10)

  # Calculate valid date + 1 day; this is needed because some obs files
  # are stored in the *next* day's 00h directory
  vdate_p1d=$($DATE_UTIL -d "${unix_init_DATE} ${current_fcst} hours 1 day" +%Y%m%d%H)
  vyyyymmdd_p1d=$(echo ${vdate_p1d} | cut -c1-8)

echo
echo "HELLO HHHHHHHH"
echo "vyyyymmdd = ${vyyyymmdd}"
echo "vyyyymmdd_p1d = ${vyyyymmdd_p1d}"
echo "ihh = ${ihh}"
#exit

  #remove leading zero again, this time keep original
  vhh_noZero=$((10#${vhh}))
#
#-----------------------------------------------------------------------
#
# Retrieve CCPA observations.
#
#-----------------------------------------------------------------------
#
  if [[ ${OBTYPE} == "CCPA" ]]; then

    # CCPA is accumulation observations.  We do not need to retrieve any
    # observed accumulations at forecast hour 0 because there aren't yet
    # any accumulations in the forecast(s) to compare it to.
    if [[ ${current_fcst} -eq 0 ]]; then
      current_fcst=$((current_fcst + 1))
      continue
    fi

    # CCPA accumulation period to consider.  Here, we only retrieve data for
    # 01h accumulations (see note above).  Other accumulations (03h, 06h, 24h)
    # are obtained elsewhere in the workflow by adding up these 01h accumulations.
    accum=01

    # Base directory in which the daily subdirectories containing the CCPA
    # grib2 files will appear after this script is done, and the daily such
    # subdirectory for the current valid time (year, month, and day).  We
    # refer to these as the "processed" base and daily subdirectories because
    # they contain the final files after all processing by this script is
    # complete.
    ccpa_basedir_proc=${OBS_DIR}
    ccpa_day_dir_proc="${ccpa_basedir_proc}/${vyyyymmdd}"
    # Make sure these directories exist.
    mkdir -p ${ccpa_day_dir_proc}

    # Name of the grib2 file to extract from the archive (tar) file as well
    # as the name of the processed grib2 file.
    ccpa_fn="ccpa.t${vhh}z.${accum}h.hrap.conus.gb2"

    # Full path to the location of the processed CCPA grib2 file for the
    # current valid time.  Note that this path includes the valid date (year,
    # month, and day) information in the name of a subdirectory and the valid
    # hour-of-day in the name of the file.
    ccpa_fp_proc="${ccpa_day_dir_proc}/${ccpa_fn}"

    # Check if the CCPA grib2 file for the current valid time already exists
    # at its procedded location on disk.  If so, skip and go to the next valid
    # time.  If not, pull it.
    if [[ -f "${ccpa_fp_proc}" ]]; then

      echo "${OBTYPE} file exists on disk:"
      echo "  ccpa_fp_proc = \"${ccpa_fp_proc}\""
      echo "Will NOT attempt to retrieve from remote locations."

    else

      echo "${OBTYPE} file does not exist on disk:"
      echo "  ccpa_fp_proc = \"${ccpa_fp_proc}\""
      echo "Will attempt to retrieve from remote locations."
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
      #   directory (ccpa_basedir_proc).
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

      # Set parameters for retrieving CCPA data using retrieve_data.py.
      # Definitions:
      #
      # valid_time:
      # The valid time in the name of the archive (tar) file from which data
      # will be pulled.  Due to the way the data is arranged in the CCPA archive
      # files (as described above), for valid hours 19 to 23 of the current day,
      # this must be set to the corresponding valid time on the NEXT day.
      #
      # ccpa_basedir_raw:
      # Raw base directory that will contain the raw daily subdirectory in which
      # the retrieved CCPA grib2 file will be placed.  Note that this must be
      # cycle-dependent (where the cycle is given by the variable iyyyymmddhh)
      # to avoid get_obs_ccpa workflow tasks for other cycles writing to the
      # same directories/files.  Note also that this doesn't have to depend on
      # the current valid hour (0-18 vs. 19-23), but for clarity and ease of
      # debugging, here we do make it valid-hour-dependent.
      #
      # ccpa_day_dir_raw:
      # Raw daily subdirectory under the raw base directory.  This is dependent
      # on the valid hour (i.e. different for hours 19-23 than for hours 0-18)
      # in order to maintain the same data timing arrangement in the raw daily
      # directories as in the archive files.
      #
      if [[ ${vhh_noZero} -ge 0 && ${vhh_noZero} -le 18 ]]; then
        valid_time=${vyyyymmdd}${vhh}
        ccpa_basedir_raw="${ccpa_basedir_proc}/raw_cyc${iyyyymmddhh}"
        ccpa_day_dir_raw="${ccpa_basedir_raw}/${vyyyymmdd}"
      elif [[ ${vhh_noZero} -ge 19 && ${vhh_noZero} -le 23 ]]; then
        valid_time=${vyyyymmdd_p1d}${vhh}
        ccpa_basedir_raw="${ccpa_basedir_proc}/raw_cyc${iyyyymmddhh}_vhh19-23"
        ccpa_day_dir_raw="${ccpa_basedir_raw}/${vyyyymmdd_p1d}"
      fi
      mkdir -p ${ccpa_day_dir_raw}

      # Before calling retrieve_data.py, change location to the raw base
      # directory to avoid get_obs_ccpa tasks for other cycles from clobbering
      # the output from this call to retrieve_data.py.  Note that retrieve_data.py
      # extracts the CCPA tar files into the directory it was called from,
      # which is the working directory of this script right before retrieve_data.py
      # is called.
      cd ${ccpa_basedir_raw}

      # Pull CCPA data from HPSS.  This will get a single grib2 (.gb2) file
      # corresponding to the current valid time (valid_time).
      cmd="
      python3 -u ${USHdir}/retrieve_data.py \
        --debug \
        --file_set obs \
        --config ${PARMdir}/data_locations.yml \
        --cycle_date ${valid_time} \
        --data_stores hpss \
        --data_type CCPA_obs \
        --output_path ${ccpa_day_dir_raw} \
        --summary_file ${logfile}"

      echo "CALLING: ${cmd}"
      $cmd || print_err_msg_exit "\
      Could not retrieve CCPA data from HPSS.

      The following command exited with a non-zero exit status:
      ${cmd}
"

      # Create the processed CCPA grib2 files.  This usually consists of just
      # moving or copying the raw file to its processed location, but for valid
      # times between 20180718 and 20210504, it involves using wgrib2 to correct
      # an error in the metadata of the raw file and writing the corrected data
      # to a new grib2 file in the processed location.
      #
      # Since this script is part of a workflow, another get_obs_ccpa task (i.e.
      # for another cycle) may have extracted and placed the current file in its
      # processed location between the time we checked for its existence above
      # (and didn't find it) and now.  This can happen because there can be
      # overlap between the verification times for the current cycle and those
      # of other cycles.  For this reason, check again for the existence of the
      # processed file.  If it has already been created by another get_obs_ccpa
      # task, don't bother to recreate it.
      if [[ -f "${ccpa_fp_proc}" ]]; then

        echo "${OBTYPE} file exists on disk:"
        echo "  ccpa_fp_proc = \"{ccpa_fp_proc}\""
        echo "It was likely created by a get_obs_ccpa workflow task for another cycle that overlaps the current one."
        echo "NOT moving or copying file from its raw location to its processed location."

      else

        # Full path to the CCPA file that was pulled and extracted above and
        # placed in the raw directory.
        ccpa_fp_raw="${ccpa_day_dir_raw}/${ccpa_fn}"

        #mv_or_cp="mv"
        mv_or_cp="cp"
        if [[ ${vhh_noZero} -ge 1 && ${vhh_noZero} -le 18 ]]; then
          ${mv_or_cp} ${ccpa_fp_raw} ${ccpa_fp_proc}
        elif [[ (${vhh_noZero} -eq 0) || (${vhh_noZero} -ge 19 && ${vhh_noZero} -le 23) ]]; then
          # One hour CCPA files have incorrect metadata in the files under the "00"
          # directory from 20180718 to 20210504.  After data is pulled, reorganize
          # into correct valid yyyymmdd structure.
          if [[ ${vyyyymmdd} -ge 20180718 && ${vyyyymmdd} -le 20210504 ]]; then
            wgrib2 ${ccpa_fp_raw} -set_date -24hr -grib ${ccpa_fp_proc} -s
          else
            ${mv_or_cp} ${ccpa_fp_raw} ${ccpa_fp_proc}
          fi
        fi

      fi

    fi
#
#-----------------------------------------------------------------------
#
# Retrieve MRMS observations.
#
#-----------------------------------------------------------------------
#
  elif [[ ${OBTYPE} == "MRMS" ]]; then

    # Base directory in which the daily subdirectories containing the MRMS
    # grib2 files for REFC (composite reflectivity) and REFC (echo top) will
    # be located after this script is done, and the daily such subdirectory
    # for the current valid time (year, month, and day).  We refer to these
    # as the "processed" base and daily subdirectories because they contain
    # the final files after all processing by this script is complete.
    mrms_basedir_proc=${OBS_DIR}
    mrms_day_dir_proc="${mrms_basedir_proc}/${vyyyymmdd}"

    # Loop over the fields (REFC and RETOP).
    for field in ${VAR[@]}; do

      # Set field-dependent parameters needed in forming grib2 file names.
      if [ "${field}" = "REFC" ]; then
        file_base_name="MergedReflectivityQCComposite"
        level="_00.50_"
      elif [ "${field}" = "RETOP" ]; then
        file_base_name="EchoTop"
        level="_18_00.50_"
      else
        echo "Invalid field: ${field}"
        print_err_msg_exit "\
        Invalid field specified: ${field}

        Valid options are 'REFC', 'RETOP'.
"
      fi

      # Name of the MRMS grib2 file for the current field and valid time that
      # will appear in the processed daily subdirectory after this script finishes.
      # This is the name of the processed file.  Note that this is generally
      # not the name of the gzipped grib2 files that may be retrieved below
      # from archive files using the retrieve_data.py script.
      mrms_fn="${file_base_name}${level}${vyyyymmdd}-${vhh}0000.grib2"

      # Full path to the processed MRMS grib2 file for the current field and
      # valid time.
      mrms_fp_proc="${mrms_day_dir_proc}/${mrms_fn}"

      # Check if the processed MRMS grib2 file for the current field and valid
      # time already exists on disk.  If so, skip this valid time and go to the
      # next one.  If not, pull it.
      if [[ -f "${mrms_fp_proc}" ]]; then

        echo "${OBTYPE} file exists on disk:"
        echo "  mrms_fp_proc = \"${mrms_fp_proc}\""
        echo "Will NOT attempt to retrieve from remote locations."

      else

        echo "${OBTYPE} file does not exist on disk:"
        echo "  mrms_fp_proc = \"${mrms_fp_proc}\""
        echo "Will attempt to retrieve from remote locations."

        # Base directory that will contain the daily subdirectories in which the
        # gzipped MRMS grib2 files retrieved from archive files will be placed,
        # and the daily subdirectory for the current valid year, month, and day.
        # We refer to these as the "raw" MRMS base and daily directories because
        # they contain files as they are found in the archives before any processing
        # by this script.
        #
        # Note that the name of the raw base directory depends on (contains) the
        # valid year, month, and day (but not on the cycle, i.e. not on iyyyymmddhh)
        # in order to avoid having get_obs_mrms tasks from other cycles clobbering
        # the output from this one.  It is also possible to make the name of this
        # directory name depend instead on the cycle, but that turns out to cause
        # an inefficiency in that get_obs_mrms tasks for different cycles will
        # not be able to detect that another cycle has already retrieved the data
        # for the current valid day will unnecessarily repeat the retrieval.
        mrms_basedir_raw="${mrms_basedir_proc}/raw_day${vyyyymmdd}"
        mrms_day_dir_raw="${mrms_basedir_raw}/${vyyyymmdd}"

        # Check if the raw daily directory already exists on disk.  If so, it
        # means all the gzipped MRMS grib2 files -- i.e. for both REFC and RETOP
        # and for all times (hours, minutes, and seconds) in the current valid
        # day -- have already been or are in the process of being retrieved from
        # the archive (tar) files.  If so, skip the retrieval process.  If not,
        # proceed to retrieve all the files and place them in the raw daily
        # directory.
        if [[ -d "${mrms_day_dir_raw}" ]]; then

          echo "${OBTYPE} directory for day ${vyyyymmdd} exists on disk:"
          echo "  mrms_day_dir_proc = \"${mrms_day_dir_proc}\""
          echo "This means MRMS files for all hours of the current valid day (${vyyyymmdd}) have been or are being retrieved."
          echo "Thus, we will NOT attempt to retrieve MRMS data for the current valid time from remote locations."

        else

          mkdir -p ${mrms_day_dir_raw}
          valid_time=${vyyyymmdd}${vhh}

          # Before calling retrieve_data.py, change location to the raw base
          # directory to avoid get_obs_mrms tasks for other cycles from clobbering
          # the output from this call to retrieve_data.py.  Note that retrieve_data.py
          # extracts the MRMS tar files into the directory it was called from,
          # which is the working directory of this script right before retrieve_data.py
          # is called.
          cd ${mrms_basedir_raw}

          # Use the retrieve_data.py script to retrieve all the gzipped MRMS grib2
          # files -- i.e. for both REFC and RETOP and for all times (hours, minutes,
          # and seconds) in the current valid day -- and place them in the raw daily
          # directory.  Note that this will pull both the REFC and RETOP files in
          # one call.
          cmd="
          python3 -u ${USHdir}/retrieve_data.py \
            --debug \
            --file_set obs \
            --config ${PARMdir}/data_locations.yml \
            --cycle_date ${valid_time} \
            --data_stores hpss \
            --data_type MRMS_obs \
            --output_path ${mrms_day_dir_raw} \
            --summary_file ${logfile}"

          echo "CALLING: ${cmd}"

          $cmd || print_err_msg_exit "\
          Could not retrieve MRMS data from HPSS

          The following command exited with a non-zero exit status:
          ${cmd}
"

          # Create a flag file that can be used to confirm the completion of the
          # retrieval of all files for the current valid day.
          touch ${mrms_day_dir_raw}/pull_completed.txt

        fi

        # Make sure the retrieval process for the current day (which may have
        # been executed above for this cycle or for another cycle) has completed
        # by checking for the existence of the flag file that marks completion.
        # If not, keep checking until the flag file shows up.
        while [[ ! -f "${mrms_day_dir_raw}/pull_completed.txt" ]]; do
          echo "Waiting for the retrieval process for valid day ${vyyyymmdd} to complete..."
          sleep 5s
        done

        # Since this script is part of a workflow, another get_obs_mrms task (i.e.
        # for another cycle) may have extracted and placed the current file in its
        # processed location between the time we checked for its existence above
        # (and didn't find it) and now.  This can happen because there can be
        # overlap between the verification times for the current cycle and those
        # of other cycles.  For this reason, check again for the existence of the
        # processed file.  If it has already been created by another get_obs_mrms
        # task, don't bother to recreate it.
        if [[ -f "${mrms_fp_proc}" ]]; then

          echo "${OBTYPE} file exists on disk:"
          echo "  mrms_fp_proc = \"${mrms_fp_proc}\""
          echo "Will NOT attempt to retrieve from remote locations."

        else

          # Search the raw daily directory for the current valid day to find the
          # gizipped MRMS grib2 file whose time stamp (in the file name) is closest
          # to the current valid day and hour.  Then unzip that file and copy it
          # to the processed daily directory, in the process renaming it to replace
          # the minutes and hours in the file name with "0000".
          valid_time=${vyyyymmdd}${vhh}
          python ${USHdir}/mrms_pull_topofhour.py \
            --valid_time ${valid_time} \
            --outdir ${mrms_basedir_proc} \
            --source ${mrms_basedir_raw} \
            --product ${file_base_name}

        fi

      fi

    done
#
#-----------------------------------------------------------------------
#
# Retrieve NDAS observations.
#
#-----------------------------------------------------------------------
#
  elif [[ ${OBTYPE} == "NDAS" ]]; then

    # Calculate valid date plus 1 hour.  This is needed because we need to 
    # check whether this date corresponds to one of the valid hours-of-day
    # 00, 06, 12, and 18 on which the NDAS archives are provided.
    unix_vdate_p1h=$($DATE_UTIL -d "${unix_init_DATE} $((current_fcst+1)) hours" "+%Y-%m-%d %H:00:00")
    vdate_p1h=$($DATE_UTIL -d "${unix_vdate_p1h}" +%Y%m%d%H)
    vyyyymmdd_p1h=$(echo ${vdate_p1h} | cut -c1-8)
    vhh_p1h=$(echo ${vdate_p1h} | cut -c9-10)
    vhh_p1h_noZero=$((10#${vhh_p1h}))

echo ""
echo "HELLO PPPPPPP"
echo "vyyyymmdd = ${vyyyymmdd}"
echo "vhh = ${vhh}"
echo "vhh_noZero = ${vhh_noZero}"
echo "vdate = ${vdate}"
echo "vdate_p1h = ${vdate_p1h}"

    # Base directory in which the hourly NDAS prepbufr files will be located.
    # We refer to this as the "processed" base directory because it contains
    # the final files after all processing by this script is complete.
    ndas_basedir_proc=${OBS_DIR}

    # Name of the NDAS prepbufr file for the current valid time that will
    # appear in the processed daily subdirectory after this script finishes.
    # This is the name of the processed file.  Note that this is not the 
    # same as the name of the raw file, i.e. the file extracted from the
    # archive (tar) file retrieved below by the retrieve_data.py script.
    ndas_fn="prepbufr.ndas.${vyyyymmdd}${vhh}"

    # Full path to the processed NDAS prepbufr file for the current field and
    # valid time.
    ndas_fp_proc="${ndas_basedir_proc}/${ndas_fn}"

    # Check if the processed NDAS prepbufr file for the current valid time
    # already exists on disk.  If so, skip this valid time and go to the next
    # one. 
    if [[ -f "${ndas_fp_proc}" ]]; then

      echo "${OBTYPE} file exists on disk:"
      echo "  ndas_fp_proc = \"${ndas_fp_proc}\""
      echo "Will NOT attempt to retrieve from remote locations."

    else

      echo "${OBTYPE} file does not exist on disk:"
      echo "  ndas_fp_proc = \"${ndas_fp_proc}\""
      echo "Will attempt to retrieve from remote locations."
      # NDAS data is available in 6-hourly combined tar files, each with 7 1-hour prepbufr files:
      # nam.tHHz.prepbufr.tm00.nr, nam.tHHz.prepbufr.tm01.nr, ... , nam.tHHz.prepbufr.tm06.nr
      #
      # The "tm" here means "time minus", so nam.t12z.prepbufr.tm00.nr is valid for 12z,
      # nam.t00z.prepbufr.tm03.nr is valid for 21z the previous day, etc.
      # This means that every six hours we have two obs files valid for the same time:
      # nam.tHHz.prepbufr.tm00.nr and nam.t[HH+6]z.prepbufr.tm06.nr
      # We want to use the tm06 file because it contains more/better obs (confirmed with EMC: even
      # though the earlier files are larger, this is because the time window is larger)

      # Whether to move or copy extracted files from the raw directories to their
      # final locations.
      #mv_or_cp="mv"
      mv_or_cp="cp"

echo ""
echo "HELLO AAAAA"
echo "vhh_noZero = ${vhh_noZero}"
echo "vhh_p1h_noZero = ${vhh_p1h_noZero}"

      # Due to the way NDAS archives are organized, we can only retrieve the
      # archive (tar) file containing data for the current valid hour (and the
      # 5 hours preceeding it) if the hour-of-day corresponding to the current
      # valid time plus 1 hour corresponds to one of 0, 6, 12, and 18.
      if [[ ${vhh_p1h_noZero} -eq 0 || ${vhh_p1h_noZero} -eq 6 || \
            ${vhh_p1h_noZero} -eq 12 || ${vhh_p1h_noZero} -eq 18 ]]; then

        # Base directory that will contain the 6-hourly subdirectories in which
        # the NDAS prepbufr files retrieved from archive files will be placed,
        # and the 6-hourly subdirectory for the current valid time plus 1 hour.
        # We refer to these as the "raw" NDAS base and 6-hourly directories
        # because they contain files as they are found in the archives before
        # any processing by this script.
        ndas_basedir_raw="${ndas_basedir_proc}/raw_day${vyyyymmdd_p1h}"
        ndas_day_dir_raw="${ndas_basedir_raw}/${vdate_p1h}"

        # Check if the raw 6-hourly directory already exists on disk.  If so, it
        # means the NDAS prepbufr files for the current valid hour and the 5 hours
        # preceeding it have already been or are in the process of being retrieved
        # from the archive (tar) files.  If so, skip the retrieval process.  If
        # not, proceed to retrieve the archive file, extract the prepbufr files
        # from it, and place them in the raw daily directory.
        if [[ -d "${ndas_day_dir_raw}" ]]; then

          print_info_msg "
${OBTYPE} raw directory for day ${vdate_p1h} exists on disk:
  ndas_day_dir_raw = \"${ndas_day_dir_raw}\"
This means NDAS files for the current valid time (${vyyyymmdd}) and the
5 hours preceeding it have been or are being retrieved by a get_obs_ndas
workflow task for another cycle.  Thus, we will NOT attempt to retrieve
NDAS data for the current valid time from remote locations."

        else

          mkdir -p ${ndas_day_dir_raw}

          # Before calling retrieve_data.py, change location to the raw base
          # directory to avoid get_obs_ndas tasks for other cycles from clobbering
          # the output from this call to retrieve_data.py.  Note that retrieve_data.py
          # extracts the NDAS prepbufr files the archive into the directory it was
          # called from, which is the working directory of this script right before
          # retrieve_data.py is called.
          cd ${ndas_basedir_raw}

          # Use the retrieve_data.py script to retrieve all the NDAS prepbufr files
          # for the current valid hour and the 5 hours preceeding it and place them
          # in the raw 6-hourly directory.
          cmd="
          python3 -u ${USHdir}/retrieve_data.py \
            --debug \
            --file_set obs \
            --config ${PARMdir}/data_locations.yml \
            --cycle_date ${vdate_p1h} \
            --data_stores hpss \
            --data_type NDAS_obs \
            --output_path ${ndas_day_dir_raw} \
            --summary_file ${logfile}"

          echo "CALLING: ${cmd}"

          $cmd || print_err_msg_exit "\
          Could not retrieve NDAS data from HPSS

          The following command exited with a non-zero exit status:
          ${cmd}
"

          # Create a flag file that can be used to confirm the completion of the
          # retrieval of all files for the 6-hour interval ending in vdate_p1h.
          touch ${ndas_day_dir_raw}/pull_completed.txt

        fi

        # Make sure the retrieval process for the 6-hour interval ending in
        # vdate_p1h (which may have been executed above for this cycle or for
        # another cycle) has completed by checking for the existence of the flag
        # file that marks completion.  If not, keep checking until the flag file
        # shows up.
        while [[ ! -f "${ndas_day_dir_raw}/pull_completed.txt" ]]; do
          echo "Waiting for completion of the NDAS obs retrieval process for the"
          echo "6-hour interval ending on ${vdate_p1h} ..."
          sleep 5s
        done

        # Since this script is part of a workflow, another get_obs_ndas task (i.e.
        # for another cycle) may have extracted and placed the current file in its
        # processed location between the time we checked for its existence above
        # (and didn't find it) and now.  This can happen because there can be
        # overlap between the verification times for the current cycle and those
        # of other cycles.  For this reason, check again for the existence of the
        # processed file.  If it has already been created by another get_obs_ndas
        # task, don't bother to recreate it.
        if [[ -f "${ndas_fp_proc}" ]]; then

          echo "${OBTYPE} file exists on disk:"
          echo "  ndas_fp_proc = \"${ndas_fp_proc}\""
          echo "Will NOT attempt to retrieve from remote locations."

        else

          # Create the processed NDAS prepbufr files for the current valid hour as
          # well as the preceeding 5 hours (or fewer if they're outside the time
          # interval of the forecast) by copying or moving (and in the process
          # renaming) them from the raw 6-hourly directory.  In the following loop,
          # "tm" means "time minus".  Note that the tm06 files contain more/better
          # observations than tm00 for the equivalent time.
          for tm in $(seq 6 -1 1); do
#          for tm in $(seq --format="%02g" 6 -1 1); do
            vdate_p1h_tm=$($DATE_UTIL -d "${unix_vdate_p1h} ${tm} hours ago" +%Y%m%d%H)
            if [ ${vdate_p1h_tm} -le ${vdate_last} ]; then
              tm2=$(echo $tm | awk '{printf "%02d\n", $0;}')
              ${mv_or_cp} ${ndas_day_dir_raw}/nam.t${vhh_p1h}z.prepbufr.tm${tm2}.nr \
                          ${ndas_basedir_proc}/prepbufr.ndas.${vdate_p1h_tm}
            fi
          done

        fi

      fi

    fi
#
#-----------------------------------------------------------------------
#
# Retrieve NOHRSC observations.
#
#-----------------------------------------------------------------------
#
  elif [[ ${OBTYPE} == "NOHRSC" ]]; then

    #NOHRSC is accumulation observations, so none to retrieve for hour zero
    if [[ ${current_fcst} -eq 0 ]]; then
      current_fcst=$((${current_fcst} + 1))
      continue
    fi

    # Reorganized NOHRSC location (no need for raw data dir)
    nohrsc_proc=${OBS_DIR}

    nohrsc06h_file="$nohrsc_proc/${vyyyymmdd}/sfav2_CONUS_06h_${vyyyymmdd}${vhh}_grid184.grb2"
    nohrsc24h_file="$nohrsc_proc/${vyyyymmdd}/sfav2_CONUS_24h_${vyyyymmdd}${vhh}_grid184.grb2"
    retrieve=0
    # If 24-hour files should be available (at 00z and 12z) then look for both files
    # Otherwise just look for 6hr file
    if (( ${current_fcst} % 12 == 0 )) && (( ${current_fcst} >= 24 )) ; then
      if [[ ! -f "${nohrsc06h_file}" || ! -f "${nohrsc24h_file}" ]] ; then
        retrieve=1
        echo "${OBTYPE} files do not exist on disk:"
        echo "${nohrsc06h_file}"
        echo "${nohrsc24h_file}"
        echo "Will attempt to retrieve from remote locations"
      else
        echo "${OBTYPE} files exist on disk:"
        echo "${nohrsc06h_file}"
        echo "${nohrsc24h_file}"
      fi
    elif (( ${current_fcst} % 6 == 0 )) ; then
      if [[ ! -f "${nohrsc06h_file}" ]]; then
        retrieve=1
        echo "${OBTYPE} file does not exist on disk:"
        echo "${nohrsc06h_file}"
        echo "Will attempt to retrieve from remote locations"
      else
        echo "${OBTYPE} file exists on disk:"
        echo "${nohrsc06h_file}"
      fi
    fi
    if [ $retrieve == 1 ]; then
      if [[ ! -d "$nohrsc_proc/${vyyyymmdd}" ]]; then
        mkdir -p $nohrsc_proc/${vyyyymmdd}
      fi

      # Pull NOHRSC data from HPSS; script will retrieve all files so only call once
      cmd="
      python3 -u ${USHdir}/retrieve_data.py \
        --debug \
        --file_set obs \
        --config ${PARMdir}/data_locations.yml \
        --cycle_date ${vyyyymmdd}${vhh} \
        --data_stores hpss \
        --data_type NOHRSC_obs \
        --output_path $nohrsc_proc/${vyyyymmdd} \
        --summary_file ${logfile}"

      echo "CALLING: ${cmd}"

      $cmd || print_err_msg_exit "\
      Could not retrieve NOHRSC data from HPSS

      The following command exited with a non-zero exit status:
      ${cmd}
"
      # 6-hour forecast needs to be renamed
      mv $nohrsc_proc/${vyyyymmdd}/sfav2_CONUS_6h_${vyyyymmdd}${vhh}_grid184.grb2 ${nohrsc06h_file}
    fi

  else
    print_err_msg_exit "\
    Invalid OBTYPE specified for script; valid options are CCPA, MRMS, NDAS, and NOHRSC
  "
  fi  # Increment to next forecast hour

  # Increment to next forecast hour
  echo "Finished fcst hr=${current_fcst}"
  current_fcst=$((${current_fcst} + 1))

done


# Clean up raw, unprocessed observation files
#rm -rf ${OBS_DIR}/raw

#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

