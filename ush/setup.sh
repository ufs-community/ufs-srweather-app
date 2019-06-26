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
# Source the script defining the valid values of experiment variables.
#
#-----------------------------------------------------------------------
#
. ./valid_param_vals.sh
#
#-----------------------------------------------------------------------
#
# Make sure that VERBOSE is set to a valid value.
#
#-----------------------------------------------------------------------
#
iselementof "$VERBOSE" valid_vals_VERBOSE || { \
valid_vals_VERBOSE_str=$(printf "\"%s\" " "${valid_vals_VERBOSE[@]}");
print_err_msg_exit "\
Value specified in VERBOSE is not supported:
  VERBOSE = \"$VERBOSE\"
VERBOSE must be set to one of the following:
  $valid_vals_VERBOSE_str
"; }
#
#-----------------------------------------------------------------------
#
# Convert machine name to upper case if necessary.  Then make sure that
# MACHINE is set to a valid value.
#
#-----------------------------------------------------------------------
#
MACHINE=$( printf "%s" "$MACHINE" | sed -e 's/\(.*\)/\U\1/' )

iselementof "$MACHINE" valid_vals_MACHINE || { \
valid_vals_MACHINE_str=$(printf "\"%s\" " "${valid_vals_MACHINE[@]}");
print_err_msg_exit "\
Machine specified in MACHINE is not supported:
  MACHINE = \"$MACHINE\"
MACHINE must be set to one of the following:
  $valid_vals_MACHINE_str
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
  SCHED="slurm"
  QUEUE_DEFAULT=${QUEUE_DEFAULT:-"batch"}
  QUEUE_HPSS=${QUEUE_HPSS:-"service"}
  QUEUE_RUN_FV3SAR=${QUEUE_RUN_FV3SAR:-""}
  ;;
#
"JET")
#
  ncores_per_node=24
  SCHED="slurm"
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
# Make sure predef_domain is set to a valid value.
#
#-----------------------------------------------------------------------
#
if [ ! -z ${predef_domain} ]; then
  iselementof "$predef_domain" valid_vals_predef_domain || { \
  valid_vals_predef_domain_str=$(printf "\"%s\" " "${valid_vals_predef_domain[@]}");
  print_err_msg_exit "\
Predefined regional domain specified in predef_domain is not supported:
  predef_domain = \"$predef_domain\"
predef_domain must be set either to an empty string or to one of the following:
  $valid_vals_predef_domain_str
"; }
fi



#
#-----------------------------------------------------------------------
#
# Make sure CCPP is set to a valid value.
#
#-----------------------------------------------------------------------
#
if [ ! -z ${CCPP} ]; then
  iselementof "$CCPP" valid_vals_CCPP || { \
  valid_vals_CCPP_str=$(printf "\"%s\" " "${valid_vals_CCPP[@]}");
  print_err_msg_exit "\
The value specified for the CCPP flag is not supported:
  CCPP = \"$CCPP\"
CCPP must be set to one of the following:
  $valid_vals_CCPP_str
"; }
fi
#
#-----------------------------------------------------------------------
#
# If CCPP is set to "true", make sure CCPP_phys_suite is set to a valid
# value.
#
#-----------------------------------------------------------------------
#
if [ "$CCPP" = "true" ]; then

  if [ ! -z ${CCPP_phys_suite} ]; then
    iselementof "$CCPP_phys_suite" valid_vals_CCPP_phys_suite || { \
    valid_vals_CCPP_phys_suite_str=$(printf "\"%s\" " "${valid_vals_CCPP_phys_suite[@]}");
    print_err_msg_exit "\
The CCPP physics suite specified in CCPP_phys_suite is not supported:
  CCPP_phys_suite = \"$CCPP_phys_suite\"
CCPP_phys_suite must be set to one of the following:
  $valid_vals_CCPP_phys_suite_str
  "; }
  fi

fi


if [ "$grid_gen_method" = "GFDLgrid" ]; then
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
    RES="384"
    ;;
#
  "HRRR")       # The HRRR domain.
    RES="384"
    ;;
#
  "EMCCONUS")   # EMC's C768 domain over the CONUS.
    RES="768"
    ;;
#
  esac
#
#-----------------------------------------------------------------------
#
# Make sure RES is set to a valid value.
#
#-----------------------------------------------------------------------
#
  iselementof "$RES" valid_vals_RES || { \
  valid_vals_RES_str=$(printf "\"%s\" " "${valid_vals_RES[@]}");
  print_err_msg_exit "\
Number of grid cells per tile (in each horizontal direction) specified in
RES is not supported:
  RES = \"$RES\"
RES must be one of the following:
  $valid_vals_RES_str
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
# For a grid with grid_gen_method set to "JPgrid", the orography filter-
# is performed by passing to the orography filtering the parameters for
# an "equivalent" global uniform cubed-sphere grid.  These are the para-
# meters that a global uniform cubed-sphere grid needs to have in order
# to have a nominal grid cell size equal to that of the (average) cell
# size on the regional grid.  These globally-equivalent parameters in-
# clude a resolution (in units of number of cells in each of the two ho-
# rizontal directions) and a stretch factor.  The equivalent resolution
# is calculated in the script that generates the grid and orography, and
# the stretch factor needs to be set to 1 because we are considering an
# equivalent globally UNIFORM grid.  However, it turns out that with a 
# non-symmetric regional grid (one in which nx is not equal to ny), set-
# ting stretch_fac to 1 fails because the orography filtering program is
# designed for a global cubed-sphere grid and thus assumes that nx and 
# ny for a given tile are equal when stretch_fac is exactly equal to 1.  <-- Why is this?  Seems like symmetry btwn x and y should still hold when stretch_fac is not equal to 1.  
# It turns out that the program will work if we set stretch_fac that is
# not exactly 1.  This is what we do below. 
#
#-----------------------------------------------------------------------
#
elif [ "$grid_gen_method" = "JPgrid" ]; then

  stretch_fac="0.999"

fi





#
#-----------------------------------------------------------------------
#
# Check that DATE_FIRST_CYCL and DATE_LAST_CYCL are strings consisting 
# of exactly 8 digits.
#
#-----------------------------------------------------------------------
#
DATE_OR_NULL=$( printf "%s" "$DATE_FIRST_CYCL" | sed -n -r -e "s/^([0-9]{8})$/\1/p" )
if [ -z "${DATE_OR_NULL}" ]; then
  print_err_msg_exit "\
DATE_FIRST_CYCL must be a string consisting of exactly 8 digits of the 
form \"YYYYMMDD\", where YYYY is the 4-digit year, MM is the 2-digit 
month, DD is the 2-digit day-of-month, and HH is the 2-digit hour-of-
day.
  DATE_FIRST_CYCL = \"$DATE_FIRST_CYCL\""
fi

DATE_OR_NULL=$( printf "%s" "$DATE_LAST_CYCL" | sed -n -r -e "s/^([0-9]{8})$/\1/p" )
if [ -z "${DATE_OR_NULL}" ]; then
  print_err_msg_exit "\
DATE_LAST_CYCL must be a string consisting of exactly 8 digits of the 
form \"YYYYMMDD\", where YYYY is the 4-digit year, MM is the 2-digit 
month, DD is the 2-digit day-of-month, and HH is the 2-digit hour-of-
day.
  DATE_LAST_CYCL = \"$DATE_LAST_CYCL\""
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

  if [ "${CYCL_OR_NULL}" -lt "0" ] || [ "${CYCL_OR_NULL}" -gt "23" ]; then
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
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
YYYY_FIRST_CYCL=${DATE_FIRST_CYCL:0:4}
MM_FIRST_CYCL=${DATE_FIRST_CYCL:4:2}
DD_FIRST_CYCL=${DATE_FIRST_CYCL:6:2}
HH_FIRST_CYCL=${CYCL_HRS[0]}
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
# EXECDIR:
# Directory containing various executable files.
#
# TEMPLATE_DIR:
# Directory in which templates of various FV3SAR input files are locat-
# ed.
#
# NEMSfv3gfs_DIR:
# Directory in which the (NEMS-enabled) FV3SAR application is located.
# This directory includes subdirectories for FV3, NEMS, and FMS.  If
# CCPP is set to "true", it also includes a subdirectory for CCPP.  Note
# that this directory depends on whether or not we are using CCPP.
#
# FIXgsm:
# System directory in which the fixed (i.e. time-independent) files that
# are needed to run the FV3SAR model are located.
#
# SFC_CLIMO_INPUT_DIR:
# Directory in which the sfc_climo_gen code looks for surface climatolo-
# gy input files.
#
# UPPFIX:
# System directory from which to copy necessary fixed files for UPP.
#
# GSDFIX:
# System directory from which to copy GSD physics-related fixed files 
# needed when running CCPP.
#
#-----------------------------------------------------------------------
#
FV3SAR_DIR="$BASEDIR/fv3sar_workflow"
USHDIR="$FV3SAR_DIR/ush"
SORCDIR="$FV3SAR_DIR/sorc"
EXECDIR="$FV3SAR_DIR/exec"
TEMPLATE_DIR="$USHDIR/templates"

if [ "$CCPP" = "true" ]; then
  NEMSfv3gfs_DIR="$BASEDIR/NEMSfv3gfs-CCPP"
else
  NEMSfv3gfs_DIR="$BASEDIR/NEMSfv3gfs"
fi
#
# Make sure that the NEMSfv3gfs_DIR directory exists.
#
if [ ! -d "$NEMSfv3gfs_DIR" ]; then
  print_err_msg_exit "\
The NEMSfv3gfs directory specified by NEMSfv3gfs_DIR that should contain
the FV3 source code does not exist:
  NEMSfv3gfs_DIR = \"$NEMSfv3gfs_DIR\"
Please clone the NEMSfv3gfs repository in this directory, build the FV3
executable, and then rerun the workflow."
fi

UPPFIX="$FV3SAR_DIR/fix/fix_upp"
GSDFIX="$FV3SAR_DIR/fix/fix_gsd"

case $MACHINE in

"WCOSS_C")
  FIXgsm="/gpfs/hps3/emc/global/noscrub/emc.glopara/git/fv3gfs/fix/fix_am"

#  if [ "$ictype" = "pfv3gfs" ]; then
#    export INIDIR="/gpfs/hps3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/gfs.$YMD/$HH"
#  else
#    export INIDIR="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
#  fi
  ;;

"WCOSS")
  FIXgsm="/gpfs/hps3/emc/global/noscrub/emc.glopara/git/fv3gfs/fix/fix_am"

#  if [ "$ictype" = "pfv3gfs" ]; then
#    export INIDIR="/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/gfs.$YMD/$HH"
#  else
#    export INIDIR="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
#  fi
  ;;

"DELL")
  FIXgsm="/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/fv3gfs/fix/fix_am"

#  if [ "$ictype" = "pfv3gfs" ]; then
#    export INIDIR="/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/gfs.$YMD/$HH"
#  else
#    export INIDIR="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
#  fi
  ;;

"THEIA")
  FIXgsm="/scratch4/NCEPDEV/global/save/glopara/git/fv3gfs/fix/fix_am"
  SFC_CLIMO_INPUT_DIR="/scratch4/NCEPDEV/da/noscrub/George.Gayno/climo_fields_netcdf"

#  if [ "$ictype" = "pfv3gfs" ]; then
#    export INIDIR="/scratch4/NCEPDEV/fv3-cam/noscrub/Eric.Rogers/prfv3rt1/gfs.$YMD/$HH"
#  else
#    export COMROOTp2="/scratch4/NCEPDEV/rstprod/com"
#    export INIDIR="$COMROOTp2/gfs/prod/gfs.$YMD"
#  fi
  ;;

"JET")
  FIXgsm="/lfs3/projects/hpc-wof1/ywang/regional_fv3/fix/fix_am"
  ;;

"ODIN")
  FIXgsm="/scratch/ywang/external/fix_am"
  ;;

*)
  print_err_msg_exit "\
Directories have not been specified for this machine:
  MACHINE = \"$MACHINE\"
"
  ;;

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
# by the BC update interval (LBC_UPDATE_INTVL_HRS).  If not, print out a
# warning and exit this script.  If so, generate an array of forecast
# hours at which the boundary values will be updated.
#
#-----------------------------------------------------------------------
#
rem=$(( $fcst_len_hrs % $LBC_UPDATE_INTVL_HRS ))

if [ "$rem" -ne "0" ]; then
  print_err_msg_exit "\
The forecast length (fcst_len_hrs) is not evenly divisible by the later-
al boundary conditions update interval (LBC_UPDATE_INTVL_HRS):
  fcst_len_hrs = $fcst_len_hrs
  LBC_UPDATE_INTVL_HRS = $LBC_UPDATE_INTVL_HRS
  rem = fcst_len_hrs % LBC_UPDATE_INTVL_HRS = $rem"
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
LBC_UPDATE_FCST_HRS=($( seq ${LBC_UPDATE_INTVL_HRS} \
                            ${LBC_UPDATE_INTVL_HRS} \
                            ${fcst_len_hrs} ))
#
#-----------------------------------------------------------------------
#
# If expt_title is set to a non-empty value [i.e. it is neither unset 
# nor null, where null means an empty string], prepend an underscore to
# it.  Otherwise, set it to null.
#
#-----------------------------------------------------------------------
#
expt_title=${expt_title:+_$expt_title}
#
#-----------------------------------------------------------------------
#
# Check if predef_domain is set to a valid (non-empty) value.  If so:
#
# 1) Reset the experiment title (expt_title).
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
# Prepend the string "_RAP" to expt_title.
#
  expt_title="_RAP${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then

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

    dt_atmos="90"

    layout_x="14"
    layout_y="14"
    write_tasks_per_group="14"
    blocksize="26"

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-106.0
    lat_rgnl_ctr=54.0

    delx="13000.0"
    dely="13000.0"

    nx_T7=960
    ny_T7=960

    nhw_T7=6

    dt_atmos="90"

    layout_x="16"
    layout_y="16"
    write_tasks_per_group="16"
    blocksize="30"

  fi
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
# Prepend the string "_HRRR" to expt_title.
#
  expt_title="_HRRR${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then
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

    dt_atmos="50"

    layout_x="20"
    layout_y="20"
    write_tasks_per_group="20"
    blocksize="36"

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-97.5
    lat_rgnl_ctr=38.5

    delx="3000.0"
    dely="3000.0"

#
# This is the old HRRR-like grid that is slightly larger than the WRF-
# ARW HRRR grid.
#
if [ 0 = 1 ]; then

    nx_T7=1800
    ny_T7=1120

    nhw_T7=6

    dt_atmos="50"

    layout_x="20"
    layout_y="20"
    write_tasks_per_group="20"
    blocksize="36"
#
# This is the new HRRR-like grid that is slightly smaller than the WRF-
# ARW HRRR grid (so that it can be initialized off the latter).
#
else

    nx_T7=1734
    ny_T7=1008

    nhw_T7=6

    dt_atmos="50"

    layout_x="34"
    layout_y="24"
    write_tasks_per_group="24"
    blocksize="34"

fi


  fi
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
# Prepend the string "_EMCCONUS" to expt_title.
#
  expt_title="_EMCCONUS${expt_title}"

  if [ "$grid_gen_method" = "GFDLgrid" ]; then

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

    dt_atmos="18"

    layout_x="16"
    layout_y="72"
    write_tasks_per_group="72"
    blocksize=32

  elif [ "$grid_gen_method" = "JPgrid" ]; then

    lon_rgnl_ctr=-97.5
    lat_rgnl_ctr=38.5

    delx="3000.0"
    dely="3000.0"

    nx_T7=960
    ny_T7=960

    nhw_T7=6

  fi
#
# If the write-component is being used and the variable (WRTCMP_PARAMS_-
# TEMPLATE_FN) containing the name of the template file that specifies
# various write-component parameters has not been specified or has been
# set to an empty string, reset it to the preexisting template file for
# the EMCCONUS domain.
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
# Construct a name (EXPT_SUBDIR) that we will used for the experiment
# directory as well as the work directory (which will be created under
# the specified TMPDIR).
#
#-----------------------------------------------------------------------
#
if [ -z "${EXPT_SUBDIR}" ]; then  # If EXPT_SUBDIR is not set or is set to an empty string.

  if [ "$grid_gen_method" = "GFDLgrid" ]; then
    stretch_str="_S$( printf "%s" "${stretch_fac}" | sed "s|\.|p|" )"
    refine_str="_RR${refine_ratio}"
    EXPT_SUBDIR=${CRES}${stretch_str}${refine_str}${expt_title}
  elif [ "$grid_gen_method" = "JPgrid" ]; then
    nx_T7_str="NX$( printf "%s" "${nx_T7}" | sed "s|\.|p|" )"
    ny_T7_str="NY$( printf "%s" "${ny_T7}" | sed "s|\.|p|" )"
    a_grid_param_str="_A$( printf "%s" "${a_grid_param}" | sed "s|-|mns|" | sed "s|\.|p|" )"
    k_grid_param_str="_K$( printf "%s" "${k_grid_param}" | sed "s|-|mns|" | sed "s|\.|p|" )"
    EXPT_SUBDIR=${nx_T7_str}_${ny_T7_str}${a_grid_param_str}${k_grid_param_str}${expt_title}
  fi

fi
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
WORKDIR=$TMPDIR/$EXPT_SUBDIR
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
# WORKDIR_ICSLBCS:
# Work directory for the preprocessing steps that generate the files
# containing the surface fields as well as the initial and lateral 
# boundary conditions.
#
# WORKDIR_SFC_CLIMO:
# Work directory for the preprocessing step that generates surface files
# from climatology.
#
#----------------------------------------------------------------------
#
WORKDIR_GRID=$WORKDIR/grid
WORKDIR_OROG=$WORKDIR/orog
WORKDIR_FLTR=$WORKDIR/filtered_topo
WORKDIR_SHVE=$WORKDIR/shave
WORKDIR_ICSLBCS=$WORKDIR/ICs_BCs
WORKDIR_SFC_CLIMO=$WORKDIR/sfc_climo
#
#-----------------------------------------------------------------------
#
# Define the full path to the experiment directory.  This is the direct-
# ory in which the static input files to the FV3SAR are placed.  Then
# call the function that checks whether the experiment directory already
# exists and if so, moves it, deletes it, or quits out of this script 
# (the action taken depends on the value of the variable preexisting_-
# dir_method).  Note that we do not yet create a new experiment directory; we will do that later below once
# the workflow/experiment configuration parameters pass the various 
# checks.
#
#-----------------------------------------------------------------------
#
#if [ -z "${EXPT_BASEDIR+x}" ]; then  # If EXPT_BASEDIR is not set at all, not even to an empty string.
if [ -z "${EXPT_BASEDIR}" ]; then  # If EXPT_BASEDIR is not set or is set to an empty string.
  EXPT_BASEDIR="${BASEDIR}/expt_dirs"
fi
mkdir_vrfy -p "${EXPT_BASEDIR}"

EXPTDIR="${EXPT_BASEDIR}/${EXPT_SUBDIR}"
check_for_preexist_dir $EXPTDIR $preexisting_dir_method
#
#-----------------------------------------------------------------------
#
# Make sure EXTRN_MDL_NAME_ICSSURF is set to a valid value.
#
#-----------------------------------------------------------------------
#
iselementof "$EXTRN_MDL_NAME_ICSSURF" valid_vals_EXTRN_MDL_NAME_ICSSURF || { \
valid_vals_EXTRN_MDL_NAME_ICSSURF_str=$(printf "\"%s\" " "${valid_vals_EXTRN_MDL_NAME_ICSSURF[@]}");
print_err_msg_exit "\
The external model specified in EXTRN_MDL_NAME_ICSSURF that provides 
initial conditions (ICs) and surface fields to the FV3SAR is not support-
ed:
  EXTRN_MDL_NAME_ICSSURF = \"$EXTRN_MDL_NAME_ICSSURF\"
EXTRN_MDL_NAME_ICSSURF must be one of the following:
  $valid_vals_EXTRN_MDL_NAME_ICSSURF_str
"; }
#
#-----------------------------------------------------------------------
#
# Make sure EXTRN_MDL_NAME_LBCS is set to a valid value.
#
#-----------------------------------------------------------------------
#
iselementof "$EXTRN_MDL_NAME_LBCS" valid_vals_EXTRN_MDL_NAME_LBCS || { \
valid_vals_EXTRN_MDL_NAME_LBCS_str=$(printf "\"%s\" " "${valid_vals_EXTRN_MDL_NAME_LBCS[@]}");
print_err_msg_exit "\
The external model specified in EXTRN_MDL_NAME_LBCS that provides later-
al boundary conditions (LBCs) to the FV3SAR is not supported:
  EXTRN_MDL_NAME_LBCS = \"$EXTRN_MDL_NAME_LBCS\"
EXTRN_MDL_NAME_LBCS must be one of the following:
  $valid_vals_EXTRN_MDL_NAME_LBCS_str
"; }
#
#-----------------------------------------------------------------------
#
# Set the variable EXTRN_MDL_FILES_BASEDIR_ICSSURF that will contain the
# location of the directory in which we will create subdirectories for 
# each forecast (i.e. for each CDATE) in which to store the analysis and
# /or surface files generated by the external model specified in EXTRN_-
# MDL_NAME_ICSSURF.  These files will be used to generate input initial
# condition and surface files for the FV3SAR.
#
#-----------------------------------------------------------------------
#
case $EXTRN_MDL_NAME_ICSSURF in
"GFS")
  EXTRN_MDL_FILES_BASEDIR_ICSSURF="${WORKDIR}/GFS/ICSSURF"
  ;;
"RAPX")
  EXTRN_MDL_FILES_BASEDIR_ICSSURF="${WORKDIR}/RAPX/ICSSURF"
  ;;
"HRRRX")
  EXTRN_MDL_FILES_BASEDIR_ICSSURF="${WORKDIR}/HRRRX/ICSSURF"
  ;;
esac
#
#-----------------------------------------------------------------------
#
# Set the variable EXTRN_MDL_FILES_BASEDIR_LBCS that will contain the 
# location of the directory in which we will create subdirectories for 
# each forecast (i.e. for each CDATE) in which to store the forecast 
# files generated by the external model specified in EXTRN_MDL_NAME_-
# LBCS.  These files will be used to generate input lateral boundary 
# condition files for the FV3SAR (one per boundary update time).
#
# Also, set EXTRN_MDL_LBCS_OFFSET_HRS, which is the number of hours to
# shift the starting time of the external model that provides lateral
# boundary conditions.
#
#-----------------------------------------------------------------------
#
case $EXTRN_MDL_NAME_LBCS in
"GFS")
  EXTRN_MDL_FILES_BASEDIR_LBCS="${WORKDIR}/GFS/LBCS"
  EXTRN_MDL_LBCS_OFFSET_HRS="0"
  ;;
"RAPX")
  EXTRN_MDL_FILES_BASEDIR_LBCS="${WORKDIR}/RAPX/LBCS"
  EXTRN_MDL_LBCS_OFFSET_HRS="3"
  ;;
"HRRRX")
  EXTRN_MDL_FILES_BASEDIR_LBCS="${WORKDIR}/HRRRX/LBCS"
  EXTRN_MDL_LBCS_OFFSET_HRS="0"
  ;;
esac
#
#-----------------------------------------------------------------------
#
# Set the system directory (i.e. location on disk, not on HPSS) in which
# the files generated by the external model specified by EXTRN_MDL_-
# NAME_ICSSURF that are necessary for generating initial condition (IC)
# and surface files for the FV3SAR are stored (usually for a limited 
# time, e.g. for the GFS external model, 2 weeks on WCOSS and 2 days on
# theia).  If for a given forecast start date and time these files are
# available in this system directory, they will be copied over to EX-
# TRN_MDL_FILES_DIR, which is the location where the preprocessing tasks
# that generate the IC and surface files look for these files.  If these
# files are not available in the system directory, then we search for 
# them elsewhere, e.g. in the mass store (HPSS).
#
#-----------------------------------------------------------------------
#
case $EXTRN_MDL_NAME_ICSSURF in
#
"GFS")
#
  case $MACHINE in
  "WCOSS_C")
    EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF="/gpfs/hps/nco/ops/com/gfs/prod"
    ;;
  "THEIA")
    EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF="/scratch4/NCEPDEV/rstprod/com/gfs/prod"
    ;;
  "JET")
    EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF="/lfs3/projects/hpc-wof1/ywang/regional_fv3/gfs"
    ;;
  "ODIN")
    EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF="/scratch/ywang/test_runs/FV3_regional/gfs"
    ;;
  *)
    print_err_msg_exit "\
The system directory in which to look for the files generated by the ex-
ternal model specified by EXTRN_MDL_NAME_ICSSURF has not been specified
for this machine and external model combination:
  MACHINE = \"$MACHINE\"
  EXTRN_MDL_NAME_ICSSURF = \"$EXTRN_MDL_NAME_ICSSURF\"
"
    ;;
  esac
  ;;
#
"RAPX")
#
  case $MACHINE in
  "THEIA")
    EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF="/scratch4/BMC/public/data/gsd/rr/full/wrfnat"
    ;;
  *)
    print_err_msg_exit "\
The system directory in which to look for the files generated by the ex-
ternal model specified by EXTRN_MDL_NAME_ICSSURF has not been specified
for this machine and external model combination:
  MACHINE = \"$MACHINE\"
  EXTRN_MDL_NAME_ICSSURF = \"$EXTRN_MDL_NAME_ICSSURF\"
"
    ;;
  esac
  ;;
#
"HRRRX")
#
  case $MACHINE in
  "THEIA")
    EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF="/scratch4/BMC/public/data/gsd/hrrr/conus/wrfnat"
    ;;
  *)
    print_err_msg_exit "\
The system directory in which to look for the files generated by the ex-
ternal model specified by EXTRN_MDL_NAME_ICSSURF has not been specified
for this machine and external model combination:
  MACHINE = \"$MACHINE\"
  EXTRN_MDL_NAME_ICSSURF = \"$EXTRN_MDL_NAME_ICSSURF\"
"
    ;;
  esac
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Set the system directory (i.e. location on disk, not on HPSS) in which
# the files generated by the external model specified by EXTRN_MDL_-
# NAME_LBCS that are necessary for generating lateral boundary condition
# (LBC) files for the FV3SAR are stored (usually for a limited time, 
# e.g. for the GFS external model, 2 weeks on WCOSS and 2 days on the-
# ia).  If for a given forecast start date and time these files are
# available in this system directory, they will be copied over to EX-
# TRN_MDL_FILES_DIR, which is the location where the preprocessing tasks
# that generate the LBC files look for these files.  If these files are
# not available in the system directory, then we search for them else-
# where, e.g. in the mass store (HPSS).
#
#-----------------------------------------------------------------------
#
case $EXTRN_MDL_NAME_LBCS in
#
"GFS")
#
  case $MACHINE in
  "WCOSS_C")
    EXTRN_MDL_FILES_SYSBASEDIR_LBCS="/gpfs/hps/nco/ops/com/gfs/prod"
    ;;
  "THEIA")
    EXTRN_MDL_FILES_SYSBASEDIR_LBCS="/scratch4/NCEPDEV/rstprod/com/gfs/prod"
    ;;
  "JET")
    EXTRN_MDL_FILES_SYSBASEDIR_LBCS="/lfs3/projects/hpc-wof1/ywang/regional_fv3/gfs"
    ;;
  "ODIN")
    EXTRN_MDL_FILES_SYSBASEDIR_LBCS="/scratch/ywang/test_runs/FV3_regional/gfs"
    ;;
  *)
    print_err_msg_exit "\
The system directory in which to look for the files generated by the ex-
ternal model specified by EXTRN_MDL_NAME_LBCS has not been specified for
this machine and external model combination:
  MACHINE = \"$MACHINE\"
  EXTRN_MDL_NAME_LBCS = \"$EXTRN_MDL_NAME_LBCS\"
"
    ;;
  esac
  ;;
#
"RAPX")
#
  case $MACHINE in
  "THEIA")
    EXTRN_MDL_FILES_SYSBASEDIR_LBCS="/scratch4/BMC/public/data/gsd/rr/full/wrfnat"
    ;;
  *)
    print_err_msg_exit "\
The system directory in which to look for the files generated by the ex-
ternal model specified by EXTRN_MDL_NAME_LBCS has not been specified for
this machine and external model combination:
  MACHINE = \"$MACHINE\"
  EXTRN_MDL_NAME_LBCS = \"$EXTRN_MDL_NAME_LBCS\"
"
    ;;
  esac
  ;;
#
"HRRRX")
#
  case $MACHINE in
  "THEIA")
    EXTRN_MDL_FILES_SYSBASEDIR_LBCS="/scratch4/BMC/public/data/gsd/hrrr/conus/wrfnat"
    ;;
  *)
    print_err_msg_exit "\
The system directory in which to look for the files generated by the ex-
ternal model specified by EXTRN_MDL_NAME_LBCS has not been specified for
this machine and external model combination:
  MACHINE = \"$MACHINE\"
  EXTRN_MDL_NAME_LBCS = \"$EXTRN_MDL_NAME_LBCS\"
"
    ;;
  esac
  ;;
#
esac
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
# Make sure grid_gen_method is set to a valid value.
#
#-----------------------------------------------------------------------
#
iselementof "$grid_gen_method" valid_vals_grid_gen_method || { \
valid_vals_grid_gen_method_str=$(printf "\"%s\" " "${valid_vals_grid_gen_method[@]}");
print_err_msg_exit "\
The grid generation method specified in grid_gen_method is not supported:
  grid_gen_method = \"$grid_gen_method\"
grid_gen_method must be one of the following:
  $valid_vals_grid_gen_method_str
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

  . $USHDIR/set_gridparams_GFDLgrid.sh
#
#-----------------------------------------------------------------------
#
# Now consider Jim Purser's map projection/grid generation method.
#
#-----------------------------------------------------------------------
#
elif [ "$grid_gen_method" = "JPgrid" ]; then

  . $USHDIR/set_gridparams_JPgrid.sh

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
The number of MPI tasks for the forecast (including those for the write
component if it is being used) are:
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
  prime_factors_num_cols_per_task=$( factor $num_cols_per_task | sed -r -e 's/^[0-9]+: (.*)/\1/' )
  print_err_msg_exit "\
The number of columns assigned to a given MPI task must be divisible by
the blocksize:
  nx_per_task = nx_T7/layout_x = $nx_T7/$layout_x = $nx_per_task
  ny_per_task = ny_T7/layout_y = $ny_T7/$layout_y = $ny_per_task
  num_cols_per_task = nx_per_task*ny_per_task = $num_cols_per_task
  blocksize = $blocksize
  rem = num_cols_per_task%%blocksize = $rem
The prime factors of num_cols_per_task are (useful for determining a valid
blocksize): 
  prime_factors_num_cols_per_task: $prime_factors_num_cols_per_task"
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
# Create a new work directory and a new experiment directory.  Note that
# at this point we are guaranteed that there are no preexisting work or
# experiment directories.
#
#-----------------------------------------------------------------------
#
mkdir_vrfy -p "$WORKDIR"
mkdir_vrfy -p "$EXPTDIR"
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
SCRIPT_VAR_DEFNS_FP="$EXPTDIR/$SCRIPT_VAR_DEFNS_FN"
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
line_list=$( sed -r \
             -e "s/^([ ]*)([^ ]+.*)/\2/g" \
             -e "/^#.*/d" \
             -e "/^$/d" \
             ${SCRIPT_VAR_DEFNS_FP} )
echo 
echo "The variable \"line_list\" contains:"
echo
printf "%s\n" "${line_list}"
echo
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

    printf "\n%s\n" "var_name = \"${var_name}\""
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
        var_value=$(printf "\"%s\" " "${!array_name_at}")
        var_value="( $var_value)"
      fi
#
# If the variable specified in var_name is no set in the current envi-
# ron ment,  (to either an empty or non-empty string), get its value and in-
# sert it in the variable definitions file on the line where that varia-
# ble is defined.
#
    else

      print_info_msg "\
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
    set_file_param "${SCRIPT_VAR_DEFNS_FP}" "${var_name}" "${var_value}"
#
# If var_name is empty, then a variable name was not found in the cur-
# rent line in line_list.  In this case, print out a warning and move on
# to the next line.
#
  else

    print_info_msg "\

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
{ cat << EOM >> $SCRIPT_VAR_DEFNS_FP

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
EXECDIR="$EXECDIR"
TEMPLATE_DIR="$TEMPLATE_DIR"
NEMSfv3gfs_DIR="$NEMSfv3gfs_DIR"
EXTRN_MDL_FILES_BASEDIR_ICSSURF="$EXTRN_MDL_FILES_BASEDIR_ICSSURF"
EXTRN_MDL_FILES_BASEDIR_LBCS="$EXTRN_MDL_FILES_BASEDIR_LBCS"
EXPTDIR="$EXPTDIR"
FIXgsm="$FIXgsm"
SFC_CLIMO_INPUT_DIR="$SFC_CLIMO_INPUT_DIR"
UPPFIX="$UPPFIX"
GSDFIX="$GSDFIX"
WORKDIR_GRID="$WORKDIR_GRID"
WORKDIR_OROG="$WORKDIR_OROG"
WORKDIR_FLTR="$WORKDIR_FLTR"
WORKDIR_SHVE="$WORKDIR_SHVE"
WORKDIR_ICSLBCS="$WORKDIR_ICSLBCS"
WORKDIR_SFC_CLIMO="$WORKDIR_SFC_CLIMO"
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
# Grid configuration parameters needed regardless of grid generation me-
# thod used.
#
#-----------------------------------------------------------------------
#
gtype="$gtype"
nh0_T7="$nh0_T7"
nh3_T7="$nh3_T7"
nh4_T7="$nh4_T7"
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
if [ "$grid_gen_method" = "GFDLgrid" ]; then

  { cat << EOM >> $SCRIPT_VAR_DEFNS_FP
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
nhw_T7="$nhw_T7"
nx_T7="$nx_T7"
ny_T7="$ny_T7"
istart_rgnl_wide_halo_T6SG="$istart_rgnl_wide_halo_T6SG"
iend_rgnl_wide_halo_T6SG="$iend_rgnl_wide_halo_T6SG"
jstart_rgnl_wide_halo_T6SG="$jstart_rgnl_wide_halo_T6SG"
jend_rgnl_wide_halo_T6SG="$jend_rgnl_wide_halo_T6SG"
CRES="$CRES"
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to append grid parameters to variable definitions
file returned with a nonzero status."

elif [ "$grid_gen_method" = "JPgrid" ]; then

  { cat << EOM >> $SCRIPT_VAR_DEFNS_FP
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
del_angle_x_SG="$del_angle_x_SG"
del_angle_y_SG="$del_angle_y_SG"
mns_nx_T7_pls_wide_halo="$mns_nx_T7_pls_wide_halo"
mns_ny_T7_pls_wide_halo="$mns_ny_T7_pls_wide_halo"
#
# The following variables must be set in order to be able to use the 
# same scripting machinary for the case of grid_gen_method set to "JP-
# grid" as for grid_gen_method set to "GFDLgrid".
#
RES=""   # This will be set after the grid generation task is complete.
CRES=""  # This will be set after the grid generation task is complete.
stretch_fac="$stretch_fac"
EOM
} || print_err_msg_exit "\
Heredoc (cat) command to append grid parameters to variable definitions
file returned with a nonzero status."

fi
#
#-----------------------------------------------------------------------
#
# Continue appending variable defintions to the variable definitions 
# file.
#
#-----------------------------------------------------------------------
#
{ cat << EOM >> $SCRIPT_VAR_DEFNS_FP 
#
#-----------------------------------------------------------------------
#
# System directory in which to look for the files generated by the ex-
# ternal model specified in EXTRN_MDL_NAME_ICSSURF.  These files will be
# used to generate the input initial condition and surface files for the
# FV3SAR.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF="$EXTRN_MDL_FILES_SYSBASEDIR_ICSSURF"
#
#-----------------------------------------------------------------------
#
# System directory in which to look for the files generated by the ex-
# ternal model specified in EXTRN_MDL_NAME_LBCS.  These files will be 
# used to generate the input lateral boundary condition files for the 
# FV3SAR.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_FILES_SYSBASEDIR_LBCS="$EXTRN_MDL_FILES_SYSBASEDIR_LBCS"
#
#-----------------------------------------------------------------------
#
# Shift back in time (in units of hours) of the starting time of the ex-
# ternal model specified in EXTRN_MDL_NAME_LBCS.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_LBCS_OFFSET_HRS="$EXTRN_MDL_LBCS_OFFSET_HRS"
#
#-----------------------------------------------------------------------
#
# Boundary condition update times (in units of forecast hours).
#
#-----------------------------------------------------------------------
#
LBC_UPDATE_FCST_HRS=(${LBC_UPDATE_FCST_HRS[@]})  # LBC_UPDATE_FCST_HRS is an array, even if it has only one element.
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


