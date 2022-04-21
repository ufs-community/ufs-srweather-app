.. _WE2E_tests:

================================
Workflow End-to-End (WE2E) Tests
================================
The SRW App's experiment generation system contains a set of end-to-end tests that 
exercise various configurations of that system as well as those of the pre-processing, 
UFS Weather Model, UPP post-processing, and MET/METPlus verification scripts and codes. 
These are referred to as workflow end-to-end (WE2E) tests.  The script to run these tests is named 
``run_WE2E_tests.sh`` and is located in the directory ``ufs-srweather-app/regional_workflow/tests/WE2E``.

Each WE2E test has associated with it a configuration file named ``config.${test_name}.sh``, 
where ``${test_name}`` is the name of the corresponding test. 
These configuration files are subsets of
the full ``config.sh`` experiment configuration file used in :numref:`Section %s <SetUpConfigFileC>` 
and described in :numref:`Section %s <UserSpecificConfig>`.  For each test that the user wants 
to run, the ``run_WE2E_tests.sh`` script reads in its configuration file and generates from 
it a complete ``config.sh`` file.  It then calls ``generate_FV3LAM_wflow.sh``, which in turn
reads in ``config.sh`` and generates a new experiment for the test.  
The name of each experiment directory is set to that of the corresponding test, 
and a copy of ``config.sh`` for each test is placed in its experiment directory.

The WE2E tests are currently grouped into the following categories:

* ``grids_extrn_mdls_suites_community``

  This category of tests ensures that the SRW App workflow running in **community mode**
  completes successfully for various combinations of predefined grids, physics
  suites, and external models for ICs and LBCs.

* ``grids_extrn_mdls_suites_nco``

  This category of tests ensures that the workflow running in **NCO mode** (i.e. using
  an operational environment and directory structure) 
  completes successfully for various combinations of predefined grids, physics
  suites, and external models for ICs and LBCs.

* ``wflow_features``

  This category of tests ensures that the workflow with various features/capabilities activated
  completes successfully.  Thus, their focus is the various scripts in the ``ufs-srweather-app``
  and ``regional_workflow`` repositories.  To reduce computational cost, these tests generally 
  use coarser grids.

The test configuration files for these categories are located in the following directories,
respectively:

.. code-block::

    ufs-srweather-app/regional_workflow/tests/WE2E/test_configs/grids_extrn_mdls_suites_community
    ufs-srweather-app/regional_workflow/tests/WE2E/test_configs/grids_extrn_mdls_suites_nco
    ufs-srweather-app/regional_workflow/tests/WE2E/test_configs/wflow_features

Since ``run_WE2E_tests.sh`` calls ``generate_FV3LAM_wflow.sh`` for each test, the 
Python modules required for experiment generation must be loaded before ``run_WE2E_tests.sh`` 
can be called.  See :numref:`Section %s <SetUpPythonEnv>` for information on loading the Python
environment on supported platforms.  Note also that ``run_WE2E_tests.sh`` assumes that all of 
the executables have been built.  If they are not, then ``run_WE2E_tests.sh`` will still
generate the experiment directories, but the workflows will fail.

Running the WE2E Tests
----------------------

The user specifies the set of tests that ``run_WE2E_tests.sh`` will run by creating a text 
file, say ``my_tests.txt``, that contains a list of the WE2E tests to run (one per line) 
and passing the name of that file to ``run_WE2E_tests.sh``.  For example, if the user
wants to run the tests ``new_ESGgrid`` and ``grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16``
(from the ``wflow_features`` and ``grids_extrn_mdls_suites_community`` categories, respectively), we would have:

.. code-block:: console

    > cat my_tests.txt
    new_ESGgrid
    grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16
 

For each test in ``my_tests.txt``, ``run_WE2E_tests.sh``
will generate a new experiment directory and, by default, create a new cron job in the user's cron
table that will (re)launch the workflow every two minutes.  This cron job calls the workflow launch script 
``launch_FV3LAM_wflow.sh`` located in the experiment directory until the workflow either 
completes successfully (i.e. all tasks are successful) or fails (i.e. at least one task fails). 
The cron job is then removed from the user's cron table.

Next, we show several common ways that ``run_WE2E_tests.sh`` may be called with
the ``my_tests.txt`` file above.

1) To run the tests listed in ``my_tests.txt`` on Hera and charge the computational
   resources used to the "rtrr" account, use:

   .. code-block::

       > run_WE2E_tests.sh tests_file="my_tests.txt" machine="hera" account="rtrr"

   This will create the experiment subdirectories for the two tests in
   the directory

   .. code-block::

     ${SR_WX_APP_TOP_DIR}/../expt_dirs

   where ``SR_WX_APP_TOP_DIR`` is the directory in which the ufs-srweather-app 
   repository is cloned (usually set to something like ``/path/to/ufs-srweather-app``).
   Thus, the following two experiment directories will be created:

   .. code-block::

     ${SR_WX_APP_TOP_DIR}/../expt_dirs/new_ESGgrid
     ${SR_WX_APP_TOP_DIR}/../expt_dirs/grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16

   In addition, by default, cron jobs will be added to the user's cron
   table to relaunch the workflows of these experiments every 2 minutes.

2) To change the frequency with which the cron relaunch jobs are submitted
   from the default of 2 minutes to 1 minute, use:

   .. code-block::

     > run_WE2E_tests.sh tests_file="my_tests.txt" machine="hera" account="rtrr" cron_relaunch_intvl_mnts="01"

3) To disable use of cron (which implies the worfkow for each test will 
   have to be relaunched manually from within each experiment directory),
   use:

   .. code-block::

     > run_WE2E_tests.sh tests_file="my_tests.txt" machine="hera" account="rtrr" use_cron_to_relaunch="FALSE"

   In this case, the user will have to go into each test's experiment directory and 
   either manually call the ``launch_FV3LAM_wflow.sh`` script or use the Rocoto commands described 
   in :numref:`Chapter %s <RocotoInfo>` to (re)launch the workflow.  Note that if using the Rocoto
   commands directly, the log file ``log.launch_FV3LAM_wflow`` will not be created; in this case, 
   the status of the workflow can be checked using the ``rocotostat`` command (see :numref:`Chapter %s <RocotoInfo>`).

4) To place the experiment subdirectories in a subdirectory named ``test_set_01`` under 
   ``${SR_WX_APP_TOP_DIR}/../expt_dirs`` (instead of immediately under the latter), use:

   .. code-block::

     > run_WE2E_tests.sh tests_file="my_tests.txt" machine="hera" account="rtrr" expt_basedir="test_set_01"

   In this case, the full paths to the experiment directories will be:

   .. code-block::

     ${SR_WX_APP_TOP_DIR}/../expt_dirs/test_set_01/new_ESGgrid
     ${SR_WX_APP_TOP_DIR}/../expt_dirs/test_set_01/grid_RRFS_CONUScompact_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v16

   This is useful for grouping various sets of tests.

5) To use a test list file (again named ``my_tests.txt``) located in ``/path/to/custom/location`` 
   instead of in the same directory as ``run_WE2E_tests.sh``, and to have the experiment directories 
   be placed in an arbitrary location, say ``/path/to/custom/expt_dirs``, use:

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

The arguments in brackets are optional.  A complete description of these arguments can be 
obtained by issuing

.. code-block::

  run_WE2E_tests.sh --help

in the directory ``ufs-srweather-app/regional_workflow/tests/WE2E``.




Checking Test Status
--------------------
If cron jobs are being used to periodically relaunch the tests, the status of
each test can be checked by viewing the end of the log file ``log.launch_FV3LAM_wflow``
(since the cron jobs use ``launch_FV3LAM_wflow.sh`` for this purpose, which 
generates that log file).  Otherwise (or alternatively), the ``rocotorun``/``rocotostat``
combination of commands can be used.  See :numref:`Section %s <RocotoRun>` for
details.  

The App also provides the script ``get_expts_status.sh`` in the directory 
``ufs-srweather-app/regional_workflow/tests/WE2E`` that can be used to generate 
a status summary for all tests in a given base directory.  This script updates
the workflow status of each test (by internally calling ``launch_FV3LAM_wflow.sh``)
and then prints out to screen the status of the various tests.  It also creates 
a status report file named ``expts_status_${create_date}.txt`` (where ``create_date``
is a time stamp of the form ``YYYYMMDDHHmm`` corresponding to the creation date/time
of the report) and places it in the experiment base directory.  This status file 
contains the last 40 lines (by default; this can be adjusted) from the end of each 
``log.launch_FV3LAM_wflow`` log file.  These lines include the experiment status 
as well as the task status table generated by ``rocotostat`` (so that, in 
case of failure, it is convenient to pinpoint the task that failed).
For details on the usage of ``get_expts_stats.sh``, issue

.. code-block::

   > get_expts_status.sh --help

For example:

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


Adding New WE2E Tests
---------------------
To add a new test named, for example ``new_test01``, to one of the existing categories listed
above, say ``wflow_features``:

1) Choose an existing test configuration file in any one of the category directories that
   matches most closely the new test to be added.  Copy that file to ``config.new_test01.sh``
   and, if necessary, move it to the ``wflow_features`` category directory. 

2) Edit ``config.new_test01.sh`` so that the header containing the test description properly
   describes the new test.

3) Further edit ``config.new_test01.sh`` by modifying existing experiment variable values
   and/or adding new variables such that the test runs with the intended configuration.

To create a new test category called, e.g. ``new_category``:

1) In the directory ``ufs-srweather-app/regional_workflow/tests/WE2E/test_configs``.
   create a new directory named ``new_category``. 

2) In the file ``get_WE2Etest_names_subdirs_descs.sh``, add the element ``"new_category"`` 
   to the array ``category_subdirs`` that contains the list of categories/subdirectories
   in which to search for test configuration files.  Thus, ``category_subdirs`` becomes:

   .. code-block:: console

     category_subdirs=( \
       "." \
       "grids_extrn_mdls_suites_community" \
       "grids_extrn_mdls_suites_nco" \
       "wflow_features" \
       "new_category" \
       )

New tests can now be added to ``new_category`` using the procedure described above.




