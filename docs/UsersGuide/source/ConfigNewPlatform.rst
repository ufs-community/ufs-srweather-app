.. _ConfigNewPlatform:

============================
Configuring a New Platform
============================

The UFS SRW Application has been designed to work primarily on a number of Level 1 and 2 support platforms, listed `here <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__. However, it is also designed with flexibility in mind, so that any sufficiently up-to-date machine with a UNIX-based operating system should be capable of running the application. A full list of prerequisites for installing the UFS SRW App and running the Graduate Student Test can be found in :numref:`Section %s <SW-OS-Requirements>`.

The first step to installing on a new machine is to install the :term:`HPC-Stack` (https://github.com/NOAA-EMC/hpc-stack), which is a unified, shell script-based build system created and maintained by NCEP and EMC, which builds the software stack required for the SRW App and its components. HPC-Stack comes with a large number of prerequisites (see :numref:`Section %s <SW-OS-Requirements>` for more info), but the only required software prior to starting the installation process is as follows:

* Fortran compiler with support for Fortran 2003

   * gfortran v9+ or ifort v18+ are the only ones tested, but others may work.

* C and C++ compilers compatible with the Fortran compiler

   * gcc v9+, ifort v18+, and clang v9+ (macOS, native Apple clang or LLVM clang) have been tested

* Python v3.6+

   * Prerequisite packages must be downloaded: jinja2, yaml and f90nml, as well as a number of additional Python modules (see :numref:`Section %s <SW-OS-Requirements>`) if the user would like to use the provided graphics scripts

* Perl 5

* git v1.8+

* CMake v3.12+

   * CMake v3.15+ is needed for building NCEPLIBS, but versions as old as 3.12 can be used to build NCEPLIBS-external, which contains a newer CMake that can be used for the rest of the build.

For both Linux and macOS systems, users will need to set the stack size to "unlimited" (if allowed) or the largest possible value.

.. code-block:: console

   # Linux, if allowed
   ulimit -s unlimited

   # MacOS, this corresponds to 65MB
   ulimit -S -s unlimited

For Linux systems, as long as the above software is available, users can move on to the next step: installing the :term:`HPC-Stack` package according to the instructions in :numref:`Chapter %s <InstallBuildHPCstack>`.

For MacOS systems, some extra software is needed: ``gcc@11``, ``cmake``, ``make``, ``wget``, ``coreutils``, and ``pkg-config``. It is recommended that users install this software using the `Homebrew <https://brew.sh/>`__ package manager for MacOS:

* brew install gcc@11
* brew install cmake
* brew install make
* brew install wget
* brew install coreutils
* brew install pkg-config

.. 
   COMMENT: Is this still accurate? It seems like we should delete the last 2 and add openssl@3, Lmod, curl, libtiff.

However, it is also possible to install these utilities via `Macports <https://www.macports.org>`__ or by installing each utility individually (not recommended).


Installing the HPC-Stack
===========================
Prior to building the UFS SRW Application on a new machine, users will need to install the :term:`HPC-Stack`. Installation instructions appear in both the `HPC-Stack documentation <https://hpc-stack.readthedocs.io/en/latest/>`__ and in :numref:`Chapter %s <InstallBuildHPCstack>` of this User's Guide. The instructions will vary somewhat depending on the user's platform. However, in all cases, the process involves cloning the `HPC-Stack repository <https://github.com/NOAA-EMC/hpc-stack>`__, creating and entering a build directory, and invoking ``cmake`` and ``make`` to build the code. This process will create a number of modulefiles and scripts that will be used for setting up the build environment for the UFS SRW App. 

Once the HPC-Stack has been successfully installed, users can move on to building the UFS SRW Application.

.. note::
   The ``ESMFMKFILE`` variable allows HPC-Stack to find the location where ESMF has been built; if users receive a ``ESMF not found, abort`` error, they may need to specify a slightly different location:

   .. code-block:: console

      export ESMFMKFILE=${INSTALL_PREFIX}/lib64/esmf.mk

   Then they can delete and re-create the build directory and continue the build process as described above.

.. note::

   If users skipped the building of any of the software provided by HPC-Stack, they may need to add the appropriate locations to their ``CMAKE_PREFIX_PATH`` variable. Multiple directories may be added, separated by semicolons (;) as in the following example:

   .. code-block:: console

      cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=”${INSTALL_PREFIX};/location/of/other/software” -DOPENMP=ON .. 2>&1 | tee log.cmake

..
   COMMENT: Are these notes relevant now that NCEPLIBS/NCEPLIBS-external have been changed to HPC-Stack?

Building the UFS SRW Application 
=======================================

For a detailed explanation of how to build and run the SRW App on any supported system, see :numref:`Chapter %s <BuildRunSRW>`. The overall procedure for generating an experiment is shown in :numref:`Figure %s <AppOverallProc>`, with the scripts to generate and run the workflow shown in red. An overview of the required steps appears below. However, users can expect to access other referenced sections of this User's Guide for more detail. 

   #. Clone the SRW App from GitHub:

      .. code-block:: console

         git clone -b develop https://github.com/ufs-community/ufs-srweather-app.git

   #. Check out the external repositories:

      .. code-block:: console

         cd ufs-srweather-app
         ./manage_externals/checkout_externals

   #. Set up the build environment.

      .. code-block:: console

         source etc/lmod-setup.sh <machine>

      where <machine> refers to the user's platform (e.g., ``macos``, ``gaea``, ``odin``, ``singularity``). 

      Users will also need to load the "build" modulefile appropriate to their system. On Level 3 & 4 systems, users can adapt an existing modulefile (such as ``build_macos_gnu``) to their system. 

      .. code-block:: console

         module use <path/to/modulefiles/directory>
         module load build_<platform>_<compiler>

   #. Build the executables

      From the top-level ``ufs-srweather-app`` directory, run:

      .. code-block:: console

         mkdir build
         cd build
         cmake .. -DCMAKE_INSTALL_PREFIX=..
         make -j 4  >& build.out &

   #. Download and stage data (both the fix files and the :term:`IC/LBC` files) according to the instructions in :numref:`Chapter %s <DownloadingStagingInput>` (if on a Level 3-4 system).

      .. code-block:: console

         wget https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#fix/<path/to/fix/files>
         wget https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#input_model_data/FV3GFS/grib2/2019061518/<file_name>

   #. Configure the experiment parameters.

      .. code-block:: console

         cd regional_workflow/ush
         cp config.community.sh config.sh
      
      Users will need to adjust the experiment parameters in the ``config.sh`` file to suit the needs of their experiment (e.g., date, time, grid, physics suite, etc.). More detailed guidance is available in :numref:`Chapter %s <UserSpecificConfig>`. Parameters and valid values are listed in :numref:`Chapter %s <ConfigWorkflow>`. 

   #. Load the python environment for the regional workflow. Users on Level 3-4 systems will need to use one of the existing ``wflow_<platform>`` modulefiles (e.g., ``wflow_macos``) and adapt it to their system. 

      .. code-block:: console

         module use <path/to/modulefiles>
         module load wflow_<platform>
         conda activate regional_workflow

   #. Generate the experiment workflow. 

      .. code-block:: console

         ./generate_FV3LAM_wflow.sh

   #. Run the regional workflow. There are several methods available for this step, which are discussed in :numref:`Chapter %s <RocotoRun>` and :numref:`Chapter %s <RunUsingStandaloneScripts>`. One possible method is summarized below. It requires the Rocoto Workflow Manager. 

      .. code-block:: console

         cd $EXPTDIR
         ./launch_FV3LAM_wflow.sh

      To launch the workflow and check the experiment's progress:

      .. code-block:: console

         ./launch_FV3LAM_wflow.sh; tail -n 40 log.launch_FV3LAM_wflow

Optionally, users may `configure their own grid <UserDefinedGrid>`, instead of using a predefined grid, and `plot the output <Graphics>` of their experiment(s).


Background Knowledge Prerequisites
=====================================

In general, the instructions in this documentation assume that users have certain background knowledge. 

* Familiarity with LINUX/UNIX systems
* Command line basics
* System configuration knowledge (e.g., compilers, environment variables, paths, etc.)
* Meteorology & Numerical Weather Prediction

..
   COMMENT: Suggested sub-bullets for Meteorology/NWP? 

Additional background knowledge in the following areas could be helpful:
* High-Performance Computing (HPC) Systems for those running the SRW App on an HPC system
* Programming (particularly Python) for those interested in contributing to the SRW App code
* Creating an SSH Tunnel to access HPC systems from the command line
* Containerization
* Workflow Managers/Rocoto

.. _SW-OS-Requirements:

Software/Operating System Requirements
=======================================
Those requirements highlighted in **bold** are included in the `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__.

**Minimum platform requirements for the UFS SRW Application and NCEPLIBS:**

* POSIX-compliant UNIX-style operating system

* >40 GB disk space

   * 18 GB input data from GFS, RAP, and HRRR for Graduate Student Test
   * 6 GB for NCEPLIBS-external and NCEPLIBS full installation
   * 1 GB for ufs-srweather-app installation
   * 11 GB for 48hr forecast on CONUS 25km domain

* 4GB memory (CONUS 25km domain)

* Fortran compiler with full Fortran 2008 standard support

* C and C++ compiler

* Python v3.6+, including prerequisite packages ``jinja2``, ``pyyaml`` and ``f90nml``

* Perl 5

* git v1.8+

* MPI (**MPICH**, OpenMPI, or other implementation)

* CMake v3.15+

* Software libraries

   * **netCDF (C and Fortran libraries)**
   * **HDF5** 
   * **ESMF** 8.0.2
   * **Jasper**
   * **libJPG**
   * **libPNG**
   * **zlib**

..
   COMMENT: Update version of ESMF? Need other version updates?

macOS-specific prerequisites:

* brew install gcc@11
* brew install cmake
* brew install make
* brew install wget
* brew install coreutils
* brew install pkg-config

..
   COMMENT: Do we need these last 2? Are there others? (e.g., openssl@3?) Lmod, curl, libtiff

Optional but recommended prerequisites:

* Conda for installing/managing Python packages
* Bash v4+
* Rocoto Workflow Management System (1.3.1)
* **CMake v3.15+**
* Python packages ``scipy``, ``matplotlib``, ``pygrib``, ``cartopy``, and ``pillow`` for graphics
* Lmod

..
   COMMENT: Are we supporting any installations that don't use Lmod? Should this come under "required?" Or not because it is not mandatory for running the SRW App (but do we know that?).
