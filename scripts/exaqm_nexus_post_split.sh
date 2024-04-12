#!/bin/bash

set -x

msg="JOB $job HAS BEGUN"
postmsg "$msg"
   
export pgm=aqm_nexus_post_split

#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHaqm/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm|task_nexus_post_split" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHaqm/preamble.sh; } > /dev/null 2>&1
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

This is the ex-script for the task that runs NEXUS.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set run command.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

mm="${PDY:4:2}"
dd="${PDY:6:2}"
hh="${cyc}"
yyyymmdd="${PDY}"

NUM_SPLIT_NEXUS=$( printf "%02d" ${NUM_SPLIT_NEXUS} )
if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
start_date=${yyyymmdd}${hh}
end_date=`$NDATE +${FCST_LEN_HRS} ${yyyymmdd}${hh}`

#
#-----------------------------------------------------------------------
#
# Copy the NEXUS config files to the tmp directory  
#
#-----------------------------------------------------------------------
#
cpreq ${PARMaqm}/nexus_config/cmaq/HEMCO_sa_Time.rc ${DATA}/HEMCO_sa_Time.rc

cpreq ${FIXaqmnexus}/${NEXUS_GRID_FN} ${DATA}/grid_spec.nc
if [ "${NUM_SPLIT_NEXUS}" = "01" ]; then
  nspt="00"
  cpreq ${COMIN}/${cyc}/NEXUS/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt_split.${nspt}.nc ${DATA}/NEXUS_Expt_combined.nc
else
  ${USHaqm}/nexus_utils/python/concatenate_nexus_post_split.py "${COMIN}/${cyc}/NEXUS/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt_split.*.nc" "${DATA}/NEXUS_Expt_combined.nc"  >> $pgmout 2>errfile
  export err=$?
  if [ -e "${pgmout}" ]; then
   cat ${pgmout}
  fi
  if [ $err -ne 0 ]; then
    message_txt="FATAL ERROR Call to python script \"concatenate_nexus_post_split.py\" failed."
    err_exit "${message_txt}"
  fi
fi    
#
#-----------------------------------------------------------------------
#
# run MEGAN NCO script
#
#-----------------------------------------------------------------------
#
${USHaqm}/nexus_utils/combine_ant_bio.py "${DATA}/NEXUS_Expt_combined.nc" ${DATA}/NEXUS_Expt.nc
export err=$?
if [ $err -ne 0 ]; then
  message_txt="FATAL ERROR Call to python script \"NEXUS_Expt_pretty.py\" failed."
  err_exit "${message_txt}"
fi
#
#-----------------------------------------------------------------------
#
# Move NEXUS output to INPUT_DATA directory.
#
#-----------------------------------------------------------------------
#
mv ${DATA}/NEXUS_Expt.nc ${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt.nc
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
