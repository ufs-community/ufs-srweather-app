.. _WE2E_tests:

=======================
Testing the SRW App
=======================

Introduction to Workflow End-to-End (WE2E) Tests
==================================================

The SRW App contains a set of end-to-end tests that exercise various workflow configurations of the SRW App. These are referred to as workflow end-to-end (WE2E) tests because they all use the Rocoto workflow manager to run their individual workflows from start to finish. The purpose of these tests is to ensure that new changes to the App do not break existing functionality and capabilities. However, these WE2E tests also provide users with additional sample cases and data beyond the basic ``config.community.yaml`` case. 

.. attention::

   * This introductory section provides high-level information on what is and is not tested with WE2E tests. It also provides information on :ref:`WE2E test categories <we2e-categories>` and the :ref:`WE2E test information file <WE2ETestInfoFile>`, which summarizes each test. 
   * To skip directly to running WE2E tests, go to :numref:`Section %s: Running the WE2E Tests <RunWE2E>`.

What is a WE2E test?
----------------------

WE2E tests are, in essence, tests of the workflow generation, task execution (:term:`J-jobs`, 
:term:`ex-scripts`), and other auxiliary scripts to ensure that these scripts function correctly. Tested functions
include creating and correctly arranging and naming directories and files, ensuring 
that all input files are available and readable, calling executables with correct namelists and/or options, etc. 

Note that the WE2E tests are **not** regression tests---they do not check whether 
current results are identical to previously established baselines. They also do
not test the scientific integrity of the results (e.g., they do not check that values 
of output fields are reasonable). These tests only check that the tasks within each test's workflow complete successfully. Currently, it is up to the external repositories that the App clones (see :numref:`Section %s <SRWStructure>`) to check that changes to those repositories do not change results, or, if they do, to ensure that the new results are acceptable. (At least two of these external repositories---``UFS_UTILS`` and ``ufs-weather-model``---do have such regression tests.) 

WE2E Test Categories
----------------------

WE2E tests are grouped into two categories that are of interest to code developers: ``fundamental`` and ``comprehensive`` tests. "Fundamental" tests are a lightweight but wide-reaching set of tests designed to function as a cheap "`smoke test <https://en.wikipedia.org/wiki/Smoke_testing_(software)>`__" for changes to the UFS SRW App. The fundamental suite of tests runs common combinations of workflow tasks, physical domains, input data, physics suites, etc.
The comprehensive suite of tests covers a broader range of combinations of capabilities, configurations, and components, ideally including all capabilities that *can* be run on a given platform. Because some capabilities are not available on all platforms (e.g., retrieving data directly from NOAA HPSS), the suite of comprehensive tests varies from machine to machine.
The list of fundamental and comprehensive tests can be viewed in the ``ufs-srweather-app/tests/WE2E/machine_suites/`` directory, and the tests are described in more detail in :doc:`this table <../../tables/Tests>`.

.. note::

   There are two additional test suites, ``coverage`` (designed for automated testing) and ``all`` (includes *all* tests, including those known to fail). Running these suites is **not recommended**.

For convenience, the WE2E tests are currently grouped into the following categories (under ``ufs-srweather-app/tests/WE2E/test_configs/``):

* ``aqm``
   This category tests the :term:`AQM` configuration of the SRW App. 

* ``custom_grids``
   This category tests custom grids aside from those specified in ``ufs-srweather-app/ush/predef_grid_params.yaml``. These tests help ensure a wide range of domain sizes, resolutions, and locations will work as expected. These test files can also serve as examples for how to set your own custom domain.

* ``default_configs``
   This category tests example configuration files provided for user reference. They are symbolically linked from the ``ufs-srweather-app/ush/`` directory.

* ``grids_extrn_mdls_suites_community``
   This category of tests ensures that the SRW App workflow running in **community mode** (i.e., with ``RUN_ENVIR`` set to ``"community"``) completes successfully for various combinations of predefined grids, physics suites, and input data from different external models. Note that in community mode, all output from the Application is placed under a single experiment directory.

* ``grids_extrn_mdls_suites_nco``
   This category of tests ensures that the workflow running in **NCO mode** (i.e., with ``RUN_ENVIR`` set to ``"nco"``) completes successfully for various combinations of predefined grids, physics suites, and input data from different external models. Note that in NCO mode, an operational run environment is used. This involves a specific directory structure and variable names (see :numref:`Section %s <NCOModeParms>`).

* ``ufs_case_studies``
   This category tests that the workflow running in community mode completes successfully when running cases derived from the `ufs-case-studies repository <https://github.com/dtcenter/ufs-case-studies>`__. 

* ``verification``
   This category specifically tests the various combinations of verification capabilities using METPlus. 

* ``wflow_features``
   This category of tests ensures that the workflow completes successfully with particular features/capabilities activated.

.. note::

   Users should be aware that some tests assume :term:`HPSS` access. 
   
      * ``custom_ESGgrid_Great_Lakes_snow_8km`` and ``MET_verification_only_vx_time_lag`` require HPSS access, as well as ``rstprod`` access on both :term:`RDHPCS` and HPSS. 
      * On certain machines, the *community* test assumes HPSS access. If the ``ush/machine/*.yaml`` file contains the following lines, and these paths are different from what is provided in ``TEST_EXTRN_MDL_SOURCE_BASEDIR``, users will need to have HPSS access or modify the tests to point to another data source:

      .. code-block:: console

         data:
           ics_lbcs:
             FV3GFS:
             RAP:
             HRRR:

Some tests are duplicated among the above categories via symbolic links, both for legacy reasons (when tests for different capabilities were consolidated) and for convenience when a user would like to run all tests for a specific category (e.g., verification tests).

.. _WE2ETestInfoFile:

WE2E Test Information File
-----------------------------

If users want to see consolidated test information, they can generate a file that can be imported into a spreadsheet program (Google Sheets, Microsoft Excel, etc.) that summarizes each test. This file, named ``WE2E_test_info.txt`` by default, is delimited by the ``|`` character and can be created either by running the ``./print_test_info.py`` script, or by generating an experiment using ``./run_WE2E_tests.py`` with the ``--print_test_info`` flag.

The rows of the file/sheet represent the full set of available tests (not just the ones to be run). The columns contain the following information (column titles are included in the CSV file):

| **Column 1**
| The primary test name followed (in parentheses) by the category subdirectory where it is
  located.

| **Column 2**
| Any alternate names for the test followed by their category subdirectories
  (in parentheses).

| **Column 3**
| The test description.

| **Column 4**
| The relative cost of running the dynamics in the test. This gives an 
  idea of how expensive the test is relative to a reference test that runs 
  a single 6-hour forecast on the ``RRFS_CONUS_25km`` predefined grid using 
  its default time step (``DT_ATMOS: 40``). To calculate the relative cost, the absolute cost (``abs_cost``) is first calculated as follows:

.. code-block::

     abs_cost = nx*ny*num_time_steps*num_fcsts

| Here, ``nx`` and ``ny`` are the number of grid points in the horizontal 
  (``x`` and ``y``) directions, ``num_time_steps`` is the number of time 
  steps in one forecast, and ``num_fcsts`` is the number of forecasts the 
  test runs (see Column 5 below). (Note that this cost calculation does 
  not (yet) differentiate between different physics suites.)  The relative 
  cost ``rel_cost`` is then calculated using:

.. code-block::

    rel_cost = abs_cost/abs_cost_ref

| where ``abs_cost_ref`` is the absolute cost of running the reference forecast 
  described above, i.e., a single (``num_fcsts = 1``) 6-hour forecast 
  (``FCST_LEN_HRS = 6``) on the ``RRFS_CONUS_25km grid`` (which currently has 
  ``nx = 219``, ``ny = 131``, and ``DT_ATMOS = 40 sec`` (so that ``num_time_steps 
  = FCST_LEN_HRS*3600/DT_ATMOS = 6*3600/40 = 540``). Therefore, the absolute cost reference is calculated as:

.. code-block::

    abs_cost_ref = 219*131*540*1 = 15,492,060

| **Column 5**
| The number of times the forecast model will be run by the test. This 
  is calculated using quantities such as the number of :term:`cycle` dates (i.e., 
  forecast model start dates) and the number of ensemble members (which 
  is greater than 1 if running ensemble forecasts and 1 otherwise). The 
  number of cycle dates and/or ensemble members is derived from the quantities listed
  in Columns 6, 7, ....

| **Columns 6, 7, ...**
| The values of various experiment variables (if defined) in each test's 
  configuration file. Currently, the following experiment variables are 
  included:

  |  ``PREDEF_GRID_NAME``
  |  ``CCPP_PHYS_SUITE``
  |  ``EXTRN_MDL_NAME_ICS``
  |  ``EXTRN_MDL_NAME_LBCS``
  |  ``DATE_FIRST_CYCL``
  |  ``DATE_LAST_CYCL``
  |  ``INCR_CYCL_FREQ``
  |  ``FCST_LEN_HRS``
  |  ``DT_ATMOS``
  |  ``LBC_SPEC_INTVL_HRS``
  |  ``NUM_ENS_MEMBERS``

.. _RunWE2E:

Running the WE2E Tests
================================

About the Test Script (``run_WE2E_tests.py``)
-----------------------------------------------

The script to run the WE2E tests is named ``run_WE2E_tests.py`` and is located in the directory ``ufs-srweather-app/tests/WE2E``. Each WE2E test has an associated configuration file named ``config.${test_name}.yaml``, where ``${test_name}`` is the name of the corresponding test. These configuration files are subsets of the full range of ``config.yaml`` experiment configuration options. (See :numref:`Section %s <ConfigWorkflow>` for all configurable options and :numref:`Section %s <UserSpecificConfig>` for information on configuring ``config.yaml`` or any test configuration ``.yaml`` file.) For each test, the ``run_WE2E_tests.py`` script reads in the test configuration file and generates from it a complete ``config.yaml`` file. It then calls the ``generate_FV3LAM_wflow()`` function, which in turn reads in ``config.yaml`` and generates a new experiment for the test. The name of each experiment directory is set to that of the corresponding test, and a copy of ``config.yaml`` for each test is placed in its experiment directory.

.. note::

   The full list of WE2E tests is extensive, and some larger, high-resolution tests are computationally expensive. Estimates of walltime and core-hour cost for each test are provided in :doc:`this table <../../tables/Tests>`. 

Using the Test Script 
----------------------

.. attention::

   These instructions assume that the user has already built the SRW App (as described in :numref:`Section %s <BuildExecutables>`).

First, load the appropriate python environment (as described in :numref:`Section %s <SetUpPythonEnv>`).

The test script has three required arguments: machine, account, and tests. 

   * Users must indicate which machine they are on using the ``--machine`` or ``-m`` option. See :numref:`Section %s <user>` for valid values or check the ``valid_param_vals.yaml`` file.
   * Users must submit a valid account name using the ``--account`` or ``-a`` option to run submitted jobs. On systems where an account name is not required, users may simply use ``-a none``. 
   * Users must specify the set of tests to run using the ``--tests`` or ``-t`` option. Users may pass (in order of priority): 

      #. The name of a single test or list of tests to the test script. 
      #. A test suite name (e.g., "fundamental", "comprehensive", "coverage", or "all").
      #. The name of a subdirectory under ``ufs-srweather-app/tests/WE2E/test_configs/`` 
      #. The name of a text file (full or relative path), such as ``my_tests.txt``, which contains a list of the WE2E tests to run (one per line). 

Users may run ``./run_WE2E_tests.py -h`` for additional (optional) usage instructions. 

Examples
^^^^^^^^^^^

.. attention::

   * Users will need to adjust the machine name and account in these examples to run tests successfully. 
   * These commands assume that the user is working from the ``WE2E`` directory (``ufs-srweather-app/tests/WE2E/``). 

To run the ``custom_ESGgrid`` and ``pregen_grid_orog_sfc_climo`` tests on Jet, users could run: 

.. code-block:: console

   ./run_WE2E_tests.py -t custom_ESGgrid pregen_grid_orog_sfc_climo -m jet -a hfv3gfs

Alternatively, to run the entire suite of fundamental tests on Hera, users might run: 

.. code-block:: console

   ./run_WE2E_tests.py -t fundamental -m hera -a nems

To add ``custom_ESGgrid`` and ``grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16`` to a text file and run the tests in that file on NOAA Cloud, users would enter the following commands:

.. code-block:: console

   echo "custom_ESGgrid" > my_tests.txt
   echo "grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16" > my_tests.txt
   ./run_WE2E_tests.py -t my_tests.txt -m noaacloud -a none

By default, the experiment directory for a WE2E test has the same name as the test itself, and it is created in ``${HOMEdir}/../expt_dirs``, where ``HOMEdir`` is the top-level directory for the ``ufs-srweather-app`` repository (usually set to something like ``/path/to/ufs-srweather-app``). Thus, the ``custom_ESGgrid`` experiment directory would be located in ``${HOMEdir}/../expt_dirs/custom_ESGgrid``.

**A More Complex Example:** To run the fundamental suite of tests on Orion in parallel, charging computational resources to the "gsd-fv3" account, and placing all the experiment directories into a directory named ``test_set_01``, run:

   .. code-block::

      ./run_WE2E_tests.py -t fundamental -m orion -a gsd-fv3 --expt_basedir "test_set_01" -q -p 2

   * ``--expt_basedir``: Useful for grouping sets of tests. If set to a relative path, the provided path will be appended to the default path. In this case, all of the fundamental tests will reside in ``${HOMEdir}/../expt_dirs/test_set_01/``. It can also take a full (absolute) path as an argument, which will place experiments in the given location.
   * ``-q``: Suppresses the output from ``generate_FV3LAM_wflow()`` and prints only important messages (warnings and errors) to the screen. The suppressed output will still be available in the ``log.run_WE2E_tests`` file.
   * ``-p 2``: Indicates the number of parallel proceeses to run. By default, job monitoring and submission is serial, using a single task. Therefore, the script may take a long time to return to a given experiment and submit the next job when running large test suites. Depending on the machine settings, running in parallel can substantially reduce the time it takes to run all experiments. However, it should be used with caution on shared resources (such as HPC login nodes) due to the potential to overwhelm machine resources. 

Workflow Information
^^^^^^^^^^^^^^^^^^^^^^

For each specified test, ``run_WE2E_tests.py`` will generate a new experiment directory and, by default, launch a second function ``monitor_jobs()`` that will continuously monitor active jobs, submit new jobs, and track the success or failure status of the experiment in a ``.yaml`` file. Finally, when all jobs have finished running (successfully or not), the function ``print_WE2E_summary()`` will print a summary of the jobs to screen, including the job's success or failure, timing information, and (if on an appropriately configured platform) the number of core hours used. An example run would look like this: 

.. code-block:: console

   $ ./run_WE2E_tests.py -t my_tests.txt -m hera -a gsd-fv3 -q
   Checking that all tests are valid
   Will run 2 tests:
   /user/home/ufs-srweather-app/tests/WE2E/test_configs/wflow_features/config.custom_ESGgrid.yaml
   /user/home/ufs-srweather-app/tests/WE2E/test_configs/grids_extrn_mdls_suites_community/config.grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.yaml
   Calling workflow generation function for test custom_ESGgrid
   ...
   Workflow for test custom_ESGgrid successfully generated in
   /user/home/expt_dirs/custom_ESGgrid
   
   Calling workflow generation function for test grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
   ...
   Workflow for test grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16 successfully generated in
   /user/home/expt_dirs/grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
   
   calling function that monitors jobs, prints summary
   Writing information for all experiments to WE2E_tests_20230418174042.yaml
   Checking tests available for monitoring...
   Starting experiment custom_ESGgrid running
   Updating database for experiment custom_ESGgrid
   Starting experiment grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16 running
   Updating database for experiment grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
   Setup complete; monitoring 2 experiments
   Use ctrl-c to pause job submission/monitoring
   Experiment custom_ESGgrid is COMPLETE
   Took 0:19:29.877497; will no longer monitor.
   Experiment grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16 is COMPLETE
   Took 0:29:38.951777; will no longer monitor.
   All 2 experiments finished
   Calculating core-hour usage and printing final summary
   ----------------------------------------------------------------------------------------------------
   Experiment name                                                  | Status    | Core hours used 
   ----------------------------------------------------------------------------------------------------
   custom_ESGgrid                                                     COMPLETE              18.02
   grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16   COMPLETE              15.52
   ----------------------------------------------------------------------------------------------------
   Total                                                              COMPLETE              33.54
   
   Detailed summary written to /user/home/expt_dirs/WE2E_summary_20230418181025.txt
   
   All experiments are complete
   Summary of results available in WE2E_tests_20230418174042.yaml

As the script runs, detailed debug output is written to the file ``log.run_WE2E_tests``. This can be useful for debugging if something goes wrong. Adding the ``-d`` flag will print all this output to the screen during the run, but this can get quite cluttered.

The progress of ``monitor_jobs()`` is tracked in a file ``WE2E_tests_{datetime}.yaml``, where {datetime} is the date and time (in ``YYYYMMDDHHmmSS`` format) that the file was created. The final job summary is written by the ``print_WE2E_summary()``; this prints a short summary of experiments to the screen and prints a more detailed summary of all jobs for all experiments in the indicated ``.txt`` file.

.. code-block:: console

   $ cat /user/home/expt_dirs/WE2E_summary_20230418181025.txt
   ----------------------------------------------------------------------------------------------------
   Experiment name                                                  | Status    | Core hours used 
   ----------------------------------------------------------------------------------------------------
   custom_ESGgrid                                                     COMPLETE              18.02
   grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16   COMPLETE              15.52
   ----------------------------------------------------------------------------------------------------
   Total                                                              COMPLETE              33.54

   Detailed summary of each experiment:

   ----------------------------------------------------------------------------------------------------
   Detailed summary of experiment custom_ESGgrid
   in directory /user/home/expt_dirs/custom_ESGgrid
                                           | Status    | Walltime   | Core hours used
   ----------------------------------------------------------------------------------------------------
   make_grid_201907010000                    SUCCEEDED          13.0           0.09
   get_extrn_ics_201907010000                SUCCEEDED          10.0           0.00
   get_extrn_lbcs_201907010000               SUCCEEDED           6.0           0.00
   make_orog_201907010000                    SUCCEEDED          65.0           0.43
   make_sfc_climo_201907010000               SUCCEEDED          39.0           0.52
   make_ics_mem000_201907010000              SUCCEEDED         120.0           1.60
   make_lbcs_mem000_201907010000             SUCCEEDED         201.0           2.68
   run_fcst_mem000_201907010000              SUCCEEDED         340.0          11.33
   run_post_mem000_f000_201907010000         SUCCEEDED          11.0           0.15
   run_post_mem000_f001_201907010000         SUCCEEDED          13.0           0.17
   run_post_mem000_f002_201907010000         SUCCEEDED          16.0           0.21
   run_post_mem000_f003_201907010000         SUCCEEDED          16.0           0.21
   run_post_mem000_f004_201907010000         SUCCEEDED          16.0           0.21
   run_post_mem000_f005_201907010000         SUCCEEDED          16.0           0.21
   run_post_mem000_f006_201907010000         SUCCEEDED          16.0           0.21
   ----------------------------------------------------------------------------------------------------
   Total                                     COMPLETE                         18.02
   
   ----------------------------------------------------------------------------------------------------
   Detailed summary of experiment grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
   in directory /user/home/expt_dirs/grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
                                           | Status    | Walltime   | Core hours used
   ----------------------------------------------------------------------------------------------------
   make_grid_201907010000                    SUCCEEDED           8.0           0.05
   get_extrn_ics_201907010000                SUCCEEDED           5.0           0.00
   get_extrn_lbcs_201907010000               SUCCEEDED          11.0           0.00
   make_orog_201907010000                    SUCCEEDED          49.0           0.33
   make_sfc_climo_201907010000               SUCCEEDED          41.0           0.55
   make_ics_mem000_201907010000              SUCCEEDED          83.0           1.11
   make_lbcs_mem000_201907010000             SUCCEEDED         199.0           2.65
   run_fcst_mem000_201907010000              SUCCEEDED         883.0           9.81
   run_post_mem000_f000_201907010000         SUCCEEDED          10.0           0.13
   run_post_mem000_f001_201907010000         SUCCEEDED          11.0           0.15
   run_post_mem000_f002_201907010000         SUCCEEDED          10.0           0.13
   run_post_mem000_f003_201907010000         SUCCEEDED          11.0           0.15
   run_post_mem000_f004_201907010000         SUCCEEDED          11.0           0.15
   run_post_mem000_f005_201907010000         SUCCEEDED          11.0           0.15
   run_post_mem000_f006_201907010000         SUCCEEDED          12.0           0.16
   ----------------------------------------------------------------------------------------------------
   Total                                     COMPLETE                         15.52


One might have noticed the line during the experiment run that reads "Use ctrl-c to pause job submission/monitoring". The ``monitor_jobs()`` function (called automatically after all experiments are generated) is designed to be easily paused and re-started if necessary. To stop actively submitting jobs, simply quit the script using ``ctrl-c`` to stop the function, and a short message will appear explaining how to continue the experiment:

.. code-block:: console

   Setup complete; monitoring 1 experiments
   Use ctrl-c to pause job submission/monitoring
   ^C

   User interrupted monitor script; to resume monitoring jobs run:

   ./monitor_jobs.py -y=WE2E_tests_20230418174042.yaml -p=1

Checking Test Status and Summary
----------------------------------

By default, ``./run_WE2E_tests.py`` will actively monitor jobs, printing to console when jobs are complete (either successfully or with a failure), and printing a summary file ``WE2E_summary_{datetime.now().strftime("%Y%m%d%H%M%S")}.txt``.
However, if the user is using the legacy crontab option (by submitting ``./run_WE2E_tests.py`` with the ``--launch cron`` option), or if the user would like to summarize one or more experiments that either are not complete or were not handled by the WE2E test scripts, this status/summary file can be generated manually using ``WE2E_summary.py``.
In this example, an experiment was generated using the crontab option and has not yet finished running.
We use the ``-e`` option to point to the experiment directory and get the current status of the experiment:

   .. code-block::

      ./WE2E_summary.py -e /user/home/PR_466/expt_dirs/
    Updating database for experiment grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_HRRR_suite_RRFS_v1beta
    Updating database for experiment grid_RRFS_CONUS_25km_ics_GSMGFS_lbcs_GSMGFS_suite_GFS_v16
    Updating database for experiment grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_HRRR
    Updating database for experiment specify_template_filenames
    Updating database for experiment grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_RAP_suite_HRRR
    Updating database for experiment grid_RRFS_CONUScompact_3km_ics_HRRR_lbcs_RAP_suite_RRFS_v1beta
    Updating database for experiment grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_2017_gfdlmp_regional
    Updating database for experiment grid_SUBCONUS_Ind_3km_ics_HRRR_lbcs_RAP_suite_HRRR
    Updating database for experiment grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
    Updating database for experiment grid_RRFS_SUBCONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
    Updating database for experiment specify_DOT_OR_USCORE
    Updating database for experiment custom_GFDLgrid__GFDLgrid_USE_NUM_CELLS_IN_FILENAMES_eq_FALSE
    Updating database for experiment grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
    ----------------------------------------------------------------------------------------------------
    Experiment name                                             | Status    | Core hours used 
    ----------------------------------------------------------------------------------------------------
    grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_HRRR_suite_RRFS_v1  COMPLETE              49.72
    grid_RRFS_CONUS_25km_ics_GSMGFS_lbcs_GSMGFS_suite_GFS_v16     DYING                  6.51
    grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_HRRR         COMPLETE             411.84
    specify_template_filenames                                    COMPLETE              17.36
    grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_RAP_suite_HRRR      COMPLETE              16.03
    grid_RRFS_CONUScompact_3km_ics_HRRR_lbcs_RAP_suite_RRFS_v1be  COMPLETE             318.55
    grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_2017_g  COMPLETE              17.79
    grid_SUBCONUS_Ind_3km_ics_HRRR_lbcs_RAP_suite_HRRR            COMPLETE              17.76
    grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16      RUNNING                0.00
    grid_RRFS_SUBCONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16   RUNNING                0.00
    specify_DOT_OR_USCORE                                         QUEUED                 0.00
    custom_GFDLgrid__GFDLgrid_USE_NUM_CELLS_IN_FILENAMES_eq_FALS  QUEUED                 0.00
    grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS  QUEUED                 0.00
    ----------------------------------------------------------------------------------------------------
    Total                                                         RUNNING              855.56

    Detailed summary written to WE2E_summary_20230306173013.txt

As with all python scripts in the SRW App, additional options for this script can be viewed by calling with the ``-h`` argument.

The "Status" as specified by the above summary is explained below:

* ``CREATED``
   The experiment directory has been created, but the monitor script has not yet begun submitting jobs. This is immediately overwritten at the beginning of the "monitor_jobs" function, so this status should not be seen unless the experiment has not yet been started.

* ``SUBMITTING``
   All jobs are in status SUBMITTING or SUCCEEDED (as reported by the Rocoto workflow manager). This is a normal state; we will continue to monitor this experiment.

* ``DYING``
   One or more tasks have died (status "DEAD"), so this experiment has had an error. We will continue to monitor this experiment until all tasks are either status DEAD or status SUCCEEDED (see next entry).

* ``DEAD``
   One or more tasks are at status DEAD, and the rest are either DEAD or SUCCEEDED. We will no longer monitor this experiment.

* ``ERROR``
   Could not read the rocoto database file. This will require manual intervention to solve, so we will no longer monitor this experiment.

* ``RUNNING``
   One or more jobs are at status RUNNING, and the rest are either status QUEUED, SUBMITTED, or SUCCEEDED. This is a normal state; we will continue to monitor this experiment.

* ``QUEUED``
   One or more jobs are at status QUEUED, and some others may be at status SUBMITTED or SUCCEEDED. This is a normal state; we will continue to monitor this experiment.

* ``SUCCEEDED``
   All jobs are status SUCCEEDED; we will monitor for one more cycle in case there are unsubmitted jobs remaining.

* ``COMPLETE``
   All jobs are status SUCCEEDED, and we have monitored this job for an additional cycle to ensure there are no unsubmitted jobs. We will no longer monitor this experiment.

Modifying the WE2E System
============================

Users may wish to modify the WE2E testing system to suit specific testing needs.

.. _ModExistingTest:

Modifying an Existing Test
-----------------------------
To modify an existing test, simply edit the configuration file for that test by changing
existing variable values and/or adding new variables to suit the requirements of the
modified test. Such a change may also require modifications to the test description
in the header of the file.


.. _AddNewTest:

Adding a New Test
---------------------
To add a new test named, e.g., ``new_test01``, to one of the existing test categories, such as ``wflow_features``:

#. Choose an existing test configuration file that most closely matches the new test to be added. It could come from any one of the category directories. 

#. Copy that file to ``config.new_test01.yaml`` and, if necessary, move it to the ``wflow_features`` category directory. 

#. Edit the header comments in ``config.new_test01.yaml`` so that they properly describe the new test.

#. Edit the contents of ``config.new_test01.yaml`` by modifying existing experiment variable values and/or adding new variables such that the test runs with the intended configuration.
