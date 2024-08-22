#!/bin/bash

set -x

msg="JOB $job HAS BEGUN"
postmsg "$msg"
   
export pgm=aqm_fire_emission

EMAIL_SDM=${EMAIL_SDM:-YES}

#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#

. $USHaqm/source_util_funcs.sh

source_config_for_task "cpl_aqm_parm|task_fire_emission" ${GLOBAL_VAR_DEFNS_FP}

#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHaqm/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that fetches fire emission
data files from disk or generates model-ready RAVE emission file from raw
data files.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set up variables for call to retrieve_data.py
#
#-----------------------------------------------------------------------
#
yyyymmdd=${FIRE_FILE_CDATE:0:8}
hh=${FIRE_FILE_CDATE:8:2}

CDATE_mh1=`$NDATE -1 ${yyyymmdd}${hh}`

yyyymmdd_mh1=${CDATE_mh1:0:8}
hh_mh1=${CDATE_mh1:8:2}
#
#-----------------------------------------------------------------------
#
# Retrieve fire file to FIRE_EMISSION_STAGING_DIR
#
#-----------------------------------------------------------------------
#
aqm_fire_file_fn="${AQM_FIRE_FILE_PREFIX}_${yyyymmdd}_t${hh}z${AQM_FIRE_FILE_SUFFIX}"

# Check if the fire file exists in the designated directory
if [ -e "${DCOMINfire}/${aqm_fire_file_fn}" ]; then
  cpreq "${DCOMINfire}/${aqm_fire_file_fn}" "${FIRE_EMISSION_STAGING_DIR}"
else
  # Copy raw data 
  for ihr in {0..23}; do
    download_time=`$NDATE -$ihr ${yyyymmdd_mh1}${hh_mh1}`
    FILE_curr=Hourly_Emissions_13km_${download_time}00_${download_time}00.nc
    FILE_13km=RAVE-HrlyEmiss-13km_v2r0_blend_s${download_time}00000_e${download_time}59590_c*.nc
    yyyymmdd_dn=${download_time:0:8}
    hh_dn=${download_time:8:2}
    missing_download_time=`$NDATE -24 ${yyyymmdd_dn}${hh_dn}`
    yyyymmdd_dn_md1=${missing_download_time:0:8}
    FILE_13km_md1=RAVE-HrlyEmiss-13km_v2r0_blend_s${missing_download_time}00000_e${missing_download_time}59590_c*.nc
    if ls ${DCOMINfire}/${yyyymmdd_dn}/rave/${FILE_13km} 1> /dev/null 2>&1; then
       if [ $(stat -c %s ${DCOMINfire}/${yyyymmdd_dn}/rave/${FILE_13km}) -gt 4000000 ]; then
           cpreq ${DCOMINfire}/${yyyymmdd_dn}/rave/${FILE_13km} ${FILE_curr}
       fi
    elif ls ${DCOMINfire}/${yyyymmdd_dn_md1}/rave/${FILE_13km_md1} 1> /dev/null 2>&1; then
       if [ $(stat -c %s ${DCOMINfire}/${yyyymmdd_dn_md1}/rave/${FILE_13km_md1}) -gt 4000000 ]; then
           echo "WARNING: ${FILE_13km} does not exist or is broken. Replacing with the file from the previous date..."
           cpreq ${DCOMINfire}/${yyyymmdd_dn_md1}/rave/${FILE_13km_md1} ${FILE_curr}
       fi
    else
      message_txt="WARNING Fire Emission RAW data does not exist or broken:
  FILE_13km_md1 = \"${FILE_13km_md1}\"
  DCOMINfire = \"${DCOMINfire}\""

        cpreq ${FIXaqmfire}/Hourly_Emissions_13km_dummy.nc ${FILE_curr}
        message_warning="WARNING: ${message_txt}. Replacing with the dummy file :: AQM RUN SOFT FAILED."
        print_info_msg "${message_warning}"
        if [ "${EMAIL_SDM^^}" = "YES" ] ; then
	  MAILFROM=${MAILFROM:-"nco.spa@noaa.gov"}
          MAILTO=${MAILTO:-"${maillist}"}
          subject="${cyc}Z ${RUN^^} Output for ${basinname:-} WILDFIRE EMIS "
          mail.py -s "${subject}" -v "${MAILTO}" 
	fi

    fi
  done  

  ncks -O -h --mk_rec_dmn time Hourly_Emissions_13km_${download_time}00_${download_time}00.nc temp.nc
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to NCKS returned with nonzero exit code."
      err_exit "${message_txt}"
  fi

  mv temp.nc Hourly_Emissions_13km_${download_time}00_${download_time}00.nc

  ncrcat -h Hourly_Emissions_13km_*.nc Hourly_Emissions_13km_${yyyymmdd}0000_${yyyymmdd}2300.t${cyc}z.nc
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to NCRCAT returned with nonzero exit code."
      err_exit "${message_txt}"
  fi

  input_fire="${DATA}/Hourly_Emissions_13km_${yyyymmdd}0000_${yyyymmdd}2300.t${cyc}z.nc"
  output_fire="${DATA}/Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_new24.t${cyc}z.nc"

  ${USHaqm}/aqm_utils_python/RAVE_remake.allspecies.aqmna13km.g793.py --date "${yyyymmdd}" --cyc "${hh}" --input_fire "${input_fire}" --output_fire "${output_fire}"
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to python script \"RAVE_remake.allspecies.py\" returned with nonzero exit code."
      err_exit "${message_txt}"
  fi

  ncks --mk_rec_dmn Time Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_new24.t${cyc}z.nc -o Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to NCKS returned with nonzero exit code."
      err_exit "${message_txt}"
  fi

  cpreq Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24_1.nc 
  cpreq Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24_2.nc

  ncrcat -O -D 2 Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24_1.nc Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24_2.nc ${aqm_fire_file_fn}

  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to NCRCAT returned with nonzero exit code."
      err_exit "${message_txt}"
  fi

  # Copy the final fire emission file to STAGING_DIR 
  cpreq "${DATA}/${aqm_fire_file_fn}" "${FIRE_EMISSION_STAGING_DIR}"

fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
