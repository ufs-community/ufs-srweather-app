.. _srw-sd:

==================================
SRW Smoke & Dust (SRW-SD) Features
==================================

This chapter provides instructions for running an example six-hour forecast for July 22, 2019 at 0z using SRW Smoke & Dust (SRW-SD) features. These features have been merged into the SRW App from the UFS WM. This experimental forecast uses RAP data for :term:`ICs` and :term:`LBCs`, the ``RRFS_CONUS_3km`` predefined grid, and the ``FV3_HRRR_gf`` physics suite. This physics suite is similar to the NOAA operational HRRR v4 suite (Dowell et al., 2022), with the addition of the Grell-Freitas deep convective parameterization. `Scientific documentation for the HRRR_gf suite <https://dtcenter.ucar.edu/GMTB/v7.0.0/sci_doc/_h_r_r_r_gf_page.html>`_ and `technical documentation <https://ccpp-techdoc.readthedocs.io/en/v7.0.0/>`_ are available with the CCPP v7.0.0 release but may differ slightly from the version available in the SRW App.

.. note::

   Although this chapter is the primary documentation resource for running the SRW-SD configuration, users may need to refer to :numref:`Chapter %s <BuildSRW>` and :numref:`Chapter %s <RunSRW>` for additional information on building and running the SRW App, respectively. 

Quick Start Guide (SRW-SD)
==========================

Build the SRW & Load the |wflow_env| Environment
------------------------------------------------

Please refer to :ref:`QuickBuildRun` (quick build/run) or :ref:`BuildSRW` for step-by-step build instructions.

Configure an Experiment
-----------------------

Users will need to configure their experiment by setting parameters in the ``config.yaml`` file. To start, users can copy a default experiment setting into ``config.yaml``:

.. code-block:: console

   cd /path/to/ufs-srweather-app/ush
   cp config.smoke_dust.yaml config.yaml
   
Users will need to change the ``ACCOUNT`` variable in ``config.yaml`` to an account that they have access to. They will also need to indicate which ``MACHINE`` they are working on. Users may also wish to adjust other experiment settings. For more information on each task and variable, see :ref:`ConfigWorkflow`. For smoke/dust specific parameters please see :ref:`smoke-dust-parameters`.

In addition to the UFS SRW fixed files, additional data files are required to run the smoke and dust experiment:

   * ``fix_smoke``: Contains forecast grids, regridding weights, a vegetation map, and dummy emissions (used when no in situ emission files are available).
   * ``data_smoke_dust/RAVE_fire``: Emission estimates and Fire Radiative Power (FRP) observations derived from `RAVE <https://www.ospo.noaa.gov/products/land/rave/>`_ satellite observations. Additional RAVE data may be downloaded here for the last six months: https://www.ospo.noaa.gov/pub/Blended/RAVE/RAVE-HrlyEmiss-3km/. Note that SRW-SD uses 3-kilometer RAVE data files.

When using the basic ``config.smoke_dust.yaml`` experiment, the usual pre-processing and coldstart forecast tasks are used, because ``"parm/wflow/prep.yaml"`` appears in the list of workflow files in the ``rocoto: tasks: taskgroups:`` section of ``config.yaml`` (see :numref:`Section %s <TasksPrepAQM>` for task descriptions).

Smoke simulations can be performed in three ways:

#. Current-day emissions: Using emissions estimated from satellite observations on the same day as the simulation (``EBB_DCYCLE=1, PERSISTENCE=false``).
#. Traditional persistence: Using biomass burning emissions estimated from satellite observations of the previous day (a method commonly used in most smoke forecasting systems, ``EBB_DCYCLE=1, PERSISTENCE=true``).
#. Modulated persistence (*considered experimental in the SRW App*): The approach currently used by the RRFS-Smoke model, where emissions are forecasted based on a fire weather index that dictates the diurnal cycle (``EBB_DCYCLE=2, PERSISTENCE=true``).

Predefined Grid Support in SRW-SD
---------------------------------

SRW-SD supports these predefined grids:

* ``RRFS_CONUS_3km``
* ``RRFS_CONUS_13km``
* ``RRFS_CONUS_25km``
* ``RRFS_NA_13km``
* ``RRFS_NA_3km``

Please see :ref:`LAMGrids` for more information on predefined grids in the SRW. User-generated grids are *not* supported with SRW-SD.

.. note::
   North American ICs and LBCs are not staged for the predefined SRW-SD experiment.

.. _srw-sd-more-tasks:

Additional SRW-SD Tasks
-----------------------

Compared to the typical SRW App workflow, the SRW-SD has slightly different tasks for pre-processing. As in the SRW App default workflow, the SRW-SD workflow uses the preprocessing tasks from ``prep.yaml``, but it adds smoke-and-dust-specific tasks from ``smoke_dust.yaml``.

The new tasks for SRW-SD are shown in :numref:`Table %s <pre-srw-sd>`. 

.. _pre-srw-sd:

.. list-table:: *Tasks for SRW-SD Pre-Processing*
   :widths: 20 50 30
   :header-rows: 1

   * - Task Name
     - Description
     - File
   * - ``smoke_dust``
     - Generates the input data file for smoke and dust to be used in the UFS Weather Model.
     - ``parm/wflow/smoke_dust.yaml``
   * - ``prepstart``
     - Adds the smoke and dust fields to the ICs file from the restart file in the previous cycle.
     - ``parm/wflow/smoke_dust.yaml``

The Python utilities listed in :numref:`Table %s <sd-scripts>` are used to perform data processing and calculations required for the SRW-SD forecast.

.. _sd-scripts:

.. list-table:: *Python Utilities Used by Smoke and Dust Tasks*
   :widths: 20 50
   :header-rows: 1

   * - Script
     - Description
   * - ``ush/smoke_dust/add_smoke.py``
     - Transfers smoke and dust-related variables from FV3 tracer outputs to GFS initial conditions.
   * - ``ush/smoke_dust/generate_emissions.py``
     - Calculates fire behavior and emission variables, creating input for the smoke and dust tracers.

----

.. plantuml::
    :caption: Overview of the major steps occurring in the ``smoke_dust`` task.
    :align: center

    participant rocoto as R
    participant task_smoke_dust as T
    participant JSRW_SMOKE_DUST as J
    participant exsrw_smoke_dust.sh as E
    participant generate_emissions.py as G

    == Task: smoke_dust ==

    R -> T: Run task
    T -> J: Submit job card
    J -> E: Run wrapper script
    E -> G: Run emissions generation
    G -> G: Process emissions
    E <- G
    J <- E
    T <- J
    R <- T

----

.. plantuml::
    :caption: Deep dive into the sequence of operations occurring in ``generate_emissions.py``.
    :align: center

    collections "Input Data" as SD
    participant generate_emissions.py as G
    participant SmokeDustContext as C
    participant SmokeDustPreprocessor as P
    participant SmokeDustCycleProcessor as CP
    participant SmokeDustRegridProcessor as RP
    collections "Output Data" as OD

    == Task: smoke_dust (generate_emissions.py) ==

    activate G
    G -> C: Intialize context
    activate C
    SD <-- C: Validate input structure
    G -> P: Run preprocessor
    activate P
    C <-- P: Read context
    P -> CP: Initialize cycle processor
    C <-- CP: Read context
    activate CP
    P <- CP: Get forecast dates
    P -> RP: Initialize regrid processor
    activate RP
    C <-- RP: Read context
    P -> RP: Run regridding
    SD <-- RP: Read input data
    OD <- RP: Write interpolated data
    activate OD
    P <- RP
    deactivate RP
    P -> CP: Run cycle processor
    SD <-- CP: Read input data
    OD <-- CP: Read interpolated data
    OD <- CP: Write emissions file
    P <- CP
    deactivate CP
    G <- P
    deactivate P
    deactivate C
    deactivate G

----

.. plantuml::
    :caption: Overview of the major steps occurring in the ``prepstart`` task.
    :align: center

    participant rocoto as R
    participant task_prepstart as T
    participant JSRW_PREPSTART as J
    participant exsrw_prepstart.sh as E
    participant add_smoke.py as G

    == Task: prep_start ==

    R -> T: Run task
    T -> J: Submit job card
    J -> E: Run wrapper script
    E -> G: Run transfer script
    G -> G: Transfer tracers
    E <- G
    J <- E
    T <- J
    R <- T

----

Unit tests can be found in ``tests/test_python/test_smoke_dust``. The SRW-SD Python utilities run under their own Anaconda environment similar to the ``srw_app`` environment: ``sd_environment.yml``.

Generate and Run the Workflow
-----------------------------

Please refer to :ref:`QuickBuildRun` (quick build/run) or :ref:`BuildSRW` for step-by-step instructions on how to build and run the workflow.

.. _srw-sd-success:

Experiment Output
-----------------

The workflow run is complete when all tasks display a "SUCCEEDED" message. If everything goes smoothly, users will eventually see a workflow status table similar to the following: 

.. code-block:: console

   $ rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
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
   201907220000     run_forecast_mem000    18984328    SUCCEEDED            0       1     6199.0
   201907220000    run_post_mem000_f000    18988282    SUCCEEDED            0       1      212.0
   201907220000    run_post_mem000_f001    18988283    SUCCEEDED            0       1      247.0
   201907220000    run_post_mem000_f002    18988284    SUCCEEDED            0       1      258.0
   201907220000    run_post_mem000_f003    18988285    SUCCEEDED            0       1      271.0
   201907220000    run_post_mem000_f004    18988286    SUCCEEDED            0       1      284.0
   201907220000    run_post_mem000_f005    18988287    SUCCEEDED            0       1      286.0
   201907220000    run_post_mem000_f006    18988288    SUCCEEDED            0       1      292.0
   ==============================================================================================
   201907220600              smoke_dust    18988289    SUCCEEDED            0       1      225.0
   201907220600               prepstart    18988302    SUCCEEDED            0       1      112.0
   201907220600           get_extrn_ics    18984150    SUCCEEDED            0       1       10.0
   201907220600          get_extrn_lbcs    18984151    SUCCEEDED            0       1       14.0
   201907220600         make_ics_mem000    18984188    SUCCEEDED            0       1      152.0
   201907220600        make_lbcs_mem000    18984189    SUCCEEDED            0       1       79.0
   201907220600     run_forecast_mem000    18988311    SUCCEEDED            0       1     6191.0
   201907220600    run_post_mem000_f000    18989105    SUCCEEDED            0       1      212.0
   201907220600    run_post_mem000_f001    18989106    SUCCEEDED            0       1      283.0
   201907220600    run_post_mem000_f002    18989107    SUCCEEDED            0       1      287.0
   201907220600    run_post_mem000_f003    18989108    SUCCEEDED            0       1      284.0
   201907220600    run_post_mem000_f004    18989109    SUCCEEDED            0       1      289.0
   201907220600    run_post_mem000_f005    18989110    SUCCEEDED            0       1      294.0
   201907220600    run_post_mem000_f006    18989111    SUCCEEDED            0       1      294.0

If something goes wrong, users can check the log files, which are located by default in ``expt_dirs/smoke_dust_conus3km/logs``. Post-processed smoke/dust output can be found in ``expt_dirs/smoke_dust_conus3km/<cycle>/postprd/smoke_dust.*.grib2``. Output can also be found in the netCDF physcis/dynamics files: ``expt_dirs/smoke_dust_conus3km/<cycle>/<dynf|phyf><tile>.nc``.

.. csv-table:: Smoke/Dust Output Variables
   :file: ../../tables/SRW-SD_output-variables.csv
   :widths: 25, 25, 25, 25
   :header-rows: 1
