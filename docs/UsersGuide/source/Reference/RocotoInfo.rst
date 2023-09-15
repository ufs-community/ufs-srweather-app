.. _RocotoInfo:

==================================
Rocoto Introductory Information
==================================
The tasks in the SRW Application are typically run using the Rocoto Workflow Manager 
(see :numref:`Table %s <WorkflowTasksTable>` for default tasks). 
Rocoto is a Ruby program that communicates with the batch system on an
:term:`HPC` system to run and manage dependencies between the tasks. Rocoto submits jobs to the HPC batch
system as the task dependencies allow and runs one instance of the workflow for a set of user-defined
:term:`cycles <cycle>`. More information about Rocoto can be found on the 
`Rocoto Wiki <https://github.com/christopherwharrop/rocoto/wiki/documentation>`__.

The SRW App workflow is defined in a Jinja-enabled Rocoto XML template called ``FV3LAM_wflow.xml``,
which resides in the ``parm`` directory. When the ``generate_FV3LAM_wflow.py`` script is run, 
the :ref:`Unified Workflow <uwtools>` ``set_template`` tool is called, and the parameters in the template file
are filled in. The completed file contains the workflow task names, parameters needed by the job scheduler,
and task interdependencies. The generated XML file is then copied to the experiment directory:
``$EXPTDIR/FV3LAM_wflow.xml``.

There are a number of Rocoto commands available to run and monitor the workflow; users can find more information in the
complete `Rocoto documentation <http://christopherwharrop.github.io/rocoto/>`__.
Descriptions and examples of commonly used commands are discussed below.

.. _RocotoRunCmd:

rocotorun
==========
The ``rocotorun`` command is used to run the workflow by submitting tasks to the batch system. It will
automatically resubmit failed tasks and can recover from system outages without user intervention. The command takes the following format:

.. code-block:: console

   rocotorun -w /path/to/workflow/xml/file -d /path/to/workflow/database/file -v 10

where 				

* ``-w`` specifies the name of the workflow definition file. This must be an XML file.
* ``-d`` specifies the name of the database file that stores the state of the workflow. The database file is a binary file created and used only by Rocoto. It does not need to exist when the command is initially run. 
* ``-v`` (optional) specified level of verbosity. If no level is specified, a level of 1 is used.

From the ``$EXPTDIR`` directory, the ``rocotorun`` command for the workflow would be:

.. code-block:: console

   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db

Users will need to include the absolute or relative path to these files when running the command from another directory. 

It is important to note that the ``rocotorun`` process is iterative; the command must be executed
many times before the entire workflow is completed, usually every 1-10 minutes. This command can be
placed in the user’s :term:`crontab`, and cron will call it with a specified frequency. More information on
this command can be found in the `Rocoto documentation <http://christopherwharrop.github.io/rocoto/>`__.

The first time the ``rocotorun`` command is executed for a workflow, the files ``FV3LAM_wflow.db`` and
``FV3LAM_wflow_lock.db`` are created.  There is usually no need for the user to modify these files.
Each time this command is executed, the last known state of the workflow is read from the ``FV3LAM_wflow.db``
file, the batch system is queried, jobs are submitted for tasks whose dependencies have been satisfied,
and the current state of the workflow is saved in ``FV3LAM_wflow.db``. If there is a need to relaunch
the workflow from scratch, both database files can be deleted, and the workflow can be run by executing the ``rocotorun`` command
or the launch script (``launch_FV3LAM_wflow.sh``) multiple times.

.. _RocotoStatCmd:

rocotostat
===========
``rocotostat`` is a tool for querying the status of tasks in an active Rocoto workflow.  Once the
workflow has been started with the ``rocotorun`` command, Rocoto can check the status of the
workflow using the ``rocotostat`` command:

.. code-block:: console

   rocotostat -w /path/to/workflow/xml/file -d /path/to/workflow/database/file

Executing this command will generate a workflow status table similar to the following:

.. code-block:: console

          CYCLE                    TASK                   JOBID          STATE    EXIT STATUS   TRIES    DURATION
   ===============================================================================================================
   201907010000               make_grid                  175805         QUEUED              -       0         0.0
   201907010000               make_orog                       -              -              -       -           -
   201907010000          make_sfc_climo                       -              -              -       -           -
   201907010000           get_extrn_ics     druby://hfe01:36261     SUBMITTING              -       0         0.0
   201907010000          get_extrn_lbcs     druby://hfe01:36261     SUBMITTING              -       0         0.0
   201907010000         make_ics_mem000                       -              -              -       -           -
   201907010000        make_lbcs_mem000                       -              -              -       -           -
   201907010000         run_fcst_mem000                       -              -              -       -           -
   201907010000   run_post__mem000_f000                       -              -              -       -           -
   201907010000   run_post__mem000_f001                       -              -              -       -           -
   201907010000   run_post__mem000_f002                       -              -              -       -           -
   201907010000   run_post__mem000_f003                       -              -              -       -           -
   201907010000   run_post__mem000_f004                       -              -              -       -           -
   201907010000   run_post__mem000_f005                       -              -              -       -           -
   201907010000   run_post__mem000_f006                       -              -              -       -           -

This table indicates that the ``make_grid`` task was sent to the batch system and is now queued, while
the ``get_extrn_ics`` and ``get_extrn_lbcs`` tasks for the ``201907010000`` cycle are currently being
submitted to the batch system. 

Note that issuing a ``rocotostat`` command without an intervening ``rocotorun`` command will not result in an
updated workflow status table; it will print out the same table. It is the ``rocotorun`` command that updates
the workflow database file (in this case ``FV3LAM_wflow.db``, located in ``$EXPTDIR``). The ``rocotostat`` command
reads the database file and prints the table to the screen. To see an updated table, the ``rocotorun`` command
must be executed followed by the ``rocotostat`` command.

After issuing the ``rocotorun`` command several times (over the course of several minutes or longer, depending
on the grid size and computational resources available), the output of the ``rocotostat`` command should look like this:

.. code-block:: console

          CYCLE                    TASK        JOBID           STATE   EXIT STATUS   TRIES   DURATION
   ===================================================================================================
   201907010000               make_grid       175805       SUCCEEDED            0       1       10.0
   201907010000               make_orog       175810       SUCCEEDED            0       1       27.0
   201907010000          make_sfc_climo       175822       SUCCEEDED            0       1       38.0
   201907010000           get_extrn_ics       175806       SUCCEEDED            0       1       37.0
   201907010000          get_extrn_lbcs       175807       SUCCEEDED            0       1       53.0
   201907010000         make_ics_mem000       175825       SUCCEEDED            0       1       99.0
   201907010000        make_lbcs_mem000       175826       SUCCEEDED            0       1       90.0
   201907010000         run_fcst_mem000       175937         RUNNING            -       0        0.0
   201907010000   run_post__mem000_f000            -               -            -       -          -
   201907010000   run_post__mem000_f001            -               -            -       -          -
   201907010000   run_post__mem000_f002            -               -            -       -          -
   201907010000   run_post__mem000_f003            -               -            -       -          -
   201907010000   run_post__mem000_f004            -               -            -       -          -
   201907010000   run_post__mem000_f005            -               -            -       -          -
   201907010000   run_post__mem000_f006            -               -            -       -          -

When the workflow runs to completion, all tasks will be marked as SUCCEEDED. The log file for each task
is located in ``$EXPTDIR/log``. If any task fails, the corresponding log file can be checked for error
messages. Optional arguments for the ``rocotostat`` command can be found in the 
`Rocoto documentation <http://christopherwharrop.github.io/rocoto/>`__.

.. _rocotocheck:

rocotocheck
============
Sometimes, issuing a ``rocotorun`` command will not cause the next task to launch. ``rocotocheck`` is a
tool that can be used to query detailed information about a task or cycle in the Rocoto workflow. To
determine why a particular task has not been submitted, the ``rocotocheck`` command can be used
from the ``$EXPTDIR`` directory as follows:

.. code-block:: console

   rocotocheck -w FV3LAM_wflow.xml -d FV3LAM_wflow.db file -c <YYYYMMDDHHmm> -t <taskname> 

where 

* ``-c`` is the cycle to query in YYYYMMDDHHmm format.
* ``-t`` is the task name (e.g., ``make_grid``, ``get_extrn_ics``, ``run_fcst_mem000``). 

The cycle and task names appear in the first and second columns of the table output by ``rocotostat``. Users will need to include the absolute or relative path to the workflow XML and database files when running the command from another directory.

A specific example is:

.. code-block:: console

   rocotocheck -w /Users/John.Doe/expt_dirs/test_community/FV3LAM_wflow.xml -d /Users/John.Doe/expt_dirs/test_community/FV3LAM_wflow.db -v 10 -c 201907010000 -t run_fcst_mem000

Running ``rocotocheck`` will result in output similar to the following:

.. code-block:: console
   :emphasize-lines: 8,19,34

   Task: run_fcst_mem000
      account: gsd-fv3
      command: /scratch2/BMC/det/$USER/ufs-srweather-app/ush/load_modules_run_task.sh "run_fcst_mem000" "/scratch2/BMC/det/$USER/ufs-srweather-app/jobs/JREGIONAL_RUN_FCST"
      cores: 24
      final: false
      jobname: run_FV3
      join: /scratch2/BMC/det/$USER/expt_dirs/test_community/log/run_fcst_mem000_2019070100.log
      maxtries: 3
      name: run_fcst_mem000
      nodes: 1:ppn=24
      queue: batch
      throttle: 9999999
      walltime: 04:30:00
      environment
         CDATE ==> 2019070100
         CYCLE_DIR ==> /scratch2/BMC/det/$USER/UFS_CAM/expt_dirs/test_community/2019070100
         PDY ==> 20190701
         SCRIPT_VAR_DEFNS_FP ==> /scratch2/BMC/det/$USER/expt_dirs/test_community/var_defns.sh
      dependencies
         AND is satisfied
            make_ICS_surf_LBC0 of cycle 201907010000 is SUCCEEDED
            make_LBC1_to_LBCN of cycle 201907010000 is SUCCEEDED
   
   Cycle: 201907010000
      Valid for this task: YES
      State: active
      Activated: 2019-10-29 18:13:10 UTC
      Completed: -
      Expired: -
   
   Job: 513615
      State:  DEAD (FAILED)
      Exit Status: 1
      Tries: 3
      Unknown count: 0
      Duration: 58.0

This output shows that although all dependencies for this task are satisfied (see the dependencies section, highlighted above),
it cannot run because its ``maxtries`` value (highlighted) is 3. Rocoto will attempt to launch it at most 3 times,
and it has already been tried 3 times (note the ``Tries`` value, also highlighted).

The output of the ``rocotocheck`` command is often useful in determining whether the dependencies for a given task
have been met. If not, the dependencies section in the output of ``rocotocheck`` will indicate this by stating that a
dependency "is NOT satisfied".  

rocotorewind
=============
``rocotorewind`` is a tool that attempts to undo the effects of running a task. It is commonly used to rerun part
of a workflow that has failed. If a task fails to run (the STATE is DEAD) and needs to be restarted, the ``rocotorewind``
command will rerun tasks in the workflow. The command line options are the same as those described for ``rocotocheck``
(in :numref:`Section %s <rocotocheck>`), and the general usage statement looks like this:
						
.. code-block:: console

   rocotorewind -w /path/to/workflow/xml/file -d /path/to/workflow/database/ file -c <YYYYMMDDHHmm> -t <taskname> 

Running this command will edit the Rocoto database file ``FV3LAM_wflow.db`` to remove evidence that the job has been run.
``rocotorewind`` is recommended over ``rocotoboot`` for restarting a task, since ``rocotoboot`` will force a specific
task to run, ignoring all dependencies and throttle limits. The throttle limit, denoted by the variable ``cyclethrottle``
in the ``FV3LAM_wflow.xml`` file, limits how many cycles can be active at one time. An example of how to use the ``rocotorewind``
command to rerun the forecast task from ``$EXPTDIR`` is:

.. code-block:: console

   rocotorewind -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10 -c 201907010000 -t run_fcst_mem000

rocotoboot
===========
``rocotoboot`` will force a specific task of a cycle in a Rocoto workflow to run. All dependencies and throttle
limits are ignored, and it is generally recommended to use ``rocotorewind`` instead. An example of how to
use this command to rerun the ``make_ics`` task from ``$EXPTDIR`` is:

.. code-block:: console

   rocotoboot -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10 -c 201907010000 -t make_ics

