.. _Introduction:

==============
Introduction
==============

The Unified Forecast System (:term:`UFS`) is a community-based, coupled, comprehensive Earth modeling system. NOAA's operational model suite for numerical weather prediction (:term:`NWP`) is quickly transitioning to the UFS from a number of different modeling systems. The UFS enables research, development, and contribution opportunities within the broader :term:`Weather Enterprise` (including government, industry, and academia). For more information about the UFS, visit the `UFS Portal <https://ufscommunity.org/>`__.

The UFS includes `multiple applications <https://ufscommunity.org/science/aboutapps/>`__ that support different forecast durations and spatial domains. This documentation describes the UFS Short-Range Weather (SRW) Application, which targets predictions of atmospheric behavior on a limited spatial domain and on time scales from minutes to several days. The most recent SRW Application includes a prognostic atmospheric model, pre- and post-processing, and a community workflow for running the system end-to-end. These components are documented within this User's Guide and supported through the `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ forum. The SRW App also includes support for a verification package (METplus) for both deterministic and ensemble simulations and support for four stochastically perturbed physics schemes. 

Since the last release, developers have added a variety of features:

   * Bug fixes since the v2.1.0 release
   * Addition of the supported ``FV3_RAP`` physics suite (:srw-repo:`PR #811 <pull/811>`) and support for the ``RRFS_NA_13km`` predefined grid
   * Addition of ``FV3_GFS_v17_p8`` physics suite (:srw-repo:`PR #574 <pull/574>`)
   * Updates to :term:`CCPP` that target the top of the ``main`` branch (which is ahead of CCPP v6.0.0). See :ref:`this page <CCPPUpdates>` for a detailed summary of updates that came in ahead of the v2.2.0 release.
   * Expansion of :srw-wiki:`Level 1 platforms <Supported-Platforms-and-Compilers>` to include Derecho, Hercules, and Gaea C5 (PRs :srw-repo:`#894 <pull/894>`, :srw-repo:`#898 <pull/898>`, :srw-repo:`#911 <pull/911>`)
   * Transition to spack-stack modulefiles for most supported platforms to align with the UFS WM shift to spack-stack (PRs :srw-repo:`#913 <pull/913>` and :srw-repo:`#941 <pull/941>`)
   * Overhaul of the WE2E testing suite (see, e.g., PRs :srw-repo:`#686 <pull/686>`, :srw-repo:`#732 <pull/732>`,  :srw-repo:`#864 <pull/864>`, :srw-repo:`#871 <pull/871>`)
   * Improvements to the CI/CD automated testing pipeline (see, e.g., PRs :pull/707>` and :srw-repo:`#847 <pull/847>`)
   * Incorporation of additional METplus verification capabilities (PRs :srw-repo:`#552 <pull/552>`, :srw-repo:`#614 <pull/614>`, :srw-repo:`#757 <pull/757>`, :srw-repo:`#853 <pull/853>`)
   * Integration of the Unified Workflow's templater tool (:srw-repo:`PR #793 <pull/793>`)
   * Ability to create a user-defined custom workflow (:srw-repo:`PR #676 <pull/676>`)
   * Option to use a custom vertical coordinate file with different distribution of vertical layers (:srw-repo:`PR #813 <pull/813>`) and :ref:`documentation on how to use this feature <VerticalLevels>` (:srw-repo:`PR #888 <pull/888>`)
   * Incorporation of plotting tasks into the workflow (PR :srw-repo:`#482 <pull/482>`); addition of ability to plot on both CONUS and smaller regional grid (:srw-repo:`PR #560 <pull/560>`)
   * Addition of a sample verification case (:srw-repo:`PR #500 <pull/500>`) with :ref:`documentation <VXCases>` 
   * A new :ref:`tutorial chapter <Tutorial>` in the documentation (:srw-repo:`PR #584 <pull/584>`)
   * Incorporation of `UFS Case Studies <https://github.com/dtcenter/ufs-case-studies>`__ within the WE2E framework (PRs :srw-repo:`#736 <pull/736>` and :srw-repo:`#822 <pull/822>`)
   * Air Quality Modeling (AQM) capabilities (unsupported but available; see :srw-repo:`PR #613 <pull/613>`)
   * Miscellaneous documentation updates to reflect the changes above

The SRW App |latestr| citation is as follows and should be used when presenting results based on research conducted with the App:

UFS Development Team. (2023, Oct. 31). Unified Forecast System (UFS) Short-Range Weather (SRW) Application (Version v2.2.0). Zenodo. https://doi.org/10.5281/zenodo.10015544

.. _ug-organization:

User's Guide Organization 
============================

The SRW Application documentation is organized into four sections: (1) *Background Information*; (2) *Building, Running, and Testing the SRW App*; (3) *Customizing the Workflow*; and (4) *Reference*.

Background Information
-------------------------

   * This **Introduction** section explains how the SRW App documentation is organized, how to use this guide, and where to find user support and component documentation. 
   * :numref:`Section %s: Technical Overview <TechOverview>` provides technical information about the SRW App, including prerequisites and an overview of the code directory structure.
   * :numref:`Section %s: SRW Application Components <Components>` provides a description of the application components, including optional components.

Building, Running, and Testing the SRW App
--------------------------------------------

   * :numref:`Section %s: Quick Start Guide <NCQuickstart>` is an overview of the workflow and gives instructions for its use on :srw-wiki:`Level 1 platforms <Supported-Platforms-and-Compilers>`.
   * :numref:`Section %s: Container-Based Quick Start Guide <QuickstartC>` explains how to run the SRW Application in a container. Containers may be run on a broad range of systems and come with SRW App prerequisites already installed. 
   * :numref:`Section %s: Building the SRW App <BuildSRW>` provides a *detailed* explanation of how to build the SRW App. 
   * :numref:`Section %s: Running the SRW App <RunSRW>` provides a *detailed* explanation of how to run the SRW App after it has been built/compiled. It includes information on standard workflow tasks, additional optional tasks (e.g., METplus verification, plotting), and different techniques for running the workflow. 
   * :numref:`Section %s: Testing the SRW App <WE2E_tests>` explains how to run workflow end-to-end (WE2E) tests to ensure that new developments do not break the current workflow. 
   * :numref:`Section %s: Tutorials <Tutorial>` walks users through different SRW App experiment cases and analysis of results. 
   * :numref:`Section %s: METplus Verification Sample Cases <VXCases>` explains how to run METplus verification as part of the workflow. 
   * :numref:`Section %s: Air Quality Modeling <AQM>` provides information specific to air quality modeling (AQM). This feature is currently unsupported, so documentation may be behind the current state of development, which is progressing rapidly. However, this section is a starting point for those interested in AQM. 

.. hint:: 
   * To get started with the SRW App, it is recommended that users try one of the following options: 

      #. View :numref:`Section %s: Quick Start Guide <NCQuickstart>` for a quick overview of the workflow steps. Especially helpful for users with access to a :srw-wiki:`Level 1 platform <Supported-Platforms-and-Compilers>`.
      #. To build the application in a container, which provides a more uniform work environment, users can refer to :numref:`Section %s: Container-Based Quick Start Guide <QuickstartC>`. 
      #. For detailed instructions on building and running the SRW App, users can refer to :numref:`Section %s: Building the SRW App <BuildSRW>` and :numref:`Section %s: Running the SRW App <RunSRW>`. 

Customizing the Workflow
---------------------------

   * :numref:`Section %s: Workflow Parameters <ConfigWorkflow>` documents all of the user-configurable experiment parameters that can be set in the user configuration file (``config.yaml``). 
   * :numref:`Section %s: Input & Output Files <InputOutputFiles>` describes application input and output files, as well as information on where to get publicly available data. 
   * :numref:`Section %s: Limited Area Model (LAM) Grids <LAMGrids>` describes the SRW App predefined grids, explains how to create a custom user-generated grid, and provides information on using a custom distribution of vertical levels.
   * :numref:`Section %s: Defining an SRW App Workflow <DefineWorkflow>` explains how to build a customized SRW App workflow XML file. 
   * :numref:`Section %s: Template Variables <TemplateVars>` explains how to use template variables. 

Reference Information
-----------------------

   * :numref:`Section %s: Rocoto Introductory Information <RocotoInfo>` provides an introduction to standard Rocoto commands with examples. 
   * :numref:`Section %s: FAQ <FAQ>` answers users' frequently asked questions. 
   * :numref:`Section %s: Glossary <Glossary>` defines important terms related to the SRW App. 

.. _doc-conventions:

SRW App Documentation Conventions
===================================

This guide uses particular conventions to indicate commands and code snippets, file and directory paths, variables, and options. 

.. code-block:: console

   Throughout the guide, this presentation style indicates shell commands, code snippets, etc.

Text rendered as ``AaBbCc123`` typically refers to variables in scripts, names of files, or directories.

Code that includes angle brackets (e.g., ``build_<platform>_<compiler>``) indicates that users should insert options appropriate to their SRW App configuration (e.g., ``build_hera_intel``). 

File or directory paths that begin with ``/path/to/`` should be replaced with the actual path on the user's system. For example, ``/path/to/modulefiles`` might be replaced by ``/Users/Jane.Smith/ufs-srweather-app/modulefiles``. 

.. _component-docs:

Component Documentation
=========================

A list of available component documentation is shown in :numref:`Table %s <list_of_documentation>`. In general, technical documentation will explain how to use a particular component, whereas scientific documentation provides more in-depth information on the science involved in specific component files. 

.. _list_of_documentation:

.. list-table:: Centralized List of Documentation
   :widths: 20 50
   :header-rows: 1

   * - Documentation
     - Location
   * - spack-stack Documentation
     - https://spack-stack.readthedocs.io/en/latest/
   * - HPC-Stack Documentation
     - https://hpc-stack.readthedocs.io/en/latest/
   * - UFS_UTILS Technical Documentation
     - https://noaa-emcufs-utils.readthedocs.io/en/latest
   * - UFS_UTILS Scientific Documentation
     - https://ufs-community.github.io/UFS_UTILS/index.html
   * - UFS Weather Model User's Guide
     - https://ufs-weather-model.readthedocs.io/en/latest
   * - FV3 Technical Documentation
     - https://noaa-emc.github.io/FV3_Dycore_ufs-v2.0.0/html/index.html
   * - FV3 Scientific Documentation
     - https://repository.library.noaa.gov/view/noaa/30725
   * - CCPP Technical Documentation
     - https://ccpp-techdoc.readthedocs.io/en/latest/
   * - CCPP Scientific Documentation
     - https://dtcenter.ucar.edu/GMTB/UFS_SRW_App_v2.2.0/sci_doc/index.html
   * - Stochastic Physics Documentation
     - https://stochastic-physics.readthedocs.io/en/latest/
   * - ESMF manual
     - https://earthsystemmodeling.org/docs/release/latest/ESMF_usrdoc/
   * - Unified Post Processor User's Guide
     - https://upp.readthedocs.io/en/latest/
   * - Unified Post Processor Scientific Documentation
     - https://noaa-emc.github.io/UPP/
   * - Unified Workflow User's Guide
     - https://uwtools.readthedocs.io/en/main/
   * - METplus User's Guide
     - https://metplus.readthedocs.io/en/latest/Users_Guide/index.html
   * - HEMCO User's Guide (a component of the NEXUS AQM system)
     - https://hemco.readthedocs.io/en/stable/

.. _user-support:

User Support and Contributions to Development
================================================

Questions
-----------

The SRW App's `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ forum provides online support for UFS users and developers to post questions and exchange information. When users encounter difficulties running the workflow, this is the place to post. Users can expect an initial response within two business days. 

When posting a question, it is recommended that users provide the following information: 

* The platform or system being used (e.g., Hera, Orion, MacOS, Linux)
* The version of the SRW Application being used (e.g., ``develop``, ``release/public-v2.2.0``). (To determine this, users can run ``git branch``, and the name of the branch with an asterisk ``*`` in front of it is the name of the branch they are working on.) Note that the version of the application being used and the version of the documentation being used should match, or users will run into difficulties. 
* Stage of the application when the issue appeared (i.e., configuration, build/compilation, or name of a workflow task)
* Configuration file contents (e.g., ``config.yaml`` contents)
* Full error message (preferably in text form rather than a screenshot)
* Current shell (e.g., bash, csh) and modules loaded
* Compiler + MPI combination being used

Bug Reports
-------------

If users (especially new users) believe they have identified a bug in the system, it is recommended that they first ask about the problem in :srw-repo:`GitHub Discussions <discussions/categories/q-a>`, since many "bugs" do not require a code change/fix --- instead, the user may be unfamiliar with the system and/or may have misunderstood some component of the system or the instructions, which is causing the problem. Asking for assistance in a :srw-repo:`GitHub Discussion <discussions/categories/q-a>` post can help clarify whether there is a simple adjustment to fix the problem or whether there is a genuine bug in the code. Users are also encouraged to search :srw-repo:`open issues <issues>` to see if their bug has already been identified. If there is a genuine bug, and there is no open issue to address it, users can report the bug by filing a :srw-repo:`GitHub Issue <issues/new/choose>`. 

Feature Requests and Enhancements
-----------------------------------

Users who want to request a feature enhancement or the addition of a new feature can file a `GitHub Issue <https://github.com/ufs-community/ufs-srweather-app/issues/new/choose>`__ and add (or request that a code manager add) the ``EPIC Support Requested`` label. These feature requests will be forwarded to the Earth Prediction Innovation Center (`EPIC <https://epic.noaa.gov/>`__) management team for prioritization and eventual addition to the SRW App. 

Community Contributions
-------------------------

The UFS community is encouraged to contribute to the development efforts of all related
utilities, model code, and infrastructure. As described above, users can post issues in the SRW App to report bugs or to announce upcoming contributions to the code base. 
Contributions to the `ufs-srweather-app <https://github.com/ufs-community/ufs-srweather-app>`__ repository should follow the guidelines contained in the :srw-wiki:`SRW App Contributor's Guide <Contributor's-Guide>`. 
Additionally, users can file issues in component repositories for contributions that directly concern those repositories. For code to be accepted into a component repository, users must follow the code management rules of that component's authoritative repository. These rules are usually outlined in the component's User's Guide (see :numref:`Table %s <list_of_documentation>`) or GitHub wiki for each respective repository (see :numref:`Table %s <top_level_repos>`).

.. _future-direction:

Future Direction
=================

Users can expect to see incremental improvements and additional capabilities in upcoming releases of the SRW Application to enhance research opportunities and support operational forecast implementations. Planned enhancements include:

* Inclusion of data assimilation and forecast restart/cycling capabilities.
* A more extensive set of supported developmental physics suites.
* A larger number of pre-defined domains/resolutions and a *fully supported* capability to create a user-defined domain.
* Incorporation of additional `Unified Workflow <https://github.com/ufs-community/uwtools>`__ tools.


.. bibliography:: ../../references.bib
