.. _FAQ:
  
****
FAQ
****

* :ref:`How do I define an experiment name? <DefineExptName>`
* :ref:`How do I change the Physics Suite Definition File (SDF)? <ChangePhysics>`
* :ref:`How do I change the grid? <ChangeGrid>`
* :ref:`How do I turn on/off the cycle-independent workflow tasks? <CycleInd>`
* :ref:`How do I know if I correctly modified config.yaml? <CorrectConfig>`
* :ref:`How do I restart a DEAD task? <RestartTask>`
* :ref:`How can I clean up the SRW App code if something went wrong? <CleanUp>`
* :ref:`How do I run a new experiment? <NewExpt>`

.. _DefineExptName:

====================================
How do I define an experiment name?
====================================

The name of the experiment is set in the ``workflow:`` section of the ``config.yaml`` file using the variable ``EXPT_SUBDIR``.
See :numref:`Section %s <UserSpecificConfig>` and/or :numref:`Section %s <DirParams>` for more details.

.. _ChangePhysics:

=========================================================
How do I change the Physics Suite Definition File (SDF)?
=========================================================

The SDF is set in the ``workflow:`` section of the ``config.yaml`` file using the variable ``CCPP_PHYS_SUITE``. The four supported physics suites for the SRW Application as of the v2.1.0 release are:

.. code-block:: console
   
   FV3_GFS_v16
   FV3_RRFS_v1beta
   FV3_HRRR
   FV3_WoFS_v0

When users run the ``generate_FV3LAM_wflow.py`` script, the SDF file is copied from its location in the forecast
model directory to the experiment directory ``$EXPTDIR``. For more information on the :term:`CCPP` physics suite parameters, see :numref:`Section %s <CCPP_Params>`.

.. _ChangeGrid:

===========================
How do I change the grid?
===========================

To change the predefined grid, modify the ``PREDEF_GRID_NAME`` variable in the ``task_run_fcst:`` section of the ``config.yaml`` script (see :numref:`Section %s <UserSpecificConfig>` for details on creating and modifying the ``config.yaml`` file). The four supported predefined grids as of the SRW Application v2.1.0 release are:

.. code-block:: console
   
   RRFS_CONUS_3km
   RRFS_CONUS_13km
   RRFS_CONUS_25km
   SUBCONUS_Ind_3km

However, users can choose from a variety of predefined grids listed in :numref:`Section %s <PredefGrid>`. An option also exists to create a user-defined grid, with information available in :numref:`Chapter %s <UserDefinedGrid>`. However, the user-defined grid option is not fully supported as of the v2.1.0 release and is provided for informational purposes only. 

.. _CycleInd:

===========================================================
How do I turn on/off the cycle-independent workflow tasks?
===========================================================

The first three pre-processing tasks ``make_grid``, ``make_orog``, and ``make_sfc_climo``
are :term:`cycle-independent`, meaning that they only need to be run once per experiment. If the
grid, orography, and surface climatology files that these tasks generate are already 
available (e.g., from a previous experiment that used the same grid as the current experiment), then
these tasks can be skipped, and the workflow can use those pre-generated files. This 
can be done by adding the following parameters to the appropriate sections of the ``config.yaml`` script before running ``generate_FV3LAM_wflow.py``:

.. code-block:: console

   workflow_switches:
      RUN_TASK_MAKE_GRID: false
      RUN_TASK_MAKE_OROG: false
      RUN_TASK_MAKE_SFC_CLIMO: false
   task_make_grid:
      GRID_DIR: /path/to/directory/containing/grid/files
   task_make_orog:
      OROG_DIR: /path/to/directory/containing/orography/files
   task_make_sfc_climo:
      SFC_CLIMO_DIR: /path/to/directory/containing/surface/climatology/files
   
The ``RUN_TASK_MAKE_GRID``, ``RUN_TASK_MAKE_OROG``, and ``RUN_TASK_MAKE_SFC_CLIMO`` flags disable their respective tasks. ``GRID_DIR``, ``OROG_DIR``, and ``SFC_CLIMO_DIR``
specify the directories where pre-generated grid, orography, and surface climatology files are located (all
three sets of files *may* be placed in the same directory location). By default, the ``RUN_TASK_MAKE_*`` 
flags are set to true in ``config_defaults.yaml``. This means that the workflow will
run the ``make_grid``, ``make_orog``, and ``make_sfc_climo`` tasks by default.

.. _CorrectConfig:

=========================================================
How do I know if I correctly modified ``config.yaml``?
=========================================================

To determine whether ``config.yaml`` file adjustments are valid, users can run the following script from the ``ush`` directory after loading the regional workflow:

.. code-block:: console

   ./config_utils.py -c $PWD/config.yaml -v $PWD/config_defaults.yaml

A correct ``config.yaml`` file will output a ``SUCCESS`` message. A ``config.yaml`` file with problems will output a ``FAILURE`` message describing the problem. For example:

.. code-block:: console
   
   INVALID ENTRY: EXTRN_MDL_FILES_ICS=[]
   FAILURE

.. _RestartTask:

=============================
How do I restart a DEAD task?
=============================

On platforms that utilize Rocoto workflow software (such as NCAR's Cheyenne machine), if something goes wrong with the workflow, a task may end up in the DEAD state:

.. code-block:: console

   rocotostat -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
          CYCLE            TASK        JOBID    STATE    EXIT STATUS  TRIES DURATION
   =================================================================================
   201906151800       make_grid      9443237   QUEUED              -      0      0.0
   201906151800       make_orog            -        -              -      -        -
   201906151800  make_sfc_climo            -        -              -      -        -
   201906151800   get_extrn_ics      9443293     DEAD            256      3      5.0

This means that the dead task has not completed successfully, so the workflow has stopped. Once the issue
has been identified and fixed (by referencing the log files in ``$EXPTDIR/log``), users can re-run the failed task using the ``rocotorewind`` command:

.. code-block:: console

   rocotorewind -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10 -c 201906151800 -t get_extrn_ics

where ``-c`` specifies the cycle date (first column of rocotostat output) and ``-t`` represents the task name
(second column of rocotostat output). After using ``rocotorewind``, the next time ``rocotorun`` is used to
advance the workflow, the job will be resubmitted.

.. _CleanUp:

===============================================================
How can I clean up the SRW App code if something went wrong?
===============================================================

The ``ufs-srweather-app`` repository contains a ``devclean.sh`` convenience script. This script can be used to clean up code if something goes wrong when checking out externals or building the application. To view usage instructions and to get help, run with the ``-h`` flag:

.. code-block:: console
   
   ./devclean.sh -h

To remove the ``build`` directory, run:

.. code-block:: console
   
   ./devclean.sh --remove

To remove all build artifacts (including ``build``, ``exec``, ``lib``, and ``share``), run: 

.. code-block:: console
   
   ./devclean.sh --clean
   OR
   ./devclean.sh -a

To remove external submodules, run: 

.. code-block:: console
   
   ./devclean.sh --sub-modules

Users will need to check out the external submodules again before building the application. 

In addition to the options above, many standard terminal commands can be run to remove unwanted files and directories (e.g., ``rm -rf expt_dirs``). A complete explanation of these options is beyond the scope of this User's Guide. 

.. _NewExpt:

==================================
How can I run a new experiment?
==================================

To run a new experiment at a later time, users need to rerun the commands in :numref:`Section %s <SetUpPythonEnv>` that reactivate the regional workflow python environment: 

.. code-block:: console
   
   source <path/to/etc/lmod-setup.sh/or/lmod-setup.csh> <platform>
   module use <path/to/modulefiles>
   module load wflow_<platform>

Follow any instructions output by the console. 

Then, users can configure a new experiment by updating the environment variables in ``config.yaml`` to reflect the desired experiment configuration. Detailed instructions can be viewed in :numref:`Section %s <UserSpecificConfig>`. Parameters and valid values are listed in :numref:`Chapter %s <ConfigWorkflow>`. After adjusting the configuration file, generate the new experiment by running ``./generate_FV3LAM_wflow.py``. Check progress by navigating to the ``$EXPTDIR`` and running ``rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10``.
