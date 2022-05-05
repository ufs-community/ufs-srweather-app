.. _QuickstartC:

====================================
Container-Based Quick Start Guide
====================================

This Quick Start Guide will help users to build and run the "out-of-the-box" case for the Unified Forecast System (:term:`UFS`) Short-Range Weather (SRW) Application using a `Singularity <https://sylabs.io/guides/3.5/user-guide/introduction.html>`__ :term:`container`. The container approach provides a uniform enviroment in which to build and run the SRW App. Normally, the details of building and running the SRW App vary from system to system due to the many possible combinations of operating systems, compilers, :term:`MPI`’s, and package versions available. Installation via Singularity container reduces this variability and allows for a smoother SRW App build experience. However, the container is not compatible with the `Rocoto workflow manager <https://github.com/christopherwharrop/rocoto/wiki/Documentation>`__, so users must run each task in the workflow manually. Additionally, the Singularity container can only run on a single compute node, which makes the container-based approach inadequate for large experiments. It is an excellent starting point for running the "out-of-the-box" SRW App case and other small experiments. However, the :ref:`non-container approach <BuildRunSRW>` may be more appropriate for those users who desire additional customizability or more compute power, particularly if they already have experience running the SRW App.

The "out-of-the-box" SRW App case described in this User's Guide builds a weather forecast for June 15-16, 2019. Multiple convective weather events during these two days produced over 200 filtered storm reports. Severe weather was clustered in two areas: the Upper Midwest through the Ohio Valley and the Southern Great Plains. This forecast uses a predefined 25-km Continental United States (:term:`CONUS`) grid (RRFS_CONUS_25km), the Global Forecast System (:term:`GFS`) version 16 physics suite (FV3_GFS_v16 :term:`CCPP`), and :term:`FV3`-based GFS raw external model data for initialization.

.. attention::

   All UFS applications support `four platform levels <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_. The steps described in this chapter will work most smoothly on preconfigured (Level 1) systems. However, this guide can serve as a starting point for running the SRW App on other systems, too. 

.. _DownloadCodeC:

Building the UFS SRW Application
=========================================== 

Prerequisites: Install Singularity
------------------------------------

To build and run the SRW App using a Singularity container, first install the Singularity package according to the `Singularity Installation Guide <https://sylabs.io/guides/3.2/user-guide/installation.html#>`_. This will include the installation of dependencies and the installation of the Go programming language. SingularityCE Version 3.7 or above is recommended. 

.. warning:: 
   Docker containers can only be run with root privileges, and users cannot have root privileges on HPC's. Therefore, it is not possible to build the SRW, which uses the HPC-Stack, inside a Docker container on an HPC system. A Docker image may be pulled, but it must be run inside a container such as Singularity. 


Working in the Cloud
-----------------------

For those working on non-cloud-based systems, skip to :numref:`Step %s <WorkOnHPC>`. Users building the SRW App using NOAA's Cloud resources must complete a few additional steps to ensure that the SRW App builds and runs correctly. 

On NOAA Cloud systems, certain environment variables must be set *before* building the container:
   
.. code-block:: 

   sudo su
   export SINGULARITY_CACHEDIR=/lustre/cache
   export SINGULARITY_TEMPDIR=/lustre/tmp

If the ``cache`` and ``tmp`` directories do not exist already, they must be created with a ``mkdir`` command. 

.. note:: 
   ``/lustre`` is a fast but non-persistent file system used on NOAA cloud systems. To retain work completed in this directory, `tar the files <https://www.howtogeek.com/248780/how-to-compress-and-extract-files-using-the-tar-command-on-linux/>`__ and move them to the ``/contrib`` directory, which is much slower but persistent.

.. _WorkOnHPC:

Working on HPC Systems
--------------------------

Those *not* working on HPC systems may skip to the :ref:`next step <BuildC>`. 
On HPC systems (including NOAA's Cloud platforms), allocate a compute node on which to run the SRW App. On NOAA's Cloud platforms, the following commands will allocate a compute node:

.. code-block:: console

   salloc -N 1 
   module load gnu openmpi
   mpirun -n 1 hostname
   ssh <hostname>

The third command will output a hostname. Replace ``<hostname>`` in the last command with the output from the third command. After "ssh-ing" to the compute node in the last command, build and run the SRW App from that node. 

The appropriate commands on other Level 1 platforms will vary, and users should consult the `documentation <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ for those platforms. In general, the allocation command will follow one of these two patterns depending on whether the system uses the Slurm or PBS resource manager respectively:

.. code-block:: console

   salloc -N 1 -n <cores-per-node> -A <account> -t <time> -q <queue/qos> --partition=<system> [-M <cluster>]
   qsub -I -lwalltime=<time> -A <account> -q <destination> -lselect=1:ncpus=36:mpiprocs=36

For example, on Orion, which uses the Slurm resource manager, run:

.. code-block:: console

   salloc -N 1 -n 40 -A epic-ps -t 2:30:00 -q batch --partition=orion

For more information on the ``salloc`` command options, see Slurm's `documentation <https://slurm.schedmd.com/salloc.html>`__. 

On Cheyenne, which uses the PBS resource manager, run:

.. code-block:: console

   qsub -I -lwalltime=1:00:00 -A scsg0002 -q regular -lselect=1:ncpus=36:mpiprocs=36

For more information on the ``qsub`` command options, see the `PBS Manual §2.59.3 <https://2021.help.altair.com/2021.1/PBSProfessional/PBS2021.1.pdf>`__, (p. 1416).

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

The command above also binds the local directory to the container so that data can be shared between them. On Level 1 systems, ``<local_base_dir>`` is usually the topmost directory (e.g., /lustre, /contrib, /work, or /home). Additional directories can be bound by adding another ``--bind /<local_base_dir>:/<container_dir>`` argument before the name of the container. 

.. attention::
   * When binding two directories, they must have the same name. It may be necessary to ``cd`` into the container and create an appropriately named directory in the container using the ``mkdir`` command if one is not already there. 
   * Be sure to bind the directory that contains the experiment data. 


.. _SetUpBuildC:

Set up the Build Environment
============================

Set the build environments and modules within the ``ufs-srweather-app`` directory as follows:

.. code-block:: console

   cd ubuntu20.04-epic-srwapp-1.0/opt/ufs-srweather-app/
   ln -s /usr/bin/python3 /usr/bin/python
   source /usr/share/lmod/6.6/init/profile
   module use /opt/hpc-modules/modulefiles/stack
   module load hpc hpc-gnu hpc-openmpi hpc-python
   module load netcdf hdf5 bacio sfcio sigio nemsio w3emc esmf fms crtm g2 png zlib g2tmpl ip sp w3nco cmake gfsio upp



Build the Executables
======================

From the ``ufs-srweather-app`` directory, ``cd`` into the build directory and run the script that builds the SRW App: 

.. code-block:: console

   cd build
   source build-srw.sh

Download and Stage the Data
============================

The SRW App requires input files to run. These include static datasets, initial and boundary condition files, and model configuration files. On Level 1 and 2 systems, the data required to run SRW App tests are already available, as long as the ``--bind`` command in :numref:`Step %s <BuildC>` included the directory with the data. For Level 3 and 4 systems, the data must be added. Detailed instructions on how to add the data can be found in the :numref:`Section %s <DownloadingStagingInput>`. :numref:`Sections %s <Input>` and :numref:`%s <OutputFiles>` contain useful background information on the input and output files used in the SRW App. 

.. _GenerateForecastC:

Generate the Forecast Experiment 
=================================
To generate the forecast experiment, users must:

#. :ref:`Set experiment parameters <SetUpConfigFileC>`
#. :ref:`Set Python and other environment parameters to activate the regional workflow <SetUpPythonEnvC>`
#. :ref:`Run a script to generate the experiment workflow <GenerateWorkflowC>`

The first two steps depend on the platform being used and are described here for each Level 1 platform. Users will need to adjust the instructions to their machine if they are working on a Level 2-4 platform. 

.. _SetUpConfigFileC:

Set the Experiment Parameters
-------------------------------
Each experiment requires certain basic information to run (e.g., date, grid, physics suite). This information is specified in the ``config.sh`` file. Two example ``config.sh`` templates are provided: ``config.community.sh`` and ``config.nco.sh``. They can be found in the ``ufs-srweather-app/regional_workflow/ush`` directory. The first file is a minimal example for creating and running an experiment in the *community* mode (with ``RUN_ENVIR`` set to ``community``). The second is an example for creating and running an experiment in the *NCO* (operational) mode (with ``RUN_ENVIR`` set to ``nco``).  The *community* mode is recommended in most cases and will be fully supported for this release. 

Make a copy of ``config.community.sh`` to get started. From the ``ufs-srweather-app`` directory, run the following commands:

.. code-block:: console

   cd regional_workflow/ush
   cp config.community.sh config.sh

The default settings in this file include a predefined 25-km :term:`CONUS` grid (RRFS_CONUS_25km), the :term:`GFS` v16 physics suite (FV3_GFS_v16 :term:`CCPP`), and :term:`FV3`-based GFS raw external model data for initialization.

Next, edit the new ``config.sh`` file to customize it for your experiment. At a minimum, update the ``MACHINE`` and ``ACCOUNT`` variables; then choose a name for the experiment directory by setting ``EXPT_SUBDIR``: 

.. code-block:: console

   MACHINE="SINGULARITY"
   ACCOUNT="none"
   EXPT_SUBDIR="<expt_name>"
   EXPT_BASEDIR="/home/$USER/expt_dirs"
   COMPILER="gnu"

Additionally, set ``USE_USER_STAGED_EXTRN_FILES="TRUE"``, and add the correct paths to the data. The following is a sample for a 24-hour forecast:

.. code-block::

   USE_USER_STAGED_EXTRN_FILES="TRUE"
   EXTRN_MDL_SOURCE_BASEDIR_ICS="/path/to/model_data/FV3GFS"
   EXTRN_MDL_FILES_ICS=( "gfs.pgrb2.0p25.f000" )
   EXTRN_MDL_SOURCE_BASEDIR_LBCS="/path/to/model_data/FV3GFS"
   EXTRN_MDL_FILES_LBCS=( "gfs.pgrb2.0p25.f006" "gfs.pgrb2.0p25.f012" "gfs.pgrb2.0p25.f018" "gfs.pgrb2.0p25.f024" )

On Level 1 systems, ``/path/to/model_data/FV3GFS`` should correspond to the location of the machine's global data. Alternatively, the user can add the path to their local data if they downloaded it as described in :numref:`Step %s <InitialConditions>`. 

On NOAA Cloud platforms, users may continue to the :ref:`next step <SetUpPythonEnvC>`. On other Level 1 systems, additional file paths must be set: 

   #. From the ``regional_workflow/ush`` directory, run: ``cd machine``. 
   #. Open the file corresponding to the Level 1 platform in use (e.g., ``vi orion.sh``).
   #. Copy the section of code starting after ``#UFS SRW App specific paths``. For example, on Orion, the following text must be copied:

      .. code-block:: console

         FIXgsm=${FIXgsm:-"/work/noaa/global/glopara/fix/fix_am"}
         FIXaer=${FIXaer:-"/work/noaa/global/glopara/fix/fix_aer"}
         FIXlut=${FIXlut:-"/work/noaa/global/glopara/fix/fix_lut"}
         TOPO_DIR=${TOPO_DIR:-"/work/noaa/global/glopara/fix/fix_orog"}
         SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/work/noaa/global/glopara/fix/fix_sfc_climo"}
         FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}

   #. Exit the system-specific file and open ``singularity.sh``. 
   #. Comment out or delete the corresponding chunk of text in ``singularity.sh``, and paste the correct paths from the system-specific file in its place. For example, on Orion, delete the text below from ``singularity.sh``, and replace it with the Orion-specific text copied in the previous step. 

      .. code-block:: console

         # UFS SRW App specific paths
         FIXgsm=${FIXgsm:-"/contrib/global/glopara/fix/fix_am"}
         FIXaer=${FIXaer:-"/contrib/global/glopara/fix/fix_aer"}
         FIXlut=${FIXlut:-"/contrib/global/glopara/fix/fix_lut"}
         TOPO_DIR=${TOPO_DIR:-"/contrib/global/glopara/fix/fix_orog"}
         SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/contrib/global/glopara/fix/fix_sfc_climo"}
         FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/needs/to/be/specified"}

On Level 1 systems, it should be possible to continue to the :ref:`next step <SetUpPythonEnvC>` after changing the settings above. Detailed guidance applicable to all systems can be found in :numref:`Chapter %s: Configuring the Workflow <ConfigWorkflow>`, which discusses each variable and the options available. For users interested in experimenting with a different grid, information about the three predefined Limited Area Model (LAM) Grid options can be found in :numref:`Chapter %s: Limited Area Model (LAM) Grids <LAMGrids>`.

.. _SetUpPythonEnvC:

Activate the Regional Workflow
----------------------------------------------
Next, activate the regional workflow: 

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

The generated workflow will be in the experiment directory specified in the ``config.sh`` file in :numref:`Step %s <SetUpConfigFileC>`.  

.. _RunUsingStandaloneScripts:

Run the Workflow Using Stand-Alone Scripts
=============================================

.. note:: 
   The Rocoto workflow manager cannot be used inside a container. 

The regional workflow can be run using standalone shell scripts in cases where the Rocoto software is not available on a given platform. If Rocoto *is* available, see :numref:`Section %s <RocotoRun>` to run the workflow using Rocoto. 

#. ``cd`` into the experiment directory

#. Set the environment variable ``EXPTDIR`` for either bash or csh, respectively:

   .. code-block:: console

      export EXPTDIR=`pwd`
      setenv EXPTDIR `pwd`

#. Copy the wrapper scripts from the regional_workflow directory into the experiment directory. Each workflow task has a wrapper script that sets environment variables and runs the job script.

   .. code-block:: console

      cp ufs-srweather-app/regional_workflow/ush/wrappers/* .

#. Set the ``OMP_NUM_THREADS`` variable and fix dash/bash shell issue (this ensures the system does not use an alias of ``sh`` to dash). 

   .. code-block:: console

      export OMP_NUM_THREADS=1
      sed -i 's/bin\/sh/bin\/bash/g' *sh

#. Run each of the listed scripts in order.  Scripts with the same stage number (listed in :numref:`Table %s <RegionalWflowTasks>`) may be run simultaneously.

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

Check the batch script output file in your experiment directory for a “SUCCESS” message near the end of the file.

.. _RegionalWflowTasks:

.. table::  List of tasks in the regional workflow in the order that they are executed.
            Scripts with the same stage number may be run simultaneously. The number of
            processors and wall clock time is a good starting point for Cheyenne or Hera 
            when running a 48-h forecast on the 25-km CONUS domain. For a brief description of tasks, see :numref:`Table %s <WorkflowTasksTable>`. 

   +------------+------------------------+----------------+----------------------------+
   | **Stage/** | **Task Run Script**    | **Number of**  | **Wall clock time (H:MM)** |
   | **step**   |                        | **Processors** |                            |             
   +============+========================+================+============================+
   | 1          | run_get_ics.sh         | 1              | 0:20 (depends on HPSS vs   |
   |            |                        |                | FTP vs staged-on-disk)     |
   +------------+------------------------+----------------+----------------------------+
   | 1          | run_get_lbcs.sh        | 1              | 0:20 (depends on HPSS vs   |
   |            |                        |                | FTP vs staged-on-disk)     |
   +------------+------------------------+----------------+----------------------------+
   | 1          | run_make_grid.sh       | 24             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 2          | run_make_orog.sh       | 24             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 3          | run_make_sfc_climo.sh  | 48             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 4          | run_make_ics.sh        | 48             | 0:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 4          | run_make_lbcs.sh       | 48             | 0:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 5          | run_fcst.sh            | 48             | 0:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 6          | run_post.sh            | 48             | 0:25 (2 min per output     |
   |            |                        |                | forecast hour)             |
   +------------+------------------------+----------------+----------------------------+

.. hint:: 
   If any of the scripts return an error that "Primary job terminated normally, but one process returned a non-zero exit code," there may not be enough space on one node to run the process. On an HPC system, the user will need to allocate a(nother) compute node. The process for doing so is system-dependent, and users should check the documentation available for their HPC system. Instructions for allocating a compute node on NOAA Cloud systems can be viewed in the :numref:`Step %s <WorkOnHPC>` as an example. 

.. note::
   On most HPC systems, users will need to submit a batch job to run multi-processor jobs. On some HPC systems, users may be able to run the first two jobs (serial) on a login node/command-line. Example scripts for Slurm (Hera) and PBS (Cheyenne) resource managers are provided (``sq_job.sh`` and ``qsub_job.sh``, respectively). These examples will need to be adapted to each user's system. Alternatively, some batch systems allow users to specify most of the settings on the command line (with the ``sbatch`` or ``qsub`` command, for example). 

Plot the Output
===============
Two python scripts are provided to generate plots from the FV3-LAM post-processed GRIB2 output. Information on how to generate the graphics can be found in :numref:`Chapter %s <Graphics>`.
