#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_save_restart|task_run_fcst" ${GLOBAL_VAR_DEFNS_FP}
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
This is the ex-script for the task that runs the post-processor (UPP) on
the output files corresponding to a specified forecast hour.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respectively)
# from CDATE.
#
#-----------------------------------------------------------------------
#
yyyymmdd=${CDATE:0:8}
hh=${CDATE:8:2}
cyc=$hh

save_time=$( date --utc --date "${yyyymmdd} ${hh} UTC + ${fhr} hours" "+%Y%m%d%H" )
save_yyyy=${save_time:0:4}
save_mm=${save_time:4:2}
save_dd=${save_time:6:2}
save_hh=${save_time:8:2}


# 
#-----------------------------------------------------------------------
#
# Let save the restart files if needed before run post.
# This part will copy or move restart files matching the forecast hour
# this post will process to the nwges directory. The nwges is used to 
# stage the restart files for a long time. 
#-----------------------------------------------------------------------
#
filelist="fv_core.res.nc coupler.res"
filelistn="fv_core.res.tile1.nc fv_srf_wnd.res.tile1.nc fv_tracer.res.tile1.nc phy_data.nc sfc_data.nc"
filelistcold="gfs_data.tile7.halo0.nc sfc_data.tile7.halo0.nc"
n_iolayouty=$(($IO_LAYOUT_Y-1))
list_iolayout=$(seq 0 $n_iolayouty)

restart_prefix=${save_yyyy}${save_mm}${save_dd}.${save_hh}0000
if [ ! -r ${OUTPUT_DIR}/INPUT/gfs_ctrl.nc ]; then
  cp_vrfy $DATA/INPUT/gfs_ctrl.nc ${OUTPUT_DIR}/INPUT/gfs_ctrl.nc
  if [ -r ${DATA}/INPUT/coupler.res ]; then  # warm start
    if [ "${IO_LAYOUT_Y}" == "1" ]; then
      for file in ${filelistn}; do
        cp_vrfy $DATA/INPUT/${file} ${OUTPUT_DIR}/INPUT/${file}
      done
    else
      for file in ${filelistn}; do
        for ii in ${list_iolayout}
        do
          iii=$(printf %4.4i $ii)
         cp_vrfy $DATA/INPUT/${file}.${iii} ${OUTPUT_DIR}/INPUT/${file}.${iii}
        done
      done
    fi
    for file in ${filelist}; do
      cp_vrfy $DATA/INPUT/${file} ${OUTPUT_DIR}/INPUT/${file}
    done
  else  # cold start
    for file in ${filelistcold}; do
      cp_vrfy $DATA/INPUT/${file} ${OUTPUT_DIR}/INPUT/${file}
    done
  fi
fi
if [ -r "$DATA/RESTART/${restart_prefix}.coupler.res" ]; then
  if [ "${IO_LAYOUT_Y}" == "1" ]; then
    for file in ${filelistn}; do
      mv_vrfy $DATA/RESTART/${restart_prefix}.${file} ${OUTPUT_DIR}/RESTART/${restart_prefix}.${file}
    done
  else
    for file in ${filelistn}; do
      for ii in ${list_iolayout}
      do
        iii=$(printf %4.4i $ii)
        mv_vrfy $DATA/RESTART/${restart_prefix}.${file}.${iii} ${OUTPUT_DIR}/RESTART/${restart_prefix}.${file}.${iii}
      done
    done
  fi
  for file in ${filelist}; do
    mv_vrfy $DATA/RESTART/${restart_prefix}.${file} ${OUTPUT_DIR}/RESTART/${restart_prefix}.${file}
  done
  echo " ${fhr} forecast from ${yyyymmdd}${hh} is ready " #> ${OUTPUT_DIR}/RESTART/restart_done_f${fhr}
else

  FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS}
  if [ ${CYCLE_TYPE} == "spinup" ]; then
    FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS_SPINUP}
  else
    num_fhrs=( "${#FCST_LEN_HRS_CYCLES[@]}" )
    ihh=`expr ${hh} + 0`
    if [ ${num_fhrs} -gt ${ihh} ]; then
       FCST_LEN_HRS_thiscycle=${FCST_LEN_HRS_CYCLES[${ihh}]}
    fi
  fi
  print_info_msg "$VERBOSE" " The forecast length for cycle (\"${hh}\") is
                 ( \"${FCST_LEN_HRS_thiscycle}\") "

  if [ -r "$DATA/RESTART/coupler.res" ] && ([ ${fhr} -eq ${FCST_LEN_HRS_thiscycle} ] || [ ${CYCLE_SUBTYPE} == "ensinit" ]) ; then
    if [ "${IO_LAYOUT_Y}" == "1" ]; then
      for file in ${filelistn}; do
        mv_vrfy $DATA/RESTART/${file} ${OUTPUT_DIR}/RESTART/${restart_prefix}.${file}
      done
    else
      for file in ${filelistn}; do
        for ii in ${list_iolayout}
        do
          iii=$(printf %4.4i $ii)
          mv_vrfy $DATA/RESTART/${file}.${iii} ${OUTPUT_DIR}/RESTART/${restart_prefix}.${file}.${iii}
        done
      done
    fi
    for file in ${filelist}; do
       mv_vrfy $DATA/RESTART/${file} ${OUTPUT_DIR}/RESTART/${restart_prefix}.${file}
    done
    echo " ${fhr} forecast from ${yyyymmdd}${hh} is ready " #> ${OUTPUT_DIR}/RESTART/restart_done_f${fhr}
  else
    echo "This forecast hour does not need to save restart: ${yyyymmdd}${hh}f${fhr}"
  fi
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
save restart for forecast hour $fhr completed successfully.
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
