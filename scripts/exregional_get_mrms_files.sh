#!/bin/sh

# This script pulls MRMS data from the NOAA HPSS
# Top-level MRMS directory
mrms_dir=${OBS_DIR}/..
if [[ ! -d "$mrms_dir" ]]; then
  mkdir -p $mrms_dir
fi

# MRMS data from HPSS
mrms_raw=$mrms_dir/raw
if [[ ! -d "$mrms_raw" ]]; then
  mkdir -p $mrms_raw
fi

# Reorganized MRMS location
mrms_proc=$mrms_dir/proc
if [[ ! -d "$mrms_proc" ]]; then
  mkdir -p $mrms_proc
fi

# Initialization
yyyymmdd=${CDATE:0:8}
hh=${CDATE:8:2}
cyc=$hh

start_valid=${CDATE}${hh}

fhr_last=`echo ${FHR}  | awk '{ print $NF }'`

# Forecast length
fcst_length=${fhr_last}

s_yyyy=`echo ${start_valid} | cut -c1-4`  # year (YYYY) of start time
s_mm=`echo ${start_valid} | cut -c5-6`    # month (MM) of start time
s_dd=`echo ${start_valid} | cut -c7-8`    # day (DD) of start time
s_hh=`echo ${start_valid} | cut -c9-10`   # hour (HH) of start time
start_valid_ut=`date -ud ''${s_yyyy}-${s_mm}-${s_dd}' UTC '${s_hh}':00:00' +%s` # convert start time to universal time

end_fcst_sec=`expr ${fcst_length} \* 3600` # convert last forecast lead hour to seconds
end_valid_ut=`expr ${start_valid_ut} + ${end_fcst_sec}` # calculate current forecast time in universal time

cur_ut=${start_valid_ut}
current_fcst=0
fcst_sec=`expr ${current_fcst} \* 3600` # convert forecast lead hour to seconds

while [[ ${cur_ut} -le ${end_valid_ut} ]]; do
  cur_time=`date -ud '1970-01-01 UTC '${cur_ut}' seconds' +%Y%m%d%H` # convert universal time to standard time
  echo "cur_time=${cur_time}"

  # Calculate valid date info
  vyyyy=`echo ${cur_time} | cut -c1-4`  # year (YYYY) of time
  vmm=`echo ${cur_time} | cut -c5-6`    # month (MM) of time
  vdd=`echo ${cur_time} | cut -c7-8`    # day (DD) of time
  vhh=`echo ${cur_time} | cut -c9-10`   # hour (HH) of time
  vyyyymmdd=`echo ${cur_time} | cut -c1-8`    # YYYYMMDD of time
  vinit_ut=`date -ud ''${vyyyy}-${vmm}-${vdd}' UTC '${vhh}':00:00' +%s` # convert time to universal time

  # Create necessary raw and proc directories
  if [[ ! -d "$mrms_raw/${vyyyymmdd}" ]]; then
    mkdir -p $mrms_raw/${vyyyymmdd}
  fi

  # Check if file exists on disk; if not, pull it.
  mrms_file="$mrms_proc/${vyyyymmdd}/MergedReflectivityQComposite_00.00_${vyyyy}${vmm}${vdd}-${vhh}0000.grib2"
  echo "MRMS FILE:${mrms_file}"

  if [[ ! -f "${mrms_file}" ]]; then
    cd $mrms_raw/${vyyyymmdd}

    # Name of MRMS tar file on HPSS is dependent on date. Logic accounts for files from 2019 until Sept. 2020.
    if [[ ${vyyyymmdd} -ge 20190101 && ${vyyyymmdd} -lt 20200303 ]]; then
      CheckFile=`hsi "ls -1 /NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/ldmdata.gyre.${vyyyy}${vmm}${vdd}.tar" >& /dev/null`
      Status=$?
      if [[ ${Status} == 0 ]]; then
        TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/ldmdata.gyre.${vyyyy}${vmm}${vdd}.tar"
      else
        CheckFile=`hsi "ls -1 /NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/ldmdata.tide.${vyyyy}${vmm}${vdd}.tar" >& /dev/null`   
        Status=$?
        if [[ ${Status} == 0 ]]; then
          TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/ldmdata.tide.${vyyyy}${vmm}${vdd}.tar" 
        else
          echo "ERROR: MRMS data not available for ${vyyyy}${vmm}${vdd}!"
          exit 
        fi
      fi
    fi 

    if [[ ${vyyyymmdd} -ge 20200303 ]]; then
      TarFile="/NCEPPROD/hpssprod/runhistory/rh${vyyyy}/${vyyyy}${vmm}/${vyyyy}${vmm}${vdd}/dcom_prod_ldmdata_obs.tar"
    fi

    echo "TAR FILE:${TarFile}"

    TarCommand="htar -xvf ${TarFile} \`htar -tf ${TarFile} | egrep \"MergedReflectivityQComposite_00.00_${vyyyy}${vmm}${vdd}-[0-9][0-9][0-9][0-9][0-9][0-9].grib2.gz\" | awk '{print $7}'\`"
    htar -xvf ${TarFile} `htar -tf ${TarFile} | egrep "MergedReflectivityQComposite_00.00_${vyyyy}${vmm}${vdd}-[0-9][0-9][0-9][0-9][0-9][0-9].grib2.gz" | awk '{print $7}'`
    Status=$?

    if [[ ${Status} != 0 ]]; then
      echo "WARNING: Bad return status (${Status}) for date \"${CurDate}\".  Did you forget to run \"module load hpss\"?"
      echo "WARNING: ${TarCommand}"
    else
      if [[ ! -d "$mrms_proc/${vyyyymmdd}" ]]; then
        mkdir -p $mrms_proc/${vyyyymmdd}
      fi
	
      hour=0
      while [[ ${hour} -le 23 ]]; do
        echo "hour=${hour}"
        python ${SCRIPTSDIR}/mrms_pull_topofhour.py ${vyyyy}${vmm}${vdd}${hour} ${mrms_proc} ${mrms_raw}
      hour=$((${hour} + 1)) # hourly increment
      done
    fi

  else
    # Check if file exists on disk; if not, pull it.
    mrms_file="$mrms_proc/${vyyyymmdd}/MergedReflectivityQComposite_00.00_${vyyyy}${vmm}${vdd}-${vhh}0000.grib2"

    if [[ ! -f "${mrms_file}" ]]; then
      cd $mrms_raw/${vyyyymmdd}

      python ${SCRIPTSDIR}/mrms_pull_topofhour.py ${vyyyy}${vmm}${vdd}${vhh} ${mrms_proc} ${mrms_raw}
    fi
  fi

  # Increment
  current_fcst=$((${current_fcst} + 1)) # hourly increment
  fcst_sec=`expr ${current_fcst} \* 3600` # convert forecast lead hour to seconds
  cur_ut=`expr ${start_valid_ut} + ${fcst_sec}`
  
done
