.. _QuickstartC:

====================================
Container-Based Quick Start Guide
====================================

This Container-Based Quick Start Guide will help users build and run the "out-of-the-box" case for the Unified Forecast System (:term:`UFS`) Short-Range Weather (SRW) Application using a `Singularity/Apptainer <https://apptainer.org/docs/user/1.2/introduction.html>`__ container. The :term:`container` approach provides a uniform enviroment in which to build and run the SRW App. Normally, the details of building and running the SRW App vary from system to system due to the many possible combinations of operating systems, compilers, :term:`MPIs <MPI>`, and package versions available. Installation via container reduces this variability and allows for a smoother SRW App build experience. 

The basic "out-of-the-box" case described in this User's Guide builds a weather forecast for June 15-16, 2019. Multiple convective weather events during these two days produced over 200 filtered storm reports. Severe weather was clustered in two areas: the Upper Midwest through the Ohio Valley and the Southern Great Plains. This forecast uses a predefined 25-km Continental United States (:term:`CONUS`) grid (RRFS_CONUS_25km), the Global Forecast System (:term:`GFS`) version 16 physics suite (FV3_GFS_v16 :term:`CCPP`), and :term:`FV3`-based GFS raw external model data for initialization.

.. attention::

   * The SRW Application has :srw-wiki:`four levels of support <Supported-Platforms-and-Compilers>`. The steps described in this chapter will work most smoothly on preconfigured (Level 1) systems. However, this guide can serve as a starting point for running the SRW App on other systems, too. 
   * This chapter of the User's Guide should **only** be used for container builds. For non-container builds, see :numref:`Section %s <NCQuickstart>` for a Quick Start Guide or :numref:`Section %s <BuildSRW>` for a detailed guide to building the SRW App **without** a container. 

.. _DownloadCodeC:

Download the Container
==========================

Prerequisites 
-------------------

**Intel Compiler and MPI**

Users must have an **Intel** compiler and :term:`MPI` (`available for free here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__) in order to run the SRW App in the container provided using the method described in this chapter. Additionally, it is recommended that users install the `Rocoto workflow manager <https://github.com/christopherwharrop/rocoto>`__ on their system in order to take advantage of automated workflow options. Although it is possible to run an experiment without Rocoto, and some tips are provided, the only fully-supported and tested container option assumes that Rocoto is preinstalled. 

**Install Singularity/Apptainer**

To build and run the SRW App using a Singularity/Apptainer container, first install the software according to the `Apptainer Installation Guide <https://apptainer.org/docs/admin/1.2/installation.html>`__. This will include the installation of all dependencies. 

.. note::

   As of November 2021, the Linux-supported version of Singularity has been `renamed <https://apptainer.org/news/community-announcement-20211130/>`__ to *Apptainer*. Apptainer has maintained compatibility with Singularity, so ``singularity`` commands should work with either Singularity or Apptainer (see compatibility details `here <https://apptainer.org/docs/user/1.2/singularity_compatibility.html>`__.)

.. attention:: 
   Docker containers can only be run with root privileges, and users cannot have root privileges on :term:`HPCs <HPC>`. Therefore, it is not possible to build the SRW App, which uses the spack-stack, inside a Docker container on an HPC system. However, a Singularity/Apptainer image may be built directly from a Docker image for use on the system.

.. _work-on-hpc:

Working in the Cloud or on HPC Systems
-----------------------------------------

Users working on systems with limited disk space in their ``/home`` directory may need to set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. For example:

.. code-block:: 

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

where ``/absolute/path/to/writable/directory/`` refers to the absolute path to a writable directory with sufficient disk space. If the ``cache`` and ``tmp`` directories do not exist already, they must be created with a ``mkdir`` command. See :numref:`Section %s <work-on-hpc-details>` to view an example of how this can be done. 

.. _BuildC:

Build the Container
------------------------

* :ref:`On Level 1 Systems <container-L1>` (see :srw-wiki:`list <Supported-Platforms-and-Compilers>`)
* :ref:`On Level 2-4 Systems <container-L2-4>`

.. hint::
   If a ``singularity: command not found`` error message appears when working on Level 1 platforms, try running: ``module load singularity`` or (on Derecho) ``module load apptainer``.

.. _container-L1:

Level 1 Systems
^^^^^^^^^^^^^^^^^^

On most Level 1 systems, a container named ``ubuntu20.04-intel-ue-1.4.1-srw-dev.img`` has already been built at the following locations:

.. list-table:: Locations of pre-built containers
   :widths: 20 50
   :header-rows: 1

   * - Machine
     - File Location
   * - Derecho [#fn]_
     - /glade/work/epicufsrt/contrib/containers
   * - Gaea [#fn]_
     - /lustre/f2/dev/role.epic/containers
   * - Hera
     - /scratch1/NCEPDEV/nems/role.epic/containers
   * - Jet
     - /mnt/lfs4/HFIP/hfv3gfs/role.epic/containers
   * - NOAA Cloud
     - /contrib/EPIC/containers
   * - Orion/Hercules [#fn]_
     - /work/noaa/epic/role-epic/contrib/containers

.. [#fn] On these systems, container testing shows inconsistent results. 

.. note::
   * On Gaea, Singularity/Apptainer is only available on the C5 partition, and therefore container use is only supported on Gaea C5. 
   * The NOAA Cloud containers are accessible only to those with EPIC resources. 

Users can simply set an environment variable to point to the container: 

.. code-block:: console

   export img=/path/to/ubuntu20.04-intel-ue-1.4.1-srw-dev.img

Users may convert the container ``.img`` file to a writable sandbox:

.. code-block:: console

   singularity build --sandbox ubuntu20.04-intel-srwapp $img

When making a writable sandbox on Level 1 systems, the following warnings commonly appear and can be ignored:

.. code-block:: console

   INFO:    Starting build...
   INFO:    Verifying bootstrap image ubuntu20.04-intel-ue-1.4.1-srw-dev.img
   WARNING: integrity: signature not found for object group 1
   WARNING: Bootstrap image could not be verified, but build will continue.

.. _container-L2-4:

Level 2-4 Systems
^^^^^^^^^^^^^^^^^^^^^

On non-Level 1 systems, users should build the container in a writable sandbox:

.. code-block:: console

   sudo singularity build --sandbox ubuntu20.04-intel-srwapp docker://noaaepic/ubuntu20.04-intel-srwapp:develop

Some users may prefer to issue the command without the ``sudo`` prefix. Whether ``sudo`` is required is system-dependent. 

.. note::
   Users can choose to build a release version of the container using a similar command:

   .. code-block:: console

      sudo singularity build --sandbox ubuntu20.04-intel-srwapp docker://noaaepic/ubuntu20.04-intel-srwapp:release-public-v2.2.0

For easier reference, users can set an environment variable to point to the container: 

.. code-block:: console

   export img=/path/to/ubuntu20.04-intel-srwapp

.. _RunContainer:

Start Up the Container
----------------------

Copy ``stage-srw.sh`` from the container to the local working directory: 

.. code-block:: console

   singularity exec -B /<local_base_dir>:/<container_dir> $img cp /opt/ufs-srweather-app/container-scripts/stage-srw.sh .

If the command worked properly, ``stage-srw.sh`` should appear in the local directory. The command above also binds the local directory to the container so that data can be shared between them. On :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems, ``<local_base_dir>`` is usually the topmost directory (e.g., ``/lustre``, ``/contrib``, ``/work``, or ``/home``). Additional directories can be bound by adding another ``-B /<local_base_dir>:/<container_dir>`` argument before the name of the container. In general, it is recommended that the local base directory and container directory have the same name. For example, if the host system's top-level directory is ``/user1234``, the user can create a ``user1234`` directory in the writable container sandbox and then bind it:

.. code-block:: console

   mkdir /path/to/container/user1234
   singularity exec -B /user1234:/user1234 $img cp /opt/ufs-srweather-app/container-scripts/stage-srw.sh .

.. attention::
   Be sure to bind the directory that contains the experiment data! 

To explore the container and view available directories, users can either ``cd`` into the container and run ``ls`` (if it was built as a sandbox) or run the following commands:

.. code-block:: console

   singularity shell $img
   cd /
   ls 

The list of directories printed will be similar to this: 

.. code-block:: console

   bin      discover       lfs   lib     media  run         singularity    usr
   boot     environment    lfs1  lib32   mnt    sbin        srv            var
   contrib  etc            lfs2  lib64   opt    scratch     sys            work
   data     glade          lfs3  libx32  proc   scratch1    tmp
   dev      home           lfs4  lustre  root   scratch2    u

Users can run ``exit`` to exit the shell. 

Download and Stage the Data
============================

The SRW App requires input files to run. These include static datasets, initial and boundary condition files, and model configuration files. On Level 1 systems, the data required to run SRW App tests are already available as long as the bind argument (starting with ``-B``) in :numref:`Step %s <RunContainer>` included the directory with the input model data. See :numref:`Table %s <DataLocations>` for Level 1 data locations. For Level 2-4 systems, the data must be added manually by the user. In general, users can download fix file data and experiment data (:term:`ICs/LBCs`) from the `SRW App Data Bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`__ and then untar it:

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/current_srw_release_data/fix_data.tgz
   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/current_srw_release_data/gst_data.tgz
   tar -xzf fix_data.tgz
   tar -xzf gst_data.tgz

More detailed information can be found in :numref:`Section %s <DownloadingStagingInput>`. Sections :numref:`%s <Input>` and :numref:`%s <OutputFiles>` contain useful background information on the input and output files used in the SRW App.

.. _GenerateForecastC:

Generate the Forecast Experiment 
=================================
To generate the forecast experiment, users must:

#. :ref:`Activate the workflow <SetUpPythonEnvC>`
#. :ref:`Set experiment parameters to configure the workflow <SetUpConfigFileC>`
#. :ref:`Run a script to generate the experiment workflow <GenerateWorkflowC>`

The first two steps depend on the platform being used and are described here for Level 1 platforms. Users will need to adjust the instructions to match their machine configuration if their local machine is a Level 2-4 platform. 

.. _SetUpPythonEnvC:

Activate the Workflow
------------------------

Copy the container's modulefiles to the local working directory so that the files can be accessed outside of the container:

.. code-block:: console

   singularity exec -B /<local_base_dir>:/<container_dir> $img cp -r /opt/ufs-srweather-app/modulefiles .

After this command runs, the local working directory should contain the ``modulefiles`` directory. 

To activate the workflow, run the following commands: 

.. code-block:: console

   module use /path/to/modulefiles
   module load wflow_<platform>

where: 

   * ``/path/to/modulefiles`` is replaced with the actual path to the modulefiles on the user's local system (often ``$PWD/modulefiles``), and 
   * ``<platform>`` is a valid, lowercased machine/platform name (see the ``MACHINE`` variable in :numref:`Section %s <user>`). 

The ``wflow_<platform>`` modulefile will then output instructions to activate the workflow. The user should run the commands specified in the modulefile output. For example, if the output says: 

.. code-block:: console

   Please do the following to activate conda:
       > conda activate workflow_tools

then the user should run |activate|. This will activate the |wflow_env| conda environment. The command(s) will vary from system to system, but the user should see |prompt| in front of the Terminal prompt at this point.

.. _SetUpConfigFileC: 

Configure the Workflow
---------------------------

Run ``stage-srw.sh``:

.. code-block:: console

   ./stage-srw.sh -c=<compiler> -m=<mpi_implementation> -p=<platform> -i=$img

where: 

   * ``-c`` indicates the compiler on the user's local machine (e.g., ``intel/2022.1.2``)
   * ``-m`` indicates the :term:`MPI` on the user's local machine (e.g., ``impi/2022.1.2``)
   * ``<platform>`` refers to the local machine (e.g., ``hera``, ``jet``, ``noaacloud``, ``macos``, ``linux``). See ``MACHINE`` in :numref:`Section %s <user>` for a full list of options.
   * ``-i`` indicates the container image that was built in :numref:`Step %s <BuildC>` (``ubuntu20.04-intel-srwapp`` or ``ubuntu20.04-intel-ue-1.4.1-srw-dev.img`` by default).

For example, on Hera, the command would be:

.. code-block:: console

   ./stage-srw.sh -c=intel/2022.1.2 -m=impi/2022.1.2 -p=hera -i=ubuntu20.04-intel-ue-1.4.1-srw-dev.img

.. attention::

   The user must have an Intel compiler and MPI on their system because the container uses an Intel compiler and MPI. Intel compilers are now available for free as part of the `Intel oneAPI Toolkit <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__.

After this command runs, the working directory should contain ``srw.sh``, a ``ufs-srweather-app`` directory, and an ``ush`` directory.

.. COMMENT: Check that the above is true for the dev containers...

From here, users can follow the steps below to configure the out-of-the-box SRW App case with an automated Rocoto workflow. For more detailed instructions on experiment configuration, users can refer to :numref:`Section %s <UserSpecificConfig>`. 

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
-----------------------------

.. attention::

   This section assumes that Rocoto is installed on the user's machine. If it is not, the user will need to allocate a compute node (described in the :ref:`Appendix <allocate-compute-node>`) and run the workflow using standalone scripts as described in :numref:`Section %s <RunUsingStandaloneScripts>`. 

Run the following command to generate the workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

This workflow generation script creates an experiment directory and populates it with all the data needed to run through the workflow. The last line of output from this script should start with ``*/3 * * * *`` (or similar). 

The generated workflow will be in the experiment directory specified in the ``config.yaml`` file in :numref:`Step %s <SetUpConfigFileC>`. The default location is ``expt_dirs/test_community``. To view experiment progress, users can ``cd`` to the experiment directory from ``ufs-srweather-app/ush`` and run the ``rocotostat`` command to check the experiment's status:

.. code-block:: console

   cd ../../expt_dirs/test_community
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

Troubleshooting
------------------

If a task goes DEAD, it will be necessary to restart it according to the instructions in :numref:`Section %s <RestartTask>`. To determine what caused the task to go DEAD, users should view the log file for the task in ``$EXPTDIR/log/<task_log>``, where ``<task_log>`` refers to the name of the task's log file. After fixing the problem and clearing the DEAD task, it is sometimes necessary to reinitialize the crontab. Run ``crontab -e`` to open your configured editor. Inside the editor, copy-paste the crontab command from the bottom of the ``$EXPTDIR/log.generate_FV3LAM_wflow`` file into the crontab:

.. code-block:: console

   crontab -e
   */3 * * * * cd /path/to/expt_dirs/test_community && ./launch_FV3LAM_wflow.sh called_from_cron="TRUE"

where ``/path/to`` is replaced by the actual path to the user's experiment directory.

New Experiment
===============

To run a new experiment in the container at a later time, users will need to rerun the commands in :numref:`Section %s <SetUpPythonEnvC>` to reactivate the workflow. Then, users can configure a new experiment by updating the experiment variables in ``config.yaml`` to reflect the desired experiment configuration. Basic instructions appear in :numref:`Section %s <SetUpConfigFileC>` above, and detailed instructions can be viewed in :numref:`Section %s <UserSpecificConfig>`. After adjusting the configuration file, regenerate the experiment by running ``./generate_FV3LAM_wflow.py``.

.. _appendix:

Appendix
==========

.. _work-on-hpc-details:

Sample Commands for Working in the Cloud or on HPC Systems
-----------------------------------------------------------

Users working on systems with limited disk space in their ``/home`` directory may set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. On NOAA Cloud systems, the ``sudo su``/``exit`` commands may also be required; users on other systems may be able to omit these. For example:
   
.. code-block:: 

   mkdir /lustre/cache
   mkdir /lustre/tmp
   sudo su
   export SINGULARITY_CACHEDIR=/lustre/cache
   export SINGULARITY_TMPDIR=/lustre/tmp
   exit

.. note:: 
   ``/lustre`` is a fast but non-persistent file system used on NOAA Cloud systems. To retain work completed in this directory, `tar the files <https://www.howtogeek.com/248780/how-to-compress-and-extract-files-using-the-tar-command-on-linux/>`__ and move them to the ``/contrib`` directory, which is much slower but persistent.

.. _allocate-compute-node:

Allocate a Compute Node
--------------------------

Users working on HPC systems that do **not** have Rocoto installed must `install Rocoto <https://github.com/christopherwharrop/rocoto/blob/develop/INSTALL>`__ or allocate a compute node. All other users may :ref:`continue to start up the container <RunContainer>`. 

.. note::
   
   All NOAA Level 1 systems have Rocoto pre-installed. 

The appropriate commands for allocating a compute node will vary based on the user's system and resource manager (e.g., Slurm, PBS). If the user's system has the Slurm resource manager, the allocation command will follow this pattern:

.. code-block:: console

   salloc -N 1 -n <cores-per-node> -A <account> -t <time> -q <queue/qos> --partition=<system> [-M <cluster>]

For more information on the ``salloc`` command options, see Slurm's `documentation <https://slurm.schedmd.com/salloc.html>`__.

If users have the PBS resource manager installed on their system, the allocation command will follow this pattern:

.. code-block:: console

   qsub -I -lwalltime=<time> -A <account> -q <destination> -lselect=1:ncpus=36:mpiprocs=36

For more information on the ``qsub`` command options, see the `PBS Manual §2.59.3 <https://2021.help.altair.com/2021.1/PBSProfessional/PBS2021.1.pdf>`__, (p. 1416).

These commands should output a hostname. Users can then run ``ssh <hostname>``. After "ssh-ing" to the compute node, they can run the container from that node. To run larger experiments, it may be necessary to allocate multiple compute nodes. 