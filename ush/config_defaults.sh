# This file is always sourced by another script (i.e. it's never run in
# its own shell), so there's no need to put the #!/bin/some_shell on the
# first line.

#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
RUN_ENVIR="nco"
#
#-----------------------------------------------------------------------
#
# mach_doc_start
# Set machine and queue parameters.  Definitions:
#
# MACHINE:
# Machine on which the workflow will run.  Valid values are "WCOSS_C", 
# "WCOSS", "DELL", "THEIA","HERA","JET", "ODIN", and "CHEYENNE".  New values 
# may be added as the workflow is ported to additional machines.
#
# ACCOUNT:
# The account under which to submit jobs to the queue.
#
# QUEUE_DEFAULT:
# The default queue to which workflow tasks are submitted.  If a task
# does not have a specific variable in which its queue is defined (e.g.
# QUEUE_HPSS, QUEUE_FCST; see below), it is submitted to this
# queue.  If this is not set or set to an empty string, it will be reset
# to a machine-dependent value in the setup script (setup.sh).
#
# QUEUE_HPSS:
# The queue to which the tasks that get or link to external model files
# (needed to generate ICs and LBCs) are submitted.  This task either co-
# pies the GFS analysis and forecast files from a system direc-
# tory or fetches them from HPSS.  In either case, it places the files
# in a temporary directory.  If this is not set or set to an empty
# string, it will be reset to a machine-dependent value in the setup
# script (setup.sh).
#
# QUEUE_FCST:
# The queue to which the run_FV3 task is submitted.  This task runs
# the forecast.  If this is not set or set to an empty string, it will
# be reset to a machine-dependent value in the setup script (setup.sh).
#
# mach_doc_end
#
#-----------------------------------------------------------------------
#
MACHINE="BIG_COMPUTER"
ACCOUNT="project_name"
QUEUE_DEFAULT="batch_queue"
QUEUE_HPSS="hpss_queue"
QUEUE_FCST="production_queue"
#
#-----------------------------------------------------------------------
#
# dir_doc_start
# Set directories.  Definitions:
#
# EXPT_BASEDIR:
# The base directory in which the experiment directory will be created.  
# If this is not specified or if it is set to an empty string, it will
# default to $BASEDIR/expt_dirs.  The full path to the experiment di-
# rectory, which we will denote by EXPTDIR, will be set to $EXPT_BASEDIR
# /$EXPT_SUBDIR (also see definition of EXPT_SUBDIR).
#
# EXPT_SUBDIR:
# The name that the experiment directory (without the full path) will 
# have.  The full path to the experiment directory, which we will denote
# by EXPTDIR, will be set to ${EXPT_BASEDIR}/${EXPT_SUBDIR} (also see 
# definition of EXPT_BASEDIR).
# dir_doc_end
#
#-----------------------------------------------------------------------
#
#EXPT_BASEDIR="/path/to/directory/in/which/experiment/subdirs/will/exist"
#EXPT_SUBDIR="my_test"
EXPT_BASEDIR=""
EXPT_SUBDIR=""

NET="rrfs"
envir="para"
RUN="experiment_name"
COMINgfs="/path/to/directory/containing/gfs/input/files"
STMP="/path/to/temporary/directory/stmp"
PTMP="/path/to/temporary/directory/ptmp"
#
#-----------------------------------------------------------------------
#
# File names.  Definitions:
#
# RGNL_GRID_NML_FN:
# Name of file containing the namelist settings for the utility that ge-
# nerates a "JPgrid" type of regional grid.
#
# FV3_NML_FN:
# Name of file containing the FV3SAR namelist settings.
#
# FV3_NML_CCPP_GFSPHYS_GFSEXTRN_FN:
# Name of file containing the FV3SAR namelist settings for a CCPP-ena-
# bled forecast that uses GFS external model data for the initial condi-
# tions (ICs) and GFS physics.
#
# FV3_NML_CCPP_GSDPHYS_FN:
# Name of file containing the FV3SAR namelist settings for a CCPP-ena-
# bled forecast that uses GSD physics.
#
# DIAG_TABLE_FN:
# Name of file that specifies the fields that the FV3SAR will output.
#
# DIAG_TABLE_CCPP_GFS_FN:
# Name of file that specifies the fields that the FV3SAR will output for
# a CCPP-enabled forecast that uses GFS physics.  This is needed because
# the current version of the CCPP-enabled FV3SAR executable using GFS 
# physics cannot handle refl_10cm variable in diag_table.
#
# DIAG_TABLE_CCPP_GSD_FN:
# Name of file that specifies the fields that the FV3SAR will output for
# a CCPP-enabled forecast that uses GSD physics.  This includes varia-
# bles specific to Thompson microphysics.
#
# FIELD_TABLE_FN:
# Name of file that specifies the traces that the FV3SAR will read in
# from the IC/BC files.
#
# FIELD_TABLE_CCPP_GSD_FN:
# Name of file that specifies the traces that the FV3SAR will read in
# from the IC/BC files for a CCPP-enabled forecast that uses GSD phys-
# ics.
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
# figuration file (MODEL_CONFIG_FN) if the write component (QUILTING) is
# going to be used to write output files.  This file contains defini-
# tions (either in terms of actual values or placeholders) of the para-
# meters that the write component needs.  If the write component is go-
# ing to be used, this file is first appended to MODEL_CONFIG_FN, and
# any placeholder values in the variable definitions in the new MODEL_-
# CONFIG_FN file are subsequently replaced by actual values.  If a pre-
# defined domain is being used (see PREDEF_GRID_NAME below), WRTCMP_PA-
# RAMS_TEMPLATE_FN may be set to an empty string.  In this case, it will
# be reset to the name of the existing template file for that predefined
# domain.  It is assumed that the file specified by WRTCMP_PARAMS_TEMP-
# LATE_FN is located in the templates directory TEMPLATE_DIR, which is
# in turn defined in the setup script.
#
#-----------------------------------------------------------------------
#
RGNL_GRID_NML_FN="regional_grid.nml"
FV3_NML_FN="input.nml"
FV3_NML_CCPP_GFSPHYS_GFSEXTRN_FN="input_ccpp_GFSphys_GFSextrn.nml"
FV3_NML_CCPP_GSDPHYS_FN="input_ccpp_GSDphys.nml"
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
# DATE_FIRST_CYCL:
# Starting date of the first forecast in the set of forecasts to run.  
# Format is "YYYYMMDD".  Note that this does not include the hour-of-
# day.
#
# DATE_LAST_CYCL:
# Starting date of the last forecast in the set of forecasts to run.
# Format is "YYYYMMDD".  Note that this does not include the hour-of-
# day.
#
# CYCL_HRS:
# An array containing the hours of the day at which to launch forecasts.
# Forecasts are launched at these hours on each day from DATE_FIRST_CYCL
# to DATE_LAST_CYCL, inclusive.  Each element of this array must be a 
# two-digit string representing an integer that is less than or equal to
# 23, e.g. "00", "03", "12", "23".
#
# FCST_LEN_HRS:
# The length of each forecast, in integer hours.
#
#-----------------------------------------------------------------------
#
DATE_FIRST_CYCL="YYYYMMDD"
DATE_LAST_CYCL="YYYYMMDD"
CYCL_HRS=( "HH1" "HH2" )
FCST_LEN_HRS="24"
#
#-----------------------------------------------------------------------
#
# Set initial and lateral boundary condition generation parameters.  De-
# finitions:
#
# EXTRN_MDL_NAME_ICS
#`The name of the external model that will provide fields from which 
# initial condition (IC) and surface files will be generated for input
# into the FV3SAR.
#
# EXTRN_MDL_NAME_LBCS
#`The name of the external model that will provide fields from which 
# lateral boundary condition (LBC) files will be generated for input in-
# to the FV3SAR.
#
# LBC_UPDATE_INTVL_HRS:
# The frequency (in integer hours) with which lateral boundary data will
# be provided to the FV3SAR model.  We will refer to this as the bound-
# ary update interval.  If the boundary data is obtained from GFS fore-
# cast files in nemsio format stored in HPSS (mass store), then LBC_UP-
# DATE_INTVL_HRS must be greater than or equal to 6 because these fore-
# cast files are available only every 6 hours.
#
# EXTRN_MDL_INFO_FN:
# Name of sourceable file (not including the full path) defining the va-
# riables specified in EXTRN_MDL_INFO_VAR_NAMES (see below).  
#
# EXTRN_MDL_INFO_VAR_NAMES:
# Names to use for the following parameters (for a given cycle of the 
# FV3SAR):
# * The date and hour-of-day (in YYYYMMDDHH format) of the start time of
#   the external model.
# * Array containing the forecast hours (relative to the 
# * Array containing the names of the external model output files.
# * The system directory in which the external model output files may be
#   found (if the cycle start time is not too old).
# * The format of the archive file (e.g. "tar", "zip", etc) on HPSS that
#   may contain the external model output files.  Note that this archive
#   file will exist only if the cycle start time is old enough.
# * The name of the archive file on HPSS that may contain the external
#   model output files.
# * The full path to the archive file on HPSS that may contain the ex-
#   ternal model output files.
# * The directory "within" the archive file in which the external model 
#   output files are stored.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"
FV3GFS_FILE_FMT="nemsio"
LBC_UPDATE_INTVL_HRS="6"
#
#-----------------------------------------------------------------------
#
# Flag controlling whether or not a CCPP-enabled version of the FV3SAR
# will be run.  This must be set to "TRUE" or "FALSE".  Setting this 
# flag to "TRUE" will cause the workflow to stage the appropriate CCPP-
# enabled versions of the FV3SAR executable and various input files 
# (e.g. the FV3SAR namelist file, the diagnostics table file, the field
# table file, etc) that have settings that correspond to EMC's CCPP-ena-
# bled FV3SAR regression test.  It will also cause additional files 
# (i.e. in addition to the ones for the non-CCPP enabled version of the
# FV3SAR) to be staged in the experiment directory (e.g. module setup
# scripts, module load files).
#
#-----------------------------------------------------------------------
#
USE_CCPP="FALSE"
#
#-----------------------------------------------------------------------
#
# If CCPP has been set to "TRUE", the CCPP_PHYS_SUITE variable defines 
# the physics suite that will run using CCPP.  This affects the FV3SAR
# namelist file, the diagnostics table file, the field table file, and
# the XML physics suite definition file that are staged in the experi-
# ment directory and/or the run directories under it.  As of 4/4/2019,
# valid values for this parameter are:
#
#   "GFS" - to run with the GFS physics suite
#   "GSD" - to run with the GSD physics suite
#
# Note that with CCPP set to "FALSE", the only physics suite that can be
# run is the GFS.
#
# IMPORTANT NOTE: 
# It is up to the user to ensure that the CCPP FV3 executable is com-
# piled with either the dynamic build or the static build with the cor-
# rect physics package.  If using a static build, the run will fail if 
# there is a mismatch between the physics package specified in this con-
# figuration file and the physics package used for the static build. 
#
#-----------------------------------------------------------------------
#
CCPP_PHYS_SUITE="GSD"
#CCPP_PHYS_SUITE="GFS"
#
#-----------------------------------------------------------------------
#
# Set GRID_GEN_METHOD.  This variable specifies the method to use to ge-
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
GRID_GEN_METHOD="JPgrid"
#
#-----------------------------------------------------------------------
#
# Set parameters specific to the method for generating a regional grid
# WITH a global parent (i.e. for GRID_GEN_METHOD set to "GFDLgrid").  
# Note that for this method:
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
if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then

  RES="384"
  lon_ctr_T6=-97.5
  lat_ctr_T6=35.5
  stretch_fac=1.5
  istart_rgnl_T6=10
  iend_rgnl_T6=374
  jstart_rgnl_T6=10
  jend_rgnl_T6=374
  refine_ratio=3
#
#-----------------------------------------------------------------------
#
# Set parameters specific to the method for generating a regional grid
# without a global parent (i.e. for GRID_GEN_METHOD set to "JPgrid").  
# These are:
#
# lon_rgnl_ctr:
# The longitude of the center of the grid (in degrees).
#
# lat_rgnl_ctr:
# The latitude of the center of the grid (in degrees).
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
elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then

  lon_rgnl_ctr=-97.5
  lat_rgnl_ctr=35.5
  delx="3000.0"
  dely="3000.0"
  nx_T7=1000
  ny_T7=1000
  nhw_T7=6
  a_grid_param="0.21423"
  k_grid_param="-0.23209"

fi
#
#-----------------------------------------------------------------------
#
# Set PREDEF_GRID_NAME.  This variable specifies a predefined (regional)
# domain, as follows:
#
# * If PREDEF_GRID_NAME is set to an empty string, the grid configuration
#   parameters set below are used to generate a grid.
#
# * If PREDEF_GRID_NAME is set to a valid non-empty string, the grid confi-
#   guration parameters set below are overwritten by predefined values
#   in order to generate a predefined grid.  Valid non-empty values for
#   PREDEF_GRID_NAME currently consist of:
#
#     "RAP"
#     "HRRR"
#     "EMCCONUS"
#
#   These result in regional grids that cover (as closely as possible)
#   the domains used in the WRF/ARW-based RAP and HRRR models, respec-
#   tively.
#
#-----------------------------------------------------------------------
#
PREDEF_GRID_NAME=""
#
#-----------------------------------------------------------------------
#
# Set the model integraton time step dt_atmos.  This is the time step 
# for the largest atmosphere model loop.  It corresponds to the frequen-
# cy with which the top level routine in the dynamics is called as well
# as the frequency with which the physics is called.
#
#-----------------------------------------------------------------------
#
dt_atmos=18 #Preliminary values: 18 for 3-km runs, 90 for 13-km runs
#
#-----------------------------------------------------------------------
#
# Set PREEXISTING_DIR_METHOD.  This variable determines the strategy to
# use to deal with preexisting experiment and/or work directories (e.g
# ones generated by previous experiments).  This variable must be set to
# one of "delete", "rename", and "quit".  The resulting behavior for 
# each of these values is as follows:
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
PREEXISTING_DIR_METHOD="delete"
#PREEXISTING_DIR_METHOD="rename"
#PREEXISTING_DIR_METHOD="quit"
#
#-----------------------------------------------------------------------
#
# Set the flag that determines whether or not the workflow scripts tend
# to be more verbose.  This must be set to "TRUE" or "FALSE".
#
#-----------------------------------------------------------------------
#
VERBOSE="TRUE"
#VERBOSE="FALSE"
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
# Set write-component (quilting) parameters.  Definitions:
#
# QUILTING:
# Flag for whether or not to use the write component for output.
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
QUILTING="TRUE"
print_esmf=".false."

WRTCMP_write_groups="1"
WRTCMP_write_tasks_per_group="20"
WRTCMP_output_grid="''"
WRTCMP_cen_lon=""
WRTCMP_cen_lat=""
WRTCMP_lon_lwr_left=""
WRTCMP_lat_lwr_left=""
#
# The following are used only for the case of WRTCMP_output_grid set to
# "'rotated_latlon'".
#
WRTCMP_lon_upr_rght=""
WRTCMP_lat_upr_rght=""
WRTCMP_dlon=""
WRTCMP_dlat=""
#
# The following are used only for the case of WRTCMP_output_grid set to
# "'lambert_conformal'".
#
WRTCMP_cen_lon=""
WRTCMP_cen_lat=""
WRTCMP_stdlat1=""
WRTCMP_stdlat2=""
WRTCMP_nx=""
WRTCMP_ny=""
WRTCMP_dx=""
WRTCMP_dy=""


#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
RUN_TASK_MAKE_GRID="TRUE"
GRID_DIR="/path/to/pregenerated/grid/files"

RUN_TASK_MAKE_OROG="TRUE"
OROG_DIR="/path/to/pregenerated/orog/files"
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
RUN_TASK_MAKE_SFC_CLIMO="TRUE"
SFC_CLIMO_DIR="/path/to/pregenerated/surface/climo/files"

#
#-----------------------------------------------------------------------
#
# 
#
#-----------------------------------------------------------------------
#
FIXam_FILES_SYSDIR=( \
"CFSR.SEAICE.1982.2012.monthly.clim.grb" \
"RTGSST.1982.2012.monthly.clim.grb" \
"seaice_newland.grb" \
"global_climaeropac_global.txt" \
"global_albedo4.1x1.grb" \
"global_glacier.2x2.grb" \
"global_h2o_pltc.f77" \
"global_maxice.2x2.grb" \
"global_mxsnoalb.uariz.t126.384.190.rg.grb" \
"ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77" \
"global_shdmax.0.144x0.144.grb" \
"global_shdmin.0.144x0.144.grb" \
"global_slope.1x1.grb" \
"global_snoclim.1.875.grb" \
"global_snowfree_albedo.bosu.t126.384.190.rg.grb" \
"global_soilmgldas.t126.384.190.grb" \
"global_soiltype.statsgo.t126.384.190.rg.grb" \
"global_tg3clim.2.6x1.5.grb" \
"global_vegfrac.0.144.decpercent.grb" \
"global_vegtype.igbp.t126.384.190.rg.grb" \
"global_zorclim.1x1.grb" \
"global_sfc_emissivity_idx.txt" \
"global_solarconstant_noaa_an.txt" \
"fix_co2_proj/global_co2historicaldata_2010.txt" \
"fix_co2_proj/global_co2historicaldata_2011.txt" \
"fix_co2_proj/global_co2historicaldata_2012.txt" \
"fix_co2_proj/global_co2historicaldata_2013.txt" \
"fix_co2_proj/global_co2historicaldata_2014.txt" \
"fix_co2_proj/global_co2historicaldata_2015.txt" \
"fix_co2_proj/global_co2historicaldata_2016.txt" \
"fix_co2_proj/global_co2historicaldata_2017.txt" \
"fix_co2_proj/global_co2historicaldata_2018.txt" \
"global_co2historicaldata_glob.txt" \
"co2monthlycyc.txt" \
)
# "global_o3prdlos.f77" \

FIXam_FILES_EXPTDIR=( \
"CFSR.SEAICE.1982.2012.monthly.clim.grb" \
"RTGSST.1982.2012.monthly.clim.grb" \
"seaice_newland.grb" \
"aerosol.dat" \
"global_albedo4.1x1.grb" \
"global_glacier.2x2.grb" \
"global_h2oprdlos.f77" \
"global_maxice.2x2.grb" \
"global_mxsnoalb.uariz.t126.384.190.rg.grb" \
"global_o3prdlos.f77" \
"global_shdmax.0.144x0.144.grb" \
"global_shdmin.0.144x0.144.grb" \
"global_slope.1x1.grb" \
"global_snoclim.1.875.grb" \
"global_snowfree_albedo.bosu.t126.384.190.rg.grb" \
"global_soilmgldas.t126.384.190.grb" \
"global_soiltype.statsgo.t126.384.190.rg.grb" \
"global_tg3clim.2.6x1.5.grb" \
"global_vegfrac.0.144.decpercent.grb" \
"global_vegtype.igbp.t126.384.190.rg.grb" \
"global_zorclim.1x1.grb" \
"sfc_emissivity_idx.txt" \
"solarconstant_noaa_an.txt" \
"co2historicaldata_2010.txt" \
"co2historicaldata_2011.txt" \
"co2historicaldata_2012.txt" \
"co2historicaldata_2013.txt" \
"co2historicaldata_2014.txt" \
"co2historicaldata_2015.txt" \
"co2historicaldata_2016.txt" \
"co2historicaldata_2017.txt" \
"co2historicaldata_2018.txt" \
"co2historicaldata_glob.txt" \
"co2monthlycyc.txt" \
)

