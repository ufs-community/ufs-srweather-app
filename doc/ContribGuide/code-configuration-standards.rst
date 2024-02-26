==================================
Code and Configuration Standards
==================================

General Policies
==================

* Platform-specific settings should be handled only through configuration and modulefiles, not in code or scripts.
* For changes to the ``scripts``, ``ush``, or ``jobs`` directories, developers should follow the :nco:`NCO Guidelines <>` for what is incorporated into each layer. 
* Developers should ensure that their contributions work with the most recent version of the ``ufs-srweather-app``, including all the specific up-to-date hashes of each subcomponent.
* Modifications should not break any existing supported capabilities on any supported platforms.
* Update the RST documentation files where appropriate as part of the PR. If necessary, contributors may update the documentation in a subsequent PR. In these cases, the contributor should :srw-repo:`open an issue <issues/new/choose>` reflecting the need for documentation and include the issue number and explanation in the Documentation section of their initial PR. 
* Binary files will no longer be merged into the ``develop`` branch.  A binary file is defined as a "non-text" file and can include ``*.png``, ``*.gif``, ``*.jp*g``, ``*.tiff``, ``*.tar``, ``*.tgz``, ``*.gz``, ``*.mod``, ``*.o``, and executables.  If a binary file needs to be staged in the ``ufs-srweather-app`` repository, please add it to the wiki's repository.  The command to clone the ``ufs-srweather-app``'s wiki repository is ``git clone https://github.com/ufs-community/ufs-srweather-app.wiki.git``. Users with write access to the wiki repository can add the files here and link them to the documentation as needed. Users who do not have write access to the wiki repository should reach out to @MichaelLueken and/or note this in their pull request so that the files can be added. 

SRW Application Guidelines
============================


**General Coding Standards:** 

* The ``ufs-srweather-app`` repository must not contain source code for compiled programs. Only scripts and configuration files should reside in this repository. 
* All bash scripts must explicitly be ``#!/bin/bash`` scripts. They should *not* be login-enabled (i.e., scripts should *not* use the ``-l`` flag).
* MacOS does not have all Linux utilities by default. Developers should ensure that they do not break any MacOS capabilities with their contribution.
* All code must be indented appropriately and conform to the style of existing scripts (e.g., local variables should be lowercase, global variables should be uppercase).

**External Components**

* All externals live in a single ``Externals.cfg`` file.
* Only a single hash will be maintained for any given external code base. All externals should point to this static hash (not to the top of a branch). 
* All new entries in ``Externals.cfg`` must point only to authoritative repositories. In other words, entries must point to either a `ufs-community GitHub organization <https://github.com/ufs-community>`__ repository or another NOAA project organization repository. 

   * Temporary exceptions are made for a PR into the ``develop`` branch of ``ufs-srweather-app`` that is dependent on another PR. When the component PR is merged, the contributor must update the corresponding ``ufs-srweather-app`` PR with the hash of the component's authoritative repository.
    
**Build System**

* Each component must build with CMake
* Each component must build with Intel compilers on official :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` platforms and with GNU or Intel compilers on other platforms. 
* Each component must have a mechanism for platform independence (i.e., no hard-coded machine-specific settings outside of established environment, configuration, and modulefiles). 
* Each component must build with the standard supported NCEPLIBS environment (currently `spack-stack <https://github.com/JCSDA/spack-stack>`__). 

**Modulefiles**

* All official platforms should have a modulefile that can be sourced to provide the appropriate Python packages and other settings for the platform. 
* Each SRW component must build using the common modules located in the ``modulefiles/srw_common`` file.


Workflow Coding Standards
--------------------------

**Python Coding Standards:** 

 * All new Python workflow contributions should come with an appropriate environment YAML file (similar to ``environment.yaml``, ``graphics_environment.yaml``, and ``aqm_environment.yaml``). 
 * Keep the use of external Python packages to a minimum for necessary workflow tasks. Currently, these include ``f90nml``, ``pyyaml``, and ``Jinja2``. 

**Workflow Design:** Follow the :nco:`NCO Guidelines <>` for what is incorporated in each layer of the workflow. This is particularly important in the ``scripts`` directory. 

**Management of the Configuration File:** New configurable options must be consistent with existing configurable options and be documented in :srw-repo:`UsersGuide/CustomizingTheWorkflow/ConfigWorkflow.rst <blob/develop/doc/UsersGuide/CustomizingTheWorkflow/ConfigWorkflow.rst>`. Add necessary checks on acceptable options where applicable. Add appropriate default values in ``config_defaults.yaml``.

**Management of Template Files:** If a new configurable option is required in an existing template, it must be handled similarly to its counterparts in the scripts that fill in the template. For example, if a new type of namelist is introduced for a new application component, it should make use of the existing ``jinja`` framework for populating namelist settings.

**Namelist Management:** Namelists in ``ufs-srweather-app`` are generated using a Python tool and managed by setting YAML configuration parameters. This allows for the management of multiple configuration settings with maximum flexibility and minimum duplication of information. 