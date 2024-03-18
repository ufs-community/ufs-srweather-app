.. role:: bolditalic
    :class: bolditalic

.. role:: raw-html(raw)
    :format: html

.. _RunSRW:

===========================
Running the SRW App
=========================== 

This section explains how to set up and run the basic "out-of-the-box" case for the SRW Application. However, the steps are relevant to any SRW App experiment and can be modified to suit user goals. This chapter assumes that users have already built the SRW App by following the steps in :numref:`Section %s <BuildSRW>` (or :numref:`Section %s <DownloadCodeC>` if running the containerized version of the SRW App).

The out-of-the-box SRW App case builds a weather forecast for June 15-16, 2019. Multiple convective weather events during these two days produced over 200 filtered storm reports. Severe weather was clustered in two areas: the Upper Midwest through the Ohio Valley and the Southern Great Plains. This forecast uses a predefined 25-km Continental United States (:term:`CONUS`) domain (RRFS_CONUS_25km), the Global Forecast System (:term:`GFS`) version 16 physics suite (FV3_GFS_v16 :term:`CCPP`), and :term:`FV3`-based GFS raw external model data for initialization.

.. attention::

   The SRW Application has :srw-wiki:`four levels of support <Supported-Platforms-and-Compilers>`. The steps described in this section will work most smoothly on preconfigured (Level 1) systems. They should also work on other systems (including generic Linux/Mac systems), but the user may need to perform additional troubleshooting. 


The overall procedure for generating an experiment is shown in :numref:`Figure %s <AppOverallProc>`, with the scripts to generate and run the workflow shown in red. Once the SRW App has been built, as described in :numref:`Chapter %s <BuildSRW>`, the steps to run a forecast are as follows:

   #. :ref:`Download and stage data <Data>`
   #. :ref:`Optional: Configure a new grid <GridSpecificConfig>`
   #. :ref:`Generate an SRW App experiment <GenerateForecast>`

      * :ref:`Load the workflow environment <SetUpPythonEnv>`
      * :ref:`Set the experiment configuration parameters <UserSpecificConfig>`
      * :ref:`Optional: Plot the output <PlotOutput>`
      * :ref:`Optional: Configure METplus Verification Suite <VXConfig>`

   #. :ref:`Run the SRW App workflow <Run>`

.. _AppOverallProc:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/WorkflowImages/SRW_run_process.png
   :alt: Flowchart describing the SRW App workflow steps. 

   *Overall Layout of the SRW App Workflow*

.. _Data:

Download and Stage the Data
============================

The SRW App requires input files to run. These include static datasets, initial and boundary conditions files, and model configuration files. On Level 1 systems, the data required to run SRW App tests are already available in the following locations: 

.. _DataLocations:
.. list-table:: Data Locations for Level 1 Systems
   :widths: 20 50
   :header-rows: 1

   * - Machine
     - File location
   * - Derecho
     - /glade/work/epicufsrt/contrib/UFS_SRW_data/|data|/input_model_data
   * - Gaea (C3/C4/C5)
     - /lustre/f2/dev/role.epic/contrib/UFS_SRW_data/|data|/input_model_data/
   * - Hera
     - /scratch1/NCEPDEV/nems/role.epic/UFS_SRW_data/|data|/input_model_data/
   * - Hercules
     - /work/noaa/epic/role-epic/contrib/UFS_SRW_data/|data|/input_model_data/
   * - Jet
     - /mnt/lfs4/HFIP/hfv3gfs/role.epic/UFS_SRW_data/|data|/input_model_data/
   * - NOAA Cloud
     - /contrib/EPIC/UFS_SRW_data/|data|/input_model_data/
   * - Orion
     - /work/noaa/epic/role-epic/contrib/UFS_SRW_data/|data|/input_model_data/
   * - WCOSS2
     - /lfs/h2/emc/lam/noscrub/UFS_SRW_App/develop/input_model_data/

For Level 2-4 systems, the data must be added to the user's system. Detailed instructions on how to add the data can be found in :numref:`Section %s: Downloading and Staging Input Data <DownloadingStagingInput>`. Sections :numref:`%s: Input Files <Input>` and :numref:`%s: Output Files <OutputFiles>` contain useful background information on the input and output files used in the SRW App.

.. _GridSpecificConfig:

Grid Configuration
=======================

The SRW App officially supports the five predefined grids shown in :numref:`Table %s <PredefinedGrids>`. The out-of-the-box SRW App case uses the ``RRFS_CONUS_25km`` predefined grid option. More information on the predefined and user-generated grid options can be found in :numref:`Section %s: Limited Area Model (LAM) Grids <LAMGrids>`. Users who plan to utilize one of the five predefined domain (grid) options may continue to the next step (:numref:`Step %s: Generate the Forecast Experiment <GenerateForecast>`). Users who plan to create a new custom predefined grid should refer to the instructions in :numref:`Section %s: Creating User-Generated Grids <UserDefinedGrid>`. At a minimum, these users will need to add the new grid name to the ``valid_param_vals.yaml`` file and add the corresponding grid-specific parameters in the ``predef_grid_params.yaml`` file.

.. _PredefinedGrids:

.. list-table:: Predefined Grids Supported in the SRW App
   :widths: 30 30 30
   :header-rows: 1

   * - Grid Name
     - Grid Type
     - Quilting (write component)
   * - RRFS_CONUS_25km
     - ESG grid
     - lambert_conformal
   * - RRFS_CONUS_13km
     - ESG grid
     - lambert_conformal
   * - RRFS_CONUS_3km
     - ESG grid
     - lambert_conformal
   * - SUBCONUS_Ind_3km
     - ESG grid
     - lambert_conformal
   * - RRFS_NA_13km
     - ESG grid
     - lambert_conformal

.. _GenerateForecast:

Generate the Forecast Experiment 
=================================
Generating the forecast experiment requires three steps:

#. :ref:`Load the workflow environment <SetUpPythonEnv>`
#. :ref:`Set experiment configuration parameters <ExptConfig>`
#. :ref:`Run a script to generate the experiment workflow <GenerateWorkflow>`

The first two steps depend on the platform being used and are described here for each Level 1 platform. Users will need to adjust the instructions to reflect their machine's configuration if they are working on a Level 2-4 platform. Information in :numref:`Section %s: Configuring the Workflow <ConfigWorkflow>` can help with this. 

.. _SetUpPythonEnv:

Load the Conda/Python Environment
------------------------------------

The SRW App workflow requires a variety of Python packages. To manage the packages, the App relies
on conda as a package manager and virtual environment manager. At build time, users have the option
to install the latest version of miniforge and automatically create the environments needed by the SRW App.
Managed environments will no longer be updated on Level 1 platforms for newer versions of the SRW App.


.. _Load-WF-L1:

Loading the Workflow Environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The |wflow_env| conda/Python environment can be activated in the following way:

.. code-block:: console

   source /path/to/ufs-srweather-app/etc/lmod-setup.sh <platform>
   module use /path/to/ufs-srweather-app/modulefiles
   module load wflow_<platform>

where ``<platform>`` refers to a valid machine name (see :numref:`Section %s <user>` for ``MACHINE`` options). In a csh shell environment, users should replace ``lmod-setup.sh`` with ``lmod-setup.csh``. 

.. note::
   If users source the lmod-setup file on a system that doesn't need it, it will not cause any problems (it will simply do a ``module purge``).

The ``wflow_<platform>`` modulefile will then output instructions to activate the SRW App workflow. The user should run the commands specified in the modulefile output. The command may vary from system to system. For example, if the output says: 

.. code-block:: console

   Please do the following to activate conda:
       > conda activate srw_app

then the user should run |activate|. This activates the |wflow_env| conda environment, and the user typically sees |prompt| in front of the Terminal prompt at this point.

.. note::
   If users do not use the wflow module to load conda, ``conda`` will need to be initialized before running ``conda activate srw_app`` command. Depending on the user's system and login setup, this may be accomplished in a variety of ways. Conda initialization usually involves the following command: ``source <conda_basedir>/etc/profile.d/conda.sh``, where ``<conda_basedir>`` is the base conda installation directory and by default will be the full path to ``ufs-srweather-app/conda``.

After loading the workflow environment, users may continue to :numref:`Section %s <ExptConfig>` for instructions on setting the experiment configuration parameters.

Modify a ``wflow_<platform>`` File
``````````````````````````````````````

Users can copy one of the provided ``wflow_<platform>`` files from the ``modulefiles`` directory and use it as a template to create a ``wflow_<platform>`` file that functions on their system. The ``wflow_macos`` and ``wflow_linux`` template modulefiles are provided as a starting point, but any ``wflow_<platform>`` file could be used. Since conda environments are installed with the SRW App build, the existing modulefiles will be able to automatically find those environments. No need to edit any of the information in those files for Python purposes.

.. _ExptConfig:

Set Experiment Configuration Parameters
------------------------------------------

Each experiment requires certain basic information to run (e.g., date, grid, physics suite). Default values are assigned in ``config_defaults.yaml``, and users adjust the desired variables in the experiment configuration file named ``config.yaml``. When generating a new experiment, the SRW App first reads and assigns default values from ``config_defaults.yaml``. Then, it reads and (re)assigns variables from the user's custom ``config.yaml`` file. 

.. _DefaultConfigSection:

Default configuration: ``config_defaults.yaml``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In general, ``config_defaults.yaml`` is split into sections by category (e.g., ``user:``, ``platform:``, ``workflow:``, ``task_make_grid:``). Users can view a full list of categories and configuration parameters in the :doc:`Table of Variables in config_defaults.yaml <DefaultVarsTable>`. Definitions and default values of each of the variables can be found in :numref:`Section %s: Workflow Parameters <ConfigWorkflow>` and in the ``config_defaults.yaml`` file comments. Some of these default values are intentionally invalid in order to ensure that the user assigns valid values in their ``config.yaml`` file. There is usually no need for a user to modify ``config_defaults.yaml`` because any settings provided in ``config.yaml`` will override the settings in ``config_defaults.yaml``.

.. _UserSpecificConfig:

User-specific configuration: ``config.yaml``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The user must set the specifics of their experiment configuration in a ``config.yaml`` file located in the ``ufs-srweather-app/ush`` directory. Two example templates are provided in that directory: ``config.community.yaml`` and ``config.nco.yaml``. The first file is a basic example for creating and running an experiment in *community* mode (with ``RUN_ENVIR`` set to ``community``). The second is an example for creating and running an experiment in the *NCO* (operational) mode (with ``RUN_ENVIR`` set to ``nco``). The *community* mode is recommended in most cases, and user support is available for running in community mode. The operational/NCO mode is typically used by developers at the Environmental Modeling Center (:term:`EMC`) and the Global Systems Laboratory (:term:`GSL`) who are working on pre-implementation testing for the Rapid Refresh Forecast System (:term:`RRFS`). :numref:`Table %s <ConfigCommunity>` compares the configuration variables that appear in the ``config.community.yaml`` with their default values in ``config_defaults.yaml``.

.. _ConfigCommunity:

.. list-table:: Configuration variables specified in the *config.community.yaml* script
   :widths: 30 30 30
   :header-rows: 1

   * - Parameter
     - Default Value
     - *config.community.yaml* Value
   * - RUN_ENVIR
     - "nco"
     - "community"
   * - MACHINE
     - "BIG_COMPUTER"
     - "hera"
   * - ACCOUNT
     - ""
     - "an_account"
   * - CCPA_OBS_DIR
     - "{{ workflow.EXPTDIR }}/obs_data/ccpa/proc"
     - ""
   * - MRMS_OBS_DIR
     - "{{ workflow.EXPTDIR }}/obs_data/mrms/proc"
     - ""
   * - NDAS_OBS_DIR
     - "{{ workflow.EXPTDIR }}/obs_data/ndas/proc"
     - ""
   * - USE_CRON_TO_RELAUNCH
     - false
     - false
   * - EXPT_SUBDIR
     - ""
     - "test_community"
   * - CCPP_PHYS_SUITE
     - "FV3_GFS_v16"
     - "FV3_GFS_v16"
   * - PREDEF_GRID_NAME
     - ""
     - "RRFS_CONUS_25km"
   * - DATE_FIRST_CYCL
     - "YYYYMMDDHH"
     - '2019061518'
   * - DATE_LAST_CYCL
     - "YYYYMMDDHH"
     - '2019061518'
   * - FCST_LEN_HRS
     - 24
     - 12
   * - PREEXISTING_DIR_METHOD
     - "delete"
     - "rename"
   * - VERBOSE
     - true
     - true
   * - COMPILER
     - "intel"
     - "intel"
   * - EXTRN_MDL_NAME_ICS
     - "FV3GFS"
     - "FV3GFS"
   * - FV3GFS_FILE_FMT_ICS
     - "nemsio"
     - "grib2"
   * - EXTRN_MDL_NAME_LBCS
     - "FV3GFS"
     - "FV3GFS"
   * - LBC_SPEC_INTVL_HRS
     - 6
     - 6
   * - FV3GFS_FILE_FMT_LBCS
     - "nemsio"
     - "grib2"
   * - QUILTING
     - true
     - true
   * - COMOUT_REF
     - ""
     - ""
   * - DO_ENSEMBLE
     - false
     - false
   * - NUM_ENS_MEMBERS
     - 1
     - 2
   * - VX_FCST_MODEL_NAME
     - '{{ nco.NET_default }}.{{ task_run_post.POST_OUTPUT_DOMAIN_NAME }}'
     - FV3_GFS_v16_CONUS_25km

.. _GeneralConfig:

General Instructions for All Systems
```````````````````````````````````````

To get started with a basic forecast in *community* mode, make a copy of ``config.community.yaml``. From the ``ufs-srweather-app`` directory, run:

.. code-block:: console

   cd ush
   cp config.community.yaml config.yaml

The default settings in this file include a predefined 25-km :term:`CONUS` grid (RRFS_CONUS_25km), the :term:`GFS` v16 physics suite (FV3_GFS_v16 :term:`CCPP`), and :term:`FV3`-based GFS raw external model data for initialization.

Next, users should edit the new ``config.yaml`` file to customize it for their machine. On most systems, the following fields need to be updated or added to the appropriate section of the ``config.yaml`` file in order to run the out-of-the-box SRW App case:

.. code-block:: console

   user:
      MACHINE: hera
      ACCOUNT: an_account
   workflow:
      EXPT_SUBDIR: test_community
   task_get_extrn_ics:
      USE_USER_STAGED_EXTRN_FILES: true
      EXTRN_MDL_SOURCE_BASEDIR_ICS: "/path/to/UFS_SRW_data/develop/input_model_data/<model_type>/<data_type>/${yyyymmddhh}"
   task_get_extrn_lbcs:
      USE_USER_STAGED_EXTRN_FILES: true
      EXTRN_MDL_SOURCE_BASEDIR_LBCS: "/path/to/UFS_SRW_data/develop/input_model_data/<model_type>/<data_type>/${yyyymmddhh}"

where: 
   * ``MACHINE`` refers to a valid machine name (see :numref:`Section %s <user>` for options).
   * ``ACCOUNT`` refers to a valid account name. Not all systems require a valid account name, but most Level 1 & 2 systems do. 

   .. hint::

      * To determine an appropriate ACCOUNT field for Level 1 systems, run ``groups``, and it will return a list of projects you have permissions for. Not all of the listed projects/groups have an HPC allocation, but those that do are potentially valid account names. 
      * Users can also try running ``saccount_params``, which provides more information but is not available on all systems.

   * ``EXPT_SUBDIR`` is changed to an experiment name of the user's choice.
   * ``/path/to/`` is the path to the SRW App data on the user's machine (see :numref:`Section %s <Data>` for data locations on Level 1 systems). 
   * ``<model_type>`` refers to a subdirectory containing the experiment data from a particular model. Valid values on Level 1 systems correspond to the valid values for ``EXTRN_MDL_NAME_ICS`` and ``EXTRN_MDL_NAME_LBCS`` (see :numref:`Section %s <basic-get-extrn-ics>` or :numref:`%s <basic-get-extrn-lbcs>` for options). 
   * ``<data_type>`` refers to one of 3 possible data formats: ``grib2``, ``nemsio``, or ``netcdf``. 
   * ``${yyyymmddhh}`` refers to a subdirectory containing data for the :term:`cycle` date (in YYYYMMDDHH format). Users may hardcode this value or leave it as-is, and the experiment will derive the correct value from ``DATE_FIRST_CYCL`` and related information.

On platforms where Rocoto and :term:`cron` are available, users can automate resubmission of their experiment workflow by adding the following lines to the ``workflow:`` section of the ``config.yaml`` file:

.. code-block:: console

   USE_CRON_TO_RELAUNCH: true
   CRON_RELAUNCH_INTVL_MNTS: 3

.. note::

   On Orion, *cron* is only available on the orion-login-1 node, so users will need to work on that node when running *cron* jobs on Orion.

When running with GNU compilers (i.e., if the modulefile used to set up the build environment in :numref:`Section %s <BuildExecutables>` uses a GNU compiler), users must also set ``COMPILER: "gnu"`` in the ``workflow:`` section of the ``config.yaml`` file.

.. note::

   On ``JET``, users should add ``PARTITION_DEFAULT: xjet`` and ``PARTITION_FCST: xjet`` to the ``platform:`` section of the ``config.yaml`` file.

For example, to run the out-of-the-box experiment on Derecho using cron to automate job submission, users can add or modify variables in the ``user``, ``workflow``, ``task_get_extrn_ics``, and ``task_get_extrn_lbcs`` sections of ``config.yaml`` according to the following example (unmodified variables are not shown here): 

   .. code-block::
      
      user:
         MACHINE: derecho
         ACCOUNT: NRAL0000
      workflow:
         EXPT_SUBDIR: run_basic_srw
         USE_CRON_TO_RELAUNCH: true
         CRON_RELAUNCH_INTVL_MNTS: 3
      task_get_extrn_ics:
         USE_USER_STAGED_EXTRN_FILES: true
         EXTRN_MDL_SOURCE_BASEDIR_ICS: /glade/work/epicufsrt/contrib/UFS_SRW_data/develop/input_model_data/FV3GFS/grib2/2019061518
      task_get_extrn_lbcs:
         USE_USER_STAGED_EXTRN_FILES: true
         EXTRN_MDL_SOURCE_BASEDIR_LBCS: /glade/work/epicufsrt/contrib/UFS_SRW_data/develop/input_model_data/FV3GFS/grib2/2019061518

.. hint::

   * Valid values for configuration variables should be consistent with those in the ``ush/valid_param_vals.yaml`` script. 

   * Various sample configuration files can be found within the subdirectories of ``tests/WE2E/test_configs``.

   * Users can find detailed information on configuration parameter options in :numref:`Section %s: Configuring the Workflow <ConfigWorkflow>`. 

.. COMMENT: Add back if script is fixed: 
   To determine whether the ``config.yaml`` file adjustments are valid, users can run the following script from the ``ush`` directory:

   .. code-block:: console

      ./config_utils.py -c config.yaml -v config_defaults.yaml -k "(?\!rocoto\b)"

   A correct ``config.yaml`` file will output a ``SUCCESS`` message. A ``config.yaml`` file with problems will output a ``FAILURE`` message describing the problem. For example:

   .. code-block:: console

      INVALID ENTRY: EXTRN_MDL_FILES_ICS=[]
      FAILURE

.. _ConfigTasks:

Turning On/Off Workflow Tasks
````````````````````````````````

The ``ufs-srweather-app/parm/wflow`` directory contains several ``YAML`` files that configure different workflow task groups. Each task group file contains a number of tasks that are typically run together. :numref:`Table %s <task-group-files>` describes each of the task groups. 

.. _task-group-files:

.. list-table:: Task Group Files
   :widths: 20 50
   :header-rows: 1

   * - File
     - Function
   * - aqm_post.yaml
     - SRW-AQM post-processing tasks
   * - aqm_prep.yaml
     - SRW-AQM pre-processing tasks
   * - coldstart.yaml
     - Tasks required to run a cold-start forecast
   * - default_workflow.yaml
     - Sets the default workflow (prep.yaml, coldstart.yaml, post.yaml)
   * - plot.yaml
     - Plotting tasks
   * - post.yaml
     - Post-processing tasks
   * - prdgen.yaml
     - Horizontal map projection processor that creates smaller domain products from the larger domain created by the UPP. 
   * - prep.yaml
     - Pre-processing tasks
   * - verify_det.yaml
     - Deterministic verification tasks
   * - verify_ens.yaml
     - Ensemble verification tasks
   * - verify_pre.yaml
     - Verification pre-processing tasks

The default workflow task groups are set in ``parm/wflow/default_workflow.yaml`` and include ``prep.yaml``, ``coldstart.yaml``, and ``post.yaml``. To turn on/off tasks in the workflow, users must alter the list of task groups in the ``rocoto: tasks: taskgroups:`` section of ``config.yaml``. The list in ``config.yaml`` will override the default and run only the task groups listed. For example, to omit :term:`cycle-independent` tasks and run plotting tasks, users would delete ``prep.yaml`` from the list of tasks and add ``plot.yaml``:

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/plot.yaml"]|include }}'

Users may need to make additional adjustments to ``config.yaml`` depending on which task groups they add or remove. For example, when plotting, the user should add the plotting increment (``PLOT_FCST_INC``) for the plotting tasks in ``task_plot_allvars`` (see :numref:`Section %s <PlotOutput>` on plotting). 

Users can omit specific tasks from a task group by including them under the list of tasks as an empty entry. For example, if a user wanted to run only ``task_pre_post_stat`` from ``aqm_post.yaml``, the taskgroups list would include ``aqm_post.yaml``, and the tasks that the user wanted to omit would be listed with no value: 

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/aqm_post.yaml"]|include }}'
       task_post_stat_o3:
       task_post_stat_pm25:
       task_bias_correction_o3:
       task_bias_correction_pm25:

**Next Steps:**

   * To configure an experiment for a general Linux or Mac system, see the :ref:`next section <LinuxMacExptConfig>` for additional required steps. 
   * To add the graphics plotting tasks to the experiment workflow, go to section :numref:`Section %s: Plotting Configuration <PlotOutput>`. 
   * To configure an experiment to run METplus verification tasks, see :numref:`Section %s <VXConfig>`. 
   * Otherwise, skip to :numref:`Section %s <GenerateWorkflow>` to generate the workflow.

.. _LinuxMacExptConfig:

Configuring an Experiment on General Linux and MacOS Systems
``````````````````````````````````````````````````````````````

.. note::
    Examples in this subsection presume that the user is running in the Terminal with a bash shell environment. If this is not the case, users will need to adjust the commands to fit their command line application and shell environment. 

**Optional: Install Rocoto**

.. note::
   Users may `install Rocoto <https://github.com/christopherwharrop/rocoto/blob/develop/INSTALL>`__ if they want to make use of a workflow manager to run their experiments. However, this option has not yet been tested on MacOS and has had limited testing on general Linux plaforms.


**Configure the SRW App:**

After following the steps in :numref:`Section %s: General Configuration <GeneralConfig>` above, users should have a ``config.yaml`` file with settings from ``community.config.yaml`` and updates similar to this: 

.. code-block:: console

   user:
      MACHINE: macos
      ACCOUNT: user 
   workflow:
      EXPT_SUBDIR: my_test_expt
      COMPILER: gnu
   task_get_extrn_ics:
      USE_USER_STAGED_EXTRN_FILES: true
      EXTRN_MDL_SOURCE_BASEDIR_ICS: /path/to/input_model_data/FV3GFS/grib2/2019061518
   task_get_extrn_lbcs:
      USE_USER_STAGED_EXTRN_FILES: true
      EXTRN_MDL_SOURCE_BASEDIR_LBCS: /path/to/input_model_data/FV3GFS/grib2/2019061518

Due to the limited number of processors on MacOS systems, users must also configure the domain decomposition parameters directly in the section of the ``predef_grid_params.yaml`` file pertaining to the grid they want to use. Domain decomposition needs to take into account the number of available CPUs and configure the variables ``LAYOUT_X``, ``LAYOUT_Y``, and ``WRTCMP_write_tasks_per_group`` accordingly. 

The example below is for systems with 8 CPUs:

.. code-block:: console

   task_run_fcst:
      LAYOUT_X: 3
      LAYOUT_Y: 2
      WRTCMP_write_tasks_per_group: 2

.. note::
   The number of MPI processes required by the forecast will be equal to ``LAYOUT_X`` * ``LAYOUT_Y`` + ``WRTCMP_write_tasks_per_group``. 

For a machine with 4 CPUs, the following domain decomposition could be used:

.. code-block:: console

   task_run_fcst:
      LAYOUT_X: 3
      LAYOUT_Y: 1
      WRTCMP_write_tasks_per_group: 1

**Configure the Machine File**

Configure the ``macos.yaml`` or ``linux.yaml`` machine file in ``ufs-srweather-app/ush/machine`` based on the number of CPUs (``NCORES_PER_NODE``) in the system (usually 8 or 4 in MacOS; varies on Linux systems). Job scheduler (``SCHED``) options can be viewed :ref:`here <sched>`. Users must also set the path to the fix file directories. 

.. code-block:: console

   platform:
      # Architecture information
      WORKFLOW_MANAGER: none
      NCORES_PER_NODE: 8
      SCHED: none
      # Run commands for executables
      RUN_CMD_FCST: 'mpirun -np ${PE_MEMBER01}'
      RUN_CMD_POST: 'mpirun -np 4'
      RUN_CMD_SERIAL: time
      RUN_CMD_UTILS: 'mpirun -np 4'
      # Commands to run at the start of each workflow task.
      PRE_TASK_CMDS: '{ ulimit -a; }'
      FIXaer: /path/to/FIXaer/files
      FIXgsm: /path/to/FIXgsm/files
      FIXlut: /path/to/FIXlut/files

      # Path to location of static input files used by the make_orog task
      FIXorg: path/to/FIXorg/files 

      # Path to location of static surface climatology input fields used by sfc_climo_gen
      FIXsfc: path/to/FIXsfc/files 

      #Path to location of NaturalEarth shapefiles used for plotting
      FIXshp: /Users/username/DATA/UFS/NaturalEarth

   task_run_fcst:
      FIXaer: /path/to/FIXaer/files
      FIXgsm: /path/to/FIXgsm/files
      FIXlut: /path/to/FIXlut/files

   data:
      # Used by setup.py to set the values of EXTRN_MDL_SOURCE_BASEDIR_ICS and EXTRN_MDL_SOURCE_BASEDIR_LBCS
      FV3GFS: /Users/username/DATA/UFS/FV3GFS 

The ``data:`` section of the machine file can point to various data sources that the user has pre-staged on disk. For example:

.. code-block:: console

   data:
      FV3GFS:
         nemsio: /Users/username/DATA/UFS/FV3GFS/nemsio
         grib2: /Users/username/DATA/UFS/FV3GFS/grib2
         netcdf: /Users/username/DATA/UFS/FV3GFS/netcdf
      RAP: /Users/username/DATA/UFS/RAP/grib2
      HRRR: /Users/username/DATA/UFS/HRRR/grib2

This can be helpful when conducting multiple experiments with different types of data. 

**Next Steps:**

   * To add the graphics plotting tasks to the experiment workflow, go to the next section :ref:`Plotting Configuration <PlotOutput>`. 
   * To configure an experiment to run METplus verification tasks, see :numref:`Section %s <VXConfig>`. 
   * Otherwise, skip to :numref:`Section %s <GenerateWorkflow>` to generate the workflow.

.. _PlotOutput:

Plotting Configuration (optional)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

An optional Python plotting task (plot_allvars) can be activated in the workflow to generate plots for the :term:`FV3`-:term:`LAM` post-processed :term:`GRIB2`
output over the :term:`CONUS`. It generates graphics plots for a number of variables, including:

   * 2-m temperature
   * 2-m dew point temperature
   * 10-m winds
   * 250 hPa winds
   * Accumulated precipitation
   * Composite reflectivity
   * Surface-based :term:`CAPE`/:term:`CIN`
   * Max/Min 2-5 km updraft helicity
   * Sea level pressure (SLP)

This workflow task can produce both plots from a single experiment and difference plots that compare the same cycle from two experiments. When plotting the difference, the two experiments must be on the same domain and available for 
the same cycle starting date/time and forecast hours. Other parameters may differ (e.g., the experiments may use different physics suites).

.. _Cartopy:

Cartopy Shapefiles
`````````````````````

The Python plotting tasks require a path to the directory where the Cartopy Natural Earth shapefiles are located. The medium scale (1:50m) cultural and physical shapefiles are used to create coastlines and other geopolitical borders on the map. On :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems, this path is already set in the system's machine file using the variable ``FIXshp``. Users on other systems will need to download the shapefiles and update the path of ``$FIXshp`` in the machine file they are using (e.g., ``$SRW/ush/machine/macos.yaml`` for a generic MacOS system, where ``$SRW`` is the path to the ``ufs-srweather-app`` directory). The subset of shapefiles required for the plotting task can be obtained from the `SRW Data Bucket <https://noaa-ufs-srw-pds.s3.amazonaws.com/NaturalEarth/NaturalEarth.tgz>`__. The full set of medium-scale (1:50m) Cartopy shapefiles can be downloaded `here <https://www.naturalearthdata.com/downloads/>`__. 

Task Configuration
`````````````````````

Users will need to add or modify certain variables in ``config.yaml`` to run the plotting task(s). At a minimum, to activate the ``plot_allvars`` tasks, users must add the task's ``.yaml`` file to the default list of ``taskgroups`` under the ``rocoto: tasks:`` section.

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/plot.yaml"]|include }}'

Users may also wish to adjust the start, end, and increment value for the plotting task in the ``config.yaml`` file. For example:  

.. code-block:: console

   task_plot_allvars:
      PLOT_FCST_START: 0
      PLOT_FCST_INC: 6
      PLOT_FCST_END: 12

If the user chooses not to set these values, the default values will be used (see :numref:`Section %s <PlotVars>` for defaults).

.. note::
   If a forecast starts at 18 UTC, this is considered the 0th forecast hour, so "starting forecast hour" should be 0, not 18. 

When plotting output from a single experiment, no further adjustments are necessary. The output files (in ``.png`` format) will be located in the experiment directory under the ``$CDATE/postprd`` subdirectory where ``$CDATE`` 
corresponds to the cycle date and hour in YYYYMMDDHH format (e.g., ``2019061518``).

Plotting the Difference Between Two Experiments
""""""""""""""""""""""""""""""""""""""""""""""""""

When plotting the difference between two experiments (``expt1`` and ``expt2``), users must set the ``COMOUT_REF`` template variable in ``expt2``'s ``config.yaml`` file to point at forecast output from the ``expt1`` directory. For example, in *community* mode, users can set ``COMOUT_REF`` as follows in the ``expt2`` configuration file:

.. code-block:: console

   task_plot_allvars:
      COMOUT_REF: '${EXPT_BASEDIR}/expt1/${PDY}${cyc}/postprd'

This will ensure that ``expt2`` can produce a difference plot comparing ``expt1`` and ``expt2``. In *community* mode, using default directory names and settings, ``$COMOUT_REF`` will resemble ``/path/to/expt_dirs/test_community/2019061518/postprd``. Additional details on the plotting variables are provided in :numref:`Section %s <PlotVars>`. 

The output files (in ``.png`` format) will be located in the ``postprd`` directory for the experiment.

**Next Steps:**

   * To configure an experiment to run METplus verification tasks, see the :ref:`next section <VXConfig>`. 
   * Otherwise, skip to :numref:`Section %s <GenerateWorkflow>` to generate the workflow.

.. _VXConfig:

Configure METplus Verification Suite (Optional)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Users who want to use the METplus verification suite to evaluate their forecasts need to add additional information to their machine file (``ush/machine/<platform>.yaml``) or their ``config.yaml`` file. Other users may skip to the next step (:numref:`Section %s: Generate the SRW App Workflow <GenerateWorkflow>`). 

.. note::
   If METplus users update their METplus installation, they must update the module load statements in ``ufs-srweather-app/modulefiles/tasks/<machine>/run_vx.local`` to correspond to their system's updated installation:

   .. code-block:: console
      
      module use -a /path/to/met/modulefiles
      module load met/<version.X.X>
      module load metplus/<version.X.X>

To use METplus verification,  MET and METplus modules need to be installed. To turn on verification tasks in the workflow, include the ``parm/wflow/verify_*.yaml`` file(s) in the ``rocoto: tasks: taskgroups:`` section of ``config.yaml``. For example:

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/verify_pre.yaml", "parm/wflow/verify_det.yaml"]|include }}'

:numref:`Table %s <VX-yamls>` indicates which functions each ``verify_*.yaml`` file configures. Users must add ``verify_pre.yaml`` anytime they want to run verification (VX); it runs preprocessing tasks that are necessary for both deterministic and ensemble VX. Then users can add ``verify_det.yaml`` for deterministic VX or ``verify_ens.yaml`` for ensemble VX (or both). Note that ensemble VX requires the user to be running an ensemble forecast or to stage ensemble forecast files in an appropriate location.

.. _VX-yamls:

.. list-table:: Verification YAML Task Groupings
   :widths: 20 50
   :header-rows: 1

   * - File
     - Description
   * - verify_pre.yaml
     - Contains (meta)tasks that are prerequisites for both deterministic and ensemble verification (vx)
   * - verify_det.yaml
     - Perform deterministic vx
   * - verify_ens.yaml
     - Perform ensemble vx (must set ``DO_ENSEMBLE: true`` in ``config.yaml``)

The ``verify_*.yaml`` files include the definitions of several common verification tasks by default. Individual verification tasks appear in :numref:`Table %s <VXWorkflowTasksTable>`. The tasks in the ``verify_*.yaml`` files are independent of each other, so users may want to turn some off depending on the needs of their experiment. To turn off a task, simply include its entry from ``verify_*.yaml`` as an empty YAML entry in ``config.yaml``. For example, to turn off PointStat tasks:

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/verify_pre.yaml", "parm/wflow/verify_det.yaml"]|include }}'
     metatask_vx_ens_member:
       metatask_PointStat_mem#mem#:


More information about configuring the ``rocoto:`` section can be found in :numref:`Section %s <DefineWorkflow>`.

If users have access to NOAA :term:`HPSS` but have not pre-staged the data, the default ``verify_pre.yaml`` taskgroup will activate the tasks, and the workflow will attempt to download the appropriate data from NOAA HPSS. In this case, the ``*_OBS_DIR`` paths must be set to the location where users want the downloaded data to reside. 

Users who do not have access to NOAA HPSS and do not have the data on their system will need to download :term:`CCPA`, :term:`MRMS`, and :term:`NDAS` data manually from collections of publicly available data, such as the ones listed `here <https://dtcenter.org/nwp-containers-online-tutorial/publicly-available-data-sets>`__. 

Users who have already staged the observation data needed for METplus (i.e., the :term:`CCPA`, :term:`MRMS`, and :term:`NDAS` data) on their system should set the path to this data in ``config.yaml``. 

.. code-block:: console

   platform:
      CCPA_OBS_DIR: /path/to/UFS_SRW_data/develop/obs_data/ccpa/proc
      NOHRSC_OBS_DIR: /path/to/UFS_SRW_data/develop/obs_data/nohrsc/proc
      MRMS_OBS_DIR: /path/to/UFS_SRW_data/develop/obs_data/mrms/proc
      NDAS_OBS_DIR: /path/to/UFS_SRW_data/develop/obs_data/ndas/proc

After adding the VX tasks to the ``rocoto:`` section and the data paths to the ``platform:`` section, users can proceed to generate the experiment, which will perform VX tasks in addition to the default workflow tasks.

.. _GenerateWorkflow: 

Generate the SRW App Workflow
--------------------------------

Run the following command from the ``ufs-srweather-app/ush`` directory to generate the workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

The last line of output from this script, starting with ``*/1 * * * *`` or ``*/3 * * * *``, can be saved and used later to automatically run portions of the workflow if users have the Rocoto workflow manager installed on their system. 

This workflow generation script creates an experiment directory and populates it with all the data needed to run through the workflow. The flowchart in :numref:`Figure %s <WorkflowGeneration>` describes the experiment generation process. The ``generate_FV3LAM_wflow.py`` script: 

   #. Runs the ``setup.py`` script to set the configuration parameters. This script reads four other configuration scripts in order:
      
      a. ``config_defaults.yaml`` (:numref:`Section %s <DefaultConfigSection>`)
      b. ``${machine}.yaml`` (the machine configuration file)
      c. ``config.yaml`` (:numref:`Section %s <UserSpecificConfig>`) 
      d. ``valid_param_vals.yaml``

   #. Symlinks the time-independent (fix) files and other necessary data input files from their location to the experiment directory (``$EXPTDIR``). 
   #. Creates the input namelist file ``input.nml`` based on the ``input.nml.FV3`` file in the ``parm`` directory. 
   #. Creates the workflow XML file ``FV3LAM_wflow.xml`` that is executed when running the experiment with the Rocoto workflow manager.

The generated workflow will appear in ``$EXPTDIR``, where ``EXPTDIR=${EXPT_BASEDIR}/${EXPT_SUBDIR}``; these variables were specified in ``config_defaults.yaml`` and ``config.yaml`` in :numref:`Step %s <ExptConfig>`. The settings for these directory paths can also be viewed in the console output from the ``./generate_FV3LAM_wflow.py`` script or in the ``log.generate_FV3LAM_wflow`` file, which can be found in ``$EXPTDIR``.

.. _WorkflowGeneration:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/WorkflowImages/SRW_regional_workflow_gen.png
   :alt: Flowchart of the workflow generation process. Scripts are called in the following order: source_util_funcs.sh (which calls bash_utils), then set_FV3nml_sfc_climo_filenames.py, set_FV3nml_ens_stoch_seeds.py, create_diag_table_file.py, and setup.py. setup.py reads several yaml configuration files (config_defaults.yaml, config.yaml, {machine_config}.yaml, valid_param_vals.yaml, and others) and calls several scripts: set_cycle_dates.py, set_grid_params_GFDLgrid.py, set_grid_params_ESGgrid.py, link_fix.py, and set_ozone_param.py. Then, it sets a number of variables, including FIXgsm, fixorg, and FIXsfc variables. Next, set_predef_grid_params.py is called, and the FIXam and FIXLAM directories are set, along with the forecast input files. The setup script also calls set_extrn_mdl_params.py, sets the GRID_GEN_METHOD with HALO, checks various parameters, and generates shell scripts. Then, the workflow generation script produces a YAML configuration file and generates the actual Rocoto workflow XML file from the template file (by calling workflow-tools set_template). The workflow generation script checks the crontab file and, if applicable, copies certain fix files to the experiment directory. Then, it copies templates of various input files to the experiment directory and sets parameters for the input.nml file. Finally, it generates the workflow. Additional information on each step appears in comments within each script.

   *Experiment Generation Description*

.. _WorkflowTaskDescription: 

Description of Workflow Tasks
--------------------------------

.. note::
   This section gives a general overview of workflow tasks. To begin running the workflow, skip to :numref:`Step %s <Run>`

:numref:`Figure %s <WorkflowTasksFig>` illustrates the overall workflow. Individual tasks that make up the workflow are detailed in the ``FV3LAM_wflow.xml`` file. :numref:`Table %s <WorkflowTasksTable>` describes the function of each baseline task. The first three pre-processing tasks; ``make_grid``, ``make_orog``, and ``make_sfc_climo``; are optional. If the user stages pre-generated grid, orography, and surface climatology fix files, these three tasks can be skipped by removing the ``prep.yaml`` file from the default ``taskgroups`` entry in the ``config.yaml`` file before running the ``generate_FV3LAM_wflow.py`` script:

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/coldstart.yaml", "parm/wflow/post.yaml"]|include }}'

.. _WorkflowTasksFig:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/WorkflowImages/SRW_wflow_flowchart.png
   :alt: Flowchart of the default workflow tasks. If the make_grid, make_orog, and make_sfc_climo tasks are toggled off, they will not be run. If toggled on, make_grid, make_orog, and make_sfc_climo will run consecutively by calling the corresponding exregional script in the scripts directory. The get_ics, get_lbcs, make_ics, make_lbcs, and run_fcst tasks call their respective exregional scripts. The run_post task will run, and if METplus verification tasks have been configured, those will run during post-processing by calling their exregional scripts. 

   *Flowchart of the Default Workflow Tasks*


The ``FV3LAM_wflow.xml`` file runs the specific j-job scripts (``jobs/JREGIONAL_[task name]``) in the prescribed order when the experiment is launched via the ``launch_FV3LAM_wflow.sh`` script or the ``rocotorun`` command. Each j-job task has its own source script (or "ex-script") named ``exregional_[task name].sh`` in the ``ufs-srweather-app/scripts`` directory. Two database files named ``FV3LAM_wflow.db`` and ``FV3LAM_wflow_lock.db`` are generated and updated by the Rocoto calls. There is usually no need for users to modify these files. To relaunch the workflow from scratch, delete these two ``*.db`` files and then call the launch script repeatedly for each task.


.. _WorkflowTasksTable:

.. list-table:: Baseline Workflow Tasks in the SRW App
   :widths: 20 50
   :header-rows: 1

   * - Workflow Task
     - Task Description
   * - make_grid
     - Pre-processing task to generate regional grid files. Only needs to be run once per experiment.
   * - make_orog
     - Pre-processing task to generate orography files. Only needs to be run once per experiment.
   * - make_sfc_climo
     - Pre-processing task to generate surface climatology files. Only needs to be run once per experiment.
   * - get_extrn_ics
     - Cycle-specific task to obtain external data for the initial conditions (ICs)
   * - get_extrn_lbcs
     - Cycle-specific task to obtain external data for the lateral boundary conditions (LBCs)
   * - make_ics_*
     - Generate ICs from the external data
   * - make_lbcs_*
     - Generate LBCs from the external data
   * - run_fcst_*
     - Run the forecast model (UFS Weather Model)
   * - run_post_*
     - Run the post-processing tool (UPP)
   * - integration_test_*
     - Run integration test 
   
In addition to the baseline tasks described in :numref:`Table %s <WorkflowTasksTable>` above, users may choose to run a variety of optional tasks, including plotting and verification tasks. 

.. _PlottingTaskTable:

.. list-table:: Plotting Task in the SRW App
   :widths: 20 50
   :header-rows: 1

   * - Workflow Task
     - Task Description
   * - plot_allvars
     - Run the plotting task and, optionally, the difference plotting task
   
METplus verification tasks are described in :numref:`Table %s <VXWorkflowTasksTable>` below. The column "taskgroup" indicates the taskgroup file that must be included in the user's ``config.yaml`` file under ``rocoto: tasks: taskgroups:`` (see :numref:`Section %s <DefineWorkflow>` for more details). For each task, ``mem###`` refers to either ``mem000`` (if running a deterministic forecast) or a specific forecast member number (if running an ensemble forecast). "Metatasks" indicate task definitions that will become more than one workflow task based on different variables, number of hours, etc., as described in the Task Description column. See :numref:`Section %s <defining_metatasks>` for more details about metatasks.

.. _VXWorkflowTasksTable:

.. list-table:: Verification (VX) Workflow Tasks in the SRW App
   :widths: 20 20 50
   :header-rows: 1

   * - Workflow Task
     - ``taskgroup``
     - Task Description
   * - :bolditalic:`task_get_obs_ccpa`
     - ``verify_pre.yaml``
     - If user has staged :term:`CCPA` data for verification, checks to ensure that data exists in the specified location (``CCPA_OBS_DIR``). If data does not exist, attempts to retrieve that data from NOAA :term:`HPSS`.
   * - :bolditalic:`task_get_obs_ndas`
     - ``verify_pre.yaml``
     - If user has staged :term:`NDAS` data for verification, checks to ensure that data exists in the specified location (``NDAS_OBS_DIR``). If data does not exist, attempts to retrieve that data from NOAA HPSS.
   * - :bolditalic:`task_get_obs_nohrsc`
     - ``verify_pre.yaml``
     - Retrieves and organizes hourly :term:`NOHRSC` data from NOAA HPSS. Can only be run if ``verify_pre.yaml`` is included in a ``tasksgroups`` list *and* user has access to NOAA :term:`HPSS` data. ``ASNOW`` should also be added to the ``VX_FIELDS`` list.
   * - :bolditalic:`task_get_obs_mrms`
     - ``verify_pre.yaml``
     - If user has staged :term:`MRMS` data for verification, checks to ensure that data exists in the specified location (``MRMS_OBS_DIR``). If data does not exist, attempts to retrieve that data from NOAA HPSS.
   * - :bolditalic:`task_run_MET_Pb2nc_obs`
     - ``verify_pre.yaml``
     - Converts files from prepbufr to NetCDF format.
   * - :bolditalic:`metatask_PcpCombine_obs`
     - ``verify_pre.yaml``
     - Derives 3-hr, 6-hr, and 24-hr accumulated precipitation observations from the 1-hr observation files. In log files, tasks will be named like ``MET_PcpCombine_obs_APCP##h``, where ``##h`` is 03h, 06h, or 24h.
   * - :bolditalic:`metatask_check_post_output_all_mems`
     - ``verify_pre.yaml``
     - Ensures that required post-processing tasks have completed and that the output exists in the correct form and location for each forecast member. In log files, tasks will be named like ``check_post_output_mem###``.
   * - :bolditalic:`metatask_PcpCombine_fcst_APCP_all_accums_all_mems`
     - ``verify_pre.yaml``
     - Derives accumulated precipitation forecast for 3-hr, 6-hr, and 24-hr windows for all forecast members based on 1-hr precipitation forecast values. In log files, tasks will be named like ``MET_PcpCombine_fcst_APCP##h_mem###``, where ``##h`` is 03h, 06h, or 24h.
   * - :bolditalic:`metatask_PcpCombine_fcst_ASNOW_all_accums_all_mems`
     - ``verify_pre.yaml``
     - Derives accumulated snow forecast for 6-hr and 24-hr windows for all forecast members based on 1-hr precipitation forecast values. In log files, tasks will be named like ``MET_PcpCombine_fcst_ASNOW##h_mem###``, where ``##h`` is 06h or 24h.
   * - :bolditalic:`metatask_GridStat_CCPA_all_accums_all_mems` 
     - ``verify_det.yaml``
     - Runs METplus grid-to-grid verification for 1-h, 3-h, 6-h, and 24-h (i.e., daily) accumulated precipitation. In log files, tasks will be named like ``run_MET_GridStat_vx_APCP##h_mem###``.
   * - :bolditalic:`metatask_GridStat_NOHRSC_all_accums_all_mems` 
     - ``verify_det.yaml``
     - Runs METplus grid-to-grid verification for 6-h and 24-h (i.e., daily) accumulated snow. In log files, tasks will be named like ``run_MET_GridStat_vx_ASNOW##h_mem###``.
   * - :bolditalic:`metatask_GridStat_MRMS_all_mems`
     - ``verify_det.yaml``
     - Runs METplus grid-to-grid verification for composite reflectivity and :term:`echo top`. In log files, tasks will be named like ``run_MET_GridStat_vx_REFC_mem###`` or ``run_MET_GridStat_vx_RETOP_mem###``.
   * - :bolditalic:`metatask_PointStat_NDAS_all_mems`
     - ``verify_det.yaml``
     - Runs METplus grid-to-point verification for surface and upper-air variables. In log files, tasks will be named like ``run_MET_PointStat_vx_SFC_mem###`` or ``run_MET_PointStat_vx_UPA_mem###``.
   * - :bolditalic:`metatask_GenEnsProd_EnsembleStat_CCPA` :raw-html:`<br/> <br/>`
       (formerly *VX_ENSGRID_##h*)
     - ``verify_ens.yaml``
     - Runs METplus grid-to-grid ensemble verification for 1-h, 3-h, 6-h, and 24-h (i.e., daily) accumulated precipitation. In log files, tasks will be named like ``run_MET_EnsembleStat_vx_APCP##h`` or ``run_MET_GenEnsProd_vx_APCP##h``. Can only be run if ``DO_ENSEMBLE: true`` in ``config.yaml``.
   * - :bolditalic:`metatask_GenEnsProd_EnsembleStat_NOHRSC`
     - ``verify_ens.yaml``
     - Runs METplus grid-to-grid ensemble verification for 6-h and 24-h (i.e., daily) accumulated snow. In log files, tasks will be named like ``run_MET_EnsembleStat_vx_ASNOW##h`` or ``run_MET_GenEnsProd_vx_ASNOW##h``. Can only be run if ``DO_ENSEMBLE: true`` in ``config.yaml``.
   * - :bolditalic:`metatask_GenEnsProd_EnsembleStat_MRMS` :raw-html:`<br/> <br/>`
       (formerly *VX_ENSGRID_[REFC|RETOP]*)
     - ``verify_ens.yaml``
     - Runs METplus grid-to-grid ensemble verification for composite reflectivity and :term:`echo top`. In log files, tasks will be named like ``run_MET_GenEnsProd_vx_[REFC|RETOP]`` or ``run_MET_EnsembleStat_vx_[REFC|RETOP]``. Can only be run if ``DO_ENSEMBLE: true`` in ``config.yaml``. 
   * - :bolditalic:`metatask_GridStat_CCPA_ensmeanprob_all_accums` :raw-html:`<br/> <br/>`
       (formerly *VX_ENSGRID_MEAN_##h* and *VX_ENSGRID_PROB_##h*)
     - ``verify_ens.yaml``
     - Runs METplus grid-to-grid verification for (1) ensemble mean 1-h, 3-h, 6-h, and 24h (i.e., daily) accumulated precipitation and (2) 1-h, 3-h, 6-h, and 24h (i.e., daily) accumulated precipitation probabilistic output. In log files, the ensemble mean subtask will be named like ``run_MET_GridStat_vx_ensmean_APCP##h`` and the ensemble probabilistic output subtask will be named like ``run_MET_GridStat_vx_ensprob_APCP##h``, where ``##h`` is 01h, 03h, 06h, or 24h. Can only be run if ``DO_ENSEMBLE: true`` in ``config.yaml``.
   * - :bolditalic:`metatask_GridStat_NOHRSC_ensmeanprob_all_accums`
     - ``verify_ens.yaml``
     - Runs METplus grid-to-grid verification for (1) ensemble mean 6-h and 24h (i.e., daily) accumulated snow and (2) 6-h and 24h (i.e., daily) accumulated snow probabilistic output. In log files, the ensemble mean subtask will be named like ``run_MET_GridStat_vx_ensmean_ASNOW##h`` and the ensemble probabilistic output subtask will be named like ``run_MET_GridStat_vx_ensprob_ASNOW##h``, where ``##h`` is 06h or 24h. Can only be run if ``DO_ENSEMBLE: true`` in ``config.yaml``.
   * - :bolditalic:`metatask_GridStat_MRMS_ensprob` :raw-html:`<br/> <br/>`
       (formerly *VX_ENSGRID_PROB_[REFC|RETOP]*)
     - ``verify_ens.yaml``
     - Runs METplus grid-to-grid verification for ensemble probabilities for composite reflectivity and :term:`echo top`. In log files, tasks will be named like ``run_MET_GridStat_vx_ensprob_[REFC|RETOP]``. Can only be run if ``DO_ENSEMBLE: true`` in ``config.yaml``.
   * - :bolditalic:`metatask_GenEnsProd_EnsembleStat_NDAS` :raw-html:`<br/> <br/>`
       (formerly *VX_ENSPOINT*)
     - ``verify_ens.yaml``
     - Runs METplus grid-to-point ensemble verification for surface and upper-air variables. In log files, tasks will be named like ``run_MET_GenEnsProd_vx_[SFC|UPA]`` or ``run_MET_EnsembleStat_vx_[SFC|UPA]``. Can only be run if ``DO_ENSEMBLE: true`` in ``config.yaml``.
   * - :bolditalic:`metatask_PointStat_NDAS_ensmeanprob` :raw-html:`<br/> <br/>`
       (formerly *VX_ENSPOINT_[MEAN|PROB]*)
     - ``verify_ens.yaml``
     - Runs METplus grid-to-point verification for (1) ensemble mean surface and upper-air variables and (2) ensemble probabilities for surface and upper-air variables. In log files, tasks will be named like ``run_MET_PointStat_vx_ensmean_[SFC|UPA]`` or ``run_MET_PointStat_vx_ensprob_[SFC|UPA]``. Can only be run if ``DO_ENSEMBLE: true`` in ``config.yaml``.

.. _Run:

Run the Workflow 
=======================

The workflow can be run using the Rocoto workflow manager (see :numref:`Section %s <UseRocoto>`) or using standalone wrapper scripts (see :numref:`Section %s <RunUsingStandaloneScripts>`). 

.. attention::

   If users are running the SRW App on a system that does not have Rocoto installed (e.g., :srw-wiki:`Level 3 & 4 <Supported-Platforms-and-Compilers>` systems, such as many MacOS or generic Linux systems), they should follow the process outlined in :numref:`Section %s <RunUsingStandaloneScripts>`.


.. _UseRocoto:

Run the Workflow Using Rocoto
--------------------------------

The information in this section assumes that Rocoto is available on the desired platform. All official HPC platforms for the UFS SRW App make use of the Rocoto workflow management software for running experiments. However, if Rocoto is not available, it is still possible to run the workflow using stand-alone scripts according to the process outlined in :numref:`Section %s <RunUsingStandaloneScripts>`. 

There are three ways to run the workflow with Rocoto: (1) automation via crontab (2) by calling the ``launch_FV3LAM_wflow.sh`` script, and (3) by manually issuing the ``rocotorun`` command.

.. note::
   Users may find it helpful to review :numref:`Section %s: Rocoto Introductory Information <RocotoInfo>` to gain a better understanding of Rocoto commands and workflow management before continuing, but this is not required to run the experiment. 

Optionally, an environment variable can be set to navigate to the experiment directory (``$EXPTDIR``) more easily. If the login shell is bash, it can be set as follows:

.. code-block:: console

   export EXPTDIR=/path/to/experiment/directory

If the login shell is csh/tcsh, it can instead be set using:

.. code-block:: console

   setenv EXPTDIR /path/to/experiment/directory


.. _Automate:

Automated Option
^^^^^^^^^^^^^^^^^^^

The simplest way to run the Rocoto workflow is to automate the process using a job scheduler such as :term:`Cron`. For automatic resubmission of the workflow at regular intervals (e.g., every 3 minutes), the user can add the following commands to their ``config.yaml`` file *before* generating the experiment (as outlined in :numref:`Section %s <GeneralConfig>`):

.. code-block:: console

   USE_CRON_TO_RELAUNCH: true
   CRON_RELAUNCH_INTVL_MNTS: 3

This will automatically add an appropriate entry to the user's :term:`cron table` and launch the workflow. Alternatively, the user can add a crontab entry manually using the ``crontab -e`` command. As mentioned in :numref:`Section %s <GenerateWorkflow>`, the last line of output from ``./generate_FV3LAM_wflow.py`` (usually starting with ``*/3 * * * *``), can be pasted into the crontab file. It can also be found in the ``$EXPTDIR/log.generate_FV3LAM_wflow`` file. The crontab entry should resemble the following: 

.. code-block:: console

   */3 * * * * cd /path/to/experiment/directory && ./launch_FV3LAM_wflow.sh called_from_cron="TRUE"

where ``/path/to/experiment/directory`` is changed to correspond to the user's ``$EXPTDIR``. The number ``3`` can be changed to a different positive integer; it simply means that the workflow will be resubmitted every three minutes.

.. hint::

   * On NOAA Cloud instances, ``*/1 * * * *`` (or ``CRON_RELAUNCH_INTVL_MNTS: 1``) is the preferred option for cron jobs because compute nodes will shut down if they remain idle too long. If the compute node shuts down, it can take 15-20 minutes to start up a new one. 
   * On other NOAA HPC systems, administrators discourage using ``*/1 * * * *`` due to load problems. ``*/3 * * * *`` (or ``CRON_RELAUNCH_INTVL_MNTS: 3``) is the preferred option for cron jobs on other Level 1 systems.

To check the experiment progress:

.. code-block:: console
   
   cd $EXPTDIR
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Users can track the experiment's progress by reissuing the ``rocotostat`` command above every so often until the experiment runs to completion. The following message usually means that the experiment is still getting set up:

.. code-block:: console
   
   08/04/23 17:34:32 UTC :: FV3LAM_wflow.xml :: ERROR: Can not open FV3LAM_wflow.db read-only because it does not exist

After a few (3-5) minutes, ``rocotostat`` should show a status-monitoring table.

.. _Success:

The workflow run is complete when all tasks have "SUCCEEDED". If everything goes smoothly, users will eventually see a workflow status table similar to the following: 

.. code-block:: console

   CYCLE              TASK                   JOBID         STATE        EXIT STATUS   TRIES   DURATION
   ==========================================================================================================
   201906151800   make_grid                4953154       SUCCEEDED         0          1          5.0
   201906151800   make_orog                4953176       SUCCEEDED         0          1         26.0
   201906151800   make_sfc_climo           4953179       SUCCEEDED         0          1         33.0
   201906151800   get_extrn_ics            4953155       SUCCEEDED         0          1          2.0
   201906151800   get_extrn_lbcs           4953156       SUCCEEDED         0          1          2.0
   201906151800   make_ics_mem000          4953184       SUCCEEDED         0          1         16.0
   201906151800   make_lbcs_mem000         4953185       SUCCEEDED         0          1         71.0
   201906151800   run_fcst_mem000          4953196       SUCCEEDED         0          1       1035.0
   201906151800   run_post_mem000_f000     4953244       SUCCEEDED         0          1          5.0
   201906151800   run_post_mem000_f001     4953245       SUCCEEDED         0          1          4.0
   ...
   201906151800   run_post_mem000_f012     4953381       SUCCEEDED         0          1          7.0
   201906151800   integration_test_mem000     4953237       SUCCEEDED         0          1          7.0

If users choose to run METplus verification tasks as part of their experiment, the output above will include additional lines after ``run_post_mem000_f012``. The output will resemble the following but may be significantly longer when using ensemble verification: 

.. code-block:: console

   CYCLE          TASK                                 JOBID          STATE       EXIT STATUS   TRIES   DURATION
   ================================================================================================================
   201906151800   make_grid                            30466134       SUCCEEDED        0          1          5.0
   ...
   201906151800   run_post_mem000_f012                 30468271       SUCCEEDED        0          1          7.0
   201906151800   get_obs_ccpa                         46903539       SUCCEEDED        0          1          9.0
   201906151800   get_obs_mrms                         46903540       SUCCEEDED        0          1         12.0
   201906151800   get_obs_ndas                         46903541       SUCCEEDED        0          1          9.0
   ...
   201906151800   run_gridstatvx                       30468420       SUCCEEDED        0          1         53.0
   201906151800   run_gridstatvx_refc                  30468421       SUCCEEDED        0          1        934.0
   201906151800   run_gridstatvx_retop                 30468422       SUCCEEDED        0          1       1002.0
   201906151800   run_gridstatvx_03h                   30468491       SUCCEEDED        0          1         43.0
   201906151800   run_gridstatvx_06h                   30468492       SUCCEEDED        0          1         29.0
   201906151800   run_gridstatvx_24h                   30468493       SUCCEEDED        0          1         20.0
   201906151800   run_pointstatvx                      30468423       SUCCEEDED        0          1        670.0
   ...
   201906151800   run_MET_GridStat_vx_APCP01h_mem000      -                   -                   -         -             -
   201906151800   run_MET_GridStat_vx_APCP03h_mem000      -                   -                   -         -             -
   201906151800   run_MET_GridStat_vx_APCP06h_mem000      -                   -                   -         -             -
   201906151800   run_MET_GridStat_vx_REFC_mem000         -                   -                   -         -             -
   201906151800   run_MET_GridStat_vx_RETOP_mem000        -                   -                   -         -             -
   201906151800   run_MET_PointStat_vx_SFC_mem000         -                   -                   -         -             -
   201906151800   run_MET_PointStat_vx_UPA_mem000         -                   -                   -         -             -

After finishing the experiment, open the crontab using ``crontab -e`` and delete the crontab entry.

Launch the Rocoto Workflow Using a Script
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Users who prefer not to automate their experiments can run the Rocoto workflow using the ``launch_FV3LAM_wflow.sh`` script provided. Simply call it without any arguments from the experiment directory: 

.. code-block:: console

   cd $EXPTDIR
   ./launch_FV3LAM_wflow.sh

This script creates a log file named ``log.launch_FV3LAM_wflow`` in ``$EXPTDIR`` or appends information to the file if it already exists. The launch script also creates the ``log/FV3LAM_wflow.log`` file, which shows Rocoto task information. Check the end of the log file periodically to see how the experiment is progressing:

.. code-block:: console

   tail -n 40 log.launch_FV3LAM_wflow

In order to launch additional tasks in the workflow, call the launch script again; this action will need to be repeated until all tasks in the workflow have been launched. To (re)launch the workflow and check its progress on a single line, run: 

.. code-block:: console

   ./launch_FV3LAM_wflow.sh; tail -n 40 log.launch_FV3LAM_wflow

This will output the last 40 lines of the log file, which lists the status of the workflow tasks (e.g., SUCCEEDED, DEAD, RUNNING, SUBMITTING, QUEUED). The number 40 can be changed according to the user's preferences. The output will look similar to this:

.. code-block:: console

   CYCLE                          TASK                       JOBID        STATE   EXIT STATUS   TRIES  DURATION
   ======================================================================================================
   201906151800              make_grid         druby://hfe01:33728   SUBMITTING             -       0       0.0
   201906151800              make_orog                           -            -             -       -         -
   201906151800         make_sfc_climo                           -            -             -       -         -
   201906151800          get_extrn_ics         druby://hfe01:33728   SUBMITTING             -       0       0.0
   201906151800         get_extrn_lbcs         druby://hfe01:33728   SUBMITTING             -       0       0.0
   201906151800        make_ics_mem000                           -            -             -       -         -
   201906151800       make_lbcs_mem000                           -            -             -       -         -
   201906151800        run_fcst_mem000                           -            -             -       -         -
   201906151800   run_post_mem000_f000                           -            -             -       -         -
   201906151800   run_post_mem000_f001                           -            -             -       -         -
   201906151800   run_post_mem000_f002                           -            -             -       -         -
   201906151800   run_post_mem000_f003                           -            -             -       -         -
   201906151800   run_post_mem000_f004                           -            -             -       -         -
   201906151800   run_post_mem000_f005                           -            -             -       -         -
   201906151800   run_post_mem000_f006                           -            -             -       -         -
   201906151800   integration_test_mem000

   Summary of workflow status:
   ~~~~~~~~~~~~~~~~~~~~~~~~~~

     0 out of 1 cycles completed.
     Workflow status:  IN PROGRESS

If all the tasks complete successfully, the "Workflow status" at the bottom of the log file will change from "IN PROGRESS" to "SUCCESS". If certain tasks could not complete, the "Workflow status" will instead change to "FAILURE". Error messages for each task can be found in the task log files located in ``$EXPTDIR/log``. Users can look at the log file for a failed task to determine what caused the failure. For example, if the ``make_grid`` task failed, users can open the ``make_grid.log`` file to see what caused the problem: 

.. code-block:: console

   cd $EXPTDIR/log
   vi make_grid.log

After making any required changes, users can restart a DEAD or failed task as described in :numref:`Section %s of the FAQ <RestartTask>`.

The workflow run is complete when all tasks have "SUCCEEDED", and the ``rocotostat`` command outputs a table similar to the one :ref:`above <Success>`.


.. _RocotoManualRun:

Launch the Rocoto Workflow Manually
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Load Rocoto**

Instead of running the ``./launch_FV3LAM_wflow.sh`` script, users can load Rocoto and any other required modules manually. This gives the user more control over the process and allows them to view experiment progress more easily. On Level 1 systems, the Rocoto modules are loaded automatically in :numref:`Step %s <SetUpPythonEnv>`. For most other systems, users can load a modified ``wflow_<platform>`` modulefile, or they can use a variant on the following commands to load the Rocoto module:

.. code-block:: console

   module use <path_to_rocoto_package>
   module load rocoto

Some systems may require a version number (e.g., ``module load rocoto/1.3.3``)

**Run the Rocoto Workflow**

After loading Rocoto, ``cd`` to the experiment directory and call ``rocotorun`` to launch the workflow tasks. This will start any tasks that are not awaiting completion of a dependency. As the workflow progresses through its stages, ``rocotostat`` will show the state of each task and allow users to monitor progress:

.. code-block:: console

   cd $EXPTDIR
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

The ``rocotorun`` and ``rocotostat`` commands above will need to be resubmitted regularly and repeatedly until the experiment is finished. In part, this is to avoid having the system time out. This also ensures that when one task ends, tasks dependent on it will run as soon as possible, and ``rocotostat`` will capture the new progress. 

If the experiment fails, the ``rocotostat`` command will indicate which task failed. Users can look at the log file in the ``log`` subdirectory for the failed task to determine what caused the failure. For example, if the ``make_grid`` task failed, users can open the ``make_grid.log`` file to see what caused the problem: 

.. code-block:: console

   cd $EXPTDIR/log
   vi make_grid.log

.. note::
   
   If users have the `Slurm workload manager <https://slurm.schedmd.com/documentation.html>`__ on their system, they can run the ``squeue`` command in lieu of ``rocotostat`` to check what jobs are currently running. 


.. _RunUsingStandaloneScripts:

Run the Workflow Using Stand-Alone Scripts
---------------------------------------------

The SRW App workflow can be run using standalone shell scripts in cases where the Rocoto software is not available on a given platform. If Rocoto *is* available, see :numref:`Section %s <UseRocoto>` to run the workflow using Rocoto. 

.. attention:: 

   When working on an HPC system, users should allocate compute nodes prior to running their experiment. The proper command will depend on the system's resource manager, but some guidance is offered in :numref:`Section %s <allocate-compute-node>`. It may be necessary to reload the ``build_<platform>_<compiler>`` scripts (see :numref:`Section %s <CMakeApproach>`) and the workflow environment (see :numref:`Section %s <SetUpPythonEnv>`) after allocating compute nodes.

.. note::
   Examples in this subsection presume that the user is running in the Terminal with a bash shell environment. If this is not the case, users will need to adjust the commands to fit their command line application and shell environment. 

#. ``cd`` into the experiment directory. For example, from ``ush``, presuming default directory settings:

   .. code-block:: console
      
      cd ../../expt_dirs/test_community

#. Set the environment variable ``$EXPTDIR``:

   .. code-block:: console

      export EXPTDIR=`pwd`

#. Copy the wrapper scripts from the ``ush`` directory into the experiment directory. Each workflow task has a wrapper script that sets environment variables and runs the job script.

   .. code-block:: console

      cp /path/to/ufs-srweather-app/ush/wrappers/* .

#. Set the ``OMP_NUM_THREADS`` variable. 

   .. code-block:: console

      export OMP_NUM_THREADS=1

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
      ./run_integration_test.sh

Each task should finish with error code 0. For example: 

.. code-block:: console
   
   End exregional_get_extrn_mdl_files.sh at Wed Nov 16 18:08:19 UTC 2022 with error code 0 (time elapsed: 00:00:01)

Check the batch script output file in your experiment directory for a “SUCCESS” message near the end of the file.

.. _RegionalWflowTasks:

.. table::  List of tasks in the SRW App workflow in the order that they are executed.
            Scripts with the same stage number may be run simultaneously. The number of
            processors and wall clock time is a good starting point for NOAA HPC systems
            when running a 48-h forecast on the 25-km CONUS domain. For a brief description of tasks, see :numref:`Table %s <WorkflowTasksTable>`. 

   +------------+--------------------------+----------------+----------------------------+
   | **Stage/** | **Task Run Script**      | **Number of**  | **Wall Clock Time (H:mm)** |
   |            |                          | **Processors** |                            |             
   +============+==========================+================+============================+
   | 1          | run_get_ics.sh           | 1              | 0:20 (depends on HPSS vs   |
   |            |                          |                | FTP vs staged-on-disk)     |
   +------------+--------------------------+----------------+----------------------------+
   | 1          | run_get_lbcs.sh          | 1              | 0:20 (depends on HPSS vs   |
   |            |                          |                | FTP vs staged-on-disk)     |
   +------------+--------------------------+----------------+----------------------------+
   | 1          | run_make_grid.sh         | 24             | 0:20                       |
   +------------+--------------------------+----------------+----------------------------+
   | 2          | run_make_orog.sh         | 24             | 0:20                       |
   +------------+--------------------------+----------------+----------------------------+
   | 3          | run_make_sfc_climo.sh    | 48             | 0:20                       |
   +------------+--------------------------+----------------+----------------------------+
   | 4          | run_make_ics.sh          | 48             | 0:30                       |
   +------------+--------------------------+----------------+----------------------------+
   | 4          | run_make_lbcs.sh         | 48             | 0:30                       |
   +------------+--------------------------+----------------+----------------------------+
   | 5          | run_fcst.sh              | 48             | 0:30                       |
   +------------+--------------------------+----------------+----------------------------+
   | 6          | run_post.sh              | 48             | 0:25 (2 min per output     |
   |            |                          |                | forecast hour)             |
   +------------+--------------------------+----------------+----------------------------+
   | 7          | run_integration_test.sh  | 1              | 0:05                       |
   +------------+--------------------------+----------------+----------------------------+

Users can access log files for specific tasks in the ``$EXPTDIR/log`` directory. To see how the experiment is progressing, users can also check the end of the ``log.launch_FV3LAM_wflow`` file from the command line:

.. code-block:: console

   tail -n 40 log.launch_FV3LAM_wflow

.. hint:: 
   If any of the scripts return an error that "Primary job terminated normally, but one process returned a non-zero exit code," there may not be enough space on one node to run the process. On an HPC system, the user will need to allocate a(nother) compute node. The process for doing so is system-dependent, and users should check the documentation available for their HPC system. Instructions for allocating a compute node on NOAA HPC systems can be viewed in :numref:`Section %s <allocate-compute-node>` as an example.

.. note::
   On most HPC systems, users will need to submit a batch job to run multi-processor jobs. On some HPC systems, users may be able to run the first two jobs (serial) on a login node/command-line. Example scripts for Slurm (Hera) and PBS (Cheyenne) resource managers are provided (``sq_job.sh`` and ``qsub_job.sh``, respectively). These examples will need to be adapted to each user's system. Alternatively, some batch systems allow users to specify most of the settings on the command line (with the ``sbatch`` or ``qsub`` command, for example). 

.. COMMENT: Test manual run section. 
