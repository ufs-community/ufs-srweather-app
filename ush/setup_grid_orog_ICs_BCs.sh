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
set -eux
#
#-----------------------------------------------------------------------
#
# Set the machine name.
#
#-----------------------------------------------------------------------
#
#export machine="WCOSS"
#export machine="WCOSS_C"
export machine="THEIA"
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
  echo "Exiting script $0."
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
#export gtype="uniform"     # Grid type: uniform, stretch, nest, or regional
#export gtype="stretch"     # Grid type: uniform, stretch, nest, or regional
#export gtype="nest"        # Grid type: uniform, stretch, nest, or regional
export gtype="regional"    # Grid type: uniform, stretch, nest, or regional
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
  echo "Exiting script $0."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# Set the cubed-sphere grid tile resolution.  This must be one of the
# following:
#
#   48, 96, 192, 384, 768, 1152, 3072
#
#-----------------------------------------------------------------------
#
export RES="96"
#export RES="768"
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
  echo "Exiting script $0."
  exit 1
fi
#
# Set the C-resolution.  This is just a convenience variable containing
# the character "C" followed by the resolution.
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
#export CDATE="2018041000"
#export CDATE="2018051000"
#export CDATE="2018053000"
#export CDATE="2018060100"
export CDATE=$( date --date="yesterday" "+%Y%m%d"00 )
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
export YMD=`echo $CDATE | cut -c 1-8`

if [ "$machine" = "WCOSS_C" ]; then

  export BASE_GSM="/gpfs/hps3/emc/meso/noscrub/${LOGNAME}/fv3gfs"
  export INIDIR="/gpfs/hps/nco/ops/com/gfs/prod/gfs.$YMD"
  export TMPDIR="/gpfs/hps3/ptmp/$LOGNAME/fv3_grid.$gtype"

elif [ "$machine" = "WCOSS" ]; then

# Not sure how these should be set on WCOSS.
  export BASE_GSM=""
  export INIDIR=""
  export TMPDIR=""

elif [ "$machine" = "THEIA" ]; then

  #export BASE_GSM="/scratch3/BMC/fim/$LOGNAME/regional_FV3_EMC_visit_20180509/fv3gfs"
  #export COMROOTp2="/scratch4/NCEPDEV/rstprod/com"   # Does this really need to be exported??
  #export INIDIR="$COMROOTp2/gfs/prod/gfs.$YMD"
  #export TMPDIR="/scratch3/BMC/fim/$LOGNAME/regional_FV3_EMC_visit_20180509/work_dirs"
  
  export BASE_GSM="/scratch3/BMC/det/beck/FV3-CAM/fv3gfs"
  export COMROOTp2="/scratch4/NCEPDEV/rstprod/com"   # Does this really need to be exported??
  export INIDIR="$COMROOTp2/gfs/prod/gfs.$YMD"
  export TMPDIR="/scratch3/BMC/det/beck/FV3-CAM/fv3gfs/work_dirs"

fi
#
#-----------------------------------------------------------------------
#
# Check whether the directory (INIDIR) that's supposed to contain the 
# GFS analysis corresponding to the CDATE specified above actually ex-
# ists on disk.  If not, try to fetch the archived analysis file from 
# mass store (HPSS).  
#
# GFS analysis files are available on disk for 2 weeks on WCOSS and 
# WCOSS_C and for 2 days on THEIA, so they will not be available on disk
# if the specified CDATE is older than these retention periods.  In this
# case, we attempt to retrieve the analysis from mass store (HPSS).
#
#-----------------------------------------------------------------------
#
if [ ! -d "$INIDIR" ]; then

  echo
  echo "The GFS analysis directory (INIDIR) is not available on disk for the specified CDATE:"
  echo "  CDATE = $CDATE"
  echo "  INIDIR = $INIDIR"
  echo "Attempting to retrieve analysis from HPSS (mass storage)..."
#
# Set a new GFS analysis directory.  This is a local directory in which
# archived (tar) analyses obtained from HPSS will be stored and extract-
# ed.
#
  export INIDIR="$BASE_GSM/../gfs/prod/gfs.${YMD}"
#
# Set the directory on mass store (HPSS) in which the tar archive file 
# that we want to fetch is located.
#
  export HPSS_DIR="/NCEPPROD/hpssprod/runhistory/rh$YYYY/${YYYY}${MM}/${YMD}"
#
# Set the name of the tar file we want to fetch.
#
#  export TAR_FILE="gpfs_hps_nco_ops_com_gfs_prod_gfs.${YYYY}${MM}${DD}${HH}.anl.tar"   # Need rstprod group access permission.
  export TAR_FILE="com2_gens_prod_cmce.${YMD}_${HH}.pgrba.tar"   # This is a file for which I have access permission.  Use for testing.
#
# Submit the job that fetches the tar file from HPSS.  This job must be
# submitted to the "service" queue (because access to the HPSS is only 
# available through this queue).
#
#  qsub -v INIDIR,HPSS_DIR,TAR_FILE $BASE_GSM/ush/read_from_HPSS.sh
#
# Submit as an interactive job (using the -I flag along with the -x flag
# to specify the script to run) so that the system waits until the job 
# is complete before moving on with the rest of this script.
#
# Note that the output of the interactive qsub command generates carri-
# age return (or, equivalently, \r or Ctrl-M) characters that clutter 
# the files into which this output is redirected.  In places, there are
# two consecutive carriage returns as well as whitespace followed by two
# carriage returns followed by more whitespace followed by a single car-
# riage return.  To remove or replace these sequences of nuisance carri-
# age returns and/or whitespace, we pipe the output of qsub through sed.  
# The particular sed substitution strings used below are obtained by 
# trial-and-error.
#
  job_name="fetch_GFSanl_from_HPSS"

  qsub \
  -v INIDIR,HPSS_DIR,TAR_FILE \
  -A gsd-fv3 \
  -N $job_name \
  -q service \
  -l nodes=1:ppn=1,walltime=00:30:00 \
  -I \
  -x "$BASE_GSM/ush/fetch_GFSanl_from_HPSS.sh" \
  | sed -r -e 's/\s*\r\r\s+\r/\n/g' -e 's/\w*\r\r/\n/g' -e 's/\r//g' \
  1>out.$job_name 2>err.$job_name 

#  | sed -r 's/\s*\r\r\s+\r/\n/g' | sed -r 's/\w*\r\r/\n/g' | sed -r 's/\r//g' \
#  | sed 's/\r//g' \
#  | sed 's///g' \
#  -o $BASE_GSM/ush/out.$job_name \
#  -e $BASE_GSM/ush/err.$job_name \

#
# Get the PBS job id of the above qsub interactive job from the first 
# line of the file to which stdout was redirected. 
#
  jobid=$( head -1 out.${job_name} | sed -r -n 's/.* ([0-9]+\.[A-Z,a-z,0-9]+) .*/\1/p' )
#
# Rename the files into which the stdout and stderr of the above qsub 
# command were redirected by appending the job id to the ends of the
# file names.
#
  mv out.$job_name out.$job_name.$jobid
  mv err.$job_name err.$job_name.$jobid

fi
#
#-----------------------------------------------------------------------
#
# Set various grid-type (gtype) dependent parameters.
#
#-----------------------------------------------------------------------
#
echo
echo "Setting grid parameters..."
#
#-----------------------------------------------------------------------
#
# Consider gtype set to "uniform".
#
#-----------------------------------------------------------------------
#
if [ "$gtype" = "uniform" ];  then
#
# title is a string that is used in directory names below as a forecast
# identifier.  Here, we set it to "global" to indicate that the grid has
# global coverage.  Other values are possible.
#
  export title="global"          # Identifier based on grid coverage.
#
# Set string that describes the grid resolution and type and the region
# it covers.  This is used in setting directory names.
# 
  export grid_and_domain_str=${CRES}r10n1_uniform_${title}
#
#-----------------------------------------------------------------------
#
# Consider gtype set to "stretch".
#
#-----------------------------------------------------------------------
#
elif [ "$gtype" = "stretch" ]; then
#
# stretch_fac is the factor by which tile 6 of the global cubed-sphere
# grid will be compressed to obtain a new stretched global grid that has
# a higher resolution (i.e. smaller grid size) on tile 6 (relative to 
# tile 6 of the original unstretched global grid).  Note that this im-
# plies that the remaining 5 tiles of the new stretched grid will have
# lower resolution than their counterparts on the original unstretched
# grid. 
#
  export stetch_fac=1.5          # Stretching factor for the grid.
#
# target_lon and target_lat are the longitude and latitude, in degrees,
# of the center of the highest resolution tile of the stretched grid.
# The code is hard-coded so that this is always tile 6.  Change these
# two parameters to move the highest resolution tile over the region of
# interest.
#
  export target_lon=-97.5        # Center longitude of the highest resolution tile.
  export target_lat=35.5         # Center latitude of the highest resolution tile.
#
# title is a string that is used in directory names below as a forecast
# identifier.  One way to set this is to base it on the location of the 
# region of refinement (i.e. tile 6).  For example, this can be set to 
# "CONUS" if tile 6 is located over the continental United States.
#
  export title="CONUS"           # Identifier based on refinement location.
#
# Set string that describes the grid resolution and type and the region
# it covers.  This is used in setting directory names.
# 
  export rn=$( echo "$stetch_fac * 10" | bc | cut -c1-2 )
  export grid_and_domain_str=${CRES}r${rn}_stretched_${title}
#
#-----------------------------------------------------------------------
#
# Consider gtype set to "nest" or "regional".
#
#-----------------------------------------------------------------------
#
elif [ "$gtype" = "nest" ] || [ "$gtype" = "regional" ]; then
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
  export stetch_fac=1.5          # Stretching factor for the grid.
  export target_lon=-97.5        # Center longitude of the highest resolution tile.
  export target_lat=35.5         # Center latitude of the highest resolution tile.
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
  export refine_ratio=3          # Specify the refinement ratio for nest grid.
#
# istart_nest, iend_nest, jstart_nest, and jend_nest are the starting 
# and ending i and j indices of the nest on the parent tile's "super-
# grid", where the parent tile is tile 6 and its supergrid is a grid
# having twice the resolution of the parent tile's grid.
#
  export istart_nest=27          # Specify the starting i-direction index of nest grid in parent tile supergrid (Fortran index).
  export iend_nest=166           # Specify the ending i-direction index of nest grid in parent tile supergrid (Fortran index).
  export jstart_nest=37          # Specify the starting j-direction index of nest grid in parent tile supergrid (Fortran index).
  export jend_nest=164           # Specify the ending j-direction index of nest grid in parent tile supergrid (Fortran index).
#
# Various halo sizes (units are number of cells beyond the boundary of
# the nested or regional grid).
#
  export halo=3                  # Halo size to be used in the atmosphere cubic sphere model for the grid tile.
  export halop1=`expr $halo + 1` # Halo size that will be used for the orography and grid tile in chgres.
  export halo0=0                 # No halo, used to shave the filtered orography for use in the model.
#
# title is a string that is used in directory names below as a forecast
# identifier.  One way to set this is to base it on the location of the 
# nested or regional grid.  For example, this can be set to "CONUS" if 
# the nested or regional grid is located over the continental United 
# States.
#
  export title="CONUS"           # Identifier based on nested or regional grid location.
  export title="BBBBB"           # Identifier based on nested or regional grid location.
#  export title="CCCCC"           # Identifier based on nested or regional grid location.
#  export title="DDDDD"           # Identifier based on nested or regional grid location.
#
# Set string that describes the grid resolution and type and the region
# it covers.  This is used in setting directory names.
# 
  if [ "$gtype" = "nest" ];then
    export rn=$( echo "$stetch_fac * 10" | bc | cut -c1-2 )
    export grid_and_domain_str=${CRES}r${rn}n${refine_ratio}_nested_${title}
  else
    export rn=$( echo "$stetch_fac * 10" | bc | cut -c1-2 )
    export grid_and_domain_str=${CRES}r${rn}n${refine_ratio}_regional_${title}
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
  echo "Exiting script $0."
  exit 1

fi
#
#-----------------------------------------------------------------------
#
# Set out_dir.  This is the directory in which the scripts place their
# output files.  Create this directory if doesn't already exist.
#
#-----------------------------------------------------------------------
#
export out_dir="$BASE_GSM/fix/fix_fv3/$grid_and_domain_str"
mkdir -p $out_dir
#
#-----------------------------------------------------------------------
#
# Set the forecast length (in hours).
#
#-----------------------------------------------------------------------
#
fcst_len_hrs=6
#fcst_len_hrs=9
#fcst_len_hrs=24
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
  echo "Exiting script $0."
  exit 1
fi
#
#-----------------------------------------------------------------------
#
# For a regional grid, set the boundary condition (BC) time interval (in
# hours), i.e. the interval between the times at which the BCs are pro-
# vided.  We refer to these as the BC times.
#
#-----------------------------------------------------------------------
#
if [ "$gtype" = "regional" ]; then

  BC_interval_hrs=3
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
    echo "Exiting script $0."
    exit 1
  fi

fi


