.. _Introduction:

==============
Introduction
==============

The Unified Forecast System (:term:`UFS`) is a community-based, coupled, comprehensive Earth modeling system. NOAA's operational model suite for numerical weather prediction (:term:`NWP`) is quickly transitioning to the UFS from a number of different modeling systems. The UFS enables research, development, and contribution opportunities within the broader :term:`Weather Enterprise` (including government, industry, and academia). For more information about the UFS, visit the `UFS Portal <https://ufscommunity.org/>`__.

The UFS includes `multiple applications <https://ufscommunity.org/science/aboutapps/>`__ that support different forecast durations and spatial domains. This documentation describes the UFS Short-Range Weather (SRW) Application, which targets predictions of atmospheric behavior on a limited spatial domain and on time scales from minutes to several days. The SRW Application v2.0.0 release includes a prognostic atmospheric model, pre- and post-processing, and a community workflow for running the system end-to-end. These components are documented within this User's Guide and supported through a `community forum <https://forums.ufscommunity.org/>`__. New and improved capabilities for this release include the addition of a verification package (METplus) for both deterministic and ensemble simulations and support for four stochastically perturbed physics schemes. Future work will expand the capabilities of the application to include data assimilation (DA) and a forecast restart/cycling capability. 

This documentation provides a :ref:`Quick Start Guide <NCQuickstart>` designed for use on `Level 1 systems <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ or as an overview of the workflow. It also provides a :ref:`Container-Based Quick Start Guide <QuickstartC>` for running the SRW Application in a container and a :ref:`detailed guide <BuildRunSRW>` for running the SRW App on any supported platform. Additionally, this User's Guide provides an overview of the :ref:`release components <Components>` and details on how to customize or modify different portions of the workflow.

The SRW App v2.0.0 citation is as follows and should be used when presenting results based on research conducted with the App:

UFS Development Team. (2022, June 23). Unified Forecast System (UFS) Short-Range Weather (SRW) Application (Version v2.0.0). Zenodo. https://doi.org/10.5281/zenodo.6505854


How to Use This Document
========================

This guide instructs both novice and experienced users on downloading, building, and running the SRW Application. Please post questions in the `UFS Forum <https://forums.ufscommunity.org/forum/short-range-weatherconvection-allowing-application>`__.

.. code-block:: console

   Throughout the guide, this presentation style indicates shell commands and options, 
   code examples, etc.

Variables presented as ``AaBbCc123`` in this User's Guide typically refer to variables in scripts, names of files, and directories.

File paths or code that include angle brackets (e.g., ``build_<platform>_<compiler>``) indicate that users should insert options appropriate to their SRW App configuration (e.g., ``build_orion_intel``). 

.. hint:: 
   * To get started running the SRW App, users can view :numref:`Chapter %s <NCQuickstart>` for a quick overview of the workflow steps. For more detailed explanations, users can refer to the :ref:`Container-Based Quick Start Guide <QuickstartC>` or the in-depth chapter on :ref:`Building and Running the Short-Range Weather Application <BuildRunSRW>`. 
   * For background information on the SRW App code repositories and directory structure, see :numref:`Section %s <SRWStructure>` below. 
   * For an outline of SRW App components, see section :numref:`Section %s <ComponentsOverview>` below or refer to :numref:`Chapter %s <Components>` for a more in-depth treatment.


.. _SRWPrerequisites:

Prerequisites for Using the SRW Application
===============================================

Background Knowledge Prerequisites
--------------------------------------

The instructions in this documentation assume that users have certain background knowledge: 

* Familiarity with LINUX/UNIX systems
* Command line basics
* System configuration knowledge (e.g., compilers, environment variables, paths, etc.)
* Numerical Weather Prediction (concepts of parameterizations: physical, microphysical, convective)
* Meteorology (in particular, meteorology at the scales being predicted: 25km, 13km, and 3km resolutions)

Additional background knowledge in the following areas could be helpful:

* High-Performance Computing (HPC) Systems for those running the SRW App on an HPC system
* Programming (particularly Python) for those interested in contributing to the SRW App code
* Creating an SSH Tunnel to access HPC systems from the command line
* Containerization
* Workflow Managers/Rocoto


Software/Operating System Requirements
-----------------------------------------
The UFS SRW Application has been designed so that any sufficiently up-to-date machine with a UNIX-based operating system should be capable of running the application. NOAA `Level 1 & 2 systems <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ already have these prerequisites installed. However, users working on other systems must ensure that the following requirements are installed on their system: 

**Minimum Platform Requirements:**

* POSIX-compliant UNIX-style operating system

* >82 GB disk space

   * 53 GB input data for a standard collection of global database, or "fix" data (topography, climatology, observational database) for a short 12-hour test forecast on CONUS 25km domain. See data download instructions in :numref:`Section %s <DownloadingStagingInput>`.
   * 8 GB for :term:`HPC-Stack` full installation
   * 3 GB for ``ufs-srweather-app`` installation
   * 1 GB for boundary conditions for a short 12-h test forecast on the CONUS 25km domain. See data download instructions in :numref:`Section %s <DownloadingStagingInput>`
   * 17 GB for a 12-h test forecast on the CONUS 25km domain, with model output saved hourly, see :numref:`Section %s <GridSpecificConfig>`

* Fortran compiler released since 2018

   * gfortran v9+ or ifort v18+ are the only ones tested, but others may work.

* C and C++ compilers compatible with the Fortran compiler

   * gcc v9+, ifort v18+, and clang v9+ (macOS, native Apple clang, LLVM clang, GNU) have been tested

* Python v3.6+, including prerequisite packages ``jinja2``, ``pyyaml`` and ``f90nml``
   
   * Python packages ``scipy``, ``matplotlib``, ``pygrib``, ``cartopy``, and ``pillow`` are required for users who would like to use the provided graphics scripts.

* Perl 5

* git v2.12+

* curl 

* wget

* Lmod


The following software is also required to run the SRW Application, but the :term:`HPC-Stack` (which contains the software libraries necessary for building and running the SRW App) can be configured to build these requirements:

* CMake v3.20+

* MPI (MPICH, OpenMPI, or other implementation)

   * Only **MPICH** or **OpenMPI** can be built with HPC-Stack. Other implementations must be installed separately by the user (if desired). 

For MacOS systems, some additional software packages are needed. When possible, it is recommended that users install and/or upgrade this software (along with software listed above) using the `Homebrew <https://brew.sh/>`__ package manager for MacOS. See :numref:`Chapter %s <MacInstall>` and :numref:`Chapter %s <MacMorePackages>` for further guidance on installing these prerequisites on MacOS.

* bash v4.x
* GNU compiler suite v.11 or higher with gfortran
* cmake
* make
* coreutils
* gsed

Optional but recommended prerequisites for all systems:

* Conda for installing/managing Python packages
* Bash v4+
* Rocoto Workflow Management System (1.3.1)
* Python packages ``scipy``, ``matplotlib``, ``pygrib``, ``cartopy``, and ``pillow`` for graphics

.. _ComponentsOverview: 

SRW App Components Overview 
==============================

Pre-processor Utilities and Initial Conditions
------------------------------------------------

The SRW Application includes a number of pre-processing utilities that initialize and prepare the model. Tasks include generating a regional grid along with :term:`orography` and surface climatology files for that grid. One pre-processing utility converts the raw external model data into initial and lateral boundary condition files in netCDF format. Later, these files are used as input to the atmospheric model (FV3-LAM). Additional information about the pre-processor utilities can be found in :numref:`Chapter %s <Utils>`, in the `UFS_UTILS Technical Documentation <https://noaa-emcufs-utils.readthedocs.io/en/latest>`__, and in the `UFS_UTILS Scientific Documentation <https://ufs-community.github.io/UFS_UTILS/index.html>`__.

Forecast Model
-----------------

Atmospheric Model
^^^^^^^^^^^^^^^^^^^^^^

The prognostic atmospheric model in the UFS SRW Application is the Finite-Volume Cubed-Sphere
(:term:`FV3`) dynamical core configured with a Limited Area Model (LAM) capability (:cite:t:`BlackEtAl2021`). The :term:`dynamical core` is the computational part of a model that solves the equations of fluid motion. A User's Guide for the UFS :term:`Weather Model` can be found `here <https://ufs-weather-model.readthedocs.io/en/latest>`__. 

Common Community Physics Package
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The `Common Community Physics Package <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`__ (:term:`CCPP`) supports interoperable atmospheric physics and land surface model options. Atmospheric physics are a set of numerical methods describing small-scale processes such as clouds, turbulence, radiation, and their interactions. The most recent release includes four supported physics suites. 

Data Format
^^^^^^^^^^^^^^^^^^^^^^

The SRW App supports the use of external model data in :term:`GRIB2`, :term:`NEMSIO`, and :term:`netCDF` format when generating initial and boundary conditions. The UFS Weather Model ingests initial and lateral boundary condition files produced by :term:`chgres_cube`. 


Unified Post-Processor (UPP)
--------------------------------

The `Unified Post Processor <https://dtcenter.org/community-code/unified-post-processor-upp>`__ (:term:`UPP`) processes raw output from a variety of numerical weather prediction (:term:`NWP`) models. In the SRW App, it converts data output from netCDF format to GRIB2 format. The UPP can also be used to compute a variety of useful diagnostic fields, as described in the `UPP User’s Guide <https://upp.readthedocs.io/en/latest/>`__. 

METplus Verification Suite
------------------------------

The Model Evaluation Tools (MET) package is a set of statistical verification tools developed by the `Developmental Testbed Center <https://dtcenter.org/>`__ (DTC) for use by the :term:`NWP` community to help them assess and evaluate the performance of numerical weather predictions. MET is the core component of the enhanced METplus verification framework. The suite also includes the associated database and display systems called METviewer and METexpress. METplus spans a wide range of temporal and spatial scales. It is intended to be extensible through additional capabilities developed by the community. More details about METplus can be found in :numref:`Chapter %s <MetplusComponent>` and on the `METplus website <https://dtcenter.org/community-code/metplus>`__.

Visualization Example
-------------------------

The SRW Application includes Python scripts to create basic visualizations of the model output. :numref:`Chapter %s <Graphics>` contains usage information and instructions; instructions also appear at the top of the scripts. 

Build System and Workflow
----------------------------

The SRW Application has a portable CMake-based build system that packages together all the components required to build the SRW Application. Once built, users can generate a Rocoto-based workflow that will run each task in the proper sequence (see the `Rocoto documentation <https://github.com/christopherwharrop/rocoto/wiki/Documentation>`__ for more on workflow management). Individual workflow tasks can also be run in a stand-alone, command line fashion. 

The SRW Application allows for configuration of various elements of the workflow. For example, users can modify the parameters of the atmospheric model, such as start and end dates, duration, time step, and the physics suite used for the simulation. More information on how to do this is available in :numref:`Section %s <UserSpecificConfig>`.

The SRW Application has been tested on a variety of platforms widely used by researchers, including NOAA High-Performance Computing (HPC) systems (e.g., Hera, Orion), cloud environments, and generic Linux and MacOS systems. Four `levels of support <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_ have been defined for the SRW Application. Preconfigured (Level 1) systems already have the required external libraries available in a central location (via :term:`HPC-Stack`). The SRW Application is expected to build and run out-of-the-box on these systems, and users can :ref:`download the SRW App code <DownloadSRWApp>` without first installing prerequisites. On other platforms (Levels 2-4), the SRW App can be :ref:`run within a container <QuickstartC>` that includes the HPC-Stack, or the required libraries will need to be installed as part of the :ref:`SRW Application build <BuildRunSRW>` process. Once these prerequisite libraries are installed, applications and models should build and run successfully. However, users may need to perform additional troubleshooting on Level 3 or 4 systems since little or no pre-release testing has been conducted on these systems. 



.. _SRWStructure:

Code Repositories and Directory Structure
=========================================

.. _HierarchicalRepoStr:

Hierarchical Repository Structure
-----------------------------------
The :term:`umbrella repository` for the SRW Application is named ``ufs-srweather-app`` and is available on GitHub at https://github.com/ufs-community/ufs-srweather-app. An umbrella repository is a repository that houses external code, called "externals," from additional repositories. The SRW Application includes the ``manage_externals`` tool and a configuration file called ``Externals.cfg``, which tags the appropriate versions of the external repositories associated with the SRW App (see :numref:`Table %s <top_level_repos>`).

.. _top_level_repos:

.. table::  List of top-level repositories that comprise the UFS SRW Application

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

The UFS Weather Model contains a number of sub-repositories, which are documented `here <https://ufs-weather-model.readthedocs.io/en/latest/CodeOverview.html>`__.

.. note::
   The prerequisite libraries (including NCEP Libraries and external libraries) are not included in the UFS SRW Application repository. The `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__ repository assembles these prerequisite libraries. The HPC-Stack has already been built on `preconfigured (Level 1) platforms <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__. However, it must be built on other systems. :numref:`Chapter %s <InstallBuildHPCstack>` contains details on installing the HPC-Stack. 


.. _TopLevelDirStructure:

Directory Structure
----------------------
The ``ufs-srweather-app`` :term:`umbrella repository` structure is determined by the ``local_path`` settings contained within the ``Externals.cfg`` file. After ``manage_externals/checkout_externals`` is run (see :numref:`Section %s <CheckoutExternals>`), the specific GitHub repositories described in :numref:`Table %s <top_level_repos>` are cloned into the target subdirectories shown below. Directories that will be created as part of the build process appear in parentheses and will not be visible until after the build is complete. Some directories have been removed for brevity.

.. code-block:: console

   ufs-srweather-app
   ├── (bin)
   ├── (build)
   ├── docs  
   │     └── UsersGuide
   ├── etc
   ├── (include)
   ├── (lib)
   ├── manage_externals
   ├── modulefiles
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
   ├── src
   │    ├── UPP
   │    │     ├── parm
   │    │     └── sorc
   │    │          └── ncep_post.fd
   │    ├── UFS_UTILS
   │    │     ├── sorc
   │    │     │    ├── chgres_cube.fd
   │    │     │    ├── fre-nctools.fd
   │    │     │    ├── grid_tools.fd
   │    │     │    ├── orog_mask_tools.fd
   │    │     │    └── sfc_climo_gen.fd
   │    │     └── ush
   │    └── ufs-weather-model
   │	     └── FV3
   │              ├── atmos_cubed_sphere
   │              └── ccpp
   └── test

Regional Workflow Sub-Directories
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
A number of sub-directories are created under the ``regional_workflow`` directory when the regional workflow is cloned (see directory diagram :ref:`above <TopLevelDirStructure>`). :numref:`Table %s <Subdirectories>` describes the contents of these sub-directories. 

.. _Subdirectories:

.. table::  Sub-directories of the regional workflow

   +-------------------------+---------------------------------------------------------+
   | **Directory Name**      | **Description**                                         |
   +=========================+=========================================================+
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
--------------------------------
When the user generates an experiment using the ``generate_FV3LAM_wflow.sh`` script (:numref:`Step %s <GenerateWorkflow>`), a user-defined experimental directory (``$EXPTDIR``) is created based on information specified in the ``config.sh`` file. :numref:`Table %s <ExptDirStructure>` shows the contents of the experiment directory before running the experiment workflow.

.. _ExptDirStructure:

.. table::  Files and sub-directory initially created in the experimental directory 
   :widths: 33 67 

   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | **File Name**             | **Description**                                                                                              |
   +===========================+==============================================================================================================+
   | config.sh                 | User-specified configuration file, see :numref:`Section %s <UserSpecificConfig>`                             |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | data_table                | :term:`Cycle-independent` input file (empty)                                                                 |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | field_table               | :term:`Tracers` in the `forecast model                                                                       |
   |                           | <https://ufs-weather-model.readthedocs.io/en/latest/InputsOutputs.html#field-table-file>`__                  |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | FV3LAM_wflow.xml          | Rocoto XML file to run the workflow                                                                          |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | input.nml                 | :term:`Namelist` for the `UFS Weather Model                                                                  |
   |                           | <https://ufs-weather-model.readthedocs.io/en/latest/InputsOutputs.html#namelist-file-input-nml>`__           | 
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | launch_FV3LAM_wflow.sh    | Symlink to the shell script of                                                                               |
   |                           | ``ufs-srweather-app/regional_workflow/ush/launch_FV3LAM_wflow.sh``,                                          |
   |                           | which can be used to (re)launch the Rocoto workflow.                                                         |
   |                           | Each time this script is called, it appends to a log                                                         |
   |                           | file named ``log.launch_FV3LAM_wflow``.                                                                      |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | log.generate_FV3LAM_wflow | Log of the output from the experiment generation script                                                      |
   |                           | (``generate_FV3LAM_wflow.sh``)                                                                               |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | nems.configure            | See `NEMS configuration file                                                                                 |
   |                           | <https://ufs-weather-model.readthedocs.io/en/latest/InputsOutputs.html#nems-configure-file>`__               |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | suite_{CCPP}.xml          | :term:`CCPP` suite definition file used by the forecast model                                                |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   | var_defns.sh              | Shell script defining the experiment parameters. It contains all                                             |
   |                           | of the primary parameters specified in the default and                                                       |
   |                           | user-specified configuration files plus many secondary parameters                                            |
   |                           | that are derived from the primary ones by the experiment                                                     |
   |                           | generation script. This file is sourced by various other scripts                                             |
   |                           | in order to make all the experiment variables available to these                                             |
   |                           | scripts.                                                                                                     |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+
   |  YYYYMMDDHH               | Cycle directory (empty)                                                                                      |
   +---------------------------+--------------------------------------------------------------------------------------------------------------+

In addition, running the SRW App in *community* mode creates the ``fix_am`` and ``fix_lam`` directories (see :numref:`Table %s <FixDirectories>`) in ``$EXPTDIR``. The ``fix_lam`` directory is initially empty but will contain some *fix* (time-independent) files after the grid, orography, and/or surface climatology generation tasks run. 

.. _FixDirectories:

.. table::  Description of the fix directories

   +-------------------------+----------------------------------------------------------+
   | **Directory Name**      | **Description**                                          |
   +=========================+==========================================================+
   | fix_am                  | Directory containing the global fix (time-independent)   |
   |                         | data files. The experiment generation script copies      |
   |                         | these files from a machine-dependent system directory.   |
   +-------------------------+----------------------------------------------------------+
   | fix_lam                 | Directory containing the regional fix (time-independent) |
   |                         | data files that describe the regional grid, orography,   |
   |                         | and various surface climatology fields, as well as       |
   |                         | symlinks to pre-generated files.                         |
   +-------------------------+----------------------------------------------------------+

Once the Rocoto workflow is launched, several files and directories are generated. A log file named ``log.launch_FV3LAM_wflow`` will be created (unless it already exists) in ``$EXPTDIR``. The first several workflow tasks (i.e., ``make_grid``, ``make_orog``, ``make_sfc_climo``, ``get_extrn_ics``, and ``get_extrn_lbc``) are preprocessing tasks, and these tasks also result in the creation of new files and sub-directories, described in :numref:`Table %s <CreatedByWorkflow>`.

.. _CreatedByWorkflow:

.. table::  New directories and files created when the workflow is launched
   :widths: 30 70

   +---------------------------+--------------------------------------------------------------------+
   | **Directory/File Name**   | **Description**                                                    |
   +===========================+====================================================================+
   | YYYYMMDDHH                | This is a “cycle directory” that is updated when the first         |
   |                           | cycle-specific workflow tasks (``get_extrn_ics`` and               |
   |                           | ``get_extrn_lbcs``) are run. These tasks are launched              |
   |                           | simultaneously for each cycle in the experiment. Cycle directories |
   |                           | are created to contain cycle-specific files for each cycle that    |
   |                           | the experiment runs. If ``DATE_FIRST_CYCL`` and ``DATE_LAST_CYCL`` |
   |                           | are different, and/or if ``CYCL_HRS`` contains more than one       |
   |                           | element in the ``config.sh`` file, more than one cycle directory   |
   |                           | will be created under the experiment directory.                    |
   +---------------------------+--------------------------------------------------------------------+
   | grid                      | Directory generated by the ``make_grid`` task to store grid files  |
   |                           | for the experiment                                                 |
   +---------------------------+--------------------------------------------------------------------+
   | log                       | Contains log files generated by the overall workflow and by its    |
   |                           | various tasks. Look in these files to determine why a task may     |
   |                           | have failed.                                                       |
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
   | log.launch_FV3LAM_wflow   | The ``launch_FV3LAM_wflow.sh`` script appends its output to this   |
   |                           | log file each time it is called. Take a look at the last 30–50     |
   |                           | lines of this file to check the status of the workflow.            |
   +---------------------------+--------------------------------------------------------------------+

The output files for an experiment are described in :numref:`Section %s <OutputFiles>`.
The workflow tasks are described in :numref:`Section %s <WorkflowTaskDescription>`.


User Support, Documentation, and Contributions to Development
===============================================================

A forum-based, online `support system <https://forums.ufscommunity.org>`_ organized by topic provides a centralized location for UFS users and developers to post questions and exchange information. 

A list of available documentation is shown in :numref:`Table %s <list_of_documentation>`.

.. _list_of_documentation:

.. table::  Centralized list of documentation

   +----------------------------+---------------------------------------------------------------------------------+
   | **Documentation**          | **Location**                                                                    |
   +============================+=================================================================================+
   | UFS SRW Application        | https://ufs-srweather-app.readthedocs.io/en/develop/                            |
   | User's Guide               |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | UFS_UTILS Technical        | https://noaa-emcufs-utils.readthedocs.io/en/latest                              |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | UFS_UTILS Scientific       | https://ufs-community.github.io/UFS_UTILS/index.html                            |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | UFS Weather Model          | https://ufs-weather-model.readthedocs.io/en/latest                              |
   | User's Guide               |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | HPC-Stack Documentation    | https://hpc-stack.readthedocs.io/en/latest/                                     |
   +----------------------------+---------------------------------------------------------------------------------+
   | FV3 Scientific             | https://repository.library.noaa.gov/view/noaa/30725                             |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | FV3 Technical              | https://noaa-emc.github.io/FV3_Dycore_ufs-v2.0.0/html/index.html                |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | CCPP Scientific            | https://dtcenter.ucar.edu/GMTB/v6.0.0/sci_doc/index.html                        |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | CCPP Technical             | https://ccpp-techdoc.readthedocs.io/en/latest/                                  |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | Stochastic Physics         | https://stochastic-physics.readthedocs.io/en/release-public-v3/                 |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | ESMF manual                | https://earthsystemmodeling.org/docs/release/latest/ESMF_usrdoc/                |
   +----------------------------+---------------------------------------------------------------------------------+
   | Unified Post Processor     | https://upp.readthedocs.io/en/latest/                                           |
   +----------------------------+---------------------------------------------------------------------------------+

..
   COMMENT: Stochastic physics "latest" branch is noticeably behind the release/public-v3 branch, the link to the release branch is maintained here/throughout develop docs for now.

The UFS community is encouraged to contribute to the development effort of all related
utilities, model code, and infrastructure. Users can post issues in the related GitHub repositories to report bugs or to announce upcoming contributions to the code base. For code to be accepted in the authoritative repositories, users must follow the code management rules of each UFS component repository, which are outlined in the respective User's Guides listed in :numref:`Table %s <list_of_documentation>`. Contributions to the `ufs-srweather-app <https://github.com/ufs-community/ufs-srweather-app>`__ repository or the `regional_workflow <https://github.com/ufs-community/regional_workflow>`__ repository should follow the guidelines contained in the :ref:`SRW App Contributor's Guide <ContributorsGuide>`.

Future Direction
=================

Users can expect to see incremental improvements and additional capabilities in upcoming releases of the SRW Application to enhance research opportunities and support operational forecast implementations. Planned enhancements include:

* A more extensive set of supported developmental physics suites.
* A larger number of pre-defined domains/resolutions and a *fully supported* capability to create a user-defined domain.
* Add user-defined vertical levels (number and distribution).
* Inclusion of data assimilation and forecast restart/cycling capabilities.


.. bibliography:: references.bib




