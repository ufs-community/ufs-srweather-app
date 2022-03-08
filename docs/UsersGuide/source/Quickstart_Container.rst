.. _QuickstartC:

=================================================
Containerized Workflow Quick Start (Recommended)
=================================================

This Workflow Quick Start Guide will help users to build and run the "out-of-the-box" case for the Unified Forecast System (:term:`UFS`) Short-Range Weather (SRW) Application using a container. The container approach provides a uniform enviroment in which to build and run the SRW. Normally, the details of building and running the SRW vary from system to system due to the many possible combinations of operating systems, compilers, :term:`MPI`’s, and package versions. Installation via an EPIC-provided container reduces this variability and allows for a smoother SRW build and run experience. 

The "out-of-the-box" SRW case described in this guide builds a weather forecast for June 15-16, 2019. Multiple convective weather events during these two days produced over 200 filtered storm reports. Severe weather was clustered in two areas: the Upper Midwest through the Ohio Valley and the Southern Great Plains. This forecast uses a predefined 25-km Continental United States (:term:`CONUS`) grid (RRFS_CONUS_25km), the Global Forecast System (:term:`GFS`) version 15.2 physics suite (FV3_GFS_v15p2 CCPP), and :term:`FV3`-based GFS raw external model data for initialization.

.. _DownloadCodeC:

Download the UFS SRW Application Code
===========================================
The SRW Application source code is publicly available on GitHub and can be run in a container or locally, depending on user preference. The SRW Application relies on a variety of components detailed in the :ref:`Components Chapter <Components>` of this User's Guide. Users must (1) clone the UFS SRW Application umbrella repository and then (2) run the ``checkout_externals`` script to link the necessary external repositories to the SRW App. The ``checkout_externals`` script uses the configuration file ``Externals.cfg`` in the top level directory of the SRW App and will clone the correct version of the regional workflow, pre-processing utilities, UFS Weather Model, and UPP source code into the appropriate directories under the ``regional_workflow`` and ``src`` directories. 

Working in the Cloud
-----------------------

Users building the SRW using NOAA's Cloud resources must complete a few additional steps to ensure the SRW builds and runs correctly. For those working on non-cloud-based systems, skip to :numref:`Step %s <BuildC>`.

On NOAA Cloud systems, certain environment variables must be set *before* building the container:
   
.. code-block:: 

   sudo su
   export SINGULARITY_CACHEDIR=/lustre/cache
   export SINGULARITY_TEMPDIR=/lustre/tmp

* If the ``cache`` and ``tmp`` directories do not exist already, they must be created. 

* ``/lustre`` is a fast but non-persistent file system used on NOAA cloud systems. To retain work completed in this directory, `tar the file <https://www.howtogeek.com/248780/how-to-compress-and-extract-files-using-the-tar-command-on-linux/>`__ and move it to the ``/contrib`` directory, which is much slower but persistent.

On NOAA Cloud systems, allocate a compute node on which to run the SRW. Then, build and run the SRW from that node:

.. code-block:: console

   salloc -N 1 
   module load gnu openmpi
   mpirun -n 1 hostname
      
This last command will output a hostname. Next, run ``ssh <hostname>``, replacing ``<hostname>`` with the actual hostname output in the prior command. 

.. _BuildC:

Set Up the Container
------------------------

Build the container:

.. code-block:: console

   singularity build --sandbox ubuntu20.04-epic-srwapp-1.0 docker://noaaepic/ubuntu20.04-epic-srwapp:1.0

.. hint::
   If a ``singularity: command not found`` error message appears, try running: ``module load singularity``.

Start the container and run an interactive shell within it: 

.. code-block:: console

   singularity shell -e --writable --bind /<local_base_dir>:/<path_to_container_dir_w_same_name> ubuntu20.04-epic-srwapp-1.0

The command above also binds the local directory to the container so that data can be shared between them. On NOAA systems, the local directory is usually the topmost directory (e.g., /lustre, /contrib, /work, or /home). Additional directories can be bound by adding another ``--bind /<local_base_dir>:/<container_dir>`` argument before the name of the container. 

.. important::
   * When binding two directories, they must have the same name. It may be necessary to ``cd`` into the container and create an appropriately named directory in the container using the ``mkdir`` command if one is not already there. 
   * Be sure to bind the directory that contains the data the experiment will access. 

Download the SRW Code
------------------------

Clone the develop branch of the UFS-SRW weather application repository:

.. code-block:: console

   git clone -b feature/singularity-addition https://github.com/EdwardSnyder-NOAA/ufs-srweather-app

.. 
   COMMENT: change repo for release

Check out submodules for the SRW Application:

.. code-block:: console

   cd ufs-srweather-app
   ./manage_externals/checkout_externals

If the ``manage_externals`` command brings up an error, it may be necessary to run ``ln -s /usr/bin/python3 /usr/bin/python`` first. 


.. _SetUpBuildC:

Set up the Build Environment
============================

If the SRW Application has been built in a container provided by the Earth Prediction Innovation Center (EPIC), set build environments and modules within the ``ufs-srweather-app`` directory as follows:

.. code-block:: console

   ln -s /usr/bin/python3 /usr/bin/python
   source /usr/share/lmod/6.6/init/profile
   module use /opt/hpc-modules/modulefiles/stack
   module load hpc hpc-gnu hpc-openmpi hpc-python
   module load netcdf hdf5 bacio sfcio sigio nemsio w3emc esmf fms crtm g2 png zlib g2tmpl ip sp w3nco cmake gfsio wgrib2 upp



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

The build will take a few minutes to complete. When it starts, a random number is printed to the console, and when it is done, a ``[1]+  Done`` message is printed to the console when you list the files in ``ufs-srweather-app/bin`` (``[1]+  Exit`` may indicate an error). Output from the build will be in the ``ufs-srweather-app/build/build.out`` file. When the build completes, you should see the forecast model executable ``ufs_model`` and several pre- and post-processing executables in the ``ufs-srweather-app/bin`` directory. These executables are described in :numref:`Table %s <ExecDescription>`. 

.. hint::

   If you see the build.out file, but there is no ``ufs-srweather-app/bin`` directory, wait a few more minutes for the build to complete.

Download and Stage the Data
============================

The SRW requires input files to run. These include static datasets, initial and boundary conditions 
files, and model configuration files. On Level 1 and 2 systems, the data required to run SRW tests are already available. For Level 3 and 4 systems, the data must be added. Detailed instructions on how to add the data can be found in the :numref:`Section %s Downloading and Staging Input Data <DownloadingStagingInput>`. :numref:`Sections %s <Input>` and :numref:`%s <OutputFiles>` contain useful background information on the input and output files used in the SRW. 

.. _GenerateForecastC:

Generate the Forecast Experiment 
=================================
Generating the forecast experiment requires three steps:

* Set experiment parameters
* Set Python and other environment parameters
* Run a script to generate the experiment workflow

The first two steps depend on the platform being used and are described here for each Level 1 platform. Users will need to adjust the instructions to their machine if they are working on a Level 2-4 platform. 

.. _SetUpConfigFileC:

Set Experiment Parameters
-------------------------
Each experiment requires certain basic information to run (e.g., date, grid, physics suite). This information is specified in the ``config.sh`` file. Two example ``config.sh`` templates are provided: ``config.community.sh`` and ``config.nco.sh``. They can be found in the ``ufs-srweather-app/regional_workflow/ush`` directory. The first file is a minimal example for creating and running an experiment in the *community* mode (with ``RUN_ENVIR`` set to ``community``). The second is an example for creating and running an experiment in the *NCO* (operational) mode (with ``RUN_ENVIR`` set to ``nco``).  The *community* mode is recommended in most cases and will be fully supported for this release. 

Make a copy of ``config.community.sh`` to get started (under ``<path-to-ufs-srweather-app>/regional_workflow/ush``). From the ``ufs-srweather-app`` directory, run:

.. code-block:: console

   cd ../regional_workflow/ush
   cp config.community.sh config.sh

The default settings in this file include a predefined 25-km :term:`CONUS` grid (RRFS_CONUS_25km), the :term:`GFS` v15.2 physics suite (FV3_GFS_v15p2 CCPP), and :term:`FV3`-based GFS raw external model data for initialization.

Next, edit the new ``config.sh`` file to customize it for your machine. At a minimum, change the ``MACHINE`` and ``ACCOUNT`` variables; then choose a name for the experiment directory by setting ``EXPT_SUBDIR``. If you have pre-staged the initialization data for the experiment, set ``USE_USER_STAGED_EXTRN_FILES="TRUE"``, and set the paths to the data for ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS``. For example:

.. code-block:: console

   MACHINE="SINGULARITY"
   ACCOUNT="none"
   EXPT_SUBDIR="GST"
   EXPT_BASEDIR="home/$USER/expt_dirs"
   COMPILER="gnu"

Sample settings are indicated below for Level 1 platforms. Detailed guidance applicable to all systems can be found in :numref:`Chapter %s: Configuring the Workflow <ConfigWorkflow>`, which discusses each variable and the options available. Additionally, information about the three predefined Limited Area Model (LAM) Grid options can be found in :numref:`Chapter %s: Limited Area Model (LAM) Grids <LAMGrids>`.

.. Important::

   If you set up the build environment with the GNU compiler in :numref:`Section %s <SetUpBuildC>`, you will have to add the line ``COMPILER="gnu"`` to the ``config.sh`` file.

Minimum parameter settings for Level 1 machines:

**Cheyenne:**

.. code-block:: console

   MACHINE="cheyenne"
   ACCOUNT="<my_account>"
   EXPT_SUBDIR="<my_expt_name>"
   USE_USER_STAGED_EXTRN_FILES="TRUE"
   EXTRN_MDL_SOURCE_BASEDIR_ICS="/glade/p/ral/jntp/UFS_SRW_app/model_data/FV3GFS"
   EXTRN_MDL_SOURCE_BASEDIR_LBCS="/glade/p/ral/jntp/UFS_SRW_app/model_data/FV3GFS"

**Hera:**

.. code-block:: console

   MACHINE="hera"
   ACCOUNT="<my_account>"
   EXPT_SUBDIR="<my_expt_name>"

**Jet, Orion, Gaea:**

The settings are the same as for Hera, except that ``"hera"`` should be switched to ``"jet"``, ``"orion"``, or ``"gaea"``, respectively. 

For **WCOSS**, edit ``config.sh`` with these WCOSS-specific parameters, and use a valid WCOSS project code for the account parameter:

.. code-block:: console

   MACHINE=”wcoss_cray” or MACHINE=”wcoss_dell_p3”
   ACCOUNT="my_account"
   EXPT_SUBDIR="my_expt_name"


**NOAA Cloud Systems:**

.. code-block:: console

   MACHINE="SINGULARITY"
   ACCOUNT="none"
   EXPT_SUBDIR="<expt_name>"
   EXPT_BASEDIR="lustre/$USER/expt_dirs"
   COMPILER="gnu"
   USE_USER_STAGED_EXTRN_FILES="TRUE"
   EXTRN_MDL_SOURCE_BASEDIR_ICS="/contrib/GST/model_data/FV3GFS"
   EXTRN_MDL_FILES_ICS=( "gfs.pgrb2.0p25.f000" )
   EXTRN_MDL_SOURCE_BASEDIR_LBCS="/contrib/GST/model_data/FV3GFS"
   EXTRN_MDL_FILES_LBCS=( "gfs.pgrb2.0p25.f006" "gfs.pgrb2.0p25.f012" )


.. _SetUpPythonEnvC:

Activate the Regional Workflow
----------------------------------------------
Next, activate the regional workflow. 

.. code-block:: console

   conda init
   source ~/.bashrc
   conda activate regional_workflow

The user should see ``(regional_workflow)`` in front of the Terminal prompt at this point. 


.. _GenerateWorkflowC: 

Generate the Regional Workflow
-------------------------------------------

Run the following command to generate the workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.sh

This workflow generation script creates an experiment directory and populates it with all the data needed to run through the workflow. The last line of output from this script should start with ``*/1 * * * *`` or ``*/3 * * * *``. 

The generated workflow will be in experiment directory specified in the ``config.sh`` file in :numref:`Step %s <SetUpConfigFileC>`. The settings for these paths can also be viewed in the console output from the ``./generate_FV3LAM_wflow.sh`` script or in the ``log.generate_FV3LAM_wflow`` file, which can be found in the experiment directory. 

Run the Workflow Using Stand-Alone Scripts
=============================================

.. note:: 
   The Rocoto workflow manager cannot be used inside a container. 

#. ``cd`` into the experiment directory

#. Set the environment variable ``EXPTDIR`` for either bash or csh, respectively:

   .. code-block:: console

      export EXPTDIR=`pwd`
      setenv EXPTDIR `pwd`

#. COPY the wrapper scripts from the regional_workflow directory into your experiment directory:

   .. code-block:: console

      cp ufs-srweather-app/regional_workflow/ush/wrappers/* .

#. Set the OMP_NUM_THREADS variable and fix dash/bash shell issue (this ensures the system does not use an alias of ``sh`` to dash). 

   .. code-block:: console

      export OMP_NUM_THREADS=1
      sed -i 's/bin\/sh/bin\/bash/g' *sh

#. RUN each of the listed scripts in order.  Scripts with the same stage number (listed in :numref:`Table %s <RegionalWflowTasks>`) may be run simultaneously.

   .. code-block:: console

      ./run_make_grid.sh
      ./run_get_ics.sh
      ./run_get_lbcs.sh
      ./run_make_orog.sh
      ./run_make_sfc_climo.sh
      ./run_make_ics.sh
      ./run_make_lbcs.sh
      ./run_fcst.sh
      ./run_post.sh


Plot the Output
===============
Two python scripts are provided to generate plots from the FV3-LAM post-processed GRIB2 output. Information on how to generate the graphics can be found in :numref:`Chapter %s <Graphics>`.
