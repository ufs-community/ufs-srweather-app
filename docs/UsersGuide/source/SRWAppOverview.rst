.. _SRWAppOverview:

========================================
Short-Range Weather Application Overview
========================================
The UFS Short-Range Weather Application (SRW App) is an umbrella repository that contains the tool
``checkout_externals`` to check out all of the components required for the application. Once the
build process is complete, all the files and executables necessary for a regional experiment are
located in the ``regional_workflow`` and ``bin`` directories, respectively, under the ``ufs-srweather-app``.
Users can utilize the pre-defined domains or build their own domain (details provided in TODO: link Chapter 7?).
In either case, users must create/modify the case-specific (``config.sh``) and/or grid-specific configuration
files (``set_predef_grid_params.sh``). The overall procedure is shown in :numref:`Figure %s <AppOverallProc>`,
with the scripts to generate and run the workflow shown in red. The steps are as follows:

#. Clone the UFS Short Range Weather Application from GitHub.
#. Check out the external components.
#. Set up the build environment and build the regional workflow system using ``cmake/make``.
#. Check the grid-specific configuration file ``set_predef_grid_param.sh``.
#. Modify the case-specific configuration file ``config.sh``.
#. Load the python environment for the regional workflow
#. Generate a regional workflow experiment.
#. Run the regional workflow repeatedly as needed.

Each step will be described in detail in the following sections.

.. _AppOverallProc:

.. figure:: _static/FV3LAM_wflow_overall.png

    *Overall procedure of the SRW App.*

.. _DownloadSRWApp:

Download from GitHub
====================
Retrieve the UFS Short Range Weather Application (SRW App) repository form the GitHub
``release/public-v1`` branch:

.. code-block:: console

   git clone -b release/public-v1 https://github.com/ufs-community/ufs-srweather-app.git
   cd ufs-srweather-app

The cloned repository contains the configuration files and sub-directories shown in
:numref:`Table %s <FilesAndSubDirs>`.

.. _FilesAndSubDirs:

.. table::  Files and sub-directories of SRW App.

   +--------------------------------+--------------------------------------------------------+
   | **File/directory Name**        | **Description**                                        |
   +================================+========================================================+
   | CMakeLists.txt                 | Main cmake file for SRW App                            |
   +--------------------------------+--------------------------------------------------------+
   | Externals.cfg                  | Hashes of the GitHub repositories/branches for the     |
   |                                | external components                                    |
   +--------------------------------+--------------------------------------------------------+
   | LICENSE.md                     | (empty)                                                |
   +--------------------------------+--------------------------------------------------------+
   | README.md                      | Quick User's Guide                                     |
   +--------------------------------+--------------------------------------------------------+
   | ufs_srweather_app_meta.h.in    | Meta information for SRW App which can be used by      |
   |                                | other packages                                         |
   +--------------------------------+--------------------------------------------------------+
   | ufs_srweather_app.settings.in  | SRW App configuration summary                          |
   +--------------------------------+--------------------------------------------------------+
   | docs                           | Release notes, documentation, User's Guide             |
   +--------------------------------+--------------------------------------------------------+
   | manage_externals               | Method for checking out external components            |
   +--------------------------------+--------------------------------------------------------+
   | src                            | Contains CMakeLIsts.txt; the external components       |
   |                                | will be cloned in this directory.                      |
   +--------------------------------+--------------------------------------------------------+

.. _CheckoutExternals:

External Components
===================
Check out the sub-modules such as regional_workflow, ufs_weather_model, ufs_utils, and emc_post for SRW App.

.. code-block:: console

   ./manage_externals/checkout_externals

This step will use the configuration ``Externals.cfg`` file in the ``ufs-srweather-app`` directory to
clone the specific hashes (version of codes) of the external components as listed in 
:numref:`Section %s <HierarchicalRepoStr>`. 

.. _BuildExecutables:

Building the Executables for the Application
============================================
Before building the executables, the build environment must be set up for your individual platform.
Instructions for loading the proper modules and/or setting the correct environment variables for
can be found in the ``docs/`` directory in files named ``README_<platform>_<compiler>.txt.`` For the
most part the commands in those files can be directly copy-pasted, but you may need to modify
certain variables such as the path to NCEP libraries for your individual platform.  The commands
are in the following files:

.. code-block:: console

   $ ls -l docs/
      -rw-rw-r-- 1 user ral 1228 Oct  9 10:09 README_cheyenne_intel.txt
      -rw-rw-r-- 1 user ral 1134 Oct  9 10:09 README_hera_intel.txt
      -rw-rw-r-- 1 user ral 1228 Oct  9 10:09 README_jet_intel.txt
      ...

The following steps will build the regional workflow system, including the pre-processing utilities,
forecast model, and post-processor:

.. code-block:: console

   make dir
   cd build
   cmake .. -DCMAKE_INSTALL_PREFIX=..
   make -j 8 

where ``-DCMAKE_INSTALL_PREFIX`` specifies the location in which the ``bin``, ``include``, ``lib``,
and ``share`` directories containing various components of the SRW App will be created, and its
recommended value ``..`` denotes one directory up from the build directory. In the next line for
the ``make`` call, ``-j 8`` means the parallel run with 8 threads. If this step is successful, the
executables listed in :numref:`Table %s <exec_description>` should be located in the
``ufs-srweather-app/bin`` directory.

.. _exec_description:

.. table::  Names and descriptions of the executables produced by the build step and used by the SRW App.

   +------------------------+---------------------------------------------------------------------------------+
   | **Executable Name**    | **Description**                                                                 |
   +========================+=================================================================================+
   | chgres_cube            | Reads in raw external model (global or regional) and surface climatology data   |
   |                        | to create initial and lateral boundary conditions for the UFS Weather Model     |
   +------------------------+---------------------------------------------------------------------------------+
   | filter_topo            | Filters topography based on resolution                                          |
   +------------------------+---------------------------------------------------------------------------------+
   | global_equiv_resol     | Calculates a global, uniform, cubed-sphere equivalent resolution for the        |
   |                        | regional Extended Schmidt Gnomonic (ESG) grid                                   |
   +------------------------+---------------------------------------------------------------------------------+
   | make_hgrid             | Creates GFDL regional grid                                                      |
   +------------------------+---------------------------------------------------------------------------------+
   | make_solo_mosaic       | Creates mosaic files with halos                                                 |
   +------------------------+---------------------------------------------------------------------------------+
   | ncep_post              | Post-processes the model output                                                 |
   +------------------------+---------------------------------------------------------------------------------+
   | NEMS.exe               | UFS Weather Model executable                                                    |
   +------------------------+---------------------------------------------------------------------------------+
   | orog                   | Generates orography, land mask, and gravity wave drag files from fixed files    |
   +------------------------+---------------------------------------------------------------------------------+
   | regional_esg_grid      | Generates an  ESG regional grid based on a user-defined namelist                |
   +------------------------+---------------------------------------------------------------------------------+
   | sfc_climo_gen          | Creates surface climatology fields from fixed files for use in ``chgres_cube``  |
   +------------------------+---------------------------------------------------------------------------------+
   | shave                  | Shaves the excess halo rows down to what is required for the LBCs in the        |
   |                        | orography and grid files                                                        |
   +------------------------+---------------------------------------------------------------------------------+
   | vcoord_gen             | Generate hybrid coordinate interface profiles                                   |
   +------------------------+---------------------------------------------------------------------------------+

.. _GridSpecificConfig:

Grid-specific Configuration
===========================

Some parameters depend on the characteristics of the grid such as grid resolution and domain size.
These include ``GFDL grid``, ``ESG grid``, and ``Input configuration`` as well as the variables
related to the write component (quilting). The SRW App officially supports three different predefined
grids as shown in :numref:`Table %s <PredefinedGrids>`. Their names should be found under
``valid_vals_PREDEF_GRID_NAME`` in the ``valid_param_vals`` script, and their grid-specific configuration
variables are specified in the ``set_predef_grid_params`` script. If users want to create a new domain,
they should put its name in the ``valid_param_vals`` script and the corresponding grid-specific
parameters in the ``set_predef_grid_params`` script.

.. _PredefinedGrids:

.. table::  Predefined grids in SRW App.

   +----------------------+-------------------+--------------------------------+
   | **Grid Name**        | **Grid Type**     | **Quilting (write component)** |
   +======================+===================+================================+
   | RRFS_CONUS_25km      | ESG grid          | lambert_conformal              |
   +----------------------+-------------------+--------------------------------+
   | RRFS_CONUS_13km      | ESG grid          | lambert_conformal              |
   +----------------------+-------------------+--------------------------------+
   | RRFS_CONUS_3km       | ESG grid          | lambert_conformal              |
   +----------------------+-------------------+--------------------------------+

Case-specific Configuration
===========================

.. _DefaultConfigSection:

Default configuration: ``config_default.sh``
--------------------------------------------
In generating a new workflow experiment, will be described in :numref:`Section %s <GeneratingWflowExpt>`,
the ``config_default.sh`` file is read in first, and assigns default values to the experiment
parameters. The configuration variables in the ``config_default.sh`` file are shown in
:numref:`Table %s <ConfigVarsDefault>`. Some of these default values are intentionally invalid
in order to ensure that the user assigns them valid values in the user-specified configuration
``config.sh`` file. The settings in ``config.sh`` will override the default settings. There is
usually no need for a user to modify the default configuration file. Note that the default
configuration file also contains documentation describing the experiment parameters.

.. _ConfigVarsDefault:

.. table::  Configuration variables specified in the config_default.sh script.

   +----------------------+------------------------------------------------------------+
   | **Group Name**       | **Configuration variables**                                |
   +======================+============================================================+
   | Experiment mode      | RUN_ENVIR                                                  | 
   +----------------------+------------------------------------------------------------+
   | Machine and queue    | MACHINE, ACCOUNT, SCHED, QUEUE_DEFAULT, QUEUE_DEFAULT_TAG, |
   |                      | QUEUE_HPSS, QUEUE_HPSS_TAG, QUEUE_FCST, QUEUE_FCST_TAG     |
   +----------------------+------------------------------------------------------------+
   | Cron                 | USE_CRON_TO_RELAUNCH, CRON_RELAUNCH_INTVL_MNTS             |
   +----------------------+------------------------------------------------------------+
   | Experiment Dir.      | EXPT_BASEDIR, EXPT_SUBDIR                                  |
   +----------------------+------------------------------------------------------------+
   | NCO mode             | COMINgfs, STMP, NET, envir, RUN, PTMP                      |
   +----------------------+------------------------------------------------------------+
   | Separator            | DOT_OR_USCORE                                              |
   +----------------------+------------------------------------------------------------+
   | File name            | EXPT_CONFIG_FN, RGNL_GRID_NML_FN, DATA_TABLE_FN,           |
   |                      | DIAG_TABLE_FN, FIELD_TABLE_FN, FV3_NML_YALM_CONFIG_FN,     |
   |                      | MODEL_CONFIG_FN, NEMS_CONFIG_FN, FV3_EXEC_FN,              |
   |                      | WFLOW_XML_FN, GLOBAL_VAR_DEFNS_FN,                         |
   |                      | EXTRN_MDL_ICS_VAR_DEFNS_FN, EXTRN_MDL_LBCS_VAR_DEFNS_FN,   |
   |                      | WFLOW_LAUNCH_SCRIPT_FN, WFLOW_LAUNCH_LOG_FN                |
   +----------------------+------------------------------------------------------------+
   | Forecast             | DATE_FIRST_CYCL, DATE_LAST_CYCL, CYCL_HRS, FCST_LEN_HRS    |
   +----------------------+------------------------------------------------------------+
   | IC/LBC               | EXTRN_MDL_NAME_ICS, EXTRN_MDL_NAME_LBCS,                   |
   |                      | LBC_SPEC_INTVL_HRS, FV3GFS_FILE_FMT_ICS,                   |
   |                      | FV3GFS_FILE_FMT_LBCS                                       |
   +----------------------+------------------------------------------------------------+
   | NOMADS               | NOMADS, NOMADS_file_type                                   |
   +----------------------+------------------------------------------------------------+
   | External model       | USE_USER_STAGED_EXTRN_FILES, EXTRN_MDL_SOURCE_BASEDRI_ICS, |
   |                      | EXTRN_MDL_FILES_ICS, EXTRN_MDL_SOURCE_BASEDIR_LBCS,        |
   |                      | EXTRN_MDL_FILES_LBCS                                       |
   +----------------------+------------------------------------------------------------+
   | CCPP                 | USE_CCPP, CCPP_PHYS_SUITE, OZONE_PARAM_NO_CCPP             |
   +----------------------+------------------------------------------------------------+
   | GRID                 | GRID_GEN_METHOD                                            |
   +----------------------+------------------------------------------------------------+
   | GFDL grid            | GFDLgrid_LON_T6_CTR, GFDLgrid_LAT_T6_CTR, GFDLgrid_RES,    |
   |                      | GFDLgrid_STRETCH_FAC, GFDLgrid_REFINE_RATIO,               |
   |                      | GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G,                        |
   |                      | GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G,                          |
   |                      | GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G,                        |
   |                      | GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G,                          |
   |                      | GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES                     |
   +----------------------+------------------------------------------------------------+
   | ESG grid             | ESGgrid_LON_CTR, ESGgrid_LAT_CTR, ESGgrid_DELX,            |
   |                      | ESGgrid_DELY, ESGgrid_NX, ESGgrid_NY,                      |
   |                      | ESGgrid_WIDE_HALO_WIDTH                                    |
   +----------------------+------------------------------------------------------------+
   | Input configuration  | DT_ATMOS, LAYOUT_X, LAYOUT_Y, BLOCKSIZE, QUILTING,         |
   |                      | PRINT_ESMF, WRTCMP_write_groups,                           |
   |                      | WRTCMP_write_tasks_per_group                               |
   +----------------------+------------------------------------------------------------+
   | Pre-existing grid    | PREDEF_GRID_NAME, EMC_GRID_NAME, PREEXISTING_DIR_METHOD,   |
   |                      | VERBOSE                                                    |
   +----------------------+------------------------------------------------------------+
   | Cycle-independent    | RUN_TASK_MAKE_GRID, GRID_DIR, RUN_TASK_MAKE_OROG,          |
   |                      | OROG_DIR, RUN_TASK_MAKE_SFC_CLIMO, SFC_CLIMO_DIR           |
   +----------------------+------------------------------------------------------------+
   | Surface climatology  | SFC_CLIMO_FIELDS, FIXgsm, TOPO_DIR, SFC_CLIMO_INPUT_DIR,   |
   |                      | FNGLAC, FNMXIC, FNTSFC, FNSNOC, FNZORC, FNAISC, FNSMCC,    |
   |                      | FNMSKH, FIXgsm_FILES_TO_COPY_TO_FIXam,                     |
   |                      | FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING,                    |
   |                      | FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING,                |
   |                      | CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING                      |
   +----------------------+------------------------------------------------------------+
   | Workflow task        | MAKE_GRID_TN, MAKE_OROG_TN, MAKE_SFC_CLIMO_TN,             |
   |                      | GET_EXTRN_ICS_TN, GET_EXTRN_LBCS_TN, MAKE_ICS_TN,          |
   |                      | MAKE_LBCS_TN, RUN_FCST_TN, RUN_POST_TN                     |
   +----------------------+------------------------------------------------------------+
   | NODE                 | NNODES_MAKE_GRID, NNODES_MAKE_OROG, NNODES_MAKE_SFC_CLIMO, |
   |                      | NNODES_GET_EXTRN_ICS, NNODES_GET_EXTRN_LBCS,               |
   |                      | NNODES_MAKE_ICS, NNODES_MAKE_LBCS, NNODES_RUN_FCST,        |
   |                      | NNODES_RUN_POST                                            |
   +----------------------+------------------------------------------------------------+
   | MPI processes        | PPN_MAKE_GRID, PPN_MAKE_OROG, PPN_MAKE_SFC_CLIMO,          |
   |                      | PPN_GET_EXTRN_ICS, PPN_GET_EXTRN_LBCS, PPN_MAKE_ICS,       |
   |                      | PPN_MAKE_LBCS, PPN_RUN_FCST, PPN_RUN_POST                  |
   +----------------------+------------------------------------------------------------+
   | Walltime             | WTIME_MAKE_GRID, WTIME_MAKE_OROG, WTIME_MAKE_SFC_CLIMO,    |
   |                      | WTIME_GET_EXTRN_ICS, WTIME_GET_EXTRN_LBCS, WTIME_MAKE_ICS, |
   |                      | WTIME_MAKE_LBCS, WTIME_RUN_FCST, WTIME_RUN_POST            |
   +----------------------+------------------------------------------------------------+
   | Maximum attempt      | MAXTRIES_MAKE_GRID, MAXTRIES_MAKE_OROG,                    |
   |                      | MAXTRIES_MAKE_SFC_CLIMO, MAXTRIES_GET_EXTRN_ICS,           |
   |                      | MAXTRIES_GET_EXTRN_LBCS, MAXTRIES_MAKE_ICS,                |
   |                      | MAXTRIES_MAKE_LBCS, MAXTRIES_RUN_FCST, MAXTRIES_RUN_POST   |
   +----------------------+------------------------------------------------------------+
   | Post configuration   | USE_CUSTOM_POST_CONFIG_FILE, CUSTOM_POST_CONFIG_FP         |
   +----------------------+------------------------------------------------------------+
   | Running ensembles    | DO_ENSEMBLE, NUM_ENS_MEMBERS                               |
   +----------------------+------------------------------------------------------------+
   | Stochastic physics   | DO_SHUM, DO_SPPT, DO_SKEB, SHUM_MAG, SHUM_LSCALE,          |
   |                      | SHUM_TSCALE, SHUM_INT, SPPT_MAG, SPPT_LSCALE, SPPT_TSCALE, |
   |                      | SPPT_INT, SKEB_MAG, SKEB_LSCALE, SKEP_TSCALE, SKEB_INT,    |
   |                      | SKEB_VDOF, USE_ZMTNBLCK                                    |
   +----------------------+------------------------------------------------------------+
   | Boundary blending    | HALO_BLEND                                                 |
   +----------------------+------------------------------------------------------------+
   | FVCOM                | USE_FVCOM, FVCOM_DIR, FVCOM_FILE                           |
   +----------------------+------------------------------------------------------------+
 
.. _UserSpecificConfig:

User-specific configuration: ``config.sh``
------------------------------------------
Before generating a workflow experiment, the user must create a ``config.sh`` file in the
``ufs-srweather-app/regional_workflow/ush`` directory by copying either of the example
configuration files: ``config.community.sh`` for the community mode or ``config.nco.sh`` for
the NCO mode. Note that the *community mode* is recommended in most cases and will be fully
supported for this release while the operational mode will be more exclusively used by NOAA/NCEP
Central Operations (NCO) and those in the NOAA/NCEP/Environmental Modeling Center (EMC) working
with NCO on pre-implementation testing. The values of the variables in the ``config.sh`` file
will replace those of the corresponding variables in the ``config_default.sh`` file.
:numref:`Table %s <ConfigCommunity>` shows the configuration variables, and their default and
new values in the ``config_default.sh`` and ``config.community.sh`` scripts, respectively.

.. note::

   The values of the configuration variables should be consistent with those in the
   ``valid_param_vals script``. In addition, various example configuration files can be
   found in the ``regional_workflow/tests/baseline_configs`` directory.

.. _ConfigCommunity:

.. table::   Configuration variables specified in the config.community.sh script.

   +-------------------------+----------------------+--------------------------------+
   | **Parameter**           | **Default Value**    | **New Value**                  |
   +=========================+======================+================================+
   | MACHINE                 | "BIG_COMPUTER"       | "hera"                         |
   +-------------------------+----------------------+--------------------------------+
   | ACCOUNT                 | "project_name"       | "an_account"                   |
   +-------------------------+----------------------+--------------------------------+
   | EXPT_SUBDIR             | ""                   | "test_community"               |
   +-------------------------+----------------------+--------------------------------+
   | QUEUE_DEFAULT           | "batch_queue"        | "batch"                        |
   +-------------------------+----------------------+--------------------------------+
   | QUEUE_HPSS              | "hpss_queue"         | "service"                      |
   +-------------------------+----------------------+--------------------------------+
   | QUEUE_FCST              | "production_queue"   | "batch"                        |
   +-------------------------+----------------------+--------------------------------+
   | RUN_ENVIR               | "nco"                | "community"                    |
   +-------------------------+----------------------+--------------------------------+
   | PREEXISTING_DIR_METHOD  | "delete"             | "rename"                       |
   +-------------------------+----------------------+--------------------------------+
   | PREDEF_GRID_NAME        | ""                   | "RRFS_CONUS_25km"              |
   +-------------------------+----------------------+--------------------------------+
   | CCPP_PHYS_SUITE         | "FV3_GSD_V0"         | "FV3_GFS_v15p2"                |
   +-------------------------+----------------------+--------------------------------+
   | FCST_LEN_HRS            | "24"                 | "6"                            |
   +-------------------------+----------------------+--------------------------------+
   | DATE_FIRST_CYCL         | "YYYYMMDD"           | "20190701"                     |
   +-------------------------+----------------------+--------------------------------+
   | DATE_LAST_CYCL          | "YYYYMMDD"           | "20190701"                     |
   +-------------------------+----------------------+--------------------------------+
   | CYCL_HRS                |  (“HH1” “HH2”)       | "00"                           |
   +-------------------------+----------------------+--------------------------------+

.. _LoadPythonEnv:

Python Environment for Workflow
===============================
It is necessary to load the appropriate Python environment for the workflow. The workflow
requires Python 3, with the packages 'PyYAML', 'Jinja2', and 'f90nml' available. This Python
environment has already been set up on Level 1 platforms, and can be activated in the following way:

On Cheyenne:


.. code-block:: console

   module load ncarenv
   ncar_pylib /glade/p/ral/jntp/UFS_CAM/ncar_pylib_20200427

Load the rocoto module:

.. code-block:: console

   module use -a /glade/p/ral/jntp/UFS_SRW_app/modules
   module load rocoto 


On Hera and Jet:

.. code-block:: console

   module use -a /contrib/miniconda3/modulefiles
   module load miniconda3
   conda activate regional_workflow
   module load rocoto

On Orion:

.. code-block:: console

   module use -a /apps/contrib/miniconda3-noaa-gsl/modulefiles
   module load miniconda3
   conda activate regional_workflow


.. _GeneratingWflowExpt:

Generating a Regional Workflow Experiment
=========================================

Steps to a New Workflow Experiment
----------------------------------
A workflow experiment is generated by running

.. code-block:: console

   generate_FV3LAM_wflow.sh

in the ``ufs-srweather-app/regional_workflow/ush`` directory. This is the all-in-one script for users
to set up their experiment with ease. :numref:`Figure %s <WorkflowGeneration>` shows the flowchart
of generating a workflow experiment. First, it sets up the configuration parameters by running
the ``setup.sh`` script. Second, it copies the time-independent (FIX) files and other necessary
input files such as ``data_table``, ``field_table``, ``nems.configure``, ``model_configure``,
and CCPP suite file from the templates directory to the experiment directory (``EXPT_SUBDIR``).
Third, it copies the weather model executable (``NEMS.exe``) from the ``bin`` directory to ``EXPT_SUBDIR``,
and creates the input namelist file ``input.nml`` for the weather model based on the ``input.nml.FV3``
file in the templates directory. Lastly, it creates the workflow XML file ``FV3LAM_wflow.xml``
that is executed when running the experiment with the Rocoto workflow manager.

.. _WorkflowGeneration:

.. figure:: _static/FV3regional_workflow_gen.png

    *Structure of workflow-experiment generation*

The ``setup.sh`` script reads three other configuration scripts: (1) ``config_default.sh``
(:numref:`Section %s <DefaultConfigSection>`), (2) ``config.sh`` (:numref:`Section %s <UserSpecificConfig>`),
and (3) ``set_predef_grid_params.sh`` (:numref:`Section %s <GridSpecificConfig>`). Note that these three
scripts are read in order of ``config_default.sh``, ``config.sh``, ``set_predef_grid_params.sh``.
If one parameter is specified separately in these scripts, it will be replaced by the value in the last call.  

.. _WorkflowTaskDescription:

Description of Workflow Tasks
-----------------------------
The flowchart of the workflow tasks that are specified in the ``FV3LAM_wflow.xml`` file are
illustrated in :numref:`Figure %s <WorkflowTasksFig>`, and each task is described in
:numref:`Table %s <WorkflowTasksTable>`. The first three pre-processing tasks; ``MAKE_GRID``,
``MAKE_OROG``, and ``MAKE_SFC_CLIMO`` are optional. If the pre-generated grid, orography, and
surface climatology fix files exist, these three task can be skipped by setting ``RUN_TASK_MAKE_GRID=”FALSE”``,
``RUN_TASK_MAKE_OROG=”FALSE”``, and ``RUN_TASK_MAKE_SFC_CLIMO=”FALSE”`` in the ``regional_workflow/ush/config.sh``
script before running the ``generate_FV3LAM_wflow.sh`` script. As shown in the figure, the ``FV3LAM_wflow.xml``
file runs the specific J-job scripts in the prescribed order (``regional_workflow/jobs/JREGIONAL_[task name]``)
when the ``launch_FV3LAM_wflow.sh`` is submitted. Each J-job task has its own source script named
``exregional_[task name].sh`` in the ``regional_workflow/scripts`` directory. Two database files
``FV3LAM_wflow.db`` and ``FV3LAM_wflow_lock.db`` are generated and updated by the rocoto calls.
There is usually no need for users to modify these files. To relaunch the workflow from scratch,
delete these files and then call the launch script (multiple times, as usual).

.. _WorkflowTasksFig:

.. figure:: _static/FV3LAM_wflow_flowchart.png

    *Flowchart of the workflow tasks*

.. _WorkflowTasksTable:

.. table::  Workflow tasks in SRW App

   +----------------------+------------------------------------------------------------+
   | **Workflow Task**    | **Task Description**                                       |
   +======================+============================================================+
   | make_grid            | Pre-processing task to generate regional grid files.  Can  |
   |                      | be run, at most, once per experiment.                      |
   +----------------------+------------------------------------------------------------+
   | make_orog            | Pre-processing task to generate orography files.  Can be   |
   |                      | run, at most, once per experiment.                         |
   +----------------------+------------------------------------------------------------+
   | make_sfc_climo       | Pre-processing task to generate surface climatology files. |
   |                      | Can be run, at most, once per experiment.                  |
   +----------------------+------------------------------------------------------------+
   | get_extrn_ics        | Cycle-specific task to obtain external data for the        |
   |                      | initial conditions                                         |
   +----------------------+------------------------------------------------------------+
   | get_extrn_lbcs       | Cycle-specific task to obtain external data for the        |
   |                      | lateral boundary (LB) conditions                           |
   +----------------------+------------------------------------------------------------+
   | make_ics             | Generate initial conditions from the external data         |
   +----------------------+------------------------------------------------------------+
   | make_lbcs            | Generate LB conditions from the external data              |
   +----------------------+------------------------------------------------------------+
   | run_fcst             | Run the forecast model (UFS weather model)                 |
   +----------------------+------------------------------------------------------------+
   | run_post             | Run the post-processing too (UPP)                          |
   +----------------------+------------------------------------------------------------+

Launch of Workflow
==================
There are two ways to launch the workflow using Rocoto: (1) using the ``launch_FV3LAM_wflow.sh``
script, and (2) manually calling the ``rocotorun`` command. Moreover, you can run the workflow
separately using stand-alone scripts.

Launch with the ``launch_FV3LAM_wflow.sh`` script
-------------------------------------------------
To launch the ``launch_FV3LAM_wflow.sh`` script, simply call it without any arguments as follows:

.. code-block:: console

   cd ${EXPTDIR}
   ./launch_FV3LAM_wflow.sh

This script creates a log file named ``log.launch_FV3LAM_wflow`` in the EXPTDIR directory
(described in :numref:`Section %s <ExperimentDirSection>`) or appends to if it already exists.
You can check the contents towards the end of this log file (e.g. last 30 lines) using the command:

.. code-block:: console

   tail -n 30 log.launch_FV3LAM_wflow

This command will print out the status of the tasks as follows:

.. code-block:: console

   CYCLE                    TASK                       JOBID        STATE   EXIT STATUS   TRIES  DURATION
   ======================================================================================================
   202006170000        make_grid         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000        make_orog                           -            -             -       -         -
   202006170000   make_sfc_climo                           -            -             -       -         -
   202006170000    get_extrn_ics         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000   get_extrn_lbcs         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000         make_ics                           -            -             -       -         -
   202006170000        make_lbcs                           -            -             -       -         -
   202006170000         run_fcst                           -            -             -       -         -
   202006170000      run_post_00                           -            -             -       -         -
   202006170000      run_post_01                           -            -             -       -         -
   202006170000      run_post_02                           -            -             -       -         -
   202006170000      run_post_03                           -            -             -       -         -
   202006170000      run_post_04                           -            -             -       -         -
   202006170000      run_post_05                           -            -             -       -         -
   202006170000      run_post_06                           -            -             -       -         -

   Summary of workflow status:
   ~~~~~~~~~~~~~~~~~~~~~~~~~~

     0 out of 1 cycles completed.
     Workflow status:  IN PROGRESS

Error messages for each task can be found in the ``EXPTDIR/log`` directory. In order to launch
more tasks in the workflow, you just need to call the launch script again as follows:

.. code-block:: console

   ./launch_FV3LAM_wflow

If everything goes smoothly, you will eventually get the following workflow status table as follows:

.. code-block:: console

   CYCLE                    TASK                       JOBID        STATE   EXIT STATUS   TRIES  DURATION
   ======================================================================================================
   202006170000        make_grid                     8854765    SUCCEEDED             0       1       6.0
   202006170000        make_orog                     8854809    SUCCEEDED             0       1      27.0
   202006170000   make_sfc_climo                     8854849    SUCCEEDED             0       1      36.0
   202006170000    get_extrn_ics                     8854763    SUCCEEDED             0       1      54.0
   202006170000   get_extrn_lbcs                     8854764    SUCCEEDED             0       1      61.0
   202006170000         make_ics                     8854914    SUCCEEDED             0       1     119.0
   202006170000        make_lbcs                     8854913    SUCCEEDED             0       1      98.0
   202006170000         run_fcst                     8854992    SUCCEEDED             0       1     655.0
   202006170000      run_post_00                     8855459    SUCCEEDED             0       1       6.0
   202006170000      run_post_01                     8855460    SUCCEEDED             0       1       6.0
   202006170000      run_post_02                     8855461    SUCCEEDED             0       1       6.0
   202006170000      run_post_03                     8855462    SUCCEEDED             0       1       6.0
   202006170000      run_post_04                     8855463    SUCCEEDED             0       1       6.0
   202006170000      run_post_05                     8855464    SUCCEEDED             0       1       6.0
   202006170000      run_post_06                     8855465    SUCCEEDED             0       1       6.0

If all the tasks are completed successfully, the workflow status in the log file will be set to “SUCCESS”.
Otherwise, the workflow status will be set to “FAILURE”.

Launch manually by calling the ``rocotorun`` command
----------------------------------------------------
To launch the workflow manually, the ``rocoto`` module should be loaded:

.. code-block:: console

   module load rocoto

Then, launch the workflow as follows:

.. code-block:: console

   cd ${EXPTDIR}
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10 

To check the status of the workflow, issue a ``rocotostat`` command as follows:

.. code-block:: console

   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Wait a few seconds and issue a second set of ``rocotorun`` and ``rocotostat`` commands:

.. code-block:: console

   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10 
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10


.. _RunUsingStandaloneScripts:

Run Workflow Using Stand-alone Scripts
--------------------------------------
The regional workflow has the capability to be run as standalone shell scripts if the
Rocoto software is not available on a given platform. These scripts are located in the
``ufs-srweather-app/regional_workflow/ush/wrappers`` directory. Each workflow task has
a wrapper script to set environment variables and run the job script.
 
Example batch-submit scripts for Hera (Slurm) and Cheyenne (PBS) are included: ``sq_job.sh``
and ``qsub_job.sh``. These examples set the build and run environment for Hera or Cheyenne,
so that run-time libraries match the compiled libraries (i.e. netcdf, mpi). Users may either
modify the one batch submit script as each task is submitted, or duplicate this batch wrapper
for their system settings, for each task. Alternatively, some batch systems allow users to
specify most of the settings on the command line (with the ``sbatch`` or ``qsub`` command,
for example). This piece will be unique to your system. The tasks run by the regional workflow
are shown in :numref:`Table %s <RegionalWflowTasks>`.  Tasks with the same stage level may
be run concurrently (no dependency).

.. _RegionalWflowTasks:

.. table::  List of tasks in the regional workflow in the order that they are executed.
            Scripts with the same stage number may be run simultaneously. The number of
            processors is typical for Cheyenne or Hera.

   +------------+------------------------+----------------+----------------------------+
   | **Stage/** | **Task Run Script**    | **Number of**  | **Wall clock time (H:MM)** |
   | **step**   |                        | **Processors** |                            |             
   +============+========================+================+============================+
   | 1          | run_get_ics.sh         | 1              | 0:20 (depends on HPSS vs   |
   |            |                        |                | FTP vs staged-on-disk)     |
   +------------+------------------------+----------------+----------------------------+
   | 1          | run_get_lbcs.sh        | 1              | 0:20 (depends on HPSS vs   |
   |            |                        |                | FTP vs staged-on-disk)     |
   +------------+------------------------+----------------+----------------------------+
   | 1          | run_make_grid.sh       | 24             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 2          | run_make_orog.sh       | 24             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 3          | run_make_sfc_climo.sh  | 48             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 4          | run_make_ics.sh        | 48             | 0:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 4          | run_make_lbcs.sh       | 48             | 0:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 5          | run_fcst.sh            | 48             | 2:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 6          | run_post.sh            | 48             | 0:25 (2 min per output     |
   |            |                        |                | forecast hour)             |
   +------------+------------------------+----------------+----------------------------+

The steps to run the standalone scripts are as follows:

#. Clone and build the ufs-srweather-app following the steps
   `here <https://github.com/ufs-community/ufs-srweather-app/wiki/Getting-Started>`_, or in
   :numref:`Sections %s <DownloadSRWApp>` to :numref:`Section %s <LoadPythonEnv>` above.

#. Generate an experiment configuration following the steps
   `here <https://github.com/ufs-community/ufs-srweather-app/wiki/Getting-Started>`_, or in
   :numref:`Section %s <GeneratingWflowExpt>` above.

#. ``cd`` into the experiment directory

#. SET the environment variable ``EXPTDIR`` for cshrc and bash, respectively:

   .. code-block:: console

      setenv EXPTDIR `pwd`
      export EXPTDIR=`pwd`

#. COPY the wrapper scripts from the workflow directory into your experiment directory:

   .. code-block:: console

      cp ufs-srweather-app/regional-workflow/ush/wrappers/* .

#. RUN each of the listed scripts in the order given.  Scripts with the same stage number
   may be run simultaneously.

    #. On most HPC systems, you will need to submit a batch job to run the multi-processor jobs.

    #. On some HPC systems, you can run the first two jobs (serial) on a login node/command-line

    #. Example scripts for Slurm (Hera) and PBS (Cheyenne) are provided.  These will need to be adapted to your system.

    #. This batch-submit script is hard-coded per task, so will need to be modified or copied to run each task.
 
Check the batch script output file in your experiment directory for a “success” message near the end of the file.

