.. _WE2E_tests:

==================================
Workflow End-to-End (WE2E) Tests
==================================
The SRW App contains a set of end-to-end tests that exercise various workflow configurations of the SRW App. These are referred to as workflow end-to-end (WE2E) tests because they all use the Rocoto 
workflow manager to run their individual workflows. The purpose of these tests is to 
ensure that new changes to the App do not break existing functionality and capabilities. 

Note that the WE2E tests are not regression tests---they do not check whether 
current results are identical to previously established baselines. They also do
not test the scientific integrity of the results (e.g., they do not check that values 
of output fields are reasonable). These tests only check that the tasks within each test's workflow complete successfully. They are, in essence, tests of the workflow generation, task execution (j-jobs, 
ex-scripts), and other auxiliary scripts (which are mostly in the ``regional_workflow``
repository) to ensure that these scripts function correctly. These functions
include creating and correctly arranging and naming directories and files, ensuring 
that all input files are available and readable, calling executables with correct namelists and/or options, etc. Currently, it is up to the external repositories that the App clones (:numref:`Section %s <SRWStructure>`) to check that changes to those repos do not change results, or, if they do, to ensure that the new results are acceptable. (At least two of these external repositories---``UFS_UTILS`` and ``ufs-weather-model``---do have such regression tests.)  

For convenience, the WE2E tests are currently grouped into the following categories:

* ``grids_extrn_mdls_suites_community``
   This category of tests ensures that the SRW App workflow running in **community mode** (i.e. with ``RUN_ENVIR`` set to ``"community"``) completes successfully for various combinations of predefined grids, physics suites, and external models for ICs and LBCs. Note that in community mode, all output from the App is placed under a single experiment directory.

* ``grids_extrn_mdls_suites_nco``
   This category of tests ensures that the workflow running in **NCO mode** (i.e. with ``RUN_ENVIR`` set to ``"nco"``) completes successfully for various combinations of predefined grids, physics suites, and external models for ICs and LBCs. Note that in NCO mode, an operational run environment (i.e. variable names) is used along with a directory structure in which output is placed in multiple directories (see 
   Sections :numref:`%s <UserSpecificConfig>` and :numref:`%s <NCOModeParms>`).

* ``wflow_features``

   This category of tests ensures that the workflow with various features/capabilities activated
   completes successfully. To reduce computational cost, most tests in this category use coarser grids.

The test configuration files for these categories are located in the following directories, respectively:

.. code-block::

   ufs-srweather-app/regional_workflow/tests/WE2E/test_configs/grids_extrn_mdls_suites_community
   ufs-srweather-app/regional_workflow/tests/WE2E/test_configs/grids_extrn_mdls_suites_nco
   ufs-srweather-app/regional_workflow/tests/WE2E/test_configs/wflow_features

The script to run the WE2E tests is named ``run_WE2E_tests.sh`` and is located in the directory ``ufs-srweather-app/regional_workflow/tests/WE2E``. Each WE2E test has an associated configuration file named ``config.${test_name}.sh``, where ``${test_name}`` is the name of the corresponding test. These configuration files are subsets of the full ``config.sh`` experiment configuration file used in :numref:`Section %s <SetUpConfigFileC>` and described in :numref:`Section %s <UserSpecificConfig>`. For each test, the ``run_WE2E_tests.sh`` script reads in its configuration file and generates from it a complete ``config.sh`` file. It then calls ``generate_FV3LAM_wflow.sh``, which in turn reads in ``config.sh`` and generates a new experiment for the test. The name of each experiment directory is set to that of the corresponding test, and a copy of ``config.sh`` for each test is placed in its experiment directory.

Since ``run_WE2E_tests.sh`` calls ``generate_FV3LAM_wflow.sh`` for each test, the 
Python modules required for experiment generation must be loaded before ``run_WE2E_tests.sh`` 
can be called. See :numref:`Section %s <SetUpPythonEnv>` for information on loading the Python
environment on supported platforms. Note also that ``run_WE2E_tests.sh`` assumes that all of 
the executables have been built. If they have not, then ``run_WE2E_tests.sh`` will still
generate the experiment directories, but the workflows will fail.

Supported Tests
===================

The full list of WE2E tests is extensive; it is not recommended to run all of the tests, as some are computationally expensive. A subset of the tests are supported for the latest release of the SRW Application`. Frequent test cases appear in :numref:`Table %s <FrequentTests>` below, and complete test cases appear :doc:`here <CompleteTests>`. Frequent tests are a lightweight set of tests that can be automated and run regularly on each Level 1 platform. These tests and cover a wide scope of capabilities to ensure that there are no major, obvious faults in the underlying code. Complete tests include the remainder of the supported WE2E tests and cover a fuller list of workflow configurations.

..
   COMMENT: Add file w/supported tests to repo 
   COMMENT: Contrib Guide says that "Fundamental testing consists of a lightweight set of tests that can be automated and run regularly on each Level 1 platform. These are mostly low-resolution tests and cover a wide scope of capabilities to ensure that there are no major, obvious faults in the underlying code. Comprehensive testing includes the entire set of WE2E tests." How would we define frequent v complete? 

.. _FrequentTests:

.. table:: Frequent Test Cases (Supported)

   +------------------+--------+--------+---------------+--------------+---------------------------------------------------------------------+
   | Grid             | ICs    | LBCs   | Physics Suite | Dataset Used | Script Name                                                         |
   +==================+========+========+===============+==============+=====================================================================+
   | CONUS_25km       | FV3GFS | FV3GFS | GFS_v16       | 2019-07-01   | config.grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.sh |
   +------------------+--------+--------+---------------+--------------+---------------------------------------------------------------------+
   | CONUS_13km       | FV3GFS | FV3GFS | GFS_v16       | 2019-07-01   | config.grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.sh |
   +------------------+--------+--------+---------------+--------------+---------------------------------------------------------------------+
   | INDIANAPOLIS_3km | FV3GFS | FV3GFS | GFS_v16       | 2019-06-15   | config.SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.sh     |
   +------------------+--------+--------+---------------+--------------+---------------------------------------------------------------------+
   | INDIANAPOLIS_3km | HRRR   | RAP    | RRFS_v1beta   | 2019-06-15   | config.SUBCONUS_Ind_3km_ics_HRRR_lbcs_RAP_suite_RRFS_v1beta.sh      |
   +------------------+--------+--------+---------------+--------------+---------------------------------------------------------------------+
   | INDIANAPOLIS_3km | HRRR   | RAP    | HRRR          | 2019-06-15   | config.SUBCONUS_Ind_3km_ics_HRRR_lbcs_RAP_suite_HRRR.sh             |
   +------------------+--------+--------+---------------+--------------+---------------------------------------------------------------------+
   | INDIANAPOLIS_3km | HRRR   | RAP    | WoFS          | 2019-06-15   | config.SUBCONUS_Ind_3km_ics_HRRR_lbcs_RAP_suite_WoFS.sh             |
   +------------------+--------+--------+---------------+--------------+---------------------------------------------------------------------+


Running the WE2E Tests
================================

Users may specify the set of tests to run by creating a text file, such as ``my_tests.txt``, which contains a list of the WE2E tests to run (one per line). Then, they pass the name of that file to ``run_WE2E_tests.sh``. For example, to run the tests ``new_ESGgrid`` and ``grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16`` (from the ``wflow_features`` and ``grids_extrn_mdls_suites_community`` categories, respectively), users would enter the following:

.. code-block:: console

   > cat my_tests.txt
   new_ESGgrid
   grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
 

For each test in ``my_tests.txt``, ``run_WE2E_tests.sh`` will generate a new experiment directory and, by default, create a new cron job in the user's cron table that will (re)launch the workflow every 2 minutes. This cron job calls the workflow launch script ``launch_FV3LAM_wflow.sh`` until the workflow either completes successfully (i.e., all tasks are successful) or fails (i.e., at least one task fails). 
The cron job is then removed from the user's cron table.

The examples below demonstrate several common ways that ``run_WE2E_tests.sh`` can be called with the ``my_tests.txt`` file above.

#. To run the tests listed in ``my_tests.txt`` on Hera and charge the computational
   resources used to the "rtrr" account, use:

   .. code-block::

      > run_WE2E_tests.sh tests_file="my_tests.txt" machine="hera" account="rtrr"

   This will create the experiment subdirectories for the two sample WE2E tests in the directory ``${SR_WX_APP_TOP_DIR}/../expt_dirs``, where ``SR_WX_APP_TOP_DIR`` is the directory in which the ufs-srweather-app repository is cloned (usually set to something like ``/path/to/ufs-srweather-app``).
   Thus, the following two experiment directories will be created:

   .. code-block::

      ${SR_WX_APP_TOP_DIR}/../expt_dirs/new_ESGgrid
      ${SR_WX_APP_TOP_DIR}/../expt_dirs/grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16

   In addition, by default, cron jobs will be added to the user's cron table to relaunch the workflows of these experiments every 2 minutes.

#. To change the frequency with which the cron relaunch jobs are submitted
   from the default of 2 minutes to 1 minute, use:

   .. code-block::

      > run_WE2E_tests.sh tests_file="my_tests.txt" machine="hera" account="rtrr" cron_relaunch_intvl_mnts="01"

#. To disable use of cron (which implies the worfkow for each test will have to be relaunched manually from within each experiment directory), use:

   .. code-block::

      > run_WE2E_tests.sh tests_file="my_tests.txt" machine="hera" account="rtrr" use_cron_to_relaunch="FALSE"

   In this case, the user will have to go into each test's experiment directory and either manually call the ``launch_FV3LAM_wflow.sh`` script or use the Rocoto commands described in :numref:`Chapter %s <RocotoInfo>` to (re)launch the workflow. Note that if using the Rocoto commands directly, the log file ``log.launch_FV3LAM_wflow`` will not be created; in this case, the status of the workflow can be checked using the ``rocotostat`` command (see :numref:`Chapter %s <RocotoInfo>`).

#. To place the experiment subdirectories in a subdirectory named ``test_set_01`` under 
   ``${SR_WX_APP_TOP_DIR}/../expt_dirs`` (instead of immediately under the latter), use:

   .. code-block::

      > run_WE2E_tests.sh tests_file="my_tests.txt" machine="hera" account="rtrr" expt_basedir="test_set_01"

   In this case, the full paths to the experiment directories will be:

   .. code-block::

      ${SR_WX_APP_TOP_DIR}/../expt_dirs/test_set_01/new_ESGgrid
      ${SR_WX_APP_TOP_DIR}/../expt_dirs/test_set_01/grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16

   This is useful for grouping various sets of tests.

#. To use a test list file (again named ``my_tests.txt``) located in ``/path/to/custom/location`` instead of in the same directory as ``run_WE2E_tests.sh``, and to have the experiment directories be placed in an arbitrary location, say ``/path/to/custom/expt_dirs``, use:

   .. code-block::

      > run_WE2E_tests.sh tests_file="/path/to/custom/location/my_tests.txt" machine="hera" account="rtrr" expt_basedir="/path/to/custom/expt_dirs"


The full usage statement for ``run_WE2E_tests.sh`` is as follows:

.. code-block::

   run_WE2E_tests.sh \
      tests_file="..." \
      machine="..." \
      account="..." \
      [expt_basedir="..."] \
      [exec_subdir="..."] \
      [use_cron_to_relaunch="..."] \
      [cron_relaunch_intvl_mnts="..."] \
      [verbose="..."] \
      [machine_file="..."] \
      [stmp="..."] \
      [ptmp="..."] \
      [compiler="..."] \
      [build_env_fn="..."]

The arguments in brackets are optional. A complete description of these arguments can be 
obtained by issuing

.. code-block::

   run_WE2E_tests.sh --help

in the directory ``ufs-srweather-app/regional_workflow/tests/WE2E``.


.. _WE2ETestInfoFile:

The WE2E Test Information File
================================
In addition to creating the WE2E tests' experiment directories and optionally creating
cron jobs to launch their workflows, the ``run_WE2E_tests.sh`` script generates (if necessary)
a CSV (Comma-Separated Value) file named ``WE2E_test_info.csv`` that contains information 
on the full set of WE2E tests.  This file serves as a single location where relevant 
information about the WE2E tests can be found. It can be imported into Google Sheets 
using the "|" (pipe symbol) character as the custom field separator. The rows of the 
file/sheet represent the full set of available tests (not just the ones to be run), 
while the columns contain the following information (column titles are included in the CSV file):

| Column 1:
| The primary test name and (in parentheses) the category subdirectory it is
  located in.

| Column 2:
| Any alternate names for the test (if any) followed by their category subdirectories
  (in parentheses).

| Column 3:
| The test description.

| Column 4:
| The number of times the forecast model will be run by the test.  This gives an idea
  of how expensive the test is. It is calculated using quantities such as the number
  of cycle dates (i.e. forecast model start dates) and the number of of ensemble members
  (if running ensemble forecasts). The are in turn obtained directly or indirectly
  from the quantities in Columns 5, 6, ....

| Columns 5,6,...:
| The values of various experiment variables (if defined) in each test's configuration
  file. Currently, the following experiment variables are included:

  |  ``PREDEF_GRID_NAME``
  |  ``CCPP_PHYS_SUITE``
  |  ``EXTRN_MDL_NAME_ICS``
  |  ``EXTRN_MDL_NAME_LBCS``
  |  ``DATE_FIRST_CYCL``
  |  ``DATE_LAST_CYCL``
  |  ``CYCL_HRS``
  |  ``INCR_CYCL_FREQ``
  |  ``FCST_LEN_HRS``
  |  ``LBC_SPEC_INTVL_HRS``
  |  ``NUM_ENS_MEMBERS``

Additional fields (columns) will likely be added to the CSV file in the near future.

Note that the CSV file is not part of the ``regional_workflow`` repo (i.e. it is 
not tracked by the repo). The ``run_WE2E_tests.sh`` script will generate a CSV 
file if (1) the CSV file doesn't already exist, or (2) the CSV file does exist 
but changes have been made to one or more of the category subdirectories (e.g., 
test configuration files modified, added, or deleted) since the creation of the 
CSV file. Thus, ``run_WE2E_tests.sh`` will always create a CSV file the first
time it is run in a fresh git clone of the SRW App.


Checking Test Status
======================
If cron jobs are used to periodically relaunch the tests, the status of each test can be checked by viewing the end of the log file ``log.launch_FV3LAM_wflow`` (since the cron jobs use ``launch_FV3LAM_wflow.sh`` to relaunch the workflow, and that in turn generates the log files).  Otherwise (or alternatively), the ``rocotorun``/``rocotostat`` combination of commands can be used. See :numref:`Section %s <RocotoRun>` for details.  

The SRW App also provides the script ``get_expts_status.sh`` in the directory 
``ufs-srweather-app/regional_workflow/tests/WE2E``, which can be used to generate 
a status summary for all tests in a given base directory. This script updates
the workflow status of each test (by internally calling ``launch_FV3LAM_wflow.sh``)
and then prints out to the command prompt the status of the various tests. It also creates 
a status report file named ``expts_status_${create_date}.txt`` (where ``create_date``
is a time stamp of the form ``YYYYMMDDHHmm`` corresponding to the creation date/time
of the report) and places it in the experiment base directory. This status file 
contains the last 40 lines (by default; this can be adjusted via the ``num_log_lines``
argument) from the end of each ``log.launch_FV3LAM_wflow`` log file. These lines include the experiment status as well as the task status table generated by ``rocotostat`` (so that, in 
case of failure, it is convenient to pinpoint the task that failed).
For details on the usage of ``get_expts_stats.sh``, issue the command:

.. code-block::

   > get_expts_status.sh --help

Here is an example of how to call ``get_expts_status.sh`` along with sample output:

.. code-block::  console

   > ./get_expts_status.sh expts_basedir=/path/to/expt_dirs/set01
   Checking for active experiment directories in the specified experiments
   base directory (expts_basedir):
     expts_basedir = "/path/to/expt_dirs/set01"
   ...
   
   The number of active experiments found is:
     num_expts = 2
   The list of experiments whose workflow status will be checked is:
     'new_ESGgrid'
     'grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16'

   ======================================
   Checking workflow status of experiment "new_ESGgrid" ...
   Workflow status:  SUCCESS
   ======================================

   ======================================
   Checking workflow status of experiment "grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16" ...
   Workflow status:  IN PROGRESS
   ======================================

   A status report has been created in:
      expts_status_fp = "/path/to/expt_dirs/set01/expts_status_202204211440.txt"

   DONE.


The "Workflow status" field of each test indicates the status of its workflow. 
The values that this can take on are "SUCCESS", "FAILURE", and "IN PROGRESS".


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
To add a new test named, for example ``new_test01``, to one of the existing categories listed
above, such as ``wflow_features``:

#. Choose an existing test configuration file in any one of the category directories that matches most closely the new test to be added. Copy that file to ``config.new_test01.sh`` and, if necessary, move it to the ``wflow_features`` category directory. 

#. Edit ``config.new_test01.sh`` so that the header containing the test description properly describes the new test.

#. Further edit ``config.new_test01.sh`` by modifying existing experiment variable values and/or adding new variables such that the test runs with the intended configuration.


.. _AddNewCategory:

Adding a New WE2E Test Category
-----------------------------------
To create a new test category called, e.g., ``new_category``:

#. In the directory ``ufs-srweather-app/regional_workflow/tests/WE2E/test_configs``, create a new directory named ``new_category``. 

#. In the file ``get_WE2Etest_names_subdirs_descs.sh``, add the element ``"new_category"`` to the array ``category_subdirs`` that contains the list of categories/subdirectories in which to search for test configuration files. Thus, ``category_subdirs`` becomes:

   .. code-block:: console

     category_subdirs=( \
       "." \
       "grids_extrn_mdls_suites_community" \
       "grids_extrn_mdls_suites_nco" \
       "wflow_features" \
       "new_category" \
       )

New tests can now be added to ``new_category`` using the procedure described in :numref:`Section %s <AddNewTest>`.


.. _CreateAltTestNames:

Creating Alternate Names for a Test
--------------------------------------
To prevent proliferation of WE2E tests, users might want to use the same test for multiple purposes. For example, consider the test 

   ``grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16`` 

in the ``grids_extrn_mdls_suites_community`` category. This checks for the successful
completion of the Rocoto workflow running the combination of the ``RRFS_CONUScompact_25km`` grid, the ``FV3GFS`` model for ICs and LBCs, and the ``FV3_GFS_v16`` physics suite. If this test also
happens to use the inline post capability of the weather model (it currently doesn't; this is only a hypothetical example), then this test can also be used to ensure that the inline post feature of the App/Weather Model (which is activated in the App by setting ``WRITE_DOPOST`` to ``"TRUE"``) is working properly.
Since this test will serve two purposes, it should have two names --- one per purpose. To set the second (alternate) name to ``activate_inline_post``, the user needs to create a symlink named ``config.activate_inline_post.sh`` in the ``wflow_features`` category directory that points to the configuration file 

  ``config.grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.sh``

in the ``grids_extrn_mdls_suites_community`` category directory. 

.. code-block:: console

   ln -fs --relative </path/to/grids_extrn_mdls_suites_community/config.grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.sh> </path/to/wflow_features/config.activate_inline_post.sh>

In this situation, the primary name for the test is ``grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16`` 
(because ``config.grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16.sh`` is an actual file, not a symlink), and ``activate_inline_post`` is an alternate name. This approach of allowing multiple names for the same test makes it easier to identify the multiple purposes that a test may serve. 

Note the following:

* A primary test can have more than one alternate test name (by having more than one symlink point to the test's configuration file).
* The symlinks representing the alternate test names can be in the same or a different category directory.
* The --relative flag makes the symlink relative (i.e., within/below the ``regional_workflow`` directory structure) so that it stays valid when copied to other locations. However, the ``--relative`` flag may be different and/or not exist on every platform.
* To determine whether a test has one or more alternate names, a user can 
  view the CSV file ``WE2E_test_info.csv`` that ``run_WE2E_tests.sh`` generates. 
  Recall from :numref:`Section %s <WE2ETestInfoFile>` that column 1 of this CSV 
  file contains the test's primary name (and its category) while column 2 contains 
  any alternate names (and their categories).
* With this primary/alternate test naming convention, a user can list either the 
  primary test name or one of the alternate test names in the experiments list file 
  (e.g. ``my_tests.txt``) that ``run_WE2E_tests.sh`` reads in. If both primary and 
  one or more alternate test names are listed, then ``run_WE2E_tests.sh`` will exit 
  with a warning message without running any tests.

