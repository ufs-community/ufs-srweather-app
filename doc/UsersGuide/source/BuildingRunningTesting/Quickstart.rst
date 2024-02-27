.. _NCQuickstart:

====================
Quick Start Guide
====================

This chapter provides a brief summary of how to build and run the SRW Application. The steps will run most smoothly on :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems. Users should expect to reference other chapters of this User's Guide, particularly :numref:`Section %s: Building the SRW App <BuildSRW>` and :numref:`Section %s: Running the SRW App <RunSRW>`, for additional explanations regarding each step.


Install the Prerequisite Software Stack
=========================================
SRW App users who are **not** working on a :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` platform will need to install the prerequisite software stack via :term:`spack-stack` or :term:`HPC-Stack` prior to building the SRW App on a new machine. Users can find installation instructions in the :doc:`spack-stack documentation <spack-stack:index>` or the :doc:`HPC-Stack documentation <hpc-stack:index>`. The steps will vary slightly depending on the user's platform, but detailed instructions for a variety of platforms are available in the documentation. Users may also post questions in the `ufs-community Discussions tab <https://github.com/orgs/ufs-community/discussions/categories/q-a>`__.

Once spack-stack or HPC-Stack has been successfully installed, users can move on to building the SRW Application.

.. attention::
   Most SRW App :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems have shifted to spack-stack from HPC-Stack (with the exception of Derecho). Spack-stack is a Spack-based method for installing UFS prerequisite software libraries. Currently, spack-stack is the software stack validated by the UFS Weather Model (:term:`WM <Weather Model>`) for running regression tests. UFS applications and components are also shifting to spack-stack from HPC-Stack but are at various stages of this transition. Although users can still build and use HPC-Stack, the UFS WM no longer uses HPC-Stack for validation, and support for this option is being deprecated. 

.. _QuickBuildRun:

Building and Running the UFS SRW Application 
===============================================

For a detailed explanation of how to build and run the SRW App on any supported system, see :numref:`Section %s: Building the SRW App <BuildSRW>` and :numref:`Section %s: Running the SRW App <RunSRW>`. :numref:`Figure %s <AppBuildProc>` outlines the steps of the build process. The overall procedure for generating an experiment is shown in :numref:`Figure %s <AppOverallProc>`, with the scripts to generate and run the workflow shown in red. An overview of the required steps appears below. However, users can expect to access other referenced sections of this User's Guide for more detail.

   #. Clone the SRW App from GitHub:

      .. code-block:: console

         git clone -b develop https://github.com/ufs-community/ufs-srweather-app.git

   #. Check out the external repositories:

      .. code-block:: console

         cd ufs-srweather-app
         ./manage_externals/checkout_externals

   #. Set up the build environment and build the executables:

      .. code-block:: console
            
         ./devbuild.sh --platform=<machine_name>

      where ``<machine_name>`` is replaced with the name of the user's platform/system. Valid values include: ``derecho`` | ``gaea`` | ``hera`` | ``hercules`` | ``jet`` | ``linux`` | ``macos`` | ``noaacloud`` | ``orion`` | ``wcoss2``

      For additional details, see :numref:`Section %s <DevBuild>`, or view :numref:`Section %s <CMakeApproach>` to try the CMake build approach instead. 

   #. Users on a :srw-wiki:`Level 2-4 <Supported-Platforms-and-Compilers>` system must download and stage data (both the fix files and the :term:`IC/LBC <ICs/LBCs>` files) according to the instructions in :numref:`Section %s <DownloadingStagingInput>`. Standard data locations for Level 1 systems appear in :numref:`Table %s <DataLocations>`.

   #. Load the python environment for the workflow. Users on Level 2-4 systems will need to use one of the existing ``wflow_<platform>`` modulefiles (e.g., ``wflow_macos``) and adapt it to their system. Then, run:

      .. code-block:: console
         
         source /path/to/ufs-srweather-app/etc/lmod-setup.sh <platform>
         module use /path/to/ufs-srweather-app/modulefiles
         module load wflow_<platform>

      where ``<platform>`` refers to a valid machine name (see :numref:`Section %s <user>`). After loading the workflow, users should follow the instructions printed to the console. For example, if the output says: 

      .. code-block:: console

         Please do the following to activate conda:
            > conda activate srw_app
      
      then the user should run |activate| to activate the workflow environment. 

   #. Configure the experiment: 

      Copy the contents of the sample experiment from ``config.community.yaml`` to ``config.yaml``:

      .. code-block:: console

         cd ush
         cp config.community.yaml config.yaml
      
      Users will need to open the ``config.yaml`` file and adjust the experiment parameters in it to suit the needs of their experiment (e.g., date, grid, physics suite). At a minimum, users need to modify the ``MACHINE`` parameter. In most cases, users will need to specify the ``ACCOUNT`` parameter and the location of the experiment data (see :numref:`Section %s <Data>` for Level 1 system default locations). 

      For example, a user on Gaea might adjust or add the following fields to run the 12-hr "out-of-the-box" case on Gaea using prestaged system data and :term:`cron` to automate the workflow: 

      .. code-block:: console
         
         user:
           MACHINE: gaea
           ACCOUNT: hfv3gfs
         workflow:
           EXPT_SUBDIR: run_basic_srw
           USE_CRON_TO_RELAUNCH: true
           CRON_RELAUNCH_INTVL_MNTS: 3
         task_get_extrn_ics:
           USE_USER_STAGED_EXTRN_FILES: true
           EXTRN_MDL_SOURCE_BASEDIR_ICS: /lustre/f2/dev/role.epic/contrib/UFS_SRW_data/v2p2/input_model_data/FV3GFS/grib2/${yyyymmddhh}
         task_get_extrn_lbcs:
           USE_USER_STAGED_EXTRN_FILES: true
           EXTRN_MDL_SOURCE_BASEDIR_LBCS: /lustre/f2/dev/role.epic/contrib/UFS_SRW_data/v2p2/input_model_data/FV3GFS/grib2/${yyyymmddhh}
      
      Users on a different system would update the machine, account, and data paths accordingly. Additional changes may be required based on the system and experiment. More detailed guidance is available in :numref:`Section %s <UserSpecificConfig>`. Parameters and valid values are listed in :numref:`Section %s <ConfigWorkflow>`. 

   #. Generate the experiment workflow. 

      .. code-block:: console

         ./generate_FV3LAM_wflow.py

   #. Run the workflow from the experiment directory (``$EXPTDIR``). By default, the path to this directory is ``${EXPT_BASEDIR}/${EXPT_SUBDIR}`` (see :numref:`Section %s <DirParams>` for more detail). There are several methods for running the workflow, which are discussed in :numref:`Section %s <Run>`. Most require the :ref:`Rocoto Workflow Manager <RocotoInfo>`. For example, if the user automated the workflow using cron, run: 

      .. code-block:: console
         
         cd $EXPTDIR
         rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   
      The user can resubmit the ``rocotostat`` command as needed to check the workflow progress.

      If the user has Rocoto but did *not* automate the workflow using :term:`cron`, run: 

      .. code-block:: console

         cd $EXPTDIR
         ./launch_FV3LAM_wflow.sh

      To (re)launch the workflow and check the experiment's progress, run:

      .. code-block:: console

         ./launch_FV3LAM_wflow.sh; tail -n 40 log.launch_FV3LAM_wflow

      The workflow must be relaunched regularly and repeatedly until the log output includes a ``Workflow status: SUCCESS`` message indicating that the experiment has finished.

Optionally, users may :ref:`configure their own grid <UserDefinedGrid>` or :ref:`vertical levels <VerticalLevels>` instead of using a predefined grid and default set of vertical levels. Users can also :ref:`plot the output <PlotOutput>` of their experiment(s) or :ref:`run verification tasks using METplus <vxconfig>`.
