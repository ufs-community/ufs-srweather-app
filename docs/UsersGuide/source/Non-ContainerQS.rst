.. _NCQuickstart:

============================
Non-Container Quick Start
============================

Install the HPC-Stack
===========================
SRW App users who are not working on a `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ platform will need to install the :term:`HPC-Stack` prior to building the SRW App on a new machine. Installation instructions appear in both the `HPC-Stack documentation <https://hpc-stack.readthedocs.io/en/latest/>`__ and in :numref:`Chapter %s <InstallBuildHPCstack>` of this User's Guide. The steps will vary slightly depending on the user's platform. However, in all cases, the process involves cloning the `HPC-Stack repository <https://github.com/NOAA-EMC/hpc-stack>`__, creating and entering a build directory, and invoking ``cmake`` and ``make`` to build the code. This process will create a number of modulefiles and scripts that will be used for setting up the build environment for the UFS SRW App. 

Once the HPC-Stack has been successfully installed, users can move on to building the UFS SRW Application.

.. 
   COMMENT: Are these notes relevant now that NCEPLIBS/NCEPLIBS-external have been changed to HPC-Stack?
   .. note::
      The ``ESMFMKFILE`` variable allows HPC-Stack to find the location where ESMF has been built; if users receive an ``ESMF not found, abort`` error, they may need to specify a slightly different location:

      .. code-block:: console

         export ESMFMKFILE=${INSTALL_PREFIX}/lib64/esmf.mk

      Then they can delete and re-create the build directory and continue the build process as described above.

   .. note::

      If users skipped the building of any of the software provided by HPC-Stack, they may need to add the appropriate locations to their ``CMAKE_PREFIX_PATH`` variable. Multiple directories may be added, separated by semicolons (;) as in the following example:

      .. code-block:: console

         cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DCMAKE_PREFIX_PATH=”${INSTALL_PREFIX};/location/of/other/software” -DOPENMP=ON .. 2>&1 | tee log.cmake


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

   #. Set up the build environment and build the executables.

      * **Option 1:** 

         .. code-block:: console
            
            ./devbuild.sh --platform=<machine_name>

         where <machine_name> is replaced with the name of the platform the user is working on. Valid values are: ``cheyenne`` | ``gaea`` | ``hera`` | ``jet`` | ``macos`` | ``odin`` | ``orion`` | ``singularity`` | ``wcoss_dell_p3``

      * **Option 2:**

         .. code-block:: console

            source etc/lmod-setup.sh <machine>

         where <machine> refers to the user's platform (e.g., ``macos``, ``gaea``, ``odin``, ``singularity``). 

         Users will also need to load the "build" modulefile appropriate to their system. On Level 3 & 4 systems, users can adapt an existing modulefile (such as ``build_macos_gnu``) to their system. 

         .. code-block:: console

            module use <path/to/modulefiles/directory>
            module load build_<platform>_<compiler>

         From the top-level ``ufs-srweather-app`` directory, run:

         .. code-block:: console

            mkdir build
            cd build
            cmake .. -DCMAKE_INSTALL_PREFIX=..
            make -j 4  >& build.out &

   #. Download and stage data (both the fix files and the :term:`IC/LBC` files) according to the instructions in :numref:`Chapter %s <DownloadingStagingInput>` (if on a Level 3-4 system).

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

Optionally, users may :ref:`configure their own grid <UserDefinedGrid>`, instead of using a predefined grid, and :ref:`plot the output <Graphics>` of their experiment(s).
