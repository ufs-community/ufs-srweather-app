#!/bin/bash -l

set -x
#
#-----------------------------------------------------------------------
#
# Get the name of this script/function (scrfunc_name), the full path to
# the file in which it is located (scrfunc_fp), the name of the file 
# (scrfunc_fn), and the directory in which the file is located (scr-
# func_-dir).  Note that if this is a script (as opposed to a function), 
# the script name (scrfunc_name) will be set to "main" if it is the top-
# level script and to "script" if it is a script called from another 
# script or function.
#
#-----------------------------------------------------------------------
#
scrfunc_name="${FUNCNAME[0]}"
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
# The current script should be located in the "tests" subdirectory of 
# the workflow directory.  Thus, the workflow directory is the one above
# the directory of the current script.  Get the path to this directory
# and save it in HOMErrfs.
#
HOMErrfs=${scrfunc_dir%/*}
#
#-----------------------------------------------------------------------
#
# Set directories.
#
#-----------------------------------------------------------------------
#
#basedir="$(pwd)/../.."
#USHDIR="$basedir/regional_workflow/ush"
USHDIR="$HOMErrfs/ush"
TESTSDIR="$HOMErrfs/tests"
#
#-----------------------------------------------------------------------
#
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
echo "AAAAAAAA  scrfunc_dir = ${scrfunc_dir}"
. $USHDIR/source_util_funcs.sh
echo "BBBBBBBB  scrfunc_dir = ${scrfunc_dir}"
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
# Set site and computational parameters.
#
#-----------------------------------------------------------------------
#
MACHINE="HERA"
ACCOUNT="gsd-fv3"
QUEUE_DEFAULT="batch"
QUEUE_HPSS="service"
QUEUE_FCST="batch"
#VERBOSE="FALSE"  # This should be removed later.  To do so, must remove VERBOSE variable from function print_info_msg in file print_msg.sh.
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
readarray -t experiments_list < ${TESTSDIR}/experiments_list.txt
printf "%s\n" "${experiments_list[@]}"
num_elem="${#experiments_list[@]}"
echo "num_elem = ${num_elem}"
echo "scrfunc_dir = ${scrfunc_dir}"
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
set +x
echo
i=0
while [ ! -z "${experiments_list[$i]}" ]; do
echo
echo "======================================================"
echo "i = $i"
echo "experiments_list[$i] = '${experiments_list[$i]}'"

# Remove all leading and trailing whitespace.
  experiments_list[$i]=$( \
    printf "%s" "${experiments_list[$i]}" | \
    sed -r -e "s/^[ ]*//" -e "s/[ ]*$//" )
#                    sed -r -n -e "s/^[ ]*//" -e "s/[ ]*$//p" )
echo "experiments_list[$i] = '${experiments_list[$i]}'"
# Remove spaces before and after all separators.  We use the pipe symbol
# as the separator.
  experiments_list[$i]=$( \
    printf "%s" "${experiments_list[$i]}" | \
    sed -r -e "s/[ ]*\|[ ]*/\|/g" )
#                    sed -r -n -e "s/[ ]*\|[ ]*/\|/gp" )
echo "experiments_list[$i] = '${experiments_list[$i]}'"

#  regex_search="^[ ]*([^\|]*)[ ]*\|[ ]*(.*)"
#  regex_search="^([^\|]*)\|(.*)"
  regex_search="^([^\|]*)(\|(.*)|)"

  baseline_name=$( printf "%s" "${experiments_list[$i]}" | sed -r -n -e "s/${regex_search}/\1/p" )
  remainder=$( printf "%s" "${experiments_list[$i]}" | sed -r -n -e "s/${regex_search}/\3/p" )
echo
echo "  baseline_name = '${baseline_name}'"
echo "  remainder = '$remainder'"

  modvar_name=()
  modvar_value=()
  num_mod_vars=0
  while [ ! -z "${remainder}" ]; do
#    next_field=$( printf "%s" "$remainder" | sed -r -n -e "s/${regex_search}/\1/p" )
#    remainder=$( printf "%s" "$remainder" | sed -r -n -e "s/${regex_search}/\3/p" )
    next_field=$( printf "%s" "$remainder" | sed -r -e "s/${regex_search}/\1/" )
    remainder=$( printf "%s" "$remainder" | sed -r -e "s/${regex_search}/\3/" )
#    modvar_name[${num_mod_vars}]=$( printf "%s" "${next_field}" | sed -r -n -e "s/^([^=]*)=(.*)/\1/p" )
#    modvar_value[${num_mod_vars}]=$( printf "%s" "${next_field}" | sed -r -n -e "s/^([^=]*)=(.*)/\2/p" )
    modvar_name[${num_mod_vars}]=$( printf "%s" "${next_field}" | sed -r -e "s/^([^=]*)=(.*)/\1/" )
    modvar_value[${num_mod_vars}]=$( printf "%s" "${next_field}" | sed -r -e "s/^([^=]*)=(\")?([^\"]+*)(\")?/\3/" )
echo
echo "  next_field = '${next_field}'"
echo "  remainder = '$remainder'"
echo "  modvar_name[${num_mod_vars}] = ${modvar_name[${num_mod_vars}]}"
echo "  modvar_value[${num_mod_vars}] = ${modvar_value[${num_mod_vars}]}"
    num_mod_vars=$((num_mod_vars+1))
echo "  num_mod_vars = ${num_mod_vars}"

  done


  baseline_config_fp="${TESTSDIR}/baseline_configs/config.${baseline_name}.sh"
  if [ ! -f "${baseline_config_fp}" ]; then
    print_err_msg_exit "\
The experiment/workflow configuration file (baseline_config_fp) for the
specified baseline (baseline_name) does not exist:
  baseline_name = \"${baseline_name}\"
  baseline_config_fp = \"${baseline_config_fp}\""
  fi

  experiment_name="${baseline_name}"
  for (( j=0; j<${num_mod_vars}; j++ )); do
    if [ $j -lt ${#modvar_name[@]} ]; then
      experiment_name="${experiment_name}__${modvar_name[$j]}=${modvar_value[$j]}"
    else
      break
    fi
  done
echo
echo "experiment_name = '${experiment_name}'"

  experiment_config_fp="${USHDIR}/config.${experiment_name}.sh"
  cp_vrfy "${baseline_config_fp}" "${experiment_config_fp}"

  EXPT_SUBDIR="${experiment_name}"

  set_bash_param "${experiment_config_fp}" "MACHINE" "$MACHINE"
  set_bash_param "${experiment_config_fp}" "ACCOUNT" "$ACCOUNT"
  set_bash_param "${experiment_config_fp}" "QUEUE_DEFAULT" "${QUEUE_DEFAULT}"
  set_bash_param "${experiment_config_fp}" "QUEUE_HPSS" "${QUEUE_HPSS}"
  set_bash_param "${experiment_config_fp}" "QUEUE_FCST" "${QUEUE_FCST}"
#  set_bash_param "${experiment_config_fp}" "VERBOSE" "$VERBOSE"
  set_bash_param "${experiment_config_fp}" "EXPT_SUBDIR" "${EXPT_SUBDIR}"

  ln_vrfy -fs "${experiment_config_fp}" "$USHDIR/config.sh"
  
  log_fp="$USHDIR/log.generate_wflow.${experiment_name}"
  $USHDIR/generate_FV3SAR_wflow.sh 2>&1 >& "${log_fp}" || { \
    print_err_msg_exit "\
Could not generate an experiment/workflow for the test specified by 
experiment_name:
  experiment_name = \"${experiment_name}\"
The log file from the generation script is in the file specified by 
log_fp:
  log_fp = \"${log_fp}\"";
  }
#
#-----------------------------------------------------------------------
#
# Set the experiment directory to the one that the workflow will create.
# Then move the configuration file and experiment/workflow generation 
# log file to the experiment directory.
#
#-----------------------------------------------------------------------
#
  EXPTDIR=$( readlink -f "$HOMErrfs/../expt_dirs/${EXPT_SUBDIR}" )
  mv_vrfy "${experiment_config_fp}" "${EXPTDIR}"
  mv_vrfy "${log_fp}" "${EXPTDIR}"
#
#-----------------------------------------------------------------------
#
# Create a script in the run directory that can be used to (re)launch 
# the workflow and report on its status.  This script saves its output 
# to a log file (in the run directory) for debugging purposes and to al-
# low the user to check on the status of the workflow.
#
#-----------------------------------------------------------------------
#
  cd_vrfy $EXPTDIR

  xml_bn="FV3SAR_wflow"
  xml_fn="${xml_bn}.xml"
  db_fn="${xml_bn}.db"
  relaunch_script_fn="relaunch_wflow.sh"

  { cat << EOM > ${relaunch_script_fn}
#!/bin/bash -l

module load rocoto
cd "$EXPTDIR"
{
rocotorun -w "${xml_fn}" -d "${db_fn}" -v 10;
echo;
rocotostat -w "${xml_fn}" -d "${db_fn}" -v 10; 
} >> log.rocotostat 2>&1

dead_tasks=$( rocotostat -w "${xml_fn}" -d "${db_fn}" -v 10 | grep "DEAD" )
if [ ! -z ${dead_tasks} ]; then
  printf "%s\n" "
The end-to-end workflow test for the experiment specified below FAILED:
  experiment_name = \"${experiment_name}\"
Removing the corresponding line from the crontab file.\n"
fi
EOM
  } || print_err_msg_exit "\
cat operation to create a relaunch script (relaunch_script_fn) in the experi-
ment directory (EXPTDIR) failed:
  EXPTDIR = \"$EXPTDIR\"
  relaunch_script_fn = \"${relaunch_script_fn}\""
#
# Make the relaunch script executable.
#
  chmod u+x ${relaunch_script_fn}
#
#-----------------------------------------------------------------------
#
# Add a line to the user's cron table to call the (re)launch script at
# some frequency (e.g. every 5 minutes).
#
#-----------------------------------------------------------------------
#
  crontab_orig_fp="$(pwd)/crontab.orig"
  print_info_msg "
Copying contents of user cron table to backup file:
  crontab_orig_fp = \"${crontab_orig_fp}\""
  crontab -l > ${crontab_orig_fp}

  crontab_line="*/5 * * * * cd $EXPTDIR && ./${relaunch_script_fn}" 
#
# Below, we use "grep" to determine whether the above crontab line is 
# already present in the cron table.  For that purpose, we need to es-
# cape the asterisks in the crontab line with backslashes.  Do this 
# next.
#
  crontab_line_esc_astr=$( printf "%s" "${crontab_line}" | \
                           sed -r -e "s![*]!\\\\*!g" )
  grep_output=$( crontab -l | grep "${crontab_line_esc_astr}" )
  exit_status=$?

  if [ "${exit_status}" -eq 0 ]; then

    print_info_msg "
The following line already exists in the cron table and thus will not be
added:
  crontab_line = \"${crontab_line}\""
  
  else

    print_info_msg "
Adding the following line to the cron table in order to automatically
resubmit FV3SAR workflow:
  crontab_line = \"${crontab_line}\""

    (crontab -l 2>/dev/null; echo "${crontab_line}") | crontab -

  fi
#
#-----------------------------------------------------------------------
#
# Increment the index that keeps track of the test/experiment number.
#
#-----------------------------------------------------------------------
#
  i=$((i+1))

done
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

