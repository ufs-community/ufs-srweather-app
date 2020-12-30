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

   git clone -b release/public-v1 https://github.com/ufs-community/ufs-srweather-app.git
   cd ufs-srweather-app

Then, check out the submodules for the SRW application:

.. code-block:: console

   ./manage_externals/checkout_externals

The ``checkout_externals`` script uses the configuration file ``Externals.cfg`` in the top level directory
and will clone the regional workflow, pre-processing utilities, UFS Weather Model, and UPP source code
into the appropriate directories under your ``regional_workflow`` and ``src`` directories.


Set up the Build Environment
============================
Instructions for loading the proper modules and/or setting the correct environment variables can be
found in the ``docs/`` directory in files named ``README_<platform>_<compiler>.txt``.  For the most part,
the commands in those files can be directly copy-pasted, but you may need to modify certain variables
such as the path to NCEP libraries for your individual platform:

.. code-block:: console

   $ ls -l docs/
      -rw-rw-r-- 1 user ral 1228 Oct  9 10:09 README_cheyenne_intel.txt
      -rw-rw-r-- 1 user ral 1134 Oct  9 10:09 README_hera_intel.txt
      -rw-rw-r-- 1 user ral 1228 Oct  9 10:09 README_jet_intel.txt

Build the Executables
=====================
Build the executables as follows:

.. code-block:: console

   mkdir build
   cd build

Run ``cmake`` to set up the ``Makefile``, then run ``make``:

.. code-block:: console

   cmake .. -DCMAKE_INSTALL_PREFIX=..
   make -j 8  >& build.out &

Output from the build will be in the ``ufs-srweather-app/build/build.out`` file.
When the build completes, you should see the forecast model executable ``NEMS.exe`` and eleven
pre- and post-processing executables in the ``ufs-srweather-app/bin`` directory which are
described in :numref:`Table %s <exec_description>`.

Generate the Workflow Experiment
================================
Generating the workflow experiment requires three steps:

* Set experiment parameters in config.sh
* Set Python and other environment parameters
* Run the generate_FV3LAM_wflow.sh script

The first two steps depend on the platform being used and are described here for each Level 1 platform.

Set up ``config.sh`` file
-------------------------
The workflow requires a file called ``config.sh`` to specify the values of your experiment parameters.
Two example templates are provided: ``config.community.sh`` and ``config.nco.sh`` and can be found in
the ``ufs-srweather-app/regional_workflow/ush directory``.  The first file is a minimal example for
creating and running an experiment in the *community* mode (with ``RUN_ENVIR`` set to ``community``),
while the second is an example of creating and running an experiment in the *NCO*’ (operational) mode
(with ``RUN_ENVIR`` set to ``nco``).   The *community* mode is recommended in most cases and will be
fully supported for this release while the operational mode will be more exclusively used by NOAA/NCEP
Central Operations (NCO) and those in the NOAA/NCEP/Environmental Modeling Center (EMC) working with
NCO on pre-implementation testing. Sample config.sh files are discussed in this section for Level 1 platforms. 

Make a copy of ``config.community.sh`` to get started:

.. code-block:: console

   cd ufs-srweather-app/regional_workflow/ush
   cp config.community.sh config.sh

Edit the ``config.sh`` file to use an account you can charge to ``ACCOUNT``, and the name of the
experiment ``EXPT_SUBDIR``. The following parameters should be set for the machine you are using:

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

For WCOSS, edit ``config.sh`` with these WCOSS-specific parameters, and use a valid WCOSS
project code for the account parameter:

.. code-block:: console

   MACHINE=”wcoss_cray” or MACHINE=”wcoss_dell_p3”
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"

Set up the Python and other Environment Parameters
--------------------------------------------------
Next, it is necessary to load the appropriate Python environment for the workflow.
The workflow requires Python 3, with the packages 'PyYAML', 'Jinja2', and 'f90nml' available.
This Python environment has already been set up on Level 1 platforms, and can be activated in
the following way:

On Cheyenne:

.. code-block:: console

   module load ncarenv
   ncar_pylib /glade/p/ral/jntp/UFS_CAM/ncar_pylib_20200427
   module use -a /glade/p/ral/jntp/UFS_SRW_app/modules
   module load rocoto 


On Hera and Jet:

.. code-block:: console

   module use -a /contrib/miniconda3/modulefiles
   module load miniconda3
   conda activate regional_workflow
   module load rocoto

On Orion:

.. code-block:: console

   module use -a /apps/contrib/miniconda3-noaa-gsl/modulefiles
   module load miniconda3
   conda activate regional_workflow
   module load contrib/0.1
   module load rocoto/1.3.2

On WCOSS, append the following to your PYTHONPATH:

.. code-block:: console

   module load python/3.6.3
   export PYTHONPATH=”${PYTHONPATH}:/gpfs/dell2/emc/modeling/noscrub/Jacob.Carley/python/lib/python3.6/site-packages"

The path to wgrib2_dir should be defined on WCOSS Dell:

.. code-block:: console

   PATH=$PATH:/gpfs/dell1/nco/ops/nwprod/grib_util.v1.0.6/exec/wgrib2

Run the ``generate_FV3LAM_wflow.sh`` script
-------------------------------------------
For all platforms, the workflow can then be generated with the command:

.. code-block:: console

   ./generate_FV3LAM_wflow.sh

The generated workflow will be in ``$EXPTDIR``, where ``EXPTDIR=${EXPT_BASEDIR}/${EXPT_SUBDIR}``.  The
settings for these paths can be found in the output from the ``./generate_FV3LAM_wflow.sh`` script.

Run the Workflow Using Rocoto
=============================
The information in this section assumes that Rocoto is available on the desired platform.
If Rocoto is not available, it is still possible to run the workflow using stand-alone scripts
described in :numref:`Section %s <RunUsingStandaloneScripts>`. To run the workflow with Rocoto:

.. code-block:: console

   cd $EXPTDIR
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

For automatic resubmission of the workflow (every 3 minutes), the following line can be added
to the user's crontab (use ``crontab -e`` to edit the cron table):

.. code-block:: console

   */3 * * * * cd /glade/p/ral/jntp/$USER/expt_dirs/test_CONUS_25km_GFSv15p2 && /glade/p/ral/jntp/tools/rocoto/rocoto-1.3.1/bin/rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

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

