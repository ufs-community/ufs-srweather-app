#!/bin/sh

#
#-----------------------------------------------------------------------
#
# This script sets up parameters needed by the scripts that:
#
# 1) Generate the grid and orography files.
# 2) Generate the initial condition (IC) file.
# 3) Generate the lateral boundary condition (BC) files (these are need-
#    ed only if running a regional grid).
#
# These parameters are the ones most commonly modified by users.  They
# are grouped into this script for convenience.  These parameters only 
# need to be modified here because the above three scripts source this 
# script at the start of their execution.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Change shell behavior with "set" with these flags:
#
# -e 
# This will cause the script to exit as soon as any line in the script 
# fails (with some exceptions; see manual).
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

if [ -v ${BASEDIR} ]; then

. ${BASEDIR}/fv3gfs/ush/config.sh

else

. ./config.sh

fi

#
#-----------------------------------------------------------------------
#
# Set the machine name.
#
#-----------------------------------------------------------------------
#
export machine=${machine:-}
#
# Convert machine name to lower case if necessary.
#
#machine=$( echo "$machine" | sed -e 's/\(.*\)/\L\1/' )  # <-- Don't do this yet, maybe later; requires changing this and other scripts to use lowercase everywhere.
# 
# Make sure machine is set to one of the allowed values.
#
if [ "$machine" != "WCOSS_C" ] && \
   [ "$machine" != "WCOSS" ] && \
   [ "$machine" != "THEIA" ]; then
  echo
  echo "Error.  Machine specified in \"machine\" is not supported:"
  echo "  machine = $machine"
  echo "machine must be one of:  \"WCOSS_C\"  \"WCOSS\"  \"THEIA\""
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
# Set the cubed-sphere grid type (gtype).  This can be one of "uniform", 
# "stretch", "nest", and "regional".
#
#-----------------------------------------------------------------------
#
export gtype=${gtype:-}
# 
# Make sure gtype is set to one of the allowed values.
#
if [ "$gtype" != "uniform" ] && \
   [ "$gtype" != "stretch" ] && \
   [ "$gtype" != "nest" ] && \
   [ "$gtype" != "regional" ]; then
  echo
  echo "Error.  Grid type specified in \"gtype\" is not supported:"
  echo "  gtype = $gtype"
  echo "gtype must be one of:  \"uniform\"  \"stretch\"  \"nest\"  \"regional\""
  echo "Exiting script."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Set the cubed-sphere grid tile resolution for tiles 1 through 6.  This
# must be one of "48", "96", "192", "384", "768", "1152", or "3072".
#
# Note that for a nested or regional grid (gtype set to "nest" or "re-
# gional"), the resolution of the nested or regional grid is determined
# not only by this number but also the refinement ratio (refine_ratio).
#
#-----------------------------------------------------------------------
#
export RES=${RES:-}

#
# RES may have to be reset if the domain is regional and a predefined
# regional domain is specified (e.g. the RAP or HRRR domain).
#
if [ "$gtype" = "regional" ]; then
#
# Set the variable predef_rgnl_domain that defines a predefined regional
# domain/grid.  If this is not set, set it to an empty string, which re-
# sults in no predefined regional domain.
#
  predef_rgnl_domain=${predef_rgnl_domain:-""}
#
# Possibly reset RES depending on the value of predef_rgnl_domain.
#
  case $predef_rgnl_domain in
# No predined regional domain - do nothing.
  "")
    ;;
# The RAP domain.
  "RAP")
    export RES="384"
    ;;
# The HRRR domain.
  "HRRR")
    export RES="384"
    ;;
# Unknown value of predef_rgnl_domain.
  *)
    echo
    echo "Error.  Predefined regional domain specified in \"predef_rgnl_domain\" is not supported:"
    echo "  predef_rgnl_domain = $predef_rgnl_domain"
    echo "predef_rgnl_domain must be one of:  \"RAP\"  \"HRRR\""
    echo "Exiting script."
    exit 1
    ;;
  esac

fi
# 
# Make sure RES is set to one of the allowed values.
#
if [ "$RES" != "48" ] && \
   [ "$RES" != "96" ] && \
   [ "$RES" != "192" ] && \
   [ "$RES" != "384" ] && \
   [ "$RES" != "768" ] && \
   [ "$RES" != "1152" ] && \
   [ "$RES" != "3072" ]; then
  echo
  echo "Error.  Grid resolution specified in \"RES\" is not supported:"
  echo "  RES = $RES"
  echo "RES must be one of:  48  96  192  384  768  1152  3072"
  echo "Exiting script."
  exit 1
fi
#
# Set the C-resolution.  This is just a convenience variable containing
# the character "C" followed by the tile resolution.
#
export CRES="C${RES}"
#
#-----------------------------------------------------------------------
#
# Set the date and hour-of-day at which initial conditions will be ob-
# tained.  The format of CDATE is YYYYMMDDHH.
#
#-----------------------------------------------------------------------
#
export CDATE=${CDATE:-}
#
# Extract from CDATE the starting year, month, day, and hour.  These are
# needed below for various operations.`
#
YYYY=${CDATE:0:4}
MM=${CDATE:4:2}
DD=${CDATE:6:2}
HH=${CDATE:8:2}

export YMD=${CDATE:0:8}
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
# Set various directories.  These are:
#
# BASE_GSM:
# This is the base directory for the "superstructure" fv3gfs code.
#
# TMPDIR:
# This is a temporary work directory.  Scripts may create subdirecto-
# ries under this directory and may or may not delete them after com-
# pleting their tasks.
#
#-----------------------------------------------------------------------
#
export BASEDIR=${BASEDIR:-}
export TMPDIR=${TMPDIR:-}
export BASE_GSM="$BASEDIR/fv3gfs"

if [ "$machine" = "WCOSS_C" ]; then
  export FIXgsm="/gpfs/hps3/emc/global/noscrub/emc.glopara/svn/fv3gfs/fix/fix_am"
elif [ "$machine" = "WCOSS" ]; then
  export FIXgsm=""
elif [ "$machine" = "THEIA" ]; then
  export FIXgsm="/scratch4/NCEPDEV/global/save/glopara/svn/fv3gfs/fix/fix_am"
fi
#
#-----------------------------------------------------------------------
#
# Set the forecast length (in hours).
#
#-----------------------------------------------------------------------
#
fcst_len_hrs=${fcst_len_hrs:-}
#
# The forecast length (in hours) cannot contain more than 3 characters.
# Thus, its maximum value is 999.  Check whether the specified forecast
# length exceeds this maximum value.
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
# For a regional grid, set the boundary condition (BC) time interval (in
# hours), i.e. the interval between the times at which the BCs are pro-
# vided.  We refer to these as the BC times.  Then create an integer ar-
# ray containing these times.  
#
#-----------------------------------------------------------------------
#
if [ "$gtype" = "regional" ]; then

  BC_interval_hrs=${BC_interval_hrs:-}
#
# Check whether the forecast length (fcst_len_hrs) is evenly divisible 
# by the BC time interval.  If not, exit script.
#
  remainder=$(( $fcst_len_hrs % $BC_interval_hrs ))

  if [ "$remainder" != "0" ]; then
    echo
    echo "Error.  The forecast length is not evenly divisible by the BC time interval:"
    echo "  fcst_len_hrs = $fcst_len_hrs"
    echo "  BC_interval_hrs = $BC_interval_hrs"
    echo "  remainder = fcst_len_hrs % BC_interval_hrs = $remainder"
    echo "Exiting script."
    exit 1
  fi

  BC_times_hrs=($( seq 0 $BC_interval_hrs $fcst_len_hrs ))

fi
#
#-----------------------------------------------------------------------
#
# Set various grid-type (gtype) dependent parameters.
#
# title:
# This is a descriptive string used in directory names as a forecast 
# identifier.
#
# coverage_str:
# Describes the coverage of the grid.  This is "glob" for a global grid
# and "rgnl" for a regional grid.
#
# nest_str:
# Specifies whether or not the outer grid has embedded within it a nest-
# ed grid.  This is "nest" for a global grid having a nest and empty for
# a regional grid (since, at least for now, a regional grid can't have a
# nest).
# 
# stretch_str:
# This specifies whether or not the global grid is stretched.  This is 
# empty if there is no stretching of the global grid (i.e. if stretch_-
# fac is assumed to be 1) and "strch" otherwise.  Note that for gtype=
# "regional", the global grid is a "ghost" grid in that it is only used
# for grid generation (i.e. the model isn't integrated on the global 
# grid).  Nevertheless, it may still be stretched, so stretch_str is 
# still set to "strch" in this case.
#
# refine_str:
# Specifies whether or not the outer grid has embedded within it a nest-
# ed grid.  This is "nest" for a global grid having a nest and empty for
# a regional grid (since, at least for now, a regional grid can't have a
# nest).
#
#-----------------------------------------------------------------------
#
echo
echo "Setting grid parameters..."

title=${title:-}


#
#-----------------------------------------------------------------------
#
# Consider gtype set to "uniform".
#
#-----------------------------------------------------------------------
#
if [ "$gtype" = "uniform" ];  then
#
  coverage_str="glob"
  nest_str=""
  stretch_str=""
  refine_str=""
#
# Unset variables that will not be used for gtype="uniform".
#
#  unset stretch_fac target_lon target_lat refine_ratio \
#        istart_nest iend_nest jstart_nest jend_nest
#
#-----------------------------------------------------------------------
#
# Consider gtype set to "stretch".
#
#-----------------------------------------------------------------------
#
elif [ "$gtype" = "stretch" ]; then
#
  coverage_str="glob"
  nest_str=""
  stretch_str="strch"
  refine_str=""
#
# stretch_fac is the factor by which tile 6 of the global cubed-sphere
# grid will be compressed to obtain a new stretched global grid that has
# a higher resolution (i.e. smaller grid size) on tile 6 (relative to 
# tile 6 of the original unstretched global grid).  Note that this im-
# plies that the remaining 5 tiles of the new stretched grid will have
# lower resolution than their counterparts on the original unstretched
# grid. 
#
  export stretch_fac=${stretch_fac:-1.5}
#
# target_lon and target_lat are the longitude and latitude, in degrees,
# of the center of the highest resolution tile of the stretched grid.
# The code is hard-coded so that this is always tile 6.  Change these
# two parameters to move the highest resolution tile over the region of
# interest.
#
  export target_lon=${lon_tile6_ctr:--97.5}
  export target_lat=${lat_tile6_ctr:-35.5}
#
#-----------------------------------------------------------------------
#
# Consider gtype set to "nest".
#
#-----------------------------------------------------------------------
#
elif [ "$gtype" = "nest" ]; then
#
  coverage_str="glob"
  nest_str="nest"
  stretch_str="strch"
  refine_str="rfn"
#
# For gtype set to "nest", stretch_fac, target_lon, and target_lat have
# the same meaning as for gtype set to "stretch", i.e. they are the 
# stretching factor and center longitude and latitude of the highest re-
# solution tile (which is again hard-coded to be tile 6) of the global
# grid that serves as the "parent" of the nested grid.
#
  export stretch_fac=${stretch_fac:-1.5}
  export target_lon=${lon_tile6_ctr:--97.5}
  export target_lat=${lat_tile6_ctr:-35.5}
#
# refine_ratio is the ratio of the number of grid points in the nested
# grid to the number of grid points on the parent tile along the bound-
# ary of the two grids (where the boundary consists of four segments - 
# the lower, right, upper, and left edges of the nest region).  Thus, 
# setting refine_ratio = 3 means that each cell of the parent tile is 
# met by 3 cells of the nested grid.  Note also that if the grid size on
# the parent tile is delx, then the grid size on the nested grid will be
# delx/refine_ratio.
#
  export refine_ratio=${refine_ratio:-3}
#
# Set
#
  istart_nest_tile6=${istart_nest_tile6:-14}
  iend_nest_tile6=${iend_nest_tile6:-83}
  jstart_nest_tile6=${jstart_nest_tile6:-19}
  jend_nest_tile6=${jend_nest_tile6:-82}
#
# istart_nest, iend_nest, jstart_nest, and jend_nest are the starting 
# and ending i and j indices of the nest on the parent tile's "super-
# grid", where the parent tile is tile 6 and its supergrid is a grid
# having twice the resolution of the parent tile's grid.
#
  export istart_nest=$(( 2*$istart_nest_tile6 - 1 ))
  export iend_nest=$(( 2*$iend_nest_tile6 ))
  export jstart_nest=$(( 2*$jstart_nest_tile6 - 1 ))
  export jend_nest=$(( 2*$jend_nest_tile6 ))
#
# Various halo sizes (units are number of cells beyond the boundary of
# the nested or regional grid).
#
  export halo=3                  # Halo size to be used in the atmosphere cubic sphere model for the grid tile.
#
#-----------------------------------------------------------------------
#
# Consider gtype set to "regional".
#
#-----------------------------------------------------------------------
#
elif [ "$gtype" = "regional" ]; then
#
  coverage_str="rgnl"
  nest_str=""
  stretch_str="strch"
  refine_str="rfn"
#
#-----------------------------------------------------------------------
#
# Check if a predefined regional domain is set and proceed accordingly.
#
#-----------------------------------------------------------------------
# 
  case $predef_rgnl_domain in
#
#-----------------------------------------------------------------------
#
# Consider case of no predefined regional domain.
#
#-----------------------------------------------------------------------
#
  "")
#
# For gtype set to "regional", stretch_fac, target_lon, and target_lat 
# have the same meaning as for gtype set to "stretch", i.e. they are the 
# stretching factor and center longitude and latitude of the highest re-
# solution tile (which is again hard-coded to be tile 6) of the global 
# grid that serves as the "parent" of the regional grid, except that 
# this parent grid is an imaginary or "ghost" grid in the sense that the
# governing equations are not integrated on it (they are integrated only
# on the regional grid).  Thus, the parent grid is only used as a refer-
# ence grid with respect to which to construct the regional grid.  The 
# preprocessing will generate grid files for the 6 tiles of this parent
# grid (as well as for the regional grid, i.e. tile 7), but those 6 grid
# files will not be used as input to the FV3 model.
#
    export stretch_fac=${stretch_fac:-1.5}
    export target_lon=${lon_tile6_ctr:--97.5}
    export target_lat=${lat_tile6_ctr:-35.5}
#
# refine_ratio is the ratio of the number of grid cells in the regional
# grid for each grid cell on the PT's grid along the boundary of the re-
# gional grid (which consists of the lower, right, upper, and left edges
# of the regional domain).  Thus, setting refine_ratio = 3 means that 
# each cell on the PT's grid is met by 3 cells on the regional grid.  
# Note also that if the grid size on the parent tile is delx, then the
# grid size on the regional grid will be delx/refine_ratio.
#
    export refine_ratio=${refine_ratio:-3}
    export refine_ratio=${refine_ratio:-3}
#
# Starting and ending indices of regional domain on tile 6.
#
    istart_nest_tile6=${istart_nest_tile6:-14}
    iend_nest_tile6=${iend_nest_tile6:-83}
    jstart_nest_tile6=${jstart_nest_tile6:-19}
    jend_nest_tile6=${jend_nest_tile6:-82}
    ;;
#
#-----------------------------------------------------------------------
#
# Consider valid predefined regional domains.
#
# For the predefined domains, we determine the starting and ending indi-
# ces of the regional grid within its parent tile (or PT, which is tile 
# 6) by specifying the number of cells (as counted on tile 6) between 
# the boundary of tile 6 and that of the regional grid (tile 7) along 
# the left, right, bottom, and top portions of these boundaries.  (Note
# that we do not use "west", "east", "north", and "south" here because 
# the tiles aren't necessarily oriented such that the left boundary seg-
# ment corresponds to the west edge, etc.)  We refer to this region of
# cells between the tile 6 and tile 7 boundaries as the gap.  The width
# of this gap along the left, right, bottom, and top portions of the 
# boundaries are specified via the parameters
#
#   num_gap_cells_tile6_left
#   num_gap_cells_tile6_right
#   num_gap_cells_tile6_bottom
#   num_gap_cells_tile6_top
#
# where the "_tile6" in these names is used to indicate that the cell
# count is on tile 6 (not tile 7).
#
# Note that we must make the gap wide enough (by making the above four
# parameters large enough) such that a region of halo cells around the 
# boundary of the regional grid fits into the gap, i.e. such that the 
# halo does not overrun the boundary of tile 6.  (The halo is added la-
# ter in another script; its function is to feed in boundary conditions
# to the regional grid.)  Currently, a halo of 5 regional grid cells is 
# used round the regional grid.  Setting num_gap_cells_tile6_... to at
# least 10 leaves enough room for this halo.
#
#-----------------------------------------------------------------------
#

#
# The RAP domain.
#
  "RAP")

    export title="RAP"

#    export stretch_fac=0.7
    export stretch_fac=0.63
    export target_lon=-106.0
    export target_lat=54.0
    export refine_ratio=3
#    export refine_ratio=4

    num_gap_cells_tile6_left=10
    istart_nest_tile6=$num_gap_cells_tile6_left

    num_gap_cells_tile6_right=10
    iend_nest_tile6=$(( $RES - $num_gap_cells_tile6_right ))

    num_gap_cells_tile6_bottom=10
    jstart_nest_tile6=$num_gap_cells_tile6_bottom

    num_gap_cells_tile6_top=10
    jend_nest_tile6=$(( $RES - $num_gap_cells_tile6_top ))
    ;;
#
# The HRRR domain.
#
  "HRRR")

    export title="HRRR"

#    export stretch_fac=1.8
    export stretch_fac=1.65
    export target_lon=-97.5
    export target_lat=38.5
    export refine_ratio=5

    num_gap_cells_tile6_left=12
    istart_nest_tile6=$num_gap_cells_tile6_left

    num_gap_cells_tile6_right=12
    iend_nest_tile6=$(( $RES - $num_gap_cells_tile6_right ))

    num_gap_cells_tile6_bottom=80
    jstart_nest_tile6=$num_gap_cells_tile6_bottom

    num_gap_cells_tile6_top=80
    jend_nest_tile6=$(( $RES - $num_gap_cells_tile6_top ))
    ;;

  esac
#
# istart_nest, iend_nest, jstart_nest, and jend_nest are the starting 
# and ending i and j indices of the nest on the parent tile's "super-
# grid", where the parent tile is tile 6 and its supergrid is a grid
# having twice the resolution of the parent tile's grid.
#
  export istart_nest=$(( 2*$istart_nest_tile6 - 1 ))
  export iend_nest=$(( 2*$iend_nest_tile6 ))
  export jstart_nest=$(( 2*$jstart_nest_tile6 - 1 ))
  export jend_nest=$(( 2*$jend_nest_tile6 ))
#
# Various halo sizes (units are number of cells beyond the boundary of
# the nested or regional grid).
#
  export halo=3                  # Halo size to be used in the atmosphere cubic sphere model for the grid tile.
  export halop1=`expr $halo + 1` # Halo size that will be used for the orography and grid tile in chgres.
  export halo0=0                 # No halo, used to shave the filtered orography for use in the model.
#
#-----------------------------------------------------------------------
#
# Disallowed value specified for gtype.
#
#-----------------------------------------------------------------------
#
else

  echo
  echo "Error.  Grid type specified in \"gtype\" is not supported:"
  echo "  gtype = $gtype"
  echo "gtype must be one of:  \"uniform\"  \"stretch\"  \"nest\"  \"regional\""
  echo "Exiting script."
  exit 1

fi
#
#-----------------------------------------------------------------------
#
# Create strings that will be used to form a subdirectory name for the 
# current grid configuration.  Two subdirectories having this name will
# be created; one will be a temporary work directory (created in the 
# specified temporary directory TMPDIR), while the other will be the 
# output directory for the preprocessing scripts (created in $BASE_GSM/
# fix/fix_fv3).
#
#-----------------------------------------------------------------------
#
# If nest_str is set to a non-empty value (i.e. it is neither null nor
# unset), prepend an underscore to it.  Otherwise, set it to null.
#
nest_str=${nest_str:+_${nest_str}}
#
# If stretch_str is set to a non-empty value (i.e. it is neither null 
# nor unset), prepend an underscore to it and append to it the value of 
# stretch_fac (with any decimal points replaced with "p"s).  Otherwise,
# set it to null.
#
stretch_str=${stretch_str:+_${stretch_str}_$( echo "${stretch_fac}" | sed "s|\.|p|" )}
#
# If refine_str is set to a non-empty value (i.e. it is neither null nor
# unset), prepend an underscore to it and append to it an underscore 
# followed by the value of refine_ratio.  Otherwise, set it to null.
#
refine_str=${refine_str:+_${refine_str}_${refine_ratio}}
#
# If title is set to a non-empty value (i.e. it is neither null nor un-
# set), prepend an underscore to it.  Otherwise, set it to null.
#
title=${title:+_${title}}
#
# Construct a subdirectory name for the current grid configuration.
#
export subdir_name=${coverage_str}${nest_str}_${CRES}${stretch_str}${refine_str}${title}
#
#-----------------------------------------------------------------------
#
# Set out_dir.  This is the directory in which the preprocessing scripts
# place their output files.  Create this directory if doesn't already 
# exist.
#
#-----------------------------------------------------------------------
#
export out_dir="$BASE_GSM/fix/fix_fv3/$subdir_name"
mkdir -p $out_dir
#
#-----------------------------------------------------------------------
#
# Set the directory (INIDIR) in which we will store the analysis (at the
# initial time CDATE) and forecasts (at the boundary condition times) 
# files.
#
#-----------------------------------------------------------------------
#
export INIDIR="${TMPDIR}/$subdir_name/gfs"
mkdir -p $INIDIR



