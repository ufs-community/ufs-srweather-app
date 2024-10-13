#!/usr/bin/env bash

set -xue
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${PARMsrw}/source_util_funcs.sh
task_global_vars=( "PRE_TASK_CMDS" "FCST_LEN_CYCL" "FCST_LEN_HRS" \
  "DATE_FIRST_CYCL" "INCR_CYCL_FREQ" "FIXemis" "PT_SRC_SUBDIR" )
for var in ${task_global_vars[@]}; do
  source_config_for_task ${var} ${GLOBAL_VAR_DEFNS_FP}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
#{ save_shell_opts; set -xue; } > /dev/null 2>&1
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

if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
nstep=$(( FCST_LEN_HRS+1 ))
YYYYMMDDHH="${PDY}${cyc}"
#
#-----------------------------------------------------------------------
#
# Path to the point source data files
#
#-----------------------------------------------------------------------
#
PT_SRC_PRECOMB="${FIXemis}/${PT_SRC_SUBDIR}"
#
#-----------------------------------------------------------------------
#
# Run stack-pt-mergy.py if file does not exist.
#
#-----------------------------------------------------------------------
#
if [ ! -s "${DATA}/pt-${YYYYMMDDHH}.nc" ]; then 
  ${USHsrw}/aqm_utils_python/stack-pt-merge.py -s ${YYYYMMDDHH} -n ${nstep} -i ${PT_SRC_PRECOMB}
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to python script \"stack-pt-merge.py\" failed."
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi
fi
# Move to COMIN
mv ${DATA}/pt-${YYYYMMDDHH}.nc ${COMOUT}/${NET}.${cycle}${dot_ensmem}.PT.nc 
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
#{ restore_shell_opts; } > /dev/null 2>&1
