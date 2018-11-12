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
# Source the configuration script.
#
#-----------------------------------------------------------------------
#
. ./config.sh
#
#-----------------------------------------------------------------------
#
# Source the shell script containing the function that checks for preex-
# isting directories and handles them according to the setting of the 
# variable preexisting_dir_method (which is specified in the configura-
# tion script config.sh).  This must be done here to define the function
# so that it can be used later below.
#
#-----------------------------------------------------------------------
#
. ./check_for_preexist_dir.sh
#
#-----------------------------------------------------------------------
#
# Source the shell script containing the function that replaces variable
# values (or value placeholders) in several types of files (e.g. Fortran
# namelist files) with actual values.  This must be done here to define
# the function so that it can be used later below.
#
#-----------------------------------------------------------------------
#
. ./set_file_param.sh
# 
#-----------------------------------------------------------------------
#
# Make sure VERBOSE is set to either "true" or "false".
#
#-----------------------------------------------------------------------
#
if [ "$VERBOSE" != "true" ] && [ "$VERBOSE" != "false" ]; then
  echo
  echo "Error.  The verbosity flag VERBOSE must be set to either \
\"trueS\" or \"false\":"
  echo "  VERBOSE = $VERBOSE"
  echo "Exiting script."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Convert machine name to upper case if necessary.  Then make sure that
# MACHINE is set to one of the allowed values.
#
#-----------------------------------------------------------------------
#
MACHINE=$( echo "$MACHINE" | sed -e 's/\(.*\)/\U\1/' )

if [ "$MACHINE" != "WCOSS_C" ] && \
   [ "$MACHINE" != "WCOSS" ] && \
   [ "$MACHINE" != "THEIA" ] && \
   [ "$MACHINE" != "JET" ] && \
   [ "$MACHINE" != "ODIN" ]; then
  echo
  echo "Error.  Machine specified in \"MACHINE\" is not supported:"
  echo "  MACHINE = $MACHINE"
  echo "MACHINE must be set to one of the following:"
  echo "  \"WCOSS_C\""
  echo "  \"WCOSS\""
  echo "  \"THEIA\""
  echo "  \"JET\""
  echo "  \"ODIN\""
  echo "Exiting script."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Set the number of cores per node, the job scheduler, and the names of 
# several queues.  These queues are defined in the configuration script
# (config.sh).
#
#-----------------------------------------------------------------------
#
case $MACHINE in
#
"WCOSS_C")
#
  echo
  echo "ERROR:  Don't know how to set several parameters on MACHINE=\"$MACHINE\"."
  echo "Please specify the correct parameters for this machine in the \
setup script.  Then remove this message and exit call and rerun."
  exit 1
  ncores_per_node=""
  SCHED=""
  QUEUE_DEFAULT=${QUEUE_DEFAULT:-""}
  QUEUE_HPSS=${QUEUE_HPSS:-""}
  QUEUE_RUN_FV3SAR=${QUEUE_RUN_FV3SAR:-""}
  ;;
#
"WCOSS")
#
  echo
  echo "ERROR:  Don't know how to set several parameters on MACHINE=\"$MACHINE\"."
  echo "Please specify the correct parameters for this machine in the \
setup script.  Then remove this message and exit call and rerun."
  exit 1
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
if [ "$predef_domain" != "" ] && \
   [ "$predef_domain" != "RAP" ] && \
   [ "$predef_domain" != "HRRR" ]; then
  echo
  echo "Error.  Predefined regional domain specified in \"predef_domain\" \
is not supported:"
  echo "  predef_domain = $predef_domain"
  echo "predef_domain must be set either to an empty string or to one \
of the following:"
  echo "  \"RAP\""
  echo "  \"HRRR\""
  echo "Exiting script."
  exit 1
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
"RAP")   # The RAP domain.
#
  RES="384"
  ;;
#
"HRRR")  # The HRRR domain.
#
  RES="384"
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
  echo "Error.  Number of grid cells per tile (in each direction) \
specified in \"RES\" is not supported:"
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
CRES="C${RES}"
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the 
# forecast.  These areneeded below for various operations.`
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
FV3SAR_DIR="$BASEDIR/fv3gfs"
USHDIR="$FV3SAR_DIR/ush"
TEMPLATE_DIR="$USHDIR/templates"
UPPFIX="$BASEDIR/fv3gfs/fix"

case $MACHINE in
#
"WCOSS_C")
#
  FIXgsm="/gpfs/hps3/emc/global/noscrub/emc.glopara/svn/fv3gfs/fix/fix_am"
  ;;
#
"WCOSS")
#
  FIXgsm=""  # Don't know what this should be.
  ;;
#
"THEIA")
#
#  FIXgsm="/scratch4/NCEPDEV/global/save/glopara/svn/fv3gfs/fix/fix_am"  # Not sure what the difference is (if any) between the svn and git fix_am directories.
  FIXgsm="/scratch4/NCEPDEV/global/save/glopara/git/fv3gfs/fix/fix_am"
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
# warning and exit this script.  If so, generate an array of forecast
# hours at which the boundary values will be updated.
#
#-----------------------------------------------------------------------
#
rem=$(( $fcst_len_hrs % $BC_update_intvl_hrs ))

if [ "$rem" -ne "0" ]; then
  echo
  echo "Error.  The forecast length is not evenly divisible by the BC update interval:"
  echo "  fcst_len_hrs = $fcst_len_hrs"
  echo "  BC_update_intvl_hrs = $BC_update_intvl_hrs"
  echo "  rem = fcst_len_hrs % BC_update_intvl_hrs = $rem"
  echo "Exiting script."
  exit 1
else
  BC_times_hrs=($( seq 0 $BC_update_intvl_hrs $fcst_len_hrs ))
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
stretch_str="_S$( echo "${stretch_fac}" | sed "s|\.|p|" )"
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
# tory; we will do that later below once the configuration parameters 
# pass the various tests.
#
#-----------------------------------------------------------------------
#
WORKDIR=$TMPDIR/$RUN_SUBDIR
check_for_preexist_dir $WORKDIR $preexisting_dir_method
if [ $? -ne 0 ]; then
  exit 1
fi
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
# the configuration parameters pass the various tests.
#
#-----------------------------------------------------------------------
#
RUNDIR_BASE="${BASEDIR}/run_dirs"
mkdir -p ${RUNDIR_BASE}
RUNDIR="${RUNDIR_BASE}/${RUN_SUBDIR}"
check_for_preexist_dir $RUNDIR $preexisting_dir_method
if [ $? -ne 0 ]; then
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Set the directory INIDIR in which we will store the analysis (at the
# initial time CDATE) and forecast (at the boundary condition times) 
# files.  These are the files that will be used to generate surface
# fields and initial and boundary conditions for the FV3SAR.
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
IC_date_sec=$( date -d "${YYYY}-${MM}-${DD} ${HH} UTC" "+%s" )
transition_date_sec=$( date -d "2017-07-19 00 UTC" "+%s" )

if [ "$IC_date_sec" -ge "$transition_date_sec" ]; then
  ictype="opsgfs"
else
  ictype="oldgfs"
fi











#
#-----------------------------------------------------------------------
#
# Any regional model must be supplied lateral boundary conditions (in 
# addition to initial conditions) to be able to perform a forecast.  In
# FV3SAR model, these boundary conditions (BCs) are supplied using a 
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
set -x

echo
echo "Original values of halo width on tile 6 supergrid and on tile 7:"
echo "  nhw_T6SG = $nhw_T6SG"
echo "  nhw_T7 = $nhw_T7"

nhw_T6SG=$(( $istart_rgnl_T6SG - $istart_rgnl_wide_halo_T6SG ))
nhw_T6=$(( $nhw_T6SG/2 ))
nhw_T7=$(( $nhw_T6*$refine_ratio ))

echo "Values of halo width on tile 6 supergrid and on tile 7 AFTER adjustments:"
echo "  nhw_T6SG = $nhw_T6SG"
echo "  nhw_T7 = $nhw_T7"

set +x
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
set +x

nx_T6SG=$(( $iend_rgnl_T6SG - $istart_rgnl_T6SG + 1 ))
nx_T6=$(( $nx_T6SG/2 ))
nx_T7=$(( $nx_T6*$refine_ratio ))

ny_T6SG=$(( $jend_rgnl_T6SG - $jstart_rgnl_T6SG + 1 ))
ny_T6=$(( $ny_T6SG/2 ))
ny_T7=$(( $ny_T6*$refine_ratio ))

echo
#
echo "nx_T7 = $nx_T7 \
(istart_rgnl_T6SG = $istart_rgnl_T6SG, \
iend_rgnl_T6SG = $iend_rgnl_T6SG)"
#
echo "ny_T7 = $ny_T7 \
(jstart_rgnl_T6SG = $jstart_rgnl_T6SG, \
jend_rgnl_T6SG = $jend_rgnl_T6SG)"

set +x
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
set -x

nx_wide_halo_T6SG=$(( $iend_rgnl_wide_halo_T6SG - $istart_rgnl_wide_halo_T6SG + 1 ))
nx_wide_halo_T6=$(( $nx_wide_halo_T6SG/2 ))
nx_wide_halo_T7=$(( $nx_wide_halo_T6*$refine_ratio ))

ny_wide_halo_T6SG=$(( $jend_rgnl_wide_halo_T6SG - $jstart_rgnl_wide_halo_T6SG + 1 ))
ny_wide_halo_T6=$(( $ny_wide_halo_T6SG/2 ))
ny_wide_halo_T7=$(( $ny_wide_halo_T6*$refine_ratio ))

echo
#
echo "nx_wide_halo_T7 = $nx_T7 \
(istart_rgnl_wide_halo_T6SG = $istart_rgnl_wide_halo_T6SG, \
iend_rgnl_wide_halo_T6SG = $iend_rgnl_wide_halo_T6SG)"
#
echo "ny_wide_halo_T7 = $ny_T7 \
(jstart_rgnl_wide_halo_T6SG = $jstart_rgnl_wide_halo_T6SG, \
jend_rgnl_wide_halo_T6SG = $jend_rgnl_wide_halo_T6SG)"

set -x







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

if [ $VERBOSE ]; then
  echo
  echo "The number of MPI tasks for the forecast (including those for \
the write component if it is being used) are:"
  echo "  PE_MEMBER01 = $PE_MEMBER01"
fi
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
   echo
   echo "The number of grid cells in the x direction (nx_T7) is not evenly \
divisible by the number of MPI tasks in the x direction (layout_x):"
   echo "  nx_T7 = $nx_T7"
   echo "  layout_x = $layout_x"
   echo "Exiting script."
   exit 1
fi

rem=$(( $ny_T7%$layout_y ))
if [ $rem -ne 0 ]; then 
   echo
   echo "The number of grid cells in the x direction (ny_T7) is not evenly \
divisible by the number of MPI tasks in the x direction (layout_y):"
   echo "  ny_T7 = $ny_T7"
   echo "  layout_y = $layout_y"
   echo "Exiting script."
   exit 1
fi
 
if [ $VERBOSE ]; then
  echo
  echo "The MPI task layout is as follows:"
  echo "  layout_x = $layout_x"
  echo "  layout_y = $layout_y"
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
  echo
  echo "The write-component template file does not exist:"
  echo "  WRTCMP_PARAMS_TEMPLATE_FP = $WRTCMP_PARAMS_TEMPLATE_FP"
  echo "Exiting script."
  exit 1
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
    echo
    echo "The number of grid points in the y direction on the regional \
grid (ny_T7) must be evenly divisible by the number of tasks per write \
group (write_tasks_per_group):"
    echo "  ny_T7 = $ny_T7"
    echo "  write_tasks_per_group = $write_tasks_per_group"
    echo "  ny_T7%write_tasks_per_group = $rem"
    echo "Exiting script."
    exit 1
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
mkdir $WORKDIR
mkdir -p $RUNDIR
mkdir $RUNDIR/INPUT
mkdir $RUNDIR/RESTART




#
#-----------------------------------------------------------------------
#
# Generate the shell script that will appear in the run directory (RUN-
# DIR) and will contain definitions of variables needed by the various 
# scripts in the workflow.  We refer to this as the variable definitions
# file.  We will create this file by first copying the configuration 
# script config.sh in the shell script directory (USHDIR) to the run di-
# rectory (and renaming it to the value in SCRIPT_VAR_DEFNS_FP), then 
# resetting the original values in this variable definitions file (that
# were inherited from config.sh) of those variables that were modified
# in this setup script to their new values, and finally appending to the
# variable definitions file any new variables introduced in this setup
# script that may be needed by the scripts that perform the various 
# tasks in the workflow (and which source the variable defintions file).
#
# First, set the full path to the variable definitions file and copy the
# configuration file into it.
#
#-----------------------------------------------------------------------
#
SCRIPT_VAR_DEFNS_FP="$RUNDIR/$SCRIPT_VAR_DEFNS_FN"
cp ./config.sh $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Add a comment at the beginning of the variable definitions script that
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
# This section is a copy of the configuration file (config.sh) in the 
# shell scripts directory (USHDIR) execpt that any parameters in that 
# file that were modified by the setup script (setup.sh) are assigned 
# the updated values in this file.  [This can happen, for example, if 
# the variable predef_domain in config.sh has been set to a valid non-
# empty string, in which case the run title (run_title), the grid para-
# meters, and possibly the name of the write-component parameter file 
# (WRTCMP_PARAMS_TEMPLATE_FN) will be modified in setup.sh.]
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
# If predef_domain is set to a valid non-empty string, then the values 
# of run_title, the grid parameters, and possibly WRTCMP_PARAMS_TEMP-
# LATE_FN specified in the configuration file would have been updated 
# above.  In this case, replace the values of these parameters in the 
# variable defintions file (that were inherited from the configuration
# file) with the updated values.
#
#-----------------------------------------------------------------------
#
if [ -n "${predef_domain}" ]; then

  if [ "$VERBOSE" = "true" ]; then
    echo
    echo "Updating run_title, the grid parameters, and WRTCMP_PARAMS_TEMPLATE_FN \
in the variable definitions file SCRIPT_VAR_DEFNS_FP to that of the predefined \
domain:"
    echo "  SCRIPT_VAR_DEFNS_FP = $SCRIPT_VAR_DEFNS_FP"
    echo "  predef_domain = $predef_domain"
  fi

  set_file_param $SCRIPT_VAR_DEFNS_FP "run_title" $run_title $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "RES" $RES $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "lon_ctr_T6" $lon_ctr_T6 $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "lat_ctr_T6" $lat_ctr_T6 $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "stretch_fac" $stretch_fac $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "istart_rgnl_T6" $istart_rgnl_T6 $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "jstart_rgnl_T6" $jstart_rgnl_T6 $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "iend_rgnl_T6" $iend_rgnl_T6 $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "jend_rgnl_T6" $jend_rgnl_T6 $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "refine_ratio" $refine_ratio $VERBOSE
  set_file_param $SCRIPT_VAR_DEFNS_FP "WRTCMP_PARAMS_TEMPLATE_FN" $WRTCMP_PARAMS_TEMPLATE_FN $VERBOSE

fi
#
#-----------------------------------------------------------------------
#
# Append additional variable definitions (and comments) to the variable
# definitions file.  These variables have been set above using the vari-
# ables in the configuration script.  They are needed by various tasks/
# scripts in the workflow.
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
TEMPLATE_DIR="$TEMPLATE_DIR"
INIDIR="$INIDIR"              
RUNDIR="$RUNDIR"
FIXgsm="$FIXgsm"
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
# Grid configuration parameters (these are in addition to the basic ones
# defined above).
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
# Initial date and time and boundary condition times.
#
#-----------------------------------------------------------------------
#
YYYY="$YYYY"
MM="$MM"
DD="$DD"
HH="$HH"
YMD="$YMD"
BC_times_hrs=(${BC_times_hrs[@]})  # BC_times_hrs is an array, even if it has only one element.
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


