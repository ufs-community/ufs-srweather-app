#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_anl|task_run_enkf" ${GLOBAL_VAR_DEFNS_FP}
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

This is the ex-script for the task that retrieves observation data for
RRFS data assimilation tasks. 
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
# Enter working directory; set up variables for call to retrieve_data.py
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Entering working directory for observation files ..."

cd_vrfy ${DATA}

#
#-----------------------------------------------------------------------
#
# if path has space in between it is a command, otherwise
# treat it as a template path
#
#-----------------------------------------------------------------------
#
input_file_path=$(eval echo ${input_file_path})
if [[ $input_file_path = *" "* ]]; then
  input_file_path=$(eval ${input_file_path})
fi

if [ $SYMLINK_FIX_FILES = "TRUE" ]; then
  additional_flags="$additional_flags \
  --symlink"
fi

#
#-----------------------------------------------------------------------
#
# Call script to retrieve RAP obs bufr files
#
#-----------------------------------------------------------------------
#
if [ $RUN_ENVIR = "nco" ]; then
    EXTRN_DEFNS="${NET}.${cycle}.${EXTRN_MDL_NAME}.${ICS_OR_LBCS}.${EXTRN_MDL_VAR_DEFNS_FN}.sh"
else
    EXTRN_DEFNS="${EXTRN_MDL_VAR_DEFNS_FN}.sh"
fi
cmd="
python3 -u ${USHdir}/retrieve_data.py \
  --debug \
  --file_set obs \
  --config ${PARMdir}/data_locations.yml \
  --cycle_date ${EXTRN_MDL_CDATE} \
  --data_stores ${data_stores} \
  --data_type ${obs_type} \
  --output_path ${DATA} \
  --summary_file ${EXTRN_DEFNS} \
  $additional_flags"

$cmd || print_err_msg_exit "\
Call to retrieve_data.py failed with a non-zero exit status.

The command was:
${cmd}
"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

