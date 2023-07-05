#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_process_lightning" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that runs lightning preprocessing
with FV3 for the specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
START_DATE=$(echo "${PDY} ${cyc}")
YYYYMMDDHH=$(date +%Y%m%d%H -d "${START_DATE}")

#
#-----------------------------------------------------------------------
#
# Get into working directory
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Getting into working directory for lightning process ..."

cd_vrfy ${DATA}

pregen_grid_dir=$DOMAIN_PREGEN_BASEDIR/${PREDEF_GRID_NAME}

print_info_msg "$VERBOSE" "pregen_grid_dir is $pregen_grid_dir"

#
#-----------------------------------------------------------------------
#
# link or copy background and grid files
#
#-----------------------------------------------------------------------

cp_vrfy ${pregen_grid_dir}/fv3_grid_spec          fv3sar_grid_spec.nc

#-----------------------------------------------------------------------
#
# Link to the NLDN data
#
#-----------------------------------------------------------------------
run_lightning=false
filenum=0

for file in "${COMIN}/obs/NLDN_lightning_*"; do
  ln_vrfy ${file} .
done

#-----------------------------------------------------------------------
#
# Build namelist and run executable
#
#   analysis_time : process obs used for this analysis date (YYYYMMDDHH)
#   NLDN_filenum  : number of NLDN lighting observation files 
#   IfAlaska      : logic to decide if to process Alaska lightning obs
#   bkversion     : grid type (background will be used in the analysis)
#                   = 0 for ARW  (default)
#                   = 1 for FV3LAM
#-----------------------------------------------------------------------

cat << EOF > namelist.lightning
 &setup
  analysis_time = ${YYYYMMDDHH},
  NLDN_filenum  = ${filenum},
  grid_type = "${PREDEF_GRID_NAME}",
  obs_type = "nldn_nc"
 /
EOF

#
#-----------------------------------------------------------------------
#
# Copy the executable to the run directory.
#
#-----------------------------------------------------------------------
#
exec_fn="process_Lightning.exe"
exec_fp="$EXECdir/${exec_fn}"

if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable specified in exec_fp does not exist:
  exec_fp = \"${exec_fp}\"
Build lightning process and rerun."
fi
#
#
#-----------------------------------------------------------------------
#
# Run the process
#
#-----------------------------------------------------------------------
#

if [[ "$run_lightning" == true ]]; then
    PREP_STEP
    eval ${RUN_CMD_UTILS} ${exec_fp} ${REDIRECT_OUT_ERR} || \
    print_err_msg_exit "\
    Call to executable (exec_fp) to run lightning (nc) process returned 
    with nonzero exit code:
      exec_fp = \"${exec_fp}\""
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
LIGHTNING PROCESS completed successfully!!!

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
