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
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
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
  hour=$( printf "%02d" "${FHR[i]}" )
  FHR_STR="$FHR_STR $hour"
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
set_file_param "$WFLOW_XML_FP" "SCRIPT_VAR_DEFNS_FP" "$SCRIPT_VAR_DEFNS_FP"
set_file_param "$WFLOW_XML_FP" "ACCOUNT" "$ACCOUNT"
set_file_param "$WFLOW_XML_FP" "SCHED" "$SCHED"
set_file_param "$WFLOW_XML_FP" "QUEUE_DEFAULT" "$QUEUE_DEFAULT"
set_file_param "$WFLOW_XML_FP" "QUEUE_HPSS" "$QUEUE_HPSS"
set_file_param "$WFLOW_XML_FP" "QUEUE_RUN_FV3SAR" "$QUEUE_RUN_FV3SAR"
set_file_param "$WFLOW_XML_FP" "USHDIR" "$USHDIR"
set_file_param "$WFLOW_XML_FP" "RUNDIR" "$RUNDIR"
set_file_param "$WFLOW_XML_FP" "PROC_RUN_FV3SAR" "$PROC_RUN_FV3SAR"
set_file_param "$WFLOW_XML_FP" "YYYY" "$YYYY"
set_file_param "$WFLOW_XML_FP" "MM" "$MM"
set_file_param "$WFLOW_XML_FP" "DD" "$DD"
set_file_param "$WFLOW_XML_FP" "HH" "$HH"
set_file_param "$WFLOW_XML_FP" "FHR" "$FHR"
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
# For convenience, print out the commands that needs to be issued on the 
# command line in order to launch the workflow and to check its status.  
# Also, print out the command that should be placed in the user's cron-
# tab in order for the workflow to be continually resubmitted.
#
#-----------------------------------------------------------------------
#
WFLOW_DB_FN="${WFLOW_XML_FN%.xml}.db"

rocotorun_cmd="${ROCOTO_EXEC_DIR}/rocotorun -w ${WFLOW_XML_FN} -d ${WFLOW_DB_FN} -v 10"
rocotostat_cmd="${ROCOTO_EXEC_DIR}/rocotostat -w ${WFLOW_XML_FN} -d ${WFLOW_DB_FN} -v 10"

print_info_msg "\
========================================================================
========================================================================

Workflow generation completed.

========================================================================
========================================================================

The run directory and work directory for this experiment are:

  RUNDIR=\"$RUNDIR\"
  WORKDIR=\"$WORKDIR\"

To launch the workflow, change location to the run directory and issue the following 
command:

  $rocotorun_cmd

To check on the status of the workflow, issue the following command (from the 
run directory):

  $rocotostat_cmd

Note that the rocotorun command above must be issued after the completion of 
each task in the workflow in order for the workflow to submit the next task to
the queue.  

Note also that in order for the output of the rocotostat command above to be 
up-to-date, the rocotorun command must be issued immediately before the rocotostat 
command.

For automatic resubmission of the workflow (say every 3 minutes), the following 
line can be added to the user's crontab (use \"crontab -e\" to edit the cron 
table): 

*/3 * * * * cd $RUNDIR && $rocotorun_cmd

Done."
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1



