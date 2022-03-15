.. _SRWAppOverview:

===========================================================
Overview of the Short-Range Weather Application Workflow
===========================================================


.. _WorkflowTaskDescription:

Description of Workflow Tasks
-----------------------------
Workflow tasks are specified in the ``FV3LAM_wflow.xml`` file and illustrated in :numref:`Figure %s <WorkflowTasksFig>`. Each task is described in :numref:`Table %s <WorkflowTasksTable>`. The first three pre-processing tasks; ``MAKE_GRID``, ``MAKE_OROG``, and ``MAKE_SFC_CLIMO`` are optional. If the user stages pre-generated grid, orography, and surface climatology fix files, these three tasks can be skipped by setting ``RUN_TASK_MAKE_GRID=”FALSE”``, ``RUN_TASK_MAKE_OROG=”FALSE”``, and ``RUN_TASK_MAKE_SFC_CLIMO=”FALSE”`` in the ``regional_workflow/ush/config.sh`` file before running the ``generate_FV3LAM_wflow.sh`` script. As shown in the figure, the ``FV3LAM_wflow.xml`` file runs the specific j-job scripts in the prescribed order (``regional_workflow/jobs/JREGIONAL_[task name]``) when the ``launch_FV3LAM_wflow.sh`` is submitted. Each j-job task has its own source script named ``exregional_[task name].sh`` in the ``regional_workflow/scripts`` directory. Two database files ``FV3LAM_wflow.db`` and ``FV3LAM_wflow_lock.db`` are generated and updated by the Rocoto calls. There is usually no need for users to modify these files. To relaunch the workflow from scratch, delete these two ``*.db`` files and then call the launch script repeatedly for each task. 

.. _WorkflowTasksFig:

.. figure:: _static/FV3LAM_wflow_flowchart.png

    *Flowchart of the workflow tasks*

.. _WorkflowTasksTable:

.. table::  Workflow tasks in SRW App

   +----------------------+------------------------------------------------------------+
   | **Workflow Task**    | **Task Description**                                       |
   +======================+============================================================+
   | make_grid            | Pre-processing task to generate regional grid files. Can   |
   |                      | be run, at most, once per experiment.                      |
   +----------------------+------------------------------------------------------------+
   | make_orog            | Pre-processing task to generate orography files. Can be    |
   |                      | run, at most, once per experiment.                         |
   +----------------------+------------------------------------------------------------+
   | make_sfc_climo       | Pre-processing task to generate surface climatology files. |
   |                      | Can be run, at most, once per experiment.                  |
   +----------------------+------------------------------------------------------------+
   | get_extrn_ics        | Cycle-specific task to obtain external data for the        |
   |                      | initial conditions                                         |
   +----------------------+------------------------------------------------------------+
   | get_extrn_lbcs       | Cycle-specific task to obtain external data for the        |
   |                      | lateral boundary (LB) conditions                           |
   +----------------------+------------------------------------------------------------+
   | make_ics             | Generate initial conditions from the external data         |
   +----------------------+------------------------------------------------------------+
   | make_lbcs            | Generate lateral boundary conditions from the external data|
   +----------------------+------------------------------------------------------------+
   | run_fcst             | Run the forecast model (UFS weather model)                 |
   +----------------------+------------------------------------------------------------+
   | run_post             | Run the post-processing tool (UPP)                         |
   +----------------------+------------------------------------------------------------+

Launch of Workflow
==================
There are two ways to launch the workflow using Rocoto: (1) with the ``launch_FV3LAM_wflow.sh``
script, and (2) manually calling the ``rocotorun`` command. Moreover, you can run the workflow
separately using stand-alone scripts.

An environment variable may be set to navigate to the ``$EXPTDIR`` more easily. If the login
shell is bash, it can be set as follows:

.. code-block:: console

   export EXPTDIR=/path-to-experiment/directory

Or if the login shell is csh/tcsh, it can be set using:

.. code-block:: console

   setenv EXPTDIR /path-to-experiment/directory

Launch with the ``launch_FV3LAM_wflow.sh`` script
-------------------------------------------------
To launch the ``launch_FV3LAM_wflow.sh`` script, simply call it without any arguments as follows:

.. code-block:: console

   cd ${EXPTDIR}
   ./launch_FV3LAM_wflow.sh

This script creates a log file named ``log.launch_FV3LAM_wflow`` in the EXPTDIR directory
(described in :numref:`Section %s <ExperimentDirSection>`) or appends to it if it already exists.
You can check the contents of the end of the log file (e.g. last 30 lines) using the command:

.. code-block:: console

   tail -n 30 log.launch_FV3LAM_wflow

This command will print out the status of the workflow tasks as follows:

.. code-block:: console

   CYCLE                    TASK                       JOBID        STATE   EXIT STATUS   TRIES  DURATION
   ======================================================================================================
   202006170000        make_grid         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000        make_orog                           -            -             -       -         -
   202006170000   make_sfc_climo                           -            -             -       -         -
   202006170000    get_extrn_ics         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000   get_extrn_lbcs         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000         make_ics                           -            -             -       -         -
   202006170000        make_lbcs                           -            -             -       -         -
   202006170000         run_fcst                           -            -             -       -         -
   202006170000      run_post_00                           -            -             -       -         -
   202006170000      run_post_01                           -            -             -       -         -
   202006170000      run_post_02                           -            -             -       -         -
   202006170000      run_post_03                           -            -             -       -         -
   202006170000      run_post_04                           -            -             -       -         -
   202006170000      run_post_05                           -            -             -       -         -
   202006170000      run_post_06                           -            -             -       -         -

   Summary of workflow status:
   ~~~~~~~~~~~~~~~~~~~~~~~~~~

     0 out of 1 cycles completed.
     Workflow status:  IN PROGRESS

Error messages for each task can be found in the task log files located in the ``EXPTDIR/log`` directory. In order to launch more tasks in the workflow, you just need to call the launch script again:

.. code-block:: console

   ./launch_FV3LAM_wflow

If everything goes smoothly, you will eventually get the following workflow status table as follows:

.. code-block:: console

   CYCLE                    TASK                       JOBID        STATE   EXIT STATUS   TRIES  DURATION
   ======================================================================================================
   202006170000        make_grid                     8854765    SUCCEEDED             0       1       6.0
   202006170000        make_orog                     8854809    SUCCEEDED             0       1      27.0
   202006170000   make_sfc_climo                     8854849    SUCCEEDED             0       1      36.0
   202006170000    get_extrn_ics                     8854763    SUCCEEDED             0       1      54.0
   202006170000   get_extrn_lbcs                     8854764    SUCCEEDED             0       1      61.0
   202006170000         make_ics                     8854914    SUCCEEDED             0       1     119.0
   202006170000        make_lbcs                     8854913    SUCCEEDED             0       1      98.0
   202006170000         run_fcst                     8854992    SUCCEEDED             0       1     655.0
   202006170000      run_post_00                     8855459    SUCCEEDED             0       1       6.0
   202006170000      run_post_01                     8855460    SUCCEEDED             0       1       6.0
   202006170000      run_post_02                     8855461    SUCCEEDED             0       1       6.0
   202006170000      run_post_03                     8855462    SUCCEEDED             0       1       6.0
   202006170000      run_post_04                     8855463    SUCCEEDED             0       1       6.0
   202006170000      run_post_05                     8855464    SUCCEEDED             0       1       6.0
   202006170000      run_post_06                     8855465    SUCCEEDED             0       1       6.0

If all the tasks complete successfully, the workflow status in the log file will include the word “SUCCESS."
Otherwise, the workflow status will include the word “FAILURE."

Manually launch by calling the ``rocotorun`` command
----------------------------------------------------
To launch the workflow manually, the ``rocoto`` module should be loaded:

.. code-block:: console

   module use rocoto
   module load rocoto

Then, launch the workflow:

.. code-block:: console

   cd ${EXPTDIR}
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10 

To check the status of the workflow, issue a ``rocotostat`` command:

.. code-block:: console

   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Wait a few seconds and issue a second set of ``rocotorun`` and ``rocotostat`` commands:

.. code-block:: console

   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10 
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10



