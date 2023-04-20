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
  fcst_sec=$(( ${current_fcst} * 3600 )) # convert forecast lead hour to seconds
  yyyy=${init:0:4}  # year (YYYY) of initialization time
  mm=${init:4:2}   # month (MM) of initialization time
  dd=${init:6:2}   # day (DD) of initialization time
  hh=${init:8:2}   # hour (HH) of initialization time
  init_ut=`$DATE_UTIL -ud ''${yyyy}-${mm}-${dd}' UTC '${hh}':00:00' +%s` # convert initialization time to universal time
  vdate_ut=$(( ${init_ut} + ${fcst_sec} )) # calculate current forecast time in universal time
  vdate=`$DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut}' seconds' +%Y%m%d%H` # convert universal time to standard time
  vyyyymmdd=${vdate:0:8}  # forecast time (YYYYMMDD)
  vyyyy=${vdate:0:4}  # year (YYYY) of valid time
  vmm=${vdate:4:2} # month (MM) of valid time
  vdd=${vdate:6:2} # day (DD) of valid time
  vhh=${vdate:8:2} # forecast hour (HH)
  vhh_noZero=$(( ${vhh} + 0 ))

echo "yyyy mm dd hh= $yyyy $mm $dd $hh"
echo "vyyyy vmm vdd vhh= $vyyyy $vmm $vdd $vhh"
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
    elif [[ ${vyyyymmdd} -gt 20200226 && ${vyyyymmdd} -le 20220627 ]]; then
      TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/com_nam_prod_nam.${vyyyy}${vmm}${vdd}${vhh}.bufr.tar"
      TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"prepbufr.tm[0-9][0-9].nr\" | awk '{print $7}'\`"
      echo "CALLING: ${TarCommand}"
      htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "prepbufr.tm[0-9][0-9].nr" | awk '{print $7}'`
    else
      TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/com_obsproc_v1.0_nam.${vyyyy}${vmm}${vdd}${vhh}.bufr.tar"
      TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"prepbufr.tm[0-9][0-9].nr\" | awk '{print $7}'\`"
      echo "CALLING: ${TarCommand}"
      htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "prepbufr.tm[0-9][0-9].nr" | awk '{print $7}'`
    fi

    if [[ ! -d "$ndas_proc" ]]; then
      mkdir_vrfy -p $ndas_proc
    fi 
 
    if [[ ${vhh_noZero} -eq 0 || ${vhh} -eq 6 || ${vhh} -eq 12 || ${vhh} -eq 18 ]]; then
      # copy files from the previous 6 hours
      for tm in $(seq 0 5); do
        vdate_ut_tm=$(( ${vdate_ut} - $tm  * 3600 )) 
        vdate_tm=$($DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut_tm}' seconds' +%Y%m%d%H)
        vyyyymmddhh_tm=${vdate_tm:0:10}
        tm2=$(echo $tm | awk '{printf "%02d\n", $0;}')

        cp_vrfy $ndas_raw/${vyyyymmdd}${vhh}/nam.t${vhh}z.prepbufr.tm${tm2}.nr $ndas_proc/prepbufr.ndas.${vyyyymmddhh_tm}
      done
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

