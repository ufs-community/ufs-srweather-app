.. _config_regional_workflow:

***************************************
Configuring the FV3SAR Workflow
***************************************

The following steps describe how to create a user-specific configuration
file in order to run your experiment in a given environment.

1. Create a user-specific configuration file named ``config.sh`` in the subdirectory
   ``ush`` under the ``$BASEDIR/regional_workflow`` directory containing appropriate
   variable settings for your environment, experiment, etc.

   A configuration file named ``config_defaults.sh`` containing default values already
   exists in the ``ush`` subdirectory (this file is part of the ``regional_workflow`` 
   repository).  The setup script (called ``setup.sh`` and located in ``ush``) that
   will be called in the workflow generation step below first sources ``config_defaults.sh``
   and then sources ``config.sh`` if the latter exists.  Thus, any settings in ``config.sh``
   will overwrite the ones in ``config_defaults.sh``.

   Instead of creating a ``config.sh`` script with custom settings, a user can directly
   modify the variable settings in ``config_defaults.sh``.  However, we do not recommend
   this approach because if this file is then pushed to the remote ``regional_workflow``
   repository, that repository will contain in its copy of ``config_defaults.sh`` variable
   settings that are specific to your environment and/or experiment.  If others then pull
   from this repository, they will inherit these settings, but these settings will likely
   not be appropriate for their environment and/or experiment.  To avoid this situation,
   we’ve designed the setup script to read in the local configuration file ``config.sh``
   that users can (and should) create locally in the ush directory and which should remain
   out of the repository.  We use ``config_defaults.sh`` to document the variables, setting
   them to dummy/placeholder values that will be overwritten by the settings in ``config.sh``.

   For the experiment(s) we will run, we do not need to include in ``config.sh`` all the
   variables defined in ``config_defaults.sh``; we only need to include the most relevant
   ones (the rest will keep their settings in ``config_default.sh``).  Thus, include in your
   ``config.sh`` the following variable settings:

.. code-block:: console

   #
   MACHINE="THEIA"
   ACCOUNT="gsd-fv3"
   QUEUE_DEFAULT="debug"
   QUEUE_HPSS="service"
   QUEUE_RUN_FV3SAR="batch"
   #
   BASEDIR="/path/to/directory/of/regional_workflow/and/NEMSfv3gfs/clones"
   TMPDIR="/path/to/temporary/work/directories"
   UPPDIR="/path/to/UPP/executable/directory"
   CCPP="false"
   #
   CDATE="2018060400"
   #
   fcst_len_hrs="6"
   BC_update_intvl_hrs="6"
   #
   run_title="my_test"
   #
   #predef_domain="RAP"
   predef_domain="HRRR"
   #
   if [ "$predef_domain" = "RAP" ]; then
     layout_x="14"  # One possibility: 14 for RAP, 20 for HRRR.
     layout_y="14"  # One possibility: 14 for RAP, 20 for HRRR.
     write_tasks_per_group="14"  # One possibility: 14 for RAP, 20 for HRRR.
   elif [ "$predef_domain" = "HRRR" ]; then
     layout_x="20"  # One possibility: 14 for RAP, 20 for HRRR.
     layout_y="20"  # One possibility: 14 for RAP, 20 for HRRR.
     write_tasks_per_group="20"  # One possibility: 14 for RAP, 20 for HRRR.
   fi
   #
   preexisting_dir_method="delete"
   #preexisting_dir_method="rename"
   #preexisting_dir_method="quit"

Note that the variable values in this code snippet still need to be customized for
your environment and/or experiment.  This customization is described in the next step.

.. warning::
   The following table and the queue information in Step 2 are specific to the NOAA HPC machine theia.

.. _tasks_queues:

.. table:: *Workflow task names and the queue submission.*

   +-------------------------+-----------------------------+
   | **Task Name**           | **Queue**                   |
   +=========================+=============================+
   | ``make_grid_orog``      | ``QUEUE_DEFAULT``           |
   +-------------------------+-----------------------------+
   | ``get_GFS_files``       | ``QUEUE_HPSS``              |
   +-------------------------+-----------------------------+
   | ``make_surf_IC_BC0``    | ``QUEUE_DEFAULT``           |
   +-------------------------+-----------------------------+
   | ``make_BC1_to_BCend``   | ``QUEUE_DEFAULT``           |
   +-------------------------+-----------------------------+
   | ``stage``               | ``QUEUE_DEFAULT``           |
   +-------------------------+-----------------------------+
   | ``run_FV3SAR``          | ``QUEUE_RUN_FV3SAR``        |
   +-------------------------+-----------------------------+
   | ``post_00 ... post_NN`` | ``QUEUE_DEFAULT``           |
   +-------------------------+-----------------------------+


2.  Customize the variables in your ``config.sh`` as follows (note that you can find 
    documentation on what each of these variables represent in ``config_defaults.sh``):

 * Since we're running on theia, leave ``MACHINE`` set to ``"THEIA"``.

 * If you have access to the ``gsd-fv3`` account, leave ``ACCOUNT`` set to ``"gsd-fv3"``.
   Otherwise, set ``ACCOUNT`` to one of the accounts you're a member of.

 * Leave ``QUEUE_HPSS`` and ``QUEUE_RUN_FV3SAR`` unchanged, but you can change
   ``QUEUE_DEFAULT`` if you like.  The workflow tasks and the queues they will
   get submitted to are shown in :numref:`Table %s <tasks_queues>`.

   From :numref:`Table %s <tasks_queues>`, we can see that the task that gets the
   GFS analysis and forecast files (``get_GFS_files``) is submitted to the queue
   defined by ``QUEUE_HPSS``, the forecast task (``run_FV3SAR``) is submitted to
   the queue defined by ``QUEUE_RUN_FV3SAR``, and all remaining tasks are submitted
   to the queue defined by ``QUEUE_DEFAULT``.  The theia admins require that any jobs
   that access the HPSS run in the ``"service"`` queue, so you have to leave ``QUEUE_HPSS``
   set to ``"service"``.  Also, leave ``QUEUE_RUN_FV3SAR`` set to ``"batch"`` because if
   you change it to ``“debug”``, the forecast will not complete within the 30 min maximum
   walltime of the ``"debug"`` queue, causing the job to time out.  For debugging tests,
   set ``QUEUE_DEFAULT`` to ``"debug"`` to get the remaining tasks (i.e. the ones other
   than ``get_GFS_file`` and ``run_FV3SAR``) in the queue faster.  For production runs,
   set it to ``"batch"``.

 * Edit ``BASEDIR`` to be your top-level directory.

 * Edit ``TMPDIR`` to be your work directory, wherever you want that to be.  A subdirectory
   will be created under this directory for each experiment for which you generate a
   workflow (using ``generate_FV3SAR_wflow.sh``; see below).  Since the run directory that
   the setup script (``setup.sh`` in ``ush``) will create will be in ``$BASEDIR/run_dirs``,
   it is convenient to set ``TMPDIR`` to ``$BASEDIR/work_dirs`` so that the work and run
   directories will be at the same directory level. This is not necessary, however; you
   can use another location for ``TMPDIR`` that is independent of ``BASEDIR``.

 * Leave ``UPPDIR`` unchanged for now.  This is set to where Jeff's version of UPP is located.
   We need to decide where in the SAR directory structure to put UPP and document how to build
   it to work with the FV3SAR.

 * Leave ``CDATE``, ``fcst_len_hrs``, and ``BC_update_intvl_hrs`` unchanged since we know
   the workflow should complete with these settings.  We can explore other values of these
   variables later.

 * Change ``run_title`` to a descriptive string for your run.  This will get appended to
   the end of the names of your run and work directories.

 * Leave ``predef_domain`` set to ``"HRRR"``.  If that works, you can later try the
   ``"RAP"`` setting.  This variable sets the regional domain to one of these two 
   predefined domains.  It does this by setting the grid parameters (i.e. ``RES``,
   ``lon_ctr_T6``, etc defined in ``config_defaults.sh``) to predefined values.
   If you want a domain other than one of these two defaults, then you have to first
   set predef_domain to an empty string and then copy the grid parameters from
   ``config_defaults.sh`` to ``config.sh`` and set them to the values you want.
   But don't do that for now.

 * Leave the ``layout_x``, ``layout_y``, and write_tasks_per_group settings
   unchanged for now.  You will likely have to change these if you decide to use a custom domain.

 * Set ``preexisting_dir_method`` to the method you want to use to handle pre-existing
   versions of run and work directories.  The workflow generation script (``generate_FV3SAR_wflow.sh``,
   discussed below) will create run and work directories for your experiment.  If one or both
   of those directories already exist, the setting of ``preexisting_dir_method`` determines what
   will be done with them.  If this variable is set to ``"delete"``, pre-existing directories will
   be deleted and replaced with new ones; if it is set to ``"rename"``, they will get renamed
   (by appending ``"_old001"``, ``"_old002"``, etc to their names); and if it is set to ``"quit"``,
   the workflow generation script will fail if it finds any pre-existing directories.
