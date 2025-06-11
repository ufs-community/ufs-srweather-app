.. _TechOverview:

====================
Technical Overview
====================

This chapter provides information on SRW App prerequistes, component code repositories, and SRW App directory structure.

.. _SRWPrerequisites:

Prerequisites for Using the SRW Application
===============================================

Background Knowledge Prerequisites
--------------------------------------

The instructions in this documentation assume that users have certain background knowledge: 

* Familiarity with LINUX/UNIX systems
* Command line basics
* System configuration knowledge (e.g., compilers, environment variables, paths, etc.)
* Numerical Weather Prediction (e.g., concepts of parameterizations: physical, microphysical, convective)
* Meteorology (in particular, meteorology at the scales being predicted: 25-km, 13-km, and 3-km resolutions)

Additional background knowledge in the following areas could be helpful:

* High-Performance Computing (HPC) Systems (for those running the SRW App on an HPC system)
* Programming (particularly Python and bash scripting) for those interested in contributing to the SRW App code
* Creating an SSH Tunnel to access HPC systems from the command line
* Containerization
* Workflow Managers/Rocoto

.. _software-prereqs:

Software/Operating System Requirements
-----------------------------------------
The UFS SRW Application has been designed so that any sufficiently up-to-date machine with a UNIX-based operating system should be capable of running the application. SRW App :srw-wiki:`Level 1 systems <Supported-Platforms-and-Compilers>` already have these prerequisites installed. However, users working on other systems must ensure that the following requirements are installed on their system:

**Minimum Platform Requirements:**

* POSIX-compliant UNIX-style operating system

* >90 GB disk space

   * 56 GB input data for a standard collection of global data, or "fix" file data (topography, climatology, observational data) for a short 12-hour test forecast on the :term:`CONUS` 25-km domain. See data download instructions in :numref:`Section %s <DownloadingStagingInput>`.
   * ~19 GB for full :term:`spack-stack` installation
   * 8 GB for ``ufs-srweather-app`` installation
   * 1 GB for boundary conditions for a short 12-hour test forecast on the CONUS 25-km domain. See data download instructions in :numref:`Section %s <DownloadingStagingInput>`.
   * 6 GB for a 12-hour test forecast on the CONUS 25-km domain, with model output saved hourly.

* Fortran compiler released since 2018

   * gfortran v9+ or ifort v18+ are the only ones tested, but others may work.

* C and C++ compilers compatible with the Fortran compiler

   * gcc v9+ and ifort v18+ have been tested.

* Python v3.7+ (preferably 3.9+)

* Perl 5

* git v2.12+

* Lmod

* wget 

   * Only required for retrieving data using ``retrieve_data.py``. If data is prestaged, *wget* is not required. If data is retrieved using other means, *curl* may be used as an alternative. 

The following software is also required to run the SRW Application, but the :term:`spack-stack` (which contains the software libraries necessary for building and running the SRW App) can be configured to build these requirements:

* CMake v3.20+

* :term:`MPI` (MPICH, OpenMPI, or other implementation)

   * Only **MPICH** or **OpenMPI** can be built with spack-stack. Other implementations must be installed separately by the user (if desired).

Optional but recommended prerequisites for all systems:

* Bash v4+
* Rocoto Workflow Management System (1.3.1)


.. _SRWStructure:

Code Repositories and Directory Structure
=========================================

.. _HierarchicalRepoStr:

Hierarchical Repository Structure
-----------------------------------
The :term:`umbrella repository` for the SRW Application is named ``ufs-srweather-app`` and is available on GitHub at https://github.com/ufs-community/ufs-srweather-app. The SRW Application uses the ``manage_externals`` tool and a configuration file called ``Externals.cfg`` to pull in the appropriate versions of the external repositories associated with the SRW App (see :numref:`Table %s <top_level_repos>`).

.. _top_level_repos:

.. list-table::  List of top-level repositories that comprise the UFS SRW Application
   :widths: 20 40
   :header-rows: 1

   * - Repository Description
     - Authoritative repository URL
   * - Umbrella repository for the UFS Short-Range Weather (SRW) Application
     - https://github.com/ufs-community/ufs-srweather-app
   * - Repository for the UFS Weather Model
     - https://github.com/ufs-community/ufs-weather-model
   * - Repository for UFS Utilities, including chgres_cube and other pre-processing utilities
     - https://github.com/ufs-community/UFS_UTILS
   * - Repository for the Unified Post Processor (UPP)
     - https://github.com/NOAA-EMC/UPP
   * - Repository for Air Quality Modeling (AQM) Utilities
     - https://github.com/NOAA-EMC/AQM-utils
   * - Repository for the NOAA Emission and eXchange Unified System (NEXUS)
     - https://github.com/noaa-oar-arl/NEXUS

The UFS Weather Model (WM) contains a number of sub-repositories, which are documented in the :doc:`UFS WM User's Guide <ufs-wm:CodeOverview>`.

.. note::
   The prerequisite libraries (including NCEP Libraries and external libraries) are **not** included in the UFS SRW Application repository. The `spack-stack <https://github.com/JCSDA/spack-stack>`__ repository assembles these prerequisite libraries. Spack-stack has already been built on :srw-wiki:`preconfigured (Level 1) platforms <Supported-Platforms-and-Compilers>`. However, it must be built on other systems. See the :doc:`spack-stack Documentation <spack-stack:index>` for details on installing spack-stack.

.. _TopLevelDirStructure:

Repository Structure
----------------------
The ``ufs-srweather-app`` :term:`umbrella repository` is an NCO-compliant repository. Its structure follows the standards laid out in the :term:`NCEP` Central Operations (NCO) WCOSS :nco:`Implementation Standards <ImplementationStandards.v11.0.0.pdf>`. This structure is implemented using the ``local_path`` settings contained within the ``Externals.cfg`` file. When ``manage_externals/checkout_externals`` is run (see :numref:`Section %s <CheckoutExternals>`), the specific GitHub repositories described in :numref:`Table %s <top_level_repos>` are cloned into the target subdirectories shown below under ``/sorc``. Directories that will be created as part of the build process appear in parentheses and will not be visible until after the build is complete. Some files and directories have been removed for brevity.

.. code-block:: console

   ufs-srweather-app
   ├── (build)
   ├── (conda)
   │     └── envs
   ├── (conda_loc)
   ├── doc  
   │     ├── ContribGuide
   │     ├── UsersGuide
   │     └── TechDocs
   ├── etc
   │     └── lmod-setup.sh
   ├── (exec)
   ├── fix
   ├── (include)
   ├── jobs
   ├── (lib)
   ├── manage_externals
   ├── modulefiles
   │     ├── build_<platform>_<compiler>.lua
   │     ├── python_srw*.lua
   │     └── wflow_<platform>.lua
   ├── parm
   │     ├── wflow
   │     │     └── default_workflow.yaml
   │     ├── FV3.input.yml
   │     ├── FV3LAM_wflow.xml
   │     ├── diag_table.*
   │     ├── field_table.*
   │     ├── input.nml.FV3
   │     ├── model_configure
   │     └── ufs.configure
   ├── scripts
   ├── sorc
   │     ├── CMakeLists.txt
   │     ├── arl_nexus
   │     ├── AQM-utils
   │     ├── UPP
   │     │     ├── parm
   │     │     └── sorc
   │     │          └── ncep_post.fd
   │     ├── UFS_UTILS
   │     │     ├── sorc
   │     │     │    ├── chgres_cube.fd
   │     │     │    ├── sfc_climo_gen.fd
   │     │     │    └── vcoord_gen.fd
   │     │     └── ush
   │     └── ufs-weather-model
   │	         └── FV3
   │                ├── atmos_cubed_sphere
   │                └── ccpp
   ├── tests/WE2E
   │     └── run_WE2E_tests.py 
   ├── ush
   │     ├── bash_utils
   │     ├── machine
   │     ├── wrappers
   │     ├── python_utils
   │     ├── config.community.yaml
   │     ├── config.*.yaml
   │     ├── config_defaults.yaml
   │     ├── experiment.jsonschema
   │     ├── generate_FV3LAM_wflow.py
   │     ├── launch_FV3LAM_wflow.sh
   │     ├── setup.py
   │     └── user.jsonschema
   ├── versions
   ├── CMakeLists.txt
   ├── Externals.cfg
   ├── aqm_environment.yml
   ├── devbuild.sh
   ├── environment.yml
   ├── graphics_environment.yml
   └── sd_environment.yml


SRW App Subdirectories
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
:numref:`Table %s <Subdirectories>` describes the contents of the most important SRW App subdirectories. :numref:`Table %s <FilesAndSubDirs>` provides a more comprehensive explanation of the ``ufs-srweather-app`` files and subdirectories. Users can reference the :nco:`NCO Implementation Standards <ImplementationStandards.v11.0.0.pdf>` (p. 19) for additional details on repository structure in NCO-compliant repositories. 

.. _Subdirectories:

.. list-table:: Subdirectories of the ``ufs-srweather-app`` repository
   :widths: 20 50
   :header-rows: 1

   * - Directory Name
     - Description
   * - conda
     - Installation location for miniconda and SRW App environments
   * - doc
     - Repository documentation
   * - exec
     - Executables built from code in ``/sorc``
   * - jobs
     - :term:`J-job <J-jobs>` scripts launched by Rocoto
   * - modulefiles
     - Files used to load modules needed for building and running the workflow
   * - parm
     - Parameter files used to configure the model, physics, workflow, and various SRW App components
   * - scripts
     - Scripts launched by the J-jobs
   * - sorc
     - External source code used to build the SRW App
   * - tests
     - Tests for baseline experiment configurations
   * - ush
     - Utility scripts used by the workflow
   
.. _ExperimentDirSection:

Experiment Directory Structure
--------------------------------
When the user generates an experiment using the ``generate_FV3LAM_wflow.py`` script (:numref:`Step %s <GenerateWorkflow>`), a user-defined experiment directory (``$EXPTDIR``) is created based on information specified in the ``config.yaml`` file. :numref:`Table %s <ExptDirStructure>` shows the contents of the experiment directory before running the experiment workflow.

.. _ExptDirStructure:

.. list-table:: *Files and subdirectories initially created in the experiment directory*
   :widths: 33 67
   :header-rows: 1

   * - File Name
     - Description
   * - config.yaml
     - Copy of the user-specified configuration file (see :numref:`Section %s <UserSpecificConfig>`)
   * - data_table
     - :term:`Cycle-independent` input file (empty)
   * - fd_ufs.yaml
     - The name of the field dictionary file. This file is a community-based dictionary for shared coupling fields and is automatically generated by the NUOPC Layer. 
   * - field_table
     - :term:`Tracers <tracer>` in the :ref:`forecast model field_table <ufs-wm:field_tableFile>`
   * - fix_am 
     - Directory containing the global fix (time-independent) data files (or symlinks to the fix files) for various fields on global grids (which are usually much coarser than the native FV3-LAM grid).
   * - fix_lam
     - Directory (initially empty) that will contain the regional fix (time-independent) data files (or symlinks to the fix files) that describe the regional grid, orography, and various surface climatology fields on the native FV3-LAM grid.
   * - FV3LAM_wflow.xml
     - Rocoto XML file to run the workflow
   * - input.nml
     - :term:`Namelist` for the :ref:`UFS Weather Model <ufs-wm:InputNML>`
   * - launch_FV3LAM_wflow.sh
     - Symlink to the ``ufs-srweather-app/ush/launch_FV3LAM_wflow.sh`` shell script, 
       which can be used to (re)launch the Rocoto workflow. Each time this script is 
       called, it appends information to a log file named ``log.launch_FV3LAM_wflow``.
   * - log.generate_FV3LAM_wflow
     - Log of the output from the experiment generation script (``generate_FV3LAM_wflow.py``)
   * - rocoto_defns.yaml
     - YAML file containing the YAML workflow definition from which the Rocoto XML file is created.
   * - suite_{CCPP}.xml
     - :term:`CCPP` suite definition file (:term:`SDF`) used by the forecast model
   * - var_defns.yaml
     - YAML file containing the experiment parameters. It contains all of the primary 
       parameters specified in the default and user-specified configuration files plus 
       many secondary parameters that are derived from the primary ones by the 
       experiment generation script based on the machine files and other settings. 
       This file is the primary source of information on experiment variables used in the scripts at run time.
   * - task_skip_coldstart_YYYYMMDDHHmm.txt
     - Flag file for cold start 



Once the workflow is launched, several files and directories are generated. A log file named ``log.launch_FV3LAM_wflow`` will be created (unless it already exists) in ``$EXPTDIR``. The first several workflow tasks (i.e., ``make_grid``, ``make_orog``, ``make_sfc_climo``, ``get_extrn_ics``, and ``get_extrn_lbcs``) are preprocessing tasks, and these tasks also result in the creation of new files and subdirectories, described in :numref:`Table %s <CreatedByWorkflow>`.

.. _CreatedByWorkflow:

.. list-table:: *New directories and files created when the workflow is launched*
   :widths: 30 70
   :header-rows: 1

   * - Directory/File Name
     - Description
   * - YYYYMMDDHH
     - This is a “cycle directory” that is updated when the first cycle-specific 
       workflow tasks (``get_extrn_ics`` and ``get_extrn_lbcs``) are run. These tasks 
       are launched simultaneously for each cycle in the experiment. Cycle directories 
       are created to contain cycle-specific files for each cycle that the experiment 
       runs. If ``DATE_FIRST_CYCL`` and ``DATE_LAST_CYCL`` are different in the 
       ``config.yaml`` file, more than one cycle directory will be created under the 
       experiment directory.
   * - FV3LAM_wflow.db
       
       FV3LAM_wflow_lock.db
     - Database files that are generated when Rocoto is called (by the launch script) to launch the workflow
   * - grid
     - Directory generated by the ``make_grid`` task to store grid files for the experiment
   * - log
     - Directory containing log files generated by the overall workflow and by its various tasks. View the files in this directory to determine why a task may have failed.
   * - orog
     - Directory generated by the ``make_orog`` task containing the orography files for the experiment
   * - sfc_climo
     - Directory generated by the ``make_sfc_climo`` task containing the surface climatology files for the experiment
   
   
The output files for an experiment are described in :numref:`Section %s <OutputFiles>`.
The workflow tasks are described in :numref:`Section %s <WorkflowTaskDescription>`.