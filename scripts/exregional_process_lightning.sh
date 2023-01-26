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

This is the ex-script for the task that runs lightning preprocess
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
START_DATE=$(echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')
YYYYMMDDHH=$(date +%Y%m%d%H -d "${START_DATE}")
JJJ=$(date +%j -d "${START_DATE}")

YYYY=${YYYYMMDDHH:0:4}
MM=${YYYYMMDDHH:4:2}
DD=${YYYYMMDDHH:6:2}
HH=${YYYYMMDDHH:8:2}
YYYYMMDD=${YYYYMMDDHH:0:8}

YYJJJHH=$(date +"%y%j%H" -d "${START_DATE}")
PREYYJJJHH=$(date +"%y%j%H" -d "${START_DATE} 1 hours ago")

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

fixdir=$FIXgsi
fixgriddir=$FIXgsi/${PREDEF_GRID_NAME}

print_info_msg "$VERBOSE" "fixdir is $fixdir"
print_info_msg "$VERBOSE" "fixgriddir is $fixgriddir"

#
#-----------------------------------------------------------------------
#
# link or copy background and grid files
#
#-----------------------------------------------------------------------

cp_vrfy ${fixgriddir}/fv3_grid_spec          fv3sar_grid_spec.nc

#-----------------------------------------------------------------------
#
# Link to the NLDN data
#
#-----------------------------------------------------------------------
run_lightning=false
filenum=0
LIGHTNING_FILE=${LIGHTNING_ROOT}/vaisala/netcdf
for n in 00 05 ; do
  filename=${LIGHTNING_FILE}/${YYJJJHH}${n}0005r
  if [ -r ${filename} ]; then
  ((filenum += 1 ))
    ln -sf ${filename} ./NLDN_lightning_${filenum}
  else
   echo " ${filename} does not exist"
  fi
done
for n in 55 50 45 40 35 ; do
  filename=${LIGHTNING_FILE}/${PREYYJJJHH}${n}0005r
  if [ -r ${filename} ]; then
  ((filenum += 1 ))
    ln -sf ${filename} ./NLDN_lightning_${filenum}
    run_lightning=true
  else
   echo " ${filename} does not exist"
  fi
done

echo "found GLD360 files: ${filenum}"

#-----------------------------------------------------------------------
#
# copy bufr table from fix directory
#
#-----------------------------------------------------------------------
BUFR_TABLE=${FIXgsi}/prepobs_prep_RAP.bufrtable

cp_vrfy $BUFR_TABLE prepobs_prep.bufrtable

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
    eval $RUN_CMD_UTILS ${exec_fp} ${REDIRECT_OUT_ERR} || print_err_msg "\  
        Call to executable to run lightning (nc) process returned with nonzero exit code."
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
