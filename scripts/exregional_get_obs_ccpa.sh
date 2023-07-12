#!/bin/bash

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
# This script performs several important tasks for preparing CCPA data
# for verification tasks.
#
# If data is not available on disk (in the location specified by
# CCPA_OBS_DIR), the script attempts to retrieve the data from HPSS using
# the retrieve_data.py script. There are a few strange quirks and/or
# bugs in the way data is organized; see in-line comments for details.
#
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
# for. See in-line comments below for details
 
#-----------------------------------------------------------------------
#

# Set log file for retrieving obs
logfile=retrieve_data.log

# Top-level CCPA directory
ccpa_dir=${OBS_DIR}/..
if [[ ! -d "$ccpa_dir" ]]; then
  mkdir_vrfy -p $ccpa_dir
fi

# raw CCPA data from HPSS
ccpa_raw=$ccpa_dir/raw

# Reorganized CCPA location
ccpa_proc=$ccpa_dir/proc

# Accumulation is for accumulation of CCPA data to pull (hardcoded to 01h, see note above.)
#accum=${ACCUM}
accum=01

# PDY and cyc are defined in rocoto XML...they are the yyyymmdd and hh for initial forecast hour respectively
iyyyy=`echo ${PDY} | cut -c1-4`
imm=`echo ${PDY} | cut -c5-6`
idd=`echo ${PDY} | cut -c7-8`
ihh=${cyc}

# Unix date utility needs dates in yyyy-mm-dd hh:mm:ss format
unix_init_DATE="${iyyyy}-${imm}-${idd} ${ihh}:00:00"

# This awk expression gets the last item of the list $FHR
fcst_length=`echo ${FHR}  | awk '{ print $NF }'`

current_fcst=$accum
while [[ ${current_fcst} -le ${fcst_length} ]]; do
  #remove leading zero from current_fcst because bash treats numbers with leading zeros as octal *sigh*
  current_fcst=$((10#${current_fcst}))
  # Calculate valid date info using date utility  
  vdate=`$DATE_UTIL -d "${unix_init_DATE} ${current_fcst} hours" +%Y%m%d%H`
  vyyyymmdd=`echo ${vdate} | cut -c1-8`
  vhh=`echo ${vdate} | cut -c9-10`

  # Calculate valid date + 1 day; this is needed because (for some ungodly reason) CCPA files for 19-23z
  # are stored in the *next* day's 00h directory
  vdate_p1=`$DATE_UTIL -d "${unix_init_DATE} ${current_fcst} hours 1 day" +%Y%m%d%H`
  vyyyymmdd_p1=`echo ${vdate_p1} | cut -c1-8`

  #remove leading zero again, this time keep original
  vhh_noZero=$((10#${vhh}))

  # Check if file exists on disk; if not, pull it.
  ccpa_file="$ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2"
  echo "CCPA FILE:${ccpa_file}"
  if [[ ! -f "${ccpa_file}" ]]; then 
      # Create necessary raw and prop directories
      if [[ ! -d "$ccpa_raw/${vyyyymmdd}" ]]; then
        mkdir_vrfy -p $ccpa_raw/${vyyyymmdd}
      fi
      if [[ ! -d "$ccpa_raw/${vyyyymmdd_p1}" ]]; then
        mkdir_vrfy -p $ccpa_raw/${vyyyymmdd_p1}
      fi
      if [[ ! -d "$ccpa_proc/${vyyyymmdd}" ]]; then
        mkdir_vrfy -p $ccpa_proc/${vyyyymmdd}
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
        cp_vrfy $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 7 && ${vhh_noZero} -le 12 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 13 && ${vhh_noZero} -le 18 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 19 && ${vhh_noZero} -le 23 ]]; then
        if [[ ${vyyyymmdd} -ge 20180718 && ${vyyyymmdd} -le 20210504 ]]; then
          wgrib2 $ccpa_raw/${vyyyymmdd_p1}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -set_date -24hr -grib $ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -s
        else
          cp_vrfy $ccpa_raw/${vyyyymmdd_p1}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
        fi
      elif [[ ${vhh_noZero} -eq 0 ]]; then
        # One hour CCPA files on HPSS have incorrect metadata in the files under the "00" directory from 20180718 to 20210504.
        if [[ ${vyyyymmdd} -ge 20180718 && ${vyyyymmdd} -le 20210504 ]]; then
          wgrib2 $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -set_date -24hr -grib $ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -s
        else
          cp_vrfy $ccpa_raw/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
        fi
      fi

  else
    echo "File already exists on disk; will not retrieve"
  fi
  
  # Increment to next forecast hour      
  current_fcst=$((${current_fcst} + ${accum}))
  echo "Current fcst hr=${current_fcst}"

done
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

