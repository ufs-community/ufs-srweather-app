.. _WE2E_tests:

================================
Workflow End-to-End (WE2E) Tests
================================
The SRW Application's experiment generation system contains a set of end-to-end tests that 
exercise various configurations of that system as well as those of the pre-processing, 
UFS Weather Model, and UPP post-processing codes. The script to run these tests is named 
``run_experiments.sh`` and is located in the directory ``ufs-srweather-app/regional_workflow/tests``.
A complete list of the available tests can be found in ``baselines_list.txt`` in that directory.   
This list is extensive; it is not recommended to run all of the tests as some are computationally 
expensive.  A subset of the tests supported for this release of the SRW Application can be found 
in the file ``testlist.release_public_v1.txt``. 
 
The base experiment configuration file for each test is located in the ``baseline_configs`` 
subdirectory.  Each file is named ``config.${expt_name}.sh``, where ``${expt_name}`` is the 
name of the corresponding test configuration. These base configuration files are subsets of
the full ``config.sh`` experiment configuration file used in :numref:`Section %s <SetUpConfigFile>` 
and described in :numref:`Section %s <UserSpecificConfig>`.  For each test that the user wants 
to run, the ``run_experiments.sh`` script reads in its base configuration file and generates from 
it a full ``config.sh`` file (a copy of which is placed in the experiment directory for the test).

Since ``run_experiments.sh`` calls ``generate_FV3LAM_wflow.sh`` for each test to be run, the 
Python modules required for experiment generation must be loaded before ``run_experiments.sh`` 
can be called.  See :numref:`Section %s <SetUpPythonEnv>` for information on loading the Python
environment on supported platforms.  Note also that ``run_experiments.sh`` assumes that all of 
the executables have been built. 

The user specifies the set of test configurations that the ``run_experiments.sh`` script will 
run by creating a text file, say ``expts_list.txt``, that contains a list of tests (one per line) 
and passing the name of that file to the script.  For each test in the file, ``run_experiments.sh``
will generate an experiment directory and, by default, will continuously (re)launch its workflow 
by inserting a new cron job in the user's cron table.  This cron job calls the workflow launch script 
``launch_FV3LAM_wflow.sh`` located in the experiment directory until the workflow either 
completes successfully (i.e. all tasks are successful) or fails (i.e. at least one task fails). 
The cron job is then removed from the user's cron table.


The script ``run_experiments.sh`` accepts the command line arguments shown in
:numref:`Table %s <WE2ECommandLineArgs>`.  

.. _WE2ECommandLineArgs:

.. list-table:: Command line arguments for the WE2E testing script ``run_experiments.sh``.
   :widths: 20 40 40
   :header-rows: 1

   * - Command Line Argument
     - Description
     - Optional
   * - expts_file
     - Name of the file containing the list of tests to run.  If ``expts_file`` is the absolute path
       to a file, it is used as is.  If it is a relative path (including just a file name), it is assumed
       to be given relative to the path from which this script is called.
     - No
   * - machine
     - Machine name
     - No
   * - account
     - HPC account to use
     - No
   * - use_cron_to_relaunch
     - Flag that specifies whether or not to use a cron job to continuously relaunch the workflow
     - Yes.  Default value is ``TRUE`` (set in ``run_experiments.sh``).
   * - cron_relaunch_intvl_mnts 
     - Frequency (in minutes) with which cron will relaunch the workflow
     - Used only if ``use_cron_to_relaunch`` is set to ``TRUE``.  Default value is "02" (set in ``run_experiments.sh``).

For example, to run the tests named ``grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2``
and ``grid_RRFS_CONUS_25km_ics_HRRR_lbcs_RAP_suite_RRFS_v1alpha`` on Cheyenne, first create the file 
``expts_list.txt`` containing the following lines:

.. code-block:: console

   
    grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2
    grid_RRFS_CONUS_25km_ics_HRRR_lbcs_RAP_suite_RRFS_v1alpha

Then, from the ``ufs-srweather-app/regional_workflow/tests`` directory, issue the following command:

.. code-block:: console

   ./run_experiments.sh expts_file="expts_list.txt" machine=cheyenne account="account_name"

where ``account_name`` should be replaced by the account to which to charge the core-hours used
by the tests.  Running this command will automatically insert an entry into the user's crontab 
that regularly (re)launches the workflow.  The experiment directories will be created under 
``ufs-srweather-app/../expt_dirs``, and the name of each experiment directory will be identical 
to the name of the corresponding test.

To see if a test completed successfully, look at the end of the ``log.launch_FV3LAM_wflow`` file (which
is the log file that ``launch_FV3LAM_wflow.sh`` appends to every time it is called) located in the
experiment directory for that test:

.. code-block:: console

   Summary of workflow status:
   ~~~~~~~~~~~~~~~~~~~~~~~~~~
 
     1 out of 1 cycles completed.
     Workflow status:  SUCCESS
 
   ========================================================================
   End of output from script "launch_FV3LAM_wflow.sh".
   ========================================================================


Use of cron for all tests to be run by ``run_experiments.sh`` can be turned off by instead issuing 
the following command:

.. code-block:: console

   ./run_experiments.sh expts_file="expts_list.txt" machine=cheyenne account="account_name" use_cron_to_relaunch=FALSE 

In this case, the experiment directories for the tests will be created, but their workflows will 
not be (re)launched. For each test, the user will have to go into the experiment directory and 
either manually call the ``launch_FV3LAM_wflow.sh`` script or use the Rocoto commands described 
in :numref:`Chapter %s <RocotoInfo>` to (re)launch the workflow.  Note that if using the Rocoto
commands directly, the log file ``log.launch_FV3LAM_wflow`` will not be created; in this case, 
the status of the workflow can be checked using the ``rocotostat`` command (see :numref:`Chapter %s <RocotoInfo>`).


