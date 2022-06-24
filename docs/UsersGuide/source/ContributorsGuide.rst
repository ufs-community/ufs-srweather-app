
.. _ContributorsGuide:

==============================
SRW App Contributor's Guide
==============================

.. _Background:

Background
===========

Authoritative branch
-----------------------

The main development branch for the ``ufs-srweather-app`` repository is ``develop``. The HEAD of ``develop`` reflects the latest development changes. It points to regularly updated hashes for individual sub-components, including the ``regional_workflow``. Pull requests (PRs) will be merged to ``develop``. 

The ``develop`` branch is protected by the code management team:
    #. Pull requests for this branch require approval by at least two code reviewers.
    #. A code manager should perform the review and the merge, but other contributors are welcome to provide comments/suggestions.


Code Management Team
--------------------------

Scientists from across multiple labs and organizations have volunteered to review pull requests for the ``develop`` branch:

.. table::

    +------------------+------------------------------------------------+
    | **Organization** | **Reviewers**                                  |
    +==================+================================================+
    | EMC              | Chan-Hoo Jeon (@chan-hoo)                      |
    |                  |                                                |
    |                  | Ben Blake (@BenjaminBlake-NOAA)                |
    |                  |                                                |
    |                  | Ratko Vasic (@RatkoVasic-NOAA)                 |
    +------------------+------------------------------------------------+
    | EPIC             | Mark Potts (@mark-a-potts)                     |
    |                  |                                                |
    |                  | Jong Kim (@jkbk2004)                           |
    |                  |                                                |                  
    |                  | Natalie Perlin (@natalie-perlin)               |
    |                  |                                                |
    |                  | Gillian Petro (@gspetro-NOAA)                  |
    |                  |                                                |
    |                  | Edward Snyder (@EdwardSnyder-NOAA)             |
    +------------------+------------------------------------------------+
    | GLERL/UM         | David Wright (@dmwright526)                    |
    +------------------+------------------------------------------------+
    | GSL              | Jeff Beck (@JeffBeck-NOAA)                     |
    |                  |                                                |
    |                  | Gerard Ketefian (@gsketefian)                  |
    |                  |                                                |
    |                  | Linlin Pan (@panll)                            |
    |                  |                                                |
    |                  | Christina Holt (@christinaholtNOAA)            |
    |                  |                                                |
    |                  | Christopher Harrop (@christopherwharrop-noaa)  |
    |                  |                                                |
    |                  | Daniel Abdi (@danielabdi-noaa)                 |
    +------------------+------------------------------------------------+
    | NCAR             | Mike Kavulich (@mkavulich)                     |
    |                  |                                                |
    |                  | Will Mayfield (@willmayfield)                  |
    +------------------+------------------------------------------------+
    | NSSL             | Yunheng Wang (@ywangwof)                       |
    +------------------+------------------------------------------------+


.. _ContribProcess:

Contribution Process
========================

The steps below should be followed in order to make changes to the ``develop`` branch of the ``ufs-srweather-app`` repository. Communication with code managers and the code management team throughout the process is encouraged.

    #. **Issue** - Open an issue to document changes. Click `here <https://github.com/ufs-community/ufs-srweather-app/issues/new/choose>`__ to open a new ``ufs-srweather-app`` issue or see :numref:`Step %s <Issue>` for detailed instructions. 
    #. **GitFlow** - Follow `GitFlow <https://nvie.com/posts/a-successful-git-branching-model/>`__ procedures for development. 
    #. **Fork the repository** - Read more `here <https://docs.github.com/en/get-started/quickstart/fork-a-repo>`__ about forking in GitHub.
    #. **Create a branch** - Create a branch in your fork of the authoritative repository. Follow `GitFlow <https://nvie.com/posts/a-successful-git-branching-model/>`__ conventions when creating the branch. Branches should be named as follows, where [name] is a one-word description of the branch:

        * **bugfix/[name]:** Fixes a demonstrably incorrect portion of code
        * **feature/[name]:** Adds a new feature to the code
        * **enhancement/[name]:** Improves an existing portion of the code
        * **textonly/[name]:** Changes elements of the repository that do not impact program output or log files (e.g., changes to README, documentation, comments, changing quoted Registry elements, white space alignment). Any change which does not impact the compiled code in any way should fall under this category.
         
    #. **Development** - Perform and test changes in the branch. Document work in the issue and mention the issue number in commit messages to link your work to the issue (e.g., ``commit -m "Issue #23 - <commit message>"``). Test code modifications on as many platforms as possible, and request help with further testing from the code management team when unable to test on all platforms. Document changes to the workflow and capabilities (either in the ``.rst`` files or separately) so that the SRW App documentation stays up-to-date. 
    #. **Pull request** - When ready to merge changes back to the ``develop`` branch, the code developer should initiate a pull request (PR) of the feature branch into the ``develop`` branch. Read `here <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests>`__ about pull requests in GitHub. When a PR is initiated, the :ref:`PR Template <Template>` autofills. Developers should use the template to provide information about the PR in the proper fields. See the guidelines in :numref:`Section %s <GoodPR>` for more details on making a good pull request. Developers should also tag all relevant reviewers from the code management team to the PR.
    #. **Merge** - When review and testing is complete, a code manager will complete the pull request and subsequent merge. If the PR was issued by a code manager, that same code manager should perform the merge or explicitly delegate another code manager to do so. 
    #. **Cleanup** - After the PR is merged, the code developer should delete the branch on their fork and close the issue.

.. note::
    Feature branches are intended to be short-lived, concentrated on code with one sole purpose, and applicable to a single PR. These branches should be deleted once merged, and a new feature branch should be created when subsequent code development continues.

.. _Issue:

Opening an Issue
-------------------

To open an issue, click on `New Issue <https://github.com/ufs-community/ufs-srweather-app/issues/new/choose>`__ within the ``ufs-srweather-app`` GitHub repository. 

Choose from three options: 
    #. `Bug Report <https://github.com/ufs-community/ufs-srweather-app/issues/new?assignees=&labels=bug&template=bug_report.md&title=>`__: Report specific problems ("bugs") in the code using the following template:

        .. code-block:: console

            ## Description
            Provide a clear and concise description of the bug and what behavior 
            you are expecting.

            ## Steps to Reproduce
            Please provide detailed steps for reproducing the issue.

                1. step 1
                2. step 2
                3. see the bug...

            ## Additional Context
            Please provide any relevant information about your setup. This is important in 
            case the issue is not reproducible except for under certain conditions.

                * Machine
                * Compiler
                * Reference other issues or PRs in other repositories that this 
                is related to, and how they are related.

            ## Output
            Please include any relevant log files, screenshots or other output here.


    #. `Feature Request <https://github.com/ufs-community/ufs-srweather-app/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=>`__: New features and feature enhancements fall under this category. Propose features and enhancements using the following template. Optional sections may be deleted.

        .. code-block:: console

            ## Description
            Provide a clear and concise description of the problem to be solved.

            ## Solution
            Add a clear and concise description of the proposed solution.

            ## Alternatives (optional)
            If applicable, add a description of any alternative solutions or 
            features you've considered.

            ## Related to (optional)
            Directly reference any issues or PRs in this or other repositories 
            that this is related to, and describe how they are related.

    #. `Text-Only Changes <https://github.com/ufs-community/ufs-srweather-app/issues/new?assignees=&labels=textonly&template=textonly_request.md&title=>`__: Propose text-only changes using the "Text-only request" template. This template's content is the same as for the "Feature Request" template above. 

    #. `Other <https://github.com/ufs-community/ufs-srweather-app/issues/new>`__: Open a blank issue, and use the "Feature Request" template above as a starting point to describe the issue. 

For all issue reports, indicate whether this is an issue that you plan to work on and eventually submit a PR for or whether you are merely making a suggestion. After filling out the issue report, click on "Submit new issue." 

.. _GoodPR:

Making a Pull Request
---------------------------

All changes to the SRW App ``develop`` branch should be handled via GitHub’s “Pull Request” (PR) functionality from a branch in the developer’s fork. Developers must follow the template PR instructions (see :numref:`Step %s <Template>` below) and provide links to the relevant GitHub issue(s). They must also indicate which tests were run on which machines. 

Pull requests will be reviewed and approved by at least two code managers. When a PR has met the requirements and been approved by code reviewers, a code manager will merge the PR. 


.. note::

    * If a developer wants to make use of automated testing, any SRW App + regional_workflow dependencies must be opened in PRs from dependent branches of forks belonging to the same user.
    * The ``Externals.cfg`` file should point to any dependent branches in ``regional_workflow`` (and other components, if necessary) while those branches are under review. Once the corresponding ``regional_workflow`` PR has been merged, the developer should update the references in their ``Externals.cfg`` file to reflect the appropriate hashes in the authoritative repositories. 
    * Developers should mention in their ``ufs-srweather-app`` PR description that they are temporarily pointing to a branch/hash in their fork of ``regional_worklfow`` and that it will be updated once the corresponding ``regional_workflow`` PR is merged.


.. _Template:

PR Template
^^^^^^^^^^^^^^^^

Here is the template that is provided when developers click "Create pull request:"

.. code-block:: console
    
    - Update develop to head at ufs-community
    - Use this template to give a detailed message describing the change 
    you want to make to the code.
    - You may delete any sections labeled "optional".
    - If you are unclear on what should be written here, see https://github.com/wrf-model/WRF/wiki/Making-a-good-pull-request-message 
    for some guidance. 
    - The title of this pull request should be a brief summary (ideally less than 100 
    characters) of the changes included in this PR. Please also include the branch to 
    which this PR is being issued.
    - Use the "Preview" tab to see what your PR will look like when you hit "Create pull request"

    # --- Delete this line and those above before hitting "Create pull request" ---

    ## DESCRIPTION OF CHANGES: 
    One or more paragraphs describing the problem, solution, and required changes.

    ## TESTS CONDUCTED: 
    Explicitly state what tests were run on these changes, or if any are still pending 
    (for README or other text-only changes, just put "None required". Make note of the 
    compilers used, the platform/machine, and other relevant details as necessary. For 
    more complicated changes, or those resulting in scientific changes, please be explicit!

    ## DEPENDENCIES:
    Add any links to external PRs (e.g. regional_workflow and/or UFS PRs). For example:
    - ufs-community/regional_workflow/pull/<pr_number>
    - ufs-community/UFS_UTILS/pull/<pr_number>
    - ufs-community/ufs-weather-model/pull/<pr_number>

    ## DOCUMENTATION:
    If this PR is contributing new capabilities that need to be documented, please also 
    include updates to the RST files (docs/UsersGuide/source) as supporting material.

    ## ISSUE (optional): 
    If this PR is resolving or referencing one or more issues, in this repository or 
    elewhere, list them here. For example, "Fixes issue mentioned in #123" or "Related to 
    bug in https://github.com/ufs-community/other_repository/pull/63"

    ## CONTRIBUTORS (optional): 
    If others have contributed to this work aside from the PR author, list them here


Additional Guidance
^^^^^^^^^^^^^^^^^^^^^^^^

**TITLE:** The title should give code reviewers a clear idea of what the change will do in approximately 5-10 words. Some good examples from the past:

    * Make thompson_mynn_lam3km ccpp suite available
    * Fix module loads on Hera
    * Add support for Rocoto with generic LINUX platform

All of the above examples concisely describe the changes contained in the pull request. The title will not get cut off in emails and web pages. In contrast, here are some made-up (but plausible) examples of BAD pull request titles:

    * Bug fixes (Bug fixes on what part of the code?)
    * Changes to surface scheme (What kind of changes? Which surface scheme?)

**DESCRIPTION OF CHANGES:** The first line of the description should be a single-line "purpose" for this change. Note the type of change (i.e., bug fix, feature, enhancement, text-only). Summarize the problem, proposed solution, and required changes. If this is an enhancement or new feature, describe why the change is important.

**DOCUMENTATION:** Developers should include documentation on new capabilities and enhancements by updating the appropriate ``.rst`` documentation files in their ``ufs-srweather-app`` fork prior to the PR. These documentation updates should be noted in the "Documentation" section of the PR message. If necessary, contributors may submit the ``.rst`` documentation in a subsequent PR. In these cases, the developers should include any existing documentation in the "Documentation" section of the initial PR message or as a file attachment to the PR. Then, the contributor should open an issue (see :numref:`Step %s <Issue>`) reflecting the need for official ``.rst`` documentation updates and include the issue number and explanation in the "Documentation" section of the initial PR template.
 

Tips, Best Practices, and Protocols to Follow When Submitting a PR
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* **Indicate urgency.** If a PR is particularly urgent, this information should be provided in the PR "Description" section, and multiple code management team members should be tagged to draw attention to this PR. After submitting the PR, a "high priority" label should be added to it (see below). 
* **Indicate the scope of the PR.** If the PR is extremely minor (e.g., change to the README file), indicate this in the PR message. If it is an extensive PR, the developer should test it on as many platforms as possible and stress the necessity that it be tested on systems for which they do not have access.
* **Clarify in the PR message where the code has been tested.** At a minimum, code should be tested on the platform where code modification has taken place. It should also be tested on machines where code modifications will impact results. If the developer does not have access to these platforms, this should be noted in the PR. 
* **Follow separation of concerns.** For example, module loads are only handled in the appropriate modulefiles, Rocoto always sets the work directory, j-jobs make the work directory, and ex-scripts require the work directory to exist.
* **Label PR status appropriately.** If the PR is not completely ready to be merged please add a “Work in Progress” label. Urgent PRs should be marked "high priority." All PRs should have a type label (e.g., "bug," "enhancement"). Labels can be added on the right-hand side of a submitted PR request by clicking on the gear icon beside "Labels" (below the list of Reviewers).
* **Target subject matter experts (SMEs) among the code management team.** When possible, tag team members who are familiar with the modifications made in the PR so that the code management team can provide effective and streamlined PR reviews and approvals. Developers can tag SMEs by selecting the gear icon next to "Assignees" (under the Reviewers list) and adding the appropriate names. 
* **Schedule a live code review** if the PR is exceptionally complex in order to brief members of the code management team on the PR either in-person or through a teleconference. Developers should indicate in the PR message that they are interested in a live code review if they believe that it would be beneficial. 


.. _ContribStandards:

Code and Configuration Standards
===================================

General
-----------

Platform-specific settings should be handled only through configuration and modulefiles, not in code or scripts.

SRW Application
------------------

Externals.cfg
    * All externals live in a single ``Externals.cfg`` file.
    * Externals should point only to authoritative repositories for the given code base.

        * Temporary exceptions are made for a PR into the ``develop`` branch of ``ufs-srweather-app`` that is dependent on another PR (e.g., a ``regional_workflow`` PR from the same contributor). When the component PR is merged, the contributor must update the corresponding ``ufs-srweather-app`` PR with the hash of the component's authoritative repository.
    * Only a single hash will be maintained for any given external code base. All externals should point to this static hash (not to the top of a branch). 
    
Build system
    * Each component should build with CMake
    * Each component should build with Intel compilers on official `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ platforms and with GNU or Intel compilers on other platforms. 
    * Each component should have a mechanism for platform independence (i.e., no hard-coded machine-specific settings outside of established environment, configuration, and modulefiles). 
    * Each component should build with the latest release of the `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__. 

Modulefiles
    * Each component should build using the common modules located in the ``modulefiles/srw_common`` file.


Regional Workflow
----------------------
The ``regional_workflow`` repository must not contain source code for compiled programs. Only scripts, configuration files, and documentation should reside in this repository. 

**General Coding Standards:** 
    * All bash scripts must explicitly be ``#!/bin/bash`` scripts. They should *not* be login-enabled (i.e., scripts should *not* use the ``-l`` flag).
    * MacOS does not have all Linux utilities by default. Developers should ensure that they do not break any MacOS capabilities with their contribution.
    * All code must be indented appropriately and conform to the style of existing scripts (e.g., local variables should be lowercase, global variables should be uppercase).

**Python Coding Standards:** 
    * All Python code contributions should come with an appropriate ``environment.yaml`` file for the feature. 
    * Keep the use of external Python packages to a minimum for necessary workflow tasks. Currently, the required external Python packages are: ``f90nml``, ``pyyaml``, and ``jinja``. 

**Workflow Design:** Follow the `NCO Guidelines <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/>`__ for what is incorporated in each layer of the workflow. This is particularly important in the ``scripts`` directory. 

**Modulefiles:** All official platforms should have a modulefile that can be sourced to provide the appropriate python packages and other settings for the platform. 

**Management of the Configuration File:** New configurable options must be consistent with existing configurable options and documented in ``docs/UsersGuide/source/ConfigWorkflow.rst``. Add necessary checks on acceptable options where applicable. Add appropriate default values in ``config_defaults.sh``.

**Management of Template Files:** If a new configurable option is required in an existing template, it must be handled similarly to its counterparts in the scripts that fill in the template.

**Namelist Management:** Namelists in ``ufs-srweather-app`` and ``regional_workflow`` are generated using a Python tool and managed by setting YAML configuration parameters. This allows for the management of multiple configuration settings with maximum flexibility and minimum duplication of information. 



Contributor Requirements
===========================

Preparing Code for Contribution to the UFS SRW Application
------------------------------------------------------------

All changes should be associated with a GitHub Issue. If developers are working on a change, they should search the existing issues in the appropriate repository (``ufs-srweather-app`` and/or ``regional_workflow``). If an issue does not exist for the work they are doing, they should create one prior to opening a new pull request (see :numref:`Step %s <Issue>`).

**Guidelines for All Modifications:**
    * All changes should adhere to the Code and Configuration Standards detailed in :numref:`Section %s <ContribStandards>`. 
    * For changes to the ``scripts``, ``ush``, or ``jobs`` directories (within ``ufs-srweather-app/regional_workflow``), developers should follow the `NCO Guidelines <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/>`__ for what is incorporated into each layer. 
    * Developers should ensure that their contributions work with the most recent version of the ``ufs-srweather-app``, including all the specific up-to-date hashes of each subcomponent.
    * Modifications should not break any existing supported capabilities on any supported platforms.
    * Developers will not be required to run tests on *all* supported platforms, but if a failure is pointed out by another reviewer (or by automated testing), then the developer should work with reviewers and code managers to ensure that the problem is resolved prior to merging.
    * If possible, developers should run a fundamental test suite (see :numref:`Section %s <Testing>`) on at least one supported platform and report on the outcome in the PR template.
    * If changes are made to ``regional_workflow``, a corresponding PR to ``ufs-srweather-app`` should be opened to update the ``regional_workflow`` hash. 
    * Update the ``.rst`` documentation files where appropriate as part of the PR. If necessary, contributors may update the documentation in a subsequent PR. In these cases, the contributor should open an issue reflecting the need for documentation (see :numref:`Step %s <Issue>`) and include the issue number and explanation in the Documentation section of the initial PR template. 

**Guidelines for New Features:**
    * Components should have a mechanism for portability and platform-independence; code that is included in the SRW App should not be tied to specific platforms. 
    * New components should be able to build using the standard supported NCEPLIBS environment (currently `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__).
    * New entries in ``Externals.cfg`` should only be repositories from “official” sources; either the `UFS Community GitHub organization <https://github.com/ufs-community>`__ or another NOAA project organization.
    * Document how to use the new component, and include this information in the PR. 


.. _Testing: 

Testing
===============

The ``ufs-srweather-app`` repository uses the established workflow end-to-end (WE2E) testing framework (see :numref:`Chapter %s <WE2E_tests>`) to implement two tiers of testing: fundamental and comprehensive. *Fundamental testing* consists of a lightweight set of tests that can be automated and run regularly on each `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ platform. These are mostly low-resolution tests and cover a wide scope of capabilities to ensure that there are no major, obvious faults in the underlying code. *Comprehensive testing* involves a broader range of capabilities, configurations, and components. 

Before opening a PR, a minimum set of tests should be run: 
    * At least one end-to-end test (preferably a fundamental test suite) should be run on at least one supported platform
    * Any new functionality should be tested explicitly, and tests should be described in detail in the PR message. Depending on the impact of this functionality, this test should be added to the WE2E suite of fundamental or comprehensive tests. 

**Updating the Testing Suite:** When new capabilities are added or new bugs/issues are discovered, WE2E tests should be created and/or modified to verify that new features are not broken in subsequent PRs. For example, if a new physics suite is introduced, it may be possible to alter an existing test rather than creating an entirely new test. Code developers introducing new capabilities should work with code managers to provide the proper configuration files, data, and other information necessary to create new tests for these capabilities.












