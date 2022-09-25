#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHdir/source_util_funcs.sh
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
# This script reorganizes the NDAS data into a more intuitive structure:
# A valid YYYYMMDD directory is created, and all files for the valid day are placed within the directory.
#
#-----------------------------------------------------------------------
#

# Top-level NDAS directory
ndas_dir=${OBS_DIR}/..
if [[ ! -d "$ndas_dir" ]]; then
  mkdir_vrfy -p $ndas_dir
fi

# NDAS data from HPSS
ndas_raw=$ndas_dir/raw
if [[ ! -d "$ndas_raw" ]]; then
  mkdir_vrfy -p $ndas_raw
fi

# Reorganized NDAS location
ndas_proc=$ndas_dir/proc
if [[ ! -d "$ndas_proc" ]]; then
  mkdir_vrfy -p $ndas_proc
fi

# Initialization
yyyymmdd=${PDY}
hh=${cyc}

init=${CDATE}${hh}

# Forecast length
fhr_last=`echo ${FHR}  | awk '{ print $NF }'`

fcst_length=${fhr_last}

current_fcst=00
while [[ ${current_fcst} -le ${fcst_length} ]]; do
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

echo "yyyy mm dd hh= $yyyy $mm $dd $hh"
echo "vyyyy vmm vdd vhh= $vyyyy $vmm $vdd $vhh"

  vdate_ut_m1h=`expr ${vdate_ut} - 3600` # calculate current forecast time in universal time
  vdate_m1h=`$DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut_m1h}' seconds' +%Y%m%d%H` # convert universal time to standard time
  vyyyymmdd_m1h=`echo ${vdate_m1h} | cut -c1-8`  # forecast time (YYYYMMDD)
  vyyyy_m1h=`echo ${vdate_m1h} | cut -c1-4`  # year (YYYY) of valid time
  vmm_m1h=`echo ${vdate_m1h} | cut -c5-6`    # month (MM) of valid time
  vdd_m1h=`echo ${vdate_m1h} | cut -c7-8`    # day (DD) of valid time
  vhh_m1h=`echo ${vdate_m1h} | cut -c9-10`       # forecast hour (HH)

  vdate_ut_m2h=`expr ${vdate_ut} - 7200` # calculate current forecast time in universal time
  vdate_m2h=`$DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut_m2h}' seconds' +%Y%m%d%H` # convert universal time to standard time
  vyyyymmdd_m2h=`echo ${vdate_m2h} | cut -c1-8`  # forecast time (YYYYMMDD)
  vyyyy_m2h=`echo ${vdate_m2h} | cut -c1-4`  # year (YYYY) of valid time
  vmm_m2h=`echo ${vdate_m2h} | cut -c5-6`    # month (MM) of valid time
  vdd_m2h=`echo ${vdate_m2h} | cut -c7-8`    # day (DD) of valid time
  vhh_m2h=`echo ${vdate_m2h} | cut -c9-10`       # forecast hour (HH)

  vdate_ut_m3h=`expr ${vdate_ut} - 10800` # calculate current forecast time in universal time
  vdate_m3h=`$DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut_m3h}' seconds' +%Y%m%d%H` # convert universal time to standard time
  vyyyymmdd_m3h=`echo ${vdate_m3h} | cut -c1-8`  # forecast time (YYYYMMDD)
  vyyyy_m3h=`echo ${vdate_m3h} | cut -c1-4`  # year (YYYY) of valid time
  vmm_m3h=`echo ${vdate_m3h} | cut -c5-6`    # month (MM) of valid time
  vdd_m3h=`echo ${vdate_m3h} | cut -c7-8`    # day (DD) of valid time
  vhh_m3h=`echo ${vdate_m3h} | cut -c9-10`       # forecast hour (HH)

  vdate_ut_m4h=`expr ${vdate_ut} - 14400` # calculate current forecast time in universal time
  vdate_m4h=`$DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut_m4h}' seconds' +%Y%m%d%H` # convert universal time to standard time
  vyyyymmdd_m4h=`echo ${vdate_m4h} | cut -c1-8`  # forecast time (YYYYMMDD)
  vyyyy_m4h=`echo ${vdate_m4h} | cut -c1-4`  # year (YYYY) of valid time
  vmm_m4h=`echo ${vdate_m4h} | cut -c5-6`    # month (MM) of valid time
  vdd_m4h=`echo ${vdate_m4h} | cut -c7-8`    # day (DD) of valid time
  vhh_m4h=`echo ${vdate_m4h} | cut -c9-10`       # forecast hour (HH)

  vdate_ut_m5h=`expr ${vdate_ut} - 18000` # calculate current forecast time in universal time
  vdate_m5h=`$DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut_m5h}' seconds' +%Y%m%d%H` # convert universal time to standard time
  vyyyymmdd_m5h=`echo ${vdate_m5h} | cut -c1-8`  # forecast time (YYYYMMDD)
  vyyyy_m5h=`echo ${vdate_m5h} | cut -c1-4`  # year (YYYY) of valid time
  vmm_m5h=`echo ${vdate_m5h} | cut -c5-6`    # month (MM) of valid time
  vdd_m5h=`echo ${vdate_m5h} | cut -c7-8`    # day (DD) of valid time
  vhh_m5h=`echo ${vdate_m5h} | cut -c9-10`       # forecast hour (HH)

  vhh_noZero=$(expr ${vhh} + 0)

echo "vyyyymmdd_m1h vhh_m1h=$vyyyymmdd_m1h $vhh_m1h"
echo "vhh_noZero=$vhh_noZero"

  # Check if file exists on disk
  ndas_file="$ndas_proc/prepbufr.ndas.${vyyyymmdd}${vhh}"
  echo "NDAS PB FILE:${ndas_file}"

  if [[ ! -f "${ndas_file}" ]]; then 
    if [[ ! -d "$ndas_raw/${vyyyymmdd}${vhh}" ]]; then
      mkdir_vrfy -p $ndas_raw/${vyyyymmdd}${vhh}
    fi      
    cd_vrfy $ndas_raw/${vyyyymmdd}${vhh}

    # Name of NDAS tar file on HPSS is dependent on date. Logic accounts for files from 2019 until July 2020.
    if [[ ${vyyyymmdd} -ge 20190101 && ${vyyyymmdd} -le 20190820 ]]; then
      TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/com2_nam_prod_nam.${vyyyy}${vmm}${vdd}${vhh}.bufr.tar"
      TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"prepbufr.tm[0-9][0-9].nr\" | awk '{print $7}'\`" 
      echo "CALLING: ${TarCommand}"
      htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "prepbufr.tm[0-9][0-9].nr" | awk '{print $7}'`
    elif [[ ${vyyyymmdd} -ge 20190821 && ${vyyyymmdd} -le 20200226 ]]; then
      TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/gpfs_dell1_nco_ops_com_nam_prod_nam.${vyyyy}${vmm}${vdd}${vhh}.bufr.tar"
      TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"prepbufr.tm[0-9][0-9].nr\" | awk '{print $7}'\`"
      echo "CALLING: ${TarCommand}"
      htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "prepbufr.tm[0-9][0-9].nr" | awk '{print $7}'`
    else
      TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/com_nam_prod_nam.${vyyyy}${vmm}${vdd}${vhh}.bufr.tar"
      TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"prepbufr.tm[0-9][0-9].nr\" | awk '{print $7}'\`"
      echo "CALLING: ${TarCommand}"
      htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "prepbufr.tm[0-9][0-9].nr" | awk '{print $7}'`
    fi

    if [[ ! -d "$ndas_proc" ]]; then
      mkdir_vrfy -p $ndas_proc
    fi 
 
    if [[ ${vhh_noZero} -eq 0 || ${vhh} -eq 6 || ${vhh} -eq 12 || ${vhh} -eq 18 ]]; then
      #echo "$ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm00.nr $ndas_proc/prepbufr.ndas.${vyyyymmdd}${vhh}"
      cp_vrfy $ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm00.nr $ndas_proc/prepbufr.ndas.${vyyyymmdd}${vhh}
      cp_vrfy $ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm01.nr $ndas_proc/prepbufr.ndas.${vyyyymmdd_m1h}${vhh_m1h}
      cp_vrfy $ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm02.nr $ndas_proc/prepbufr.ndas.${vyyyymmdd_m2h}${vhh_m2h}
      cp_vrfy $ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm03.nr $ndas_proc/prepbufr.ndas.${vyyyymmdd_m3h}${vhh_m3h}
      cp_vrfy $ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm04.nr $ndas_proc/prepbufr.ndas.${vyyyymmdd_m4h}${vhh_m4h}
      cp_vrfy $ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm05.nr $ndas_proc/prepbufr.ndas.${vyyyymmdd_m5h}${vhh_m5h}
    fi
  fi
  current_fcst=$((${current_fcst} + 6))
  echo "new fcst=${current_fcst}"

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

