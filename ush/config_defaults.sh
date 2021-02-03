#
#-----------------------------------------------------------------------
#
# This file sets the experiment's configuration variables (which are
# global shell variables) to their default values.  For many of these
# variables, the valid values that they may take on are defined in the
# file $USHDIR/valid_param_vals.sh.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Set the RUN_ENVIR variable that is listed and described in the WCOSS
# Implementation Standards document:
#
#   NCEP Central Operations
#   WCOSS Implementation Standards
#   April 17, 2019
#   Version 10.2.0
#
# RUN_ENVIR is described in this document as follows:
#
#   Set to "nco" if running in NCO's production environment. Used to 
#   distinguish between organizations.
#
# Valid values are "nco" and "community".  Here, we use it to generate
# and run the experiment either in NCO mode (if RUN_ENVIR is set to "nco")
# or in community mode (if RUN_ENVIR is set to "community").  This has 
# implications on the experiment variables that need to be set and the
# the directory structure used.
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
# Machine on which the workflow will run.
#
# ACCOUNT:
# The account under which to submit jobs to the queue.
#
# SCHED:
# The job scheduler to use (e.g. slurm).  Set this to an empty string in
# order for the experiment generation script to set it depending on the
# machine.
#
# PARTITION_DEFAULT:
# If using the slurm job scheduler (i.e. if SCHED is set to "slurm"), 
# the default partition to which to submit workflow tasks.  If a task 
# does not have a specific variable that specifies the partition to which 
# it will be submitted (e.g. PARTITION_HPSS, PARTITION_FCST; see below), 
# it will be submitted to the partition specified by this variable.  If 
# this is not set or is set to an empty string, it will be (re)set to a 
# machine-dependent value.  This is not used if SCHED is not set to 
# "slurm".
#
# QUEUE_DEFAULT:
# The default queue or QOS (if using the slurm job scheduler, where QOS
# is Quality of Service) to which workflow tasks are submitted.  If a 
# task does not have a specific variable that specifies the queue to which 
# it will be submitted (e.g. QUEUE_HPSS, QUEUE_FCST; see below), it will 
# be submitted to the queue specified by this variable.  If this is not 
# set or is set to an empty string, it will be (re)set to a machine-
# dependent value.
#
# PARTITION_HPSS:
# If using the slurm job scheduler (i.e. if SCHED is set to "slurm"), 
# the partition to which the tasks that get or create links to external 
# model files [which are needed to generate initial conditions (ICs) and 
# lateral boundary conditions (LBCs)] are submitted.  If this is not set 
# or is set to an empty string, it will be (re)set to a machine-dependent 
# value.  This is not used if SCHED is not set to "slurm".
#
# QUEUE_HPSS:
# The queue or QOS to which the tasks that get or create links to external 
# model files [which are needed to generate initial conditions (ICs) and 
# lateral boundary conditions (LBCs)] are submitted.  If this is not set 
# or is set to an empty string, it will be (re)set to a machine-dependent 
# value.
#
# PARTITION_FCST:
# If using the slurm job scheduler (i.e. if SCHED is set to "slurm"), 
# the partition to which the task that runs forecasts is submitted.  If 
# this is not set or set to an empty string, it will be (re)set to a 
# machine-dependent value.  This is not used if SCHED is not set to 
# "slurm".
#
# QUEUE_FCST:
# The queue or QOS to which the task that runs a forecast is submitted.  
# If this is not set or set to an empty string, it will be (re)set to a 
# machine-dependent value.
#
# mach_doc_end
#
#-----------------------------------------------------------------------
#
MACHINE="BIG_COMPUTER"
ACCOUNT="project_name"
SCHED=""
PARTITION_DEFAULT=""
QUEUE_DEFAULT=""
PARTITION_HPSS=""
QUEUE_HPSS=""
PARTITION_FCST=""
QUEUE_FCST=""
#
#-----------------------------------------------------------------------
#
# Set cron-associated parameters.  Definitions:
#
# USE_CRON_TO_RELAUNCH:
# Flag that determines whether or not to add a line to the user's cron 
# table to call the experiment launch script every CRON_RELAUNCH_INTVL_MNTS 
# minutes.
#
# CRON_RELAUNCH_INTVL_MNTS:
# The interval (in minutes) between successive calls of the experiment
# launch script by a cron job to (re)launch the experiment (so that the
# workflow for the experiment kicks off where it left off).
#
#-----------------------------------------------------------------------
#
USE_CRON_TO_RELAUNCH="FALSE"
CRON_RELAUNCH_INTVL_MNTS="03"
#
#-----------------------------------------------------------------------
#
# dir_doc_start
# Set directories.  Definitions:
#
# EXPT_BASEDIR:
# The base directory in which the experiment directory will be created.  
# If this is not specified or if it is set to an empty string, it will
# default to ${HOMErrfs}/../expt_dirs.  
#
# EXPT_SUBDIR:
# The name that the experiment directory (without the full path) will
# have.  The full path to the experiment directory, which will be contained
# in the variable EXPTDIR, will be:
#
#   EXPTDIR="${EXPT_BASEDIR}/${EXPT_SUBDIR}"
#
# This cannot be empty.  If set to a null string here, it must be set to
# a (non-empty) value in the user-defined experiment configuration file.
#
# dir_doc_end
#
#-----------------------------------------------------------------------
#
EXPT_BASEDIR=""
EXPT_SUBDIR=""
#
#-----------------------------------------------------------------------
#
# Set variables that are only used in NCO mode (i.e. when RUN_ENVIR is 
# set to "nco").  Definitions:
#
# COMINgfs:
# The beginning portion of the directory containing files generated by 
# the external model (FV3GFS) that the initial and lateral boundary 
# condition generation tasks need in order to create initial and boundary
# condition files for a given cycle on the native FV3-LAM grid.  For a 
# cycle that starts on the date specified by the variable yyyymmdd 
# (consisting of the 4-digit year followed by the 2-digit month followed
# by the 2-digit day of the month) and hour specified by the variable hh
# (consisting of the 2-digit hour-of-day), the directory in which the 
# workflow will look for the external model files is:
#
#   $COMINgfs/gfs.$yyyymmdd/$hh
#
# FIXLAM_NCO_BASEDIR:
# The base directory containing pregenerated grid, orography, and surface 
# climatology files.  For the pregenerated grid specified by PREDEF_GRID_NAME, 
# these "fixed" files are located in:
#
#   ${FIXLAM_NCO_BASEDIR}/${PREDEF_GRID_NAME}
#
# The workflow scripts will create a symlink in the experiment directory
# that will point to a subdirectory (having the name of the grid being
# used) under this directory.  This variable should be set to a null 
# string in this file, but it can be specified in the user-specified 
# workflow configuration file (EXPT_CONFIG_FN).
#
# STMP:
# The beginning portion of the directory that will contain cycle-dependent
# model input files, symlinks to cycle-independent input files, and raw 
# (i.e. before post-processing) forecast output files for a given cycle.
# For a cycle that starts on the date specified by yyyymmdd and hour 
# specified by hh (where yyyymmdd and hh are as described above) [so that
# the cycle date (cdate) is given by cdate="${yyyymmdd}${hh}"], the 
# directory in which the aforementioned files will be located is:
#
#   $STMP/tmpnwprd/$RUN/$cdate
#
# NET, envir, RUN:
# Variables used in forming the path to the directory that will contain
# the output files from the post-processor (UPP) for a given cycle (see
# definition of PTMP below).  These are defined in the WCOSS Implementation
# Standards document as follows:
#
#   NET:
#   Model name (first level of com directory structure)
#
#   envir:
#   Set to "test" during the initial testing phase, "para" when running
#   in parallel (on a schedule), and "prod" in production.
#
#   RUN:
#   Name of model run (third level of com directory structure).
#
# PTMP:
# The beginning portion of the directory that will contain the output 
# files from the post-processor (UPP) for a given cycle.  For a cycle 
# that starts on the date specified by yyyymmdd and hour specified by hh
# (where yyyymmdd and hh are as described above), the directory in which
# the UPP output files will be placed will be:
# 
#   $PTMP/com/$NET/$envir/$RUN.$yyyymmdd/$hh
#
#-----------------------------------------------------------------------
#
COMINgfs="/base/path/of/directory/containing/gfs/input/files"
FIXLAM_NCO_BASEDIR=""
STMP="/base/path/of/directory/containing/model/input/and/raw/output/files"
NET="rrfs"
envir="para"
RUN="experiment_name"
PTMP="/base/path/of/directory/containing/postprocessed/output/files"
#
#-----------------------------------------------------------------------
#
# Set the sparator character(s) to use in the names of the grid, mosaic,
# and orography fixed files.
#
# Ideally, the same separator should be used in the names of these fixed
# files as the surface climatology fixed files (which always use a "."
# as the separator), i.e. ideally, DOT_OR_USCORE should be set to "."
#
#-----------------------------------------------------------------------
#
DOT_OR_USCORE="_"
#
#-----------------------------------------------------------------------
#
# Set file names.  Definitions:
#
# EXPT_CONFIG_FN:
# Name of the user-specified configuration file for the forecast experiment.
#
# RGNL_GRID_NML_FN:
# Name of file containing the namelist settings for the code that generates
# a "ESGgrid" type of regional grid.
#
# FV3_NML_BASE_SUITE_FN:
# Name of Fortran namelist file containing the forecast model's base suite
# namelist, i.e. the portion of the namelist that is common to all physics
# suites.
#
# FV3_NML_YAML_CONFIG_FN:
# Name of YAML configuration file containing the forecast model's namelist
# settings for various physics suites.
#
# FV3_NML_BASE_ENS_FN:
# Name of Fortran namelist file containing the forecast model's base 
# ensemble namelist, i.e. the the namelist file that is the starting point 
# from which the namelist files for each of the enesemble members are
# generated.
#
# DIAG_TABLE_FN:
# Name of file that specifies the fields that the forecast model will 
# output.
#
# FIELD_TABLE_FN:
# Name of file that specifies the tracers that the forecast model will
# read in from the IC/LBC files.
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
# FV3_EXEC_FN:
# Name to use for the forecast model executable when it is copied from
# the directory in which it is created in the build step to the executables
# directory (EXECDIR; this is set during experiment generation).
#
# WFLOW_XML_FN:
# Name of the rocoto workflow XML file that the experiment generation
# script creates and that defines the workflow for the experiment.
#
# GLOBAL_VAR_DEFNS_FN:
# Name of file (a shell script) containing the defintions of the primary 
# experiment variables (parameters) defined in this default configuration 
# script and in the user-specified configuration as well as secondary 
# experiment variables generated by the experiment generation script.  
# This file is sourced by many scripts (e.g. the J-job scripts corresponding 
# to each workflow task) in order to make all the experiment variables 
# available in those scripts.
#
# EXTRN_MDL_ICS_VAR_DEFNS_FN:
# Name of file (a shell script) containing the defintions of variables 
# associated with the external model from which ICs are generated.  This 
# file is created by the GET_EXTRN_ICS_TN task because the values of the
# variables it contains are not known before this task runs.  The file is
# then sourced by the MAKE_ICS_TN task.
#
# EXTRN_MDL_LBCS_VAR_DEFNS_FN:
# Name of file (a shell script) containing the defintions of variables 
# associated with the external model from which LBCs are generated.  This 
# file is created by the GET_EXTRN_LBCS_TN task because the values of the
# variables it contains are not known before this task runs.  The file is
# then sourced by the MAKE_ICS_TN task.
#
# WFLOW_LAUNCH_SCRIPT_FN:
# Name of the script that can be used to (re)launch the experiment's rocoto
# workflow.
#
# WFLOW_LAUNCH_LOG_FN:
# Name of the log file that contains the output from successive calls to
# the workflow launch script (WFLOW_LAUNCH_SCRIPT_FN).
#
#-----------------------------------------------------------------------
#
EXPT_CONFIG_FN="config.sh"

RGNL_GRID_NML_FN="regional_grid.nml"

DATA_TABLE_FN="data_table"
DIAG_TABLE_FN="diag_table"
FIELD_TABLE_FN="field_table"
FV3_NML_BASE_SUITE_FN="input.nml.FV3"
FV3_NML_YAML_CONFIG_FN="FV3.input.yml"
FV3_NML_BASE_ENS_FN="input.nml.base_ens"
MODEL_CONFIG_FN="model_configure"
NEMS_CONFIG_FN="nems.configure"
FV3_EXEC_FN="ufs_model"

WFLOW_XML_FN="FV3LAM_wflow.xml"
GLOBAL_VAR_DEFNS_FN="var_defns.sh"
EXTRN_MDL_ICS_VAR_DEFNS_FN="extrn_mdl_ics_var_defns.sh"
EXTRN_MDL_LBCS_VAR_DEFNS_FN="extrn_mdl_lbcs_var_defns.sh"
WFLOW_LAUNCH_SCRIPT_FN="launch_FV3LAM_wflow.sh"
WFLOW_LAUNCH_LOG_FN="log.launch_FV3LAM_wflow"
#
#-----------------------------------------------------------------------
#
# Set forecast parameters.  Definitions:
#
# DATE_FIRST_CYCL:
# Starting date of the first forecast in the set of forecasts to run.  
# Format is "YYYYMMDD".  Note that this does not include the hour-of-day.
#
# DATE_LAST_CYCL:
# Starting date of the last forecast in the set of forecasts to run.
# Format is "YYYYMMDD".  Note that this does not include the hour-of-day.
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
# Set initial and lateral boundary condition generation parameters.  
# Definitions:
#
# EXTRN_MDL_NAME_ICS:
#`The name of the external model that will provide fields from which 
# initial condition (including and surface) files will be generated for
# input into the forecast model.
#
# EXTRN_MDL_NAME_LBCS:
#`The name of the external model that will provide fields from which 
# lateral boundary condition (LBC) files will be generated for input into
# the forecast model.
#
# LBC_SPEC_INTVL_HRS:
# The interval (in integer hours) with which LBC files will be generated.
# We will refer to this as the boundary update interval.  Note that the
# model specified in EXTRN_MDL_NAME_LBCS must have data available at a
# frequency greater than or equal to that implied by LBC_SPEC_INTVL_HRS.
# For example, if LBC_SPEC_INTVL_HRS is set to 6, then the model must have
# data availble at least every 6 hours.  It is up to the user to ensure 
# that this is the case.
#
# FV3GFS_FILE_FMT_ICS:
# If using the FV3GFS model as the source of the ICs (i.e. if EXTRN_MDL_NAME_ICS
# is set to "FV3GFS"), this variable specifies the format of the model
# files to use when generating the ICs.
#
# FV3GFS_FILE_FMT_LBCS:
# If using the FV3GFS model as the source of the LBCs (i.e. if 
# EXTRN_MDL_NAME_LBCS is set to "FV3GFS"), this variable specifies the 
# format of the model files to use when generating the LBCs.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"
LBC_SPEC_INTVL_HRS="6"
FV3GFS_FILE_FMT_ICS="nemsio"
FV3GFS_FILE_FMT_LBCS="nemsio"
#
#-----------------------------------------------------------------------
#
# Set NOMADS online data associated parameters. Definitions:
#
# NOMADS:
# Flag controlling whether or not using NOMADS online data.
#
# NOMADS_file_type:
# Flag controlling the format of data.
#
#-----------------------------------------------------------------------
#
NOMADS="FALSE"
NOMADS_file_type="nemsio"
#
#-----------------------------------------------------------------------
#
# User-staged external model directories and files.  Definitions:
#
# USE_USER_STAGED_EXTRN_FILES:
# Flag that determines whether or not the workflow will look for the 
# external model files needed for generating ICs and LBCs in user-specified
# directories.
#
# EXTRN_MDL_SOURCE_BASEDIR_ICS:
# Directory in which to look for external model files for generating ICs.
# If USE_USER_STAGED_EXTRN_FILES is set to "TRUE", the workflow looks in 
# this directory (specifically, in a subdirectory under this directory 
# named "YYYYMMDDHH" consisting of the starting date and cycle hour of 
# the forecast, where YYYY is the 4-digit year, MM the 2-digit month, DD 
# the 2-digit day of the month, and HH the 2-digit hour of the day) for 
# the external model files specified by the array EXTRN_MDL_FILES_ICS 
# (these files will be used to generate the ICs on the native FV3-LAM 
# grid).  This variable is not used if USE_USER_STAGED_EXTRN_FILES is 
# set to "FALSE".
# 
# EXTRN_MDL_FILES_ICS:
# Array containing the names of the files to search for in the directory
# specified by EXTRN_MDL_SOURCE_BASEDIR_ICS.  This variable is not used
# if USE_USER_STAGED_EXTRN_FILES is set to "FALSE".
#
# EXTRN_MDL_SOURCE_BASEDIR_LBCS:
# Analogous to EXTRN_MDL_SOURCE_BASEDIR_ICS but for LBCs instead of ICs.
#
# EXTRN_MDL_FILES_LBCS:
# Analogous to EXTRN_MDL_FILES_ICS but for LBCs instead of ICs.
#
#-----------------------------------------------------------------------
#
USE_USER_STAGED_EXTRN_FILES="FALSE"
EXTRN_MDL_SOURCE_BASEDIR_ICS="/base/dir/containing/user/staged/extrn/mdl/files/for/ICs"
EXTRN_MDL_FILES_ICS=( "ICS_file1" "ICS_file2" "..." )
EXTRN_MDL_SOURCE_BASEDIR_LBCS="/base/dir/containing/user/staged/extrn/mdl/files/for/LBCs"
EXTRN_MDL_FILES_LBCS=( "LBCS_file1" "LBCS_file2" "..." )
#
#-----------------------------------------------------------------------
#
# Set CCPP-associated parameters.  Definitions:
#
# CCPP_PHYS_SUITE:
# The physics suite that will run using CCPP (Common Community Physics
# Package).  The choice of physics suite determines the forecast model's 
# namelist file, the diagnostics table file, the field table file, and 
# the XML physics suite definition file that are staged in the experiment 
# directory or the cycle directories under it.
#
#-----------------------------------------------------------------------
#
CCPP_PHYS_SUITE="FV3_GFS_v15p2"
#
#-----------------------------------------------------------------------
#
# Set GRID_GEN_METHOD.  This variable specifies the method to use to 
# generate a regional grid in the horizontal.  The values that it can 
# take on are:
#
# * "GFDLgrid":
#   This setting will generate a regional grid by first generating a 
#   "parent" global cubed-sphere grid and then taking a portion of tile
#   6 of that global grid -- referred to in the grid generation scripts
#   as "tile 7" even though it doesn't correspond to a complete tile --
#   and using it as the regional grid.  Note that the forecast is run on
#   only on the regional grid (i.e. tile 7, not tiles 1 through 6).
#
# * "ESGgrid":
#   This will generate a regional grid using the map projection developed
#   by Jim Purser of EMC.
#
# Note that:
#
# 1) If the experiment is using one of the predefined grids (i.e. if 
#    PREDEF_GRID_NAME is set to the name of one of the valid predefined 
#    grids), then GRID_GEN_METHOD will be reset to the value of 
#    GRID_GEN_METHOD for that grid.  This will happen regardless of 
#    whether or not GRID_GEN_METHOD is assigned a value in the user-
#    specified experiment configuration file, i.e. any value it may be
#    assigned in the experiment configuration file will be overwritten.
#
# 2) If the experiment is not using one of the predefined grids (i.e. if 
#    PREDEF_GRID_NAME is set to a null string), then GRID_GEN_METHOD must 
#    be set in the experiment configuration file.  Otherwise, it will 
#    remain set to a null string, and the experiment generation will 
#    fail because the generation scripts check to ensure that it is set 
#    to a non-empty string before creating the experiment directory.
#
#-----------------------------------------------------------------------
#
GRID_GEN_METHOD=""
#
#-----------------------------------------------------------------------
#
# Set parameters specific to the "GFDLgrid" method of generating a regional
# grid (i.e. for GRID_GEN_METHOD set to "GFDLgrid").  The following 
# parameters will be used only if GRID_GEN_METHOD is set to "GFDLgrid". 
# In this grid generation method:
#
# * The regional grid is defined with respect to a "parent" global cubed-
#   sphere grid.  Thus, all the parameters for a global cubed-sphere grid
#   must be specified in order to define this parent global grid even 
#   though the model equations are not integrated on (they are integrated
#   only on the regional grid).
#
# * GFDLgrid_RES is the number of grid cells in either one of the two 
#   horizontal directions x and y on any one of the 6 tiles of the parent
#   global cubed-sphere grid.  The mapping from GFDLgrid_RES to a nominal
#   resolution (grid cell size) for a uniform global grid (i.e. Schmidt
#   stretch factor GFDLgrid_STRETCH_FAC set to 1) for several values of
#   GFDLgrid_RES is as follows:
#
#     GFDLgrid_RES      typical cell size
#     ------------      -----------------
#              192                  50 km
#              384                  25 km
#              768                  13 km
#             1152                 8.5 km
#             3072                 3.2 km
#
#   Note that these are only typical cell sizes.  The actual cell size on
#   the global grid tiles varies somewhat as we move across a tile.
#
# * Tile 6 has arbitrarily been chosen as the tile to use to orient the
#   global parent grid on the sphere (Earth).  This is done by specifying 
#   GFDLgrid_LON_T6_CTR and GFDLgrid_LAT_T6_CTR, which are the longitude
#   and latitude (in degrees) of the center of tile 6.
#
# * Setting the Schmidt stretching factor GFDLgrid_STRETCH_FAC to a value
#   greater than 1 shrinks tile 6, while setting it to a value less than 
#   1 (but still greater than 0) expands it.  The remaining 5 tiles change
#   shape as necessary to maintain global coverage of the grid.
#
# * The cell size on a given global tile depends on both GFDLgrid_RES and
#   GFDLgrid_STRETCH_FAC (since changing GFDLgrid_RES changes the number
#   of cells in the tile, and changing GFDLgrid_STRETCH_FAC modifies the
#   shape and size of the tile).
#
# * The regional grid is embedded within tile 6 (i.e. it doesn't extend
#   beyond the boundary of tile 6).  Its exact location within tile 6 is
#   is determined by specifying the starting and ending i and j indices
#   of the regional grid on tile 6, where i is the grid index in the x
#   direction and j is the grid index in the y direction.  These indices
#   are stored in the variables 
#
#     GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G
#     GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G
#     GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G
#     GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G
#
# * In the forecast model code and in the experiment generation and workflow
#   scripts, for convenience the regional grid is denoted as "tile 7" even
#   though it doesn't map back to one of the 6 faces of the cube from 
#   which the parent global grid is generated (it maps back to only a 
#   subregion on face 6 since it is wholly confined within tile 6).  Tile
#   6 may be referred to as the "parent" tile of the regional grid.
#
# * GFDLgrid_REFINE_RATIO is the refinement ratio of the regional grid 
#   (tile 7) with respect to the grid on its parent tile (tile 6), i.e.
#   it is the number of grid cells along the boundary of the regional grid
#   that abut one cell on tile 6.  Thus, the cell size on the regional 
#   grid depends not only on GFDLgrid_RES and GFDLgrid_STRETCH_FAC (because
#   the cell size on tile 6 depends on these two parameters) but also on 
#   GFDLgrid_REFINE_RATIO.  Note that as on the tiles of the global grid, 
#   the cell size on the regional grid is not uniform but varies as we 
#   move across the grid.
#
# Definitions of parameters that need to be specified when GRID_GEN_METHOD
# is set to "GFDLgrid":
#
# GFDLgrid_LON_T6_CTR:
# Longitude of the center of tile 6 (in degrees).
#
# GFDLgrid_LAT_T6_CTR:
# Latitude of the center of tile 6 (in degrees).
#
# GFDLgrid_RES:
# Number of points in each of the two horizontal directions (x and y) on
# each tile of the parent global grid.  Note that the name of this parameter
# is really a misnomer because although it has the stirng "RES" (for 
# "resolution") in its name, it specifies number of grid cells, not grid
# size (in say meters or kilometers).  However, we keep this name in order
# to remain consistent with the usage of the word "resolution" in the 
# global forecast model and other auxiliary codes.
#
# GFDLgrid_STRETCH_FAC:
# Stretching factor used in the Schmidt transformation applied to the
# parent cubed-sphere grid.
#
# GFDLgrid_REFINE_RATIO:
# Cell refinement ratio for the regional grid, i.e. the number of cells
# in either the x or y direction on the regional grid (tile 7) that abut
# one cell on its parent tile (tile 6).
#
# GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G:
# i-index on tile 6 at which the regional grid (tile 7) starts.
#
# GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G:
# i-index on tile 6 at which the regional grid (tile 7) ends.
#
# GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G:
# j-index on tile 6 at which the regional grid (tile 7) starts.
#
# GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G:
# j-index on tile 6 at which the regional grid (tile 7) ends.
#
# GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES:
# Flag that determines the file naming convention to use for grid, orography,
# and surface climatology files (or, if using pregenerated files, the
# naming convention that was used to name these files).  These files 
# usually start with the string "C${RES}_", where RES is an integer.
# In the global forecast model, RES is the number of points in each of
# the two horizontal directions (x and y) on each tile of the global grid
# (defined here as GFDLgrid_RES).  If this flag is set to "TRUE", RES will
# be set to GFDLgrid_RES just as in the global forecast model.  If it is
# set to "FALSE", we calculate (in the grid generation task) an "equivalent
# global uniform cubed-sphere resolution" -- call it RES_EQUIV -- and 
# then set RES equal to it.  RES_EQUIV is the number of grid points in 
# each of the x and y directions on each tile that a global UNIFORM (i.e. 
# stretch factor of 1) cubed-sphere grid would have to have in order to
# have the same average grid size as the regional grid.  This is a more
# useful indicator of the grid size because it takes into account the 
# effects of GFDLgrid_RES, GFDLgrid_STRETCH_FAC, and GFDLgrid_REFINE_RATIO
# in determining the regional grid's typical grid size, whereas simply
# setting RES to GFDLgrid_RES doesn't take into account the effects of
# GFDLgrid_STRETCH_FAC and GFDLgrid_REFINE_RATIO on the regional grid's
# resolution.  Nevertheless, some users still prefer to use GFDLgrid_RES
# in the file names, so we allow for that here by setting this flag to
# "TRUE".
#
# Note that:
#
# 1) If the experiment is using one of the predefined grids (i.e. if 
#    PREDEF_GRID_NAME is set to the name of one of the valid predefined
#    grids), then:
#
#    a) If the value of GRID_GEN_METHOD for that grid is "GFDLgrid", then
#       these parameters will get reset to the values for that grid.  
#       This will happen regardless of whether or not they are assigned 
#       values in the user-specified experiment configuration file, i.e. 
#       any values they may be assigned in the experiment configuration 
#       file will be overwritten.
#
#    b) If the value of GRID_GEN_METHOD for that grid is "ESGgrid", then
#       these parameters will not be used and thus do not need to be reset
#       to non-empty strings.
#
# 2) If the experiment is not using one of the predefined grids (i.e. if 
#    PREDEF_GRID_NAME is set to a null string), then:
#
#    a) If GRID_GEN_METHOD is set to "GFDLgrid" in the user-specified 
#       experiment configuration file, then these parameters must be set
#       in that configuration file.
#
#    b) If GRID_GEN_METHOD is set to "ESGgrid" in the user-specified 
#       experiment configuration file, then these parameters will not be 
#       used and thus do not need to be reset to non-empty strings.
#
#-----------------------------------------------------------------------
#
GFDLgrid_LON_T6_CTR=""
GFDLgrid_LAT_T6_CTR=""
GFDLgrid_RES=""
GFDLgrid_STRETCH_FAC=""
GFDLgrid_REFINE_RATIO=""
GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G=""
GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G=""
GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G=""
GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G=""
GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES=""
#
#-----------------------------------------------------------------------
#
# Set parameters specific to the "ESGgrid" method of generating a regional
# grid (i.e. for GRID_GEN_METHOD set to "ESGgrid").  Definitions:
#
# ESGgrid_LON_CTR:
# The longitude of the center of the grid (in degrees).
#
# ESGgrid_LAT_CTR:
# The latitude of the center of the grid (in degrees).
#
# ESGgrid_DELX:
# The cell size in the zonal direction of the regional grid (in meters).
#
# ESGgrid_DELY:
# The cell size in the meridional direction of the regional grid (in 
# meters).
#
# ESGgrid_NX:
# The number of cells in the zonal direction on the regional grid.
#
# ESGgrid_NY:
# The number of cells in the meridional direction on the regional grid.
#
# ESGgrid_WIDE_HALO_WIDTH:
# The width (in units of number of grid cells) of the halo to add around
# the regional grid before shaving the halo down to the width(s) expected
# by the forecast model.  
#
# In order to generate grid files containing halos that are 3-cell and
# 4-cell wide and orography files with halos that are 0-cell and 3-cell
# wide (all of which are required as inputs to the forecast model), the
# grid and orography tasks first create files with halos around the regional
# domain of width ESGgrid_WIDE_HALO_WIDTH cells.  These are first stored 
# in files.  The files are then read in and "shaved" down to obtain grid
# files with 3-cell-wide and 4-cell-wide halos and orography files with
# 0-cell-wide (i.e. no halo) and 3-cell-wide halos.  For this reason, we
# refer to the original halo that then gets shaved down as the "wide" 
# halo, i.e. because it is wider than the 0-cell-wide, 3-cell-wide, and
# 4-cell-wide halos that we will eventually end up with.  Note that the
# grid and orography files with the wide halo are only needed as intermediates
# in generating the files with 0-cell-, 3-cell-, and 4-cell-wide halos;
# they are not needed by the forecast model.  
# NOTE: Probably don't need to make ESGgrid_WIDE_HALO_WIDTH a user-specified 
#       variable.  Just set it in the function set_gridparams_ESGgrid.sh.
#
# Note that:
#
# 1) If the experiment is using one of the predefined grids (i.e. if 
#    PREDEF_GRID_NAME is set to the name of one of the valid predefined
#    grids), then:
#
#    a) If the value of GRID_GEN_METHOD for that grid is "GFDLgrid", then
#       these parameters will not be used and thus do not need to be reset
#       to non-empty strings.
#
#    b) If the value of GRID_GEN_METHOD for that grid is "ESGgrid", then
#       these parameters will get reset to the values for that grid.  
#       This will happen regardless of whether or not they are assigned 
#       values in the user-specified experiment configuration file, i.e. 
#       any values they may be assigned in the experiment configuration 
#       file will be overwritten.
#
# 2) If the experiment is not using one of the predefined grids (i.e. if 
#    PREDEF_GRID_NAME is set to a null string), then:
#
#    a) If GRID_GEN_METHOD is set to "GFDLgrid" in the user-specified 
#       experiment configuration file, then these parameters will not be 
#       used and thus do not need to be reset to non-empty strings.
#
#    b) If GRID_GEN_METHOD is set to "ESGgrid" in the user-specified 
#       experiment configuration file, then these parameters must be set
#       in that configuration file.
#
#-----------------------------------------------------------------------
#
ESGgrid_LON_CTR=""
ESGgrid_LAT_CTR=""
ESGgrid_DELX=""
ESGgrid_DELY=""
ESGgrid_NX=""
ESGgrid_NY=""
ESGgrid_WIDE_HALO_WIDTH=""
#
#-----------------------------------------------------------------------
#
# Set computational parameters for the forecast.  Definitions:
#
# DT_ATMOS:
# The main forecast model integraton time step.  As described in the 
# forecast model documentation, "It corresponds to the frequency with 
# which the top level routine in the dynamics is called as well as the 
# frequency with which the physics is called."
#
# LAYOUT_X, LAYOUT_Y:
# The number of MPI tasks (processes) to use in the two horizontal 
# directions (x and y) of the regional grid when running the forecast 
# model.
#
# BLOCKSIZE:
# The amount of data that is passed into the cache at a time.
#
# Here, we set these parameters to null strings.  This is so that, for 
# any one of these parameters:
#
# 1) If the experiment is using a predefined grid, then if the user 
#    sets the parameter in the user-specified experiment configuration 
#    file (EXPT_CONFIG_FN), that value will be used in the forecast(s).
#    Otherwise, the default value of the parameter for that predefined 
#    grid will be used.
#
# 2) If the experiment is not using a predefined grid (i.e. it is using
#    a custom grid whose parameters are specified in the experiment 
#    configuration file), then the user must specify a value for the 
#    parameter in that configuration file.  Otherwise, the parameter 
#    will remain set to a null string, and the experiment generation 
#    will fail because the generation scripts check to ensure that all 
#    the parameters defined in this section are set to non-empty strings
#    before creating the experiment directory.
#
#-----------------------------------------------------------------------
#
DT_ATMOS=""
LAYOUT_X=""
LAYOUT_Y=""
BLOCKSIZE=""
#
#-----------------------------------------------------------------------
#
# Set write-component (quilting) parameters.  Definitions:
#
# QUILTING:
# Flag that determines whether or not to use the write component for 
# writing output files to disk.
#
# WRTCMP_write_groups:
# The number of write groups (i.e. groups of MPI tasks) to use in the
# write component.
#
# WRTCMP_write_tasks_per_group:
# The number of MPI tasks to allocate for each write group.
#
# PRINT_ESMF:
# Flag for whether or not to output extra (debugging) information from
# ESMF routines.  Must be "TRUE" or "FALSE".  Note that the write
# component uses ESMF library routines to interpolate from the native
# forecast model grid to the user-specified output grid (which is defined 
# in the model configuration file MODEL_CONFIG_FN in the forecast's run 
# directory).
#
#-----------------------------------------------------------------------
#
QUILTING="TRUE"
PRINT_ESMF="FALSE"

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
WRTCMP_stdlat1=""
WRTCMP_stdlat2=""
WRTCMP_nx=""
WRTCMP_ny=""
WRTCMP_dx=""
WRTCMP_dy=""
#
#-----------------------------------------------------------------------
#
# Set PREDEF_GRID_NAME.  This parameter specifies a predefined regional
# grid, as follows:
#
# * If PREDEF_GRID_NAME is set to a valid predefined grid name, the grid 
#   generation method GRID_GEN_METHOD, the (native) grid parameters, and 
#   the write-component grid parameters are set to predefined values for 
#   the specified grid, overwriting any settings of these parameters in 
#   the user-specified experiment configuration file.  In addition, if 
#   the time step DT_ATMOS and the computational parameters LAYOUT_X, 
#   LAYOUT_Y, and BLOCKSIZE are not specified in that configuration file, 
#   they are also set to predefined values for the specified grid.
#
# * If PREDEF_GRID_NAME is set to an empty string, it implies the user
#   is providing the native grid parameters in the user-specified 
#   experiment configuration file (EXPT_CONFIG_FN).  In this case, the 
#   grid generation method GRID_GEN_METHOD, the native grid parameters, 
#   and the write-component grid parameters as well as the time step 
#   forecast model's main time step DT_ATMOS and the computational 
#   parameters LAYOUT_X, LAYOUT_Y, and BLOCKSIZE must be set in that 
#   configuration file; otherwise, the values of all of these parameters 
#   in this default experiment configuration file will be used.
#
# Setting PREDEF_GRID_NAME provides a convenient method of specifying a
# commonly used set of grid-dependent parameters.  The predefined grid 
# parameters are specified in the script 
#
#   $HOMErrfs/ush/set_predef_grid_params.sh
#
#-----------------------------------------------------------------------
#
PREDEF_GRID_NAME=""
#
#-----------------------------------------------------------------------
#
# Set PREEXISTING_DIR_METHOD.  This variable determines the method to use
# use to deal with preexisting directories [e.g ones generated by previous
# calls to the experiment generation script using the same experiment name
# (EXPT_SUBDIR) as the current experiment].  This variable must be set to
# one of "delete", "rename", and "quit".  The resulting behavior for each
# of these values is as follows:
#
# * "delete":
#   The preexisting directory is deleted and a new directory (having the
#   same name as the original preexisting directory) is created.
#
# * "rename":
#   The preexisting directory is renamed and a new directory (having the
#   same name as the original preexisting directory) is created.  The new
#   name of the preexisting directory consists of its original name and
#   the suffix "_oldNNN", where NNN is a 3-digit integer chosen to make
#   the new name unique.
#
# * "quit":
#   The preexisting directory is left unchanged, but execution of the
#   currently running script is terminated.  In this case, the preexisting
#   directory must be dealt with manually before rerunning the script.
#
#-----------------------------------------------------------------------
#
PREEXISTING_DIR_METHOD="delete"
#
#-----------------------------------------------------------------------
#
# Set VERBOSE.  This is a flag that determines whether or not the experiment
# generation and workflow task scripts tend to be print out more informational
# messages.
#
#-----------------------------------------------------------------------
#
VERBOSE="TRUE"
#
#-----------------------------------------------------------------------
#
# Set flags (and related directories) that determine whether the grid, 
# orography, and/or surface climatology file generation tasks should be
# run.  Note that these are all cycle-independent tasks, i.e. if they are
# to be run, they do so only once at the beginning of the workflow before
# any cycles are run.  Definitions:
#
# RUN_TASK_MAKE_GRID:
# Flag that determines whether the grid file generation task is to be run.
# If this is set to "TRUE", the grid generation task is run and new grid
# files are generated.  If it is set to "FALSE", then the scripts look 
# for pregenerated grid files in the directory specified by GRID_DIR (see
# below).
#
# GRID_DIR:
# The directory in which to look for pregenerated grid files if 
# RUN_TASK_MAKE_GRID is set to "FALSE".
# 
# RUN_TASK_MAKE_OROG:
# Same as RUN_TASK_MAKE_GRID but for the orography generation task.
#
# OROG_DIR:
# Same as GRID_DIR but for the orogrpahy generation task.
# 
# RUN_TASK_MAKE_SFC_CLIMO:
# Same as RUN_TASK_MAKE_GRID but for the surface climatology generation
# task.
#
# SFC_CLIMO_DIR:
# Same as GRID_DIR but for the surface climatology generation task.
# 
#-----------------------------------------------------------------------
#
RUN_TASK_MAKE_GRID="TRUE"
GRID_DIR="/path/to/pregenerated/grid/files"

RUN_TASK_MAKE_OROG="TRUE"
OROG_DIR="/path/to/pregenerated/orog/files"

RUN_TASK_MAKE_SFC_CLIMO="TRUE"
SFC_CLIMO_DIR="/path/to/pregenerated/surface/climo/files"
#
#-----------------------------------------------------------------------
#
# Set the array parameter containing the names of all the fields that the
# MAKE_SFC_CLIMO_TN task generates on the native FV3-LAM grid.
#
#-----------------------------------------------------------------------
#
SFC_CLIMO_FIELDS=( \
"facsf" \
"maximum_snow_albedo" \
"slope_type" \
"snowfree_albedo" \
"soil_type" \
"substrate_temperature" \
"vegetation_greenness" \
"vegetation_type" \
)
#
#-----------------------------------------------------------------------
#
# Set parameters associated with the fixed (i.e. static) files.  Definitions:
#
# FIXgsm:
# System directory in which the majority of fixed (i.e. time-independent) 
# files that are needed to run the FV3-LAM model are located
#
# TOPO_DIR:
# The location on disk of the static input files used by the make_orog
# task (orog.x and shave.x). Can be the same as FIXgsm.
#
# SFC_CLIMO_INPUT_DIR:
# The location on disk of the static surface climatology input fields, used by 
# sfc_climo_gen. These files are only used if RUN_TASK_MAKE_SFC_CLIMO=TRUE
#
# FNGLAC, ..., FNMSKH:
# Names of (some of the) global data files that are assumed to exist in 
# a system directory specified (this directory is machine-dependent; 
# the experiment generation scripts will set it and store it in the 
# variable FIXgsm).  These file names also appear directly in the forecast 
# model's input namelist file.
#
# FIXgsm_FILES_TO_COPY_TO_FIXam:
# If not running in NCO mode, this array contains the names of the files
# to copy from the FIXgsm system directory to the FIXam directory under
# the experiment directory.  Note that the last element has a dummy value.
# This last element will get reset by the workflow generation scripts to
# the name of the ozone production/loss file to copy from FIXgsm.  The
# name of this file depends on the ozone parameterization being used, 
# and that in turn depends on the CCPP physics suite specified for the 
# experiment.  Thus, the CCPP physics suite XML must first be read in to
# determine the ozone parameterizaton and then the name of the ozone 
# production/loss file.  These steps are carried out elsewhere (in one 
# of the workflow generation scripts/functions).
#
# FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING:
# This array is used to set some of the namelist variables in the forecast 
# model's namelist file that represent the relative or absolute paths of 
# various fixed files (the first column of the array, where columns are 
# delineated by the pipe symbol "|") to the full paths to these files in 
# the FIXam directory derived from the corresponding workflow variables 
# containing file names (the second column of the array).
#
# FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING:
# This array is used to set some of the namelist variables in the forecast 
# model's namelist file that represent the relative or absolute paths of 
# various fixed files (the first column of the array, where columns are 
# delineated by the pipe symbol "|") to the full paths to surface climatology 
# files (on the native FV3-LAM grid) in the FIXLAM directory derived from 
# the corresponding surface climatology fields (the second column of the 
# array).
#
# CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING:
# This array specifies the mapping to use between the symlinks that need
# to be created in each cycle directory (these are the "files" that FV3
# looks for) and their targets in the FIXam directory.  The first column
# of the array specifies the symlink to be created, and the second column
# specifies its target file in FIXam (where columns are delineated by the
# pipe symbol "|").
#
#-----------------------------------------------------------------------
#
# Because the default values are dependent on the platform, we set these
# to a null string which will then be overwritten in setup.sh unless the
# user has specified a different value in config.sh
FIXgsm=""
TOPO_DIR=""
SFC_CLIMO_INPUT_DIR=""

FNGLAC="global_glacier.2x2.grb"
FNMXIC="global_maxice.2x2.grb"
FNTSFC="RTGSST.1982.2012.monthly.clim.grb"
FNSNOC="global_snoclim.1.875.grb"
FNZORC="igbp"
FNAISC="CFSR.SEAICE.1982.2012.monthly.clim.grb"
FNSMCC="global_soilmgldas.t126.384.190.grb"
FNMSKH="seaice_newland.grb"

FIXgsm_FILES_TO_COPY_TO_FIXam=( \
"$FNGLAC" \
"$FNMXIC" \
"$FNTSFC" \
"$FNSNOC" \
"$FNAISC" \
"$FNSMCC" \
"$FNMSKH" \
"global_climaeropac_global.txt" \
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
"global_h2o_pltc.f77" \
"global_hyblev.l65.txt" \
"global_zorclim.1x1.grb" \
"global_sfc_emissivity_idx.txt" \
"global_solarconstant_noaa_an.txt" \
"replace_with_FIXgsm_ozone_prodloss_filename" \
)

#
# It is possible to remove this as a workflow variable and make it only
# a local one since it is used in only one script.
#
FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING=( \
"FNGLAC | $FNGLAC" \
"FNMXIC | $FNMXIC" \
"FNTSFC | $FNTSFC" \
"FNSNOC | $FNSNOC" \
"FNAISC | $FNAISC" \
"FNSMCC | $FNSMCC" \
"FNMSKH | $FNMSKH" \
)
#"FNZORC | $FNZORC" \

FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING=( \
"FNALBC  | snowfree_albedo" \
"FNALBC2 | facsf" \
"FNTG3C  | substrate_temperature" \
"FNVEGC  | vegetation_greenness" \
"FNVETC  | vegetation_type" \
"FNSOTC  | soil_type" \
"FNVMNC  | vegetation_greenness" \
"FNVMXC  | vegetation_greenness" \
"FNSLPC  | slope_type" \
"FNABSC  | maximum_snow_albedo" \
)

CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING=( \
"aerosol.dat                | global_climaeropac_global.txt" \
"co2historicaldata_2010.txt | fix_co2_proj/global_co2historicaldata_2010.txt" \
"co2historicaldata_2011.txt | fix_co2_proj/global_co2historicaldata_2011.txt" \
"co2historicaldata_2012.txt | fix_co2_proj/global_co2historicaldata_2012.txt" \
"co2historicaldata_2013.txt | fix_co2_proj/global_co2historicaldata_2013.txt" \
"co2historicaldata_2014.txt | fix_co2_proj/global_co2historicaldata_2014.txt" \
"co2historicaldata_2015.txt | fix_co2_proj/global_co2historicaldata_2015.txt" \
"co2historicaldata_2016.txt | fix_co2_proj/global_co2historicaldata_2016.txt" \
"co2historicaldata_2017.txt | fix_co2_proj/global_co2historicaldata_2017.txt" \
"co2historicaldata_2018.txt | fix_co2_proj/global_co2historicaldata_2018.txt" \
"co2historicaldata_glob.txt | global_co2historicaldata_glob.txt" \
"co2monthlycyc.txt          | co2monthlycyc.txt" \
"global_h2oprdlos.f77       | global_h2o_pltc.f77" \
"global_zorclim.1x1.grb     | global_zorclim.1x1.grb" \
"sfc_emissivity_idx.txt     | global_sfc_emissivity_idx.txt" \
"solarconstant_noaa_an.txt  | global_solarconstant_noaa_an.txt" \
"global_o3prdlos.f77        | " \
)
#
#-----------------------------------------------------------------------
#
# Set the names of the various workflow tasks.  Then, for each task, set
# the parameters to pass to the job scheduler (e.g. slurm) that will submit
# a job for each task to be run.  These parameters include the number of
# nodes to use to run the job, the MPI processes per node, the maximum
# walltime to allow for the job to complete, and the maximum number of
# times to attempt to run each task.
#
#-----------------------------------------------------------------------
#
# Task names.
#
MAKE_GRID_TN="make_grid"
MAKE_OROG_TN="make_orog"
MAKE_SFC_CLIMO_TN="make_sfc_climo"
GET_EXTRN_ICS_TN="get_extrn_ics"
GET_EXTRN_LBCS_TN="get_extrn_lbcs"
MAKE_ICS_TN="make_ics"
MAKE_LBCS_TN="make_lbcs"
RUN_FCST_TN="run_fcst"
RUN_POST_TN="run_post"
#
# Number of nodes.
#
NNODES_MAKE_GRID="1"
NNODES_MAKE_OROG="1"
NNODES_MAKE_SFC_CLIMO="2"
NNODES_GET_EXTRN_ICS="1"
NNODES_GET_EXTRN_LBCS="1"
NNODES_MAKE_ICS="4"
NNODES_MAKE_LBCS="4"
NNODES_RUN_FCST=""  # This is calculated in the workflow generation scripts, so no need to set here.
NNODES_RUN_POST="2"
#
# Number of MPI processes per node.
#
PPN_MAKE_GRID="24"
PPN_MAKE_OROG="24"
PPN_MAKE_SFC_CLIMO="24"
PPN_GET_EXTRN_ICS="1"
PPN_GET_EXTRN_LBCS="1"
PPN_MAKE_ICS="12"
PPN_MAKE_LBCS="12"
PPN_RUN_FCST="24"  # This may have to be changed depending on the number of threads used.
PPN_RUN_POST="24"
#
# Walltimes.
#
WTIME_MAKE_GRID="00:20:00"
WTIME_MAKE_OROG="00:20:00"
WTIME_MAKE_SFC_CLIMO="00:20:00"
WTIME_GET_EXTRN_ICS="00:45:00"
WTIME_GET_EXTRN_LBCS="00:45:00"
WTIME_MAKE_ICS="00:30:00"
WTIME_MAKE_LBCS="00:30:00"
WTIME_RUN_FCST="04:30:00"
WTIME_RUN_POST="00:15:00"
#
# Maximum number of attempts.
#
MAXTRIES_MAKE_GRID="1"
MAXTRIES_MAKE_OROG="1"
MAXTRIES_MAKE_SFC_CLIMO="1"
MAXTRIES_GET_EXTRN_ICS="1"
MAXTRIES_GET_EXTRN_LBCS="1"
MAXTRIES_MAKE_ICS="1"
MAXTRIES_MAKE_LBCS="1"
MAXTRIES_RUN_FCST="1"
MAXTRIES_RUN_POST="1"
#
#-----------------------------------------------------------------------
#
# Set parameters associated with defining a customized post configuration 
# file.
#
# USE_CUSTOM_POST_CONFIG_FILE:
# Flag that determines whether a user-provided custom configuration file
# should be used for post-processing the model data. If this is set to
# "TRUE", then the workflow will use the custom post-processing (UPP) 
# configuration file specified in CUSTOM_POST_CONFIG_FP. Otherwise, a 
# default configuration file provided in the EMC_post repository will be 
# used.
#
# CUSTOM_POST_CONFIG_FP:
# The full path to the custom post flat file, including filename, to be 
# used for post-processing. This is only used if CUSTOM_POST_CONFIG_FILE
# is set to "TRUE".
#
#-----------------------------------------------------------------------
#
USE_CUSTOM_POST_CONFIG_FILE="FALSE"
CUSTOM_POST_CONFIG_FP=""
#
#-----------------------------------------------------------------------
#
# Set parameters associated with running ensembles.  Definitions:
#
# DO_ENSEMBLE:
# Flag that determines whether to run a set of ensemble forecasts (for
# each set of specified cycles).  If this is set to "TRUE", NUM_ENS_MEMBERS
# forecasts are run for each cycle, each with a different set of stochastic
# seed values.  Otherwise, a single forecast is run for each cycle.
#
# NUM_ENS_MEMBERS:
# The number of ensemble members to run if DO_ENSEMBLE is set to "TRUE".
# This variable also controls the naming of the ensemble member directories.  
# For example, if this is set to "8", the member directories will be named 
# mem1, mem2, ..., mem8.  If it is set to "08" (note the leading zero), 
# the member directories will be named mem01, mem02, ..., mem08.  Note, 
# however, that after reading in the number of characters in this string
# (in order to determine how many leading zeros, if any, should be placed
# in the names of the member directories), the workflow generation scripts
# strip away those leading zeros.  Thus, in the variable definitions file 
# (GLOBAL_VAR_DEFNS_FN), this variable appear with its leading zeros 
# stripped.  This variable is not used if DO_ENSEMBLE is not set to "TRUE".
# 
#-----------------------------------------------------------------------
#
DO_ENSEMBLE="FALSE"
NUM_ENS_MEMBERS="1"
#
#-----------------------------------------------------------------------
#
# Set default ad-hoc stochastic physics options.
# For detailed documentation of these parameters, see:
# https://stochastic-physics.readthedocs.io/en/ufs_public_release/namelist_options.html
#
#-----------------------------------------------------------------------
#
DO_SHUM="false"
DO_SPPT="false"
DO_SKEB="false"
SHUM_MAG="0.006" #Variable "shum" in input.nml
SHUM_LSCALE="150000"
SHUM_TSCALE="21600" #Variable "shum_tau" in input.nml
SHUM_INT="3600" #Variable "shumint" in input.nml
SPPT_MAG="1.0" #Variable "sppt" in input.nml
SPPT_LSCALE="150000"
SPPT_TSCALE="21600" #Variable "sppt_tau" in input.nml
SPPT_INT="3600" #Variable "spptint" in input.nml
SKEB_MAG="0.5" #Variable "skeb" in input.nml
SKEB_LSCALE="150000"
SKEB_TSCALE="21600" #Variable "skeb_tau" in input.nml
SKEB_INT="3600" #Variable "skebint" in input.nml
SKEB_VDOF="10"
USE_ZMTNBLCK="false"
#
#-----------------------------------------------------------------------
#
# Set default SPP stochastic physics options.
# Each SPP option is an array, applicable (in order) to the scheme/parameter
# listed in SPP_VAR_LIST. Enter each value of the array in config.sh as 
# shown below without commas or single quotes (e.g., SPP_VAR_LIST=
# ( "pbl" "lsm" "mp" ). Both commas and single quotes will be added by
# Jinja when creating the namelist.
#
# Note that SPP is currently only available for specific physics schemes 
# used in the RAP/HRRR physics suite.  Users need to be aware of which SDF
# is chosen when turning this option on. 
#
#-----------------------------------------------------------------------
#
DO_SPP="false"
SPP_VAR_LIST=( "pbl" )
SPP_MAG_LIST=( "0.2" ) #Variable "spp_prt_list" in input.nml
SPP_LSCALE=( "150000.0" )
SPP_TSCALE=( "21600.0" ) #Variable "spp_tau" in input.nml
SPP_SIGTOP1=( "0.1" )
SPP_SIGTOP2=( "0.025" )
SPP_STDDEV_CUTOFF=( "1.5" )
#
#-----------------------------------------------------------------------
# 
# HALO_BLEND:
# Number of rows into the computational domain that should be blended 
# with the LBCs.  To shut halo blending off, this can be set to zero.
#
#-----------------------------------------------------------------------
#
HALO_BLEND=10
#
#-----------------------------------------------------------------------
#
# USE_FVCOM:
# Flag set to update surface conditions in FV3-LAM with fields generated
# from the Finite Volume Community Ocean Model (FVCOM). This will
# replace lake/sea surface temperature, ice surface temperature, and ice
# placement. FVCOM data must already be interpolated to the desired
# FV3-LAM grid. This flag will be used in make_ics to modify sfc_data.nc
# after chgres_cube is run by running the routine process_FVCOM.exe
#
# FVCOM_DIR:
# User defined directory where FVCOM data already interpolated to FV3-LAM
# grid is located. File name in this path should be "fvcom.nc" to allow
#
# FVCOM_FILE:
# Name of file located in FVCOM_DIR that has FVCOM data interpolated to 
# FV3-LAM grid. This file will be copied later to a new location and name
# changed to fvcom.nc
#
#------------------------------------------------------------------------
#
USE_FVCOM="FALSE"
FVCOM_DIR="/user/defined/dir/to/fvcom/data"
FVCOM_FILE="fvcom.nc"
#
#-----------------------------------------------------------------------
#
# COMPILER:
# Type of compiler invoked during the build step. 
#
#------------------------------------------------------------------------
#
COMPILER="intel"
#
#-----------------------------------------------------------------------
#
# GWD_HRRRsuite_BASEDIR:
# Temporary workflow variable specifies the base directory in which to 
# look for certain fixed orography statistics files needed only by the 
# gravity wave drag parameterization in the FV3_HRRR physics suite.  This 
# variable is added in order to avoid including hard-coded paths in the 
# workflow scripts.  Currently, the workflow simply copies the necessary 
# files from a subdirectory under this directory (named according to the 
# specified predefined grid) to the orography directory (OROG_DIR) under 
# the experiment directory.  
#
# Note that this variable is only used when using the FV3_HRRR physics 
# suite.  It should be removed from the workflow once there is a script 
# or code available that generates these files for any grid.
#
#-----------------------------------------------------------------------
#
GWD_HRRRsuite_BASEDIR=""

