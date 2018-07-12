#!/bin/sh

#
#-----------------------------------------------------------------------
#
# This script sets up parameters needed by the scripts that:
#
# 1) Generate the grid and orography files.
# 2) Generate the initial conditions (ICs) files.
# 3) Generate the lateral boundary conditions (BCs) files (these are 
#    needed only if running a regional grid).
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

. ./config.sh
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
YYYY=$(echo $CDATE | cut -c 1-4 )
MM=$(echo $CDATE | cut -c 5-6 )
DD=$(echo $CDATE | cut -c 7-8 )
HH=$(echo $CDATE | cut -c 9-10 )
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
# INIDIR:
# This is the location of the GFS analysis for the specified CDATE.
#
# TMPDIR:
# This is a temporary work directory.  Scripts may create subdirecto-
# ries under this directory and may or may not delete them after com-
# pleting their tasks.
#
#-----------------------------------------------------------------------
#
export BASE_GSM=${BASE_GSM:-}
export TMPDIR=${TMPDIR:-}

export YMD=`echo $CDATE | cut -c 1-8`

if [ "$machine" = "WCOSS_C" ]; then

#  export BASE_GSM="/gpfs/hps3/emc/meso/noscrub/${LOGNAME}/fv3gfs"
  export INIDIR="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
#  export TMPDIR="/gpfs/hps3/ptmp/$LOGNAME/fv3_grid.$gtype"

elif [ "$machine" = "WCOSS" ]; then

# Not sure how these should be set on WCOSS.
  export INIDIR=""
#  export TMPDIR=""

elif [ "$machine" = "THEIA" ]; then

#  export BASE_GSM="/scratch3/BMC/fim/$LOGNAME/regional_FV3_EMC_visit_20180509/fv3gfs"
  export COMROOTp2="/scratch4/NCEPDEV/rstprod/com"   # Does this really need to be exported??
  export INIDIR="$COMROOTp2/gfs/prod/gfs.$YMD"
#  export TMPDIR="/scratch3/BMC/fim/$LOGNAME/regional_FV3_EMC_visit_20180509/work_dirs"

fi
#
#-----------------------------------------------------------------------
#
# Check whether the directory (INIDIR) that's supposed to contain the 
# GFS analysis corresponding to the CDATE specified above actually ex-
# ists on disk.  GFS analysis files are available on disk for 2 weeks on 
# WCOSS and WCOSS_C and for 2 days on THEIA, so they will not be availa-
# ble on disk if the specified CDATE is older than these retention per-
# iods.  In this case, we will attempt (in another script that sources
# this one) to retrieve the analysis file from mass store (HPSS) and 
# then extract it.  Thus, if INIDIR as set above doesn't exist, reset it
# to a location to which the archived analysis file from HPSS can be co-
# pied and extracted.
#
# Note that the user needs to be a memeber of the rstprod (restricted 
# products) group to be able to access the GFS analysis files on HPSS. 
#
#-----------------------------------------------------------------------
#
#if [ ! -d "$INIDIR" ]; then
#
#  echo
#  echo "The GFS analysis directory (INIDIR) is not available on disk for the specified CDATE:"
#  echo
#  echo "  CDATE = $CDATE"
#  echo "  INIDIR = $INIDIR"
#  echo
#  echo "Will attempt to retrieve the archived analysis file for this CDATE from mass store (HPSS)."
#  echo "Resetting INIDIR to a location to which this archived analysis file can be copied and extracted."
##
## Set a new GFS analysis directory.  This is a local directory into
## which the archived analysis (i.e. .tar) file obtained from HPSS will 
## be copied.  The relevant files from this archive file will be then be
## extracted into this directory, and finally the archive file will be 
## deleted (since it is usually very large).
##
#  export INIDIR="$BASE_GSM/../gfs/prod/gfs.${YMD}"
##
## Set the directory on mass store (HPSS) in which the tarred archive 
## file that we want to fetch is located.
##
#  export HPSS_DIR="/NCEPPROD/hpssprod/runhistory/rh$YYYY/${YYYY}${MM}/${YMD}"
##
## Set the name of the tar file we want to fetch.  Note that the user i
## must to be a member of the rstprod group to be able to "get" this file
## using hsi.
##
#  export TAR_FILE="gpfs_hps_nco_ops_com_gfs_prod_gfs.${YYYY}${MM}${DD}${HH}.anl.tar"
#
#fi


#
#-----------------------------------------------------------------------
#
# Set the names of the nemsio analysis files needed to generate initial
# conditions.
#
#-----------------------------------------------------------------------
#
atmanl_file="gfs.t${HH}z.atmanl.nemsio"
nstanl_file="gfs.t${HH}z.nstanl.nemsio"
sfcanl_file="gfs.t${HH}z.sfcanl.nemsio"
#
#-----------------------------------------------------------------------
#
# Check whether the nemsio analysis files exist in the INIDIR specified
# above.  If not, reset INIDIR to a new location.  
#
#-----------------------------------------------------------------------
#
if [ ! -f "$INIDIR/$atmanl_file" ] || \
   [ ! -f "$INIDIR/$nstanl_file" ] || \
   [ ! -f "$INIDIR/$sfcanl_file" ]; then

  echo
  echo "One or more of the nemsio analysis files needed for initialization do not exist in INIDIR:"
  echo
  echo "  INIDIR = $INIDIR"
  echo "  atmanl_file = $atmanl_file"
  echo "  nstanl_file = $nstanl_file"
  echo "  sfcanl_file = $sfcanl_file"
#
# Set a new GFS analysis directory.  This is a local directory into
# which the archived analysis (i.e. .tar) file obtained from HPSS will 
# be copied.  The relevant files from this archive file will be then be
# extracted into this directory, and finally the archive file will be 
# deleted (since it is usually very large).
#
  export INIDIR="$BASE_GSM/../gfs/prod/gfs.${YMD}"

  echo
  echo "Resetting INIDIR to the following alternate location:"
  echo
  echo "  INIDIR = $INIDIR"

  if [ -f "$INIDIR/$atmanl_file" ] && \
     [ -f "$INIDIR/$nstanl_file" ] && \
     [ -f "$INIDIR/$sfcanl_file" ]; then
    echo
    echo "This location contains the nemsio analysis files needed for initialization."
    echo "Continuing."
#    echo
#    echo "  INIDIR = $INIDIR"
#    echo "  atmanl_file = $atmanl_file"
#    echo "  nstanl_file = $nstanl_file"
#    echo "  sfcanl_file = $sfcanl_file"
  else
    echo
    echo "This location also does not contain the nemsio analysis files needed for initialization."
    echo "The analysis files must first be obtained from HPSS."
#    echo "Exiting script."
#    exit
  fi

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

  BC_times=$( seq 0 $BC_interval_hrs $fcst_len_hrs )

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
  unset stretch_fac target_lon target_lat refine_ratio \
        istart_nest iend_nest jstart_nest jend_nest
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
# For gtype set to "regional", these three parameters apply to an imagi-
# nary or "ghost" parent grid relative to which the regional grid will 
# be constructed.
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
# For gtype set to "nest", stretch_fac, target_lon, and target_lat have
# the same meaning as for gtype set to "stretch", i.e. they are the 
# stretching factor and center longitude and latitude of the highest re-
# solution tile (which is again hard-coded to be tile 6) of the global
# grid that serves as the "parent" of the nested grid.
#
# For gtype set to "regional", these three parameters apply to an imagi-
# nary or "ghost" parent grid relative to which the regional grid will 
# be constructed.
#
  export stretch_fac=${stretch_fac:-1.5}
  export target_lon=${lon_tile6_ctr:--97.5}
  export target_lat=${lat_tile6_ctr:-35.5}
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
  export halop1=`expr $halo + 1` # Halo size that will be used for the orography and grid tile in chgres.
  export halo0=0                 # No halo, used to shave the filtered orography for use in the model.

#  make_RAP_domain="true"
  make_RAP_domain="false"
  if [ "$make_RAP_domain" = "true" ]; then
#    export stretch_fac=0.6
    export stretch_fac=0.7
    export target_lon=-106.0
    export target_lat=54.0
    export refine_ratio=3
#
# In order to determine the starting and ending indices of the regional 
# grid within its parent tile (or PT, which is tile 6), we assume that 
# there is a gap between the boundary of the regional grid and that of
# its parent tile (PT).  We set the width of this gap using the parame-
# ter num_gap_cells_PT.  Note that this is a cell count on the PT grid
# (not on the regional grid).  We must make the gap between the boundary
# of the regional grid and that of its PT large enough (by making num_-
# gap_cells_PT large enough) so that a region of halo cells around the 
# boundary of the regional grid (the halo is added later in another 
# script; its function is to feed in boundary conditions to the regional
# grid) fits into the gap (i.e. does not overrun the boundary of the 
# PT).  
#
# Currently, a halo of 5 regional grid cells is used round the regional
# grid.  Setting num_gap_cells_PT to 10 leaves enough room for this 
# halo.
#
    num_gap_cells_PT=10
    export istart_nest=$(( 2*$num_gap_cells_PT + 1 ))
    export iend_nest=$(( 2*$RES - 2*$num_gap_cells_PT ))
    export jstart_nest=$istart_nest
    export jend_nest=$iend_nest
    export title="RAP"
  fi
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


