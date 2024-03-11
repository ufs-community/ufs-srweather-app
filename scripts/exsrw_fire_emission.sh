#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm|task_fire_emission" ${GLOBAL_VAR_DEFNS_FP}
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

CDATE_mh1=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC - 1 hours" "+%Y%m%d%H" )

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
  cp_vrfy "${DCOMINfire}/${aqm_fire_file_fn}" "${FIRE_EMISSION_STAGING_DIR}"
else
  # Copy raw data 
  for ihr in {0..23}; do
    download_time=$( $DATE_UTIL --utc --date "${yyyymmdd_mh1} ${hh_mh1} UTC - $ihr hours" "+%Y%m%d%H" )
    FILE_13km="Hourly_Emissions_13km_${download_time}00_${download_time}00.nc"
    yyyymmdd_dn=${download_time:0:8}
    hh_dn=${download_time:8:2}
    missing_download_time=$( $DATE_UTIL --utc --date "${yyyymmdd_dn} ${hh_dn} UTC - 24 hours" "+%Y%m%d%H" )
    yyyymmdd_dn_md1=${missing_download_time:0:8}
    FILE_13km_md1=Hourly_Emissions_13km_${missing_download_time}00_${missing_download_time}00.nc
    if [ -e "${DCOMINfire}/${yyyymmdd_dn}/rave/${FILE_13km}" ]; then
      cp_vrfy "${DCOMINfire}/${yyyymmdd_dn}/rave/${FILE_13km}" .
    elif [ -e "${DCOMINfire}/${yyyymmdd_dn_md1}/rave/${FILE_13km_md1}" ]; then
      echo "WARNING: ${FILE_13km} does not exist. Replacing with the file of previous date ..."
      cp_vrfy "${DCOMINfire}/${yyyymmdd_dn_md1}/rave/${FILE_13km_md1}" "${FILE_13km}"
    else
      message_txt="Fire Emission RAW data does not exist:
  FILE_13km_md1 = \"${FILE_13km_md1}\"
  DCOMINfire = \"${DCOMINfire}\""

      if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
        cp_vrfy "${DCOMINfire}/Hourly_Emissions_13km_dummy.nc" "${FILE_13km}"
        message_warning="WARNING: ${message_txt}. Replacing with the dummy file :: AQM RUN SOFT FAILED."
        print_info_msg "${message_warning}"
        if [ ! -z "${maillist}" ]; then
          echo "${message_warning}" | mail.py $maillist
        fi
      else
        print_err_msg_exit "${message_txt}"
      fi
    fi
  done  

  ncks -O -h --mk_rec_dmn time Hourly_Emissions_13km_${download_time}00_${download_time}00.nc temp.nc
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to NCKS returned with nonzero exit code."
    if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
      err_exit "${message_txt}"
    else
      print_err_msg_exit "${message_txt}"
    fi
  fi

  mv_vrfy temp.nc Hourly_Emissions_13km_${download_time}00_${download_time}00.nc

  ncrcat -h Hourly_Emissions_13km_*.nc Hourly_Emissions_13km_${yyyymmdd}0000_${yyyymmdd}2300.t${cyc}z.nc
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to NCRCAT returned with nonzero exit code."
    if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
      err_exit "${message_txt}"
    else
      print_err_msg_exit "${message_txt}"
    fi
  fi

  input_fire="${DATA}/Hourly_Emissions_13km_${yyyymmdd}0000_${yyyymmdd}2300.t${cyc}z.nc"
  output_fire="${DATA}/Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_new24.t${cyc}z.nc"

  python3 ${HOMEdir}/sorc/AQM-utils/python_utils/RAVE_remake.allspecies.aqmna13km.g793.py --date "${yyyymmdd}" --cyc "${hh}" --input_fire "${input_fire}" --output_fire "${output_fire}"
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to python script \"RAVE_remake.allspecies.py\" returned with nonzero exit code."
    if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
      err_exit "${message_txt}"
    else
      print_err_msg_exit "${message_txt}"
    fi
  fi

  ncks --mk_rec_dmn Time Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_new24.t${cyc}z.nc -o Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to NCKS returned with nonzero exit code."
    if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
      err_exit "${message_txt}"
    else
      print_err_msg_exit "${message_txt}"
    fi
  fi

  ncrcat Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc ${aqm_fire_file_fn}
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to NCRCAT returned with nonzero exit code."
    if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
      err_exit "${message_txt}"
    else
      print_err_msg_exit "${message_txt}"
    fi
  fi

  # Copy the final fire emission file to STAGING_DIR 
  cp_vrfy "${DATA}/${aqm_fire_file_fn}" "${FIRE_EMISSION_STAGING_DIR}"

  # Archive the final fire emission file to disk and HPSS
  if [ "${DO_AQM_SAVE_FIRE}" = "TRUE" ]; then
    cp "${DATA}/${aqm_fire_file_fn}" ${DCOMINfire}

    hsi_log_fn="log.hsi_put.${yyyymmdd}_${hh}"
    hsi put ${aqm_fire_file_fn} : ${AQM_FIRE_ARCHV_DIR}/${aqm_fire_file_fn} >& ${hsi_log_fn}
    export err=$?
    if [ $err -ne 0 ]; then
      message_txt="htar file writing operation (\"hsi put ...\") failed. Check the log 
file hsi_log_fn in the DATA directory for details:
  DATA = \"${DATA}\"
  hsi_log_fn = \"${hsi_log_fn}\""
      if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
        err_exit "${message_txt}"
      else
        print_err_msg_exit "${message_txt}"
      fi
    fi
  fi
fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
