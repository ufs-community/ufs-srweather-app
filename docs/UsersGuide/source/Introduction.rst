.. _Introduction:

============
Introduction
============

The Unified Forecast System (:term:`UFS`) is a community-based, coupled, comprehensive Earth modeling system. The UFS is the source system for NOAA’s operational numerical weather prediction applications. It enables research, development, and contribution opportunities within the broader :term:`weather enterprise` (e.g. government, industry, and academia). For more information about the UFS, visit the `UFS Portal <https://ufscommunity.org/>`__.

The UFS can be configured for multiple applications (see the `complete list here <https://ufscommunity.org/science/aboutapps/>`__). The configuration described in this documentation is the UFS Short-Range Weather (SRW) Application, which targets predictions of atmospheric behavior on a limited spatial domain and on time scales from minutes out to several days. The SRW Application v2.0 release includes a prognostic atmospheric model, pre- and post-processing, and a community workflow for running the system end-to-end. These components are documented within this User's Guide and supported through a `community forum <https://forums.ufscommunity.org/>`_. Future work will expand the capabilities of the application to include data assimilation (DA) and a verification package (e.g., METplus). This documentation provides a `Quick Start Guide <Quickstart>` for running the application, in addition to an overview of the `release components <Components>`, a description of the supported capabilities, and details on where to find more information and obtain support.

The SRW App v1.0.0 citation is as follows and should be used when presenting results based on research conducted with the App:

UFS Development Team. (2021, March 4). Unified Forecast System (UFS) Short-Range Weather (SRW) Application (Version v1.0.0). Zenodo. https://doi.org/10.5281/zenodo.4534994

How to Use This Document
========================

This guide instructs both novice and experienced users on downloading, building, and running the SRW Application. Please post questions in the `UFS forum <https://forums.ufscommunity.org/>`__.

.. code-block:: console

   Throughout the guide, this presentation style indicates shell commands and options, 
   code examples, etc.

Variables presented as ``AaBbCc123`` in this document typically refer to variables in scripts, names of files, and directories.

File paths or code that include angle brackets (e.g., ``env/build_<platform>_<compiler>.env``) indicate that users should insert options appropriate to their SRW configuration (e.g., ``env/build_aws_gcc.env``). 


Pre-processor Utilities and Initial Conditions
==============================================

The SRW Application includes a number of pre-processing utilities that initialize and prepare the
model. Tasks include generating a regional grid along with :term:`orography` and surface climatology files for that grid. The pre-processing software converts the raw external model data into initial and lateral boundary condition files in netCDF format. Later, this is used as input to the atmospheric model (FV3-LAM). Additional information about the UFS pre-processor utilities can be found in the `UFS_UTILS User’s Guide <https://noaa-emcufs-utils.readthedocs.io/en/ufs-v2.0.0/>`_.


Forecast Model
==============

Atmospheric Model
--------------------

The prognostic atmospheric model in the UFS SRW Application is the Finite-Volume Cubed-Sphere
(:term:`FV3`) dynamical core configured with a Limited Area Model (LAM) capability :cite:t:`BlackEtAl2020`.
The dynamical core is the computational part of a model that solves the equations of fluid motion. A User’s Guide for the UFS :term:`Weather Model` can be found `here <https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/>`__. 

Common Community Physics Package
---------------------------------

The `Common Community Physics Package <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`_ (:term:`CCPP`) supports interoperable atmospheric physics and Noah Multi-parameterization (Noah MP) Land Surface Model options. Atmospheric physics are a set of numerical methods describing small-scale processes such as clouds, turbulence, radiation, and their interactions.The SRW release includes an experimental physics version and an updated operational version. 

Data Format
--------------

The SRW App supports the use of both :term:`GRIB2` and :term:`NEMSIO` input data. The UFS Weather Model
ingests initial and lateral boundary condition files produced by :term:`chgres_cube`. 


Post-processor
==============

The `Unified Post Processor <https://dtcenter.org/community-code/unified-post-processor-upp>`__ (:term:`UPP`) is included in the SRW Application workflow. The UPP is designed to generate useful products from raw model output. In the SRW, it converts data output formats from netCDF format on the native model grid to GRIB2 format. The UPP can also be used to compute a variety of useful diagnostic fields, as described in the `UPP User’s Guide <https://upp.readthedocs.io/en/upp-v9.0.0/>`_. Output from UPP can be used with visualization, plotting, and verification packages, or for further downstream post-processing (e.g., statistical post-processing techniques).


Visualization Example
=====================

This SRW Application provides Python scripts to create basic visualizations of the model output. Usage information and instructions are described in :numref:`Chapter %s <Graphics>` and are also included at the top of the script. 

Build System and Workflow
=========================

The SRW Application has a portable CMake-based build system that packages together all the components required to build the SRW Application. Once built, users can generate a Rocoto-based workflow that will run each task in the proper sequence (see `Rocoto documentation <https://github.com/christopherwharrop/rocoto/wiki/Documentation>`__ for more on workflow management). Individual components can also be run in a stand-alone, command line fashion. 

The SRW Application allows for configuration of various elements of the workflow. For example, users can modify the parameters of the atmospheric model, such as start and end dates, duration, time step, and the physics suite for the forecast. 

This SRW Application release has been tested on a variety of platforms widely used by researchers, including NOAA High-Performance Comuting (HPC) systems (e.g. Hera, Orion), cloud environments, and generic Linux and macOS systems. Four `levels of support <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_ have been defined for the SRW Application, including pre-configured (Level 1), configurable (Level 2), limited test platforms (Level 3), and build-only platforms (Level 4). Preconfigured (Level 1) systems already have the required external libraries (e.g., NCEPLIBS) available in a central location. The SRW Application is expected to build and run out-of-the-box on these systems, and users can proceed directly to using the workflow to generate an experiment, as described in the Quick Start Guide (:numref:`Section %s Generate the Forecast Experiment <GenerateForecast>`). On other platforms, the required libraries will need to be installed via the HPC_Stack (see :numref:`Section %s Installing the HPC-Stack <HPCstackInfo>`). Once these libraries are built, applications and models should build and run successfully. However, users may need to perform additional troubleshooting on Level 3 or 4 systems since little or no pre-release testing has been conducted on these systems. 

User Support, Documentation, and Contributing Development
=========================================================

A forum-based, online `support system <https://forums.ufscommunity.org>`_ organized by topic provides a centralized location for UFS users and developers to post questions and exchange information. 

A list of available documentation is shown in :numref:`Table %s <list_of_documentation>`.

.. _list_of_documentation:

.. table::  Centralized List of Documentation

   +----------------------------+---------------------------------------------------------------------------------+
   | **Documentation**          | **Location**                                                                    |
   +============================+=================================================================================+
   | UFS SRW Application v1.0   |  https://ufs-srweather-app.readthedocs.io/en/ufs-v1.0.0                         |
   | User's Guide               |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | UFS_UTILS v2.0 User's      | https://noaa-emcufs-utils.readthedocs.io/en/ufs-v2.0.0/                         |
   | Guide                      |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | UFS Weather Model v2.0     | https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0                          |
   | User's Guide               |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | NCEPLIBS Documentation     | https://github.com/NOAA-EMC/NCEPLIBS/wiki                                       |
   +----------------------------+---------------------------------------------------------------------------------+
   | NCEPLIBS-external          | https://github.com/NOAA-EMC/NCEPLIBS-external/wiki                              |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | FV3 Documentation          | https://noaa-emc.github.io/FV3_Dycore_ufs-v2.0.0/html/index.html                |
   +----------------------------+---------------------------------------------------------------------------------+
   | CCPP Scientific            | https://dtcenter.ucar.edu/GMTB/v5.0.0/sci_doc/index.html                        |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | CCPP Technical             | https://ccpp-techdoc.readthedocs.io/en/v5.0.0/                                  |
   | Documentation              |                                                                                 |
   +----------------------------+---------------------------------------------------------------------------------+
   | ESMF manual                | http://earthsystemmodeling.org/docs/release/ESMF_8_0_0/ESMF_usrdoc/             |
   +----------------------------+---------------------------------------------------------------------------------+
   | Unified Post Processor     | https://upp.readthedocs.io/en/upp-v9.0.0/                                       |
   +----------------------------+---------------------------------------------------------------------------------+

The UFS community is encouraged to contribute to the development effort of all related
utilities, model code, and infrastructure. Users can post issues in the related GitHub repositories to report bugs or to announce upcoming contributions to the code base. For code to be accepted in the authoritative repositories, users must follow the code management rules of each component (described in the User’s Guides listed in :numref:`Table %s <list_of_documentation>`).

Future Direction
================

Users can expect to see incremental improvements and additional capabilities in upcoming
releases of the SRW Application to enhance research opportunities and support operational
forecast implementations. Planned enhancements include:

* A more extensive set of supported developmental physics suites.
* A larger number of pre-defined domains/resolutions and a fully supported capability to create a user-defined domain.
* Inclusion of data assimilation, cycling, and ensemble capabilities.
* A verification package (e.g., METplus) integrated into the workflow. 
* Inclusion of stochastic perturbation techniques.

In addition to the above list, other improvements will be addressed in future releases.

.. bibliography:: references.bib




