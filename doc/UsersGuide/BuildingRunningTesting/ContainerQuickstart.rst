.. _QuickstartC:

====================================
Container-Based Quick Start Guide
====================================

This chapter provides a unified Quick Start Guide for building and running the
“out-of-the-box” community test case for the Unified Forecast System (:term:`UFS`)
Short-Range Weather (SRW) Application using container technology. Containers
provide a reproducible, portable, and uniform environment that includes a
pre-built software stack for the SRW App. This eliminates the need to compile
large dependency software stacks on every machine, reduces setup time, and supports
consistent workflows across different systems and cloud platforms.

Two container options are provided:

* **Intel-based container:** uses Intel compilers and Intel MPI.
* **GNU-based container:** uses fully open-source GNU compilers and OpenMPI.

Additional differences between the containers are that the Intel-based image includes pre-built SRW App binaries. 
When using the GNU-based container, users download UFS SRW App (develop branch) from GitHub and build it interactively by 
shelling into the container.

This guide demonstrates how to:

* Build a Singularity/Apptainer image containing a software stack
* Use the resulting container image to to build the UFS SRW Application (for GNU-based container) or stage the containerized pre-built UFS SRW App on a host system (Intel-based container) 
* Use the container to run the provided “out-of-the-box” community test case.

Both workflows rely on `Singularity/Apptainer <https://apptainer.org/docs/user/1.2/introduction.html>`__ 
to transform a DockerHub-based container into a Singularity/Apptainer 
image or a writable container sandbox. The SRW Application is executed only through this Singularity/Apptainer image (or sandbox)
suitable for HPC systems or compute environments where users do not have root privileges, required for running Docker.

The basic "out-of-the-box" case described in this User's Guide builds a weather forecast for 
June 15-16, 2019. Multiple convective weather events during these two days produced over 200 
filtered storm reports. This forecast uses a predefined 25-km 
Continental United States (:term:`CONUS`) grid (RRFS_CONUS_25km), 
the Global Forecast System (:term:`GFS`) version 16 physics suite (FV3_GFS_v16 :term:`CCPP`), 
and :term:`FV3`-based GFS raw external model data for initialization.

.. attention::

   This chapter applies **only** to container-based builds.
   For a non-container Quick Start Guide, see :numref:`Section %s <NCQuickstart>`.
   For detailed build instructions without containers, see :numref:`Section %s <BuildSRW>`.

-------------------
Prerequisites 
-------------------

The following prerequisites apply to **all** container workflows.


Singularity/Apptainer Installation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Users must have **Singularity** or **Apptainer** installed on their compute platform. 

.. note::

   As of November 2021, the Linux-supported version of Singularity has been `renamed <https://apptainer.org/news/community-announcement-20211130/>`__ to *Apptainer*. Apptainer has maintained compatibility with Singularity, so ``singularity`` commands should work with either Singularity or Apptainer (see compatibility details `here <https://apptainer.org/docs/user/1.2/singularity_compatibility.html>`__.)

Apptainer is fully compatible with Singularity, and commands shown here using ``singularity`` may be 
replaced with ``apptainer`` as appropriate.

On many HPC systems, Singularity/Apptainer could be available as a loadable module:

.. code-block:: console

   module load singularity
   # or
   module load apptainer

When not available system-wide, Apptainer could be installed on the Linux-based system following `Apptainer Installation Guide <https://apptainer.org/docs/admin/1.2/installation.html>`__. This will include the installation of all dependencies. 

Compiler and MPI Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Although containers provide a complete SRW software stack, MPI-based execution still
depends on the compilers and MPI implementation available through the host system.

* The **Intel-based container** requires Intel compilers and Intel MPI (or the
  Intel oneAPI toolkit).
* The **GNU-based container** requires GNU compilers (GCC 12+ recommended) and an
  MPI library compatible with OpenMPI (e.g., system OpenMPI or Cray-MPICH).

Users must choose a container consistent with the host environment's compiler and
MPI availability.

.. note::

   Building a singularity container image/sandbox relies on user's temporary space (TMP); these requirements are much higher for 
   Intel-based container. The example is given in :ref:`Appendix` on seting up TMP spaces for singularity to avoid exceeding default TMP space quotas.

----------------------------------------
Download and Stage Input Data
----------------------------------------

Both Intel and GNU container workflows require the same SRW App input datasets.
These include:

* static files
* fixed fields
* grid and orography
* initial conditions (ICs)
* lateral boundary conditions (LBCs)
* configuration files

On **Level 1 Systems** (see :srw-wiki:`Supported Platforms and Compilers <Supported-Platforms-and-Compilers>`), these datasets are pre-staged. They become available
inside the container as long as the top-level directory containing the data is bound via ``-B`` option.

On **Level 2–4 Systems**, users must download and unpack the data manually:

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/experiment-user-cases/release-public-v3.0.0/out-of-the-box/fix_data.tgz
   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/experiment-user-cases/release-public-v3.0.0/out-if-the-box/gst_data.tgz

   tar -xzf fix_data.tgz
   tar -xzf gst_data.tgz

For more information about data organization, see :numref:`Section %s <DownloadingStagingInput>`. Sections :numref:`%s <Input>` and :numref:`%s <OutputFiles>` contain useful background information on the input and output files used in the SRW App.

.. _DownloadCodeC:

----------------------------------------
Intel-Based Container Workflow
----------------------------------------

The Intel-based workflow uses a pre-built container that includes the SRW App
software stack built with Intel compilers and Intel MPI. This workflow is
recommended for systems where Intel toolchains are standard (e.g., Level 1
platforms).

.. _BuildC:

Obtain or Build the Intel-Based Singularity Container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**On Level 1 systems**, pre-built images exist at system-specific shared paths.

.. list-table:: Locations of pre-built containers
   :widths: 20 50
   :header-rows: 1

   * - Machine
     - File Location
   * - Derecho [#fn]_
     - /glade/work/epicufsrt/contrib/containers
   * - Gaea-C6 [#fn]_
     - /gpfs/f6/bil-fire8/world-shared/containers
   * - Hera
     - /scratch1/NCEPDEV/nems/role.epic/containers
   * - NOAA Cloud [#fn]_
     - /contrib/EPIC/containers
   * - Orion/Hercules
     - /work/noaa/epic/role-epic/contrib/containers

.. [#fn] On these systems, container testing shows inconsistent results. 

.. note::
   * The NOAA Cloud containers are accessible only to those with EPIC resources. 

It is practical to set an environment variable to point to the container: 

.. code-block:: console

   export img=/path/to/ubuntu22.04-intel-ue-1.6.0-srw-dev.img

Users may convert the read-only image in a shared location to a writable sandbox in user's space:

.. code-block:: console

   singularity build --sandbox ubuntu22.04-intel-ue-1.6.0-srw-dev $img

Signature warnings may be ignored.

**On Level 2–4 systems**, build a sandbox directly from the Docker Hub repository:

.. code-block:: console

   singularity build --sandbox ubuntu22.04-intel-ue-1.6.0-srw-dev \
        docker://noaaepic/ubuntu22.04-intel21.10-srw:ue160-fms202401-dev

A release-tagged container may be built in a similar way:

.. code-block:: console

   singularity build --sandbox ubuntu22.04-intel-srw-release-public-v3.0.0 \
        docker://noaaepic/ubuntu22.04-intel21.10-srw:ue160-fms202401-release3
        

Set an environment variable to point to your sandbox container: 
 
.. code-block:: console

   export img=/path/to/ubuntu22.04-intel-ue-1.6.0-srw-dev

.. _RunContainer:

Start the Intel Container and Retrieve a Staging Script 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Copy the staging ``stage-srw.sh`` script from the container to the local working directory:

.. code-block:: console

   singularity exec -B /<local_base_dir>:/<container_dir> $img \
        cp /opt/ufs-srweather-app/container-scripts/stage-srw.sh .

The ``-B`` option binds the host directory ``/<local_base_dir>`` into the container at ``/<container_dir>``. 
Typically, both paths are the same, but ``/<container_dir>`` may be set differently to change how the directory is referenced inside the container.

.. attention::
   Be sure to bind the directory that contains the experiment data!  

Explore the container and view available directories:

.. code-block:: console

   singularity shell $img
   cd /
   ls 

The list of directories printed will be similar to this: 

.. code-block:: console

   autofs	 dev	      gpfs	  lfs2	 lib64	 ncrc  sbin	    srv			      u
   bin	 discover     home	  lfs3	 libx32  opt   scratch	    sw			      usr
   boot	 environment  host_lib64  lfs4	 lustre  proc  scratch1     sys			      usw
   contrib  etc	      lfs	  lib	 media	 root  scratch2     third-party-programs.txt  var
   data	 glade	      lfs1	  lib32  mnt	 run   singularity  tmp			      work

Users run ``exit`` to exit the container shell. 

Generate the Forecast Experiment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To generate the forecast experiment, users do the following steps:

#. :ref:`Stage the container <SetUpCont>`
#. :ref:`Set experiment parameters to configure the workflow <SetUpConfigFileC>`
#. :ref:`Run a script to generate the experiment workflow <GenerateWorkflowC>`

.. _SetUpCont:

To set up the container with your host system, run the ``stage-srw.sh`` script:

.. code-block:: console

   ./stage-srw.sh -c=<compiler> -m=<mpi> -p=<platform> -i=$img

where:

   * ``-c`` indicates the compiler on the user's local machine (e.g., ``intel/2022.1.2``, ``intel-oneapi-compilers/2022.2.1``, ``intel/2023.2.0``)
   * ``-m`` indicates the :term:`MPI` on the user's local machine (e.g., ``impi/2022.1.2``, ``intel-oneapi-mpi/2021.7.1``, ``cray-mpich/8.1.28``)
   * ``<platform>`` refers to the local machine (e.g., ``hera``, ``derecho``, ``noaacloud``). See ``MACHINE`` in :numref:`Section %s <user>` for a full list of options.
   * ``-i`` indicates the full path to the container image that was built in :numref:`Step %s <BuildC>` (``ubuntu22.04-intel-ue-1.6.0-srw-dev`` or ``ubuntu22.04-intel-ue-1.6.0-srw-dev.img`` by default).

For example, on Hera, the command would be:

.. code-block:: console

   ./stage-srw.sh -c=intel/2022.1.2 -m=impi/2022.1.2 -p=hera -i=$img

.. attention::

   The user must have an Intel compiler and MPI on their system because the container uses an Intel compiler and MPI. Intel compilers are now available for free as part of the `Intel oneAPI Toolkit <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__.

This produces:

* ``srw.sh`` — wrapper script
* ``ufs-srweather-app/`` — SRW App repository

.. _SetUpConfigFileC:

Configure the Workflow
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Configuring the workflow for the container is similar to configuring the workflow without a container. The only exception is that there is no need to activate the ``srw_app`` conda environment. That is because there is a conflict between the container's conda and the host’s conda. To get around this, the container’s conda environment bin directory is appended to the system’s ``PATH`` variable in the ``python_srw.lua`` and ``build_<platform>_intel.lua`` modulefiles with the ``stage-srw.sh`` script. Activate the workflow by running the following commands: 
Load workflow modules:

.. code-block:: console

   module use ufs-srweather-app/modulefiles
   module load wflow_<platform>

where: 

   * ``<platform>`` is a valid, lowercased machine/platform name (see the ``MACHINE`` variable in :numref:`Section %s <user>`). 

Generally, the following variables need to be configured:

* ``MACHINE``  
* ``ACCOUNT``  
* paths to ICs/LBCs  
* (optional) cron automation settings

For more detailed instructions on experiment configuration, refer to :numref:`Section %s <UserSpecificConfig>`. 
Follow the steps below to configure the out-of-the-box SRW App case with an automated Rocoto workflow. 

   #. Copy the out-of-the-box case from ``config.community.yaml`` to ``config.yaml``. This file contains basic information (e.g., forecast date, grid, physics suite) required for the experiment.   
      
      .. code-block:: console

         cd ufs-srweather-app/ush
         cp config.community.yaml config.yaml

      The default settings include a predefined 25-km :term:`CONUS` grid (RRFS_CONUS_25km), the :term:`GFS` v16 physics suite (FV3_GFS_v16 :term:`CCPP`), and :term:`FV3`-based GFS raw external model data for initialization.

   #. Edit the ``MACHINE`` and ``ACCOUNT`` variables in the ``user:`` section of ``config.yaml``. See :numref:`Section %s <user>` for details on valid values. 

      .. note::

         On ``JET``, users must also add ``PARTITION_DEFAULT: xjet`` and ``PARTITION_FCST: xjet`` to the ``platform:`` section of the ``config.yaml`` file. 
   
   #. To automate the workflow, add these two lines to the ``workflow:`` section of ``config.yaml``: 

      .. code-block:: console

         USE_CRON_TO_RELAUNCH: TRUE
         CRON_RELAUNCH_INTVL_MNTS: 3

      There are instructions for running the experiment via additional methods in :numref:`Section %s <Run>`. However, this technique (automation via :term:`crontab`) is the simplest option. 

      .. note::
         On Orion, *cron* is only available on the orion-login-1 node, so users will need to work on that node when running *cron* jobs on Orion.

   #. Edit the ``task_get_extrn_ics:`` section of the ``config.yaml`` to include the correct data paths to the initial conditions files. For example, on Hera, add: 

      .. code-block:: console

         USE_USER_STAGED_EXTRN_FILES: true
         EXTRN_MDL_SOURCE_BASEDIR_ICS: /scratch1/NCEPDEV/nems/role.epic/UFS_SRW_data/develop/input_model_data/FV3GFS/grib2/${yyyymmddhh}

      On other systems, users will need to change the path for ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS`` (below) to reflect the location of the system's data. The location of the machine's global data can be viewed :ref:`here <Data>` for Level 1 systems. Alternatively, the user can add the path to their local data if they downloaded it as described in :numref:`Section %s <InitialConditions>`. 

   #. Edit the ``task_get_extrn_lbcs:`` section of the ``config.yaml`` to include the correct data paths to the lateral boundary conditions files. For example, on Hera, add: 

      .. code-block:: console

         USE_USER_STAGED_EXTRN_FILES: true
         EXTRN_MDL_SOURCE_BASEDIR_LBCS: /scratch1/NCEPDEV/nems/role.epic/UFS_SRW_data/develop/input_model_data/FV3GFS/grib2/${yyyymmddhh}


.. _GenerateWorkflowC: 

Generate the Workflow
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. attention::

   This section assumes that Rocoto is installed on the user's machine. If it is not, the user may need to allocate a compute node (described in the :ref:`Appendix <allocate-compute-node>`) and run the workflow using standalone scripts as described in :numref:`Section %s <RunUsingStandaloneScripts>`. 


Generate workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

This workflow generation script creates an experiment directory and populates it with all the data needed to run 
through the workflow. The generated workflow will be in the experiment directory specified in the ``config.yaml`` file in :numref:`Step %s <SetUpConfigFileC>`. The default location is ``expt_dirs/test_community``. To view experiment progress, users can ``cd`` to the experiment directory from ``ufs-srweather-app/ush`` and run the ``rocotostat`` command to check the experiment's status:

.. code-block:: console

   cd ../../expt_dirs/test_community

Monitor progress:

.. code-block:: console

   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Users can track the experiment's progress by reissuing the ``rocotostat`` command above every so often until the experiment runs to completion. The following message usually means that the experiment is still getting set up:

.. code-block:: console

   08/04/23 17:34:32 UTC :: FV3LAM_wflow.xml :: ERROR: Can not open FV3LAM_wflow.db read-only because it does not exist

After a few (3-5) minutes, ``rocotostat`` should show a status-monitoring table:

.. code-block:: console

          CYCLE             TASK      JOBID    STATE   EXIT STATUS   TRIES   DURATION
   ==================================================================================
   201906151800        make_grid   53583094   QUEUED             -       0        0.0
   201906151800        make_orog          -        -             -       -          -
   201906151800   make_sfc_climo          -        -             -       -          -
   201906151800    get_extrn_ics   53583095   QUEUED             -       0        0.0
   201906151800   get_extrn_lbcs   53583096   QUEUED             -       0        0.0
   201906151800         make_ics          -        -             -       -          -
   201906151800        make_lbcs          -        -             -       -          -
   201906151800         run_fcst          -        -             -       -          -
   201906151800    run_post_f000          -        -             -       -          -
   ...
   201906151800    run_post_f012          -        -             -       -          -

When all tasks show ``SUCCEEDED``, the experiment has completed successfully. 

For users who do not have Rocoto installed, see :numref:`Section %s <RunUsingStandaloneScripts>` for guidance on how to run the workflow without Rocoto. 

----------------------------------------
GNU-Based Container Workflow
----------------------------------------

The GNU-based workflow uses a fully open-source toolchain (GCC + OpenMPI). This
workflow is recommended for environments where open-source compilers are
preferred or where Intel toolchains are not available.


Build the GNU Container from Docker Hub
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Load Singularity or Apptainer module if needed:

.. code-block:: console

   module load singularity

Build a Singularity/Apptainer container image from the DockerHub image:

.. code-block:: console

   singularity build rocky9-ss192-gcc13.sif \
        docker://noaaepic/rocky9-gcc13.3.1-spack-stack:v1.9.2-ufs-wm-srw

The file *rocky9-ss192-gcc13.sif* built is in Singularity Image Format (*.sif*).

Set the environment variable for convenience and later use:

.. code-block:: console

   export IMG=${PWD}/rocky9-ss192-gcc13.sif

Download the UFS SRW App and Submodules
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Clone the UFS SRW App develop branch from the GitHub repository as is done when  :ref:`Building the SRW App <BuildSRW>`.

.. code-block:: console

   git clone -b develop \
       https://github.com/ufs-srweather-app.git/ufs-srweather-app.git ufs-srweather-app
   cd ufs-srweather-app
   ./manage_externals/checkout_externals

Save the environoment variable SRW for later use:

.. code-block:: console

   export SRW=${PWD}


Enter the GNU Container with Platform-Specific Bindings 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Shell into the existing Singularity container image in order to build the SRW App interactively. 
Python/conda environment and UFS SRW App binaries will then be built while running inside the container. 
Some platforms
may require additional user host system directories to be specified with ``-B`` option (bind) 
to make them available inside the container. This could be required, for example, 
for **conda**-related configurations to be stored in a user home directory that resides on a different 
file system from the current directory. Below are given examples on how to shell into the 
container on some Level 1 Platforms.
NOAA RDHPCs:

* NOAA AWS/Azure:

  .. code-block:: console

     singularity shell -B /contrib -e $IMG

* Hercules / Orion:

  .. code-block:: console

     singularity shell -B /work -B /local -e $IMG

* Ursa:

  .. code-block:: console

     singularity shell -B /scratch3 -e $IMG

* Gaea:

  .. code-block:: console

     singularity shell -B /gpfs -B /ncrc/home2 -e $IMG


Build SRW Executables and Conda Environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Inside the container, set environmental variables that help to generate consistent build and 
run-time environment:

Specify location of the Singularity image:

.. code-block:: console

   export IMG=/full/path/to/rocky9-ss192-gcc13.sif

Optional platform-specific paths that require to be accessible by the container at runtime:

.. code-block:: console

   export BIND_ADD=/local   # Orion/Hercules, needed during run-time for interaction with Slurm job scheduler
   export BIND_ADD=/var     # Gaea-C6

Build executables using devbuild.sh script, in a similar way as described in  :ref:`Building Executables <BuildExecutables>`, 
except placing binaries into the ``bin`` directory. 
This is the essential difference, as the default ``exec`` directory where the SRW App expects to find binaries 
will be set up to contain wrappers for the actual binaries.

.. code-block:: console

   ./devbuild.sh --bin-dir=bin --platform=singularity --compiler=gnu \
        | tee log.devbuild.sh_001

When all the conda environments and binaries are successfully built, exit from the container:

.. code-block:: console

   exit


Use Wrapper Scripts and Runtime Environment Files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In addition to binaries and conda installs, successful build produces:

* ``srw.sh`` — wrapper to launch tasks within the container
* ``ufs-srw.env`` — runtime environment settings and environment variables

Verify the following configuration in the ``srw.sh``:

* ``img`` variable points to the correct ``.sif`` GNU container image file, absolute path
* ``-B`` binds all host directories, required for access inside the container at runtime, including staged data locations


Link Executables to Wrapper Scripts
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The following code below is run interactively to create links to executables in ``exec`` directory to a wrapper script. 
Make sure the $SRW variable is properly set, as done after downloading the UFS SRW App repository and dependencies. 

.. code-block:: console

   cd $SRW
   export wrapper_script=${SRW}/srw.sh

   mkdir -p exec
   cd bin

   for file in *; do
       echo $file
       if [[ "$file" != "build_settings.yaml" ]]; then
           ln -s $wrapper_script ../exec/$file
       else
           cp -pv $file ../exec/.
       fi
   done


Add Loading Host Modules to the Workflow Modulefile 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Host-system GNU module and corresponding MPI module need to be used and 
loaded to interact with GNU-built libraries and SRW App binaries. Users neeed to determine 
their availability on a host system, and add these modules to ``modulefiles/wflow_singularity.yaml``
modulefile. If Singularity/Apptainer software requires a module to be loaded, it needs to be added as well.
Loading the rocoto module could be added, if crontab option to launch job tasks is enabled.
The examples below show added modules for running the test on selected Tier 1 platforms.

For Orion and Hercules the loaded modules is as follows:

.. code-block:: console

   load("gcc/12.2.0")
   load("openmpi/4.1.4")
   load("singularity")
   load("contrib")
   load("rocoto/1.3.7")


For AWS, Azure:

.. code-block:: console

   load("gnu/13.2.0")
   load("openmpi/4.1.6")
   load("rocoto/1.3.7")

For Ursa:

.. code-block:: console

   load("gcc/12.4.0")
   load("openmpi/4.1.6")
   load("rocoto")

For Gaea:

.. code-block:: console
   
   load("gcc-native/13.2")
   prepend_path("MODULEPATH","/ncrc/proj/epic/rocoto/modulefiles")
   load("rocoto")

Prepare Configuration Files 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. A machine configuration file ``singularity.yaml`` needs to be configured in ``$SRW/ush/machine`` directory. 
It contains variables to set the system job sheduler, node count information, queue and patition names for use
with batch job scheduler, locations of fix climatology files and model data input files, as well
as workflow manager configuration.

Depending on host system job scheduler and GNU and MPI modules that were added to ``wflow_singularity.yaml``
in the previous step, MPI jobs on user system are expected to be launched with either **mpirun** or **srun**.
Edit the following variables to specify the MPI jobs launch command that fits your system: 
``RUN_CMD_FCST``, ``RUN_CMD_POST``, ``RUN_CMD_UTILS``, ``RUN_CMD_PRDGEN``.
The default launch command is set to **mpirun**; set it to **srun --mpi=pmi2** when using Slurm to 
interact with container-installed MPI plugins for Slurm (PMI or PMI2). 
For example, if the default variable is set:

.. code-block:: console

 RUN_CMD_FCST: mpirun -n ${nprocs}

change it to the following to use Slurm-based MPI job launch:

.. code-block:: console

 RUN_CMD_FCST: srun --mpi=pmi2 -n ${nprocs}

.. note::
   
   The Tier 1 Platform that were tested and require use of ``srun --mpi=pmi2`` are **Gaea-C6**, 
   **Hercules**, **Orion**. The Tier 1 systems **Ursa**, **NOAA-AWS** and **NOAA-Azure** allow the 
   MPI job launch using both ``srun`` and  ``mpirun``.

Additional edits the ``singularity.yaml`` to configure for your system include:

* ``WORKFLOW_MANAGER`` - workflow manager; rocoto (default), ``rocoto:`` section for job tasks
* ``NCORES_PER_NODE`` - number of cores available per node on the platform
* ``SCHED`` - job scheduler; slurm (default)
* ``FIX*`` - paths to staged fix climatogy datasets
* ``data:`` section: staged external model input files
* ``RUN_CMD_*`` variables, including MPI launch commands


2. Configuration file for the community test case, ``config.yaml`` is expected to be located in 
``ush`` directory. Use a singularity GNU template for the community test case:

.. code-block:: console

   cp ${SRW}/ush/config.singularity.yaml ${SRW}/ush/config.yaml

Edit the ``config.yaml`` to configure following:

* ``ACCOUNT`` - account for running jobs on your compute platform (if required)
* ``EXPT_SUBDIR`` - experiment directory; a default is ``test_community``
* ``USE_CRON_TO_RELAUNCH`` - set to **false** (default); may set to **true** if system allow use of cron/crontab to launch job tasks

 
Generate Workflow
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Load the modulefile **wflow_singularity** containing host system compiler and MPI modules, which starts
the conda environment (srw_app) for running the workflow:

.. code-block:: console

   module use $SRW/modulefiles
   module load wflow_singularity

Generate the workflow:

.. code-block:: console

   cd $SRW/ush
   ./generate_FV3LAM_wflow.py

When generated successully, the ``EXPTDIR`` path for the experiment will be displayed. 
Record it into the corresponding environmental variable, e.g.:

.. code-block:: console
   
   export EXPTDIR='/full/path/to/your/expt_dirs/test_community'

----------------------------------------
Run the SRW Test Case
----------------------------------------

When rocoto workflow manager is available, cd to the experiment directory, and issue the ``rocotorun`` command to advance the workflow.

.. code-block:: console

   cd $EXPTDIR
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Users must reissue ``rocotorun`` periodically unless workflow automation is configured.
Monitor the progress:

.. code-block:: console

   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

When all tasks show STATUS as ``SUCCEEDED``, the experiment has completed successfully. 

.. note::

   Rocoto workflow manager interacts with a job scheduler, e.g., Slurm, and relies on the recent information 
   about the job provided by the job scheduler. To get the updated information of the job status, it is always 
   required to run the ``rocotorun ...`` command before issuing the ``rocotostat ...``.

For users who do not have Rocoto installed, see :numref:`Section %s <RunUsingStandaloneScripts>` for guidance on how to run the workflow without Rocoto. 

----------------------------------------
Troubleshooting
----------------------------------------

If a workflow task becomes ``DEAD``:

If a task goes DEAD, it will be necessary to restart it according to the instructions in :numref:`Section %s <RestartTask>`. To determine what caused the task to go DEAD, users should view the log file for the task in ``$EXPTDIR/log/<task_log>``, where ``<task_log>`` refers to the name of the task's log file. After fixing the problem and clearing the DEAD task, it is sometimes necessary to reinitialize the crontab. Run ``crontab -e`` to open your configured editor. Inside the editor, copy-paste the crontab command from the bottom of the ``$EXPTDIR/log.generate_FV3LAM_wflow`` file into the crontab:

.. code-block:: console

   crontab -e
   */3 * * * * cd /path/to/expt_dirs/test_community && ./launch_FV3LAM_wflow.sh called_from_cron="TRUE"

where ``/path/to`` is replaced by the actual path to the user's experiment directory.


Example cron entry:

.. code-block:: console

   */3 * * * * cd /path/to/expt_dirs/test_community && \
       ./launch_FV3LAM_wflow.sh called_from_cron="TRUE"


.. _appendix:

----------------------------------------
Appendix
----------------------------------------

.. _work-on-hpc-details:

Working on the Cloud or HPC Systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   
Building a singularity container image/sandbox relies on user's temporary space (TMP); 
these requirements are much higher for 
Intel-based container. Users working on systems with limited disk space in their ``/home`` directory may set 
the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. 
If the cache and tmp directories do not exist already, they must be created with a ``mkdir`` command preceeding the export of the variables.

.. code-block:: console

   mkdir /absolute/path/to/writable/directory/cache
   mkdir /absolute/path/to/writable/directory/tmp

where /absolute/path/to/writable/directory/ refers to the absolute path to a writable directory with sufficient disk space.
Proceed with exportig the variables:

.. code-block:: console

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

.. _allocate-compute-node:

Allocating a Compute Node 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
For interactive compiling/build or runing jobs, job allocation request is placed as following:

On **Slurm** systems:

.. code-block:: console

   salloc -N 1 -n <cores> -A <account> -t <time> \
          -q <qos> --partition=<partition>

On **PBS** systems:

.. code-block:: console

   qsub -I -lwalltime=<time> -A <account> \
        -q <destination> -lselect=1:ncpus=36:mpiprocs=36

After allocation:

.. code-block:: console

   ssh <hostname>

Larger experiments may require multiple compute nodes.
