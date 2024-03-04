.. role:: bolditalic
    :class: bolditalic

.. _FAQ:
  
****
FAQ
****

.. contents::
   :depth: 2
   :local:

=====================
Building the SRW App
=====================

.. _CleanUp:

How can I clean up the SRW App code if something went wrong during the build?
===============================================================================

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

===========================
Configuring an Experiment
===========================

.. _DefineExptName:

How do I define an experiment name?
====================================

The name of the experiment is set in the ``workflow:`` section of the ``config.yaml`` file using the variable ``EXPT_SUBDIR``.
See :numref:`Section %s <UserSpecificConfig>` and/or :numref:`Section %s <DirParams>` for more details.

.. _ChangePhysics:

How do I change the Physics Suite Definition File (SDF)?
=========================================================

The SDF is set in the ``workflow:`` section of the ``config.yaml`` file using the variable ``CCPP_PHYS_SUITE``. The five supported physics suites for the SRW Application are:

.. code-block:: console
   
   FV3_GFS_v16
   FV3_RRFS_v1beta
   FV3_HRRR
   FV3_WoFS_v0
   FV3_RAP

When users run the ``generate_FV3LAM_wflow.py`` script, the SDF file is copied from its location in the forecast
model directory to the experiment directory ``$EXPTDIR``. For more information on the :term:`CCPP` physics suite parameters, see :numref:`Section %s <CCPP_Params>`.

.. _ChangeGrid:

How do I change the grid?
===========================

To change the predefined grid, modify the ``PREDEF_GRID_NAME`` variable in the ``task_run_fcst:`` section of the ``config.yaml`` script (see :numref:`Section %s <UserSpecificConfig>` for details on creating and modifying the ``config.yaml`` file). The five supported predefined grids as of the SRW Application |latestr| release are:

.. code-block:: console
   
   RRFS_CONUS_3km
   RRFS_CONUS_13km
   RRFS_CONUS_25km
   SUBCONUS_Ind_3km
   RRFS_NA_13km

However, users can choose from a variety of predefined grids listed in :numref:`Section %s <PredefGrid>`. An option also exists to create a user-defined grid, with information available in :numref:`Section %s <UserDefinedGrid>`. However, the user-defined grid option is not fully supported as of the |latestr| release and is provided for informational purposes only.

.. _SetTasks:

How can I select which workflow tasks to run? 
===============================================

:numref:`Section %s <ConfigTasks>` provides a full description of how to turn on/off workflow tasks.

The default workflow tasks are defined in ``ufs-srweather-app/parm/wflow/default_workflow.yaml``. However, the ``/parm/wflow`` directory contains several ``YAML`` files that configure different workflow task groups. Each file contains a number of tasks that are typically run together (see :numref:`Table %s <task-group-files>` for a description of each task group). To add or remove workflow tasks, users will need to alter the user configuration file (``config.yaml``) as described in :numref:`Section %s <ConfigTasks>` to override the default workflow and run the selected tasks and task groups.


.. _CompPower:

How can I configure the computational parameters to use more compute power? 
==============================================================================

In general, there are two options for using more compute power: (1) increase the number of PEs or (2) enable more threads.

**Increase Number of PEs**

PEs are processing elements, which correspond to the number of :term:`MPI` processes/tasks. In the SRW App, ``PE_MEMBER01`` is the number of MPI processes required by the forecast. It is calculated by: :math:`LAYOUT\_X * LAYOUT\_Y + WRTCMP\_write\_groups * WRTCMP\_write\_tasks\_per\_group` when ``QUILTING`` is true. Since these variables are connected, it is recommended that users consider how many processors they want to use to run the forecast model and work backwards to determine the other values.

For simplicity, it is often best to set ``WRTCMP_write_groups`` to 1. It may be necessary to increase this number in cases where a single write group cannot finish writing its output before the model is ready to write again. This occurs when the model produces output at very short time intervals.

The ``WRTCMP_write_tasks_per_group`` value will depend on domain (i.e., grid) size. This means that a larger domain would require a higher value, while a smaller domain would likely require less than 5 tasks per group.

The ``LAYOUT_X`` and ``LAYOUT_Y`` variables are the number of MPI tasks to use in the horizontal x and y directions of the regional grid when running the forecast model. Note that the ``LAYOUT_X`` and ``LAYOUT_Y`` variables only affect the number of MPI tasks used to compute the forecast, not resolution of the grid. The larger these values are, the more work is involved when generating a forecast. That work can be spread out over more MPI processes to increase the speed, but this requires more computational resources. There is a limit where adding more MPI processes will no longer increase the speed at which the forecast completes, but the UFS scales well into the thousands of MPI processes.

Users can take a look at the `SRW App predefined grids <https://github.com/ufs-community/ufs-srweather-app/blob/develop/ush/predef_grid_params.yaml>`__ to get a better sense of what values to use for different types of grids. The :ref:`Computational Parameters <CompParams>` and :ref:`Write Component Parameters <WriteComp>` sections of the SRW App User's Guide define these variables.

**Enable More Threads**

In general, enabling more threads offers less increase in performance than doubling the number of PEs. However, it uses less memory and still improves performance. To enable more threading, set ``OMP_NUM_THREADS_RUN_FCST`` to a higher number (e.g., 2 or 4). When increasing the value, it must be a factor of the number of cores/CPUs (``number of MPI tasks * OMP threads`` cannot exceed the number of cores per node). Typically, it is best not to raise this value higher than 4 or 5 because there is a limit to the improvement possible via OpenMP parallelization (compared to MPI parallelization, which is significantly more efficient).

.. _CycleInd:

How do I turn on/off the cycle-independent workflow tasks?
===========================================================

The first three pre-processing tasks ``make_grid``, ``make_orog``, and ``make_sfc_climo``
are :term:`cycle-independent`, meaning that they only need to be run once per experiment. 
By default, the the workflow will run these tasks. However, if the
grid, orography, and surface climatology files that these tasks generate are already 
available (e.g., from a previous experiment that used the same grid as the current experiment), then
these tasks can be skipped, and the workflow can use those pre-generated files.

To skip these tasks, remove ``parm/wflow/prep.yaml`` from the list of task groups in the Rocoto section of the configuration file (``config.yaml``):

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/coldstart.yaml", "parm/wflow/post.yaml"]|include }}'

Then, add the appropriate tasks and paths to the previously generated grid, orography, and surface climatology files to ``config.yaml``:

.. code-block:: console

   task_make_grid:
      GRID_DIR: /path/to/directory/containing/grid/files
   task_make_orog:
      OROG_DIR: /path/to/directory/containing/orography/files
   task_make_sfc_climo:
      SFC_CLIMO_DIR: /path/to/directory/containing/surface/climatology/files
   
All three sets of files *may* be placed in the same directory location (and would therefore have the same path), but they can also reside in different directories and use different paths. 

.. _change-default-params:

How can I change the default parameters (e.g., walltime) for workflow tasks?
=============================================================================

You can change default parameters for a workflow task by setting them to a new value in the ``rocoto: tasks:`` section of the ``config.yaml`` file. First, be sure that the task you want to change is part of the :ref:`default workflow <WorkflowTasksTable>` or included under ``taskgroups:`` in the ``rocoto: tasks:`` section of ``config.yaml``. For instructions on how to add a task to the workflow, see :ref:`this FAQ <SetTasks>`. 

Once you verify that the task you want to modify is included in your workflow, you can configure the task by adding it to the ``rocoto: tasks:`` section of ``config.yaml``. Users should refer to the YAML file where the task is defined to see how to structure the modifications (these YAML files reside in ``ufs-srweather-app/parm/wflow``). For example, to change the wall clock time from 15 to 20 minutes for the ``run_post_mem###_f###`` tasks, users would look at ``post.yaml``, where the post-processing tasks are defined. Formatting for tasks and metatasks should match the structure in this YAML file exactly. 

.. figure:: https://raw.githubusercontent.com/wiki/ufs-community/ufs-srweather-app/OtherImages/FAQpostyaml.png
   :alt: Excerpt of post.yaml file 

   *Excerpt of post.yaml*

Since the ``run_post_mem###_f###`` task in ``post.yaml`` comes under ``metatask_run_ens_post`` and ``metatask_run_post_mem#mem#_all_fhrs``, all of these tasks and metatasks must be included under ``rocoto: tasks:`` before defining the ``walltime`` variable. Therefore, to change the ``walltime`` from 15 to 20 minutes, the ``rocoto: tasks:`` section should look like this:

.. code-block:: yaml
   
   rocoto:
     tasks:
       metatask_run_ens_post:
         metatask_run_post_mem#mem#_all_fhrs:
           task_run_post_mem#mem#_f#fhr#:
             walltime: 00:20:00

Notice that this section contains all three of the tasks/metatasks highlighted in yellow above and lists the ``walltime`` where the details of the task begin. While users may simply adjust the ``walltime`` variable in ``post.yaml``, learning to make these changes in ``config.yaml`` allows for greater flexibility in experiment configuration. Users can modify a single file (``config.yaml``), rather than (potentially) several workflow YAML files, and can account for differences between experiments instead of hard-coding a single value. 

See `SRW Discussion #990 <https://github.com/ufs-community/ufs-srweather-app/discussions/990>`__ for the question that inspired this FAQ. 

.. _AddPhys:

:bolditalic:`Advanced:` How can I add a physics scheme (e.g., YSU PBL) to the UFS SRW App?
===============================================================================================

At this time, there are ten physics suites available in the SRW App, :ref:`five of which are fully supported <CCPP_Params>`. However, several additional physics schemes are available in the UFS Weather Model (WM) and can be enabled in the SRW App. The CCPP Scientific Documentation details the various `namelist options <https://dtcenter.ucar.edu/GMTB/v6.0.0/sci_doc/_c_c_p_psuite_nml_desp.html>`__ available in the UFS WM, including physics schemes, and also includes an `overview of schemes and suites <https://dtcenter.ucar.edu/GMTB/v6.0.0/sci_doc/allscheme_page.html>`__. 

.. attention::

   Note that when users enable new physics schemes in the SRW App, they are using untested and unverified combinations of physics, which can lead to unexpected and/or poor results. It is recommended that users run experiments only with the supported physics suites and physics schemes unless they have an excellent understanding of how these physics schemes work and a specific research purpose in mind for making such changes. 

To enable an additional physics scheme, such as the YSU PBL scheme, users may need to modify ``ufs-srweather-app/parm/FV3.input.yml``. This is necessary when the namelist has a logical variable corresponding to the desired physics scheme. In this case, it should be set to *True* for the physics scheme they would like to use (e.g., ``do_ysu = True``). 

It may be necessary to disable another physics scheme, too. For example, when using the YSU PBL scheme, users should disable the default SATMEDMF PBL scheme (*satmedmfvdifq*) by setting the ``satmedmf`` variable to *False* in the ``FV3.input.yml`` file. 

It may also be necessary to add or subtract interstitial schemes, so that the communication between schemes and between schemes and the host model is in order. For example, it is necessary that the connections between clouds and radiation are correctly established.

Regardless, users will need to modify the suite definition file (:term:`SDF`) and recompile the code. For example, to activate the YSU PBL scheme, users should replace the line ``<scheme>satmedmfvdifq</scheme>`` with ``<scheme>ysuvdif</scheme>`` and recompile the code.

Depending on the scheme, additional changes to the SDF (e.g., to add, remove, or change interstitial schemes) and to the namelist (to include scheme-specific tuning parameters) may be required. Users are encouraged to reach out on GitHub Discussions to find out more from subject matter experts about recommendations for the specific scheme they want to implement. Users can post on the `SRW App Discussions page <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ or ask their questions directly to the developers of `ccpp-physics <https://github.com/NCAR/ccpp-physics/discussions>`__ and `ccpp-framework <https://github.com/NCAR/ccpp-framework/discussions>`__, which also handle support through GitHub Discussions.

After making appropriate changes to the SDF and namelist files, users must ensure that they are using the same physics suite in their ``config.yaml`` file as the one they modified in ``FV3.input.yml``. Then, the user can run the ``generate_FV3LAM_wflow.py`` script to generate an experiment and navigate to the experiment directory. They should see ``do_ysu = .true.`` in the namelist file (or a similar statement, depending on the physics scheme selected), which indicates that the YSU PBL scheme is enabled.

===========================================
Running an Experiment and Troubleshooting
===========================================

.. _RestartTask:

How do I restart a DEAD task?
=============================

On platforms that utilize Rocoto workflow software (such as NCAR's Derecho machine), if something goes wrong with the workflow, a task may end up in the DEAD state:

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

where ``-c`` specifies the cycle date (first column of ``rocotostat`` output) and ``-t`` represents the task name
(second column of ``rocotostat`` output). After using ``rocotorewind``, the next time ``rocotorun`` is used to
advance the workflow, the job will be resubmitted.

.. _TweakExpt:

I ran an experiment, and now I want to tweak one minor detail and rerun the task(s) without regenerating the experiment. How can I do this?
==============================================================================================================================================

In almost every case, it is best to regenerate the experiment from scratch, even if most of the experiment ran successfully and the modification seems minor. Some variable checks are performed in the workflow generation step, while others are done at runtime. Some settings are changed based on the cycle, and some changes may be incompatible with the output of a previous task. At this time, there is no general way to partially rerun an experiment with different settings, so it is almost always better just to regenerate the experiment from scratch.

The exception to this rule is tasks that failed due to platform reasons (e.g., disk space, incorrect file paths). In these cases, users can refer to the :ref:`FAQ on how to restart a DEAD task <RestartTask>`.

Users who are insistent on modifying and rerunning an experiment that fails for non-platform reasons would need to modify variables in ``config.yaml`` and ``var_defns.sh`` at a minimum. Modifications to ``rocoto_defns.yaml`` and ``FV3LAM_wflow.xml`` may also be necessary. However, even with modifications to all appropriate variables, the task may not run successfully due to task dependencies or other factors mentioned above. If there is a compelling need to make such changes in place (e.g., resource shortage for expensive experiments), users are encouraged to reach out via `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ for advice.

See `SRW Discussion #995 <https://github.com/ufs-community/ufs-srweather-app/discussions/995>`__ for the question that inspired this FAQ.

.. _NewExpt:

How can I run a new experiment?
==================================

To run a new experiment at a later time, users need to rerun the commands in :numref:`Section %s <SetUpPythonEnv>` that reactivate the |wflow_env| environment:

.. code-block:: console
   
   source /path/to/etc/lmod-setup.sh/or/lmod-setup.csh <platform>
   module use /path/to/modulefiles
   module load wflow_<platform>

Follow any instructions output by the console (e.g., |activate|).

Then, users can configure a new experiment by updating the experiment parameters in ``config.yaml`` to reflect the desired experiment configuration. Detailed instructions can be viewed in :numref:`Section %s <UserSpecificConfig>`. Parameters and valid values are listed in :numref:`Section %s <ConfigWorkflow>`. After adjusting the configuration file, generate the new experiment by running ``./generate_FV3LAM_wflow.py``. Check progress by navigating to the ``$EXPTDIR`` and running ``rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10``.

.. note:: 

   If users have updated their clone of the SRW App (e.g., via ``git pull`` or ``git fetch``/``git merge``) since running their last experiment, and the updates include a change to ``Externals.cfg``, users will need to rerun ``checkout_externals`` (instructions :ref:`here <CheckoutExternals>`) and rebuild the SRW App according to the instructions in :numref:`Section %s <BuildExecutables>`.

.. _IC-LBC-gen-issue:

How can I troubleshoot issues related to :term:`ICS`/:term:`LBCS` generation for a predefined 3-km grid?
==========================================================================================================

If you encounter issues while generating ICS and LBCS for a predefined 3-km grid using the UFS SRW App, there are a number of troubleshooting options. The first step is always to check the log file for a failed task. This file will provide information on what went wrong. A log file for each task appears in the ``log`` subdirectory of the experiment directory (e.g., ``$EXPTDIR/log/make_ics``).

Additionally, users can try increasing the number of processors or the wallclock time requested for the jobs. Sometimes jobs may fail without errors because the process is cut short. These settings can be adusted in one of the ``ufs-srweather-app/parm/wflow`` files. For ICs/LBCs tasks, these parameters are set in the ``coldstart.yaml`` file. 

Users can also update the hash of UFS_UTILS in the ``Externals.cfg`` file to the HEAD of that repository. There was a known memory issue with how ``chgres_cube`` was handling regridding of the 3-D wind field for large domains at high resolutions (see `UFS_UTILS PR #766 <https://github.com/ufs-community/UFS_UTILS/pull/766>`__ and the associated issue for more information). If changing the hash in ``Externals.cfg``, users will need to rerun ``manage_externals`` and rebuild the code (see :numref:`Section %s <BuildSRW>`). 
