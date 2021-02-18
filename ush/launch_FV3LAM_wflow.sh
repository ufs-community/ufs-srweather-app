#!/bin/bash -l

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
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the experiment directory.  We assume that there is a symlink to 
# this script in the experiment directory, and this script is called via
# that symlink.  Thus, finding the directory in which the symlink is lo-
# cated will give us the experiment directory.  We find this by first 
# obtaining the directory portion (i.e. the portion without the name of
# this script) of the command that was used to called this script (i.e.
# "$0") and then use the "readlink -f" command to obtain the correspond-
# ing absolute path.  This will work for all four of the following ways
# in which the symlink in the experiment directory pointing to this 
# script may be called:
#
# 1) Call this script from the experiment directory:
#    > cd /path/to/experiment/directory
#    > launch_FV3LAM_wflow.sh
#
# 2) Call this script from the experiment directory but using "./" be-
#    fore the script name:
#    > cd /path/to/experiment/directory
#    > ./launch_FV3LAM_wflow.sh
#
# 3) Call this script from any directory using the absolute path to the
#    symlink in the experiment directory:
#    > /path/to/experiment/directory/launch_FV3LAM_wflow.sh
#
# 4) Call this script from a directory that is several levels up from
#    the experiment directory (but not necessarily at the root directo-
#    ry):
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
exptdir=$( readlink -f "$exptdir" )
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file for the experiment.
#
#-----------------------------------------------------------------------
#
. $exptdir/var_defns.sh
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
if [ "$MACHINE" = "CHEYENNE" ]; then
  module use -a /glade/p/ral/jntp/UFS_SRW_app/modules/
  module load rocoto
elif [ "$MACHINE" = "ORION" ]; then
  module purge
  module load contrib rocoto
elif [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
  module purge
  module load lsf/10.1
  module use /gpfs/dell3/usrx/local/dev/emc_rocoto/modulefiles/
  module load ruby/2.5.1 rocoto/1.2.4
elif [ "$MACHINE" = "WCOSS_CRAY" ]; then
  module purge
  module load xt-lsfhpc/9.1.3
  module use -a /usrx/local/emc_rocoto/modulefiles
  module load rocoto/1.2.4
else
  module purge
  module load rocoto
fi
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
cd "$exptdir"
#
#-----------------------------------------------------------------------
#
# Issue the rocotorun command to (re)launch the next task in the 
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
rm "${tmp_fn}"

error_msg="sbatch: error: Batch job submission failed:"
# Job violates accounting/QOS policy (job submit limit, user's size and/or time limits)"
while read -r line; do
  grep_output=$( printf "$line" | grep "${error_msg}" )
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
  grep_output=$( printf "$line" | grep "${error_msg}" )
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
# this case, we reset the wflow_status to "SUCCESS".
#
#-----------------------------------------------------------------------
#
if [ ${num_cycles_completed} -eq ${num_cycles_total} ]; then
  wflow_status="SUCCESS"
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
  Workflow status:  ${wflow_status}

========================================================================
End of output from script \"${scrfunc_fn}\".
========================================================================

" >> ${WFLOW_LAUNCH_LOG_FN} 2>&1
#
#-----------------------------------------------------------------------
#
# If the workflow status is now either "SUCCESS" or "FAILURE", indicate
# this by appending an appropriate workflow completion message to the 
# end of the launch log file.
#
#-----------------------------------------------------------------------
#
if [ "${wflow_status}" = "SUCCESS" ] || \
   [ "${wflow_status}" = "FAILURE" ]; then

  msg="
The end-to-end run of the workflow for the forecast experiment specified 
by expt_name has completed with the following workflow status (wflow_-
status):
  expt_name = \"${expt_name}\"
  wflow_status = \"${wflow_status}\"
"
#
# If a cron job was being used to periodically relaunch the workflow, we
# now remove the entry in the crontab corresponding to the workflow be-
# cause the end-to-end run of the workflow has now either succeeded or
# failed and will remain in that state without manual user intervention.
# Thus, there is no need to try to relaunch it.  We also append a mes-
# sage to the completion message above to indicate this.
#
  if [ "${USE_CRON_TO_RELAUNCH}" = "TRUE" ]; then

    msg="${msg}\
Thus, there is no need to relaunch the workflow via a cron job.  Remo-
ving from the crontab the line (CRONTAB_LINE) that calls the workflow
launch script for this experiment:
  CRONTAB_LINE = \"${CRONTAB_LINE}\"
"
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
#
# Print the workflow completion message to the launch log file.
#
  printf "$msg" >> ${WFLOW_LAUNCH_LOG_FN} 2>&1
#
# If the stdout from this script is being sent to the screen (e.g. it is
# not being redirected to a file), then also print out the workflow 
# completion message to the screen.
#
  if [ -t 1 ]; then
    printf "$msg"
  fi

fi




