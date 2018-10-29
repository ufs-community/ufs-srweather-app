#!/bin/sh

#
#-----------------------------------------------------------------------
#
# This script sets parameters needed by the various scripts that are 
# called by the rocoto workflow.  This secondary set of parameters is 
# calculated using the primary set of user-defined parameters in the 
# configuration script config.sh.  This script then saves both sets of
# parameters in a variable-definitions script in the run directory that
# will be sourced by the various scripts called by the workflow.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Change shell behavior with "set" with these flags:
#
# -a 
# This will cause the script to automatically export all variables and 
# functions which are modified or created to the environments of subse-
# quent commands.
#
# -e 
# This will cause the script to exit as soon as any line in the script 
# fails (with some exceptions; see manual).  Apparently, it is a bad 
# idea to use "set -e".  See here:
#   http://mywiki.wooledge.org/BashFAQ/105
#
# -u 
# This will cause the script to exit if an undefined variable is encoun-
# tered.
#
# -x
# This will cause all executed commands in the script to be printed to 
# the terminal (used for debugging).
#
#-----------------------------------------------------------------------
#
#set -aux
#set -eux
set -ux
#
#-----------------------------------------------------------------------
#
# Source shell script containing function that checks for preexisting
# directories and deals with them appropriately (depending on the set-
# ting of preexisting_dir_method in the configuration script config.sh).  
# This is just to define the function so that it can be used later be-
# low.
#
#-----------------------------------------------------------------------
#
. ./check_for_preexist_dir.sh
#
#-----------------------------------------------------------------------
#
# Source the config.sh configuration script.  Depending on whether or 
# not RUNDIR has been set, this will be either in the same directory as
# the current setup script or in the run directory.
#
#-----------------------------------------------------------------------
#
CONFIG_DIR=${RUNDIR:-"."}
. $CONFIG_DIR/config.sh
#
#-----------------------------------------------------------------------
#
# Convert machine name to lower case if necessary.  Then make sure that
# machine is set to one of the allowed values.
#
#-----------------------------------------------------------------------
#
#machine=$( echo "$machine" | sed -e 's/\(.*\)/\L\1/' )  # <-- Don't do this yet, maybe later; requires changing this and other scripts to use lowercase everywhere.

if [ "$machine" != "WCOSS_C" ] && \
   [ "$machine" != "WCOSS" ] && \
   [ "$machine" != "THEIA" ]; then
  echo
  echo "Error.  Machine specified in \"machine\" is not supported:"
  echo "  machine = $machine"
  echo "machine must be set to one of the following:"
  echo "  \"WCOSS_C\""
  echo "  \"WCOSS\""
  echo "  \"THEIA\""
  echo "Exiting script."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Set the number of cores per node for the specified machine.
#
#-----------------------------------------------------------------------
#
if [ "$machine" = "WCOSS_C" ]; then
  export ncores_per_node=${ncores_per_node}  # Don't know the default on WCOS_C, so must get it from environment.
elif [ "$machine" = "WCOSS" ]; then
  export ncores_per_node=${ncores_per_node}  # Don't know the default on WCOS, so must get it from environment.
elif [ "$machine" = "THEIA" ]; then
  export ncores_per_node=${ncores_per_node:-24}
fi
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
export gtype="regional"
# 
#-----------------------------------------------------------------------
#
# Make sure predef_rgnl_domain is set to one of the allowed values.
#
#-----------------------------------------------------------------------
#
if [ "$predef_rgnl_domain" != "" ] && \
   [ "$predef_rgnl_domain" != "RAP" ] && \
   [ "$predef_rgnl_domain" != "HRRR" ]; then
  echo
  echo "Error.  Predefined regional domain specified in \"predef_rgnl_domain\" is not supported:"
  echo "  predef_rgnl_domain = $predef_rgnl_domain"
  echo "predef_rgnl_domain must either be an empty string or be one of the following:"
  echo "  \"RAP\""
  echo "  \"HRRR\""
  echo "Exiting script."
  exit 1
fi
# 
#-----------------------------------------------------------------------
#
# If predef_rgnl_domain is set to a non-empty string, reset RES to the
# appropriate value.
# 
#-----------------------------------------------------------------------
#
case $predef_rgnl_domain in
#
"RAP")   # The RAP domain.
  export RES="384"
  ;;
#
"HRRR")  # The HRRR domain.
  export RES="384"
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
if [ "$RES" != "48" ] && \
   [ "$RES" != "96" ] && \
   [ "$RES" != "192" ] && \
   [ "$RES" != "384" ] && \
   [ "$RES" != "768" ] && \
   [ "$RES" != "1152" ] && \
   [ "$RES" != "3072" ]; then
  echo
  echo "Error.  Number of grid points specified in \"RES\" is not supported:"
  echo "  RES = $RES"
  echo "RES must be one of:  48  96  192  384  768  1152  3072"
  echo "Exiting script."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Set the C-resolution.  This is just a convenience variable containing
# the character "C" followed by the tile resolution.
#
#-----------------------------------------------------------------------
#
export CRES="C${RES}"
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour.  These are
# needed below for various operations.`
#
#-----------------------------------------------------------------------
#
YYYY=${CDATE:0:4}
MM=${CDATE:4:2}
DD=${CDATE:6:2}
HH=${CDATE:8:2}
export YMD=${CDATE:0:8}
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
# TEMPLATE_DIR:
# Directory in which templates of various FV3SAR input files are locat-
# ed.
#
# FIXgsm:
# System directory from which to copy fixed files that are needed as in-
# puts to the FV3SAR model.
#
#-----------------------------------------------------------------------
#
export FV3SAR_DIR="$BASEDIR/tmp/fv3gfs"
export USHDIR="$FV3SAR_DIR/ush"
export TEMPLATE_DIR="$USHDIR/templates"

if [ "$machine" = "WCOSS_C" ]; then
  export FIXgsm="/gpfs/hps3/emc/global/noscrub/emc.glopara/svn/fv3gfs/fix/fix_am"
elif [ "$machine" = "WCOSS" ]; then
  export FIXgsm=""
elif [ "$machine" = "THEIA" ]; then
#  export FIXgsm="/scratch4/NCEPDEV/global/save/glopara/svn/fv3gfs/fix/fix_am"
  export FIXgsm="/scratch4/NCEPDEV/global/save/glopara/git/fv3gfs/fix/fix_am"
fi
#
#-----------------------------------------------------------------------
#
# The forecast length (in integer hours) cannot contain more than 3 cha-
# racters.  Thus, its maximum value is 999.  Check whether the specified
# forecast length exceeds this maximum value.
#
#-----------------------------------------------------------------------
#
fcst_len_hrs_max=999
if [ "$fcst_len_hrs" -gt "$fcst_len_hrs_max" ]; then
  echo
  echo "Error.  Forecast length is greater than maximum allowed length:"
  echo "  fcst_len_hrs = $fcst_len_hrs"
  echo "  fcst_len_hrs_max = $fcst_len_hrs_max"
  echo "Exiting script."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Check whether the forecast length (fcst_len_hrs) is evenly divisible 
# by the BC update interval (BC_update_intvl_hrs).  If not, print out a
# warning and exit this script.
#
#-----------------------------------------------------------------------
#
remainder=$(( $fcst_len_hrs % $BC_update_intvl_hrs ))

if [ "$remainder" != "0" ]; then
  echo
  echo "Error.  The forecast length is not evenly divisible by the BC update interval:"
  echo "  fcst_len_hrs = $fcst_len_hrs"
  echo "  BC_update_intvl_hrs = $BC_update_intvl_hrs"
  echo "  remainder = fcst_len_hrs % BC_update_intvl_hrs = $remainder"
  echo "Exiting script."
  exit 1
fi

BC_times_hrs=($( seq 0 $BC_update_intvl_hrs $fcst_len_hrs ))
#
#-----------------------------------------------------------------------
#
# If run_title is set to a non-empty value [i.e. it is neither unset nor
# null (where null means an empty string)], prepend an underscore to it.
# Otherwise, set it to null.  
#
#-----------------------------------------------------------------------
#
run_title=${run_title:+_$run_title}
#
#-----------------------------------------------------------------------
#
# Check if predef_rgnl_domain is set to a valid (non-empty) value and 
# reset grid configuration parameters (as well as run_title) according-
# ly. 
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
# grid cells is used round the regional grid.  Setting num_margin_-
# cells_T6_... to at least 10 leaves enough room for this halo.
#
#-----------------------------------------------------------------------
#
case $predef_rgnl_domain in
#
"RAP")  # The RAP domain.

  export lon_ctr_T6=-106.0
  export lat_ctr_T6=54.0
  export stretch_fac=0.63
  export refine_ratio=3
#
# Prepend the string "_RAP" to run_title.
#
  run_title="_RAP${run_title}"

  num_margin_cells_T6_left=10
  istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))

  num_margin_cells_T6_right=10
  iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))

  num_margin_cells_T6_bottom=10
  jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))

  num_margin_cells_T6_top=10
  jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))
  ;;
#
"HRRR")  # The HRRR domain.

  export lon_ctr_T6=-97.5
  export lat_ctr_T6=38.5
  export stretch_fac=1.65
  export refine_ratio=5
#
# Prepend the string "_HRRR" to run_title.
#
  run_title="_HRRR${run_title}"

  num_margin_cells_T6_left=12
  istart_rgnl_T6=$(( $num_margin_cells_T6_left + 1 ))

  num_margin_cells_T6_right=12
  iend_rgnl_T6=$(( $RES - $num_margin_cells_T6_right ))

  num_margin_cells_T6_bottom=80
  jstart_rgnl_T6=$(( $num_margin_cells_T6_bottom + 1 ))

  num_margin_cells_T6_top=80
  jend_rgnl_T6=$(( $RES - $num_margin_cells_T6_top ))
  ;;

esac
#
#-----------------------------------------------------------------------
#
# Various halo sizes (units are number of cells beyond the boundary of
# the nested or regional grid).
#
#-----------------------------------------------------------------------
#
export halo=3                   # Halo size to be used in the atmosphere cubic sphere model for the grid tile.
export halop1=$(( $halo + 1 ))  # Halo size that will be used for the orography and grid tile in chgres.
export halo0=0                  # No halo, used to shave the filtered orography for use in the model.
#
#-----------------------------------------------------------------------
#
# Construct a name (RUN_SUBDIR) that we will use for the run directory
# as well as the work directory (which will be created under the speci-
# fied TMPDIR).
#
#-----------------------------------------------------------------------
#
stretch_str="_S$( echo "${stretch_fac}" | sed "s|\.|p|" )"
refine_str="_R${refine_ratio}"
export RUN_SUBDIR=${CRES}${stretch_str}${refine_str}${run_title}
#
#-----------------------------------------------------------------------
#
# Define the full path of the work directory.  This is the directory in
# which the prerpocessing steps create their input and/or place their 
# output.  Then call an external function that checks whether the work 
# directory already exists and if so, moves or deletes it or causes this
# script to quit (depending on the value of preexisting_dir_method).  
# Then create a new work directory.
#
#-----------------------------------------------------------------------
#
WORKDIR=$TMPDIR/$RUN_SUBDIR
ec=$( check_for_preexist_dir $WORKDIR $preexisting_dir_method )
if [ $ec .ne. 0 ]; then
  exit 1 
fi
mkdir $WORKDIR
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
# Work directory for the step that "shaves" the grid and filtered oro-
# graphy files.
#
# WORKDIR_SHVE:
# Work directory for the step that generates the files containing the 
# surface fields as well as the initial and boundary conditions.
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
# output files that it generates will be placed.  Then call an external
# function that checks whether the run directory already exists and if 
# so, moves or deletes it or causes this script to quit (depending on
# the value of preexisting_dir_method).  Then create a new run directory
# as well as the subdirectory INPUT under it.
#
#-----------------------------------------------------------------------
#
RUNDIR="${BASEDIR}/run_dirs/${RUN_SUBDIR}"
ec=$( check_for_preexist_dir $RUNDIR $preexisting_dir_method )
if [ $ec .ne. 0 ]; then
  exit 1 
fi
mkdir -p $RUNDIR/INPUT
#
#-----------------------------------------------------------------------
#
# Set the directory INIDIR in which we will store the analysis (at the
# initial time CDATE) and forecast (at the boundary condition times) 
# files.  These are the files that will then used to generate surface
# fields and initial and boundary conditions for the FV3SAR.
#
#-----------------------------------------------------------------------
#
export INIDIR="${WORKDIR}/gfs"
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
IC_date_sec=$( date -d "${YYYY}-${MM}-${DD} ${HH} UTC" "+%s" )
transition_date_sec=$( date -d "2017-07-19 00 UTC" "+%s" )

if [ "$IC_date_sec" -ge "$transition_date_sec" ]; then
  export ictype="opsgfs"
else
  export ictype="oldgfs"
fi


#
#-----------------------------------------------------------------------
#
# Set the name of the shell script that will appear in the run directory
# (RUNDIR) and will contain the definitions of variables needed by the 
# various scripts in the workflow.
#
#-----------------------------------------------------------------------
#
VAR_DEFNS_FILE=$RUNDIR/var_defns.sh
#
#-----------------------------------------------------------------------
#
# Copy the configuration script to the variable definitions script in 
# the run directory.
#
#-----------------------------------------------------------------------
#
cp ./config.sh $VAR_DEFNS_FILE
#
#-----------------------------------------------------------------------
#
# Add a comment at the beginning of VAR_DEFNS_FILE that indicates that
# the first section of that file is identical to the configuration file.
#
#-----------------------------------------------------------------------
#
read -r -d '' str_to_insert << EOM
#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
# Section 1: 
# This section is an exact copy of the configuration file (config.sh) in
# the shell scripts directory (USHDIR).
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
# Insert str_to_insert into VAR_DEFNS_FILE right after the line contain-
# ing the name of the interpreter.
#
REGEXP="(^#!.*)"
sed -i -r -e "s|$REGEXP|\1\n\n$str_to_insert\n|g" $VAR_DEFNS_FILE
#
#-----------------------------------------------------------------------
#
# Add additional variable definitions (and comments) to the end of VAR_-
# DEFNS_FILE.  These variables have been set by the setup script sourced
# above (using the variables in the configuration script).  They are 
# needed by various tasks/scripts in the workflow.
#
#-----------------------------------------------------------------------
#
cat << EOM >> $VAR_DEFNS_FILE
#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
# Section 2: 
# This section defines variables that have been derived from the ones
# above by the setup script (setup.sh).
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
FV3SAR_DIR=\"${FV3SAR_DIR}\"
USHDIR=\"${USHDIR}\"
TEMPLATE_DIR=\"${TEMPLATE_DIR}\"
INIDIR=\"${INIDIR}\"              
RUNDIR=\"${RUNDIR}\"
FIXgsm=\"${FIXgsm}\"
WORKDIR_GRID=\"${WORKDIR_GRID}\"
WORKDIR_OROG=\"${WORKDIR_OROG}\"
WORKDIR_FLTR=\"${WORKDIR_FLTR}\"
WORKDIR_SHVE=\"${WORKDIR_SHVE}\"
WORKDIR_ICBC=\"${WORKDIR_ICBC}\"
#
#-----------------------------------------------------------------------
#
# Grid configuration parameters.
#
#-----------------------------------------------------------------------
#
gtype=\"${gtype}\"
CRES=\"${CRES}\"
halo0=\"${halo0}\"
halo=\"${halo}\"
halop1=\"${halop1}\"
#
#-----------------------------------------------------------------------
#
# Initial date and time and boundary condition times.
#
#-----------------------------------------------------------------------
#
YYYY=\"${YYYY}\"
MM=\"${MM}\"
DD=\"${DD}\"
HH=\"${HH}\"
YMD=\"${YMD}\"
BC_times_hrs=(${BC_times_hrs[@]})  # BC_times_hrs is an array, even if it has only one element.
#
#-----------------------------------------------------------------------
#
# Computational parameters.
#
#-----------------------------------------------------------------------
#
ncores_per_node=\"${ncores_per_node}\"
EOM

