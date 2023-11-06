.. _ConfigWorkflow:

================================================================================================
Workflow Parameters: Configuring the Workflow in ``config.yaml`` and ``config_defaults.yaml``		
================================================================================================
To create the experiment directory and workflow when running the SRW Application, the user must create an experiment configuration file (usually named ``config.yaml``). This file contains experiment-specific information, such as forecast dates, grid and physics suite choices, data directories, and other relevant settings. To help the user, two sample configuration files have been included in the ``ush`` directory: ``config.community.yaml`` and ``config.nco.yaml``. The first is for running experiments in *community* mode (``RUN_ENVIR`` set to "community"), and the second is for running experiments in *nco* mode (``RUN_ENVIR`` set to "nco"). The content of these files can be copied into ``config.yaml`` and used as the starting point from which to generate a variety of experiment configurations for the SRW App. Note that for this release, only *community* mode is supported. 

There is an extensive list of experiment parameters that a user can set when configuring the experiment. Not all of these parameters need to be set explicitly by the user in ``config.yaml``. If a user does not define a variable in the ``config.yaml`` script, its value in ``config_defaults.yaml`` will be used, or the value will be reset depending on other parameters, such as the platform (``MACHINE``) selected for the experiment. 

.. note:: 
   The ``config_defaults.yaml`` file contains the full list of experiment parameters that a user may set in ``config.yaml``. The user cannot set parameters in ``config.yaml`` that are not initialized in ``config_defaults.yaml``.

The following is a list of the parameters in the ``config_defaults.yaml`` file. For each parameter, the default value and a brief description is provided. 

.. _user:

USER Configuration Parameters
=================================

If non-default parameters are selected for the variables in this section, they should be added to the ``user:`` section of the ``config.yaml`` file. 

``RUN_ENVIR``: (Default: "nco")
   This variable determines the workflow mode. The user can choose between two options: "nco" and "community". The "nco" mode uses a directory structure that mimics what is used in operations at NOAA/NCEP Central Operations (NCO) and at the NOAA/NCEP/Environmental Modeling Center (EMC), which works with NCO on pre-implementation testing. Specifics of the conventions used in "nco" mode can be found in the following `WCOSS Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/>`__ document:

   | NCEP Central Operations
   | WCOSS Implementation Standards
   | January 19, 2022
   | Version 11.0.0
   
   Setting ``RUN_ENVIR`` to "community" is recommended in most cases for users who are not planning to implement their code into operations at NCO. Valid values: ``"nco"`` | ``"community"``

``MACHINE``: (Default: "BIG_COMPUTER")
   The machine (a.k.a. platform or system) on which the workflow will run. Currently supported platforms are listed on the `SRW App Wiki page <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__. When running the SRW App on any ParellelWorks/NOAA Cloud system, use "NOAACLOUD" regardless of the underlying system (AWS, GCP, or Azure). Valid values: ``"HERA"`` | ``"ORION"`` | ``"JET"`` | ``"CHEYENNE"`` | ``"GAEA"`` | ``"NOAACLOUD"`` | ``"STAMPEDE"`` | ``"ODIN"`` | ``"MACOS"`` | ``"LINUX"`` | ``"SINGULARITY"`` | ``"WCOSS2"``

   .. hint::
      Users who are NOT on a named, supported Level 1 or 2 platform will need to set the ``MACHINE`` variable to ``LINUX`` or ``MACOS``; to combine use of a Linux or MacOS platform with the Rocoto workflow manager, users will also need to set ``WORKFLOW_MANAGER: "rocoto"`` in the ``platform:`` section of ``config.yaml``. This combination will assume a Slurm batch manager when generating the XML. 

``MACHINE_FILE``: (Default: "")
   Path to a configuration file with machine-specific settings. If none is provided, ``setup.py`` will attempt to set the path to a configuration file for a supported platform.

``ACCOUNT``: (Default: "project_name")
   The account under which users submit jobs to the queue on the specified ``MACHINE``. To determine an appropriate ``ACCOUNT`` field for `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, users may run the ``groups`` command, which will return a list of projects that the user has permissions for. Not all of the listed projects/groups have an HPC allocation, but those that do are potentially valid account names. On some systems, the ``saccount_params`` command will display additional account details. 

.. _PlatformConfig:

PLATFORM Configuration Parameters
=====================================

If non-default parameters are selected for the variables in this section, they should be added to the ``platform:`` section of the ``config.yaml`` file. 

``WORKFLOW_MANAGER``: (Default: "none")
   The workflow manager to use (e.g., "rocoto"). This is set to "none" by default, but if the machine name is set to a platform that supports Rocoto, this will be overwritten and set to "rocoto." If set explicitly to "rocoto" along with the use of the ``MACHINE: "LINUX"`` target, the configuration layer assumes a Slurm batch manager when generating the XML. Valid values: ``"rocoto"`` | ``"none"``

``NCORES_PER_NODE``: (Default: "")
   The number of cores available per node on the compute platform. Set for supported platforms in ``setup.py``, but it is now also configurable for all platforms.

``BUILD_MOD_FN``: (Default: "")
   Name of an alternative build module file to use if running on an unsupported platform. It is set automatically for supported machines.

``WFLOW_MOD_FN``: (Default: "")
   Name of an alternative workflow module file to use if running on an unsupported platform. It is set automatically for supported machines.

``BUILD_VER_FN``: (Default: "")
   File name containing the version of the modules used for building the app. Currently, WCOSS2 only uses this file.

``RUN_VER_FN``: (Default: "")
   File name containing the version of the modules used for running the app. Currently, WCOSS2 only uses this file.

.. _sched:

``SCHED``: (Default: "")
   The job scheduler to use (e.g., Slurm) on the specified ``MACHINE``. Leaving this an empty string allows the experiment generation script to set it automatically depending on the machine the workflow is running on. Valid values: ``"slurm"`` | ``"pbspro"`` | ``"lsf"`` | ``"lsfcray"`` | ``"none"``

``SCHED_NATIVE_CMD``: (Default: "")
   Allows an extra parameter to be passed to the job scheduler (Slurm or PBSPRO) via XML Native command. 

``DOMAIN_PREGEN_BASEDIR``: (Default: "")
   For use in NCO mode only (``RUN_ENVIR: "nco"``). The base directory containing pregenerated grid, orography, and surface climatology files. This is an alternative for setting ``GRID_DIR``, ``OROG_DIR``, and ``SFC_CLIMO_DIR`` individually. For the pregenerated grid specified by ``PREDEF_GRID_NAME``, these "fixed" files are located in: 

   .. code-block:: console 

      ${DOMAIN_PREGEN_BASEDIR}/${PREDEF_GRID_NAME}

   The workflow scripts will create a symlink in the experiment directory that will point to a subdirectory (having the same name as the experiment grid) under this directory. This variable should be set to a null string in ``config_defaults.yaml``, but it can be changed in the user-specified workflow configuration file set by ``EXPT_CONFIG_FN`` (usually ``config.yaml``).

``PRE_TASK_CMDS``: (Default: "")
   Pre-task commands such as ``ulimit`` needed by tasks. For example: ``'{ ulimit -s unlimited; ulimit -a; }'``

Machine-Dependent Parameters
-------------------------------
These parameters vary depending on machine. On `Level 1 and 2 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, the appropriate values for each machine can be viewed in the ``ush/machine/<platform>.sh`` scripts. To specify a value other than the default, add these variables and the desired value in the ``config.yaml`` file so that they override the ``config_defaults.yaml`` and machine default values. 

``PARTITION_DEFAULT``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., when ``SCHED: "slurm"``). This is the default partition to which Slurm submits workflow tasks. When a variable that designates the partition (e.g., ``PARTITION_HPSS``, ``PARTITION_FCST``; see below) is **not** specified, the task will be submitted to the default partition indicated in the ``PARTITION_DEFAULT`` variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Options are machine-dependent and include: ``""`` | ``"hera"`` | ``"normal"`` | ``"orion"`` | ``"sjet"`` | ``"vjet"`` | ``"kjet"`` | ``"xjet"`` | ``"workq"``

``QUEUE_DEFAULT``: (Default: "")
   The default queue or QOS to which workflow tasks are submitted (QOS is Slurm's term for queue; it stands for "Quality of Service"). If the task's ``QUEUE_HPSS`` or ``QUEUE_FCST`` parameters (see below) are not specified, the task will be submitted to the queue indicated by this variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Options are machine-dependent and include: ``""`` | ``"batch"`` | ``"dev"`` | ``"normal"`` | ``"regular"`` | ``"workq"``

``PARTITION_HPSS``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., when ``SCHED: "slurm"``). Tasks that get or create links to external model files are submitted to the partition specified in this variable. These links are needed to generate initial conditions (:term:`ICs`) and lateral boundary conditions (:term:`LBCs`) for the experiment. If this variable is not set or is set to an empty string, it will be (re)set to the ``PARTITION_DEFAULT`` value (if set) or to a machine-dependent value. Options are machine-dependent and include: ``""`` | ``"normal"`` | ``"service"`` | ``"workq"``

``QUEUE_HPSS``: (Default: "")
   Tasks that get or create links to external model files are submitted to this queue, or QOS (QOS is Slurm's term for queue; it stands for "Quality of Service"). These links are needed to generate initial conditions (:term:`ICs`) and lateral boundary conditions (:term:`LBCs`) for the experiment. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Options are machine-dependent and include: ``""`` | ``"batch"`` | ``"dev_transfer"`` | ``"normal"`` | ``"regular"`` | ``"workq"``

``PARTITION_FCST``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., when ``SCHED: "slurm"``). The task that runs forecasts is submitted to this partition. If this variable is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Options are machine-dependent and include: ``""`` | ``"hera"`` | ``"normal"`` | ``"orion"`` | ``"sjet"`` | ``"vjet"`` | ``"kjet"`` | ``"xjet"`` | ``"workq"``

``QUEUE_FCST``: (Default: "")
   The task that runs a forecast is submitted to this queue, or QOS (QOS is Slurm's term for queue; it stands for "Quality of Service"). If this variable is not set or set to an empty string, it will be (re)set to a machine-dependent value. Options are machine-dependent and include: ``""`` | ``"batch"`` | ``"dev"`` | ``"normal"`` | ``"regular"`` | ``"workq"``

Parameters for Running Without a Workflow Manager
-----------------------------------------------------
These settings set run commands for platforms without a workflow manager. Values will be ignored unless ``WORKFLOW_MANAGER: "none"``.

``RUN_CMD_UTILS``: (Default: "mpirun -np 1")
   The run command for MPI-enabled pre-processing utilities (e.g., shave, orog, sfc_climo_gen). This can be left blank for smaller domains, in which case the executables will run without :term:`MPI`. Users may need to use a different command for launching an MPI-enabled executable depending on their machine and MPI installation.

``RUN_CMD_FCST``: (Default: "mpirun -np ${PE_MEMBER01}")
   The run command for the model forecast step. This will be appended to the end of the variable definitions file (``var_defns.sh``). Changing the ``${PE_MEMBER01}`` variable is **not** recommended; it refers to the number of MPI tasks that the Weather Model will expect to run with. Running the Weather Model with a different number of MPI tasks than the workflow has been set up for can lead to segmentation faults and other errors. 

``RUN_CMD_POST``: (Default: "mpirun -np 1")
   The run command for post-processing (via the :term:`UPP`). Can be left blank for smaller domains, in which case UPP will run without :term:`MPI`.


METplus Parameters
----------------------

:ref:`METplus <MetplusComponent>` is a scientific verification framework that spans a wide range of temporal and spatial scales. Many of the METplus parameters are described below, but additional documentation for the METplus components is available on the `METplus website <https://dtcenter.org/community-code/metplus>`__. 

``MODEL``: (Default: "")
   A descriptive name of the user's choice for the model being verified.
   
``MET_INSTALL_DIR``: (Default: "")
   Path to top-level directory of MET installation.

``METPLUS_PATH``: (Default: "")
   Path to top-level directory of METplus installation.

``MET_BIN_EXEC``: (Default: "")
   Name of subdirectory where METplus executables are installed.

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
   User-specified location of top-level directory where CCPA hourly precipitation files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA :term:`HPSS` (if the user has access) via the ``TN_GET_OBS_CCPA`` task. (This task is activated in the workflow by setting ``RUN_TASK_GET_OBS_CCPA: true``). 

   METplus configuration files require the use of a predetermined directory structure and file names. If the CCPA files are user-provided, they need to follow the anticipated naming structure: ``{YYYYMMDD}/ccpa.t{HH}z.01h.hrap.conus.gb2``, where YYYYMMDD and HH are as described in the note :ref:`above <METParamNote>`. When pulling observations from NOAA HPSS, the data retrieved will be placed in the ``CCPA_OBS_DIR`` directory. This path must be defind as ``/<full-path-to-obs>/ccpa/proc``. METplus is configured to verify 01-, 03-, 06-, and 24-h accumulated precipitation using hourly CCPA files.    

   .. note::
      There is a problem with the valid time in the metadata for files valid from 19 - 00 UTC (i.e., files under the "00" directory). The script to pull the CCPA data from the NOAA HPSS (``scripts/exregional_get_obs_ccpa.sh``) has an example of how to account for this and organize the data into a more intuitive format. When a fix is provided, it will be accounted for in the ``exregional_get_obs_ccpa.sh`` script.

``MRMS_OBS_DIR``: (Default: "")
   User-specified location of top-level directory where MRMS composite reflectivity files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA :term:`HPSS` (if the user has access) via the ``TN_GET_OBS_MRMS`` task (activated in the workflow by setting ``RUN_TASK_GET_OBS_MRMS: true``). When pulling observations directly from NOAA HPSS, the data retrieved will be placed in this directory. Please note, this path must be defind as ``/<full-path-to-obs>/mrms/proc``. 
   
   METplus configuration files require the use of a predetermined directory structure and file names. Therefore, if the MRMS files are user-provided, they need to follow the anticipated naming structure: ``{YYYYMMDD}/MergedReflectivityQCComposite_00.50_{YYYYMMDD}-{HH}{mm}{SS}.grib2``, where YYYYMMDD and {HH}{mm}{SS} are as described in the note :ref:`above <METParamNote>`. 

.. note::
   METplus is configured to look for a MRMS composite reflectivity file for the valid time of the forecast being verified; since MRMS composite reflectivity files do not always exactly match the valid time, a script (within the main script that retrieves MRMS data from the NOAA HPSS) is used to identify and rename the MRMS composite reflectivity file to match the valid time of the forecast. The script to pull the MRMS data from the NOAA HPSS has an example of the expected file-naming structure: ``scripts/exregional_get_obs_mrms.sh``. This script calls the script used to identify the MRMS file closest to the valid time: ``ush/mrms_pull_topofhour.py``.

``NDAS_OBS_DIR``: (Default: "")
   User-specified location of the top-level directory where NDAS prepbufr files used by METplus are located. This parameter needs to be set for both user-provided observations and for observations that are retrieved from the NOAA :term:`HPSS` (if the user has access) via the ``TN_GET_OBS_NDAS`` task (activated in the workflow by setting ``RUN_TASK_GET_OBS_NDAS: true``). When pulling observations directly from NOAA HPSS, the data retrieved will be placed in this directory. Please note, this path must be defined as ``/<full-path-to-obs>/ndas/proc``. METplus is configured to verify near-surface variables hourly and upper-air variables at 00 and 12 UTC with NDAS prepbufr files. 
   
   METplus configuration files require the use of predetermined file names. Therefore, if the NDAS files are user-provided, they need to follow the anticipated naming structure: ``prepbufr.ndas.{YYYYMMDDHH}``, where YYYYMMDDHH is as described in the note :ref:`above <METParamNote>`. The script to pull the NDAS data from the NOAA HPSS (``scripts/exregional_get_obs_ndas.sh``) has an example of how to rename the NDAS data into a more intuitive format with the valid time listed in the file name.

Test Directories
----------------------

These directories are used only by the ``run_WE2E_tests.py`` script, so they are not used unless the user runs a Workflow End-to-End (WE2E) test (see :numref:`Chapter %s <WE2E_tests>`). Their function corresponds to the same variables without the ``TEST_`` prefix. Users typically should not modify these variables. For any alterations, the logic in the ``run_WE2E_tests.py`` script would need to be adjusted accordingly.

``TEST_EXTRN_MDL_SOURCE_BASEDIR``: (Default: "")
   This parameter allows testing of user-staged files in a known location on a given platform. This path contains a limited dataset and likely will not be useful for most user experiments. 

``TEST_PREGEN_BASEDIR``: (Default: "")
   Similar to ``DOMAIN_PREGEN_BASEDIR``, this variable sets the base directory containing pregenerated grid, orography, and surface climatology files for WE2E tests. This is an alternative for setting ``GRID_DIR``, ``OROG_DIR``, and ``SFC_CLIMO_DIR`` individually. 

``TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS``: (Default: "")
   This parameter is used to test the mechanism that allows users to point to a data stream on disk. It sets up a sandbox location that mimics the stream in a more controlled way and tests the ability to access :term:`ICS`. 

``TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS``: (Default: "")
   This parameter is used to test the mechanism that allows users to point to a data stream on disk. It sets up a sandbox location that mimics the stream in a more controlled way and tests the ability to access :term:`LBCS`.


.. _workflow:

WORKFLOW Configuration Parameters
=====================================

If non-default parameters are selected for the variables in this section, they should be added to the ``workflow:`` section of the ``config.yaml`` file. 

.. _Cron:

Cron-Associated Parameters
------------------------------

Cron is a job scheduler accessed through the command-line on UNIX-like operating systems. It is useful for automating tasks such as the ``rocotorun`` command, which launches each workflow task in the SRW App. Cron periodically checks a cron table (aka crontab) to see if any tasks are are ready to execute. If so, it runs them. 

``USE_CRON_TO_RELAUNCH``: (Default: false)
   Flag that determines whether or not a line is added to the user's cron table, which calls the experiment launch script every ``CRON_RELAUNCH_INTVL_MNTS`` minutes. Valid values: ``True`` | ``False``

``CRON_RELAUNCH_INTVL_MNTS``: (Default: 3)
   The interval (in minutes) between successive calls of the experiment launch script by a cron job to (re)launch the experiment (so that the workflow for the experiment kicks off where it left off). This is used only if ``USE_CRON_TO_RELAUNCH`` is set to true.

.. _DirParams:

Directory Parameters
-----------------------

``EXPT_BASEDIR``: (Default: "")
   The full path to the base directory in which the experiment directory (``EXPT_SUBDIR``) will be created. If this is not specified or if it is set to an empty string, it will default to ``${HOMEaqm}/../expt_dirs``, where ``${HOMEaqm}`` contains the full path to the ``ufs-srweather-app`` directory. If set to a relative path, the provided path will be appended to the default value ``${HOMEaqm}/../expt_dirs``. For example, if ``EXPT_BASEDIR=some/relative/path`` (i.e. a path that does not begin with ``/``), the value of ``EXPT_BASEDIR`` used by the workflow will be ``EXPT_BASEDIR=${HOMEaqm}/../expt_dirs/some/relative/path``.

``EXPT_SUBDIR``: (Default: "")
   The user-designated name of the experiment directory (*not* its full path). The full path to the experiment directory, which will be contained in the variable ``EXPTDIR``, will be:

   .. code-block:: console

      EXPTDIR="${EXPT_BASEDIR}/${EXPT_SUBDIR}"

   This parameter cannot be left as a null string. It must be set to a non-null value in the user-defined experiment configuration file (i.e., ``config.yaml``).

``EXEC_SUBDIR``: (Default: "exec")
   The name of the subdirectory of ``ufs-srweather-app`` where executables are installed.

Pre-Processing File Separator Parameters
--------------------------------------------

``DOT_OR_USCORE``: (Default: "_")
   This variable sets the separator character(s) to use in the names of the grid, mosaic, and orography fixed files. Ideally, the same separator should be used in the names of these fixed files as in the surface climatology fixed files. Valid values: ``"_"`` | ``"."``


Set File Name Parameters
----------------------------

``EXPT_CONFIG_FN``: (Default: "config.yaml")
   Name of the user-specified configuration file for the forecast experiment.

``CONSTANTS_FN``: (Default: "constants.yaml")
   Name of the file containing definitions of various mathematical, physical, and SRW App contants.

``RGNL_GRID_NML_FN``: (Default: "regional_grid.nml")
   Name of the file containing namelist settings for the code that generates an "ESGgrid" regional grid.

``FV3_NML_BASE_SUITE_FN``: (Default: "input.nml.FV3")
   Name of the Fortran file containing the forecast model's base suite namelist (i.e., the portion of the namelist that is common to all physics suites).

``FV3_NML_YAML_CONFIG_FN``: (Default: "FV3.input.yml")
   Name of YAML configuration file containing the forecast model's namelist settings for various physics suites.

``FV3_NML_BASE_ENS_FN``: (Default: "input.nml.base_ens")
   Name of the Fortran file containing the forecast model's base ensemble namelist (i.e., the original namelist file from which each of the ensemble members' namelist files is generated).

``FV3_EXEC_FN``: (Default: "ufs_model")
   Name to use for the forecast model executable. 

``DIAG_TABLE_TMPL_FN``: (Default: "")
   Name of a template file that specifies the output fields of the forecast model. The selected physics suite is appended to this file name in ``setup.py``, taking the form ``{DIAG_TABLE_TMPL_FN}.{CCPP_PHYS_SUITE}``. Generally, the SRW App expects to read in the default value set in ``setup.py`` (i.e., ``diag_table.{CCPP_PHYS_SUITE}``), and users should **not** specify a value for ``DIAG_TABLE_TMPL_FN`` in their configuration file (i.e., ``config.yaml``) unless (1) the file name required by the model changes, and (2) they also change the names of the ``diag_table`` options in the ``ufs-srweather-app/parm`` directory. 

``FIELD_TABLE_TMPL_FN``: (Default: "")
   Name of a template file that specifies the :term:`tracers <tracer>` that the forecast model will read in from the :term:`IC/LBC <IC/LBCs>` files. The selected physics suite is appended to this file name in ``setup.py``, taking the form ``{FIELD_TABLE_TMPL_FN}.{CCPP_PHYS_SUITE}``. Generally, the SRW App expects to read in the default value set in ``setup.py`` (i.e., ``field_table.{CCPP_PHYS_SUITE}``), and users should **not** specify a different value for ``FIELD_TABLE_TMPL_FN`` in their configuration file (i.e., ``config.yaml``) unless (1) the file name required by the model changes, and (2) they also change the names of the ``field_table`` options in the ``ufs-srweather-app/parm`` directory. 

``DATA_TABLE_TMPL_FN``: (Default: "")
   Name of a template file that contains the data table read in by the forecast model. Generally, the SRW App expects to read in the default value set in ``setup.py`` (i.e., ``data_table``), and users should **not** specify a different value for ``DATA_TABLE_TMPL_FN`` in their configuration file (i.e., ``config.yaml``) unless (1) the file name required by the model changes, and (2) they also change the name of ``data_table`` in the ``ufs-srweather-app/parm`` directory. 

``MODEL_CONFIG_TMPL_FN``: (Default: "")
   Name of a template file that contains settings and configurations for the :term:`NUOPC`/:term:`ESMF` main component. Generally, the SRW App expects to read in the default value set in ``setup.py`` (i.e., ``model_configure``), and users should **not** specify a different value for ``MODEL_CONFIG_TMPL_FN`` in their configuration file (i.e., ``config.yaml``) unless (1) the file name required by the model changes, and (2) they also change the name of ``model_configure`` in the ``ufs-srweather-app/parm`` directory. 

``NEMS_CONFIG_TMPL_FN``: (Default: "")
   Name of a template file that contains information about the various :term:`NEMS` components and their run sequence. Generally, the SRW App expects to read in the default value set in ``setup.py`` (i.e., ``nems.configure``), and users should **not** specify a different value for ``NEMS_CONFIG_TMPL_FN`` in their configuration file (i.e., ``config.yaml``) unless (1) the file name required by the model changes, and (2) they also change the name of ``nems.configure`` in the ``ufs-srweather-app/parm`` directory.

``FCST_MODEL``: (Default: "ufs-weather-model")
   Name of forecast model. Valid values: ``"ufs-weather-model"`` | ``"fv3gfs_aqm"``

``WFLOW_XML_FN``: (Default: "FV3LAM_wflow.xml")
   Name of the Rocoto workflow XML file that the experiment generation script creates. This file defines the workflow for the experiment.

``GLOBAL_VAR_DEFNS_FN``: (Default: "var_defns.sh")
   Name of the file (a shell script) containing definitions of the primary and secondary experiment variables (parameters). This file is sourced by many scripts (e.g., the J-job scripts corresponding to each workflow task) in order to make all the experiment variables available in those scripts. The primary variables are defined in the default configuration script (``config_defaults.yaml``) and in ``config.yaml``. The secondary experiment variables are generated by the experiment generation script. 

``EXTRN_MDL_VAR_DEFNS_FN``: (Default: "extrn_mdl_var_defns")
   Name of the file (a shell script) containing the definitions of variables associated with the external model from which :term:`ICs` or :term:`LBCs` are generated. This file is created by the ``TN_GET_EXTRN_*`` task because the values of the variables it contains are not known before this task runs. The file is then sourced by the ``TN_MAKE_ICS`` and ``TN_MAKE_LBCS`` tasks.

``WFLOW_LAUNCH_SCRIPT_FN``: (Default: "launch_FV3LAM_wflow.sh")
   Name of the script that can be used to (re)launch the experiment's Rocoto workflow.

``WFLOW_LAUNCH_LOG_FN``: (Default: "log.launch_FV3LAM_wflow")
   Name of the log file that contains the output from successive calls to the workflow launch script (``WFLOW_LAUNCH_SCRIPT_FN``).

.. _CCPP_Params:

CCPP Parameter
------------------

``CCPP_PHYS_SUITE``: (Default: "FV3_GFS_v16")
   This parameter indicates which :term:`CCPP` (Common Community Physics Package) physics suite to use for the forecast(s). The choice of physics suite determines the forecast model's namelist file, the diagnostics table file, the field table file, and the XML physics suite definition file, which are staged in the experiment directory or the :term:`cycle` directories under it. 

   .. note:: 
      For information on *stochastic physics* parameters, see :numref:`Section %s <stochastic-physics>`.
   
   **Current supported settings for the CCPP parameter are:** 

   | ``"FV3_GFS_v16"`` 
   | ``"FV3_RRFS_v1beta"`` 
   | ``"FV3_HRRR"``
   | ``"FV3_WoFS_v0"``

   **Other valid values include:**

   | ``"FV3_GFS_2017_gfdlmp"``
   | ``"FV3_GFS_2017_gfdlmp_regional"``
   | ``"FV3_GFS_v15p2"``
   | ``"FV3_GFS_v15_thompson_mynn_lam3km"``


.. _GridGen:

Grid Generation Parameters
------------------------------

``GRID_GEN_METHOD``: (Default: "")
   This variable specifies which method to use to generate a regional grid in the horizontal plane. The values that it can take on are:

   * ``"ESGgrid"``: The "ESGgrid" method will generate a regional version of the Extended Schmidt Gnomonic (ESG) grid using the map projection developed by Jim Purser of EMC (:cite:t:`Purser_2020`). "ESGgrid" is the preferred grid option. 

   * ``"GFDLgrid"``: The "GFDLgrid" method first generates a "parent" global cubed-sphere grid. Then a portion from tile 6 of the global grid is used as the regional grid. This regional grid is referred to in the grid generation scripts as "tile 7," even though it does not correspond to a complete tile. The forecast is run only on the regional grid (i.e., on tile 7, not on tiles 1 through 6). Note that the "GFDLgrid" method is the legacy grid generation method. It is not supported in *all* predefined domains. 

.. attention::

   If the experiment uses a **predefined grid** (i.e., if ``PREDEF_GRID_NAME`` is set to the name of a valid predefined grid), then ``GRID_GEN_METHOD`` will be reset to the value of ``GRID_GEN_METHOD`` for that grid. This will happen regardless of whether ``GRID_GEN_METHOD`` is assigned a value in the experiment configuration file; any value assigned will be overwritten.

.. note::

   If the experiment uses a **user-defined grid** (i.e., if ``PREDEF_GRID_NAME`` is set to a null string), then ``GRID_GEN_METHOD`` must be set in the experiment configuration file. Otherwise, the experiment generation will fail because the generation scripts check to ensure that the grid name is set to a non-empty string before creating the experiment directory.

Forecast Parameters
----------------------
``DATE_FIRST_CYCL``: (Default: "YYYYMMDDHH")
   Starting date of the first forecast in the set of forecasts to run. Format is "YYYYMMDDHH".

``DATE_LAST_CYCL``: (Default: "YYYYMMDDHH")
   Starting date of the last forecast in the set of forecasts to run. Format is "YYYYMMDDHH".

``INCR_CYCL_FREQ``: (Default: 24)
   Increment in hours for Rocoto cycle frequency. The default is 24, which means cycl_freq=24:00:00.

``FCST_LEN_HRS``: (Default: 24)
   The length of each forecast, in integer hours.

Pre-Existing Directory Parameter
------------------------------------
``PREEXISTING_DIR_METHOD``: (Default: "delete")
   This variable determines how to deal with pre-existing directories (resulting from previous calls to the experiment generation script using the same experiment name [``EXPT_SUBDIR``] as the current experiment). This variable must be set to one of three valid values: ``"delete"``, ``"rename"``, or ``"quit"``.  The behavior for each of these values is as follows:

   * **"delete":** The preexisting directory is deleted and a new directory (having the same name as the original preexisting directory) is created.

   * **"rename":** The preexisting directory is renamed and a new directory (having the same name as the original pre-existing directory) is created. The new name of the preexisting directory consists of its original name and the suffix "_old###", where ``###`` is a 3-digit integer chosen to make the new name unique.

   * **"quit":** The preexisting directory is left unchanged, but execution of the currently running script is terminated. In this case, the preexisting directory must be dealt with manually before rerunning the script.

Verbose Parameter
---------------------
``VERBOSE``: (Default: true)
   Flag that determines whether the experiment generation and workflow task scripts print out extra informational messages. Valid values: ``True`` | ``False``

Debug Parameter
--------------------
``DEBUG``: (Default: false)
   Flag that determines whether to print out very detailed debugging messages.  Note that if DEBUG is set to true, then VERBOSE will also be reset to true if it isn't already. Valid values: ``True`` | ``False``

Compiler
-----------

``COMPILER``: (Default: "intel")
   Type of compiler invoked during the build step. Currently, this must be set manually; it is not inherited from the build system in the ``ufs-srweather-app`` directory. Valid values: ``"intel"`` | ``"gnu"``

Verification Parameters
---------------------------

``GET_OBS``: (Default: "get_obs")
   Set the name of the Rocoto workflow task used to load proper module files for ``GET_OBS_*`` tasks. Users typically do not need to change this value. 

``TN_VX``: (Default: "run_vx")
   Set the name of the Rocoto workflow task used to load proper module files for ``VX_*`` tasks. Users typically do not need to change this value. 

``TN_VX_ENSGRID``: (Default: "run_ensgridvx")
   Set the name of the Rocoto workflow task that runs METplus grid-to-grid ensemble verification for 1-h accumulated precipitation. Users typically do not need to change this value. 

``TN_VX_ENSGRID_PROB_REFC``: (Default: "run_ensgridvx_prob_refc")
   Set the name of the Rocoto workflow task that runs METplus grid-to-grid verification for ensemble probabilities for composite reflectivity. Users typically do not need to change this value. 

``MAXTRIES_VX_ENSGRID_PROB_REFC``: (Default: 1)
   Maximum number of times to attempt ``TN_VX_ENSGRID_PROB_REFC``.


.. _NCOModeParms:

NCO-Specific Variables
=========================

A standard set of environment variables has been established for *nco* mode to simplify the production workflow and improve the troubleshooting process for operational and preoperational models. These variables are only used in *nco* mode (i.e., when ``RUN_ENVIR: "nco"``). When non-default parameters are selected for the variables in this section, they should be added to the ``nco:`` section of the ``config.yaml`` file. 

.. note::
   Only *community* mode is fully supported for this release. *nco* mode is used by those at the Environmental Modeling Center (EMC) and Global Systems Laboratory (GSL) who are working on pre-implementation operational testing. Other users should run the SRW App in *community* mode. 

``envir, NET, model_ver, RUN``:
   Standard environment variables defined in the NCEP Central Operations WCOSS Implementation Standards document. These variables are used in forming the path to various directories containing input, output, and workflow files. The variables are defined in the `WCOSS Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/ImplementationStandards.v11.0.0.pdf?>`__ document (pp. 4-5) as follows: 

   ``envir``: (Default: "para")
      Set to "test" during the initial testing phase, "para" when running in parallel (on a schedule), and "prod" in production. 

   ``NET``: (Default: "rrfs")
      Model name (first level of ``com`` directory structure)

   ``model_ver``: (Default: "v1.0.0")
      Version number of package in three digits (second level of ``com`` directory)

   ``RUN``: (Default: "rrfs")
      Name of model run (third level of ``com`` directory structure). In general, same as ``$NET``.

``OPSROOT``: (Default: "")
  The operations root directory in *nco* mode.

.. _workflow-switches:

WORKFLOW SWITCHES Configuration Parameters
=============================================

These parameters set flags that determine whether various workflow tasks should be run. When non-default parameters are selected for the variables in this section, they should be added to the ``workflow_switches:`` section of the ``config.yaml`` file. Note that the ``TN_MAKE_GRID``, ``TN_MAKE_OROG``, and ``TN_MAKE_SFC_CLIMO`` are all :term:`cycle-independent` tasks, i.e., if they are run, they only run once at the beginning of the workflow before any cycles are run. 

Baseline Workflow Tasks
--------------------------

``RUN_TASK_MAKE_GRID``: (Default: true)
   Flag that determines whether to run the grid file generation task (``TN_MAKE_GRID``). If this is set to true, the grid generation task is run and new grid files are generated. If it is set to false, then the scripts look for pre-generated grid files in the directory specified by ``GRID_DIR`` (see :numref:`Section %s <make-grid>` below). Valid values: ``True`` | ``False``

``RUN_TASK_MAKE_OROG``: (Default: true)
   Same as ``RUN_TASK_MAKE_GRID`` but for the orography generation task (``TN_MAKE_OROG``). Flag that determines whether to run the orography file generation task (``TN_MAKE_OROG``). If this is set to true, the orography generation task is run and new orography files are generated. If it is set to false, then the scripts look for pre-generated orography files in the directory specified by ``OROG_DIR`` (see :numref:`Section %s <make-orog>` below). Valid values: ``True`` | ``False``

``RUN_TASK_MAKE_SFC_CLIMO``: (Default: true)
   Same as ``RUN_TASK_MAKE_GRID`` but for the surface climatology generation task (``TN_MAKE_SFC_CLIMO``). Flag that determines whether to run the surface climatology file generation task (``TN_MAKE_SFC_CLIMO``). If this is set to true, the surface climatology generation task is run and new surface climatology files are generated. If it is set to false, then the scripts look for pre-generated surface climatology files in the directory specified by ``SFC_CLIMO_DIR`` (see :numref:`Section %s <make-sfc-climo>` below). Valid values: ``True`` | ``False``

``RUN_TASK_GET_EXTRN_ICS``: (Default: true)
   Flag that determines whether to run the ``TN_GET_EXTRN_ICS`` task.

``RUN_TASK_GET_EXTRN_LBCS``: (Default: true)
   Flag that determines whether to run the ``TN_GET_EXTRN_LBCS`` task.

``RUN_TASK_MAKE_ICS``: (Default: true)
   Flag that determines whether to run the ``TN_MAKE_ICS`` task.

``RUN_TASK_MAKE_LBCS``: (Default: true)
   Flag that determines whether to run the ``TN_MAKE_LBCS`` task.

``RUN_TASK_RUN_FCST``: (Default: true)
   Flag that determines whether to run the ``TN_RUN_FCST`` task.

``RUN_TASK_RUN_POST``: (Default: true)
   Flag that determines whether to run the ``TN_RUN_POST`` task. Valid values: ``True`` | ``False``

``RUN_TASK_RUN_PRDGEN``: (Default: false)
   Flag that determines whether to run the ``TN_RUN_PRDGEN`` task. Valid values: ``True`` | ``False``

.. _VXTasks:

Verification Tasks
--------------------

``RUN_TASK_GET_OBS_CCPA``: (Default: false)
   Flag that determines whether to run the ``TN_GET_OBS_CCPA`` task, which retrieves the :term:`CCPA` hourly precipitation files used by METplus from NOAA :term:`HPSS`. See :numref:`Section %s <get-obs-ccpa>` for additional parameters related to this task.

``RUN_TASK_GET_OBS_MRMS``: (Default: false)
   Flag that determines whether to run the ``TN_GET_OBS_MRMS`` task, which retrieves the :term:`MRMS` composite reflectivity files used by METplus from NOAA HPSS. See :numref:`Section %s <get-obs-mrms>` for additional parameters related to this task.

``RUN_TASK_GET_OBS_NDAS``: (Default: false)
   Flag that determines whether to run the ``TN_GET_OBS_NDAS`` task, which retrieves the :term:`NDAS` PrepBufr files used by METplus from NOAA HPSS. See :numref:`Section %s <get-obs-ndas>` for additional parameters related to this task.

``RUN_TASK_VX_GRIDSTAT``: (Default: false)
   Flag that determines whether to run the grid-stat verification task. The :ref:`MET Grid-Stat tool <grid-stat>` provides verification statistics for a matched forecast and observation grid. See :numref:`Section %s <VX-gridstat>` for additional parameters related to this task. Valid values: ``True`` | ``False``

``RUN_TASK_VX_POINTSTAT``: (Default: false)
   Flag that determines whether to run the point-stat verification task. The :ref:`MET Point-Stat tool <point-stat>` provides verification statistics for forecasts at observation points (as opposed to over gridded analyses). See :numref:`Section %s <VX-pointstat>` for additional parameters related to this task. Valid values: ``True`` | ``False``

``RUN_TASK_VX_ENSGRID``: (Default: false)
   Flag that determines whether to run the ensemble-stat verification for gridded data task. The :ref:`MET Ensemble-Stat tool <ensemble-stat>` provides verification statistics for ensemble forecasts and can be used in conjunction with the :ref:`MET Grid-Stat tool <grid-stat>`. See :numref:`Section %s <VX-ensgrid>` for additional parameters related to this task. Valid values: ``True`` | ``False``

``RUN_TASK_VX_ENSPOINT``: (Default: false)
   Flag that determines whether to run the ensemble point verification task. If this flag is set, both ensemble-stat point verification and point verification of ensemble-stat output is computed. The :ref:`MET Ensemble-Stat tool <ensemble-stat>` provides verification statistics for ensemble forecasts and can be used in conjunction with the :ref:`MET Point-Stat tool <point-stat>`. See :numref:`Section %s <VX-enspoint>` for additional parameters related to this task. Valid values: ``True`` | ``False``

.. COMMENT: COMMENT: Define "ensemble-stat verification for gridded data," "ensemble point verification," "ensemble-stat point verification," and "point verification of ensemble-stat output"?

Plotting Task
----------------

``RUN_TASK_PLOT_ALLVARS:`` (Default: false)
   Flag that determines whether to run python plotting scripts.

.. _make-grid:

MAKE_GRID Configuration Parameters
======================================

Non-default parameters for the ``make_grid`` task are set in the ``task_make_grid:`` section of the ``config.yaml`` file. 

Basic Task Parameters
--------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. Typically, users do not need to adjust the default values. 

   ``TN_MAKE_GRID``: (Default: "make_grid")
      Set the name of this :term:`cycle-independent` Rocoto workflow task. Users typically do not need to change this value. 

   ``NNODES_MAKE_GRID``: (Default: 1)
      Number of nodes to use for the job. 

   ``PPN_MAKE_GRID``: (Default: 24)
      Number of :term:`MPI` processes per node. 

   ``WTIME_MAKE_GRID``: (Default: 00:20:00)
      Maximum time for the task to complete. 

   ``MAXTRIES_MAKE_GRID``: (Default: 2)
      Maximum number of times to attempt the task.

   ``GRID_DIR``: (Default: "")
      The directory containing pre-generated grid files when ``RUN_TASK_MAKE_GRID`` is set to false.

.. _ESGgrid:

ESGgrid Settings
-------------------

The following parameters must be set if using the "ESGgrid" method to generate a regional grid (i.e., when ``GRID_GEN_METHOD: "ESGgrid"``, see :numref:`Section %s <GridGen>`). If a different ``GRID_GEN_METHOD`` is used, these parameters will be ignored. When using a predefined grid with ``GRID_GEN_METHOD: "ESGgrid"``, the values in this section will be set automatically to the assigned values for that grid.

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
   The width (in number of grid cells) of the :term:`halo` to add around the regional grid before shaving the halo down to the width(s) expected by the forecast model. The user need not specify this variable since it is set automatically in ``set_gridparams_ESGgrid.py``

.. _WideHalo:

.. note::
   A :term:`halo` is the strip of cells surrounding the regional grid; the halo is used to feed in the lateral boundary conditions to the grid. The forecast model requires **grid** files containing 3-cell- and 4-cell-wide halos and **orography** files with 0-cell- and 3-cell-wide halos. In order to generate grid and orography files with appropriately-sized halos, the grid and orography tasks create preliminary files with halos around the regional domain of width ``ESGgrid_WIDE_HALO_WIDTH`` cells. The files are then read in and "shaved" down to obtain grid files with 3-cell-wide and 4-cell-wide halos and orography files with 0-cell-wide and 3-cell-wide halos. The original halo that gets shaved down is referred to as the "wide" halo because it is wider than the 0-cell-wide, 3-cell-wide, and 4-cell-wide halos that users eventually end up with. Note that the grid and orography files with the wide halo are only needed as intermediates in generating the files with 0-cell-, 3-cell-, and 4-cell-wide halos; they are not needed by the forecast model.

GFDLgrid Settings
---------------------

The following parameters must be set if using the "GFDLgrid" method to generate a regional grid (i.e., when ``GRID_GEN_METHOD: "GFDLgrid"``, see :numref:`Section %s <GridGen>`). If a different ``GRID_GEN_METHOD`` is used, these parameters will be ignored. When using a predefined grid with ``GRID_GEN_METHOD: "GFDLgrid"``, the values in this section will be set automatically to the assigned values for that grid. 

Note that the regional grid is defined with respect to a "parent" global cubed-sphere grid. Thus, all the parameters for a global cubed-sphere grid must be specified even though the model equations are integrated only on the regional grid. Tile 6 has arbitrarily been chosen as the tile to use to orient the global parent grid on the sphere (Earth). For convenience, the regional grid is denoted as "tile 7" even though it is embedded within tile 6 (i.e., it doesn't extend beyond the boundary of tile 6). Its exact location within tile 6 is determined by specifying the starting and ending i- and j-indices of the regional grid on tile 6, where ``i`` is the grid index in the x direction and ``j`` is the grid index in the y direction. All of this information is set in the variables below. 

``GFDLgrid_LON_T6_CTR``: (Default: "")
   Longitude of the center of tile 6 (in degrees).

``GFDLgrid_LAT_T6_CTR``: (Default: "")
   Latitude of the center of tile 6 (in degrees).

``GFDLgrid_NUM_CELLS``: (Default: "")
   Number of grid cells in either of the two horizontal directions (x and y) on each of the six tiles of the parent global cubed-sphere grid. Valid values: ``48`` | ``96`` | ``192`` | ``384`` | ``768`` | ``1152`` | ``3072``

   To give an idea of what these values translate to in terms of grid cell size in kilometers, we list below the approximate grid cell size on a uniform global grid having the specified value of ``GFDLgrid_NUM_CELLS``, where by "uniform" we mean with Schmidt stretch factor ``GFDLgrid_STRETCH_FAC: "1"`` (although in regional applications ``GFDLgrid_STRETCH_FAC`` will typically be set to a value greater than ``"1"`` to obtain a smaller grid size on tile 6):

         +---------------------+--------------------+
         | GFDLgrid_NUM_CELLS  | Typical Cell Size  |
         +=====================+====================+
         |  48                 |     200 km         |
         +---------------------+--------------------+
         |  96                 |     100 km         |
         +---------------------+--------------------+
         | 192                 |      50 km         |
         +---------------------+--------------------+
         | 384                 |      25 km         |
         +---------------------+--------------------+
         | 768                 |      13 km         |
         +---------------------+--------------------+
         | 1152                |      8.5 km        |
         +---------------------+--------------------+
         | 3072                |      3.2 km        |
         +---------------------+--------------------+

      Note that these are only typical cell sizes. The actual cell size on the global grid tiles varies somewhat as we move across a tile and is also dependent on ``GFDLgrid_STRETCH_FAC``, which modifies the shape and size of the tile.

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
   Flag that determines the file naming convention to use for grid, orography, and surface climatology files (or, if using pregenerated files, the naming convention that was used to name these files).  These files usually start with the string ``"C${RES}_"``, where ``RES`` is an integer. In the global forecast model, ``RES`` is the number of points in each of the two horizontal directions (x and y) on each tile of the global grid (defined here as ``GFDLgrid_NUM_CELLS``). If this flag is set to true, ``RES`` will be set to ``GFDLgrid_NUM_CELLS`` just as in the global forecast model. If it is set to false, we calculate (in the grid generation task) an "equivalent global uniform cubed-sphere resolution" --- call it ``RES_EQUIV`` --- and then set ``RES`` equal to it. ``RES_EQUIV`` is the number of grid points in each of the x and y directions on each tile that a global UNIFORM (i.e., stretch factor of 1) cubed-sphere grid would need to have in order to have the same average grid size as the regional grid. This is a more useful indicator of the grid size because it takes into account the effects of ``GFDLgrid_NUM_CELLS``, ``GFDLgrid_STRETCH_FAC``, and ``GFDLgrid_REFINE_RATIO`` in determining the regional grid's typical grid size, whereas simply setting ``RES`` to ``GFDLgrid_NUM_CELLS`` doesn't take into account the effects of ``GFDLgrid_STRETCH_FAC`` and ``GFDLgrid_REFINE_RATIO`` on the regional grid's resolution. Nevertheless, some users still prefer to use ``GFDLgrid_NUM_CELLS`` in the file names, so we allow for that here by setting this flag to true.

.. _make-orog:
 
MAKE_OROG Configuration Parameters
=====================================

Non-default parameters for the ``make_orog`` task are set in the ``task_make_orog:`` section of the ``config.yaml`` file. 

``TN_MAKE_OROG``: (Default: "make_orog")
   Set the name of this :term:`cycle-independent` Rocoto workflow task. Users typically do not need to change this value.

``NNODES_MAKE_OROG``: (Default: 1)
   Number of nodes to use for the job. 

``PPN_MAKE_OROG``: (Default: 24)
   Number of :term:`MPI` processes per node. 

``WTIME_MAKE_OROG``: (Default: 00:20:00)
   Maximum time for the task to complete.

``MAXTRIES_MAKE_OROG``: (Default: 2)
   Maximum number of times to attempt the task.

``KMP_AFFINITY_MAKE_OROG``: (Default: "disabled")
   Intel Thread Affinity Interface for the ``make_orog`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity. Settings for the ``make_orog`` task is disabled because this task does not use parallelized code.

``OMP_NUM_THREADS_MAKE_OROG``: (Default: 6)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_MAKE_OROG``: (Default: "2048m")
   Controls the size of the stack for threads created by the OpenMP implementation.

``OROG_DIR``: (Default: "")
   The directory containing pre-generated orography files to use when ``TN_MAKE_OROG`` is set to false.

.. _make-sfc-climo:

MAKE_SFC_CLIMO Configuration Parameters
===========================================

Non-default parameters for the ``make_sfc_climo`` task are set in the ``task_make_sfc_climo:`` section of the ``config.yaml`` file. 

``TN_MAKE_SFC_CLIMO``: "make_sfc_climo"
   Set the name of this :term:`cycle-independent` Rocoto workflow task. Users typically do not need to change this value.

``NNODES_MAKE_SFC_CLIMO``: (Default: 2)
   Number of nodes to use for the job. 

``PPN_MAKE_SFC_CLIMO``: (Default: 24)
   Number of :term:`MPI` processes per node. 

``WTIME_MAKE_SFC_CLIMO``: (Default: 00:20:00)
   Maximum time for the task to complete.

``MAXTRIES_MAKE_SFC_CLIMO``: (Default: 2)
   Maximum number of times to attempt the task.

``KMP_AFFINITY_MAKE_SFC_CLIMO``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``make_sfc_climo`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_MAKE_SFC_CLIMO``: (Default: 1)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_MAKE_SFC_CLIMO``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

``SFC_CLIMO_DIR``: (Default: "")
   The directory containing pre-generated surface climatology files to use when ``TN_MAKE_SFC_CLIMO`` is set to false.

.. _task_get_extrn_ics:

GET_EXTRN_ICS Configuration Parameters
=========================================

Non-default parameters for the ``get_extrn_ics`` task are set in the ``task_get_extrn_ics:`` section of the ``config.yaml`` file. 

.. _basic-get-extrn-ics:

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``TN_GET_EXTRN_ICS``: (Default: "get_extrn_ics")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_GET_EXTRN_ICS``: (Default: 1)
   Number of nodes to use for the job.

``PPN_GET_EXTRN_ICS``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_GET_EXTRN_ICS``: (Default: 00:45:00)
   Maximum time for the task to complete.

``MAXTRIES_GET_EXTRN_ICS``: (Default: 1)
   Maximum number of times to attempt the task.

``EXTRN_MDL_NAME_ICS``: (Default: "FV3GFS")
   The name of the external model that will provide fields from which initial condition (IC) files, surface files, and 0-th hour boundary condition files will be generated for input into the forecast model. Valid values: ``"GSMGFS"`` | ``"FV3GFS"`` | ``"GEFS"`` | ``"GDAS"`` | ``"RAP"`` | ``"HRRR"`` | ``"NAM"``

``EXTRN_MDL_ICS_OFFSET_HRS``: (Default: 0)
   Users may wish to start a forecast using forecast data from a previous cycle of an external model. This variable indicates how many hours earlier the external model started than the FV3 forecast configured here. For example, if the forecast should start from a 6-hour forecast of the GFS, then ``EXTRN_MDL_ICS_OFFSET_HRS: "6"``.

``FV3GFS_FILE_FMT_ICS``: (Default: "nemsio")
   If using the FV3GFS model as the source of the :term:`ICs` (i.e., if ``EXTRN_MDL_NAME_ICS: "FV3GFS"``), this variable specifies the format of the model files to use when generating the ICs. Valid values: ``"nemsio"`` | ``"grib2"`` | ``"netcdf"``

File and Directory Parameters
--------------------------------

``USE_USER_STAGED_EXTRN_FILES``: (Default: false)
   Flag that determines whether the workflow will look for the external model files needed for generating :term:`ICs` in user-specified directories (rather than fetching them from mass storage like NOAA :term:`HPSS`). Valid values: ``True`` | ``False``

``EXTRN_MDL_SOURCE_BASEDIR_ICS``: (Default: "")
   Directory containing external model files for generating ICs. If ``USE_USER_STAGED_EXTRN_FILES`` is set to true, the workflow looks within this directory for a subdirectory named "YYYYMMDDHH", which contains the external model files specified by the array ``EXTRN_MDL_FILES_ICS``. This "YYYYMMDDHH" subdirectory corresponds to the start date and cycle hour of the forecast (see :ref:`above <METParamNote>`). These files will be used to generate the :term:`ICs` on the native FV3-LAM grid. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to false.

``EXTRN_MDL_SYSBASEDIR_ICS``: (Default: '')
   A known location of a real data stream on a given platform. This is typically a real-time data stream as on Hera, Jet, or WCOSS. External model files for generating :term:`ICs` on the native grid should be accessible via this data stream. The way the full path containing these files is constructed depends on the user-specified external model for ICs (defined above in :numref:`Section %s <basic-get-extrn-ics>` ``EXTRN_MDL_NAME_ICS``).

   .. note::
      This variable must be defined as a null string in ``config_defaults.yaml`` so that if it is specified by the user in the experiment configuration file (``config.yaml``), it remains set to those values, and if not, it gets set to machine-dependent values.

``EXTRN_MDL_FILES_ICS``: (Default: "")
   Array containing templates of the file names to search for in the ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` directory. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to false. A single template should be used for each model file type that is used. Users may use any of the Python-style templates allowed in the ``ush/retrieve_data.py`` script. To see the full list of supported templates, run that script with the ``-h`` option. 
   
   For example, to set FV3GFS nemsio input files:
   
   .. code-block:: console

      EXTRN_MDL_FILES_ICS=[ gfs.t{hh}z.atmf{fcst_hr:03d}.nemsio ,
      gfs.t{hh}z.sfcf{fcst_hr:03d}.nemsio ]
  
   To set FV3GFS grib files:

   .. code-block:: console

      EXTRN_MDL_FILES_ICS=[ gfs.t{hh}z.pgrb2.0p25.f{fcst_hr:03d} ]

``EXTRN_MDL_DATA_STORES``: (Default: "")
   A list of data stores where the scripts should look to find external model data. The list is in priority order. If disk information is provided via ``USE_USER_STAGED_EXTRN_FILES`` or a known location on the platform, the disk location will receive highest priority. Valid values: ``disk`` | ``hpss`` | ``aws`` | ``nomads``

NOMADS Parameters
---------------------

Set parameters associated with NOMADS online data.

``NOMADS``: (Default: false)
   Flag controlling whether to use NOMADS online data. Valid values: ``True`` | ``False``

``NOMADS_file_type``: (Default: "nemsio")
   Flag controlling the format of the data. Valid values: ``"GRIB2"`` | ``"grib2"`` | ``"NEMSIO"`` | ``"nemsio"``

.. _task_get_extrn_lbcs:

GET_EXTRN_LBCS Configuration Parameters
==========================================

Non-default parameters for the ``get_extrn_lbcs`` task are set in the ``task_get_extrn_lbcs:`` section of the ``config.yaml`` file. 

.. _basic-get-extrn-lbcs:

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``TN_GET_EXTRN_LBCS``: (Default: "get_extrn_lbcs")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_GET_EXTRN_LBCS``: (Default: 1)
   Number of nodes to use for the job.

``PPN_GET_EXTRN_LBCS``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_GET_EXTRN_LBCS``: (Default: 00:45:00)
   Maximum time for the task to complete.

``MAXTRIES_GET_EXTRN_LBCS``: (Default: 1)
   Maximum number of times to attempt the task.

``EXTRN_MDL_NAME_LBCS``: (Default: "FV3GFS")
   The name of the external model that will provide fields from which lateral boundary condition (LBC) files (except for the 0-th hour LBC file) will be generated for input into the forecast model. Valid values: ``"GSMGFS"`` | ``"FV3GFS"`` | ``"GEFS"`` | ``"GDAS"`` | ``"RAP"`` | ``"HRRR"`` | ``"NAM"``

``LBC_SPEC_INTVL_HRS``: (Default: "6")
   The interval (in integer hours) at which LBC files will be generated. This is also referred to as the *boundary update interval*. Note that the model selected in ``EXTRN_MDL_NAME_LBCS`` must have data available at a frequency greater than or equal to that implied by ``LBC_SPEC_INTVL_HRS``. For example, if ``LBC_SPEC_INTVL_HRS`` is set to "6", then the model must have data available at least every 6 hours. It is up to the user to ensure that this is the case.

``EXTRN_MDL_LBCS_OFFSET_HRS``: (Default: "")
   Users may wish to use lateral boundary conditions from a forecast that was started earlier than the start of the forecast configured here. This variable indicates how many hours earlier the external model started than the FV3 forecast configured here. For example, if the forecast should use lateral boundary conditions from the GFS started 6 hours earlier, then ``EXTRN_MDL_LBCS_OFFSET_HRS: "6"``. Note: the default value is model-dependent and is set in ``ush/set_extrn_mdl_params.py``.

``FV3GFS_FILE_FMT_LBCS``: (Default: "nemsio")
   If using the FV3GFS model as the source of the :term:`LBCs` (i.e., if ``EXTRN_MDL_NAME_LBCS: "FV3GFS"``), this variable specifies the format of the model files to use when generating the LBCs. Valid values: ``"nemsio"`` | ``"grib2"`` | ``"netcdf"``


File and Directory Parameters
--------------------------------

``USE_USER_STAGED_EXTRN_FILES``: (Default: false)
   Analogous to ``USE_USER_STAGED_EXTRN_FILES`` in :term:`ICs` but for :term:`LBCs`. Flag that determines whether the workflow will look for the external model files needed for generating :term:`LBCs` in user-specified directories (rather than fetching them from mass storage like NOAA :term:`HPSS`). Valid values: ``True`` | ``False``
 
``EXTRN_MDL_SOURCE_BASEDIR_LBCS``: (Default: "")
   Analogous to ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` but for :term:`LBCs` instead of :term:`ICs`.
   Directory containing external model files for generating LBCs. If ``USE_USER_STAGED_EXTRN_FILES`` is set to true, the workflow looks within this directory for a subdirectory named "YYYYMMDDHH", which contains the external model files specified by the array ``EXTRN_MDL_FILES_LBCS``. This "YYYYMMDDHH" subdirectory corresponds to the start date and cycle hour of the forecast (see :ref:`above <METParamNote>`). These files will be used to generate the :term:`LBCs` on the native FV3-LAM grid. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to false.

``EXTRN_MDL_SYSBASEDIR_LBCS``: (Default: '')
   Same as ``EXTRN_MDL_SYSBASEDIR_ICS`` but for :term:`LBCs`. A known location of a real data stream on a given platform. This is typically a real-time data stream as on Hera, Jet, or WCOSS. External model files for generating :term:`LBCs` on the native grid should be accessible via this data stream. The way the full path containing these files is constructed depends on the user-specified external model for LBCs (defined above in :numref:`Section %s <basic-get-extrn-lbcs>` ``EXTRN_MDL_NAME_LBCS`` above).

   .. note::
      This variable must be defined as a null string in ``config_defaults.yaml`` so that if it is specified by the user in the experiment configuration file (``config.yaml``), it remains set to those values, and if not, it gets set to machine-dependent values.

``EXTRN_MDL_FILES_LBCS``: (Default: "")
   Analogous to ``EXTRN_MDL_FILES_ICS`` but for :term:`LBCs` instead of :term:`ICs`. Array containing templates of the file names to search for in the ``EXTRN_MDL_SOURCE_BASEDIR_LBCS`` directory. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to false. A single template should be used for each model file type that is used. Users may use any of the Python-style templates allowed in the ``ush/retrieve_data.py`` script. To see the full list of supported templates, run that script with the ``-h`` option. For examples, see the ``EXTRN_MDL_FILES_ICS`` variable above. 
   
``EXTRN_MDL_DATA_STORES``: (Default: "")
   Analogous to ``EXTRN_MDL_DATA_STORES`` in :term:`ICs` but for :term:`LBCs`. A list of data stores where the scripts should look to find external model data. The list is in priority order. If disk information is provided via ``USE_USER_STAGED_EXTRN_FILES`` or a known location on the platform, the disk location will receive highest priority. Valid values: ``disk`` | ``hpss`` | ``aws`` | ``nomads``

NOMADS Parameters
---------------------

Set parameters associated with NOMADS online data. Analogus to :term:`ICs` NOMADS Parameters. 

``NOMADS``: (Default: false)
   Flag controlling whether to use NOMADS online data.

``NOMADS_file_type``: (Default: "nemsio")
   Flag controlling the format of the data. Valid values: ``"GRIB2"`` | ``"grib2"`` | ``"NEMSIO"`` | ``"nemsio"``

MAKE_ICS Configuration Parameters
======================================

Non-default parameters for the ``make_ics`` task are set in the ``task_make_ics:`` section of the ``config.yaml`` file. 

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``TN_MAKE_ICS``: (Default: "make_ics")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_MAKE_ICS``: (Default: 4)
   Number of nodes to use for the job.

``PPN_MAKE_ICS``: (Default: 12)
   Number of :term:`MPI` processes per node.

``WTIME_MAKE_ICS``: (Default: 00:30:00)
   Maximum time for the task to complete.

``MAXTRIES_MAKE_ICS``: (Default: 1)
   Maximum number of times to attempt the task.

``KMP_AFFINITY_MAKE_ICS``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``make_ics`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_MAKE_ICS``: (Default: 1)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_MAKE_ICS``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

FVCOM Parameter
-------------------
``USE_FVCOM``: (Default: false)
   Flag that specifies whether to update surface conditions in FV3-:term:`LAM` with fields generated from the Finite Volume Community Ocean Model (:term:`FVCOM`). If set to true, lake/sea surface temperatures, ice surface temperatures, and ice placement will be overwritten using data provided by FVCOM. Setting ``USE_FVCOM`` to true causes the executable ``process_FVCOM.exe`` in the ``TN_MAKE_ICS`` task to run. This, in turn, modifies the file ``sfc_data.nc`` generated by ``chgres_cube`` during the ``make_ics`` task. Note that the FVCOM data must already be interpolated to the desired FV3-LAM grid. Valid values: ``True`` | ``False``

``FVCOM_WCSTART``: (Default: "cold")
   Define if this is a "warm" start or a "cold" start. Setting this to "warm" will read in ``sfc_data.nc`` generated in a RESTART directory. Setting this to "cold" will read in the ``sfc_data.nc`` generated from ``chgres_cube`` in the ``make_ics`` portion of the workflow. Valid values: ``"cold"`` | ``"COLD"`` | ``"warm"`` | ``"WARM"``

``FVCOM_DIR``: (Default: "")
   User-defined directory where the ``fvcom.nc`` file containing :term:`FVCOM` data already interpolated to the FV3-LAM native grid is located. The file in this directory must be named ``fvcom.nc``.

``FVCOM_FILE``: (Default: "fvcom.nc")
   Name of the file located in ``FVCOM_DIR`` that has :term:`FVCOM` data interpolated to the FV3-LAM grid. This file will be copied later to a new location, and the name will be changed to ``fvcom.nc`` if a name other than ``fvcom.nc`` is selected.


MAKE_LBCS Configuration Parameters
======================================

Non-default parameters for the ``make_lbcs`` task are set in the ``task_make_lbcs:`` section of the ``config.yaml`` file. 

``TN_MAKE_LBCS``: (Default: "make_lbcs")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_MAKE_LBCS``: (Default: 4)
   Number of nodes to use for the job.

``PPN_MAKE_LBCS``: (Default: 12)
   Number of :term:`MPI` processes per node.

``WTIME_MAKE_LBCS``: (Default: 00:30:00)
   Maximum time for the task to complete.

``MAXTRIES_MAKE_LBCS``: (Default: 1)
   Maximum number of times to attempt the task.

``KMP_AFFINITY_MAKE_LBCS``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``make_lbcs`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_MAKE_LBCS``: (Default: 1)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_MAKE_LBCS``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

.. _FcstConfigParams:

FORECAST Configuration Parameters
=====================================

Non-default parameters for the ``run_fcst`` task are set in the ``task_run_fcst:`` section of the ``config.yaml`` file. 

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``TN_RUN_FCST``: (Default: "run_fcst")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_RUN_FCST``: (Default: "")
   Number of nodes to use for the job. This is calculated in the workflow generation scripts, so there is no need to set it in the configuration file.

``PPN_RUN_FCST``: (Default: "")
   Number of :term:`MPI` processes per node. It will be calculated from ``NCORES_PER_NODE`` and ``OMP_NUM_THREADS`` in ``setup.py``.

``WTIME_RUN_FCST``: (Default: 04:30:00)
   Maximum time for the task to complete.

``MAXTRIES_RUN_FCST``: (Default: 1)
   Maximum number of times to attempt the task.

``KMP_AFFINITY_RUN_FCST``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``run_fcst`` task. 

.. _thread-affinity:

   .. note:: 

      **Thread Affinity Interface**

      "Intel's runtime library can bind OpenMP threads to physical processing units. The interface is controlled using the ``KMP_AFFINITY`` environment variable. Thread affinity restricts execution of certain threads to a subset of the physical processing units in a multiprocessor computer. Depending on the system (machine) topology, application, and operating system, thread affinity can have a dramatic effect on the application speed and on the execution speed of a program." Valid values: ``"scatter"`` | ``"disabled"`` | ``"balanced"`` | ``"compact"`` | ``"explicit"`` | ``"none"``

      For more information, see the `Intel Development Reference Guide <https://software.intel.com/content/www/us/en/develop/documentation/cpp-compiler-developer-guide-and-reference/top/optimization-and-programming-guide/openmp-support/openmp-library-support/thread-affinity-interface-linux-and-windows.html>`__. 

``OMP_NUM_THREADS_RUN_FCST``: (Default: 2)
   The number of OpenMP threads to use for parallel regions. Corresponds to the ``atmos_nthreads`` value in ``model_configure``.

``OMP_STACKSIZE_RUN_FCST``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

.. _ModelConfigParams:

Model Configuration Parameters
----------------------------------

These parameters set values in the Weather Model's ``model_configure`` file.

``DT_ATMOS``: (Default: "")
   Time step for the outermost atmospheric model loop in seconds. This corresponds to the frequency at which the physics routines and the top level dynamics routine are called. (Note that one call to the top-level dynamics routine results in multiple calls to the horizontal dynamics, :term:`tracer` transport, and vertical dynamics routines; see the `FV3 dycore scientific documentation <https://repository.library.noaa.gov/view/noaa/30725>`__ for details.) Must be set. Takes an integer value. In the SRW App, a default value for ``DT_ATMOS`` appears in the ``set_predef_grid_params.yaml`` script, but a different value can be set in ``config.yaml``. In general, the smaller the grid cell size is, the smaller this value needs to be in order to avoid numerical instabilities during the forecast.

``RESTART_INTERVAL``: (Default: 0)
   Frequency of the output restart files in hours. Using the default interval (0), restart files are produced at the end of a forecast run. When ``RESTART_INTERVAL: 1``, restart files are produced every hour with the prefix "YYYYMMDD.HHmmSS." in the ``RESTART`` directory. 

.. _InlinePost:

``WRITE_DOPOST``: (Default: false)
   Flag that determines whether to use the inline post option. The default ``WRITE_DOPOST: false`` does not use the inline post functionality, and the ``run_post`` tasks are called from outside of the Weather Model. If ``WRITE_DOPOST: true``, the ``WRITE_DOPOST`` flag in the ``model_configure`` file will be set to true, and the post-processing (:term:`UPP`) tasks will be called from within the Weather Model. This means that the post-processed files (in :term:`grib2` format) are output by the Weather Model at the same time that it outputs the ``dynf###.nc`` and ``phyf###.nc`` files. Setting ``WRITE_DOPOST: true`` turns off the separate ``run_post`` task (i.e., ``RUN_TASK_RUN_POST`` is set to false) in ``setup.py`` to avoid unnecessary computations. Valid values: ``True`` | ``False``

Computational Parameters
----------------------------

``LAYOUT_X, LAYOUT_Y``: (Default: "")
   The number of :term:`MPI` tasks (processes) to use in the two horizontal directions (x and y) of the regional grid when running the forecast model.

``BLOCKSIZE``: (Default: "")
   The amount of data that is passed into the cache at a time.

.. note::

   In ``config_defaults.yaml`` the computational parameters are set to null strings so that:

   #. If the experiment is using a predefined grid and the user sets the parameter in the user-specified experiment configuration file (i.e., ``config.yaml``), that value will be used in the forecast(s). Otherwise, the default value for that predefined grid will be used.
   #. If the experiment is *not* using a predefined grid (i.e., it is using a custom grid whose parameters are specified in the experiment configuration file), then the user must specify a value for the parameter in that configuration file. Otherwise, the parameter will remain set to a null string, and the experiment generation will fail because the generation scripts check to ensure that all the parameters defined in this section are set to non-empty strings before creating the experiment directory.

.. _WriteComp:

Write-Component (Quilting) Parameters
-----------------------------------------

.. note::
   The :term:`UPP` (called by the ``TN_RUN_POST`` task) cannot process output on the native grid types ("GFDLgrid" and "ESGgrid"), so output fields are interpolated to a **write component grid** before writing them to an output file. The output files written by the UFS Weather Model use an Earth System Modeling Framework (:term:`ESMF`) component, referred to as the **write component**. This model component is configured with settings in the ``model_configure`` file, as described in `Section 4.2.3 <https://ufs-weather-model.readthedocs.io/en/latest/InputsOutputs.html#model-configure-file>`__ of the UFS Weather Model documentation. 

``QUILTING``: (Default: true)

   .. attention::
      The regional grid requires the use of the write component, so users generally should not need to change the default value for ``QUILTING``. 

   Flag that determines whether to use the write component for writing forecast output files to disk. If set to true, the forecast model will output files named ``dynf$HHH.nc`` and ``phyf$HHH.nc`` (where ``HHH`` is the 3-digit forecast hour) containing dynamics and physics fields, respectively, on the write-component grid. For example, the output files for the 3rd hour of the forecast would be ``dynf$003.nc`` and ``phyf$003.nc``. (The regridding from the native FV3-LAM grid to the write-component grid is done by the forecast model.) If ``QUILTING`` is set to false, then the output file names are ``fv3_history.nc`` and ``fv3_history2d.nc``, and they contain fields on the native grid. Although the UFS Weather Model can run without quilting, the regional grid requires the use of the write component. Therefore, QUILTING should be set to true when running the SRW App. If ``QUILTING`` is set to false, the ``TN_RUN_POST`` (meta)task cannot run because the :term:`UPP` code called by this task cannot process fields on the native grid. In that case, the ``TN_RUN_POST`` (meta)task will be automatically removed from the Rocoto workflow XML. The :ref:`INLINE POST <InlinePost>` option also requires ``QUILTING`` to be set to true in the SRW App. Valid values: ``True`` | ``False``

``PRINT_ESMF``: (Default: false)
   Flag that determines whether to output extra (debugging) information from :term:`ESMF` routines. Note that the write component uses ESMF library routines to interpolate from the native forecast model grid to the user-specified output grid (which is defined in the model configuration file ``model_configure`` in the forecast run directory). Valid values: ``True`` | ``False``

``WRTCMP_write_groups``: (Default: 1)
   The number of write groups (i.e., groups of :term:`MPI` tasks) to use in the write component. Each write group will write to one set of output files (a ``dynf${fhr}.nc`` and a ``phyf${fhr}.nc`` file, where ``${fhr}`` is the forecast hour). Each write group contains ``WRTCMP_write_tasks_per_group`` tasks. Usually, one write group is sufficient. This may need to be increased if the forecast is proceeding so quickly that a single write group cannot complete writing to its set of files before there is a need/request to start writing the next set of files at the next output time.

``WRTCMP_write_tasks_per_group``: (Default: 20)
   The number of MPI tasks to allocate for each write group.

``WRTCMP_output_grid``: (Default: "''")
   Sets the type (coordinate system) of the write component grid. The default empty string forces the user to set a valid value for ``WRTCMP_output_grid`` in ``config.yaml`` if specifying a *custom* grid. When creating an experiment with a user-defined grid, this parameter must be specified or the experiment will fail. Valid values: ``"lambert_conformal"`` | ``"regional_latlon"`` | ``"rotated_latlon"``

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

.. _PredefGrid:

Predefined Grid Parameters
------------------------------

``PREDEF_GRID_NAME``: (Default: "")
   This parameter indicates which (if any) predefined regional grid to use for the experiment. Setting ``PREDEF_GRID_NAME`` provides a convenient method of specifying a commonly used set of grid-dependent parameters. The predefined grid settings can be viewed in the script ``ush/set_predef_grid_params.yaml``. 
   
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

   * If ``PREDEF_GRID_NAME`` is set to a valid predefined grid name, the grid generation method, the (native) grid parameters, and the write component grid parameters are set to predefined values for the specified grid, overwriting any settings of these parameters in the user-specified experiment configuration file (``config.yaml``). In addition, if the time step ``DT_ATMOS`` and the computational parameters (``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE``) are not specified in that configuration file, they are also set to predefined values for the specified grid.

   * If ``PREDEF_GRID_NAME`` is set to an empty string, it implies that the user will provide the native grid parameters in the user-specified experiment configuration file (``config.yaml``).  In this case, the grid generation method, the native grid parameters, the write component grid parameters, the main time step (``DT_ATMOS``), and the computational parameters (``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE``) must be set in the configuration file. Otherwise, the values of the parameters in the default experiment configuration file (``config_defaults.yaml``) will be used.

Aerosol Climatology Parameter
---------------------------------

``USE_MERRA_CLIMO``: (Default: false)
   Flag that determines whether :term:`MERRA2` aerosol climatology data and lookup tables for optics properties are obtained. Valid values: ``True`` | ``False``

   .. COMMENT: When would it be appropriate to obtain these files?

Fixed File Parameters
-------------------------

These parameters are associated with the fixed (i.e., static) files. On `Level 1 & 2 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, fixed files are pre-staged with paths defined in the ``setup.py`` script. Because the default values are platform-dependent, they are set to a null string in ``config_defaults.yaml``. Then these null values are overwritten in ``setup.py`` with machine-specific values or with a user-specified value from ``config.yaml``.

``FIXgsm``: (Default: "")
   System directory in which the majority of fixed (i.e., time-independent) files that are needed to run the FV3-LAM model are located.

``FIXaer``: (Default: "")
   System directory where :term:`MERRA2` aerosol climatology files are located.

``FIXlut``: (Default: "")
   System directory where the lookup tables for optics properties are located.

``FIXshp``: (Default: "")
   System directory where the graphics shapefiles are located. On Level 1 systems, these are set within the machine files. Users on other systems will need to provide the path to the directory that contains the *Natural Earth* shapefiles.

``TOPO_DIR``: (Default: "")
   The location on disk of the static input files used by the ``make_orog`` task (i.e., ``orog.x`` and ``shave.x``). Can be the same as ``FIXgsm``.

``SFC_CLIMO_INPUT_DIR``: (Default: "")
   The location on disk of the static surface climatology input fields, used by ``sfc_climo_gen``. These files are only used if ``RUN_TASK_MAKE_SFC_CLIMO: true``.

``SYMLINK_FIX_FILES``: (Default: true)
   Flag that indicates whether to symlink or copy fix files to the experiment directory. 

RUN_POST Configuration Parameters
=====================================

Non-default parameters for the ``run_post`` task are set in the ``task_run_post:`` section of the ``config.yaml`` file. 

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``TN_RUN_POST``: (Default: "run_post")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_RUN_POST``: (Default: 2)
   Number of nodes to use for the job. 

``PPN_RUN_POST``: (Default: 24)
   Number of :term:`MPI` processes per node.

``WTIME_RUN_POST``: (Default: 00:15:00)
   Maximum time for the task to complete.

``MAXTRIES_RUN_POST``: (Default: 2)
   Maximum number of times to attempt the task.

``KMP_AFFINITY_RUN_POST``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``run_post`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_RUN_POST``: (Default: 1)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_RUN_POST``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.


Subhourly Post Parameters
-----------------------------
Set parameters associated with subhourly forecast model output and post-processing. 

``SUB_HOURLY_POST``: (Default: false)
   Flag that indicates whether the forecast model will generate output files on a sub-hourly time interval (e.g., 10 minutes, 15 minutes). This will also cause the post-processor to process these sub-hourly files. If this variable is set to true, then ``DT_SUBHOURLY_POST_MNTS`` should be set to a valid value between 1 and 59. Valid values: ``True`` | ``False``

``DT_SUB_HOURLY_POST_MNTS``: (Default: 0)
   Time interval in minutes between the forecast model output files (only used if ``SUB_HOURLY_POST`` is set to true). If ``SUB_HOURLY_POST`` is set to true, this needs to be set to a valid two-digit integer between 1 and 59. Note that if ``SUB_HOURLY_POST`` is set to true but ``DT_SUB_HOURLY_POST_MNTS`` is set to 0, ``SUB_HOURLY_POST`` will get reset to false in the experiment generation scripts (there will be an informational message in the log file to emphasize this). Valid values: ``0`` | ``1`` | ``2`` | ``3`` | ``4`` | ``5`` | ``6`` | ``10`` | ``12`` | ``15`` | ``20`` | ``30``

Customized Post Configuration Parameters
--------------------------------------------

Set parameters for customizing the :term:`UPP`.

``USE_CUSTOM_POST_CONFIG_FILE``: (Default: false)
   Flag that determines whether a user-provided custom configuration file should be used for post-processing the model data. If this is set to true, then the workflow will use the custom post-processing (:term:`UPP`) configuration file specified in ``CUSTOM_POST_CONFIG_FP``. Otherwise, a default configuration file provided in the UPP repository will be used. Valid values: ``True`` | ``False``

``CUSTOM_POST_CONFIG_FP``: (Default: "")
   The full path to the custom post flat file, including filename, to be used for post-processing. This is only used if ``CUSTOM_POST_CONFIG_FILE`` is set to true.

``POST_OUTPUT_DOMAIN_NAME``: (Default: "")
   Domain name (in lowercase) used to construct the names of the output files generated by the :term:`UPP`. If using a predefined grid, ``POST_OUTPUT_DOMAIN_NAME`` defaults to ``PREDEF_GRID_NAME``. If using a custom grid, ``POST_OUTPUT_DOMAIN_NAME`` must be specified by the user. The post output files are named as follows:

   .. code-block:: console 
      
      $NET.tHHz.[var_name].f###.${POST_OUTPUT_DOMAIN_NAME}.grib2
   
   Note that this variable is first changed to lower case before being used to construct the file names.

RUN_PRDGEN Configuration Parameters
=====================================

Non-default parameters for the ``run_prdgen`` task are set in the ``task_run_prdgen:`` section of the ``config.yaml`` file.

Basic Task Parameters
---------------------------------
For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task.

``TN_RUN_PRDGEN``: (Default: "run_prdgen")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_RUN_PRDGEN``: (Default: 1) 
   Number of nodes to use for the job.

``PPN_RUN_PRDGEN``: (Default: 22)
   Number of :term:`MPI` processes per node.

``WTIME_RUN_PRDGEN``: (Default: 00:30:00)
   Maximum time for the task to complete.

``MAXTRIES_RUN_PRDGEN``: (Default: 2)
   Maximum number of times to attempt the task.

``KMP_AFFINITY_RUN_PRDGEN``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``run_prdgen`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_RUN_PRDGEN``: (Default: 1) 
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_RUN_PRDGEN``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

``DO_PARALLEL_PRDGEN``: (Default: false)
   Flag that determines whether to use CFP to run the product generation job in parallel.  CFP is a utility that allows the user to launch a number of small jobs across nodes/cpus in one batch command.  This option should be used with the ``RRFS_NA_3km`` grid and ``PPN_RUN_PRDGEN`` should be set to 22.

``ADDNL_OUTPUT_GRIDS``: (Default: [])
   Set additional output grids for wgrib2 remapping, if any.  Space-separated list of strings, e.g., ( "130" "242" "clue").  Default is no additional grids.

``TESTBED_FIELDS_FN``: (Default: "")
   The file which lists grib2 fields to be extracted for testbed files.  Empty string means no need to generate testbed files.


.. _get-obs-ccpa:

GET_OBS_CCPA Configuration Parameters
========================================

Non-default parameters for the ``get_obs_ccpa`` task are set in the ``task_get_obs_ccpa:`` section of the ``config.yaml`` file. 

``TN_GET_OBS_CCPA``: (Default: "get_obs_ccpa")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value. See :numref:`Section %s <VXTasks>` for more information about the verification tasks. 

``NNODES_GET_OBS_CCPA``: (Default: 1)
   Number of nodes to use for the job.

``PPN_GET_OBS_CCPA``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_GET_OBS_CCPA``: (Default: 00:45:00)
   Maximum time for the task to complete.

``MAXTRIES_GET_OBS_CCPA``: (Default: 1)
   Maximum number of times to attempt the task.

.. _get-obs-mrms:

GET_OBS_MRMS Configuration Parameters
========================================

Non-default parameters for the ``get_obs_mrms`` task are set in the ``task_get_obs_mrms:`` section of the ``config.yaml`` file. See :numref:`Section %s <VXTasks>` for more information about the verification tasks. 

``TN_GET_OBS_MRMS``: (Default: "get_obs_mrms")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_GET_OBS_MRMS``: (Default: 1)
   Number of nodes to use for the job.

``PPN_GET_OBS_MRMS``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_GET_OBS_MRMS``: (Default: 00:45:00)
   Maximum time for the task to complete.

``MAXTRIES_GET_OBS_MRMS``: (Default: 1)
   Maximum number of times to attempt the task.

.. _get-obs-ndas:

GET_OBS_NDAS Configuration Parameters
========================================

Non-default parameters for the ``get_obs_ndas`` task are set in the ``task_get_obs_ndas:`` section of the ``config.yaml`` file. See :numref:`Section %s <VXTasks>` for more information about the verification tasks. 

``TN_GET_OBS_NDAS``: (Default: "get_obs_ndas")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_GET_OBS_NDAS``: (Default: 1)
   Number of nodes to use for the job.

``PPN_GET_OBS_NDAS``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_GET_OBS_NDAS``: (Default: 02:00:00)
   Maximum time for the task to complete.

``MAXTRIES_GET_OBS_NDAS``: (Default: 1)
   Maximum number of times to attempt the task.


.. _VX-gridstat:

VX_GRIDSTAT Configuration Parameters
========================================

Non-default parameters for the ``run_gridstatvx`` task are set in the ``task_run_vx_gridstat:`` section of the ``config.yaml`` file. 

``TN_VX_GRIDSTAT``: (Default: "run_gridstatvx")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_GRIDSTAT``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_GRIDSTAT``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_GRIDSTAT``: (Default: 02:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_GRIDSTAT``: (Default: 1)
   Maximum number of times to attempt the task.


VX_GRIDSTAT_REFC Configuration Parameters
=============================================

Non-default parameters for the ``run_gridstatvx_refc`` task are set in the ``task_run_vx_gridstat_refc:`` section of the ``config.yaml`` file. 

``TN_VX_GRIDSTAT_REFC``: (Default: "run_gridstatvx_refc")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_GRIDSTAT``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_GRIDSTAT``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_GRIDSTAT``: (Default: 02:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_GRIDSTAT_REFC``: (Default: 1)
   Maximum number of times to attempt the task.


VX_GRIDSTAT_RETOP Configuration Parameters
=============================================

Non-default parameters for the ``run_gridstatvx_retop`` task are set in the ``task_run_vx_gridstat_retop:`` section of the ``config.yaml`` file. 

``TN_VX_GRIDSTAT_RETOP``: (Default: "run_gridstatvx_retop")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_GRIDSTAT``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_GRIDSTAT``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_GRIDSTAT``: (Default: 02:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_GRIDSTAT_RETOP``: (Default: 1)
   Maximum number of times to attempt the task.


VX_GRIDSTAT_03h Configuration Parameters
=============================================

Non-default parameters for the ``run_gridstatvx_03h`` task are set in the ``task_run_vx_gridstat_03h:`` section of the ``config.yaml`` file. 

``TN_VX_GRIDSTAT_03h``: (Default: "run_gridstatvx_03h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_GRIDSTAT``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_GRIDSTAT``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_GRIDSTAT``: (Default: 02:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_GRIDSTAT_03h``: (Default: 1)
   Maximum number of times to attempt the task.


VX_GRIDSTAT_06h Configuration Parameters
=============================================

Non-default parameters for the ``run_gridstatvx_06h`` task are set in the ``task_run_vx_gridstat_06h:`` section of the ``config.yaml`` file. 

``TN_VX_GRIDSTAT_06h``: (Default: "run_gridstatvx_06h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_GRIDSTAT``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_GRIDSTAT``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_GRIDSTAT``: (Default: 02:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_GRIDSTAT_06h``: (Default: 1)
   Maximum number of times to attempt the task.


VX_GRIDSTAT_24h Configuration Parameters
=============================================

Non-default parameters for the ``run_gridstatvx_24h`` task are set in the ``task_run_vx_gridstat_24h:`` section of the ``config.yaml`` file. 

``TN_VX_GRIDSTAT_24h``: (Default: "run_gridstatvx_24h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_GRIDSTAT``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_GRIDSTAT``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_GRIDSTAT``: (Default: 02:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_GRIDSTAT_24h``: (Default: 1)
   Maximum number of times to attempt the task.

.. _VX-pointstat:

VX_POINTSTAT Configuration Parameters
=============================================

Non-default parameters for the ``run_pointstatvx`` task are set in the ``task_run_vx_pointstat:`` section of the ``config.yaml`` file. 

``TN_VX_POINTSTAT``: (Default: "run_pointstatvx")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_POINTSTAT``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_POINTSTAT``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_POINTSTAT``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_POINTSTAT``: (Default: 1)
   Maximum number of times to attempt the task.

.. _VX-ensgrid:

VX_ENSGRID Configuration Parameters
=============================================

Non-default parameters for the ``run_ensgridvx_*`` tasks are set in the ``task_run_vx_ensgrid:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_03h``: (Default: "run_ensgridvx_03h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``MAXTRIES_VX_ENSGRID_03h``: (Default: 1)
   Maximum number of times to attempt the task.

``TN_VX_ENSGRID_06h``: (Default: "run_ensgridvx_06h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``MAXTRIES_VX_ENSGRID_06h``: (Default: 1)
   Maximum number of times to attempt the task.

``TN_VX_ENSGRID_24h``: (Default: "run_ensgridvx_24h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``MAXTRIES_VX_ENSGRID_24h``: (Default: 1)
   Maximum number of times to attempt the task.

``TN_VX_ENSGRID_RETOP``: (Default: "run_ensgridvx_retop")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``MAXTRIES_VX_ENSGRID_RETOP``: (Default: 1)
   Maximum number of times to attempt the task.

``TN_VX_ENSGRID_PROB_RETOP``: (Default: "run_ensgridvx_prob_retop")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``MAXTRIES_VX_ENSGRID_PROB_RETOP``: (Default: 1)
   Maximum number of times to attempt the task.

``NNODES_VX_ENSGRID``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_REFC Configuration Parameters
=============================================

Non-default parameters for the ``run_ensgridvx_refc`` task are set in the ``task_run_vx_ensgrid_refc:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_REFC``: (Default: "run_ensgridvx_refc")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_REFC``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_MEAN Configuration Parameters
=============================================

Non-default parameters for the ``run_ensgridvx_mean`` task are set in the ``task_run_vx_ensgrid_mean:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_MEAN``: (Default: "run_ensgridvx_mean")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID_MEAN``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID_MEAN``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID_MEAN``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_MEAN``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_MEAN_03h Configuration Parameters
===============================================

Non-default parameters for the ``run_ensgridvx_mean_03h`` task are set in the ``task_run_vx_ensgrid_mean_03h:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_MEAN_03h``: (Default: "run_ensgridvx_mean_03h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID_MEAN``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID_MEAN``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID_MEAN``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_MEAN_03h``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_MEAN_06h Configuration Parameters
===============================================

Non-default parameters for the ``run_ensgridvx_mean_06h`` task are set in the ``task_run_vx_ensgrid_mean_06h:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_MEAN_06h``: (Default: "run_ensgridvx_mean_06h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID_MEAN``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID_MEAN``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID_MEAN``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_MEAN_06h``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_MEAN_24h Configuration Parameters
===============================================

Non-default parameters for the ``run_ensgridvx_mean_24h`` task are set in the ``task_run_vx_ensgrid_mean_24h:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_MEAN_24h``: (Default: "run_ensgridvx_mean_24h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID_MEAN``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID_MEAN``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID_MEAN``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_MEAN_24h``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_PROB Configuration Parameters
============================================

Non-default parameters for the ``run_ensgridvx_prob`` task are set in the ``task_run_vx_ensgrid_prob:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_PROB``: (Default: "run_ensgridvx_prob")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID_PROB``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID_PROB``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID_PROB``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_PROB``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_PROB_03h Configuration Parameters
================================================

Non-default parameters for the ``run_ensgridvx_prob_03h`` task are set in the ``task_run_vx_ensgrid_prob_03h:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_PROB_03h``: (Default: "run_ensgridvx_prob_03h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID_PROB``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID_PROB``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID_PROB``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_PROB_03h``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_PROB_06h Configuration Parameters
================================================

Non-default parameters for the ``run_ensgridvx_prob_06h`` task are set in the ``task_run_vx_ensgrid_prob_06h:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_PROB_06h``: (Default: "run_ensgridvx_prob_06h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID_PROB``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID_PROB``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID_PROB``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_PROB_06h``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSGRID_PROB_24h Configuration Parameters
================================================

Non-default parameters for the ``run_ensgridvx_prob_24h`` task are set in the ``task_run_vx_ensgrid_prob_24h:`` section of the ``config.yaml`` file. 

``TN_VX_ENSGRID_PROB_24h``: (Default: "run_ensgridvx_prob_24h")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSGRID_PROB``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSGRID_PROB``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSGRID_PROB``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSGRID_PROB_24h``: (Default: 1)
   Maximum number of times to attempt the task.

.. _VX-enspoint:

VX_ENSPOINT Configuration Parameters
========================================

Non-default parameters for the ``run_enspointvx`` task are set in the ``task_run_vx_enspoint:`` section of the ``config.yaml`` file. 

``TN_VX_ENSPOINT``: (Default: "run_enspointvx")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSPOINT``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSPOINT``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSPOINT``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSPOINT``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSPOINT_MEAN Configuration Parameters
==============================================

Non-default parameters for the ``run_enspointvx_mean`` task are set in the ``task_run_vx_enspoint_mean:`` section of the ``config.yaml`` file. 

``TN_VX_ENSPOINT_MEAN``: (Default: "run_enspointvx_mean")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSPOINT_MEAN``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSPOINT_MEAN``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSPOINT_MEAN``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSPOINT_MEAN``: (Default: 1)
   Maximum number of times to attempt the task.


VX_ENSPOINT_PROB Configuration Parameters
==============================================

Non-default parameters for the ``run_enspointvx_prob`` task are set in the ``task_run_vx_enspoint_prob:`` section of the ``config.yaml`` file. 

``TN_VX_ENSPOINT_PROB``: (Default: "run_enspointvx_prob")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_VX_ENSPOINT_PROB``: (Default: 1)
   Number of nodes to use for the job.

``PPN_VX_ENSPOINT_PROB``: (Default: 1)
   Number of :term:`MPI` processes per node.

``WTIME_VX_ENSPOINT_PROB``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_VX_ENSPOINT_PROB``: (Default: 1)
   Maximum number of times to attempt the task.

.. _PlotVars:

PLOT_ALLVARS Configuration Parameters
========================================

Non-default parameters for the ``plot_allvars`` task are set in the ``task_plot_allvars:`` section of the ``config.yaml`` file. 

Basic Task Parameters
--------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. Typically, users do not need to adjust the default values. 

``TN_PLOT_ALLVARS``: (Default: "plot_allvars")
   Set the name of this Rocoto workflow task. Users typically do not need to change this value.

``NNODES_PLOT_ALLVARS``: (Default: 1)
   Number of nodes to use for the job.

``PPN_PLOT_ALLVARS``: (Default: 24)
   Number of :term:`MPI` processes per node.

``WTIME_PLOT_ALLVARS``: (Default: 01:00:00)
   Maximum time for the task to complete.

``MAXTRIES_PLOT_ALLVARS``: (Default: 1)
   Maximum number of times to attempt the task.

Additional Parameters
------------------------

Typically, the following parameters must be set explicitly by the user in the configuration file (``config.yaml``) when executing the plotting tasks. 

``COMOUT_REF``: (Default: "")
   The directory where the GRIB2 files from post-processing are located. In *community* mode (i.e., when ``RUN_ENVIR: "community"``), this directory will correspond to the location in the experiment directory where the post-processed output can be found (e.g., ``$EXPTDIR/$DATE_FIRST_CYCL/postprd``). In *nco* mode, this directory should be set to the location of the ``COMOUT`` directory and end with ``$PDY/$cyc``. For more detail on *nco* standards and directory naming conventions, see `WCOSS Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/ImplementationStandards.v11.0.0.pdf?>`__ (particularly pp. 4-5). 
  
``PLOT_FCST_START``: (Default: 0)
   The starting forecast hour for the plotting task. For example, if a forecast starts at 18h/18z, this is considered the 0th forecast hour, so "starting forecast hour" should be 0, not 18. If a forecast starts at 18h/18z, but the user only wants plots from the 6th forecast hour on, "starting forecast hour" should be 6.

``PLOT_FCST_INC``: (Default: 3)
   Forecast hour increment for the plotting task. For example, if the user wants plots for each forecast hour, they should set ``PLOT_FCST_INC: 1``. If the user only wants plots for some of the output (e.g., every 6 hours), they should set ``PLOT_FCST_INC: 6``. 
  
``PLOT_FCST_END``: (Default: "")
   The last forecast hour for the plotting task. For example, if a forecast run for 24 hours, and the user wants plots for each available hour of forecast output, they should set ``PLOT_FCST_END: 24``. If the user only wants plots from the first 12 hours of the forecast, the "last forecast hour" should be 12.

``PLOT_DOMAINS``: (Default: ["conus"])
   Domains to plot. Currently supported options are ["conus"], ["regional"], or both (i.e., ["conus", "regional"]).

Global Configuration Parameters
===================================

Non-default parameters for the miscellaneous tasks are set in the ``global:`` section of the ``config.yaml`` file. 

Community Radiative Transfer Model (CRTM) Parameters
--------------------------------------------------------

These variables set parameters associated with outputting satellite fields in the :term:`UPP` :term:`grib2` files using the Community Radiative Transfer Model (:term:`CRTM`). :numref:`Section %s <SatelliteProducts>` includes further instructions on how to do this. 

``USE_CRTM``: (Default: false)
   Flag that defines whether external :term:`CRTM` coefficient files have been staged by the user in order to output synthetic satellite products available within the :term:`UPP`. If this is set to true, then the workflow will check for these files in the directory ``CRTM_DIR``. Otherwise, it is assumed that no satellite fields are being requested in the UPP configuration. Valid values: ``True`` | ``False``

``CRTM_DIR``: (Default: "")
   This is the path to the top CRTM fix file directory. This is only used if ``USE_CRTM`` is set to true.


Ensemble Model Parameters
-----------------------------

Set parameters associated with running ensembles. 

``DO_ENSEMBLE``: (Default: false)
   Flag that determines whether to run a set of ensemble forecasts (for each set of specified cycles).  If this is set to true, ``NUM_ENS_MEMBERS`` forecasts are run for each cycle, each with a different set of stochastic seed values. When false, a single forecast is run for each cycle. Valid values: ``True`` | ``False``

``NUM_ENS_MEMBERS``: (Default: 1)
   The number of ensemble members to run if ``DO_ENSEMBLE`` is set to true. This variable also controls the naming of the ensemble member directories. For example, if ``NUM_ENS_MEMBERS`` is set to 8, the member directories will be named *mem1, mem2, ..., mem8*. This variable is not used unless ``DO_ENSEMBLE`` is set to true.

.. _stochastic-physics:

Stochastic Physics Parameters
----------------------------------

Set default ad-hoc stochastic physics options. For the most updated and detailed documentation of these parameters, see the `UFS Stochastic Physics Documentation <https://stochastic-physics.readthedocs.io/en/latest/namelist_options.html>`__.

``NEW_LSCALE``: (Default: true) 
   Use correct formula for converting a spatial legnth scale into spectral space. 

Specific Humidity (SHUM) Perturbation Parameters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``DO_SHUM``: (Default: false)
   Flag to turn Specific Humidity (SHUM) perturbations on or off. SHUM perturbations multiply the low-level specific humidity by a small random number at each time-step. The SHUM scheme attempts to address missing physics phenomena (e.g., cold pools, gust fronts) most active in convective regions. Valid values: ``True`` | ``False``

``ISEED_SHUM``: (Default: 2)
   Seed for setting the SHUM random number sequence.

``SHUM_MAG``: (Default: 0.006) 
   Amplitudes of random patterns. Corresponds to the variable ``shum`` in ``input.nml``.

``SHUM_LSCALE``: (Default: 150000)
   Decorrelation spatial scale in meters.

``SHUM_TSCALE``: (Default: 21600)
   Decorrelation timescale in seconds. Corresponds to the variable ``shum_tau`` in ``input.nml``.

``SHUM_INT``: (Default: 3600)
   Interval in seconds to update random pattern (optional). Perturbations still get applied at every time-step. Corresponds to the variable ``shumint`` in ``input.nml``.

.. _SPPT:

Stochastically Perturbed Physics Tendencies (SPPT) Parameters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

SPPT perturbs full physics tendencies *after* the call to the physics suite, unlike :ref:`SPP <SPP>` (below), which perturbs specific tuning parameters within a physics scheme. 

``DO_SPPT``: (Default: false)
   Flag to turn Stochastically Perturbed Physics Tendencies (SPPT) on or off. SPPT multiplies the physics tendencies by a random number between 0 and 2 before updating the model state. This addresses error in the physics parameterizations (either missing physics or unresolved subgrid processes). It is most active in the boundary layer and convective regions. Valid values: ``True`` | ``False``

``ISEED_SPPT``: (Default: 1) 
   Seed for setting the SPPT random number sequence.

``SPPT_MAG``: (Default: 0.7)
   Amplitude of random patterns. Corresponds to the variable ``sppt`` in ``input.nml``.

``SPPT_LOGIT``: (Default: true)
   Limits the SPPT perturbations to between 0 and 2. Should be "TRUE"; otherwise the model will crash.

``SPPT_LSCALE``: (Default: 150000)
   Decorrelation spatial scale in meters. 

``SPPT_TSCALE``: (Default: 21600) 
   Decorrelation timescale in seconds. Corresponds to the variable ``sppt_tau`` in ``input.nml``.
   
``SPPT_INT``: (Default: 3600) 
   Interval in seconds to update random pattern (optional parameter). Perturbations still get applied at every time-step. Corresponds to the variable ``spptint`` in ``input.nml``.

``SPPT_SFCLIMIT``: (Default: true)
   When true, tapers the SPPT perturbations to zero at the model's lowest level, which reduces model crashes. 

``USE_ZMTNBLCK``: (Default: false)
   When true, do not apply perturbations below the dividing streamline that is diagnosed by the gravity wave drag, mountain blocking scheme. Valid values: ``True`` | ``False``


Stochastic Kinetic Energy Backscatter (SKEB) Parameters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``DO_SKEB``: (Default: false)
   Flag to turn Stochastic Kinetic Energy Backscatter (SKEB) on or off. SKEB adds wind perturbations to the model state. Perturbations are random in space/time, but amplitude is determined by a smoothed dissipation estimate provided by the :term:`dynamical core`. SKEB addresses errors in the dynamics more active in the mid-latitudes. Valid values: ``True`` | ``False``

``ISEED_SKEB``: (Default: 3)
   Seed for setting the SHUM random number sequence.

``SKEB_MAG``: (Default: 0.5) 
   Amplitude of random patterns. Corresponds to the variable ``skeb`` in ``input.nml``.

``SKEB_LSCALE``: (Default: 150000)
   Decorrelation spatial scale in meters. 

``SKEB_TSCALE``: (Default: 21600)
   Decorrelation timescale in seconds. Corresponds to the variable ``skeb_tau`` in ``input.nml``.

``SKEB_INT``: (Default: 3600)
   Interval in seconds to update random pattern (optional). Perturbations still get applied every time-step. Corresponds to the variable ``skebint`` in ``input.nml``.

``SKEBNORM``: (Default: 1)
   Patterns:
      * 0-random pattern is stream function
      * 1-pattern is K.E. norm
      * 2-pattern is vorticity

``SKEB_VDOF``: (Default: 10)
   The number of degrees of freedom in the vertical direction for the SKEB random pattern. 


.. _SPP:

Parameters for Stochastically Perturbed Parameterizations (SPP)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

SPP perturbs specific tuning parameters within a physics :term:`parameterization <parameterizations>` (unlike :ref:`SPPT <SPPT>`, which multiplies overall physics tendencies by a random perturbation field *after* the call to the physics suite). Patterns evolve and are applied at each time step. Each SPP option is an array, applicable (in order) to the :term:`RAP`/:term:`HRRR`-based parameterization listed in ``SPP_VAR_LIST``. Enter each value of the array in ``config.yaml`` as shown below without commas or single quotes (e.g., ``SPP_VAR_LIST: [ "pbl" "sfc" "mp" "rad" "gwd" ]`` ). Both commas and single quotes will be added by Jinja when creating the namelist.

.. note::
   SPP is currently only available for specific physics schemes used in the RAP/HRRR physics suite. Users need to be aware of which :term:`SDF` is chosen when turning this option on. Of the four supported physics suites, the full set of parameterizations can only be used with the ``FV3_HRRR`` option for ``CCPP_PHYS_SUITE``.

``DO_SPP``: (Default: false)
   Flag to turn SPP on or off. SPP perturbs parameters or variables with unknown or uncertain magnitudes within the physics code based on ranges provided by physics experts. Valid values: ``True`` | ``False``

``ISEED_SPP``: (Default: [ 4, 5, 6, 7, 8 ] )
   Seed for setting the random number sequence for the perturbation pattern. 

``SPP_VAR_LIST``: (Default: [ "pbl", "sfc", "mp", "rad", "gwd" ] )
   The list of parameterizations to perturb: planetary boundary layer (PBL), surface physics (SFC), microphysics (MP), radiation (RAD), gravity wave drag (GWD). Valid values: ``"pbl"`` | ``"sfc"`` | ``"rad"`` | ``"gwd"`` | ``"mp"``

``SPP_MAG_LIST``: (Default: [ 0.2, 0.2, 0.75, 0.2, 0.2 ] ) 
   SPP perturbation magnitudes used in each parameterization. Corresponds to the variable ``spp_prt_list`` in ``input.nml``

``SPP_LSCALE``: (Default: [ 150000.0, 150000.0, 150000.0, 150000.0, 150000.0 ] )
   Decorrelation spatial scales in meters.
   
``SPP_TSCALE``: (Default: [ 21600.0, 21600.0, 21600.0, 21600.0, 21600.0 ] ) 
   Decorrelation timescales in seconds. Corresponds to the variable ``spp_tau`` in ``input.nml``.

``SPP_SIGTOP1``: (Default: [ 0.1, 0.1, 0.1, 0.1, 0.1 ] )
   Controls vertical tapering of perturbations at the tropopause and corresponds to the lower sigma level at which to taper perturbations to zero. 

``SPP_SIGTOP2``: (Default: [ 0.025, 0.025, 0.025, 0.025, 0.025 ] )
   Controls vertical tapering of perturbations at the tropopause and corresponds to the upper sigma level at which to taper perturbations to zero.

``SPP_STDDEV_CUTOFF``: (Default: [ 1.5, 1.5, 2.5, 1.5, 1.5 ] )
   Limit for possible perturbation values in standard deviations from the mean.


Land Surface Model (LSM) SPP
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Land surface perturbations can be applied to land model parameters and land model prognostic variables. The LSM scheme is intended to address errors in the land model and land-atmosphere interactions. LSM perturbations include soil moisture content (SMC) (volume fraction), vegetation fraction (VGF), albedo (ALB), salinity (SAL), emissivity (EMI), surface roughness (ZOL) (in cm), and soil temperature (STC). Perturbations to soil moisture content (SMC) are only applied at the first time step. Only five perturbations at a time can be applied currently, but all seven are shown below. In addition, only one unique *iseed* value is allowed at the moment, and it is used for each pattern.

The parameters below turn on SPP in Noah or RUC LSM (support for Noah MP is in progress). Please be aware of the :term:`SDF` that you choose if you wish to turn on Land Surface Model (LSM) SPP. SPP in LSM schemes is handled in the ``&nam_sfcperts`` namelist block instead of in ``&nam_sppperts``, where all other SPP is implemented. 

``DO_LSM_SPP``: (Default: false) 
   Turns on Land Surface Model (LSM) Stochastic Physics Parameterizations (SPP). When true, sets ``lndp_type=2``, which applies land perturbations to the selected paramaters using a newer scheme designed for data assimilation (DA) ensemble spread. LSM SPP perturbs uncertain land surface fields ("smc" "vgf" "alb" "sal" "emi" "zol" "stc") based on recommendations from physics experts. Valid values: ``True`` | ``False``

``LSM_SPP_TSCALE``: (Default: [ 21600, 21600, 21600, 21600, 21600, 21600, 21600 ] )
   Decorrelation timescales in seconds. 

``LSM_SPP_LSCALE``: (Default: [ 150000, 150000, 150000, 150000, 150000, 150000, 150000 ] )
   Decorrelation spatial scales in meters.

``ISEED_LSM_SPP``: (Default: [ 9 ] )
   Seed to initialize the random perturbation pattern.

``LSM_SPP_VAR_LIST``: (Default: [ "smc", "vgf", "alb", "sal", "emi", "zol", "stc" ] )
   Indicates which LSM variables to perturb. 

``LSM_SPP_MAG_LIST``: (Default: [ 0.017, 0.001, 0.001, 0.001, 0.001, 0.001, 0.2 ] )
   Sets the maximum random pattern amplitude for each of the LSM perturbations. 

.. _HaloBlend:

Halo Blend Parameter
------------------------
``HALO_BLEND``: (Default: 10)
   Number of cells to use for "blending" the external solution (obtained from the :term:`LBCs`) with the internal solution from the FV3LAM :term:`dycore`. Specifically, it refers to the number of rows into the computational domain that should be blended with the LBCs. Cells at which blending occurs are all within the boundary of the native grid; they don't involve the 4 cells outside the boundary where the LBCs are specified (which is a different :term:`halo`). Blending is necessary to smooth out waves generated due to mismatch between the external and internal solutions. To shut :term:`halo` blending off, set this to zero. 

