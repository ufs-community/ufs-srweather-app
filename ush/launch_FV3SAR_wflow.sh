#!/bin/bash -l

#
#-----------------------------------------------------------------------
#
# Set shell options.
#
#-----------------------------------------------------------------------
#
set -u
#set -x
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
# Source the variable definitions file.  This is assumed to be in the 
# same directory as this script.
#
#-----------------------------------------------------------------------
#
. ${scrfunc_dir}/var_defns.sh
#
#-----------------------------------------------------------------------
#
# Set the variables containing the full path to the experiment directo-
# ry, the experiment name, and the full path to the workflow launch 
# script (this script).  In doing so, we assume that:
#
# 1) This script has been copied to the experiment directory.  Thus, the
#    directory in which it is located is the experiment directory.
# 2) The name of the experiment subdirectory (i.e. the string after the
#    last "/" in the full path to the experiment directory) is identical
#    to the experiment name.
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
module load rocoto
#
#-----------------------------------------------------------------------
#
# Set file names.
#
#-----------------------------------------------------------------------
#
rocoto_xml_bn=$( basename "${WFLOW_XML_FN}" ".xml" )
rocoto_database_fn="${rocoto_xml_bn}.db"
launch_log_fn="log.launch_${rocoto_xml_bn}"
#
#-----------------------------------------------------------------------
#
# Set the default status of the workflow to be "IN PROGRESS".  Also, 
# change directory to the experiment directory.
#
#-----------------------------------------------------------------------
#
workflow_status="IN PROGRESS"
cd "$EXPTDIR"
#
#-----------------------------------------------------------------------
#
# Issue the rocotorun command to launch/relaunch the next task in the 
# workflow.  Then check for error messages in the output of rocotorun.  
# If any are found, it means the end-to-end run of the workflow failed.  
# In this case, we remove the crontab entry that launches the workflow,
# and we append an appropriate failure message at the end of the launch
# log file.
#
#-----------------------------------------------------------------------
#

#rocotorun_output=$( ls -alF )
#echo
#echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
#echo "${rocotorun_output}"
#echo "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"

#rocotorun_output=$( \
#rocotorun -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10 \
#)
#rocotorun_output=$( (rocotorun -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10) 2>&1 )  # This freezes the script.
#rocotorun_output=$( (rocotorun -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10) 1>&2 )  # This leaves rocotorun_output empty.
#rocotorun_output=$( rocotorun -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10 )
#{ error=$(command 2>&1 1>&$out); } {out}>&1
#{ rocotorun_output=$( rocotorun -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10 2>&1 1>&$out); } {out}>&1  # This freezes the script.

#
# Ideally, the following two lines should work, but for some reason the
# output of rocotorun cannot be captured in a variable using the $(...)
# notation.  Maybe it's not being written to stdout, although I tried
# redirecting stderr to stdout and other tricks but nothing seemed to
# work.  For this reason, below we first redirect the output of rocoto-
# run to a temporary file and then read in the contents of that file in-
# to the rocotorun_output variable using the cat command.
#
#rocotorun_cmd="rocotorun -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10"
#rocotorun_output=$( eval ${rocotorun_cmd} 2>&1 )
#
tmp_fn="rocotorun_output.txt"
#rocotorun_cmd="rocotorun -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10 > ${tmp_fn}"
rocotorun_cmd="rocotorun -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10"
eval ${rocotorun_cmd} > ${tmp_fn} 2>&1
rocotorun_output=$( cat "${tmp_fn}" )
#rm "${tmp_fn}"

#rocotorun -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10 > ${tmp_fn} 2>&1

error_msg="sbatch: error: Batch job submission failed:"
# Job violates accounting/QOS policy (job submit limit, user's size and/or time limits)"
while read -r line; do
  grep_output=$( printf "$line" | grep "${error_msg}" )
  if [ $? -eq 0 ]; then
    workflow_status="FAILED"
    break
  fi
done <<< "${rocotorun_output}"
#
#-----------------------------------------------------------------------
#
# Issue the rocotostat command to obtain a table specifying the status 
# of each task.  Then check for dead tasks in the output of rocotostat.  
# If any are found, it means the end-to-end run of the workflow failed.  
# In this case, we remove the crontab entry that launches the workflow,
# and we append an appropriate failure message at the end of the launch
# log file.
#
#-----------------------------------------------------------------------
#
#rocotostat_cmd="{ pwd; rocotostat -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10; }"
#rocotostat_cmd="{ pwd; ls -alF; rocotostat -w ${WFLOW_XML_FN} -d ${rocoto_database_fn} -v 10; }"
#rocotostat_cmd="{ pwd; ls -alF; rocotostat -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10; }"
#rocotostat_cmd="{ pwd; rocotostat -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10; }"
#rocotostat_cmd="{ rocotostat -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10; }"
rocotostat_cmd="rocotostat -w \"${WFLOW_XML_FN}\" -d \"${rocoto_database_fn}\" -v 10"

#rocotostat_output=$( pwd; rocotostat -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10 2>&1 )
#rocotostat_output=$( rocotostat -w "${WFLOW_XML_FN}" -d "${rocoto_database_fn}" -v 10 2>&1 )
rocotostat_output=$( eval ${rocotostat_cmd} 2>&1 )
#rocotostat_output=$( ${rocotostat_cmd} 2>&1 )
#rocotostat_output=$( { pwd; ls -alF; } 2>&1 )
error_msg="DEAD"
while read -r line; do
#  grep_output=$( printf "$line" | grep "DEAD" )
  grep_output=$( printf "$line" | grep "${error_msg}" )
  if [ $? -eq 0 ]; then
    workflow_status="FAILED"
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
printf "

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
# the remaining rows each correspond to one cycle in the workflow.  Be-
# low, we are interested in the first and second columns of each row.
# The first column is a string containing the start time of the cycle 
# (in the format YYYYMMDDHHmm, where YYYY is the 4-digit year, MM is the
# 2-digit month, DD is the 2-digit day of the month, HH is the 2-digit
# hour of the day, and mm is the 2-digit minute of the hour).  The se-
# cond column is a string containing the state of the cycle.  This can
# be "Active" or "Done".  Below, we read in and store these two columns
# in (1-D) arrays.
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
# Note that the first line in rocotostat_output is a header line con-
# taining the column titles.  Thus, we ignore it and consider only the
# remaining lines (of which there is one per cycle).
#
  if [ $i -gt 0 ]; then
    im1=$((i-1))
    cycle_str[im1]=$( echo "$line" | sed -r -n -e "s/${regex_search}/\1/p" )
    cycle_status[im1]=$( echo "$line" | sed -r -n -e "s/${regex_search}/\2/p" )
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
  if [ "${cycle_status}" = "Done" ]; then
    num_cycles_completed=$((num_cycles_completed+1))
  fi
done
#
#-----------------------------------------------------------------------
#
# If the number of completed cycles is equal to the total number of cy-
# cles, it means the end-to-end run of the workflow was successful.  In
# this case, we reset the workflow_status to "SUCCEEDED".
#
#-----------------------------------------------------------------------
#
if [ ${num_cycles_completed} -eq ${num_cycles_total} ]; then
  workflow_status="SUCCEEDED"
fi
#
#-----------------------------------------------------------------------
#
# Print informational messages about the workflow to the launch log 
# file, including the workflow status.
#
#-----------------------------------------------------------------------
#
printf "

Summary of workflow status:
~~~~~~~~~~~~~~~~~~~~~~~~~~

  ${num_cycles_completed} out of ${num_cycles_total} cycles completed.
  Workflow status:  ${workflow_status}

========================================================================
End of output from script \"${scrfunc_fn}\".
========================================================================

" >> ${WFLOW_LAUNCH_LOG_FN} 2>&1
#
#-----------------------------------------------------------------------
#
# If the workflow status is now either "SUCCEEDED" or "FAILED", indicate
# this by appending an appropriate message to the end of the launch log
# file.
#
#-----------------------------------------------------------------------
#
msg="
The end-to-end run of the workflow for the experiment specified by 
expt_name ${workflow_status}:
  expt_name = \"${expt_name}\"
"

if [ "${workflow_status}" = "SUCCEEDED" ] || \
   [ "${workflow_status}" = "FAILED" ]; then

  printf "$msg" >> ${WFLOW_LAUNCH_LOG_FN} 2>&1
#
# If a cron job was being used to periodically relaunch the workflow, we
# now remove the entry in the crontab corresponding to the workflow be-
# cause the end-to-end run of the workflow has now either succeeded or
# failed and will remain in that state without manual user intervention.
# Thus, there is no need to try to relaunch it.
#
  if [ "${USE_CRON_TO_RELAUNCH}" = "TRUE" ]; then

    msg="$msg
Removing the corresponding line (CRONTAB_LINE) from the crontab file:
  CRONTAB_LINE = \"${CRONTAB_LINE}\"
"
    printf "$msg"
#
# Below, we use "grep" to determine whether the crontab line that the
# variable CRONTAB_LINE contains is already present in the cron table.
# For that purpose, we need to escape the asterisks in the string in
# CRONTAB_LINE with backslashes.  Do this next.
#
    crontab_line_esc_astr=$( printf "%s" "${CRONTAB_LINE}" | \
                             sed -r -e "s%[*]%\\\\*%g" )
#
# In the string passed to the grep command below, we use the line start
# and line end anchors ("^" and "$", respectively) to ensure that we on-
# ly find lines in the crontab that contain exactly the string in cron-
# tab_line_esc_astr without any leading or trailing characters.
#
    ( crontab -l | grep -v "^${crontab_line_esc_astr}$" ) | crontab -

  fi

fi




