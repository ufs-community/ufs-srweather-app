#!/bin/sh


machine="THEIA"       # Machine on which we are running.  Must be "WCOSS", "WCOSS_C", or "THEIA"
#gtype="uniform"       # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
#gtype="stretch"       # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
#gtype="nest"          # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
gtype="regional"      # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
RES="384"             # Number of points in each direction of each tile of global grid.  Must be "48", "96", "192", "384", "768", "1152", or "3072"
CDATE="2018060300"    # Starting date of forecast.  Format is "YYYYMMDDHH".
#CDATE="2018071000"    # Starting date of forecast.  Format is "YYYYMMDDHH".
#CDATE=$( date "+%Y%m%d"00 )  # This sets CDATE to today.
#CDATE=$( date --date="yesterday" "+%Y%m%d"00 )  # This sets CDATE to yesterday.
BASE_GSM="/scratch3/BMC/fim/$LOGNAME/regional_FV3_EMC_visit_20180509/fv3gfs"  # Directory in which clone of fv3gfs git repository is located.
TMPDIR="/scratch3/BMC/fim/$LOGNAME/regional_FV3_EMC_visit_20180509/work_dirs" # Temporary work directory.
fcst_len_hrs=6        # Forecast length (in hours).
BC_interval_hrs=3     # Boundary condition time interval (in hours).
title=""              # Descriptive string for the forecast.  Used in forming output directory name.
stretch_fac=0.7       # Stretching factor used in the Schmidt transformation (stretching of cubed sphere grid).
lon_tile6_ctr=-106.0  # Longitude of center of tile 6 (in degrees).
lat_tile6_ctr=54.0    # Latitude of center of tile 6 (in degrees).
refine_ratio=3        # Refinement ratio for nested or regional grid.
istart_nest_tile6=10  # i-index on tile 6 at which nested or regional grid starts.
iend_nest_tile6=374   # i-index on tile 6 at which nested or regional grid ends.
jstart_nest_tile6=10  # j-index on tile 6 at which nested or regional grid starts.
jend_nest_tile6=374   # j-index on tile 6 at which nested or regional grid ends.


#generate_RAP_domain
#generate_HRRR_domain

#if [ "$gtype" = "global" ]; then
#elif [ "$gtype" = "stretch" ]; then
#elif [ "$gtype" = "nest" ]; then
#elif [ "$gtype" = "stretch" ]; then
#fi



