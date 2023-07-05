.. _Introduction:

==============
Introduction
==============

The Unified Forecast System (:term:`UFS`) is a community-based, coupled, comprehensive Earth modeling system. NOAA's operational model suite for numerical weather prediction (:term:`NWP`) is quickly transitioning to the UFS from a number of different modeling systems. The UFS enables research, development, and contribution opportunities within the broader :term:`Weather Enterprise` (including government, industry, and academia). For more information about the UFS, visit the `UFS Portal <https://ufscommunity.org/>`__.

The UFS includes `multiple applications <https://ufscommunity.org/science/aboutapps/>`__ that support different forecast durations and spatial domains. This documentation describes the UFS Short-Range Weather (SRW) Application, which targets predictions of atmospheric behavior on a limited spatial domain and on time scales from minutes to several days. The most recent SRW Application includes a prognostic atmospheric model, pre- and post-processing, and a community workflow for running the system end-to-end. These components are documented within this User's Guide and supported through the `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ forum. The SRW App also includes support for a verification package (METplus) for both deterministic and ensemble simulations and support for four stochastically perturbed physics schemes. 

Since the v2.1.0 release, developers have added a variety of features:

   * Bug fixes since the v2.1.0 release
   * Rapid Refresh Forecast System (RRFS) capabilities
   * Air Quality Modeling (AQM) capabilities
   * Updates to :term:`CCPP` that target the top of the ``main`` branch (which is ahead of CCPP v6.0.0). See :ref:`this page <CCPPUpdates>` for a detailed summary of updates that came in ahead of the v2.1.0 release.
   * Support for the :term:`UPP` inline post option (see :ref:`here <InlinePost>`)
   * Documentation updates to reflect the changes above

The SRW App v2.1.0 citation is as follows and should be used when presenting results based on research conducted with the App:

UFS Development Team. (2022, Nov. 17). Unified Forecast System (UFS) Short-Range Weather (SRW) Application (Version v2.1.0). Zenodo. https://doi.org/10.5281/zenodo.7277602

Organization of SRW App Documentation
========================================

The SRW Application documentation is organized into four sections: *Background Information*; *Building, Running, and Testing the SRW App*; *Technical Information*; and *Reference*. 

.. hint:: 
   * To get started with the SRW App, users can try one of the following options: 

      #. View :numref:`Chapter %s <NCQuickstart>` for a quick overview of the workflow steps. 
      #. To build the application in a container, which provides a more uniform work environment, users can refer to the :ref:`Container-Based Quick Start Guide <QuickstartC>`. 
      #. For detailed instructions on building and running the SRW App, users can refer to :numref:`Chapter %s: Building the SRW App <BuildSRW>` and :numref:`Chapter %s: Running the SRW App <RunSRW>`. 

Background Information
------------------------

   * This **Introduction** chapter explains how the SRW App documentation is organized, how to use this guide, and where to find user support/documentation. 
   * :numref:`Chapter %s: Technical Overview <TechOverview>` provides a technical overview, including SRW App prerequisites, code overview/directory structure, and summary of components.
   * :numref:`Chapter %s: Components <Components>` provides a more detailed description of the application components, including optional application components.

Building, Running, and Testing the SRW App
--------------------------------------------

   * :numref:`Chapter %s: Quick Start Guide <NCQuickstart>` is designed for use on `Level 1 systems <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ or as an overview of the workflow.
   * :numref:`Chapter %s: Container-Based Quick Start Guide <QuickstartC>` explains how to run the SRW Application in a container. Containers come with SRW App prerequisites already installed and run on a broad range of systems. 
   * :numref:`Chapter %s: Building the SRW App <BuildSRW>` provides a *detailed* explanation of how to build the SRW App. 
   * :numref:`Chapter %s: Running the SRW App <RunSRW>` provides a *detailed* explanation of how to run the App after it has been built. It includes information on standard workflow tasks, additional optional tasks (e.g., METplus verification, plotting), and different techniques for running the workflow. 
   * :numref:`Chapter %s: Tutorials <Tutorial>` walks users through different SRW App experiment cases and analysis of results. 
   * :numref:`Chapter %s: <WE2E_tests>` explains how to run workflow end-to-end tests to ensure that new developments do not break the current workflow. 
   * :numref:`Chapter %s: <VXCases>` explains how to run METplus verification as part of the workflow. 
   * :numref:`Chapter %s: Air Quality Modeling <AQM>` provides information specific to air quality modeling (AQM). This feature is currently unsupported, so documentation may be behind the current state of development, which is progressing rapidly. However, this chapter is a starting point for those interested in AQM. 

Technical Information for Users
---------------------------------

   * :numref:`Chapter %s: <ConfigWorkflow>` documents all of the user-configurable experiment parameters that can be set in ``config.yaml``.  
   * :numref:`Chapter %s: <InputOutputFiles>` provides information on application input and output files, as well as information on where to get publicly available data. 
   * :numref:`Chapter %s: <LAMGrids>` describes the SRW App predefined grids in detail and explains how to create a custom user-generated grid. 
   * :numref:`Chapter %s: <DefineWorkflow>` explains how to build or alter the SRW App workflow XML file. 
   * :numref:`Chapter %s: <TemplateVars>` explains how to use template variables. 

Reference Information
-----------------------

   * :numref:`Chapter %s: Rocoto Introductory Information <RocotoInfo>` provides an introduction to standard Rocoto commands with examples. 
   * :numref:`Chapter %s: FAQ <FAQ>` answers users' frequently asked questions. 
   * :numref:`Chapter %s: Glossary <Glossary>` defines important terms related to the SRW App. 


How to Use This Document
========================

This guide instructs both novice and experienced users on downloading, building, and running the SRW Application. Please post questions in the `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions>`__ forum.

.. code-block:: console

   Throughout the guide, this presentation style indicates shell commands and options, code examples, etc.

Variables presented as ``AaBbCc123`` in this User's Guide typically refer to variables in scripts, names of files, or directories.

File paths and code that include angle brackets (e.g., ``build_<platform>_<compiler>``) indicate that users should insert options appropriate to their SRW App configuration (e.g., ``build_orion_intel``). 

User Support, Documentation, and Contributions to Development
===============================================================

The SRW App's `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ forum provides online support for UFS users and developers to post questions and exchange information.

A list of available documentation is shown in :numref:`Table %s <list_of_documentation>`.

.. _list_of_documentation:

.. table::  Centralized list of documentation

   +----------------------------+---------------------------------------------------------------------------------+
   | **Documentation**          | **Location**                                                                    |
   +============================+=================================================================================+
   | UFS SRW Application        | https://ufs-srweather-app.readthedocs.io/en/develop/                            |
   | User's Guide               |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | UFS_UTILS Technical        | https://noaa-emcufs-utils.readthedocs.io/en/latest                              |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | UFS_UTILS Scientific       | https://ufs-community.github.io/UFS_UTILS/index.html                            |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | UFS Weather Model          | https://ufs-weather-model.readthedocs.io/en/latest                              |
   | User's Guide               |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | HPC-Stack Documentation    | https://hpc-stack.readthedocs.io/en/latest/                                     |
   +----------------------------+---------------------------------------------------------------------------------+
   | FV3 Scientific             | https://repository.library.noaa.gov/view/noaa/30725                             |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | FV3 Technical              | https://noaa-emc.github.io/FV3_Dycore_ufs-v2.0.0/html/index.html                |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | CCPP Scientific            | https://dtcenter.ucar.edu/GMTB/v6.0.0/sci_doc/index.html                        |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | CCPP Technical             | https://ccpp-techdoc.readthedocs.io/en/latest/                                  |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | Stochastic Physics         | https://stochastic-physics.readthedocs.io/en/latest/                            |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | ESMF manual                | https://earthsystemmodeling.org/docs/release/latest/ESMF_usrdoc/                |
   +----------------------------+---------------------------------------------------------------------------------+
   | Unified Post Processor     | https://upp.readthedocs.io/en/latest/                                           |
   +----------------------------+---------------------------------------------------------------------------------+

The UFS community is encouraged to contribute to the development effort of all related
utilities, model code, and infrastructure. Users can post issues in the related GitHub repositories to report bugs or to announce upcoming contributions to the code base. For code to be accepted into the authoritative repositories, users must follow the code management rules of each UFS component repository. These rules are usually outlined in the User's Guide (see :numref:`Table %s <list_of_documentation>`) or wiki for each respective repository (see :numref:`Table %s <top_level_repos>`). Contributions to the `ufs-srweather-app <https://github.com/ufs-community/ufs-srweather-app>`__ repository should follow the guidelines contained in the `SRW App Contributor's Guide <https://github.com/ufs-community/ufs-srweather-app/wiki/Contributor's-Guide>`__.

Future Direction
=================

Users can expect to see incremental improvements and additional capabilities in upcoming releases of the SRW Application to enhance research opportunities and support operational forecast implementations. Planned enhancements include:

* A more extensive set of supported developmental physics suites.
* A larger number of pre-defined domains/resolutions and a *fully supported* capability to create a user-defined domain.
* Add user-defined vertical levels (number and distribution).
* Inclusion of data assimilation and forecast restart/cycling capabilities.


.. bibliography:: references.bib



