.. _ConfigWorkflow:

============================================================================================
Workflow Parameters: Configuring the Workflow in ``config.sh`` and ``config_defaults.sh``		
============================================================================================
To create the experiment directory and workflow when running the SRW Application, the user must create an experiment configuration file named ``config.sh``. This file contains experiment-specific information, such as dates, external model data, observation data, directories, and other relevant settings. To help the user, two sample configuration files have been included in the ``regional_workflow`` repository's ``ush`` directory: ``config.community.sh`` and ``config.nco.sh``. The first is for running experiments in community mode (``RUN_ENVIR`` set to "community"), and the second is for running experiments in "nco" mode (``RUN_ENVIR`` set to "nco"). Note that for this release, only "community" mode is supported. These files can be used as the starting point from which to generate a variety of experiment configurations for the SRW App.

There is an extensive list of experiment parameters that a user can set when configuring the experiment. Not all of these need to be explicitly set by the user in ``config.sh``. If a user does not define an entry in the ``config.sh`` script, either its value in ``config_defaults.sh`` will be used, or it will be reset depending on other parameters, such as the platform on which the experiment will be run (specified by ``MACHINE``). Note that ``config_defaults.sh`` contains the full list of experiment parameters that a user may set in ``config.sh`` (i.e., the user cannot set parameters in ``config.sh`` that are not initialized in ``config_defaults.sh``).

The following is a list of the parameters in the ``config_defaults.sh`` file. For each parameter, the default value and a brief description is given. 

Platform Environment
====================
``RUN_ENVIR``: (Default: "nco")
   This variable determines the workflow mode. The user can choose between two options: "nco" and "community". The "nco" mode uses a directory structure that mimics what is used in operations at NOAA/NCEP Central Operations (NCO) and at the NOAA/NCEP/Environmental Modeling Center (EMC), which works with NCO on pre-implementation testing. Specifics of the conventions used in "nco" mode can be found in the following `WCOSS Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/>`__ document:

   | NCEP Central Operations
   | WCOSS Implementation Standards
   | January 19, 2022
   | Version 11.0.0
   
   Setting ``RUN_ENVIR`` to "community" is recommended in most cases for users who are not planning to implement their code into operations at NCO.

``MACHINE``: (Default: "BIG_COMPUTER")
   The machine (a.k.a. platform or system) on which the workflow will run. Currently supported platforms are listed on the `SRW App Wiki page <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__. When running the SRW App on any ParellelWorks/NOAA Cloud system, use "NOAACLOUD" regardless of the underlying system (AWS, GCP, or Azure). When running the SRW App in a container, set ``MACHINE`` to "SINGULARITY" regardless of the underlying platform (including on NOAA Cloud systems). Valid values: ``"HERA"`` | ``"ORION"`` | ``"JET"`` | ``"CHEYENNE"`` | ``"GAEA"`` | ``"NOAACLOUD"`` | ``"STAMPEDE"`` | ``"ODIN"`` | ``"MACOS"`` | ``"LINUX"`` | ``"SINGULARITY"`` | ``"WCOSS_DELL_P3"``

``MACHINE_FILE``: (Default: "")
   Path to a configuration file with machine-specific settings. If none is provided, ``setup.sh`` will attempt to set the path to a configuration file for a supported platform.

``ACCOUNT``: (Default: "project_name")
   The account under which users submit jobs to the queue on the specified ``MACHINE``. To determine an appropriate ``ACCOUNT`` field for `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, users may run the ``groups`` command, which will return a list of projects that the user has permissions for. Not all of the listed projects/groups have an HPC allocation, but those that do are potentially valid account names. On some systems, the ``saccount_params`` command will display additional account details. 

``COMPILER``: (Default: "intel")
   Type of compiler invoked during the build step. Currently, this must be set manually (i.e., it is not inherited from the build system in the ``ufs-srweather-app`` directory). Valid values: ``"intel"`` | ``"gnu"``

``WORKFLOW_MANAGER``: (Default: "none")
   The workflow manager to use (e.g., "ROCOTO"). This is set to "none" by default, but if the machine name is set to a platform that supports Rocoto, this will be overwritten and set to "ROCOTO." Valid values: ``"rocoto"`` | ``"none"``

``NCORES_PER_NODE``: (Default: "")
   The number of cores available per node on the compute platform. Set for supported platforms in ``setup.sh``, but it is now also configurable for all platforms.

``LMOD_PATH``: (Default: "")
   Path to the LMOD shell file on the user's Linux system. It is set automatically for supported machines.

``BUILD_MOD_FN``: (Default: "")
   Name of alternative build module file to use if running on an unsupported platform. Is set automatically for supported machines.

``WFLOW_MOD_FN``: (Default: "")
   Name of alternative workflow module file to use if running on an unsupported platform. Is set automatically for supported machines.

.. _sched:

``SCHED``: (Default: "")
   The job scheduler to use (e.g., Slurm) on the specified ``MACHINE``. Leaving this an empty string allows the experiment generation script to set it automatically depending on the machine the workflow is running on. Valid values: ``"slurm"`` | ``"pbspro"`` | ``"lsf"`` | ``"lsfcray"`` | ``"none"``

Machine-Dependent Parameters:
-------------------------------
These parameters vary depending on machine. On `Level 1 and 2 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, the appropriate values for each machine can be viewed in the ``regional_workflow/ush/machine/<platform>.sh`` scripts. To specify a value other than the default, add these variables and the desired value in the ``config.sh`` file so that they override the ``config_defaults.sh`` and machine default values. 

``PARTITION_DEFAULT``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). This is the default partition to which Slurm submits workflow tasks. When a variable that designates the partition (e.g., ``PARTITION_HPSS``, ``PARTITION_FCST``; see below) is **not** specified, the task will be submitted to the default partition indicated in the ``PARTITION_DEFAULT`` variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values: ``""`` | ``"hera"`` | ``"normal"`` | ``"orion"`` | ``"sjet,vjet,kjet,xjet"`` | ``"workq"``

``CLUSTERS_DEFAULT``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). These are the default clusters to which Slurm submits workflow tasks. If ``CLUSTERS_HPSS`` or ``CLUSTERS_FCST`` (see below) are not specified, the task will be submitted to the default clusters indicated in this variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. 

``QUEUE_DEFAULT``: (Default: "")
   The default queue or QOS to which workflow tasks are submitted (QOS is Slurm's term for queue; it stands for "Quality of Service"). If the task's ``QUEUE_HPSS`` or ``QUEUE_FCST`` parameters (see below) are not specified, the task will be submitted to the queue indicated by this variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values: ``""`` | ``"batch"`` | ``"dev"`` | ``"normal"`` | ``"regular"`` | ``"workq"``

``PARTITION_HPSS``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). Tasks that get or create links to external model files are submitted to the partition specified in this variable. These links are needed to generate initial conditions (:term:`ICs`) and lateral boundary conditions (:term:`LBCs`) for the experiment. If this variable is not set or is set to an empty string, it will be (re)set to the ``PARTITION_DEFAULT`` value (if set) or to a machine-dependent value. Valid values: ``""`` | ``"normal"`` | ``"service"`` | ``"workq"``

``CLUSTERS_HPSS``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). Tasks that get or create links to external model files are submitted to the clusters specified in this variable. These links are needed to generate initial conditions (ICs) and lateral boundary conditions (LBCs) for the experiment. If this variable is not set or is set to an empty string, it will be (re)set to a machine-dependent value. 

``QUEUE_HPSS``: (Default: "")
   Tasks that get or create links to external model files are submitted to this queue, or QOS (QOS is Slurm's term for queue; it stands for "Quality of Service"). If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values: ``""`` | ``"batch"`` | ``"dev_transfer"`` | ``"normal"`` | ``"regular"`` | ``"workq"``

``PARTITION_FCST``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). The task that runs forecasts is submitted to this partition. If this variable is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Valid values: ``""`` | ``"hera"`` | ``"normal"`` | ``"orion"`` | ``"sjet,vjet,kjet,xjet"`` | ``"workq"``

``CLUSTERS_FCST``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., if ``SCHED`` is set to "slurm"). The task that runs forecasts is submitted to this cluster. If this variable is not set or is set to an empty string, it will be (re)set to a machine-dependent value. 

``QUEUE_FCST``: (Default: "")
   The task that runs a forecast is submitted to this queue, or QOS (QOS is Slurm's term for queue; it stands for "Quality of Service"). If this variable is not set or set to an empty string, it will be (re)set to a machine-dependent value. Valid values: ``""`` | ``"batch"`` | ``"dev"`` | ``"normal"`` | ``"regular"`` | ``"workq"``

Parameters for Running Without a Workflow Manager
=================================================
These settings control run commands for platforms without a workflow manager. Values will be ignored unless ``WORKFLOW_MANAGER="none"``.

``RUN_CMD_UTILS``: (Default: "mpirun -np 1")
   The run command for MPI-enabled pre-processing utilities (e.g., shave, orog, sfc_climo_gen). This can be left blank for smaller domains, in which case the executables will run without :term:`MPI`. Users may need to use a different command for launching an MPI-enabled executable depending on their machine and MPI installation.

``RUN_CMD_FCST``: (Default: "mpirun -np \${PE_MEMBER01}")
   The run command for the model forecast step. This will be appended to the end of the variable definitions file (``var_defns.sh``). Changing the ``${PE_MEMBER01}`` variable is **not** recommended; it refers to the number of MPI tasks that the Weather Model will expect to run with. Running the Weather Model with a different number of MPI tasks than the workflow has been set up for can lead to segmentation faults and other errors. It is also important to escape the ``$`` character or use single quotes here so that ``PE_MEMBER01`` is not referenced until runtime, since it is not defined at the beginning of the workflow generation script.

``RUN_CMD_POST``: (Default: "mpirun -np 1")
   The run command for post-processing (via the :term:`UPP`). Can be left blank for smaller domains, in which case UPP will run without :term:`MPI`.

.. _Cron:

Cron-Associated Parameters
==========================

Cron is a job scheduler accessed through the command-line on UNIX-like operating systems. It is useful for automating tasks such as the ``rocotorun`` command, which launches each workflow task in the SRW App. Cron periodically checks a cron table (aka crontab) to see if any tasks are are ready to execute. If so, it runs them. 

``USE_CRON_TO_RELAUNCH``: (Default: "FALSE")
   Flag that determines whether or not a line is added to the user's cron table, which calls the experiment launch script every ``CRON_RELAUNCH_INTVL_MNTS`` minutes.

``CRON_RELAUNCH_INTVL_MNTS``: (Default: "03")
   The interval (in minutes) between successive calls of the experiment launch script by a cron job to (re)launch the experiment (so that the workflow for the experiment kicks off where it left off). This is used only if ``USE_CRON_TO_RELAUNCH`` is set to "TRUE".

.. _DirParams:

Directory Parameters
====================
``EXPT_BASEDIR``: (Default: "")
   The full path to the base directory inside of which the experiment directory (``EXPT_SUBDIR``) will be created. If this is not specified or if it is set to an empty string, it will default to ``${HOMErrfs}/../../expt_dirs``, where ``${HOMErrfs}`` contains the full path to the ``regional_workflow`` directory.

``EXPT_SUBDIR``: (Default: "")
   A descriptive name of the user's choice for the experiment directory (*not* its full path). The full path to the experiment directory, which will be contained in the variable ``EXPTDIR``, will be:

   .. code-block:: console

      EXPTDIR="${EXPT_BASEDIR}/${EXPT_SUBDIR}"

   This parameter cannot be left as a null string.

``EXEC_SUBDIR``: (Default: "bin")
   The name of the subdirectory of ``ufs-srweather-app`` where executables are installed.

.. _NCOModeParms:

NCO Mode Parameters
===================
These variables apply only when using NCO mode (i.e., when ``RUN_ENVIR`` is set to "nco").

``COMINgfs``: (Default: "/base/path/of/directory/containing/gfs/input/files")
   The beginning portion of the path to the directory that contains files generated by the external model (FV3GFS). The initial and lateral boundary condition generation tasks need this path in order to create initial and boundary condition files for a given cycle on the native FV3-LAM grid. For a cycle that starts on the date specified by the variable YYYYMMDD (consisting of the 4-digit year, 2-digit month, and 2-digit day of the month) and the hour specified by the variable HH (consisting of the 2-digit hour of the day), the directory in which the workflow will look for the external model files is:

   .. code-block:: console

      $COMINgfs/gfs.$yyyymmdd/$hh/atmos

``FIXLAM_NCO_BASEDIR``: (Default: "")
   The base directory containing pregenerated grid, orography, and surface climatology files. For the pregenerated grid type specified in the variable ``PREDEF_GRID_NAME``, these "fixed" files are located in:

   .. code-block:: console

      ${FIXLAM_NCO_BASEDIR}/${PREDEF_GRID_NAME}

   The workflow scripts will create a symlink in the experiment directory that will point to a subdirectory (having the name of the grid being used) under this directory. This variable should be set to a null string in ``config_defaults.sh`` and specified by the user in the workflow configuration file (``config.sh``).

``STMP``: (Default: "/base/path/of/directory/containing/model/input/and/raw/output/files")
   The beginning portion of the path to the directory that will contain :term:`cycle-dependent` model input files, symlinks to :term:`cycle-independent` input files, and raw (i.e., before post-processing) forecast output files for a given :term:`cycle`. The format for cycle dates (cdate) is ``cdate="${YYYYMMDD}${HH}"``, where the date is specified using YYYYMMDD format, and the hour is specified using HH format. The files for a cycle date will be located in the following directory:

   .. code-block:: console

      $STMP/tmpnwprd/$RUN/$cdate

``NET, envir, RUN``:
   Variables used in forming the path to the directory that will contain the post-processor (:term:`UPP`) output files for a given cycle (see ``PTMP`` below). These are defined in the `WCOSS Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/ImplementationStandards.v11.0.0.pdf?>`__ document (pp. 4-5, 19-20) as follows:

   ``NET``: (Default: "rrfs")
      Model name (first level of ``com`` directory structure)

   ``envir``: (Default: "para")
      Set to "test" during the initial testing phase, "para" when running in parallel (on a schedule), and "prod" in production. (Second level of ``com`` directory structure.)

   ``RUN``: (Default: "experiment_name")
      Name of model run (third level of ``com`` directory structure).

``PTMP``: (Default: "/base/path/of/directory/containing/postprocessed/output/files")
   The beginning portion of the path to the directory that will contain the output files from the post-processor (:term:`UPP`) for a given cycle. For a cycle that starts on the date specified by YYYYMMDD and hour specified by HH (where YYYYMMDD and HH are as described above), the UPP output files will be placed in the following directory:
 
   .. code-block:: console

      $PTMP/com/$NET/$envir/$RUN.$yyyymmdd/$hh

Pre-Processing File Separator Parameters
========================================
``DOT_OR_USCORE``: (Default: "_")
   This variable sets the separator character(s) to use in the names of the grid, mosaic, and orography fixed files. Ideally, the same separator should be used in the names of these fixed files as in the surface climatology fixed files. Valid values: ``"_"`` | ``"."``

File Name Parameters
====================
``EXPT_CONFIG_FN``: (Default: "config.sh")
   Name of the user-specified configuration file for the forecast experiment.

``RGNL_GRID_NML_FN``: (Default: "regional_grid.nml")
   Name of the file containing namelist settings for the code that generates an "ESGgrid" regional grid.

``FV3_NML_BASE_SUITE_FN``: (Default: "input.nml.FV3")
   Name of the Fortran file containing the forecast model's base suite namelist (i.e., the portion of the namelist that is common to all physics suites).

``FV3_NML_YAML_CONFIG_FN``: (Default: "FV3.input.yml")
   Name of YAML configuration file containing the forecast model's namelist settings for various physics suites.

``FV3_NML_BASE_ENS_FN``: (Default: "input.nml.base_ens")
   Name of the Fortran file containing the forecast model's base ensemble namelist (i.e., the original namelist file from which each of the ensemble members' namelist files is generated).

``DIAG_TABLE_FN``: (Default: "diag_table")
   Name of the file specifying the fields that the forecast model will output.

``FIELD_TABLE_FN``: (Default: "field_table")
   Name of the file specifying the :term:`tracers` that the forecast model will read in from the :term:`IC/LBC` files.

``DATA_TABLE_FN``: (Default: "data_table")
   Name of the file containing the data table read in by the forecast model.

``MODEL_CONFIG_FN``: (Default: "model_configure")
   Name of the file containing settings and configurations for the :term:`NUOPC`/:term:`ESMF` component.

``NEMS_CONFIG_FN``: (Default: "nems.configure")
   Name of the file containing information about the various :term:`NEMS` components and their run sequence.

``FV3_EXEC_FN``: (Default: "ufs_model")
   Name of the forecast model executable stored in the executables directory (``EXECDIR``; set during experiment generation).

``FCST_MODEL``: (Default: "ufs-weather-model")
   Name of forecast model. Valid values: ``"ufs-weather-model"`` | ``"fv3gfs_aqm"``

``WFLOW_XML_FN``: (Default: "FV3LAM_wflow.xml")
   Name of the Rocoto workflow XML file that the experiment generation script creates. This file defines the workflow for the experiment.

``GLOBAL_VAR_DEFNS_FN``: (Default: "var_defns.sh")
   Name of the file (a shell script) containing definitions of the primary and secondary experiment variables (parameters). This file is sourced by many scripts (e.g., the J-job scripts corresponding to each workflow task) in order to make all the experiment variables available in those scripts. The primary variables are defined in the default configuration script (``config_defaults.sh``) and in ``config.sh``. The secondary experiment variables are generated by the experiment generation script. 

``EXTRN_MDL_ICS_VAR_DEFNS_FN``: (Default: "extrn_mdl_ics_var_defns.sh")
   Name of the file (a shell script) containing the definitions of variables associated with the external model from which :term:`ICs` are generated. This file is created by the ``GET_EXTRN_ICS_TN`` task because the values of the variables it contains are not known before this task runs. The file is then sourced by the ``MAKE_ICS_TN`` task.

``EXTRN_MDL_LBCS_VAR_DEFNS_FN``: (Default: "extrn_mdl_lbcs_var_defns.sh")
   Name of the file (a shell script) containing the definitions of variables associated with the external model from which :term:`LBCs` are generated. This file is created by the ``GET_EXTRN_LBCS_TN`` task because the values of the variables it contains are not known before this task runs. The file is then sourced by the ``MAKE_ICS_TN`` task.

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
   An array containing the hours of the day at which to launch forecasts. Forecasts are launched at these hours on each day from ``DATE_FIRST_CYCL`` to ``DATE_LAST_CYCL``, inclusive. Each element of this array must be a two-digit string representing an integer that is less than or equal to 23 (e.g., "00", "03", "12", "23").

``INCR_CYCL_FREQ``: (Default: "24")
   Increment in hours for cycle frequency (cycl_freq). The default is "24", which means cycl_freq=24:00:00.

``FCST_LEN_HRS``: (Default: "24")
   The length of each forecast, in integer hours.

Model Configuration Parameters
=================================

``DT_ATMOS``: (Default: "")
   Time step for the outermost atmospheric model loop in seconds. This corresponds to the frequency at which the physics routines and the top level dynamics routine are called. (Note that one call to the top-level dynamics routine results in multiple calls to the horizontal dynamics, tracer transport, and vertical dynamics routines; see the `FV3 dycore scientific documentation <https://repository.library.noaa.gov/view/noaa/30725>`__ for details.) Must be set. Takes an integer value. In the SRW App, a default value for ``DT_ATMOS`` appears in the ``set_predef_grid_params.sh`` script, but a different value can be set in ``config.sh``. 

``RESTART_INTERVAL``: (Default: "0")
   Frequency of the output restart files in hours. Using the default interval ("0"), restart files are produced at the end of a forecast run. When ``RESTART_INTERVAL="1"``, restart files are produced every hour with the prefix "YYYYMMDD.HHmmSS." in the ``RESTART`` directory. 

.. _InlinePost:

``WRITE_DOPOST``: (Default: "FALSE")
   Flag that determines whether to use the INLINE POST option. If TRUE, the ``WRITE_DOPOST`` flag in the ``model_configure`` file will be set to "TRUE", and the post-processing tasks get called from within the weather model so that the post-processed files (in :term:`grib2` format) are output by the Weather Model at the same time that it outputs the ``dynf###.nc`` and ``phyf###.nc`` files. Setting ``WRITE_DOPOST="TRUE"`` turns off the separate ``run_post`` task (i.e., ``RUN_TASK_RUN_POST`` is set to "FALSE") in ``setup.sh``.

METplus Parameters
=====================

:ref:`METplus <MetplusComponent>` is a scientific verification framework that spans a wide range of temporal and spatial scales. Many of the METplus parameters are described below, but additional documentation for the METplus components is available on the `METplus website <https://dtcenter.org/community-code/metplus>`__. 

``MODEL``: (Default: "")
   A descriptive name of the user's choice for the model being verified.
   
``MET_INSTALL_DIR``: (Default: "")
   Path to top-level directory of MET installation.

``METPLUS_PATH``: (Default: "")
   Path to top-level directory of METplus installation.

``MET_BIN_EXEC``: (Default: "bin")
   Location where METplus executables are installed.

.. _METParamNote:

.. note::
   Where a date field is required: 
      * ``YYYY`` refers to the 4-digit valid year
      * ``MM`` refers to the 2-digit valid month
      * ``DD`` refers to the 2-digit valid day of the month
      * ``HH`` refers to the 2-digit valid hour of the day
      * ``mm`` refers to the 2-digit valid minutes of the hour
      * ``SS`` refers to the two-digit valid seconds of the hour

``CCPA_OBS_DIR``: (Default: "")
   User-specified location of top-level directory where CCPA hourly precipitation files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA :term:`HPSS` (if the user has access) via the ``get_obs_ccpa_tn`` task. (This task is activated in the workflow by setting ``RUN_TASK_GET_OBS_CCPA="TRUE"``). 

   METplus configuration files require the use of a predetermined directory structure and file names. If the CCPA files are user-provided, they need to follow the anticipated naming structure: ``{YYYYMMDD}/ccpa.t{HH}z.01h.hrap.conus.gb2``, where YYYYMMDD and HH are as described in the note :ref:`above <METParamNote>`. When pulling observations from NOAA HPSS, the data retrieved will be placed in the ``CCPA_OBS_DIR`` directory. This path must be defind as ``/<full-path-to-obs>/ccpa/proc``. METplus is configured to verify 01-, 03-, 06-, and 24-h accumulated precipitation using hourly CCPA files.    

   .. note::
      There is a problem with the valid time in the metadata for files valid from 19 - 00 UTC (i.e., files under the "00" directory). The script to pull the CCPA data from the NOAA HPSS (``regional_workflow/scripts/exregional_get_ccpa_files.sh``) has an example of how to account for this and organize the data into a more intuitive format. When a fix is provided, it will be accounted for in the ``exregional_get_ccpa_files.sh`` script.

``MRMS_OBS_DIR``: (Default: "")
   User-specified location of top-level directory where MRMS composite reflectivity files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA :term:`HPSS` (if the user has access) via the ``get_obs_mrms_tn`` task (activated in the workflow by setting ``RUN_TASK_GET_OBS_MRMS="TRUE"``). When pulling observations directly from NOAA HPSS, the data retrieved will be placed in this directory. Please note, this path must be defind as ``/<full-path-to-obs>/mrms/proc``. 
   
   METplus configuration files require the use of a predetermined directory structure and file names. Therefore, if the MRMS files are user-provided, they need to follow the anticipated naming structure: ``{YYYYMMDD}/MergedReflectivityQCComposite_00.50_{YYYYMMDD}-{HH}{mm}{SS}.grib2``, where YYYYMMDD and {HH}{mm}{SS} are as described in the note :ref:`above <METParamNote>`. 

.. note::
   METplus is configured to look for a MRMS composite reflectivity file for the valid time of the forecast being verified; since MRMS composite reflectivity files do not always exactly match the valid time, a script (within the main script that retrieves MRMS data from the NOAA HPSS) is used to identify and rename the MRMS composite reflectivity file to match the valid time of the forecast. The script to pull the MRMS data from the NOAA HPSS has an example of the expected file-naming structure: ``regional_workflow/scripts/exregional_get_mrms_files.sh``. This script calls the script used to identify the MRMS file closest to the valid time: ``regional_workflow/ush/mrms_pull_topofhour.py``.


``NDAS_OBS_DIR``: (Default: "")
   User-specified location of top-level directory where NDAS prepbufr files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA :term:`HPSS` (if the user has access) via the ``get_obs_ndas_tn`` task (activated in the workflow by setting ``RUN_TASK_GET_OBS_NDAS="TRUE"``). When pulling observations directly from NOAA HPSS, the data retrieved will be placed in this directory. Please note, this path must be defined as ``/<full-path-to-obs>/ndas/proc``. METplus is configured to verify near-surface variables hourly and upper-air variables at 00 and 12 UTC with NDAS prepbufr files. 
   
   METplus configuration files require the use of predetermined file names. Therefore, if the NDAS files are user-provided, they need to follow the anticipated naming structure: ``prepbufr.ndas.{YYYYMMDDHH}``, where YYYYMMDD and HH are as described in the note :ref:`above <METParamNote>`. The script to pull the NDAS data from the NOAA HPSS (``regional_workflow/scripts/exregional_get_ndas_files.sh``) has an example of how to rename the NDAS data into a more intuitive format with the valid time listed in the file name.

Initial and Lateral Boundary Condition Generation Parameters
============================================================
``EXTRN_MDL_NAME_ICS``: (Default: "FV3GFS")
   The name of the external model that will provide fields from which initial condition (IC) files, surface files, and 0-th hour boundary condition files will be generated for input into the forecast model. Valid values: ``"GSMGFS"`` | ``"FV3GFS"`` | ``"RAP"`` | ``"HRRR"`` | ``"NAM"``

``EXTRN_MDL_NAME_LBCS``: (Default: "FV3GFS")
   The name of the external model that will provide fields from which lateral boundary condition (LBC) files (except for the 0-th hour LBC file) will be generated for input into the forecast model. Valid values: ``"GSMGFS"`` | ``"FV3GFS"`` | ``"RAP"`` | ``"HRRR"`` | ``"NAM"``

``LBC_SPEC_INTVL_HRS``: (Default: "6")
   The interval (in integer hours) at which LBC files will be generated. This is also referred to as the *boundary specification interval*. Note that the model selected in ``EXTRN_MDL_NAME_LBCS`` must have data available at a frequency greater than or equal to that implied by ``LBC_SPEC_INTVL_HRS``. For example, if ``LBC_SPEC_INTVL_HRS`` is set to "6", then the model must have data available at least every 6 hours. It is up to the user to ensure that this is the case.

``EXTRN_MDL_ICS_OFFSET_HRS``: (Default: "0")
   Users may wish to start a forecast using forecast data from a previous cycle of an external model. This variable indicates how many hours earlier the external model started than the FV3 forecast configured here. For example, if the forecast should start from a 6-hour forecast of the GFS, then ``EXTRN_MDL_ICS_OFFSET_HRS="6"``.

``EXTRN_MDL_LBCS_OFFSET_HRS``: (Default: "")
   Users may wish to use lateral boundary conditions from a forecast that was started earlier than the start of the forecast configured here. This variable indicates how many hours earlier the external model started than the FV3 forecast configured here. For example, if the forecast should use lateral boundary conditions from the GFS started 6 hours earlier, then ``EXTRN_MDL_LBCS_OFFSET_HRS="6"``. Note: the default value is model-dependent and is set in ``set_extrn_mdl_params.sh``.

``FV3GFS_FILE_FMT_ICS``: (Default: "nemsio")
   If using the FV3GFS model as the source of the :term:`ICs` (i.e., if ``EXTRN_MDL_NAME_ICS="FV3GFS"``), this variable specifies the format of the model files to use when generating the ICs. Valid values: ``"nemsio"`` | ``"grib2"`` | ``"netcdf"``

``FV3GFS_FILE_FMT_LBCS``: (Default: "nemsio")
   If using the FV3GFS model as the source of the :term:`LBCs` (i.e., if ``EXTRN_MDL_NAME_ICS="FV3GFS"``), this variable specifies the format of the model files to use when generating the LBCs. Valid values: ``"nemsio"`` | ``"grib2"`` | ``"netcdf"``



Base Directories for External Model Files
===========================================

.. note::
   These variables must be defined as null strings in ``config_defaults.sh`` so that if they are specified by the user in the experiment configuration file (``config.sh``), they remain set to those values, and if not, they get set to machine-dependent values.

``EXTRN_MDL_SYSBASEDIR_ICS``: (Default: "")
   Base directory on the local machine containing external model files for generating :term:`ICs` on the native grid. The way the full path containing these files is constructed depends on the user-specified external model for ICs (defined in ``EXTRN_MDL_NAME_ICS`` above).

``EXTRN_MDL_SYSBASEDIR_LBCS``: (Default: "")
   Base directory on the local machine containing external model files for generating :term:`LBCs` on the native grid. The way the full path containing these files is constructed depends on the user-specified external model for LBCs (defined in ``EXTRN_MDL_NAME_LBCS`` above).


User-Staged External Model Directory and File Parameters
========================================================
``USE_USER_STAGED_EXTRN_FILES``: (Default: "FALSE")
   Flag that determines whether the workflow will look for the external model files needed for generating :term:`ICs` and :term:`LBCs` in user-specified directories (rather than fetching them from mass storage like NOAA :term:`HPSS`).

``EXTRN_MDL_SOURCE_BASEDIR_ICS``: (Default: "/base/dir/containing/user/staged/extrn/mdl/files/for/ICs")
   Directory containing external model files for generating ICs. If ``USE_USER_STAGED_EXTRN_FILES`` is set to "TRUE", the workflow looks within this directory for a subdirectory named "YYYYMMDDHH", which contains the external model files specified by the array ``EXTRN_MDL_FILES_ICS``. This "YYYYMMDDHH" subdirectory corresponds to the start date and cycle hour of the forecast (see :ref:`above <METParamNote>`). These files will be used to generate the :term:`ICs` on the native FV3-LAM grid. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to "FALSE".
 
``EXTRN_MDL_FILES_ICS``: (Default: "ICS_file1" "ICS_file2" "...")
   Array containing the file names to search for in the ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` directory. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to "FALSE".

``EXTRN_MDL_SOURCE_BASEDIR_LBCS``: (Default: "/base/dir/containing/user/staged/extrn/mdl/files/for/ICs")
   Analogous to ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` but for :term:`LBCs` instead of :term:`ICs`.
   Directory containing external model files for generating LBCs. If ``USE_USER_STAGED_EXTRN_FILES`` is set to "TRUE", the workflow looks within this directory for a subdirectory named "YYYYMMDDHH", which contains the external model files specified by the array ``EXTRN_MDL_FILES_LBCS``. This "YYYYMMDDHH" subdirectory corresponds to the start date and cycle hour of the forecast (see :ref:`above <METParamNote>`). These files will be used to generate the :term:`LBCs` on the native FV3-LAM grid. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to "FALSE".

``EXTRN_MDL_FILES_LBCS``: (Default: " "LBCS_file1" "LBCS_file2" "...")
   Analogous to ``EXTRN_MDL_FILES_ICS`` but for :term:`LBCs` instead of :term:`ICs`. Array containing the file names to search for in the ``EXTRN_MDL_SOURCE_BASEDIR_LBCS`` directory. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to "FALSE".


NOMADS Parameters
======================

Set parameters associated with NOMADS online data. 

``NOMADS``: (Default: "FALSE")
   Flag controlling whether to use NOMADS online data.

``NOMADS_file_type``: (Default: "nemsio")
   Flag controlling the format of the data. Valid values: ``"GRIB2"`` | ``"grib2"`` | ``"NEMSIO"`` | ``"nemsio"``

.. _CCPP_Params:

CCPP Parameter
===============
``CCPP_PHYS_SUITE``: (Default: "FV3_GFS_v16")
   This parameter indicates which :term:`CCPP` (Common Community Physics Package) physics suite to use for the forecast(s). The choice of physics suite determines the forecast model's namelist file, the diagnostics table file, the field table file, and the XML physics suite definition file, which are staged in the experiment directory or the :term:`cycle` directories under it. 
   
   **Current supported settings for this parameter are:** 

   | ``"FV3_GFS_v16"`` 
   | ``"FV3_RRFS_v1beta"`` 
   | ``"FV3_HRRR"``
   | ``"FV3_WoFS_v0"``

   **Other valid values include:**

   | ``"FV3_GFS_2017_gfdlmp"``
   | ``"FV3_GFS_2017_gfdlmp_regional"``
   | ``"FV3_GFS_v15p2"``
   | ``"FV3_GFS_v15_thompson_mynn_lam3km"``

Stochastic Physics Parameters
================================

For the most updated and detailed documentation of these parameters, see the `UFS Stochastic Physics Documentation <https://stochastic-physics.readthedocs.io/en/release-public-v3/namelist_options.html>`__.

``NEW_LSCALE``: (Default: "TRUE") 
   Use correct formula for converting a spatial legnth scale into spectral space. 

Specific Humidity (SHUM) Perturbation Parameters
---------------------------------------------------

``DO_SHUM``: (Default: "FALSE")
   Flag to turn Specific Humidity (SHUM) perturbations on or off. SHUM perturbations multiply the low-level specific humidity by a small random number at each time-step. The SHUM scheme attempts to address missing physics phenomena (e.g., cold pools, gust fronts) most active in convective regions. 

``ISEED_SHUM``: (Default: "2")
   Seed for setting the SHUM random number sequence.

``SHUM_MAG``: (Default: "0.006") 
   Amplitudes of random patterns. Corresponds to the variable ``shum`` in ``input.nml``.

``SHUM_LSCALE``: (Default: "150000")
   Decorrelation spatial scale in meters.

``SHUM_TSCALE``: (Default: "21600")
   Decorrelation timescale in seconds. Corresponds to the variable ``shum_tau`` in ``input.nml``.

``SHUM_INT``: (Default: "3600")
   Interval in seconds to update random pattern (optional). Perturbations still get applied at every time-step. Corresponds to the variable ``shumint`` in ``input.nml``.

.. _SPPT:

Stochastically Perturbed Physics Tendencies (SPPT) Parameters
-----------------------------------------------------------------

SPPT perturbs full physics tendencies *after* the call to the physics suite, unlike :ref:`SPP <SPP>` (below), which perturbs specific tuning parameters within a physics scheme. 

``DO_SPPT``: (Default: "FALSE")
   Flag to turn Stochastically Perturbed Physics Tendencies (SPPT) on or off. SPPT multiplies the physics tendencies by a random number between 0 and 2 before updating the model state. This addresses error in the physics parameterizations (either missing physics or unresolved subgrid processes). It is most active in the boundary layer and convective regions. 

``ISEED_SPPT``: (Default: "1") 
   Seed for setting the SPPT random number sequence.

``SPPT_MAG``: (Default: "0.7")
   Amplitude of random patterns. Corresponds to the variable ``sppt`` in ``input.nml``.

``SPPT_LOGIT``: (Default: "TRUE")
   Limits the SPPT perturbations to between 0 and 2. Should be "TRUE"; otherwise the model will crash.

``SPPT_LSCALE``: (Default: "150000")
   Decorrelation spatial scale in meters. 

``SPPT_TSCALE``: (Default: "21600") 
   Decorrelation timescale in seconds. Corresponds to the variable ``sppt_tau`` in ``input.nml``.
   
``SPPT_INT``: (Default: "3600") 
   Interval in seconds to update random pattern (optional parameter). Perturbations still get applied at every time-step. Corresponds to the variable ``spptint`` in ``input.nml``.

``SPPT_SFCLIMIT``: (Default: "TRUE")
   When "TRUE", tapers the SPPT perturbations to zero at the model's lowest level, which reduces model crashes. 

``USE_ZMTNBLCK``: (Default: "FALSE")
   When "TRUE", do not apply perturbations below the dividing streamline that is diagnosed by the gravity wave drag, mountain blocking scheme

Stochastic Kinetic Energy Backscatter (SKEB) Parameters
----------------------------------------------------------

``DO_SKEB``: (Default: "FALSE")
   Flag to turn Stochastic Kinetic Energy Backscatter (SKEB) on or off. SKEB adds wind perturbations to the model state. Perturbations are random in space/time, but amplitude is determined by a smoothed dissipation estimate provided by the :term:`dynamical core`. SKEB addresses errors in the dynamics more active in the mid-latitudes.

``ISEED_SKEB``: (Default: "3")
   Seed for setting the SHUM random number sequence.

``SKEB_MAG``: (Default: "0.5") 
   Amplitude of random patterns. Corresponds to the variable ``skeb`` in ``input.nml``.

``SKEB_LSCALE``: (Default: "150000")
   Decorrelation spatial scale in meters. 

``SKEB_TSCALE``: (Default: "21600")
   Decorrelation timescale in seconds. Corresponds to the variable ``skeb_tau`` in ``input.nml``.

``SKEB_INT``: (Default: "3600")
   Interval in seconds to update random pattern (optional). Perturbations still get applied every time-step. Corresponds to the variable ``skebint`` in ``input.nml``.

``SKEBNORM``: (Default: "1")
   Patterns:
      * 0-random pattern is stream function
      * 1-pattern is K.E. norm
      * 2-pattern is vorticity

``SKEB_VDOF``: (Default: "10")
   The number of degrees of freedom in the vertical direction for the SKEB random pattern. 

.. _SPP:

Parameters for Stochastically Perturbed Parameterizations (SPP)
------------------------------------------------------------------

SPP perturbs specific tuning parameters within a physics :term:`parameterization` (unlike :ref:`SPPT <SPPT>`, which multiplies overall physics tendencies by a random perturbation field *after* the call to the physics suite). Each SPP option is an array, applicable (in order) to the :term:`RAP`/:term:`HRRR`-based parameterization listed in ``SPP_VAR_LIST``. Enter each value of the array in ``config.sh`` as shown below without commas or single quotes (e.g., ``SPP_VAR_LIST=( "pbl" "sfc" "mp" "rad" "gwd"`` ). Both commas and single quotes will be added by Jinja when creating the namelist.

.. note::
   SPP is currently only available for specific physics schemes used in the RAP/HRRR physics suite. Users need to be aware of which :term:`SDF` is chosen when turning this option on. Among the supported physics suites, the full set of parameterizations can only be used with the ``FV3_HRRR`` option for ``CCPP_PHYS_SUITE``.

``DO_SPP``: (Default: "false")
   Flag to turn SPP on or off. SPP perturbs parameters or variables with unknown or uncertain magnitudes within the physics code based on ranges provided by physics experts.

``ISEED_SPP``: (Default: ( "4" "4" "4" "4" "4" ) )
   Seed for setting the random number sequence for the perturbation pattern. 

``SPP_MAG_LIST``: (Default: ( "0.2" "0.2" "0.75" "0.2" "0.2" ) ) 
   SPP perturbation magnitudes used in each parameterization. Corresponds to the variable ``spp_prt_list`` in ``input.nml``

``SPP_LSCALE``: (Default: ( "150000.0" "150000.0" "150000.0" "150000.0" "150000.0" ) )
   Decorrelation spatial scales in meters.
   
``SPP_TSCALE``: (Default: ( "21600.0" "21600.0" "21600.0" "21600.0" "21600.0" ) ) 
   Decorrelation timescales in seconds. Corresponds to the variable ``spp_tau`` in ``input.nml``.

``SPP_SIGTOP1``: (Default: ( "0.1" "0.1" "0.1" "0.1" "0.1") )
   Controls vertical tapering of perturbations at the tropopause and corresponds to the lower sigma level at which to taper perturbations to zero. 

``SPP_SIGTOP2``: (Default: ( "0.025" "0.025" "0.025" "0.025" "0.025" ) )
   Controls vertical tapering of perturbations at the tropopause and corresponds to the upper sigma level at which to taper perturbations to zero.

``SPP_STDDEV_CUTOFF``: (Default: ( "1.5" "1.5" "2.5" "1.5" "1.5" ) )
   Limit for possible perturbation values in standard deviations from the mean.

``SPP_VAR_LIST``: (Default: ( "pbl" "sfc" "mp" "rad" "gwd" ) )
   The list of parameterizations to perturb: planetary boundary layer (PBL), surface physics (SFC), microphysics (MP), radiation (RAD), gravity wave drag (GWD). Valid values: ``"pbl"`` | ``"sfc"`` | ``"rad"`` | ``"gwd"`` | ``"mp"``


Land Surface Model (LSM) SPP
-------------------------------

Land surface perturbations can be applied to land model parameters and land model prognostic variables. The LSM scheme is intended to address errors in the land model and land-atmosphere interactions. LSM perturbations include soil moisture content (SMC) (volume fraction), vegetation fraction (VGF), albedo (ALB), salinity (SAL), emissivity (EMI), surface roughness (ZOL) (in cm), and soil temperature (STC). Perturbations to soil moisture content (SMC) are only applied at the first time step. Only five perturbations at a time can be applied currently, but all seven are shown below. In addition, only one unique *iseed* value is allowed at the moment, and it is used for each pattern.

The parameters below turn on SPP in Noah or RUC LSM (support for Noah MP is in progress). Please be aware of the :term:`SDF` that you choose if you wish to turn on Land Surface Model (LSM) SPP. SPP in LSM schemes is handled in the ``&nam_sfcperts`` namelist block instead of in ``&nam_sppperts``, where all other SPP is implemented. The default perturbation frequency is determined by the ``fhcyc`` namelist entry. Since that parameter is set to zero in the SRW App, use ``LSM_SPP_EACH_STEP`` to perturb every time step. 

``DO_LSM_SPP``: (Default: "false") 
   Turns on Land Surface Model (LSM) Stochastic Physics Parameterizations (SPP). When "TRUE", sets ``lndp_type=2``, which applies land perturbations to the selected paramaters using a newer scheme designed for data assimilation (DA) ensemble spread. LSM SPP perturbs uncertain land surface fields ("smc" "vgf" "alb" "sal" "emi" "zol" "stc") based on recommendations from physics experts. 

``LSM_SPP_TSCALE``: (Default: ( ( "21600" "21600" "21600" "21600" "21600" "21600" "21600" ) ) )
   Decorrelation timescales in seconds. 

``LSM_SPP_LSCALE``: (Default: ( ( "150000" "150000" "150000" "150000" "150000" "150000" "150000" ) ) )
   Decorrelation spatial scales in meters.

``ISEED_LSM_SPP``: (Default: ("9") )
   Seed to initialize the random perturbation pattern.

``LSM_SPP_VAR_LIST``: (Default: ( ( "smc" "vgf" "alb" "sal" "emi" "zol" "stc" ) ) )
   Indicates which LSM variables to perturb. 

``LSM_SPP_MAG_LIST``: (Default: ( ( "0.2" "0.001" "0.001" "0.001" "0.001" "0.001" "0.2" ) ) )
   Sets the maximum random pattern amplitude for each of the LSM perturbations. 

``LSM_SPP_EACH_STEP``: (Default: "true") 
   When set to "TRUE", it sets ``lndp_each_step=.true.`` and perturbs each time step. 

.. _PredefGrid:

Predefined Grid Parameters
==========================
``PREDEF_GRID_NAME``: (Default: "")
   This parameter indicates which (if any) predefined regional grid to use for the experiment. Setting ``PREDEF_GRID_NAME`` provides a convenient method of specifying a commonly used set of grid-dependent parameters. The predefined grid settings can be viewed in the script ``ush/set_predef_grid_params.sh``. 
   
   **Currently supported options:**
   
   | ``"RRFS_CONUS_25km"``
   | ``"RRFS_CONUS_13km"``
   | ``"RRFS_CONUS_3km"``
   | ``"SUBCONUS_Ind_3km"`` 
   
   **Other valid values include:**

   | ``"CONUS_25km_GFDLgrid"`` 
   | ``"CONUS_3km_GFDLgrid"``
   | ``"EMC_AK"`` 
   | ``"EMC_HI"`` 
   | ``"EMC_PR"`` 
   | ``"EMC_GU"`` 
   | ``"GSL_HAFSV0.A_25km"`` 
   | ``"GSL_HAFSV0.A_13km"`` 
   | ``"GSL_HAFSV0.A_3km"`` 
   | ``"GSD_HRRR_AK_50km"``
   | ``"RRFS_AK_13km"``
   | ``"RRFS_AK_3km"`` 
   | ``"RRFS_CONUScompact_25km"``
   | ``"RRFS_CONUScompact_13km"``
   | ``"RRFS_CONUScompact_3km"``
   | ``"RRFS_NA_13km"`` 
   | ``"RRFS_NA_3km"``
   | ``"RRFS_SUBCONUS_3km"`` 
   | ``"WoFS_3km"``

.. note::

   * If ``PREDEF_GRID_NAME`` is set to a valid predefined grid name, the grid generation method, the (native) grid parameters, and the write component grid parameters are set to predefined values for the specified grid, overwriting any settings of these parameters in the user-specified experiment configuration file (``config.sh``). In addition, if the time step ``DT_ATMOS`` and the computational parameters (``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE``) are not specified in that configuration file, they are also set to predefined values for the specified grid.

   * If ``PREDEF_GRID_NAME`` is set to an empty string, it implies that the user will provide the native grid parameters in the user-specified experiment configuration file (``config.sh``).  In this case, the grid generation method, the native grid parameters, the write component grid parameters, the main time step (``DT_ATMOS``), and the computational parameters (``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE``) must be set in the configuration file. Otherwise, the values of the parameters in the default experiment configuration file (``config_defaults.sh``) will be used.


.. _ConfigParameters:

Grid Generation Parameters
==========================
``GRID_GEN_METHOD``: (Default: "")
   This variable specifies which method to use to generate a regional grid in the horizontal plane. The values that it can take on are:

   * **"ESGgrid":** The "ESGgrid" method will generate a regional version of the Extended Schmidt Gnomonic (ESG) grid using the map projection developed by Jim Purser of EMC (:cite:t:`Purser_2020`). "ESGgrid" is the preferred grid option. 

   * **"GFDLgrid":** The "GFDLgrid" method first generates a "parent" global cubed-sphere grid. Then a portion from tile 6 of the global grid is used as the regional grid. This regional grid is referred to in the grid generation scripts as "tile 7," even though it does not correspond to a complete tile. The forecast is run only on the regional grid (i.e., on tile 7, not on tiles 1 through 6). Note that the "GFDLgrid" method is the legacy grid generation method. It is not supported in *all* predefined domains. 

.. attention::

   If the experiment uses a **predefined grid** (i.e., if ``PREDEF_GRID_NAME`` is set to the name of a valid predefined grid), then ``GRID_GEN_METHOD`` will be reset to the value of ``GRID_GEN_METHOD`` for that grid. This will happen regardless of whether ``GRID_GEN_METHOD`` is assigned a value in the experiment configuration file; any value assigned will be overwritten.

.. note::

   If the experiment uses a **user-defined grid** (i.e., if ``PREDEF_GRID_NAME`` is set to a null string), then ``GRID_GEN_METHOD`` must be set in the experiment configuration file. Otherwise, the experiment generation will fail because the generation scripts check to ensure that the grid name is set to a non-empty string before creating the experiment directory.

.. _ESGgrid:

ESGgrid Settings
-------------------

The following parameters must be set if using the "ESGgrid" method to generate a regional grid (i.e., when ``GRID_GEN_METHOD="ESGgrid"``). 

``ESGgrid_LON_CTR``: (Default: "")
   The longitude of the center of the grid (in degrees).

``ESGgrid_LAT_CTR``: (Default: "")
   The latitude of the center of the grid (in degrees).

``ESGgrid_DELX``: (Default: "")
   The cell size in the zonal direction of the regional grid (in meters).

``ESGgrid_DELY``: (Default: "")
   The cell size in the meridional direction of the regional grid (in meters).

``ESGgrid_NX``: (Default: "")
   The number of cells in the zonal direction on the regional grid.

``ESGgrid_NY``: (Default: "")
   The number of cells in the meridional direction on the regional grid.

``ESGgrid_PAZI``: (Default: "")
   The rotational parameter for the "ESGgrid" (in degrees).

``ESGgrid_WIDE_HALO_WIDTH``: (Default: "")
   The width (in number of grid cells) of the :term:`halo` to add around the regional grid before shaving the halo down to the width(s) expected by the forecast model. 

.. _WideHalo:

.. note::
   A :term:`halo` is the strip of cells surrounding the regional grid; the halo is used to feed in the lateral boundary conditions to the grid. The forecast model requires **grid** files containing 3-cell- and 4-cell-wide halos and **orography** files with 0-cell- and 3-cell-wide halos. In order to generate grid and orography files with appropriately-sized halos, the grid and orography tasks create preliminary files with halos around the regional domain of width ``ESGgrid_WIDE_HALO_WIDTH`` cells. The files are then read in and "shaved" down to obtain grid files with 3-cell-wide and 4-cell-wide halos and orography files with 0-cell-wide and 3-cell-wide halos. The original halo that gets shaved down is referred to as the "wide" halo because it is wider than the 0-cell-wide, 3-cell-wide, and 4-cell-wide halos that users eventually end up with. Note that the grid and orography files with the wide halo are only needed as intermediates in generating the files with 0-cell-, 3-cell-, and 4-cell-wide halos; they are not needed by the forecast model.

GFDLgrid Settings
---------------------

The following parameters must be set if using the "GFDLgrid" method to generate a regional grid (i.e., when ``GRID_GEN_METHOD="GFDLgrid"``). Note that the regional grid is defined with respect to a "parent" global cubed-sphere grid. Thus, all the parameters for a global cubed-sphere grid must be specified even though the model equations are integrated only on the regional grid. Tile 6 has arbitrarily been chosen as the tile to use to orient the global parent grid on the sphere (Earth). For convenience, the regional grid is denoted as "tile 7" even though it is embedded within tile 6 (i.e., it doesn't extend beyond the boundary of tile 6). Its exact location within tile 6 is determined by specifying the starting and ending i- and j-indices of the regional grid on tile 6, where ``i`` is the grid index in the x direction and ``j`` is the grid index in the y direction. All of this information is set in the variables below. 

``GFDLgrid_LON_T6_CTR``: (Default: "")
   Longitude of the center of tile 6 (in degrees).

``GFDLgrid_LAT_T6_CTR``: (Default: "")
   Latitude of the center of tile 6 (in degrees).

``GFDLgrid_NUM_CELLS``: (Default: "")
   Number of grid cells in either of the two horizontal directions (x and y) on each of the six tiles of the parent global cubed-sphere grid. Valid values: ``"48"`` | ``"96"`` | ``"192"`` | ``"384"`` | ``"768"`` | ``"1152"`` | ``"3072"``

   To give an idea of what these values translate to in terms of grid cell size in kilometers, we list below the approximate grid cell size on a uniform global grid having the specified value of ``GFDLgrid_NUM_CELLS``, where by "uniform" we mean with Schmidt stretch factor ``GFDLgrid_STRETCH_FAC="1"`` (although in regional applications ``GFDLgrid_STRETCH_FAC`` will typically be set to a value greater than ``"1"`` to obtain a smaller grid size on tile 6):

         +---------------------+--------------------+
         | GFDLgrid_NUM_CELLS  | typical cell size  |
         +=====================+====================+
         |  48                 |     208 km         |
         +---------------------+--------------------+
         |  96                 |     104 km         |
         +---------------------+--------------------+
         | 192                 |      52 km         |
         +---------------------+--------------------+
         | 384                 |      26 km         |
         +---------------------+--------------------+
         | 768                 |      13 km         |
         +---------------------+--------------------+
         | 1152                |      8.7 km        |
         +---------------------+--------------------+
         | 3072                |      3.3 km        |
         +---------------------+--------------------+

      Note that these are only typical cell sizes. The actual cell size on the global grid tiles varies somewhat as we move across a tile (and is dependent on ``GFDLgrid_STRETCH_FAC``).


``GFDLgrid_STRETCH_FAC``: (Default: "")
   Stretching factor used in the Schmidt transformation applied to the parent cubed-sphere grid. Setting the Schmidt stretching factor to a value greater than 1 shrinks tile 6, while setting it to a value less than 1 (but still greater than 0) expands it. The remaining 5 tiles change shape as necessary to maintain global coverage of the grid.

``GFDLgrid_REFINE_RATIO``: (Default: "")
   Cell refinement ratio for the regional grid. It refers to the number of cells in either the x or y direction on the regional grid (tile 7) that abut one cell on its parent tile (tile 6).

``GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G``: (Default: "")
   i-index on tile 6 at which the regional grid (tile 7) starts.

``GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G``: (Default: "")
   i-index on tile 6 at which the regional grid (tile 7) ends.

``GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G``: (Default: "")
   j-index on tile 6 at which the regional grid (tile 7) starts.

``GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G``: (Default: "")
   j-index on tile 6 at which the regional grid (tile 7) ends.

``GFDLgrid_USE_NUM_CELLS_IN_FILENAMES``: (Default: "")
   Flag that determines the file naming convention to use for grid, orography, and surface climatology files (or, if using pregenerated files, the naming convention that was used to name these files).  These files usually start with the string ``"C${RES}_"``, where ``RES`` is an integer. In the global forecast model, ``RES`` is the number of points in each of the two horizontal directions (x and y) on each tile of the global grid (defined here as ``GFDLgrid_NUM_CELLS``). If this flag is set to "TRUE", ``RES`` will be set to ``GFDLgrid_NUM_CELLS`` just as in the global forecast model. If it is set to "FALSE", we calculate (in the grid generation task) an "equivalent global uniform cubed-sphere resolution" -- call it ``RES_EQUIV`` -- and then set ``RES`` equal to it. ``RES_EQUIV`` is the number of grid points in each of the x and y directions on each tile that a global UNIFORM (i.e., stretch factor of 1) cubed-sphere grid would need to have in order to have the same average grid size as the regional grid. This is a more useful indicator of the grid size because it takes into account the effects of ``GFDLgrid_NUM_CELLS``, ``GFDLgrid_STRETCH_FAC``, and ``GFDLgrid_REFINE_RATIO`` in determining the regional grid's typical grid size, whereas simply setting ``RES`` to ``GFDLgrid_NUM_CELLS`` doesn't take into account the effects of ``GFDLgrid_STRETCH_FAC`` and ``GFDLgrid_REFINE_RATIO`` on the regional grid's resolution. Nevertheless, some users still prefer to use ``GFDLgrid_NUM_CELLS`` in the file names, so we allow for that here by setting this flag to "TRUE".

Computational Forecast Parameters
=================================

``LAYOUT_X, LAYOUT_Y``: (Default: "")
   The number of :term:`MPI` tasks (processes) to use in the two horizontal directions (x and y) of the regional grid when running the forecast model.

``BLOCKSIZE``: (Default: "")
   The amount of data that is passed into the cache at a time.

.. note::

   In ``config_defaults.sh`` these parameters are set to null strings so that:

   #. If the experiment is using a predefined grid and the user sets the ``BLOCKSIZE`` parameter in the user-specified experiment configuration file (i.e., ``config.sh``), that value will be used in the forecast(s). Otherwise, the default ``BLOCKSIZE`` for that predefined grid will be used.
   #. If the experiment is *not* using a predefined grid (i.e., it is using a custom grid whose parameters are specified in the experiment configuration file), then the user must specify a value for the ``BLOCKSIZE`` parameter in that configuration file. Otherwise, it will remain set to a null string, and the experiment generation will fail, because the generation scripts check to ensure that all the parameters defined in this section are set to non-empty strings before creating the experiment directory.

.. _WriteComp:

Write-Component (Quilting) Parameters
======================================

.. note::
   The :term:`UPP` (called by the ``RUN_POST_TN`` task) cannot process output on the native grid types ("GFDLgrid" and "ESGgrid"), so output fields are interpolated to a **write-component grid** before writing them to an output file. The output files written by the UFS Weather Model use an Earth System Modeling Framework (:term:`ESMF`) component, referred to as the **write component**. This model component is configured with settings in the ``model_configure`` file, as described in `Section 4.2.3 <https://ufs-weather-model.readthedocs.io/en/latest/InputsOutputs.html#model-configure-file>`__ of the UFS Weather Model documentation. 

``QUILTING``: (Default: "TRUE")

   .. attention::
      The regional grid requires the use of the write component, so users generally should not need to change the default value for ``QUILTING``. 

   Flag that determines whether to use the write component for writing forecast output files to disk. If set to "TRUE", the forecast model will output files named ``dynf$HHH.nc`` and ``phyf$HHH.nc`` (where ``HHH`` is the 3-digit forecast hour) containing dynamics and physics fields, respectively, on the write-component grid. For example, the output files for the 3rd hour of the forecast would be ``dynf$003.nc`` and ``phyf$003.nc``. (The regridding from the native FV3-LAM grid to the write-component grid is done by the forecast model.) If ``QUILTING`` is set to "FALSE", then the output file names are ``fv3_history.nc`` and ``fv3_history2d.nc``, and they contain fields on the native grid. Although the UFS Weather Model can run without quilting, the regional grid requires the use of the write component. Therefore, QUILTING should be set to "TRUE" when running the SRW App. If ``QUILTING`` is set to "FALSE", the ``RUN_POST_TN`` (meta)task cannot run because the :term:`UPP` code that this task calls cannot process fields on the native grid. In that case, the ``RUN_POST_TN`` (meta)task will be automatically removed from the Rocoto workflow XML. The :ref:`INLINE POST <InlinePost>` option also requires ``QUILTING`` to be set to "TRUE" in the SRW App. 

``PRINT_ESMF``: (Default: "FALSE")
   Flag that determines whether to output extra (debugging) information from :term:`ESMF` routines. Must be "TRUE" or "FALSE". Note that the write component uses ESMF library routines to interpolate from the native forecast model grid to the user-specified output grid (which is defined in the model configuration file ``model_configure`` in the forecast run directory).

``WRTCMP_write_groups``: (Default: "1")
   The number of write groups (i.e., groups of :term:`MPI` tasks) to use in the write component.

``WRTCMP_write_tasks_per_group``: (Default: "20")
   The number of MPI tasks to allocate for each write group.

``WRTCMP_output_grid``: (Default: "''")
   Sets the type (coordinate system) of the write component grid. The default empty string forces the user to set a valid value for ``WRTCMP_output_grid`` in ``config.sh`` if specifying a *custom* grid. When creating an experiment with a user-defined grid, this parameter must be specified or the experiment will fail. Valid values: ``"lambert_conformal"`` | ``"regional_latlon"`` | ``"rotated_latlon"``

``WRTCMP_cen_lon``: (Default: "")
   Longitude (in degrees) of the center of the write component grid. Can usually be set to the corresponding value from the native grid.

``WRTCMP_cen_lat``: (Default: "")
   Latitude (in degrees) of the center of the write component grid. Can usually be set to the corresponding value from the native grid.

``WRTCMP_lon_lwr_left``: (Default: "")
   Longitude (in degrees) of the center of the lower-left (southwest) cell on the write component grid. If using the "rotated_latlon" coordinate system, this is expressed in terms of the rotated longitude. Must be set manually when running an experiment with a user-defined grid.

``WRTCMP_lat_lwr_left``: (Default: "")
   Latitude (in degrees) of the center of the lower-left (southwest) cell on the write component grid. If using the "rotated_latlon" coordinate system, this is expressed in terms of the rotated latitude. Must be set manually when running an experiment with a user-defined grid.

**The following parameters must be set when** ``WRTCMP_output_grid`` **is set to "rotated_latlon":**

``WRTCMP_lon_upr_rght``: (Default: "")
   Longitude (in degrees) of the center of the upper-right (northeast) cell on the write component grid (expressed in terms of the rotated longitude).

``WRTCMP_lat_upr_rght``: (Default: "")
   Latitude (in degrees) of the center of the upper-right (northeast) cell on the write component grid (expressed in terms of the rotated latitude).

``WRTCMP_dlon``: (Default: "")
   Size (in degrees) of a grid cell on the write component grid (expressed in terms of the rotated longitude).

``WRTCMP_dlat``: (Default: "")
   Size (in degrees) of a grid cell on the write component grid (expressed in terms of the rotated latitude).

**The following parameters must be set when** ``WRTCMP_output_grid`` **is set to "lambert_conformal":**

``WRTCMP_stdlat1``: (Default: "")
   First standard latitude (in degrees) in definition of Lambert conformal projection.

``WRTCMP_stdlat2``: (Default: "")
   Second standard latitude (in degrees) in definition of Lambert conformal projection.

``WRTCMP_nx``: (Default: "")
   Number of grid points in the x-coordinate of the Lambert conformal projection.

``WRTCMP_ny``: (Default: "")
   Number of grid points in the y-coordinate of the Lambert conformal projection.

``WRTCMP_dx``: (Default: "")
   Grid cell size (in meters) along the x-axis of the Lambert conformal projection.

``WRTCMP_dy``: (Default: "")
   Grid cell size (in meters) along the y-axis of the Lambert conformal projection. 

Pre-existing Directory Parameter
================================
``PREEXISTING_DIR_METHOD``: (Default: "delete")
   This variable determines how to deal with pre-existing directories (resulting from previous calls to the experiment generation script using the same experiment name [``EXPT_SUBDIR``] as the current experiment). This variable must be set to one of three valid values: ``"delete"``, ``"rename"``, or ``"quit"``.  The behavior for each of these values is as follows:

   * **"delete":** The preexisting directory is deleted and a new directory (having the same name as the original preexisting directory) is created.

   * **"rename":** The preexisting directory is renamed and a new directory (having the same name as the original pre-existing directory) is created. The new name of the preexisting directory consists of its original name and the suffix "_old###", where ``###`` is a 3-digit integer chosen to make the new name unique.

   * **"quit":** The preexisting directory is left unchanged, but execution of the currently running script is terminated. In this case, the preexisting directory must be dealt with manually before rerunning the script.


Verbose Parameter
=================
``VERBOSE``: (Default: "TRUE")
   Flag that determines whether the experiment generation and workflow task scripts print out extra informational messages. Valid values: ``"TRUE"`` | ``"true"`` | ``"YES"`` | ``"yes"`` | ``"FALSE"`` | ``"false"`` | ``"NO"`` | ``"no"``

Debug Parameter
=================
``DEBUG``: (Default: "FALSE")
   Flag that determines whether to print out very detailed debugging messages.  Note that if DEBUG is set to TRUE, then VERBOSE will also be reset to TRUE if it isn't already. Valid values: ``"TRUE"`` | ``"true"`` | ``"YES"`` | ``"yes"`` | ``"FALSE"`` | ``"false"`` | ``"NO"`` | ``"no"``

.. _WFTasks:

Rocoto Workflow Tasks
========================

Set the names of the various Rocoto workflow tasks. These names usually do not need to be changed. 

**Baseline Tasks:**

| ``MAKE_GRID_TN``: (Default: "make_grid")
| ``MAKE_OROG_TN``: (Default: "make_orog")
| ``MAKE_SFC_CLIMO_TN``: (Default: "make_sfc_climo")
| ``GET_EXTRN_ICS_TN``: (Default: "get_extrn_ics")
| ``GET_EXTRN_LBCS_TN``: (Default: "get_extrn_lbcs")
| ``MAKE_ICS_TN``: (Default: "make_ics")
| ``MAKE_LBCS_TN``: (Default: "make_lbcs")
| ``RUN_FCST_TN``: (Default: "run_fcst")
| ``RUN_POST_TN``: (Default: "run_post")

**METplus Verification Tasks:** When running METplus verification tasks, the following task names are also added to the Rocoto workflow:

| ``GET_OBS``: (Default: "get_obs")
| ``GET_OBS_CCPA_TN``: (Default: "get_obs_ccpa")
| ``GET_OBS_MRMS_TN``: (Default: "get_obs_mrms")
| ``GET_OBS_NDAS_TN``: (Default: "get_obs_ndas")
| ``VX_TN``: (Default: "run_vx")
| ``VX_GRIDSTAT_TN``: (Default: "run_gridstatvx")
| ``VX_GRIDSTAT_REFC_TN``: (Default: "run_gridstatvx_refc")
| ``VX_GRIDSTAT_RETOP_TN``: (Default: "run_gridstatvx_retop")
| ``VX_GRIDSTAT_03h_TN``: (Default: "run_gridstatvx_03h")
| ``VX_GRIDSTAT_06h_TN``: (Default: "run_gridstatvx_06h")
| ``VX_GRIDSTAT_24h_TN``: (Default: "run_gridstatvx_24h")
| ``VX_POINTSTAT_TN``: (Default: "run_pointstatvx")
| ``VX_ENSGRID_TN``: (Default: "run_ensgridvx")
| ``VX_ENSGRID_03h_TN``: (Default: "run_ensgridvx_03h")
| ``VX_ENSGRID_06h_TN``: (Default: "run_ensgridvx_06h")
| ``VX_ENSGRID_24h_TN``: (Default: "run_ensgridvx_24h")
| ``VX_ENSGRID_REFC_TN``: (Default: "run_ensgridvx_refc")
| ``VX_ENSGRID_RETOP_TN``: (Default: "run_ensgridvx_retop")
| ``VX_ENSGRID_MEAN_TN``: (Default: "run_ensgridvx_mean")
| ``VX_ENSGRID_PROB_TN``: (Default: "run_ensgridvx_prob")
| ``VX_ENSGRID_MEAN_03h_TN``: (Default: "run_ensgridvx_mean_03h")
| ``VX_ENSGRID_PROB_03h_TN``: (Default: "run_ensgridvx_prob_03h")
| ``VX_ENSGRID_MEAN_06h_TN``: (Default: "run_ensgridvx_mean_06h")
| ``VX_ENSGRID_PROB_06h_TN``: (Default: "run_ensgridvx_prob_06h")
| ``VX_ENSGRID_MEAN_24h_TN``: (Default: "run_ensgridvx_mean_24h")
| ``VX_ENSGRID_PROB_24h_TN``: (Default: "run_ensgridvx_prob_24h")
| ``VX_ENSGRID_PROB_REFC_TN``: (Default: "run_ensgridvx_prob_refc")
| ``VX_ENSGRID_PROB_RETOP_TN``: (Default: "run_ensgridvx_prob_retop")
| ``VX_ENSPOINT_TN``: (Default: "run_enspointvx")
| ``VX_ENSPOINT_MEAN_TN``: (Default: "run_enspointvx_mean")
| ``VX_ENSPOINT_PROB_TN``: (Default: "run_enspointvx_prob")


Workflow Task Parameters
========================
For each workflow task, additional parameters determine the values to pass to the job scheduler (e.g., Slurm), which submits a job for each task. Parameters include the number of nodes to use for the job, the number of :term:`MPI` processes per node, the maximum walltime to allow for the job to complete, and the maximum number of times to attempt each task.

**Number of nodes:**

| ``NNODES_MAKE_GRID``: (Default: "1")
| ``NNODES_MAKE_OROG``: (Default: "1")
| ``NNODES_MAKE_SFC_CLIMO``: (Default: "2")
| ``NNODES_GET_EXTRN_ICS``: (Default: "1")
| ``NNODES_GET_EXTRN_LBCS``: (Default: "1")
| ``NNODES_MAKE_ICS``: (Default: "4")
| ``NNODES_MAKE_LBCS``: (Default: "4")
| ``NNODES_RUN_FCST``: (Default: "")

.. note::
   The correct value for ``NNODES_RUN_FCST`` will be calculated in the workflow generation scripts.

| ``NNODES_RUN_POST``: (Default: "2")
| ``NNODES_GET_OBS_CCPA``: (Default: "1")
| ``NNODES_GET_OBS_MRMS``: (Default: "1")
| ``NNODES_GET_OBS_NDAS``: (Default: "1")
| ``NNODES_VX_GRIDSTAT``: (Default: "1")
| ``NNODES_VX_POINTSTAT``: (Default: "1")
| ``NNODES_VX_ENSGRID``: (Default: "1")
| ``NNODES_VX_ENSGRID_MEAN``: (Default: "1")
| ``NNODES_VX_ENSGRID_PROB``: (Default: "1")
| ``NNODES_VX_ENSPOINT``: (Default: "1")
| ``NNODES_VX_ENSPOINT_MEAN``: (Default: "1")
| ``NNODES_VX_ENSPOINT_PROB``: (Default: "1")

**Number of MPI processes per node:**

| ``PPN_MAKE_GRID``: (Default: "24")
| ``PPN_MAKE_OROG``: (Default: "24")
| ``PPN_MAKE_SFC_CLIMO``: (Default: "24")
| ``PPN_GET_EXTRN_ICS``: (Default: "1")
| ``PPN_GET_EXTRN_LBCS``: (Default: "1")
| ``PPN_MAKE_ICS``: (Default: "12")
| ``PPN_MAKE_LBCS``: (Default: "12")
| ``PPN_RUN_FCST``: (Default: "")    

.. note::
   The correct value for ``PPN_RUN_FCST`` will be calculated from ``NCORES_PER_NODE`` and ``OMP_NUM_THREADS`` in ``setup.sh``. 

| ``PPN_RUN_POST``: (Default: "24")
| ``PPN_GET_OBS_CCPA``: (Default: "1")
| ``PPN_GET_OBS_MRMS``: (Default: "1")
| ``PPN_GET_OBS_NDAS``: (Default: "1")
| ``PPN_VX_GRIDSTAT``: (Default: "1")
| ``PPN_VX_POINTSTAT``: (Default: "1")
| ``PPN_VX_ENSGRID``: (Default: "1")
| ``PPN_VX_ENSGRID_MEAN``: (Default: "1")
| ``PPN_VX_ENSGRID_PROB``: (Default: "1")
| ``PPN_VX_ENSPOINT``: (Default: "1")
| ``PPN_VX_ENSPOINT_MEAN``: (Default: "1")
| ``PPN_VX_ENSPOINT_PROB``: (Default: "1")


**Wall Times:** Maximum amount of time for the task to run

| ``WTIME_MAKE_GRID``: (Default: "00:20:00")
| ``WTIME_MAKE_OROG``: (Default: "01:00:00")
| ``WTIME_MAKE_SFC_CLIMO``: (Default: "00:20:00")
| ``WTIME_GET_EXTRN_ICS``: (Default: "00:45:00")
| ``WTIME_GET_EXTRN_LBCS``: (Default: "00:45:00")
| ``WTIME_MAKE_ICS``: (Default: "00:30:00")
| ``WTIME_MAKE_LBCS``: (Default: "00:30:00")
| ``WTIME_RUN_FCST``: (Default: "04:30:00")
| ``WTIME_RUN_POST``: (Default: "00:15:00")
| ``WTIME_GET_OBS_CCPA``: (Default: "00:45:00")
| ``WTIME_GET_OBS_MRMS``: (Default: "00:45:00")
| ``WTIME_GET_OBS_NDAS``: (Default: "02:00:00")
| ``WTIME_VX_GRIDSTAT``: (Default: "02:00:00")
| ``WTIME_VX_POINTSTAT``: (Default: "01:00:00")
| ``WTIME_VX_ENSGRID``: (Default: "01:00:00")
| ``WTIME_VX_ENSGRID_MEAN``: (Default: "01:00:00")
| ``WTIME_VX_ENSGRID_PROB``: (Default: "01:00:00")
| ``WTIME_VX_ENSPOINT``: (Default: "01:00:00")
| ``WTIME_VX_ENSPOINT_MEAN``: (Default: "01:00:00")
| ``WTIME_VX_ENSPOINT_PROB``: (Default: "01:00:00")

**Maximum number of attempts to run a task:**

| ``MAXTRIES_MAKE_GRID``: (Default: "2")
| ``MAXTRIES_MAKE_OROG``: (Default: "2")
| ``MAXTRIES_MAKE_SFC_CLIMO``: (Default: "2")
| ``MAXTRIES_GET_EXTRN_ICS``: (Default: "1")
| ``MAXTRIES_GET_EXTRN_LBCS``: (Default: "1")
| ``MAXTRIES_MAKE_ICS``: (Default: "1")
| ``MAXTRIES_MAKE_LBCS``: (Default: "1")
| ``MAXTRIES_RUN_FCST``: (Default: "1")
| ``MAXTRIES_RUN_POST``: (Default: "2")
| ``MAXTRIES_GET_OBS_CCPA``: (Default: "1")
| ``MAXTRIES_GET_OBS_MRMS``: (Default: "1")
| ``MAXTRIES_GET_OBS_NDAS``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_REFC``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_RETOP``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_03h``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_06h``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_24h``: (Default: "1")
| ``MAXTRIES_VX_POINTSTAT``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_REFC``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_RETOP``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_03h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_06h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_24h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_MEAN``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_MEAN_03h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_03h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_MEAN_06h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_06h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_MEAN_24h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_24h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_REFC``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_RETOP``: (Default: "1")
| ``MAXTRIES_VX_ENSPOINT``: (Default: "1")
| ``MAXTRIES_VX_ENSPOINT_MEAN``: (Default: "1")
| ``MAXTRIES_VX_ENSPOINT_PROB``: (Default: "1")


Pre-Processing Parameters
=========================
These parameters set flags (and related directories) that determine whether various workflow tasks should be run. Note that the ``MAKE_GRID_TN``, ``MAKE_OROG_TN``, and ``MAKE_SFC_CLIMO_TN`` are all :term:`cycle-independent` tasks, i.e., if they are to be run, they do so only once at the beginning of the workflow before any cycles are run. 

Baseline Workflow Tasks
--------------------------

``RUN_TASK_MAKE_GRID``: (Default: "TRUE")
   Flag that determines whether to run the grid file generation task (``MAKE_GRID_TN``). If this is set to "TRUE", the grid generation task is run and new grid files are generated. If it is set to "FALSE", then the scripts look for pre-generated grid files in the directory specified by ``GRID_DIR`` (see below).

``GRID_DIR``: (Default: "/path/to/pregenerated/grid/files")
   The directory containing pre-generated grid files when ``RUN_TASK_MAKE_GRID`` is set to "FALSE".

``RUN_TASK_MAKE_OROG``: (Default: "TRUE")
   Same as ``RUN_TASK_MAKE_GRID`` but for the orography generation task (``MAKE_OROG_TN``). Flag that determines whether to run the orography file generation task (``MAKE_OROG_TN``). If this is set to "TRUE", the orography generation task is run and new orography files are generated. If it is set to "FALSE", then the scripts look for pre-generated orography files in the directory specified by ``OROG_DIR`` (see below).

``OROG_DIR``: (Default: "/path/to/pregenerated/orog/files")
   The directory containing pre-generated orography files to use when ``MAKE_OROG_TN`` is set to "FALSE".

``RUN_TASK_MAKE_SFC_CLIMO``: (Default: "TRUE")
   Same as ``RUN_TASK_MAKE_GRID`` but for the surface climatology generation task (``MAKE_SFC_CLIMO_TN``). Flag that determines whether to run the surface climatology file generation task (``MAKE_SFC_CLIMO_TN``). If this is set to "TRUE", the surface climatology generation task is run and new surface climatology files are generated. If it is set to "FALSE", then the scripts look for pre-generated surface climatology files in the directory specified by ``SFC_CLIMO_DIR`` (see below).

``SFC_CLIMO_DIR``: (Default: "/path/to/pregenerated/surface/climo/files")
   The directory containing pre-generated surface climatology files to use when ``MAKE_SFC_CLIMO_TN`` is set to "FALSE".

``RUN_TASK_GET_EXTRN_ICS``: (Default: "TRUE")
   Flag that determines whether to run the ``GET_EXTRN_ICS_TN`` task.

``RUN_TASK_GET_EXTRN_LBCS``: (Default: "TRUE")
   Flag that determines whether to run the ``GET_EXTRN_LBCS_TN`` task.

``RUN_TASK_MAKE_ICS``: (Default: "TRUE")
   Flag that determines whether to run the ``MAKE_ICS_TN`` task.

``RUN_TASK_MAKE_LBCS``: (Default: "TRUE")
   Flag that determines whether to run the ``MAKE_LBCS_TN`` task.

``RUN_TASK_RUN_FCST``: (Default: "TRUE")
   Flag that determines whether to run the ``RUN_FCST_TN`` task.

``RUN_TASK_RUN_POST``: (Default: "TRUE")
   Flag that determines whether to run the ``RUN_POST_TN`` task.

.. _VXTasks:

Verification Tasks
--------------------

``RUN_TASK_GET_OBS_CCPA``: (Default: "FALSE")
   Flag that determines whether to run the ``GET_OBS_CCPA_TN`` task, which retrieves the :term:`CCPA` hourly precipitation files used by METplus from NOAA :term:`HPSS`. 

``RUN_TASK_GET_OBS_MRMS``: (Default: "FALSE")
   Flag that determines whether to run the ``GET_OBS_MRMS_TN`` task, which retrieves the :term:`MRMS` composite reflectivity files used by METplus from NOAA HPSS. 

``RUN_TASK_GET_OBS_NDAS``: (Default: "FALSE")
   Flag that determines whether to run the ``GET_OBS_NDAS_TN`` task, which retrieves the :term:`NDAS` PrepBufr files used by METplus from NOAA HPSS. 

``RUN_TASK_VX_GRIDSTAT``: (Default: "FALSE")
   Flag that determines whether to run the grid-stat verification task.

``RUN_TASK_VX_POINTSTAT``: (Default: "FALSE")
   Flag that determines whether to run the point-stat verification task.

``RUN_TASK_VX_ENSGRID``: (Default: "FALSE")
   Flag that determines whether to run the ensemble-stat verification for gridded data task. 

``RUN_TASK_VX_ENSPOINT``: (Default: "FALSE")
   Flag that determines whether to run the ensemble point verification task. If this flag is set, both ensemble-stat point verification and point verification of ensemble-stat output is computed.

..
   COMMENT: Might be worth defining "ensemble-stat verification for gridded data," "ensemble point verification," "ensemble-stat point verification," and "point verification of ensemble-stat output"

Aerosol Climatology Parameter
================================

``USE_MERRA_CLIMO``: (Default: "FALSE")
   Flag that determines whether :term:`MERRA2` aerosol climatology data and lookup tables for optics properties are obtained. 

..
   COMMENT: When would it be appropriate to obtain these files?

Surface Climatology Parameter
=============================
``SFC_CLIMO_FIELDS``: (Default: "("facsf" "maximum_snow_albedo" "slope_type" "snowfree_albedo" "soil_type" "substrate_temperature" "vegetation_greenness" "vegetation_type")" )
   Array containing the names of all the fields for which ``MAKE_SFC_CLIMO_TN`` generates files on the native FV3-LAM grid.

Fixed File Parameters
=====================
These parameters are associated with the fixed (i.e., static) files. On `Level 1 & 2 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, fixed files are prestaged with paths defined in the ``setup.sh`` script. Because the default values are platform-dependent, they are set to a null string in ``config_defaults.sh``. Then these null values are overwritten in ``setup.sh`` with machine-specific values or with a user-specified value from ``config.sh``.

``FIXgsm``: (Default: "")
   System directory in which the majority of fixed (i.e., time-independent) files that are needed to run the FV3-LAM model are located.

``FIXaer``: (Default: "")
   System directory where :term:`MERRA2` aerosol climatology files are located.

``FIXlut``: (Default: "")
   System directory where the lookup tables for optics properties are located.

``TOPO_DIR``: (Default: "")
   The location on disk of the static input files used by the ``make_orog`` task (i.e., ``orog.x`` and ``shave.x``). Can be the same as ``FIXgsm``.

``SFC_CLIMO_INPUT_DIR``: (Default: "")
   The location on disk of the static surface climatology input fields, used by ``sfc_climo_gen``. These files are only used if ``RUN_TASK_MAKE_SFC_CLIMO=TRUE``.

``FNGLAC, ..., FNMSKH``: (Default: see below)
   .. code-block:: console

     (FNGLAC="global_glacier.2x2.grb"
      FNMXIC="global_maxice.2x2.grb"
      FNTSFC="RTGSST.1982.2012.monthly.clim.grb"
      FNSNOC="global_snoclim.1.875.grb"
      FNZORC="igbp"
      FNAISC="CFSR.SEAICE.1982.2012.monthly.clim.grb"
      FNSMCC="global_soilmgldas.t126.384.190.grb"
      FNMSKH="seaice_newland.grb")

   Names and default locations of (some of the) global data files that are assumed to exist in a system directory. (This directory is machine-dependent; the experiment generation scripts will set it and store it in the variable ``FIXgsm``.) These file names also appear directly in the forecast model's input :term:`namelist` file.

``FIXgsm_FILES_TO_COPY_TO_FIXam``: (Default: see below)
   .. code-block:: console

     ("$FNGLAC" \
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
      "replace_with_FIXgsm_ozone_prodloss_filename")

   If not running in NCO mode, this array contains the names of the files to copy from the ``FIXgsm`` system directory to the ``FIXam`` directory under the experiment directory. 
   
   .. note::
      The last element in the list above contains a dummy value. This value will be reset by the workflow generation scripts to the name of the ozone production/loss file that needs to be copied from ``FIXgsm``. This file depends on the :term:`CCPP` physics suite specified for the experiment (and the corresponding ozone parameterization scheme used in that physics suite). 

``FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING``: (Default: see below)
   .. code-block:: console

      ("FNGLAC | $FNGLAC" \
       "FNMXIC | $FNMXIC" \
       "FNTSFC | $FNTSFC" \
       "FNSNOC | $FNSNOC" \
       "FNAISC | $FNAISC" \
       "FNSMCC | $FNSMCC" \
       "FNMSKH | $FNMSKH" )

   This array is used to set some of the :term:`namelist` variables in the forecast model's namelist file. It maps file symlinks to the actual fixed file locations in the ``FIXam`` directory. The symlink names appear in the first column (to the left of the "|" symbol), and the paths to these files (in the ``FIXam`` directory) are held in workflow variables, which appear to the right of the "|" symbol. It is possible to remove ``FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING`` as a workflow variable and make it only a local one since it is used in only one script.

``FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING``: (Default: see below)
   .. code-block:: console

      ("FNALBC  | snowfree_albedo" \
       "FNALBC2 | facsf" \
       "FNTG3C  | substrate_temperature" \
       "FNVEGC  | vegetation_greenness" \
       "FNVETC  | vegetation_type" \
       "FNSOTC  | soil_type" \
       "FNVMNC  | vegetation_greenness" \
       "FNVMXC  | vegetation_greenness" \
       "FNSLPC  | slope_type" \
       "FNABSC  | maximum_snow_albedo" )

   This array is used to set some of the :term:`namelist` variables in the forecast model's namelist file. The variable names appear in the first column (to the left of the "|" symbol), and the paths to these surface climatology files on the native FV3-LAM grid (in the ``FIXLAM`` directory) are derived from the corresponding surface climatology fields (the second column of the array).
   
``CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING``: (Default: see below)
   .. code-block:: console

      ("aerosol.dat                | global_climaeropac_global.txt" \
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
       "global_o3prdlos.f77        | " )

   This array specifies the mapping to use between the symlinks that need to be created in each cycle directory (these are the "files" that :term:`FV3` looks for) and their targets in the ``FIXam`` directory. The first column of the array specifies the symlink to be created, and the second column specifies its target file in ``FIXam`` (where columns are delineated by the pipe symbol "|").

Subhourly Forecast Parameters
=================================

``SUB_HOURLY_POST``: (Default: "FALSE")
   Flag that indicates whether the forecast model will generate output files on a sub-hourly time interval (e.g., 10 minutes, 15 minutes). This will also cause the post-processor to process these sub-hourly files. If this variable is set to "TRUE", then ``DT_SUBHOURLY_POST_MNTS`` should be set to a valid value between "01" and "59".

``DT_SUB_HOURLY_POST_MNTS``: (Default: "00")
   Time interval in minutes between the forecast model output files. If ``SUB_HOURLY_POST`` is set to "TRUE", this needs to be set to a valid two-digit integer between "01" and "59". Note that if ``SUB_HOURLY_POST`` is set to "TRUE" but ``DT_SUB_HOURLY_POST_MNTS`` is set to "00", ``SUB_HOURLY_POST`` will get reset to "FALSE" in the experiment generation scripts (there will be an informational message in the log file to emphasize this). Valid values: ``"1"`` | ``"01"`` | ``"2"`` | ``"02"`` | ``"3"`` | ``"03"`` | ``"4"`` | ``"04"`` | ``"5"`` | ``"05"`` | ``"6"`` | ``"06"`` | ``"10"`` | ``"12"`` | ``"15"`` | ``"20"`` | ``"30"``

Customized Post Configuration Parameters
========================================

``USE_CUSTOM_POST_CONFIG_FILE``: (Default: "FALSE")
   Flag that determines whether a user-provided custom configuration file should be used for post-processing the model data. If this is set to "TRUE", then the workflow will use the custom post-processing (:term:`UPP`) configuration file specified in ``CUSTOM_POST_CONFIG_FP``. Otherwise, a default configuration file provided in the UPP repository will be used.

``CUSTOM_POST_CONFIG_FP``: (Default: "")
   The full path to the custom flat file, including filename, to be used for post-processing. This is only used if ``CUSTOM_POST_CONFIG_FILE`` is set to "TRUE".


Community Radiative Transfer Model (CRTM) Parameters
=======================================================

These variables set parameters associated with outputting satellite fields in the :term:`UPP` :term:`grib2` files using the Community Radiative Transfer Model (:term:`CRTM`). :numref:`Section %s <SatelliteProducts>` includes further instructions on how to do this. 

``USE_CRTM``: (Default: "FALSE")
   Flag that defines whether external :term:`CRTM` coefficient files have been staged by the user in order to output synthetic satellite products available within the :term:`UPP`. If this is set to "TRUE", then the workflow will check for these files in the directory ``CRTM_DIR``. Otherwise, it is assumed that no satellite fields are being requested in the UPP configuration.

``CRTM_DIR``: (Default: "")
   This is the path to the top CRTM fix file directory. This is only used if ``USE_CRTM`` is set to "TRUE".

Ensemble Model Parameters
============================

``DO_ENSEMBLE``: (Default: "FALSE")
   Flag that determines whether to run a set of ensemble forecasts (for each set of specified cycles).  If this is set to "TRUE", ``NUM_ENS_MEMBERS`` forecasts are run for each cycle, each with a different set of stochastic seed values. When "FALSE", a single forecast is run for each cycle.

``NUM_ENS_MEMBERS``: (Default: "1")
   The number of ensemble members to run if ``DO_ENSEMBLE`` is set to "TRUE". This variable also controls the naming of the ensemble member directories. For example, if ``NUM_ENS_MEMBERS`` is set to "8", the member directories will be named *mem1, mem2, ..., mem8*.  If it is set to "08" (with a leading zero), the member directories will be named *mem01, mem02, ..., mem08*. However, after reading in the number of characters in this string (in order to determine how many leading zeros, if any, should be placed in the names of the member directories), the workflow generation scripts strip away those leading zeros. Thus, in the variable definitions file (``GLOBAL_VAR_DEFNS_FN``), this variable appears with its leading zeros stripped. This variable is not used unless ``DO_ENSEMBLE`` is set to "TRUE".

.. _HaloBlend:

Halo Blend Parameter
====================
``HALO_BLEND``: (Default: "10")
   Number of cells to use for "blending" the external solution (obtained from the :term:`LBCs`) with the internal solution from the FV3LAM :term:`dycore`. Specifically, it refers to the number of rows into the computational domain that should be blended with the LBCs. Cells at which blending occurs are all within the boundary of the native grid; they don't involve the 4 cells outside the boundary where the LBCs are specified (which is a different :term:`halo`). Blending is necessary to smooth out waves generated due to mismatch between the external and internal solutions. To shut :term:`halo` blending off, set this to zero. 


FVCOM Parameter
===============
``USE_FVCOM``: (Default: "FALSE")
   Flag that specifies whether or not to update surface conditions in FV3-LAM with fields generated from the Finite Volume Community Ocean Model (:term:`FVCOM`). If set to "TRUE", lake/sea surface temperatures, ice surface temperatures, and ice placement will be overwritten using data provided by FVCOM. Setting ``USE_FVCOM`` to "TRUE" causes the executable ``process_FVCOM.exe`` in the ``MAKE_ICS_TN`` task to run. This, in turn, modifies the file ``sfc_data.nc`` generated by ``chgres_cube``.  Note that the FVCOM data must already be interpolated to the desired FV3-LAM grid. 

``FVCOM_WCSTART``: (Default: "cold")
   Define if this is a "warm" start or a "cold" start. Setting this to "warm" will read in ``sfc_data.nc`` generated in a RESTART directory. Setting this to "cold" will read in the ``sfc_data.nc`` generated from ``chgres_cube`` in the ``make_ics`` portion of the workflow. Valid values: ``"cold"`` | ``"warm"``

``FVCOM_DIR``: (Default: "/user/defined/dir/to/fvcom/data")
   User-defined directory where the ``fvcom.nc`` file containing :term:`FVCOM` data on the FV3-LAM native grid is located. The file name in this directory must be ``fvcom.nc``.

``FVCOM_FILE``: (Default: "fvcom.nc")
   Name of file located in ``FVCOM_DIR`` that has :term:`FVCOM` data interpolated to the FV3-LAM grid. This file will be copied later to a new location and the name changed to ``fvcom.nc`` if a name other than ``fvcom.nc`` is selected.

Thread Affinity Interface
===========================

.. note::
   Note that settings for the ``make_grid`` and ``make_orog`` tasks are disabled or not included below because they do not use parallelized code.

``KMP_AFFINITY_*``: (Default: see below)

   .. code-block:: console

      KMP_AFFINITY_MAKE_OROG="disabled"
      KMP_AFFINITY_MAKE_SFC_CLIMO="scatter"
      KMP_AFFINITY_MAKE_ICS="scatter"
      KMP_AFFINITY_MAKE_LBCS="scatter"
      KMP_AFFINITY_RUN_FCST="scatter"
      KMP_AFFINITY_RUN_POST="scatter"

   "Intel's runtime library can bind OpenMP threads to physical processing units. The interface is controlled using the KMP_AFFINITY environment variable. Thread affinity restricts execution of certain threads to a subset of the physical processing units in a multiprocessor computer. Depending on the system (machine) topology, application, and operating system, thread affinity can have a dramatic effect on the application speed and on the execution speed of a program." Valid values: ``"scatter"`` | ``"disabled"`` | ``"balanced"`` | ``"compact"`` | ``"explicit"`` | ``"none"``

   For more information, see the `Intel Development Reference Guide <https://software.intel.com/content/www/us/en/develop/documentation/cpp-compiler-developer-guide-and-reference/top/optimization-and-programming-guide/openmp-support/openmp-library-support/thread-affinity-interface-linux-and-windows.html>`__. 

``OMP_NUM_THREADS_*``: (Default: see below)

   .. code-block:: console

      OMP_NUM_THREADS_MAKE_OROG="6"
      OMP_NUM_THREADS_MAKE_SFC_CLIMO="1"
      OMP_NUM_THREADS_MAKE_ICS="1"
      OMP_NUM_THREADS_MAKE_LBCS="1"
      OMP_NUM_THREADS_RUN_FCST="2"     # atmos_nthreads in model_configure
      OMP_NUM_THREADS_RUN_POST="1"

   The number of OpenMP threads to use for parallel regions.

..
   COMMENT: What does the #atmos_nthreads comment mean? Can it be removed?
   

``OMP_STACKSIZE_*``: (Default: see below)

   .. code-block:: console

      OMP_STACKSIZE_MAKE_OROG="2048m"
      OMP_STACKSIZE_MAKE_SFC_CLIMO="1024m"
      OMP_STACKSIZE_MAKE_ICS="1024m"
      OMP_STACKSIZE_MAKE_LBCS="1024m"
      OMP_STACKSIZE_RUN_FCST="1024m"
      OMP_STACKSIZE_RUN_POST="1024m"

   Controls the size of the stack for threads created by the OpenMP implementation.


