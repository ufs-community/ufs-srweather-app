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
* Meteorology (in particular, meteorology at the scales being predicted: 25km, 13km, and 3km resolutions)

Additional background knowledge in the following areas could be helpful:

* High-Performance Computing (HPC) Systems (for those running the SRW App on an HPC system)
* Programming (particularly Python and bash scripting) for those interested in contributing to the SRW App code
* Creating an SSH Tunnel to access HPC systems from the command line
* Containerization
* Workflow Managers/Rocoto

.. _software-prereqs:

Software/Operating System Requirements
-----------------------------------------
The UFS SRW Application has been designed so that any sufficiently up-to-date machine with a UNIX-based operating system should be capable of running the application. SRW App :srw-wiki:`Level 1 & 2 systems <Supported-Platforms-and-Compilers>` already have these prerequisites installed. However, users working on other systems must ensure that the following requirements are installed on their system: 

**Minimum Platform Requirements:**

* POSIX-compliant UNIX-style operating system

* >97 GB disk space

   * 53 GB input data for a standard collection of global data, or "fix" file data (topography, climatology, observational data) for a short 12-hour test forecast on the :term:`CONUS` 25km domain. See data download instructions in :numref:`Section %s <DownloadingStagingInput>`.
   * ~23 GB for full :term:`spack-stack` installation (or ~8 GB :term:`HPC-Stack`)
   * 3 GB for ``ufs-srweather-app`` installation
   * 1 GB for boundary conditions for a short 12-hour test forecast on the CONUS 25km domain. See data download instructions in :numref:`Section %s <DownloadingStagingInput>`.
   * 17 GB for a 12-hour test forecast on the CONUS 25km domain, with model output saved hourly.

* Fortran compiler released since 2018

   * gfortran v9+ or ifort v18+ are the only ones tested, but others may work.

* C and C++ compilers compatible with the Fortran compiler

   * gcc v9+, ifort v18+, and clang v9+ (macOS, native Apple clang, LLVM clang, GNU) have been tested

* Python v3.7+ (preferably 3.9+), including prerequisite packages ``jinja2``, ``pyyaml``, and ``f90nml``
   
   * Python packages ``scipy``, ``matplotlib``, ``pygrib``, ``cartopy``, and ``pillow`` are required for users who would like to use the provided graphics scripts.

* Perl 5

* git v2.12+

* Lmod

* wget 

   * Only required for retrieving data using ``retrieve_data.py``. If data is prestaged, *wget* is not required. If data is retrieved using other means, *curl* may be used as an alternative. 

The following software is also required to run the SRW Application, but the :term:`spack-stack` (which contains the software libraries necessary for building and running the SRW App) can be configured to build these requirements:

* CMake v3.20+

* :term:`MPI` (MPICH, OpenMPI, or other implementation)

   * Only **MPICH** or **OpenMPI** can be built with spack-stack. Other implementations must be installed separately by the user (if desired).

For MacOS systems, some additional software packages are needed. When possible, it is recommended that users install and/or upgrade this software (along with software listed above) using the `Homebrew <https://brew.sh/>`__ package manager for MacOS. See :doc:`HPC-Stack Documentation: Chapter 3 <hpc-stack:mac-install>` for further guidance on installing these prerequisites on MacOS.

* bash v4.x
* GNU compiler suite v11 or higher with gfortran
* cmake
* make
* coreutils
* gsed

Optional but recommended prerequisites for all systems:

* Conda for installing/managing Python packages
* Bash v4+
* Rocoto Workflow Management System (1.3.1)
* Python packages ``scipy``, ``matplotlib``, ``pygrib``, ``cartopy``, and ``pillow`` for graphics


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
   * - Repository for UFS Utilities, including pre-processing, chgres_cube, and more
     - https://github.com/ufs-community/UFS_UTILS
   * - Repository for the Unified Post Processor (UPP)
     - https://github.com/NOAA-EMC/UPP
   * - Repository for Air Quality Modeling (AQM) Utilities
     - https://github.com/NOAA-EMC/AQM-utils
   * - Repository for the NOAA Emission and eXchange Unified System (NEXUS)
     - https://github.com/noaa-oar-arl/NEXUS
   * - Repository for the Unified Workflow (UW) Toolkit
     - https://github.com/ufs-community/uwtools

The UFS Weather Model contains a number of sub-repositories, which are documented :doc:`here <ufs-wm:CodeOverview>`.

.. note::
   The prerequisite libraries (including NCEP Libraries and external libraries) are **not** included in the UFS SRW Application repository. The `spack-stack <https://github.com/JCSDA/spack-stack>`__ repository assembles these prerequisite libraries. Spack-stack has already been built on :srw-wiki:`preconfigured (Level 1) platforms <Supported-Platforms-and-Compilers>`. However, it must be built on other systems. See the :doc:`spack-stack Documentation <spack-stack:index>` for details on installing spack-stack.

.. _TopLevelDirStructure:

Repository Structure
----------------------
The ``ufs-srweather-app`` :term:`umbrella repository` is an NCO-compliant repository. Its structure follows the standards laid out in :term:`NCEP` Central Operations (NCO) WCOSS :nco:`Implementation Standards <ImplementationStandards.v11.0.0.pdf>`. This structure is implemented using the ``local_path`` settings contained within the ``Externals.cfg`` file. After ``manage_externals/checkout_externals`` is run (see :numref:`Section %s <CheckoutExternals>`), the specific GitHub repositories described in :numref:`Table %s <top_level_repos>` are cloned into the target subdirectories shown below. Directories that will be created as part of the build process appear in parentheses and will not be visible until after the build is complete. Some directories have been removed for brevity.

.. code-block:: console

   ufs-srweather-app
   ├── (build)
   ├── docs  
   │     └── UsersGuide
   ├── etc
   ├── (exec)
   ├── (include)
   ├── jobs
   ├── (lib)
   ├── manage_externals
   ├── modulefiles
   │     ├── build_<platform>_<compiler>.lua
   │     └── wflow_<platform>.lua
   ├── parm
   │     ├── wflow
   │     │     └── default_workflow.yaml
   │     └── FV3LAM_wflow.xml
   ├── (share)
   ├── scripts
   ├── sorc
   │     ├── CMakeLists.txt
   │     ├── (UPP)
   │     │     ├── parm
   │     │     └── sorc
   │     │          └── ncep_post.fd
   │     ├── (UFS_UTILS)
   │     │     ├── sorc
   │     │     │    ├── chgres_cube.fd
   │     │     │    ├── sfc_climo_gen.fd
   │     │     │    └── vcoord_gen.fd
   │     │     └── ush
   │     └── (ufs-weather-model)
   │	         └── FV3
   │                ├── atmos_cubed_sphere
   │                └── ccpp
   ├── tests/WE2E
   │     └── run_WE2E_tests.py 
   ├── ush
   │     ├── bash_utils
   │     ├── machine
   │     ├── wrappers
   │     ├── config.community.yaml
   │     ├── config_defaults.yaml
   │     ├── generate_FV3LAM_wflow.py
   │     ├── launch_FV3LAM_wflow.sh
   │     ├── setup.py
   │     └── valid_param_vals.yaml
   └── versions

SRW App SubDirectories
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
:numref:`Table %s <Subdirectories>` describes the contents of the most important SRW App subdirectories. :numref:`Table %s <FilesAndSubDirs>` provides a more comprehensive explanation of the ``ufs-srweather-app`` files and subdirectories. Users can reference the :nco:`NCO Implementation Standards <ImplementationStandards.v11.0.0.pdf>` (p. 19) for additional details on repository structure in NCO-compliant repositories. 

.. _Subdirectories:

.. list-table:: *Subdirectories of the ufs-srweather-app repository*
   :widths: 20 50
   :header-rows: 1

   * - Directory Name
     - Description
   * - docs
     - Repository documentation
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

.. list-table:: *Files and subdirectory initially created in the experiment directory*
   :widths: 33 67
   :header-rows: 1

   * - File Name
     - Description
   * - config.yaml
     - User-specified configuration file, see :numref:`Section %s <UserSpecificConfig>`
   * - data_table
     - :term:`Cycle-independent` input file (empty)
   * - field_table
     - :term:`Tracers <tracer>` in the :ref:`forecast model <ufs-wm:field_tableFile>`
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
   * - nems.configure
     - See :ref:`NEMS configuration file <ufs-wm:ufs-conf>`
   * - suite_{CCPP}.xml
     - :term:`CCPP` suite definition file (:term:`SDF`) used by the forecast model
   * - var_defns.sh
     - Shell script defining the experiment parameters. It contains all of the primary 
       parameters specified in the default and user-specified configuration files plus 
       many secondary parameters that are derived from the primary ones by the 
       experiment generation script. This file is sourced by various other scripts in 
       order to make all the experiment variables available to these scripts. 
   * - YYYYMMDDHH
     - Cycle directory (empty)

In addition, running the SRW App in *community* mode creates the ``fix_am`` and ``fix_lam`` directories (see :numref:`Table %s <FixDirectories>`) in ``$EXPTDIR``. The ``fix_lam`` directory is initially empty but will contain some *fix* (time-independent) files after the grid, orography, and/or surface climatology generation tasks run. 

.. _FixDirectories:

.. list-table:: *Description of the fix directories*
   :widths: 33 67
   :header-rows: 1

   * - Directory Name
     - Description
   * - fix_am
     - Directory containing the global fix (time-independent) data files. The 
       experiment generation script symlinks these files from a machine-dependent 
       system directory.
   * - fix_lam
     - Directory containing the regional fix (time-independent) data files that 
       describe the regional grid, orography, and various surface climatology fields, 
       as well as symlinks to pre-generated files.

Once the Rocoto workflow is launched, several files and directories are generated. A log file named ``log.launch_FV3LAM_wflow`` will be created (unless it already exists) in ``$EXPTDIR``. The first several workflow tasks (i.e., ``make_grid``, ``make_orog``, ``make_sfc_climo``, ``get_extrn_ics``, and ``get_extrn_lbcs``) are preprocessing tasks, and these tasks also result in the creation of new files and subdirectories, described in :numref:`Table %s <CreatedByWorkflow>`.

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
   * - grid
     - Directory generated by the ``make_grid`` task to store grid files for the experiment
   * - log
     - Contains log files generated by the overall workflow and by its various tasks. View the files in this directory to determine why a task may have failed.
   * - orog
     - Directory generated by the ``make_orog`` task containing the orography files for the experiment
   * - sfc_climo
     - Directory generated by the ``make_sfc_climo`` task containing the surface climatology files for the experiment
   * - FV3LAM_wflow.db
       
       FV3LAM_wflow_lock.db
     - Database files that are generated when Rocoto is called (by the launch script) to launch the workflow
   * - log.launch_FV3LAM_wflow
     - The ``launch_FV3LAM_wflow.sh`` script appends its output to this log file each time it is called. View the last several lines of this file to check the status of the workflow.
   
The output files for an experiment are described in :numref:`Section %s <OutputFiles>`.
The workflow tasks are described in :numref:`Section %s <WorkflowTaskDescription>`.

