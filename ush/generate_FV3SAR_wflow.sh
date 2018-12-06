#!/bin/sh -l

#
#-----------------------------------------------------------------------
#
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. ./source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Source the setup script.  Note that this in turn sources the configu-
# ration file/script (config.sh) in the current directory.  It also cre-
# ates the run and work directories, the INPUT and RESTART subdirecto-
# ries under the run directory, and a variable definitions file/script
# in the run directory.  The latter gets sources by each of the scripts
# that run the various workflow tasks.
#
#-----------------------------------------------------------------------
#
. ./setup.sh
#
#-----------------------------------------------------------------------
#
# Set the full paths to the template and actual workflow xml files.  The
# actual workflow xml will be placed in the run directory and then used
# by rocoto to run the workflow.
#
#-----------------------------------------------------------------------
#
TEMPLATE_XML_FP="$TEMPLATE_DIR/$WFLOW_XML_FN"
WFLOW_XML_FP="$RUNDIR/$WFLOW_XML_FN"
#
#-----------------------------------------------------------------------
#
# Copy the xml template file to the run directory.
#
#-----------------------------------------------------------------------
#
cp_vrfy $TEMPLATE_XML_FP $WFLOW_XML_FP
#
#-----------------------------------------------------------------------
#
# Set local variables that will be used later below to replace place-
# holder values in the workflow xml file.
#
#-----------------------------------------------------------------------
#
PROC_RUN_FV3SAR="${NUM_NODES}:ppn=${ncores_per_node}"

FHR=( $( seq 0 1 $fcst_len_hrs ) )
i=0
FHR_STR=$( printf "%02d" "${FHR[i]}" )
numel=${#FHR[@]}
for i in $(seq 0 $(($numel-1)) ); do
  HH=$( printf "%02d" "${FHR[i]}" )
  FHR_STR="$FHR_STR $HH"
done
FHR="$FHR_STR"
#
#-----------------------------------------------------------------------
#
# Fill in the xml file with parameter values that are either specified
# in the configuration file/script (config.sh) or set in the setup
# script sourced above.
#
#-----------------------------------------------------------------------
#
set_file_param $WFLOW_XML_FP "SCRIPT_VAR_DEFNS_FP" \
               "$SCRIPT_VAR_DEFNS_FP" $VERBOSE

set_file_param $WFLOW_XML_FP "ACCOUNT" \
               "$ACCOUNT" $VERBOSE

set_file_param $WFLOW_XML_FP "SCHED" \
               "$SCHED" $VERBOSE

set_file_param $WFLOW_XML_FP "QUEUE_DEFAULT" \
               "$QUEUE_DEFAULT" $VERBOSE

set_file_param $WFLOW_XML_FP "QUEUE_HPSS" \
               "$QUEUE_HPSS" $VERBOSE

set_file_param $WFLOW_XML_FP "QUEUE_RUN_FV3SAR" \
               "$QUEUE_RUN_FV3SAR" $VERBOSE

set_file_param $WFLOW_XML_FP "USHDIR" \
               "$USHDIR" $VERBOSE

set_file_param $WFLOW_XML_FP "RUNDIR" \
               "$RUNDIR" $VERBOSE

set_file_param $WFLOW_XML_FP "PROC_RUN_FV3SAR" \
               "$PROC_RUN_FV3SAR" $VERBOSE

set_file_param $WFLOW_XML_FP "FHR" \
               "$FHR" $VERBOSE
#
#-----------------------------------------------------------------------
#
# Save the current shell options, turn off the xtrace option, load the
# rocoto module, then restore the original shell options.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set +x; } > /dev/null 2>&1
module load rocoto
{ restore_shell_opts; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the various rocoto commands.
#
#-----------------------------------------------------------------------
#
ROCOTO_EXEC_FP=$( which rocotorun )
ROCOTO_EXEC_DIR=${ROCOTO_EXEC_FP%/rocotorun}
#
#-----------------------------------------------------------------------
#
# For convenience, print out the shell command that needs to be issued
# in order to launch the workflow.  This should be placed in the user's
# crontab so that the workflow is continually resubmitted.
#
#-----------------------------------------------------------------------
#
WFLOW_DB_FN="${WFLOW_XML_FN%.xml}.db"

cmd="cd $RUNDIR && ${ROCOTO_EXEC_DIR}/rocotorun -w ${WFLOW_XML_FN} -d ${WFLOW_DB_FN} -v 10"
print_info_msg "\
To run the workflow, use the following command:
  \"$cmd\"
This command can be added to the user's crontab for automatic resubmission 
of the workflow."

cmd="cd $RUNDIR && ${ROCOTO_EXEC_DIR}/rocotostat -w ${WFLOW_XML_FN} -d ${WFLOW_DB_FN} -v 10"
print_info_msg "\
To check on the status of the workflow, use the following command:
  \"$cmd\""
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1



