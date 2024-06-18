#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${USHsrw}/source_util_funcs.sh
for sect in user nco platform workflow nco global verification cpl_aqm_parm \
  constants fixed_files grid_params \
  task_nexus_post_split ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; sex -xue; } > /dev/null 2>&1
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

This is the ex-script for the task that runs NEXUS POST SPLIT.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set run command.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

YYYYMMDD="${PDY}"
MM="${PDY:4:2}"
DD="${PDY:6:2}"
HH="${cyc}"

NUM_SPLIT_NEXUS=$( printf "%02d" ${NUM_SPLIT_NEXUS} )

if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
start_date=${YYYYMMDD}${HH}
end_date=`$NDATE +${FCST_LEN_HRS} ${YYYYMMDD}${HH}`
#
#-----------------------------------------------------------------------
#
# Copy the NEXUS config files to the tmp directory  
#
#-----------------------------------------------------------------------
#
cp -p ${PARMsrw}/nexus_config/cmaq/HEMCO_sa_Time.rc ${DATA}/HEMCO_sa_Time.rc
cp -p ${FIXaqm}/nexus/${NEXUS_GRID_FN} ${DATA}/grid_spec.nc

if [ "${NUM_SPLIT_NEXUS}" = "01" ]; then
  nspt="00"
  cp -p ${DATA_SHARE}/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt_split.${nspt}.nc ${DATA}/NEXUS_Expt_combined.nc
else
  ${USHsrw}/nexus_utils/python/concatenate_nexus_post_split.py "${DATA_SHARE}/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt_split.*.nc" "${DATA}/NEXUS_Expt_combined.nc"
  export err=$?
  if [ $err -ne 0 ]; then
    message_txt="Call to python script \"concatenate_nexus_post_split.py\" failed."
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi
fi
#
#-----------------------------------------------------------------------
#
# run MEGAN NCO script
#
#-----------------------------------------------------------------------
#
${USHsrw}/nexus_utils/combine_ant_bio.py "${DATA}/NEXUS_Expt_combined.nc" ${DATA}/NEXUS_Expt.nc
export err=$?
if [ $err -ne 0 ]; then
  message_txt="Call to python script \"NEXUS_Expt_pretty.py\" failed."
  err_exit "${message_txt}"
  print_err_msg_exit "${message_txt}"
fi
#
#-----------------------------------------------------------------------
#
# Move NEXUS output to INPUT_DATA directory.
#
#-----------------------------------------------------------------------
#
cp -p ${DATA}/NEXUS_Expt.nc ${COMOUT}/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt.nc
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
NEXUS NetCDF file has been generated successfully!!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
