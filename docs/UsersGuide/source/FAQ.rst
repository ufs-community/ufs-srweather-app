.. _FAQ:
  
***
FAQ
***

=========================================================
How do I turn On/Off the Cycle-Independent Workflow Tasks
=========================================================
The first three pre-processing tasks ``make_grid``, ``make_orog``, and ``make_sfc_climo``
are cycle-independent, meaning that they only need to be run once per experiment. If the
pre-generated grid, orography, and surface climatology fix files exist, these three tasks can
be skipped by setting:

.. code-block:: console

   RUN_TASK_MAKE_GRID=”FALSE”
   RUN_TASK_MAKE_OROG=”FALSE”
   RUN_TASK_MAKE_SFC_CLIMO=”FALSE”

in the ``config.sh`` script before running the ``generate_FV3LAM_wflow.sh`` script.  By default,
these flags are set to ``TRUE`` in ``config_defaults.sh``.

===================================
How do I define an experiment name?
===================================
The name of the experiment is set in the ``config.sh`` file using the variable ``EXPT_SUBDIR``.
See :numref:`Section %s <SetUpConfigFile>` for more details.

================================================
How do I change the Suite Definition File (SDF)?
================================================
The SDF is set in the ``config.sh`` file using the variable ``CCPP_PHYS_SUITE``.  When the
``generate_FV3LAM_wflow.sh`` script is run, the SDF file is copied from its location in the forecast
model directory to the experiment directory ``EXPTDIR``.

=============================
How do I restart a DEAD task?
=============================
On platforms that utilize Rocoto workflow software (such as NCAR’s Cheyenne machine), sometimes if
something goes wrong with the workflow a task may end up in the DEAD state:

.. code-block:: console

   rocotostat -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
          CYCLE            TASK        JOBID    STATE    EXIT STATUS  TRIES DURATION
   =================================================================================
   201905200000       make_grid      9443237   QUEUED              -      0      0.0
   201905200000       make_orog            -        -              -      -        -
   201905200000  make_sfc_climo            -        -              -      -        -
   201905200000   get_extrn_ics      9443293     DEAD            256      3      5.0

This means that the dead task has not completed successfully, so the workflow has stopped. Once the issue
has been identified and fixed (by referencing the log files), the failed task can re-run using the ``rocotorewind``
command:

.. code-block:: console

   rocotorewind -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10 -c 201905200000 -t get_extrn_ics

where ``-c`` specifies the cycle date (first column of rocotostat output) and ``-t`` represents the task name
(second column of rocotostat output).  After using ``rocotorewind``, the next time ``rocotorun`` is used to
advance the workflow, the job will be resubmitted.

===========================
How do I change the grid?
===========================
To change the predefined grid, you need to modify the ``PREDEF_GRID_NAME`` variable in the
``config.sh`` script which the user has created to generate an experiment configuration and workflow.
Users can choose from one of three predefined grids for the SRW Application:

.. code-block:: console

   RRFS_CONUS_3km
   RRFS_CONUS_13km
   RRFS_CONUS_25km

An option also exists to create a user-defined grid, with information available in
:numref:`Chapter %s <LAMGrids>`.

