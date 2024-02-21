.. _Components:

============================
SRW Application Components
============================

The SRW Application assembles a variety of components, including:

* UFS Utilities
* UFS Weather Model
* Unified Post Processor
* METplus verification suite
* Unified Workflow tools
* Build system and workflow

These components are documented within this User's Guide and supported through the `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ forum. 

.. _Utils:

UFS Preprocessing Utilities (UFS_UTILS)
==========================================

The SRW Application includes a number of pre-processing utilities (UFS_UTILS) that initialize and prepare the model. Since the SRW App provides forecast predictions over a limited area (rather than globally), these utilities generate a regional grid (``regional_esg_grid/make_hgrid``) along with :term:`orography` (``orog``) and surface climatology (``sfc_climo_gen``) files on that grid. Grids include a strip, or "halo," of six cells that surround the regional grid and feed in lateral boundary condition data. Since different grid and orography files require different numbers of :term:`halo` cells, additional utilities handle topography filtering and shave the number of halo points (based on downstream workflow component requirements). The pre-processing software :term:`chgres_cube` is used to convert the raw external model data into initial and lateral boundary condition files in :term:`netCDF` format. These are needed as input to the :term:`FV3` limited area model (:term:`LAM`). Additional information about the UFS pre-processing utilities can be found in the :doc:`UFS_UTILS Technical Documentation <ufs-utils:index>` and in the `UFS_UTILS Scientific Documentation <https://ufs-community.github.io/UFS_UTILS/index.html>`__.

The SRW Application can be initialized from a range of operational initial condition files. It is possible to initialize the model from the Global Forecast System (:term:`GFS`), North American Mesoscale (:term:`NAM`) Forecast System, Rapid Refresh (:term:`RAP`), and High-Resolution Rapid Refresh (:term:`HRRR`) files in Gridded Binary v2 (:term:`GRIB2`) format. GFS files also come in :term:`NEMSIO` format for past dates. 

.. WARNING::
   For GFS data, dates prior to 1 January 2018 may work but are not guaranteed. Public archives of model data can be accessed through the `NOAA Operational Model Archive and Distribution System <https://nomads.ncep.noaa.gov/>`__ (NOMADS). Raw external model data may be pre-staged on disk by the user.


Forecast Model
==============

The prognostic atmospheric model in the UFS SRW Application is the Finite-Volume Cubed-Sphere (:term:`FV3`) dynamical core configured with a Limited Area Model (:term:`LAM`) capability (:cite:t:`BlackEtAl2021`). The :term:`dynamical core` is the computational part of a model that solves the equations of fluid motion. A User's Guide for the UFS :term:`Weather Model` can be accessed :doc:`here <ufs-wm:index>`.

Supported model resolutions in this release include 3-, 13-, and 25-km predefined contiguous U.S. (:term:`CONUS`) domains, each with 127 vertical levels. Preliminary tools for users to define their own domain are also available in the release with full, formal support of these tools to be provided in future releases. The Extended Schmidt Gnomonic (ESG) grid is used with the FV3-LAM, which features relatively uniform grid cells across the entirety of the domain. Additional information about the FV3 dynamical core can be found in the `scientific documentation <https://repository.library.noaa.gov/view/noaa/30725>`__, the `technical documentation <https://noaa-emc.github.io/FV3_Dycore_ufs-v2.0.0/html/index.html>`__, and on the `NOAA Geophysical Fluid Dynamics Laboratory website <https://www.gfdl.noaa.gov/fv3/>`__.

Model Physics
---------------

The Common Community Physics Package (CCPP), described `here <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`__, supports interoperable atmospheric physics and land surface model options. Atmospheric physics are a set of numerical methods describing small-scale processes such as clouds, turbulence, radiation, and their interactions. The most recent SRW App release (|latestr|) included five supported physics suites: FV3_RRFS_v1beta, FV3_GFS_v16, FV3_WoFS_v0, FV3_HRRR, and FV3_RAP. The FV3_RRFS_v1beta physics suite is being tested for use in the future operational implementation of the Rapid Refresh Forecast System (:term:`RRFS`) planned for 2023-2024, and the FV3_GFS_v16 is an updated version of the physics suite used in the operational Global Forecast System (GFS) v16. A detailed list of CCPP updates since the SRW App v2.1.0 release is available :ref:`here <CCPPUpdates>`. A full scientific description of CCPP parameterizations and suites can be found in the `CCPP Scientific Documentation <https://dtcenter.ucar.edu/GMTB/UFS_SRW_App_v2.2.0/sci_doc/index.html>`__, and CCPP technical aspects are described in the :doc:`CCPP Technical Documentation <ccpp-techdoc:index>`. The model namelist has many settings beyond the physics options that can optimize various aspects of the model for use with each of the supported suites. Additional information on Stochastic Physics options is available :doc:`here <stochphys:index>`. 

.. note::
   SPP is currently only available for specific physics schemes used in the RAP/HRRR physics suite. Users need to be aware of which physics suite definition file (:term:`SDF`) is chosen when turning this option on. Among the supported physics suites, the full set of parameterizations can only be used with the ``FV3_HRRR`` option for ``CCPP_PHYS_SUITE``.

Additionally, a CCPP single-column model (`CCPP-SCM <https://github.com/NCAR/ccpp-scm>`__) option has also been developed as a child repository. Users can refer to the `CCPP Single Column Model User and Technical Guide <https://github.com/NCAR/ccpp-scm/blob/main/scm/doc/TechGuide/main.pdf>`__ for more details. This CCPP-SCM user guide contains a Quick Start Guide with instructions for obtaining the code, compiling, and running test cases, which include five standard test cases and two additional FV3 replay cases (refer to section 5.2 in the CCPP-SCM user guide for more details). Moreover, the CCPP-SCM supports a precompiled version in a docker container, allowing it to be easily executed on NOAA's cloud computing platforms without any issues (see section 2.5 in the CCPP-SCM user guide for more details).

The SRW App supports the use of both :term:`GRIB2` and :term:`NEMSIO` input data. The UFS Weather Model ingests initial and lateral boundary condition files produced by :term:`chgres_cube` and outputs files in netCDF format on a specific projection (e.g., Lambert Conformal) in the horizontal direction and model levels in the vertical direction.

Unified Post Processor (UPP)
==============================

The Unified Post Processor (:term:`UPP`) processes raw output from a variety of numerical weather prediction (:term:`NWP`) models. In the SRW App, the UPP converts model output data from the model's native :term:`netCDF` format to :term:`GRIB2` format on standard isobaric vertical coordinates. The UPP can also be used to compute a variety of useful diagnostic fields, as described in the :doc:`UPP User's Guide <upp:index>`. Output from UPP can be used with visualization, plotting, and verification packages or in further downstream post-processing (e.g., statistical post-processing techniques).

.. _MetplusComponent:

METplus Verification Suite
=============================

The Model Evaluation Tools (MET) package is a set of statistical verification tools developed by the `Developmental Testbed Center <https://dtcenter.org/>`__ (DTC) for use by the :term:`NWP` community to help them assess and evaluate the performance of numerical weather predictions. MET is the core component of the enhanced `METplus <https://dtcenter.org/community-code/metplus>`__ verification framework; the suite also includes the associated database and display systems called METviewer and METexpress. 

The METplus verification framework has been integrated into the SRW App to facilitate forecast evaluation. METplus is a verification framework that spans a wide range of temporal scales (warn-on-forecast to climate) and spatial scales (storm to global). It is supported by the `Developmental Testbed Center (DTC) <https://dtcenter.org/>`__. 

METplus comes preinstalled with :term:`spack-stack` but can also be installed on other systems individually or as part of :term:`HPC-Stack` installation. Users on systems without a previous installation of METplus can follow the :ref:`MET Installation Guide <met:installation>` and :ref:`METplus Installation Guide <metplus:install>` for individual installation. Currently, METplus *installation* is only supported as part of spack-stack installation; users attempting to install METplus individually or as part of HPC-Stack will need to direct assistance requests to the METplus team. However, METplus *use* is supported on any system with a functioning METplus installation.

The core components of the METplus framework include the statistical driver (MET), the associated database and display systems known as METviewer and METexpress, and a suite of Python wrappers to provide low-level automation and examples, also called use cases. MET is a set of verification tools developed for use by the :term:`NWP` community. It matches up gridded forecast fields with either gridded analyses or point observations and applies configurable methods to compute statistics and diagnostics. Extensive documentation is available in the :doc:`METplus User's Guide <metplus:index>` and :doc:`MET User's Guide <met:index>`. Documentation for all other components of the framework can be found at the *Documentation* link for each component on the METplus `downloads <https://dtcenter.org/community-code/metplus/download>`__ page.

Among other techniques, MET provides the capability to compute standard verification scores for comparing deterministic gridded model data to point-based and gridded observations. It also provides ensemble and probabilistic verification methods for comparing gridded model data to point-based or gridded observations. Verification tasks to accomplish these comparisons are defined in the SRW App in :numref:`Table %s <VXWorkflowTasksTable>`. Currently, the SRW App supports the use of :term:`NDAS` observation files (which include conventional point-based surface and upper-air data) `in prepBUFR format <https://nomads.ncep.noaa.gov/pub/data/nccf/com/nam/prod/>`__ for point-based verification. It also supports gridded Climatology-Calibrated Precipitation Analysis (:term:`CCPA`) data for accumulated precipitation evaluation and Multi-Radar/Multi-Sensor (:term:`MRMS`) gridded analysis data for composite reflectivity and :term:`echo top` verification.

METplus is being actively developed by :term:`NCAR`/Research Applications Laboratory (RAL), NOAA/Earth Systems Research Laboratories (`ESRL <https://www.esrl.noaa.gov/>`__), and NOAA/Environmental Modeling Center (:term:`EMC`), and it is open to community contributions. More details about METplus can be found on the `METplus website <https://dtcenter.org/community-code/metplus>`__.

Air Quality Modeling (AQM) Utilities
=======================================

AQM Utilities (AQM-utils) include the utility executables and python scripts to run SRW-AQM (Online-:term:`CMAQ`).
For more information on AQM-utils, visit the GitHub repository at https://github.com/NOAA-EMC/AQM-utils. 

.. _nexus:

NOAA Emission and eXchange Unified System (NEXUS)
===================================================

The NOAA Emission and eXchange Unified System (NEXUS) is an emissions processing system developed at the NOAA Air Resources Laboratory (ARL) for use with regional and global UFS atmospheric composition models. NEXUS provides a streamlined process to include new emissions inventories quickly and can flexibly blend different emissions datasets. NEXUS incorporates the :term:`ESMF`-compliant Harmonized Emissions Component (`HEMCO <https://github.com/geoschem/HEMCO/tree/main>`__), which "comput[es] emissions from a user-selected ensemble of emission inventories and algorithms" and "allows users to re-grid, combine, overwrite, subset, and scale emissions from different inventories through a configuration file and with no change to the model source code" (:cite:t:`LinEtAl2021`). 

For more information on NEXUS, visit the GitHub repository at https://github.com/noaa-oar-arl/NEXUS. 

.. _uwtools:

Unified Workflow Tools
========================

The Unified Workflow (UW) is a set of tools intended to unify the workflow for various UFS applications under one framework. The UW toolkit currently includes templater and configuration (config) tools, which have been incorporated into the SRW App workflow and will soon be incorporated into other UFS repositories. Additional tools are under development. More details about UW tools can be found in the `uwtools <https://github.com/ufs-community/uwtools>`__ GitHub repository and in the :uw:`UW Documentation <>`.

Build System and Workflow
=========================

The SRW Application has a portable, CMake-based build system that packages together all the components required to build the SRW Application. This build system collects the components necessary for running the end-to-end SRW Application, including the UFS Weather Model and the pre- and post-processing software. Additional libraries necessary for the application (e.g., :term:`NCEPLIBS-external` and :term:`NCEPLIBS`) are not included in the SRW Application build system but are available pre-built on pre-configured platforms. On other systems, they can be installed via spack-stack (see :doc:`spack-stack Documentation <spack-stack:index>`). There is a small set of :ref:`prerequisite system libraries <software-prereqs>` and utilities that are assumed to be present on the target computer: the CMake build software; a Fortran, C, and C++ compiler; and an :term:`MPI` library.

Once built, users can generate a Rocoto-based workflow that will run each task in the proper sequence (see :numref:`Chapter %s <RocotoInfo>` or the `Rocoto documentation <https://github.com/christopherwharrop/rocoto/wiki/Documentation>`__ for more information on Rocoto and workflow management). If Rocoto and/or a batch system is not present on the available platform, the individual components can be run in a stand-alone, command line fashion with provided run scripts. 

The SRW Application allows users to configure various elements of the workflow. For example, users can modify the parameters of the atmospheric model, such as start and end dates, duration, integration time step, and the physics suite used for the simulation. It also allows for configuration of other elements of the workflow; for example, users can choose whether to run some or all of the pre-processing, forecast model, and post-processing steps. More information on how to configure the workflow is available in :numref:`Section %s <UserSpecificConfig>`.

An optional Python plotting task can also be included in the workflow to create basic visualizations of the model output. The task outputs graphics in PNG format for several standard meteorological variables on the pre-defined :term:`CONUS` domain. A difference plotting option is also included to visually compare two runs for the same domain and resolution. These plots may be used to perform a visual check to verify that the application is producing reasonable results. Configuration instructions are provided in :numref:`Section %s <PlotOutput>`.

The SRW Application has been tested on a variety of platforms widely used by researchers, including NOAA High-Performance Computing (HPC) systems (e.g., Hera, Jet); the National Center for Atmospheric Research (:term:`NCAR`) Derecho system; cloud environments; and generic Linux and MacOS systems using Intel and GNU compilers. Four :srw-wiki:`levels of support <Supported-Platforms-and-Compilers>` have been defined for the SRW Application, including pre-configured (Level 1), configurable (Level 2), limited-test (Level 3), and build-only (Level 4) platforms. 

Preconfigured (Level 1) systems already have the required external libraries available in a central location (via :term:`spack-stack` or :term:`HPC-Stack`). The SRW Application is expected to build and run out-of-the-box on these systems, and users can :ref:`download the SRW App code <DownloadSRWApp>` without first installing prerequisites.

Configurable platforms (Level 2) are platforms where all of the required libraries for building the SRW Application are expected to install successfully but are not available in a central location. Users will need to install the required libraries as part of the :ref:`SRW Application build <BuildSRW>` process. Applications and models are expected to build and run once the required libraries are built. Release testing is conducted on these systems to ensure that the SRW App runs smoothly there. 

Limited-Test (Level 3) and Build-Only (Level 4) computational platforms are those in which the developers have built the code but little or no pre-release testing has been conducted, respectively. Users may need to perform additional troubleshooting on Level 3 or 4 systems since little or no pre-release testing has been conducted on these systems. 

On all platforms, the SRW App can be :ref:`run within a container <QuickstartC>` that includes the prerequisite software.

A complete description of the levels of support, along with a list of preconfigured and configurable platforms can be found in the :srw-wiki:`SRW Application Wiki <Supported-Platforms-and-Compilers>`.

