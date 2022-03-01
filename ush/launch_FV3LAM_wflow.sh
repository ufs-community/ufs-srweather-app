#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Set shell options.
#
#-----------------------------------------------------------------------
#
set -u
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
if [[ $(uname -s) == Darwin ]]; then
  command -v greadlink >/dev/null 2>&1 || { \
    echo >&2 "\
For Darwin-based operating systems (MacOS), the 'greadlink' utility is 
required to run the UFS SRW Application. Reference the User's Guide for 
more information about platform requirements. Aborting."; \
    exit 1; \
  }
  scrfunc_fp=$( greadlink -f "${BASH_SOURCE[0]}" )
else
  scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
fi
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the experiment directory.  We assume that there is a symlink to 
# this script in the experiment directory, and this script is called via
# that symlink.  Thus, finding the directory in which the symlink is
# located will give us the experiment directory.  We find this by first 
# obtaining the directory portion (i.e. the portion without the name of
# this script) of the command that was used to called this script (i.e.
# "$0") and then use the "readlink -f" command to obtain the corresponding
# absolute path.  This will work for all four of the following ways in 
# which the symlink in the experiment directory pointing to this script 
# may be called:
#
# 1) Call this script from the experiment directory:
#    > cd /path/to/experiment/directory
#    > launch_FV3LAM_wflow.sh
#
# 2) Call this script from the experiment directory but using "./" before
#    the script name:
#    > cd /path/to/experiment/directory
#    > ./launch_FV3LAM_wflow.sh
#
# 3) Call this script from any directory using the absolute path to the
#    symlink in the experiment directory:
#    > /path/to/experiment/directory/launch_FV3LAM_wflow.sh
#
# 4) Call this script from a directory that is several levels up from the
#    experiment directory (but not necessarily at the root directory):
#    > cd /path/to
#    > experiment/directory/launch_FV3LAM_wflow.sh
#
# Note that given just a file name, e.g. the name of this script without
# any path before it, the "dirname" command will return a ".", e.g. in 
# bash, 
#
#   > exptdir=$( dirname "launch_FV3LAM_wflow.sh" )
#   > echo $exptdir
#
# will print out ".".
#
#-----------------------------------------------------------------------
#
exptdir=$( dirname "$0" )
if [[ $(uname -s) == Darwin ]]; then
  command -v greadlink >/dev/null 2>&1 || { \
    echo >&2 "\
For Darwin-based operating systems (MacOS), the 'greadlink' utility is 
required to run the UFS SRW Application. Reference the User's Guide for 
more information about platform requirements. Aborting."; 
    exit 1;
  }
  exptdir=$( greadlink -f "$exptdir" )
else
  exptdir=$( readlink -f "$exptdir" )
fi
#
#-----------------------------------------------------------------------
#
# Source necessary files.
#
#-----------------------------------------------------------------------
#
. $exptdir/var_defns.sh
. $USHDIR/source_machine_file.sh
. $USHDIR/constants.sh
. $USHDIR/source_util_funcs.sh
. $USHDIR/init_env.sh
. $USHDIR/get_crontab_contents.sh
#
#-----------------------------------------------------------------------
#
# Declare arguments.
#
#-----------------------------------------------------------------------
#
valid_args=( \
  "called_from_cron" \
  )
process_args valid_args "$@"
print_input_args "valid_args"
#
#-----------------------------------------------------------------------
#
# Make sure called_from_cron is set to a valid value.
#
#-----------------------------------------------------------------------
#
called_from_cron=${called_from_cron:-"FALSE"}
check_var_valid_value "called_from_cron" "valid_vals_BOOLEAN"
called_from_cron=$(boolify ${called_from_cron})
#
#-----------------------------------------------------------------------
#
# Initialize the environment, e.g. by making the "module" command as well
# as others available.
#
#-----------------------------------------------------------------------
#
env_init_scripts_fps_str="( "$(printf "\"%s\" " "${ENV_INIT_SCRIPTS_FPS[@]}")")"
init_env env_init_scripts_fps="${env_init_scripts_fps_str}"
#
#-----------------------------------------------------------------------
#
# Set the name of the experiment.  We take this to be the name of the 
# experiment subdirectory (i.e. the string after the last "/" in the 
# full path to the experiment directory).
#
#-----------------------------------------------------------------------
#
expt_name="${EXPT_SUBDIR}"
#
#-----------------------------------------------------------------------
#
# Load necessary modules.
#
#-----------------------------------------------------------------------
#
env_fp="${SR_WX_APP_TOP_DIR}/env/${WFLOW_ENV_FN}"
source "${env_fp}" || print_err_msg_exit "\
Sourcing platform-specific environment file (env_fp) for the workflow 
task failed:
  env_fp = \"${env_fp}\""
#
#-----------------------------------------------------------------------
#
# Set file names.  These include the rocoto database file and the log
# file in which to store output from this script (aka the workflow 
# launch script).
#
#-----------------------------------------------------------------------
#
rocoto_xml_bn=$( basename "${WFLOW_XML_FN}" ".xml" )
rocoto_database_fn="${rocoto_xml_bn}.db"
launch_log_fn="log.launch_${rocoto_xml_bn}"
#
#-----------------------------------------------------------------------
#
# Initialize the default status of the workflow to "IN PROGRESS".
#
#-----------------------------------------------------------------------
#
wflow_status="IN PROGRESS"
#
#-----------------------------------------------------------------------
#
# Change location to the experiment directory.
#
#-----------------------------------------------------------------------
#
cd_vrfy "$exptdir"
#
#-----------------------------------------------------------------------
#
# Issue the rocotorun command to (re)launch the next task in the workflow.  
# Then check for error messages in the output of rocotorun.  If any are 
# found, it means the end-to-end run of the workflow failed, so set the
# status of the workflow to "FAILURE".
#
#-----------------------------------------------------------------------
#
tmp_fn="rocotorun_output.txt"
rocotorun_cmd="rocotorun -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10"
eval ${rocotorun_cmd} > ${tmp_fn} 2>&1 || \
  print_err_msg_exit "\
Call to \"rocotorun\" failed with return code $?."
rocotorun_output=$( cat "${tmp_fn}" )
rm "${tmp_fn}"

error_msg="sbatch: error: Batch job submission failed:"
while read -r line; do
  grep_output=$( printf "%s" "$line" | grep "${error_msg}" )
  if [ $? -eq 0 ]; then
    wflow_status="FAILURE"
    break
  fi
done <<< "${rocotorun_output}"
#
#-----------------------------------------------------------------------
#
# Issue the rocotostat command to obtain a table specifying the status 
# of each task.  Then check for dead tasks in the output of rocotostat.  
# If any are found, it means the end-to-end run of the workflow failed,
# so set the status of the workflow (wflow_status) to "FAILURE".
#
#-----------------------------------------------------------------------
#
rocotostat_cmd="rocotostat -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10"
rocotostat_output=$( eval ${rocotostat_cmd} 2>&1 || \
                     print_err_msg_exit "\
Call to \"rocotostat\" failed with return code $?."
                   )

error_msg="DEAD"
while read -r line; do
  grep_output=$( printf "%s" "$line" | grep "${error_msg}" )
  if [ $? -eq 0 ]; then
    wflow_status="FAILURE"
    break
  fi
done <<< "${rocotostat_output}"
#
#-----------------------------------------------------------------------
#
# Place the outputs of the rocotorun and rocotostat commands obtained
# above into the launch log file.
#
#-----------------------------------------------------------------------
#
printf "%s" "

========================================================================
Start of output from script \"${scrfunc_fn}\".
========================================================================

Running rocotorun command (rocotorun_cmd):
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  rocotorun_cmd = \'${rocotorun_cmd}\'

Output of rocotorun_cmd is:
~~~~~~~~~~~~~~~~~~~~~~~~~~

${rocotorun_output}

Running rocotostat command (rocotostat_cmd):
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  rocotostat_cmd = \'${rocotostat_cmd}\'

Output of rocotostat_cmd is:
~~~~~~~~~~~~~~~~~~~~~~~~~~~

${rocotostat_output}
" >> "${WFLOW_LAUNCH_LOG_FN}" 2>&1
#
#-----------------------------------------------------------------------
#
# Use the rocotostat command with the "-s" flag to obtain a summary of 
# the status of each cycle in the workflow.  The output of this command
# has the following format:
#
#   CYCLE         STATE           ACTIVATED              DEACTIVATED
# 201905200000      Active    Nov 07 2019 00:23:30             -
# ...
#
# Thus, the first row is a header line containing the column titles, and
# the remaining rows each correspond to one cycle in the workflow.  Below, 
# we are interested in the first and second columns of each row.  The 
# first column is a string containing the start time of the cycle (in the 
# format YYYYMMDDHHmm, where YYYY is the 4-digit year, MM is the 2-digit 
# month, DD is the 2-digit day of the month, HH is the 2-digit hour of 
# the day, and mm is the 2-digit minute of the hour).  The second column 
# is a string containing the state of the cycle.  This can be "Active" 
# or "Done".  Below, we read in and store these two columns in (1-D) 
# arrays.
#
#-----------------------------------------------------------------------
#
rocotostat_output=$( rocotostat -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10 -s )

regex_search="^[ ]*([0-9]+)[ ]+([A-Za-z]+)[ ]+.*"
cycle_str=()
cycle_status=()
i=0
while read -r line; do
#
# Note that the first line in rocotostat_output is a header line containing 
# the column titles.  Thus, we ignore it and consider only the remaining 
# lines (of which there is one per cycle).
#
  if [ $i -gt 0 ]; then
    im1=$((i-1))
    cycle_str[im1]=$( echo "$line" | $SED -r -n -e "s/${regex_search}/\1/p" )
    cycle_status[im1]=$( echo "$line" | $SED -r -n -e "s/${regex_search}/\2/p" )
  fi
  i=$((i+1))
done <<< "${rocotostat_output}"
#
#-----------------------------------------------------------------------
#
# Get the number of cycles.  Then count the number of completed cycles
# by finding the number of cycles for which the corresponding element in
# the cycle_status array is set to "Done".  
#
#-----------------------------------------------------------------------
#
num_cycles_total=${#cycle_str[@]}
num_cycles_completed=0
for (( i=0; i<=$((num_cycles_total-1)); i++ )); do
  if [ "${cycle_status[i]}" = "Done" ]; then
    num_cycles_completed=$((num_cycles_completed+1))
  fi
done
#
#-----------------------------------------------------------------------
#
# If the number of completed cycles is equal to the total number of cycles, 
# it means the end-to-end run of the workflow was successful.  In this 
# case, we reset the wflow_status to "SUCCESS".
#
#-----------------------------------------------------------------------
#
if [ ${num_cycles_completed} -eq ${num_cycles_total} ]; then
  wflow_status="SUCCESS"
fi
#
#-----------------------------------------------------------------------
#
# Print informational messages about the workflow to the launch log file, 
# including the workflow status.
#
#-----------------------------------------------------------------------
#
printf "%s" "

Summary of workflow status:
~~~~~~~~~~~~~~~~~~~~~~~~~~

  ${num_cycles_completed} out of ${num_cycles_total} cycles completed.
  Workflow status:  ${wflow_status}

========================================================================
End of output from script \"${scrfunc_fn}\".
========================================================================

" >> ${WFLOW_LAUNCH_LOG_FN} 2>&1
#
#-----------------------------------------------------------------------
#
# If the workflow status (wflow_status) has been set to either "SUCCESS" 
# or "FAILURE", indicate this by appending an appropriate workflow 
# completion message to the end of the launch log file.
#
#-----------------------------------------------------------------------
#
if [ "${wflow_status}" = "SUCCESS" ] || \
   [ "${wflow_status}" = "FAILURE" ]; then

  msg="
The end-to-end run of the workflow for the forecast experiment specified 
by expt_name has completed with the following workflow status (wflow_status):
  expt_name = \"${expt_name}\"
  wflow_status = \"${wflow_status}\"
"
#
# If a cron job was being used to periodically relaunch the workflow, we
# now remove the entry in the crontab corresponding to the workflow 
# because the end-to-end run of the workflow has now either succeeded or 
# failed and will remain in that state without manual user intervention.
# Thus, there is no need to try to relaunch it.  We also append a message 
# to the completion message above to indicate this.
#
  if [ "${USE_CRON_TO_RELAUNCH}" = "TRUE" ]; then

    msg="${msg}\
Thus, there is no need to relaunch the workflow via a cron job.  Removing 
from the crontab the line (CRONTAB_LINE) that calls the workflow launch 
script for this experiment:
  CRONTAB_LINE = \"${CRONTAB_LINE}\"
"
#
# Below, we use "grep" to determine whether the crontab line that the
# variable CRONTAB_LINE contains is already present in the cron table.
# For that purpose, we need to escape the asterisks in the string in
# CRONTAB_LINE with backslashes.  Do this next.
#
    crontab_line_esc_astr=$( printf "%s" "${CRONTAB_LINE}" | \
                             $SED -r -e "s%[*]%\\\\*%g" )
#
# Get the full contents of the user's cron table.  
#
    get_crontab_contents called_from_cron=${called_from_cron} \
                         outvarname_crontab_cmd="crontab_cmd" \
                         outvarname_crontab_contents="crontab_contents"
#
# Remove the line in the contents of the cron table corresponding to the 
# current forecast experiment (if that line is part of the contents).
# Then record the results back into the user's cron table.
#
# In the string passed to the grep command below, we use the line start
# and line end anchors ("^" and "$", respectively) to ensure that we
# only find lines in the crontab that contain exactly the string in 
# crontab_line_esc_astr without any leading or trailing characters.
#
    crontab_contents=$( echo "${crontab_contents}" | grep -v "^${crontab_line_esc_astr}$" )

    if [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
      echo "${crontab_contents}" > "/u/$USER/cron/mycrontab"
    else
      echo "${crontab_contents}" | ${crontab_cmd} 
    fi

  fi
#
# Print the workflow completion message to the launch log file.
#
  printf "%s" "$msg" >> ${WFLOW_LAUNCH_LOG_FN} 2>&1
#
# If the stdout from this script is being sent to the screen (e.g. it is
# not being redirected to a file), then also print out the workflow 
# completion message to the screen.
#
  if [ -t 1 ]; then
    printf "%s" "$msg"
  fi

fi
