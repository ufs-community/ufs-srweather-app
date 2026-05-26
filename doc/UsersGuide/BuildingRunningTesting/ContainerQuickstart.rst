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

This section distinguishes the following container workflows:

* **Intel-based pre-built SRW runtime container workflow:** 
  this workflow uses a container that includes a pre-built SRW App v3.0
  executable and its runtime environment. The pre-built application is staged
  from the container and then used to run the community test case.

* **Containerized software-stack workflow for building and running the SRW App:** 
  this workflow uses a container that provides the software stack needed to
  build and run the UFS SRW App from source. The first step depends on the
  container option being used. Users may use a staged GNU-based or Intel-based
  software-stack container available on Tier 1 NOAA RDHPC platforms, or they may
  build a GNU-based or Intel-capable Singularity/Apptainer image from Docker
  Hub on non-supported systems. After the container is available, the
  remaining steps are the same for all of these options: clone the SRW App
  source code, build the application using the containerized software stack, and
  run the community test case.
  
.. note:: **Compilers and MPI in the containers**

   * **Intel-based pre-staged containers** on Tier 1 NOAA RDHPC platforms
     include Intel oneAPI compilers and MPI. Similar Intel software 
     components are available on the host systems. Use the containerized 
     compilers and MPI to build the SRW App when using the software-stack workflow.

   * **GNU-based containers**, whether staged locally or built from Docker Hub,
     include the open-source GNU Compiler Open MPI. These containers can be used
     to build the SRW App from source after cloning the application repository.

   * **Intel-capable Docker Hub workflows** require additional steps. The final
     Docker Hub image does not include Intel oneAPI software because those
     components were removed to comply with Intel's End User License Agreement
     (EULA). A workaround is provided to reinstall the Intel oneAPI compilers
     and Intel MPI into a writable sandbox container, then assemble or convert
     the sandbox into a final container image with all required dependencies in
     place.

   (more details in :ref:`Compiler and MPI Requirements <CompilerMPIReqC>`)
   

This guide covers two container-based approaches for using the SRW App. 

In the Intel-based pre-built runtime workflow, the container already provides
the SRW App v3.0 executable and runtime environment. Users stage the container
and run the provided out-of-the-box community test case without building the SRW
App from source
(:ref:`Intel-Based Container Workflow with a Pre-build SRW App
<DownloadContainerIntelC>`).

In the software-stack workflow, the container provides the compiler, MPI library,
and pre-built spack-stack libraries required to build the SRW App. Users clone
the SRW App source code, build the application inside the container, and run the
generated workflow from the host system
(:ref:`Containerized Software-Stack Workflow for Building from Source
<ContainerSoftwareStackWorkflowC>`).

This guide demonstrates how to:

* Build or obtain a Singularity/Apptainer images that contains the required
  software stack;
* Stage the Intel-based pre-built SRW App container on a host system, or:
* Build the UFS SRW Application from source inside the container;
* Run the provided out-of-the-box community test case.

Both workflows rely on `Singularity/Apptainer
<https://apptainer.org/docs/user/1.2/introduction.html>`_ 
to transform a Docker Hub-based container into a Singularity/Apptainer 
image or a writable container sandbox. The SRW Application is executed only through
this Singularity/Apptainer image or sandbox suitable for HPC systems or shared compute
environments where users do not have root privileges, required for running Docker
(another popular container solution).

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

.. _PrerequsitesC:

-------------------
Prerequisites 
-------------------

The following prerequisites apply to **all** container workflows.

.. _ContainerSoftrareInstallC:

Singularity/Apptainer Installation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Users must have **Singularity** or **Apptainer** installed on their compute platform. 

On many HPC systems, Singularity/Apptainer may be available as a loadable
module:

.. code-block:: console

   module load singularity
   # or
   module load apptainer

When not available system-wide, Apptainer could be installed on Linux-based
system following `Apptainer Installation Guide
<https://apptainer.org/docs/admin/latest/installation.html>`__. 
This will include the installation of all dependencies. 

Further information on Singularity/Apptainer is available at:

- Singularity/Apptainer container solution for HPC systems:
  `https://en.wikipedia.org/wiki/Apptainer#History
  <https://en.wikipedia.org/wiki/Apptainer#History>`_

- SingularityCE:
  `https://sylabs.io/singularity/ <https://sylabs.io/singularity/>`_
- SingularityCE Documentation:
  `https://https://sylabs.io/docs/ <https://sylabs.io/docs/>`_
  `https://docs.sylabs.io/guides/latest/user-guide/ <https://docs.sylabs.io/guides/latest/user-guide/>`_

- Apptainer:
  `https://apptainer.org/ <https://apptainer.org/>`_
- Apptainer Documentation:
  `https://apptainer.org/docs/ <https://apptainer.org/docs/>`_
  `https://apptainer.org/docs/user/latest/ <https://apptainer.org/docs/user/latest/>`_

- NOAA RDHPCs Documentation:
  `https://docs.rdhpcs.noaa.gov/software/containers
  <https://docs.rdhpcs.noaa.gov/software/containers>`_

Apptainer is fully compatible with Singularity, and commands shown here using ``singularity``
may be replaced with ``apptainer`` as appropriate.

.. note::

   In this chapter, ``<container-command>`` means either ``singularity`` or
   ``apptainer``, depending on the software available on the target platform.
   When using Apptainer, prefer the ``APPTAINER_`` environment-variable prefix
   instead of the legacy ``SINGULARITY_`` prefix. Compatibility with
   ``SINGULARITY_`` variables may vary by Apptainer version, site installation,
   and local configuration.

Some platforms provide Singularity/Apptainer by default. Others require a module
load before building or running the container.

.. list-table:: Container software used on NOAA RDHPC Tier 1 platforms
   :widths: 25 25 30
   :header-rows: 1

   * - Machine
     - Container command
     - Module to load
   * - Ursa
     - ``apptainer``
     - none required
   * - Gaea
     - ``apptainer``
     - none required
   * - Hercules/Orion
     - ``singularity``
     - ``module load singularity``
   * - Derecho
     - ``apptainer``
     - ``module load apptainer``
   * - NOAA Cloud AWS/Azure
     - ``singularity``
     - none required
  
.. _CompilerMPIReqC:

Compiler and MPI Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Although containers may provide a complete SRW software stack or the software
libraries needed to build the SRW App, runtime execution still depends on
compatible MPI support on the host system. In the Tier 1 platform
examples,  Slurm launches MPI tasks the host system. The
host-side MPI startup then communicates with the binary-compatible MPI library
inside the container: Intel MPI for Intel-based containers, or OpenMPI built
with PMI2 support for GNU-based containers. On unsupported systems,
or when MPI jobs are launched with ``mpirun`` or ``mpiexec`` instead of
``srun``, users may need to adapt the workflow and load host compilers and 
corresponding MPI libraries that are binary-compatible with the containerized
versions. 

* The **Intel-based container** requires Intel compilers and Intel MPI through
  the Intel OneAPI toolkit.
    
    * Intel-based image with a pre-built SRW App: includes Intel oneAPI
      2023.2.1, with the C/C++/Fortran 2021.10.0 compilers and Intel MPI
      2021.9.0.

    * Intel-based software-stack image pre-staged on supported Tier 1
      platforms: includes Intel oneAPI 2024.2.1, with C/C++ 2024.2.1,
      Fortran 2021.13.1, and Intel MPI 2021.13.
      
    * Intel-capable container image: provides software libraries built with
      Intel oneAPI 2024.2.1, similar to the pre-staged Intel-based software-stack
      image. Because this image does not include the full Intel compiler and MPI
      installation, users must reinstall the matching Intel oneAPI components in a
      writable sandbox before building a final fully capable container image.
        
* The **GNU-based container** may require compatible GNU compilers and MPI
   support on the host system. GCC 12 or newer is recommended. The container
   image includes GNU Compiler Collection 13.3.1 and OpenMPI 4.1.6, configured
   with PMI2 support from Slurm 24.05.4-1, and should be used with a
   binary-compatible host MPI library or MPI startup mechanism, such as host
   OpenMPI or a Slurm-based PMI/PMIx plugin. 

Users must choose a container image consistent with the host environment's compiler and
MPI availability.

.. note::

   Building a singularity/apptainer container image or sandbox relies on user's
   temporary space (TMP); these requirements are much higher for Intel-based
   containers. The example is given in :ref:`Appendix` on setting up TMP spaces
   for container software to avoid exceeding default TMP space quotas.

.. _DownloadStageDataC:

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
   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/experiment-user-cases/release-public-v3.0.0/out-of-the-box/gst_data.tgz

   tar -xzf fix_data.tgz
   tar -xzf gst_data.tgz

For more information about data organization, see :numref:`Section %s <DownloadingStagingInput>`. Sections :numref:`%s <Input>` and :numref:`%s <OutputFiles>` contain useful background information on the input and output files used in the SRW App.

.. _DownloadContainerIntelC:

-------------------------------------------------------
Intel-Based Container Workflow with a Pre-build SRW App
-------------------------------------------------------

The Intel-based workflow uses a pre-built container that includes the SRW App
software stack built with Intel compilers and Intel MPI. This workflow is
recommended for systems where Intel toolchains are standard (e.g., Level 1
platforms).

.. _BuildC:

Obtain or Build the Intel-Based Singularity Container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**On Level 1 systems**, pre-built images exist at system-specific shared paths.

.. |containers-note| replace:: :sup:`(*)`

.. list-table:: Locations of pre-built containers
   :widths: 20 50
   :header-rows: 1

   * - Machine
     - File Location
   * - Derecho |containers-note|
     - /glade/work/epicufsrt/contrib/containers
   * - Gaea-C6 |containers-note|
     - /gpfs/f6/bil-fire8/world-shared/containers
   * - Ursa
     - /scratch3/NCEPDEV/nems/role.epic/containers
   * - NOAA Cloud |containers-note|
     - /contrib/EPIC/containers
   * - Orion/Hercules
     - /work/noaa/epic/role-epic/contrib/containers

|containers-note| On these systems, container testing shows inconsistent results. 

.. note::
   * The NOAA Cloud containers are accessible only to those with EPIC resources. 

It is practical to set an environment variable to point to the container: 

.. code-block:: console

   export img=/path/to/ubuntu22.04-intel-srw-release-public-v3.0.0-rt.img

Users may convert the read-only image in a shared location to a writable sandbox in user's space:

.. code-block:: console

   singularity build --sandbox ubuntu22.04-intel-srw-release-public-v3.0.0-rt $img

Signature warnings may be ignored.

**On Level 2–4 systems**, build a sandbox directly from the Docker Hub repository:

.. code-block:: console

   singularity build --sandbox ubuntu22.04-intel-srw-release-public-v3.0.0-rt \
        docker://noaaepic/ubuntu22.04-intel2023.2.1-srw:ue160-fms202401-release3-rt

Set an environment variable to point to your sandbox container:

.. code-block:: console

   export img=/path/to/ubuntu22.04-intel-srw-release-public-v3.0.0-rt

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
   * ``<platform>`` refers to the local machine (e.g., ``ursa``, ``derecho``, ``noaacloud``). See ``MACHINE`` in :numref:`Section %s <user>` for a full list of options.
   * ``-i`` indicates the full path to the container image that was built in :numref:`Step %s <BuildC>` (``ubuntu22.04-intel-srw-release-public-v3.0.0-rt`` or ``ubuntu22.04-intel-srw-release-public-v3.0.0-rt.img`` by default).

For example, on Ursa, the command would be:

.. code-block:: console

   ./stage-srw.sh -c=intel/2022.1.2 -m=impi/2022.1.2 -p=ursa -i=$img

.. attention::

   The user must have an Intel compiler and MPI on their system because the container uses an Intel compiler and MPI. Intel compilers are now available for free as part of the `Intel oneAPI Toolkit <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__.

This produces:

* ``srw.sh`` — wrapper script
* ``ufs-srweather-app/`` — SRW App repository

.. _SetUpConfigFileC:

Configure the Workflow
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Configuring the workflow for the container is similar to configuring the workflow without a container. The only exception is that there is no need to activate the ``srw_app`` conda environment because there is a conflict between the container's conda and the host’s conda. To work around this conflict, the container’s conda environment bin directory is appended to the system’s ``PATH`` variable in the ``python_srw.lua`` and ``build_<platform>_intel.lua`` modulefiles. 

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

   #. To automate the workflow, add these two lines to the ``workflow:`` section of ``config.yaml``: 

      .. code-block:: console

         USE_CRON_TO_RELAUNCH: TRUE
         CRON_RELAUNCH_INTVL_MNTS: 3

      There are instructions for running the experiment via additional methods in :numref:`Section %s <Run>`. However, this technique (automation via :term:`crontab`) is the simplest option. 

      .. note::
         On Orion, *cron* is only available on the orion-login-1 node, so users will need to work on that node when running *cron* jobs on Orion.

   #. Edit the ``task_get_extrn_ics:`` section of the ``config.yaml`` to include the correct data paths to the initial conditions files. For example, on Ursa, add:

      .. code-block:: console

         USE_USER_STAGED_EXTRN_FILES: true
         EXTRN_MDL_SOURCE_BASEDIR_ICS: /scratch3/NCEPDEV/nems/role.epic/ursa/UFS_SRW_data/develop/input_model_data/FV3GFS/grib2/${yyyymmddhh}

      On other systems, users will need to change the path for ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS`` (below) to reflect the location of the system's data. The location of the machine's global data can be viewed :ref:`here <Data>` for Level 1 systems. Alternatively, the user can add the path to their local data if they downloaded it as described in :numref:`Section %s <InitialConditions>`.

   #. Edit the ``task_get_extrn_lbcs:`` section of the ``config.yaml`` to include the correct data paths to the lateral boundary conditions files. For example, on Ursa, add:

      .. code-block:: console

         USE_USER_STAGED_EXTRN_FILES: true
         EXTRN_MDL_SOURCE_BASEDIR_LBCS: /scratch3/NCEPDEV/nems/role.epic/ursa/UFS_SRW_data/develop/input_model_data/FV3GFS/grib2/${yyyymmddhh}


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

.. _ContainerSoftwareStackWorkflowC:

---------------------------------------------------------------
Containerized Software-Stack Workflow for Building from Source
---------------------------------------------------------------

This workflow uses a container that provides compilers, MPI libraries, and
pre-built spack-stack software libraries required to build and run the SRW App.
Users download the SRW App source code, build it inside the container, and run
the generated workflow from the host system through container wrapper scripts.

The workflow supports the following container options:

* a staged GNU-based or Intel oneAPI-based software-stack containers on supported
  NOAA RDHPC Tier 1 platforms;
* a GNU-based container image built from Docker Hub on systems where a staged
  image is not available;
* an Intel-capable container image prepared from Docker Hub, followed by a
  local Intel oneAPI compiler and MPI reinstall step. 

After the container image is available, the remaining workflow is the same for
GNU and Intel containers: clone the SRW App, open an interactive shell inside
the container, build the application, exit the container, configure the
workflow, and run the community test case from the host system.

.. _SelectSoftwareStackContainerC:

Select or Build a Software-Stack Container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Option 1: Use a staged NOAA RDHPC Tier 1 container**

On supported Tier 1 platforms, GNU-based and Intel oneAPI-based software-stack
container images are available in shared locations, as shown in the table below.
These containers include compilers, corresponding software and MPI libraries,
and the software stack.


.. list-table:: Locations of pre-built container images on supported systems
   :widths: 20 50
   :header-rows: 1

   * - Machine
     - File Location
   * - Ursa
     - /scratch3/NCEPDEV/nems/role.epic/containers
   * - Gaea-C6 
     - /gpfs/f6/bil-fire8/world-shared/containers
   * - Orion/Hercules
     - /work/noaa/epic/role-epic/contrib/containers
   * - Derecho [#fn1]_
     - /glade/work/epicufsrt/contrib/containers
   * - NOAA Cloud [#fn2]_
     - /contrib/EPIC/containers


.. [#fn1] Software-stack container support on Derecho is still a work in progress.
.. [#fn2] NOAA Cloud containers are accessible only to users with EPIC resources through
   the Parallel Works dashboard.

Use one of the following approaches to define the ``IMG`` variable as the full
path to the container image that will be used for the SRW App build and runtime
workflow

.. code-block:: console

   # For GNU-based container image define:
   export IMG=<full-container-path>/rocky9-gcc13-ss192-ompi416.sif
   # for Intel-based container image define:
   export IMG=<full-container-path>/rocky9-oneapi2024.2-ss192.sif

Proceed to :ref:`downloading the SRW and submodules <DownloadSRWC>`.

**Option 2: Build a GNU-based container from Docker Hub**

If a staged GNU image is not available, build a Singularity/Apptainer image from
Docker Hub. 

.. code-block:: console

   singularity build rocky9-gcc13-ss192-ompi416.sif \
      docker://noaaepic/rocky9-gcc13.3.1-spack-stack:v1.9.2-ufs-env-ompi416

   export IMG=${PWD}/rocky9-gcc13-ss192-ompi416.sif

If the build fails because of cache or temporary-space limits, you may need to clear
the default temporary directories (e.g, *${HOME}/.singularity/cache* or
*${HOME}/.apptainer/cache*) and proceed to allocate more temporary space as 
outlined in :ref:`Appendix`.

After the image is built, proceed to :ref:`downloading the SRW and submodules <DownloadSRWC>`.

**Option 3: Prepare an Intel-capable container from Docker Hub**

This workflow starts from an Intel-capable software-stack image available on
Docker Hub, creates a writable sandbox, reinstalls the required Intel oneAPI
compiler and MPI components, and then converts the updated sandbox into a
Singularity/Apptainer image.

The examples in the following steps use local names for images and sandboxes.
In general, use the full path to each image or sandbox unless a specific step
instructs otherwise.

#. Create a writable sandbox from the Docker Hub image.
   Include bind-mounting host directories into the
   container. At a minimum, bind the top-level filesystem that contains your
   current directory, ``</top_dir>``, and any additional directories, ``/bind_add``,
   required for container builds. These may include system-dependent temporary
   build space, scratch space used as the default ``/tmp``, or ``/local``.
   Each bind path must be listed with a preceding ``-B`` flag. Typical bind
   directories for supported NOAA RDHPC Tier 1 platforms are listed in 
   :numref:`ContainerBindDirectoriesTable`.

   .. code-block:: console

      singularity build -B </top_dir> -B </bind_add> --sandbox --fix-perms rocky9-oneapi2024.2-ss192 \
         docker://noaaepic/rocky9-oneapi2024.2-spack-stack:v1.9.2-ufs-wm-env

#. Copy the helper scripts out of the sandbox.

   .. code-block:: console

      singularity exec rocky9-oneapi2024.2-ss192 cp /opt/intel-sandbox.sh .
      singularity exec rocky9-oneapi2024.2-ss192 cp /opt/compilers_cp.sh .

   These scripts retrieve the Intel compiler and MPI components and reinstall
   them for use with the software-stack sandbox.

#. Create a sandbox with the original Intel oneAPI compilers by running the
   ``intel-sandbox.sh`` script from the same directory that contains the
   software-stack sandbox ``rocky9-oneapi2024.2-ss192``.

   .. code-block:: console

      ./intel-sandbox.sh

   After this step, an additional ``intel-sandbox`` sandbox container will be available.

#. Copy the required software and libraries from ``intel-sandbox`` to the
   original software-stack sandbox by running the ``compilers_cp.sh`` script.
   Include only the names of the source sandbox, ``intel-sandbox``, and target
   sandbox, ``rocky9-oneapi2024.2-ss192``; do not provide their full paths.

   .. code-block:: console

      ./compilers_cp.sh intel-sandbox rocky9-oneapi2024.2-ss192

   After this step, the software-stack sandbox contains the compilers, MPI, and
   required software stack. The Intel sandbox, ``intel-sandbox``, can then be removed.

   The assembled sandbox can be used for runs, but it is large compared to a
   compressed image. For production runs, convert the sandbox into a SIF image,
   as shown in the next step.

#. Build a Singularity/Apptainer container image from the updated sandbox. Bind
   host directories as required.

   .. code-block:: console

      singularity build -B /<top-level-dir> --fix-perms rocky9-oneapi2024.2-ss192.sif \
         rocky9-oneapi2024.2-ss192

   After the image is built successfully, the sandbox can be removed. Finally, 
   define the ``IMG`` variable for use in later steps.
   
   .. code-block:: console

      export IMG=<full-container-path>/rocky9-oneapi2024.2-ss192.sif
   
Proceed with downloading, building, and running the SRW App.

.. _DownloadSRWC:

Download the UFS SRW App and Submodules
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Clone the UFS SRW App develop branch from the GitHub repository as is done
when  :ref:`Building the SRW App <BuildSRW>`.

.. include:: ../../doc-snippets/clone.rst

.. code-block:: console

   cd ufs-srweather-app

.. include:: ../../doc-snippets/externals.rst

Save the environment variable SRW for later use:

.. code-block:: console

   export SRW=${PWD}

.. _ShellInteractiveC:

Shell into the Software-Stack Container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Open an interactive shell inside the container before building the SRW App. Bind
the top-level host filesystem that contains the SRW App checkout, the input
data, and the intended experiment directories. If additional site filesystems
are required, bind them with additional ``-B`` options.

.. code-block:: console

   singularity shell -B </top_dir> [-B </bind_add>] -e ${IMG}

.. _ContainerBindDirectoriesTable:

.. list-table:: Typical bind directories on NOAA RDHPC Tier 1 platforms
   :widths: 25 35 40
   :header-rows: 1

   * - Machine
     - Main bind directory ``</top_dir>``
     - Additional bind directory ``</bind_add>``
   * - Derecho
     - ``/glade``
     - none
   * - Ursa
     - ``/scratch3``
     - ``/scratch4``
   * - Gaea-C6
     - ``/gpfs``
     - ``/ncrc/home2``
   * - Hercules/Orion
     - ``/work``
     - ``/work2``; ``/local`` if required by the workflow
   * - NOAA Cloud AWS/Azure
     - ``/contrib``
     - ``/lustre`` if attached to the cluster and used for testing

Examples:

.. code-block:: console

   # Ursa
   apptainer shell -B /scratch3 -B /scratch4 -e ${IMG}

   # Gaea-C6
   apptainer shell -B /gpfs -B /ncrc/home2 -e ${IMG}

   # Hercules or Orion
   singularity shell -B /work -B /work2 -B /local -e ${IMG}

   # NOAA Cloud AWS or Azure
   singularity shell -B /contrib -B /lustre -e ${IMG}

After the shell starts, the prompt changes to ``Apptainer>`` or
``Singularity>``.

.. _BuildSRWInsideContainerC:

Build SRW Executables and Conda Environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Inside the container, build executables using ``devbuild.sh`` script,
in a similar way as described in  :ref:`Building Executables <BuildExecutables>`, 
except placing binaries into the ``bin`` directory. 
This is the essential difference, since the default ``exec`` directory
where the SRW App expects to find binaries, 
will be used to contain wrapper scripts for the actual binaries.

.. code-block:: console

   ./devbuild.sh --bin-dir=bin --platform=container --compiler=gnu \
        | tee log.devbuild.001

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

Prepare the Workflow Module File
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Prepare a workflow module file in the ``./modulefiles`` directory. A sample
container workflow module file, ``wflow_container.lua``, is provided and may be
kept for reference.

The examples below assume that standard platform names are used:

* ``ursa``
* ``gaeac6``
* ``orion``
* ``hercules``
* ``noaacloud``

On NOAA RDHPC Tier 1 systems, copy the workflow module file for the target
platform to ``wflow_container.lua``:

.. code-block:: console

   cd modulefiles
   cp wflow_<platform>.lua wflow_container.lua

For example:

.. code-block:: console

   cp wflow_ursa.lua wflow_container.lua

Some platforms require loading a container runtime module before Singularity or
Apptainer can be used. On those systems, add the appropriate module load command
to the platform workflow module file. For example, on Hercules and Orion, add
the following line to ``wflow_hercules.lua`` or ``wflow_orion.lua``:

.. code-block:: lua

   load("singularity")

.. note::

   The exact container runtime module may vary by platform. Use the module name
   provided by the target system, such as ``singularity`` or ``apptainer``.


.. _PrepareConfigurationFilesC:

Prepare Configuration Files
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Adapt the configuration files for the target platform and for the community
test case.

First, prepare the main SRW App configuration file:

.. code-block:: console

   cd ../ush
   cp config.container.yaml config.yaml

Edit ``./ush/config.yaml`` and set the following variables as needed:

.. code-block:: yaml

   ACCOUNT: epic
   COMPILER: gnu
   USE_CRON_TO_RELAUNCH: false
   EXPT_SUBDIR: test_community

Set ``ACCOUNT`` to the account or project name used on the target system. Set
``COMPILER`` to the compiler used by the container software stack, such as
``gnu`` or ``intel``. Set ``USE_CRON_TO_RELAUNCH`` to ``true`` only on systems
where cron-based relaunching is allowed. Modify ``EXPT_SUBDIR`` if a different
experiment directory name is desired.

Next, prepare the machine file:

.. code-block:: console

   cd machines
   cp <platform>.yaml container.yaml

For example:

.. code-block:: console

   cp ursa.yaml container.yaml

Edit ``./ush/machines/container.yaml`` for the container workflow. Modify
``NCORES_PER_NODE`` if the default value does not match the target platform or
the resources requested for the test.

Set the run commands to use ``srun`` with the ``pmi2`` MPI interface:

.. code-block:: yaml

   RUN_CMD_FCST: srun --mpi=pmi2 -n $nprocs
   RUN_CMD_POST: srun --mpi=pmi2 -n $nprocs
   RUN_CMD_PRDGEN: srun --mpi=pmi2 -n $nprocs
   RUN_CMD_UTILS: srun --mpi=pmi2 -n $nprocs

Adapt ``SCHED_NATIVE_CMD`` for the target platform. On Gaea-C6, set:

.. code-block:: yaml

   SCHED_NATIVE_CMD: --clusters=c6

For Hercules, Orion, Ursa, and NOAA Cloud, remove the ``SCHED_NATIVE_CMD`` line
from ``container.yaml``.

.. note::

   AQM and NEXUS have not been tested with the container workflow.

.. _GenerateWorkflowSoftwareStackC:

Generate Workflow for Software-Stack Container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Load the modulefile **wflow_container** that load any host
modulefiles if needed and starts
the conda environment (srw_app) for running the workflow:

.. code-block:: console

   module use $SRW/modulefiles
   module load wflow_container

Generate the workflow:

.. code-block:: console

   cd $SRW/ush
   ./generate_FV3LAM_wflow.py

When generated successfully, the ``EXPTDIR`` path for the experiment will be displayed. 
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
If the cache and tmp directories do not exist already, they must be created with a ``mkdir`` command preceding the export of the variables.

.. code-block:: console

   mkdir /absolute/path/to/writable/directory/cache
   mkdir /absolute/path/to/writable/directory/tmp

where /absolute/path/to/writable/directory/ refers to the absolute path to a writable directory with sufficient disk space.
Proceed with exporting the variables:

.. code-block:: console

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

When using Apptainer, use the ``APPTAINER_`` environment-variable prefix
instead of the legacy ``SINGULARITY_`` prefix. Compatibility with
``SINGULARITY_`` variables may vary by Apptainer version, site installation,
and local configuration.


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

After allocation you may or may not need to connect to the allocated host. Connect by
``ssh`` if required:

.. code-block:: console

   ssh <hostname>

Larger experiments may require multiple compute nodes.
