.. _NCQuickstart:

====================
Quick Start Guide
====================

This chapter provides a brief summary of how to build and run the SRW Application. The steps will run most smoothly on `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems. Users should expect to reference other chapters of this User's Guide, particularly :numref:`Chapter %s: Building the SRW App <BuildSRW>` and :numref:`Chapter %s: Running the SRW App <RunSRW>`, for additional explanations regarding each step.


Install the HPC-Stack
===========================
SRW App users who are not working on a `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ platform will need to install the prerequisite software stack via :term:`HPC-Stack` prior to building the SRW App on a new machine. Users can find installation instructions in the :doc:`HPC-Stack documentation <hpc-stack:index>`. The steps will vary slightly depending on the user's platform. However, in all cases, the process involves (1) cloning the `HPC-Stack repository <https://github.com/NOAA-EMC/hpc-stack>`__, (2) reviewing/modifying the ``config/config_<system>.sh`` and ``stack/stack_<system>.yaml`` files, and (3) running the commands to build the stack. This process will create a number of modulefiles required for building the SRW App.

Once the HPC-Stack has been successfully installed, users can move on to building the SRW Application.

.. _QuickBuildRun:

Building and Running the UFS SRW Application 
===============================================

For a detailed explanation of how to build and run the SRW App on any supported system, see :numref:`Chapter %s: Building the SRW App <BuildSRW>` and :numref:`Chapter %s: Running the SRW App <RunSRW>`. :numref:`Figure %s <AppBuildProc>` outlines the steps of the build process. The overall procedure for generating an experiment is shown in :numref:`Figure %s <AppOverallProc>`, with the scripts to generate and run the workflow shown in red. An overview of the required steps appears below. However, users can expect to access other referenced sections of this User's Guide for more detail.

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

      where ``<machine_name>`` is replaced with the name of the user's platform/system. Valid values include: ``cheyenne`` | ``gaea`` | ``hera`` | ``jet`` | ``linux`` | ``macos`` | ``noaacloud`` | ``orion`` | ``wcoss2``

      For additional details, see :numref:`Section %s <DevBuild>`, or view :numref:`Section %s <CMakeApproach>` to try the CMake build approach instead. 

   #. Users on a `Level 2-4 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ system must download and stage data (both the fix files and the :term:`IC/LBC <IC/LBCs>` files) according to the instructions in :numref:`Section %s <DownloadingStagingInput>`. Standard data locations for Level 1 systems appear in :numref:`Table %s <DataLocations>`.

   #. Load the python environment for the regional workflow. Users on Level 2-4 systems will need to use one of the existing ``wflow_<platform>`` modulefiles (e.g., ``wflow_macos``) and adapt it to their system. Then, run:

      .. code-block:: console
         
         source <path/to/etc/lmod-setup.sh/or/lmod-setup.csh> <platform>
         module use <path/to/modulefiles>
         module load wflow_<platform>

      where ``<platform>`` refers to a valid machine name (see :numref:`Section %s <user>`). After loading the workflow, users should follow the instructions printed to the console. For example, if the output says: 

      .. code-block:: console

         Please do the following to activate conda:
            > conda activate regional_workflow
      
      then the user should run ``conda activate regional_workflow`` to activate the regional workflow environment. 

      .. note::
         If users source the *lmod-setup* file on a system that doesn't need it, it will not cause any problems (it will simply do a ``module purge``).

   #. Configure the experiment: 

      .. code-block:: console

         cd ush
         cp config.community.yaml config.yaml
      
      Users will need to open the ``config.yaml`` file and adjust the experiment parameters in it to suit the needs of their experiment (e.g., date, grid, physics suite). At a minimum, users need to modify the ``MACHINE`` parameter. In most cases, users will need to specify the ``ACCOUNT`` parameter and the location of the experiment data (see :numref:`Section %s <Data>` for Level 1 system default locations). Additional changes may be required based on the system and experiment. More detailed guidance is available in :numref:`Section %s <UserSpecificConfig>`. Parameters and valid values are listed in :numref:`Chapter %s <ConfigWorkflow>`. 

      To determine whether the ``config.yaml`` file adjustments are valid, users can run:

      .. code-block:: console

         ./config_utils.py -c $PWD/config.yaml -v $PWD/config_defaults.yaml
      
      A correct ``config.yaml`` file will output a ``SUCCESS`` message. A ``config.yaml`` file with problems will output a ``FAILURE`` message describing the problem. 

   #. Generate the experiment workflow. 

      .. code-block:: console

         ./generate_FV3LAM_wflow.py

   #. Run the regional workflow. There are several methods available for this step, which are discussed in :numref:`Section %s <Run>`. One possible method is summarized below. It requires the :ref:`Rocoto Workflow Manager <RocotoInfo>`. 

      .. code-block:: console

         cd $EXPTDIR
         ./launch_FV3LAM_wflow.sh

      To (re)launch the workflow and check the experiment's progress:

      .. code-block:: console

         ./launch_FV3LAM_wflow.sh; tail -n 40 log.launch_FV3LAM_wflow

      The workflow must be relaunched regularly and repeatedly until the log output includes a ``Workflow status: SUCCESS`` message indicating that the experiment has finished.

Optionally, users may :ref:`configure their own grid <UserDefinedGrid>`, instead of using a predefined grid, and/or :ref:`plot the output <Graphics>` of their experiment(s).
