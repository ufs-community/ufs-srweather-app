.. _SRWMacOS:

===========================================
Building the SRW Application on MacOS 
===========================================

.. note::
    Examples throughout this chapter presume that the user is running Terminal.app with a bash shell environment. If this is not the case, users will need to adjust the commands to fit their command line application and shell environment. 

Download the Application
===========================

The SRW Application source code is publicly available on GitHub. To download the SRW App, clone the develop branch of the repository:

.. code-block:: console

    git clone -b develop https://github.com/ufs-community/ufs-srweather-app.git

The cloned repository contains the configuration files and sub-directories shown in :numref:`Table %s <FilesAndSubDirs>`. Set the new ``ufs-srweather-app`` repository as your ``$SRW`` environmental variable:

.. code-block:: console

    export SRW=$HOME/ufs-srweather-app

Check Out External Components
================================

Run the executable that pulls in SRW App components from external repositories (see :numref:`Chapter %s <CheckoutExternals>` for additional background information):

.. code-block:: console

    cd ufs-srweather-app
    ./manage_externals/checkout_externals

Set Up the Build Environment
===============================

The ``build_<platform>_<compiler>.env`` scripts located in ``$SRW/env/`` allow users to customize the SRW App build environment for their system. On MacOS, ``<platform>`` is ``macosx`` and ``<compiler>`` is ``gnu``. The ``build_macosx_gnu.env`` script initializes the module environment, lists the location of hpc-stack modules, loads the meta-modules and modules, and sets compilers, additional flags, and environment variables needed for building the SRW App. The ``$HPC-stack-install`` variable is set to the installation directory for the HPC-Stack. The ``srw_common`` file contains a list of specific libraries and modules to be loaded, and it is sourced from the build_macosx_gnu.env . 

Sample ``build_macosx_gnu.env`` contents appear below for Option 1. To use Option 2, the user will need to comment out the lines specific to Option 1 and uncomment the lines specific to Option 2 in the ``build_macosx_gnu.env`` file.


.. code-block:: console

    # Setup instructions for macOS (build_macosx_gnu.env)

    module purge
    source /opt/homebrew/opt/lmod/init/profile   (Option 1)
    # source /usr/local/opt/lmod/init/profile    (Option 2)
    module use $HPC_INSTALL_DIR/modulefiles/stack 
    module load hpc
    module load hpc-python
    module load hpc-gnu
    module load openmpi
    module load hpc-openmpi

    export SRW=${HOME}/SRW/ufs-srweather-app
    source ${SRW}/env/srw_common
    module list

    % Option 1 compiler paths:
    export CC=/opt/homebrew/bin/gcc  
    export CXX=/opt/homebrew/bin/g++
    export FC=/opt/homebrew/bin/gfortran

    % Option 2 compiler paths:
    %export CC=/usr/local/bin/gcc
    %export CXX=/usr/local/bin/g++
    %export FC=/usr/local/bin/gfortran

    export MPI_CC=mpicc
    export MPI_CXX=mpicxx
    export MPI_FC=mpif90

    export CMAKE_C_COMPILER=$MPI_CC
    export CMAKE_CXX_COMPILER=$MPI_CXX
    export CMAKE_Fortran_COMPILER=$MPI_FC
    export CMAKE_Platform=macosx.gnu
    export CMAKE_Fortran_COMPILER_ID="GNU"
    export LDFLAGS="-L$MPI_ROOT/lib"
    export FFLAGS="-DNO_QUAD_PRECISION -fallow-argument-mismatch"  

Then, the user must source the configuration file:

.. code-block:: console

    source $SRW/env/build_macosx_gnu.env

Additional Changes
--------------------

For Option 1, set the variable ``ENABLE_QUAD_PRECISION`` to ``OFF`` in line 35 of the ``$SRW/src/ufs-weather-model/FV3/atmos_cubed_sphere/CMakeLists.txt`` file: 

.. code-block:: console

    option(ENABLE_QUAD_PRECISION "Enable compiler definition -DENABLE_QUAD_PRECISION" OFF)

This change is optional if using Option 2 to build the SRW App. 


Build the SRW App
===================

Create a directory to hold the build's executables:

.. code-block:: console

    mkdir build
    cd build

From the build directory, run the following commands to build the pre-processing utilities, forecast model, and post-processor:

.. code-block:: console
 
    cmake .. -DCMAKE_INSTALL_PREFIX=..
    make -j 4  &>  build.out &

Verify that the binaries in :numref:`Table %s <ExecDescription>` are built in the directory ``$SRW/bin``. The build process make take a while. For more details, see :numref:`Chapter %s <BuildExecutables>`



