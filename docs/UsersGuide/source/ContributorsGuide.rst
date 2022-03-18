
.. _ContributorsGuide:

***********************************
Contributor's Guide
***********************************


.. _Summary:

==========
Summary
==========

Authoritative branch
========================

The main development branch for the ``ufs-srweather-app`` repository is ``develop``. The HEAD of ``develop`` reflects the latest development changes. It points to regularly updated hashes for individual sub-components, including ``regional_workflow``. Pull requests (PR's) will be merged to ``develop``. 

The ``develop`` branch is protected by the code management team:
    #. Pull requests for this branch require approval by at least one code reviewer
    #. A code manager should perform the review and the merge, but other contributors are welcome to provide comments/suggestions


Code Review Committee
=========================

Scientists from across multiple labs and organizations have volunteered to review pull requests for the ``develop`` branch:

.. code-block:: console

    NSSL: Yunheng Wang (@ywangwof)
    EMC: Chan-Hoo Jeon(@chan-hoo), Ben Blake (@BenjaminBlake-NOAA), Ratko Vasic (@RatkoVasic-NOAA)
    GSL: Jeff Beck (@JeffBeck-NOAA), Gerard Ketefian (@gsketefian), Linlin Pan (@panll), Christina Holt (@christinaholtNOAA), Christopher Harrop (@christopherwharrop-noaa), Daniel Abdi (@danielabdi-noaa)
    EPIC: Mark Potts (@mark-a-potts), Jong Kim (@jkbk2004)
    NCAR: Mike Kavulich (@mkavulich), Will Mayfield (@willmayfield), and Jamie Wolff (@jwolff-ncar) 
    GLERL/UM: David Wright (@dmwright526)

..
    COMMENT: Edit list of PR Reviewers!!!


.. _ContribProcess:

========================
Contribution Process
========================

The following steps should be followed in order to make changes to the ``develop`` branch of ``ufs-srweather-app``. Communication with code managers and the code review committee throughout the process is encouraged.
    #. Issue - Open an issue to document changes. Click `here <https://github.com/ufs-community/ufs-srweather-app/issues/new/choose>`__ to open a new ``ufs-srweather-app`` issue. 
    #. GitFlow - Follow `GitFlow <https://nvie.com/posts/a-successful-git-branching-model/>`__ procedures for development (branch names, forking vs branching, etc.). Read more here about GitFlow within the UFS repositories here
    #. Fork the repository - Read more `here <https://docs.github.com/en/get-started/quickstart/fork-a-repo>`__ about forking in GitHub.
    #. Feature Branch - Create a feature branch in your fork of the authoritative repository. Follow Gitflow conventions when creating the branch.
    #. Development - Perform and test changes in the branch. Document work in the issue and mention the issue number in commit messages to link your work to the issue (e.g. commit -m "Issue #23 - ...commit message..."). Attempt to test code modifications on as many platforms as possible, and request help with further testing from code review committee when unable to test on all platforms.
    #. Pull request - When ready to merge changes back to the develop branch, the code developer should initiate a pull request (PR) of the feature branch into the develop branch. Read `here <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests>`__ about pull requests in GitHub. See the guidelines in :numref:`Section %s <GoodPR>` on making a good pull request. Provide some information about the PR in the proper field, and tag all relevant reviewers from the code management team to the PR.
    #. Complete - When review and testing is complete a code manager will complete the pull request and subsequent merge.
    #. Cleanup - When complete, the code developer should delete the branch and close the issue.


.. _ContribStandards:

===================================
Code and Configuration Standards
===================================




.. _GoodPR:

Making a Good Pull Request
===============================

This is a brief guide to pull request messages for the SRW repository:

To start, here is the template that is provided when you click "Create pull request:"

.. code-block:: console

    - Update develop to head at ufs-community
    - Use this template to give a detailed message describing the change you want to make to the code.
    - You may delete any sections labeled "optional".
    - If you are unclear on what should be written here, see https://github.com/wrf-model/WRF/wiki/Making-a-good-pull-request-message for some guidance. 
    - The title of this pull request should be a brief summary (ideally less than 100 characters) of the changes included in this PR. Please also include the branch to which this PR is being issued.
    - Use the "Preview" tab to see what your PR will look like when you hit "Create pull request"

    # --- Delete this line and those above before hitting "Create pull request" ---

    ## DESCRIPTION OF CHANGES: 
    One or more paragraphs describing the problem, solution, and required changes.

    ## TESTS CONDUCTED: 
    Explicitly state what tests were run on these changes, or if any are still pending (for README or other text-only changes, just put "None required". Make note of the compilers used, the platform/machine, and other relevant details as necessary. For more complicated changes, or those resulting in scientific changes, please be explicit!

    ## DEPENDENCIES:
    Add any links to external PRs (e.g. regional_workflow and/or UFS PRs). For example:
    - ufs-community/regional_workflow/pull/<pr_number>
    - ufs-community/UFS_UTILS/pull/<pr_number>
    - ufs-community/ufs-weather-model/pull/<pr_number>

    ## DOCUMENTATION:
    If this PR is contributing new capabilities that need to be documented, please also include updates to the RST files (docs/UsersGuide/source) as supporting material.

    ## ISSUE (optional): 
    If this PR is resolving or referencing one or more issues, in this repository or elewhere, list them here. For example, "Fixes issue mentioned in #123" or "Related to bug in https://github.com/ufs-community/other_repository/pull/63"

    ## CONTRIBUTORS (optional): 
    If others have contributed to this work aside from the PR author, list them here









The first line should be a single-line "purpose" for this change

TYPE: choose one of [bug fix, enhancement, new feature, feature removed, no impact, text only]

KEYWORDS: approximately 3 to 6 words (more is always better) related to commit, separated by commas

SOURCE: Either "developer's name ( and affiliation)" .XOR. "internal" for a WRF Dev committee member

DESCRIPTION OF CHANGES: One or more paragraphs describing problem, solution, and required changes.

ISSUE: If this modification addresses an "issue" then it should be referenced here. This will let GitHub know that it can mark the issue as complete. (e.g., "This issue fixes #123," where 123 is the issue number).

LIST OF MODIFIED FILES: list of changed files (use `git diff --name-status master` to get formatted list)

TESTS CONDUCTED: Explicitly state if a WTF and or other tests were run, or are pending. For more complicated changes please be explicit! It may help to include plots.

RELEASE NOTE: If relevant, you may type here the important information that should go out to users in the code release notes. This should be brief, but descriptive, and should read exactly as this will appear to users from the official release notes.
It's a bit descriptive, but it might not tell you everything you need to know. Below we will go over what should be listed in each section, and give an example from previous "good" pull requests.

Title
Every pull request needs a title. Titles should give people a good idea of what your code change will do in approximately 5-15 words. They should be as precise as possible, so people can already have some idea on whether they are interested in the changes from the title alone.

Some good examples from the past:

NMM: Remove HWRF/NMM variable (avgPchg) from the history file
Introduce physics suites mechanism for ARW
Fix uninitialized variable in Noah-MP surface exchange option
Tweaks to allow CRTM_2.2.3 to compile on Fujitsu
Bug Fix for Single-layer UCM Green Roof Option
Major bug fix for tendencies from NSAS cumulus scheme
Reduce computational patch size for intermediate domain for vertical nesting
All of the above do a good job of concisely describing the changes contained in the pull request: they are not too wordy so that the title gets cut off in various emails and web pages, and not too vague so that it's unclear what part of the code is being changed.

In contrast, here are some made-up (but plausible) examples of BAD pull request titles:

Bug fixes (Bug fixes on what part of the code?)
Changes to surface scheme (What kind of changes? What surface scheme?)
Add new scheme
TYPE:
The "type" of pull request you are opening is a descriptor of the general impact your change will have on the code. You should choose one of the following options:

bug fix
Fixing a demonstrably incorrect portion of code (this is the only type that should be committed to the bug fix release branches, e.g., release-v4.1.1)

enhancement
Changing an existing portion of the code; though the old code was not unambiguously wrong, this change presumably improves the code

new feature
Adding a new feature to the code

feature removed
Removing an existing feature of the code. This one has yet to ever be invoked I'm pretty sure.

no impact
For display changes such as changing the "version_decl", changing variable names, improving error messages, changing quoted Registry elements, or otherwise changing what appears in the log/out/error files but not impacting history/restart output results, timing performance, or memory footprint.

text only
For README and comments, changing quoted Registry elements, white space alignment, or other changes which have no impact on program output or log files. Ultimately, any change which does not impact the compiled code in any way should fall under this category.

KEYWORDS:
See description in the template at the top of this page.

SOURCE:
See description in the template at the top of this page.

DESCRIPTION OF CHANGES:
One or more paragraphs that clearly state the problem and effects it invoked, the solution, and the required changes, or if this is an enhancement or new code, describe the purpose and why it's necessary. It may be useful to include plots.

ISSUE:
See description in the template at the top of this page.

LIST OF MODIFIED FILES:
See description in the template at the top of this page.

TESTS CONDUCTED:
See description in the template at the top of this page.

RELEASE NOTE:
See description in the template at the top of this page.

© 2022 GitHub, Inc.
Terms
Privacy
Security






.. _Testing: 
===============
Testing
===============

Two tiers of testing: fundamental and comprehensive using the established workflow end-to-end (WE2E) testing framework

    * fundamental testing will represent a lightweight set of tests that can be automated and run regularly on each tier-1 platform.

Other branches should be used for staging proposed changes to develop or release branches, and should reside on a developer’s fork.

    * Feature branches: when developing a new feature, improving an old feature, or other change; should be associated with a Github issue
    * Bug fix branches: functionally the same as feature branches, but for fixing specific bugs; should be associated with a Github Issue if applicable

All changes to develop and release branches should be handled via Github’s “Pull Request” (PR) functionality, from a feature or bug-fix branch in the developer’s fork.

    * Before opening a PR, a minimum set of tests should be run

        * At least one end-to-end test (preferably a fundamental test suite) should be run on at least one supported platform
        * Any new functionality should be tested explicitly, and tests should be described in detail in the PR message

            * Depending on the impact of this functionality, this test should be added to the suite of fundamental or comprehensive tests

        * A developer may open a draft PR prior to meeting all of these requirements, but they must be met prior to opening the PR for review

    * A PR should be reviewed and approved by at least two code managers

Release branches will be branched from develop according to the UFS development schedule and will be used for testing and bug-fixing of the semi-frozen/”slushed” code prior to official releases.

Keeping testing suite up-to-date
When new capabilities are added, or new bugs/issues are discovered, tests should be created and/or modified to test for these conditions. Code developers introducing new capabilities should work with code managers to provide the proper configuration files, data, and other information necessary to create new tests for these capabilities.

===================================
Code and Configuration Standards
===================================

General
-----------

Platform-specific settings should be handled only through configuration and module files. Not in code or scripts.

SRW
----------

Externals.cfg
    * Only a single hash will be maintained for any given external code base. 
    * All externals should point to a static hash (not the top of a branch).
    * All externals live in a single Externals.cfg file.
    * Externals should point to authoritative repositories for the given code base.
Build system
    * Each component should build with CMake
    * Each component should build with Intel compilers on official tier-1 platforms, and either GNU or Intel compilers on other platforms
    * Each component should have a mechanism for platform independence
        * i.e. no hard-coded machine-specific settings outside of established environment, configuration, and module files
    * Each component should build with the latest release of hpc-stack


Module files (env files)
    * Each component should build using the common

regional_workflow
----------------------
Regional workflow must not contain source code for compiled programs. Only scripts, configuration files, and documentation should reside in this repository
Coding Standards: General
    * All bash scripts must explicitly be #!/bin/bash scripts. They should not be login-enabled.
    * MacOS requires special consideration as it does not have all Linux utilities by default. Developers should ensure they do not break these capabilities.
    * All code must be indented appropriately, and keeping with the style of existing scripts.
Workflow Design. Follow the NCO Guidelines for what is incorporated in each layer.
    * This is particularly important in the scripts/ directory
Module files (env files)
    * All official platforms should have an environment file that can be sourced to provide the appropriate python packages and other settings
Configuration file management.
    * Added configurable options must be consistent with existing configurable options. Add necessary checks on acceptable options where applicable. Add appropriate default values.
Template file management.
    * Jinja Templates include …
    * If a new configurable option is required in an existing template, it must be handled similarly to its counterparts in the scripts that fill in the template.
        * Example: if a new type of namelist is introduced for, say, a new component to the application, it should make use of the existing jinja framework for populating namelist settings.
Namelist management.
    * Namelists in ufs-srweather-app and regional_workflow are managed by setting YAML configuration parameters and generated using a Python tool. This allows for the management of multiple configuration settings with maximum flexibility and minimum duplication of information.
Coding Standards: Python.
    * All newly added Python code must be linted with a score of 10/10 following the .pylintrc configuration file set by the code managers. This will be checked in github actions.
    * All Python code contributions should come with an appropriate environment.yml file for the feature. Please reach out for support with this requirement, if needed.
    * Keep the use of external Python packages to a minimum for necessary workflow tasks.
        * Currently these include f90nml, pyyaml, and jinja

===========================
Contributor Requirements
===========================

Preparing code for contribution to the UFS SRW Application
------------------------------------------------------------
Opening an issue
All changes, whether a bug fix, new feature, or other modification, should be associated with a GitHub Issue. If a developer is working on a change, they should search the existing issues in the appropriate repository (ufs-srweather-app and/or regional_workflow). If one does not exist for the particular work they are doing, they should create one prior to opening a new pull request.

All modifications
Should follow the “code standards” section of this document
If possible, run a fundamental test suite on one supported platform and report on the outcome in PR template.
If changes are made to regional_workflow, a corresponding PR to ufs-srweather-app should also be opened to update the regional_workflow hash
Modifying existing code
For changes in the regional_workflow/scripts directory, developers should follow the NCO Guidelines for what is incorporated in each layer as closely as possible. 
Modifications should not break any existing supported capabilities on any supported platforms. 
Developers will not be required to run tests on all supported platforms, but if a failure is pointed out by another reviewer (or by automated testing) then the developer should work with reviewers and code managers to ensure the problem is resolved prior to merging.
Developers should ensure their contributions work with the most recent version of the ufs-srweather-app, including all the specific up-to-date hashes of each subcomponent.
Adding new components
Components should have a mechanism for portability and platform-independence; code that is included in the UFS SRW App should not be tied to specific platforms. 
New components should be able to build using the standard supported NCEPLIBS environment (currently hpc-stack).
New entries in Externals.cfg should only be repositories from “official” sources; either the ufs-community GitHub organization or another project organization.



Opening new pull requests
-----------------------------
Developers should follow the template PR messages included in each repository
Provide links to relevant GitHub issue(s)
Provide details of which tests were run on which machines
If the developer wants to make use of automated testing, any SRW + regional_workflow dependencies must be opened in PRs from the same user fork and branch.
The Externals.cfg file should point to any dependent branches in regional_workflow (and other components if necessary) while under review. Before being merged, these references must be updated to the appropriate hashes in the authoritative repositories (in the ufs-community GitHub organization).

Merging pull requests
-------------------------
Pull requests should be reviewed and approved by at least two code managers. Reviewers should ensure that the PR meets the requirements laid out in this document prior to approval.

When a PR has met the requirements and been approved by code reviewers, the developer who opened the PR may merge the PR, or can request that another developer or code manager do so (for example, if they do not have permissions to do so). The person merging the PR should follow the “Checklist for merging a PR” at the end of this document.

While repository administrators have the technical ability to merge pull requests without meeting the approval requirements, they should not do so.

Checklist for merging a PR
----------------------------
If code has changed since the PR was opened, ensure that appropriate tests have been re-run prior to merging.
(SRW App only) If the PR branch depends on PRs in other repositories, ensure all hashes have been updated in Externals.cfg to point to the updated code in the relevant repositories
Select “Squash and merge” if it is not already selected
Copy the PR message into the commit message box, overwriting the default contents
Select “Confirm squash and merge” to complete the merge







