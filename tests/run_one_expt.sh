#!/bin/bash -l

#
#-----------------------------------------------------------------------
#
# Set directories.
#
#-----------------------------------------------------------------------
#
basedir="$(pwd)/../.."
USHDIR="$basedir/regional_workflow/ush"
#
#-----------------------------------------------------------------------
#
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
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
# Set the script name and print out an informational message informing
# the user that we've entered this script.
#
#-----------------------------------------------------------------------
#
script_name=$( basename "${BASH_SOURCE[0]}" )
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
"verbose" \
"run_envir" \
"predef_domain" \
"grid_gen_method" \
"use_CCPP" \
"phys_suite" \
"cdate" \
"fcst_len_hrs" \
"quilting" \
)
process_args valid_args "$@"

# If verbose is set to TRUE, print out what each valid argument has been
# set to.
if [ "$verbose" = "TRUE" ]; then
  num_valid_args="${#valid_args[@]}"
  print_info_msg "\n\
The arguments to script/function \"${script_name}\" have been set as 
follows:
"
  for (( i=0; i<$num_valid_args; i++ )); do
    line=$( declare -p "${valid_args[$i]}" )
    printf "  $line\n"
  done
fi
#
#-----------------------------------------------------------------------
#
# Set defaults for various 
#
#-----------------------------------------------------------------------
#
run_envir=${run_envir:-"community"}
machine=${machine:-"hera"}
account=${account:-"gsd-fv3"}
queue_default=${queue_default:-"batch"}
queue_hpss=${queue_hpss:-"service"}
queue_fcst=${queue_hpss:-"batch"}

basedir=${basedir:-"/path/to/your/workflow/base/directory"}
expt_basedir=${expt_basedir:-"$basedir/expt_dirs"}
expt_subdir=${expt_subdir:-""}

predef_domain=${predef_domain:-"GSD_HRRR25km"}
grid_gen_method=${grid_gen_method:-"JPgrid"}
use_CCPP=${use_CCPP:-"TRUE"}
phys_suite=${phys_suite:-"GFS"}
quilting=${quilting:-"TRUE"}

extrn_mdl_name_ics=${extrn_mdl_name_ics:-"FV3GFS"}
extrn_mdl_name_lbcs=${extrn_mdl_name_ics:-"FV3GFS"}

run_task_make_grid="${run_task_make_grid:-"TRUE"}"
run_task_make_orog="${run_task_make_orog:-"TRUE"}"
run_task_make_sfc_climo="${run_task_make_sfc_climo:-"TRUE"}"

date_first_cycl=${date_first_cycl:-""}
date_last_cycl=${date_last_cycl:-""}
cycl_hrs=${cycl_hrs:-""}
fcst_len_hrs=${fcst_len_hrs:-}
lbc_update_intvl_hrs=${lbc_update_intvl_hrs:-"3"}

if [ -z "${basedir}" ]; then
  print_err_msg_exit "${script_name}" "
A base directory must be specified.
"
#
#-----------------------------------------------------------------------
#
# Check arguments.
#
#-----------------------------------------------------------------------
#
if [ 0 = 1 ]; then

if [ "$#" -ne 7 ]; then

  printf "\

Script \"$0\":  Incorrect number of arguments specified.
Usage:

  $0  predef_domain  grid_gen_method  use_CCPP  phys_suite  CDATE  fcst_len_hrs  quilting

where the arguments are defined as follows:

  predef_domain:
  The predefined domain to use.

  grid_gen_method:
  The horizontal grid generation method to use.

  use_CCPP
  Whether or not to run a CCPP-enabled verson of the FV3SAR.

  phys_suite
  The physics suite to use.

  CDATE
  The starting date (and hour) of the forecast.

  fsct_len_hrs
  The length of the forecast, in hours.

  quilting
  Whether or not to use the write-component to write output files.

These are described in more detail in the documentation of the FV3SAR 
workflow.

Exiting script with nonzero exit code.\n"

  exit 1

fi
fi
#
#-----------------------------------------------------------------------
#
# Set forecast parameters.
#
#-----------------------------------------------------------------------
#
predef_domain=${1:-}
grid_gen_method=${2:-}
use_CCPP=${3:-}
phys_suite=${4:-}
CDATE=${5:-}
fcst_len_hrs=${6:-}
quilting="${7:-}"

dot_quilting=".${quilting}."

print_info_msg "\
User-specified forecast parameters:

  predef_domain = \"${predef_domain}\"
  grid_gen_method = \"${grid_gen_method}\"
  use_CCPP = \"${use_CCPP}\"
  phys_suite = \"${phys_suite}\"
  CDATE = \"${CDATE}\"
  fcst_len_hrs = \"${fcst_len_hrs}\"
  quilting = \"${quilting}\""
#
#-----------------------------------------------------------------------
#
# Construct new variables based on input arguments.
#
#-----------------------------------------------------------------------
#
CONFIG_FN="config.sh"
CONFIG_FP="${USHDIR}/${CONFIG_FN}"

EXPT_NAME="${predef_domain}_${grid_gen_method}_CCPP${use_CCPP}_${phys_suite}phys_${CDATE}_FCST${fcst_len_hrs}hrs_QUILT$quilting"
#TEST_DATE=$( date "+%Y%m%d-%H_%M" )
TEST_DATE=$( date "+%Y%m%d" )
RUNDIR_BASE="$BASEDIR/run_dirs"
RUN_SUBDIR="test_date_${TEST_DATE}/$EXPT_NAME"
TMPDIR="$BASEDIR/work_dirs"

print_info_msg "\
Variables constructed from user-specified forecast parameters:

  BASEDIR = \"${BASEDIR}\"
  USHDIR = \"${USHDIR}\"
  CONFIG_FN = \"${CONFIG_FN}\"
  CONFIG_FP = \"${CONFIG_FP}\"

  EXPT_NAME = \"${EXPT_NAME}\"
  TEST_DATE = \"${TEST_DATE}\"
  RUNDIR_BASE = \"${RUNDIR_BASE}\"
  RUN_SUBDIR = \"${RUN_SUBDIR}\""
#
#-----------------------------------------------------------------------
#
# The GSD physics suite cannot be run without CCPP.  Check for this and
# issue an error message if found.
#
#-----------------------------------------------------------------------
#
if [ $use_CCPP = "false" ] && [ $phys_suite = "GSD" ]; then

  print_err_msg_exit "\
The GSD physics suite cannot be run without CCPP:
  use_CCPP = \"${use_CCPP}\"
  phys_suite = \"${phys_suite}\"
Not generating a workflow for this set of experiment parameters."

fi
#
#-----------------------------------------------------------------------
#
# Use a heredoc to construct the configuration file for the forecast.  
# Note that whatever is not specified in this file is obtained from 
# config_defaults.sh.
#
#-----------------------------------------------------------------------
#
{ cat << EOM > $CONFIG_FP
#
#-----------------------------------------------------------------------
#
# This is the local workflow configuration file.  It is not tracked by 
# the git repository.
#
#-----------------------------------------------------------------------
#
RUN_ENVIR="${run_envir}"
MACHINE="${machine}"
ACCOUNT="${account}"
QUEUE_DEFAULT="${queue_default}"
QUEUE_HPSS="${queue_hpss}"
QUEUE_FCST="${queue_fcst}"
#
BASEDIR="${basedir}"
EXPT_BASEDIR="${expt_basedir}"
EXPT_SUBDIR="${expt_subdir}"
#
DATE_FIRST_CYCL="${date_first_cycl}"
DATE_LAST_CYCL="${date_last_cycl}"
CYCL_HRS="${cycl_hrs}"
FCST_LEN_HRS="${fcst_len_hrs}"
LBC_UPDATE_INTVL_HRS="${lbc_update_intvl_hrs}"

RUNDIR_BASE="$RUNDIR_BASE"
RUN_SUBDIR="$RUN_SUBDIR"
#
CDATE="$CDATE"
fcst_len_hrs="$fcst_len_hrs"
BC_update_intvl_hrs="6"
#
run_title=""
#
predef_domain="$predef_domain"
#
grid_gen_method="$grid_gen_method"
#
preexisting_dir_method="delete"
quilting="$dot_quilting"
#
use_CCPP="$use_CCPP"
phys_suite="$phys_suite"
EOM
}
#
#-----------------------------------------------------------------------
#
# Generate workflow XML for the specified experiment configuration and
# save the output in a log file for debugging.  Then move the log file
# to the run directory.
#
#-----------------------------------------------------------------------
#
cd_vrfy $USHDIR
LOG_GEN_WFLOW_FP="$USHDIR/log.generate_FV3SAR_wflow"
./generate_FV3SAR_wflow.sh > "$LOG_GEN_WFLOW_FP" 2>&1
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
  print_err_msg_exit "\
Workflow generation script returned with a nonzero exit status.
Check the log file located at:
  LOG_GEN_WFLOW_FP = \"$LOG_GEN_WFLOW_FP\""
fi

RUNDIR="$RUNDIR_BASE/$RUN_SUBDIR"
mv_vrfy log.generate_FV3SAR_wflow $RUNDIR
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
cd_vrfy $RUNDIR

XML_BASENAME="FV3SAR_wflow"
RELAUNCH_SCR="relaunch_wflow.sh"

{ cat << EOM > ${RELAUNCH_SCR}
#!/bin/sh -l

module load rocoto/1.3.0
cd $RUNDIR
{
rocotorun -w ${XML_BASENAME}.xml -d ${XML_BASENAME}.db -v 10 ;
echo ;
rocotostat -w ${XML_BASENAME}.xml -d ${XML_BASENAME}.db -v 10 ; 
} >> log.rocotostat 2>&1
EOM
}
#
# Make the relaunch script executable.
#
chmod u+x $RELAUNCH_SCR
#
#-----------------------------------------------------------------------
#
# Add a line to the user's cron table to call the (re)launch script at
# some frequency (e.g. every 5 minutes).
#
#-----------------------------------------------------------------------
#
CRONTAB_ORIG="$(pwd)/crontab.orig"
print_info_msg "\
Copying contents of user cron table to backup file:
  CRONTAB_ORIG = \"$CRONTAB_ORIG\""
crontab -l > $CRONTAB_ORIG

crontab_line="*/5 * * * * cd $RUNDIR && ./$RELAUNCH_SCR" 
#
# Below, we use "grep" to determine whether the above crontab line is 
# already present in the cron table.  For that purpose, we need to es-
# cape the asterisks in the crontab line with backslashes.  Do this 
# next.
#
crontab_line_esc_astr=$( echo "$crontab_line" | sed -r -e "s![*]!\\\\*!g" )
grep_output=$( crontab -l | grep "$crontab_line_esc_astr" )
exit_status=$?

if [ "$exit_status" -eq 0 ]; then

  print_info_msg "\
The following line already exists in the cron table and thus will not be
added:
  crontab_line = \"$crontab_line\""
  
else

  print_info_msg "\
Adding the following line to the cron table in order to automatically
resubmit FV3SAR workflow:
  crontab_line = \"$crontab_line\""

  (crontab -l 2>/dev/null; echo "$crontab_line") | crontab -

fi

#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

