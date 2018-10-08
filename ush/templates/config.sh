#!/bin/sh

# Machine and queue paramters.

machine=        # Machine on which we are running.  Must be "WCOSS", "WCOSS_C", or "THEIA"
ACCOUNT=        # The account under which to submit jobs to the queue.

# Directories.

BASEDIR=         # Directory in which clone of fv3gfs and NEMSfv3gfs git repositories are located.
TMPDIR=  # Temporary work directory.

# Forecast parameters.

CDATE=${CDATE:-}           # Starting date of forecast.  Format is "YYYYMMDDHH".

fcst_len_hrs=       # Forecast length (in hours).
BC_interval_hrs=  # Boundary condition time interval (in hours).

# Grid configuration.

gtype=   # Grid type.  Must be "uniform", "stretch", "nest", or "regional"
RES=   # Number of points in each direction of each tile of global grid.  Must be "48", "96", "192", "384", "768", "1152", or "3072"
stretch_fac=             # Stretching factor used in the Schmidt transformation (stretching of cubed sphere grid).
lon_tile6_ctr=       # Longitude of center of tile 6 (in degrees).
lat_tile6_ctr=        # Latitude of center of tile 6 (in degrees).
refine_ratio=             # Refinement ratio for nested or regional grid.
istart_nest_tile6=  # i-index on tile 6 at which nested or regional grid starts.
iend_nest_tile6=     # i-index on tile 6 at which nested or regional grid ends.
jstart_nest_tile6=  # j-index on tile 6 at which nested or regional grid starts.
jend_nest_tile6=     # j-index on tile 6 at which nested or regional grid ends.
title=           # Descriptive string for the forecast.  Used in forming the name of the preprocessing output directory.

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

predef_rgnl_domain=       # No predefined regional domain.  Will use grid parameters above to generate grid.

layout_x=  #Number of MPI tasks in the x direction
layout_y=  #Number of MPI tasks in the y direction

ncores_per_node=             #Define number of cores per node
quilting=                    #Define whether to use the "write component" or not
print_esmf=                  #Define whether to output ESMF information or not
write_groups=                #Define number of write groups
write_tasks_per_group=       #Define write tasks per group

