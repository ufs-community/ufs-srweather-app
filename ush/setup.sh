#!/bin/sh -l

#
#-----------------------------------------------------------------------
#
# This script sets parameters needed by the various scripts that are
# called by the rocoto workflow.  This secondary set of parameters is
# calculated using the primary set of user-defined parameters in the
# default and local workflow/experiment configuration scripts (whose 
# file names are defined below).  This script then saves both sets of 
# parameters in a variable-definitions script in the run directory that
# will be sourced by the various scripts called by the workflow.
#
#-----------------------------------------------------------------------
#

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
# Set the names of the default and local workflow/experiment configura-
# tion scripts.
#
#-----------------------------------------------------------------------
#
DEFAULT_CONFIG_FN="config_defaults.sh"
LOCAL_CONFIG_FN="config.sh"
#
#-----------------------------------------------------------------------
#
# Source the configuration script containing default values of experi-
# ment variables.
#
#-----------------------------------------------------------------------
#
. ./${DEFAULT_CONFIG_FN}
#
#-----------------------------------------------------------------------
#
# If a local configuration script exists, source that as well.  Here, by
# "local", we mean one that contains variable settings that are relevant
# only to the local environment (e.g. a directory setting that applies
# only to the current user on the current machine).  Note that this lo-
# cal script is not tracked by the repository, whereas the default con-
# figuration script sourced above is tracked.  Any variable settings in
# the local script will override the ones in the default script.  The 
# purpose of having a local configuration script is to avoid having to 
# make changes to the default configuration script that are only appli-
# cable to one user, one machine, etc.
#
#-----------------------------------------------------------------------
#
if [ -f "$LOCAL_CONFIG_FN" ]; then
#
# We require that the variables being set in the local configuration 
# script have counterparts in the default configuration script.  This is
# so that we do not accidentally introduce new variables in the local
# script without also officially introducing them in the default script.
# Thus, before sourcing the local configuration script, we check for 
# this.
#
  . ./compare_config_scripts.sh
#
# Now source the local configuration script.
#
  . ./$LOCAL_CONFIG_FN
#
fi
#
#-----------------------------------------------------------------------
#
# Make sure VERBOSE is set to either "true" or "false".
#
#-----------------------------------------------------------------------
#
if [ "$VERBOSE" != "true" ] && [ "$VERBOSE" != "false" ]; then
  print_err_msg_exit "\
The verbosity flag VERBOSE must be set to either \"true\" or \"false\":
  VERBOSE = \"$VERBOSE\""
fi
#
#-----------------------------------------------------------------------
#
# Convert machine name to upper case if necessary.  Then make sure that
# MACHINE is set to one of the allowed values.
#
#-----------------------------------------------------------------------
#
MACHINE=$( printf "%s" "$MACHINE" | sed -e 's/\(.*\)/\U\1/' )

valid_MACHINES=("WCOSS_C" "WCOSS" "DELL" "THEIA" "JET" "ODIN" "CHEYENNE")
iselementof "$MACHINE" valid_MACHINES || { \
valid_MACHINES_str=$(printf "\"%s\" " "${valid_MACHINES[@]}");
print_err_msg_exit "\
Machine specified in MACHINE is not supported:
  MACHINE = \"$MACHINE\"
MACHINE must be set to one of the following:
  $valid_MACHINES_str
"; }
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
#
"WCOSS_C")
#
  print_err_msg_exit "\
Don't know how to set several parameters on MACHINE=\"$MACHINE\".
Please specify the correct parameters for this machine in the setup script.  
Then remove this message and rerun."

  ncores_per_node=""
  SCHED=""
  QUEUE_DEFAULT=${QUEUE_DEFAULT:-""}
  QUEUE_HPSS=${QUEUE_HPSS:-""}
  QUEUE_RUN_FV3SAR=${QUEUE_RUN_FV3SAR:-""}
  ;;
#
"WCOSS")
#
  print_err_msg_exit "\
Don't know how to set several parameters on MACHINE=\"$MACHINE\".
Please specify the correct parameters for this machine in the setup script.  
Then remove this message and rerun."

  ncores_per_node=""
  SCHED=""
  QUEUE_DEFAULT=${QUEUE_DEFAULT:-""}
  QUEUE_HPSS=${QUEUE_HPSS:-""}
  QUEUE_RUN_FV3SAR=${QUEUE_RUN_FV3SAR:-""}
  ;;
#
"THEIA")
#
  ncores_per_node=24
  SCHED="moabtorque"
  QUEUE_DEFAULT=${QUEUE_DEFAULT:-"batch"}
  QUEUE_HPSS=${QUEUE_HPSS:-"service"}
  QUEUE_RUN_FV3SAR=${QUEUE_RUN_FV3SAR:-""}
  ;;
#
"JET")
#
  ncores_per_node=24
  SCHED="moabtorque"
  QUEUE_DEFAULT=${QUEUE_DEFAULT:-"batch"}
  QUEUE_HPSS=${QUEUE_HPSS:-"service"}
  QUEUE_RUN_FV3SAR=${QUEUE_RUN_FV3SAR:-"batch"}
  ;;
#
"ODIN")
#
  ncores_per_node=24
  SCHED="slurm"
  QUEUE_DEFAULT=${QUEUE_DEFAULT:-""}
  QUEUE_HPSS=${QUEUE_HPSS:-""}
  QUEUE_RUN_FV3SAR=${QUEUE_RUN_FV3SAR:-""}
  ;;
#
"CHEYENNE")
#
  print_err_msg_exit "\
Don't know how to set several parameters on MACHINE=\"$MACHINE\".
Please specify the correct parameters for this machine in the setup script.  
Then remove this message and rerun."

  ncores_per_node=
  SCHED=""
  QUEUE_DEFAULT=${QUEUE_DEFAULT:-""}
  QUEUE_HPSS=${QUEUE_HPSS:-""}
  QUEUE_RUN_FV3SAR=${QUEUE_RUN_FV3SAR:-""}
#
esac
#
#-----------------------------------------------------------------------
#
# Set the grid type (gtype).  In general, in the FV3 code, this can take
# on one of the following values: "global", "stretch", "nest", and "re-
# gional".  The first three values are for various configurations of a
# global grid, while the last one is for a regional grid.  Since here we
# are only interested in a regional grid, gtype must be set to "region-
# al".
#
#-----------------------------------------------------------------------
#
gtype="regional"
#
#-----------------------------------------------------------------------
#
# Make sure predef_domain is set to one of the allowed values.
#
#-----------------------------------------------------------------------
#
valid_predef_domains=("RAP" "HRRR" "EMCCONUS")
if [ ! -z ${predef_domain} ]; then
  iselementof "$predef_domain" valid_predef_domains || { \
  valid_predef_domains_str=$(printf "\"%s\" " "${valid_predef_domains[@]}");
  print_err_msg_exit "\
Predefined regional domain specified in predef_domain is not supported:
  predef_domain = \"$predef_domain\"
predef_domain must be set either to an empty string or to one of the following:
  $valid_predef_domains_str
"; }
fi
#
#-----------------------------------------------------------------------
#
# If predef_domain is set to a non-empty string, reset RES to the appro-
# priate value.
#
#-----------------------------------------------------------------------
#
case $predef_domain in
#
"RAP")        # The RAP domain.
#
  RES="384"
  ;;
#
"HRRR")       # The HRRR domain.
#
  RES="384"
  ;;
#
"EMCCONUS")   # EMC's C768 domain over the CONUS.
#
  RES="768"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Make sure RES is set to one of the allowed values.
#
#-----------------------------------------------------------------------
#
valid_RESES=("48" "96" "192" "384" "768" "1152" "3072")
iselementof "$RES" valid_RESES || { \
valid_RESES_str=$(printf "\"%s\" " "${valid_RESES[@]}");
print_err_msg_exit "\
Number of grid cells per tile (in each horizontal direction) specified in
RES is not supported:
  RES = \"$RES\"
RES must be one of the following:  $valid_RESES_str
"; }
#
#-----------------------------------------------------------------------
#
# Set the C-resolution.  This is just a convenience variable containing
# the character "C" followed by the tile resolution.
#
#-----------------------------------------------------------------------
#
CRES="C${RES}"
#
#-----------------------------------------------------------------------
#
# Check that CDATE is a string consisting of exactly 10 digits.  The 
# temporary variable CDATE_OR_NULL will be empty if CDATE is not a 
# string of exactly 10 digits.
#
#-----------------------------------------------------------------------
#
#
CDATE_OR_NULL=$( printf "%s" "$CDATE" | sed -n -r -e "s/^([0-9]{10})$/\1/p" )

if [ -z "${CDATE_OR_NULL}" ]; then
  print_err_msg_exit "\
CDATE must be a string consisting of exactly 10 digits of the form \"YYYYMMDDHH\",
where YYYY is the 4-digit year, MM is the 2-digit month, DD is the 2-digit day-
of-month, and HH is the 2-digit hour-of-day.
  CDATE = \"$CDATE\""
fi
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
YYYY=${CDATE:0:4}
MM=${CDATE:4:2}
DD=${CDATE:6:2}
HH=${CDATE:8:2}
YMD=${CDATE:0:8}
#
#-----------------------------------------------------------------------
#
# Set various directories.
#
# FV3SAR_DIR:
# Top directory of the clone of the FV3SAR workflow git repository.
#
# USHDIR:
# Directory containing the shell scripts called by the workflow.
#
# SORCDIR:
# Directory containing various source codes.
#
# TEMPLATE_DIR:
# Directory in which templates of various FV3SAR input files are locat-
# ed.
#
# FIXgsm:
# System directory in which the fixed (i.e. time-independent) files that
# are needed to run the FV3SAR model are located.
#
# UPPFIX:
# System directory from which to copy necessary fix files for UPP.
#
# GSDFIX:
# System directory from which to copy GSD physics-related fixed files that are needed 
# when running CCPP.
#
# CCPPFIX:
# System directory from which to copy CCPP-related fixed files that are needed
# for specific module loads when running the CCPP compiled version of the FV3SAR.
#
# UPPFIX:
# System directory from which to copy necessary fix files for UPP.
#
# GSDFIX:
# System directory from which to copy GSD physics-related fixed files that are needed 
# when running CCPP.
#
# CCPPFIX:
# System directory from which to copy CCPP-related fixed files that are needed
# for specific module loads when running the CCPP compiled version of the FV3SAR.
#
#-----------------------------------------------------------------------
#
FV3SAR_DIR="$BASEDIR/fv3sar_workflow"
USHDIR="$FV3SAR_DIR/ush"
SORCDIR="$FV3SAR_DIR/sorc"
TEMPLATE_DIR="$USHDIR/templates"
UPPFIX="$FV3SAR_DIR/fix/fix_upp"
GSDFIX="$FV3SAR_DIR/fix/fix_gsd"
CCPPFIX="$FV3SAR_DIR/fix/fix_ccpp"

case $MACHINE in
#
"WCOSS_C")
#
  FIXgsm="/gpfs/hps3/emc/global/noscrub/emc.glopara/git/fv3gfs/fix/fix_am"

#  if [ "$ictype" = "pfv3gfs" ]; then
#    export INIDIR="/gpfs/hps3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/gfs.$YMD/$HH"
#  else
#    export INIDIR="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
#  fi
  ;;
#
"WCOSS")
#
  FIXgsm="/gpfs/hps3/emc/global/noscrub/emc.glopara/git/fv3gfs/fix/fix_am"

#  if [ "$ictype" = "pfv3gfs" ]; then
#    export INIDIR="/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/gfs.$YMD/$HH"
#  else
#    export INIDIR="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
#  fi
  ;;
#
"DELL")
#
  FIXgsm="/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/fv3gfs/fix/fix_am"

#  if [ "$ictype" = "pfv3gfs" ]; then
#    export INIDIR="/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/gfs.$YMD/$HH"
#  else
#    export INIDIR="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
#  fi
  ;;
#
"THEIA")
#
  FIXgsm="/scratch4/NCEPDEV/global/save/glopara/git/fv3gfs/fix/fix_am"

#  if [ "$ictype" = "pfv3gfs" ]; then
#    export INIDIR="/scratch4/NCEPDEV/fv3-cam/noscrub/Eric.Rogers/prfv3rt1/gfs.$YMD/$HH"
#  else
#    export COMROOTp2="/scratch4/NCEPDEV/rstprod/com"
#    export INIDIR="$COMROOTp2/gfs/prod/gfs.$YMD"
#  fi
  ;;
#
"JET")
#
  export FIXgsm="/lfs3/projects/hpc-wof1/ywang/regional_fv3/fix/fix_am"
  ;;
#
"ODIN")
#
  export FIXgsm="/scratch/ywang/external/fix_am"
  ;;
#
esac
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
fcst_len_hrs_max=999
if [ "$fcst_len_hrs" -gt "$fcst_len_hrs_max" ]; then
  print_err_msg_exit "\
Forecast length is greater than maximum allowed length:
  fcst_len_hrs = $fcst_len_hrs
  fcst_len_hrs_max = $fcst_len_hrs_max"
fi
#
#-----------------------------------------------------------------------
#
# Check whether the forecast length (fcst_len_hrs) is evenly divisible
# by the BC update interval (BC_update_intvl_hrs).  If not, print out a
# warning and exit this script.  If so, generate an array of forecast
# hours at which the boundary values will be updated.
#
#-----------------------------------------------------------------------
#
rem=$(( $fcst_len_hrs % $BC_update_intvl_hrs ))

if [ "$rem" -ne "0" ]; then

  print_err_msg_exit "\
The forecast length is not evenly divisible by the BC update interval:
  fcst_len_hrs = $fcst_len_hrs
  BC_update_intvl_hrs = $BC_update_intvl_hrs
  rem = fcst_len_hrs % BC_update_intvl_hrs = $rem"

else

  BC_update_times_hrs=($( seq 0 $BC_update_intvl_hrs $fcst_len_hrs ))

fi
#
#-----------------------------------------------------------------------
#
# If run_title is set to a non-empty value [i.e. it is neither unset nor
# null, where null means an empty string], prepend an underscore to it.
# Otherwise, set it to null.
#
#-----------------------------------------------------------------------
#
run_title=${run_title:+_$run_title}
#
#-----------------------------------------------------------------------
#
# Check if predef_domain is set to a valid (non-empty) value.  If so:
#
# 1) Reset the run title (run_title).
# 2) Reset the grid parameters.
# 3) If the write component is to be used (i.e. quilting is set to
#    ".true.") and the variable WRTCMP_PARAMS_TEMPLATE_FN containing the
#    name of the write-component template file is unset or empty, set
#    that filename variable to the appropriate preexisting template
#    file.
#
# For the predefined domains, we determine the starting and ending indi-
# ces of the regional grid within tile 6 by specifying margins (in units
# of number of cells on tile 6) between the boundary of tile 6 and that
# of the regional grid (tile 7) along the left, right, bottom, and top
# portions of these boundaries.  Note that we do not use "west", "east",
# "south", and "north" here because the tiles aren't necessarily orient-
# ed such that the left boundary segment corresponds to the west edge,
# etc.  The widths of these margins (in units of number of cells on tile
# 6) are specified via the parameters
#
#   num_margin_cells_T6_left
#   num_margin_cells_T6_right
#   num_margin_cells_T6_bottom
#   num_margin_cells_T6_top
#
# where the "_T6" in these names is used to indicate that the cell count
# is on tile 6, not tile 7.
#
# Note that we must make the margins wide enough (by making the above
# four parameters large enough) such that a region of halo cells around
# the boundary of the regional grid fits into the margins, i.e. such
# that the halo does not overrun the boundary of tile 6.  (The halo is
# added later in another script; its function is to feed in boundary
# conditions to the regional grid.)  Currently, a halo of 5 regional
# grid cells is used around the regional grid.  Setting num_margin_-
# cells_T6_... to at least 10 leaves enough room for this halo.
#
#-----------------------------------------------------------------------
#
case $predef_domain in
#
"RAP")  # The RAP domain.
#
# Prepend the string "_RAP" to run_title.
#
  run_title="_RAP${run_title}"
#
# Reset grid parameters.
#
  lon_ctr_T6=-106.0
  lat_ctr_T6=54.0
  stretch_fac=0.63
  refine_ratio=3

  num_margin_cells_T6_left=10
  istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))

  num_margin_cells_T6_right=10
  iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))

  num_margin_cells_T6_bottom=10
  jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))

  num_margin_cells_T6_top=10
  jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))
#
# If the write-component is being used and the variable (WRTCMP_PARAMS_-
# TEMPLATE_FN) containing the name of the template file that specifies
# various write-component parameters has not been specified or has been
# set to an empty string, reset it to the preexisting template file for
# the RAP domain.
#
  if [ "$quilting" = ".true." ]; then
    WRTCMP_PARAMS_TEMPLATE_FN=${WRTCMP_PARAMS_TEMPLATE_FN:-"wrtcomp_RAP"}
  fi
  ;;
#
"HRRR")  # The HRRR domain.
#
# Prepend the string "_HRRR" to run_title.
#
  run_title="_HRRR${run_title}"
#
# Reset grid parameters.
#
  lon_ctr_T6=-97.5
  lat_ctr_T6=38.5
  stretch_fac=1.65
  refine_ratio=5

  num_margin_cells_T6_left=12
  istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))

  num_margin_cells_T6_right=12
  iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))

  num_margin_cells_T6_bottom=80
  jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))

  num_margin_cells_T6_top=80
  jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))
#
# If the write-component is being used and the variable (WRTCMP_PARAMS_-
# TEMPLATE_FN) containing the name of the template file that specifies
# various write-component parameters has not been specified or has been
# set to an empty string, reset it to the preexisting template file for
# the HRRR domain.
#
  if [ "$quilting" = ".true." ]; then
    WRTCMP_PARAMS_TEMPLATE_FN=${WRTCMP_PARAMS_TEMPLATE_FN:-"wrtcomp_HRRR"}
  fi
  ;;
#
"EMCCONUS")  # EMC's C768 domain over the CONUS.
#
# Prepend the string "_EMCCONUS" to run_title.
#
  run_title="_EMCCONUS${run_title}"
#
# Reset grid parameters.
#
  lon_ctr_T6=-97.5
  lat_ctr_T6=38.5
  stretch_fac=1.5
  refine_ratio=3

  num_margin_cells_T6_left=61
  istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))

  num_margin_cells_T6_right=67
  iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))

  num_margin_cells_T6_bottom=165
  jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))

  num_margin_cells_T6_top=171
  jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))
#
# If the write-component is being used and the variable (WRTCMP_PARAMS_-
# TEMPLATE_FN) containing the name of the template file that specifies
# various write-component parameters has not been specified or has been
# set to an empty string, reset it to the preexisting template file for
# the RAP domain.
#
  if [ "$quilting" = ".true." ]; then
    WRTCMP_PARAMS_TEMPLATE_FN=${WRTCMP_PARAMS_TEMPLATE_FN:-"wrtcomp_EMCCONUS"}
  fi
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Construct a name (RUN_SUBDIR) that we will used for the run directory
# as well as the work directory (which will be created under the speci-
# fied TMPDIR).
#
#-----------------------------------------------------------------------
#
stretch_str="_S$( printf "%s" "${stretch_fac}" | sed "s|\.|p|" )"
refine_str="_RR${refine_ratio}"
RUN_SUBDIR=${CRES}${stretch_str}${refine_str}${run_title}
#
#-----------------------------------------------------------------------
#
# Define the full path to the work directory.  This is the directory in
# which the prepocessing steps create their input and/or place their
# output.  Then call the function that checks whether the work directory
# already exists and if so, moves it, deletes it, or quits out of this
# script (the action taken depends on the value of the variable preex-
# isting_dir_method).  Note that we do not yet create a new work direc-
# tory; we will do that later below once the workflow/experiment config-
# uration parameters pass the various checks.
#
#-----------------------------------------------------------------------
#
WORKDIR=$TMPDIR/$RUN_SUBDIR
check_for_preexist_dir $WORKDIR $preexisting_dir_method
#
#-----------------------------------------------------------------------
#
# Define the various work subdirectories under the main work directory.
# Each of these corresponds to a different step/substep/task in the pre-
# processing, as follows:
#
# WORKDIR_GRID:
# Work directory for the grid generation preprocessing step.
#
# WORKDIR_OROG:
# Work directory for the orography generation preprocessing step.
#
# WORKDIR_FLTR:
# Work directory for the orography filtering preprocessing step.
#
# WORKDIR_SHVE:
# Work directory for the preprocessing step that "shaves" the grid and
# filtered orography files.
#
# WORKDIR_ICBC:
# Work directory for the preprocessing steps that generate the files
# containing the surface fields as well as the initial and boundary con-
# ditions.
#
#-----------------------------------------------------------------------
#
WORKDIR_GRID=$WORKDIR/grid
WORKDIR_OROG=$WORKDIR/orog
WORKDIR_FLTR=$WORKDIR/filtered_topo
WORKDIR_SHVE=$WORKDIR/shave
WORKDIR_ICBC=$WORKDIR/ICs_BCs
#
#-----------------------------------------------------------------------
#
# Define the full path of the run directory.  This is the directory in
# which most of the input files to the FV3SAR as well as most of the
# output files that it generates will be placed.  Then call the function
# that checks whether the run directory already exists and if so, moves
# it, deletes it, or quits out of this script (the action taken depends
# on the value of the variable preexisting_dir_method).  Note that we do
# not yet create a new run directory; we will do that later below once
# the workflow/experiment configuration parameters pass the various 
# checks.
#
#-----------------------------------------------------------------------
#
RUNDIR_BASE="${BASEDIR}/run_dirs"
mkdir_vrfy -p "${RUNDIR_BASE}"

RUNDIR="${RUNDIR_BASE}/${RUN_SUBDIR}"
check_for_preexist_dir $RUNDIR $preexisting_dir_method
#
#-----------------------------------------------------------------------
#
# Set the directory INIDIR in which we will store the analysis (at the
# initial time CDATE) and forecast (at the boundary update times) files.  
# These are the files that will be used to generate surface fields and 
# initial and boundary conditions for the FV3SAR.
#
#-----------------------------------------------------------------------
#
INIDIR="${WORKDIR}/gfs"
#
#-----------------------------------------------------------------------
#
# The following may not be necessary since global_chgres_driver.sh resets ictype.  But it was in the original version of this script, so we keep it here for now.
#
# Set the type (ictype) of GFS analysis file we will be reading in to
# obtain the ICs.  This type (or format) must be either "opsgfs" (the
# current operational GFS format; used for dates on and after the tran-
# sition date of July 19, 2017) or "oldgfs" (old GFS format; for dates
# before the transition date).
#
# Calculate the duration in seconds from some default date (see man page
# of "date" command) to the specified CDATE and the duration from that
# default date to the transition date.  Then compare these two durations
# to determine the ictype.
#
#-----------------------------------------------------------------------
#
if [ 0 = 1 ]; then
IC_date_sec=$( date -d "${YYYY}-${MM}-${DD} ${HH} UTC" "+%s" )
transition_date_sec=$( date -d "2017-07-19 00 UTC" "+%s" )

if [ "$IC_date_sec" -ge "$transition_date_sec" ]; then
  ictype="opsgfs"
#  ictype="pfv3gfs"
else
  ictype="oldgfs"
fi
fi
#
#-----------------------------------------------------------------------
#
# Any regional model must be supplied lateral boundary conditions (in
# addition to initial conditions) to be able to perform a forecast.  In
# the FV3SAR model, these boundary conditions (BCs) are supplied using a
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
# * nh0_T7 denote the width (in units of number of cells on tile 7) of
#   the 0-cell-wide halo, i.e. nh0_T7 = 0;
#
# * nh3_T7 denote the width (in units of number of cells on tile 7) of
#   the 3-cell-wide halo, i.e. nh3_T7 = 3; and
#
# * nh4_T7 denote the width (in units of number of cells on tile 7) of
#   the 4-cell-wide halo, i.e. nh4_T7 = 4.
#
# We define these variables next.
#
#-----------------------------------------------------------------------
#
nh0_T7=0
nh3_T7=3
nh4_T7=$(( $nh3_T7 + 1 ))
#
#-----------------------------------------------------------------------
#
# Make sure grid_gen_method is set to one of the allowed values.
#
#-----------------------------------------------------------------------
#
valid_grid_gen_methods=("GFDLgrid" "JPgrid")
iselementof "$grid_gen_method" valid_grid_gen_methods || { \
valid_grid_gen_methods_str=$(printf "\"%s\" " "${valid_grid_gen_methods[@]}");
print_err_msg_exit "\
The grid generation method specified in grid_gen_method is not supported:
  grid_gen_method = \"$grid_gen_method\"
grid_gen_method must be one of the following:  $valid_grid_gen_methods_str
"; }
#
#-----------------------------------------------------------------------
#
# Set parameters according to the type of horizontal grid generation me-
# thod specified.  First consider GFDL's global-parent-grid based me-
# thod.
#
#-----------------------------------------------------------------------
#
if [ "$grid_gen_method" = "GFDLgrid" ]; then
#
#-----------------------------------------------------------------------
#
# The grid generation script grid_gen_scr called below in turn calls the
# make_hgrid utility/executable to construct the regional grid.  make_-
# hgrid accepts as arguments the index limits (i.e. starting and ending
# indices) of the regional grid on the supergrid of the regional grid's
# parent tile.  The regional grid's parent tile is tile 6, and the su-
# pergrid of any given tile is defined as the grid obtained by doubling
# the number of cells in each direction on that tile's grid.  We will
# denote these index limits by
#
#   istart_rgnl_T6SG
#   iend_rgnl_T6SG
#   jstart_rgnl_T6SG
#   jend_rgnl_T6SG
#
# The "_T6SG" suffix in these names is used to indicate that the indices
# are on the supergrid of tile 6.  Recall, however, that we have as in-
# puts the index limits of the regional grid on the tile 6 grid, not its
# supergrid.  These are given by
#
#   istart_rgnl_T6
#   iend_rgnl_T6
#   jstart_rgnl_T6
#   jend_rgnl_T6
#
# We can obtain the former from the latter by recalling that the super-
# grid has twice the resolution of the original grid.  Thus,
#
#   istart_rgnl_T6SG = 2*istart_rgnl_T6 - 1
#   iend_rgnl_T6SG = 2*iend_rgnl_T6
#   jstart_rgnl_T6SG = 2*jstart_rgnl_T6 - 1
#   jend_rgnl_T6SG = 2*jend_rgnl_T6
#
# These are obtained assuming that grid cells on tile 6 must either be
# completely within the regional domain or completely outside of it,
# i.e. the boundary of the regional grid must coincide with gridlines
# on the tile 6 grid; it cannot cut through tile 6 cells.  (Note that
# this implies that the starting indices on the tile 6 supergrid must be
# odd while the ending indices must be even; the above expressions sa-
# tisfy this requirement.)  We perfrom these calculations next.
#
#-----------------------------------------------------------------------
#
  istart_rgnl_T6SG=$(( 2*$istart_rgnl_T6 - 1 ))
  iend_rgnl_T6SG=$(( 2*$iend_rgnl_T6 ))
  jstart_rgnl_T6SG=$(( 2*$jstart_rgnl_T6 - 1 ))
  jend_rgnl_T6SG=$(( 2*$jend_rgnl_T6 ))
#
#-----------------------------------------------------------------------
#
# If we simply pass to make_hgrid the index limits of the regional grid
# on the tile 6 supergrid calculated above, make_hgrid will generate a
# regional grid without a halo.  To obtain a regional grid with a halo,
# we must pass to make_hgrid the index limits (on the tile 6 supergrid)
# of the regional grid including a halo.  We will let the variables
#
#   istart_rgnl_wide_halo_T6SG
#   iend_rgnl_wide_halo_T6SG
#   jstart_rgnl_wide_halo_T6SG
#   jend_rgnl_wide_halo_T6SG
#
# denote these limits.  The reason we include "_wide_halo" in these va-
# riable names is that the halo of the grid that we will first generate
# will be wider than the halos that are actually needed as inputs to the
# FV3SAR model (i.e. the 0-cell-wide, 3-cell-wide, and 4-cell-wide halos
# described above).  We will generate the grids with narrower halos that
# the model needs later on by "shaving" layers of cells from this wide-
# halo grid.  Next, we describe how to calculate the above indices.
#
# Let nhw_T7 denote the width of the "wide" halo in units of number of
# grid cells on the regional grid (i.e. tile 7) that we'd like to have
# along all four edges of the regional domain (left, right, bottom, and
# top).  To obtain the corresponding halo width in units of number of
# cells on the tile 6 grid -- which we denote by nhw_T6 -- we simply di-
# vide nhw_T7 by the refinement ratio, i.e.
#
#   nhw_T6 = nhw_T7/refine_ratio
#
# The corresponding halo width on the tile 6 supergrid is then given by
#
#   nhw_T6SG = 2*nhw_T6
#            = 2*nhw_T7/refine_ratio
#
# Note that nhw_T6SG must be an integer, but the expression for it de-
# rived above may not yield an integer.  To ensure that the halo has a
# width of at least nhw_T7 cells on the regional grid, we round up the
# result of the expression above for nhw_T6SG, i.e. we redefine nhw_T6SG
# to be
#
#   nhw_T6SG = ceil(2*nhw_T7/refine_ratio)
#
# where ceil(...) is the ceiling function, i.e. it rounds its floating
# point argument up to the next larger integer.  Since in bash division
# of two integers returns a truncated integer and since bash has no
# built-in ceil(...) function, we perform the rounding-up operation by
# adding the denominator (of the argument of ceil(...) above) minus 1 to
# the original numerator, i.e. by redefining nhw_T6SG to be
#
#   nhw_T6SG = (2*nhw_T7 + refine_ratio - 1)/refine_ratio
#
# This trick works when dividing one positive integer by another.
#
# In order to calculate nhw_T6G using the above expression, we must
# first specify nhw_T7.  Next, we specify an initial value for it by
# setting it to one more than the largest-width halo that the model ac-
# tually needs, which is nh4_T7.  We then calculate nhw_T6SG using the
# above expression.  Note that these values of nhw_T7 and nhw_T6SG will
# likely not be their final values; their final values will be calcula-
# ted later below after calculating the starting and ending indices of
# the regional grid with wide halo on the tile 6 supergrid and then ad-
# justing the latter to satisfy certain conditions.
#
#-----------------------------------------------------------------------
#
  nhw_T7=$(( $nh4_T7 + 1 ))
  nhw_T6SG=$(( (2*nhw_T7 + refine_ratio - 1)/refine_ratio ))
#
#-----------------------------------------------------------------------
#
# With an initial value of nhw_T6SG now available, we can obtain the
# tile 6 supergrid index limits of the regional domain (including the
# wide halo) from the index limits for the regional domain without a ha-
# lo by simply subtracting nhw_T6SG from the lower index limits and add-
# ing nhw_T6SG to the upper index limits, i.e.
#
#   istart_rgnl_wide_halo_T6SG = istart_rgnl_T6SG - nhw_T6SG
#   iend_rgnl_wide_halo_T6SG = iend_rgnl_T6SG + nhw_T6SG
#   jstart_rgnl_wide_halo_T6SG = jstart_rgnl_T6SG - nhw_T6SG
#   jend_rgnl_wide_halo_T6SG = jend_rgnl_T6SG + nhw_T6SG
#
# We calculate these next.
#
#-----------------------------------------------------------------------
#
  istart_rgnl_wide_halo_T6SG=$(( $istart_rgnl_T6SG - $nhw_T6SG ))
  iend_rgnl_wide_halo_T6SG=$(( $iend_rgnl_T6SG + $nhw_T6SG ))
  jstart_rgnl_wide_halo_T6SG=$(( $jstart_rgnl_T6SG - $nhw_T6SG ))
  jend_rgnl_wide_halo_T6SG=$(( $jend_rgnl_T6SG + $nhw_T6SG ))
#
#-----------------------------------------------------------------------
#
# As for the regional grid without a halo, the regional grid with a wide
# halo that make_hgrid will generate must be such that grid cells on
# tile 6 either lie completely within this grid or outside of it, i.e.
# they cannot lie partially within/outside of it.  This implies that the
# starting indices on the tile 6 supergrid of the grid with wide halo
# must be odd while the ending indices must be even.  Thus, below, we
# subtract 1 from the starting indices if they are even (which ensures
# that there will be at least nhw_T7 halo cells along the left and bot-
# tom boundaries), and we add 1 to the ending indices if they are odd
# (which ensures that there will be at least nhw_T7 halo cells along the
# right and top boundaries).
#
#-----------------------------------------------------------------------
#
  if [ $(( istart_rgnl_wide_halo_T6SG%2 )) -eq 0 ]; then
    istart_rgnl_wide_halo_T6SG=$(( istart_rgnl_wide_halo_T6SG - 1 ))
  fi
  if [ $(( iend_rgnl_wide_halo_T6SG%2 )) -eq 1 ]; then
    iend_rgnl_wide_halo_T6SG=$(( iend_rgnl_wide_halo_T6SG + 1 ))
  fi
  
  if [ $(( jstart_rgnl_wide_halo_T6SG%2 )) -eq 0 ]; then
    jstart_rgnl_wide_halo_T6SG=$(( jstart_rgnl_wide_halo_T6SG - 1 ))
  fi
  if [ $(( jend_rgnl_wide_halo_T6SG%2 )) -eq 1 ]; then
    jend_rgnl_wide_halo_T6SG=$(( jend_rgnl_wide_halo_T6SG + 1 ))
  fi
#
#-----------------------------------------------------------------------
#
# Save the current shell options and temporarily turn off the xtrace op-
# tion to prevent clutter in stdout.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; set +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Now that the starting and ending tile 6 supergrid indices of the re-
# gional grid with the wide halo have been calculated (and adjusted), we
# recalculate the width of the wide halo on:
#
# 1) the tile 6 supergrid;
# 2) the tile 6 grid; and
# 3) the tile 7 grid.
#
# These are the final values of these quantities that are guaranteed to
# correspond to the starting and ending indices on the tile 6 supergrid.
#
#-----------------------------------------------------------------------
#
  print_info_msg_verbose "\
Original values of the halo width on the tile 6 supergrid and on the 
tile 7 grid are:
  nhw_T6SG = $nhw_T6SG
  nhw_T7   = $nhw_T7"

  nhw_T6SG=$(( $istart_rgnl_T6SG - $istart_rgnl_wide_halo_T6SG ))
  nhw_T6=$(( $nhw_T6SG/2 ))
  nhw_T7=$(( $nhw_T6*$refine_ratio ))

  print_info_msg_verbose "\
Values of the halo width on the tile 6 supergrid and on the tile 7 grid 
AFTER adjustments are:
  nhw_T6SG = $nhw_T6SG
  nhw_T7   = $nhw_T7"
#
#-----------------------------------------------------------------------
#
# Calculate the number of cells that the regional domain (without halo)
# has in each of the two horizontal directions (say x and y).  We denote
# these by nx_T7 and ny_T7, respectively.  These will be needed in the
# "shave" steps later below.
#
#-----------------------------------------------------------------------
#
  nx_rgnl_T6SG=$(( $iend_rgnl_T6SG - $istart_rgnl_T6SG + 1 ))
  nx_rgnl_T6=$(( $nx_rgnl_T6SG/2 ))
  nx_T7=$(( $nx_rgnl_T6*$refine_ratio ))
  
  ny_rgnl_T6SG=$(( $jend_rgnl_T6SG - $jstart_rgnl_T6SG + 1 ))
  ny_rgnl_T6=$(( $ny_rgnl_T6SG/2 ))
  ny_T7=$(( $ny_rgnl_T6*$refine_ratio ))
#
# The following are set only for informational purposes.
#
  nx_T6=$RES
  ny_T6=$RES
  nx_T6SG=$(( $nx_T6*2 ))
  ny_T6SG=$(( $ny_T6*2 ))
  
  prime_factors_nx_T7=$( factor $nx_T7 | sed -r -e 's/^[0-9]+: (.*)/\1/' )
  prime_factors_ny_T7=$( factor $ny_T7 | sed -r -e 's/^[0-9]+: (.*)/\1/' )
  
  print_info_msg_verbose "\
The number of cells in the two horizontal directions (x and y) on the 
parent tile's (tile 6) grid and supergrid are:
  nx_T6 = $nx_T6
  ny_T6 = $ny_T6
  nx_T6SG = $nx_T6SG
  ny_T6SG = $ny_T6SG

The number of cells in the two horizontal directions on the tile 6 grid
and supergrid that the regional domain (tile 7) WITHOUT A HALO encompasses
are:
  nx_rgnl_T6 = $nx_rgnl_T6
  ny_rgnl_T6 = $ny_rgnl_T6
  nx_rgnl_T6SG = $nx_rgnl_T6SG
  ny_rgnl_T6SG = $ny_rgnl_T6SG

The starting and ending i and j indices on the tile 6 grid used to 
generate this regional grid are:
  istart_rgnl_T6 = $istart_rgnl_T6
  iend_rgnl_T6   = $iend_rgnl_T6
  jstart_rgnl_T6 = $jstart_rgnl_T6
  jend_rgnl_T6   = $jend_rgnl_T6

The corresponding starting and ending i and j indices on the tile 6 
supergrid are:
  istart_rgnl_T6SG = $istart_rgnl_T6SG
  iend_rgnl_T6SG   = $iend_rgnl_T6SG
  jstart_rgnl_T6SG = $jstart_rgnl_T6SG
  jend_rgnl_T6SG   = $jend_rgnl_T6SG

The refinement ratio (ratio of the number of cells in tile 7 that abut
a single cell in tile 6) is:
  refine_ratio = $refine_ratio

The number of cells in the two horizontal directions on the regional 
tile's/domain's (tile 7) grid WITHOUT A HALO are:
  nx_T7 = $nx_T7
  ny_T7 = $ny_T7

The prime factors of nx_T7 and ny_T7 are (useful for determining an MPI
task layout, i.e. layout_x and layout_y):
  prime_factors_nx_T7: $prime_factors_nx_T7
  prime_factors_ny_T7: $prime_factors_ny_T7"
#
#-----------------------------------------------------------------------
#
# For informational purposes, calculate the number of cells in each di-
# rection on the regional grid that includes the wide halo (of width
# nhw_T7 cells).  We denote these by nx_wide_halo_T7 and ny_wide_halo_-
# T7, respectively.
#
#-----------------------------------------------------------------------
#
  nx_wide_halo_T6SG=$(( $iend_rgnl_wide_halo_T6SG - $istart_rgnl_wide_halo_T6SG + 1 ))
  nx_wide_halo_T6=$(( $nx_wide_halo_T6SG/2 ))
  nx_wide_halo_T7=$(( $nx_wide_halo_T6*$refine_ratio ))
  
  ny_wide_halo_T6SG=$(( $jend_rgnl_wide_halo_T6SG - $jstart_rgnl_wide_halo_T6SG + 1 ))
  ny_wide_halo_T6=$(( $ny_wide_halo_T6SG/2 ))
  ny_wide_halo_T7=$(( $ny_wide_halo_T6*$refine_ratio ))

  print_info_msg_verbose "\
nx_wide_halo_T7 = $nx_T7 \
(istart_rgnl_wide_halo_T6SG = $istart_rgnl_wide_halo_T6SG, \
iend_rgnl_wide_halo_T6SG = $iend_rgnl_wide_halo_T6SG)"

  print_info_msg_verbose "\
ny_wide_halo_T7 = $ny_T7 \
(jstart_rgnl_wide_halo_T6SG = $jstart_rgnl_wide_halo_T6SG, \
jend_rgnl_wide_halo_T6SG = $jend_rgnl_wide_halo_T6SG)"
#
#-----------------------------------------------------------------------
#
# Restore the shell options before turning off xtrace.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Now consider Jim Purser's map projection/grid generation method.
#
#-----------------------------------------------------------------------
#
elif [ "$grid_gen_method" = "JPgrid" ]; then

  pi_geom="3.14159265358979323846264338327"
  degs_per_radian=$( bc -l <<< "360.0/(2.0*$pi_geom)" )
  radius_Earth="6371000.0"  # In meters.
  
  echo
  echo "degs_per_radian = $degs_per_radian"
  echo "radius_Earth = $radius_Earth"
  
  del_angle_x_SG=$( bc -l <<< "($delx/(2.0*$radius_Earth))*$degs_per_radian" )
  del_angle_x_SG=$( printf "%0.10f\n" $del_angle_x_SG )
  
  del_angle_y_SG=$( bc -l <<< "($dely/(2.0*$radius_Earth))*$degs_per_radian" )
  del_angle_y_SG=$( printf "%0.10f\n" $del_angle_y_SG )
  
  echo "del_angle_x_SG = $del_angle_x_SG"
  echo "del_angle_y_SG = $del_angle_y_SG"
  
  mns_nx_T7_pls_wide_halo=$( bc -l <<< "-($nx_T7 + 2*$nhw_T7)" )
  mns_nx_T7_pls_wide_halo=$( printf "%.0f\n" $mns_nx_T7_pls_wide_halo )
  echo "mns_nx_T7_pls_wide_halo = $mns_nx_T7_pls_wide_halo"
  
  mns_ny_T7_pls_wide_halo=$( bc -l <<< "-($ny_T7 + 2*$nhw_T7)" )
  mns_ny_T7_pls_wide_halo=$( printf "%.0f\n" $mns_ny_T7_pls_wide_halo )
  echo "mns_ny_T7_pls_wide_halo = $mns_ny_T7_pls_wide_halo"
#
# The following need to be defined in order for this script to not quit
# with an "Undefined Variable" error, but they're not actually used for
# needed for grid_gen_method set to "JPgrid".
# type grid generation.
#
  istart_rgnl_wide_halo_T6SG=""
  iend_rgnl_wide_halo_T6SG=""
  jstart_rgnl_wide_halo_T6SG=""
  jend_rgnl_wide_halo_T6SG=""

fi
#
#-----------------------------------------------------------------------
#
# Calculate PE_MEMBER01.  This is the number of MPI tasks used for the
# forecast, including those for the write component if quilting is set
# to true.
#
#-----------------------------------------------------------------------
#
PE_MEMBER01=$(( $layout_x*$layout_y ))
if [ "$quilting" = ".true." ]; then
  PE_MEMBER01=$(( $PE_MEMBER01 + $write_groups*$write_tasks_per_group ))
fi

print_info_msg_verbose "\
The number of MPI tasks for the forecast (including those for the write component
if it is being used) are:
  PE_MEMBER01 = $PE_MEMBER01"
#
#-----------------------------------------------------------------------
#
# Make sure that the number of cells in the x and y direction are divi-
# sible by the MPI task dimensions layout_x and layout_y, respectively.
#
#-----------------------------------------------------------------------
#
rem=$(( $nx_T7%$layout_x ))
if [ $rem -ne 0 ]; then
  print_err_msg_exit "\
The number of grid cells in the x direction (nx_T7) is not evenly divisible
by the number of MPI tasks in the x direction (layout_x):
  nx_T7 = $nx_T7
  layout_x = $layout_x"
fi

rem=$(( $ny_T7%$layout_y ))
if [ $rem -ne 0 ]; then
  print_err_msg_exit "\
The number of grid cells in the y direction (ny_T7) is not evenly divisible
by the number of MPI tasks in the y direction (layout_y):
  ny_T7 = $ny_T7
  layout_y = $layout_y"
fi

print_info_msg_verbose "\
The MPI task layout is:
  layout_x = $layout_x
  layout_y = $layout_y"
#
#-----------------------------------------------------------------------
#
# Make sure that, for a given MPI task, the number columns (which is 
# equal to the number of horizontal cells) is divisible by the blocksize.
#
#-----------------------------------------------------------------------
#
nx_per_task=$(( $nx_T7/$layout_x ))
ny_per_task=$(( $ny_T7/$layout_y ))
num_cols_per_task=$(( $nx_per_task*$ny_per_task ))

rem=$(( $num_cols_per_task%$blocksize ))
if [ $rem -ne 0 ]; then
  print_err_msg_exit "\
The number of columns assigned to a given MPI task must be divisible by
the blocksize:
  nx_per_task = nx_T7/layout_x = $nx_T7/$layout_x = $nx_per_task
  ny_per_task = ny_T7/layout_y = $ny_T7/$layout_y = $ny_per_task
  num_cols_per_task = nx_per_task*ny_per_task = $num_cols_per_task
  blocksize = $blocksize
  rem = num_cols_per_task%%blocksize = $rem"
fi
#
#-----------------------------------------------------------------------
#
# Set the full path to the template file that defines the write-compo-
# nent parameters.  This file is assumed/expected to be in the templates
# directory (TEMPLATE_DIR).  Then, if the write component is going to be
# used to write output files (i.e. quilting is set to ".true."), make
# sure that this template file exists.
#
#-----------------------------------------------------------------------
#
WRTCMP_PARAMS_TEMPLATE_FP="$TEMPLATE_DIR/$WRTCMP_PARAMS_TEMPLATE_FN"
if [ \( "$quilting" = ".true." \) -a \
     \( ! -f "$WRTCMP_PARAMS_TEMPLATE_FP" \) ]; then
  print_err_msg_exit "\
The write-component template file does not exist:
  WRTCMP_PARAMS_TEMPLATE_FP = \"$WRTCMP_PARAMS_TEMPLATE_FP\""
fi
#
#-----------------------------------------------------------------------
#
# If the write component is going to be used, make sure that the number
# of grid cells in the y direction (ny_T7) is divisible by the number of
# write tasks per group.  This is because the ny_T7 rows of the grid
# must be distributed evenly among the write_tasks_per_group tasks in a
# given write group, i.e. each task must receive the same number of
# rows.  This implies that ny_T7 must be evenly divisible by write_-
# tasks_per_group.  If it isn't, the write component will hang or fail.
# We check for this below.
#
#-----------------------------------------------------------------------
#
if [ "$quilting" = ".true." ]; then

  rem=$(( $ny_T7%$write_tasks_per_group ))

  if [ $rem -ne 0 ]; then
    print_err_msg_exit "\
The number of grid points in the y direction on the regional grid (ny_T7) must
be evenly divisible by the number of tasks per write group (write_tasks_per_group):
  ny_T7 = $ny_T7
  write_tasks_per_group = $write_tasks_per_group
  ny_T7 % write_tasks_per_group = $rem"
  fi

fi
#
#-----------------------------------------------------------------------
#
# Calculate the number of nodes (NUM_NODES) to request from the job
# scheduler.  This is just PE_MEMBER01 dividied by the number of cores
# per node (ncores_per_node) rounded up to the nearest integer, i.e.
#
#   NUM_NODES = ceil(PE_MEMBER01/ncores_per_node)
#
# where ceil(...) is the ceiling function, i.e. it rounds its floating
# point argument up to the next larger integer.  Since in bash division
# of two integers returns a truncated integer and since bash has no
# built-in ceil(...) function, we perform the rounding-up operation by
# adding the denominator (of the argument of ceil(...) above) minus 1 to
# the original numerator, i.e. by redefining NUM_NODES to be
#
#   NUM_NODES = (PE_MEMBER01 + ncores_per_node - 1)/ncores_per_node
#
#-----------------------------------------------------------------------
#
NUM_NODES=$(( ($PE_MEMBER01 + $ncores_per_node - 1)/$ncores_per_node ))
#
#-----------------------------------------------------------------------
#
# Create a new work directory.  Then create a new run directory as well
# as the subdirectories INPUT and RESTART under it.  Note that at this
# point we are guaranteed that there are no preexisting work or run di-
# rectories.
#
#-----------------------------------------------------------------------
#
mkdir_vrfy -p "$WORKDIR"
mkdir_vrfy -p "$RUNDIR"
mkdir_vrfy "$RUNDIR/INPUT"
mkdir_vrfy "$RUNDIR/RESTART"
#
#-----------------------------------------------------------------------
#
# Generate the shell script that will appear in the run directory (RUN-
# DIR) and will contain definitions of variables needed by the various
# scripts in the workflow.  We refer to this as the variable definitions
# file.  We will create this file by:
#
# 1) Copying the default workflow/experiment configuration script (spe-
#    fied by DEFAULT_CONFIG_FN and located in the shell script directory
#    USHDIR) to the run directory and renaming it to the name specified
#    by SCRIPT_VAR_DEFNS_FN.
#
# 2) Resetting the original values of the variables defined in this file
#    to their current values.  This is necessary because these variables 
#    may have been reset by the local configuration script (if one ex-
#    ists in USHDIR) and/or by this setup script, e.g. because predef_-
#    domain is set to a valid non-empty value.
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
SCRIPT_VAR_DEFNS_FP="$RUNDIR/$SCRIPT_VAR_DEFNS_FN"
cp_vrfy ./${DEFAULT_CONFIG_FN} ${SCRIPT_VAR_DEFNS_FP}
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
# Replace all occurrences of actual newlines in the variable str_to_in-
# sert with escaped backslash-n.  This is needed for the sed command be-
# low to work properly (i.e. to avoid it failing with an "unterminated
# `s' command" message).
#
str_to_insert=${str_to_insert//$'\n'/\\n}
#
# Insert str_to_insert into SCRIPT_VAR_DEFNS_FP right after the line
# containing the name of the interpreter.
#
REGEXP="(^#!.*)"
sed -i -r -e "s|$REGEXP|\1\n\n$str_to_insert\n|g" $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Reset each of the variables in the variable definitions file to its 
# value in the current environment.  To accomplish this, we:
#
# 1) Create a list of variable settings by stripping out comments, blank
#    lines, extraneous leading whitespace, etc from the variable defini-
#    tions file (which is currently identical to the default workflow/
#    experiment configuration script) and saving the result in the vari-
#    able var_list.  Each line of var_list will have the form
#
#      VAR=...
#
#    where the VAR is a variable name and ... is the value from the de-
#    fault configuration script (which does not necessarily correspond
#    to the current value of the variable).
#
# 2) Loop through each line of var_list.  For each line, extract the
#    variable name (and save it in the variable var_name), get its value
#    from the current environment (using bash indirection, i.e. 
#    ${!var_name}), and use the set_file_param() function to replace the
#    value of the variable in the variable definitions script (denoted 
#    above by ...) with its current value. 
#
#-----------------------------------------------------------------------
#
var_list=$( sed -r \
            -e "s/^([ ]*)([^ ]+.*)/\2/g" \
            -e "/^#.*/d" \
            -e "/^$/d" \
            ${SCRIPT_VAR_DEFNS_FP} )

while read crnt_line; do
  var_name=$( printf "%s" "${crnt_line}" | sed -n -r -e "s/^([^ ]*)=.*/\1/p" )
  var_value="${!var_name}"
  set_file_param "${SCRIPT_VAR_DEFNS_FP}" "${var_name}" "${var_value}"
done <<< "${var_list}"
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
cat << EOM >> $SCRIPT_VAR_DEFNS_FP

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
# Directories.
#
#-----------------------------------------------------------------------
#
FV3SAR_DIR="$FV3SAR_DIR"
USHDIR="$USHDIR"
SORCDIR="$SORCDIR"
TEMPLATE_DIR="$TEMPLATE_DIR"
INIDIR="$INIDIR"
RUNDIR="$RUNDIR"
FIXgsm="$FIXgsm"
UPPFIX="$UPPFIX"
GSDFIX="$GSDFIX"
CCPPFIX="$CCPPFIX"
WORKDIR_GRID="$WORKDIR_GRID"
WORKDIR_OROG="$WORKDIR_OROG"
WORKDIR_FLTR="$WORKDIR_FLTR"
WORKDIR_SHVE="$WORKDIR_SHVE"
WORKDIR_ICBC="$WORKDIR_ICBC"
#
#-----------------------------------------------------------------------
#
# Files.
#
#-----------------------------------------------------------------------
#
WRTCMP_PARAMS_TEMPLATE_FP="$WRTCMP_PARAMS_TEMPLATE_FP"
#
#-----------------------------------------------------------------------
#
# Grid configuration parameters for the cubed-sphere-based grid (these
# are in addition to the basic ones defined above).
#
#-----------------------------------------------------------------------
#
gtype="$gtype"
CRES="$CRES"
nh0_T7="$nh0_T7"
nh3_T7="$nh3_T7"
nh4_T7="$nh4_T7"
nhw_T7="$nhw_T7"
istart_rgnl_wide_halo_T6SG="$istart_rgnl_wide_halo_T6SG"
iend_rgnl_wide_halo_T6SG="$iend_rgnl_wide_halo_T6SG"
jstart_rgnl_wide_halo_T6SG="$jstart_rgnl_wide_halo_T6SG"
jend_rgnl_wide_halo_T6SG="$jend_rgnl_wide_halo_T6SG"
nx_T7="$nx_T7"
ny_T7="$ny_T7"
#
#-----------------------------------------------------------------------
#
# Grid configuration parameterms for Jim Purser's map projection.
#
#-----------------------------------------------------------------------
#
del_angle_x_SG="$del_angle_x_SG"
del_angle_y_SG="$del_angle_y_SG"
mns_nx_T7_pls_wide_halo="$mns_nx_T7_pls_wide_halo"
mns_ny_T7_pls_wide_halo="$mns_ny_T7_pls_wide_halo"
a_grid_param="$a_grid_param"
k_grid_param="$k_grid_param"
#
#-----------------------------------------------------------------------
#
# Initial date and time and boundary update times.
#
#-----------------------------------------------------------------------
#
YYYY="$YYYY"
MM="$MM"
DD="$DD"
HH="$HH"
YMD="$YMD"
BC_update_times_hrs=(${BC_update_times_hrs[@]})  # BC_update_times_hrs is an array, even if it has only one element.
#
#-----------------------------------------------------------------------
#
# Computational parameters.
#
#-----------------------------------------------------------------------
#
ncores_per_node="$ncores_per_node"
PE_MEMBER01="$PE_MEMBER01"
EOM
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

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


