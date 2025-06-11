.. _BuildSRW:

==========================
Building the SRW App
========================== 

The Unified Forecast System (:term:`UFS`) Short-Range Weather (SRW) Application is an :term:`umbrella repository` consisting of a number of different :ref:`components <Components>` housed in external repositories. Once the SRW App is built (i.e., components are assembled/compiled), users can configure experiments and generate predictions of atmospheric behavior over a limited spatial area and on time scales ranging from minutes out to several days. 

.. attention::

   The SRW Application has :srw-wiki:`four levels of support <Supported-Platforms-and-Compilers>`. The steps described in this chapter will work most smoothly on preconfigured (Level 1) systems.

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

Currently, installation of the prerequisite software stack is supported via spack-stack on most systems. :term:`Spack-stack` is a :term:`repository` that provides a Spack-based system to build the software stack required for `UFS <https://ufs.epic.noaa.gov/>`_ applications such as the SRW App. Spack-stack is the software stack validated by the UFS Weather Model (:term:`WM`), and the SRW App has likewise shifted to spack-stack for most Level 1 systems.

.. hint::
   Skip the spack-stack installation if working on a :srw-wiki:`Level 1 system <Supported-Platforms-and-Compilers>` (e.g., Hera, Jet, Derecho, NOAA Cloud), and :ref:`continue to the next section <DownloadSRWApp>`.

Background
----------------

SRW App components, including the UFS :term:`WM`, draw on over 50 code libraries to run. These libraries range from libraries developed in-house at NOAA (e.g., NCEPLIBS, FMS) to libraries developed by NOAA's partners (e.g., PIO, ESMF) to truly third-party libraries (e.g., netCDF). Individual installation of these libraries is not practical, so `spack-stack <https://github.com/JCSDA/spack-stack>`__ was developed as a central installation system to ensure that the infrastructure environment across multiple platforms is as similar as possible. Installation of spack-stack is required to run the SRW App.

Instructions
-------------------------

Users working on systems that fall under :srw-wiki:`Support Levels 2-4 <Supported-Platforms-and-Compilers>` will need to install spack-stack the first time they try to build applications (such as the SRW App) that depend on it. Users can build the stack on their local system or use the centrally maintained stacks on each HPC platform if they are working on a Level 1 system.

For a detailed description of installation options, see :doc:`spack-stack instructions for configuring the stack on a new platform <spack-stack:NewSiteConfigs>`.

After completing installation, continue to the :ref:`next section <DownloadSRWApp>` to download the UFS SRW Application Code. 

.. _DownloadSRWApp:

Download the UFS SRW Application Code
======================================
The SRW Application source code is publicly available on GitHub. To download the SRW App code, clone the |branch| branch of the repository:

.. include:: ../../doc-snippets/clone.rst

The cloned repository contains the configuration files and sub-directories shown in
:numref:`Table %s <FilesAndSubDirs>`. The user may set an ``$SRW`` environment variable to point to the location of the new ``ufs-srweather-app`` repository. For example, if ``ufs-srweather-app`` was cloned into the ``$HOME`` directory, the following commands will set an ``$SRW`` environment variable in a bash or csh shell, respectively:

.. code-block:: console

    # In a bash shell, run:
    export SRW=$HOME/ufs-srweather-app

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

.. include:: ../../doc-snippets/externals.rst

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

.. include:: ../../doc-snippets/devbuild.rst

Directly following the release of SRW v2.2.0, the App will install miniconda and SRW environments as part
of the build process. The location defaults to inside the SRW clone in ``ufs-srweather-app/conda``,
however users can set any path on their system using the ``--conda-dir`` flag. If conda is already
installed in that location, conda installation will be skipped. The following example uses a
pre-installed conda installation at ``/path/to/conda``

.. code-block:: console

   ./devbuild.sh --platform=<machine_name> --conda-dir /path/to/conda

Running ``./devbuild.sh`` without any arguments will show the usage statement for all available
flags and targets for this script.

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

If the ``devbuild.sh`` approach failed, users need to set up their environment to run a workflow on their specific platform. First, users should make sure ``Lmod`` is the app used for loading modulefiles. This is the case on most Level 1 systems; however, on systems such as Gaea, the default modulefile loader is from Cray and must be switched to Lmod. For example, on Gaea, users with a bash shell environment can run:

.. code-block:: console

   source /path/to/ufs-srweather-app/etc/lmod-setup.sh gaea

.. note::

   If users source the lmod-setup file on systems that don't need it, it will not cause any problems (it will simply do a ``module purge``). 

From here, ``Lmod`` is ready to load the modulefiles needed by the SRW App. These modulefiles are located in the ``modulefiles`` directory. To load the necessary modulefile for a specific ``<platform>`` using a given ``<compiler>``, run:

.. code-block:: console

   module use /path/to/ufs-srweather-app/modulefiles
   module load build_<platform>_<compiler>

where ``/path/to/ufs-srweather-app/modulefiles/`` is the full path to the ``modulefiles`` directory.

This will work on Level 1 systems, where a modulefile is available in the ``modulefiles`` directory. Users on Level 2-4 systems will need to modify an appropriate ``build_<platform>_<compiler>`` modulefile. One of the current ``build_<platform>_<compiler>`` modulefiles can be copied and used as a template. However, users will need to adjust certain environment variables in their modulefile, such as the path to the software stack, so that the SRW App can find and load the appropriate modules. 

.. note::

   These instructions assume that Lmod (an SRW App prerequisite) is installed. To check whether Lmod is installed, run ``echo $LMOD_PKG``, and see if it outputs a path to the Lmod package. Building the SRW App without Lmod is not supported at this time. It should be possible to do so, but it has not been tested. Users are encouraged to install Lmod on their system. 

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

There are a few additional steps needed to successfully run the SRW App that is built with CMake. The ``build_settings.yaml`` will need to be copied or symlinked from ``ufs-srweather-app/build`` to ``ufs-srweather-app/exec directory``, and the platform name needs to be added to the "Machine" variable in the ``build_settings.yaml`` file.

.. _install-uw:

Install ``uwtools``
^^^^^^^^^^^^^^^^^^^^

The :uw:`UW Tools documentation <sections/user_guide/installation.html>` has the most up-to-date installation instructions. Users should refer to that documentation as authoritative. The UW team welcomes questions in its :uw-repo:`GitHub Discussions <discussions>` forum. See :numref:`Section %s <uwtools>` for more information on ``uwtools`` in the SRW App.

For convenience, a suggested procedure is included below for users who do not have ``uwtools`` or ``conda`` installed. However, in the event of problems, refer to the UW Tools documentation and forums. 

#. Run ``uname -om`` to determine the system's operating system and architecture.
#. Go to the `Miniforge releases page <https://github.com/conda-forge/miniforge/releases>`_ and download the desired version of Miniforge. For example:

   .. code-block:: console
      
      wget https://github.com/conda-forge/miniforge/releases/download/24.11.2-1/Miniforge3-24.11.2-1-Linux-x86_64.sh

#. Run the shell script to install ``conda``. For example:

   .. code-block:: console

      bash Miniforge3-24.11.2-1-Linux-x86_64.sh -bfp $PWD/conda 
   
   Users should replace ``Miniforge3-24.11.2-1-Linux-x86_64.sh`` with the name of the file they downloaded. 
#. Remove the installation script, e.g., by running: ``rm Miniforge3-24.11.2-1-Linux-x86_64.sh``.
#. Run: 

   .. code-block:: console
      
      source conda/etc/profile.d/conda.sh
      conda activate
      cd ufs-srweather-app/conda/envs
      conda create -n srw_app -c ufs-community -c conda-forge --override-channels uwtools=<X.Y.Z>
   
   where ``<X.Y.Z>`` is the desired version number. (It may be necessary to create the ``conda/envs`` directory within the ``ufs-srweather-app`` using the ``mkdir`` command if it does not already exist.)
   Hit ``y`` to continue installation. 

#. Create the ``conda_loc`` file which is the location of the conda directory and is used as part of the ``wflow_<platform>`` modulefile. If the user used the build location ``$PWD/conda`` from step 3, then they can run the following ``realpath ../conda`` to get the conda directory path. After obtaining the conda directory path, users can create the ``conda_loc by`` doing the following:

   .. code-block:: console
      
      # cd back ufs-srweather-app
      cd ../../
      vi conda_loc
      # paste the conda directory path
      # save the file

Run an Experiment
=====================

To configure and run an experiment, users have a few options: 

#. Proceed to :numref:`Section %s: Quick Start Guide <NCQuickstart>` for a quick overview of the workflow steps. 
#. Try the :ref:`SRW App Tutorials <Tutorial>` (good for new users!). 
#. For detailed information on running the SRW App, including optional tasks like plotting and verification, users can refer to :numref:`Section %s: Running the SRW App <RunSRW>`.
