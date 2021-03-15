#
#-----------------------------------------------------------------------
#
# This file defines and then calls a function that sets a secondary set
# of parameters needed by the various scripts that are called by the 
# FV3-LAM rocoto community workflow.  This secondary set of parameters is 
# calculated using the primary set of user-defined parameters in the de-
# fault and custom experiment/workflow configuration scripts (whose file
# names are defined below).  This script then saves both sets of parame-
# ters in a global variable definitions file (really a bash script) in 
# the experiment directory.  This file then gets sourced by the various 
# scripts called by the tasks in the workflow.
#
#-----------------------------------------------------------------------
#
function setup() {
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
local scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
local scrfunc_fn=$( basename "${scrfunc_fp}" )
local scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
cd_vrfy ${scrfunc_dir}
#
#-----------------------------------------------------------------------
#
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
. ./source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Source other necessary files.
#
#-----------------------------------------------------------------------
#
. ./set_cycle_dates.sh
. ./set_gridparams_GFDLgrid.sh
. ./set_gridparams_ESGgrid.sh
. ./link_fix.sh
. ./set_ozone_param.sh
. ./set_thompson_mp_fix_files.sh
. ./check_ruc_lsm.sh
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
# Set the name of the configuration file containing default values for
# the experiment/workflow variables.  Then source the file.
#
#-----------------------------------------------------------------------
#
EXPT_DEFAULT_CONFIG_FN="config_defaults.sh"
. ./${EXPT_DEFAULT_CONFIG_FN}
#
#-----------------------------------------------------------------------
#
# If a user-specified configuration file exists, source it.  This file
# contains user-specified values for a subset of the experiment/workflow 
# variables that override their default values.  Note that the user-
# specified configuration file is not tracked by the repository, whereas
# the default configuration file is tracked.
#
#-----------------------------------------------------------------------
#
if [ -f "${EXPT_CONFIG_FN}" ]; then
#
# We require that the variables being set in the user-specified configu-
# ration file have counterparts in the default configuration file.  This
# is so that we do not introduce new variables in the user-specified 
# configuration file without also officially introducing them in the de-
# fault configuration file.  Thus, before sourcing the user-specified 
# configuration file, we check that all variables in the user-specified
# configuration file are also assigned default values in the default 
# configuration file.
#
  . ./compare_config_scripts.sh
#
# Now source the user-specified configuration file.
#
  . ./${EXPT_CONFIG_FN}
#
fi
#
#-----------------------------------------------------------------------
#
# Source the script defining the valid values of experiment variables.
#
#-----------------------------------------------------------------------
#
. ./valid_param_vals.sh
#
#-----------------------------------------------------------------------
#
# Make sure that RUN_ENVIR is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "RUN_ENVIR" "valid_vals_RUN_ENVIR"
#
#-----------------------------------------------------------------------
#
# Make sure that VERBOSE is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "VERBOSE" "valid_vals_VERBOSE"
#
# Set VERBOSE to either "TRUE" or "FALSE" so we don't have to consider
# other valid values later on.
#
VERBOSE=${VERBOSE^^}
if [ "$VERBOSE" = "TRUE" ] || \
   [ "$VERBOSE" = "YES" ]; then
  VERBOSE="TRUE"
elif [ "$VERBOSE" = "FALSE" ] || \
     [ "$VERBOSE" = "NO" ]; then
  VERBOSE="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that USE_CRON_TO_RELAUNCH is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "USE_CRON_TO_RELAUNCH" "valid_vals_USE_CRON_TO_RELAUNCH"
#
# Set USE_CRON_TO_RELAUNCH to either "TRUE" or "FALSE" so we don't have to consider
# other valid values later on.
#
USE_CRON_TO_RELAUNCH=${USE_CRON_TO_RELAUNCH^^}
if [ "${USE_CRON_TO_RELAUNCH}" = "TRUE" ] || \
   [ "${USE_CRON_TO_RELAUNCH}" = "YES" ]; then
  USE_CRON_TO_RELAUNCH="TRUE"
elif [ "${USE_CRON_TO_RELAUNCH}" = "FALSE" ] || \
     [ "${USE_CRON_TO_RELAUNCH}" = "NO" ]; then
  USE_CRON_TO_RELAUNCH="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that RUN_TASK_MAKE_GRID is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "RUN_TASK_MAKE_GRID" "valid_vals_RUN_TASK_MAKE_GRID"
#
# Set RUN_TASK_MAKE_GRID to either "TRUE" or "FALSE" so we don't have to
# consider other valid values later on.
#
RUN_TASK_MAKE_GRID=${RUN_TASK_MAKE_GRID^^}
if [ "${RUN_TASK_MAKE_GRID}" = "TRUE" ] || \
   [ "${RUN_TASK_MAKE_GRID}" = "YES" ]; then
  RUN_TASK_MAKE_GRID="TRUE"
elif [ "${RUN_TASK_MAKE_GRID}" = "FALSE" ] || \
     [ "${RUN_TASK_MAKE_GRID}" = "NO" ]; then
  RUN_TASK_MAKE_GRID="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that RUN_TASK_MAKE_OROG is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "RUN_TASK_MAKE_OROG" "valid_vals_RUN_TASK_MAKE_OROG"
#
# Set RUN_TASK_MAKE_OROG to either "TRUE" or "FALSE" so we don't have to
# consider other valid values later on.
#
RUN_TASK_MAKE_OROG=${RUN_TASK_MAKE_OROG^^}
if [ "${RUN_TASK_MAKE_OROG}" = "TRUE" ] || \
   [ "${RUN_TASK_MAKE_OROG}" = "YES" ]; then
  RUN_TASK_MAKE_OROG="TRUE"
elif [ "${RUN_TASK_MAKE_OROG}" = "FALSE" ] || \
     [ "${RUN_TASK_MAKE_OROG}" = "NO" ]; then
  RUN_TASK_MAKE_OROG="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that RUN_TASK_MAKE_SFC_CLIMO is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value \
  "RUN_TASK_MAKE_SFC_CLIMO" "valid_vals_RUN_TASK_MAKE_SFC_CLIMO"
#
# Set RUN_TASK_MAKE_SFC_CLIMO to either "TRUE" or "FALSE" so we don't
# have to consider other valid values later on.
#
RUN_TASK_MAKE_SFC_CLIMO=${RUN_TASK_MAKE_SFC_CLIMO^^}
if [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "TRUE" ] || \
   [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "YES" ]; then
  RUN_TASK_MAKE_SFC_CLIMO="TRUE"
elif [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "FALSE" ] || \
     [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "NO" ]; then
  RUN_TASK_MAKE_SFC_CLIMO="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that DO_SHUM is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "DO_SHUM" "valid_vals_DO_SHUM"
#
# Set DO_SHUM to either "TRUE" or "FALSE" so we don't
# have to consider other valid values later on.
#
DO_SHUM=${DO_SHUM^^}
if [ "${DO_SHUM}" = "TRUE" ] || \
   [ "${DO_SHUM}" = "YES" ]; then
  DO_SHUM="TRUE"
elif [ "${DO_SHUM}" = "FALSE" ] || \
     [ "${DO_SHUM}" = "NO" ]; then
  DO_SHUM="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that DO_SPPT is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "DO_SPPT" "valid_vals_DO_SPPT"
#
# Set DO_SPPT to either "TRUE" or "FALSE" so we don't
# have to consider other valid values later on.
#
DO_SPPT=${DO_SPPT^^}
if [ "${DO_SPPT}" = "TRUE" ] || \
   [ "${DO_SPPT}" = "YES" ]; then
  DO_SPPT="TRUE"
elif [ "${DO_SPPT}" = "FALSE" ] || \
     [ "${DO_SPPT}" = "NO" ]; then
  DO_SPPT="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that DO_SKEB is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "DO_SKEB" "valid_vals_DO_SKEB"
#
# Set DO_SKEB to either "TRUE" or "FALSE" so we don't
# have to consider other valid values later on.
#
DO_SKEB=${DO_SKEB^^}
if [ "${DO_SKEB}" = "TRUE" ] || \
   [ "${DO_SKEB}" = "YES" ]; then
  DO_SKEB="TRUE"
elif [ "${DO_SKEB}" = "FALSE" ] || \
     [ "${DO_SKEB}" = "NO" ]; then
  DO_SKEB="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that DO_SPP is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "DO_SPP" "valid_vals_DO_SPP"
#
# Set DO_SPP to either "TRUE" or "FALSE" so we don't
# have to consider other valid values later on.
#
DO_SPP=${DO_SPP^^}
if [ "${DO_SPP}" = "TRUE" ] || \
   [ "${DO_SPP}" = "YES" ]; then
  DO_SPP="TRUE"
elif [ "${DO_SPP}" = "FALSE" ] || \
     [ "${DO_SPP}" = "NO" ]; then
  DO_SPP="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Set magnitude of stochastic ad-hoc schemes to -999.0 if they are not
# being used. This is required at the moment, since "do_shum/sppt/skeb"
# does not override the use of the scheme unless the magnitude is also
# specifically set to -999.0.  If all "do_shum/sppt/skeb" are set to
# "false," then none will run, regardless of the magnitude values. 
#
#-----------------------------------------------------------------------
#
if [ "${DO_SHUM}" = "FALSE" ]; then
  SHUM_MAG=-999.0
fi
if [ "${DO_SKEB}" = "FALSE" ]; then
  SKEB_MAG=-999.0
fi
if [ "${DO_SPPT}" = "FALSE" ]; then
  SPPT_MAG=-999.0
fi
#
#-----------------------------------------------------------------------
#
# If running with SPP, count the number of entries in SPP_VAR_LIST to
# correctly set N_VAR_SPP, otherwise set it to zero. 
#
#-----------------------------------------------------------------------
#
N_VAR_SPP=0
if [ "${DO_SPP}" = "TRUE" ]; then
  N_VAR_SPP=${#SPP_VAR_LIST[@]}
fi
#
#-----------------------------------------------------------------------
#
# Make sure that USE_FVCOM is set to a valid value and assign directory
# and file names.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "USE_FVCOM" "valid_vals_USE_FVCOM"
#
# Set USE_FVCOM to either "TRUE" or "FALSE" so we don't have to consider
# other valid values later on.
#
USE_FVCOM=${USE_FVCOM^^}
if [ "$USE_FVCOM" = "TRUE" ] || \
   [ "$USE_FVCOM" = "YES" ]; then
  USE_FVCOM="TRUE"
elif [ "$USE_FVCOM" = "FALSE" ] || \
     [ "$USE_FVCOM" = "NO" ]; then
  USE_FVCOM="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that SUB_HOURLY_POST is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "SUB_HOURLY_POST" "valid_vals_SUB_HOURLY_POST"
#
# Set SUB_HOURLY_POST to either "TRUE" or "FALSE" so we don't have to consider
# other valid values later on.
#
SUB_HOURLY_POST=${SUB_HOURLY_POST^^}
if [ "$SUB_HOURLY_POST" = "TRUE" ] || \
   [ "$SUB_HOURLY_POST" = "YES" ]; then
  SUB_HOURLY_POST="TRUE"
elif [ "$SUB_HOURLY_POST" = "FALSE" ] || \
     [ "$SUB_HOURLY_POST" = "NO" ]; then
  SUB_HOURLY_POST="FALSE"
fi

if [ "${DT_SUBHOURLY_POST_MNTS}" -eq "0" ]; then
  SUB_HOURLY_POST="FALSE"
  print_info_msg "NOTE: since you have set DT_SUBHOURLY_POST_MNTS to '00', then 
  SUB_HOURLY_POST is being overwritten to FALSE. If you do not want this, you 
  must set DT_SUBHOURLY_POST_MNTS to something other than '00.'"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that DOT_OR_USCORE is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "DOT_OR_USCORE" "valid_vals_DOT_OR_USCORE"
#
#-----------------------------------------------------------------------
#
# Convert machine name to upper case if necessary.  Then make sure that
# MACHINE is set to a valid value.
#
#-----------------------------------------------------------------------
#
MACHINE=$( printf "%s" "$MACHINE" | sed -e 's/\(.*\)/\U\1/' )
check_var_valid_value "MACHINE" "valid_vals_MACHINE"
#
#-----------------------------------------------------------------------
#
# Set the number of cores per node, the job scheduler, and the names of
# several queues.  These queues are defined in the default and local 
# workflow/experiment configuration script.
#
#-----------------------------------------------------------------------
#
case $MACHINE in

  "WCOSS_CRAY")
    NCORES_PER_NODE="24"
    SCHED="lsfcray"
    QUEUE_DEFAULT=${QUEUE_DEFAULT:-"dev"}
    QUEUE_HPSS=${QUEUE_HPSS:-"dev_transfer"}
    QUEUE_FCST=${QUEUE_FCST:-"dev"}
    ;;

  "WCOSS_DELL_P3")
    NCORES_PER_NODE=24
    SCHED="lsf"
    QUEUE_DEFAULT=${QUEUE_DEFAULT:-"dev"}
    QUEUE_HPSS=${QUEUE_HPSS:-"dev_transfer"}
    QUEUE_FCST=${QUEUE_FCST:-"dev"}
    ;;

  "HERA")
    NCORES_PER_NODE=40
    SCHED="${SCHED:-slurm}"
    PARTITION_DEFAULT=${PARTITION_DEFAULT:-"hera"}
    QUEUE_DEFAULT=${QUEUE_DEFAULT:-"batch"}
    PARTITION_HPSS=${PARTITION_HPSS:-"service"}
    QUEUE_HPSS=${QUEUE_HPSS:-"batch"}
    PARTITION_FCST=${PARTITION_FCST:-"hera"}
    QUEUE_FCST=${QUEUE_FCST:-"batch"}
    ;;

  "ORION")
    NCORES_PER_NODE=40
    SCHED="${SCHED:-slurm}"
    PARTITION_DEFAULT=${PARTITION_DEFAULT:-"orion"}
    QUEUE_DEFAULT=${QUEUE_DEFAULT:-"batch"}
    PARTITION_HPSS=${PARTITION_HPSS:-"service"}
    QUEUE_HPSS=${QUEUE_HPSS:-"batch"}
    PARTITION_FCST=${PARTITION_FCST:-"orion"}
    QUEUE_FCST=${QUEUE_FCST:-"batch"}
    ;;

  "JET")
    NCORES_PER_NODE=24
    SCHED="${SCHED:-slurm}"
    PARTITION_DEFAULT=${PARTITION_DEFAULT:-"sjet,vjet,kjet,xjet"}
    QUEUE_DEFAULT=${QUEUE_DEFAULT:-"batch"}
    PARTITION_HPSS=${PARTITION_HPSS:-"service"}
    QUEUE_HPSS=${QUEUE_HPSS:-"batch"}
    PARTITION_FCST=${PARTITION_FCST:-"sjet,vjet,kjet,xjet"}
    QUEUE_FCST=${QUEUE_FCST:-"batch"}
    ;;

  "ODIN")
    NCORES_PER_NODE=24
    SCHED="${SCHED:-slurm}"
    PARTITION_DEFAULT=${PARTITION_DEFAULT:-"workq"}
    QUEUE_DEFAULT=${QUEUE_DEFAULT:-"workq"}
    PARTITION_HPSS=${PARTITION_HPSS:-"workq"}
    QUEUE_HPSS=${QUEUE_HPSS:-"workq"}
    PARTITION_FCST=${PARTITION_FCST:-"workq"}
    QUEUE_FCST=${QUEUE_FCST:-"workq"}
    ;;

  "CHEYENNE")
    NCORES_PER_NODE=36
    SCHED="${SCHED:-pbspro}"
    QUEUE_DEFAULT=${QUEUE_DEFAULT:-"regular"}
    QUEUE_HPSS=${QUEUE_HPSS:-"regular"}
    QUEUE_FCST=${QUEUE_FCST:-"regular"}
    ;;

  "STAMPEDE")
    NCORES_PER_NODE=68
    SCHED="slurm"
    PARTITION_DEFAULT=${PARTITION_DEFAULT:-"normal"}
    QUEUE_DEFAULT=${QUEUE_DEFAULT:-"normal"}
    PARTITION_HPSS=${PARTITION_HPSS:-"normal"}
    QUEUE_HPSS=${QUEUE_HPSS:-"normal"}
    PARTITION_FCST=${PARTITION_FCST:-"normal"}
    QUEUE_FCST=${QUEUE_FCST:-"normal"}
    ;;

esac
#
#-----------------------------------------------------------------------
#
# Make sure that the job scheduler set above is valid.
#
#-----------------------------------------------------------------------
#
SCHED="${SCHED,,}"
check_var_valid_value "SCHED" "valid_vals_SCHED"
#
#-----------------------------------------------------------------------
#
# Verify that the ACCOUNT variable is not empty.  If it is, print out an
# error message and exit.
#
#-----------------------------------------------------------------------
#
if [ -z "$ACCOUNT" ]; then
  print_err_msg_exit "\
The variable ACCOUNT cannot be empty:
  ACCOUNT = \"$ACCOUNT\""
fi
#
#-----------------------------------------------------------------------
#
# Set the grid type (GTYPE).  In general, in the FV3 code, this can take
# on one of the following values: "global", "stretch", "nest", and "re-
# gional".  The first three values are for various configurations of a
# global grid, while the last one is for a regional grid.  Since here we
# are only interested in a regional grid, GTYPE must be set to "region-
# al".
#
#-----------------------------------------------------------------------
#
GTYPE="regional"
TILE_RGNL="7"
#
#-----------------------------------------------------------------------
#
# Make sure that GTYPE is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "GTYPE" "valid_vals_GTYPE"
#
#-----------------------------------------------------------------------
#
# Make sure PREDEF_GRID_NAME is set to a valid value.
#
#-----------------------------------------------------------------------
#
if [ ! -z ${PREDEF_GRID_NAME} ]; then
  err_msg="\
The predefined regional grid specified in PREDEF_GRID_NAME is not sup-
ported:
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\""
  check_var_valid_value \
    "PREDEF_GRID_NAME" "valid_vals_PREDEF_GRID_NAME" "${err_msg}"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that PREEXISTING_DIR_METHOD is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value \
  "PREEXISTING_DIR_METHOD" "valid_vals_PREEXISTING_DIR_METHOD"
#
#-----------------------------------------------------------------------
#
# Make sure CCPP_PHYS_SUITE is set to a valid value.
#
#-----------------------------------------------------------------------
#
err_msg="\
The CCPP physics suite specified in CCPP_PHYS_SUITE is not supported:
  CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\""
check_var_valid_value \
  "CCPP_PHYS_SUITE" "valid_vals_CCPP_PHYS_SUITE" "${err_msg}"
#
#-----------------------------------------------------------------------
#
# Check that DATE_FIRST_CYCL and DATE_LAST_CYCL are strings consisting 
# of exactly 8 digits.
#
#-----------------------------------------------------------------------
#
DATE_OR_NULL=$( printf "%s" "${DATE_FIRST_CYCL}" | \
                sed -n -r -e "s/^([0-9]{8})$/\1/p" )
if [ -z "${DATE_OR_NULL}" ]; then
  print_err_msg_exit "\
DATE_FIRST_CYCL must be a string consisting of exactly 8 digits of the 
form \"YYYYMMDD\", where YYYY is the 4-digit year, MM is the 2-digit 
month, and DD is the 2-digit day-of-month.
  DATE_FIRST_CYCL = \"${DATE_FIRST_CYCL}\""
fi

DATE_OR_NULL=$( printf "%s" "${DATE_LAST_CYCL}" | \
                sed -n -r -e "s/^([0-9]{8})$/\1/p" )
if [ -z "${DATE_OR_NULL}" ]; then
  print_err_msg_exit "\
DATE_LAST_CYCL must be a string consisting of exactly 8 digits of the 
form \"YYYYMMDD\", where YYYY is the 4-digit year, MM is the 2-digit 
month, and DD is the 2-digit day-of-month.
  DATE_LAST_CYCL = \"${DATE_LAST_CYCL}\""
fi
#
#-----------------------------------------------------------------------
#
# Check that DT_SUBHOURLY_POST_MNTS is a string consisting of exactly 2 digits between "00" and "59"
#
#-----------------------------------------------------------------------
#
min_or_null=$( printf "%s" "${DT_SUBHOURLY_POST_MNTS}" | \
                sed -n -r -e "s/^([0-5][0-9])$/\1/p" )
if [ -z "${min_or_null}" ]; then
  print_err_msg_exit "\
DT_SUBHOURLY_POST_MNTS must be a 2-digit integer between 00 and 59 inclusive, as "MM".
  DT_SUBHOURLY_POST_MNTS = \"${DT_SUBHOURLY_POST_MNTS}\""
fi
#
#-----------------------------------------------------------------------
#
# Check that all elements of CYCL_HRS are strings consisting of exactly
# 2 digits that are between "00" and "23", inclusive.
#
#-----------------------------------------------------------------------
#
CYCL_HRS_str=$(printf "\"%s\" " "${CYCL_HRS[@]}")
CYCL_HRS_str="( $CYCL_HRS_str)"

i=0
for CYCL in "${CYCL_HRS[@]}"; do

  CYCL_OR_NULL=$( printf "%s" "$CYCL" | sed -n -r -e "s/^([0-9]{2})$/\1/p" )

  if [ -z "${CYCL_OR_NULL}" ]; then
    print_err_msg_exit "\
Each element of CYCL_HRS must be a string consisting of exactly 2 digits
(including a leading \"0\", if necessary) specifying an hour-of-day.  Ele-
ment #$i of CYCL_HRS (where the index of the first element is 0) does not
have this form:
  CYCL_HRS = $CYCL_HRS_str
  CYCL_HRS[$i] = \"${CYCL_HRS[$i]}\""
  fi

  if [ "${CYCL_OR_NULL}" -lt "0" ] || \
     [ "${CYCL_OR_NULL}" -gt "23" ]; then
    print_err_msg_exit "\
Each element of CYCL_HRS must be an integer between \"00\" and \"23\", in-
clusive (including a leading \"0\", if necessary), specifying an hour-of-
day.  Element #$i of CYCL_HRS (where the index of the first element is 0) 
does not have this form:
  CYCL_HRS = $CYCL_HRS_str
  CYCL_HRS[$i] = \"${CYCL_HRS[$i]}\""
  fi

  i=$(( $i+1 ))

done
#
#-----------------------------------------------------------------------
#
# Call a function to generate the array ALL_CDATES containing the cycle 
# dates/hours for which to run forecasts.  The elements of this array
# will have the form YYYYMMDDHH.  They are the starting dates/times of 
# the forecasts that will be run in the experiment.  Then set NUM_CYCLES
# to the number of elements in this array.
#
#-----------------------------------------------------------------------
#
set_cycle_dates \
  date_start="${DATE_FIRST_CYCL}" \
  date_end="${DATE_LAST_CYCL}" \
  cycle_hrs="${CYCL_HRS_str}" \
  output_varname_all_cdates="ALL_CDATES"

NUM_CYCLES="${#ALL_CDATES[@]}"
#
#-----------------------------------------------------------------------
#
# Set various directories.
#
# HOMErrfs:
# Top directory of the clone of the FV3-LAM workflow git repository.
#
# USHDIR:
# Directory containing the shell scripts called by the workflow.
#
# SCRIPTSDIR:
# Directory containing the ex scripts called by the workflow.
#
# JOBSSDIR:
# Directory containing the jjobs scripts called by the workflow.
#
# SORCDIR:
# Directory containing various source codes.
#
# PARMDIR:
# Directory containing parameter files, template files, etc.
#
# EXECDIR:
# Directory containing various executable files.
#
# TEMPLATE_DIR:
# Directory in which templates of various FV3-LAM input files are locat-
# ed.
#
# UFS_WTHR_MDL_DIR:
# Directory in which the (NEMS-enabled) FV3-LAM application is located.
# This directory includes subdirectories for FV3, NEMS, and FMS.
#
#-----------------------------------------------------------------------
#

#
# The current script should be located in the ush subdirectory of the 
# workflow directory.  Thus, the workflow directory is the one above the
# directory of the current script.  Get the path to this latter directo-
# ry and save it in HOMErrfs.
#
SR_WX_APP_TOP_DIR=${scrfunc_dir%/*/*}
# GSK to do:  Get HOMErrfs from Externals.cfg 
HOMErrfs="${SR_WX_APP_TOP_DIR}/regional_workflow"

USHDIR="$HOMErrfs/ush"
SCRIPTSDIR="$HOMErrfs/scripts"
JOBSDIR="$HOMErrfs/jobs"
SORCDIR="$HOMErrfs/sorc"
SRC_DIR="${SR_WX_APP_TOP_DIR}/src"
PARMDIR="$HOMErrfs/parm"
MODULES_DIR="$HOMErrfs/modulefiles"
EXECDIR="${SR_WX_APP_TOP_DIR}/bin"
TEMPLATE_DIR="$USHDIR/templates"

case $MACHINE in

  "WCOSS_CRAY")
    FIXgsm=${FIXgsm:-"/gpfs/hps3/emc/global/noscrub/emc.glopara/git/fv3gfs/fix/fix_am"}
    TOPO_DIR=${TOPO_DIR:-"/gpfs/hps3/emc/global/noscrub/emc.glopara/git/fv3gfs/fix/fix_orog"}
    SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/gpfs/hps3/emc/global/noscrub/emc.glopara/git/fv3gfs/fix/fix_sfc_climo"}
    FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}
    ;;

  "WCOSS_DELL_P3")
    FIXgsm=${FIXgsm:-"/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/fv3gfs/fix/fix_am"}
    TOPO_DIR=${TOPO_DIR:-"/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/fv3gfs/fix/fix_orog"}
    SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/fv3gfs/fix/fix_sfc_climo"}
    FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}
    ;;

  "HERA")
    FIXgsm=${FIXgsm:-"/scratch1/NCEPDEV/global/glopara/fix/fix_am"}
    TOPO_DIR=${TOPO_DIR:-"/scratch1/NCEPDEV/global/glopara/fix/fix_orog"}
    SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/scratch1/NCEPDEV/global/glopara/fix/fix_sfc_climo"}
    FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/scratch2/BMC/det/FV3LAM_pregen"}
    ;;

  "ORION")
    FIXgsm=${FIXgsm:-"/work/noaa/global/glopara/fix/fix_am"}
    TOPO_DIR=${TOPO_DIR:-"/work/noaa/global/glopara/fix/fix_orog"}
    SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/work/noaa/global/glopara/fix/fix_sfc_climo"}
    FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}
    ;;

  "JET")
    FIXgsm=${FIXgsm:-"/lfs4/HFIP/hfv3gfs/glopara/git/fv3gfs/fix/fix_am"}
    TOPO_DIR=${TOPO_DIR:-"/lfs4/HFIP/hfv3gfs/glopara/git/fv3gfs/fix/fix_orog"}
    SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/lfs4/HFIP/hfv3gfs/glopara/git/fv3gfs/fix/fix_sfc_climo"}
    FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}
    ;;

  "ODIN")
    FIXgsm=${FIXgsm:-"/scratch/ywang/fix/theia_fix/fix_am"}
    TOPO_DIR=${TOPO_DIR:-"/scratch/ywang/fix/theia_fix/fix_orog"}
    SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/scratch/ywang/fix/climo_fields_netcdf"}
    FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}
    ;;

  "CHEYENNE")
    FIXgsm=${FIXgsm:-"/glade/p/ral/jntp/UFS_CAM/fix/fix_am"}
    TOPO_DIR=${TOPO_DIR:-"/glade/p/ral/jntp/UFS_CAM/fix/fix_orog"}
    SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/glade/p/ral/jntp/UFS_CAM/fix/climo_fields_netcdf"}
    FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}
    ;;

  "STAMPEDE")
    FIXgsm=${FIXgsm:-"/work/00315/tg455890/stampede2/regional_fv3/fix_am"}
    TOPO_DIR=${TOPO_DIR:-"/work/00315/tg455890/stampede2/regional_fv3/fix_orog"}
    SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/work/00315/tg455890/stampede2/regional_fv3/climo_fields_netcdf"}
    FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}
    ;;

  *)
    print_err_msg_exit "\
One or more fix file directories have not been specified for this machine:
  MACHINE = \"$MACHINE\"
  FIXgsm = \"${FIXgsm:-\"\"}
  TOPO_DIR = \"${TOPO_DIR:-\"\"}
  SFC_CLIMO_INPUT_DIR = \"${SFC_CLIMO_INPUT_DIR:-\"\"}
  FIXLAM_NCO_BASEDIR = \"${FIXLAM_NCO_BASEDIR:-\"\"}
You can specify the missing location(s) in config.sh"
    ;;

esac
#
#-----------------------------------------------------------------------
#
# Set the base directories in which codes obtained from external reposi-
# tories (using the manage_externals tool) are placed.  Obtain the rela-
# tive paths to these directories by reading them in from the manage_ex-
# ternals configuration file.  (Note that these are relative to the lo-
# cation of the configuration file.)  Then form the full paths to these
# directories.  Finally, make sure that each of these directories actu-
# ally exists.
#
#-----------------------------------------------------------------------
#
mng_extrns_cfg_fn=$( readlink -f "${SR_WX_APP_TOP_DIR}/Externals.cfg" )
property_name="local_path"
#
# Get the base directory of the FV3 forecast model code.
#
external_name="ufs_weather_model"
UFS_WTHR_MDL_DIR=$( \
get_manage_externals_config_property \
"${mng_extrns_cfg_fn}" "${external_name}" "${property_name}" ) || \
print_err_msg_exit "\
Call to function get_manage_externals_config_property failed."

UFS_WTHR_MDL_DIR="${SR_WX_APP_TOP_DIR}/${UFS_WTHR_MDL_DIR}"
if [ ! -d "${UFS_WTHR_MDL_DIR}" ]; then
  print_err_msg_exit "\
The base directory in which the FV3 source code should be located
(UFS_WTHR_MDL_DIR) does not exist:
  UFS_WTHR_MDL_DIR = \"${UFS_WTHR_MDL_DIR}\"
Please clone the external repository containing the code in this directory,
build the executable, and then rerun the workflow."
fi
#
# Get the base directory of the UFS_UTILS codes.
#
external_name="ufs_utils"
UFS_UTILS_DIR=$( \
get_manage_externals_config_property \
"${mng_extrns_cfg_fn}" "${external_name}" "${property_name}" ) || \
print_err_msg_exit "\
Call to function get_manage_externals_config_property failed."

UFS_UTILS_DIR="${SR_WX_APP_TOP_DIR}/${UFS_UTILS_DIR}"
if [ ! -d "${UFS_UTILS_DIR}" ]; then
  print_err_msg_exit "\
The base directory in which the UFS utilities source codes should be lo-
cated (UFS_UTILS_DIR) does not exist:
  UFS_UTILS_DIR = \"${UFS_UTILS_DIR}\"
Please clone the external repository containing the code in this direct-
ory, build the executables, and then rerun the workflow."
fi
#
# Get the base directory of the EMC_post code.
#
external_name="EMC_post"
EMC_POST_DIR=$( \
get_manage_externals_config_property \
"${mng_extrns_cfg_fn}" "${external_name}" "${property_name}" ) || \
print_err_msg_exit "\
Call to function get_manage_externals_config_property failed."

EMC_POST_DIR="${SR_WX_APP_TOP_DIR}/${EMC_POST_DIR}"
if [ ! -d "${EMC_POST_DIR}" ]; then
  print_err_msg_exit "\
The base directory in which the EMC_post source code should be located
(EMC_POST_DIR) does not exist:
  EMS_POST_DIR = \"${EMC_POST_DIR}\"
Please clone the external repository containing the code in this directory,
build the executable, and then rerun the workflow."
fi
#
#-----------------------------------------------------------------------
#
# Make sure that USE_CUSTOM_POST_CONFIG_FILE is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value \
  "USE_CUSTOM_POST_CONFIG_FILE" "valid_vals_USE_CUSTOM_POST_CONFIG_FILE"
#
# Set USE_CUSTOM_POST_CONFIG_FILE to either "TRUE" or "FALSE" so we don't
# have to consider other valid values later on.
#
USE_CUSTOM_POST_CONFIG_FILE=${USE_CUSTOM_POST_CONFIG_FILE^^}
if [ "$USE_CUSTOM_POST_CONFIG_FILE" = "TRUE" ] || \
   [ "$USE_CUSTOM_POST_CONFIG_FILE" = "YES" ]; then
  USE_CUSTOM_POST_CONFIG_FILE="TRUE"
elif [ "$USE_CUSTOM_POST_CONFIG_FILE" = "FALSE" ] || \
     [ "$USE_CUSTOM_POST_CONFIG_FILE" = "NO" ]; then
  USE_CUSTOM_POST_CONFIG_FILE="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# If using a custom post configuration file, make sure that it exists.
#
#-----------------------------------------------------------------------
#
if [ ${USE_CUSTOM_POST_CONFIG_FILE} = "TRUE" ]; then
  if [ ! -f "${CUSTOM_POST_CONFIG_FP}" ]; then
    print_err_msg_exit "
The custom post configuration specified by CUSTOM_POST_CONFIG_FP does not 
exist:
  CUSTOM_POST_CONFIG_FP = \"${CUSTOM_POST_CONFIG_FP}\""
  fi
fi
#
#-----------------------------------------------------------------------
#
# The forecast length (in integer hours) cannot contain more than 3 cha-
# racters.  Thus, its maximum value is 999.  Check whether the specified
# forecast length exceeds this maximum value.  If so, print out a warn-
# ing and exit this script.
#
#-----------------------------------------------------------------------
#
fcst_len_hrs_max="999"
if [ "${FCST_LEN_HRS}" -gt "${fcst_len_hrs_max}" ]; then
  print_err_msg_exit "\
Forecast length is greater than maximum allowed length:
  FCST_LEN_HRS = ${FCST_LEN_HRS}
  fcst_len_hrs_max = ${fcst_len_hrs_max}"
fi
#
#-----------------------------------------------------------------------
#
# Check whether the forecast length (FCST_LEN_HRS) is evenly divisible
# by the BC update interval (LBC_SPEC_INTVL_HRS).  If not, print out a
# warning and exit this script.  If so, generate an array of forecast
# hours at which the boundary values will be updated.
#
#-----------------------------------------------------------------------
#
rem=$(( ${FCST_LEN_HRS}%${LBC_SPEC_INTVL_HRS} ))

if [ "$rem" -ne "0" ]; then
  print_err_msg_exit "\
The forecast length (FCST_LEN_HRS) is not evenly divisible by the lateral
boundary conditions update interval (LBC_SPEC_INTVL_HRS):
  FCST_LEN_HRS = ${FCST_LEN_HRS}
  LBC_SPEC_INTVL_HRS = ${LBC_SPEC_INTVL_HRS}
  rem = FCST_LEN_HRS%%LBC_SPEC_INTVL_HRS = $rem"
fi
#
#-----------------------------------------------------------------------
#
# Set the array containing the forecast hours at which the lateral 
# boundary conditions (LBCs) need to be updated.  Note that this array
# does not include the 0-th hour (initial time).
#
#-----------------------------------------------------------------------
#
LBC_SPEC_FCST_HRS=($( seq ${LBC_SPEC_INTVL_HRS} ${LBC_SPEC_INTVL_HRS} \
                          ${FCST_LEN_HRS} ))
#
#-----------------------------------------------------------------------
#
# If PREDEF_GRID_NAME is set to a non-empty string, set or reset parameters
# according to the predefined domain specified.
#
#-----------------------------------------------------------------------
#
if [ ! -z "${PREDEF_GRID_NAME}" ]; then
  . $USHDIR/set_predef_grid_params.sh
fi
#
#-----------------------------------------------------------------------
#
# Make sure GRID_GEN_METHOD is set to a valid value.
#
#-----------------------------------------------------------------------
#
err_msg="\
The horizontal grid generation method specified in GRID_GEN_METHOD is 
not supported:
  GRID_GEN_METHOD = \"${GRID_GEN_METHOD}\""
check_var_valid_value \
  "GRID_GEN_METHOD" "valid_vals_GRID_GEN_METHOD" "${err_msg}"
#
#-----------------------------------------------------------------------
#
# For a "GFDLgrid" type of grid, make sure GFDLgrid_RES is set to a valid
# value.
#
#-----------------------------------------------------------------------
#
if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then
  err_msg="\
The number of grid cells per tile in each horizontal direction specified
in GFDLgrid_RES is not supported:
  GFDLgrid_RES = \"${GFDLgrid_RES}\""
  check_var_valid_value "GFDLgrid_RES" "valid_vals_GFDLgrid_RES" "${err_msg}"
fi
#
#-----------------------------------------------------------------------
#
# Check to make sure that various computational parameters needed by the 
# forecast model are set to non-empty values.  At this point in the 
# experiment generation, all of these should be set to valid (non-empty) 
# values.
#
#-----------------------------------------------------------------------
#
if [ -z "${DT_ATMOS}" ]; then
  print_err_msg_exit "\
The forecast model main time step (DT_ATMOS) is set to a null string:
  DT_ATMOS = ${DT_ATMOS}
Please set this to a valid numerical value in the user-specified experiment
configuration file (EXPT_CONFIG_FP) and rerun:
  EXPT_CONFIG_FP = \"${EXPT_CONFIG_FP}\""
else
  if [ "${SUB_HOURLY_POST}" = "TRUE" ]; then
    ((rem = (DT_SUBHOURLY_POST_MNTS*60) % DT_ATMOS))
    if [ ${rem} -ne 0 ]; then
      print_err_msg_exit "\
When performing sub-hourly post (i.e. SUB_HOURLY_POST set to \"TRUE\"), the time
interval specified by DT_SUBHOURLY_POST_MNTS (after converting to seconds) must be evenly divisible 
by the time step DT_ATMOS used in the forecast model, i.e. the remainder (rem) must 
be zero.  In this case, it is not:
  SUB_HOURLY_POST = \"${SUB_HOURLY_POST}\"
  DT_SUBHOURLY_POST_MNTS = \"${DT_SUBHOURLY_POST_MNTS}\"
  DT_ATMOS = \"${DT_ATMOS}\"
  rem = \$(( (DT_SUBHOURLY_POST_MNTS*60) %% DT_ATMOS )) = $rem
Please reset DT_SUBHOURLY_POST_MNTS and/or DT_ATMOS so that the remainder is zero."
    fi
  fi
fi

if [ -z "${LAYOUT_X}" ]; then
  print_err_msg_exit "\
The number of MPI processes to be used in the x direction (LAYOUT_X) by 
the forecast job is set to a null string:
  LAYOUT_X = ${LAYOUT_X}
Please set this to a valid numerical value in the user-specified experiment
configuration file (EXPT_CONFIG_FP) and rerun:
  EXPT_CONFIG_FP = \"${EXPT_CONFIG_FP}\""
fi

if [ -z "${LAYOUT_Y}" ]; then
  print_err_msg_exit "\
The number of MPI processes to be used in the y direction (LAYOUT_Y) by 
the forecast job is set to a null string:
  LAYOUT_Y = ${LAYOUT_Y}
Please set this to a valid numerical value in the user-specified experiment
configuration file (EXPT_CONFIG_FP) and rerun:
  EXPT_CONFIG_FP = \"${EXPT_CONFIG_FP}\""
fi

if [ -z "${BLOCKSIZE}" ]; then
  print_err_msg_exit "\
The cache size to use for each MPI task of the forecast (BLOCKSIZE) is 
set to a null string:
  BLOCKSIZE = ${BLOCKSIZE}
Please set this to a valid numerical value in the user-specified experiment
configuration file (EXPT_CONFIG_FP) and rerun:
  EXPT_CONFIG_FP = \"${EXPT_CONFIG_FP}\""
fi
#
#-----------------------------------------------------------------------
#
# If using the FV3_HRRR physics suite, make sure that the directory from 
# which certain fixed orography files will be copied to the experiment 
# directory actually exists.  Note that this is temporary code.  It should
# be removed once there is a script or code available that will create 
# these orography files for any grid.
#
#-----------------------------------------------------------------------
#
GWD_HRRRsuite_DIR=""
if [ "${CCPP_PHYS_SUITE}" = "FV3_HRRR" ]; then
#
# If in NCO mode, make sure that GWD_HRRRsuite_BASEDIR is set equal to  
# FIXLAM_NCO_BASEDIR
#
  if [ "${RUN_ENVIR}" = "nco" ]; then

    if [ "${GWD_HRRRsuite_BASEDIR}" != "${FIXLAM_NCO_BASEDIR}" ]; then

      gwd_hrrrsuite_basedir_orig="${GWD_HRRRsuite_BASEDIR}"
      GWD_HRRRsuite_BASEDIR="${FIXLAM_NCO_BASEDIR}"

      if [ ! -z "${gwd_hrrrsuite_basedir_orig}" ]; then
        print_err_msg_exit "
When RUN_ENVIR is set to \"nco\", the workflow assumes that the base 
directory (GWD_HRRRsuite_BASEDIR) under which the grid-specific 
subdirectories containing the gravity wave drag-related orography 
statistics files for the FV3_HRRR suite are located is the same as the 
base directory (FIXLAM_NCO_BASEDIR) under which the other fixed files 
are located.  Currently, this is not the case:
  GWD_HRRRsuite_BASEDIR = \"${gwd_hrrrsuite_basedir_orig}\"
  FIXLAM_NCO_BASEDIR = \"${FIXLAM_NCO_BASEDIR}\"
Resetting GWD_HRRRsuite_BASEDIR to FIXLAM_NCO_BASEDIR.  Reset value is:
  GWD_HRRRsuite_BASEDIR = \"${GWD_HRRRsuite_BASEDIR}\""
      fi

    fi

  fi
#
# Check that GWD_HRRRsuite_BASEDIR exists and is a directory.
#
  if [ ! -d "${GWD_HRRRsuite_BASEDIR}" ]; then
    print_err_msg_exit "\
The base directory (GWD_HRRRsuite_BASEDIR) under which the grid-specific
subdirectories containing the gravity wave drag-related orography files 
for the FV3_HRRR suite should be located does not exist (or is not a 
directory):
  GWD_HRRRsuite_BASEDIR = \"${GWD_HRRRsuite_BASEDIR}\""
  fi
  GWD_HRRRsuite_DIR="${GWD_HRRRsuite_BASEDIR}/${PREDEF_GRID_NAME}"
#
# Ensure that PREDEF_GRID_NAME is not set to a null string.  Currently,
# only predefined grids can be used with the FV3_HRRR suite because 
# orography statistics files required by this suite are available only
# for (some of) the predefined grids.
#
  if [ -z "${PREDEF_GRID_NAME}" ]; then
    print_err_msg_exit "\
A predefined grid name (PREDEF_GRID_NAME) must be specified when using 
the FV3_HRRR physics suite:
  CCPP_PHYS_SUITE = \"${CCPP_PHYS_SUITE}\"
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\""
  else        
#
# Ensure that the directory GWD_HRRRsuite_DIR in which the orography
# statistics files required by the FV3_HRRR suite are located actually
# exists.
#
    if [ ! -d "${GWD_HRRRsuite_DIR}" ]; then
      print_err_msg_exit "\
The directory (GWD_HRRRsuite_DIR) that should contain the gravity wave 
drag-related orography files for the FV3_HRRR suite does not exist:
  GWD_HRRRsuite_DIR = \"${GWD_HRRRsuite_DIR}\""
    elif [ ! "$( ls -A ${GWD_HRRRsuite_DIR} )" ]; then
      print_err_msg_exit "\
The directory (GWD_HRRRsuite_DIR) that should contain the gravity wave 
drag related orography files for the FV3_HRRR suite is empty:
  GWD_HRRRsuite_DIR = \"${GWD_HRRRsuite_DIR}\""
    fi      
  fi

fi
#
#-----------------------------------------------------------------------
#
# If the base directory (EXPT_BASEDIR) in which the experiment subdirectory 
# (EXPT_SUBDIR) will be located does not start with a "/", then it is 
# either set to a null string or contains a relative directory.  In both 
# cases, prepend to it the absolute path of the default directory under 
# which the experiment directories are placed.  If EXPT_BASEDIR was set 
# to a null string, it will get reset to this default experiment directory, 
# and if it was set to a relative directory, it will get reset to an 
# absolute directory that points to the relative directory under the 
# default experiment directory.  Then create EXPT_BASEDIR if it doesn't 
# already exist.
#
#-----------------------------------------------------------------------
#
if [ "${EXPT_BASEDIR:0:1}" != "/" ]; then
  EXPT_BASEDIR="${SR_WX_APP_TOP_DIR}/../expt_dirs/${EXPT_BASEDIR}"
fi
EXPT_BASEDIR="$( readlink -m ${EXPT_BASEDIR} )"
mkdir_vrfy -p "${EXPT_BASEDIR}"
#
#-----------------------------------------------------------------------
#
# If the experiment subdirectory name (EXPT_SUBDIR) is set to an empty
# string, print out an error message and exit.
#
#-----------------------------------------------------------------------
#
if [ -z "${EXPT_SUBDIR}" ]; then
  print_err_msg_exit "\
The name of the experiment subdirectory (EXPT_SUBDIR) cannot be empty:
  EXPT_SUBDIR = \"${EXPT_SUBDIR}\""
fi
#
#-----------------------------------------------------------------------
#
# Set the full path to the experiment directory.  Then check if it already
# exists and if so, deal with it as specified by PREEXISTING_DIR_METHOD.
#
#-----------------------------------------------------------------------
#
EXPTDIR="${EXPT_BASEDIR}/${EXPT_SUBDIR}"
check_for_preexist_dir_file "$EXPTDIR" "${PREEXISTING_DIR_METHOD}"
#
#-----------------------------------------------------------------------
#
# Set other directories, some of which may depend on EXPTDIR (depending
# on whether we're running in NCO or community mode, i.e. whether RUN_ENVIR 
# is set to "nco" or "community").  Definitions:
#
# LOGDIR:
# Directory in which the log files from the workflow tasks will be placed.
#
# FIXam:
# This is the directory that will contain the fixed files or symlinks to
# the fixed files containing various fields on global grids (which are
# usually much coarser than the native FV3-LAM grid).
#
# FIXLAM:
# This is the directory that will contain the fixed files or symlinks to
# the fixed files containing the grid, orography, and surface climatology
# on the native FV3-LAM grid.
#
# CYCLE_BASEDIR:
# The base directory in which the directories for the various cycles will
# be placed.
#
# COMROOT:
# In NCO mode, this is the full path to the "com" directory under which 
# output from the RUN_POST_TN task will be placed.  Note that this output
# is not placed directly under COMROOT but several directories further
# down.  More specifically, for a cycle starting at yyyymmddhh, it is at
#
#   $COMROOT/$NET/$envir/$RUN.$yyyymmdd/$hh
#
# Below, we set COMROOT in terms of PTMP as COMROOT="$PTMP/com".  COMOROOT 
# is not used by the workflow in community mode.
#
# COMOUT_BASEDIR:
# In NCO mode, this is the base directory directly under which the output 
# from the RUN_POST_TN task will be placed, i.e. it is the cycle-independent 
# portion of the RUN_POST_TN task's output directory.  It is given by
#
#   $COMROOT/$NET/$envir
#
# COMOUT_BASEDIR is not used by the workflow in community mode.
#
#-----------------------------------------------------------------------
#
LOGDIR="${EXPTDIR}/log"

FIXam="${EXPTDIR}/fix_am"
FIXLAM="${EXPTDIR}/fix_lam"

if [ "${RUN_ENVIR}" = "nco" ]; then

  CYCLE_BASEDIR="$STMP/tmpnwprd/$RUN"
  check_for_preexist_dir_file "${CYCLE_BASEDIR}" "${PREEXISTING_DIR_METHOD}"
  COMROOT="$PTMP/com"
  COMOUT_BASEDIR="$COMROOT/$NET/$envir"
  check_for_preexist_dir_file "${COMOUT_BASEDIR}" "${PREEXISTING_DIR_METHOD}"

else

  CYCLE_BASEDIR="$EXPTDIR"
  COMROOT=""
  COMOUT_BASEDIR=""

fi
#
#-----------------------------------------------------------------------
#
# The FV3 forecast model needs the following input files in the run di-
# rectory to start a forecast:
#
#   (1) The data table file
#   (2) The diagnostics table file
#   (3) The field table file
#   (4) The FV3 namelist file
#   (5) The model configuration file
#   (6) The NEMS configuration file
#
# If using CCPP, it also needs:
#
#   (7) The CCPP physics suite definition file
#
# The workflow contains templates for the first six of these files.  
# Template files are versions of these files that contain placeholder
# (i.e. dummy) values for various parameters.  The experiment/workflow 
# generation scripts copy these templates to appropriate locations in 
# the experiment directory (either the top of the experiment directory
# or one of the cycle subdirectories) and replace the placeholders in
# these copies by actual values specified in the experiment/workflow 
# configuration file (or derived from such values).  The scripts then
# use the resulting "actual" files as inputs to the forecast model.
#
# Note that the CCPP physics suite defintion file does not have a cor-
# responding template file because it does not contain any values that
# need to be replaced according to the experiment/workflow configura-
# tion.  If using CCPP, this file simply needs to be copied over from 
# its location in the forecast model's directory structure to the ex-
# periment directory.
#
# Below, we first set the names of the templates for the first six files
# listed above.  We then set the full paths to these template files.  
# Note that some of these file names depend on the physics suite while
# others do not.
#
#-----------------------------------------------------------------------
#
dot_ccpp_phys_suite_or_null=".${CCPP_PHYS_SUITE}"

DATA_TABLE_TMPL_FN="${DATA_TABLE_FN}"
DIAG_TABLE_TMPL_FN="${DIAG_TABLE_FN}${dot_ccpp_phys_suite_or_null}"
FIELD_TABLE_TMPL_FN="${FIELD_TABLE_FN}${dot_ccpp_phys_suite_or_null}"
MODEL_CONFIG_TMPL_FN="${MODEL_CONFIG_FN}"
NEMS_CONFIG_TMPL_FN="${NEMS_CONFIG_FN}"

DATA_TABLE_TMPL_FP="${TEMPLATE_DIR}/${DATA_TABLE_TMPL_FN}"
DIAG_TABLE_TMPL_FP="${TEMPLATE_DIR}/${DIAG_TABLE_TMPL_FN}"
FIELD_TABLE_TMPL_FP="${TEMPLATE_DIR}/${FIELD_TABLE_TMPL_FN}"
FV3_NML_BASE_SUITE_FP="${TEMPLATE_DIR}/${FV3_NML_BASE_SUITE_FN}"
FV3_NML_YAML_CONFIG_FP="${TEMPLATE_DIR}/${FV3_NML_YAML_CONFIG_FN}"
FV3_NML_BASE_ENS_FP="${EXPTDIR}/${FV3_NML_BASE_ENS_FN}"
MODEL_CONFIG_TMPL_FP="${TEMPLATE_DIR}/${MODEL_CONFIG_TMPL_FN}"
NEMS_CONFIG_TMPL_FP="${TEMPLATE_DIR}/${NEMS_CONFIG_TMPL_FN}"
#
#-----------------------------------------------------------------------
#
# Set:
#
# 1) the variable CCPP_PHYS_SUITE_FN to the name of the CCPP physics 
#    suite definition file.
# 2) the variable CCPP_PHYS_SUITE_IN_CCPP_FP to the full path of this 
#    file in the forecast model's directory structure.
# 3) the variable CCPP_PHYS_SUITE_FP to the full path of this file in 
#    the experiment directory.
#
# Note that the experiment/workflow generation scripts will copy this
# file from CCPP_PHYS_SUITE_IN_CCPP_FP to CCPP_PHYS_SUITE_FP.  Then, for
# each cycle, the forecast launch script will create a link in the cycle
# run directory to the copy of this file at CCPP_PHYS_SUITE_FP.
#
#-----------------------------------------------------------------------
#
CCPP_PHYS_SUITE_FN="suite_${CCPP_PHYS_SUITE}.xml"
CCPP_PHYS_SUITE_IN_CCPP_FP="${UFS_WTHR_MDL_DIR}/FV3/ccpp/suites/${CCPP_PHYS_SUITE_FN}"
CCPP_PHYS_SUITE_FP="${EXPTDIR}/${CCPP_PHYS_SUITE_FN}"
if [ ! -f "${CCPP_PHYS_SUITE_IN_CCPP_FP}" ]; then
  print_err_msg_exit "\
The CCPP suite definition file (CCPP_PHYS_SUITE_IN_CCPP_FP) does not exist
in the local clone of the ufs-weather-model:
  CCPP_PHYS_SUITE_IN_CCPP_FP = \"${CCPP_PHYS_SUITE_IN_CCPP_FP}\""
fi
#
#-----------------------------------------------------------------------
#
# Call the function that sets the ozone parameterization being used and
# modifies associated parameters accordingly. 
#
#-----------------------------------------------------------------------
#
set_ozone_param \
  ccpp_phys_suite_fp="${CCPP_PHYS_SUITE_IN_CCPP_FP}" \
  output_varname_ozone_param="OZONE_PARAM"
#
#-----------------------------------------------------------------------
#
# Set the full paths to those forecast model input files that are cycle-
# independent, i.e. they don't include information about the cycle's 
# starting day/time.  These are:
#
#   * The data table file [(1) in the list above)]
#   * The field table file [(3) in the list above)]
#   * The FV3 namelist file [(4) in the list above)]
#   * The NEMS configuration file [(6) in the list above)]
#
# Since they are cycle-independent, the experiment/workflow generation
# scripts will place them in the main experiment directory (EXPTDIR).
# The script that runs each cycle will then create links to these files
# in the run directories of the individual cycles (which are subdirecto-
# ries under EXPTDIR).  
# 
# The remaining two input files to the forecast model, i.e.
#
#   * The diagnostics table file [(2) in the list above)]
#   * The model configuration file [(5) in the list above)]
#
# contain parameters that depend on the cycle start date.  Thus, custom
# versions of these two files must be generated for each cycle and then
# placed directly in the run directories of the cycles (not EXPTDIR).
# For this reason, the full paths to their locations vary by cycle and
# cannot be set here (i.e. they can only be set in the loop over the 
# cycles in the rocoto workflow XML file).
#
#-----------------------------------------------------------------------
#
DATA_TABLE_FP="${EXPTDIR}/${DATA_TABLE_FN}"
FIELD_TABLE_FP="${EXPTDIR}/${FIELD_TABLE_FN}"
FV3_NML_FN="${FV3_NML_BASE_SUITE_FN%.*}"
FV3_NML_FP="${EXPTDIR}/${FV3_NML_FN}"
NEMS_CONFIG_FP="${EXPTDIR}/${NEMS_CONFIG_FN}"
#
#-----------------------------------------------------------------------
#
# Make sure that USE_USER_STAGED_EXTRN_FILES is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "USE_USER_STAGED_EXTRN_FILES" "valid_vals_USE_USER_STAGED_EXTRN_FILES"
#
# Set USE_USER_STAGED_EXTRN_FILES to either "TRUE" or "FALSE" so we don't 
# have to consider other valid values later on.
#
USE_USER_STAGED_EXTRN_FILES=${USE_USER_STAGED_EXTRN_FILES^^}
if [ "${USE_USER_STAGED_EXTRN_FILES}" = "YES" ]; then
  USE_USER_STAGED_EXTRN_FILES="TRUE"
elif [ "${USE_USER_STAGED_EXTRN_FILES}" = "NO" ]; then
  USE_USER_STAGED_EXTRN_FILES="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# If USE_USER_STAGED_EXTRN_FILES is set to TRUE, make sure that the user-
# specified directories under which the external model files should be 
# located actually exist.
#
#-----------------------------------------------------------------------
#
if [ "${USE_USER_STAGED_EXTRN_FILES}" = "TRUE" ]; then

  if [ ! -d "${EXTRN_MDL_SOURCE_BASEDIR_ICS}" ]; then
    print_err_msg_exit "\
The directory (EXTRN_MDL_SOURCE_BASEDIR_ICS) in which the user-staged 
external model files for generating ICs should be located does not exist:
  EXTRN_MDL_SOURCE_BASEDIR_ICS = \"${EXTRN_MDL_SOURCE_BASEDIR_ICS}\""
  fi

  if [ ! -d "${EXTRN_MDL_SOURCE_BASEDIR_LBCS}" ]; then
    print_err_msg_exit "\
The directory (EXTRN_MDL_SOURCE_BASEDIR_LBCS) in which the user-staged 
external model files for generating LBCs should be located does not exist:
  EXTRN_MDL_SOURCE_BASEDIR_LBCS = \"${EXTRN_MDL_SOURCE_BASEDIR_LBCS}\""
  fi

fi
#
#-----------------------------------------------------------------------
#
# Make sure that DO_ENSEMBLE is set to a valid value.  Then set the names
# of the ensemble members.  These will be used to set the ensemble member
# directories.  Also, set the full path to the FV3 namelist file corresponding
# to each ensemble member.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "DO_ENSEMBLE" "valid_vals_DO_ENSEMBLE"
#
# Set DO_ENSEMBLE to either "TRUE" or "FALSE" so we don't have to consider
# other valid values later on.
#
DO_ENSEMBLE=${DO_ENSEMBLE^^}
if [ "$DO_ENSEMBLE" = "TRUE" ] || \
   [ "$DO_ENSEMBLE" = "YES" ]; then
  DO_ENSEMBLE="TRUE"
elif [ "$DO_ENSEMBLE" = "FALSE" ] || \
     [ "$DO_ENSEMBLE" = "NO" ]; then
  DO_ENSEMBLE="FALSE"
fi
NDIGITS_ENSMEM_NAMES="0"
ENSMEM_NAMES=("")
FV3_NML_ENSMEM_FPS=("")
if [ "${DO_ENSEMBLE}" = "TRUE" ]; then
  NDIGITS_ENSMEM_NAMES="${#NUM_ENS_MEMBERS}"
# Strip away all leading zeros in NUM_ENS_MEMBERS by converting it to a 
# decimal (leading zeros will cause bash to interpret the number as an 
# octal).  Note that the variable definitions file will therefore contain
# the version of NUM_ENS_MEMBERS with any leading zeros stripped away.
  NUM_ENS_MEMBERS="$((10#${NUM_ENS_MEMBERS}))"  
  fmt="%0${NDIGITS_ENSMEM_NAMES}d"
  for (( i=0; i<${NUM_ENS_MEMBERS}; i++ )); do
    ip1=$( printf "$fmt" $((i+1)) )
    ENSMEM_NAMES[$i]="mem${ip1}"
    FV3_NML_ENSMEM_FPS[$i]="$EXPTDIR/${FV3_NML_FN}_${ENSMEM_NAMES[$i]}"
  done
fi
#
#-----------------------------------------------------------------------
#
# Set the full path to the forecast model executable.
#
#-----------------------------------------------------------------------
#
FV3_EXEC_FP="${EXECDIR}/${FV3_EXEC_FN}"
#
#-----------------------------------------------------------------------
#
# Set the full path to the script that can be used to (re)launch the 
# workflow.  Also, if USE_CRON_TO_RELAUNCH is set to TRUE, set the line
# to add to the cron table to automatically relaunch the workflow every
# CRON_RELAUNCH_INTVL_MNTS minutes.  Otherwise, set the variable con-
# taining this line to a null string.
#
#-----------------------------------------------------------------------
#
WFLOW_LAUNCH_SCRIPT_FP="$USHDIR/${WFLOW_LAUNCH_SCRIPT_FN}"
WFLOW_LAUNCH_LOG_FP="$EXPTDIR/${WFLOW_LAUNCH_LOG_FN}"
if [ "${USE_CRON_TO_RELAUNCH}" = "TRUE" ]; then
  CRONTAB_LINE="*/${CRON_RELAUNCH_INTVL_MNTS} * * * * cd $EXPTDIR && \
./${WFLOW_LAUNCH_SCRIPT_FN} >> ./${WFLOW_LAUNCH_LOG_FN} 2>&1"
else
  CRONTAB_LINE=""
fi
#
#-----------------------------------------------------------------------
#
# Set the full path to the script that, for a given task, loads the
# necessary module files and runs the tasks.
#
#-----------------------------------------------------------------------
#
LOAD_MODULES_RUN_TASK_FP="$USHDIR/load_modules_run_task.sh"
#
#-----------------------------------------------------------------------
#
# Define the various work subdirectories under the main work directory.
# Each of these corresponds to a different step/substep/task in the pre-
# processing, as follows:
#
# GRID_DIR:
# Directory in which the grid files will be placed (if RUN_TASK_MAKE_GRID 
# is set to "TRUE") or searched for (if RUN_TASK_MAKE_GRID is set to 
# "FALSE").
#
# OROG_DIR:
# Directory in which the orography files will be placed (if RUN_TASK_MAKE_OROG 
# is set to "TRUE") or searched for (if RUN_TASK_MAKE_OROG is set to 
# "FALSE").
#
# SFC_CLIMO_DIR:
# Directory in which the surface climatology files will be placed (if
# RUN_TASK_MAKE_SFC_CLIMO is set to "TRUE") or searched for (if 
# RUN_TASK_MAKE_SFC_CLIMO is set to "FALSE").
#
#----------------------------------------------------------------------
#
if [ "${RUN_ENVIR}" = "nco" ]; then

  nco_fix_dir="${FIXLAM_NCO_BASEDIR}/${PREDEF_GRID_NAME}"
  if [ ! -d "${nco_fix_dir}" ]; then
    print_err_msg_exit "\
The directory (nco_fix_dir) that should contain the pregenerated grid,
orography, and surface climatology files does not exist:
  nco_fix_dir = \"${nco_fix_dir}\""
  fi

  if [ "${RUN_TASK_MAKE_GRID}" = "TRUE" ] || \
     [ "${RUN_TASK_MAKE_GRID}" = "FALSE" -a \
       "${GRID_DIR}" != "${nco_fix_dir}" ]; then

    msg="
When RUN_ENVIR is set to \"nco\", the workflow assumes that pregenerated
grid files already exist in the directory 

  \${FIXLAM_NCO_BASEDIR}/\${PREDEF_GRID_NAME}

where

  FIXLAM_NCO_BASEDIR = \"${FIXLAM_NCO_BASEDIR}\"
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"

Thus, the MAKE_GRID_TN task must not be run (i.e. RUN_TASK_MAKE_GRID must 
be set to \"FALSE\"), and the directory in which to look for the grid 
files (i.e. GRID_DIR) must be set to the one above.  Current values for 
these quantities are:

  RUN_TASK_MAKE_GRID = \"${RUN_TASK_MAKE_GRID}\"
  GRID_DIR = \"${GRID_DIR}\"

Resetting RUN_TASK_MAKE_GRID to \"FALSE\" and GRID_DIR to the one above.
Reset values are:
"

    RUN_TASK_MAKE_GRID="FALSE"
    GRID_DIR="${nco_fix_dir}"

    msg="$msg""
  RUN_TASK_MAKE_GRID = \"${RUN_TASK_MAKE_GRID}\"
  GRID_DIR = \"${GRID_DIR}\"
"

    print_info_msg "$msg"

  fi

  if [ "${RUN_TASK_MAKE_OROG}" = "TRUE" ] || \
     [ "${RUN_TASK_MAKE_OROG}" = "FALSE" -a \
       "${OROG_DIR}" != "${nco_fix_dir}" ]; then

    msg="
When RUN_ENVIR is set to \"nco\", the workflow assumes that pregenerated
orography files already exist in the directory 

  \${FIXLAM_NCO_BASEDIR}/\${PREDEF_GRID_NAME}

where

  FIXLAM_NCO_BASEDIR = \"${FIXLAM_NCO_BASEDIR}\"
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"

Thus, the MAKE_OROG_TN task must not be run (i.e. RUN_TASK_MAKE_OROG must 
be set to \"FALSE\"), and the directory in which to look for the orography 
files (i.e. OROG_DIR) must be set to the one above.  Current values for 
these quantities are:

  RUN_TASK_MAKE_OROG = \"${RUN_TASK_MAKE_OROG}\"
  OROG_DIR = \"${OROG_DIR}\"

Resetting RUN_TASK_MAKE_OROG to \"FALSE\" and OROG_DIR to the one above.
Reset values are:
"

    RUN_TASK_MAKE_OROG="FALSE"
    OROG_DIR="${nco_fix_dir}"

    msg="$msg""
  RUN_TASK_MAKE_OROG = \"${RUN_TASK_MAKE_OROG}\"
  OROG_DIR = \"${OROG_DIR}\"
"

    print_info_msg "$msg"

  fi

  if [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "TRUE" ] || \
     [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "FALSE" -a \
       "${SFC_CLIMO_DIR}" != "${nco_fix_dir}" ]; then

    msg="
When RUN_ENVIR is set to \"nco\", the workflow assumes that pregenerated
surface climatology files already exist in the directory 

  \${FIXLAM_NCO_BASEDIR}/\${PREDEF_GRID_NAME}

where

  FIXLAM_NCO_BASEDIR = \"${FIXLAM_NCO_BASEDIR}\"
  PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\"

Thus, the MAKE_SFC_CLIMO_TN task must not be run (i.e. RUN_TASK_MAKE_SFC_CLIMO 
must be set to \"FALSE\"), and the directory in which to look for the 
surface climatology files (i.e. SFC_CLIMO_DIR) must be set to the one 
above.  Current values for these quantities are:

  RUN_TASK_MAKE_SFC_CLIMO = \"${RUN_TASK_MAKE_SFC_CLIMO}\"
  SFC_CLIMO_DIR = \"${SFC_CLIMO_DIR}\"

Resetting RUN_TASK_MAKE_SFC_CLIMO to \"FALSE\" and SFC_CLIMO_DIR to the 
one above.  Reset values are:
"

    RUN_TASK_MAKE_SFC_CLIMO="FALSE"
    SFC_CLIMO_DIR="${nco_fix_dir}"

    msg="$msg""
  RUN_TASK_MAKE_SFC_CLIMO = \"${RUN_TASK_MAKE_SFC_CLIMO}\"
  SFC_CLIMO_DIR = \"${SFC_CLIMO_DIR}\"
"

    print_info_msg "$msg"

  fi
#
#-----------------------------------------------------------------------
#
# Now consider community mode.
#
#-----------------------------------------------------------------------
#
else
#
# If RUN_TASK_MAKE_GRID is set to "FALSE", the workflow will look for 
# the pregenerated grid files in GRID_DIR.  In this case, make sure that 
# GRID_DIR exists.  Otherwise, set it to a predefined location under the 
# experiment directory (EXPTDIR).
#
  if [ "${RUN_TASK_MAKE_GRID}" = "FALSE" ]; then
    if [ ! -d "${GRID_DIR}" ]; then
      print_err_msg_exit "\
The directory (GRID_DIR) that should contain the pregenerated grid files 
does not exist:
  GRID_DIR = \"${GRID_DIR}\""
    fi
  else
    GRID_DIR="$EXPTDIR/grid"
  fi
#
# If RUN_TASK_MAKE_OROG is set to "FALSE", the workflow will look for 
# the pregenerated orography files in OROG_DIR.  In this case, make sure 
# that OROG_DIR exists.  Otherwise, set it to a predefined location under 
# the experiment directory (EXPTDIR).
#
  if [ "${RUN_TASK_MAKE_OROG}" = "FALSE" ]; then
    if [ ! -d "${OROG_DIR}" ]; then
      print_err_msg_exit "\
The directory (OROG_DIR) that should contain the pregenerated orography
files does not exist:
  OROG_DIR = \"${OROG_DIR}\""
    fi
  else
    OROG_DIR="$EXPTDIR/orog"
  fi
#
# If RUN_TASK_MAKE_SFC_CLIMO is set to "FALSE", the workflow will look 
# for the pregenerated surface climatology files in SFC_CLIMO_DIR.  In
# this case, make sure that SFC_CLIMO_DIR exists.  Otherwise, set it to
# a predefined location under the experiment directory (EXPTDIR).
#
  if [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "FALSE" ]; then
    if [ ! -d "${SFC_CLIMO_DIR}" ]; then
      print_err_msg_exit "\
The directory (SFC_CLIMO_DIR) that should contain the pregenerated surface
climatology files does not exist:
  SFC_CLIMO_DIR = \"${SFC_CLIMO_DIR}\""
    fi
  else
    SFC_CLIMO_DIR="$EXPTDIR/sfc_climo"
  fi

fi
#
#-----------------------------------------------------------------------
#
# Make sure EXTRN_MDL_NAME_ICS is set to a valid value.
#
#-----------------------------------------------------------------------
#
err_msg="\
The external model specified in EXTRN_MDL_NAME_ICS that provides initial
conditions (ICs) and surface fields to the FV3-LAM is not supported:
  EXTRN_MDL_NAME_ICS = \"${EXTRN_MDL_NAME_ICS}\""
check_var_valid_value \
  "EXTRN_MDL_NAME_ICS" "valid_vals_EXTRN_MDL_NAME_ICS" "${err_msg}"
#
#-----------------------------------------------------------------------
#
# Make sure EXTRN_MDL_NAME_LBCS is set to a valid value.
#
#-----------------------------------------------------------------------
#
err_msg="\
The external model specified in EXTRN_MDL_NAME_ICS that provides lateral
boundary conditions (LBCs) to the FV3-LAM is not supported:
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\""
check_var_valid_value \
  "EXTRN_MDL_NAME_LBCS" "valid_vals_EXTRN_MDL_NAME_LBCS" "${err_msg}"
#
#-----------------------------------------------------------------------
#
# Make sure FV3GFS_FILE_FMT_ICS is set to a valid value.
#
#-----------------------------------------------------------------------
#
if [ "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ]; then
  err_msg="\
The file format for FV3GFS external model files specified in FV3GFS_-
FILE_FMT_ICS is not supported:
  FV3GFS_FILE_FMT_ICS = \"${FV3GFS_FILE_FMT_ICS}\""
  check_var_valid_value \
    "FV3GFS_FILE_FMT_ICS" "valid_vals_FV3GFS_FILE_FMT_ICS" "${err_msg}"
fi
#
#-----------------------------------------------------------------------
#
# Make sure FV3GFS_FILE_FMT_LBCS is set to a valid value.
#
#-----------------------------------------------------------------------
#
if [ "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ]; then
  err_msg="\
The file format for FV3GFS external model files specified in FV3GFS_-
FILE_FMT_LBCS is not supported:
  FV3GFS_FILE_FMT_LBCS = \"${FV3GFS_FILE_FMT_LBCS}\""
  check_var_valid_value \
    "FV3GFS_FILE_FMT_LBCS" "valid_vals_FV3GFS_FILE_FMT_LBCS" "${err_msg}"
fi
#
#-----------------------------------------------------------------------
#
# Set cycle-independent parameters associated with the external models
# from which we will obtain the ICs and LBCs.
#
#-----------------------------------------------------------------------
#
. ./set_extrn_mdl_params.sh
















#
#-----------------------------------------------------------------------
#
# Any regional model must be supplied lateral boundary conditions (in
# addition to initial conditions) to be able to perform a forecast.  In
# the FV3-LAM model, these boundary conditions (BCs) are supplied using a
# "halo" of grid cells around the regional domain that extend beyond the
# boundary of the domain.  The model is formulated such that along with
# files containing these BCs, it needs as input the following files (in
# NetCDF format):
#
# 1) A grid file that includes a halo of 3 cells beyond the boundary of
#    the domain.
# 2) A grid file that includes a halo of 4 cells beyond the boundary of
#    the domain.
# 3) A (filtered) orography file without a halo, i.e. a halo of width
#    0 cells.
# 4) A (filtered) orography file that includes a halo of 4 cells beyond
#    the boundary of the domain.
#
# Note that the regional grid is referred to as "tile 7" in the code.
# We will let:
#
# * NH0 denote the width (in units of number of cells on tile 7) of
#   the 0-cell-wide halo, i.e. NH0 = 0;
#
# * NH3 denote the width (in units of number of cells on tile 7) of
#   the 3-cell-wide halo, i.e. NH3 = 3; and
#
# * NH4 denote the width (in units of number of cells on tile 7) of
#   the 4-cell-wide halo, i.e. NH4 = 4.
#
# We define these variables next.
#
#-----------------------------------------------------------------------
#
NH0=0
NH3=3
NH4=4
#
#-----------------------------------------------------------------------
#
# Set parameters according to the type of horizontal grid generation 
# method specified.  First consider GFDL's global-parent-grid based 
# method.
#
#-----------------------------------------------------------------------
#
if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

  set_gridparams_GFDLgrid \
    lon_of_t6_ctr="${GFDLgrid_LON_T6_CTR}" \
    lat_of_t6_ctr="${GFDLgrid_LAT_T6_CTR}" \
    res_of_t6g="${GFDLgrid_RES}" \
    stretch_factor="${GFDLgrid_STRETCH_FAC}" \
    refine_ratio_t6g_to_t7g="${GFDLgrid_REFINE_RATIO}" \
    istart_of_t7_on_t6g="${GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G}" \
    iend_of_t7_on_t6g="${GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G}" \
    jstart_of_t7_on_t6g="${GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G}" \
    jend_of_t7_on_t6g="${GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G}" \
    output_varname_lon_of_t7_ctr="LON_CTR" \
    output_varname_lat_of_t7_ctr="LAT_CTR" \
    output_varname_nx_of_t7_on_t7g="NX" \
    output_varname_ny_of_t7_on_t7g="NY" \
    output_varname_halo_width_on_t7g="NHW" \
    output_varname_stretch_factor="STRETCH_FAC" \
    output_varname_istart_of_t7_with_halo_on_t6sg="ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG" \
    output_varname_iend_of_t7_with_halo_on_t6sg="IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG" \
    output_varname_jstart_of_t7_with_halo_on_t6sg="JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG" \
    output_varname_jend_of_t7_with_halo_on_t6sg="JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG"
#
#-----------------------------------------------------------------------
#
# Now consider Jim Purser's map projection/grid generation method.
#
#-----------------------------------------------------------------------
#
elif [ "${GRID_GEN_METHOD}" = "ESGgrid" ]; then

  set_gridparams_ESGgrid \
    lon_ctr="${ESGgrid_LON_CTR}" \
    lat_ctr="${ESGgrid_LAT_CTR}" \
    nx="${ESGgrid_NX}" \
    ny="${ESGgrid_NY}" \
    halo_width="${ESGgrid_WIDE_HALO_WIDTH}" \
    delx="${ESGgrid_DELX}" \
    dely="${ESGgrid_DELY}" \
    output_varname_lon_ctr="LON_CTR" \
    output_varname_lat_ctr="LAT_CTR" \
    output_varname_nx="NX" \
    output_varname_ny="NY" \
    output_varname_halo_width="NHW" \
    output_varname_stretch_factor="STRETCH_FAC" \
    output_varname_del_angle_x_sg="DEL_ANGLE_X_SG" \
    output_varname_del_angle_y_sg="DEL_ANGLE_Y_SG" \
    output_varname_neg_nx_of_dom_with_wide_halo="NEG_NX_OF_DOM_WITH_WIDE_HALO" \
    output_varname_neg_ny_of_dom_with_wide_halo="NEG_NY_OF_DOM_WITH_WIDE_HALO"

fi
#
#-----------------------------------------------------------------------
#
# Create a new experiment directory.  Note that at this point we are 
# guaranteed that there is no preexisting experiment directory.
#
#-----------------------------------------------------------------------
#
mkdir_vrfy -p "$EXPTDIR"


#
#-----------------------------------------------------------------------
#
# If not running the MAKE_GRID_TN, MAKE_OROG_TN, and/or MAKE_SFC_CLIMO
# tasks, create symlinks under the FIXLAM directory to pregenerated grid,
# orography, and surface climatology files.  In the process, also set 
# RES_IN_FIXLAM_FILENAMES, which is the resolution of the grid (in units
# of number of grid points on an equivalent global uniform cubed-sphere
# grid) used in the names of the fixed files in the FIXLAM directory.
#
#-----------------------------------------------------------------------
#
mkdir_vrfy -p "$FIXLAM"
RES_IN_FIXLAM_FILENAMES=""
#
#-----------------------------------------------------------------------
#
# If the grid file generation task in the workflow is going to be skipped
# (because pregenerated files are available), create links in the FIXLAM
# directory to the pregenerated grid files.
#
#-----------------------------------------------------------------------
#
res_in_grid_fns=""
if [ "${RUN_TASK_MAKE_GRID}" = "FALSE" ]; then

  link_fix \
    verbose="$VERBOSE" \
    file_group="grid" \
    output_varname_res_in_filenames="res_in_grid_fns" || \
  print_err_msg_exit "\
Call to function to create links to grid files failed."

  RES_IN_FIXLAM_FILENAMES="${res_in_grid_fns}"

fi
#
#-----------------------------------------------------------------------
#
# If the orography file generation task in the workflow is going to be
# skipped (because pregenerated files are available), create links in
# the FIXLAM directory to the pregenerated orography files.
#
#-----------------------------------------------------------------------
#
res_in_orog_fns=""
if [ "${RUN_TASK_MAKE_OROG}" = "FALSE" ]; then

  link_fix \
    verbose="$VERBOSE" \
    file_group="orog" \
    output_varname_res_in_filenames="res_in_orog_fns" || \
  print_err_msg_exit "\
Call to function to create links to orography files failed."

  if [ ! -z "${RES_IN_FIXLAM_FILENAMES}" ] && \
     [ "${res_in_orog_fns}" -ne "${RES_IN_FIXLAM_FILENAMES}" ]; then
    print_err_msg_exit "\
The resolution extracted from the orography file names (res_in_orog_fns)
does not match the resolution in other groups of files already consi-
dered (RES_IN_FIXLAM_FILENAMES):
  res_in_orog_fns = ${res_in_orog_fns}
  RES_IN_FIXLAM_FILENAMES = ${RES_IN_FIXLAM_FILENAMES}"
  else
    RES_IN_FIXLAM_FILENAMES="${res_in_orog_fns}"
  fi

fi
#
#-----------------------------------------------------------------------
#
# If the surface climatology file generation task in the workflow is
# going to be skipped (because pregenerated files are available), create
# links in the FIXLAM directory to the pregenerated surface climatology
# files.
#
#-----------------------------------------------------------------------
#
res_in_sfc_climo_fns=""
if [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "FALSE" ]; then

  link_fix \
    verbose="$VERBOSE" \
    file_group="sfc_climo" \
    output_varname_res_in_filenames="res_in_sfc_climo_fns" || \
  print_err_msg_exit "\
Call to function to create links to surface climatology files failed."

  if [ ! -z "${RES_IN_FIXLAM_FILENAMES}" ] && \
     [ "${res_in_sfc_climo_fns}" -ne "${RES_IN_FIXLAM_FILENAMES}" ]; then
    print_err_msg_exit "\
The resolution extracted from the surface climatology file names (res_-
in_sfc_climo_fns) does not match the resolution in other groups of files
already considered (RES_IN_FIXLAM_FILENAMES):
  res_in_sfc_climo_fns = ${res_in_sfc_climo_fns}
  RES_IN_FIXLAM_FILENAMES = ${RES_IN_FIXLAM_FILENAMES}"
  else
    RES_IN_FIXLAM_FILENAMES="${res_in_sfc_climo_fns}"
  fi

fi
#
#-----------------------------------------------------------------------
#
# The variable CRES is needed in constructing various file names.  If 
# not running the make_grid task, we can set it here.  Otherwise, it 
# will get set to a valid value by that task.
#
#-----------------------------------------------------------------------
#
CRES=""
if [ "${RUN_TASK_MAKE_GRID}" = "FALSE" ]; then
  CRES="C${RES_IN_FIXLAM_FILENAMES}"
fi





#
#-----------------------------------------------------------------------
#
# Make sure that QUILTING is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "QUILTING" "valid_vals_QUILTING"
#
# Set QUILTING to either "TRUE" or "FALSE" so we don't have to consider
# other valid values later on.
#
QUILTING=${QUILTING^^}
if [ "$QUILTING" = "TRUE" ] || \
   [ "$QUILTING" = "YES" ]; then
  QUILTING="TRUE"
elif [ "$QUILTING" = "FALSE" ] || \
     [ "$QUILTING" = "NO" ]; then
  QUILTING="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Make sure that PRINT_ESMF is set to a valid value.
#
#-----------------------------------------------------------------------
#
check_var_valid_value "PRINT_ESMF" "valid_vals_PRINT_ESMF"
#
# Set PRINT_ESMF to either "TRUE" or "FALSE" so we don't have to consider
# other valid values later on.
#
PRINT_ESMF=${PRINT_ESMF^^}
if [ "${PRINT_ESMF}" = "TRUE" ] || \
   [ "${PRINT_ESMF}" = "YES" ]; then
  PRINT_ESMF="TRUE"
elif [ "${PRINT_ESMF}" = "FALSE" ] || \
     [ "${PRINT_ESMF}" = "NO" ]; then
  PRINT_ESMF="FALSE"
fi
#
#-----------------------------------------------------------------------
#
# Calculate PE_MEMBER01.  This is the number of MPI tasks used for the
# forecast, including those for the write component if QUILTING is set
# to "TRUE".
#
#-----------------------------------------------------------------------
#
PE_MEMBER01=$(( LAYOUT_X*LAYOUT_Y ))
if [ "$QUILTING" = "TRUE" ]; then
  PE_MEMBER01=$(( ${PE_MEMBER01} + ${WRTCMP_write_groups}*${WRTCMP_write_tasks_per_group} ))
fi

print_info_msg "$VERBOSE" "
The number of MPI tasks for the forecast (including those for the write
component if it is being used) are:
  PE_MEMBER01 = ${PE_MEMBER01}"
#
#-----------------------------------------------------------------------
#
# If the write-component is going to be used to write output files to 
# disk (i.e. if QUILTING is set to "TRUE"), make sure that the grid type 
# used by the write-component (WRTCMP_output_grid) is set to a valid value.
#
#-----------------------------------------------------------------------
#
if [ "$QUILTING" = "TRUE" ]; then
  err_msg="\
The coordinate system used by the write-component output grid specified
in WRTCMP_output_grid is not supported:
  WRTCMP_output_grid = \"${WRTCMP_output_grid}\""
  check_var_valid_value \
    "WRTCMP_output_grid" "valid_vals_WRTCMP_output_grid" "${err_msg}"
fi
#
#-----------------------------------------------------------------------
#
# Calculate the number of nodes (NNODES_RUN_FCST) to request from the job
# scheduler for the forecast task (RUN_FCST_TN).  This is just PE_MEMBER01
# dividied by the number of processes per node we want to request for this
# task (PPN_RUN_FCST), then rounded up to the nearest integer, i.e.
#
#   NNODES_RUN_FCST = ceil(PE_MEMBER01/PPN_RUN_FCST)
#
# where ceil(...) is the ceiling function, i.e. it rounds its floating
# point argument up to the next larger integer.  Since in bash, division
# of two integers returns a truncated integer, and since bash has no
# built-in ceil(...) function, we perform the rounding-up operation by
# adding the denominator (of the argument of ceil(...) above) minus 1 to
# the original numerator, i.e. by redefining NNODES_RUN_FCST to be
#
#   NNODES_RUN_FCST = (PE_MEMBER01 + PPN_RUN_FCST - 1)/PPN_RUN_FCST
#
#-----------------------------------------------------------------------
#
NNODES_RUN_FCST=$(( (PE_MEMBER01 + PPN_RUN_FCST - 1)/PPN_RUN_FCST ))


#
#-----------------------------------------------------------------------
#
# Call the function that checks whether the RUC land surface model (LSM)
# is being called by the physics suite and sets the workflow variable 
# SDF_USES_RUC_LSM to "TRUE" or "FALSE" accordingly.
#
#-----------------------------------------------------------------------
#
check_ruc_lsm \
  ccpp_phys_suite_fp="${CCPP_PHYS_SUITE_IN_CCPP_FP}" \
  output_varname_sdf_uses_ruc_lsm="SDF_USES_RUC_LSM"
#
#-----------------------------------------------------------------------
#
# Set the name of the file containing aerosol climatology data that, if
# necessary, can be used to generate approximate versions of the aerosol 
# fields needed by Thompson microphysics.  This file will be used to 
# generate such approximate aerosol fields in the ICs and LBCs if Thompson 
# MP is included in the physics suite and if the exteranl model for ICs
# or LBCs does not already provide these fields.  Also, set the full path
# to this file.
#
#-----------------------------------------------------------------------
#
THOMPSON_MP_CLIMO_FN="Thompson_MP_MONTHLY_CLIMO.nc"
THOMPSON_MP_CLIMO_FP="$FIXam/${THOMPSON_MP_CLIMO_FN}"
#
#-----------------------------------------------------------------------
#
# Call the function that, if the Thompson microphysics parameterization
# is being called by the physics suite, modifies certain workflow arrays
# to ensure that fixed files needed by this parameterization are copied
# to the FIXam directory and appropriate symlinks to them are created in
# the run directories.  This function also sets the workflow variable
# SDF_USES_THOMPSON_MP that indicates whether Thompson MP is called by 
# the physics suite.
#
#-----------------------------------------------------------------------
#
set_thompson_mp_fix_files \
  ccpp_phys_suite_fp="${CCPP_PHYS_SUITE_IN_CCPP_FP}" \
  thompson_mp_climo_fn="${THOMPSON_MP_CLIMO_FN}" \
  output_varname_sdf_uses_thompson_mp="SDF_USES_THOMPSON_MP"
#
#-----------------------------------------------------------------------
#
# Generate the shell script that will appear in the experiment directory
# (EXPTDIR) and will contain definitions of variables needed by the va-
# rious scripts in the workflow.  We refer to this as the experiment/
# workflow global variable definitions file.  We will create this file
# by:
#
# 1) Copying the default workflow/experiment configuration file (speci-
#    fied by EXPT_DEFAULT_CONFIG_FN and located in the shell script di-
#    rectory specified by USHDIR) to the experiment directory and rena-
#    ming it to the name specified by GLOBAL_VAR_DEFNS_FN.
#
# 2) Resetting the default variable values in this file to their current
#    values.  This is necessary because these variables may have been 
#    reset by the user-specified configuration file (if one exists in 
#    USHDIR) and/or by this setup script, e.g. because predef_domain is
#    set to a valid non-empty value.
#
# 3) Appending to the variable definitions file any new variables intro-
#    duced in this setup script that may be needed by the scripts that
#    perform the various tasks in the workflow (and which source the va-
#    riable defintions file).
#
# First, set the full path to the variable definitions file and copy the
# default configuration script into it.
#
#-----------------------------------------------------------------------
#
GLOBAL_VAR_DEFNS_FP="$EXPTDIR/$GLOBAL_VAR_DEFNS_FN"
cp_vrfy $USHDIR/${EXPT_DEFAULT_CONFIG_FN} ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#

# Read all lines of GLOBAL_VAR_DEFNS file into the variable line_list.
line_list=$( sed -r -e "s/(.*)/\1/g" ${GLOBAL_VAR_DEFNS_FP} )
#
# Loop through the lines in line_list and concatenate lines ending with
# the line bash continuation character "\".
#
rm_vrfy ${GLOBAL_VAR_DEFNS_FP}
while read crnt_line; do
  printf "%s\n" "${crnt_line}" >> ${GLOBAL_VAR_DEFNS_FP}
done <<< "${line_list}"
#
#-----------------------------------------------------------------------
#
# The following comment block needs to be updated because now line_list
# may contain lines that are not assignment statements (e.g. it may con-
# tain if-statements).  Such lines are ignored in the while-loop below.
#
# Reset each of the variables in the variable definitions file to its 
# value in the current environment.  To accomplish this, we:
#
# 1) Create a list of variable settings by stripping out comments, blank
#    lines, extraneous leading whitespace, etc from the variable defini-
#    tions file (which is currently identical to the default workflow/
#    experiment configuration script) and saving the result in the vari-
#    able line_list.  Each line of line_list will have the form
#
#      VAR=...
#
#    where the VAR is a variable name and ... is the value from the de-
#    fault configuration script (which does not necessarily correspond
#    to the current value of the variable).
#
# 2) Loop through each line of line_list.  For each line, we extract the
#    variable name (and save it in the variable var_name), get its value
#    from the current environment (using bash indirection, i.e. 
#    ${!var_name}), and use the set_file_param() function to replace the
#    value of the variable in the variable definitions script (denoted 
#    above by ...) with its current value. 
#
#-----------------------------------------------------------------------
#
# Also should remove trailing whitespace...
line_list=$( sed -r \
             -e "s/^([ ]*)([^ ]+.*)/\2/g" \
             -e "/^#.*/d" \
             -e "/^$/d" \
             ${GLOBAL_VAR_DEFNS_FP} )

print_info_msg "$VERBOSE" "
The variable \"line_list\" contains:

${line_list}
"
#
#-----------------------------------------------------------------------
#
# Add a comment at the beginning of the variable definitions file that
# indicates that the first section of that file is (mostly) the same as
# the configuration file.
#
#-----------------------------------------------------------------------
#
read -r -d '' str_to_insert << EOM
#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
# Section 1:
# This section is a copy of the default workflow/experiment configura-
# tion file config_defaults.sh in the shell scripts directory USHDIR ex-
# cept that variable values have been updated to those set by the setup
# script (setup.sh).
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#
EOM
#
# Replace all occurrences of actual newlines in the variable str_to_insert
# with escaped backslash-n.  This is needed for the sed command below to
# work properly (i.e. to avoid it failing with an "unterminated `s' command"
# message).
#
str_to_insert=${str_to_insert//$'\n'/\\n}
#
# Insert str_to_insert into GLOBAL_VAR_DEFNS_FP right after the line
# containing the name of the interpreter (i.e. the line that starts with
# the string "#!", e.g. "#!/bin/bash").
#
regexp="(^#!.*)"
sed -i -r -e "s|$regexp|\1\n\n${str_to_insert}\n|g" ${GLOBAL_VAR_DEFNS_FP}






#
# Loop through the lines in line_list.
#
while read crnt_line; do
#
# Try to obtain the name of the variable being set on the current line.
# This will be successful only if the line consists of one or more char-
# acters representing the name of a variable (recall that in generating
# the variable line_list, all leading spaces in the lines in the file 
# have been stripped out), followed by an equal sign, followed by zero
# or more characters representing the value that the variable is being
# set to.
#
  var_name=$( printf "%s" "${crnt_line}" | sed -n -r -e "s/^([^ ]*)=.*/\1/p" )
#echo
#echo "============================"
#printf "%s\n" "var_name = \"${var_name}\""
#
# If var_name is not empty, then a variable name was found in the cur-
# rent line in line_list.
#
  if [ ! -z $var_name ]; then

    print_info_msg "$VERBOSE" "
var_name = \"${var_name}\""
#
# If the variable specified in var_name is set in the current environ-
# ment (to either an empty or non-empty string), get its value and in-
# sert it in the variable definitions file on the line where that varia-
# ble is defined.  Note that 
#
#   ${!var_name+x}
#
# will retrun the string "x" if the variable specified in var_name is 
# set (to either an empty or non-empty string), and it will return an
# empty string if the variable specified in var_name is unset (i.e. un-
# defined).
#
    if [ ! -z ${!var_name+x} ]; then
#
# The variable may be a scalar or an array.  Thus, we first treat it as
# an array and obtain the number of elements that it contains.
#
      array_name_at="${var_name}[@]"
      array=("${!array_name_at}")
      num_elems="${#array[@]}"
#
# We will now set the variable var_value to the string that needs to be
# placed on the right-hand side of the assignment operator (=) on the 
# appropriate line in variable definitions file.  How this is done de-
# pends on whether the variable is a scalar or an array.
#
# If the variable contains only one element, then it is a scalar.  (It
# could be a 1-element array, but it is simpler to treat it as a sca-
# lar.)  In this case, we enclose its value in double quotes and save
# the result in var_value.
#
      if [ "$num_elems" -eq 1 ]; then
        var_value="${!var_name}"
        var_value="\"${var_value}\""
#
# If the variable contains more than one element, then it is an array.
# In this case, we build var_value in two steps as follows:
#
# 1) Generate a string containing each element of the array in double
#    quotes and followed by a space.
#
# 2) Place parentheses around the double-quoted list of array elements
#    generated in the first step.  Note that there is no need to put a
#    space before the closing parenthesis because in step 1, we have al-
#    ready placed a space after the last element.
#
      else

        arrays_on_one_line="TRUE"
        arrays_on_one_line="FALSE"

        if [ "${arrays_on_one_line}" = "TRUE" ]; then
          var_value=$(printf "\"%s\" " "${!array_name_at}")
#          var_value=$(printf "\"%s\" \\\\\\ \\\n" "${!array_name_at}")
        else
#          var_value=$(printf "%s" "\\\\\\n")
          var_value="\\\\\n"
          for (( i=0; i<${num_elems}; i++ )); do
#            var_value=$(printf "%s\"%s\" %s" "${var_value}" "${array[$i]}" "\\\\\\n")
            var_value="${var_value}\"${array[$i]}\" \\\\\n"
#            var_value="${var_value}\"${array[$i]}\" "
          done
        fi
        var_value="( $var_value)"

      fi
#
# If the variable specified in var_name is not set in the current envi-
# ronment (to either an empty or non-empty string), get its value and 
# insert it in the variable definitions file on the line where that va-
# riable is defined.
#
    else

      print_info_msg "
The variable specified by \"var_name\" is not set in the current envi-
ronment:
  var_name = \"${var_name}\"
Setting its value in the variable definitions file to an empty string."

      var_value="\"\""

    fi
#
# Now place var_value on the right-hand side of the assignment statement
# on the appropriate line in variable definitions file.
#
    set_file_param "${GLOBAL_VAR_DEFNS_FP}" "${var_name}" "${var_value}"
#
# If var_name is empty, then a variable name was not found in the cur-
# rent line in line_list.  In this case, print out a warning and move on
# to the next line.
#
  else

    print_info_msg "
Could not extract a variable name from the current line in \"line_list\"
(probably because it does not contain an equal sign with no spaces on 
either side):
  crnt_line = \"${crnt_line}\"
  var_name = \"${var_name}\"
Continuing to next line in \"line_list\"."

  fi

done <<< "${line_list}"
#
#-----------------------------------------------------------------------
#
# Append additional variable definitions (and comments) to the variable
# definitions file.  These variables have been set above using the vari-
# ables in the default and local configuration scripts.  These variables
# are needed by various tasks/scripts in the workflow.
#
#-----------------------------------------------------------------------
#
{ cat << EOM >> ${GLOBAL_VAR_DEFNS_FP}

#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
# Section 2:
# This section defines variables that have been derived from the ones
# above by the setup script (setup.sh) and which are needed by one or
# more of the scripts that perform the workflow tasks (those scripts
# source this variable definitions file).
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Full path to workflow launcher script, its log file, and the line that
# gets added to the cron table to launch this script if USE_CRON_TO_RELAUNCH
# is set to TRUE.
#
#-----------------------------------------------------------------------
#
WFLOW_LAUNCH_SCRIPT_FP="${WFLOW_LAUNCH_SCRIPT_FP}"
WFLOW_LAUNCH_LOG_FP="${WFLOW_LAUNCH_LOG_FP}"
CRONTAB_LINE="${CRONTAB_LINE}"
#
#-----------------------------------------------------------------------
#
# Directories.
#
#-----------------------------------------------------------------------
#
SR_WX_APP_TOP_DIR="${SR_WX_APP_TOP_DIR}"
HOMErrfs="$HOMErrfs"
USHDIR="$USHDIR"
SCRIPTSDIR="$SCRIPTSDIR"
JOBSDIR="$JOBSDIR"
SORCDIR="$SORCDIR"
SRC_DIR="$SRC_DIR"
PARMDIR="$PARMDIR"
MODULES_DIR="${MODULES_DIR}"
EXECDIR="$EXECDIR"
FIXam="$FIXam"
FIXLAM="$FIXLAM"
FIXgsm="$FIXgsm"
COMROOT="$COMROOT"
COMOUT_BASEDIR="${COMOUT_BASEDIR}"
TEMPLATE_DIR="${TEMPLATE_DIR}"
UFS_WTHR_MDL_DIR="${UFS_WTHR_MDL_DIR}"
UFS_UTILS_DIR="${UFS_UTILS_DIR}"
SFC_CLIMO_INPUT_DIR="${SFC_CLIMO_INPUT_DIR}"
TOPO_DIR="${TOPO_DIR}"
EMC_POST_DIR="${EMC_POST_DIR}"

EXPTDIR="$EXPTDIR"
LOGDIR="$LOGDIR"
CYCLE_BASEDIR="${CYCLE_BASEDIR}"
GRID_DIR="${GRID_DIR}"
OROG_DIR="${OROG_DIR}"
SFC_CLIMO_DIR="${SFC_CLIMO_DIR}"
GWD_HRRRsuite_DIR="${GWD_HRRRsuite_DIR}"

NDIGITS_ENSMEM_NAMES="${NDIGITS_ENSMEM_NAMES}"
ENSMEM_NAMES=( $( printf "\"%s\" " "${ENSMEM_NAMES[@]}" ))
FV3_NML_ENSMEM_FPS=( $( printf "\"%s\" " "${FV3_NML_ENSMEM_FPS[@]}" ))
#
#-----------------------------------------------------------------------
#
# Files.
#
#-----------------------------------------------------------------------
#
GLOBAL_VAR_DEFNS_FP="${GLOBAL_VAR_DEFNS_FP}"
# Try this at some point instead of hard-coding it as above; it's a more
# flexible approach (if it works).
#GLOBAL_VAR_DEFNS_FP=$( readlink -f "${BASH_SOURCE[0]}" )

DATA_TABLE_TMPL_FN="${DATA_TABLE_TMPL_FN}"
DIAG_TABLE_TMPL_FN="${DIAG_TABLE_TMPL_FN}"
FIELD_TABLE_TMPL_FN="${FIELD_TABLE_TMPL_FN}"
MODEL_CONFIG_TMPL_FN="${MODEL_CONFIG_TMPL_FN}"
NEMS_CONFIG_TMPL_FN="${NEMS_CONFIG_TMPL_FN}"

DATA_TABLE_TMPL_FP="${DATA_TABLE_TMPL_FP}"
DIAG_TABLE_TMPL_FP="${DIAG_TABLE_TMPL_FP}"
FIELD_TABLE_TMPL_FP="${FIELD_TABLE_TMPL_FP}"
FV3_NML_BASE_SUITE_FP="${FV3_NML_BASE_SUITE_FP}"
FV3_NML_YAML_CONFIG_FP="${FV3_NML_YAML_CONFIG_FP}"
FV3_NML_BASE_ENS_FP="${FV3_NML_BASE_ENS_FP}"
MODEL_CONFIG_TMPL_FP="${MODEL_CONFIG_TMPL_FP}"
NEMS_CONFIG_TMPL_FP="${NEMS_CONFIG_TMPL_FP}"

CCPP_PHYS_SUITE_FN="${CCPP_PHYS_SUITE_FN}"
CCPP_PHYS_SUITE_IN_CCPP_FP="${CCPP_PHYS_SUITE_IN_CCPP_FP}"
CCPP_PHYS_SUITE_FP="${CCPP_PHYS_SUITE_FP}"

DATA_TABLE_FP="${DATA_TABLE_FP}"
FIELD_TABLE_FP="${FIELD_TABLE_FP}"
FV3_NML_FN="${FV3_NML_FN}"   # This may not be necessary...
FV3_NML_FP="${FV3_NML_FP}"
NEMS_CONFIG_FP="${NEMS_CONFIG_FP}"

FV3_EXEC_FP="${FV3_EXEC_FP}"

LOAD_MODULES_RUN_TASK_FP="${LOAD_MODULES_RUN_TASK_FP}"

THOMPSON_MP_CLIMO_FN="${THOMPSON_MP_CLIMO_FN}"
THOMPSON_MP_CLIMO_FP="${THOMPSON_MP_CLIMO_FP}"
#
#-----------------------------------------------------------------------
#
# Parameters that indicate whether or not various parameterizations are 
# included in and called by the phsics suite.
#
#-----------------------------------------------------------------------
#
SDF_USES_RUC_LSM="${SDF_USES_RUC_LSM}"
SDF_USES_THOMPSON_MP="${SDF_USES_THOMPSON_MP}"
#
#-----------------------------------------------------------------------
#
# Grid configuration parameters needed regardless of grid generation me-
# thod used.
#
#-----------------------------------------------------------------------
#
GTYPE="$GTYPE"
TILE_RGNL="${TILE_RGNL}"
NH0="${NH0}"
NH3="${NH3}"
NH4="${NH4}"

LON_CTR="${LON_CTR}"
LAT_CTR="${LAT_CTR}"
NX="${NX}"
NY="${NY}"
NHW="${NHW}"
STRETCH_FAC="${STRETCH_FAC}"

RES_IN_FIXLAM_FILENAMES="${RES_IN_FIXLAM_FILENAMES}"
#
# If running the make_grid task, CRES will be set to a null string du-
# the grid generation step.  It will later be set to an actual value af-
# ter the make_grid task is complete.
#
CRES="$CRES"
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to append new variable definitions to variable 
definitions file returned with a nonzero status."
#
#-----------------------------------------------------------------------
#
# Append to the variable definitions file the defintions of grid parame-
# ters that are specific to the grid generation method used.
#
#-----------------------------------------------------------------------
#
if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

  { cat << EOM >> ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Grid configuration parameters for a regional grid generated from a
# global parent cubed-sphere grid.  This is the method originally sug-
# gested by GFDL since it allows GFDL's nested grid generator to be used
# to generate a regional grid.  However, for large regional domains, it
# results in grids that have an unacceptably large range of cell sizes
# (i.e. ratio of maximum to minimum cell size is not sufficiently close
# to 1).
#
#-----------------------------------------------------------------------
#
ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG="${ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}"
IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG="${IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}"
JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG="${JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}"
JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG="${JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}"
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to append grid parameters to variable definitions
file returned with a nonzero status."

elif [ "${GRID_GEN_METHOD}" = "ESGgrid" ]; then

  { cat << EOM >> ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Grid configuration parameters for a regional grid generated indepen-
# dently of a global parent grid.  This method was developed by Jim Pur-
# ser of EMC and results in very uniform grids (i.e. ratio of maximum to
# minimum cell size is very close to 1).
#
#-----------------------------------------------------------------------
#
DEL_ANGLE_X_SG="${DEL_ANGLE_X_SG}"
DEL_ANGLE_Y_SG="${DEL_ANGLE_Y_SG}"
NEG_NX_OF_DOM_WITH_WIDE_HALO="${NEG_NX_OF_DOM_WITH_WIDE_HALO}"
NEG_NY_OF_DOM_WITH_WIDE_HALO="${NEG_NY_OF_DOM_WITH_WIDE_HALO}"
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to append grid parameters to variable definitions
file returned with a nonzero status."

fi
#
#-----------------------------------------------------------------------
#
# Continue appending variable definitions to the variable definitions 
# file.
#
#-----------------------------------------------------------------------
#
{ cat << EOM >> ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Name of the ozone parameterization.  The value this gets set to depends 
# on the CCPP physics suite being used.
#
#-----------------------------------------------------------------------
#
OZONE_PARAM="${OZONE_PARAM}"
#
#-----------------------------------------------------------------------
#
# If USE_USER_STAGED_EXTRN_FILES is set to "FALSE", this is the system 
# directory in which the workflow scripts will look for the files generated 
# by the external model specified in EXTRN_MDL_NAME_ICS.  These files will 
# be used to generate the input initial condition and surface files for 
# the FV3-LAM.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_SYSBASEDIR_ICS="${EXTRN_MDL_SYSBASEDIR_ICS}"
#
#-----------------------------------------------------------------------
#
# If USE_USER_STAGED_EXTRN_FILES is set to "FALSE", this is the system 
# directory in which the workflow scripts will look for the files generated 
# by the external model specified in EXTRN_MDL_NAME_LBCS.  These files 
# will be used to generate the input lateral boundary condition files for 
# the FV3-LAM.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_SYSBASEDIR_LBCS="${EXTRN_MDL_SYSBASEDIR_LBCS}"
#
#-----------------------------------------------------------------------
#
# Shift back in time (in units of hours) of the starting time of the ex-
# ternal model specified in EXTRN_MDL_NAME_LBCS.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_LBCS_OFFSET_HRS="${EXTRN_MDL_LBCS_OFFSET_HRS}"
#
#-----------------------------------------------------------------------
#
# Boundary condition update times (in units of forecast hours).  Note that
# LBC_SPEC_FCST_HRS is an array, even if it has only one element.
#
#-----------------------------------------------------------------------
#
LBC_SPEC_FCST_HRS=(${LBC_SPEC_FCST_HRS[@]})
#
#-----------------------------------------------------------------------
#
# The number of cycles for which to make forecasts and the list of starting
# dates/hours of these cycles.
#
#-----------------------------------------------------------------------
#
NUM_CYCLES="${NUM_CYCLES}"
ALL_CDATES=( \\
$( printf "\"%s\" \\\\\n" "${ALL_CDATES[@]}" )
)
#
#-----------------------------------------------------------------------
#
# If USE_FVCOM is set to TRUE, then FVCOM data (located in FVCOM_DIR
# in FVCOM_FILE) will be used to update lower boundary conditions during
# make_ics.
#
#-----------------------------------------------------------------------
#
USE_FVCOM="${USE_FVCOM}"
FVCOM_DIR="${FVCOM_DIR}"
FVCOM_FILE="${FVCOM_FILE}"
#
#-----------------------------------------------------------------------
#
# Computational parameters.
#
#-----------------------------------------------------------------------
#
NCORES_PER_NODE="${NCORES_PER_NODE}"
PE_MEMBER01="${PE_MEMBER01}"
#
#-----------------------------------------------------------------------
#
# IF DO_SPP="TRUE," N_VAR_SPP is the number of parameterizations that
# are perturbed with SPP, otherwise N_VAR_SPP=0.
#
#-----------------------------------------------------------------------
#
N_VAR_SPP="${N_VAR_SPP}"
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to append new variable definitions to variable 
definitions file returned with a nonzero status."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Setup script completed successfully!!!
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the start of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

}
#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
setup

