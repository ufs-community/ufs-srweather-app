#!/bin/sh

#
# Machine and queue paramters.
#
machine=${machine:-"THEIA"}       # Machine on which we are running.  Must be "WCOSS", "WCOSS_C", or "THEIA"
ACCOUNT=${ACCOUNT:-"gsd-fv3"}     # The account under which to submit jobs to the queue.
#
# Directories.
#
BASEDIR=${BASEDIR:-"/scratch3/BMC/det/beck/FV3-CAM"}          # Directory in which clone of fv3gfs and NEMSfv3gfs git repositories are located.
TMPDIR=${TMPDIR:-"/scratch3/BMC/det/beck/FV3-CAM/work_dirs"}  # Temporary work directory.
#
# Forecast parameters.
#
CDATE=${CDATE:-"2018060400"}           # Starting date of forecast.  Format is "YYYYMMDDHH".
#CDATE=$( date "+%Y%m%d"00 )           # This sets CDATE to today.
#CDATE=$( date --date="yesterday" "+%Y%m%d"00 )  # This sets CDATE to yesterday.
fcst_len_hrs=${fcst_len_hrs:-24}       # Forecast length (in hours).
BC_interval_hrs=${BC_interval_hrs:-6}  # Boundary condition time interval (in hours).
#
# Grid configuration.
#
gtype=${gtype:-"regional"}                  # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
RES=${RES:-"384"}                           # Number of points in each direction of each tile of global grid.  Must be "48", "96", "192", "384", "768", "1152", or "3072"
stretch_fac=${stretch_fac:-1.5}             # Stretching factor used in the Schmidt transformation (stretching of cubed sphere grid).
lon_tile6_ctr=${lon_tile6_ctr:--97.5}       # Longitude of center of tile 6 (in degrees).
lat_tile6_ctr=${lat_tile6_ctr:-35.5}        # Latitude of center of tile 6 (in degrees).
refine_ratio=${refine_ratio:-3}             # Refinement ratio for nested or regional grid.
istart_nest_tile6=${istart_nest_tile6:-10}  # i-index on tile 6 at which nested or regional grid starts.
iend_nest_tile6=${iend_nest_tile6:-374}     # i-index on tile 6 at which nested or regional grid ends.
jstart_nest_tile6=${jstart_nest_tile6:-10}  # j-index on tile 6 at which nested or regional grid starts.
jend_nest_tile6=${jend_nest_tile6:-374}     # j-index on tile 6 at which nested or regional grid ends.
title=${title:-"descriptive_str"}           # Descriptive string for the forecast.  Used in forming the name of the preprocessing output directory.
#
# Specify a predefined regional domain.
#
# The parameter predef_rgnl_domain specifies a predefined regional do-
# main.  
#
# If gtype is not set to "regional", this parameter is ignored and the 
# grid parameters set above (or a subset of them) are used to generate a 
# non-regional grid (i.e. a grid that is global and uniform, global and
# stretched, or global and possibly stretched and contains a nest within
# tile 6).
#
# If gtype is set to "regional", then:
#
# 1) If predef_rgnl_domain is set to an empty string, the grid parame-
#    ters set above are used to generate a regional grid.
#
# 2) If predef_rgnl_domain is set to a valid non-empty string, the grid
#    parameters set above (except for gtype) are overwritted by pre-
#    defined values to generate a predefined grid.  Valid non-empty val-
#    ues of predef_rgnl_domain currently consist of:
#
#    "RAP"  "HRRR"
#
predef_rgnl_domain=${predef_rgnl_domain:-""}       # No predefined regional domain.  Will use grid parameters above to generate grid.
#predef_rgnl_domain=${predef_rgnl_domain:-"RAP"}    # Set grid configuration to that of the RAP domain.
#predef_rgnl_domain=${predef_rgnl_domain:-"HRRR"}  # Set grid configuration to that of the HRRR domain.
#
# Number of MPI tasks in the x and y directions.
#
layout_x=${layout_x:-15}  #19 - for HRRR
layout_y=${layout_y:-15}  #25 - for HRRR

#Define whether to use the "write component" or not
quilting=${quilting:-".false."}

#Define number of write groups
write_groups=${write_groups:-"1"}

#Define write tasks per group
write_tasks_per_group=${write_tasks_per_group:-"24"}
