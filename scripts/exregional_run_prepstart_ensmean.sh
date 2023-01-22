#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_prepstart" ${GLOBAL_VAR_DEFNS_FP}
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
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
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
This is the ex-script for the task that runs a analysis with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
START_DATE=$(echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')

YYYYMMDDHH=$(date +%Y%m%d%H -d "${START_DATE}")
JJJ=$(date +%j -d "${START_DATE}")

YYYY=${YYYYMMDDHH:0:4}
MM=${YYYYMMDDHH:4:2}
DD=${YYYYMMDDHH:6:2}
HH=${YYYYMMDDHH:8:2}
YYYYMMDD=${YYYYMMDDHH:0:8}
#
#-----------------------------------------------------------------------
#
# go to INPUT directory.
#
#-----------------------------------------------------------------------

cd_vrfy ${DATA}

#
#--------------------------------------------------------------------
#
# link the deterministic (control) member restart files as the ensemble mean
# to get the reference obs.input in the GSI observer run
#
#--------------------------------------------------------------------
#

fg_restart_dirname=fcst_fv3lam
fg_restart_dirname_spinup=fcst_fv3lam_spinup

YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${DA_CYCLE_INTERV} hours ago" )
bkpath=${ENSCTRL_NWGES_BASEDIR}/${YYYYMMDDHHmInterv}/${fg_restart_dirname}/RESTART  # cycling, use background from RESTART
bkpath_spinup=${ENSCTRL_NWGES_BASEDIR}/${YYYYMMDDHHmInterv}/${fg_restart_dirname_spinup}/RESTART  # cycling, use background from RESTART

#
#   the restart file from FV3 has a name like: ${YYYYMMDD}.${HH}0000.fv_core.res.tile1.nc
#

restart_prefix="${YYYYMMDD}.${HH}0000."
checkfile=${bkpath}/${restart_prefix}coupler.res
checkfile_spinup=${bkpath_spinup}/${restart_prefix}coupler.res
if [ -r "${checkfile}" ] ; then
  cp_vrfy -f ${checkfile} coupler.res
  ln_vrfy -snf ${bkpath}/${restart_prefix}fv_core.res.nc fv_core.res.nc
  ln_vrfy -snf ${bkpath}/${restart_prefix}fv_core.res.tile1.nc fv_core.res.tile1.nc
  ln_vrfy -snf ${bkpath}/${restart_prefix}fv_tracer.res.tile1.nc fv_tracer.res.tile1.nc
  ln_vrfy -snf ${bkpath}/${restart_prefix}sfc_data.nc sfc_data.nc
  ln_vrfy -snf ${bkpath}/${restart_prefix}fv_srf_wnd.res.tile1.nc fv_srf_wnd.res.tile1.nc
  ln_vrfy -snf ${bkpath}/${restart_prefix}phy_data.nc phy_data.nc
elif [ -r "${checkfile_spinup}" ] ; then
  cp_vrfy -f ${checkfile_spinup} coupler.res
  ln_vrfy -snf ${bkpath_spinup}/${restart_prefix}fv_core.res.nc fv_core.res.nc
  ln_vrfy -snf ${bkpath_spinup}/${restart_prefix}fv_core.res.tile1.nc fv_core.res.tile1.nc
  ln_vrfy -snf ${bkpath_spinup}/${restart_prefix}fv_tracer.res.tile1.nc fv_tracer.res.tile1.nc
  ln_vrfy -snf ${bkpath_spinup}/${restart_prefix}sfc_data.nc sfc_data.nc
  ln_vrfy -snf ${bkpath_spinup}/${restart_prefix}fv_srf_wnd.res.tile1.nc fv_srf_wnd.res.tile1.nc
  ln_vrfy -snf ${bkpath_spinup}/${restart_prefix}phy_data.nc phy_data.nc
else
  print_err_msg_exit "Error: cannot find deterministic (control) warm start files from : ${bkpath} or ${bkpath_spinup}"
fi

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Prepare start completed successfully!!!
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
