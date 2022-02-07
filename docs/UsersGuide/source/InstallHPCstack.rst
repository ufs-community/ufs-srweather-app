.. _InstallHPCstack:

======================
Install the HPC-Stack
======================

This step is only required for systems that fall under `Support Levels 2-4 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_.
It will be most successful for Level 2 systems. 

**Definition:** HPC-stack is a repository that provides a unified, shell script-based build system for 
building the software stack needed for the `Unified Forecasting System (UFS) <https://github.com/ufs-community/ufs-weather-model>`_ and applications. 

.. 
   COMMENT: Add details about requirements (e.g., MPI, compilers, environment modules, etc.)???

General HPC-stack installation guidelines are described below. There are several containers available for the installation of the stack and UFS applications: 

* docker://noaaepic/ubuntu20.04-gnu9.3
* docker://noaaepic/ubuntu20.04-hpc-stack
* docker://noaaepic/ubuntu20.04-epic-srwapp
* docker://noaaepic/ubuntu20.04-epic-mrwapp

.. _SingularityInstall:

Installation via Singularity Container
=======================================
To install the HPC-stack via Singularity container, first install the Singularity package according to the `Singularity Installation Guide <https://sylabs.io/guides/3.2/user-guide/installation.html#>`_. This will include the installation of dependencies and the installation of the Go programming 
language. SingularityCE Version 3.7 or above is recommended. 

.. note:: 

   Users may also choose to build the HPC-stack locally by cloning the `HPC-stack GitHub 
   repository <https://github.com/NOAA-EMC/hpc-stack.git>`_ and following the instructions in the README.md. 

.. warning:: 
   Docker containers can only be run with root privileges, and users cannot have root privileges on HPC computers. Therefore, it is not possible to build the HPC-stack inside a Docker container. A Docker image may be pulled, but it must be run inside a container such as Singularity. 

..
   COMMENT: Are there other types of containers HPC-stack could be built in?


**Build the Container**

1. Pull and build the container.

.. code-block:: console

   singularity pull ubuntu20.04-epic.sif docker://noaaepic/ubuntu20.04-epic
   singularity build --sandbox ubuntu20.04-epic ubuntu20.04-epic.sif
   cd ubuntu20.04-epic
   
Make a directory (e.g. ``contrib``) in the container if one does not exist: 

   .. code-block:: console
      
      mkdir contrib
      cd ..

2. Start the container and run an interactive shell within it. This command also binds the local working 
directory to the container so that data can be shared between them.

.. code-block:: console
      
      singularity shell -e --writable --bind /contrib:/contrib ubuntu20.04-gnu9.3

3. Clone the hpc-stack repository.

   .. code-block:: console
      
      git clone -b feature/ubuntu20.04 https://github.com/jkbk2004/hpc-stack
      cd hpc-stack


Set Up the HPC-stack Build Environment 
======================================

Building HPC-Stack from a Singularity Container
------------------------------------------------

1. Set up the build environment. Be sure to change the ``prefix`` argument in the code below to 
your system's install location (likely within the hpc-stack directory). 

   .. code-block:: console
   
      ./setup_modules.sh -p **<prefix>** -c config/config_custom.sh
   
Enter YES/YES/YES when the option is presented. Then modify ``build_stack.sh`` with the following commands:
   
   .. code-block:: console
   
      sed -i "10 a source /usr/share/lmod/6.6/init/bash" ./build_stack.sh
      sed -i "10 a export PATH=/usr/local/sbin:/usr/local/bin:$PATH" ./build_stack.sh
      sed -i "10 a export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH" ./build_stack.sh

2. Build the environment. This may take several hours to complete. 

   .. code-block:: console

      ./build_stack.sh -p **<prefix>** -c config/config_custom.sh -y stack/stack_custom.yaml -m

3. Load the required modules. 

   .. code-block:: console

      source /usr/share/lmod/lmod/init/bash
      module use <prefix>/modulefiles/stack
      module load hpc hpc-gnu hpc-openmpi
      module avail

From here, the user can continue to :ref:`Set Up the Build <SetUpBuild>` in the Quickstart Guide. 

Non-Container Method for Building HPC-Stack:
--------------------------------------------

**1. Configure the Build:**

   Choose the COMPILER, MPI, and PYTHON version, and specify any other aspects of the build that 
   you would like. For Level 1 systems, a default configuration can be found in the applicable 
   ``config/config_<platform>.sh`` file. For Level 2-4 systems, selections can be made by editing 
   the config/config_custom.sh file to reflect the appropriate compiler, mpi, and python choices 
   for your system. If Lmod is installed, you can view options using the ``module avail`` command. 
   
   Some of the parameter settings available are: 
   * HPC_COMPILER: This defines the vendor and version of the compiler you wish to use for this 
   build. The format is the same as what you would typically use in a module load command. For 
   example, HPC_COMPILER=intel/2020. Use ``gcc -v`` to determine your compiler and version. Some 
   options are: ``intel/18.0.5.274`` (default), ``intel/19.0.5.281``, ``intel/2020``, ``intel/2020.2``, 
   ``intel/2021.3.0``, ``gnu/6.5.0``, and ``gnu/9.2.0``
   * HPC_MPI: is the MPI library you wish to use for this build. The format is the same as for 
   HPC_COMPILER, for example: ``HPC_MPI=impi/2020``.
   * HPC_PYTHON: is the Python interpreter to use for the build. The format is the same as for 
   HPC_COMPILER, for example: ``HPC_PYTHON=python/3.7.5``. Use ``python --version`` to determine the current version of Python. 

   Other variables include USE_SUDO, DOWNLOAD_ONLY, NOTE, PKGDIR, LOGDIR, OVERWRITE, NTHREADS, 
   MAKE_CHECK, MAKE_VERBOSE, and VENVTYPE. For more information on their use, visit the 
   `NOAA-EMC HPC-stack README.md file <https://github.com/NOAA-EMC/hpc-stack/blob/develop/README.md>`_.

   For example, when using Intel-based compilers and Intel's implementation of the MPI interface (IMPI), the ``config/config_custom.sh`` should contain the following specifications: 

   .. code-block:: console

      export SERIAL_CC=icc
      export SERIAL_FC=ifort
      export SERIAL_CXX=icpc

      export MPI_CC=mpiicc
      export MPI_FC=mpiifort
      export MPI_CXX=mpiicpc

   This will set the C, Fortran, and C++ compilers and MPI's. 

   To verify that your chosen mpi build (e.g., mpiicc) is based on the corresponding serial compiler (e.g., icc), use the ``-show`` option to query the MPI's. For example,
   
   .. code-block:: console

      mpiicc -show 

   will display output like this:

   .. code-block:: console

      $  icc  -I<LONG_INCLUDE_PATH_FOR_MPI>   -L<ANOTHER_MPI_LIBRARY_PATH>  -L<ANOTHER_MPI_PATH> -<libraries, liners, build options...>   -X<something>  --<enable/disable/with some options>  -l<library>   -l<another_library>  -l<yet-another-library>

   The message you need from this prompt is "icc", which confirms that your mpiicc build is based on icc.  It may happen that if you query the "mpicc -show" on your system, it is based on "gcc" (or something else).

**2. Set up the compiler, MPI, python, and module system:**

   .. note::
      Skip this step if the user has already built the stack in a container. We currenly include only one compiler/mpi combination in each container, so each package is built once and there is no need for modules.

   .. note::
      This step is only required if you are using Lmod modules for managing the software stack. Lmod is installed across all 
      Level 1 and Level 2 systems. 

   Run from the top directory:

   .. code-block:: console

      ./setup_modules.sh -p <prefix> -c <configuration>

   where:

   ``<prefix>`` is the directory where the software packages will be installed with a default value $HOME/opt. The software installation trees (the top level of each being the compiler, e.g. intel-2020) will branch directly off of <prefix> while the module files will be located in the <prefix>/modulefiles subdirectory.

   ``<configuration>`` points to the configuration script that you wish to use, as described in Step 1. 
   The default configuration file is config/config_custom.sh:

   .. code-block:: console

      ./setup_modules.sh -c config/config_custom.sh

   The compiler and mpi modules are handled separately from the rest of the build because, when possible, we wish to exploit site-specific installations that maximize performance. For this reason, the compiler and mpi modules are preceded by a hpc- label. For example, to load the Intel compiler module and the Intel MPI (IMPI) software library, you would enter:

   .. code-block:: console

      module load hpc-intel/2020
      module load hpc-impi/2020

   These hpc- modules are really meta-modules that will both load the compiler/mpi library and modify the MODULEPATH so the user has access to the software packages that will be built in Step 3. On HPC systems, these meta-modules will load the native modules provided by the system administrators. For example, module load hpc-impi/2020 will first load the native impi/2020 module and then modify the MODULEPATH accordingly to allow users to access the custom libraries built by this repository.

   So, in short, you may prefer not to load the compiler or MPI modules directly. Instead, loading the hpc- meta-modules as demonstrated above will provide everything needed to load software libraries.

   If the compiler and/or MPI is natively available on the system and the user wishes to make use of it e.g. /usr/bin/gcc, the setup_modules.sh script prompts the user to answer questions regarding their use. For e.g. in containers, one would like to use the system provided GNU compilers, but build a MPI implementation.
   
   It may be necessary to set certain source and path variables in the ``build_stack.sh`` script. 
   For example:

   .. code-block:: console

      source /usr/share/lmod/6.6/init/bash
      source /usr/share/lmod/lmod/init/bash
      export PATH=/usr/local/sbin:/usr/local/bin:$PATH
      export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH
      export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

   The next step is to choose what components of the stack you wish to build. This is done by editing the yaml file in stack directory. This file defines the software packages to be built along with their version, options, compiler flags, and other package-specific options.

**3. Build the HPC-stack:**

   Now all that remains is to build the stack:

   .. code-block:: console

      ./build_stack.sh -p <prefix> -c <configuration> -y <yaml> -m

   Here the -m option is only required if LMod is used for managing the software stack. It should 
   be omitted otherwise. <prefix> and <configuration> are the same as in Step 2, namely a reference to the installation prefix and a corresponding configuration file in the config directory. As in Step 2, if this argument is omitted, the default is to use $HOME/opt and config/config_custom.sh respectively. <yaml> represents a user configurable yaml file containing a list of packages that need to be built in the stack along with their versions and package options. The default value of <yaml> is stack/stack_custom.yaml.

From here, the user can continue to `Set Up the Build <.. _SetUpBuild:>`_ in the Quickstart Guide. 

   .. note:: 
      **IMPORTANT:** Steps 1, 2, and 3 need to be repeated for each compiler/MPI combination that you wish to install. The new packages will be installed alongside any previously-existing packages that have already been built from other compiler/MPI combinations.

Troubleshooting
==================

* Libtiff errors may require installation of libtiff libraries. On a Linux system: 
   .. code-block:: console 

      git clone https://gitlab.com/libtiff/libtiff.git
      cmake --install-prefix ~/apps/libtiff    
      make  |  tee make.out
      make install | tee make.install.out

..
   COMMENT: Which of the options above (make & make install versus tee make.out & tee make.install.out) are preferable? What is the difference between them?

   where ``~/apps/libtiff`` is the directory of your choice to install the libraries. If you decide to install in a different directory later, clean the previous installation first using the command ``make clean``, and then run lines 2-4 above, specifying the new directory location:

   .. code-block:: console 
      
      cmake --install-prefix <PATH_TO_NEW_LOCATION>
      make
      make install

* 