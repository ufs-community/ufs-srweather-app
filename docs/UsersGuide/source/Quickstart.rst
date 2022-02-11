.. _Quickstart:

====================
Workflow Quick Start
====================



This Workflow Quick Start Guide will help users to build and run the "out-of-the-box" case for the Unified Forecast System (UFS) Short-Range Weather (SRW) Application. The "out-of-the-box" case builds a weather forecast for June 15-16, 2019. Multiple convective weather events during these two days produced over 200 filtered storm reports. Severe weather was clustered in two areas: the Upper Midwest through the Ohio Valley and the Southern Great Plains. This forecast uses a predefined 25-km Continental United States (CONUS) grid (RRFS_CONUS_25km), the Global Forecast System (GFS) version 15.2 physics suite (FV3_GFS_v15p2 CCPP), and FV3-based GFS raw external model data for initialization.

.. note::

   The steps described in this chapter are most applicable to preconfigured (Level 1) systems. On Level 1 systems, all of the required libraries for building community releases of UFS models and applications are available in a central location. This guide can serve as a starting point for running the SRW App on other systems as well but may require additional troubleshooting by the user. The various platform levels are listed `here <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_.


.. _HPCstackInfo:

Install the HPC-Stack
========================

.. note::
   Skip the HPC-stack installation if working on a `Level 1 system <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_ (e.g., Cheyenne, Hera, Orion).


.. include:: ../../../hpc-stack-mod/docs/source/hpc-intro.rst


After completing installation, continue to the :ref:`next section <DownloadCode>`.


.. _DownloadCode:

Download the UFS SRW Application Code
=====================================
The SRW Application source code is publicly available on GitHub and can be run in a container or locally, depending on user preference. The SRW Application relies on a variety of components detailed in the :ref:`Components Chapter <Components>` of this User's Guide. Users must (1) clone the UFS SRW Application umbrella repository and then (2) run the ``checkout_externals`` script to link the necessary external repositories to the SRW App. The ``checkout_externals`` script uses the configuration file ``Externals.cfg`` in the top level directory of the SRW App and will clone the correct version of the regional workflow, pre-processing utilities, UFS Weather Model, and UPP source code into the appropriate directories under your ``regional_workflow`` and ``src`` directories. 

Run the UFS SRW in a Singularity Container
-------------------------------------------

Pull the Singularity container:

.. code-block:: console

   singularity pull ubuntu20.04-hpc-stack-0.1.sif docker://noaaepic/ubuntu20.04-hpc-stack:0.1

Build the container and make a ``home`` directory inside it:

.. code-block:: console

   singularity build --sandbox ubuntu20.04-hpc-stack-0.1 ubuntu20.04-hpc-stack-0.1.sif
   cd ubuntu20.04-hpc-stack-0.1
   mkdir home

Start the container and run an interactive shell within it. This command also binds the local home directory to the container so that data can be shared between them. 

.. code-block:: console

   singularity shell -e --writable --bind /home:/home ubuntu20.04-hpc-stack

Clone the develop branch of the UFS-SRW weather application repository:

.. code-block:: console

   git clone https://github.com/jkbk2004/ufs-srweather-app

Check out submodules for the SRW Application:

.. code-block:: console

   cd ufs-srweather-app
   ./manage_externals/checkout_externals


Run the UFS SRW Without a Container
------------------------------------

Clone the release branch of the repository:

.. code-block:: console

   git clone -b ufs-v1.0.0 https://github.com/ufs-community/ufs-srweather-app.git

Then, check out the submodules for the SRW Application:

.. code-block:: console

   cd ufs-srweather-app
   ./manage_externals/checkout_externals


.. _SetUpBuild:

Set up the Build Environment
============================

Container Approach
--------------------
If the SRW Application has been built in an EPIC-provided Singularity container, set build environments and modules within the `ufs-srweather-app` directory as follows:

.. code-block:: console

   ln -s /usr/bin/python3 /usr/bin/python
   source /usr/share/lmod/6.6/init/profile
   module use /opt/hpc-modules/modulefiles/stack
   module load hpc hpc-gnu hpc-openmpi hpc-python
   module load netcdf hdf5 bacio sfcio sigio nemsio w3emc esmf fms crtm g2 png zlib g2tmpl ip sp w3nco cmake gfsio wgrib2 upp


On Other Systems (Non-Container Approach)
------------------------------------------

Otherwise, for Level 1 and 2 systems, scripts for loading the proper modules and/or setting the 
correct environment variables can be found in the ``env/`` directory of the SRW App in files named 
``build_<platform>_<compiler>.env``. The commands in these files can be directly copy-pasted 
to the command line, or the file can be sourced from the ufs-srweather-app ``env/`` directory. 
For example, on Hera, run ``source env/build_hera_intel.env`` from the main ufs-srweather-app 
directory to source the appropriate file.

On Level 3-4 systems, users will need to modify certain environment variables, such as the path to NCEP libraries, so that the SRW App can find and load the appropriate modules. For systems with Lmod installed, one of the current ``build_<platform>_<compiler>.env`` files can be copied and used as a template. On systems without Lmod, this process will typically involve commands in the form `export <VARIABLE_NAME>=<PATH_TO_MODULE>`. You may need to use ``setenv`` rather than ``export`` depending on your environment. 

Troubleshooting
------------------
* If the system cannot find a module (i.e., a "module unknown" message appears), check whether the module version numbers match in ``ufs-srweather-app/env/build_<platform>_<compiler>.env`` and the ``hpc-stack/stack/stack_custom.yaml``.


Build the Executables
=====================

Create a directory to hold the build's executables: 

.. code-block:: console

   mkdir build
   cd build

From the build directory, run the ``cmake`` command below to set up the ``Makefile``, then run the ``make`` command to build the executables:

.. code-block:: console

   cmake .. -DCMAKE_INSTALL_PREFIX=..
   make -j 4  >& build.out &

Output from the build will be in the ``ufs-srweather-app/build/build.out`` file.
When the build completes, you should see the forecast model executable ``NEMS.exe`` and eleven
pre- and post-processing executables in the ``ufs-srweather-app/bin`` directory. These executables are
described in :numref:`Table %s <ExecDescription>`.

Download and Stage the Data
============================

The SRW requires input files to run. These include static datasets, initial and boundary conditions 
files, and model configuration files. On Level 1 and 2 systems, the data required to run SRW tests are 
already available. For Level 3 and 4 systems, the data must be added. Detailed instructions on how to add the data can be found in the :doc:`Input and Output Files <InputOutputFiles>`, Section 3. Section 1 contains useful background information on the input files required by the SRW. 


Generate the Forecast Experiment 
=================================
Generating the forecast experiment requires three steps:

* Set experiment parameters
* Set Python and other environment parameters
* Run the ``generate_FV3LAM_wflow.sh`` script to generate the experiment workflow

The first two steps depend on the platform being used and are described here for each Level 1 platform.
Users will need to adjust the instructions to their machine if they are working on a Level 2-4 platform. 

.. _SetUpConfigFile:

Set Experiment Parameters
-------------------------
Each experiment requires certain basic information to run (e.g., date, grid, physics suite). This information is specified in the ``config.sh`` file. Two example ``config.sh`` templates are provided: ``config.community.sh`` and ``config.nco.sh``. They can be found in the ``ufs-srweather-app/regional_workflow/ush`` directory. The first file is a minimal example for creating and running an experiment in the *community* mode (with ``RUN_ENVIR`` set to ``community``). The second is an example for creating and running an experiment in the *NCO* (operational) mode (with ``RUN_ENVIR`` set to ``nco``).  The *community* mode is recommended in most cases and will be fully supported for this release. 

Make a copy of ``config.community.sh`` to get started (under <path-to-ufs-srweather-app>/regional_workflow/ush):

.. code-block:: console

   cd ../regional_workflow/ush
   cp config.community.sh config.sh

The default settings in this file include a predefined 25-km CONUS grid (RRFS_CONUS_25km), the GFS v15.2 physics suite (FV3_GFS_v15p2 CCPP), and FV3-based GFS raw external model data for initialization.

Next, edit the new ``config.sh`` file to customize it for your machine. At a minimum, change the ``MACHINE`` and ``ACCOUNT`` variables; then choose a name for the experiment directory by setting ``EXPT_SUBDIR``. If you have pre-staged the initialization data for the experiment, set ``USE_USER_STAGED_EXTRN_FILES="TRUE"``, and set the paths to the data for ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS``. 

Sample settings are indicated below for Level 1 platforms. Detailed guidance applicable to all systems can be found in :doc:`Configuring the Workflow <ConfigWorkflow>`, which discusses each variable and the options available. Additionally, information about the three predefined Limited Area Model (LAM) Grid options can be found in the section on :doc:`Limited Area Model (LAM) Grids <LAMGrids>`.

.. note::

   If you set up the build environment with the GNU compiler in :numref:`Section %s <SetUpBuild>`, you will have to add the line ``COMPILER="gnu"`` to the ``config.sh`` file.
 
Minimum parameter settings for Level 1 machines:

For Cheyenne:

.. code-block:: console

   MACHINE="cheyenne"
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"
   USE_USER_STAGED_EXTRN_FILES="TRUE"
   EXTRN_MDL_SOURCE_BASEDIR_ICS="/glade/p/ral/jntp/UFS_SRW_app/model_data/FV3GFS"
   EXTRN_MDL_SOURCE_BASEDIR_LBCS="/glade/p/ral/jntp/UFS_SRW_app/model_data/FV3GFS"

For Hera:

.. code-block:: console

   MACHINE="hera"
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"

For Jet:

.. code-block:: console

   MACHINE="jet"
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"

For Orion:

.. code-block:: console

   MACHINE="orion"
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"

For Gaea:

.. code-block:: console

   MACHINE="gaea"
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"

For WCOSS, edit ``config.sh`` with these WCOSS-specific parameters, and use a valid WCOSS project code for the account parameter:

.. code-block:: console

   MACHINE=”wcoss_cray” or MACHINE=”wcoss_dell_p3”
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"

.. _SetUpPythonEnv:

Set up the Python and other Environment Parameters
--------------------------------------------------
Next, it is necessary to load the appropriate Python environment for the workflow. The workflow requires Python 3, with the packages 'PyYAML', 'Jinja2', and 'f90nml' available. This Python environment has already been set up on Level 1 platforms, and it can be activated in the following way (from ``/ufs-srweather-app/regional_workflow/ush``):

.. code-block:: console

   source ../../env/wflow_<platform>.env


Run the ``generate_FV3LAM_wflow.sh`` script
-------------------------------------------
For all platforms, the workflow can then be generated from the ``ush`` directory with the command:

.. code-block:: console

   ./generate_FV3LAM_wflow.sh

The generated workflow will be in ``$EXPTDIR``, where ``EXPTDIR=${EXPT_BASEDIR}/${EXPT_SUBDIR}``. A  log file called ``log.generate_FV3LAM_wflow`` is generated by this step and can also be found in ``$EXPTDIR``. The settings for these paths can be found in the output from the ``./generate_FV3LAM_wflow.sh`` script.

Run the Workflow Using Rocoto
=============================
The information in this section assumes that Rocoto is available on the desired platform. If Rocoto is not available, it is still possible to run the workflow using stand-alone scripts described in :numref:`Section %s <RunUsingStandaloneScripts>`. There are two ways you can run the workflow with Rocoto using either the ``./launch_FV3LAM_wflow.sh`` or by hand. 

An environment variable may be set to navigate to the ``$EXPTDIR`` more easily. If the login shell is bash, it can be set as follows:

.. code-block:: console

   export EXPTDIR=/path-to-experiment/directory

Or if the login shell is csh/tcsh, it can be set using:

.. code-block:: console

   setenv EXPTDIR /path-to-experiment/directory

To run Rocoto using the script:

.. code-block:: console

   cd $EXPTDIR
   ./launch_FV3LAM_wflow.sh

Once the workflow is launched with the ``launch_FV3LAM_wflow.sh`` script, a log file named ``log.launch_FV3LAM_wflow`` will be created (or appended to it if it already exists) in ``EXPTDIR``.

Or to manually call Rocoto: 

First load the Rocoto module, depending on the platform used.

For Cheyenne:

.. code-block:: console

   module use -a /glade/p/ral/jntp/UFS_SRW_app/modules/
   module load rocoto

For Hera or Jet:

.. code-block:: console

   module purge
   module load rocoto

For Orion:

.. code-block:: console

   module purge
   module load contrib rocoto

For Gaea:

.. code-block:: console

   module use /lustre/f2/pdata/esrl/gsd/contrib/modulefiles
   module load rocoto/1.3.3

For WCOSS_DELL_P3:

.. code-block:: console

   module purge
   module load lsf/10.1
   module use /gpfs/dell3/usrx/local/dev/emc_rocoto/modulefiles/
   module load ruby/2.5.1 rocoto/1.2.4

For WCOSS_CRAY:

.. code-block:: console

   module purge
   module load xt-lsfhpc/9.1.3
   module use -a /usrx/local/emc_rocoto/modulefiles
   module load rocoto/1.2.4

Then manually call ``rocotorun`` to launch the tasks that have all dependencies satisfied 
and ``rocotostat`` to monitor the progress: 

.. code-block:: console

   cd $EXPTDIR
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

For automatic resubmission of the workflow (e.g., every 3 minutes), the following line can be added
to the user's crontab (use ``crontab -e`` to edit the cron table).

.. code-block:: console

   */3 * * * * cd /glade/p/ral/jntp/$USER/expt_dirs/test_CONUS_25km_GFSv15p2 && ./launch_FV3LAM_wflow.sh 

.. note::

   Currently cron is only available on the orion-login-1 node, so please use that node.
   
The workflow run is completed when all tasks have “SUCCEEDED”, and the rocotostat command will output the following:

.. code-block:: console

   CYCLE               TASK                 JOBID              STATE         EXIT STATUS   TRIES   DURATION
   ==========================================================================================================
   201906150000          make_grid           4953154           SUCCEEDED         0         1           5.0
   201906150000          make_orog           4953176           SUCCEEDED         0         1          26.0
   201906150000          make_sfc_climo      4953179           SUCCEEDED         0         1          33.0
   201906150000          get_extrn_ics       4953155           SUCCEEDED         0         1           2.0
   201906150000          get_extrn_lbcs      4953156           SUCCEEDED         0         1           2.0
   201906150000          make_ics            4953184           SUCCEEDED         0         1          16.0
   201906150000          make_lbcs           4953185           SUCCEEDED         0         1          71.0
   201906150000          run_fcst            4953196           SUCCEEDED         0         1        1035.0
   201906150000          run_post_f000       4953244           SUCCEEDED         0         1           5.0
   201906150000          run_post_f001       4953245           SUCCEEDED         0         1           4.0
   ...
   201906150000          run_post_f048       4953381           SUCCEEDED         0         1           7.0

Plot the Output
===============
Two python scripts are provided to generate plots from the FV3-LAM post-processed GRIB2 output. Information on how to generate the graphics can be found in :numref:`Chapter %s <Graphics>`.
