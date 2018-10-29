#!/bin/sh
#
#-----------------------------------------------------------------------
#
# Set machine and queue parameters.  Definitions:
#
# machine:
# Machine on which we are running.  Must be "WCOSS", "WCOSS_C", or 
# "THEIA".
#
# ACCOUNT:
# The account under which to submit jobs to the queue.
#
#-----------------------------------------------------------------------
#
machine=${machine:-"THEIA"}
ACCOUNT=${ACCOUNT:-"gsd-fv3"}
#
#-----------------------------------------------------------------------
#
# Set directories.  Definitions:
#
# BASEDIR:
# Directory in which the git clones of the fv3gfs and NEMSfv3gfs repo-
# sitories are located.
#
# TMPDIR:
# Temporary work directory.  A subdirectory for the current run will be
# created under this.
#
#-----------------------------------------------------------------------
#
BASEDIR="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509"
TMPDIR=${TMPDIR:-"/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs"}
#
#-----------------------------------------------------------------------
#
# Set forecast parameters.  Definitions:
#
# CDATE:
# Starting date of the forecast.  Format is "YYYYMMDDHH".
#
# fcst_len_hrs:
#`The length of the forecast in integer hours.
#
# BC_update_intvl_hrs:
# The frequency (in integer hours) with which boundary data will be pro-
# vided to the FV3SAR model.  We will refer to this as the boundary up-
# date interval.
#
#-----------------------------------------------------------------------
#
#
CDATE=${CDATE:-"2018060400"}           
#CDATE=$( date "+%Y%m%d"00 )                     # This sets CDATE to today.
#CDATE=$( date --date="yesterday" "+%Y%m%d"00 )  # This sets CDATE to yesterday.
#
fcst_len_hrs=${fcst_len_hrs:-6}
BC_update_intvl_hrs=${BC_update_intvl_hrs:-6}
#
#-----------------------------------------------------------------------
#
# Set parameters that determine the grid configuration.  Note that:
#
# * The regional grid is defined with respect to a global cubed-sphere
#   grid.  Thus, the parameters for a global cubed-sphere grid must be
#   specified even though the model equations are not integrated on this
#   global grid (they are integrated only on the regional grid).
#
# * RES is the number of grid cells in either one of the two horizontal
#   directions x and y on any one of the 6 tiles of the global cubed-
#   sphere grid.  RES must be one of "48", "96", "192", "384", "768", 
#   "1152", and "3072".  The mapping from RES to nominal resolution 
#   (cell size) for a uniform global grid (i.e. Schmidt stretch factor
#   stretch_fac set to 1) is as follows:
#
#     C192   -->  50km
#     C384   -->  25km
#     C768   -->  13km
#     C1152  -->   8.5km
#     C3072  -->   3.2km
#
#   Note that these are nominal resolutions.  The actual cell size on 
#   the global grid tiles varies somewhat as we move across a tile.
#
# * Tile 6 has arbitrarily been chosen as the tile to use to orient the
#   global grid on the sphere (Earth).  This is done by specifying lon_-
#   ctr_T6 and lat_ctr_T6, which are the longitude and latitude (in de-
#   grees) of the center of tile 6.
#
# * Setting the Schmidt stretching factor stretch_fac to a value greater
#   than 1 shrinks tile 6, while setting it to a value less than 1 (but
#   still greater than 0) expands tile 6.  The remaining 5 tiles change
#   shape as necessary to maintain global coverage of the grid.
#
# * The cell size on a given global tile depends on both RES and 
#   stretch_fac (since changing RES changes the number of cells in the
#   tile, and changing stretch_fac modifies the shape and size of the
#   tile).
#
# * The regional grid is embedded within tile 6 (i.e. it doesn't extend
#   beyond the boundary of tile 6).  Its exact location within tile 6 is
#   is determined by the starting and ending i and j indices
#
#     istart_rgnl_T6
#     jstart_rgnl_T6
#     iend_rgnl_T6
#     jend_rgnl_T6
#
#   where i is the grid index in the x direction and j is the grid index
#   in the y direction.
#
# * In the FV3SAR code, for convenience the regional grid is denoted as
#   "tile 7" even though it doesn't map back to one of the 6 faces of
#   the cube from which the global grid is generated (it maps back to
#   only a subregion on face 6 since it is wholly confined within tile 
#   6).  Tile 6 is often referred to as the "parent" tile of the region-
#   al grid.
#
# * refine_ratio is the refinement ratio of the regional grid (tile 7)
#   with respect to the grid on its parent tile (tile 6), i.e. it is the
#   number of grid cells along the boundary of the regional grid that 
#   abut one cell on tile 6.  Thus, the cell size on the regional grid
#   depends not only on RES and stretch_fac (because the cell size on 
#   tile 6 depends on these two parameters) but also on refine_ratio.
#   Note that as on the tiles of the global grid, the cell size on the
#   regional grid is not uniform but varies as we move across the grid.
#
# Definitions:
#
# RES:
# Number of points in each of the two horizontal directions (x and y)
# on each tile of the global grid.  Must be "48", "96", "192", "384", 
# "768", "1152", or "3072"
#
# lon_ctr_T6:
# Longitude of the center of tile 6 (in degrees).
#
# lat_ctr_T6:
# Latitude of the center of tile 6 (in degrees).
#
# stretch_fac:
# Stretching factor used in the Schmidt transformation applied to the 
# cubed sphere grid.
#
# istart_rgnl_T6:
# i-index on tile 6 at which the regional grid (tile 7) starts.
#
# iend_rgnl_T6:
# i-index on tile 6 at which the regional grid (tile 7) ends.
#
# jstart_rgnl_T6:
# j-index on tile 6 at which the regional grid (tile 7) starts.
#
# jend_rgnl_T6:
# j-index on tile 6 at which the regional grid (tile 7) ends.
#
# refine_ratio:
# Cell refinement ratio for the regional grid, i.e. the number of cells
# in either the x or y direction on the regional grid (tile 7) that abut
# one cell on its parent tile (tile 6). 
#
#-----------------------------------------------------------------------
#
RES=${RES:-"384"}
lon_ctr_T6=${lon_ctr_T6:--97.5}
lat_ctr_T6=${lat_ctr_T6:-35.5}
stretch_fac=${stretch_fac:-1.5}
istart_rgnl_T6=${istart_rgnl_T6:-10}
iend_rgnl_T6=${iend_rgnl_T6:-374}
jstart_rgnl_T6=${jstart_rgnl_T6:-10}
jend_rgnl_T6=${jend_rgnl_T6:-374}
refine_ratio=${refine_ratio:-3}
#
#-----------------------------------------------------------------------
#
# Set predef_rgnl_domain.  This variable specifies a predefined regional
# domain, as follows:
#
# * If predef_rgnl_domain is set to an empty string, the grid configura-
#   tion parameters set above are used to generate a regional grid.
#
# * If predef_rgnl_domain is set to a valid non-empty string, the grid
#   configuration parameters set above are overwritted by predefined 
#   values in order to generate a predefined grid.  Valid non-empty val-
#   ues for predef_rgnl_domain currently consist of "RAP" and "HRRR".
#   These result in regional grids that cover (as closely as possible) 
#   the domains using in the WRF/ARW-based RAP and HRRR models, respect-
#   ively.
#
#-----------------------------------------------------------------------
#
#predef_rgnl_domain=${predef_rgnl_domain:-""}
predef_rgnl_domain=${predef_rgnl_domain:-"RAP"}
#predef_rgnl_domain=${predef_rgnl_domain:-"HRRR"}
#
#-----------------------------------------------------------------------
#
# Set run_title.  This variable contains a descriptive string for the 
# current run/forecast that is used in forming the names of the run and
# work (temporary) directories that will be created.  It should be used
# to distinguish these directories from the run and work directories ge-
# nerated by other FV3SAR runs.
#
#-----------------------------------------------------------------------
#
run_title=${run_title:-"desc_str01"}
#
#-----------------------------------------------------------------------
#
# Set preexisting_dir_method.  This variable determines the strategy to
# use to deal with preexisting run and/or work directories (e.g ones 
# generated by previous forecasts; such directories may be encountered
# if the value of run_title specified above does not result in unique
# direcotry names).  This variable must be set to one of "overwrite", 
# "rename", and "quit".  The resulting behavior for each of these values
# is as follows:
#
# * "overwrite":
#   Overwrite preexisting directory.  The preexisting directory is dele-
#   ted and a new directory is created.
#
# * "rename":
#   Rename (move) preexisting directory.  The preexisting directory is
#   renamed (by appending "_oldNNN" to its name, where NNN is a 3-digit
#   integer chosen to make a new unique directory name), and a new di-
#   rectory is created.
#
# * "quit":
#   If a preexisting directory is encountered, quit out of the currently
#   running script.
#
#-----------------------------------------------------------------------
#
preexisting_dir_method="overwrite"
#preexisting_dir_method="rename"
#preexisting_dir_method="quit"
#
#-----------------------------------------------------------------------
#
# Set the number of MPI tasks to use in the x and y directions.
#
#-----------------------------------------------------------------------
#
layout_x=${layout_x:-13}  #19(?) - for HRRR
layout_y=${layout_y:-13}  #25(?) - for HRRR
#
#-----------------------------------------------------------------------
#
# Set write-component (aka quilting) parameters.  Definitions:
#
# quilting:
# Flag for whether or not to use the write component for output.  Must
# be ".true." or ".false.".
#
# write_groups:
# The number of write groups (i.e. groups of MPI tasks) to use in the 
# write component.
#
# write_tasks_per_group:
# The number of MPI tasks to allocate for each write group.
#
# print_esmf:
# Flag for whether or not to output extra (debugging) information from
# ESMF routines.  Must be ".true." or ".false.".  Note that the write 
# component uses ESMF library routines to interpolate from the native
# FV3SAR grid to the user-specified output grid (which is defined in the
# NEMS configuration file model_configure in the forecast's run directo-
# ry).
#
#-----------------------------------------------------------------------
#
quilting=${quilting:-".false."}
write_groups=${write_groups:-"1"}
write_tasks_per_group=${write_tasks_per_group:-"24"}
print_esmf=${print_esmf:-".false."}



