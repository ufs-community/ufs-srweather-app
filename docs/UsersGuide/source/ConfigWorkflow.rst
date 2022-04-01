.. _ConfigWorkflow:

==================================================================
Configuring the Workflow: ``config.sh`` and ``config_defaults.sh``		
==================================================================
To create the experiment directory and workflow when running the SRW App, the user must create an experiment configuration file named ``config.sh``. This file contains experiment-specific information, such as dates, external model data, directories, and other relevant settings. To help the user, two sample configuration files have been included in the ``regional_workflow`` repository’s ``ush`` directory: ``config.community.sh`` and ``config.nco.sh``. The first is for running experiments in community mode (``RUN_ENVIR`` set to "community"; see below), and the second is for running experiments in "nco" mode (``RUN_ENVIR`` set to "nco"). Note that for this release, only "community" mode is supported. These files can be used as the starting point from which to generate a variety of experiment configurations in which to run the SRW App.

..
   COMMENT: Is community mode still the only one supported? 

There is an extensive list of experiment parameters that a user can set when configuring the experiment. Not all of these need to be explicitly set by the user in ``config.sh``. If a user does not define an entry in the ``config.sh`` script, either its value in ``config_defaults.sh`` will be used, or it will be reset depending on other parameters, such as the platform on which the experiment will be run (specified by ``MACHINE``). Note that ``config_defaults.sh`` contains the full list of experiment parameters that a user may set in ``config.sh`` (i.e., the user cannot set parameters in config.sh that are not initialized in ``config_defaults.sh``).

The following is a list of the parameters in the ``config_defaults.sh`` file. For each parameter, the default value and a brief description is given. In addition, any relevant information on features and settings supported or unsupported in this release is specified.

Platform Environment
====================
``RUN_ENVIR``: (Default: "nco")
   This variable determines the mode that the workflow will run in. The user can choose between two modes: "nco" and "community." The "nco" mode uses a directory structure that mimics what is used in operations at NOAA/NCEP Central Operations (NCO) and at the NOAA/NCEP/Environmental Modeling Center (EMC), which is working with NCO on pre-implementation testing. Specifics of the conventions used in "nco" mode can be found in the following `WCOSS Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/>`__ document:

   | NCEP Central Operations
   | WCOSS Implementation Standards
   | January 19, 2022
   | Version 11.0.0
   
   Setting ``RUN_ENVIR`` to "community" will use the standard directory structure and variable naming convention and is recommended in most cases for users who are not planning to implement their code into operations at NCO.

``MACHINE``: (Default: "BIG_COMPUTER")
   The machine (a.k.a. platform) on which the workflow will run. Currently supported platforms include "WCOSS_DELL_P3," "HERA," "ORION," "JET," "ODIN," "CHEYENNE," "STAMPEDE," "GAEA," "SINGULARITY," "NOAACLOUD," "MACOS," and "LINUX." When running the SRW App in a container, set ``MACHINE`` to "SINGULARITY" regardless of the underlying platform. 


..
   COMMENT: Are we deleting WCOSS_CRAY and/or GAEA? Any others to add besides SINGULARITY/NOAACLOUD? 

``MACHINE_FILE``: (Default: "")
   Path to a configuration file with machine-specific settings. If none is provided, ``setup.sh`` will attempt to set the path to for a supported platform.

``ACCOUNT``: (Default: "project_name")
   The account under which to submit jobs to the queue on the specified ``MACHINE``. To determine an appropriate ACCOUNT field for Level 1 systems, users may run ``groups``, which will return a list of projects the user has permissions for. Not all of the listed projects/groups have an HPC allocation, but those that do are potentially valid account names. The ``account_params`` command will display additional account details. 

``WORKFLOW_MANAGER``: (Default: "none")
   The workflow manager to use (e.g. "ROCOTO"). This is set to "none" by default, but if the machine name is set to a platform that supports Rocoto, this will be overwritten and set to "ROCOTO." Valid values: "rocoto" "none"

``NCORES_PER_NODE``: (Default: "")
   The number of cores available per node on the compute platform. Set for supported platforms in ``setup.sh``, but is now also configurable for all platforms.

``LMOD_PATH``: (Default: "")
   Path to the LMOD sh file on the user's Linux system. Is set automatically for supported machines.

``BUILD_ENV_FN``: (Default: "")
   Name of alternative build environment file to use if using an unsupported platform. Is set automatically for supported machines.

``WFLOW_ENV_FN``: (Default: "")
   Name of alternative workflow environment file to use if using an unsupported platform. Is set automatically for supported machines.

``SCHED``: (Default: "")
   The job scheduler to use (e.g., Slurm) on the specified ``MACHINE``. Set this to an empty string in order for the experiment generation script to set it automatically depending on the machine the workflow is running on. Valid values: "slurm" "pbspro" "lsf" "lsfcray" "none"

Machine-Dependent Parameters:
-------------------------------
These parameters vary depending on machine. On `Level 1 and 2 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, the appropriate values for each machine can be viewed in the ``regional_workflow/ush/machine/<platform>.sh`` scripts. To specify a value other than the default, add these variables and the desired value in the ``config.sh`` file so that they override the ``config_defaults.sh`` and machine default values. 

``PARTITION_DEFAULT``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). This is the default partition to which Slurm submits workflow tasks. When a variable that specifies the partition (e.g., ``PARTITION_HPSS``, ``PARTITION_FCST``; see below) is **not** specified, the task will be submitted to the default partition indicated in the ``PARTITION_DEFAULT`` variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values include: "hera" "normal" "orion" "sjet,vjet,kjet,xjet" "workq" "" 

``CLUSTERS_DEFAULT``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). These are the default clusters to which Slurm submits workflow tasks. If the ``CLUSTERS_HPSS`` or ``CLUSTERS_FCST`` (see below) are not specified, the task will be submitted to the default clusters indicated in this variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. 

``QUEUE_DEFAULT``: (Default: "")
   The default queue or QOS to which workflow tasks are submitted (QOS is Slurm's term for queue; it stands for "Quality of Service"). If the task's ``QUEUE_HPSS`` or ``QUEUE_FCST`` variables (see below) are not specified, the task will be submitted to the queue indicated by this variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values include: "batch" "dev" "normal" "regular" "workq" ""

``PARTITION_HPSS``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). Tasks that get or create links to external model files are submitted to the partition specified in this variable. These links are needed to generate initial conditions (ICs) and lateral boundary conditions (LBCs) for the experiment. If this variable is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values include: "normal" "service" "workq" ""

..
   COMMENT: Wouldn't it be reset to the PARTITION_DEFAULT value? 

``CLUSTERS_HPSS``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). Tasks that get or create links to external model files are submitted to the clusters specified in this variable. These links are needed to generate initial conditions (ICs) and lateral boundary conditions (LBCs) for the experiment. If this variable is not set or is set to an empty string, it will be (re)set to a machine-dependent value. 

``QUEUE_HPSS``: (Default: "")
   Tasks that get or create links to external model files are submitted to this queue, or QOS (QOS is Slurm's term for queue; it stands for "Quality of Service"). If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values include: "batch" "dev_transfer" "normal" "regular" "workq" ""

``PARTITION_FCST``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). The task that runs forecasts is submitted to this partition. If this variable is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values include: "hera" "normal" "orion" "sjet,vjet,kjet,xjet" "workq" ""

``CLUSTERS_FCST``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). The task that runs forecasts is submitted to this cluster. If this variable is not set or is set to an empty string, it will be (re)set to a machine-dependent value. 

``QUEUE_FCST``: (Default: "")
   The task that runs a forecast is submitted to this queue, or QOS (QOS is Slurm's term for queue; it stands for "Quality of Service"). If this is not set or set to an empty string, it will be (re)set to a machine-dependent value. Valid values include: "batch" "dev" "normal" "regular" "workq"

Parameters for Running Without a Workflow Manager
=================================================
These settings control run commands for platforms without a workflow manager. Values will be ignored unless ``WORKFLOW_MANAGER="none"``.

``RUN_CMD_UTILS``: (Default: "mpirun -np 1")
   The run command for pre-processing utilities (shave, orog, sfc_climo_gen, etc.). This can be left blank for smaller domains, in which case the executables will run without MPI.

``RUN_CMD_FCST``: (Default: "mpirun -np \${PE_MEMBER01}")
   The run command for the model forecast step. This will be appended to the end of the variable definitions file ("var_defns.sh").

``RUN_CMD_POST``: (Default: "mpirun -np 1")
   The run command for post-processing (:term:`UPP`). Can be left blank for smaller domains, in which case UPP will run without MPI.

Cron-Associated Parameters
==========================
``USE_CRON_TO_RELAUNCH``: (Default: "FALSE")
   Flag that determines whether or not a line is added to the user's cron table, which calls the experiment launch script every ``CRON_RELAUNCH_INTVL_MNTS`` minutes.

``CRON_RELAUNCH_INTVL_MNTS``: (Default: "03")
   The interval (in minutes) between successive calls of the experiment launch script by a cron job to (re)launch the experiment (so that the workflow for the experiment kicks off where it left off). This is used only if ``USE_CRON_TO_RELAUNCH`` is set to "TRUE".

Directory Parameters
====================
``EXPT_BASEDIR``: (Default: "")
   The base directory in which the experiment directory will be created. If this is not specified or if it is set to an empty string, it will default to ``${HOMErrfs}/../../expt_dirs``, where ``${HOMErrfs}`` contains the full path to the ``regional_workflow`` directory.

``EXPT_SUBDIR``: (Default: "")
   The name that the experiment directory (without the full path) will have. The full path to the experiment directory, which will be contained in the variable ``EXPTDIR``, will be:

   .. code-block:: console

      EXPTDIR="${EXPT_BASEDIR}/${EXPT_SUBDIR}"

   This parameter cannot be left as a null string.

``EXEC_SUBDIR``: (Default: "bin")
   The name of the subdirectory of ``ufs-srweather-app`` where executables are installed.

NCO Mode Parameters
===================
These variables apply only when using NCO mode (i.e. when ``RUN_ENVIR`` is set to "nco").

``COMINgfs``: (Default: "/base/path/of/directory/containing/gfs/input/files")
   The beginning portion of the path to the directory that contains files generated by the external model (FV3GFS). The initial and lateral boundary condition generation tasks need this path in order to create initial and boundary condition files for a given cycle on the native FV3-LAM grid. For a cycle that starts on the date specified by the variable YYYYMMDD (consisting of the 4-digit year, 2-digit month, and 2-digit day of the month) and the hour specified by the variable HH (consisting of the 2-digit hour-of-the-day), the directory in which the workflow will look for the external model files is:

   .. code-block:: console

      $COMINgfs/gfs.$yyyymmdd/$hh/atmos

..
   COMMENT: Should "atmos" be at the end of this file path? If so, is it standing in for something (like FV3GFS), or is "atmos" actually part of the file path? Are the files created directly in the "atmos" folder? Or is there an "ICS" and "LBCS" directory generated? 

``FIXLAM_NCO_BASEDIR``: (Default: "")
   The base directory containing pregenerated grid, orography, and surface climatology files. For the pregenerated grid specified by PREDEF_GRID_NAME, these "fixed" files are located in:

   .. code-block:: console

      ${FIXLAM_NCO_BASEDIR}/${PREDEF_GRID_NAME}

   The workflow scripts will create a symlink in the experiment directory that will point to a subdirectory (having the name of the grid being used) under this directory. This variable should be set to a null string in this file, but it can be specified in the user-specified workflow configuration file (EXPT_CONFIG_FN).

..
   COMMENT: Why should this variable be set to a null string?

``STMP``: (Default: "/base/path/of/directory/containing/model/input/and/raw/output/files")
   The beginning portion of the path to the directory that will contain :term:`cycle-dependent` model input files, symlinks to :term:`cycle-independent` input files, and raw (i.e., before post-processing) forecast output files for a given :term:`cycle`. The format for cycle dates (cdate) is ``cdate="${YYYYMMDD}${HH}"``, where the date is specified using YYYYMMDD format, and the hour is specified using HH format. The files for a cycle date will be located in the following directory:

   .. code-block:: console

      $STMP/tmpnwprd/$RUN/$cdate

``NET, envir, RUN``:
   Variables used in forming the path to the directory that will contain the post-processor (UPP) output files for a given cycle (see ``PTMP`` below). These are defined in the `WCOSS Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/ImplementationStandards.v11.0.0.pdf?>`__ document (pp. 4-5, 19-20) as follows:

   ``NET``: (Default: "rrfs")
      Model name (first level of *com* directory structure)

   ``envir``: (Default: "para")
      Set to "test" during the initial testing phase, "para" when running in parallel (on a schedule), and "prod" in production.

   ``RUN``: (Default: "experiment_name")
      Name of model run (third level of *com* directory structure).

``PTMP``: (Default: "/base/path/of/directory/containing/postprocessed/output/files")
   The beginning portion of the path to the directory that will contain the output files from the post-processor (UPP) for a given cycle. For a cycle that starts on the date specified by YYYYMMDD and hour specified by HH (where YYYYMMDD and HH are as described above), the UPP output files will be placed in the following directory:
 
   .. code-block:: console

      $PTMP/com/$NET/$envir/$RUN.$yyyymmdd/$hh

Pre-Processing File Separator Parameters
========================================
``DOT_OR_USCORE``: (Default: "_")
   This variable sets the separator character(s) to use in the names of the grid, mosaic, and orography fixed files. Ideally, the same separator should be used in the names of these fixed files as in the surface climatology fixed files.

File Name Parameters
====================
``EXPT_CONFIG_FN``: (Default: "config.sh")
   Name of the user-specified configuration file for the forecast experiment.

``RGNL_GRID_NML_FN``: (Default: "regional_grid.nml")
   Name of the file containing namelist settings for the code that generates an "ESGgrid" regional grid.

``FV3_NML_BASE_SUITE_FN``: (Default: "input.nml.FV3")
   Name of the Fortran namelist file containing the forecast model's base suite namelist (i.e., the portion of the namelist that is common to all physics suites).

``FV3_NML_YAML_CONFIG_FN``: (Default: "FV3.input.yml")
   Name of YAML configuration file containing the forecast model's namelist settings for various physics suites.

``FV3_NML_BASE_ENS_FN``: (Default: "input.nml.base_ens")
   Name of the Fortran namelist file containing the forecast model's base ensemble namelist, i.e., the the namelist file that is the starting point from which the namelist files for each of the enesemble members are generated.

``DIAG_TABLE_FN``: (Default: "diag_table")
   Name of the file that specifies the fields that the forecast model will output.

``FIELD_TABLE_FN``: (Default: "field_table")
   Name of the file that specifies the tracers that the forecast model will read in from the IC/LBC files.

``DATA_TABLE_FN``: (Default: "data_table")
   The name of the file containing the data table read in by the forecast model.

``MODEL_CONFIG_FN``: (Default: "model_configure")
   The name of the file containing settings and configurations for the NUOPC/ESMF component.

``NEMS_CONFIG_FN``: (Default: "nems.configure")
   The name of the file containing information about the various NEMS components and their run sequence.

``FV3_EXEC_FN``: (Default: "ufs_model")
   Name of the forecast model executable stored in the executables directory (``EXECDIR``; set during experiment generation).

``FCST_MODEL``: (Default: "ufs-weather-model")
   Name of forecast model.

``WFLOW_XML_FN``: (Default: "FV3LAM_wflow.xml")
   Name of the Rocoto workflow XML file that the experiment generation script creates. This file defines the workflow for the experiment.

``GLOBAL_VAR_DEFNS_FN``: (Default: "var_defns.sh")
   Name of the file (a shell script) containing definitions of the primary and secondary experiment variables (parameters). This file is sourced by many scripts (e.g., the J-job scripts corresponding to each workflow task) in order to make all the experiment variables available in those scripts. The primary variables are defined in the default configuration script (``config_defaults.sh``) and in ``config.sh``. The secondary experiment variables are generated by the experiment generation script. 

``EXTRN_MDL_ICS_VAR_DEFNS_FN``: (Default: "extrn_mdl_ics_var_defns.sh")
   Name of the file (a shell script) containing the definitions of variables associated with the external model from which ICs are generated. This file is created by the ``GET_EXTRN_ICS_TN`` task because the values of the variables it contains are not known before this task runs. The file is then sourced by the ``MAKE_ICS_TN`` task.

``EXTRN_MDL_LBCS_VAR_DEFNS_FN``: (Default: "extrn_mdl_lbcs_var_defns.sh")
   Name of the file (a shell script) containing the definitions of variables associated with the external model from which LBCs are generated. This file is created by the ``GET_EXTRN_LBCS_TN`` task because the values of the variables it contains are not known before this task runs. The file is then sourced by the ``MAKE_ICS_TN`` task.

``WFLOW_LAUNCH_SCRIPT_FN``: (Default: "launch_FV3LAM_wflow.sh")
   Name of the script that can be used to (re)launch the experiment's Rocoto workflow.

``WFLOW_LAUNCH_LOG_FN``: (Default: "log.launch_FV3LAM_wflow")
   Name of the log file that contains the output from successive calls to the workflow launch script (``WFLOW_LAUNCH_SCRIPT_FN``).

Forecast Parameters
===================
``DATE_FIRST_CYCL``: (Default: "YYYYMMDD")
   Starting date of the first forecast in the set of forecasts to run. Format is "YYYYMMDD". Note that this does not include the hour of the day.

``DATE_LAST_CYCL``: (Default: "YYYYMMDD")
   Starting date of the last forecast in the set of forecasts to run. Format is "YYYYMMDD". Note that this does not include the hour of the day.

``CYCL_HRS``: (Default: ( "HH1" "HH2" ))
   An array containing the hours of the day at which to launch forecasts. Forecasts are launched at these hours on each day from ``DATE_FIRST_CYCL`` to ``DATE_LAST_CYCL``, inclusive. Each element of this array must be a two-digit string representing an integer that is less than or equal to 23, e.g., "00", "03", "12", "23".

``INCR_CYCL_FREQ``: (Default: "24")
   Increment in hours for cycle frequency (cycl_freq). The default is "24", which means cycl_freq=24:00:00.

``FCST_LEN_HRS``: (Default: "24")
   The length of each forecast, in integer hours.

Model Configuration Parameters
=================================

``DT_ATMOS``: (Default: "")
   Time step for the outermost atmospheric model loop in seconds. This corresponds to the frequency at which the physics routines and the top level dynamics routine are called. (Note that one call to the top-level dynamics routine results in multiple calls to the horizontal dynamics, tracer transport, and vertical dynamics routines; see the `FV3 dycore documentation <https://www.gfdl.noaa.gov/wp-content/uploads/2020/02/FV3-Technical-Description.pdf>`__ for details.) Must be set. Takes an integer value.

..
   COMMENT: FV3 documentation says DT_ATMOS must be set, but in our code, the default value is "". What is the actual default value? And is the default set by the FV3 dycore rather than in the SRW App itself?

``RESTART_INTERVAL``: (Default: "0")
   Frequency of the output restart files in hours. Using the default interval ("0"), restart files are produced at the end of a forecast run. When ``RESTART_INTERVAL="1"``, restart files are produced every hour with the prefix "YYYYMMDD.HHmmSS." in the ``RESTART`` directory. 

``WRITE_DOPOST``: (Default: "FALSE")
   Flag that determines whether to use the INLINE POST option. If TRUE, the ``WRITE_DOPOST`` flag in the ``model_configure`` file will be set to "TRUE", and the post-processing tasks get called from within the weather model so that the post files (grib2) are output by the weather model at the same time that it outputs the dynf###.nc and phyf###.nc files. Setting ``WRITE_DOPOST="TRUE"``
   turns off the separate ``run_post`` task (``RUN_TASK_RUN_POST=FALSE``) in ``setup.sh``.

   ..
      Should there be an underscore in inline post? 

METplus Parameters
=====================

:ref:`METplus <MetplusComponent>` is a scientific verification framework that spans a wide range of temporal and spatial scales. Many of the METplus parameters are described below, but additional documentation for the METplus components is available on the `METplus website <https://dtcenter.org/community-code/metplus>`__. 

``MODEL``: (Default: "")
   String that specifies a descriptive name for the model being verified.
   
``MET_INSTALL_DIR``: (Default: "")
   Path to top-level directory of MET installation.

``METPLUS_PATH``: (Default: "")
   Path to top-level directory of METplus installation.

``MET_BIN_EXEC``: (Default: "bin")
   The name of the subdirectory of ``ufs-srweather-app`` where the METplus executable is installed.

..
   COMMENT: Check the definition above. Should it be a subdirectory of METplus instead of SRW? 

.. _METParamNote:

.. note::
   Where a date field is required: 
      * YYYY refers to the 4-digit valid year
      * MM refers to the 2-digit valid month
      * DD refers to the 2-digit valid day of the month
      * HH refers to the 2-digit valid hour of the day.
      * mm refers to the 2-digit valid minutes of the hour
      * SS refers to the two-digit valid seconds of the hour

``CCPA_OBS_DIR``: (Default: "")
   User-specified location of top-level directory where CCPA hourly precipitation files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA HPSS (if the user has access) via the ``get_obs_ccpa_tn`` task. (This task is activated in the workflow by setting ``RUN_TASK_GET_OBS_CCPA="TRUE"``). 
   METplus configuration files require the use of predetermined directory structure and file names. If the CCPA files are user-provided, they need to follow the anticipated naming structure: ``{YYYYMMDD}/ccpa.t{HH}z.01h.hrap.conus.gb2``, where YYYYMMDD and HH are as described in the note :ref:`above <METParamNote>`. 
   When pulling observations from NOAA HPSS, the data retrieved will be placed in the ``CCPA_OBS_DIR`` directory. This path must be defind as ``/<full-path-to-obs>/ccpa/proc``. METplus is configured to verify 01-, 03-, 06-, and 24-h accumulated precipitation using hourly CCPA files.    

.. note::
   There is a problem with the valid time in the metadata for files valid from 19 - 00 UTC (i.e., files under the "00" directory). The script to pull the CCPA data from the NOAA HPSS has an example of how to account for this as well as organizing the data into a more intuitive format: ``regional_workflow/scripts/exregional_get_ccpa_files.sh``. When a fix is provided, it will be accounted for in the ``exregional_get_ccpa_files.sh`` script.

``MRMS_OBS_DIR``: (Default: "")
   User-specified location of top-level directory where MRMS composite reflectivity files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA HPSS (if the user has access) via the ``get_obs_mrms_tn`` task (activated in workflow by setting ``RUN_TASK_GET_OBS_MRMS="TRUE"``). In the case of pulling observations directly from NOAA HPSS, the data retrieved will be placed in this directory. Please note, this path must be defind as ``/<full-path-to-obs>/mrms/proc. METplus configuration files require the use of predetermined directory structure and file names. Therefore, if the MRMS files are user-provided, they need to follow the anticipated naming structure: ``{YYYYMMDD}/MergedReflectivityQCComposite_00.50_{YYYYMMDD}-{HH}{mm}{SS}.grib2``, where YYYYMMDD and {HH}{mm}{SS} are as described in the note :ref:`above <METParamNote>`. 

``NDAS_OBS_DIR``: (Default: "")
   User-specified location of top-level directory where NDAS prepbufr files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA HPSS (if the user has access) via the get_obs_ndas_tn task (activated in workflow by setting ``RUN_TASK_GET_OBS_NDAS="TRUE"``). In the case of pulling observations directly from NOAA HPSS, the data retrieved will be placed in this directory. Please note, this path must be defind as ``/<full-path-to-obs>/ndas/proc``. METplus is configured to verify near-surface variables hourly and upper-air variables at times valid at 00 and 12 UTC with NDAS prepbufr files.  METplus configuration files require the use of predetermined file names. Therefore, if the NDAS files are user provided, they need to follow the anticipated naming structure: prepbufr.ndas.{YYYYMMDDHH}, where YYYYMMDD and HH are as described in the note :ref:`above <METParamNote>`. The script to pull the NDAS data from the NOAA HPSS has an example of how to rename the NDAS data into a more intuitive format with the valid time listed in the file name: ``regional_workflow/scripts/exregional_get_ndas_files.sh``.

Initial and Lateral Boundary Condition Generation Parameters
============================================================
``EXTRN_MDL_NAME_ICS``: (Default: "FV3GFS")
   The name of the external model that will provide fields from which initial condition (IC) files, surface files, and 0-th hour boundary condition files will be generated for input into the forecast model. Valid values: "GSMGFS" "FV3GFS" "RAP" "HRRR" "NAM"

``EXTRN_MDL_NAME_LBCS``: (Default: "FV3GFS")
   The name of the external model that will provide fields from which lateral boundary condition (LBC) files (except for the 0-th hour LBC file) will be generated for input into the forecast model. Valid values: "GSMGFS" "FV3GFS" "RAP" "HRRR" "NAM"

``LBC_SPEC_INTVL_HRS``: (Default: "6")
   The interval (in integer hours) at which LBC files will be generated. This is also referred to as the *boundary specification interval*. Note that the model specified in ``EXTRN_MDL_NAME_LBCS`` must have data available at a frequency greater than or equal to that implied by ``LBC_SPEC_INTVL_HRS``. For example, if ``LBC_SPEC_INTVL_HRS`` is set to "6", then the model must have data available at least every 6 hours. It is up to the user to ensure that this is the case.

``EXTRN_MDL_ICS_OFFSET_HRS``: (Default: "0")
   Users may wish to start a forecast using forecast data from a previous cycle of an external model. This variable sets the number of hours earlier the external model started than when the FV3 forecast configured here should start. For example, if the forecast should start from a 6 hour forecast of the GFS, then ``EXTRN_MDL_ICS_OFFSET_HRS="6"``.

``EXTRN_MDL_LBCS_OFFSET_HRS``: (Default: "")
   Users may wish to use lateral boundary conditions from a forecast that was started earlier than the initial time for the FV3 forecast configured here. This variable sets the number of hours earlier the external model started than when the FV3 forecast configured here should start. For example, if the forecast should use lateral boundary conditions from the GFS started 6 hours earlier, then ``EXTRN_MDL_LBCS_OFFSET_HRS="6"``. Note: the default value is model-dependent and set in ``set_extrn_mdl_params.sh``.

``FV3GFS_FILE_FMT_ICS``: (Default: "nemsio")
   If using the FV3GFS model as the source of the ICs (i.e., if ``EXTRN_MDL_NAME_ICS="FV3GFS"``), this variable specifies the format of the model files to use when generating the ICs. Valid values: "nemsio" "grib2" "netcdf"

``FV3GFS_FILE_FMT_LBCS``: (Default: "nemsio")
   If using the FV3GFS model as the source of the LBCs (i.e. if ``EXTRN_MDL_NAME_ICS="FV3GFS"``), this variable specifies the format of the model files to use when generating the LBCs. Valid values: "nemsio" "grib2" "netcdf"



Base Directories for External Model Files
===========================================

.. note::
   Note that these must be defined as null strings here so that if they are specified by the user in the experiment configuration file, they remain set to those values, and if not, they get set to machine-dependent values.

``EXTRN_MDL_SYSBASEDIR_ICS``: (Default: "")
   Base directory on the local machine containing external model files for generating ICs on the native grid. The way the full path containing these files is constructed depends on the user-specified external model for ICs (defined in ``EXTRN_MDL_NAME_ICS`` above).

``EXTRN_MDL_SYSBASEDIR_LBCS``: (Default: "")
   Base directory on the local machine containing external model files for generating LBCs on the native grid. The way the full path containing these files is constructed depends on the user-specified external model for LBCs (defined in ``EXTRN_MDL_NAME_LBCS`` above).


User-Staged External Model Directory and File Parameters
========================================================
``USE_USER_STAGED_EXTRN_FILES``: (Default: "FALSE")
   Flag that determines whether or not the workflow will look for the external model files needed for generating ICs and LBCs in user-specified directories (as opposed to fetching them from mass storage like NOAA HPSS).

``EXTRN_MDL_SOURCE_BASEDIR_ICS``: (Default: "/base/dir/containing/user/staged/extrn/mdl/files/for/ICs")
   Directory containing external model files for generating ICs. If ``USE_USER_STAGED_EXTRN_FILES`` is set to "TRUE", the workflow looks within this directory for a subdirectory named "YYYYMMDDHH", which contains the external model files specified by the array ``EXTRN_MDL_FILES_ICS``. This "YYYYMMDDHH" subdirectory corresponds to the start date and cycle hour of the forecast (see :ref:`above <METParamNote>`). These files will be used to generate the ICs on the native FV3-LAM grid. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to "FALSE".
 
``EXTRN_MDL_FILES_ICS``: (Default: "ICS_file1" "ICS_file2" "...")
   Array containing the file names to search for in the ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` directory. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to "FALSE".

``EXTRN_MDL_SOURCE_BASEDIR_LBCS``: (Default: "/base/dir/containing/user/staged/extrn/mdl/files/for/ICs")
   Analogous to ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` but for LBCs instead of ICs.

``EXTRN_MDL_FILES_LBCS``: (Default: " "LBCS_file1" "LBCS_file2" "...")
   Analogous to ``EXTRN_MDL_FILES_ICS`` but for LBCs instead of ICs.


NOMADS Parameters
======================

Set NOMADS online data associated parameters. 

``NOMADS``: (Default: "FALSE")
   Flag controlling whether or not using NOMADS online data.

``NOMADS_file_type``: (Default: "nemsio")
   Flag controlling the format of data.


CCPP Parameter
==============
``CCPP_PHYS_SUITE``: (Default: "FV3_GFS_v16")
   The :term:`CCPP` (Common Community Physics Package) physics suite to use for the forecast(s). The choice of physics suite determines the forecast model's namelist file, the diagnostics table file, the field table file, and the XML physics suite definition file that are staged in the experiment directory or the cycle directories under it. Current supported settings for this parameter are "FV3_GFS_v16" "FV3_RRFS_v1beta" "FV3_HRRR" and "FV3_WoFS".
   Other valid values include: 
   * "FV3_GFS_2017_gfdlmp"
   * "FV3_GFS_2017_gfdlmp_regional"
   * "FV3_GFS_v15p2"
   * "FV3_GFS_v15_thompson_mynn_lam3km"
   * "FV3_RRFS_v1alpha"

..
   COMMENT: "FV3_WoFS" technically has not been merged yet... and is called NSSL? What should I put for now? Current Default is "FV3_GFS_v15p2" - need to make sure we change that. 


.. include:: ConfigParameters.inc
