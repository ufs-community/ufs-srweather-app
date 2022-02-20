.. _ConfigNewPlatform:

==========================
Configuring a New Platform
==========================

The UFS SRW Application has been designed to work primarily on a number of Level 1 and 2 support platforms, as specified `here <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_. However, it is also designed with flexibility in mind, so that any sufficiently up-to-date machine with a UNIX-based operating system should be capable of running the application. A full list of prerequisites for installing the UFS SRW App and running the Graduate Student Test can be found in :numref:`Section %s <SW-OS-Requirements>`.

The first step to installing on a new machine is to install :term:`NCEPLIBS` (https://github.com/NOAA-EMC/NCEPLIBS), the NCEP libraries package, which is a set of libraries created and maintained by NCEP and EMC that are used in many parts of the UFS. NCEPLIBS comes with a large number of prerequisites (see :numref:`Section %s <SW-OS-Requirements>` for more info), but the only required software prior to starting the installation process are as follows:

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

For both Linux and macOS, you will need to set the stack size to "unlimited" (if allowed) or the largest possible value.

.. code-block:: console

   # Linux, if allowed
   ulimit -s unlimited

   # macOS, this corresponds to 65MB
   ulimit -S -s unlimited

For Linux systems, as long as the above software is available, you can move on to the next step: installing the :term:`NCEPLIBS-external` package.

For macOS systems, some extra software is needed: ``wget``, ``coreutils``, ``pkg-config``, and ``gnu-sed``.
It is recommended that you install this software using the Homebrew package manager for macOS (https://brew.sh/):

* brew install wget

* brew install cmake

* brew install coreutils

* brew install pkg-config

* brew install gnu-sed

However, it is also possible to install these utilities via Macports (https://www.macports.org/), or installing each utility individually (not recommended).

Installing NCEPLIBS-external
============================
In order to facilitate the installation of NCEPLIBS (and therefore, the SRW and other UFS applications) on new platforms, EMC maintains a one-stop package containing most of the prerequisite libraries and software necessary for installing NCEPLIBS. This package is known as NCEPLIBS-external, and is maintained in a git repository at https://github.com/NOAA-EMC/NCEPLIBS-external. Instructions for installing these will depend on your platform, but generally so long as all the above-mentioned prerequisites have been installed you can follow the proceeding instructions verbatim (in bash; a csh-based shell will require different commands). Some examples for installing on specific platforms can be found in the `NCEPLIBS-external/doc directory <https://github.com/NOAA-EMC/NCEPLIBS-external/tree/release/public-v2/doc>`.


These instructions will install the NCEPLIBS-external in the current directory tree, so be sure you are in the desired location before starting.

.. code-block:: console

   export WORKDIR=`pwd`
   export INSTALL_PREFIX=${WORKDIR}/NCEPLIBS-ufs-v2.0.0/
   export CC=gcc
   export FC=gfortran
   export CXX=g++

The CC, CXX, and FC variables should specify the C, C++, and Fortran compilers you will be using, respectively. They can be the full path to the compiler if necessary (for example, on a machine with multiple versions of the same compiler). It will be important that all libraries and utilities are built with the same set of compilers, so it is best to set these variables once at the beginning of the process and not modify them again.

.. code-block:: console

   mkdir -p ${INSTALL_PREFIX}/src && cd ${INSTALL_PREFIX}/src
   git clone -b release/public-v2 --recursive https://github.com/NOAA-EMC/NCEPLIBS-external
   cd NCEPLIBS-external
   mkdir build && cd build
   cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} .. 2>&1 | tee log.cmake
   make -j4 2>&1 | tee log.make

The previous commands go through the process of cloning the git repository for NCEPLIBS-external, creating and entering a build directory, and invoking cmake and make to build the code/libraries. The ``make`` step will take a while; as many as a few hours depending on your machine and various settings. It is highly recommended you use at least 4 parallel make processes to prevent overly long installation times. The ``-j4`` option in the make command specifies 4 parallel make processes, ``-j8`` would specify 8 parallel processes, while omitting the flag all together will run make serially (not recommended).

If you would rather use a different version of one or more of the software packages included in NCEPLIBS-external, you can skip building individual parts of the package by including the proper flags in your call to cmake. For example: 

.. code-block:: console

   cmake -DBUILD_MPI=OFF -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} .. 2>&1 | tee log.cmake

will skip the building of MPICH that comes with NCEPLIBS-external. See the readme file ``NCEPLIBS-external/README.md`` for more information on these flags, or for general troubleshooting.

Once NCEPLIBS-external is installed, you can move on to installing NCEPLIBS.

Installing NCEPLIBS
===================
Prior to building the UFS SRW Application on a new machine, you will need to install NCEPLIBS. Installation instructions will again depend on your platform, but so long as NCEPLIBS-external has been installed successfully you should be able to build NCEPLIBS. The following instructions will install the NCEPLIBS in the same directory tree as was used for NCEPLIBS-external above, so if you did not install NCEPLIBS-external in the same way, you will need to modify these commands.

.. code-block:: console

   cd ${INSTALL_PREFIX}/src
   git clone -b release/public-v2 --recursive https://github.com/NOAA-EMC/NCEPLIBS
   cd NCEPLIBS
   mkdir build && cd build
   export ESMFMKFILE=${INSTALL_PREFIX}/lib/esmf.mk
   cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} -DOPENMP=ON .. 2>&1 | tee log.cmake
   make -j4 2>&1 | tee log.make
   make deploy 2>&1 | tee log.deploy

As with NCEPLIBS-external, the above commands go through the process of cloning the git repository for NCEPLIBS, creating and entering a build directory, and invoking cmake and make to build the code. The ``make deploy`` step created a number of modulefiles and scripts that will be used for setting up the build environment for the UFS SRW App. The ``ESMFMKFILE`` variable allows NCEPLIBS to find the location where ESMF has been built; if you receive a ``ESMF not found, abort`` error, you may need to specify a slightly different location:

.. code-block:: console

   export ESMFMKFILE=${INSTALL_PREFIX}/lib64/esmf.mk

Then delete and re-create the build directory and continue the build process as described above.

If you skipped the building of any of the software provided by NCEPLIBS-external, you may need to add the appropriate locations to your ``CMAKE_PREFIX_PATH`` variable. Multiple directories may be added, separated by semicolons (;) like in the following example:

.. code-block:: console

   cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=”${INSTALL_PREFIX};/location/of/other/software” -DOPENMP=ON .. 2>&1 | tee log.cmake

Further information on including prerequisite libraries, as well as other helpful tips, can be found in the ``NCEPLIBS/README.md`` file.

Once the NCEPLIBS package has been successfully installed, you can move on to building the UFS SRW Application.

Building the UFS Short-Range Weather Application (UFS SRW App)
==============================================================
Building the UFS SRW App is similar to building NCEPLIBS, in that the code is stored in a git repository and is built using CMake software. The first step is to retrieve the code from GitHub, using the variables defined earlier:

.. code-block:: console

   cd ${WORKDIR}
   git clone -b release/public-v1 https://github.com/ufs-community/ufs-srweather-app.git
   cd ufs-srweather-app/
   ./manage_externals/checkout_externals

Here the procedure differs a bit from NCEPLIBS and NCEPLIBS-external. The UFS SRW App is maintained using an umbrella git repository that collects the individual components of the application from their individual, independent git repositories. This is handled using "Manage Externals" software, which is included in the application; this is the final step listed above, which should output a bunch of dialogue indicating that it is retrieving different code repositories as described in :numref:`Table %s <top_level_repos>`. It may take several minutes to download these repositories.

Once the Manage Externals step has completed, you will need to make sure your environment is set up so that the UFS SRW App can find all of the prerequisite software and libraries. There are a few ways to do this, the simplest of which is to load a modulefile if your machine supports Lua Modules:

.. code-block:: console

   module use ${INSTALL_PREFIX}/modules
   module load NCEPLIBS/2.0.0

If your machine does not support Lua but rather TCL modules, see instructions in the ``NCEPLIBS/README.md`` file for converting to TCL modulefiles.

If your machine does not support modulefiles, you can instead source the provided bash script for setting up the environment:

.. code-block:: console

   source ${INSTALL_PREFIX}/bin/setenv_nceplibs.sh

This script, just like the modulefiles, will set a number of environment variables that will allow CMake to easily find all the libraries that were just built. There is also a csh version of the script in the same directory if your shell is csh-based. If you are using your machine’s pre-built version of any of the NCEP libraries (not recommended), reference that file to see which variables should be set to point CMake in the right direction.

At this point there are just a few more variables that need to be set prior to building:

.. code-block:: console

   export CMAKE_C_COMPILER=mpicc
   export CMAKE_CXX_COMPILER=mpicxx
   export CMAKE_Fortran_COMPILER=mpifort

If you are using your machine’s built-in MPI compilers, it is recommended you set the ``CMAKE_*_COMPILER`` flags to full paths to ensure that the correct MPI aliases are used. Finally, one last environment variable, ``CMAKE_Platform``, must be set. This will depend on your machine; for example, on a macOS operating system with GNU compilers:

.. code-block:: console

   export CMAKE_Platform=macosx.gnu

This is the variable used by the weather model to set a few additional flags based on your machine. The available options can be found `here <https://github.com/ufs-community/ufs-weather-model/tree/release/public-v2/modulefiles>`_. 

Now all the prerequisites have been installed and variables set, so you should be ready to build the model!

.. code-block:: console

   mkdir build && cd build
   cmake .. -DCMAKE_INSTALL_PREFIX=.. | tee log.cmake
   make -j4 | tee log.make

On many platforms this build step will take less than 30 minutes, but for some machines it may take up to a few hours, depending on the system architecture, compiler and compiler flags, and number of parallel make processes used.

Setting Up Your Python Environment
==================================
The regional_workflow repository contains scripts for generating and running experiments, and these require some specific python packages to function correctly. First, as mentioned before, your platform will need Python 3.6 or newer installed. Once this is done, you will need to install several python packages that are used by the workflow: ``jinja2`` (https://jinja2docs.readthedocs.io/), ``pyyaml`` (https://pyyaml.org/wiki/PyYAML), and ``f90nml`` (https://pypi.org/project/f90nml/). These packages can be installed individually, but it is recommended you use a package manager (https://www.datacamp.com/community/tutorials/pip-python-package-manager).

If you have conda on your machine:

.. code-block:: console

   conda install jinja2 pyyaml f90nml

Otherwise you may be able to use pip3 (the Python3 package manager; may need to be installed separately depending on your platform):

.. code-block:: console

   pip3 install jinja2 pyyaml f90nml

Running the graphics scripts in ``${WORKDIR}/ufs-srweather-app/regional_workflow/ush/Python`` will require the additional packages ``pygrib``, ``cartopy``, ``matplotlib``, ``scipy``, and ``pillow``. These can be installed in the same way as described above.

For the final step of creating and running an experiment, the exact methods will depend on if you are running with or without a workflow manager (Rocoto).

Running Without a Workflow Manager: Generic Linux and macOS Platforms
=====================================================================
Now that the code has been built, you can stage your data as described in :numref:`Section %s <DownloadingStagingInput>`.

Once the data has been staged, setting up your experiment on a platform without a workflow manager is similar to the procedure for other platforms described in earlier chapters. Enter the ``${WORKDIR}/ufs-srweather-app/regional_workflow/ush`` directory and configure the workflow by creating a ``config.sh`` file as described in :numref:`Chapter %s <ConfigWorkflow>`. There will be a few specific settings that you may need change prior to generating the experiment compared to the instructions for pre-configured platforms:

``MACHINE="MACOS" or MACHINE="LINUX"``
  These are the two ``MACHINE`` settings for generic, non-Rocoto-based platforms; you should choose the one most appropriate for your machine. ``MACOS`` has its own setting due to some differences in how command-line utilities function on Darwin-based operating systems.

``LAYOUT_X=2``
``LAYOUT_Y=2``
  These are the settings that control the MPI decomposition when running the weather model. There are default values, but for your machine it is recommended that you specify your own layout to achieve the correct number of MPI processes for your application.  In total, your machine should be able to handle ``LAYOUT_X×LAYOUT_Y+WRTCMP_write_tasks_per_group`` tasks. ``WRTCMP_write_tasks_per_group`` is the number of MPI tasks that will be set aside for writing model output, and it is a setting dependent on the domain you have selected. You can find and edit the value of this variable in the file ``regional_workflow/ush/set_predef_grid_params.sh``.

``RUN_CMD_UTILS="mpirun -np 4"``
  This is the run command for MPI-enabled pre-processing utilities. Depending on your machine and your MPI installation, you may need to use a different command for launching an MPI-enabled executable.

``RUN_CMD_POST="mpirun -np 1"``
  This is the same as RUN_CMD_UTILS but for UPP.

``RUN_CMD_FCST='mpirun -np ${PE_MEMBER01}'``
  This is the run command for the weather model. It is **strongly** recommended that you use the variable ``${PE_MEMBER01}`` here, which is calculated within the workflow generation script (based on the layout and write tasks described above) and is the number of MPI tasks that the weather model will expect to run with. Running the weather model with a different number of MPI tasks than the workflow has been set up for can lead to segmentation faults and other errors.  It is also important to use single quotes here (or escape the “$” character) so that ``PE_MEMBER01`` is not referenced until runtime, since it is not defined at the beginning of the workflow generation script.

``FIXgsm=${WORKDIR}/data/fix_am``
  The location of the ``fix_am`` static files. This and the following two static data sets will need to be downloaded to your machine, as described in :numref:`Section %s <StaticFixFiles>`.

``TOPO_DIR=${WORKDIR}/data/fix_orog``
  Location of ``fix_orog`` static files

``SFC_CLIMO_INPUT_DIR=${WORKDIR}/data/fix_sfc_climo``
  Location of ``climo_fields_netcdf`` static files

Once you are happy with your settings in ``config.sh``, it is time to run the workflow and move to the experiment directory (that is printed at the end of the script’s execution):

.. code-block:: console

   ./generate_FV3LAM_wflow.sh
   export EXPTDIR="your experiment directory"
   cd $EXPTDIR

From here, you can run each individual task of the UFS SRW App using the provided run scripts:

.. code-block:: console

   cp ${WORKDIR}/ufs-srweather-app/regional_workflow/ush/wrappers/*sh .
   cp ${WORKDIR}/ufs-srweather-app/regional_workflow/ush/wrappers/README.md .

The ``README.md`` file will contain instructions on the order that each script should be run in. An example of wallclock times for each task for an example run (2017 Macbook Pro, macOS Catalina, 25km CONUS domain, 48hr forecast) is listed in :numref:`Table %s <WallClockTimes>`.

.. _WallClockTimes:

.. table::  Example wallclock times for each workflow task.


   +--------------------+----------------------------+------------+-----------+
   | **UFS Component**  | **Script Name**            | **Num.**   | **Wall**  |
   |                    |                            | **Cores**  | **time**  |
   +====================+============================+============+===========+
   | UFS_UTILS          | ./run_get_ics.sh           | n/a        | 3 s       |
   +--------------------+----------------------------+------------+-----------+
   | UFS_UTILS          | ./run_get_lbcs.sh          | n/a        | 3 s       |
   +--------------------+----------------------------+------------+-----------+
   | UFS_UTILS          | ./run_make_grid.sh         | n/a        | 9 s       |
   +--------------------+----------------------------+------------+-----------+
   | UFS_UTILS          | ./run_make_orog.sh         | 4          | 1 m       |
   +--------------------+----------------------------+------------+-----------+
   | UFS_UTILS          | ./run_make_sfc_climo.sh    | 4          | 27 m      |
   +--------------------+----------------------------+------------+-----------+
   | UFS_UTILS          | ./run_make_ics.sh          | 4          | 5 m       |
   +--------------------+----------------------------+------------+-----------+
   | UFS_UTILS          | ./run_make_lbcs.sh         | 4          | 5 m       |
   +--------------------+----------------------------+------------+-----------+
   | ufs-weather-model  | ./run_fcst.sh              | 6          | 1h 40 m   |
   +--------------------+----------------------------+------------+-----------+
   | UPP                | ./run_post.sh              | 1          | 7 m       |
   +--------------------+----------------------------+------------+-----------+

Running on a New Platform with Rocoto Workflow Manager
======================================================
All official HPC platforms for the UFS SRW App release make use of the Rocoto workflow management software for running experiments. If you would like to use the Rocoto workflow manager on a new machine, you will have to make modifications to the scripts in the ``regional_workflow`` repository. The easiest way to do this is to search the files in the ``regional_workflow/scripts`` and ``regional_workflow/ush`` directories for an existing platform name (e.g. ``CHEYENNE``) and add a stanza for your own unique machine (e.g. ``MYMACHINE``). As an example, here is a segment of code from ``regional_workflow/ush/setup.sh``, where the highlighted text is an example of the kind of change you will need to make:

.. code-block:: console
   :emphasize-lines: 11-18

   ...
     "CHEYENNE")
       WORKFLOW_MANAGER="rocoto"
       NCORES_PER_NODE=36
       SCHED="${SCHED:-pbspro}"
       QUEUE_DEFAULT=${QUEUE_DEFAULT:-"regular"}
       QUEUE_HPSS=${QUEUE_HPSS:-"regular"}
       QUEUE_FCST=${QUEUE_FCST:-"regular"}
       ;;
    
     "MYMACHINE")
       WORKFLOW_MANAGER="rocoto"
       NCORES_PER_NODE=your_machine_cores_per_node
       SCHED="${SCHED:-your_machine_scheduler}"
       QUEUE_DEFAULT=${QUEUE_DEFAULT:-"your_machine_queue_name"}
       QUEUE_HPSS=${QUEUE_HPSS:-"your_machine_queue_name"}
       QUEUE_FCST=${QUEUE_FCST:-"your_machine_queue_name"}
       ;;
   
      "STAMPEDE")
        WORKFLOW_MANAGER="rocoto"
   ...

You will also need to add ``MYMACHINE`` to the list of valid machine names in ``regional_workflow/ush/valid_param_vals.sh``. The minimum list of files that will need to be modified in this way are as follows (all in the ``regional_workflow`` repository):

* ``scripts/exregional_run_post.sh``, line 131
* ``scripts/exregional_make_sfc_climo.sh``, line 162
* ``scripts/exregional_make_lbcs.sh``, line 114
* ``scripts/exregional_make_orog.sh``, line 147
* ``scripts/exregional_make_grid.sh``, line 145
* ``scripts/exregional_run_fcst.sh``, line 140
* ``scripts/exregional_make_ics.sh``, line 114
* ``ush/setup.sh``, lines 431 and 742
* ``ush/launch_FV3LAM_wflow.sh``, line 104
* ``ush/get_extrn_mdl_file_dir_info.sh``, many lines, starting around line 589
* ``ush/valid_param_vals.sh``, line 3
* ``ush/load_modules_run_task.sh``, line 126
* ``ush/set_extrn_mdl_params.sh``, many lines, starting around line 61

The line numbers may differ slightly given future bug fixes. Additionally, you may need to make further changes depending on the exact setup of your machine and Rocoto installation. Information about installing and configuring Rocoto on your machine can be found in the Rocoto GitHub repository: https://github.com/christopherwharrop/rocoto

.. _SW-OS-Requirements:

Software/Operating System Requirements
======================================
Those requirements highlighted in **bold** are included in the NCEPLIBS-external (https://github.com/NOAA-EMC/NCEPLIBS-external) package.

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

* wgrib2

* CMake v3.12+

* Software libraries

   * **netCDF (C and Fortran libraries)**
   * **HDF5** 
   * **ESMF** 8.0.0
   * **Jasper**
   * **libJPG**
   * **libPNG**
   * **zlib**

macOS-specific prerequisites:

* brew install wget
* brew install cmake
* brew install coreutils
* brew install pkg-config
* brew install gnu-sed

Optional but recommended prerequisites:

* Conda for installing/managing Python packages
* Bash v4+
* Rocoto Workflow Management System (1.3.1)
* **CMake v3.15+**
* Python packages scipy, matplotlib, pygrib, cartopy, and pillow for graphics
