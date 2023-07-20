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
# CCPA
# ----------
# If data is available on disk, it must be in the following 
# directory structure and file name conventions expected by verification
# tasks:
#
# {CCPA_OBS_DIR}/{YYYYMMDD}/ccpa.t{HH}z.01h.hrap.conus.gb2
#
# If data is retrieved from HPSS, it will automatically staged by this
# this script.
#
# Notes about the data and how it's used for verification:
# 
# 1. Accumulation is currently hardcoded to 01h. The verification will 
# use MET/pcp-combine to sum 01h files into desired accumulations.
#
# 2. There is a problem with the valid time in the metadata for files
# valid from 19 - 00 UTC (or files under the '00' directory). This is
# accounted for in this script for data retrieved from HPSS, but if you
# have manually staged data on disk you should be sure this is accouned
# for. See in-line comments below for details.
#
#
# MRMS
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
# NDAS
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
# If data is retrieved from HPSS, it will automatically staged by this
# this script.
#
#
# NOHRSC
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
iyyyy=`echo ${PDY} | cut -c1-4`
imm=`echo ${PDY} | cut -c5-6`
idd=`echo ${PDY} | cut -c7-8`
ihh=${cyc}

# Unix date utility needs dates in yyyy-mm-dd hh:mm:ss format
unix_init_DATE="${iyyyy}-${imm}-${idd} ${ihh}:00:00"

# This awk expression gets the last item of the list $FHR
fcst_length=`echo ${FHR}  | awk '{ print $NF }'`

current_fcst=01
while [[ ${current_fcst} -le ${fcst_length} ]]; do
  #remove leading zero from current_fcst because bash treats numbers with leading zeros as octal *sigh*
  current_fcst=$((10#${current_fcst}))
  # Calculate valid date info using date utility  
  vdate=`$DATE_UTIL -d "${unix_init_DATE} ${current_fcst} hours" +%Y%m%d%H`
  unix_vdate=`$DATE_UTIL -d "${unix_init_DATE} ${current_fcst} hours" "+%Y-%m-%d %H:00:00"`
  vyyyymmdd=`echo ${vdate} | cut -c1-8`
  vhh=`echo ${vdate} | cut -c9-10`

  # Calculate valid date + 1 day; this is needed because (for some ungodly reason) CCPA files for 19-23z
  # are stored in the *next* day's 00h directory
  vdate_p1=`$DATE_UTIL -d "${unix_init_DATE} ${current_fcst} hours 1 day" +%Y%m%d%H`
  vyyyymmdd_p1=`echo ${vdate_p1} | cut -c1-8`

  #remove leading zero again, this time keep original
  vhh_noZero=$((10#${vhh}))

  # Retrieve CCPA observations
  if [[ ${OBTYPE} == "CCPA" ]]; then

    # Staging location for raw CCPA data from HPSS
    ccpa_raw=${OBS_DIR}/raw

    # Reorganized CCPA location
    ccpa_proc=${OBS_DIR}

    # Accumulation is for accumulation of CCPA data to pull (hardcoded to 01h, see note above.)
    accum=01

    # Check if file exists on disk; if not, pull it.
    ccpa_file="$ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2"
    echo "CCPA FILE:${ccpa_file}"
    if [[ ! -f "${ccpa_file}" ]]; then 
      # Create necessary raw and prop directories
      if [[ ! -d "$ccpa_raw/${vyyyymmdd}" ]]; then
        mkdir -p $ccpa_raw/${vyyyymmdd}
      fi
      if [[ ! -d "$ccpa_raw/${vyyyymmdd_p1}" ]]; then
        mkdir -p $ccpa_raw/${vyyyymmdd_p1}
      fi
      if [[ ! -d "$ccpa_proc/${vyyyymmdd}" ]]; then
        mkdir -p $ccpa_proc/${vyyyymmdd}
      fi
      # Check if valid hour is 00
      if [[ ${vhh_noZero} -ge 19 && ${vhh_noZero} -le 23 ]]; then
        # Pull CCPA data from HPSS
        cmd="
        python3 -u ${USHdir}/retrieve_data.py \
          --debug \
          --file_set obs \
          --config ${PARMdir}/data_locations.yml \
          --cycle_date ${vyyyymmdd_p1}${vhh} \
          --data_stores hpss \
          --data_type CCPA_obs \
          --output_path $ccpa_raw/${vyyyymmdd_p1} \
          --summary_file ${logfile}"

        echo "CALLING: ${cmd}"
        $cmd || print_err_msg_exit "\
        Could not retrieve CCPA data from HPSS

        The following command exited with a non-zero exit status:
        ${cmd}
"

      else 
        # Pull CCPA data from HPSS
        cmd="
        python3 -u ${USHdir}/retrieve_data.py \
          --debug \
          --file_set obs \
          --config ${PARMdir}/data_locations.yml \
          --cycle_date ${vyyyymmdd}${vhh} \
          --data_stores hpss \
          --data_type CCPA_obs \
          --output_path $ccpa_raw/${vyyyymmdd} \
          --summary_file ${logfile}"

        echo "CALLING: ${cmd}"
        $cmd || print_err_msg_exit "\
        Could not retrieve CCPA data from HPSS

        The following command exited with a non-zero exit status:
        ${cmd}
"
      fi

      # One hour CCPA files have incorrect metadata in the files under the "00" directory from 20180718 to 20210504.
      # After data is pulled, reorganize into correct valid yyyymmdd structure.
      if [[ ${vhh_noZero} -ge 1 && ${vhh_noZero} -le 6 ]]; then
        cp $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 7 && ${vhh_noZero} -le 12 ]]; then
        cp $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 13 && ${vhh_noZero} -le 18 ]]; then
        cp $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 19 && ${vhh_noZero} -le 23 ]]; then
        if [[ ${vyyyymmdd} -ge 20180718 && ${vyyyymmdd} -le 20210504 ]]; then
          wgrib2 $ccpa_raw/${vyyyymmdd_p1}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -set_date -24hr -grib $ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -s
        else
          cp $ccpa_raw/${vyyyymmdd_p1}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
        fi
      elif [[ ${vhh_noZero} -eq 0 ]]; then
        # One hour CCPA files on HPSS have incorrect metadata in the files under the "00" directory from 20180718 to 20210504.
        if [[ ${vyyyymmdd} -ge 20180718 && ${vyyyymmdd} -le 20210504 ]]; then
          wgrib2 $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -set_date -24hr -grib $ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -s
        else
          cp $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
        fi
      fi

    else
      echo "File already exists on disk; will not retrieve"
    fi
  # Retrieve MRMS observations
  elif [[ ${OBTYPE} == "MRMS" ]]; then
    # Top-level MRMS directory
    # raw MRMS data from HPSS
    mrms_raw=${OBS_DIR}/raw

    # Reorganized MRMS location
    mrms_proc=${OBS_DIR}

    # For each field (REFC and RETOP), check if file exists on disk; if not, pull it.
    for field in ${VAR[@]}; do
      if [ "${field}" = "REFC" ]; then
        field_base_name="MergedReflectivityQCComposite"
        level="_00.50_"
      elif [ "${field}" = "RETOP" ]; then
        field_base_name="EchoTop"
        level="_18_00.50_"
      else
        echo "Invalid field: ${field}"
        print_err_msg_exit "\
        Invalid field specified: ${field}

        Valid options are 'REFC', 'RETOP'.
"
      fi

      mrms_file="$mrms_proc/${vyyyymmdd}/${field_base_name}${level}${vyyyymmdd}-${vhh}0000.grib2"
      echo "For field ${field}, looking for MRMS FILE: ${mrms_file}"

      if [[ ! -f "${mrms_file}" ]]; then
        # Create directories if necessary
        if [[ ! -d "$mrms_raw/${vyyyymmdd}" ]]; then
          mkdir -p $mrms_raw/${vyyyymmdd}
        fi
        if [[ ! -d "$mrms_proc/${vyyyymmdd}" ]]; then
          mkdir -p $mrms_proc/${vyyyymmdd}
        fi


        # Pull MRMS data from HPSS
        cmd="
        python3 -u ${USHdir}/retrieve_data.py \
          --debug \
          --file_set obs \
          --config ${PARMdir}/data_locations.yml \
          --cycle_date ${vyyyymmdd}${vhh} \
          --data_stores hpss \
          --data_type MRMS_obs \
          --output_path $mrms_raw/${vyyyymmdd} \
          --summary_file ${logfile}"

        echo "CALLING: ${cmd}"

        $cmd || print_err_msg_exit "\
        Could not retrieve MRMS data from HPSS

        The following command exited with a non-zero exit status:
        ${cmd}
"

        hour=0
        while [[ ${hour} -le 23 ]]; do
          HH=$(printf "%02d" $hour)
          echo "hour=${hour}"
          python ${USHdir}/mrms_pull_topofhour.py --valid_time ${vyyyymmdd}${HH} --outdir ${mrms_proc} --source ${mrms_raw} --product ${field_base_name} 
          hour=$((${hour} + 1)) # hourly increment
        done

      else
        echo "mrms_file exists: \"$mrms_proc/${vyyyymmdd}/${field_base_name}${level}${vyyyymmdd}-${vhh}0000.grib2\" No work to be done."
      fi
    done

  # Retrieve NDAS observations
  elif [[ ${OBTYPE} == "NDAS" ]]; then
    # raw NDAS data from HPSS
    ndas_raw=${OBS_DIR}/raw

    # Reorganized NDAS location
    ndas_proc=${OBS_DIR}

    # Check if file exists on disk; NDAS data is available in 6-hourly combined prepbufr files
    # If forecast ends on an off-hour (i.e., not 00z, 06z, 12z, or 18z), the last few hours of data may not be retrieved
    if [[ ${vhh_noZero} -eq 0 || ${vhh_noZero} -eq 6 || ${vhh_noZero} -eq 12 || ${vhh_noZero} -eq 18 ]]; then
      ndas_file="$ndas_proc/prepbufr.ndas.${vyyyymmdd}${vhh}"
      echo "NDAS PB FILE:${ndas_file}"

      if [[ ! -f "${ndas_file}" ]]; then
        if [[ ! -d "$ndas_raw/${vyyyymmdd}${vhh}" ]]; then
          mkdir -p $ndas_raw/${vyyyymmdd}${vhh}
        fi

        # Pull NDAS data from HPSS
        cmd="
        python3 -u ${USHdir}/retrieve_data.py \
          --debug \
          --file_set obs \
          --config ${PARMdir}/data_locations.yml \
          --cycle_date ${vyyyymmdd}${vhh} \
          --data_stores hpss \
          --data_type NDAS_obs \
          --output_path $ndas_raw/${vyyyymmdd}${vhh} \
          --summary_file ${logfile}"

        echo "CALLING: ${cmd}"

        $cmd || print_err_msg_exit "\
        Could not retrieve NDAS data from HPSS

        The following command exited with a non-zero exit status:
        ${cmd}
"

        if [[ ! -d "$ndas_proc" ]]; then
          mkdir -p $ndas_proc
        fi

        # copy files from the previous 6 hours
        for tm in $(seq 0 5); do
          vyyyymmddhh_tm=`$DATE_UTIL -d "${unix_vdate} ${tm} hours ago" +%Y%m%d%H`
          tm2=$(echo $tm | awk '{printf "%02d\n", $0;}')

          cp $ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm${tm2}.nr $ndas_proc/prepbufr.ndas.${vyyyymmddhh_tm}
        done
      else
        echo "NDAS file exists: ${ndas_file}"
        echo "Will not retrieve from HPSS"
      fi
    fi

  # Retrieve NOHRSC observations
  elif [[ ${OBTYPE} == "NOHRSC" ]]; then

    # Reorganized NOHRSC location (no need for raw data dir)
    nohrsc_proc=${OBS_DIR}

    nohrsc06h_file="$nohrsc_proc/${vyyyymmdd}/sfav2_CONUS_06h_${vyyyymmdd}${vhh}_grid184.grb2"
    nohrsc24h_file="$nohrsc_proc/${vyyyymmdd}/sfav2_CONUS_24h_${vyyyymmdd}${vhh}_grid184.grb2"
    retrieve=0
    # If 24-hour files should be available (at 00z and 12z) then look for both files
    # Otherwise just look for 6hr file
    if (( ${current_fcst} % 12 == 0 )) && (( ${current_fcst} >= 24 )) ; then
      if [ ! -f "${nohrsc06h_file}" ] || [ ! -f "${nohrsc24h_file}" ] ; then 
        retrieve=1
      else
        echo "NOHRSC 6h accumulation file exists: ${nohrsc06h_file}"
        echo "NOHRSC 24h accumulation file exists: ${nohrsc24h_file}"
      fi
    elif (( ${current_fcst} % 6 == 0 )) ; then
      if [ ! -f "${nohrsc06h_file}" ]; then
        retrieve=1
      else
        echo "NOHRSC 6h accumulation file exists: ${nohrsc06h_file}"
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
    else
      echo "Will not retrieve from HPSS"
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
rm -rf ${OBS_DIR}/raw

#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

