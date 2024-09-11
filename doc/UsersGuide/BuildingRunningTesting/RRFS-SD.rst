.. _rrfs-sd:

==============================================================
Rapid Refresh Forecast System Smoke & Dust (RRFS-SD) Features
==============================================================

.. attention::

   RRFS-SD capabilities are a new SRW App feature supported only on Hera. User support is available for users on Hera; on other systems, users can expect only limited support. 

This chapter provides instructions for running a sample six-hour forecast for July, 22, 2019 at 0z using RRFS-SD features. This forecast uses RAP data for :term:`ICs` and :term:`LBCs`, the ``RRFS_CONUS_3km`` predefined grid, and the ``FV3_HRRR_gf`` physics suite. This pysics suite is similar to the NOAA operational HRRR v4 suite (Dowell et al., 2022), with the addition of the Grell-Freitas deep convective parameterization. `Scientific documentation for the HRRR_gf suite <https://dtcenter.ucar.edu/GMTB/v7.0.0/sci_doc/_h_r_r_r_gf_page.html>`_ and `technical documentation <https://ccpp-techdoc.readthedocs.io/en/v7.0.0/>`_ are available with the CCPP v7.0.0 release but may differ slightly from the version available in the SRW App. 

.. note::

   Although this chapter is the primary documentation resource for running the RRFS-SD configuration, users may need to refer to :numref:`Chapter %s <BuildSRW>` and :numref:`Chapter %s <RunSRW>` for additional information on building and running the SRW App, respectively. 

Quick Start Guide (RRFS-SD)
=============================

.. attention::

   These instructions should work smoothly on Hera, but users on other systems may need to make additional adjustments. 

Download the Code
-------------------

Clone the |branch| branch of the authoritative SRW App repository:

.. code-block:: console

   git clone -b smoke_dust https://github.com/chan-hoo/ufs-srweather-app
   cd ufs-srweather-app

.. COMMENT: Update clone command to reflect authoritative branch once features are merged in. 

Checkout Externals
---------------------

Users must run the ``checkout_externals`` script to collect (or "check out") the individual components of the SRW App (AQM version) from their respective GitHub repositories. 

.. code-block:: console

   ./manage_externals/checkout_externals -e Externals_smoke_dust.cfg

Build the SRW App with AQM
-----------------------------

On Hera, users can build the SRW App AQM binaries with the smoke argument:

.. code-block:: console

   ./devbuild.sh -p=<machine> --smoke

where ``<machine>`` is ``hera``. The ``--smoke`` argument indicates the configuration/version of the application to build (i.e., RRFS-SD). 

Building the SRW App with RRFS-SD on other machines, including other :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` platforms, is not currently guaranteed to work, and users may have to make adjustments to the modulefiles for their system. 

If RRFS-SD builds correctly, users should see the standard executables listed in :numref:`Table %s <ExecDescription>` in the ``ufs-srweather-app/exec`` directory.

Load the |wflow_env| Environment
--------------------------------------------

Load the Python environment for the workflow:

.. code-block:: console

   module use /path/to/ufs-srweather-app/modulefiles
   module load wflow_<machine>
   conda activate srw_app

where ``<machine>`` is ``hera``. The workflow should load on other platforms listed under the ``MACHINE`` variable in :numref:`Section %s <user>`, but users may need to adjust other elements of the process when running on those platforms. 

.. _rrfs-sd-config:

Configure an Experiment
---------------------------

Users will need to configure their experiment by setting parameters in the ``config.yaml`` file. To start, users can copy a default experiment setting into ``config.yaml``:

.. code-block:: console

   cd ush
   cp config.smoke_dust.yaml config.yaml
   
Users will need to change the ``ACCOUNT`` variable in ``config.yaml`` to an account they have access to. They may also wish to adjust other experiment settings. For more information on each task and variable, see :numref:`Section %s <ConfigWorkflow>`. 

On Level 1 systems, users can find :term:`ICs/LBCs` for the RRFS-SD sample case in the usual :ref:`input data locations <Data>` under ``RAP/2019072200``. Users will need to add the following lines to ``task_get_extrn_*:`` in their ``config.yaml`` file, adjusting the file path to point to the correct data locations:

.. code-block:: console

   task_get_extrn_ics:
     USE_USER_STAGED_EXTRN_FILES: true
     EXTRN_MDL_SOURCE_BASEDIR_ICS: /scratch1/NCEPDEV/nems/role.epic/UFS_SRW_data/develop/input_model_data/RAP/${yyyymmddhh}
   task_get_extrn_lbcs:
     USE_USER_STAGED_EXTRN_FILES: true
     EXTRN_MDL_SOURCE_BASEDIR_LBCS: /scratch1/NCEPDEV/nems/role.epic/UFS_SRW_data/develop/input_model_data/RAP/${yyyymmddhh}

Note that users on other systems will need to use the correct data path for their system. Currently, Hera is the only system supported, but the data is available on other Level 1 systems for those interested in tinkering with the workflow. 

.. COMMENT: Data not in bucket yet. Path needs changing. 
   Users can also download the data required for the community experiment from the `UFS SRW App Data Bucket <https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#develop-20240618/input_model_data/FV3GFS/netcdf/>`_. 

Users may also wish to change :term:`cron`-related parameters in ``config.yaml``. In the ``config.smoke_dust.yaml`` file, which was copied into ``config.yaml``, cron is used for automatic submission and resubmission of the workflow:

.. code-block:: console

   workflow:
     USE_CRON_TO_RELAUNCH: true
     CRON_RELAUNCH_INTVL_MNTS: 3

This means that cron will submit the launch script every 3 minutes. Users may choose not to submit using cron or to submit at a different frequency. Note that users should create a crontab by running ``crontab -e`` the first time they use cron.

When using the basic ``config.smoke_dust.yaml`` experiment, the usual pre-processing and colstart forecast tasks are used,  because ``"parm/wflow/prep.yaml"`` appears in the list of workflow files in the ``rocoto: tasks: taskgroups:`` section of ``config.yaml`` (see :numref:`Section %s <TasksPrepAQM>` for task descriptions). To turn on AQM *post*-processing tasks in the workflow, include ``"parm/wflow/aqm_post.yaml"`` in the ``rocoto: tasks: taskgroups:`` section, too (see :numref:`Section %s <TasksPostAQM>` for task descriptions). 

.. COMMENT: Update wflow info above! 


.. _rrfs-sd-more-tasks:

Additional RRFS-SD Tasks
--------------------------

.. COMMENT:
   :numref:`Figure %s <FlowProcAQM>` illustrates the full non-:term:`DA <data assimilation>` RRFS-SD workflow using a flowchart. 

Compared to the typical SRW App workflow, the RRFS-SD has slightly different tasks for pre- and post-processing. As in the SRW App default workflow, the RRFS-SD workflow uses the preprocessing tasks from ``prep.yaml``, but it adds smoke-and-dust-specific tasks from ``smoke_dust.yaml``. For post-processing, it uses the NCO-compliant ``upp_post.yaml`` instead of the usual ``post.yaml``. 

.. COMMENT: 
   .. _rrfs-sd-wflow:

   .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/WorkflowImages/*.png
      :alt: Flowchart of the RRFS-SD tasks.

      *Workflow Structure of RRFS-SD*


The new tasks for RRFS-SD are shown in :numref:`Table %s <pre-rrfs-sd>`. 

.. _pre-rrfs-sd:

.. list-table:: *Tasks for RRFS-SD Pre- and Post-Processing*
   :widths: 20 50 30
   :header-rows: 1

   * - Task Name
     - Description
     - File
   * - smoke_dust
     - Generates the input data file for smoke and dust to be used in the UFS Weather Model.
     - ``parm/wflow/smoke_dust.yaml``
   * - prepstart
     - Adds the smoke and dust fields to the ICs file from the restart file in the previous cycle.
     - ``parm/wflow/smoke_dust.yaml``
   * - upp_post
     - Performs post-processing with UPP.
     - ``parm/wflow/upp_post.yaml``


.. COMMENT: Add info about Python scripts
   Python scripts:
      * ush/generate_fire_emissions.py
      * ush/HWP_tools.py
      * ush/interp_tools.py
      * ush/add_smoke.py


Generate the Workflow
------------------------

Generate the workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

Run the Workflow
------------------

If ``USE_CRON_TO_RELAUNCH`` is set to true in ``config.yaml`` (see :numref:`Section %s <rrfs-sd-config>`), the workflow will run automatically. If it was set to false, users must submit the workflow manually from the experiment directory:

.. code-block:: console

   cd ../../expt_dirs/smoke_dust_conus3km
   ./launch_FV3LAM_wflow.sh

Repeat the launch command regularly until a SUCCESS or FAILURE message appears on the terminal window. 

Users may check experiment status from the experiment directory with either of the following commands: 

.. code-block:: console

   # Check the experiment status (for cron jobs)
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

   # Check the experiment status and relaunch the workflow (for manual jobs)
   ./launch_FV3LAM_wflow.sh; tail -n 40 log.launch_FV3LAM_wflow

To see a description of each of the AQM workflow tasks, see :numref:`Section %s <AQM-more-tasks>`.

.. _rrfs-sd-success:

Experiment Output
--------------------

The workflow run is complete when all tasks display a "SUCCEEDED" message. If everything goes smoothly, users will eventually see a workflow status table similar to the following: 

.. code-block:: console

         CYCLE                   TASK       JOBID       STATE   EXIT STATUS   TRIES   DURATION
   ============================================================================================
   201907220000             make_grid    66218006   SUCCEEDED             0       1       45.0
   201907220000             make_orog    66218340   SUCCEEDED             0       1      372.0
   201907220000        make_sfc_climo    66218575   SUCCEEDED             0       1       90.0
   201907220000            smoke_dust    66218715   SUCCEEDED             0       1       38.0
   201907220000             prepstart    66219117   SUCCEEDED             0       1       37.0
   201907220000         get_extrn_ics    66218007   SUCCEEDED             0       1       63.0
   201907220000        get_extrn_lbcs    66218008   SUCCEEDED             0       1       58.0
   201907220000       make_ics_mem000    66218716   SUCCEEDED             0       1      152.0
   201907220000      make_lbcs_mem000    66218717   SUCCEEDED             0       1       79.0
   201907220000       run_fcst_mem000    66225732   SUCCEEDED             0       1     4462.0
   201907220000      post_mem000_f000    66229719   SUCCEEDED             0       1      197.0
   201907220000      post_mem000_f001    66229724   SUCCEEDED             0       1      198.0
   201907220000      post_mem000_f002    66229720   SUCCEEDED             0       1      202.0
   201907220000      post_mem000_f003    66229721   SUCCEEDED             0       1      208.0
   201907220000      post_mem000_f004    66229722   SUCCEEDED             0       1      214.0
   201907220000      post_mem000_f005    66229726   SUCCEEDED             0       1      216.0
   201907220000      post_mem000_f006    66229723   SUCCEEDED             0       1      222.0
   ===========================================================================================
   201907220600            smoke_dust    66229725   SUCCEEDED             0       1      171.0
   201907220600             prepstart    66230255   SUCCEEDED             0       1      102.0
   201907220600         get_extrn_ics    66218009   SUCCEEDED             0       1       63.0
   201907220600        get_extrn_lbcs    66218010   SUCCEEDED             0       1       58.0
   201907220600       make_ics_mem000    66218718   SUCCEEDED             0       1      155.0
   201907220600      make_lbcs_mem000    66218719   SUCCEEDED             0       1       79.0
   201907220600       run_fcst_mem000    66230376   SUCCEEDED             0       1     4520.0
   201907220600      post_mem000_f000    66330901   SUCCEEDED             0       1      198.0
   201907220600      post_mem000_f001    66330897   SUCCEEDED             0       1      208.0
   201907220600      post_mem000_f002    66330898   SUCCEEDED             0       1      216.0
   201907220600      post_mem000_f003    66330899   SUCCEEDED             0       1      221.0
   201907220600      post_mem000_f004    66330902   SUCCEEDED             0       1      216.0
   201907220600      post_mem000_f005    66330903   SUCCEEDED             0       1      214.0
   201907220600      post_mem000_f006    66330900   SUCCEEDED             0       1      216.0

If something goes wrong, users can check the log files, which are located by default in ``nco_dirs/test_smoke_dust/com/output/logs/20190722``. 


WE2E Test for RRFS-SD
=======================

Build the app for RRFS-SD:

.. code-block:: console

  ./devbuild.sh -p=hera --smoke

Add the WE2E test for RRFS-SD to the list file:

.. code-block:: console

   cd /path/to/ufs-srweather-app/tests/WE2E
   echo "smoke_dust_grid_RRFS_CONUS_3km_suite_HRRR_gf" >> my_tests.txt

Run the WE2E test:

.. code-block:: console

   $ ./run_WE2E_tests.py -t my_tests.txt -m hera -a gsd-fv3 -q

