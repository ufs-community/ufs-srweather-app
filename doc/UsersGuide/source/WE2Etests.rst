.. _WE2E_tests:

==================================
Workflow End-to-End (WE2E) Tests
==================================
The SRW App contains a set of end-to-end tests that exercise various workflow configurations of the SRW App. These are referred to as workflow end-to-end (WE2E) tests because they all use the Rocoto workflow manager to run their individual workflows from start to finish. The purpose of these tests is to ensure that new changes to the App do not break existing functionality and capabilities. 

Note that the WE2E tests are not regression tests---they do not check whether 
current results are identical to previously established baselines. They also do
not test the scientific integrity of the results (e.g., they do not check that values 
of output fields are reasonable). These tests only check that the tasks within each test's workflow complete successfully. They are, in essence, tests of the workflow generation, task execution (j-jobs, 
ex-scripts), and other auxiliary scripts to ensure that these scripts function correctly. Tested functions
include creating and correctly arranging and naming directories and files, ensuring 
that all input files are available and readable, calling executables with correct namelists and/or options, etc. Currently, it is up to the external repositories that the App clones (:numref:`Section %s <SRWStructure>`) to check that changes to those repositories do not change results, or, if they do, to ensure that the new results are acceptable. (At least two of these external repositories---``UFS_UTILS`` and ``ufs-weather-model``---do have such regression tests.)

WE2E tests fall into one of two categories: fundamental or comprehensive. The list of supported fundamental and comprehensive tests can be viewed in ``ufs-srweather-app/tests/WE2E/machine_suites/``. Fundamental tests are a lightweight set of tests that can be automated and run regularly on each `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ platform. These tests verify that there are no major, obvious faults in the underlying code when running common combinations of grids, input data, and physics suites. The remaining tests are called comprehensive tests because they cover a broader range of capabilities, configurations, and components. The complete set of tests (fundamental and comprehensive) can be viewed in :doc:`this table <tables/Tests>`.

For convenience, the WE2E tests are currently grouped into the following categories (under ``ufs-srweather-app/tests/WE2E/test_configs``):

* ``grids_extrn_mdls_suites_community``
   This category of tests ensures that the SRW App workflow running in **community mode** (i.e., with ``RUN_ENVIR`` set to ``"community"``) completes successfully for various combinations of predefined grids, physics suites, and input data from different external models. Note that in community mode, all output from the Application is placed under a single experiment directory.

* ``grids_extrn_mdls_suites_nco``
   This category of tests ensures that the workflow running in **NCO mode** (i.e., with ``RUN_ENVIR`` set to ``"nco"``) completes successfully for various combinations of predefined grids, physics suites, and input data from different external models. Note that in NCO mode, an operational run environment is used. This involves a specific directory structure and variable names (see :numref:`Section %s <NCOModeParms>`).

* ``wflow_features``
   This category of tests ensures that the workflow completes successfully with particular features/capabilities activated. To reduce computational cost, most tests in this category use coarser grids.

The test configuration files for these categories are located in the following directories, respectively:

.. code-block::

   ufs-srweather-app/tests/WE2E/test_configs/grids_extrn_mdls_suites_community
   ufs-srweather-app/tests/WE2E/test_configs/grids_extrn_mdls_suites_nco
   ufs-srweather-app/tests/WE2E/test_configs/wflow_features

The script to run the WE2E tests is named ``run_WE2E_tests.py`` and is located in the directory ``ufs-srweather-app/tests/WE2E``. Each WE2E test has an associated configuration file named ``config.${test_name}.yaml``, where ``${test_name}`` is the name of the corresponding test. These configuration files are subsets of the full range of ``config.yaml`` experiment configuration options. (See :numref:`Chapter %s <ConfigWorkflow>` for all configurable options and :numref:`Section %s <UserSpecificConfig>` for information on configuring ``config.yaml``.) For each test, the ``run_WE2E_tests.py`` script reads in the test configuration file and generates from it a complete ``config.yaml`` file. It then calls the ``generate_FV3LAM_wflow()`` function, which in turn reads in ``config.yaml`` and generates a new experiment for the test. The name of each experiment directory is set to that of the corresponding test, and a copy of ``config.yaml`` for each test is placed in its experiment directory.

As with any other experiment within the App, the 
Python modules required for experiment generation must be loaded before ``run_WE2E_tests.py`` 
can be called. See :numref:`Section %s <SetUpPythonEnv>` for information on loading the Python
environment on supported platforms. Note also that ``run_WE2E_tests.py`` assumes that all of 
the executables have been built (see :numref:`Section %s <BuildExecutables>`). If they have not, then ``run_WE2E_tests.py`` will still generate the experiment directories, but the workflows will fail.

Supported Tests
===================

The full list of WE2E tests is extensive; it is not recommended to run all the tests, as some are computationally expensive. A subset of the full WE2E test suite is supported for the latest release of the SRW Application. Supported test cases can be viewed in :doc:`this table <tables/Tests>`. 

Running the WE2E Tests
================================

Users may specify the set of tests to run in one of three ways. First, users can pass the name of a single test or list of tests to the script. Secondly, they can pass an option to run the ``fundamental`` or ``comprehensive`` suite of tests, or ``all`` tests (not recommended). Finally, users can create a text file, such as ``my_tests.txt``, which contains a list of the WE2E tests to run (one per line). Any one of these options can be passed to the ``run_WE2E_tests.py`` script via the ``--tests`` or ``-t`` option. 

For example, to run the tests ``custom_ESGgrid`` and ``grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16`` (from the ``wflow_features`` and ``grids_extrn_mdls_suites_community`` categories, respectively), users would enter the following commands from the ``WE2E`` working directory (``ufs-srweather-app/tests/WE2E/``):

.. code-block:: console

   echo "custom_ESGgrid" > my_tests.txt
   echo "grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16" >> my_tests.txt

For each specified test, ``run_WE2E_tests.py`` will generate a new experiment directory and, by default, launch a second function ``monitor_jobs()`` that will continuously monitor active jobs, submit new jobs, and track the success or failure status of the experiment in a ``.yaml`` file. Finally, when all jobs have finished running (successfully or not), the function ``print_WE2E_summary()`` will print a summary of the jobs to screen, including the job's success or failure, timing information, and (if on an appropriately configured platform) the number of core hours used. An example run would look like this: 

.. code-block:: console

   $ ./run_WE2E_tests.py -t custom_ESGgrid -m hera -a gsd-fv3 --expt_basedir "test_set_01" -q
   Checking that all tests are valid
   Will run 1 tests:
   /user/home/ufs-srweather-app/tests/WE2E/test_configs/wflow_features/config.custom_ESGgrid.yaml
   Calling workflow generation function for test custom_ESGgrid

   Workflow for test custom_ESGgrid successfully generated in
   /user/home/expt_dirs/test_set_01/custom_ESGgrid

   calling function that monitors jobs, prints summary
   Writing information for all experiments to WE2E_tests_20230302214843.yaml
   Checking tests available for monitoring...
   Starting experiment custom_ESGgrid running
   Updating database for experiment custom_ESGgrid
   Setup complete; monitoring 1 experiments
   Use ctrl-c to pause job submission/monitoring
   Experiment custom_ESGgrid is COMPLETE; will no longer monitor.
   All 1 experiments finished in 0:13:50.851855
   Calculating core-hour usage and printing final summary
   ----------------------------------------------------------------------------------------------------
   Experiment name                                             | Status    | Core hours used 
   ----------------------------------------------------------------------------------------------------
   custom_ESGgrid                                                COMPLETE              35.92
   ----------------------------------------------------------------------------------------------------
   Total                                                         COMPLETE              35.92

   Detailed summary written to WE2E_summary_20230302220233.txt

   All experiments are complete
   Summary of results available in WE2E_tests_20230302214843.yaml


As the script runs, detailed debug output is written to the file ``log.run_WE2E_tests``. This can be useful for debugging if something goes wrong. You can also use the ``-d`` flag to print all this output to screen during the run, but this can get quite cluttered.

The final job summary is written by the ``print_WE2E_summary()``; this prints a short summary of experiments to screen, and prints a more detailed summary of all jobs for all experiments in the indicated ``.txt`` file.

.. code-block:: console

   $ cat WE2E_summary_20230302220233.txt
   ----------------------------------------------------------------------------------------------------
   Experiment name                                             | Status    | Core hours used 
   ----------------------------------------------------------------------------------------------------
   custom_ESGgrid                                                COMPLETE              35.92
   ----------------------------------------------------------------------------------------------------
   Total                                                         COMPLETE              35.92

   Detailed summary of each experiment:

   ----------------------------------------------------------------------------------------------------
   Detailed summary of experiment custom_ESGgrid
                                            | Status    | Walltime   | Core hours used
   ----------------------------------------------------------------------------------------------------
   make_grid_201907010000                    SUCCEEDED          12.0           0.13
   get_extrn_ics_201907010000                SUCCEEDED           7.0           0.08
   get_extrn_lbcs_201907010000               SUCCEEDED           6.0           0.07
   make_orog_201907010000                    SUCCEEDED          62.0           0.69
   make_sfc_climo_201907010000               SUCCEEDED          41.0           0.91
   make_ics_201907010000                     SUCCEEDED         180.0           8.00
   make_lbcs_201907010000                    SUCCEEDED         228.0          10.13
   run_fcst_201907010000                     SUCCEEDED         208.0          13.87
   run_post_f000_201907010000                SUCCEEDED          15.0           0.33
   run_post_f001_201907010000                SUCCEEDED          15.0           0.33
   run_post_f002_201907010000                SUCCEEDED          15.0           0.33
   run_post_f003_201907010000                SUCCEEDED          12.0           0.27
   run_post_f004_201907010000                SUCCEEDED          12.0           0.27
   run_post_f005_201907010000                SUCCEEDED          11.0           0.24
   run_post_f006_201907010000                SUCCEEDED          12.0           0.27
   ----------------------------------------------------------------------------------------------------
   Total                                     COMPLETE                         35.92


One might have noticed the line during the experiment run that reads "Use ctrl-c to pause job submission/monitoring". The ``monitor_jobs()`` function (called automatically after all experiments are generated) is designed to be easily paused and re-started if necessary. If you wish to stop actively submitting jobs, simply quitting the script using "ctrl-c" will stop the function, and give a short message on how to continue the experiment.

.. code-block:: console

   Setup complete; monitoring 1 experiments
   Use ctrl-c to pause job submission/monitoring
   ^C


   User interrupted monitor script; to resume monitoring jobs run:

   ./monitor_jobs.py -y=WE2E_tests_20230302214324.yaml -p=1

The full list of options for any of these scripts can be found by using the ``-h`` flag. The examples below demonstrate several of the more common options for ``run_WE2E_tests.py``. These examples (as well as those above) assume that the user has already built the SRW App and loaded the appropriate python environment as described in :numref:`Section %s <SetUpPythonEnv>`.

#. To run the tests listed in ``my_tests.txt`` on Hera and charge the computational
   resources used to the "rtrr" account:

   .. code-block::

      ./run_WE2E_tests.py --tests=my_tests.txt --machine=hera --account=rtrr

   This will create the experiment subdirectories for the two sample WE2E tests in the directory ``${HOMEaqm}/../expt_dirs``, where ``HOMEaqm`` is the top-level directory for the ufs-srweather-app repository (usually set to something like ``/path/to/ufs-srweather-app``). Thus, the following two experiment directories will be created:

   .. code-block::

      ${HOMEaqm}/../expt_dirs/custom_ESGgrid
      ${HOMEaqm}/../expt_dirs/grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16

   Once these experiment directories are created, the script will call the ``monitor_jobs()`` function. This function runs ``rocotorun`` in the background to monitor the status of jobs in each experiment directory, tracking the status of jobs as they run and complete, and submitting new jobs when they are ready. The progress of ``monitor_jobs()`` is tracked in a file ``WE2E_tests_{datetime}.yaml``, where {datetime} is the date and time (in ``yyyymmddhhmmss`` format) that the file was created.

#. Our second example will run the fundamental suite of tests on Orion, charging computational resources to the "gsd-fv3" account, and placing the experiment subdirectories in a subdirectory named ``test_set_01``:

   .. code-block::

      ./run_WE2E_tests.py -t fundamental -m hera -a gsd-fv3 --expt_basedir "test_set_01" -q

   In this case, the full paths to the experiment directories will be:

   .. code-block::

      ${HOMEaqm}/../expt_dirs/test_set_01/grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2
      ${HOMEaqm}/../expt_dirs/test_set_01/grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
      ${HOMEaqm}/../expt_dirs/test_set_01/grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_RAP_suite_HRRR
      ${HOMEaqm}/../expt_dirs/test_set_01/grid_RRFS_CONUS_25km_ics_GSMGFS_lbcs_GSMGFS_suite_GFS_v15p2
      ${HOMEaqm}/../expt_dirs/test_set_01/grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_HRRR_suite_HRRR
      ${HOMEaqm}/../expt_dirs/test_set_01/grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_HRRR_suite_RRFS_v1beta
      ${HOMEaqm}/../expt_dirs/test_set_01/grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_RAP_suite_HRRR
      ${HOMEaqm}/../expt_dirs/test_set_01/grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_RAP_suite_RRFS_v1beta
      ${HOMEaqm}/../expt_dirs/test_set_01/nco_grid_RRFS_CONUScompact_25km_ics_HRRR_lbcs_RAP_suite_HRRR

   The ``--expt_basedir`` option is useful for grouping various sets of tests. It can also be given a full path as an argument, which will place experiments in the given location. 

   The ``-q`` flag (as used in the first example shown above), is helpful for keeping the screen less cluttered; this will suppress the output from ``generate_FV3LAM_wflow()``, only printing important messages (warnings and errors) to screen. As always, this output will still be available in the ``log.run_WE2E_tests`` file.

#. By default, the job monitoring and submission process is serial, using a single task. For test suites that contain many experiments, this means that the script may take a long time to return to a given experiment and submit the next job, due to the amount of time it takes for the ``rocotorun`` command to complete. In order to speed this process up, provided you have access to a node with the appropriate availability (e.g., submitting from a compute node), you can run the job monitoring processes in parallel using the ``-p`` option:

   .. code-block::

      ./run_WE2E_tests.py -m=jet -a=gsd-fv3-dev -t=all -q -p 6

   Depending on your machine settings, this can reduce the time it takes to run all experiments substantially. 

#. This example will run the single experiment "custom_ESGgrid" on Hera, charging computational resources to the "fv3lam" account. For this example, we submit the suite of tests using the legacy :term:`cron`-based system:

.. note::

   This option is not recommended, as it does not work on some machines and can cause system bottlenecks on others.

   .. code-block::

      ./run_WE2E_tests.py -t=custom_ESGgrid -m=hera -a=fv3lam --use_cron_to_relaunch --cron_relaunch_intvl_mnts=1

The option ``--use_cron_to_relaunch`` means that, rather than calling the ``monitor_jobs()`` function, the ``generate_FV3LAM_wflow()`` function will create a new :term:`cron` job in the user's cron table that will launch the experiment with the workflow launch script (``launch_FV3LAM_wflow.sh``). By default this script is run every 2 minutes, but we have changed that to 1 minute with the ``--cron_relaunch_intvl_mnts=1`` argument. This script will run until the workflow either completes successfully (i.e., all tasks SUCCEEDED) or fails (i.e., at least one task fails). The cron job is then removed from the user's cron table.


Checking test status and summary
=================================
By default, ``./run_WE2E_tests.py`` will actively monitor jobs, printing to screen when jobs are complete (either successfully or with a failure), and print a summary file ``WE2E_summary_{datetime.now().strftime("%Y%m%d%H%M%S")}.txt``.
However, if the user is using the legacy crontab option, or would like to summarize one or more experiments that are either not complete or were not handled by the WE2E test scripts, this status/summary file can be generated manually using ``WE2E_summary.py``.
In this example, an experiment was generated using the crontab option, and has not yet finished running.
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

As with all python scripts in the App, additional options for this script can be viewed by calling with the ``-h`` argument.


.. _WE2ETestInfoFile:

WE2E Test Information File
==================================

If the user wants to see consolidated test information, they can generate a file that can be imported into a spreadsheet program (Google Sheets, Microsoft Excel, etc.) that summarizes each test. This file, named ``WE2E_test_info.txt`` by default, is delimited by the ``|`` character, and can be created either by running the ``./print_test_info.py`` script, or by generating an experiment using ``./run_WE2E_tests.py`` with the ``--print_test_info`` flag.

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
  test runs (see Column 5 below).  [Note that this cost calculation does 
  not (yet) differentiate between different physics suites.]  The relative 
  cost ``rel_cost`` is then calculated using

.. code-block::

    rel_cost = abs_cost/abs_cost_ref

| where ``abs_cost_ref`` is the absolute cost of running the reference forecast 
  described above, i.e., a single (``num_fcsts = 1``) 6-hour forecast 
  (``FCST_LEN_HRS = 6``) on the ``RRFS_CONUS_25km grid`` (which currently has 
  ``nx = 219``, ``ny = 131``, and ``DT_ATMOS =  40 sec`` (so that ``num_time_steps 
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


Modifying the WE2E System
============================
This section describes various ways in which the WE2E testing system can be modified 
to suit specific testing needs.


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

#. Choose an existing test configuration file in any one of the category directories that matches most closely the new test to be added. Copy that file to ``config.new_test01.yaml`` and, if necessary, move it to the ``wflow_features`` category directory. 

#. Edit the header comments in ``config.new_test01.yaml`` so that they properly describe the new test.

#. Edit the contents of ``config.new_test01.yaml`` by modifying existing experiment variable values and/or adding new variables such that the test runs with the intended configuration.


.. _CreateAltTestNames:

Creating Alternate Names for a Test
--------------------------------------
To prevent proliferation of WE2E tests, users might want to use the same test for multiple purposes. For example, consider the test 

   ``grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16`` 

in the ``grids_extrn_mdls_suites_community`` category. This checks for the successful
completion of the Rocoto workflow running a combination of the ``RRFS_CONUScompact_25km`` grid, the ``FV3GFS`` model data for :term:`ICs` and :term:`LBCs`, and the ``FV3_GFS_v16`` physics suite. If this test also happens to use the inline post capability of the UFS :term:`Weather Model` (it currently doesn't; this is only a hypothetical example), then this test can also be used to ensure that the inline post feature of the SRW App/Weather Model (which is activated in the SRW App by setting ``WRITE_DOPOST: true``) is working properly. Since this test will serve two purposes, it should have two names --- one per purpose.

To set the second (alternate) name to ``activate_inline_post``, the user needs to create a symlink named ``config.activate_inline_post.yaml`` in the ``wflow_features`` category directory that points to the original configuration file (``config.grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.yaml``) in the ``grids_extrn_mdls_suites_community`` category directory: 

.. code-block:: console

   ln -fs --relative </path/to/grids_extrn_mdls_suites_community/config.grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.yaml> </path/to/wflow_features/config.activate_inline_post.yaml>

In this situation, the primary name for the test is ``grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16`` 
(because ``config.grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.yaml`` is an actual file, not a symlink), and ``activate_inline_post`` is an alternate name. This approach of allowing multiple names for the same test makes it easier to identify the multiple purposes that a test may serve. 

.. note::

   * A primary test can have more than one alternate test name (by having more than one symlink pointing to the test's configuration file).
   * The symlinks representing the alternate test names can be in the same or a different category directory.
   * The ``--relative`` flag makes the symlink relative (i.e., within/below the ``tests`` directory) so that it stays valid when copied to other locations. (Note, however, that this flag is platform-dependent and may not exist on some platforms.)
   * To determine whether a test has one or more alternate names, a user can view the file ``WE2E_test_info.txt`` as described in :numref:`Section %s <WE2ETestInfoFile>`
   * With this primary/alternate test naming convention via symbolic links, if more than one name is listed for the same test (e.g., the primary name and and an alternate name, two alternate names, etc.), ``run_WE2E_tests.py`` will only run the test once 


