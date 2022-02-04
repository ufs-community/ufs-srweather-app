.. _CodeReposAndDirs:

=========================================
Code Repositories and Directory Structure
=========================================
This chapter describes the code repositories that comprise the UFS SRW Application,
without describing any of the components in detail.

.. _HierarchicalRepoStr:

Hierarchical Repository Structure
=================================
The umbrella repository for the UFS SRW Application is named ufs-srweather-app and is
available on GitHub at https://github.com/ufs-community/ufs-srweather-app. An umbrella
repository is defined as a repository that houses external code, called "externals," from
additional repositories. The UFS SRW Application includes the ``manage_externals`` tools 
along with a configuration file called ``Externals.cfg``, which describes the external 
repositories associated with this umbrella repo (see :numref:`Table %s <top_level_repos>`).

.. _top_level_repos:

.. table::  List of top-level repositories that comprise the UFS SRW Application.

   +---------------------------------+---------------------------------------------------------+
   | **Repository Description**      | **Authoritative repository URL**                        |
   +=================================+=========================================================+
   | Umbrella repository for the UFS | https://github.com/ufs-community/ufs-srweather-app      |
   | Short-Range Weather Application |                                                         |
   +---------------------------------+---------------------------------------------------------+
   | Repository for                  | https://github.com/ufs-community/ufs-weather-model      |
   | the UFS Weather Model           |                                                         |
   +---------------------------------+---------------------------------------------------------+
   | Repository for the regional     | https://github.com/ufs-community/regional_workflow      |
   | workflow                        |                                                         |
   +---------------------------------+---------------------------------------------------------+
   | Repository for UFS utilities,   | https://github.com/ufs-community/UFS_UTILS              |
   | including pre-processing,       |                                                         |
   | chgres_cube, and more           |                                                         |
   +---------------------------------+---------------------------------------------------------+
   | Repository for the Unified Post | https://github.com/NOAA-EMC/UPP                         |
   | Processor (UPP)                 |                                                         |
   +---------------------------------+---------------------------------------------------------+

The UFS Weather Model contains a number of sub-repositories used by the model as 
documented `here <https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/CodeOverview.html>`_.

Note that the prerequisite libraries (including NCEP Libraries and external libraries) are not
included in the UFS SRW Application repository. The source code for these components resides in
the repositories `NCEPLIBS <https://github.com/NOAA-EMC/NCEPLIBS>`_ and `NCEPLIBS-external
<https://github.com/NOAA-EMC/NCEPLIBS-external>`_. 

These external components are already built on the preconfigured platforms listed `here 
<https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_.
However, they must be cloned and built on other platforms according to the instructions provided
in the wiki pages of those repositories: https://github.com/NOAA-EMC/NCEPLIBS/wiki and
https://github.com/NOAA-EMC/NCEPLIBS-external/wiki.

.. _TopLevelDirStructure:

Directory Structure
===================
The directory structure for the SRW Application is determined by the ``local_path`` settings in
the ``Externals.cfg`` file, which is in the directory where the umbrella repository has
been cloned. After ``manage_externals/checkout_externals`` is run, the specific GitHub repositories
that are described in :numref:`Table %s <top_level_repos>` are cloned into the target
subdirectories shown below. The directories that will be created later by running the
scripts are presented in parentheses.  Some directories have been removed for brevity.

.. code-block:: console

   ufs-srweather-app
   ├── (bin)
   ├── (build)
   ├── docs  
   │     └── UsersGuide
   ├── (include)
   ├── (lib)
   ├── manage_externals
   ├── regional_workflow
   │     ├── docs
   │     │     └── UsersGuide
   │     ├── (fix)
   │     ├── jobs
   │     ├── modulefiles
   │     ├── scripts
   │     ├── tests
   │     │     └── baseline_configs
   │     └── ush
   │          ├── Python
   │          ├── rocoto
   │          ├── templates
   │          └── wrappers
   ├── (share)
   └── src
        ├── UPP
        │     ├── parm
        │     └── sorc
        │          └── ncep_post.fd
        ├── UFS_UTILS
        │     ├── sorc
        │     │    ├── chgres_cube.fd
        │     │    ├── fre-nctools.fd
        |     │    ├── grid_tools.fd
        │     │    ├── orog_mask_tools.fd
        │     │    └── sfc_climo_gen.fd
        │     └── ush
        └── ufs_weather_model
    	     └── FV3
                  ├── atmos_cubed_sphere
                  └── ccpp

Regional Workflow Sub-Directories
---------------------------------
Under the ``regional_workflow`` directory shown in :numref:`TopLevelDirStructure` there are
a number of sub-directories that are created when the regional workflow is cloned.  The
contents of these sub-directories are described in :numref:`Table %s <Subdirectories>`.

.. _Subdirectories:

.. table::  Sub-directories of the regional workflow.

   +-------------------------+---------------------------------------------------------+
   | **Directory Name**      | **Description**                                         |
   +=========================+=========================================================+
   | docs                    | Users' Guide Documentation                              |
   +-------------------------+---------------------------------------------------------+
   | jobs                    | J-job scripts launched by Rocoto                        |
   +-------------------------+---------------------------------------------------------+
   | modulefiles             | Files used to load modules needed for building and      |
   |                         | running the workflow                                    |
   +-------------------------+---------------------------------------------------------+
   | scripts                 | Run scripts launched by the J-jobs                      |
   +-------------------------+---------------------------------------------------------+
   | tests                   | Baseline experiment configuration                       |
   +-------------------------+---------------------------------------------------------+
   | ush                     | Utility scripts used by the workflow                    |
   +-------------------------+---------------------------------------------------------+

.. _ExperimentDirSection:

Experiment Directory Structure
==============================
When the ``generate_FV3LAM_wflow.sh`` script is run, the user-defined experimental directory
``EXPTDIR=/path-to/ufs-srweather-app/../expt_dirs/${EXPT_SUBDIR}`` is created, where ``EXPT_SUBDIR``
is specified in the ``config.sh`` file. The contents of the ``EXPTDIR`` directory, before the
workflow is run, is shown in :numref:`Table %s <ExptDirStructure>`.

.. _ExptDirStructure:

.. table::  Files and sub-directory initially created in the experimental directory. 
   :widths: 33 67 

   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | **File Name**             | **Description**                                                                                       |
   +===========================+=======================================================================================================+
   | config.sh                 | User-specified configuration file, see :numref:`Section %s <UserSpecificConfig>`                      |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | data_table                | Cycle-independent input file (empty)                                                                  |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | field_table               | Tracers in the `forecast model                                                                        |
   |                           | <https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html#field-table-file>`_        |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | FV3LAM_wflow.xml          | Rocoto XML file to run the workflow                                                                   |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | input.nml                 | Namelist for the `UFS Weather model                                                                   |
   |                           | <https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html#namelist-file-input-nml>`_ | 
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | launch_FV3LAM_wflow.sh    | Symlink to the shell script of                                                                        |
   |                           | ``ufs-srweather-app/regional_workflow/ush/launch_FV3LAM_wflow.sh``                                    |
   |                           | that can be used to (re)launch the Rocoto workflow.                                                   |
   |                           | Each time this script is called, it appends to a log                                                  |
   |                           | file named ``log.launch_FV3LAM_wflow``.                                                               |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | log.generate_FV3LAM_wflow | Log of the output from the experiment generation script                                               |
   |                           | ``generate_FV3LAM_wflow.sh``                                                                          |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | nems.configure            | See `NEMS configuration file                                                                          |
   |                           | <https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/InputsOutputs.html#nems-configure-file>`_     |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | suite_{CCPP}.xml          | CCPP suite definition file used by the forecast model                                                 |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   | var_defns.sh              | Shell script defining the experiment parameters. It contains all                                      |
   |                           | of the primary parameters specified in the default and                                                |
   |                           | user-specified configuration files plus many secondary parameters                                     |
   |                           | that are derived from the primary ones by the experiment                                              |
   |                           | generation script. This file is sourced by various other scripts                                      |
   |                           | in order to make all the experiment variables available to these                                      |
   |                           | scripts.                                                                                              |
   +---------------------------+-------------------------------------------------------------------------------------------------------+
   |  YYYYMMDDHH               | Cycle directory (empty)                                                                               |
   +---------------------------+-------------------------------------------------------------------------------------------------------+

In addition, the *community* mode creates the ``fix_am`` and ``fix_lam`` directories in ``EXPTDIR``.
The ``fix_lam`` directory is initially empty but will contain some *fix* (time-independent) files
after the grid, orography, and/or surface climatology generation tasks are run. 

.. _FixDirectories:

.. table::  Description of the fix directories

   +-------------------------+----------------------------------------------------------+
   | **Directory Name**      | **Description**                                          |
   +=========================+==========================================================+
   | fix_am                  | Directory containing the global `fix` (time-independent) |
   |                         | data files. The experiment generation script copies      |
   |                         | these files from a machine-dependent system directory.   |
   +-------------------------+----------------------------------------------------------+
   | fix_lam                 | Directory containing the regional fix (time-independent) |
   |                         | data files that describe the regional grid, orography,   |
   |                         | and various surface climatology fields as well as        |
   |                         | symlinks to pre-generated files.                         |
   +-------------------------+----------------------------------------------------------+

Once the workflow is launched with the ``launch_FV3LAM_wflow.sh`` script, a log file named
``log.launch_FV3LAM_wflow`` will be created (or appended to it if it already exists) in ``EXPTDIR``.
Once the ``make_grid``, ``make_orog``, and ``make_sfc_climo`` tasks and the ``get_extrn_ics``
and ``get_extrn_lbc`` tasks for the YYYYMMDDHH cycle have completed successfully, new files and
sub-directories are created, as described in :numref:`Table %s <CreatedByWorkflow>`.

.. _CreatedByWorkflow:

.. table::  New directories and files created when the workflow is launched.
   :widths: 30 70

   +---------------------------+--------------------------------------------------------------------+
   | **Directory/file Name**   | **Description**                                                    |
   +===========================+====================================================================+
   | YYYYMMDDHH                | This is updated when the first cycle-specific workflow tasks are   |
   |                           | run, which are ``get_extrn_ics`` and ``get_extrn_lbcs`` (they are  |
   |                           | launched simultaneously for each cycle in the experiment). We      |
   |                           | refer to this as a “cycle directory”. Cycle directories are        |
   |                           | created to contain cycle-specific files for each cycle that the    |
   |                           | experiment runs. If ``DATE_FIRST_CYCL`` and ``DATE_LAST_CYCL``     |
   |                           | were different, and/or ``CYCL_HRS`` contained more than one        |
   |                           | element in the ``config.sh`` file, then more than one cycle        |
   |                           | directory would be created under the experiment directory.         |
   +---------------------------+--------------------------------------------------------------------+
   | grid                      | Directory generated by the ``make_grid`` task containing grid      |
   |                           | files for the experiment                                           |
   +---------------------------+--------------------------------------------------------------------+
   | log                       | Contains log files generated by the overall workflow and its       |
   |                           | various tasks. Look in these files to trace why a task may have    |
   |                           | failed.                                                            |
   +---------------------------+--------------------------------------------------------------------+
   | orog                      | Directory generated by the ``make_orog`` task containing the       |
   |                           | orography files for the experiment                                 |
   +---------------------------+--------------------------------------------------------------------+
   | sfc_climo                 | Directory generated by the ``make_sfc_climo`` task containing the  |
   |                           | surface climatology files for the experiment                       |
   +---------------------------+--------------------------------------------------------------------+
   | FV3LAM_wflow.db           | Database files that are generated when Rocoto is called (by the    |
   | FV3LAM_wflow_lock.db      | launch script) to launch the workflow.                             |
   +---------------------------+--------------------------------------------------------------------+
   | log.launch_FV3LAM_wflow   | This is the log file to which the launch script                    |
   |                           | ``launch_FV3LAM_wflow.sh`` appends its output each time it is      |
   |                           | called. Take a look at the last 30–50 lines of this file to check  |
   |                           | the status of the workflow.                                        |
   +---------------------------+--------------------------------------------------------------------+

The output files for an experiment are described in :numref:`Section %s <OutputFiles>`.
The workflow tasks are described in :numref:`Section %s <WorkflowTaskDescription>`).
