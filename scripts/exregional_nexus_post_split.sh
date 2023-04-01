#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "cpl_aqm_parm|task_nexus_post_split" ${GLOBAL_VAR_DEFNS_FP}
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
#
#-----------------------------------------------------------------------
#
# Move to the NEXUS working directory
#
#-----------------------------------------------------------------------
#
DATA="${DATA}/tmp_NEXUS_POST_SPLIT"
mkdir_vrfy -p "$DATA"

cd_vrfy $DATA

mm="${PDY:4:2}"
dd="${PDY:6:2}"
hh="${cyc}"
yyyymmdd="${PDY}"

NUM_SPLIT_NEXUS=$( printf "%02d" ${NUM_SPLIT_NEXUS} )

if [ "${FCST_LEN_HRS}" = "-1" ]; then
  CYCLE_IDX=$(( ${cyc} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
start_date=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC" "+%Y%m%d%H" )
end_date=$( $DATE_UTIL --utc --date "${yyyymmdd} ${hh} UTC + ${FCST_LEN_HRS} hours" "+%Y%m%d%H" )

#
#-----------------------------------------------------------------------
#
# Copy the NEXUS config files to the tmp directory  
#
#-----------------------------------------------------------------------
#
cp_vrfy ${ARL_NEXUS_DIR}/config/cmaq/HEMCO_sa_Time.rc ${DATA}/HEMCO_sa_Time.rc

cp_vrfy ${NEXUS_FIX_DIR}/${NEXUS_GRID_FN} ${DATA}/grid_spec.nc
if [ "${NUM_SPLIT_NEXUS}" = "01" ]; then
  nspt="00"
  cp_vrfy ${COMIN}/NEXUS/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt_split.${nspt}.nc ${DATA}/NEXUS_Expt_combined.nc
else
  python3 ${ARL_NEXUS_DIR}/utils/python/concatenate_nexus_post_split.py "${COMIN}/NEXUS/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt_split.*.nc" "${DATA}/NEXUS_Expt_combined.nc"
fi
    
#
#-----------------------------------------------------------------------
#
# make nexus output pretty
#
#-----------------------------------------------------------------------
#
python3 ${ARL_NEXUS_DIR}/utils/python/nexus_time_parser.py -f ${DATA}/HEMCO_sa_Time.rc -s $start_date -e $end_date

python3 ${ARL_NEXUS_DIR}/utils/python/make_nexus_output_pretty.py --src ${DATA}/NEXUS_Expt_combined.nc --grid ${DATA}/grid_spec.nc -o ${DATA}/NEXUS_Expt_pretty.nc -t ${DATA}/HEMCO_sa_Time.rc

#
#-----------------------------------------------------------------------
#
# run MEGAN NCO script
#
#-----------------------------------------------------------------------
#
python3 ${ARL_NEXUS_DIR}/utils/combine_ant_bio.py ${DATA}/NEXUS_Expt_pretty.nc ${DATA}/NEXUS_Expt.nc

#
#-----------------------------------------------------------------------
#
# Move NEXUS output to INPUT_DATA directory.
#
#-----------------------------------------------------------------------
#
mv_vrfy ${DATA}/NEXUS_Expt.nc ${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.NEXUS_Expt.nc
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
