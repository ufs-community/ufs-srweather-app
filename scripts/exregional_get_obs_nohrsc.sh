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
# This script retrieves and organizes the NOHRSC data into a more intuitive structure:
# A valid YYYYMMDD directory is created, and all files for the valid day are placed within the directory.
# NOTE: Accumulation is currently hardcoded to 06h and 24h which are aavailable every 6 and 12 hour, respectively..
#
#-----------------------------------------------------------------------
#

set -x

# Top-level NOHRSC directory
nohrsc_dir=${OBS_DIR}/..
if [[ ! -d "$nohrsc_dir" ]]; then
  mkdir_vrfy -p $nohrsc_dir
fi

# NOHRSC data from HPSS
nohrsc_raw=$nohrsc_dir/raw
if [[ ! -d "$nohrsc_raw" ]]; then
  mkdir_vrfy -p $nohrsc_raw
fi

# Reorganized NOHRSC location
nohrsc_proc=$nohrsc_dir/proc
if [[ ! -d "$nohrsc_proc" ]]; then
  mkdir_vrfy -p $nohrsc_proc
fi

# Accumulation is for accumulation of NOHRSC data to pull (hardcoded to 06h, see note above.)
#accum=${ACCUM}
accum=06

# Initialization
yyyymmdd=${PDY}
hh=${cyc}

init=${CDATE}${hh}

fhr_last=`echo ${FHR}  | awk '{ print $NF }'`

# Forecast length
fcst_length=${fhr_last}

current_fcst=$accum
while [[ ${current_fcst} -le ${fcst_length} ]]; do
  # Calculate valid date info
  fcst_sec=`expr ${current_fcst} \* 3600` # convert forecast lead hour to seconds
  yyyy=`echo ${init} | cut -c1-4`  # year (YYYY) of initialization time
  mm=`echo ${init} | cut -c5-6`    # month (MM) of initialization time
  dd=`echo ${init} | cut -c7-8`    # day (DD) of initialization time
  hh=`echo ${init} | cut -c9-10`   # hour (HH) of initialization time
  init_ut=`$DATE_UTIL -ud ''${yyyy}-${mm}-${dd}' UTC '${hh}':00:00' +%s` # convert initialization time to universal time
  vdate_ut=`expr ${init_ut} + ${fcst_sec}` # calculate current forecast time in universal time
  vdate=`$DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut}' seconds' +%Y%m%d%H` # convert universal time to standard time
  vyyyymmdd=`echo ${vdate} | cut -c1-8`  # forecast time (YYYYMMDD)
  vyyyy=`echo ${vdate} | cut -c1-4`  # year (YYYY) of valid time
  vmm=`echo ${vdate} | cut -c5-6`    # month (MM) of valid time
  vdd=`echo ${vdate} | cut -c7-8`    # day (DD) of valid time
  vhh=`echo ${vdate} | cut -c9-10`       # forecast hour (HH)
  #vhh_noZero=$(( ${vhh} + 0)


  # Create necessary raw and prop directories
  if [[ ! -d "$nohrsc_raw/${vyyyymmdd}" ]]; then
    mkdir_vrfy -p $nohrsc_raw/${vyyyymmdd}
  fi

  if [[ ! -d "$nohrsc_proc/${vyyyymmdd}" ]]; then
    mkdir_vrfy -p $nohrsc_proc/${vyyyymmdd}
  fi

  # Name of NOHRSC tar file on HPSS is dependent on date. Logic accounts for files from 2019 until Sept. 2020.

  TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/dcom_prod_${vyyyy}${vmm}${vdd}.tar"

  # Check if file exists on disk; if not, pull it.
  #nohrsc_file="$nohrsc_proc/${vyyyymmdd}/nohrsc.t${vhh}z.${accum}h.hrap.conus.gb2"

  #nohrsc_file="$nohrsc_proc/${vyyyymmdd}/./wgrbbul/nohrsc_snowfall/sfav2_CONUS_${accum}h_${vyyyymmdd}${vhh}_grid184.grb2"
  accum_noZero=$(( 10#$accum + 0 ))
  nohrsc_file="$nohrsc_proc/${vyyyymmdd}/sfav2_CONUS_06h_${vyyyymmdd}${vhh}_grid184.grb2"
  echo "NOHRSC FILE:${nohrsc_file}"
  if [[ ! -f "${nohrsc_file}" ]]; then 

    if (( ${current_fcst} % 6 == 0 )) ; then
      cd_vrfy $nohrsc_raw/${vyyyymmdd}
      # Pull NOHRSC data from HPSS
      TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"sfav2_CONUS_6h_${vyyyymmdd}${vhh}_grid184.grb2\" | awk '{print \$7}'\`"
      echo "CALLING: ${TarCommand}"
      htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "sfav2_CONUS_6h_${vyyyymmdd}${vhh}_grid184.grb2" | awk '{print \$7}'`

      cp_vrfy $nohrsc_raw/${vyyyymmdd}/wgrbbul/nohrsc_snowfall/sfav2_CONUS_6h_${vyyyymmdd}${vhh}_grid184.grb2 $nohrsc_proc/${vyyyymmdd}/sfav2_CONUS_06h_${vyyyymmdd}${vhh}_grid184.grb2
    fi

    if (( ${current_fcst} % 12 == 0 )) && (( ${current_fcst} >= 24 )) ; then
      cd_vrfy $nohrsc_raw/${vyyyymmdd}
      # Pull NOHRSC data from HPSS
      TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"sfav2_CONUS_24h_${vyyyymmdd}${vhh}_grid184.grb2\" | awk '{print \$7}'\`"
      echo "CALLING: ${TarCommand}"
      htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "sfav2_CONUS_24h_${vyyyymmdd}${vhh}_grid184.grb2" | awk '{print \$7}'`

      cp_vrfy $nohrsc_raw/${vyyyymmdd}/wgrbbul/nohrsc_snowfall/sfav2_CONUS_24h_${vyyyymmdd}${vhh}_grid184.grb2 $nohrsc_proc/${vyyyymmdd}/sfav2_CONUS_24h_${vyyyymmdd}${vhh}_grid184.grb2
    fi
  fi
  
  # Increment to next forecast hour      
  current_fcst=$((${current_fcst} + 06))
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

