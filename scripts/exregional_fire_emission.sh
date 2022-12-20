#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that copies or fetches fire emission
data files from disk or HPSS.
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
#
#-----------------------------------------------------------------------
#
# Retrieve fire files to FIRE_EMISSION_STAGING_DIR
#
#-----------------------------------------------------------------------
#
aqm_fire_file_fn="${AQM_FIRE_FILE_PREFIX}_${yyyymmdd}_t${hh}z${AQM_FIRE_FILE_SUFFIX}"

# Check if the file exists in the designated directory
if [ -e "${AQM_FIRE_DIR}/${yyyymmdd}/${aqm_fire_file_fn}" ]; then
  cp_vrfy "${AQM_FIRE_DIR}/${yyyymmdd}/${aqm_fire_file_fn}" "${FIRE_EMISSION_STAGING_DIR}"
else
  # Retrieve files from HPSS
  arcv_dir="/NCEPDEV/emc-naqfc/2year/Kai.Wang/RAVE_fire/RAVE_NA"
  arcv_fp="${arcv_dir}/${aqm_fire_file_fn}"

  hsi_log_fn="log.hsi_get.${yyyymmdd}_${hh}"
  hsi get ${arcv_fp} >& ${hsi_log_fn} || \
  print_err_msg_exit "\
htar file reading operation (\"hsi get ...\") failed.  Check the log 
file hsi_log_fn in the staging directory (fire_emission_staging_dir) for 
details:
  fire_emission_staging_dir = \"${FIRE_EMISSION_STAGING_DIR}\"
  hsi_log_fn = \"${hsi_log_fn}\""
fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
