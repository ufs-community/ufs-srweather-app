.. _FAQ:
  
****
FAQ
****

* :ref:`How do I turn on/off the cycle-independent workflow tasks? <CycleInd>`
* :ref:`How do I define an experiment name? <DefineExptName>`
* :ref:`How do I change the Physics Suite Definition File (SDF)? <ChangePhysics>`
* :ref:`How do I restart a DEAD task? <RestartTask>`
* :ref:`How do I change the grid? <ChangeGrid>`

.. _CycleInd:

===========================================================
How do I turn on/off the cycle-independent workflow tasks?
===========================================================

The first three pre-processing tasks ``make_grid``, ``make_orog``, and ``make_sfc_climo``
are :term:`cycle-independent`, meaning that they only need to be run once per experiment. If the
grid, orography, and surface climatology files that these tasks generate are already 
available (e.g., from a previous experiment that used the same grid as the current experiment), then
these tasks can be skipped, and the workflow can use those pre-generated files. This 
can be done by adding the following lines to the ``config.sh`` script before running 
the ``generate_FV3LAM_wflow.sh`` script:

.. code-block:: console

   RUN_TASK_MAKE_GRID="FALSE"
   GRID_DIR="/path/to/directory/containing/grid/files"
   RUN_TASK_MAKE_OROG="FALSE"
   OROG_DIR="/path/to/directory/containing/orography/files"
   RUN_TASK_MAKE_SFC_CLIMO="FALSE"
   SFC_CLIMO_DIR="/path/to/directory/containing/surface/climatology/files"

The ``RUN_TASK_MAKE_GRID``, ``RUN_TASK_MAKE_OROG``, and ``RUN_TASK_MAKE_SFC_CLIMO`` flags
disable their respective tasks. ``GRID_DIR``, ``OROG_DIR``, and ``SFC_CLIMO_DIR``
specify the directories where pre-generated grid, orography, and surface climatology files are located (all
three sets of files *may* be placed in the same directory location). By default, the ``RUN_TASK_MAKE_*`` 
flags are set to ``TRUE`` in ``config_defaults.sh``. This means that the workflow will
run the ``make_grid``, ``make_orog``, and ``make_sfc_climo`` tasks by default.

.. _DefineExptName:

===================================
How do I define an experiment name?
===================================

The name of the experiment is set in the ``config.sh`` file using the variable ``EXPT_SUBDIR``.
See :numref:`Section %s <UserSpecificConfig>` and/or :numref:`Section %s <DirParams>` for more details.


.. _ChangePhysics:

=========================================================
How do I change the Physics Suite Definition File (SDF)?
=========================================================

The SDF is set in the ``config.sh`` file using the variable ``CCPP_PHYS_SUITE``.  When users run the
``generate_FV3LAM_wflow.sh`` script, the SDF file is copied from its location in the forecast
model directory to the experiment directory ``EXPTDIR``. For more information on the :term:`CCPP` physics suite parameters, see :numref:`Section %s <CCPP_Params>`

.. _RestartTask:

=============================
How do I restart a DEAD task?
=============================

On platforms that utilize Rocoto workflow software (such as NCAR’s Cheyenne machine), if
something goes wrong with the workflow, a task may end up in the DEAD state:

.. code-block:: console

   rocotostat -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
          CYCLE            TASK        JOBID    STATE    EXIT STATUS  TRIES DURATION
   =================================================================================
   201905200000       make_grid      9443237   QUEUED              -      0      0.0
   201905200000       make_orog            -        -              -      -        -
   201905200000  make_sfc_climo            -        -              -      -        -
   201905200000   get_extrn_ics      9443293     DEAD            256      3      5.0

This means that the dead task has not completed successfully, so the workflow has stopped. Once the issue
has been identified and fixed (by referencing the log files), users can re-run the failed task using the ``rocotorewind`` command:

.. code-block:: console

   rocotorewind -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10 -c 201905200000 -t get_extrn_ics

where ``-c`` specifies the cycle date (first column of rocotostat output) and ``-t`` represents the task name
(second column of rocotostat output). After using ``rocotorewind``, the next time ``rocotorun`` is used to
advance the workflow, the job will be resubmitted.

.. _ChangeGrid:

===========================
How do I change the grid?
===========================

To change the predefined grid, modify the ``PREDEF_GRID_NAME`` variable in the ``config.sh`` script (see :numref:`Section %s <UserSpecificConfig>` for details on creating and modifying the ``config.sh`` file). The four supported predefined grids for the SRW Application v2.0.0 release were:

.. code-block:: console

   RRFS_CONUS_3km
   RRFS_CONUS_13km
   RRFS_CONUS_25km
   SUBCONUS_Ind_3km

However, users can choose from a variety of predefined grids listed in :numref:`Section %s <PredefGrid>`. An option also exists to create a user-defined grid, with information available in :numref:`Chapter %s <UserDefinedGrid>`. However, the user-defined grid option is not fully-supported for this release and is provided for informational purposes only. 

