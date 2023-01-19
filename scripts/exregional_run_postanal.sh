#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_postanal|task_run_fcst" ${GLOBAL_VAR_DEFNS_FP}
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
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_POSTANAL}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_POSTANAL}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_POSTANAL}
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

nprocs=$((NNODES_RUN_POSTANAL*PPN_RUN_POSTANAL))

gridspec_dir=${NWGES_BASEDIR}/grid_spec
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
# go to working directory.
# define fix and background path
#
#-----------------------------------------------------------------------

cd_vrfy ${DATA}

fixgriddir=$FIXgsi/${PREDEF_GRID_NAME}
if [ ${CYCLE_TYPE} == "spinup" ]; then
  if [ ${MEM_TYPE} == "MEAN" ]; then
    bkpath=${COMIN}/ensmean/fcst_fv3lam_spinup/INPUT
  else
    bkpath=${COMIN}${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam_spinup/INPUT
  fi
else
  if [ ${MEM_TYPE} == "MEAN" ]; then
    bkpath=${COMIN}/ensmean/fcst_fv3lam/INPUT
  else
    bkpath=${COMIN}${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam/INPUT
  fi
fi
# decide background type
if [ -r "${bkpath}/coupler.res" ]; then
  BKTYPE=0              # warm start
else
  BKTYPE=1              # cold start
fi

#
#-----------------------------------------------------------------------
#
# adjust soil T/Q based on analysis increment
#
#-----------------------------------------------------------------------
#
if [ ${BKTYPE} -eq 0 ] && [ ${OB_TYPE} == "conv" ] && [ "${DO_SOIL_ADJUST}" = "TRUE" ]; then  # warm start
  cd ${bkpath}
  if [ "${IO_LAYOUT_Y}" == "1" ]; then
    ln_vrfy -snf ${fixgriddir}/fv3_grid_spec                fv3_grid_spec
  else
    for ii in ${list_iolayout}
    do
      iii=`printf %4.4i $ii`
      ln_vrfy  -snf ${gridspec_dir}/fv3_grid_spec.${iii}    fv3_grid_spec.${iii}
    done
  fi

cat << EOF > namelist.soiltq
 &setup
  fv3_io_layout_y=${IO_LAYOUT_Y},
  iyear=${YYYY},
  imonth=${MM},
  iday=${DD},
  ihour=${HH},
  iminute=0,
 /
EOF

  exec_fn="adjust_soiltq.exe"
  exec_fp="$EXECdir/${exec_fn}"

  if [ ! -f "${exec_fp}" ]; then
    print_err_msg_exit "\
  The executable specified in exec_fp does not exist:
    exec_fp = \"${exec_fp}\"
  Build lightning process and rerun."
  fi
  eval $RUN_CMD_UTILS ${exec_fp} ${REDIRECT_OUT_ERR} $APRUN || print_err_msg_exit "\
  Call to executable to run adjust soil returned with nonzero exit code."

fi

#
#-----------------------------------------------------------------------
#
# update boundary condition absed on analysis results.
# This will generate a new boundary file at 0-hour
#
#-----------------------------------------------------------------------
#
if [ ${BKTYPE} -eq 0 ] && [ "${DO_UPDATE_BC}" = "TRUE" ]; then  # warm start
  cd ${bkpath}

cat << EOF > namelist.updatebc
 &setup
  fv3_io_layout_y=${IO_LAYOUT_Y},
  bdy_update_type=1,
  grid_type_fv3_regional=2,
 /
EOF

  cp gfs_bndy.tile7.000.nc gfs_bndy.tile7.000.nc_before_update

  exec_fn="update_bc.exe"
  exec_fp="$EXECdir/${exec_fn}"

  if [ ! -f "${exec_fp}" ]; then
    print_err_msg_exit "\
  The executable specified in exec_fp does not exist:
    exec_fp = \"${exec_fp}\"
  Build lightning process and rerun."
  fi

  PREP_STEP
  eval $RUN_CMD_UTILS ${exec_fp} ${REDIRECT_OUT_ERR} || print_err_msg_exit "\
  Call to executable to run update bc returned with nonzero exit code."
  POST_STEP

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
post analysis completed successfully!!!
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
