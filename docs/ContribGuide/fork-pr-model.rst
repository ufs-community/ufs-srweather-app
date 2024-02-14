=================
Fork and PR Model
=================

.. note:: 
   
   Thank you to the UW Tools team for authoring this summary of the Fork and PR Model. It has been adapted slightly for use in the SRW App. The original can be viewed in the :doc:`uwtools documentation <uw:fork_pr_model>`.

Overview
========

Contributions to the ``ufs-srweather-app`` project are made via a :github-docs:`Fork<pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks>` and :github-docs:`Pull Request (PR)<pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests>` model. GitHub provides a thorough description of this contribution model in their `Contributing to a project` :github-docs:`Quickstart<get-started/exploring-projects-on-github/contributing-to-a-project>`, but the steps, with respect to ``ufs-srweather-app`` contributions, can be summarized as:

#. :github-docs:`Fork<get-started/exploring-projects-on-github/contributing-to-a-project#forking-a-repository>` the :srw:`SRW App repository<>` into your personal GitHub account.
#. :github-docs:`Clone<get-started/exploring-projects-on-github/contributing-to-a-project>` your fork onto your development system.
#. :github-docs:`Create a branch<get-started/exploring-projects-on-github/contributing-to-a-project#creating-a-branch-to-work-on>` in your clone for your changes.
#. :github-docs:`Make, commit, and push changes<get-started/exploring-projects-on-github/contributing-to-a-project#making-and-pushing-changes>` in your clone / to your fork. (Refer to the :doc:`Developer Setup <developer-setup>` page for setting up a development shell, formatting and testing your code, etc.)
#. When your work is complete, :github-docs:`create a pull request<get-started/exploring-projects-on-github/contributing-to-a-project#making-a-pull-request>` to merge your changes.

.. COMMENT: Remove parenthetical in 2nd to last bullet?

For future contributions, you may delete and then recreate your fork or configure the official ``ufs-srweather-app`` repository as a :github-docs:`remote repository<pull-requests/collaborating-with-pull-requests/working-with-forks/configuring-a-remote-repository-for-a-fork>` on your clone and :github-docs:`sync upstream changes<pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork>` to stay up-to-date with the official repository.

Specifics for ``ufs-srweather-app``
===================================

When creating your PR, please follow these guidelines, specific to the ``ufs-srweather-app`` project:

* Ensure that your PR is targeting base repository ``ufs-community/ufs-srweather-app`` and base branch ``develop``.
* Your PR's **Add a description** field will appear pre-populated with a template that you should complete. Provide an informative synopsis of your contribution, then mark appropriate checklist items by placing an "x" between their square brackets. You may tidy up the description by removing boilerplate text and non-selected checklist items.
* Use the pull-down arrow on the green button below the description to initially create a :github-docs:`draft pull request<pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests#draft-pull-requests>`.
* Once your draft PR is open, visit its **Files changed** tab and add comments on any lines of code that you think reviewers will benefit from. Try to save time by proactively answering questions you suspect reviewers will ask.
* Once your draft PR is marked up with your comments, return to the **Conversation** tab and click the **Ready for review** button.

A default set of reviewers will automatically be added to your PR. You may add others, if appropriate. Reviewers may make comments, ask questions, or request changes on your PR. Respond to these as needed, making commits in your clone and pushing to your fork/branch. Your PR will automatically be updated when commits are pushed to its source branch in your fork, so reviewers will immediately see your updates.

Merging
========

Your PR is ready to merge when:

#. It has been approved by a required number of ``ufs-srweather-app`` reviewers, including at least one code manager.
#. All conversations have been marked as resolved.
#. All required checks have passed.

These criteria and their current statuses are detailed in a section at the bottom of your PR's **Conversation** tab. Checks take some time to run, so please be patient.

In general, the lead code manager will merge the PR when ready. Developers with write permissions should not merge their code themselves unless instructed otherwise by the lead code manager.

Need Help?
===========

Please use comments in the **Conversation** tab of your PR to ask for help with any difficulties you encounter using this process!



.. COMMENT: Decide what to add/delete/modify of content below: 

Contribution Process
======================

The steps below should be followed in order to make changes to the `develop` branch of the `ufs-srweather-app` repository. Communication with code managers and the code management team throughout the process is encouraged.

#. **Issue** - Open an issue to document changes. Click :srw:`here <issues/new/choose>` to open a new ``ufs-srweather-app`` issue or see the section on :ref:`Opening an Issue <open-issue>` for detailed instructions. 
#. **GitFlow** - Follow `GitFlow <https://nvie.com/posts/a-successful-git-branching-model>`__ procedures for development. 
#. **Fork the repository** - Read more :github-docs:`here <get-started/quickstart/fork-a-repo>` about forking in GitHub.
#. **Create a branch** - Create a branch in your fork of the authoritative repository. Follow `GitFlow <https://nvie.com/posts/a-successful-git-branching-model>`__ conventions when creating the branch. All development should take place on a branch, *not* on ``develop``. Branches should be named as follows, where [name] is a one-word description of the branch:
   * **bugfix/[name]:** Fixes a demonstrably incorrect portion of code
   * **feature/[name]:** Adds a new feature to the code or improves an existing portion of the code
   * **text/[name]:** Changes elements of the repository that do not impact program output or log files (e.g., changes to README, documentation, comments, changing quoted Registry elements, white space alignment). Any change that does not impact the compiled code in any way should fall under this category.
         
1. **Development** - Perform and test changes in the feature branch (not on `develop`!). Document work in the issue and mention the issue number in commit messages to link your work to the issue (e.g., ``commit -m "Issue #23 - <commit message>"``). Test code modifications on as many platforms as possible, and request help with further testing from the code management team when unable to test on all Level 1 platforms. Document changes to the workflow and capabilities in the ``.rst`` files so that the SRW App documentation stays up-to-date. 
1. **Pull request** - When ready to merge changes back to the ``develop`` branch, the code developer should initiate a pull request (PR) of the feature branch into the ``develop`` branch. Read :github-docs:`here <pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests>` about pull requests in GitHub. When a PR is initiated, the PR Template autofills. Developers should use the template to provide information about the PR in the proper fields. See the guidelines in the :ref:`Making a Pull Request <make-pr>` section for more details on making a good pull request. Developers should also tag all relevant reviewers from the code management team on the PR.
1. **Merge** - When review and testing are complete, a code manager will merge the PR into `develop`. PRs that are not ready for merging should have a "Work in Progress" label on them. Users who lack the permissions required to add the label can request in their PR that a code manager do so.
1. **Cleanup** - After the PR is merged, the code developer should delete the branch on their fork and close the issue.

**Note:** Feature branches are intended to be short-lived, concentrated on code with one sole purpose, and applicable to a single PR. These branches should be deleted once merged, and a new feature branch should be created when subsequent code development continues.

.. _open-issue:

Opening an Issue
==================

All changes should be associated with a GitHub Issue. If developers are working on a change, they should search the existing issues in the ``ufs-srweather-app`` repository. If an issue does not exist for the work they are doing, they should create one prior to opening a new pull request. 

To open an issue, click on "New Issue" within the ``ufs-srweather-app`` GitHub repository. 

Choose from three options: 

#. :srw:`Bug Report <issues/new?assignees=&labels=bug&template=bug_report.md&title=>`: Report specific problems ("bugs") in the code using the following template:

   .. code-block:: console

        <!-- Please remove unwanted/unrelated/irrelevant information such as comments.
        Please copy any output files into a public Github gist (see https://gist.github.com/) and link 
        to the gist, rather than relying on paths that might change. -->

        Your bug may already be reported!
        Please search on the [Issue tracker](https://github.com/ufs-community/ufs-srweather-app/issues) 
        before creating a new issue. If an issue already exists, please use that issue to add any 
        additional information.

        ## Expected behavior
        <!-- Tell us what should happen. -->

        ## Current behavior
        <!-- Tell us what happens instead of the expected behavior. -->

        ## Machines affected
        <!--- Please provide any relevant information about your setup, including machine/compiler 
        combination. -->
        <!-- Reference other issues or PRs in other repositories that this issue is related to, and how 
        they are related. -->

        ## Steps To Reproduce
        <!--- Provide a link to a live example, a code snippet, and/or an explicit set of steps to 
        reproduce this bug.
            1. Step 1
            2. Step 2
            3. See the bug... -->

        ## Detailed Description of Fix (optional)
        <!--- Provide a detailed description of the change or addition you are proposing. -->

        ## Additional Information (optional)
        <!-- Any other relevant information that we should know to correctly understand and reproduce 
        the issue. 
        Please describe in as much detail as possible. -->

        ## Possible Implementation (optional)
        <!--- Suggest an idea for implementing addition or change. -->

        ## Output (optional)
        <!-- Please include any relevant log files, screenshots or other output here. -->

#. :srw:`Feature Request <issues/new?assignees=&labels=enhancement&template=feature_request.md&title=`: New features and feature enhancements fall under this category. Propose features and enhancements using the following template. Optional sections may be deleted.

   .. code-block:: console

        <!-- Please remove unwanted/unrelated/irrelevant information such as comments.
        Please copy any output files into a public Github gist (see https://gist.github.com/) 
        and link to the gist, rather than relying on paths that might change. -->

        Your issue may already be reported!
        Please search on the [Issue tracker](https://github.com/ufs-community/ufs-srweather-app/issues) 
        before creating a new issue. If an issue already exists, please use that issue to add any 
        additional information.

        ## Description
        <!-- Provide a clear and concise description of the problem to be solved. -->
        <!-- What problem needs to be fixed? -->
        <!-- What new capability needs to be added? --> 

        ## Solution
        <!-- Add a clear and concise description of the proposed solution. -->

        ## Requirements**
        <!-- What does the new code need to accomplish? Does it require an update 
        to a version of software (e.g. modules of NCEPLibs, NetCDF, etc.), components 
        (e.g. UFS-Weather-Model), or system tools (e.g. python3) -->

        ## Acceptance Criteria (Definition of Done)
        <!-- What does it mean for this feature to be finished? -->

        ## Dependencies (optional)
        <!-- Directly reference any issues or PRs in this or other repositories that this 
        issue is related to, and describe how they are related. -->
        <!-- Does this block progress on other issues? Add this issue as a dependency to 
        other issues as appropriate e.g. #IssueNumber has a dependency on this issue -->

        ## Alternative Solutions (optional)
        <!-- If applicable, add a description of any alternative solutions or features 
        you've considered. -->


#. :srw:`Text-Only Changes <issues/new?assignees=&labels=textonly&template=textonly_request.md&title=>`: Propose text-only changes using the "Text-only request" template. Optional sections may be deleted.

   .. code-block:: console

        ## Description
        <!-- Provide a clear and concise description of the problem to be solved. -->

        ## Solution
        <!-- Add a clear and concise description of the proposed solution. -->

        ## Alternatives (optional)
        <!-- If applicable, add a description of any alternative solutions or features you've 
        considered. -->

        ## Related to (optional)
        <!-- Directly reference any issues or PRs in this or other repositories that this is 
        related to, and describe how they are related. -->

#. :srw:`Other <new>`: Open a blank issue, and use the "Feature Request" template above as a starting point to describe the issue. 

For all issue reports, indicate whether this is an issue that you plan to work on and eventually submit a PR for or whether you are merely making a suggestion. Additionally, please add a priority label to the issue (low, medium, or high priority).  If you are unable to add labels to your issues, please request that a code manager add a priority for you. If the issue you are making is for a bug fix, work related to a failing test configuration, or an update required for a release (either an operational implementation or public release), please add the ``high priority`` label. New features that are not required immediately for either an implementation or release, please add the ``medium priority`` label. Finally, please use the ``low priority`` label for refactoring work or if you feel that the work is low priority. If you are unable to work the issue and require assistance through EPIC, please make sure to include the ``EPIC Support Requested`` label. Unfortunately, if the ``EPIC Support Requested`` label is added to a ``high priority`` issue, it might take some time before EPIC will work on the issue, since EPIC management needs to account for these issues.  However, after seeing that EPIC is required for high priority issues, management will adapt and have the necessary resources in place to assist. After filling out the issue report, click on "Submit new issue."

.. _make-pr:

Making a Pull Request
======================

All changes to the SRW App ``develop`` branch should be handled via GitHub’s “Pull Request” (PR) functionality from a branch in the developer’s fork. Developers must follow the template PR instructions below and provide links to the relevant GitHub issue(s). They must also indicate which tests were run on which machines. The bare minimum testing required before opening a PR is to run the fundamental (:srw:`tests/WE2E/machine_suites/fundamental <blob/develop/tests/WE2E/machine_suites/fundamental>`) tests on at least one supported machine (additional testing from the comprehensive suite might be required, depending on the nature of the change). To manually run the fundamental tests, please use the following command in the ``tests/WE2E`` directory:

.. code-block:: console

   ./run_WE2E_tests.py -t=fundamental -m=your_machine -a=your_account

where `your_machine` is the Tier-1 machine you are running the tests on, and `your_account` is the account you charge your computational resources to.

Pull requests will be reviewed and approved by at least two code reviewers, at least one of whom must be a code manager. When a PR has met the contribution and testing requirements and has been approved by two code reviewers, a code manager will merge the PR.

PR Template
^^^^^^^^^^^^^

Here is the template that is provided when developers click "Create pull request":

.. code-block:: console

    - Update develop to head at ufs-community
    - Use this template to give a detailed message describing the change you want to make to the code.
    - You may delete any sections labeled "optional" and any instructions within <!-- these sections -->.
    - If you are unclear on what should be written here, see 
      https://github.com/wrf-model/WRF/wiki/Making-a-good-pull-request-message for some 
      guidance and review the Code Contributor's Guide at 
      https://github.com/ufs-community/ufs-srweather-app/wiki/Code-Manager's-Guide. 
    - Code reviewers will assess the PR based on the criteria laid out in the Code Reviewer's Guide 
      (https://github.com/ufs-community/ufs-srweather-app/wiki/Code-Manager's-Guide). 
    - The title of this pull request should be a brief summary (ideally less than 100 characters) of the 
      changes included in this PR. Please also include the branch to which this PR is being issued 
      (e.g., "[develop]: Updated UFS_UTILS hash").
    - Use the "Preview" tab to see what your PR will look like when you hit "Create pull request"

    # --- Delete this line and those above before hitting "Create pull request" ---

    ## DESCRIPTION OF CHANGES: 
    <!-- One or more paragraphs describing the problem, solution, and required changes. -->

    ### Type of change
    <!-- Please delete options that are not relevant. Add an X to check off a box. -->
    - [ ] Bug fix (non-breaking change which fixes an issue)
    - [ ] New feature (non-breaking change which adds functionality)
    - [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
    - [ ] This change requires a documentation update

    ## TESTS CONDUCTED: 
    <!-- Explicitly state what tests were run on these changes, or if any are still pending (for README 
    or other text-only changes, just put "None required"). Make note of the compilers used, the 
    platform/machine, and other relevant details as necessary. 
    For more complicated changes, or those resulting in scientific changes, please be explicit! -->
    <!-- Add an X to check off a box. -->

    - [ ] hera.intel
    - [ ] orion.intel
    - [ ] cheyenne.intel
    - [ ] cheyenne.gnu
    - [ ] gaea.intel
    - [ ] jet.intel
    - [ ] wcoss2.intel
    - [ ] NOAA Cloud (indicate which platform)
    - [ ] Jenkins
    - [ ] fundamental test suite
    - [ ] comprehensive tests (specify *which* if a subset was used)

    ## DEPENDENCIES:
    <!-- Add any links to external PRs (e.g. UFS PRs). For example:
    - ufs-community/UFS_UTILS/pull/<pr_number>
    - ufs-community/ufs-weather-model/pull/<pr_number> -->

    ## DOCUMENTATION:
    <!-- If this PR is contributing new capabilities that need to be documented, please also include 
    updates to the RST files 
    (docs/UsersGuide/source) as supporting material. -->

    ## ISSUE: 
    <!-- If this PR is resolving or referencing one or more issues, in this repository or 
    elsewhere, list them here (Remember, issues must always be created before starting work 
    on a PR branch!). For example, "Fixes issue mentioned in #123" or "Related to bug in 
    https://github.com/ufs-community/other_repository/pull/63" -->

    ## CHECKLIST
    <!-- Add an X to check off a box. -->
    - [ ] My code follows the style guidelines in the Contributor's Guide
    - [ ] I have performed a self-review of my own code using the Code Reviewer's Guide
    - [ ] I have commented my code, particularly in hard-to-understand areas
    - [ ] My changes need updates to the documentation. I have made corresponding changes to the 
          documentation
    - [ ] My changes do not require updates to the documentation (explain).
    - [ ] My changes generate no new warnings
    - [ ] New and existing tests pass with my changes
    - [ ] Any dependent changes have been merged and published

    ## LABELS (optional): 
    <!-- If you do not have permissions to add labels to your own PR, request that labels be added here. 
    Add an X to check off a box. Delete any unnecessary labels. -->
    A Code Manager needs to add the following labels to this PR: 
    - [ ] Work In Progress
    - [ ] bug
    - [ ] enhancement
    - [ ] documentation
    - [ ] release
    - [ ] high priority
    - [ ] run_ci
    - [ ] run_we2e_fundamental_tests
    - [ ] run_we2e_comprehensive_tests
    - [ ] Needs Cheyenne test 
    - [ ] Needs Jet test 
    - [ ] Needs Hera test 
    - [ ] Needs Orion test 
    - [ ] help wanted

    ## CONTRIBUTORS (optional): 
    <!-- If others have contributed to this work aside from the PR author, list them here -->


Additional Guidance
^^^^^^^^^^^^^^^^^^^^^

**TITLE:** Titles should start with the branch name in brackets and should give code reviewers a clear idea of what the change will do in approximately 5-10 words. Some good examples:

    * [develop] Make thompson_mynn_lam3km ccpp suite available
    * [release/public-v2] Add a build_linux_compiler modulefile
    * [develop] Fix module loads on Hera
    * [develop] Add support for Rocoto with generic LINUX platform

All of the above examples concisely describe the changes contained in the pull request. The title will not get cut off in emails and web pages. In contrast, here are some made-up (but plausible) examples of BAD pull request titles:

    * Bug fixes (Bug fixes on what part of the code?)
    * Changes to surface scheme (What kind of changes? Which surface scheme?)

**DESCRIPTION OF CHANGES:** The first line of the description should be a single-line "purpose" for this change. Note the type of change (i.e., bug fix, feature/enhancement, text-only). Summarize the problem, proposed solution, and required changes. If this is an enhancement or new feature, describe why the change is important.

**DOCUMENTATION:** Developers should include documentation on new capabilities and enhancements by updating the appropriate `.rst` documentation files in their fork prior to opening the PR. These documentation updates should be noted in the "Documentation" section of the PR message. If necessary, contributors may submit the `.rst` documentation in a subsequent PR. In these cases, the developers should include any existing documentation in the "Documentation" section of the initial PR message or as a file attachment to the PR. Then, the contributor should open an issue reflecting the need for official `.rst` documentation updates and include the issue number and explanation in the "Documentation" section of the initial PR template.
 

Tips, Best Practices, and Protocols to Follow When Issuing a PR
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* **Label PR status appropriately.** If the PR is not completely ready to be merged, please add a "Work In Progress" label. Urgent PRs should be marked "high priority." All PRs should have a type label (e.g., "bug," "enhancement"). Labels can be added on the right-hand side of a submitted PR request by clicking on the gear icon beside "Labels" (below the list of reviewers). If users do not have the permissions to add a label to their PR, they should request in their PR description that a code manager add the appropriate labels.
* **Indicate urgency.** If a PR is particularly urgent, this information should be provided in the PR "Description" section, and multiple code management team members should be tagged to draw attention to this PR. After submitting the PR, a "high priority" label should be added to it. 
* **Indicate the scope of the PR.** If the PR is extremely minor (e.g., change to the README file), indicate this in the PR message. If it is an extensive PR, the developer should test it on as many platforms as possible and stress the necessity that it be tested on systems for which they do not have access.
* **Clarify in the PR message where the code has been tested.** At a minimum, code should be tested on the platform where code modification has taken place. It should also be tested on machines where code modifications will impact results. If the developer does not have access to these platforms, this should be noted in the PR. 
* **Follow separation of concerns.** For example, module loads are only handled in the appropriate modulefiles, Rocoto always sets the work directory, j-jobs make the work directory, and ex-scripts require the work directory to exist.
* **Target subject matter experts (SMEs) among the code management team.** When possible, tag team members who are familiar with the modifications made in the PR so that the code management team can provide effective and streamlined PR reviews and approvals. Developers can tag SMEs by selecting the gear icon next to "Assignees" (under the Reviewers list) and adding the appropriate names. 
* **Schedule a live code review** if the PR is exceptionally complex in order to brief members of the code management team on the PR either in-person or through a teleconference. Developers should indicate in the PR message that they are interested in a live code review if they believe that it would be beneficial. 




