.. _WE2E_tests:

================================
Workflow End-to-End (WE2E) Tests
================================
The SRW Application workflow contains a set of end-to-end tests that exercise various
configurations of the pre-processing, UFS Weather Model, and the UPP post-processor. The
scripts to run these tests are located in ``ufs-srweather-app/regional_workflow/tests``.
A complete list of the available tests is in ``baselines_list.txt``.   This list is extensive;
it is not recommended to run all of the tests, as it is computationally expensive.  The tests
that start with ``nco_`` are run in an operational mode and are used more exclusively by NOAA/NCEP
Central Operations (NCO).  A subset of tests supported for this release are in the file
``testlist.release_public_v1.txt``. 
 
The full set of the test configuration files is in the ``baseline_configs`` subdirectory.  Each
file is named ``config.${config_name}.sh``, where ``${config_name}`` is the name of the corresponding
configuration. These configuration files are variations of the ``config.sh`` file used in
:numref:`Section %s <SetUpConfigFile>` and described in :numref:`Section %s <UserSpecificConfig>`.
Since the purpose of these tests is to ensure that the workflow completes successfully, most of the
WE2E tests use coarse grids to minimize test duration and the use of computational resources. 

Running the Tests
-----------------
The WE2E test script assumes that all of the executables have been built. A script 
``ufs-srweather-app/regional_workflow/tests/run_experiments.sh`` is available to run one or more
of the WE2E tests.  For each test, the script will generate an experiment directory and launch its
workflow.  By default, each workflow will be resubmitted via a cron job until it either completes
successfully (i.e. all tasks are successful) or fails (i.e. at least one task fails).  
 
If the user does not wish to run all of the tests listed in ``baselines_list.txt``, it is recommended
to make a copy of ``my_expts.txt`` to contain a subset of the tests to be run or use the subset of
tests in ``testlist.release_public_v1.txt``.
 
Since these tests run ``./generate_FV3LAM_wflow.sh``, the Python modules must be loaded before the
tests are run.  See :numref:`Section %s <SetUpPythonEnv>` for information on loading the Python
environment on supported platforms.
 
Running the test script ``run_experiments.sh`` uses command line arguments shown in
:numref:`Table %s <WE2ECommandLineArgs>`.  

.. _WE2ECommandLineArgs:

.. list-table:: Command line arguments for the test script ``run_experiments.sh``.
   :widths: 20 40 40
   :header-rows: 1

   * - Command Line Argument
     - Description
     - Optional
   * - expts_file
     - Name of the file containing the list of experiments to run.  If ``expts_file`` is the absolute path
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
     - Set to ``TRUE`` to use crontab to relaunch the workflow
     - Yes.  If not set, the value set in ``config_defaults.sh`` will be used, which has the default set to ``FALSE``.
   * - cron_relaunch_intvl_mnts 
     - Interval (in minutes) set in crontab to relaunch the workflow
     - Used only if ``use_cron_to_relaunch`` is ``TRUE``.  The default value is 03 set in ``config_default.sh``.

To run the tests from the tests directory on Cheyenne:

.. code-block:: console

   ./run_experiments.sh expts_file="my_expts.txt" machine=cheyenne account=$ACCOUNT use_cron_to_relaunch=TRUE cron_relaunch_intvl_mnts=05
 
Running this command will automatically insert a command into your crontab to regularly relaunch the workflow
tasks.  The tests will be run in the ``${EXPT_BASEDIR}`` directory, with each test run in its own subdirectory
``${EXPT_SUBDIR}``.  You can also turn off using cron for all the tests like this:

.. code-block:: console

   ./run_experiments.sh expts_file="my_expts.txt" machine=cheyenne account=$ACCOUNT use_cron_to_relaunch=FALSE 

Once ``./run_experiments.sh`` has been executed, with the cron options set, your crontab file will be
automatically modified to run the experiments to completion, and the line inserted into your crontab file
that relaunches the workflow tasks will also be removed when the experiment is complete.  To see if an
experiment was successful, look at the end of the ``log.launch_FV3LAM_wflow`` file for:

.. code-block:: console

   Summary of workflow status:
   ~~~~~~~~~~~~~~~~~~~~~~~~~~
 
     1 out of 1 cycles completed.
     Workflow status:  SUCCESS
 
   ========================================================================
   End of output from script "launch_FV3LAM_wflow.sh".
   ========================================================================

