# This file is always sourced by another script (i.e. it's never run in
# its own shell), so there's no need to put the #!/bin/some_shell on the
# first line.

#
#-----------------------------------------------------------------------
#
# Set machine and queue parameters.  Definitions:
#
# MACHINE:
# Machine on which the workflow will run.  Valid values are "WCOSS_C", 
# "WCOSS", "DELL", "THEIA", "JET", "ODIN", and "CHEYENNE".  New values 
# may be added as the workflow is ported to additional machines.
#
# ACCOUNT:
# The account under which to submit jobs to the queue.
#
# QUEUE_DEFAULT:
# The default queue to which workflow tasks are submitted.  If a task
# does not have a specific variable in which its queue is defined (e.g.
# QUEUE_HPSS, QUEUE_RUN_FV3SAR; see below), it is submitted to this
# queue.  If this is not set or set to an empty string, it will be reset
# to a machine-dependent value in the setup script (setup.sh).
#
# QUEUE_HPSS:
# The queue to which the get_GFS_files task is submitted.  This task
# either copies the GFS analysis and forecast files from a system direc-
# tory or fetches them from HPSS.  In either case, it places the files
# in a temporary directory.  If this is not set or set to an empty
# string, it will be reset to a machine-dependent value in the setup
# script (setup.sh).
#
# QUEUE_RUN_FV3SAR:
# The queue to which the run_FV3SAR task is submitted.  This task runs
# the forecast.  If this is not set or set to an empty string, it will
# be reset to a machine-dependent value in the setup script (setup.sh).
#
#-----------------------------------------------------------------------
#
MACHINE="BIG_COMPUTER"
ACCOUNT="project_name"
QUEUE_DEFAULT="batch_queue"
QUEUE_HPSS="hpss_queue"
QUEUE_RUN_FV3SAR="production_queue"
#
#-----------------------------------------------------------------------
#
# Set directories.  Definitions:
#
# BASEDIR:
# Directory in which the git clones of the fv3sar_workflow and 
# NEMSfv3gfs repositories are located.
#
# TMPDIR:
# Temporary work directory.  A subdirectory for the current run will be
# created under this.
#
# UPPDIR:
# Directory in which the NCEP post (UPP) executable is located.  Note 
# that the ndate executable needs to be compiled in the community UPP
# and copied into UPPDIR.
#
# CCPPDIR:
# Directory in which the CCPP version executable of FV3 is located.  If
# CCPP=false, this path is ignored.
#
#-----------------------------------------------------------------------
#
BASEDIR="/path/to/directory/of/fv3sar_workflow/and/NEMSfv3gfs/clones"
TMPDIR="/path/to/temporary/work/directories"
UPPDIR="/path/to/UPP/executable"
CCPPDIR="/path/to/CCPP/executable"
#
#-----------------------------------------------------------------------
#
# File names.  Definitions:
#
# FV3_NAMELIST_FN:
# Name of file containing the FV3SAR namelist settings.
#
# FV3_CCPP_GFS_NAMELIST_FN:
# Name of file containing the FV3SAR namelist settings for a CCPP run using GFS physics.
#
# FV3_CCPP_GSD_NAMELIST_FN:
# Name of file containing the FV3SAR namelist settings for a CCPP run using GSD physics.
#
# DIAG_TABLE_FN:
# Name of file that specifies the fields that the FV3SAR will output.
#
# DIAG_TABLE_CCPP_GFS_FN:
# Required as current version of CCPP FV3 executable using GFS physics cannot handle refl_10cm variable in diag_table.
#
# DIAG_TABLE_CCPP_GSD_FN:
# Uses specific variables for Thompson MP
#
# FIELD_TABLE_FN:
# Name of file that specifies ???
#
# FIELD_TABLE_CCPP_GSD_FN:
# Field table for a CCPP run using GSD physics
#
# DATA_TABLE_FN:
# Name of file that specifies ???
#
# MODEL_CONFIG_FN:
# Name of file that specifies ???
#
# NEMS_CONFIG_FN:
# Name of file that specifies ???
#
# WFLOW_XML_FN:
# Name of the workflow XML file to be passed to rocoto.
#
# SCRIPT_VAR_DEFNS_FN:
# Name of file that is sourced by the worflow scripts to set variable
# values.
#
# WRTCMP_PARAMS_TEMPLATE_FN:
# Name of the template file that needs to be appended to the model con-
# figuration file (MODEL_CONFIG_FN) if the write component (quilting) is
# going to be used to write output files.  This file contains defini-
# tions (either in terms of actual values or placeholders) of the para-
# meters that the write component needs.  If the write component is go-
# ing to be used, this file is first appended to MODEL_CONFIG_FN, and
# any placeholder values in the variable definitions in the new MODEL_-
# CONFIG_FN file are subsequently replaced by actual values.  If a pre-
# defined domain is being used (see predef_domain below), WRTCMP_PA-
# RAMS_TEMPLATE_FN may be set to an empty string.  In this case, it will
# be reset to the name of the existing template file for that predefined
# domain.  It is assumed that the file specified by WRTCMP_PARAMS_TEMP-
# LATE_FN is located in the templates directory TEMPLATE_DIR, which is
# in turn defined in the setup script.
#
#-----------------------------------------------------------------------
#
REGIONAL_GRID_NAMELIST_FN="regional_grid.nml"
FV3_NAMELIST_FN="input.nml"
FV3_CCPP_GFS_NAMELIST_FN="input_ccpp_gfs.nml"
FV3_CCPP_GSD_NAMELIST_FN="input_ccpp_gsd.nml"
DIAG_TABLE_FN="diag_table"
DIAG_TABLE_CCPP_GSD_FN="diag_table_ccpp_gsd"
FIELD_TABLE_FN="field_table"
FIELD_TABLE_CCPP_GSD_FN="field_table_ccpp_gsd"
DATA_TABLE_FN="data_table"
MODEL_CONFIG_FN="model_configure"
NEMS_CONFIG_FN="nems.configure"
WFLOW_XML_FN="FV3SAR_wflow.xml"
SCRIPT_VAR_DEFNS_FN="var_defns.sh"
WRTCMP_PARAMS_TEMPLATE_FN=""
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
# date interval.  As of 11/12/2018, the boundary data is obtained from 
# GFS forecast files in nemsio format, which are stored in mass storage
# (HPSS).  Since these forecast files are available only every 6 hours, 
# BC_update_intvl_hrs must be greater than or equal to 6.
#
#-----------------------------------------------------------------------
#
CDATE="YYYYMMDDHH"
fcst_len_hrs="24"
BC_update_intvl_hrs="6"
#
#-----------------------------------------------------------------------
#
# Set the parameter (ictype) that determines the source model for the 
# initial and boundary conditions.  The values that ictype can take on
# are:
#
# * "oldgfs":
#   Old GFS output.  This is for Quarter 2 of FY2016 (should this be 
#   2017?) and earlier.
#
# * "opsgfs":
#   Operational GFS.  This is for Quarter 3 of FY2017 and later.  It 
#   uses new land datasets.
#
# * "pfv3gfs":
#   The FV3 "parallels".
#
#-----------------------------------------------------------------------
#
ictype="opsgfs"
#
#-----------------------------------------------------------------------
#
# Set run_title.  This variable contains a descriptive string for the
# current run/forecast that is used in forming the names of the run and
# work (temporary) directories that will be created.  It should be used
# to distinguish these directories from the run and work directories ge-
# nerated by other FV3SAR runs.  Note that since it will be used in di-
# rectory names, it should not contain spaces.
#
#-----------------------------------------------------------------------
#
run_title="desc_str"
#
#-----------------------------------------------------------------------
# Flag controlling whether a CCPP run will be executed.  Setting this
# flag to true will cause the workflow to source the CCPP version of the
# FV3 executable, based on the path defined in FV3_CCPP_NAMELIST_FN. For
# now, a separate input.nml namelist will be used (input_ccpp.nml) that
# corresponds with settings used in the EMC regional regression tests.
#-----------------------------------------------------------------------
#
CCPP="false" # "true" or "false"
#
#-----------------------------------------------------------------------
# If CCPP=true, the suite flag defines the physics package for which the
# necessary suite XML file will be sourced from the CCPP directory defined
# in CCPPDIR.  NOTE: It is up to the user to ensure that the CCPP FV3
# executable is compiled with either the dynamic build or the static build
# with the correct physics package.  The run will fail if there is a mismatch. 
#-----------------------------------------------------------------------
#
CCPP_suite="GSD"
#CCPP_suite="GFS"
#
#-----------------------------------------------------------------------
#
# Set grid_gen_method.  This variable specifies the method to use to ge-
# nerate a regional grid in the horizontal.  The values that grid_gen_-
# method can take on are:
#
# * "GFDLgrid":
#   This will generate a regional grid by first generating a parent glo-
#   bal cubed-sphere grid using GFDL's grid generator.
#
# * "JPgrid":
#   This will generate a regional grid using the map projection deve-
#   loped by Jim Purser of EMC.
#
#-----------------------------------------------------------------------
#
grid_gen_method="GFDLgrid"
#grid_gen_method="JPgrid"
#
#-----------------------------------------------------------------------
#
# Parameters for generating a grid for grid_gen_method set to "JPgrid".
#
# delx:
# The cell size in the zonal direction of the regional grid (in meters).
#
# dely:
# The cell size in the meridional direction of the regional grid (in me-
# ters).
#
# nx_T7:
# The number of cells in the zonal direction on the regional grid.
#
# ny_T7:
# The number of cells in the meridional direction on the regional grid.
#
# nhw_T7:
# The width of the wide halo (in units of number of cells) to create 
# around the regional grid.  A grid with a halo of this width will first
# be created and stored in a grid specification file.  This grid will 
# then be shaved down to obtain grids with 3-cell-wide and 4-cell-wide
# halos.
#
# a_grid_param:
# The "a" parameter used in the Jim Purser map projection/grid genera-
# tion method.
#
# k_grid_param:
# The "k" parameter used in the Jim Purser map projection/grid genera-
# tion method.
#
#-----------------------------------------------------------------------
#
delx="3000.0"  # In meters.
dely="3000.0"  # In meters.
nx_T7=1000
ny_T7=1000
nhw_T7=6

a_grid_param="0.21423"
k_grid_param="-0.23209"

#
#-----------------------------------------------------------------------
#
# Set predef_domain.  This variable specifies a predefined (regional)
# domain, as follows:
#
# * If predef_domain is set to an empty string, the grid configuration
#   parameters set below are used to generate a grid.
#
# * If predef_domain is set to a valid non-empty string, the grid confi-
#   guration parameters set below are overwritten by predefined values
#   in order to generate a predefined grid.  Valid non-empty values for
#   predef_domain currently consist of:
#
#     "RAP"
#     "HRRR"
#
#   These result in regional grids that cover (as closely as possible)
#   the domains used in the WRF/ARW-based RAP and HRRR models, respec-
#   tively.  The run title string (run_title) set above is also modified
#   to reflect the specified predefined domain.
#
#-----------------------------------------------------------------------
#
predef_domain=""
#predef_domain="RAP"
#predef_domain="HRRR"
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
# dt_atmos:
# Time step for the largest atmosphere model loop, corresponding to the
# frequency at which the top level routine in the dynamics is called as
# well as the frequency with which the physics is called.
#
#-----------------------------------------------------------------------
#
RES="384"
lon_ctr_T6=-97.5
lat_ctr_T6=35.5
stretch_fac=1.5
istart_rgnl_T6=10
iend_rgnl_T6=374
jstart_rgnl_T6=10
jend_rgnl_T6=374
refine_ratio=3
dt_atmos=18 #Preliminary values: 18 for 3-km runs, 90 for 13-km runs
#
#-----------------------------------------------------------------------
#
# Set preexisting_dir_method.  This variable determines the strategy to
# use to deal with preexisting run and/or work directories (e.g ones
# generated by previous forecasts; such directories may be encountered
# if the value of run_title specified above does not result in unique
# direcotry names).  This variable must be set to one of "delete", "re-
# name", and "quit".  The resulting behavior for each of these values is
# as follows:
#
# * "delete":
#   The preexisting directory is deleted and a new directory (having the
#   same name as the original preexisting directory) is created.
#
# * "rename":
#   The preexisting directory is renamed and a new directory (having the
#   same name as the original preexisting directory) is created.  The
#   new name of the preexisting directory consists of its original name
#   and the suffix "_oldNNN", where NNN is a 3-digit integer chosen to
#   make the new name unique.
#
# * "quit":
#   The preexisting directory is left unchanged, but execution of the
#   currently running script is terminated.  In this case, the preexist-
#   ing directory must be dealt with manually before rerunning the
#   script.
#
#-----------------------------------------------------------------------
#
preexisting_dir_method="delete"
#preexisting_dir_method="rename"
#preexisting_dir_method="quit"
#
#-----------------------------------------------------------------------
#
# Set the flag that determines whether or not the workflow scripts tend
# to be more verbose.  This must be set to "true" or "false".
#
#-----------------------------------------------------------------------
#
VERBOSE="true"
#VERBOSE="false"
#
#-----------------------------------------------------------------------
#
# Set the number of MPI tasks to use in the x and y directions.
#
#-----------------------------------------------------------------------
#
layout_x="20"
layout_y="20"
#
#-----------------------------------------------------------------------
#
# Set the blocksize to use.  This is the amount of data that is passed
# into the cache at a time.  The number of vertical columns per MPI task
# needs to be divisible by the blocksize; otherwise, unexpected results
# may occur.
#
#-----------------------------------------------------------------------
#
blocksize="24"
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
# model configuration file MODEL_CONFIG_FN in the forecast's run direc-
# tory).
#
#-----------------------------------------------------------------------
#
quilting=".true."
write_groups="1"
write_tasks_per_group="20"
print_esmf=".false."
