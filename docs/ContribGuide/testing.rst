========
Testing
========

The `ufs-srweather-app` repository uses the established workflow end-to-end (WE2E) testing framework see the User's Guide chapter on :ref:`WE2E tests <WE2E_tests>` to implement two tiers of testing: fundamental and comprehensive. **Fundamental testing** consists of a lightweight set of tests that can be automated and run regularly on each :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` platform. These tests verify that there are no major, obvious faults in the underlying code when running common combinations of grids, input data, and physics suites. **Comprehensive testing** includes the entire set of WE2E tests and covers a broader range of capabilities, configurations, and components. Eventually, new categories of tests will be added, including regression tests and unit tests. 

Before opening a PR, a minimum set of tests should be run: 
 * Developers must run the fundamental test suite manually on at least one supported platform and report on the outcome in the PR template.
    * Developers will not be required to run tests on *all* supported platforms, but if a failure is pointed out by another reviewer (or by automated testing), then the developer should work with reviewers and code managers to ensure that the problem is resolved prior to merging. 
 * If the PR impacts functionality contained within comprehensive WE2E tests not included in the fundamental test suite, the developer must run those tests on the PR.
 * Any new functionality must be tested explicitly, and any new tests should be described in detail in the PR message. Depending on the impact of this functionality, new tests should be added to the suite of comprehensive WE2E tests, followed by a discussion with code managers on whether they should also be included as fundamental tests.
    * In some cases, it may be possible to modify a current test instead of creating a completely new test. Code developers introducing new capabilities should work with code managers to provide the proper configuration files, data, and other information necessary to create new tests for these capabilities.
 * When the above tests are complete and the PR has been approved by at least one code manager, a code manager will add the `run_we2e_coverage_tests` label to initiate fundamental testing on all Level 1 platforms via Jenkins (see below).

**Testing on Jenkins**

[Jenkins](https://www.jenkins.io/) is an "open source automation server" that allows users to automate code testing.  For the Jenkins automated testing labels, it should be noted that **ONLY** code managers should apply these labels and only after at least one code manager has given approval to the PR.  The PR will not be merged until all Jenkins-based builds and testing have successfully passed.

The following automated testing labels are available (or will be soon) for the SRW App:
   * `run_we2e_coverage_tests`
   * _Coming Soon:_ `run_we2e_comprehensive_tests`

Due to a security issue on Jenkins, where all Jenkins usernames are exposed, the ability to access Jenkins logs to the public has been disabled. Once the Jenkins tests have completed, a member of the EPIC team (who has login credentials to Jenkins) will need to provide the logs for those tests that have failed. If the Jenkins tests fail, then the developer will need to make the necessary corrections to their PR. Unfortunately, removing and adding the label back will not kick off the Jenkins test. Instead, the job will need to be manually re-run through Jenkins (by a member of the EPIC team).

While the output from the Jenkins page itself isn't available for external view, users can still access the directories that the Jenkins tests are run on the various machines so that they can view the tests, monitor progress, and investigate failures.  The location of the experiment directories on the various machines are as follows:

.. list-table::
   :header-rows: 1

   * - Tier-1 Platform
     - Location of Jenkins experiment directories
   * - Derecho
     - 
   * - Gaea
     - /lustre/f2/dev/wpo/role.epic/jenkins/workspace/fs-srweather-app_pipeline_PR-#/gaea
   * - Gaea C5
     - /lustre/f2/dev/wpo/role.epic/jenkins/workspace/fs-srweather-app_pipeline_PR-#/gaea-c5
   * - Hera (Intel)
     - /scratch2/NAGAPE/epic/role.epic/jenkins/workspace/fs-srweather-app_pipeline_PR-#__2/hera
   * - Hera (GNU)
     - /scratch2/NAGAPE/epic/role.epic/jenkins/workspace/fs-srweather-app_pipeline_PR-#/hera
   * - Hercules
     - /work/noaa/epic/role-epic/jenkins/workspace/fs-srweather-app_pipeline_PR-#/hercules
   * - Jet
     - /lfs1/NAGAPE/epic/role.epic/jenkins/workspace/fs-srweather-app_pipeline_PR-#/jet
   * - Orion
     - /work/noaa/epic/role-epic/jenkins/workspace/fs-srweather-app_pipeline_PR-#/orion

* where # is the PR number

Users can also go to the [EPIC Health Dashboard](https://noaa-epic-dashboard.s3.amazonaws.com/index.html), click the `Jenkins Artifacts` tab, identify your PR number, pull the `we2e_test_logs-{machine}-{compiler}.tgz` file (where {machine} is the Tier-1 platform that failed and {compiler} is the compiler used for the failed test), untar and ungzip the file, and look through the logs from the test that failed.




