.. _srw-sd:

==================================
SRW Smoke & Dust (SRW-SD) Features
==================================

.. attention::

   SRW-SD capabilities are a new SRW App feature supported on Hera and Orion/Hercules; on other systems, users can expect only limited support.

This chapter provides instructions for running a simple, example six-hour forecast for July 22, 2019 at 0z using SRW Smoke & Dust (SRW-SD) features. These features have been merged into an SRW App feature branch from a UFS WM Rapid Refresh Forecast System (RRFS) production branch. This forecast uses RAP data for :term:`ICs` and :term:`LBCs`, the ``RRFS_CONUS_3km`` predefined grid, and the ``FV3_HRRR_gf`` physics suite. This physics suite is similar to the NOAA operational HRRR v4 suite (Dowell et al., 2022), with the addition of the Grell-Freitas deep convective parameterization. `Scientific documentation for the HRRR_gf suite <https://dtcenter.ucar.edu/GMTB/v7.0.0/sci_doc/_h_r_r_r_gf_page.html>`_ and `technical documentation <https://ccpp-techdoc.readthedocs.io/en/v7.0.0/>`_ are available with the CCPP v7.0.0 release but may differ slightly from the version available in the SRW App.

.. note::

   Although this chapter is the primary documentation resource for running the SRW-SD configuration, users may need to refer to :numref:`Chapter %s <BuildSRW>` and :numref:`Chapter %s <RunSRW>` for additional information on building and running the SRW App, respectively. 

Quick Start Guide (SRW-SD)
==========================

.. attention::

   These instructions should work smoothly on Hera and Orion/Hercules, but users on other systems may need to make additional adjustments.

Download the Code
-----------------

Clone the |branch| branch of the authoritative SRW App repository:

.. code-block:: console

   git clone -b main_aqm https://github.com/ufs-community/ufs-srweather-app
   cd ufs-srweather-app/sorc

Checkout Externals
------------------

Users must run the ``checkout_externals`` script to collect (or "check out") the individual components of the SRW App (AQM version) from their respective GitHub repositories. 

.. code-block:: console

   ./manage_externals/checkout_externals -e Externals_smoke_dust.cfg

Build the SRW App
-----------------

.. code-block:: console

   ./app_build.sh -p=<machine>

where ``<machine>`` is ``hera``, ``orion``, or ``hercules``.

Building the SRW App with SRW-SD on other machines, including other :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` platforms, is not currently guaranteed to work, and users may have to make adjustments to the modulefiles for their system. 

If SRW-SD builds correctly, users should see the standard executables listed in :numref:`Table %s <ExecDescription>` in the ``ufs-srweather-app/exec`` directory.

Load the |wflow_env| Environment
--------------------------------

Load the workflow environment:

.. code-block:: console

   module purge
   source /path/to/ufs-srweather-app/versions/run.ver_<machine>
   module use /path/to/ufs-srweather-app/modulefiles
   module load wflow_<machine>

where ``<machine>`` is ``hera``, ``orion``, or ``hercules``. The workflow should load on other platforms listed under the ``MACHINE`` variable in :numref:`Section %s <user>`, but users may need to adjust other elements of the process when running on those platforms.

.. _srw-sd-config:

Configure an Experiment
-----------------------

Users will need to configure their experiment by setting parameters in the ``config.yaml`` file. To start, users can copy a default experiment setting into ``config.yaml``:

.. code-block:: console

   cd /path/to/ufs-srweather-app/parm
   cp config.smoke_dust.yaml config.yaml
   
Users will need to change the ``ACCOUNT`` variable in ``config.yaml`` to an account that they have access to. They will also need to indicate which ``MACHINE`` they are working on. Users may also wish to adjust other experiment settings. For more information on each task and variable, see :numref:`Section %s <ConfigWorkflow>`. 

If running on Orion or Hercules, users will need to change the data paths to :term:`ICs/LBCs` on the following lines in the ``task_get_extrn_*:`` sections of ``config.yaml`` by commenting out the Hera lines and uncommenting the Orion/Hercules lines:

.. code-block:: console

   task_get_extrn_ics:
     # EXTRN_MDL_SOURCE_BASEDIR_ICS: /scratch2/NAGAPE/epic/SRW-AQM_DATA/data_smoke_dust/RAP_DATA_SD/${yyyymmddhh} # hera
     EXTRN_MDL_SOURCE_BASEDIR_ICS: /work/noaa/epic/SRW-AQM_DATA/input_model_data/RAP/${yyyymmddhh} # orion/hercules
   task_get_extrn_lbcs:
     # EXTRN_MDL_SOURCE_BASEDIR_LBCS: /scratch2/NAGAPE/epic/SRW-AQM_DATA/data_smoke_dust/RAP_DATA_SD/${yyyymmddhh} # hera
     EXTRN_MDL_SOURCE_BASEDIR_LBCS: /work/noaa/epic/SRW-AQM_DATA/input_model_data/RAP/${yyyymmddhh} # orion/hercules

In addition to the UFS SRW fixed files, additional data files are required to run the smoke and dust experiment:

   * ``fix_smoke``: Contains analysis grids, regridding weights, a vegetation map, and dummy emissions (used when no in situ emission files are available).
   * ``data_smoke_dust/RAVE_fire``: Emission estimates and Fire Radiative Power (FRP) observations derived from `RAVE <https://www.ospo.noaa.gov/products/land/rave/>`_ satellite observations.

.. note::
   Smoke and dust fixed file data has not been added to the `SRW App data bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`_. Users and developers who would like access to the fixed file data necessary to run the application should reach out the UFS SRW team in a :srw-repo:`GitHub Discussion <discussions>`.

Users may also wish to change :term:`cron`-related parameters in ``config.yaml``. In the ``config.smoke_dust.yaml`` file, which was copied into ``config.yaml``, cron can be used for automatic submission and resubmission of the workflow by setting the following variables:

.. code-block:: console

   workflow:
     USE_CRON_TO_RELAUNCH: true
     CRON_RELAUNCH_INTVL_MNTS: 3

This means that cron will submit the launch script every 3 minutes. Users may choose not to submit using cron or to submit at a different frequency. Note that users should create a crontab by running ``crontab -e`` the first time they use cron.

When using the basic ``config.smoke_dust.yaml`` experiment, the usual pre-processing and coldstart forecast tasks are used, because ``"parm/wflow/prep.yaml"`` appears in the list of workflow files in the ``rocoto: tasks: taskgroups:`` section of ``config.yaml`` (see :numref:`Section %s <TasksPrepAQM>` for task descriptions). To turn on AQM *post*-processing tasks in the workflow, include ``"parm/wflow/aqm_post.yaml"`` in the ``rocoto: tasks: taskgroups:`` section, too (see :numref:`Section %s <TasksPostAQM>` for task descriptions).

.. _srw-sd-more-tasks:

Additional SRW-SD Tasks
-----------------------

.. COMMENT: Add workflow diagram in the future. 

Compared to the typical SRW App workflow, the SRW-SD has slightly different tasks for pre- and post-processing. As in the SRW App default workflow, the SRW-SD workflow uses the preprocessing tasks from ``prep.yaml``, but it adds smoke-and-dust-specific tasks from ``smoke_dust.yaml``. For post-processing, it uses the NCO-compliant ``upp_post.yaml`` instead of the usual ``post.yaml``. 

The new tasks for SRW-SD are shown in :numref:`Table %s <pre-srw-sd>`. 

.. _pre-srw-sd:

.. list-table:: *Tasks for SRW-SD Pre- and Post-Processing*
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

The Python scripts listed in :numref:`Table %s <sd-scripts>` are used to perform data processing and calculations required for the SRW-SD forecast. 

.. _sd-scripts:

.. list-table:: *Python Scripts Used by Smoke and Dust Tasks*
   :widths: 20 50
   :header-rows: 1

   * - Script
     - Description
   * - ``ush/smoke_dust_add_smoke.py``
     - Transfers smoke and dust-related variables from FV3 tracer outputs to GFS initial conditions.
   * - ``ush/smoke_dust_fire_emiss_tools.py``
     - Calculates fire behavior and emission variables and creates input for the smoke and dust tracers.
   * - ``ush/smoke_dust_generate_fire_emissions.py``
     - Entry point for the smoke and dust fire-related initial conditions generated during the ``smoke_dust`` task.
   * - ``ush/smoke_dust_hwp_tools.py``
     - Utilities for calculating Hourly Wildfire Potential (HWP).
   * - ``ush/smoke_dust_interp_tools.py``
     - Regridding utilities using `esmpy <https://earthsystemmodeling.org/esmpy/>`_ that interpolate data from the RAVE observational grid to the RRFS grid.

Generate the Workflow
---------------------

Generate the workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

Run the Workflow
------------------

If ``USE_CRON_TO_RELAUNCH`` is set to true in ``config.yaml`` (see :numref:`Section %s <srw-sd-config>`), the workflow will run automatically. If it was set to false, users must submit the workflow manually from the experiment directory:

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

.. _srw-sd-success:

Experiment Output
-----------------

The workflow run is complete when all tasks display a "SUCCEEDED" message. If everything goes smoothly, users will eventually see a workflow status table similar to the following: 

.. code-block:: console

   [orion-login smoke_dust_conus3km]$ rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
         CYCLE                    TASK       JOBID        STATE   EXIT STATUS   TRIES   DURATION
   ==============================================================================================
   201907220000               make_grid    18984137    SUCCEEDED            0       1       29.0
   201907220000               make_orog    18984148    SUCCEEDED            0       1      419.0
   201907220000          make_sfc_climo    18984184    SUCCEEDED            0       1       82.0
   201907220000              smoke_dust    18984186    SUCCEEDED            0       1      243.0
   201907220000               prepstart    18984324    SUCCEEDED            0       1       24.0
   201907220000           get_extrn_ics    18984138    SUCCEEDED            0       1       11.0
   201907220000          get_extrn_lbcs    18984149    SUCCEEDED            0       1       12.0
   201907220000         make_ics_mem000    18984185    SUCCEEDED            0       1      157.0
   201907220000        make_lbcs_mem000    18984187    SUCCEEDED            0       1       85.0
   201907220000         forecast_mem000    18984328    SUCCEEDED            0       1     6199.0
   201907220000    upp_post_mem000_f000    18988282    SUCCEEDED            0       1      212.0
   201907220000    upp_post_mem000_f001    18988283    SUCCEEDED            0       1      247.0
   201907220000    upp_post_mem000_f002    18988284    SUCCEEDED            0       1      258.0
   201907220000    upp_post_mem000_f003    18988285    SUCCEEDED            0       1      271.0
   201907220000    upp_post_mem000_f004    18988286    SUCCEEDED            0       1      284.0
   201907220000    upp_post_mem000_f005    18988287    SUCCEEDED            0       1      286.0
   201907220000    upp_post_mem000_f006    18988288    SUCCEEDED            0       1      292.0
   ==============================================================================================
   201907220600              smoke_dust    18988289    SUCCEEDED            0       1      225.0
   201907220600               prepstart    18988302    SUCCEEDED            0       1      112.0
   201907220600           get_extrn_ics    18984150    SUCCEEDED            0       1       10.0
   201907220600          get_extrn_lbcs    18984151    SUCCEEDED            0       1       14.0
   201907220600         make_ics_mem000    18984188    SUCCEEDED            0       1      152.0
   201907220600        make_lbcs_mem000    18984189    SUCCEEDED            0       1       79.0
   201907220600         forecast_mem000    18988311    SUCCEEDED            0       1     6191.0
   201907220600    upp_post_mem000_f000    18989105    SUCCEEDED            0       1      212.0
   201907220600    upp_post_mem000_f001    18989106    SUCCEEDED            0       1      283.0
   201907220600    upp_post_mem000_f002    18989107    SUCCEEDED            0       1      287.0
   201907220600    upp_post_mem000_f003    18989108    SUCCEEDED            0       1      284.0
   201907220600    upp_post_mem000_f004    18989109    SUCCEEDED            0       1      289.0
   201907220600    upp_post_mem000_f005    18989110    SUCCEEDED            0       1      294.0
   201907220600    upp_post_mem000_f006    18989111    SUCCEEDED            0       1      294.0

If something goes wrong, users can check the log files, which are located by default in ``expt_dirs/smoke_dust_conus3km/nco_logs/20190722``.
