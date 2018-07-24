#!/bin/sh

#
# Machine and queue paramters.
#
machine="THEIA"       # Machine on which we are running.  Must be "WCOSS", "WCOSS_C", or "THEIA"
ACCOUNT="gsd-fv3"     # The account under which to submit jobs to the queue.
#
# Directories.
#
BASE_GSM="/scratch3/BMC/fim/$LOGNAME/regional_FV3_EMC_visit_20180509/fv3gfs"  # Directory in which clone of fv3gfs git repository is located.
TMPDIR="/scratch3/BMC/fim/$LOGNAME/regional_FV3_EMC_visit_20180509/work_dirs" # Temporary work directory.
#
# Forecast parameters.
#
CDATE="2018060400"    # Starting date of forecast.  Format is "YYYYMMDDHH".
#CDATE="2018071000"    # Starting date of forecast.  Format is "YYYYMMDDHH".
#CDATE=$( date "+%Y%m%d"00 )  # This sets CDATE to today.
#CDATE=$( date --date="yesterday" "+%Y%m%d"00 )  # This sets CDATE to yesterday.
fcst_len_hrs=6        # Forecast length (in hours).
#BC_interval_hrs=3     # Boundary condition time interval (in hours).
BC_interval_hrs=6     # Boundary condition time interval (in hours).
#
# Grid configuration.
#
#gtype="uniform"       # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
#gtype="stretch"       # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
#gtype="nest"          # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
gtype="regional"      # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
RES="384"             # Number of points in each direction of each tile of global grid.  Must be "48", "96", "192", "384", "768", "1152", or "3072"
stretch_fac=1.5       # Stretching factor used in the Schmidt transformation (stretching of cubed sphere grid).
lon_tile6_ctr=-97.5   # Longitude of center of tile 6 (in degrees).
lat_tile6_ctr=35.5    # Latitude of center of tile 6 (in degrees).
refine_ratio=3        # Refinement ratio for nested or regional grid.
istart_nest_tile6=10  # i-index on tile 6 at which nested or regional grid starts.
iend_nest_tile6=374   # i-index on tile 6 at which nested or regional grid ends.
jstart_nest_tile6=10  # j-index on tile 6 at which nested or regional grid starts.
jend_nest_tile6=374   # j-index on tile 6 at which nested or regional grid ends.
title="test_preproc"              # Descriptive string for the forecast.  Used in forming the name of the preprocessing output directory.
#
# Predefined regional domains.  If this is set to a valid non-empty 
# string and if gtype is set to "regional", then the values set above
# for the grid configuration parameters above (except for gtype) are 
# overwritted by predefined values.
#
# Valid values of predef_rgnl_domain currently consist of:
#
# "RAP"  "HRRR"
#
predef_rgnl_domain=""      # No predefined regional domain.
#predef_rgnl_domain="RAP"   # Set grid configuration to that of the RAP domain.
#predef_rgnl_domain="HRRR"  # Set grid configuration to that of the HRRR domain.

