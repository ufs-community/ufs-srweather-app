.. _ConfigWorkflow:

==================================================================
Configuring the Workflow: ``config.sh`` and ``config_defaults.sh``		
==================================================================
To create the experiment directory and workflow when running the SRW App, the user must create an experiment configuration file named ``config.sh``.  This file contains experiment-specific information, such as dates, external model data, directories, and other relevant settings.  To help the user, two sample configuration files have been included in the ``regional_workflow`` repository’s ``ush`` directory: ``config.community.sh`` and ``config.nco.sh``.  The first is for running experiments in community mode (``RUN_ENVIR`` set to “community”; see below), and the second is for running experiments in “nco” mode (``RUN_ENVIR`` set to “nco”).  Note that for this release, only “community” mode is supported.  These files can be used as the starting point from which to generate a variety of experiment configurations in which to run the SRW App.

There is an extensive list of experiment parameters that a user can set when configuring the experiment.  Not all of these need to be explicitly set by the user in ``config.sh``.  In the case that a user does not define an entry in the ``config.sh`` script, either its value in ``config_defaults.sh`` will be used, or it will be reset depending on other parameters, e.g. the platform on which the experiment will be run (specified by ``MACHINE``). Note that ``config_defaults.sh`` contains the full list of experiment parameters that a user may set in ``config.sh`` (i.e. the user cannot set parameters in config.sh that are not initialized in ``config_defaults.sh``).

The following is a list of the parameters in the ``config_defaults.sh`` file.  For each parameter, the default value and a brief description is given.  In addition, any relevant information on features and settings supported or unsupported in this release is specified.

Platform Environment
====================
``RUN_ENVIR``: (Default: “nco”)
   This variable determines the mode that the workflow will run in.  The user can choose between two modes: “nco” and “community.”  The “nco” mode uses a directory structure that mimics what is used in operations at NOAA/NCEP Central Operations (NCO) and by those in the NOAA/NCEP/Environmental Modeling Center (EMC) working with NCO on pre-implementation testing.  Specifics of the conventions used in “nco” mode can be found in the following WCOSS Implementation Standards document:

   | NCEP Central Operations
   | WCOSS Implementation Standards
   | April 17, 2019
   | Version 10.2.0

   Setting ``RUN_ENVIR`` to “community” will use the standard directory structure and variable naming convention and is recommended in most cases for users who are not planning to implement their code into operations at NCO.

``MACHINE``: (Default: “BIG_COMPUTER”)
   The machine (a.k.a. platform) on which the workflow will run.  Currently supported platforms include "WCOSS_CRAY," "WCOSS_DELL_P3," "HERA," "ORION," "JET," "ODIN," "CHEYENNE," "STAMPEDE,” “GAEA,” “MACOS,” and “LINUX."

``ACCOUNT``: (Default: “project_name”)
   The account under which to submit jobs to the queue on the specified ``MACHINE``.

``WORKFLOW_MANAGER``: (Default: “none”)
   The workflow manager to use (e.g. “ROCOTO”). This is set to "none" by default, but if the machine name is set to a platform that supports Rocoto, this will be overwritten and set to "ROCOTO."

``SCHED``: (Default: “”)
   The job scheduler to use (e.g. slurm) on the specified ``MACHINE``.  Set this to an empty string in order for the experiment generation script to set it automatically depending on the machine the workflow is running on.  Currently, supported schedulers include "slurm," "pbspro," "lsf," "lsfcray," and "none".

``PARTITION_DEFAULT``: (Default: “”)
   If using the slurm job scheduler (i.e. if ``SCHED`` is set to "slurm"), the default partition to which to submit workflow tasks.  If a task does not have a specific variable that specifies the partition to which it will be submitted (e.g. ``PARTITION_HPSS``, ``PARTITION_FCST``; see below), it will be submitted to the partition specified by this variable.  If this is not set or is set to an empty string, it will be (re)set to a machine-dependent value.  This is not used if ``SCHED`` is not set to "slurm."

``CLUSTERS_DEFAULT``: (Default: “”)
   If using the slurm job scheduler (i.e. if ``SCHED`` is set to "slurm"), the default clusters to which to submit workflow tasks.  If a task does not have a specific variable that specifies the partition to which it will be submitted (e.g. ``CLUSTERS_HPSS``, ``CLUSTERS_FCST``; see below), it will be submitted to the clusters specified by this variable.  If this is not set or is set to an empty string, it will be (re)set to a machine-dependent value.  This is not used if ``SCHED`` is not set to "slurm."

``QUEUE_DEFAULT``: (Default: “”)
   The default queue or QOS (if using the slurm job scheduler, where QOS is Quality of Service) to which workflow tasks are submitted.  If a task does not have a specific variable that specifies the queue to which it will be submitted (e.g. ``QUEUE_HPSS``, ``QUEUE_FCST``; see below), it will be submitted to the queue specified by this variable.  If this is not set or is set to an empty string, it will be (re)set to a machine-dependent value.

``PARTITION_HPSS``: (Default: “”)
   If using the slurm job scheduler (i.e. if ``SCHED`` is set to "slurm"), the partition to which the tasks that get or create links to external model files [which are needed to generate initial conditions (ICs) and lateral boundary conditions (LBCs)] are submitted.  If this is not set or is set to an empty string, it will be (re)set to a machine-dependent value.  This is not used if ``SCHED`` is not set to "slurm."

``CLUSTERS_HPSS``: (Default: “”)
   If using the slurm job scheduler (i.e. if ``SCHED`` is set to "slurm"), the clusters to which the tasks that get or create links to external model files [which are needed to generate initial conditions (ICs) and lateral boundary conditions (LBCs)] are submitted.  If this is not set or is set to an empty string, it will be (re)set to a machine-dependent value.  This is not used if ``SCHED`` is not set to "slurm."

``QUEUE_HPSS``: (Default: “”)
   The queue or QOS to which the tasks that get or create links to external model files are submitted.  If this is not set or is set to an empty string, it will be (re)set to a machine-dependent value.

``PARTITION_FCST``: (Default: “”)
   If using the slurm job scheduler (i.e. if ``SCHED`` is set to "slurm"), the partition to which the task that runs forecasts is submitted.  If this is not set or set to an empty string, it will be (re)set to a machine-dependent value.  This is not used if ``SCHED`` is not set to "slurm."

``CLUSTERS_FCST``: (Default: “”)
   If using the slurm job scheduler (i.e. if ``SCHED`` is set to "slurm"), the clusters to which the task that runs forecasts is submitted.  If this is not set or set to an empty string, it will be (re)set to a machine-dependent value.  This is not used if ``SCHED`` is not set to "slurm."

``QUEUE_FCST``: (Default: “”)
   The queue or QOS to which the task that runs a forecast is submitted.  If this is not set or set to an empty string, it will be (re)set to a machine-dependent value.

Parameters for Running Without a Workflow Manager
=================================================
These settings control run commands for platforms without a workflow manager.  Values will be ignored unless ``WORKFLOW_MANAGER="none"``.

``RUN_CMD_UTILS``: (Default: "mpirun -np 1")
   The run command for pre-processing utilities (shave, orog, sfc_climo_gen, etc.).  This can be left blank for smaller domains, in which case the executables will run without MPI.

``RUN_CMD_FCST``: (Default: "mpirun -np \${PE_MEMBER01}")
   The run command for the model forecast step. This will be appended to the end of the variable definitions file ("var_defns.sh").

``RUN_CMD_POST``: (Default: "mpirun -np 1")
   The run command for post-processing (UPP). Can be left blank for smaller domains, in which case UPP will run without MPI.

Cron-Associated Parameters
==========================
``USE_CRON_TO_RELAUNCH``: (Default: “FALSE”)
   Flag that determines whether or not a line is added to the user's cron table that calls the experiment launch script every ``CRON_RELAUNCH_INTVL_MNTS`` minutes.

``CRON_RELAUNCH_INTVL_MNTS``: (Default: “03”)
   The interval (in minutes) between successive calls of the experiment launch script by a cron job to (re)launch the experiment (so that the workflow for the experiment kicks off where it left off).  This is used only if ``USE_CRON_TO_RELAUNCH`` is set to “TRUE”.

Directory Parameters
====================
``EXPT_BASEDIR``: (Default: “”)
   The base directory in which the experiment directory will be created.  If this is not specified or if it is set to an empty string, it will default to ``${HOMErrfs}/../../expt_dirs``, where ``${HOMErrfs}`` contains the full path to the ``regional_workflow`` directory.

``EXPT_SUBDIR``: (Default: “”)
   The name that the experiment directory (without the full path) will have.  The full path to the experiment directory, which will be contained in the variable ``EXPTDIR``, will be:

   .. code-block:: console

      EXPTDIR="${EXPT_BASEDIR}/${EXPT_SUBDIR}"

   This parameter cannot be left as a null string.


NCO Mode Parameters
===================
These variables apply only when using NCO mode (i.e. when ``RUN_ENVIR`` is set to "nco").

``COMINgfs``: (Default: "/base/path/of/directory/containing/gfs/input/files")
   The beginning portion of the directory which contains files generated by the external model that the initial and lateral boundary condition generation tasks need in order to create initial and boundary condition files for a given cycle on the native FV3-LAM grid.  For a cycle that starts on the date specified by the variable YYYYMMDD (consisting of the 4-digit year followed by the 2-digit month followed by the 2-digit day of the month) and hour specified by the variable HH (consisting of the 2-digit hour-of-day), the directory in which the workflow will look for the external model files is:

   .. code-block:: console

      $COMINgfs/gfs.$yyyymmdd/$hh

``STMP``: (Default: "/base/path/of/directory/containing/model/input/and/raw/output/files")
   The beginning portion of the directory that will contain cycle-dependent model input files, symlinks to cycle-independent input files, and raw (i.e. before post-processing) forecast output files for a given cycle.  For a cycle that starts on the date specified by YYYYMMDD and hour specified by HH (where YYYYMMDD and HH are as described above) [so that the cycle date (cdate) is given by ``cdate="${YYYYMMDD}${HH}"``], the directory in which the aforementioned files will be located is:

   .. code-block:: console

      $STMP/tmpnwprd/$RUN/$cdate

``NET, envir, RUN``:
   Variables used in forming the path to the directory that will contain the output files from the post-processor (UPP) for a given cycle (see definition of ``PTMP`` below).  These are defined in the WCOSS Implementation Standards document as follows:

   ``NET``: (Default: “rrfs”)
      Model name (first level of com directory structure)

   ``envir``: (Default: “para”)
      Set to "test" during the initial testing phase, "para" when running in parallel (on a schedule), and "prod" in production.

   ``RUN``: (Default: “experiment_name”)
      Name of model run (third level of com directory structure).

``PTMP``: (Default: "/base/path/of/directory/containing/postprocessed/output/files")
   The beginning portion of the directory that will contain the output files from the post-processor (UPP) for a given cycle.  For a cycle that starts on the date specified by YYYYMMDD and hour specified by HH (where YYYYMMDD and HH are as described above), the directory in which the UPP output files will be placed will be:
 
   .. code-block:: console

      $PTMP/com/$NET/$envir/$RUN.$yyyymmdd/$hh

Pre-Processing File Separator Parameters
========================================
``DOT_OR_USCORE``: (Default: "_")
   This variable sets the separator character(s) to use in the names of the grid, mosaic, and orography fixed files.  Ideally, the same separator should be used in the names of these fixed files as the surface climatology fixed files.

File Name Parameters
====================
``EXPT_CONFIG_FN``: (Default: "config.sh")
   Name of the user-specified configuration file for the forecast experiment.

``RGNL_GRID_NML_FN``: (Default: "regional_grid.nml")
   Name of the file containing Fortran namelist settings for the code that generates an "ESGgrid" type of regional grid.

``FV3_NML_BASE_SUITE_FN``: (Default: "input.nml.FV3")
   Name of the Fortran namelist file containing the forecast model's base suite namelist, i.e. the portion of the namelist that is common to all physics suites.

``FV3_NML_YAML_CONFIG_FN``: (Default: "FV3.input.yml")
   Name of YAML configuration file containing the forecast model's namelist settings for various physics suites.

``DIAG_TABLE_FN``: (Default: “diag_table”)
   Name of the file that specifies the fields that the forecast model will output.

``FIELD_TABLE_FN``: (Default: “field_table”)
   Name of the file that specifies the tracers that the forecast model will read in from the IC/LBC files.

``DATA_TABLE_FN``: (Default: “data_table”)
   The name of the file containing the data table read in by the forecast model.

``MODEL_CONFIG_FN``: (Default: “model_configure”)
   The name of the file containing settings and configurations for the NUOPC/ESMF component.

``NEMS_CONFIG_FN``: (Default: “nems.configure”)
   The name of the file containing information about the various NEMS components and their run sequence.

``FV3_EXEC_FN``: (Default: “NEMS.exe”)
   Name of the forecast model executable in the executables directory (``EXECDIR``; set during experiment generation).

``WFLOW_XML_FN``: (Default: “FV3LAM_wflow.xml”)
   Name of the Rocoto workflow XML file that the experiment generation script creates and that defines the workflow for the experiment.

``GLOBAL_VAR_DEFNS_FN``: (Default: “var_defns.sh”)
   Name of the file (a shell script) containing the definitions of the primary experiment variables (parameters) defined in this default configuration script and in config.sh as well as secondary experiment variables generated by the experiment generation script.  This file is sourced by many scripts (e.g. the J-job scripts corresponding to each workflow task) in order to make all the experiment variables available in those scripts.

``EXTRN_MDL_ICS_VAR_DEFNS_FN``: (Default: “extrn_mdl_ics_var_defns.sh")
   Name of the file (a shell script) containing the definitions of variables associated with the external model from which ICs are generated.  This file is created by the ``GET_EXTRN_ICS_TN`` task because the values of the variables it contains are not known before this task runs.  The file is then sourced by the ``MAKE_ICS_TN`` task.

``EXTRN_MDL_LBCS_VAR_DEFNS_FN``: (Default: “extrn_mdl_lbcs_var_defns.sh")
   Name of the file (a shell script) containing the definitions of variables associated with the external model from which LBCs are generated.  This file is created by the ``GET_EXTRN_LBCS_TN`` task because the values of the variables it contains are not known before this task runs.  The file is then sourced by the ``MAKE_ICS_TN`` task.

``WFLOW_LAUNCH_SCRIPT_FN``: (Default: “launch_FV3LAM_wflow.sh")
   Name of the script that can be used to (re)launch the experiment's Rocoto workflow.

``WFLOW_LAUNCH_LOG_FN``: (Default: “log.launch_FV3LAM_wflow”)
   Name of the log file that contains the output from successive calls to the workflow launch script (``WFLOW_LAUNCH_SCRIPT_FN``).

Forecast Parameters
===================
``DATE_FIRST_CYCL``: (Default: “YYYYMMDD”)
   Starting date of the first forecast in the set of forecasts to run.  Format is "YYYYMMDD".  Note that this does not include the hour-of-day.

``DATE_LAST_CYCL``: (Default: “YYYYMMDD”)
   Starting date of the last forecast in the set of forecasts to run.  Format is "YYYYMMDD".  Note that this does not include the hour-of-day.

``CYCL_HRS``: (Default: ( “HH1” “HH2” ))
   An array containing the hours of the day at which to launch forecasts.  Forecasts are launched at these hours on each day from ``DATE_FIRST_CYCL`` to ``DATE_LAST_CYCL``, inclusive.  Each element of this array must be a two-digit string representing an integer that is less than or equal to 23, e.g. "00", "03", "12", "23".

``FCST_LEN_HRS``: (Default: “24”)
   The length of each forecast, in integer hours.

Initial and Lateral Boundary Condition Generation Parameters
============================================================
``EXTRN_MDL_NAME_ICS``: (Default: “FV3GFS”)
   The name of the external model that will provide fields from which initial condition (IC) files, surface files, and 0-th hour boundary condition files will be generated for input into the forecast model.

``EXTRN_MDL_NAME_LBCS``: (Default: “FV3GFS”)
   The name of the external model that will provide fields from which lateral boundary condition (LBC) files (except for the 0-th hour LBC file) will be generated for input into the forecast model.

``LBC_SPEC_INTVL_HRS``: (Default: “6”)
   The interval (in integer hours) at which LBC files will be generated, referred to as the boundary specification interval.  Note that the model specified in ``EXTRN_MDL_NAME_LBCS`` must have data available at a frequency greater than or equal to that implied by ``LBC_SPEC_INTVL_HRS``.  For example, if ``LBC_SPEC_INTVL_HRS`` is set to 6, then the model must have data available at least every 6 hours.  It is up to the user to ensure that this is the case.

``FV3GFS_FILE_FMT_ICS``: (Default: “nemsio”)
   If using the FV3GFS model as the source of the ICs (i.e. if ``EXTRN_MDL_NAME_ICS`` is set to "FV3GFS"), this variable specifies the format of the model files to use when generating the ICs.

``FV3GFS_FILE_FMT_LBCS``: (Default: “nemsio”)
   If using the FV3GFS model as the source of the LBCs (i.e. if ``EXTRN_MDL_NAME_LBCS`` is set to "FV3GFS"), this variable specifies the format of the model files to use when generating the LBCs.

User-Staged External Model Directory and File Parameters
========================================================
``USE_USER_STAGED_EXTRN_FILES``: (Default: “False”)
   Flag that determines whether or not the workflow will look for the external model files needed for generating ICs and LBCs in user-specified directories (as opposed to fetching them from mass storage like NOAA HPSS).

``EXTRN_MDL_SOURCE_BASEDIR_ICS``: (Default: “/base/dir/containing/user/staged/extrn/mdl/files/for/ICs")
   Directory in which to look for external model files for generating ICs. If ``USE_USER_STAGED_EXTRN_FILES`` is set to "TRUE", the workflow looks in this directory (specifically, in a subdirectory under this directory named "YYYYMMDDHH" consisting of the starting date and cycle hour of the forecast, where YYYY is the 4-digit year, MM the 2-digit month, DD the 2-digit day of the month, and HH the 2-digit hour of the day) for the external model files specified by the array ``EXTRN_MDL_FILES_ICS`` (these files will be used to generate the ICs on the native FV3-LAM grid).  This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to "FALSE".
 
``EXTRN_MDL_FILES_ICS``: (Default: "ICS_file1” “ICS_file2” “...”)
   Array containing the names of the files to search for in the directory specified by ``EXTRN_MDL_SOURCE_BASEDIR_ICS``.  This variable is not used if ``USE_USER_STAGED_EXTRN_FILES`` is set to "FALSE".

``EXTRN_MDL_SOURCE_BASEDIR_LBCS``: (Default: "/base/dir/containing/user/staged/extrn/mdl/files/for/ICs")
   Analogous to ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` but for LBCs instead of ICs.

``EXTRN_MDL_FILES_LBCS``: (Default: " “LBCS_file1” “LBCS_file2” “...”)
   Analogous to ``EXTRN_MDL_FILES_ICS`` but for LBCs instead of ICs.

CCPP Parameter
==============
``CCPP_PHYS_SUITE``: (Default: "FV3_GFS_v15p2")
   The CCPP (Common Community Physics Package) physics suite to use for the forecast(s).  The choice of physics suite determines the forecast model's namelist file, the diagnostics table file, the field table file, and the XML physics suite definition file that are staged in the experiment directory or the cycle directories under it.  Current supported settings for this parameter are “FV3_GFS_v15p2” and “FV3_RRFS_v1alpha”.

.. include:: ConfigParameters.inc
