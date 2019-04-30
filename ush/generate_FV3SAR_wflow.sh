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
WFLOW_XML_FP="$EXPTDIR/$WFLOW_XML_FN"
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
for i in $(seq 1 $(($numel-1)) ); do
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
set_file_param "$WFLOW_XML_FP" "EXPTDIR" "$EXPTDIR"
set_file_param "$WFLOW_XML_FP" "PROC_RUN_FV3SAR" "$PROC_RUN_FV3SAR"
#set_file_param "$WFLOW_XML_FP" "CDATE_FIRST_CYCL" "$CDATE_FIRST_CYCL"
#set_file_param "$WFLOW_XML_FP" "CDATE_LAST_CYCL" "$CDATE_LAST_CYCL"
#set_file_param "$WFLOW_XML_FP" "YYYY_FIRST_CYCL" "$YYYY_FIRST_CYCL"
#set_file_param "$WFLOW_XML_FP" "MM_FIRST_CYCL" "$MM_FIRST_CYCL"
#set_file_param "$WFLOW_XML_FP" "DD_FIRST_CYCL" "$DD_FIRST_CYCL"
#set_file_param "$WFLOW_XML_FP" "HH_FIRST_CYCL" "$HH_FIRST_CYCL"
set_file_param "$WFLOW_XML_FP" "FHR" "$FHR"
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
regex_search="(^\s*<cycledef\s+group=\"at_start\">00)\s*(&HH_FIRST_CYCL;)\s*(&DD_FIRST_CYCL;)\s*(&MM_FIRST_CYCL;)\s*(&YYYY_FIRST_CYCL;)\s*(.*</cycledef>)(.*)"
regex_replace="\1 ${HH_FIRST_CYCL} ${DD_FIRST_CYCL} ${MM_FIRST_CYCL} ${YYYY_FIRST_CYCL} \6"
sed -i -r -e "s|${regex_search}|${regex_replace}|g" "$WFLOW_XML_FP"



regex_search="(^\s*<cycledef\s+group=\"at_)(CC)(Z\">)(&CDATE_FIRST_CYCL;)(CC)( )(&CDATE_LAST_CYCL;)(CC)(.*</cycledef>)(.*)"

i=0
for cycl in "${CYCL_HRS[@]}"; do
  regex_replace="\1$cycl\3${CDATE_FIRST_CYCL}${cycl}00\6${CDATE_FIRST_CYCL}${cycl}00\9"
  crnt_line=$( sed -n -r -e "s%$regex_search%$regex_replace%p" "$WFLOW_XML_FP" )
  if [ "$i" -eq "0" ]; then
    all_cycledefs="${crnt_line}"
  else
    all_cycledefs=$( printf "%s\n%s" "${all_cycledefs}" "${crnt_line}" )
  fi
  i=$(( $i+1 ))
done

#echo
#echo "$all_cycledefs"

#
# Replace all actual newlines in the variable all_cycledefs with back-
# slash-n's.  This is needed in order for the sed command below to work
# properly (i.e. to avoid it failing with an unterminated `s' command"
# message).
#
all_cycledefs=${all_cycledefs//$'\n'/\\n}
#
# Replace all ampersands in the variable all_cycledefs with backslash-
# ampersands.  This is needed in order for the sed command below to per-
# form the substitution properly.
#
all_cycledefs=${all_cycledefs//&/\\\&}
#echo
#echo "$all_cycledefs"

sed -i -r -e "s|${regex_search}|${all_cycledefs}|g" "$WFLOW_XML_FP"

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

The experiment and work directories for this experiment are:

  EXPTDIR=\"$EXPTDIR\"
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

*/3 * * * * cd $EXPTDIR && $rocotorun_cmd

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



