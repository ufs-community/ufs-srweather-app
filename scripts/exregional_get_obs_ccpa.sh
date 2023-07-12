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
#
#-----------------------------------------------------------------------
#
# This script reorganizes the CCPA data into a more intuitive structure:
# A valid YYYYMMDD directory is created, and all files for the valid day are placed within the directory.
# Supported accumulations: 01h, 03h, and 06h. NOTE: Accumulation is currently hardcoded to 01h.
# The verification uses MET/pcp-combine to sum 01h files into desired accumulations.
#
#-----------------------------------------------------------------------
#

# Top-level CCPA directory
ccpa_dir=${OBS_DIR}/..
if [[ ! -d "$ccpa_dir" ]]; then
  mkdir_vrfy -p $ccpa_dir
fi

# CCPA data from HPSS
ccpa_raw=$ccpa_dir/raw
if [[ ! -d "$ccpa_raw" ]]; then
  mkdir_vrfy -p $ccpa_raw
fi

# Reorganized CCPA location
ccpa_proc=$ccpa_dir/proc
if [[ ! -d "$ccpa_proc" ]]; then
  mkdir_vrfy -p $ccpa_proc
fi

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

  # Calculate valid date info using date utility  
  vdate=`$DATE_UTIL -d ${unix_init_DATE} ${current_fcst} hours +%Y%m%d%H`
  vyyyymmdd=`echo ${vdate} | cut -c1-8`
  vhh=`echo ${vdate} | cut -c9-10`

  # Calculate valid date + 1 day; this is needed because (for some ungodly reason) CCPA files for 19-23z
  # are stored in the *next* day's 00h directory
  vdate_p1=`$DATE_UTIL -d ${unix_init_DATE} ${current_fcst} hours 1 day +%Y%m%d%H`
  vyyyymmdd_p1=`echo ${vdate_p1} | cut -c1-8`

  #remove leading zero from vhh because bash treats numbers with leading zeros as octal *sigh*
  vhh_noZero=$((10#${vhh}))

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

  # Check if file exists on disk; if not, pull it.
  ccpa_file="$ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2"
  echo "CCPA FILE:${ccpa_file}"
  if [[ ! -f "${ccpa_file}" ]]; then 
      # Check if valid hour is 00
      if [[ ${vhh_noZero} -ge 19 && ${vhh_noZero} -le 23 ]]; then
        # Pull CCPA data from HPSS
        cmd="
        python3 -u ${USHdir}/retrieve_data.py \
          --debug \
          --file_set obs \
          --config ${PARMdir}/data_locations.yml \
          --cycle_date ${vyyyymmdd}${vhh} \
          --data_stores ${data_stores} \
          --data_type CCPA_obs \
          --output_path $ccpa_raw/${vyyyymmdd_p1} \
          --summary_file ${EXTRN_DEFNS} \
          --file_templates ${template_arr[@]} \
          $additional_flags"

        echo "CALLING: ${cmd}"
        $cmd || print_err_msg_exit "\
        Call to retrieve_data.py failed with a non-zero exit status.

        The command was:
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
          --data_stores ${data_stores} \
          --data_type CCPA_obs \
          --output_path $ccpa_raw/${vyyyymmdd} \
          --summary_file ${EXTRN_DEFNS} \
          --file_templates ${template_arr[@]} \
          $additional_flags"

        echo "CALLING: ${cmd}"
        $cmd || print_err_msg_exit "\
        Call to retrieve_data.py failed with a non-zero exit status.

        The command was:
        ${cmd}
"
      fi

      # One hour CCPA files have incorrect metadata in the files under the "00" directory from 20180718 to 20210504.
      # After data is pulled, reorganize into correct valid yyyymmdd structure.
      if [[ ${vhh_noZero} -ge 1 && ${vhh_noZero} -le 6 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/06/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 7 && ${vhh_noZero} -le 12 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/12/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 13 && ${vhh_noZero} -le 18 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/18/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -ge 19 && ${vhh_noZero} -le 23 ]]; then
        if [[ ${vyyyymmdd} -ge 20180718 && ${vyyyymmdd} -le 20210504 ]]; then
          wgrib2 $ccpa_raw/${vyyyymmdd_p1}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -set_date -24hr -grib $ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -s
        else
          cp_vrfy $ccpa_raw/${vyyyymmdd_p1}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
        fi
      elif [[ ${vhh_noZero} -eq 0 ]]; then
        # One hour CCPA files on HPSS have incorrect metadata in the files under the "00" directory from 20180718 to 20210504.
        if [[ ${vyyyymmdd} -ge 20180718 && ${vyyyymmdd} -le 20210504 ]]; then
          wgrib2 $ccpa_raw/${vyyyymmdd}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -set_date -24hr -grib $ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -s
        else
          cp_vrfy $ccpa_raw/${vyyyymmdd}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
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

