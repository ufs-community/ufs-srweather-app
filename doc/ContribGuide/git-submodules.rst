============================
Working with Git Submodules 
============================

.. note:: 
   
   Thank you to Janet Derrico (@jderrico-noaa) [#f1]_ for authoring the summary of Git submodules on which this chapter is based. [#f2]_ It has been adapted slightly for use in the SRW App. 

What Are Git Submodules?
=========================

Git submodules are pointers to other Git repositories. They enable developers to include external repositories as a subdirectory within their main project. This is particularly useful when a project depends on external libraries or components that are developed and maintained in separate repositories.

Key Benefits
=============

* **Version Control:** Submodules link to specific commits in external repositories, ensuring consistency and predictability. Developers can control exactly which version of an external repository their project depends on.
* **Separate Development:** Changes to submodules are tracked separately from the main repository, allowing for independent development of external dependencies.
* **Collaborative Workflows:** Multiple teams can work on different parts of a larger project simultaneously without interference, each with its own repository (e.g. changes to ``ccpp-physics`` can be developed at the same time as changes to ``ufs-weather-model``).

How Submodules Are Linked
==========================

Git knows which submodules to check out based on two key pieces of information: the submodule pointer, and the information on where to find that pointer. The pointer is a commit reference---when you add a submodule to your repository, Git doesn't just store the URL; it also records a specific commit hash from that submodule. The commit hash is what Git uses to know which exact state of the submodule to checkout. These commit references are stored in the main repository and are updated whenever a change is committed in the submodule. When you run ``git submodule update``, Git checks out the commit of each submodule according to  what is recorded in the main repository.  The ``.gitmodules`` file tracks where to find this information, storing the submodule's path within your repository and its corresponding URL.

If you commit a hash in a submodule but push to a different fork, then Git will add the new submodule hash to the supermodule, which will result in a Git error when trying to recursively check out the supermodule.

Adding a Submodule
===================

You can add a submodule to your repository using ``git submodule add <repository-url> <path>``. This clones the external repository to the specified path and adds a new entry in a special file named ``.gitmodules``.

Cloning a Repository with Submodules
=====================================
When cloning a repository that has submodules, use git clone --recursive to ensure that all submodules are also cloned.

Updating a Submodule
======================

To update a submodule, navigate into the submodule directory, check out the desired commit or branch, and then go back to the main repository to commit this change. Here is an example for making a change to ``ccpp-physics``, ``fv3``, and ``ufs-weather-model``. Since ``ccpp-phsyics`` is a submodule of ``fv3atm`` and ``ufs-weather-model``, a change to ``ccpp-physics`` requires PRs to all three repositories.
This method requires two remotes on your local workspace: the authoritative (e.g., ``ufs-community/ufs-weather-model``) and the personal fork you push to (e.g., ``jderrico-noaa/ufs-weather-model``). The steps involved are:

#. Clone locally
#. Create your working branches
#. Commit your changes
#. Push your working branches to your personal fork
#. Submit PRs from personal fork to authoritative

Cloning the Authoritative Repository and Adding Your Personal Fork
--------------------------------------------------------------------

Clone the authoritative repository to your local workspace:

.. code-block:: console
   
   git clone --recursive -b branch-name https://github.com/ufs-community/ufs-weather-model
   cd ufs-weather-model

where ``branch-name`` is the name of the branch you want to clone (usually ``develop``).

Adding Your Personal Fork as a Remote Repository
--------------------------------------------------

.. code-block:: console

   git remote add my-fork 

where ``my-fork`` is the name of your fork. You can name your fork whatever you want as long as you can distinguish it from the authoritative (e.g., janet) https://github.com/<github_username>/ufs-weather-model

Run: 

.. code-block:: console

   git remote -v 

to show the remote repositories that have been added to your local copy of ``ufs-weather-model``, if should show origin (the authoritative ufs-community repo) and my-fork (your personal fork that you push changes to)
The local repository for ufs-weather-model has been created. This process is repeated for the other submodules (``fv3atm`` and ``ccpp-physics``, where the code will be modified):

.. code-block:: console

   cd FV3
   git remote add my-fork https://github.com/<github_username>/fv3atm
   cd ccpp/physics
   git remote add my-fork https://github.com/<github_username>/ccpp-physics

Create Working Branches
------------------------

The next step is to create working branches that will hold your changes until they are merged. From ``ccpp-physics``, navigate up to ``ufs-weather-model``.  It is good practice to checkout the main branch (e.g., ``develop``) to ensure that you are working with the latest updates and then create your working branch. You will do this all the way down:


Then, navigate from ``ccpp/physics`` back to to ``ufs-weather-model`` and create a new branch to hold your changes:

.. code-block:: console

   cd ../../.. 
   git checkout -b working_branch 
   
This command creates a new branch named ``working_branch``; in practice the branch name should be more descriptive and reflect the development it will be holding. Follow the same process for the Git submodules you will be working in:

.. code-block:: console

   cd FV3
   git checkout develop
   git checkout -b working_branch
   cd ccpp/physics
   git checkout ufs/dev
   git checkout -b working_branch

Commit Changes and Push Working Branches
------------------------------------------

As you make changes to the code, you should commit often. This ensures that all of your development is tracked (so you don't lose anything) and makes it easier to go back to a working version if one of your changes breaks things (it happens!). Commit messages should be descriptive of the changes they contain.

To push your working branches to your fork from the top down, navigate to the ``ufs-weather model`` directory. Then run:

.. code-block:: console

   git push -u my-fork working_branch 

The ``-u`` flag here tells Git to set ``my-fork/working_branch`` as the default remote branch for ``working_branch``. After executing this command, you can simply use ``git push`` or ``git pull`` while on ``working_branch``, and Git will automatically know to push or pull from ``my_fork/working_branch``.

Continue this process with the other submodule repositories:

.. code-block:: console

   cd FV3
   git push -u my-fork working_branch
   cd ccpp/physics
   git push -u my-fork working_branch

All working changes are now in your personal fork.

Submitting PRs
---------------

When working with Git submodules, developers must submit individual pull requests to each repository where changes were made and link them to each other. In this case, developers would submit PRs to ``ufs-weather-model``, ``fv3atm``, and ``ccpp-physics``. There are several steps to this process: opening the PR, updating the submodules, and creating new submodule pointers. Each authoritative repository should have its own PR template that includes space to link to the URLs of related PRs. If for some reason this is not the case, developers should link to the related PRs in the "Description" section of their PR.

Updating the Submodules
^^^^^^^^^^^^^^^^^^^^^^^^

When changes are made to the authoritative repositories while you are developing or while your PR is open, you need to update the PR to include those updates.  From your local workspace, navigate to ``ufs-weather-model`` and run:

.. code-block:: console

   git checkout develop
   git pull origin develop
   git checkout working_branch
   git merge develop
   git push -u my-fork working_branch 

This will check out the ``develop`` branch, retrieve the latest updates, then check out the ``working_branch`` and merge the latest changes from ``develop`` into it. After pushing the changes on ``working_branch`` to your personal fork, your PR will update automatically. This process must then be repeated for the other components (e.g., ``fv3`` and ``ccpp-physics``). It is important to check that you are merging the correct branch---for example, the main development branch in ``ufs-community/ccpp-physics`` is ``ufs/dev``, so you would checkout/pull ``ufs/dev`` instead.

.. note:: 
   
   If you have already pushed ``working_branch`` to ``my-fork`` using the ``-u`` flag, you can omit the flag and fork specification, but it doesn't hurt to use them.

Add Submodule Pointers
^^^^^^^^^^^^^^^^^^^^^^^
To create submodule pointers, developers will navigate to the lowest submodule directory (rather than going from the top down) to create pointers linking the submodule to the supermodule. In this example, we are using *ufs-weather-model → fv3 → ccpp-physics*, so developers would start by navigating to ``ccpp-physics``.  Once your PR to ``ccpp-physics`` is merged, you then need to update your PRs to ``fv3`` and ``ufs-weather-model`` so that they point to the updated ``ccpp-physics`` submodule.

First, update the local copy of ``ccpp-physics`` with what was merged to the authoritative (e.g., your changes): 

.. code-block:: console

   git checkout ufs/dev
   git pull origin ufs/dev 

Then navigate to ``fv3atm``: 

.. code-block:: console

   cd ../.. 

If you were working with other submodules, you would navigate to submodule above the lowest here. Then create the submodule pointer, commit the change, and push it to your fork of ``fv3atm``:

.. code-block:: console

   git checkout working_branch
   git add ccpp/physics 
   git commit -m "update submodule pointer for ccpp-physics"
   git push -u my-fork working_branch 

Once again, pushing to your personal fork will automatically update the PR that includes ``working_branch``.

The ``fv3atm`` code managers will then merge your ``fv3atm`` PR, at which point only the ``ufs-weather-model`` PR will require a submodule pointer update. From your local workspace, navigate to the ``fv3`` directory (``ufs-weather-model/FV3``) and update the local copy of ``fv3atm`` with what was just merged into the authoritative: 

.. code-block:: console

   git checkout develop
   git pull origin develop 

Then, navigate up to ``ufs-weather model`` directory, check out the working branch, and add the submodule pointer for ``fv3atm``. Commit and push the changes to your personal fork. 

.. code-block:: console

   cd .. 
   git checkout working_branch
   git add FV3
   git commit -m "update submodule pointer for fv3atm"
   git push -u my-fork

The UFS code managers will then test and merge the ``ufs-weather-model`` PR.

Switching Branches With Submodules
====================================

If you are working off a branch that has different versions (or commit references/pointers) of submodules, it is important to synchronize the submodules correctly. From the supermodule, you would switch to your desired branch and then update the submodules. For example, if you want to work on a different branch of the ``ufs-weather-model`` repository:

.. code-block:: console

   git checkout desired_branch
   git submodule update --init --recursive 

Here, ``--init`` initializes any submodules that have not yet been initialized, while ``--recursive`` ensures that all nested submodules (e.g., ``fv3atm``) are updated. If you know there have been upstream changes to a submodule, and you want to incorporate these latest changes, you would go into each submodule directory and pull the changes:

.. code-block:: console

   cd path/to/submodule
   git pull origin <submodule_branch>

When working with submodules, it is best practice to always run ``git submodule update --init --recursive`` after switching branches. Changes to submodules need to be committed and pushed separately within their respective repositories (see sections above).

.. [#f1] of NOAA Global Systems Laboratory (GSL) and Coorperative Institute for Research in Environmental Sciences (CIRES)
.. [#f2] with the assistance of Grant Firl, Joseph Olson, and ChatGPT 