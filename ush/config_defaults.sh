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
#   January 19, 2022
#   Version 11.0.0
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
# Machine on which the workflow will run. If you are NOT on a named,
# supported platform, and you want to use the Rocoto workflow manager,
# you will need set MACHINE="linux" and WORKFLOW_MANAGER="rocoto". This
# combination will assume a Slurm batch manager when generating the XML.
# Please see ush/valid_param_vals.sh for a full list of supported
# platforms.
#
# MACHINE_FILE:
# Path to a configuration file with machine-specific settings. If none
# is provided, setup.sh will attempt to set the path to for a supported
# platform.
#
# ACCOUNT:
# The account under which to submit jobs to the queue.
#
# WORKFLOW_MANAGER:
# The workflow manager to use (e.g. rocoto). This is set to "none" by
# default, but if the machine name is set to a platform that supports
# rocoto, this will be overwritten and set to "rocoto". If set
# explicitly to rocoto along with the use of the MACHINE=linux target,
# the configuration layer assumes a Slurm batch manager when generating
# the XML. Valid options: "rocoto" or "none"
#
# NCORES_PER_NODE:
# The number of cores available per node on the compute platform. Set
# for supported platforms in setup.sh, but is now also configurable for
# all platforms.
#
# LMOD_PATH:
# Path to the LMOD sh file on your Linux system. Is set automatically
# for supported machines.
#
# BUILD_MOD_FN:
# Name of build module file to load before running a workflow task.  If 
# this is not specified by the user in the experiment configuration file 
# (EXPT_CONFIG_FN), it will be set automatically for supported machines.
#
# WFLOW_MOD_FN:
# Name of workflow module file to load before (re)launching the experiment's
# ROCOTO workflow (using the "rocotorun" command).  If this is not specified 
# by the user in the experiment configuration file (EXPT_CONFIG_FN), it 
# will be set automatically for supported machines.
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
MACHINE_FILE=""
ACCOUNT="project_name"
WORKFLOW_MANAGER="none"
NCORES_PER_NODE=""
LMOD_PATH=""
BUILD_MOD_FN=""
WFLOW_MOD_FN=""
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
# Set run commands for platforms without a workflow manager. These values
# will be ignored unless WORKFLOW_MANAGER="none".  Definitions:
#
# RUN_CMD_UTILS:
# The run command for pre-processing utilities (shave, orog, sfc_climo_gen, 
# etc.) Can be left blank for smaller domains, in which case the executables 
# will run without MPI.
#
# RUN_CMD_FCST:
# The run command for the model forecast step. This will be appended to 
# the end of the variable definitions file, so it can reference other 
# variables.
#
# RUN_CMD_POST:
# The run command for post-processing (UPP). Can be left blank for smaller 
# domains, in which case UPP will run without MPI.
#
#-----------------------------------------------------------------------
#
RUN_CMD_UTILS="mpirun -np 1"
RUN_CMD_FCST='mpirun -np \${PE_MEMBER01}'
RUN_CMD_POST="mpirun -np 1"
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
# EXEC_SUBDIR:
# The name of the subdirectory of ufs-srweather-app where executables are
# installed.
#-----------------------------------------------------------------------
#
EXPT_BASEDIR=""
EXPT_SUBDIR=""
EXEC_SUBDIR="bin"
#
#-----------------------------------------------------------------------
#
# Set variables that are only used in NCO mode (i.e. when RUN_ENVIR is 
# set to "nco").  Definitions:
#
# COMIN:
# Directory containing files generated by the external model (FV3GFS, NAM,
# HRRR, etc) that the initial and lateral boundary condition generation tasks 
# need in order to create initial and boundary condition files for a given 
# cycle on the native FV3-LAM grid.
#
# envir, NET, model_ver, RUN:
# Standard environment variables defined in the NCEP Central Operations WCOSS
# Implementation Standards document as follows:
#
#   envir:
#   Set to "test" during the initial testing phase, "para" when running
#   in parallel (on a schedule), and "prod" in production.
#
#   NET:
#   Model name (first level of com directory structure)
#
#   model_ver:
#   Version number of package in three digits (second level of com directory)
#
#   RUN:
#   Name of model run (third level of com directory structure).
#   In general, same as $NET
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
# PTMP:
# The beginning portion of the directory that will contain the output 
# files from the post-processor (UPP) for a given cycle.  For a cycle 
# that starts on the date specified by yyyymmdd and hour specified by hh
# (where yyyymmdd and hh are as described above), the directory in which
# the UPP output files will be placed will be:
# 
#   $PTMP/com/$NET/$model_ver/$RUN.$yyyymmdd/$hh
#
#-----------------------------------------------------------------------
#
COMIN="/path/of/directory/containing/data/files/for/IC/LBCS"
STMP="/base/path/of/directory/containing/model/input/and/raw/output/files"
envir="para"
NET="rrfs"
model_ver="v1.0.0"
RUN="rrfs"
STMP="/base/path/of/directory/containing/model/input/and/raw/output/files"
PTMP="/base/path/of/directory/containing/postprocessed/output/files"
#
#-----------------------------------------------------------------------
#
# Set the separator character(s) to use in the names of the grid, mosaic,
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
# CONSTANTS_FN:
# Name of the file containing definitions of various mathematical, physical, 
# and SRW App contants.
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
# FV3_EXEC_FN:
# Name to use for the forecast model executable when it is copied from
# the directory in which it is created in the build step to the executables
# directory (EXECDIR; this is set during experiment generation).
#
# DIAG_TABLE_TMPL_FN:
# Name of a template file that specifies the output fields of the forecast 
# model (ufs-weather-model: diag_table) followed by [dot_ccpp_phys_suite]. 
# Its default value is the name of the file that the ufs weather model 
# expects to read in.
#
# FIELD_TABLE_TMPL_FN:
# Name of a template file that specifies the tracers in IC/LBC files of the 
# forecast model (ufs-weather-mode: field_table) followed by [dot_ccpp_phys_suite]. 
# Its default value is the name of the file that the ufs weather model expects 
# to read in.
#
# MODEL_CONFIG_TMPL_FN:
# Name of a template file that contains settings and configurations for the 
# NUOPC/ESMF main component (ufs-weather-model: model_config). Its default 
# value is the name of the file that the ufs weather model expects to read in.
#
# NEMS_CONFIG_TMPL_FN:
# Name of a template file that contains information about the various NEMS 
# components and their run sequence (ufs-weather-model: nems.configure). 
# Its default value is the name of the file that the ufs weather model expects 
# to read in.
#
# FCST_MODEL:
# Name of forecast model (default=ufs-weather-model)
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
# EXTRN_MDL_VAR_DEFNS_FN:
# Name of file (a shell script) containing the defintions of variables
# associated with the external model from which ICs or LBCs are generated.  This
# file is created by the GET_EXTRN_*_TN task because the values of the variables
# it contains are not known before this task runs.  The file is then sourced by
# the MAKE_ICS_TN and MAKE_LBCS_TN tasks.
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
CONSTANTS_FN="constants.sh"

RGNL_GRID_NML_FN="regional_grid.nml"

FV3_NML_BASE_SUITE_FN="input.nml.FV3"
FV3_NML_YAML_CONFIG_FN="FV3.input.yml"
FV3_NML_BASE_ENS_FN="input.nml.base_ens"
FV3_EXEC_FN="ufs_model"

DATA_TABLE_TMPL_FN=""
DIAG_TABLE_TMPL_FN=""
FIELD_TABLE_TMPL_FN=""
MODEL_CONFIG_TMPL_FN=""
NEMS_CONFIG_TMPL_FN=""

FCST_MODEL="ufs-weather-model"
WFLOW_XML_FN="FV3LAM_wflow.xml"
GLOBAL_VAR_DEFNS_FN="var_defns.sh"
EXTRN_MDL_VAR_DEFNS_FN="extrn_mdl_var_defns.sh"
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
# INCR_CYCL_FREQ:
# Increment in hours for Cycle Frequency (cycl_freq).
# Default is 24, which means cycle_freq=24:00:00
#
# FCST_LEN_HRS:
# The length of each forecast, in integer hours.
#
#-----------------------------------------------------------------------
#
DATE_FIRST_CYCL="YYYYMMDD"
DATE_LAST_CYCL="YYYYMMDD"
CYCL_HRS=( "HH1" "HH2" )
INCR_CYCL_FREQ="24"
FCST_LEN_HRS="24"
#
#-----------------------------------------------------------------------
#
# Set model_configure parameters.  Definitions:
#
# DT_ATMOS:
# The main forecast model integraton time step.  As described in the 
# forecast model documentation, "It corresponds to the frequency with 
# which the top level routine in the dynamics is called as well as the 
# frequency with which the physics is called."
#
# CPL: parameter for coupling
# (set automatically based on FCST_MODEL in ush/setup.sh)
# (ufs-weather-model:FALSE, fv3gfs_aqm:TRUE)
#
# RESTART_INTERVAL:
# frequency of the output restart files (unit:hour). 
# Default=0: restart files are produced at the end of a forecast run
# For example, RESTART_INTERVAL="1": restart files are produced every hour
# with the prefix "YYYYMMDD.HHmmSS." in the RESTART directory
#
# WRITE_DOPOST:
# Flag that determines whether or not to use the inline post feature 
# [i.e. calling the Unified Post Processor (UPP) from within the weather 
# model].  If this is set to "TRUE", the RUN_POST_TN task is deactivated 
# (i.e. RUN_TASK_RUN_POST is set to "FALSE") to avoid unnecessary 
# computations.
#
#-----------------------------------------------------------------------
#
DT_ATMOS=""
RESTART_INTERVAL="0"
WRITE_DOPOST="FALSE"
#
#-----------------------------------------------------------------------
#
# Set METplus parameters.  Definitions:
#
# MODEL: 
# String that specifies a descriptive name for the model being verified.
#
# MET_INSTALL_DIR:
# Location to top-level directory of MET installation.
#
# METPLUS_PATH:
# Location to top-level directory of METplus installation.
#
# CCPA_OBS_DIR:
# User-specified location of top-level directory where CCPA hourly
# precipitation files used by METplus are located. This parameter needs
# to be set for both user-provided observations and for observations 
# that are retrieved from the NOAA HPSS (if the user has access) via
# the get_obs_ccpa_tn task (activated in workflow by setting
# RUN_TASK_GET_OBS_CCPA="TRUE"). In the case of pulling observations 
# directly from NOAA HPSS, the data retrieved will be placed in this 
# directory. Please note, this path must be defind as 
# /full-path-to-obs/ccpa/proc. METplus is configured to verify 01-, 
# 03-, 06-, and 24-h accumulated precipitation using hourly CCPA files.
# METplus configuration files require the use of predetermined directory 
# structure and file names. Therefore, if the CCPA files are user 
# provided, they need to follow the anticipated naming structure: 
# {YYYYMMDD}/ccpa.t{HH}z.01h.hrap.conus.gb2, where YYYY is the 4-digit 
# valid year, MM the 2-digit valid month, DD the 2-digit valid day of 
# the month, and HH the 2-digit valid hour of the day. In addition, a 
# caveat is noted for using hourly CCPA data. There is a problem with 
# the valid time in the metadata for files valid from 19 - 00 UTC (or 
# files under the '00' directory). The script to pull the CCPA data 
# from the NOAA HPSS has an example of how to account for this as well
# as organizing the data into a more intuitive format: 
# regional_workflow/scripts/exregional_get_ccpa_files.sh. When a fix
# is provided, it will be accounted for in the
# exregional_get_ccpa_files.sh script.
#
# MRMS_OBS_DIR:
# User-specified location of top-level directory where MRMS composite
# reflectivity files used by METplus are located.  This parameter needs
# to be set for both user-provided observations and for observations
# that are retrieved from the NOAA HPSS (if the user has access) via the
# get_obs_mrms_tn task (activated in workflow by setting
# RUN_TASK_GET_OBS_MRMS="TRUE").  In the case of pulling observations 
# directly from NOAA HPSS, the data retrieved will be placed in this 
# directory. Please note, this path must be defind as 
# /full-path-to-obs/mrms/proc. METplus configuration files require the
# use of predetermined directory structure and file names. Therefore, if
# the MRMS files are user provided, they need to follow the anticipated 
# naming structure:
# {YYYYMMDD}/MergedReflectivityQCComposite_00.50_{YYYYMMDD}-{HH}{mm}{SS}.grib2,
# where YYYY is the 4-digit valid year, MM the 2-digit valid month, DD 
# the 2-digit valid day of the month, HH the 2-digit valid hour of the 
# day, mm the 2-digit valid minutes of the hour, and SS is the two-digit
# valid seconds of the hour. In addition, METplus is configured to look
# for a MRMS composite reflectivity file for the valid time of the 
# forecast being verified; since MRMS composite reflectivity files do 
# not always exactly match the valid time, a script, within the main 
# script to retrieve MRMS data from the NOAA HPSS, is used to identify
# and rename the MRMS composite reflectivity file to match the valid
# time of the forecast.  The script to pull the MRMS data from the NOAA 
# HPSS has an example of the expected file naming structure: 
# regional_workflow/scripts/exregional_get_mrms_files.sh. This script 
# calls the script used to identify the MRMS file closest to the valid 
# time: regional_workflow/ush/mrms_pull_topofhour.py.
#
# NDAS_OBS_DIR:
# User-specified location of top-level directory where NDAS prepbufr 
# files used by METplus are located. This parameter needs to be set for
# both user-provided observations and for observations that are 
# retrieved from the NOAA HPSS (if the user has access) via the 
# get_obs_ndas_tn task (activated in workflow by setting 
# RUN_TASK_GET_OBS_NDAS="TRUE"). In the case of pulling observations 
# directly from NOAA HPSS, the data retrieved will be placed in this 
# directory. Please note, this path must be defind as 
# /full-path-to-obs/ndas/proc. METplus is configured to verify 
# near-surface variables hourly and upper-air variables at times valid 
# at 00 and 12 UTC with NDAS prepbufr files.  METplus configuration files
# require the use of predetermined file names. Therefore, if the NDAS 
# files are user provided, they need to follow the anticipated naming 
# structure: prepbufr.ndas.{YYYYMMDDHH}, where YYYY is the 4-digit valid
# year, MM the 2-digit valid month, DD the 2-digit valid day of the 
# month, and HH the 2-digit valid hour of the day. The script to pull 
# the NDAS data from the NOAA HPSS has an example of how to rename the
# NDAS data into a more intuitive format with the valid time listed in 
# the file name: regional_workflow/scripts/exregional_get_ndas_files.sh
#
#-----------------------------------------------------------------------
#
MODEL=""
MET_INSTALL_DIR=""
MET_BIN_EXEC="bin"
METPLUS_PATH=""
CCPA_OBS_DIR=""
MRMS_OBS_DIR=""
NDAS_OBS_DIR=""
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
# EXTRN_MDL_ICS_OFFSET_HRS:
# Users may wish to start a forecast from a forecast of a previous cycle
# of an external model. This variable sets the number of hours earlier
# the external model started than when the FV3 forecast configured here
# should start. For example, the forecast should start from a 6 hour
# forecast of the GFS, then EXTRN_MDL_ICS_OFFSET_HRS=6.

# EXTRN_MDL_LBCS_OFFSET_HRS:
# Users may wish to use lateral boundary conditions from a forecast that
# was started earlier than the initial time for the FV3 forecast
# configured here. This variable sets the number of hours earlier
# the external model started than when the FV3 forecast configured here
# should start. For example, the forecast should use lateral boundary
# conditions from the GFS started 6 hours earlier, then
# EXTRN_MDL_LBCS_OFFSET_HRS=6.
# Note: the default value is model-dependent and set in
# set_extrn_mdl_params.sh
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
EXTRN_MDL_ICS_OFFSET_HRS="0"
EXTRN_MDL_LBCS_OFFSET_HRS=""
FV3GFS_FILE_FMT_ICS="nemsio"
FV3GFS_FILE_FMT_LBCS="nemsio"
#
#-----------------------------------------------------------------------
#
# Base directories in which to search for external model files.
#
# EXTRN_MDL_SYSBASEDIR_ICS:
# Base directory on the local machine containing external model files for
# generating ICs on the native grid.  The way the full path containing 
# these files is constructed depends on the user-specified external model
# for ICs, i.e. EXTRN_MDL_NAME_ICS.
#
# EXTRN_MDL_SYSBASEDIR_LBCS:
# Same as EXTRN_MDL_SYSBASEDIR_ICS but for LBCs.
#
# Note that these must be defined as null strings here so that if they 
# are specified by the user in the experiment configuration file, they 
# remain set to those values, and if not, they get set to machine-dependent 
# values.
#
#-----------------------------------------------------------------------
#
EXTRN_MDL_SYSBASEDIR_ICS=''
EXTRN_MDL_SYSBASEDIR_LBCS=''
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
# Array containing templates of the names of the files to search for in
# the directory specified by EXTRN_MDL_SOURCE_BASEDIR_ICS.  This
# variable is not used if USE_USER_STAGED_EXTRN_FILES is set to "FALSE".
# A single template should be used for each model file type that is
# meant to be used. You may use any of the Python-style templates
# allowed in the ush/retrieve_data.py script. To see the full list of
# supported templates, run that script with a -h option. Here is an example of
# setting FV3GFS nemsio input files:
#   EXTRN_MDL_FILES_ICS=( gfs.t{hh}z.atmf{fcst_hr:03d}.nemsio \
#   gfs.t{hh}z.sfcf{fcst_hr:03d}.nemsio )
# Or for FV3GFS grib files:
#   EXTRN_MDL_FILES_ICS=( gfs.t{hh}z.pgrb2.0p25.f{fcst_hr:03d} )
#
# EXTRN_MDL_SOURCE_BASEDIR_LBCS:
# Analogous to EXTRN_MDL_SOURCE_BASEDIR_ICS but for LBCs instead of ICs.
#
# EXTRN_MDL_FILES_LBCS:
# Analogous to EXTRN_MDL_FILES_ICS but for LBCs instead of ICs.
#
# EXTRN_MDL_DATA_STORES:
# A list of data stores where the scripts should look for external model
# data. The list is in priority order. If disk information is provided
# via USE_USER_STAGED_EXTRN_FILES or a known location on the platform,
# the disk location will be highest priority. Options are disk, hpss,
# aws, and nomads.
#
#-----------------------------------------------------------------------
#
USE_USER_STAGED_EXTRN_FILES="FALSE"
EXTRN_MDL_SOURCE_BASEDIR_ICS=""
EXTRN_MDL_FILES_ICS=""
EXTRN_MDL_SOURCE_BASEDIR_LBCS=""
EXTRN_MDL_FILES_LBCS=""
EXTRN_MDL_DATA_STORES=""
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
CCPP_PHYS_SUITE="FV3_GFS_v16"
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
# ESGgrid_PAZI:
# The rotational parameter for the ESG grid (in degrees).
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
ESGgrid_PAZI=""
#
#-----------------------------------------------------------------------
#
# Set computational parameters for the forecast.  Definitions:
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
# Set flags for more detailed messages.  Defintitions:
#
# VERBOSE:
# This is a flag that determines whether or not the experiment generation 
# and workflow task scripts tend to print out more informational messages.
#
# DEBUG:
# This is a flag that determines whether or not very detailed debugging
# messages are printed to out.  Note that if DEBUG is set to TRUE, then
# VERBOSE will also get reset to TRUE if it isn't already.
#
#-----------------------------------------------------------------------
#
VERBOSE="TRUE"
DEBUG="FALSE"
#
#-----------------------------------------------------------------------
#
# Set the names of the various rocoto workflow tasks.
#
#-----------------------------------------------------------------------
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
GET_OBS="get_obs"
GET_OBS_CCPA_TN="get_obs_ccpa"
GET_OBS_MRMS_TN="get_obs_mrms"
GET_OBS_NDAS_TN="get_obs_ndas"
VX_TN="run_vx"
VX_GRIDSTAT_TN="run_gridstatvx"
VX_GRIDSTAT_REFC_TN="run_gridstatvx_refc"
VX_GRIDSTAT_RETOP_TN="run_gridstatvx_retop"
VX_GRIDSTAT_03h_TN="run_gridstatvx_03h"
VX_GRIDSTAT_06h_TN="run_gridstatvx_06h"
VX_GRIDSTAT_24h_TN="run_gridstatvx_24h"
VX_POINTSTAT_TN="run_pointstatvx"
VX_ENSGRID_TN="run_ensgridvx"
VX_ENSGRID_03h_TN="run_ensgridvx_03h"
VX_ENSGRID_06h_TN="run_ensgridvx_06h"
VX_ENSGRID_24h_TN="run_ensgridvx_24h"
VX_ENSGRID_REFC_TN="run_ensgridvx_refc"
VX_ENSGRID_RETOP_TN="run_ensgridvx_retop"
VX_ENSGRID_MEAN_TN="run_ensgridvx_mean"
VX_ENSGRID_PROB_TN="run_ensgridvx_prob"
VX_ENSGRID_MEAN_03h_TN="run_ensgridvx_mean_03h"
VX_ENSGRID_PROB_03h_TN="run_ensgridvx_prob_03h"
VX_ENSGRID_MEAN_06h_TN="run_ensgridvx_mean_06h"
VX_ENSGRID_PROB_06h_TN="run_ensgridvx_prob_06h"
VX_ENSGRID_MEAN_24h_TN="run_ensgridvx_mean_24h"
VX_ENSGRID_PROB_24h_TN="run_ensgridvx_prob_24h"
VX_ENSGRID_PROB_REFC_TN="run_ensgridvx_prob_refc"
VX_ENSGRID_PROB_RETOP_TN="run_ensgridvx_prob_retop"
VX_ENSPOINT_TN="run_enspointvx"
VX_ENSPOINT_MEAN_TN="run_enspointvx_mean"
VX_ENSPOINT_PROB_TN="run_enspointvx_prob"
#
#-----------------------------------------------------------------------
#
# Set flags (and related directories) that determine whether various
# workflow tasks should be run.  Note that the MAKE_GRID_TN, MAKE_OROG_TN, 
# and MAKE_SFC_CLIMO_TN are all cycle-independent tasks, i.e. if they 
# are to be run, they do so only once at the beginning of the workflow 
# before any cycles are run.  Definitions:
#
# RUN_TASK_MAKE_GRID:
# Flag that determines whether the MAKE_GRID_TN task is to be run.  If 
# this is set to "TRUE", the grid generation task is run and new grid
# files are generated.  If it is set to "FALSE", then the scripts look
# for pregenerated grid files in the directory specified by GRID_DIR 
# (see below).
#
# GRID_DIR:
# The directory in which to look for pregenerated grid files if 
# RUN_TASK_MAKE_GRID is set to "FALSE".
# 
# RUN_TASK_MAKE_OROG:
# Same as RUN_TASK_MAKE_GRID but for the MAKE_OROG_TN task.
#
# OROG_DIR:
# Same as GRID_DIR but for the MAKE_OROG_TN task.
# 
# RUN_TASK_MAKE_SFC_CLIMO:
# Same as RUN_TASK_MAKE_GRID but for the MAKE_SFC_CLIMO_TN task.
#
# SFC_CLIMO_DIR:
# Same as GRID_DIR but for the MAKE_SFC_CLIMO_TN task.
#
# DOMAIN_PREGEN_BASEDIR:
# The base directory containing pregenerated grid, orography, and surface 
# climatology files. This is an alternative for setting GRID_DIR,
# OROG_DIR, and SFC_CLIMO_DIR individually
# 
# For the pregenerated grid specified by PREDEF_GRID_NAME, 
# these "fixed" files are located in:
#
#   ${DOMAIN_PREGEN_BASEDIR}/${PREDEF_GRID_NAME}
#
# The workflow scripts will create a symlink in the experiment directory
# that will point to a subdirectory (having the name of the grid being
# used) under this directory.  This variable should be set to a null 
# string in this file, but it can be specified in the user-specified 
# workflow configuration file (EXPT_CONFIG_FN).
#
# RUN_TASK_GET_EXTRN_ICS:
# Flag that determines whether the GET_EXTRN_ICS_TN task is to be run.
#
# RUN_TASK_GET_EXTRN_LBCS:
# Flag that determines whether the GET_EXTRN_LBCS_TN task is to be run.
#
# RUN_TASK_MAKE_ICS:
# Flag that determines whether the MAKE_ICS_TN task is to be run.
#
# RUN_TASK_MAKE_LBCS:
# Flag that determines whether the MAKE_LBCS_TN task is to be run.
#
# RUN_TASK_RUN_FCST:
# Flag that determines whether the RUN_FCST_TN task is to be run.
#
# RUN_TASK_RUN_POST:
# Flag that determines whether the RUN_POST_TN task is to be run.
# 
# RUN_TASK_VX_GRIDSTAT:
# Flag that determines whether the grid-stat verification task is to be
# run.
#
# RUN_TASK_VX_POINTSTAT:
# Flag that determines whether the point-stat verification task is to be
# run.
#
# RUN_TASK_VX_ENSGRID:
# Flag that determines whether the ensemble-stat verification for gridded
# data task is to be run. 
#
# RUN_TASK_VX_ENSPOINT:
# Flag that determines whether the ensemble point verification task is
# to be run. If this flag is set, both ensemble-stat point verification
# and point verification of ensemble-stat output is computed.
#
#-----------------------------------------------------------------------
#
RUN_TASK_MAKE_GRID="TRUE"
GRID_DIR="/path/to/pregenerated/grid/files"

RUN_TASK_MAKE_OROG="TRUE"
OROG_DIR="/path/to/pregenerated/orog/files"

RUN_TASK_MAKE_SFC_CLIMO="TRUE"
SFC_CLIMO_DIR="/path/to/pregenerated/surface/climo/files"

DOMAIN_PREGEN_BASEDIR=""

RUN_TASK_GET_EXTRN_ICS="TRUE"
RUN_TASK_GET_EXTRN_LBCS="TRUE"
RUN_TASK_MAKE_ICS="TRUE"
RUN_TASK_MAKE_LBCS="TRUE"
RUN_TASK_RUN_FCST="TRUE"
RUN_TASK_RUN_POST="TRUE"

RUN_TASK_GET_OBS_CCPA="FALSE"
RUN_TASK_GET_OBS_MRMS="FALSE"
RUN_TASK_GET_OBS_NDAS="FALSE"
RUN_TASK_VX_GRIDSTAT="FALSE"
RUN_TASK_VX_POINTSTAT="FALSE"
RUN_TASK_VX_ENSGRID="FALSE"
RUN_TASK_VX_ENSPOINT="FALSE"
#
#-----------------------------------------------------------------------
#
# Flag that determines whether MERRA2 aerosol climatology data and
# lookup tables for optics properties are obtained
#
#-----------------------------------------------------------------------
#
USE_MERRA_CLIMO="FALSE"
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
# FIXaer:
# System directory where MERRA2 aerosol climatology files are located
#
# FIXlut:
# System directory where the lookup tables for optics properties are located
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
FIXaer=""
FIXlut=""
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
"fix_co2_proj/global_co2historicaldata_2019.txt" \
"fix_co2_proj/global_co2historicaldata_2020.txt" \
"fix_co2_proj/global_co2historicaldata_2021.txt" \
"global_co2historicaldata_glob.txt" \
"co2monthlycyc.txt" \
"global_h2o_pltc.f77" \
"global_hyblev.l65.txt" \
"global_zorclim.1x1.grb" \
"global_sfc_emissivity_idx.txt" \
"global_tg3clim.2.6x1.5.grb" \
"global_solarconstant_noaa_an.txt" \
"global_albedo4.1x1.grb" \
"geo_em.d01.lat-lon.2.5m.HGT_M.nc" \
"HGT.Beljaars_filtered.lat-lon.30s_res.nc" \
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
"co2historicaldata_2019.txt | fix_co2_proj/global_co2historicaldata_2019.txt" \
"co2historicaldata_2020.txt | fix_co2_proj/global_co2historicaldata_2020.txt" \
"co2historicaldata_2021.txt | fix_co2_proj/global_co2historicaldata_2021.txt" \
"co2historicaldata_glob.txt | global_co2historicaldata_glob.txt" \
"co2monthlycyc.txt          | co2monthlycyc.txt" \
"global_h2oprdlos.f77       | global_h2o_pltc.f77" \
"global_albedo4.1x1.grb     | global_albedo4.1x1.grb" \
"global_zorclim.1x1.grb     | global_zorclim.1x1.grb" \
"global_tg3clim.2.6x1.5.grb | global_tg3clim.2.6x1.5.grb" \
"sfc_emissivity_idx.txt     | global_sfc_emissivity_idx.txt" \
"solarconstant_noaa_an.txt  | global_solarconstant_noaa_an.txt" \
"global_o3prdlos.f77        | " \
)
#
#-----------------------------------------------------------------------
#
# For each workflow task, set the parameters to pass to the job scheduler 
# (e.g. slurm) that will submit a job for each task to be run.  These 
# parameters include the number of nodes to use to run the job, the MPI 
# processes per node, the maximum walltime to allow for the job to complete, 
# and the maximum number of times to attempt to run each task.
#
#-----------------------------------------------------------------------
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
NNODES_GET_OBS_CCPA="1"
NNODES_GET_OBS_MRMS="1"
NNODES_GET_OBS_NDAS="1"
NNODES_VX_GRIDSTAT="1"
NNODES_VX_POINTSTAT="1"
NNODES_VX_ENSGRID="1"
NNODES_VX_ENSGRID_MEAN="1"
NNODES_VX_ENSGRID_PROB="1"
NNODES_VX_ENSPOINT="1"
NNODES_VX_ENSPOINT_MEAN="1"
NNODES_VX_ENSPOINT_PROB="1"
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
PPN_RUN_FCST=""    # will be calculated from NCORES_PER_NODE and OMP_NUM_THREADS in setup.sh
PPN_RUN_POST="24"
PPN_GET_OBS_CCPA="1"
PPN_GET_OBS_MRMS="1"
PPN_GET_OBS_NDAS="1"
PPN_VX_GRIDSTAT="1"
PPN_VX_POINTSTAT="1"
PPN_VX_ENSGRID="1"
PPN_VX_ENSGRID_MEAN="1"
PPN_VX_ENSGRID_PROB="1"
PPN_VX_ENSPOINT="1"
PPN_VX_ENSPOINT_MEAN="1"
PPN_VX_ENSPOINT_PROB="1"
#
# Walltimes.
#
WTIME_MAKE_GRID="00:20:00"
WTIME_MAKE_OROG="01:00:00"
WTIME_MAKE_SFC_CLIMO="00:20:00"
WTIME_GET_EXTRN_ICS="00:45:00"
WTIME_GET_EXTRN_LBCS="00:45:00"
WTIME_MAKE_ICS="00:30:00"
WTIME_MAKE_LBCS="00:30:00"
WTIME_RUN_FCST="04:30:00"
WTIME_RUN_POST="00:15:00"
WTIME_GET_OBS_CCPA="00:45:00"
WTIME_GET_OBS_MRMS="00:45:00"
WTIME_GET_OBS_NDAS="02:00:00"
WTIME_VX_GRIDSTAT="02:00:00"
WTIME_VX_POINTSTAT="01:00:00"
WTIME_VX_ENSGRID="01:00:00"
WTIME_VX_ENSGRID_MEAN="01:00:00"
WTIME_VX_ENSGRID_PROB="01:00:00"
WTIME_VX_ENSPOINT="01:00:00"
WTIME_VX_ENSPOINT_MEAN="01:00:00"
WTIME_VX_ENSPOINT_PROB="01:00:00"
#
# Maximum number of attempts.
#
MAXTRIES_MAKE_GRID="2"
MAXTRIES_MAKE_OROG="2"
MAXTRIES_MAKE_SFC_CLIMO="2"
MAXTRIES_GET_EXTRN_ICS="1"
MAXTRIES_GET_EXTRN_LBCS="1"
MAXTRIES_MAKE_ICS="1"
MAXTRIES_MAKE_LBCS="1"
MAXTRIES_RUN_FCST="1"
MAXTRIES_RUN_POST="2"
MAXTRIES_GET_OBS_CCPA="1"
MAXTRIES_GET_OBS_MRMS="1"
MAXTRIES_GET_OBS_NDAS="1"
MAXTRIES_VX_GRIDSTAT="1"
MAXTRIES_VX_GRIDSTAT_REFC="1"
MAXTRIES_VX_GRIDSTAT_RETOP="1"
MAXTRIES_VX_GRIDSTAT_03h="1"
MAXTRIES_VX_GRIDSTAT_06h="1"
MAXTRIES_VX_GRIDSTAT_24h="1"
MAXTRIES_VX_POINTSTAT="1"
MAXTRIES_VX_ENSGRID="1"
MAXTRIES_VX_ENSGRID_REFC="1"
MAXTRIES_VX_ENSGRID_RETOP="1"
MAXTRIES_VX_ENSGRID_03h="1"
MAXTRIES_VX_ENSGRID_06h="1"
MAXTRIES_VX_ENSGRID_24h="1"
MAXTRIES_VX_ENSGRID_MEAN="1"
MAXTRIES_VX_ENSGRID_PROB="1"
MAXTRIES_VX_ENSGRID_MEAN_03h="1"
MAXTRIES_VX_ENSGRID_PROB_03h="1"
MAXTRIES_VX_ENSGRID_MEAN_06h="1"
MAXTRIES_VX_ENSGRID_PROB_06h="1"
MAXTRIES_VX_ENSGRID_MEAN_24h="1"
MAXTRIES_VX_ENSGRID_PROB_24h="1"
MAXTRIES_VX_ENSGRID_PROB_REFC="1"
MAXTRIES_VX_ENSGRID_PROB_RETOP="1"
MAXTRIES_VX_ENSPOINT="1"
MAXTRIES_VX_ENSPOINT_MEAN="1"
MAXTRIES_VX_ENSPOINT_PROB="1"

#
#-----------------------------------------------------------------------
#
# Allows an extra parameter to be passed to slurm via XML Native
# command
#
SLURM_NATIVE_CMD=""
#
#-----------------------------------------------------------------------
#
# Set parameters associated with subhourly forecast model output and 
# post-processing.
#
# SUB_HOURLY_POST:
# Flag that indicates whether the forecast model will generate output 
# files on a sub-hourly time interval (e.g. 10 minutes, 15 minutes, etc).
# This will also cause the post-processor to process these sub-hourly
# files.  If ths is set to "TRUE", then DT_SUBHOURLY_POST_MNTS should be 
# set to a value between "00" and "59".
#
# DT_SUB_HOURLY_POST_MNTS:
# Time interval in minutes between the forecast model output files.  If 
# SUB_HOURLY_POST is set to "TRUE", this needs to be set to a two-digit 
# integer between "01" and "59".  This is not used if SUB_HOURLY_POST is
# not set to "TRUE".  Note that if SUB_HOURLY_POST is set to "TRUE" but
# DT_SUB_HOURLY_POST_MNTS is set to "00", SUB_HOURLY_POST will get reset
# to "FALSE" in the experiment generation scripts (there will be an 
# informational message in the log file to emphasize this).
#
#-----------------------------------------------------------------------
#
SUB_HOURLY_POST="FALSE"
DT_SUBHOURLY_POST_MNTS="00"
#
#-----------------------------------------------------------------------
#
# Set parameters for customizing the post-processor (UPP).  Definitions:
#
# USE_CUSTOM_POST_CONFIG_FILE:
# Flag that determines whether a user-provided custom configuration file
# should be used for post-processing the model data. If this is set to
# "TRUE", then the workflow will use the custom post-processing (UPP) 
# configuration file specified in CUSTOM_POST_CONFIG_FP. Otherwise, a 
# default configuration file provided in the UPP repository will be 
# used.
#
# CUSTOM_POST_CONFIG_FP:
# The full path to the custom post flat file, including filename, to be 
# used for post-processing. This is only used if CUSTOM_POST_CONFIG_FILE
# is set to "TRUE".
#
# POST_OUTPUT_DOMAIN_NAME:
# Domain name (in lowercase) used in constructing the names of the output 
# files generated by UPP [which is called either by running the RUN_POST_TN 
# task or by activating the inline post feature (WRITE_DOPOST set to "TRUE")].  
# The post output files are named as follows:
#
#   $NET.tHHz.[var_name].f###.${POST_OUTPUT_DOMAIN_NAME}.grib2
#
# If using a custom grid, POST_OUTPUT_DOMAIN_NAME must be specified by 
# the user.  If using a predefined grid, POST_OUTPUT_DOMAIN_NAME defaults
# to PREDEF_GRID_NAME.  Note that this variable is first changed to lower
# case before being used to construct the file names.
#
#-----------------------------------------------------------------------
#
USE_CUSTOM_POST_CONFIG_FILE="FALSE"
CUSTOM_POST_CONFIG_FP=""
POST_OUTPUT_DOMAIN_NAME=""
#
#-----------------------------------------------------------------------
#
# Set parameters associated with outputting satellite fields in the UPP
# grib2 files using the Community Radiative Transfer Model (CRTM).
#
# USE_CRTM:
# Flag that defines whether external CRTM coefficient files have been
# staged by the user in order to output synthetic statellite products
# available within the UPP. If this is set to "TRUE", then the workflow
# will check for these files in the directory CRTM_DIR. Otherwise, it is
# assumed that no satellite fields are being requested in the UPP
# configuration.
#
# CRTM_DIR:
# This is the path to the top CRTM fix file directory. This is only used
# if USE_CRTM is set to "TRUE".
#
#-----------------------------------------------------------------------
#
USE_CRTM="FALSE"
CRTM_DIR=""
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
DO_SHUM="FALSE"
DO_SPPT="FALSE"
DO_SKEB="FALSE"
ISEED_SPPT="1"
ISEED_SHUM="2"
ISEED_SKEB="3"
NEW_LSCALE="TRUE"
SHUM_MAG="0.006" #Variable "shum" in input.nml
SHUM_LSCALE="150000"
SHUM_TSCALE="21600" #Variable "shum_tau" in input.nml
SHUM_INT="3600" #Variable "shumint" in input.nml
SPPT_MAG="0.7" #Variable "sppt" in input.nml
SPPT_LOGIT="TRUE"
SPPT_LSCALE="150000"
SPPT_TSCALE="21600" #Variable "sppt_tau" in input.nml
SPPT_INT="3600" #Variable "spptint" in input.nml
SPPT_SFCLIMIT="TRUE"
SKEB_MAG="0.5" #Variable "skeb" in input.nml
SKEB_LSCALE="150000"
SKEB_TSCALE="21600" #Variable "skeb_tau" in input.nml
SKEB_INT="3600" #Variable "skebint" in input.nml
SKEBNORM="1"
SKEB_VDOF="10"
USE_ZMTNBLCK="FALSE"
#
#-----------------------------------------------------------------------
#
# Set default SPP stochastic physics options. Each SPP option is an array, 
# applicable (in order) to the scheme/parameter listed in SPP_VAR_LIST. 
# Enter each value of the array in config.sh as shown below without commas
# or single quotes (e.g., SPP_VAR_LIST=( "pbl" "sfc" "mp" "rad" "gwd" ). 
# Both commas and single quotes will be added by Jinja when creating the
# namelist.
#
# Note that SPP is currently only available for specific physics schemes 
# used in the RAP/HRRR physics suite.  Users need to be aware of which SDF
# is chosen when turning this option on. 
#
# Patterns evolve and are applied at each time step.
#
#-----------------------------------------------------------------------
#
DO_SPP="false"
SPP_VAR_LIST=( "pbl" "sfc" "mp" "rad" "gwd" )
SPP_MAG_LIST=( "0.2" "0.2" "0.75" "0.2" "0.2" ) #Variable "spp_prt_list" in input.nml
SPP_LSCALE=( "150000.0" "150000.0" "150000.0" "150000.0" "150000.0" )
SPP_TSCALE=( "21600.0" "21600.0" "21600.0" "21600.0" "21600.0" ) #Variable "spp_tau" in input.nml
SPP_SIGTOP1=( "0.1" "0.1" "0.1" "0.1" "0.1")
SPP_SIGTOP2=( "0.025" "0.025" "0.025" "0.025" "0.025" )
SPP_STDDEV_CUTOFF=( "1.5" "1.5" "2.5" "1.5" "1.5" )
ISEED_SPP=( "4" "5" "6" "7" "8" )
#
#-----------------------------------------------------------------------
#
# Turn on SPP in Noah or RUC LSM (support for Noah MP is in progress).
# Please be aware of the SDF that you choose if you wish to turn on LSM
# SPP.
#
# SPP in LSM schemes is handled in the &nam_sfcperts namelist block 
# instead of in &nam_sppperts, where all other SPP is implemented.
#
# The default perturbation frequency is determined by the fhcyc namelist 
# entry.  Since that parameter is set to zero in the SRW App, use 
# LSM_SPP_EACH_STEP to perturb every time step. 
#
# Perturbations to soil moisture content (SMC) are only applied at the 
# first time step.
#
# LSM perturbations include SMC - soil moisture content (volume fraction),
# VGF - vegetation fraction, ALB - albedo, SAL - salinity, 
# EMI - emissivity, ZOL - surface roughness (cm), and STC - soil temperature.
#
# Only five perturbations at a time can be applied currently, but all seven
# are shown below.  In addition, only one unique iseed value is allowed 
# at the moment, and is used for each pattern.
#
DO_LSM_SPP="false" #If true, sets lndp_type=2
LSM_SPP_TSCALE=( "21600" "21600" "21600" "21600" "21600" "21600" "21600" )
LSM_SPP_LSCALE=( "150000" "150000" "150000" "150000" "150000" "150000" "150000" )
ISEED_LSM_SPP=( "9" )
LSM_SPP_VAR_LIST=( "smc" "vgf" "alb" "sal" "emi" "zol" "stc" )
LSM_SPP_MAG_LIST=( "0.2" "0.001" "0.001" "0.001" "0.001" "0.001" "0.2" )
LSM_SPP_EACH_STEP="true" #Sets lndp_each_step=.true.
#
#-----------------------------------------------------------------------
# 
# HALO_BLEND:
# Number of rows into the computational domain that should be blended 
# with the LBCs.  To shut halo blending off, this can be set to zero.
#
#-----------------------------------------------------------------------
#
HALO_BLEND="10"
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
# FVCOM_WCSTART:
# Define if this is a "warm" start or a "cold" start. Setting this to 
# "warm" will read in sfc_data.nc generated in a RESTART directory.
# Setting this to "cold" will read in the sfc_data.nc generated from 
# chgres_cube in the make_ics portion of the workflow.
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
FVCOM_WCSTART="cold"
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
# KMP_AFFINITY_*:
# From Intel: "The Intel® runtime library has the ability to bind OpenMP
# threads to physical processing units. The interface is controlled using
# the KMP_AFFINITY environment variable. Depending on the system (machine)
# topology, application, and operating system, thread affinity can have a
# dramatic effect on the application speed. 
#
# Thread affinity restricts execution of certain threads (virtual execution
# units) to a subset of the physical processing units in a multiprocessor 
# computer. Depending upon the topology of the machine, thread affinity can
# have a dramatic effect on the execution speed of a program."
#
# For more information, see the following link:
# https://software.intel.com/content/www/us/en/develop/documentation/cpp-
# compiler-developer-guide-and-reference/top/optimization-and-programming-
# guide/openmp-support/openmp-library-support/thread-affinity-interface-
# linux-and-windows.html
# 
# OMP_NUM_THREADS_*:
# The number of OpenMP threads to use for parallel regions.
# 
# OMP_STACKSIZE_*:
# Controls the size of the stack for threads created by the OpenMP 
# implementation.
#
# Note that settings for the make_grid and make_orog tasks are not 
# included below as they do not use parallelized code.
#
#-----------------------------------------------------------------------
#
KMP_AFFINITY_MAKE_OROG="disabled"
OMP_NUM_THREADS_MAKE_OROG="6"
OMP_STACKSIZE_MAKE_OROG="2048m"

KMP_AFFINITY_MAKE_SFC_CLIMO="scatter"
OMP_NUM_THREADS_MAKE_SFC_CLIMO="1"
OMP_STACKSIZE_MAKE_SFC_CLIMO="1024m"

KMP_AFFINITY_MAKE_ICS="scatter"
OMP_NUM_THREADS_MAKE_ICS="1"
OMP_STACKSIZE_MAKE_ICS="1024m"

KMP_AFFINITY_MAKE_LBCS="scatter"
OMP_NUM_THREADS_MAKE_LBCS="1"
OMP_STACKSIZE_MAKE_LBCS="1024m"

KMP_AFFINITY_RUN_FCST="scatter"
OMP_NUM_THREADS_RUN_FCST="2"    # atmos_nthreads in model_configure
OMP_STACKSIZE_RUN_FCST="1024m"

KMP_AFFINITY_RUN_POST="scatter"
OMP_NUM_THREADS_RUN_POST="1"
OMP_STACKSIZE_RUN_POST="1024m"
#
#-----------------------------------------------------------------------
#
