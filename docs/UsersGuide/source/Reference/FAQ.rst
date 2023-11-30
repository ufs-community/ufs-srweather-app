.. _FAQ:
  
****
FAQ
****

* :ref:`How do I define an experiment name? <DefineExptName>`
* :ref:`How do I change the Physics Suite Definition File (SDF)? <ChangePhysics>`
* :ref:`How do I change the grid? <ChangeGrid>`
* :ref:`How can I select which workflow tasks to run? <SetTasks>`
* :ref:`How do I turn on/off the cycle-independent workflow tasks? <CycleInd>`
* :ref:`How do I restart a DEAD task? <RestartTask>`
* :ref:`How can I clean up the SRW App code if something went wrong? <CleanUp>`
* :ref:`How do I run a new experiment? <NewExpt>`
* :ref:`How can I add a physics scheme (e.g., YSU PBL) to the UFS SRW App? <AddPhys>`
* :ref:`How can I troubleshoot issues related to ICS/LBCS generation for a predefined 3-km grid? <IC-LBC-gen-issue>`

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

===========================
How do I change the grid?
===========================

To change the predefined grid, modify the ``PREDEF_GRID_NAME`` variable in the ``task_run_fcst:`` section of the ``config.yaml`` script (see :numref:`Section %s <UserSpecificConfig>` for details on creating and modifying the ``config.yaml`` file). The four supported predefined grids as of the SRW Application v2.1.0 release are:

.. code-block:: console
   
   RRFS_CONUS_3km
   RRFS_CONUS_13km
   RRFS_CONUS_25km
   SUBCONUS_Ind_3km

However, users can choose from a variety of predefined grids listed in :numref:`Section %s <PredefGrid>`. An option also exists to create a user-defined grid, with information available in :numref:`Section %s <UserDefinedGrid>`. However, the user-defined grid option is not fully supported as of the v2.1.0 release and is provided for informational purposes only. 

.. _SetTasks:

===============================================
How can I select which workflow tasks to run? 
===============================================

The ``/parm/wflow`` directory contains several ``YAML`` files that configure different workflow task groups. Each task group file contains a number of tasks that are typically run together. :numref:`Table %s <task-group-files>` describes each of the task groups. 

.. _task-group-files:

.. list-table:: Task group files
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
   * - da_data_preproc.yaml
     - Preprocessing tasks for RRFS `DA <data assimilation>`.
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

The default workflow task groups are set in ``parm/wflow/default_workflow.yaml`` and include ``prep.yaml``, ``coldstart.yaml``, and ``post.yaml``. Changing this list of task groups in the user configuration file (``config.yaml``) will override the default and run only the task groups listed. For example, to omit :term:`cycle-independent` tasks and run plotting tasks, users would delete ``prep.yaml`` from the list of tasks and add ``plot.yaml``:

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/plot.yaml"]|include }}'

Users may need to make additional adjustments to ``config.yaml`` depending on which task groups they add or remove. For example, when plotting, the user should add the plotting increment (``PLOT_FCST_INC``) for the plotting tasks in ``task_plot_allvars``. 

Users can omit specific tasks from a task group by including them under the list of tasks as an empty entry. For example, if a user wanted to run only ``task_pre_post_stat`` from ``aqm_post.yaml``, the taskgroups list would include ``aqm_post.yaml``, and the tasks that the user wanted to omit would be listed with no value: 

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/aqm_post.yaml"]|include }}'
       task_post_stat_o3:
       task_post_stat_pm25:
       task_bias_correction_o3:
       task_bias_correction_pm25:

.. _CycleInd:

===========================================================
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

Then, add the paths to the previously generated grid, orography, and surface climatology files under the appropariate tasks in ``config.yaml``: 

.. code-block:: console

   task_make_grid:
      GRID_DIR: /path/to/directory/containing/grid/files
   task_make_orog:
      OROG_DIR: /path/to/directory/containing/orography/files
   task_make_sfc_climo:
      SFC_CLIMO_DIR: /path/to/directory/containing/surface/climatology/files
   
All three sets of files *may* be placed in the same directory location (and would therefore have the same path), but they can also reside in different directories and use different paths. 

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

where ``-c`` specifies the cycle date (first column of ``rocotostat`` output) and ``-t`` represents the task name
(second column of ``rocotostat`` output). After using ``rocotorewind``, the next time ``rocotorun`` is used to
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

To run a new experiment at a later time, users need to rerun the commands in :numref:`Section %s <SetUpPythonEnv>` that reactivate the *srw_app* environment: 

.. code-block:: console
   
   source /path/to/etc/lmod-setup.sh/or/lmod-setup.csh <platform>
   module use /path/to/modulefiles
   module load wflow_<platform>

Follow any instructions output by the console (e.g., ``conda activate srw_app``). 

Then, users can configure a new experiment by updating the environment variables in ``config.yaml`` to reflect the desired experiment configuration. Detailed instructions can be viewed in :numref:`Section %s <UserSpecificConfig>`. Parameters and valid values are listed in :numref:`Section %s <ConfigWorkflow>`. After adjusting the configuration file, generate the new experiment by running ``./generate_FV3LAM_wflow.py``. Check progress by navigating to the ``$EXPTDIR`` and running ``rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10``.

.. note:: 

   If users have updated their clone of the SRW App (e.g., via ``git pull`` or ``git fetch``/``git merge``) since running their last experiement, and the updates include a change to ``Externals.cfg``, users will need to rerun ``checkout_externals`` (instructions :ref:`here <CheckoutExternals>`) and rebuild the SRW App according to the instructions in :numref:`Section %s <BuildExecutables>`.

.. _AddPhys:

====================================================================
How can I add a physics scheme (e.g., YSU PBL) to the UFS SRW App?
====================================================================

At this time, there are ten physics suites available in the SRW App, :ref:`five of which are fully supported <CCPP_Params>`. However, several additional physics schemes are available in the UFS Weather Model (WM) and can be enabled in the SRW App. The CCPP Scientific Documentation details the various `namelist options <https://dtcenter.ucar.edu/GMTB/v6.0.0/sci_doc/_c_c_p_psuite_nml_desp.html>`__ available in the UFS WM, including physics schemes, and also includes an `overview of schemes and suites <https://dtcenter.ucar.edu/GMTB/v6.0.0/sci_doc/allscheme_page.html>`__. 

.. attention::

   Note that when users enable new physics schemes in the SRW App, they are using untested and unverified combinations of physics, which can lead to unexpected and/or poor results. It is recommended that users run experiments only with the supported physics suites and physics schemes unless they have an excellent understanding of how these physics schemes work and a specific research purpose in mind for making such changes. 

To enable an additional physics scheme, such as the YSU PBL scheme, users may need to modify ``ufs-srweather-app/parm/FV3.input.yml``. This is necessary when the namelist has a logical variable corresponding to the desired physics scheme. In this case, it should be set to *True* for the physics scheme they would like to use (e.g., ``do_ysu = True``). 

It may be necessary to disable another physics scheme, too. For example, when using the YSU PBL scheme, users should disable the default SATMEDMF PBL scheme (*satmedmfvdifq*) by setting the ``satmedmf`` variable to *False* in the ``FV3.input.yml`` file. 

It may also be necessary to add or subtract interstitial schemes, so that the communication between schemes and between schemes and the host model is in order. For example, it is necessary that the connections between clouds and radiation are correctly established.

Regardless, users will need to modify the suite definition file (:term:`SDF`) and recompile the code. For example, to activate the YSU PBL scheme, users should replace the line ``<scheme>satmedmfvdifq</scheme>`` with ``<scheme>ysuvdif</scheme>`` and recompile the code.

Depending on the scheme, additional changes to the SDF (e.g., to add, remove, or change interstitial schemes) and to the namelist (to include scheme-specific tuning parameters) may be required. Users are encouraged to reach out on GitHub Discussions to find out more from subject matter experts about recommendations for the specific scheme they want to implement. Users can post on the `SRW App Discussions page <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ or ask their questions directly to the developers of `ccpp-physics <https://github.com/NCAR/ccpp-physics/discussions>`__ and `ccpp-framework <https://github.com/NCAR/ccpp-framework/discussions>`__, which also handle support through GitHub Discussions.

After making appropriate changes to the SDF and namelist files, users must ensure that they are using the same physics suite in their ``config.yaml`` file as the one they modified in ``FV3.input.yml``. Then, the user can run the ``generate_FV3LAM_wflow.py`` script to generate an experiment and navigate to the experiment directory. They should see ``do_ysu = .true.`` in the namelist file (or a similar statement, depending on the physics scheme selected), which indicates that the YSU PBL scheme is enabled.

.. _IC-LBC-gen-issue:

==========================================================================================================
How can I troubleshoot issues related to :term:`ICS`/:term:`LBCS` generation for a predefined 3-km grid?
==========================================================================================================

If you encounter issues while generating ICS and LBCS for a predefined 3-km grid using the UFS SRW App, there are a number of troubleshooting options. The first step is always to check the log file for a failed task. This file will provide information on what went wrong. A log file for each task appears in the ``log`` subdirectory of the experiment directory (e.g., ``$EXPTDIR/log/make_ics``).

Additionally, users can try increasing the number of processors or the wallclock time requested for the jobs. Sometimes jobs may fail without errors because the process is cut short. These settings can be adusted in one of the ``ufs-srweather-app/parm/wflow`` files. For ICs/LBCs tasks, these parameters are set in the ``coldstart.yaml`` file. 

Users can also update the hash of UFS_UTILS in the ``Externals.cfg`` file to the HEAD of that repository. There was a known memory issue with how ``chgres_cube`` was handling regridding of the 3-D wind field for large domains at high resolutions (see `UFS_UTILS PR #766 <https://github.com/ufs-community/UFS_UTILS/pull/766>`__ and the associated issue for more information). If changing the hash in ``Externals.cfg``, users will need to rerun ``manage_externals`` and rebuild the code (see :numref:`Section %s <BuildSRW>`). 
