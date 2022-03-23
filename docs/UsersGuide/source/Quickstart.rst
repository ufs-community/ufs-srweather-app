.. _Quickstart:

====================
Workflow Quick Start
====================
To build and run the out-of-the-box case of the UFS Short-Range Weather (SRW) Application the user
must get the source code for multiple components, including: the regional workflow, the UFS_UTILS
pre-processor utilities, the UFS Weather Model, and the Unified Post Processor (UPP).  Once the UFS
SRW Application umbrella repository is cloned, obtaining the necessary external repositories is
simplified by the use of ``manage_externals``.  The out-of-the-box case uses a predefined 25-km
CONUS grid (RRFS_CONUS_25km), the GFS version 15.2 physics suite (FV3_GFS_v15p2 CCPP), and
FV3-based GFS raw external model data for initialization.

.. note::

   The steps described in this chapter are applicable to preconfigured (Level 1) machines where
   all of the required libraries for building community releases of UFS models and applications
   are available in a central place (i.e. the bundled libraries (NCEPLIBS) and third-party
   libraries (NCEPLIBS-external) have both been built).  The Level 1 platforms are listed `here
   <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_.
   For more information on compiling NCEPLIBS-external and NCEPLIBS, please refer to the
   NCEPLIBS-external `wiki <https://github.com/NOAA-EMC/NCEPLIBS-external/wiki>`_. 


Download the UFS SRW Application Code
=====================================
The necessary source code is publicly available on GitHub.  To clone the release branch of the repository:

.. code-block:: console

   git clone -b ufs-v1.0.0 https://github.com/ufs-community/ufs-srweather-app.git
   cd ufs-srweather-app

Then, check out the submodules for the SRW application:

.. code-block:: console

   ./manage_externals/checkout_externals

The ``checkout_externals`` script uses the configuration file ``Externals.cfg`` in the top level directory
and will clone the regional workflow, pre-processing utilities, UFS Weather Model, and UPP source code
into the appropriate directories under your ``regional_workflow`` and ``src`` directories.


.. _SetUpBuild:

Set up the Build Environment
============================
Instructions for loading the proper modules and/or setting the correct environment variables can be
found in the ``env/`` directory in files named ``build_<platform>_<compiler>.env``.
The commands in these files can be directly copy-pasted to the command line or the file can be sourced.
You may need to modify certain variables such as the path to NCEP libraries for your individual platform,
or use ``setenv`` rather than ``export`` depending on your environment:

.. code-block:: console

   $ ls -l env/
      -rw-rw-r-- 1 user ral 1062 Apr  27 10:09 build_cheyenne_gnu.env
      -rw-rw-r-- 1 user ral 1061 Apr  27 10:09 build_cheyenne_intel.env
      -rw-rw-r-- 1 user ral 1023 Apr  27 10:09 build_hera_intel.env
      -rw-rw-r-- 1 user ral 1017 Apr  27 10:09 build_jet_intel.env

Build the Executables
=====================
Build the executables as follows:

.. code-block:: console

   mkdir build
   cd build

Run ``cmake`` to set up the ``Makefile``, then run ``make``:

.. code-block:: console

   cmake .. -DCMAKE_INSTALL_PREFIX=..
   make -j 4  >& build.out &

Output from the build will be in the ``ufs-srweather-app/build/build.out`` file.
When the build completes, you should see the forecast model executable ``NEMS.exe`` and eleven
pre- and post-processing executables in the ``ufs-srweather-app/bin`` directory which are
described in :numref:`Table %s <ExecDescription>`.

Generate the Workflow Experiment
================================
Generating the workflow experiment requires three steps:

* Set experiment parameters in config.sh
* Set Python and other environment parameters
* Run the ``generate_FV3LAM_wflow.sh`` script

The first two steps depend on the platform being used and are described here for each Level 1 platform.

.. _SetUpConfigFile:

Set up ``config.sh`` file
-------------------------
The workflow requires a file called ``config.sh`` to specify the values of your experiment parameters.
Two example templates are provided: ``config.community.sh`` and ``config.nco.sh`` and can be found in
the ``ufs-srweather-app/regional_workflow/ush directory``.  The first file is a minimal example for
creating and running an experiment in the *community* mode (with ``RUN_ENVIR`` set to ``community``),
while the second is an example of creating and running an experiment in the *NCO* (operational) mode
(with ``RUN_ENVIR`` set to ``nco``).   The *community* mode is recommended in most cases and will be
fully supported for this release while the operational mode will be more exclusively used by NOAA/NCEP
Central Operations (NCO) and those in the NOAA/NCEP/Environmental Modeling Center (EMC) working with
NCO on pre-implementation testing. Sample config.sh files are discussed in this section for Level 1 platforms. 

Make a copy of ``config.community.sh`` to get started (under /path-to-ufs-srweather-app/regional_workflow/ush):

.. code-block:: console

   cd ../regional_workflow/ush
   cp config.community.sh config.sh

Edit the ``config.sh`` file to set the machine you are running on to ``MACHINE``, use an account you can charge for 
``ACCOUNT``, and set the name of the experiment with ``EXPT_SUBDIR``. If you have access to the NOAA HPSS from the 
machine you are running on, those changes should be sufficient; however, if that is not the case (for example, 
on Cheyenne), or if you have pre-staged the initialization data you would like to use, you will also want to set 
``USE_USER_STAGED_EXTRN_FILES="TRUE"`` and set the paths to the data for ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` and 
``EXTRN_MDL_SOURCE_BASEDIR_LBCS``. 

.. note::

   If you set up the build environment with the GNU compiler in :numref:`Section %s <SetUpBuild>`, you will
   have to add the line ``COMPILER="gnu"`` to the ``config.sh`` file.
 
At a minimum, the following parameters should be set for the machine you are using:

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

For WCOSS, edit ``config.sh`` with these WCOSS-specific parameters, and use a valid WCOSS
project code for the account parameter:

.. code-block:: console

   MACHINE=”wcoss_dell_p3”
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"

.. _SetUpPythonEnv:

Set up the Python and other Environment Parameters
--------------------------------------------------
Next, it is necessary to load the appropriate Python environment for the workflow.
The workflow requires Python 3, with the packages 'PyYAML', 'Jinja2', and 'f90nml' available.
This Python environment has already been set up on Level 1 platforms, and can be activated in
the following way (when in /path-to-ufs-srweather-app/regional_workflow/ush):

.. code-block:: console

   source ../../env/wflow_<platform>.env

Run the ``generate_FV3LAM_wflow.sh`` script
-------------------------------------------
For all platforms, the workflow can then be generated with the command:

.. code-block:: console

   ./generate_FV3LAM_wflow.sh

The generated workflow will be in ``$EXPTDIR``, where ``EXPTDIR=${EXPT_BASEDIR}/${EXPT_SUBDIR}``. A 
log file called ``log.generate_FV3LAM_wflow`` is generated by this step and can also be found in 
``$EXPTDIR``. The settings for these paths can be found in the output from the 
``./generate_FV3LAM_wflow.sh`` script.

Run the Workflow Using Rocoto
=============================
The information in this section assumes that Rocoto is available on the desired platform.
If Rocoto is not available, it is still possible to run the workflow using stand-alone scripts
described in :numref:`Section %s <RunUsingStandaloneScripts>`. There are two ways you can run 
the workflow with Rocoto using either the ``./launch_FV3LAM_wflow.sh`` or by hand. 

An environment variable may be set to navigate to the ``$EXPTDIR`` more easily. If the login 
shell is bash, it can be set as follows:

.. code-block:: console

   export EXPTDIR=/path-to-experiment/directory

Or if the login shell is csh/tcsh, it can be set using:

.. code-block:: console

   setenv EXPTDIR /path-to-experiment/directory

To run Rocoto using the script:

.. code-block:: console

   cd $EXPTDIR
   ./launch_FV3LAM_wflow.sh

Once the workflow is launched with the ``launch_FV3LAM_wflow.sh`` script, a log file named
``log.launch_FV3LAM_wflow`` will be created (or appended to it if it already exists) in ``EXPTDIR``.

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
Two python scripts are provided to generate plots from the FV3-LAM post-processed GRIB2 output. Information
on how to generate the graphics can be found in :numref:`Chapter %s <Graphics>`.
