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

  vhh_noZero=$((10#${vhh}))

  # Calculate valid date + 1 day
  vdate_ut_p1=`expr ${vdate_ut} + 86400`
  vdate_p1=`$DATE_UTIL -ud '1970-01-01 UTC '${vdate_ut_p1}' seconds' +%Y%m%d%H`
  vyyyymmdd_p1=`echo ${vdate_p1} | cut -c1-8`
  vyyyy_p1=`echo ${vdate_p1} | cut -c1-4`
  vmm_p1=`echo ${vdate_p1} | cut -c5-6` 
  vdd_p1=`echo ${vdate_p1} | cut -c7-8`
  vhh_p1=`echo ${vdate_p1} | cut -c9-10`

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

  # Name of CCPA tar file on HPSS is dependent on date. Logic accounts for files from 2019 until Sept. 2020.
  if [[ ${vyyyymmdd} -ge 20190101 && ${vyyyymmdd} -lt 20190812 ]]; then
    TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/com2_ccpa_prod_ccpa.${vyyyy}${vmm}${vdd}.tar"
  fi

  if [[ ${vyyyymmdd_p1} -ge 20190101 && ${vyyyymmdd_p1} -lt 20190812 ]]; then
    TarFile_p1="/NCEPPROD/hpssprod/runhistory/rh${vyyyy_p1}/${vyyyy_p1}${vmm_p1}/${vyyyy_p1}${vmm_p1}${vdd_p1}/com2_ccpa_prod_ccpa.${vyyyy_p1}${vmm_p1}${vdd_p1}.tar"
  fi

  if [[ ${vyyyymmdd} -ge 20190812 && ${vyyyymmdd} -le 20200217 ]]; then
    TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/gpfs_dell1_nco_ops_com_ccpa_prod_ccpa.${vyyyy}${vmm}${vdd}.tar"
  fi

  if [[ ${vyyyymmdd_p1} -ge 20190812 && ${vyyyymmdd_p1} -le 20200217 ]]; then
    TarFile_p1="/NCEPPROD/hpssprod/runhistory/rh${vyyyy_p1}/${vyyyy_p1}${vmm_p1}/${vyyyy_p1}${vmm_p1}${vdd_p1}/gpfs_dell1_nco_ops_com_ccpa_prod_ccpa.${vyyyy_p1}${vmm_p1}${vdd_p1}.tar"
  fi

  if [[ ${vyyyymmdd} -gt 20200217 && ${vyyyymmdd} -le 20220618 ]]; then
    TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/com_ccpa_prod_ccpa.${vyyyy}${vmm}${vdd}.tar"
  fi

  if [[ ${vyyyymmdd_p1} -gt 20200217 && ${vyyyymmdd_p1} -le 20220618 ]]; then
    TarFile_p1="/NCEPPROD/hpssprod/runhistory/rh${vyyyy_p1}/${vyyyy_p1}${vmm_p1}/${vyyyy_p1}${vmm_p1}${vdd_p1}/com_ccpa_prod_ccpa.${vyyyy_p1}${vmm_p1}${vdd_p1}.tar"
  fi

  if [[ ${vyyyymmdd} -ge 20220619 ]]; then
    TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/com_ccpa_v4.2_ccpa.${vyyyy}${vmm}${vdd}.tar"
  fi

  if [[ ${vyyyymmdd_p1} -ge 20220619 ]]; then
    TarFile_p1="/NCEPPROD/hpssprod/runhistory/rh${vyyyy_p1}/${vyyyy_p1}${vmm_p1}/${vyyyy_p1}${vmm_p1}${vdd_p1}/com_ccpa_v4.2_ccpa.${vyyyy_p1}${vmm_p1}${vdd_p1}.tar"
  fi

  # Check if file exists on disk; if not, pull it.
  ccpa_file="$ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2"
  echo "CCPA FILE:${ccpa_file}"
  if [[ ! -f "${ccpa_file}" ]]; then 
    if [[ ${accum} == "01" ]]; then
      # Check if valid hour is 00
      if [[ ${vhh_noZero} -ge 19 && ${vhh_noZero} -le 23 ]]; then
        cd_vrfy $ccpa_raw/${vyyyymmdd_p1}
        # Pull CCPA data from HPSS
        TarCommand="htar -xvf ${TarFile_p1} \`htar -tf ${TarFile_p1} | egrep \"ccpa.t${vhh}z.${accum}h.hrap.conus.gb2\" | awk '{print \$7}'\`"
        echo "CALLING: ${TarCommand}"
        htar -xvf ${TarFile_p1} `htar -tf ${TarFile_p1} | egrep "ccpa.t${vhh}z.${accum}h.hrap.conus.gb2" | awk '{print \$7}'`
      else 
        cd_vrfy $ccpa_raw/${vyyyymmdd}
        # Pull CCPA data from HPSS
        TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"ccpa.t${vhh}z.${accum}h.hrap.conus.gb2\" | awk '{print \$7}'\`"
        echo "CALLING: ${TarCommand}"
        htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "ccpa.t${vhh}z.${accum}h.hrap.conus.gb2" | awk '{print \$7}'`
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
        if [[ ${vyyyymmdd} -ge 20180718 && ${vyyyymmdd} -le 20210504 ]]; then
          wgrib2 $ccpa_raw/${vyyyymmdd}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -set_date -24hr -grib $ccpa_proc/${vyyyymmdd}/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 -s
        else
          cp_vrfy $ccpa_raw/${vyyyymmdd}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
        fi
      fi

    elif [[ ${accum} == "03" ]]; then
      # Check if valid hour is 21
      if [[ ${vhh_noZero} -ne 21 ]]; then
        cd_vrfy $ccpa_raw/${vyyyymmdd}
        # Pull CCPA data from HPSS
        TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"ccpa.t${vhh}z.${accum}h.hrap.conus.gb2\" | awk '{print \$7}'\`" 
        echo "CALLING: ${TarCommand}"
        htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "ccpa.t${vhh}z.${accum}h.hrap.conus.gb2" | awk '{print \$7}'`
      elif [[ ${vhh_noZero} -eq 21 ]]; then
        cd_vrfy $ccpa_raw/${vyyyymmdd_p1}
        # Pull CCPA data from HPSS
        TarCommand="htar -xvf ${TarFile_p1} \`htar -tf ${TarFile_p1} | egrep \"ccpa.t${vhh}z.${accum}h.hrap.conus.gb2\" | awk '{print \$7}'\`"
        echo "CALLING: ${TarCommand}"
        htar -xvf ${TarFile_p1} `htar -tf ${TarFile_p1} | egrep "ccpa.t${vhh}z.${accum}h.hrap.conus.gb2" | awk '{print \$7}'`
      fi

      if [[ ${vhh_noZero} -eq 0 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -eq 3 || ${vhh_noZero} -eq 6 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/06/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -eq 9 || ${vhh_noZero} -eq 12 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/12/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -eq 15 || ${vhh_noZero} -eq 18 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/18/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -eq 21 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd_p1}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      fi

    elif [[ ${accum} == "06" ]]; then
      cd_vrfy $ccpa_raw/${vyyyymmdd}
      # Pull CCPA data from HPSS
      TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"ccpa.t${vhh}z.${accum}h.hrap.conus.gb2\" | awk '{print \$7}'\`"
      echo "CALLING: ${TarCommand}"
      htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "ccpa.t${vhh}z.${accum}h.hrap.conus.gb2" | awk '{print \$7}'`

      if [[ ${vhh_noZero} -eq 0 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/00/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -eq 6 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/06/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -eq 12 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/12/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      elif [[ ${vhh_noZero} -eq 18 ]]; then
        cp_vrfy $ccpa_raw/${vyyyymmdd}/18/ccpa.t${vhh}z.${accum}h.hrap.conus.gb2 $ccpa_proc/${vyyyymmdd}
      fi
    fi
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

