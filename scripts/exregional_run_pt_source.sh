#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHdir/source_util_funcs.sh
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

This is the ex-script for the task that runs PT_SOURCE.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_PT_SOURCE}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_PT_SOURCE}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_PT_SOURCE}
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

nprocs=$(( LAYOUT_X*LAYOUT_Y ))
ppn_run_aqm="${PPN_RUN_PT_SOURCE}"
omp_num_threads_run_aqm="${OMP_NUM_THREADS_RUN_PT_SOURCE}"
nstep=$(( FCST_LEN_HRS+1 ))
yyyymmddhh="${PDY}${cyc}"

if [ -z "${RUN_CMD_AQM:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_AQM for your platform"
else
  RUN_CMD_AQM=$(eval echo ${RUN_CMD_AQM})
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_AQM}\'."
fi

#
#-----------------------------------------------------------------------
#
# Move to the working directory
#
#-----------------------------------------------------------------------
#
DATA="${DATA}/tmp_PT_SOURCE"
mkdir_vrfy -p "$DATA"
cd_vrfy $DATA

#
#-----------------------------------------------------------------------
#
# Run stack-pt-mergy.py if file does not exist.
#
#-----------------------------------------------------------------------
#
if [ ! -s "${DATA}/pt-${yyyymmddhh}.nc" ]; then 
  cp_vrfy ${HOMEdir}/sorc/AQM-utils/python_utils/stack-pt-merge.py stack-pt-merge.py
  python3 stack-pt-merge.py -s ${yyyymmddhh} -n ${nstep} -conus ${PT_SRC_BASE_DIR_CONUS} -hi ${PT_SRC_BASE_DIR_HI} -ak ${PT_SRC_BASE_DIR_AK}

  if [ ! -s "${DATA}/pt-${yyyymmddhh}.nc" ]; then
    print_err_msg_exit "\
The point source file \"pt-${yyyymmddhh}.nc\" was not generated."
  else
    print_info_msg "The intermediate file \"pt-${yyyymmddhh}.nc\" exists."
  fi
fi

#
#----------------------------------------------------------------------
#
# Export input parameters of PT_SOURCE executable
#
#-----------------------------------------------------------------------
#
export NX=${ESGgrid_NX}
export NY=${ESGgrid_NY}
export LAYOUT_X
export LAYOUT_Y
export TOPO="${NEXUS_FIX_DIR}/${NEXUS_GRID_FN}"
export PT_IN="${DATA}/pt-${yyyymmddhh}.nc"

#
#----------------------------------------------------------------------
#
# Temporary output directory for PT_SOURCE executable
#
#-----------------------------------------------------------------------
#
mkdir_vrfy -p "${DATA}/PT"

#
#----------------------------------------------------------------------
#
# Execute PT_SOURCE
#
#-----------------------------------------------------------------------
#
PREP_STEP
eval ${RUN_CMD_AQM} ${EXECdir}/decomp-ptemis-mpi ${REDIRECT_OUT_ERR} || \
print_err_msg_exit "\
Call to execute PT_SOURCE for Online-CMAQ failed."
POST_STEP

#
#-----------------------------------------------------------------------
#
# Move output to INPUT_DATA directory.
#
#-----------------------------------------------------------------------
#
mv_vrfy "${DATA}/PT" ${INPUT_DATA}

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
PT_SOURCE has successfully generated output files !!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
