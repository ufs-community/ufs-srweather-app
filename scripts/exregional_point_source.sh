#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_fcst|cpl_aqm_parm|task_point_source" ${GLOBAL_VAR_DEFNS_FP}
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
# Set run command.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

if [ "${FCST_LEN_HRS}" = "-1" ]; then
  CYCLE_IDX=$(( ${cyc} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
nstep=$(( FCST_LEN_HRS+1 ))
yyyymmddhh="${PDY}${cyc}"

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
# Set the directories for CONUS/HI/AK
#
#-----------------------------------------------------------------------
#
PT_SRC_CONUS="${PT_SRC_BASEDIR}/12US1"
PT_SRC_HI="${PT_SRC_BASEDIR}/3HI1"
PT_SRC_AK="${PT_SRC_BASEDIR}/9AK1"
#
#-----------------------------------------------------------------------
#
# Run stack-pt-mergy.py if file does not exist.
#
#-----------------------------------------------------------------------
#
if [ ! -s "${DATA}/pt-${yyyymmddhh}.nc" ]; then 
  python3 ${HOMEdir}/sorc/AQM-utils/python_utils/stack-pt-merge.py -s ${yyyymmddhh} -n ${nstep} -conus ${PT_SRC_CONUS} -hi ${PT_SRC_HI} -ak ${PT_SRC_AK}
fi

# Move to COMIN
mv_vrfy ${DATA}/pt-${yyyymmddhh}.nc ${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.PT.nc 

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
