#!/bin/bash

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
# Move to the FIRE EMISSION working directory
#
#-----------------------------------------------------------------------
#
DATA="${DATA}/tmp_FIRE_EMISSION"
rm_vrfy -rf $DATA
mkdir_vrfy -p "$DATA"
cd_vrfy $DATA
#
#-----------------------------------------------------------------------
#
# Set up variables for call to retrieve_data.py
#
#-----------------------------------------------------------------------
#
yyyymmdd=${FIRE_FILE_CDATE:0:8}
hh=${FIRE_FILE_CDATE:8:2}

CDATE_md1=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC - 24 hours" "+%Y%m%d%H" )
CDATE_mh3=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC - 3 hours" "+%Y%m%d%H" )
yyyymmdd_mh3=${CDATE_mh3:0:8}
hh_mh3=${CDATE_mh3:8:2}
CDATE_mh2=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC - 2 hours" "+%Y%m%d%H" )
CDATE_mh1=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC - 1 hours" "+%Y%m%d%H" )

#
#-----------------------------------------------------------------------
#
# Retrieve fire file to FIRE_EMISSION_STAGING_DIR
#
#-----------------------------------------------------------------------
#
aqm_fire_file_fn="${AQM_FIRE_FILE_PREFIX}_${yyyymmdd}_t${hh}z${AQM_FIRE_FILE_SUFFIX}"

# Check if the fire file exists in the designated directory
if [ -e "${AQM_FIRE_DIR}/${yyyymmdd}/${aqm_fire_file_fn}" ]; then
  cp_vrfy "${AQM_FIRE_DIR}/${yyyymmdd}/${aqm_fire_file_fn}" "${FIRE_EMISSION_STAGING_DIR}"
else
  # Copy raw data 
  for ihr in {0..21}; do
    download_time=$( $DATE_UTIL --utc --date "${yyyymmdd_mh3} ${hh_mh3} UTC - $ihr hours" "+%Y%m%d%H" )
    FILE_13km="Hourly_Emissions_13km_${download_time}00_${download_time}00.nc"
    if [ -e "${AQM_FIRE_DIR}/RAVE_raw_new/${FILE_13km}" ]; then
      ln_vrfy -sf "${AQM_FIRE_DIR}/RAVE_raw_new/Hourly_Emissions_13km_${download_time}00_${download_time}00.nc" .
    elif [ -d "${AQM_FIRE_DIR}/${CDATE_md1}" ]; then
      echo "${FILE_13km} does not exist. Replacing with the file of previous date ..."
      yyyymmdd_dn=${download_time:0:8}
      hh_dn=${download_time:8:2}
      missing_download_time=$( $DATE_UTIL --utc --date "${yyyymmdd_dn} ${hh_dn} UTC - 24 hours" "+%Y%m%d%H" )
      ln_vrfy -sf "${AQM_FIRE_DIR}/${CDATE_md1}/Hourly_Emissions_13km_${missing_download_time}00_${missing_download_time}00.nc" "Hourly_Emissions_13km_${download_time}00_${download_time}00.nc"
    else
      print_err_msg_exit "RAVE raw data files do not exist."
    fi
  done  

  ncks -O -h --mk_rec_dmn time Hourly_Emissions_13km_${download_time}00_${download_time}00.nc temp.nc || print_err_msg_exit "\
Call to NCKS returned with nonzero exit code." 

  mv_vrfy temp.nc Hourly_Emissions_13km_${download_time}00_${download_time}00.nc

  # Extra times
  cp_vrfy Hourly_Emissions_13km_${CDATE_mh3}00_${CDATE_mh3}00.nc Hourly_Emissions_13km_${CDATE_mh2}00_${CDATE_mh2}00.nc
  cp_vrfy Hourly_Emissions_13km_${CDATE_mh3}00_${CDATE_mh3}00.nc Hourly_Emissions_13km_${CDATE_mh1}00_${CDATE_mh1}00.nc

  ncrcat -h Hourly_Emissions_13km_*.nc Hourly_Emissions_13km_${yyyymmdd}0000_${yyyymmdd}2300.t${cyc}z.nc || print_err_msg_exit "\
Call to NCRCAT returned with nonzero exit code."

  input_fire="${DATA}/Hourly_Emissions_13km_${yyyymmdd}0000_${yyyymmdd}2300.t${cyc}z.nc"
  output_fire="${DATA}/Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_new24.t${cyc}z.nc"

  python3 ${HOMEdir}/sorc/AQM-utils/python_utils/RAVE_remake.allspecies.aqmna13km.g793.py --date "${yyyymmdd}" --cyc "${hh}" --input_fire "${input_fire}" --output_fire "${output_fire}"

  ncks --mk_rec_dmn Time Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_new24.t${cyc}z.nc -o Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc || print_err_msg_exit "\
Call to NCKS returned with nonzero exit code."

  ncrcat Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc Hourly_Emissions_regrid_NA_13km_${yyyymmdd}_t${cyc}z_h24.nc ${aqm_fire_file_fn} || print_err_msg_exit "\
Call to NCRCAT returned with nonzero exit code."

  # Copy the final fire emission file to STAGING_DIR 
  cp_vrfy "${DATA}/${aqm_fire_file_fn}" "${FIRE_EMISSION_STAGING_DIR}"

  # Archive the final fire emission file to disk and HPSS
  if [ "${DO_AQM_SAVE_FIRE}" = "TRUE" ]; then
    mkdir -p "${AQM_FIRE_DIR}/${yyyymmdd}"
    cp_vrfy "${DATA}/${aqm_fire_file_fn}" "${AQM_FIRE_DIR}/${yyyymmdd}"

    hsi_log_fn="log.hsi_put.${yyyymmdd}_${hh}"
    hsi put ${aqm_fire_file_fn} : ${AQM_FIRE_ARCHV_DIR}/${aqm_fire_file_fn} >& ${hsi_log_fn} || \
  print_err_msg_exit "\
htar file writing operation (\"hsi put ...\") failed.  Check the log 
file hsi_log_fn in the DATA directory for details:
  DATA = \"${DATA}\"
  hsi_log_fn = \"${hsi_log_fn}\""
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
