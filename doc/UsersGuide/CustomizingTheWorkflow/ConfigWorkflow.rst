.. _ConfigWorkflow:

================================================================================================
Workflow Parameters: Configuring the Workflow in ``config.yaml`` and ``config_defaults.yaml``		
================================================================================================
To create the experiment directory and workflow when running the SRW Application, the user must create an experiment configuration file (named ``config.yaml`` by default). This file contains experiment-specific information, such as forecast dates, grid and physics suite choices, data directories, and other relevant settings. To help the user, two sample configuration files have been included in the ``ush`` directory: ``config.community.yaml`` and ``config.nco.yaml``. The first is for running experiments in *community* mode (``RUN_ENVIR`` set to "community"), and the second is for running experiments in *nco* mode (``RUN_ENVIR`` set to "nco"). The content of these files can be copied into ``config.yaml`` and used as the starting point from which to generate a variety of experiment configurations for the SRW App. Note that for public releases, only *community* mode is supported. 

There is an extensive list of experiment parameters that a user can set when configuring the experiment. Not all of these parameters need to be set explicitly by the user in ``config.yaml``. If a user does not define a variable in the ``config.yaml`` script, its value in ``config_defaults.yaml`` will be used, or the value will be reset depending on other parameters, such as the platform (``MACHINE``) selected for the experiment. 

.. note::
   The ``config_defaults.yaml`` file contains the full list of experiment parameters that a user may set in ``config.yaml``. The user cannot set parameters in ``config.yaml`` that are not initialized in ``config_defaults.yaml``, with the notable exception of the ``rocoto`` section, described in :numref:`Chapter %s <DefineWorkflow>`.

The following is a list of the parameters in the ``config_defaults.yaml`` file. For each parameter, the default value and a brief description are provided. 

.. _user:

USER Configuration Parameters
=================================

If non-default parameters are selected for the variables in this section, they should be added to the ``user:`` section of the ``config.yaml`` file. 

``RUN_ENVIR``: (Default: "nco")
   This variable determines the workflow mode. The user can choose between two options: "nco" and "community". The "nco" mode uses a directory structure that mimics what is used in operations at NOAA/NCEP Central Operations (NCO) and at the NOAA/NCEP/Environmental Modeling Center (EMC), which works with NCO on pre-implementation testing. Specifics of the conventions used in "nco" mode can be found in the following :nco:`WCOSS Implementation Standards <>` document:

   | NCEP Central Operations
   | WCOSS Implementation Standards
   | January 19, 2022
   | Version 11.0.0
   
   Setting ``RUN_ENVIR`` to "community" is recommended in most cases for users who are not running in NCO's production environment. Valid values: ``"nco"`` | ``"community"``

``MACHINE``: (Default: "BIG_COMPUTER")
   The machine (a.k.a. platform or system) on which the workflow will run. Currently supported platforms are listed on the :srw-wiki:`SRW App Wiki page <Supported-Platforms-and-Compilers>`. When running the SRW App on any ParallelWorks/NOAA Cloud system, use "NOAACLOUD" regardless of the underlying system (AWS, GCP, or Azure). Valid values: ``"HERA"`` | ``"ORION"`` | ``"HERCULES"`` | ``"JET"`` | ``"CHEYENNE"`` | ``"DERECHO"`` | ``"GAEA"`` |  ``"NOAACLOUD"`` | ``"STAMPEDE"`` | ``"ODIN"`` | ``"MACOS"`` | ``"LINUX"`` | ``"SINGULARITY"`` | ``"WCOSS2"`` (Check ``ufs-srweather-app/ush/valid_param_vals.yaml`` for the most up-to-date list of supported platforms.)

   .. hint::
      Users who are NOT on a named, supported Level 1 or 2 platform will need to set the ``MACHINE`` variable to ``LINUX`` or ``MACOS``. To combine use of a Linux or MacOS platform with the Rocoto workflow manager, users will also need to set ``WORKFLOW_MANAGER: "rocoto"`` in the ``platform:`` section of ``config.yaml``. This combination will assume a Slurm batch manager when generating the XML. 

``ACCOUNT``: (Default: "")
   The account under which users submit jobs to the queue on the specified ``MACHINE``. To determine an appropriate ``ACCOUNT`` field for :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems, users may run the ``groups`` command, which will return a list of projects that the user has permissions for. Not all of the listed projects/groups have an HPC allocation, but those that do are potentially valid account names. On some systems, the ``saccount_params`` command will display additional account details. 

Application Directories
--------------------------

``HOMEdir``: (Default: ``'{{ user.HOMEdir }}'``)
   The path to the user's ``ufs-srweather-app`` clone. This path is set in ``ush/setup.py`` as the parent directory to ``USHdir``. 

``USHdir``: (Default: ``'{{ user.USHdir }}'``)
   The path to the user's ``ush`` directory in their ``ufs-srweather-app`` clone. This path is set automatically in the main function of ``setup.py`` and corresponds to the location of ``setup.py`` (i.e., the ``ush`` directory).

``SCRIPTSdir``: (Default: ``'{{ [HOMEdir, "scripts"]|path_join }}'``)
   The path to the user's ``scripts`` directory in their ``ufs-srweather-app`` clone.

``JOBSdir``: (Default: ``'{{ [HOMEdir, "jobs"]|path_join }}'``)
   The path to the user's ``jobs`` directory in their ``ufs-srweather-app`` clone.

``SORCdir``: (Default: ``'{{ [HOMEdir, "sorc"]|path_join }}'``)
   The path to the user's ``sorc`` directory in their ``ufs-srweather-app`` clone.

``PARMdir``: (Default: ``'{{ [HOMEdir, "parm"]|path_join }}'``)
   The path to the user's ``parm`` directory in their ``ufs-srweather-app`` clone.

``MODULESdir``: (Default: ``'{{ [HOMEdir, "modulefiles"]|path_join }}'``)
   The path to the user's ``modulefiles`` directory in their ``ufs-srweather-app`` clone.

``EXECdir``: (Default: ``'{{ [HOMEdir, workflow.EXEC_SUBDIR]|path_join }}'``)
   The path to the user's ``exec`` directory in their ``ufs-srweather-app`` clone.

``METPLUS_CONF``: (Default: ``'{{ [PARMdir, "metplus"]|path_join }}'``)
   The path to the directory where the user's final METplus configuration file resides. By default, METplus configuration files reside in ``ufs-srweather-app/parm/metplus``. 

``UFS_WTHR_MDL_DIR``: (Default: ``'{{ userUFS_WTHR_MDL_DIR }}'``)
   The path to the location where the UFS Weather Model code is located within the ``ufs-srweather-app`` clone. This parameter is set in ``setup.py`` and uses information from the ``Externals.cfg`` file to build the correct path. It is built with knowledge of ``HOMEdir`` and often corresponds to ``ufs-srweather-app/sorc/ufs-weather-model``.

``ARL_NEXUS_DIR``: (Default: ``'{{ [SORCdir, "arl_nexus"]|path_join }}'``)
   The path to the user's NEXUS directory. By default, NEXUS source code resides in ``ufs-srweather-app/sorc/arl_nexus``.

.. _PlatformConfig:

PLATFORM Configuration Parameters
=====================================

If non-default parameters are selected for the variables in this section, they should be added to the ``platform:`` section of the ``config.yaml`` file. 

``WORKFLOW_MANAGER``: (Default: "none")
   The workflow manager to use (e.g., "rocoto"). This is set to "none" by default, but if the machine name is set to a platform that supports Rocoto, this will be overwritten and set to "rocoto." If set explicitly to "rocoto" along with the use of the ``MACHINE: "LINUX"`` target, the configuration layer assumes a Slurm batch manager when generating the XML. Valid values: ``"rocoto"`` | ``"none"``

   .. note:: 

      The ability to generate an ``ecflow`` workflow is not yet available in the SRW App. Although ``ecflow`` has been added to ``ush/valid_param_vals.yaml`` as a valid option, setting this option will fail to produce a functioning workflow. 
      Without the necessary ``ecf`` directory, it is impossible to generate ``ecflow`` workflows at this time. The addition of this functionality is planned but not yet completed. 

``NCORES_PER_NODE``: (Default: "")
   The number of cores available per node on the compute platform. Set for supported platforms in ``setup.py``, but it is now also configurable for all platforms.

``TASKTHROTTLE``: (Default: 1000)
  The number of active tasks that can be run simultaneously. For Linux/MacOS systems, it makes sense to set this to 1 because these systems often have a small number of available cores/CPUs and therefore less capacity to run multiple tasks simultaneously. 

``BUILD_MOD_FN``: (Default: ``'build_{{ user.MACHINE|lower() }}_{{ workflow.COMPILER }}'``)
   Name of an alternative build modulefile to use if running on an unsupported platform. It is set automatically for supported machines.

``WFLOW_MOD_FN``: (Default: ``'wflow_{{ user.MACHINE|lower() }}'``)
   Name of an alternative workflow modulefile to use if running on an unsupported platform. It is set automatically for supported machines.

``BUILD_VER_FN``: (Default: ``'build.ver.{{ user.MACHINE|lower() }}'``)
   File name containing the version of the modules used for building the App. Currently, only WCOSS2 uses this file.

``RUN_VER_FN``: (Default: ``'run.ver.{{ user.MACHINE|lower() }}'``)
   File name containing the version of the modules used for running the App. Currently, only WCOSS2 uses this file.

.. _sched:

``SCHED``: (Default: "")
   The job scheduler to use (e.g., Slurm) on the specified ``MACHINE``. Leaving this an empty string allows the experiment generation script to set it automatically depending on the machine the workflow is running on. Valid values: ``"slurm"`` | ``"pbspro"`` | ``"lsf"`` | ``"lsfcray"`` | ``"none"``

Machine-Dependent Parameters
-------------------------------
These parameters vary depending on machine. On :srw-wiki:`Level 1 and 2 <Supported-Platforms-and-Compilers>` systems, the appropriate values for each machine can be viewed in the ``ush/machine/<platform>.sh`` scripts. To specify a value other than the default, add these variables and the desired value in the ``config.yaml`` file so that they override the ``config_defaults.yaml`` and machine default values. 

``PARTITION_DEFAULT``: (Default: "")
   This variable is only used with the Slurm job scheduler (i.e., when ``SCHED: "slurm"``). This is the default partition to which Slurm submits workflow tasks. If the task's ``PARTITION_HPSS`` or ``PARTITION_FCST`` (see below) parameters are **not** specified, the task will be submitted to the default partition indicated in the ``PARTITION_DEFAULT`` variable. If this value is not set or is set to an empty string, it will be (re)set to a machine-dependent value. Options are machine-dependent and include: ``""`` | ``"hera"`` | ``"normal"`` | ``"orion"`` | ``"sjet"`` | ``"vjet"`` | ``"kjet"`` | ``"xjet"`` | ``"workq"``

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

``REMOVE_MEMORY``: (Default: False)
  Boolean flag that determines whether to remove the memory flag for the Rocoto XML. Some platforms are not configured to accept the memory flag, so it must not be included in the XML. Valid values: ``True`` | ``False``

Parameters for Running Without a Workflow Manager
-----------------------------------------------------
These settings define platform-specific run commands. Users should set run commands for platforms without a workflow manager. These values will be ignored unless ``WORKFLOW_MANAGER: "none"``.

``RUN_CMD_UTILS``: (Default: "")
   The run command for MPI-enabled pre-processing utilities (e.g., ``shave``, ``orog``, ``sfc_climo_gen``). This can be left blank for smaller domains, in which case the executables will run without :term:`MPI`. Users may need to use an ``mpirun`` or similar command for launching an MPI-enabled executable depending on their machine and MPI installation.

``RUN_CMD_FCST``: (Default: "")
   The run command for the model forecast step. 

``RUN_CMD_POST``: (Default: "")
   The run command for post-processing (via the :term:`UPP`). Can be left blank for smaller domains, in which case UPP will run without :term:`MPI`.

``RUN_CMD_PRDGEN``: (Default: "")
  The run command for the product generation job.

``RUN_CMD_SERIAL``: (Default: "")
  The run command for some serial jobs.

``RUN_CMD_AQM``: (Default: "")
  The run command for some AQM tasks.

``RUN_CMD_AQMLBC``: (Default: "")
  The run command for the ``aqm_lbcs`` task.

``SCHED_NATIVE_CMD``: (Default: "")
   Allows an extra parameter to be passed to the job scheduler (Slurm or PBSPRO) via XML Native command. 

``PRE_TASK_CMDS``: (Default: "")
   Pre-task commands such as ``ulimit`` needed by tasks. For example: ``'{ ulimit -s unlimited; ulimit -a; }'``

METplus Parameters
----------------------

:ref:`METplus <MetplusComponent>` is a scientific verification framework that spans a wide range of temporal and spatial scales. Many of the METplus parameters are described below, but additional documentation for the METplus components is available on the `METplus website <https://dtcenter.org/community-code/metplus>`__. 

.. _METParamNote:

.. note::
   Where a date field is required: 
      * ``YYYY`` refers to the 4-digit valid year
      * ``MM`` refers to the 2-digit valid month
      * ``DD`` refers to the 2-digit valid day of the month
      * ``HH`` refers to the 2-digit valid hour of the day
      * ``mm`` refers to the 2-digit valid minutes of the hour
      * ``SS`` refers to the two-digit valid seconds of the hour

``CCPA_OBS_DIR``: (Default: ``"{{ workflow.EXPTDIR }}/obs_data/ccpa/proc"``)
   User-specified location of the directory where :term:`CCPA` hourly precipitation files used by METplus are located (or, if retrieved by the workflow, where they will be placed). See comments in file ``scripts/exregional_get_verif_obs.sh`` for more details about files and directory structure, as well as important caveats about errors in the metadata and file names. 
   
   .. attention:: 
      Do not set this to the same path as other ``*_OBS_DIR`` variables; otherwise unexpected results and data loss may occur.

``NOHRSC_OBS_DIR``: (Default: ``"{{ workflow.EXPTDIR }}/obs_data/nohrsc/proc"``)
   User-specified location of top-level directory where NOHRSC 6- and 24-hour snowfall accumulation files used by METplus are located (or, if retrieved by the workflow, where they will be placed). See comments in file scripts/exregional_get_verif_obs.sh for more details about files and directory structure 
   
   .. attention:: 
      Do not set this to the same path as other ``*_OBS_DIR`` variables; otherwise unexpected results and data loss may occur. 

   .. note::
      Due to limited availability of NOHRSC observation data on NOAA :term:`HPSS` and the likelihood that snowfall accumulation verification will not be desired outside of winter cases, this verification option is currently not present in the workflow by default. In order to use it, the verification environment variable ``VX_FIELDS`` should be updated to include ``ASNOW``. This will allow the related workflow tasks to be run.

``MRMS_OBS_DIR``: (Default: ``"{{ workflow.EXPTDIR }}/obs_data/mrms/proc"``)
   User-specified location of the directory where :term:`MRMS` composite reflectivity and echo top files used by METplus are located (or, if retrieved by the workflow, where they will be placed). See comments in the ``scripts/exregional_get_verif_obs.sh`` for more details about files and directory structure. 
   
   .. attention:: 
      Do not set this to the same path as other ``*_OBS_DIR`` variables; otherwise unexpected results and data loss may occur.

``NDAS_OBS_DIR``: (Default: ``"{{ workflow.EXPTDIR }}/obs_data/ndas/proc"``)
   User-specified location of top-level directory where :term:`NDAS` prepbufr files used by METplus are located (or, if retrieved by the workflow, where they will be placed). See comments in file ``scripts/exregional_get_verif_obs.sh`` for more details about files and directory structure. 
   
   .. attention:: 
      Do not set this to the same path as other ``*_OBS_DIR`` variables; otherwise unexpected results and data loss may occur.

Other Platform-Specific Directories
--------------------------------------

``DOMAIN_PREGEN_BASEDIR``: (Default: "")
   For use in NCO mode only (``RUN_ENVIR: "nco"``). The base directory containing pregenerated grid, orography, and surface climatology files. This is an alternative for setting ``GRID_DIR``, ``OROG_DIR``, and ``SFC_CLIMO_DIR`` individually. For the pregenerated grid specified by ``PREDEF_GRID_NAME``, these "fixed" files are located in: 

   .. code-block:: console 

      ${DOMAIN_PREGEN_BASEDIR}/${PREDEF_GRID_NAME}

   The workflow scripts will create a symlink in the experiment directory that will point to a subdirectory (having the same name as the experiment grid) under this directory.

Test Directories
----------------------

These directories are used only by the ``run_WE2E_tests.py`` script, so they are not used unless the user runs a Workflow End-to-End (WE2E) test (see :numref:`Section %s <WE2E_tests>`). Their function corresponds to the same variables without the ``TEST_`` prefix. Users typically should not modify these variables. For any alterations, the logic in the ``run_WE2E_tests.py`` script would need to be adjusted accordingly.

``TEST_EXTRN_MDL_SOURCE_BASEDIR``: (Default: "")
   This parameter allows testing of user-staged files in a known location on a given platform. This path contains a limited dataset and likely will not be useful for most user experiments. 

``TEST_AQM_INPUT_BASEDIR``: (Default: "")
   The path to user-staged AQM fire emission data for WE2E testing. 

``TEST_PREGEN_BASEDIR``: (Default: "")
   Similar to ``DOMAIN_PREGEN_BASEDIR``, this variable sets the base directory containing pregenerated grid, orography, and surface climatology files for WE2E tests. This is an alternative for setting ``GRID_DIR``, ``OROG_DIR``, and ``SFC_CLIMO_DIR`` individually. 

``TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS``, ``TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS``: (Default: "")
   These parameters are used by the testing script to test the mechanism that allows users to point to a data stream on disk. They set up a sandbox location that mimics the stream in a more controlled way and test the ability to access :term:`ICS` or :term:`LBCS`, respectively. 

``TEST_CCPA_OBS_DIR``, ``TEST_MRMS_OBS_DIR``, ``TEST_NDAS_OBS_DIR``: (Default: "")
These parameters are used by the testing script to test the mechanism that allows user to point to data streams on disk for observation data for verification tasks. They test the ability for users to set ``CCPA_OBS_DIR``, ``MRMS_OBS_DIR``, and ``NDAS_OBS_DIR`` respectively.

``TEST_VX_FCST_INPUT_BASEDIR``: (Default: "") 
   The path to user-staged forecast files for WE2E testing of verificaton using user-staged forecast files in a known location on a given platform. 

.. _SystemFixedFiles:

Fixed File Directory Parameters
----------------------------------

These parameters are associated with the fixed (i.e., static) files. On :srw-wiki:`Level 1 & 2 <Supported-Platforms-and-Compilers>` systems, fixed files are pre-staged with paths defined in the ``setup.py`` script. Because the default values are platform-dependent, they are set to a null string in ``config_defaults.yaml``. Then these null values are overwritten in ``setup.py`` with machine-specific values or with a user-specified value from ``config.yaml``.

``FIXgsm``: (Default: "")
   Path to the system directory containing the majority of fixed (i.e., time-independent) files that are needed to run the FV3-LAM model.

``FIXaer``: (Default: "")
   Path to the system directory containing :term:`MERRA2` aerosol climatology files. Only used if running with a physics suite that uses Thompson microphysics.

``FIXlut``: (Default: "")
   Path to the system directory containing the lookup tables for optics properties. Only used if running with a physics suite that uses Thompson microphysics.

``FIXorg``: (Default: "")
   Path to the system directory containing static orography data (used by the ``make_orog`` task). Can be the same as ``FIXgsm``.

``FIXsfc``: (Default: "")
   Path to the system directory containing the static surface climatology input fields, used by ``sfc_climo_gen``. These files are only used if the ``MAKE_SFC_CLIMO`` task is meant to run.

``FIXshp``: (Default: "")
   System directory containing the graphics shapefiles. On Level 1 systems, these are set within the machine files. Users on other systems will need to provide the path to the directory that contains the *Natural Earth* shapefiles.

``FIXcrtm``: (Default: "")
   Path to system directory containing CRTM fixed files. 

``FIXcrtmupp``: (Default: "")
  Path to system directory containing CRTM fixed files specifically for UPP.

``EXTRN_MDL_DATA_STORES``: (Default: "")
   A list of data stores where the scripts should look for external model data. The list is in priority order. If disk information is provided via ``USE_USER_STAGED_EXTRN_FILES`` or a known location on the platform, the disk location will be highest priority. Valid values (in priority order): ``disk`` | ``hpss`` | ``aws`` | ``nomads``. 

.. _workflow:

WORKFLOW Configuration Parameters
=====================================

If non-default parameters are selected for the variables in this section, they should be added to the ``workflow:`` section of the ``config.yaml`` file. 

``WORKFLOW_ID``: (Default: ``!nowtimestamp ''``)
   Unique ID for the workflow run that will be set in ``setup.py``.

``RELATIVE_LINK_FLAG``: (Default: "--relative")
   How to make links. The default is relative links; users may set an empty string for absolute paths in links.

.. _Cron:

Cron-Associated Parameters
------------------------------

Cron is a job scheduler accessed through the command-line on UNIX-like operating systems. It is useful for automating tasks such as the ``rocotorun`` command, which launches each workflow task in the SRW App. Cron periodically checks a cron table (aka crontab) to see if any tasks are ready to execute. If so, it runs them. 

``USE_CRON_TO_RELAUNCH``: (Default: false)
   Flag that determines whether to add a line to the user's cron table, which calls the experiment launch script every ``CRON_RELAUNCH_INTVL_MNTS`` minutes. Valid values: ``True`` | ``False``

``CRON_RELAUNCH_INTVL_MNTS``: (Default: 3)
   The interval (in minutes) between successive calls of the experiment launch script by a cron job to (re)launch the experiment (so that the workflow for the experiment kicks off where it left off). This is used only if ``USE_CRON_TO_RELAUNCH`` is set to true.

``CRONTAB_LINE``: (Default: "")
   The launch command that will appear in the crontab (e.g., ``*/3 * * * * cd <path/to/experiment/subdirectory> && ./launch_FV3LAM_wflow.sh called_from_cron="TRUE"``).

``LOAD_MODULES_RUN_TASK_FP``: (Default: ``'{{ [user.USHdir, "load_modules_run_task.sh"]|path_join }}'``)
   Path to the ``load_modules_run_task.sh`` file. 

.. _DirParams:

Directory Parameters
-----------------------

``EXPT_BASEDIR``: (Default: "")
   The full path to the base directory in which the experiment directory (``EXPT_SUBDIR``) will be created. If this is not specified or if it is set to an empty string, it will default to ``${HOMEdir}/../expt_dirs``, where ``${HOMEdir}`` contains the full path to the ``ufs-srweather-app`` directory. If set to a relative path, the provided path will be appended to the default value ``${HOMEdir}/../expt_dirs``. For example, if ``EXPT_BASEDIR=some/relative/path`` (i.e. a path that does not begin with ``/``), the value of ``EXPT_BASEDIR`` used by the workflow will be ``EXPT_BASEDIR=${HOMEdir}/../expt_dirs/some/relative/path``.

``EXPT_SUBDIR``: (Default: 'experiment')
   If ``EXPTDIR`` is not specified, ``EXPT_SUBDIR`` represents the name of the experiment directory (*not* the full path). 

``EXEC_SUBDIR``: (Default: "exec")
   The name of the subdirectory of ``ufs-srweather-app`` where executables are installed.

``EXPTDIR``: (Default: ``'{{ [workflow.EXPT_BASEDIR, workflow.EXPT_SUBDIR]|path_join }}'``)
   The full path to the experiment directory. By default, this value will point to ``"${EXPT_BASEDIR}/${EXPT_SUBDIR}"``, but the user can define it differently in the configuration file if desired. 

Pre-Processing File Separator Parameters
--------------------------------------------

``DOT_OR_USCORE``: (Default: "_")
   This variable sets the separator character(s) to use in the names of the grid, mosaic, and orography fixed files. Ideally, the same separator should be used in the names of these fixed files as in the surface climatology fixed files. Valid values: ``"_"`` | ``"."``

Set File Name Parameters
----------------------------

``EXPT_CONFIG_FN``: (Default: "config.yaml")
   Name of the user-specified configuration file for the forecast experiment.

``CONSTANTS_FN``: (Default: "constants.yaml")
   Name of the file containing definitions of various mathematical, physical, and SRW App constants.

``RGNL_GRID_NML_FN``: (Default: "regional_grid.nml")
   Name of the file containing namelist settings for the code that generates an "ESGgrid" regional grid.

``FV3_NML_FN``: (Default: "input.nml")
   Name of the forecast model's namelist file. It includes the information in ``FV3_NML_BASE_SUITE_FN`` (i.e., ``input.nml.FV3``),  ``FV3_NML_YAML_CONFIG_FN`` (i.e., ``FV3.input.yml``), and the user configuration file (i.e., ``config.yaml``).

``FV3_NML_BASE_SUITE_FN``: (Default: ``"{{ FV3_NML_FN }}.FV3"``)
   Name of the Fortran file containing the forecast model's base suite namelist (i.e., the portion of the namelist that is common to all physics suites). By default, it will be named ``input.nml.FV3``. 

``FV3_NML_YAML_CONFIG_FN``: (Default: ``"FV3.input.yml"``)
   Name of the YAML configuration file containing the forecast model's namelist settings for various physics suites.

``FV3_NML_BASE_ENS_FN``: (Default: ``"{{ FV3_NML_FN }}.base_ens"``)
   Name of the Fortran file containing the forecast model's base ensemble namelist (i.e., the original namelist file from which each of the ensemble members' namelist files is generated).

``FV3_EXEC_FN``: (Default: "ufs_model")
   Name to use for the forecast model executable. 

``DATA_TABLE_FN``: ( Default: "data_table")
   Name of the file that contains the data table read in by the forecast model. 

``DIAG_TABLE_FN``: ( Default: "diag_table")
   Prefix for the name of the file that specifies the output fields of the forecast model. 

``FIELD_TABLE_FN``: ( Default: "field_table")
   Prefix for the name of the file that specifies the :term:`tracers <tracer>` that the forecast model will read in from the :term:`IC/LBC <ICs/LBCs>` files.

.. _tmpl-fn-warning:

.. attention::

   For the file names below, the SRW App expects to read in the default value set in ``setup.py`` (e.g., ``diag_table.{CCPP_PHYS_SUITE}``), and users should **not** specify a value for these variables in their configuration file (i.e., ``config.yaml``) unless (1) the file name required by the model changes and (2) they also change the names of the corresponding files in the ``ufs-srweather-app/parm`` directory (e.g., change the names of ``diag_table`` options in ``parm`` when setting ``DIAG_TABLE_TMPL_FN``).

``DIAG_TABLE_TMPL_FN``: (Default: ``'diag_table.{{ CCPP_PHYS_SUITE }}'``)
   Name of a template file that specifies the output fields of the forecast model. The selected physics suite is appended to this file name in ``setup.py``, taking the form ``{DIAG_TABLE_TMPL_FN}.{CCPP_PHYS_SUITE}``. In general, users should not set this variable in their configuration file (see :ref:`note <tmpl-fn-warning>`).

``FIELD_TABLE_TMPL_FN``: (Default: ``'field_table.{{ CCPP_PHYS_SUITE }}'``)
   Name of a template file that specifies the :term:`tracers <tracer>` that the forecast model will read in from the :term:`IC/LBC <ICs/LBCs>` files. The selected physics suite is appended to this file name in ``setup.py``, taking the form ``{FIELD_TABLE_TMPL_FN}.{CCPP_PHYS_SUITE}``. In general, users should not set this variable in their configuration file (see :ref:`note <tmpl-fn-warning>`).

``MODEL_CONFIG_FN``: (Default: "model_configure")
   Name of a file that contains settings and configurations for the :term:`NUOPC`/:term:`ESMF` main component. In general, users should not set this variable in their configuration file (see :ref:`note <tmpl-fn-warning>`).

``NEMS_CONFIG_FN``: (Default: "nems.configure")
   Name of a file that contains information about the various :term:`NEMS` components and their run sequence. In general, users should not set this variable in their configuration file (see :ref:`note <tmpl-fn-warning>`).

``AQM_RC_FN``: (Default: "aqm.rc")
   Name of resource file for NOAA Air Quality Model (AQM). 

``AQM_RC_TMPL_FN``: (Default: "aqm.rc")
   Template file name of resource file for NOAA Air Quality Model (AQM). 

Set File Path Parameters
----------------------------

``FV3_NML_BASE_SUITE_FP``: (Default: ``'{{ [user.PARMdir, FV3_NML_BASE_SUITE_FN]|path_join }}'``)
   Path to the ``FV3_NML_BASE_SUITE_FN`` file. 

``FV3_NML_YAML_CONFIG_FP``: (Default: ``'{{ [user.PARMdir, FV3_NML_YAML_CONFIG_FN]|path_join }}'``)
   Path to the ``FV3_NML_YAML_CONFIG_FN`` file. 

``FV3_NML_BASE_ENS_FP``: (Default: ``'{{ [EXPTDIR, FV3_NML_BASE_ENS_FN]|path_join }}'``)
   Path to the ``FV3_NML_BASE_ENS_FN`` file. 

``DATA_TABLE_TMPL_FP``: (Default: ``'{{ [user.PARMdir, DATA_TABLE_FN]|path_join }}'``)
   Path to the ``DATA_TABLE_FN`` file. 

``DIAG_TABLE_TMPL_FP``: (Default: ``'{{ [user.PARMdir, DIAG_TABLE_TMPL_FN]|path_join }}'``)
   Path to the ``DIAG_TABLE_TMPL_FN`` file. 

``FIELD_TABLE_TMPL_FP``: (Default: ``'{{ [user.PARMdir, FIELD_TABLE_TMPL_FN]|path_join }}'``)
   Path to the ``FIELD_TABLE_TMPL_FN`` file. 

``MODEL_CONFIG_TMPL_FP``: (Default: ``'{{ [user.PARMdir, MODEL_CONFIG_FN]|path_join }}'``) 
   Path to the ``MODEL_CONFIG_FN`` file.

``NEMS_CONFIG_TMPL_FP``: (Default: ``'{{ [user.PARMdir, NEMS_CONFIG_FN]|path_join }}'``) 
   Path to the ``NEMS_CONFIG_FN`` file. 

``AQM_RC_TMPL_FP``: (Default: ``'{{ [user.PARMdir, AQM_RC_TMPL_FN]|path_join }}'``) 
   Path to the ``AQM_RC_TMPL_FN`` file. 


*Experiment Directory* Files and Paths
------------------------------------------

This section contains files and paths to files that are staged in the experiment directory at configuration time. 

``DATA_TABLE_FP``: (Default: ``'{{ [EXPTDIR, DATA_TABLE_FN]|path_join }}'``)
   Path to the data table in the experiment directory. 

``FIELD_TABLE_FP``: (Default: ``'{{ [EXPTDIR, FIELD_TABLE_FN]|path_join }}'``)
   Path to the field table in the experiment directory. (The field table specifies tracers that the forecast model reads in.)

``NEMS_CONFIG_FP``: (Default: ``'{{ [EXPTDIR, NEMS_CONFIG_FN]|path_join }}'``)
   Path to the ``NEMS_CONFIG_FN`` file in the experiment directory. 

``FV3_NML_FP``: (Default: ``'{{ [EXPTDIR, FV3_NML_FN]|path_join }}'``)
   Path to the ``FV3_NML_FN`` file in the experiment directory.

``FV3_NML_STOCH_FP``: (Default: ``'{{ [EXPTDIR, [FV3_NML_FN, "_stoch"]|join ]|path_join }}'``)
   Path to a namelist file that includes stochastic physics namelist parameters. 

``FCST_MODEL``: (Default: "ufs-weather-model")
   Name of forecast model. Valid values: ``"ufs-weather-model"`` | ``"fv3gfs_aqm"``

``WFLOW_XML_FN``: (Default: "FV3LAM_wflow.xml")
   Name of the Rocoto workflow XML file that the experiment generation script creates. This file defines the workflow for the experiment.

``GLOBAL_VAR_DEFNS_FN``: (Default: "var_defns.sh")
   Name of the file (a shell script) containing definitions of the primary and secondary experiment variables (parameters). This file is sourced by many scripts (e.g., the J-job scripts corresponding to each workflow task) in order to make all the experiment variables available in those scripts. The primary variables are defined in the default configuration file (``config_defaults.yaml``) and in the user configuration file (``config.yaml``). The secondary experiment variables are generated by the experiment generation script. 

``ROCOTO_YAML_FN``: (Default: "rocoto_defns.yaml")
   Name of the YAML file containing the YAML workflow definition from which the Rocoto XML file is created.

``EXTRN_MDL_VAR_DEFNS_FN``: (Default: "extrn_mdl_var_defns")
   Name of the file (a shell script) containing the definitions of variables associated with the external model from which :term:`ICs` or :term:`LBCs` are generated. This file is created by the ``GET_EXTRN_*`` task because the values of the variables it contains are not known before this task runs. The file is then sourced by the ``MAKE_ICS`` and ``MAKE_LBCS`` tasks.

``WFLOW_LAUNCH_SCRIPT_FN``: (Default: "launch_FV3LAM_wflow.sh")
   Name of the script that can be used to (re)launch the experiment's Rocoto workflow.

``WFLOW_LAUNCH_LOG_FN``: (Default: "log.launch_FV3LAM_wflow")
   Name of the log file that contains the output from successive calls to the workflow launch script (``WFLOW_LAUNCH_SCRIPT_FN``).

``GLOBAL_VAR_DEFNS_FP``: (Default: ``'{{ [EXPTDIR, GLOBAL_VAR_DEFNS_FN] |path_join }}'``) 
   Path to the global variable definition file (``GLOBAL_VAR_DEFNS_FN``) in the experiment directory. 

``ROCOTO_YAML_FP``: (Default: ``'{{ [EXPTDIR, ROCOTO_YAML_FN] |path_join }}'``)
   Path to the Rocoto YAML configuration file (``ROCOTO_YAML_FN``) in the experiment directory. 

``WFLOW_LAUNCH_SCRIPT_FP``: (Default: ``'{{ [user.USHdir, WFLOW_LAUNCH_SCRIPT_FN] |path_join }}'``) 
   Path to the workflow launch script (``WFLOW_LAUNCH_SCRIPT_FN``) in the experiment directory. 

``WFLOW_LAUNCH_LOG_FP``: (Default: ``'{{ [EXPTDIR, WFLOW_LAUNCH_LOG_FN] |path_join }}'``) 
   Path to the log file (``WFLOW_LAUNCH_LOG_FN``) in the experiment directory that contains output from successive calls to the workflow launch script. 

Experiment Fix File Paths
---------------------------

These parameters are associated with the fixed (i.e., static) files. Unlike the file path parameters in :numref:`Section %s <SystemFixedFiles>`, which pertain to the locations of system data, the parameters in this section indicate fix file paths within the experiment directory (``$EXPTDIR``).  

``FIXdir``: (Default: ``'{{ EXPTDIR }}'``)
   Location where fix files will be stored for a given experiment.

``FIXam``: (Default: ``'{{ [FIXdir, "fix_am"]|path_join }}'``)
   Directory containing the fixed files (or symlinks to fixed files) for various fields on global grids (which are usually much coarser than the native FV3-LAM grid).

``FIXclim``: (Default: ``'{{ [FIXdir, "fix_clim"]|path_join }}'``)
   Directory containing the MERRA2 aerosol climatology data file and lookup tables for optics properties.

``FIXlam``: (Default: ``'{{ [FIXdir, "fix_lam"]|path_join }}'``)
   Directory containing the fixed files (or symlinks to fixed files) for the grid, orography, and surface climatology on the native FV3-LAM grid.

``THOMPSON_MP_CLIMO_FN``: (Default: "Thompson_MP_MONTHLY_CLIMO.nc")
   Name of file that contains aerosol climatology data. It can be used to generate approximate versions of the aerosol fields needed by Thompson microphysics. This file will be used to generate such approximate aerosol fields in the :term:`ICs` and :term:`LBCs` if Thompson MP is included in the physics suite and if the external model for ICs or LBCs does not already provide these fields.
   
``THOMPSON_MP_CLIMO_FP``: (Default: ``'{{ [FIXam, THOMPSON_MP_CLIMO_FN]|path_join }}'``)
   Path to the file that contains aerosol climatology data (i.e., path to ``THOMPSON_MP_CLIMO_FN``). 

.. _CCPP_Params:

CCPP Parameter
-----------------

``CCPP_PHYS_SUITE``: (Default: "FV3_GFS_v16")
   This parameter indicates which :term:`CCPP` (Common Community Physics Package) physics suite to use for the forecast(s). The choice of physics suite determines the forecast model's namelist file, the diagnostics table file, the field table file, and the XML physics suite definition file, which are staged in the experiment directory or the :term:`cycle` directories under it. 

   .. note:: 
      For information on *stochastic physics* parameters, see :numref:`Section %s <stochastic-physics>`.
   
   **Current supported settings for the CCPP parameter are:** 

   | ``"FV3_GFS_v16"`` 
   | ``"FV3_RRFS_v1beta"`` 
   | ``"FV3_HRRR"``
   | ``"FV3_WoFS_v0"``
   | ``"FV3_RAP"``

   Other valid values can be found in the ``ush/valid_param_vals.yaml`` `file <https://github.com/ufs-community/ufs-srweather-app/blob/release/public-v2.2.0/ush/valid_param_vals.yaml>`__, but users cannot expect full support for these schemes.

``CCPP_PHYS_SUITE_FN``: (Default: ``'suite_{{ CCPP_PHYS_SUITE }}.xml'``)
   The name of the suite definition file (SDF) used for the experiment. 

``CCPP_PHYS_SUITE_IN_CCPP_FP``: (Default: ``'{{ [user.UFS_WTHR_MDL_DIR, "FV3", "ccpp", "suites", CCPP_PHYS_SUITE_FN] |path_join }}'``)
   The full path to the suite definition file (SDF) in the forecast model's directory structure (e.g., ``/path/to/ufs-srweather-app/sorc/ufs-weather-model/FV3/ccpp/suites/$CCPP_PHYS_SUITE_FN``). 

``CCPP_PHYS_SUITE_FP``: (Default: ``'{{ [workflow.EXPTDIR, CCPP_PHYS_SUITE_FN]|path_join }}'``)
   The full path to the suite definition file (SDF) in the experiment directory. 

``CCPP_PHYS_DIR``: (Default: ``'{{ [user.UFS_WTHR_MDL_DIR, "FV3", "ccpp", "physics", "physics"] |path_join }}'``)
   The directory containing the CCPP physics source code. This is needed to link table(s) contained in that repository. 

Field Dictionary Parameters
------------------------------

``FIELD_DICT_FN``: (Default: "fd_nems.yaml")
   The name of the field dictionary file. This file is a community-based dictionary for shared coupling fields and is automatically generated by the :term:`NUOPC` Layer. 

``FIELD_DICT_IN_UWM_FP``: (Default: ``'{{ [user.UFS_WTHR_MDL_DIR, "tests", "parm", FIELD_DICT_FN]|path_join }}'``)
   The full path to ``FIELD_DICT_FN`` within the forecast model's directory structure (e.g., ``/path/to/ufs-srweather-app/sorc/ufs-weather-model/tests/parm/$FIELD_DICT_FN``).

``FIELD_DICT_FP``: (Default: ``'{{ [workflow.EXPTDIR, FIELD_DICT_FN]|path_join }}'``)
   The full path to ``FIELD_DICT_FN`` in the experiment directory.

.. _GridGen:

Grid Generation Parameters
------------------------------

``GRID_GEN_METHOD``: (Default: "")
   This variable specifies which method to use to generate a regional grid in the horizontal plane. The values that it can take on are:

   * ``"ESGgrid"``: The "ESGgrid" method will generate a regional version of the Extended Schmidt Gnomonic (ESG) grid using the map projection developed by Jim Purser of EMC (:cite:t:`Purser_2020`). "ESGgrid" is the preferred grid option. More information on the ESG grid is available at :srw-wiki:`Purser_UIFCW_2023.pdf`.

   * ``"GFDLgrid"``: The "GFDLgrid" method first generates a "parent" global cubed-sphere grid. Then a portion from tile 6 of the global grid is used as the regional grid. This regional grid is referred to in the grid generation scripts as "tile 7," even though it does not correspond to a complete tile. The forecast is run only on the regional grid (i.e., on tile 7, not on tiles 1 through 6). Note that the "GFDLgrid" method is the legacy grid generation method. It is not supported in *all* predefined domains. 

.. attention::

   If the experiment uses a **predefined grid** (i.e., if ``PREDEF_GRID_NAME`` is set to the name of a valid predefined grid), then ``GRID_GEN_METHOD`` will be reset to the value of ``GRID_GEN_METHOD`` for that grid. This will happen regardless of whether ``GRID_GEN_METHOD`` is assigned a value in the experiment configuration file; any value assigned will be overwritten.

.. note::

   If the experiment uses a **user-defined grid** (i.e., if ``PREDEF_GRID_NAME`` is set to a null string), then ``GRID_GEN_METHOD`` must be set in the experiment configuration file. Otherwise, the experiment generation will fail because the generation scripts check to ensure that the grid name is set to a non-empty string before creating the experiment directory.

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
   | ``"RRFS_NA_13km"``
   
   **Other valid values include:**

   | ``"AQM_NA_13km"``
   | ``"CONUS_25km_GFDLgrid"`` 
   | ``"CONUS_3km_GFDLgrid"``
   | ``"GSD_HRRR_25km"``
   | ``"RRFS_AK_13km"``
   | ``"RRFS_AK_3km"`` 
   | ``"RRFS_CONUScompact_25km"``
   | ``"RRFS_CONUScompact_13km"``
   | ``"RRFS_CONUScompact_3km"``
   | ``"RRFS_NA_3km"``
   | ``"WoFS_3km"``

.. note::

   * If ``PREDEF_GRID_NAME`` is set to a valid predefined grid name, the grid generation method, the (native) grid parameters, and the write component grid parameters are set to predefined values for the specified grid, overwriting any settings of these parameters in the user-specified experiment configuration file (``config.yaml``). In addition, if the time step ``DT_ATMOS`` and the computational parameters (``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE``) are not specified in that configuration file, they are also set to predefined values for the specified grid.

   * If ``PREDEF_GRID_NAME`` is set to an empty string, it implies that the user will provide the native grid parameters in the user-specified experiment configuration file (``config.yaml``).  In this case, the grid generation method, the native grid parameters, the write component grid parameters, the main time step (``DT_ATMOS``), and the computational parameters (``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE``) must be set in the configuration file. Otherwise, the values of the parameters in the default experiment configuration file (``config_defaults.yaml``) will be used.

Forecast Parameters
----------------------
``DATE_FIRST_CYCL``: (Default: "YYYYMMDDHH")
   Starting cycle date of the first forecast in the set of forecasts to run. Format is "YYYYMMDDHH".

``DATE_LAST_CYCL``: (Default: "YYYYMMDDHH")
   Starting cycle date of the last forecast in the set of forecasts to run. Format is "YYYYMMDDHH".

``INCR_CYCL_FREQ``: (Default: 24)
   Increment in hours for Rocoto cycle frequency. The default is 24, which means cycl_freq=24:00:00.

``FCST_LEN_HRS``: (Default: 24)
   The length of each forecast in integer hours. (Or the short forecast length when there are different lengths.)

``LONG_FCST_LEN_HRS``: (Default: ``'{% if FCST_LEN_HRS < 0 %}{{ FCST_LEN_CYCL|max }}{% else %}{{ FCST_LEN_HRS }}{% endif %}'``)
   The length of the longer forecast in integer hours in a system that varies the length of the forecast by time of day. There is no need for the user to update this value directly, as it is derived from ``FCST_LEN_CYCL`` when ``FCST_LEN_HRS=-1``.

.. note::

   Shorter forecasts are often used to save resources. However, users may wish to gain insight further into the future. In such cases, users can periodically run a longer forecast. For example, in an experiment, a researcher might run 18-hour forecasts for most forecast hours but run a longer 48-hour forecast at "synoptic times" (e.g., 0, 6, 12, 18 UTC). This is particularly common with resource-intensive :term:`DA <data assimilation>` systems that cycle frequently. 

``FCST_LEN_CYCL``: (Default: ``- '{{ FCST_LEN_HRS }}'``)
   The length of forecast for each cycle in a given day (in integer hours). This is valid only when ``FCST_LEN_HRS = -1``. This pattern recurs for all cycle dates. Must have the same number of entries as cycles per day (as defined by 24/``INCR_CYCL_FREQ``), or if less than one day the entries must include the length of each cycle to be run. By default, it is set to a 1-item list containing the standard fcst length. 

.. hint::
   The interaction of ``FCST_LEN_HRS``, ``LONG_FCST_LEN_HRS``, and ``FCST_LEN_CYCL`` can be confusing. As an example, take an experiment with cycling every three hours, a short forecast length of 18 hours, and a long forecast length of 48 hours. The long forecasts are run at 0 and 12 UTC. Users would put the following entry in their configuration file: 

      .. code-block:: console

         FCST_LEN_HRS: -1
         FCST_LEN_CYCL: 
           - 48
           - 18
           - 18 
           - 18 
           - 48
           - 18
           - 18
           - 18

   By setting ``FCST_LEN_HRS: -1``, the experiment will derive the values of ``FCST_LEN_HRS`` (18) and ``LONG_FCST_LEN_HRS`` (48) for each cycle date. 

.. _preexisting-dirs:

Pre-Existing Directory Parameter
------------------------------------
``PREEXISTING_DIR_METHOD``: (Default: "quit")
   This variable determines how to deal with pre-existing directories (resulting from previous calls to the experiment generation script using the same experiment name [``EXPT_SUBDIR``] as the current experiment). This variable must be set to one of four valid values: ``"delete"``, ``"rename"``, ``"reuse"``, or ``"quit"``.  The behavior for each of these values is as follows:

   * **"delete":** The preexisting directory is deleted and a new directory (having the same name as the original preexisting directory) is created.

   * **"rename":** The preexisting directory is renamed and a new directory (having the same name as the original pre-existing directory) is created. The new name of the preexisting directory consists of its original name and the suffix "_old###", where ``###`` is a 3-digit integer chosen to make the new name unique.

   * **"reuse":** This method will keep the preexisting directory intact. However, when the preexisting directory is ``$EXPDIR``, this method will save all old files to a subdirectory ``oldxxx/`` and then populate new files into the ``$EXPDIR`` directory. This is useful to keep ongoing runs uninterrupted; rocotoco ``*db`` files and previous cycles will stay and hence there is no need to manually copy or move ``*db`` files and previous cycles back, and there is no need to manually restart related rocoto tasks failed during the workflow generation process. This method may be best suited for incremental system reuses.

   * **"quit":** The preexisting directory is left unchanged, but execution of the currently running script is terminated. In this case, the preexisting directory must be dealt with manually before rerunning the script.

Detailed Output Messages
--------------------------
These variables are flags that indicate whether to print more detailed messages.

``VERBOSE``: (Default: true)
   Flag that determines whether the experiment generation and workflow task scripts print out extra informational messages. Valid values: ``True`` | ``False``

``DEBUG``: (Default: false)
   Flag that determines whether to print out very detailed debugging messages.  Note that if DEBUG is set to true, then VERBOSE will also be reset to true if it isn't already. Valid values: ``True`` | ``False``

Other
--------

``COMPILER``: (Default: "intel")
   Type of compiler invoked during the build step. Currently, this must be set manually; it is not inherited from the build system in the ``ufs-srweather-app`` directory. Valid values: ``"intel"`` | ``"gnu"``

``SYMLINK_FIX_FILES``: (Default: true)
   Flag that indicates whether to symlink fix files to the experiment directory (if true) or copy them (if false). Valid values: ``True`` | ``False``

``DO_REAL_TIME``: (Default: false)
   Switch for real-time run. Valid values: ``True`` | ``False``

``COLDSTART``: (Default: true)
   Flag for turning on/off cold start for the first cycle. Valid values: ``True`` | ``False``

``WARMSTART_CYCLE_DIR``: (Default: "/path/to/warm/start/cycle/dir")
   Path to the cycle directory where RESTART subdirectory is located for warm start. 

.. _NCOModeParms:

NCO-Specific Variables
=========================

A standard set of environment variables has been established for *nco* mode to simplify the production workflow and improve the troubleshooting process for operational and preoperational models. These variables are only used in *nco* mode (i.e., when ``RUN_ENVIR: "nco"``). When non-default parameters are selected for the variables in this section, they should be added to the ``nco:`` section of the ``config.yaml`` file. 

.. note::
   Only *community* mode is fully supported for releases. *nco* mode is used by those at the Environmental Modeling Center (EMC) and Global Systems Laboratory (GSL) who are working on pre-implementation operational testing. Other users should run the SRW App in *community* mode. 

``envir_default, NET_default, model_ver_default, RUN_default``:
   Standard environment variables defined in the NCEP Central Operations WCOSS Implementation Standards document. These variables are used in forming the path to various directories containing input, output, and workflow files. The variables are defined in the :nco:`WCOSS Implementation Standards <ImplementationStandards.v11.0.0.pdf>` document (pp. 4-5) as follows: 

   ``envir_default``: (Default: "para")
      Set to "test" during the initial testing phase, "para" when running in parallel (on a schedule), and "prod" in production. 

   ``NET_default``: (Default: "srw")
      Model name (first level of ``com`` directory structure)

   ``model_ver_default``: (Default: "v1.0.0")
      Version number of package in three digits (second level of ``com`` directory)

   ``RUN_default``: (Default: "srw")
      Name of model run (third level of ``com`` directory structure). In general, same as ``${NET_default}``.

``OPSROOT_default``: (Default: ``'{{ workflow.EXPT_BASEDIR }}/../nco_dirs'``)
  The operations root directory in *nco* mode.

``COMROOT_default``: (Default: ``'{{ OPSROOT_default }}/com'``)
   The ``com`` root directory for input/output data that is located on the current system (typically ``$OPSROOT_default/com``). 

``DATAROOT_default``: (Default: ``'{{OPSROOT_default }}/tmp'``)
   Directory containing the (temporary) working directory for running jobs; typically named ``$OPSROOT_default/tmp`` in production. 

``DCOMROOT_default``: (Default: ``'{{OPSROOT_default }}/dcom'``)
   ``dcom`` root directory, typically ``$OPSROOT_default/dcom``. This directory contains input/incoming data that is retrieved from outside WCOSS.

``LOGBASEDIR_default``: (Default: ``'{% if user.RUN_ENVIR == "nco" %}{{ [OPSROOT_default, "output"]|path_join }}{% else %}{{ [workflow.EXPTDIR, "log"]|path_join }}{% endif %}'``)
   Directory in which the log files from the workflow tasks will be placed.

``COMIN_BASEDIR``: (Default: ``'{{ COMROOT_default }}/{{ NET_default }}/{{ model_ver_default }}'``)
   ``com`` directory for current model's input data, typically ``$COMROOT/$NET/$model_ver/$RUN.$PDY``.

``COMOUT_BASEDIR``: (Default: ``'{{ COMROOT_default }}/{{ NET_default }}/{{ model_ver_default }}'``)
   ``com`` directory for current model's output data, typically ``$COMROOT/$NET/$model_ver/$RUN.$PDY``.

``DBNROOT_default``: (Default: "")
   Root directory for the data-alerting utilities.
   
``SENDECF_default``: (Default: false)
   Boolean variable used to control ``ecflow_client`` child commands.

``SENDDBN_default``: (Default: false)
   Boolean variable used to control sending products off WCOSS2.

``SENDDBN_NTC_default``: (Default: false)
   Boolean variable used to control sending products with WMO headers off WCOSS2.

``SENDCOM_default``: (Default: false)
   Boolean variable to control data copies to ``$COMOUT``.

``SENDWEB_default``: (Default: false)
   Boolean variable used to control sending products to a web server, often ``ncorzdm``.

``KEEPDATA_default``: (Default: true)
   Boolean variable used to specify whether or not the working directory should be kept upon successful job completion.

``MAILTO_default``: (Default: "")
   List of email addresses to send email to.

``MAILCC_default``: (Default: "")
   List of email addresses to CC on email.

.. _make-grid:

MAKE_GRID Configuration Parameters
======================================

Non-default parameters for the ``make_grid`` task are set in the ``task_make_grid:`` section of the ``config.yaml`` file. 

Basic Task Parameters
--------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. Typically, users do not need to adjust the default values. 

   ``GRID_DIR``: (Default: ``'{{ [workflow.EXPTDIR, "grid"]|path_join if rocoto.tasks.get("task_make_grid") else "" }}'``)
      The directory containing pre-generated grid files when the ``MAKE_GRID`` task is not meant to run.

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

``ESGgrid_WIDE_HALO_WIDTH``: (Default: "")
   The width (in number of grid cells) of the :term:`halo` to add around the regional grid before shaving the halo down to the width(s) expected by the forecast model. The user need not specify this variable since it is set automatically in ``set_gridparams_ESGgrid.py``.

.. _WideHalo:

.. note::
   A :term:`halo` is the strip of cells surrounding the regional grid; the halo is used to feed in the lateral boundary conditions to the grid. The forecast model requires **grid** files containing 3-cell- and 4-cell-wide halos and **orography** files with 0-cell- and 3-cell-wide halos. In order to generate grid and orography files with appropriately-sized halos, the grid and orography tasks create preliminary files with halos around the regional domain of width ``ESGgrid_WIDE_HALO_WIDTH`` cells. The files are then read in and "shaved" down to obtain grid files with 3-cell-wide and 4-cell-wide halos and orography files with 0-cell-wide and 3-cell-wide halos. The original halo that gets shaved down is referred to as the "wide" halo because it is wider than the 0-cell-wide, 3-cell-wide, and 4-cell-wide halos that users eventually end up with. Note that the grid and orography files with the wide halo are only needed as intermediates in generating the files with 0-cell-, 3-cell-, and 4-cell-wide halos; they are not needed by the forecast model.

``ESGgrid_PAZI``: (Default: "")
   The rotational parameter for the "ESGgrid" (in degrees).

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
   Flag that determines the file naming convention to use for grid, orography, and surface climatology files (or, if using pregenerated files, the naming convention that was used to name these files). These files usually start with the string ``"C${RES}_"``, where ``RES`` is an integer. In the global forecast model, ``RES`` is the number of points in each of the two horizontal directions (x and y) on each tile of the global grid (defined here as ``GFDLgrid_NUM_CELLS``). If this flag is set to true, ``RES`` will be set to ``GFDLgrid_NUM_CELLS`` just as in the global forecast model. If it is set to false, we calculate (in the grid generation task) an "equivalent global uniform cubed-sphere resolution" --- call it ``RES_EQUIV`` --- and then set ``RES`` equal to it. ``RES_EQUIV`` is the number of grid points in each of the x and y directions on each tile that a global UNIFORM (i.e., stretch factor of 1) cubed-sphere grid would need to have in order to have the same average grid size as the regional grid. This is a more useful indicator of the grid size because it takes into account the effects of ``GFDLgrid_NUM_CELLS``, ``GFDLgrid_STRETCH_FAC``, and ``GFDLgrid_REFINE_RATIO`` in determining the regional grid's typical grid size, whereas simply setting ``RES`` to ``GFDLgrid_NUM_CELLS`` doesn't take into account the effects of ``GFDLgrid_STRETCH_FAC`` and ``GFDLgrid_REFINE_RATIO`` on the regional grid's resolution. Nevertheless, some users still prefer to use ``GFDLgrid_NUM_CELLS`` in the file names, so we allow for that here by setting this flag to true.

.. _make-orog:
 
MAKE_OROG Configuration Parameters
=====================================

Non-default parameters for the ``make_orog`` task are set in the ``task_make_orog:`` section of the ``config.yaml`` file. 

``KMP_AFFINITY_MAKE_OROG``: (Default: "disabled")
   Intel Thread Affinity Interface for the ``make_orog`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity. Settings for the ``make_orog`` task are disabled because this task does not use parallelized code.

``OMP_NUM_THREADS_MAKE_OROG``: (Default: 6)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_MAKE_OROG``: (Default: "2048m")
   Controls the size of the stack for threads created by the OpenMP implementation.

``OROG_DIR``: (Default: ``'{{ [workflow.EXPTDIR, "orog"]|path_join if rocoto.tasks.get("task_make_orog") else "" }}'``)
   The directory containing pre-generated orography files to use when the ``MAKE_OROG`` task is not meant to run.

.. _make-sfc-climo:

MAKE_SFC_CLIMO Configuration Parameters
===========================================

Non-default parameters for the ``make_sfc_climo`` task are set in the ``task_make_sfc_climo:`` section of the ``config.yaml`` file. 

``KMP_AFFINITY_MAKE_SFC_CLIMO``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``make_sfc_climo`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_MAKE_SFC_CLIMO``: (Default: 1)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_MAKE_SFC_CLIMO``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

``SFC_CLIMO_DIR``: (Default: ``'{{ [workflow.EXPTDIR, "sfc_climo"]|path_join if rocoto.tasks.get("task_make_sfc_climo") else "" }}'``)
   The directory containing pre-generated surface climatology files to use when the ``MAKE_SFC_CLIMO`` task is not meant to run.

.. _task_get_extrn_ics:

GET_EXTRN_ICS Configuration Parameters
=========================================

Non-default parameters for the ``get_extrn_ics`` task are set in the ``task_get_extrn_ics:`` section of the ``config.yaml`` file. 

.. _basic-get-extrn-ics:

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``EXTRN_MDL_NAME_ICS``: (Default: "FV3GFS")
   The name of the external model that will provide fields from which initial condition (IC) files, surface files, and 0-th hour boundary condition files will be generated for input into the forecast model. Valid values: ``"GSMGFS"`` | ``"FV3GFS"`` | ``"GEFS"`` | ``"GDAS"`` | ``"RAP"`` | ``"HRRR"`` | ``"NAM"`` | ``"UFS-CASE-STUDY"``

``EXTRN_MDL_ICS_OFFSET_HRS``: (Default: 0)
   Users may wish to start a forecast using forecast data from a previous cycle of an external model. This variable indicates how many hours earlier the external model started than the FV3 forecast configured here. For example, if the forecast should start from a 6-hour forecast of the GFS, then ``EXTRN_MDL_ICS_OFFSET_HRS: "6"``.

``FV3GFS_FILE_FMT_ICS``: (Default: "nemsio")
   If using the FV3GFS model as the source of the :term:`ICs` (i.e., if ``EXTRN_MDL_NAME_ICS: "FV3GFS"``), this variable specifies the format of the model files to use when generating the ICs. Valid values: ``"nemsio"`` | ``"grib2"`` | ``"netcdf"``

File and Directory Parameters
--------------------------------

``EXTRN_MDL_SYSBASEDIR_ICS``: (Default: '')
   A known location of a real data stream on a given platform. This is typically a real-time data stream as on Hera, Jet, or WCOSS. External model files for generating :term:`ICs` on the native grid should be accessible via this data stream. The way the full path containing these files is constructed depends on the user-specified external model for ICs (defined above in :numref:`Section %s <basic-get-extrn-ics>` ``EXTRN_MDL_NAME_ICS``).

   .. note::
      This variable must be defined as a null string in ``config_defaults.yaml`` so that if it is specified by the user in the experiment configuration file (``config.yaml``), it remains set to those values, and if not, it gets set to machine-dependent values.

``USE_USER_STAGED_EXTRN_FILES``: (Default: false)
   Flag that determines whether the workflow will look for the external model files needed for generating :term:`ICs` in user-specified directories (rather than fetching them from mass storage like NOAA :term:`HPSS`). Valid values: ``True`` | ``False``

``EXTRN_MDL_SOURCE_BASEDIR_ICS``: (Default: "")
   Directory containing external model files for generating ICs. If ``USE_USER_STAGED_EXTRN_FILES`` is set to true, the workflow looks within this directory for a subdirectory named "YYYYMMDDHH", which contains the external model files specified by the array ``EXTRN_MDL_FILES_ICS``. This "YYYYMMDDHH" subdirectory corresponds to the start date and cycle hour of the forecast (see :ref:`above <METParamNote>`). These files will be used to generate the :term:`ICs` on the native FV3-LAM grid. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to false.

``EXTRN_MDL_FILES_ICS``: (Default: "")
   Array containing templates of the file names to search for in the ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` directory. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to false. A single template should be used for each model file type that is used. Users may use any of the Python-style templates allowed in the ``ush/retrieve_data.py`` script. To see the full list of supported templates, run that script with the ``-h`` option. 
   
   For example, to set FV3GFS nemsio input files:
   
   .. code-block:: console

      EXTRN_MDL_FILES_ICS=[ gfs.t{hh}z.atmf{fcst_hr:03d}.nemsio ,
      gfs.t{hh}z.sfcf{fcst_hr:03d}.nemsio ]
  
   To set FV3GFS grib files:

   .. code-block:: console

      EXTRN_MDL_FILES_ICS=[ gfs.t{hh}z.pgrb2.0p25.f{fcst_hr:03d} ]

.. _task_get_extrn_lbcs:

GET_EXTRN_LBCS Configuration Parameters
==========================================

Non-default parameters for the ``get_extrn_lbcs`` task are set in the ``task_get_extrn_lbcs:`` section of the ``config.yaml`` file. 

.. _basic-get-extrn-lbcs:

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``EXTRN_MDL_NAME_LBCS``: (Default: "FV3GFS")
   The name of the external model that will provide fields from which lateral boundary condition (LBC) files (except for the 0-th hour LBC file) will be generated for input into the forecast model. Valid values: ``"GSMGFS"`` | ``"FV3GFS"`` | ``"GEFS"`` | ``"GDAS"`` | ``"RAP"`` | ``"HRRR"`` | ``"NAM"`` | ``"UFS-CASE-STUDY"``

``LBC_SPEC_INTVL_HRS``: (Default: 6)
   The interval (in integer hours) at which LBC files will be generated. This is also referred to as the *boundary update interval*. Note that the model selected in ``EXTRN_MDL_NAME_LBCS`` must have data available at a frequency greater than or equal to that implied by ``LBC_SPEC_INTVL_HRS``. For example, if ``LBC_SPEC_INTVL_HRS`` is set to "6", then the model must have data available at least every 6 hours. It is up to the user to ensure that this is the case.

``EXTRN_MDL_LBCS_OFFSET_HRS``: (Default: ``'{{ 3 if EXTRN_MDL_NAME_LBCS == "RAP" else 0 }}'``)
   Users may wish to use lateral boundary conditions from a forecast that was started earlier than the start of the forecast configured here. This variable indicates how many hours earlier the external model started than the forecast configured here. For example, if the forecast should use lateral boundary conditions from a GFS forecast started six hours earlier, then ``EXTRN_MDL_LBCS_OFFSET_HRS: 6``. Note: the default value is model-dependent and is set in ``ush/set_extrn_mdl_params.py``.

``FV3GFS_FILE_FMT_LBCS``: (Default: "nemsio")
   If using the FV3GFS model as the source of the :term:`LBCs` (i.e., if ``EXTRN_MDL_NAME_LBCS: "FV3GFS"``), this variable specifies the format of the model files to use when generating the LBCs. Valid values: ``"nemsio"`` | ``"grib2"`` | ``"netcdf"``

File and Directory Parameters
--------------------------------

``EXTRN_MDL_SYSBASEDIR_LBCS``: (Default: '')
   Same as ``EXTRN_MDL_SYSBASEDIR_ICS`` but for :term:`LBCs`. A known location of a real data stream on a given platform. This is typically a real-time data stream as on Hera, Jet, or WCOSS. External model files for generating :term:`LBCs` on the native grid should be accessible via this data stream. The way the full path containing these files is constructed depends on the user-specified external model for LBCs (defined above in :numref:`Section %s <basic-get-extrn-lbcs>` ``EXTRN_MDL_NAME_LBCS`` above).

   .. note::
      This variable must be defined as a null string in ``config_defaults.yaml`` so that if it is specified by the user in the experiment configuration file (``config.yaml``), it remains set to those values, and if not, it gets set to machine-dependent values.

``USE_USER_STAGED_EXTRN_FILES``: (Default: false)
   Analogous to ``USE_USER_STAGED_EXTRN_FILES`` in :term:`ICs` but for :term:`LBCs`. Flag that determines whether the workflow will look for the external model files needed for generating :term:`LBCs` in user-specified directories (rather than fetching them from mass storage like NOAA :term:`HPSS`). Valid values: ``True`` | ``False``
 
``EXTRN_MDL_SOURCE_BASEDIR_LBCS``: (Default: "")
   Analogous to ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` but for :term:`LBCs` instead of :term:`ICs`.
   Directory containing external model files for generating LBCs. If ``USE_USER_STAGED_EXTRN_FILES`` is set to true, the workflow looks within this directory for a subdirectory named "YYYYMMDDHH", which contains the external model files specified by the array ``EXTRN_MDL_FILES_LBCS``. This "YYYYMMDDHH" subdirectory corresponds to the start date and cycle hour of the forecast (see :ref:`above <METParamNote>`). These files will be used to generate the :term:`LBCs` on the native FV3-LAM grid. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to false.

``EXTRN_MDL_FILES_LBCS``: (Default: "")
   Analogous to ``EXTRN_MDL_FILES_ICS`` but for :term:`LBCs` instead of :term:`ICs`. Array containing templates of the file names to search for in the ``EXTRN_MDL_SOURCE_BASEDIR_LBCS`` directory. This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to false. A single template should be used for each model file type that is used. Users may use any of the Python-style templates allowed in the ``ush/retrieve_data.py`` script. To see the full list of supported templates, run that script with the ``-h`` option. For examples, see the ``EXTRN_MDL_FILES_ICS`` variable above. 

MAKE_ICS Configuration Parameters
======================================

Non-default parameters for the ``make_ics`` task are set in the ``task_make_ics:`` section of the ``config.yaml`` file. 

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``KMP_AFFINITY_MAKE_ICS``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``make_ics`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_MAKE_ICS``: (Default: 1)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_MAKE_ICS``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

FVCOM Parameters
-------------------
``USE_FVCOM``: (Default: false)
   Flag that specifies whether to update surface conditions in FV3-:term:`LAM` with fields generated from the Finite Volume Community Ocean Model (:term:`FVCOM`). If set to true, lake/sea surface temperatures, ice surface temperatures, and ice placement will be overwritten using data provided by FVCOM. Setting ``USE_FVCOM`` to true causes the executable ``process_FVCOM.exe`` in the ``MAKE_ICS`` task to run. This, in turn, modifies the file ``sfc_data.nc`` generated by ``chgres_cube`` during the ``make_ics`` task. Note that the FVCOM data must already be interpolated to the desired FV3-LAM grid. Valid values: ``True`` | ``False``

``FVCOM_WCSTART``: (Default: "cold")
   Define whether this is a "warm" start or a "cold" start. Setting this to "warm" will read in the ``sfc_data.nc`` file generated in a RESTART directory. Setting this to "cold" will read in the ``sfc_data.nc`` file generated from ``chgres_cube`` in the ``make_ics`` portion of the workflow. Valid values: ``"cold"`` | ``"COLD"`` | ``"warm"`` | ``"WARM"``

``FVCOM_DIR``: (Default: "")
   User-defined directory where the ``fvcom.nc`` file containing :term:`FVCOM` data already interpolated to the FV3-LAM native grid is located. The file in this directory must be named ``fvcom.nc``.

``FVCOM_FILE``: (Default: "fvcom.nc")
   Name of the file located in ``FVCOM_DIR`` that has :term:`FVCOM` data interpolated to the FV3-LAM grid. This file will be copied later to a new location, and the name will be changed to ``fvcom.nc`` if a name other than ``fvcom.nc`` is selected.

Vertical Coordinate File Parameter
------------------------------------

``VCOORD_FILE``: (Default: ``"{{ workflow.FIXam }}/global_hyblev.l65.txt"``)
   Full path to the file used to set the vertical coordinates in FV3. This file should be the same in both ``make_ics`` and ``make_lbcs``.

MAKE_LBCS Configuration Parameters
======================================

Non-default parameters for the ``make_lbcs`` task are set in the ``task_make_lbcs:`` section of the ``config.yaml`` file. 

``KMP_AFFINITY_MAKE_LBCS``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``make_lbcs`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_MAKE_LBCS``: (Default: 1)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_MAKE_LBCS``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

Vertical Coordinate File Parameter
------------------------------------

``VCOORD_FILE``: (Default: ``"{{ workflow.FIXam }}/global_hyblev.l65.txt"``)
   Full path to the file used to set the vertical coordinates in FV3. This file should be the same in both ``make_ics`` and ``make_lbcs``.

.. _FcstConfigParams:

FORECAST Configuration Parameters
=====================================

Non-default parameters for the ``run_fcst`` task are set in the ``task_run_fcst:`` section of the ``config.yaml`` file. 

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

``NNODES_RUN_FCST``: (Default: ``'{{ (PE_MEMBER01 + PPN_RUN_FCST - 1) // PPN_RUN_FCST }}'``)
   The number of nodes to request from the job scheduler for the forecast task. 

``PPN_RUN_FCST``: (Default: ``'{{ platform.NCORES_PER_NODE // OMP_NUM_THREADS_RUN_FCST }}'``)
   Processes per node for the forecast task. 

``FV3_EXEC_FP``: (Default: ``'{{ [user.EXECdir, workflow.FV3_EXEC_FN]|path_join }}'``)
   Full path to the forecast model executable.

``IO_LAYOUT_Y``: (Default: 1)
   Specifies how many MPI ranks to use in the Y direction for input/output (I/O).

   .. note::

      ``IO_LAYOUT_X`` does not explicitly exist because its value is assumed to be 1. 

``KMP_AFFINITY_RUN_FCST``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``run_fcst`` task. 

.. _thread-affinity:

   .. note:: 

      **Thread Affinity Interface**

      "Intel's runtime library can bind OpenMP threads to physical processing units. The interface is controlled using the ``KMP_AFFINITY`` environment variable. Thread affinity restricts execution of certain threads to a subset of the physical processing units in a multiprocessor computer. Depending on the system (machine) topology, application, and operating system, thread affinity can have a dramatic effect on the application speed and on the execution speed of a program." Valid values: ``"scatter"`` | ``"disabled"`` | ``"balanced"`` | ``"compact"`` | ``"explicit"`` | ``"none"``

      For more information, see the `Intel Development Reference Guide <https://www.intel.com/content/www/us/en/docs/cpp-compiler/developer-guide-reference/2021-10/thread-affinity-interface.html>`__. 

``OMP_NUM_THREADS_RUN_FCST``: (Default: 1)
   The number of OpenMP threads to use for parallel regions. Corresponds to the ``ATM_omp_num_threads`` value in ``nems.configure``.

``OMP_STACKSIZE_RUN_FCST``: (Default: "512m")
   Controls the size of the stack for threads created by the OpenMP implementation.

.. _ModelConfigParams:

Model Configuration Parameters
----------------------------------

These parameters set values in the Weather Model's ``model_configure`` file.

``DT_ATMOS``: (Default: "")
   The main forecast model integration time step (positive integer value). This is the time step for the outermost atmospheric model loop in seconds. It corresponds to the frequency at which the physics routines and the top level dynamics routine are called. (Note that one call to the top-level dynamics routine results in multiple calls to the horizontal dynamics, :term:`tracer` transport, and vertical dynamics routines; see the `FV3 dycore scientific documentation <https://repository.library.noaa.gov/view/noaa/30725>`__ for details.) In the SRW App, a default value for ``DT_ATMOS`` appears in the ``set_predef_grid_params.yaml`` script, but a different value can be set in ``config.yaml``. In general, the smaller the grid cell size is, the smaller this value needs to be in order to avoid numerical instabilities during the forecast.

``FHROT``: (Default: 0)
   Forecast hour at restart.

``RESTART_INTERVAL``: (Default: 0)
   Frequency of the output restart files in hours. 
   
   * Using the default interval (0), restart files are produced at the end of a forecast run. 
   * When ``RESTART_INTERVAL: 1``, restart files are produced every hour with the prefix "YYYYMMDD.HHmmSS." in the ``RESTART`` directory. 
   * When ``RESTART_INTERVAL: 1 2 5``, restart files are produced only at forecast hours 1, 2, and 5.

.. _InlinePost:

``WRITE_DOPOST``: (Default: false)
   Flag that determines whether to use the inline post option, which calls the Unified Post Processor (:term:`UPP`) from within the UFS Weather Model. The default ``WRITE_DOPOST: false`` does not use the inline post functionality, and the ``run_post`` tasks are called from outside of the UFS Weather Model. If ``WRITE_DOPOST: true``, the ``WRITE_DOPOST`` flag in the ``model_configure`` file will be set to true, and the post-processing (:term:`UPP`) tasks will be called from within the Weather Model. This means that the post-processed files (in :term:`grib2` format) are output by the Weather Model at the same time that it outputs the ``dynf###.nc`` and ``phyf###.nc`` files. Setting ``WRITE_DOPOST: true`` turns off the separate ``run_post`` task in ``setup.py`` to avoid unnecessary computations. Valid values: ``True`` | ``False``

``ITASKS``: (Default: 1)
   Variable denoting the number of write tasks in the ``i`` direction in the current group. Used for inline post 2D decomposition. Setting this variable to a value greater than 1 will enable 2D decomposition.
   Note that 2D decomposition does not yet work with GNU compilers, so this value will be reset to 1 automatically when using GNU compilers (i.e., when ``COMPILER: gnu``).

.. _CompParams:

Computational Parameters
----------------------------

``LAYOUT_X``: (Default: ``'{{ LAYOUT_X }}'``)
   The number of :term:`MPI` tasks (processes) to use in the x direction of the regional grid when running the forecast model.

``LAYOUT_Y``: (Default: ``'{{ LAYOUT_Y }}'``)
   The number of :term:`MPI` tasks (processes) to use in the y direction of the regional grid when running the forecast model.

``BLOCKSIZE``: (Default: ``'{{ BLOCKSIZE }}'``)
   The amount of data that is passed into the cache at a time.

.. _WriteComp:

Write-Component (Quilting) Parameters
-----------------------------------------

.. note::
   The :term:`UPP` (called by the ``run_post`` task) cannot process output on the native grid types ("GFDLgrid" and "ESGgrid"), so output fields are interpolated to a **write component grid** before writing them to an output file. The output files written by the UFS Weather Model use an Earth System Modeling Framework (:term:`ESMF`) component, referred to as the **write component**. This model component is configured with settings in the ``model_configure`` file, as described in :ref:`Section 4.2.3 <ufs-wm:model_configureFile>` of the UFS Weather Model documentation. 

``QUILTING``: (Default: true)

   .. attention::
      The regional grid requires the use of the write component, so users generally should not change the default value for ``QUILTING``. 

   Flag that determines whether to use the write component for writing forecast output files to disk. When set to true, the forecast model will output files named ``dynf$HHH.nc`` and ``phyf$HHH.nc`` (where ``HHH`` is the 3-digit forecast hour) containing dynamics and physics fields, respectively, on the write-component grid. For example, the output files for the 3rd hour of the forecast would be ``dynf$003.nc`` and ``phyf$003.nc``. (The regridding from the native FV3-LAM grid to the write-component grid is done by the forecast model.) If ``QUILTING`` is set to false, then the output file names are ``fv3_history.nc`` and ``fv3_history2d.nc``, and they contain fields on the native grid. Although the UFS Weather Model can run without quilting, the regional grid requires the use of the write component. Therefore, QUILTING should be set to true when running the SRW App. If ``QUILTING`` is set to false, the ``run_post`` (meta)task cannot run because the :term:`UPP` code called by this task cannot process fields on the native grid. In that case, the ``RUN_POST`` (meta)task will be automatically removed from the Rocoto workflow XML. The :ref:`INLINE POST <InlinePost>` option also requires ``QUILTING`` to be set to true in the SRW App. Valid values: ``True`` | ``False``

``PRINT_ESMF``: (Default: false)
   Flag that determines whether to output extra (debugging) information from :term:`ESMF` routines. Note that the write component uses ESMF library routines to interpolate from the native forecast model grid to the user-specified output grid (which is defined in the model configuration file ``model_configure`` in the forecast run directory). Valid values: ``True`` | ``False``

``PE_MEMBER01``: (Default: ``'{{ LAYOUT_Y * LAYOUT_X + WRTCMP_write_groups * WRTCMP_write_tasks_per_group if QUILTING else LAYOUT_Y * LAYOUT_X}}'``)
   The number of MPI processes required by the forecast. When QUILTING is true, it is calculated as: 
   
   .. math::
      
      LAYOUT\_X * LAYOUT\_Y + WRTCMP\_write\_groups * WRTCMP\_write\_tasks\_per\_group 

``WRTCMP_write_groups``: (Default: "")
   The number of write groups (i.e., groups of :term:`MPI` tasks) to use in the write component. Each write group will write to one set of output files (a ``dynf${fhr}.nc`` and a ``phyf${fhr}.nc`` file, where ``${fhr}`` is the forecast hour). Each write group contains ``WRTCMP_write_tasks_per_group`` tasks. Usually, one write group is sufficient. This may need to be increased if the forecast is proceeding so quickly that a single write group cannot complete writing to its set of files before there is a need/request to start writing the next set of files at the next output time.

``WRTCMP_write_tasks_per_group``: (Default: "")
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

Aerosol Climatology Parameter
---------------------------------

``USE_MERRA_CLIMO``: (Default: ``'{{ workflow.CCPP_PHYS_SUITE == "FV3_GFS_v15_thompson_mynn_lam3km" or workflow.CCPP_PHYS_SUITE == "FV3_GFS_v17_p8" }}'``)
   Flag that determines whether :term:`MERRA2` aerosol climatology data and lookup tables for optics properties are obtained. This value should be set to false until MERRA2 climatology and Thompson microphysics are fully implemented in supported physics suites. Valid values: ``True`` | ``False``

Restart Parameters
--------------------
``DO_FCST_RESTART``: (Default: false)
   Flag to turn on/off restart capability of forecast task. 


RUN_POST Configuration Parameters
=====================================

Non-default parameters for the ``run_post`` task are set in the ``task_run_post:`` section of the ``config.yaml`` file. 

Basic Task Parameters
---------------------------------

For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task. 

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
   Time interval in minutes between the forecast model output files (only used if ``SUB_HOURLY_POST`` is set to true). If ``SUB_HOURLY_POST`` is set to true, this needs to be set to a valid integer between 1 and 59. Note that if ``SUB_HOURLY_POST`` is set to true, but ``DT_SUB_HOURLY_POST_MNTS`` is set to 0, ``SUB_HOURLY_POST`` will be reset to false in the experiment generation scripts (there will be an informational message in the log file to emphasize this). Valid values: ``0`` | ``1`` | ``2`` | ``3`` | ``4`` | ``5`` | ``6`` | ``10`` | ``12`` | ``15`` | ``20`` | ``30``

Customized Post Configuration Parameters
--------------------------------------------

Set parameters for customizing the :term:`UPP`.

``USE_CUSTOM_POST_CONFIG_FILE``: (Default: true)
   Flag that determines whether a user-provided custom configuration file should be used for post-processing the model data. If this is set to true, then the workflow will use the custom post-processing (:term:`UPP`) configuration file specified in ``CUSTOM_POST_CONFIG_FP``. Otherwise, a default configuration file provided in the UPP repository will be used. Valid values: ``True`` | ``False``

``CUSTOM_POST_CONFIG_FP``: (Default: ``"{{ user.SORCdir }}/ufs-weather-model/tests/parm/postxconfig-NT-fv3lam.txt"``)
   The full path to the custom post flat file, including filename, to be used for post-processing. This is only used if ``CUSTOM_POST_CONFIG_FILE`` is set to true.

``POST_OUTPUT_DOMAIN_NAME``: (Default: ``'{{ workflow.PREDEF_GRID_NAME }}'``)
   Domain name (in lowercase) used to construct the names of the output files generated by the :term:`UPP`. If using a predefined grid, ``POST_OUTPUT_DOMAIN_NAME`` defaults to ``PREDEF_GRID_NAME``. If using a custom grid, ``POST_OUTPUT_DOMAIN_NAME`` must be specified by the user. Note that this variable is first changed to lower case before being used to construct the file names.
   
   The post output files are named as follows:

   .. code-block:: console 
      
      ${NET_default}.tHHz.[var_name].f###.${POST_OUTPUT_DOMAIN_NAME}.grib2

``TESTBED_FIELDS_FN``: (Default: "")
   The file that lists grib2 fields to be extracted for testbed files. An empty string means no need to generate testbed files.

``NUMX``: (Default: 1)
   The number of ``i`` regions in a 2D decomposition. Each ``i`` row is distributed to ``NUMX`` ranks. Used for offline post 2D decomposition. Set ``NUMX`` to a value greater than 1 to enable 2D decomposition.
   Note that 2D decomposition does not yet work with GNU compilers, so this value will be reset to 1 automatically when using GNU compilers (i.e., when ``COMPILER: gnu``).

RUN_PRDGEN Configuration Parameters
=====================================

Non-default parameters for the ``run_prdgen`` task are set in the ``task_run_prdgen:`` section of the ``config.yaml`` file.

Basic Task Parameters
---------------------------------
For each workflow task, certain parameter values must be passed to the job scheduler (e.g., Slurm), which submits a job for the task.

``KMP_AFFINITY_RUN_PRDGEN``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``run_prdgen`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_RUN_PRDGEN``: (Default: 1) 
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_RUN_PRDGEN``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

``DO_PARALLEL_PRDGEN``: (Default: false)
   Flag that determines whether to use CFP to run the product generation job in parallel. CFP is a utility that allows the user to launch a number of small jobs across nodes/CPUs in one batch command. This option should be used with the ``RRFS_NA_3km`` grid, and ``PPN_RUN_PRDGEN`` should be set to 22.

``ADDNL_OUTPUT_GRIDS``: (Default: [])
   Set additional output grids for wgrib2 remapping, if any.  Space-separated list of strings, e.g., ( "130" "242" "clue").  Default is no additional grids. Current options as of 23 Apr 2021:

   * "130"   (CONUS 13.5 km)
   * "200"   (Puerto Rico 16 km)
   * "221"   (North America 32 km)
   * "242"   (Alaska 11.25 km)
   * "243"   (Pacific 0.4-deg)
   * "clue"  (NSSL/SPC 3-km CLUE grid for 2020/2021)
   * "hrrr"  (HRRR 3-km CONUS grid)
   * "hrrre" (HRRRE 3-km CONUS grid)
   * "rrfsak" (RRFS 3-km Alaska grid)
   * "hrrrak" (HRRR 3-km Alaska grid)

.. _PlotVars:

PLOT_ALLVARS Configuration Parameters
========================================

Typically, the following parameters must be set explicitly by the user in the ``task_plot_allvars:`` section of the configuration file (``config.yaml``) when executing the plotting tasks. 

``COMOUT_REF``: (Default: "")
   Path to the reference experiment's COMOUT directory. This is the directory where the GRIB2 files from post-processing are located. In *community* mode (i.e., when ``RUN_ENVIR: "community"``), this directory will correspond to the location in the experiment directory where the post-processed output can be found (e.g., ``$EXPTDIR/$DATE_FIRST_CYCL/postprd``). In *nco* mode, this directory should be set to the location of the ``COMOUT`` directory and end with ``$PDY/$cyc``. For more detail on *nco* standards and directory naming conventions, see :nco:`WCOSS Implementation Standards <ImplementationStandards.v11.0.0.pdf>` (particularly pp. 4-5). 
  
``PLOT_FCST_START``: (Default: 0)
   The starting forecast hour for the plotting task. For example, if a forecast starts at 18h/18z, this is considered the 0th forecast hour, so "starting forecast hour" should be 0, not 18. If a forecast starts at 18h/18z, but the user only wants plots from the 6th forecast hour on, "starting forecast hour" should be 6.

``PLOT_FCST_INC``: (Default: 3)
   Forecast hour increment for the plotting task. For example, if the user wants plots for each forecast hour, they should set ``PLOT_FCST_INC: 1``. If the user only wants plots for some of the output (e.g., every 6 hours), they should set ``PLOT_FCST_INC: 6``. 
  
``PLOT_FCST_END``: (Default: "")
   The last forecast hour for the plotting task. By default, ``PLOT_FCST_END`` is set to the same value as ``FCST_LEN_HRS``. For example, if a forecast runs for 24 hours, and the user wants plots for each available hour of forecast output, they do not need to set ``PLOT_FCST_END``, and it will automatically be set to 24. If the user only wants plots from the first 12 hours of the forecast, the "last forecast hour" should be 12 (i.e., ``PLOT_FCST_END: 12``).

``PLOT_DOMAINS``: (Default: ["conus"])
   Domains to plot. Currently supported options are ["conus"], ["regional"], or both (i.e., ["conus", "regional"]).

Air Quality Modeling (AQM) Parameters
======================================

This section includes parameters related to Air Quality Modeling (AQM) tasks. Note that AQM features are not currently supported for community use. 

NEXUS_EMISSION Configuration Parameters
-------------------------------------------------

Non-default parameters for the ``nexus_emission_*`` tasks are set in the ``task_nexus_emission:`` section of the ``config.yaml`` file. 

``PPN_NEXUS_EMISSION``: (Default: ``'{{ platform.NCORES_PER_NODE // OMP_NUM_THREADS_NEXUS_EMISSION }}'``)
   Processes per node for the ``nexus_emission_*`` tasks. 

``KMP_AFFINITY_NEXUS_EMISSION``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``nexus_emission_*`` tasks. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_NEXUS_EMISSION``: (Default: 2)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_NEXUS_EMISSION``: (Default: "1024m")
   Controls the size of the stack for threads created by the OpenMP implementation.

BIAS_CORRECTION_O3 Configuration Parameters
-------------------------------------------------

Non-default parameters for the ``bias_correction_o3`` tasks are set in the ``task_bias_correction_o3:`` section of the ``config.yaml`` file. 

``KMP_AFFINITY_BIAS_CORRECTION_O3``: "scatter"
   Intel Thread Affinity Interface for the ``bias_correction_o3`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_BIAS_CORRECTION_O3``: (Default: 32)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_BIAS_CORRECTION_O3``: (Default: "2056M")
   Controls the size of the stack for threads created by the OpenMP implementation.

BIAS_CORRECTION_PM25 Configuration Parameters
-------------------------------------------------

Non-default parameters for the ``bias_correction_pm25`` tasks are set in the ``task_bias_correction_pm25:`` section of the ``config.yaml`` file. 

``KMP_AFFINITY_BIAS_CORRECTION_PM25``: (Default: "scatter")
   Intel Thread Affinity Interface for the ``bias_correction_pm25`` task. See :ref:`this note <thread-affinity>` for more information on thread affinity.

``OMP_NUM_THREADS_BIAS_CORRECTION_PM25``: (Default: 32)
   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_BIAS_CORRECTION_PM25``: (Default: "2056M")
   Controls the size of the stack for threads created by the OpenMP implementation.

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

``NUM_ENS_MEMBERS``: (Default: 0)
   The number of ensemble members to run if ``DO_ENSEMBLE`` is set to true. This variable also controls the naming of the ensemble member directories. For example, if ``NUM_ENS_MEMBERS`` is set to 8, the member directories will be named *mem1, mem2, ..., mem8*. This variable is not used unless ``DO_ENSEMBLE`` is set to true.

``ENSMEM_NAMES``: (Default: ``'{% for m in range(NUM_ENS_MEMBERS) %}{{ "mem%03d, " % m }}{% endfor %}'``)
   A list of names for the ensemble member names following the format mem001, mem002, etc.
   
``FV3_NML_ENSMEM_FPS``: (Default: ``'{% for mem in ENSMEM_NAMES %}{{ [EXPTDIR, "%s_%s" % FV3_NML_FN, mem]|path_join }}{% endfor %}'``)
   Paths to the corresponding ensemble member namelists in the experiment directory

``ENS_TIME_LAG_HRS``: (Default: ``'[ {% for m in range([1,NUM_ENS_MEMBERS]|max) %} 0, {% endfor %} ]'``)
   Time lag (in hours) to use for each ensemble member. For a deterministic forecast, this is a one-element array. Default values of array elements are zero.


.. _stochastic-physics:

Stochastic Physics Parameters
----------------------------------

Set default ad-hoc stochastic physics options. For the most updated and detailed documentation of these parameters, see the :doc:`UFS Stochastic Physics Documentation <stochphys:namelist_options>`.

``NEW_LSCALE``: (Default: true) 
   Use correct formula for converting a spatial length scale into spectral space. 

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
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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
   SPP is currently only available for specific physics schemes used in the RAP/HRRR physics suite. Users need to be aware of which :term:`SDF` is chosen when turning this option on. Of the five supported physics suites, the full set of parameterizations can only be used with the ``FV3_HRRR`` option for ``CCPP_PHYS_SUITE``.

``DO_SPP``: (Default: false)
   Flag to turn SPP on or off. SPP perturbs parameters or variables with unknown or uncertain magnitudes within the physics code based on ranges provided by physics experts. Valid values: ``True`` | ``False``

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

``ISEED_SPP``: (Default: [ 4, 5, 6, 7, 8 ] )
   Seed for setting the random number sequence for the perturbation pattern. 

Land Surface Model (LSM) SPP
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Land surface perturbations can be applied to land model parameters and land model prognostic variables. The LSM scheme is intended to address errors in the land model and land-atmosphere interactions. LSM perturbations include soil moisture content (SMC) (volume fraction), vegetation fraction (VGF), albedo (ALB), salinity (SAL), emissivity (EMI), surface roughness (ZOL) (in cm), and soil temperature (STC). Perturbations to soil moisture content (SMC) are only applied at the first time step. Only five perturbations at a time can be applied currently, but all seven are shown below. In addition, only one unique *iseed* value is allowed at the moment, and it is used for each pattern.

The parameters below turn on SPP in Noah or RUC LSM (support for Noah MP is in progress). Please be aware of the :term:`SDF` that you choose if you wish to turn on Land Surface Model (LSM) SPP. SPP in LSM schemes is handled in the ``&nam_sfcperts`` namelist block instead of in ``&nam_sppperts``, where all other SPP is implemented. 

``DO_LSM_SPP``: (Default: false) 
   Turns on Land Surface Model (LSM) Stochastic Physics Parameterizations (SPP). When true, sets ``lndp_type=2``, which applies land perturbations to the selected parameters using a newer scheme designed for data assimilation (DA) ensemble spread. LSM SPP perturbs uncertain land surface fields ("smc" "vgf" "alb" "sal" "emi" "zol" "stc") based on recommendations from physics experts. Valid values: ``True`` | ``False``

.. attention::
   
   Only five perturbations at a time can be applied currently, but all seven are shown in the ``LSM_SPP_*`` variables below. 

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
   Number of cells to use for "blending" the external solution (obtained from the :term:`LBCs`) with the internal solution from the FV3LAM :term:`dycore`. Specifically, it refers to the number of rows into the computational domain that should be blended with the LBCs. Cells at which blending occurs are all within the boundary of the native grid; they don't involve the 4 cells outside the boundary where the LBCs are specified (which is a different :term:`halo`). Blending is necessary to smooth out waves generated due to mismatch between the external and internal solutions. To shut :term:`halo` blending off, set this variable to zero. 

Pressure Tendency Diagnostic
------------------------------
``PRINT_DIFF_PGR``: (Default: false)
   Option to turn on/off the pressure tendency diagnostic. 

Verification Parameters
==========================

Non-default parameters for verification tasks are set in the ``verification:`` section of the ``config.yaml`` file.

General Verification Parameters
---------------------------------

``METPLUS_VERBOSITY_LEVEL``: (Default: ``2``)
   Logging verbosity level used by METplus verification tools. Valid values: 0 to 5, with 0 quiet and 5 loud. 

Templates for Observation Files
---------------------------------

This section includes template variables for :term:`CCPA`, :term:`MRMS`, :term:`NOHRSC`, and :term:`NDAS` observation files.

``OBS_CCPA_APCP_FN_TEMPLATE``: (Default: ``'{valid?fmt=%Y%m%d}/ccpa.t{valid?fmt=%H}z.01h.hrap.conus.gb2'``)
   File name template for CCPA accumulated precipitation (APCP) observations. This template is used by the workflow tasks that call the METplus *PcpCombine* tool on CCPA obs to find the input observation files containing 1-hour APCP and then generate NetCDF files containing either 1-hour or greater than 1-hour APCP.

``OBS_NOHRSC_ASNOW_FN_TEMPLATE``: (Default: ``'{valid?fmt=%Y%m%d}/sfav2_CONUS_${ACCUM_HH}h_{valid?fmt=%Y%m%d%H}_grid184.grb2'``)
   File name template for NOHRSC snow observations.

``OBS_MRMS_REFC_FN_TEMPLATE``: (Default: ``'{valid?fmt=%Y%m%d}/MergedReflectivityQCComposite_00.50_{valid?fmt=%Y%m%d}-{valid?fmt=%H%M%S}.grib2'``)
   File name template for :term:`MRMS` reflectivity observations.

``OBS_MRMS_RETOP_FN_TEMPLATE``: (Default: ``'{valid?fmt=%Y%m%d}/EchoTop_18_00.50_{valid?fmt=%Y%m%d}-{valid?fmt=%H%M%S}.grib2'``)
   File name template for MRMS echo top observations.

``OBS_NDAS_ADPSFCorADPUPA_FN_TEMPLATE``: (Default: ``'prepbufr.ndas.{valid?fmt=%Y%m%d%H}'``)
   File name template for :term:`NDAS` surface and upper air observations. This template is used by the workflow tasks that call the METplus *Pb2nc* tool on NDAS obs to find the input observation files containing ADP surface (ADPSFC) or ADP upper air (ADPUPA) fields and then generate NetCDF versions of these files.

``OBS_NDAS_SFCorUPA_FN_METPROC_TEMPLATE``: (Default: ``'${OBS_NDAS_SFCorUPA_FN_TEMPLATE}.nc'``)
   File name template for NDAS surface and upper air observations after processing by MET's *pb2nc* tool (to change format to NetCDF).

``OBS_CCPA_APCP_FN_TEMPLATE_PCPCOMBINE_OUTPUT``: (Default: ``'${OBS_CCPA_APCP_FN_TEMPLATE}_a${ACCUM_HH}h.nc'``)
   Template used to specify the names of the output NetCDF observation files generated by the workflow verification tasks that call the METplus *PcpCombine* tool on CCPA observations. (These files will contain observations of accumulated precipitation [APCP], both for 1 hour and for > 1 hour accumulation periods, in NetCDF format.)

``OBS_NDAS_ADPSFCorADPUPA_FN_TEMPLATE_PB2NC_OUTPUT``: (Default: ``'${OBS_NDAS_ADPSFCorADPUPA_FN_TEMPLATE}.nc'``)
   Template used to specify the names of the output NetCDF observation files generated by the workflow verification tasks that call the METplus Pb2nc tool on NDAS observations.  (These files will contain obs ADPSFC or ADPUPA fields in NetCDF format.)



VX Forecast Model Name
------------------------

``VX_FCST_MODEL_NAME``: (Default: ``'{{ nco.NET_default }}.{{ task_run_post.POST_OUTPUT_DOMAIN_NAME }}'``)
   String that specifies a descriptive name for the model being verified. This is used in forming the names of the verification output files as well as in the contents of those files.

``VX_FIELDS``: (Default: [ "APCP", "REFC", "RETOP", "SFC", "UPA" ])
   The fields or groups of fields for which verification tasks will run. Because ``ASNOW`` is often not of interest in cases outside of winter, and because observation files are not located for retrospective cases on NOAA HPSS before March 2020, ``ASNOW`` is not included by default. ``"ASNOW"`` may be added to this list in order to include the related verification tasks in the workflow. Valid values: ``"APCP"`` | ``"REFC"`` | ``"RETOP"`` | ``"SFC"`` | ``"UPA"`` | ``"ASNOW"``
  
``VX_APCP_ACCUMS_HRS``: (Default: [ 1, 3, 6, 24 ])
   The accumulation periods (in hours) to consider for accumulated precipitation (APCP). If ``VX_FIELDS`` contains ``"APCP"``, then ``VX_APCP_ACCUMS_HRS`` must contain at least one element. If ``VX_FIELDS`` does not contain ``"APCP"``, ``VX_APCP_ACCUMS_HRS`` will be ignored. Valid values: ``1`` | ``3`` | ``6`` | ``24``

``VX_ASNOW_ACCUMS_HRS``: (Default: [ 6, 24 ])
   The accumulation periods (in hours) to consider for ``ASNOW`` (accumulated snowfall). If ``VX_FIELDS`` contains ``"ASNOW"``, then ``VX_ASNOW_ACCUMS_HRS`` must contain at least one element. If ``VX_FIELDS`` does not contain ``"ASNOW"``, ``VX_ASNOW_ACCUMS_HRS`` will be ignored. Valid values: ``6`` | ``24``

Verification (VX) Directories
------------------------------

``VX_FCST_INPUT_BASEDIR``: (Default: ``'{% if user.RUN_ENVIR == "nco" %}$COMOUT/../..{% else %}{{ workflow.EXPTDIR }}{% endif %}'``)
   Template for top-level directory containing forecast (but not obs) files that will be used as input into METplus for verification.

``VX_OUTPUT_BASEDIR``: (Default: ``'{% if user.RUN_ENVIR == "nco" %}$COMOUT/metout{% else %}{{ workflow.EXPTDIR }}{% endif %}'``)
   Template for top-level directory in which METplus will place its output.

``VX_NDIGITS_ENSMEM_NAMES``: 3
   Number of digits in the ensemble member names. This is a configurable variable to allow users to change its value (e.g., to go from "mem004" to "mem04") when using staged forecast files that do not use the same number of digits as the SRW App.

Verification (VX) File Name and Path Templates
------------------------------------------------

This section contains file name and path templates used in the verification (VX) tasks.

``FCST_SUBDIR_TEMPLATE``: (Default: ``'{% if user.RUN_ENVIR == "nco" %}${NET_default}.{init?fmt=%Y%m%d?shift=-${time_lag}}/{init?fmt=%H?shift=-${time_lag}}{% else %}{init?fmt=%Y%m%d%H?shift=-${time_lag}}{% if global.DO_ENSEMBLE %}/${ensmem_name}{% endif %}/postprd{% endif %}'``)
   A template for the subdirectory containing input forecast files for VX tasks.

``FCST_FN_TEMPLATE``: (Default: ``'${NET_default}.t{init?fmt=%H?shift=-${time_lag}}z{% if user.RUN_ENVIR == "nco" and global.DO_ENSEMBLE %}.${ensmem_name}{% endif %}.prslev.f{lead?fmt=%HHH?shift=${time_lag}}.${POST_OUTPUT_DOMAIN_NAME}.grib2'``)
   A template for the forecast file names used as input to verification tasks.

``FCST_FN_METPROC_TEMPLATE``: (Default: ``'${NET_default}.t{init?fmt=%H}z{% if user.RUN_ENVIR == "nco" and global.DO_ENSEMBLE %}.${ensmem_name}{% endif %}.prslev.f{lead?fmt=%HHH}.${POST_OUTPUT_DOMAIN_NAME}_${VAR}_a${ACCUM_HH}h.nc'``)
   A template for how to name the forecast files for accumulated precipitation (APCP) with greater than 1-hour accumulation (i.e., 3-, 6-, and 24-hour accumulations) after processing by ``PcpCombine``.

``NUM_MISSING_OBS_FILES_MAX``: (Default: 2)
   For verification tasks that need observational data, this specifies the maximum number of observation files that may be missing. If more than this number are missing, the verification task will error out.
   Note that this is a crude way of checking that there are enough observations to conduct verification since this number should probably depend on the field being verified, the time interval between observations, the length of the forecast, etc.  An alternative may be to specify the maximum allowed fraction of observation files that can be missing (i.e., the number missing divided by the number that are expected to exist).

``NUM_MISSING_FCST_FILES_MAX``: (Default: 0)
   For verification tasks that need forecast data, this specifies the maximum number of post-processed forecast files that may be missing. If more than this number are missing, the verification task will not be run.

Coupled AQM Configuration Parameters
=====================================

Non-default parameters for coupled Air Quality Modeling (AQM) tasks are set in the ``cpl_aqm_parm:`` section of the ``config.yaml`` file. Note that coupled AQM features are not currently supported for community use. 

``CPL_AQM``: (Default: false)
   Coupling flag for air quality modeling.

``DO_AQM_DUST``: (Default: true)
   Flag turning on/off AQM dust option in AQM_RC.

``DO_AQM_CANOPY``: (Default: false)
   Flag turning on/off AQM canopy option in AQM_RC.

``DO_AQM_PRODUCT``: (Default: true)
   Flag turning on/off AQM output products in AQM_RC.

``DO_AQM_CHEM_LBCS``: (Default: true)
   Add chemical LBCs to chemical LBCs.

``DO_AQM_GEFS_LBCS``: (Default: false)
   Add GEFS aerosol LBCs to chemical LBCs.
   
``DO_AQM_SAVE_AIRNOW_HIST``: (Default: false)
   Save bias-correction airnow training data.
   
``DO_AQM_SAVE_FIRE``: (Default: false)
   Archive fire emission file to HPSS.
   
``DCOMINbio_default``: (Default: "")
   Path to the directory containing AQM bio files.

``DCOMINdust_default``: (Default: "/path/to/dust/dir")
   Path to the directory containing AQM dust file.

``DCOMINcanopy_default``: (Default: "/path/to/canopy/dir")
   Path to the directory containing AQM canopy files.

``DCOMINfire_default``: (Default: "")
   Path to the directory containing AQM fire files.

``DCOMINchem_lbcs_default``: (Default: "")
   Path to the directory containing chemical LBC files.
   
``DCOMINgefs_default``: (Default: "")
   Path to the directory containing GEFS aerosol LBC files.

``DCOMINpt_src_default``: (Default: "/path/to/point/source/base/directory")
   Parent directory containing point source files.

``DCOMINairnow_default``: (Default: "/path/to/airnow/obaservation/data")
   Path to the directory containing AIRNOW observation data.

``COMINbicor``: (Default: "/path/to/historical/airnow/data/dir")
   Path of reading in historical training data for bias correction. 

``COMOUTbicor``: (Default: "/path/to/historical/airnow/data/dir")
   Path to save the current cycle's model output and AirNow observations as training data for future use. ``$COMINbicor`` and ``$COMOUTbicor`` can be distinguished by the ``${yyyy}${mm}${dd}`` under the same location.

``AQM_CONFIG_DIR``: (Default: "")
   Configuration directory for AQM.

``AQM_BIO_FILE``: (Default: "BEIS_SARC401.ncf")
   File name of AQM BIO file.

``AQM_DUST_FILE_PREFIX``: (Default: "FENGSHA_p8_10km_inputs")
   Prefix of AQM dust file.

``AQM_DUST_FILE_SUFFIX``: (Default: ".nc")
   Suffix and extension of AQM dust file.

``AQM_CANOPY_FILE_PREFIX``: (Default: "gfs.t12z.geo")
   File name of AQM canopy file.

``AQM_CANOPY_FILE_SUFFIX``: (Default: ".canopy_regrid.nc")
   Suffix and extension of AQM CANOPY file.

``AQM_FIRE_FILE_PREFIX``: (Default: "GBBEPx_C401GRID.emissions_v003")
   Prefix of AQM FIRE file.

``AQM_FIRE_FILE_SUFFIX``: (Default: ".nc")
   Suffix and extension of AQM FIRE file.

``AQM_FIRE_FILE_OFFSET_HRS``: (Default: 0)
   Time offset when retrieving fire emission data files. In a real-time run, the data files for :term:`ICs/LBCs` are not ready for use until the case starts. To resolve this issue, a real-time run uses the input data files in the previous cycle. For example, if the experiment run cycle starts at 12z, and ``AQM_FIRE_FILE_OFFSET_HRS: 6``, the fire emission data file from the previous cycle (06z) is used.

``AQM_FIRE_ARCHV_DIR``: (Default: "/path/to/archive/dir/for/RAVE/on/HPSS")
   Path to the archive directory for RAVE emission files on :term:`HPSS`.

``AQM_RC_FIRE_FREQUENCY``: (Default: "static")
   Fire frequency in ``aqm.rc``.

``AQM_RC_PRODUCT_FN``: (Default: "aqm.prod.nc")
   File name of AQM output products.

``AQM_RC_PRODUCT_FREQUENCY``: (Default: "hourly")
   Frequency of AQM output products.

``AQM_LBCS_FILES``: (Default: "gfs_bndy_chen_<MM>.tile7.000.nc")
   File name of chemical LBCs.

``AQM_GEFS_FILE_PREFIX``: (Default: "geaer")
   Prefix of AQM GEFS file ("geaer" or "gfs").

``AQM_GEFS_FILE_CYC``: (Default: "")
   Cycle of the GEFS aerosol LBC files only if it is fixed.

``NEXUS_INPUT_DIR``: (Default: "")
   Same as ``GRID_DIR`` but for the the air quality emission generation task. Should be blank for the default value specified in ``setup.sh``.

``NEXUS_FIX_DIR``: (Default: "")
   Directory containing ``grid_spec`` files as the input file of NEXUS.

``NEXUS_GRID_FN``: (Default: "grid_spec_GSD_HRRR_25km.nc")
   File name of the input ``grid_spec`` file of NEXUS.

``NUM_SPLIT_NEXUS``: (Default: 3)
   Number of split NEXUS emission tasks.

``NEXUS_GFS_SFC_OFFSET_HRS``: (Default: 0)
   Time offset when retrieving GFS surface data files.

``NEXUS_GFS_SFC_DIR``: (Default: "")
   Path to directory containing GFS surface data files. This is set to ``COMINgfs`` when ``DO_REAL_TIME=TRUE``. 

``NEXUS_GFS_SFC_ARCHV_DIR``:  (Default: "/NCEPPROD/hpssprod/runhistory")
   Path to archive directory for gfs surface files on HPSS.

Rocoto Parameters
===================

Non-default Rocoto workflow parameters are set in the ``rocoto:`` section of the ``config.yaml`` file. This section is structured as follows:

.. code-block:: console

   rocoto:
     attrs: ""
     cycledefs: ""
     entities: ""
     log: ""
     tasks:
       taskgroups: ""

Users are most likely to use the ``taskgroups:`` component of the ``rocoto:`` section to add or delete groups of tasks from the default list of tasks. For example, to add plotting tasks, users would add: 

.. code-block:: console

   rocoto:
     ...
     tasks:
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/plot.yaml"]|include }}'

See :numref:`Section %s <DefineWorkflow>` for more information on the components of the ``rocoto:`` section and how to define a Rocoto workflow. 



