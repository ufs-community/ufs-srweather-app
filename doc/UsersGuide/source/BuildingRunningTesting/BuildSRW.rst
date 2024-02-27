.. _BuildSRW:

==========================
Building the SRW App
========================== 

The Unified Forecast System (:term:`UFS`) Short-Range Weather (SRW) Application is an :term:`umbrella repository` consisting of a number of different :ref:`components <Components>` housed in external repositories. Once the SRW App is built (i.e., components are assembled/compiled), users can configure experiments and generate predictions of atmospheric behavior over a limited spatial area and on time scales ranging from minutes out to several days. 

.. attention::

   The SRW Application has :srw-wiki:`four levels of support <Supported-Platforms-and-Compilers>`. The steps described in this chapter will work most smoothly on preconfigured (Level 1) systems. This chapter also provides guidance for running the SRW App on other systems (including generic Linux/Mac systems), but the user may need to perform additional steps and/or troubleshooting. 

.. note::
   The :ref:`container approach <QuickstartC>` is recommended for a smoother first-time build and run experience. Building without a container may allow for more customization. However, the non-container approach requires more in-depth system-based knowledge, especially on Level 3 and 4 systems, so it is less appropriate for beginners. 

To build the SRW App, users will complete the following steps:

   #. :ref:`Install prerequisites <StackInfo>`
   #. :ref:`Clone the SRW App from GitHub <DownloadSRWApp>`
   #. :ref:`Check out the external repositories <CheckoutExternals>`
   #. :ref:`Set up the build environment and build the executables <BuildExecutables>`

.. _AppBuildProc:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/WorkflowImages/SRW_build_process.png
   :alt: Flowchart describing the SRW App build process. 

   *Overview of the SRW App Build Process*


.. _StackInfo:

Install the Prerequisite Software Stack
==========================================

Users on any sufficiently up-to-date machine with a UNIX-based operating system should be able to install the prerequisite software stack and run the SRW Application. However, a list of prerequisites is available in :numref:`Section %s <software-prereqs>` for reference. Users should install or update their system as required before attempting to install the software stack. 

Currently, installation of the prerequisite software stack is supported via spack-stack on most systems. :term:`Spack-stack` is a :term:`repository` that provides a Spack-based system to build the software stack required for `UFS <https://ufscommunity.org/>`__ applications such as the SRW App. Spack-stack is the software stack validated by the UFS Weather Model (:term:`WM`), and the SRW App has likewise shifted to spack-stack for most Level 1 systems.

.. hint::
   Skip the spack-stack installation if working on a :srw-wiki:`Level 1 system <Supported-Platforms-and-Compilers>` (e.g., Hera, Jet, Derecho, NOAA Cloud), and :ref:`continue to the next section <DownloadSRWApp>`.

Background
----------------

SRW App components, including the UFS :term:`WM`, draw on over 50 code libraries to run. These libraries range from libraries developed in-house at NOAA (e.g., NCEPLIBS, FMS) to libraries developed by NOAA's partners (e.g., PIO, ESMF) to truly third-party libraries (e.g., netCDF). Individual installation of these libraries is not practical, so `spack-stack <https://github.com/JCSDA/spack-stack>`__ was developed as a central installation system to ensure that the infrastructure environment across multiple platforms is as similar as possible. Installation of spack-stack (or its predecessor, :term:`HPC-Stack`) is required to run the SRW App.

Instructions
-------------------------

.. attention::

   Spack-stack is the fully-supported software stack validated by the UFS WM as of `PR #1707 <https://github.com/ufs-community/ufs-weather-model/pull/1707>`__ on August 24, 2023. UFS applications are therefore shifting to :term:`spack-stack`, too. When all systems have shifted to spack-stack, support for HPC-Stack will be deprecated. Users are encouraged to check out `spack-stack <https://github.com/JCSDA/spack-stack>`__ to prepare for this shift in support from HPC-Stack to spack-stack even if their system currently has support for HPC-Stack. 

   As of the v2.2.0 release, spack-stack is supported in the SRW App on most Level 1 systems with the exception of Derecho, which uses HPC-Stack. Transition to spack-stack is underway for Derecho. Users on generic MacOS and Linux systems will find HPC-Stack-based modulefiles in the v2.2.0 release but can expect that these will also shift to spack-stack in the ``develop`` branch in the coming months. 

Users working on systems that fall under :srw-wiki:`Support Levels 2-4 <Supported-Platforms-and-Compilers>` will need to install spack-stack or HPC-Stack the first time they try to build applications (such as the SRW App) that depend on it. Users can build the stack on their local system or use the centrally maintained stacks on each HPC platform if they are working on a Level 1 system. Before installing spack-stack or HPC-Stack, users on both Linux and MacOS systems should set the stack size to "unlimited" (if allowed) or to the largest possible value:

.. code-block:: console

   # Linux, if allowed
   ulimit -s unlimited

   # MacOS, this corresponds to 65MB
   ulimit -S -s unlimited

For a detailed description of installation options, see :doc:`spack-stack instructions for configuring the stack on a new platform <spack-stack:NewSiteConfigs>` or :ref:`HPC-Stack installation instructions <InstallBuildHPCstack>`.

After completing installation, continue to the :ref:`next section <DownloadSRWApp>` to download the UFS SRW Application Code. 

.. _DownloadSRWApp:

Download the UFS SRW Application Code
======================================
The SRW Application source code is publicly available on GitHub. To download the SRW App code, clone the |branch| branch of the repository:

.. code-block:: console

   git clone -b develop https://github.com/ufs-community/ufs-srweather-app.git

The cloned repository contains the configuration files and sub-directories shown in
:numref:`Table %s <FilesAndSubDirs>`. The user may set an ``$SRW`` environment variable to point to the location of the new ``ufs-srweather-app`` repository. For example, if ``ufs-srweather-app`` was cloned into the ``$HOME`` directory, the following commands will set an ``$SRW`` environment variable in a bash or csh shell, respectively:

.. code-block:: console

    # In a bash shell, run:
    export SRW=$HOME/ufs-srweather-app
    # In a csh shell, run: 
    setenv SRW $HOME/ufs-srweather-app

.. _FilesAndSubDirs:

.. list-table:: Files and Subdirectories of the *ufs-srweather-app* Repository
   :widths: 20 50
   :header-rows: 1

   * - File/Directory Name
     - Description
   * - CMakeLists.txt
     - Main CMake file for SRW App
   * - devbuild.sh
     - SRW App build script
   * - devclean.sh
     - Convenience script that can be used to clean up code if something goes wrong when checking out externals or building the application.
   * - docs
     - Contains release notes, documentation, and User's Guide
   * - environment.yml
     - Contains information on the package versions required for the regional workflow environment.
   * - etc
     - Contains Lmod startup scripts
   * - Externals.cfg
     - Includes tags pointing to the correct version of the external GitHub repositories/branches used in the SRW App.
   * - jobs
     - Contains the *j-job* script for each workflow task. These scripts set up the environment variables and call an *ex-script* script located in the ``scripts`` subdirectory.
   * - LICENSE.md
     - CC0 license information
   * - manage_externals
     - Utility for checking out external repositories
   * - modulefiles
     - Contains build and workflow modulefiles
   * - parm
     - Contains parameter files. Includes UFS Weather Model configuration files such as ``model_configure``, ``diag_table``, and ``field_table``.
   * - README.md
     - Contains SRW App introductory information
   * - rename_model.sh
     - Used to rename the model before it is transitioned into operations. The SRW App is a generic app that is the base for models such as :term:`AQM` and :term:`RRFS`. When these models become operational, variables like ``HOMEdir`` and ``PARMdir`` will be renamed to ``HOMEaqm``/``HOMErrfs``, ``PARMaqm``/``PARMrrfs``, etc. using this script.
   * - scripts
     - Contains the *ex-script* for each workflow task. These scripts are where the task logic and executables are contained.
   * - sorc
     - Contains CMakeLists.txt; source code from external repositories is cloned into this directory.
   * - tests
     - Contains SRW App tests, including workflow end-to-end (WE2E) tests and unit tests.
   * - ufs_srweather_app_meta.h.in
     - Meta information for SRW App which can be used by other packages
   * - ufs_srweather_app.settings.in
     - SRW App configuration summary
   * - ush
     - Contains utility scripts. Includes the experiment configuration file and the experiment generation file.
   * - versions
     - Contains ``run.ver`` and ``build.ver`` files, which track package versions at run time and compile time, respectively.

.. _CheckoutExternals:

Check Out External Components
================================

The SRW App relies on a variety of components (e.g., UFS_UTILS, ufs-weather-model, and UPP) detailed in :numref:`Section %s <Components>` of this User's Guide. Each component has its own repository. Users must run the ``checkout_externals`` script to collect the individual components of the SRW App from their respective GitHub repositories. The ``checkout_externals`` script uses the configuration file ``Externals.cfg`` in the top-level directory of the SRW App to clone the correct tags (code versions) of the external repositories listed in :numref:`Section %s <HierarchicalRepoStr>` into the appropriate directories (e.g., ``ush``, ``sorc``).

Run the executable that pulls in SRW App components from external repositories:

.. code-block:: console

   cd /path/to/ufs-srweather-app/
   ./manage_externals/checkout_externals

The script should output dialogue indicating that it is retrieving different code repositories. It may take several minutes to download these repositories.

.. hint:: 

   Some systems (e.g., Hercules, Gaea) may have difficulty finding prerequisite software, such as python. If users run into this issue but know that the software exists on their system, they can run ``module load <module_name>`` followed by ``module save``. For example: 

   .. code-block:: console
      
      /usr/bin/env: ‘python’: No such file or directory
      hercules-login-1[10] username$ module load python
      hercules-login-1[11] username$ module save
      Saved current collection of modules to: "default", for system: "hercules"

To see more options for the ``checkout_externals`` script, users can run ``./manage_externals/checkout_externals -h``. For example:

   * ``-S``: Outputs the status of the repositories managed by ``checkout_externals``. By default, only summary information is provided. Use with the ``-v`` (verbose) option to see details.
   * ``-x [EXCLUDE [EXCLUDE ...]]``: allows users to exclude components when checking out externals. 
   * ``-o``: This flag will check out the optional external repositories in addition to the default repositories (by default, only the required external repositories are checked out).

Generally, users will not need to use these options and can simply run the script, but the options are available for those who are curious. 

.. _BuildExecutables:

Set Up the Environment and Build the Executables
===================================================

.. _DevBuild:

``devbuild.sh`` Approach
-----------------------------

On Level 1 systems for which a modulefile is provided under the ``modulefiles`` directory, users can build the SRW App binaries with the following command:

.. code-block:: console

   ./devbuild.sh --platform=<machine_name>

where ``<machine_name>`` is replaced with the name of the platform the user is working on. See :numref:`Section %s <user>` for all valid ``MACHINE`` options.

Directly following the release of SRW v2.2.0, the App will install miniconda and SRW environments as part
of the build process. The location defaults to inside the SRW clone in ``ufs-srweather-app/conda``,
however users can set any path on their system using the ``--conda-dir`` flag. If conda is already
installed in that location, conda installation will be skipped. The following example uses a
pre-installed conda installation at ``/path/to/conda``

.. code-block:: console

   ./devbuild.sh --platform=<machine_name> --conda-dir /path/to/conda

Running ``./devbuild.sh`` without any arguments will show the usage statement for all available
flags and targets for this script.

.. note::
   Although build modulefiles exist for generic Linux and MacOS machines, users will need to alter these according to the instructions in Sections :numref:`%s <CMakeApproach>` & :numref:`%s <MacLinuxDetails>`. Users on these systems may have more success building the SRW App with the :ref:`CMake Approach <CMakeApproach>` instead. 

If compiler auto-detection fails for some reason, specify it using the ``--compiler`` argument. For example:

.. code-block:: console

   ./devbuild.sh --platform=hera --compiler=intel

where valid values are ``intel`` or ``gnu``.

The last few lines of the console output should include ``[100%] Built target ufs-weather-model``, indicating that the UFS Weather Model executable has been built successfully. 

After running ``devbuild.sh``, the executables listed in :numref:`Table %s <ExecDescription>` should appear in the ``ufs-srweather-app/exec`` directory. If the application built properly, users may configure and run an experiment. Users have a few options: 

#. Proceed to :numref:`Section %s: Quick Start Guide <NCQuickstart>` for a quick overview of the workflow steps. 
#. Try the :ref:`SRW App Tutorials <Tutorial>` (good for new users!). 
#. For detailed information on running the SRW App, including optional tasks like plotting and verification, users can refer to :numref:`Section %s: Running the SRW App <RunSRW>`.

If the ``devbuild.sh`` build method did *not* work, or if users are not on a supported machine, they will have to manually set up the environment and build the SRW App binaries with CMake as described in :numref:`Section %s <CMakeApproach>`.

.. _ExecDescription:

.. table:: Names and descriptions of the executables produced by the build step and used by the SRW App

   +------------------------+---------------------------------------------------------------------------------+
   | **Executable Name**    | **Description**                                                                 |
   +========================+=================================================================================+
   | chgres_cube            | Reads in raw external model (global or regional) and surface climatology data   |
   |                        | to create initial and lateral boundary conditions                               |
   +------------------------+---------------------------------------------------------------------------------+
   | cpld_gridgen           | Creates the *fix* and :term:`IC <ICs>` files required for the coupled model.    |
   +------------------------+---------------------------------------------------------------------------------+
   | emcsfc_ice_blend       | Blends National Ice Center sea ice cover and EMC sea ice concentration data to  |
   |                        | create a global sea ice analysis used to update the GFS once per day            |
   +------------------------+---------------------------------------------------------------------------------+
   | emcsfc_snow2mdl        | Blends National Ice Center snow cover and Air Force snow depth data to create a |
   |                        | global depth analysis used to update the GFS snow field once per day            | 
   +------------------------+---------------------------------------------------------------------------------+
   | filter_topo            | Filters topography based on resolution                                          |
   +------------------------+---------------------------------------------------------------------------------+
   | fregrid                | Remaps data from the input mosaic grid to the output mosaic grid                |
   +------------------------+---------------------------------------------------------------------------------+
   | fvcom_to_FV3           | Determines lake surface conditions for the Great Lakes                          |
   +------------------------+---------------------------------------------------------------------------------+
   | global_cycle           | Updates the GFS surface conditions using external snow and sea ice analyses     |
   +------------------------+---------------------------------------------------------------------------------+
   | global_equiv_resol     | Calculates a global, uniform, cubed-sphere equivalent resolution for the        |
   |                        | regional Extended Schmidt Gnomonic (ESG) grid                                   |
   +------------------------+---------------------------------------------------------------------------------+
   | inland                 | Creates an inland land mask by determining inland (i.e., non-coastal) points    |
   |                        | and assigning a value of 1. Default value is 0.                                 |
   +------------------------+---------------------------------------------------------------------------------+
   | lakefrac               | Calculates the ratio of the lake area to the grid cell area at each atmospheric |
   |                        | grid point.                                                                     |
   +------------------------+---------------------------------------------------------------------------------+
   | make_hgrid             | Computes geo-referencing parameters (e.g., latitude, longitude, grid cell area) |
   |                        | for global uniform grids                                                        |
   +------------------------+---------------------------------------------------------------------------------+
   | make_solo_mosaic       | Creates mosaic files with halos                                                 |
   +------------------------+---------------------------------------------------------------------------------+
   | orog                   | Generates orography, land mask, and gravity wave drag files from fixed files    |
   +------------------------+---------------------------------------------------------------------------------+
   | orog_gsl               | Creates orographic statistics fields required for the orographic drag suite     |
   |                        | developed by NOAA's Global Systems Laboratory (GSL)                             |
   +------------------------+---------------------------------------------------------------------------------+
   | regional_esg_grid      | Generates an ESG regional grid based on a user-defined namelist                 |
   +------------------------+---------------------------------------------------------------------------------+
   | sfc_climo_gen          | Creates surface climatology fields from fixed files for use in ``chgres_cube``  |
   +------------------------+---------------------------------------------------------------------------------+
   | shave                  | Shaves the excess halo rows down to what is required for the lateral boundary   |
   |                        | conditions (LBCs) in the orography and grid files                               |
   +------------------------+---------------------------------------------------------------------------------+
   | ufs_model              | UFS Weather Model executable                                                    |
   +------------------------+---------------------------------------------------------------------------------+
   | upp.x                  | Post processor for the model output                                             |
   +------------------------+---------------------------------------------------------------------------------+
   | vcoord_gen             | Generates hybrid coordinate interface profiles                                  |
   +------------------------+---------------------------------------------------------------------------------+
   | weight_gen             | Creates ESMF SCRIP files for gaussian grids. These NetCDF-formatted files       |
   |                        | are used to create ESMF interpolation weight files.                             |
   +------------------------+---------------------------------------------------------------------------------+
   

.. _CMakeApproach:

CMake Approach
-----------------

Set Up the Build Environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. attention::
   * If users successfully built the executables listed in :numref:`Table %s <ExecDescription>`, they can skip to step :numref:`Section %s: Running the SRW App <RunSRW>`.
   * Users who want to build the SRW App on MacOS or generic Linux systems should skip to :numref:`Section %s <MacLinuxDetails>` and follow the approach there. 

If the ``devbuild.sh`` approach failed, users need to set up their environment to run a workflow on their specific platform. First, users should make sure ``Lmod`` is the app used for loading modulefiles. This is the case on most Level 1 systems; however, on systems such as Gaea/Odin, the default modulefile loader is from Cray and must be switched to Lmod. For example, on Gaea, users can run one of the following two commands depending on whether they have a bash or csh shell, respectively:

.. code-block:: console

   source /path/to/ufs-srweather-app/etc/lmod-setup.sh gaea
   source /path/to/ufs-srweather-app/etc/lmod-setup.csh gaea

.. note::

   If users execute one of the above commands on systems that don't need it, it will not cause any problems (it will simply do a ``module purge``). 

From here, ``Lmod`` is ready to load the modulefiles needed by the SRW App. These modulefiles are located in the ``modulefiles`` directory. To load the necessary modulefile for a specific ``<platform>`` using a given ``<compiler>``, run:

.. code-block:: console

   module use /path/to/ufs-srweather-app/modulefiles
   module load build_<platform>_<compiler>

where ``/path/to/ufs-srweather-app/modulefiles/`` is the full path to the ``modulefiles`` directory.

This will work on Level 1 systems, where a modulefile is available in the ``modulefiles`` directory. Users on Level 2-4 systems (including generic Linux/MacOS systems) will need to modify an appropriate ``build_<platform>_<compiler>`` modulefile. One of the current ``build_<platform>_<compiler>`` modulefiles can be copied and used as a template. However, users will need to adjust certain environment variables in their modulefile, such as the path to HPC-Stack, so that the SRW App can find and load the appropriate modules. 

.. note::

   These instructions assume that Lmod (an SRW App prerequisite) is installed. To check whether Lmod is installed, run ``echo $LMOD_PKG``, and see if it outputs a path to the Lmod package. On systems without Lmod, users can modify or set the required environment variables with the ``export`` or ``setenv`` commands, depending on whether they are using a bash or csh/tcsh shell, respectively: 

   .. code-block::

      export <VARIABLE_NAME>=<PATH_TO_MODULE>
      setenv <VARIABLE_NAME> <PATH_TO_MODULE>

   However, building the SRW App without Lmod is not supported at this time. It should be possible to do so, but it has not been tested. Users are encouraged to install Lmod on their system. 

.. _BuildCMake:

Build the Executables Using CMake
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

After setting up the build environment in the preceding section (by loading the ``build_<platform>_<compiler>`` modulefile), users need to build the executables required to run the SRW App. In the ``ufs-srweather-app`` directory, create a subdirectory to hold the build's executables: 

.. code-block:: console

   mkdir build
   cd build

From the build directory, run the following commands to build the pre-processing utilities, forecast model, and post-processor:

.. code-block:: console

   cmake .. -DCMAKE_INSTALL_PREFIX=.. -DCMAKE_INSTALL_BINDIR=exec ..
   make -j 4  >& build.out &

``-DCMAKE_INSTALL_PREFIX`` specifies the location where the ``exec``, ``include``, ``lib``, and ``share`` directories will be created. These directories will contain various components of the SRW App. Its recommended value ``..`` denotes one directory up from the ``build`` directory. In the next line, the ``make`` argument ``-j 4`` indicates that the build will run in parallel with four threads. Although users can specify a larger or smaller number of threads (e.g., ``-j 8``, ``-j 2``), it is highly recommended to use at least four parallel threads to prevent overly long installation times.

The build will take a few minutes to complete. When it starts, a random number is printed to the console, and when it is done, a ``[1]+  Done`` message is printed to the console. ``[1]+  Exit`` indicates an error. Output from the build will be in the ``ufs-srweather-app/build/build.out`` file. When the build completes, users should see the forecast model executable ``ufs_model`` and several pre- and post-processing executables in the ``ufs-srweather-app/exec`` directory. These executables are described in :numref:`Table %s <ExecDescription>`. 

.. hint::

   If you see the ``build.out`` file, but there is no ``ufs-srweather-app/exec`` directory, wait a few more minutes for the build to complete.

.. _MacLinuxDetails:

Additional Details for Building on MacOS or Generic Linux
------------------------------------------------------------

.. note::
    Users who are **not** building the SRW App on MacOS or generic Linux platforms may skip to :numref:`Section %s <BuildExecutables>` to finish building the SRW App or continue to :numref:`Section %s <RunSRW>` to configure and run an experiment if they have already built the App. 

The SRW App can be built on MacOS and generic Linux machines after the prerequisite software has been installed on these systems (via :term:`HPC-Stack` or :term:`spack-stack`). The installation for MacOS is architecture-independent and has been tested using both x86_64 and M1 chips (running natively). The following configurations for MacOS have been tested:

   #. MacBookPro 2019, 2.4 GHz 8-core Intel Core i9 (x86_64), OS Monterey 12.6.1, 32 GB RAM; GNU compiler suite v.12.3.0 (gcc, gfortran, g++); openmpi/4.1.5
   #. MacBookAir 2020, M1 chip (arm64, running natively), 4+4 cores, OS Ventura 13.0.1, 16 GB RAM; GNU compiler suite v.12.3.0 (gcc, gfortran, g++); openmpi/4.1.5

Several Linux builds have been tested on systems with x86_64 architectures.

The ``$SRW/modulefiles/build_<platform>_gnu.lua`` modulefile (where ``<platform>`` is ``macos`` or ``linux``) is written as a Lmod module in the Lua language. It can be loaded once the Lmod module environment has been initialized (which should have happened even prior to :ref:`installing HPC-Stack <StackInfo>`). The ``build_<platform>_gnu`` modulefile lists the location of the HPC-Stack modules, loads the meta-modules and modules, sets serial and parallel compilers, additional flags, and any environment variables needed for building the SRW App. The modulefile must be modified to include the absolute path to the user's HPC-Stack installation:

.. code-block:: console

   - This path should point to your HPCstack installation directory
   local HPCstack="/Users/username/hpc-stack/install"
   
Linux users need to configure the ``ufs-srweather-app/etc/lmod-setup.sh`` file for the ``linux`` case and set the ``BASH_ENV`` variable to point to the Lmod initialization script. There is no need to modify this script for the ``macos`` case presuming that Lmod followed a standard installation procedure using the Homebrew package manager for MacOS.

Next, users must source the Lmod setup file, just as they would on other systems, and load the modulefiles needed for building and running the SRW App:

.. code-block:: console
   
   source /path/to/ufs-srweather-app/etc/lmod-setup.sh <platform>
   module use /path/to/ufs-srweather-app/modulefiles
   module load build_<platform>_gnu
   export LDFLAGS+=" -L${MPI_ROOT}/lib "

In a csh/tcsh shell, users would run ``source etc/lmod-setup.csh <platform>`` in place of the first line in the code block above. The last line is primarily needed for the MacOS platforms.

Proceed to building the executables using the process outlined in :numref:`Step %s <BuildCMake>`.

Run an Experiment
=====================

To configure and run an experiment, users have a few options: 

#. Proceed to :numref:`Section %s: Quick Start Guide <NCQuickstart>` for a quick overview of the workflow steps. 
#. Try the :ref:`SRW App Tutorials <Tutorial>` (good for new users!). 
#. For detailed information on running the SRW App, including optional tasks like plotting and verification, users can refer to :numref:`Section %s: Running the SRW App <RunSRW>`.
