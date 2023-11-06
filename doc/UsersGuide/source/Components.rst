.. _Components:

============================
SRW Application Components
============================

The SRW Application assembles a variety of components, including:

* Pre-processor Utilities & Initial Conditions
* UFS Weather Forecast Model
* Unified Post Processor
* Visualization Examples
* Build System and Workflow

These components are documented within this User's Guide and supported through the `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions>`__ forum. 

.. _Utils:

Pre-processor Utilities and Initial Conditions
==============================================

The SRW Application includes a number of pre-processing utilities that initialize and prepare the model. Since the SRW App provides forecast predictions over a limited area (rather than globally), it is necessary to first generate a regional grid (``regional_esg_grid/make_hgrid``) along with :term:`orography` (``orog``) and surface climatology (``sfc_climo_gen``) files on that grid. Grids include a strip, or "halo," of six cells that surround the regional grid and feed in lateral boundary condition data. Since different grid and orography files require different numbers of :term:`halo` cells, additional utilities handle topography filtering and shave the number of halo points (based on downstream workflow component requirements). The pre-processing software :term:`chgres_cube` is used to convert the raw external model data into initial and lateral boundary condition files in :term:`netCDF` format. These are needed as input to the :term:`FV3`-:term:`LAM`. Additional information about the UFS pre-processor utilities can be found in the `UFS_UTILS Technical Documentation <https://noaa-emcufs-utils.readthedocs.io/en/latest>`__ and in the `UFS_UTILS Scientific Documentation <https://ufs-community.github.io/UFS_UTILS/index.html>`__.

The SRW Application can be initialized from a range of operational initial condition files. It is possible to initialize the model from the Global Forecast System (:term:`GFS`), North American Mesoscale (:term:`NAM`) Forecast System, Rapid Refresh (:term:`RAP`), and High-Resolution Rapid Refresh (:term:`HRRR`) files in Gridded Binary v2 (:term:`GRIB2`) format. GFS files also come in :term:`NEMSIO` format for past dates. 

.. WARNING::
   For GFS data, dates prior to 1 January 2018 may work but are not guaranteed. Public archives of model data can be accessed through the `NOAA Operational Model Archive and Distribution System <https://nomads.ncep.noaa.gov/>`__ (NOMADS). Raw external model data may be pre-staged on disk by the user.


Forecast Model
==============

The prognostic atmospheric model in the UFS SRW Application is the Finite-Volume Cubed-Sphere (:term:`FV3`) dynamical core configured with a Limited Area Model (:term:`LAM`) capability :cite:`BlackEtAl2021`. The :term:`dynamical core` is the computational part of a model that solves the equations of fluid motion. A User's Guide for the UFS Weather Model can be accessed `here <https://ufs-weather-model.readthedocs.io/en/latest/>`__.

Supported model resolutions in this release include 3-, 13-, and 25-km predefined contiguous U.S. (:term:`CONUS`) domains, each with 127 vertical levels. Preliminary tools for users to define their own domain are also available in the release with full, formal support of these tools to be provided in future releases. The Extended Schmidt Gnomonic (ESG) grid is used with the FV3-LAM, which features relatively uniform grid cells across the entirety of the domain. Additional information about the FV3 dynamical core can be found in the `scientific documentation <https://repository.library.noaa.gov/view/noaa/30725>`__, the `technical documentation <https://noaa-emc.github.io/FV3_Dycore_ufs-v2.0.0/html/index.html>`__, and on the `NOAA Geophysical Fluid Dynamics Laboratory website <https://www.gfdl.noaa.gov/fv3/>`__.

Interoperable atmospheric physics, along with various land surface model options, are supported through the Common Community Physics Package (CCPP), described `here <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`__. Atmospheric physics are a set of numerical methods describing small-scale processes such as clouds, turbulence, radiation, and their interactions. There are four physics suites supported as of the SRW App v2.1.0 release. The first is the FV3_RRFS_v1beta physics suite, which is being tested for use in the future operational implementation of the Rapid Refresh Forecast System (:term:`RRFS`) planned for 2023-2024, and the second is an updated version of the physics suite used in the operational Global Forecast System (GFS) v16. Additionally, FV3_WoFS_v0 and FV3_HRRR are supported. A detailed list of CCPP updates since the SRW App v2.0.0 release is available :ref:`here <CCPPUpdates>`. A full scientific description of CCPP parameterizations and suites can be found in the `CCPP Scientific Documentation <https://dtcenter.ucar.edu/GMTB/v6.0.0/sci_doc/index.html>`__, and CCPP technical aspects are described in the `CCPP Technical Documentation <https://ccpp-techdoc.readthedocs.io/en/latest/>`__. The model namelist has many settings beyond the physics options that can optimize various aspects of the model for use with each of the supported suites. Additional information on Stochastic Physics options is available `here <https://stochastic-physics.readthedocs.io/en/latest/>`__.

.. note::
   SPP is currently only available for specific physics schemes used in the RAP/HRRR physics suite. Users need to be aware of which physics suite definition file (:term:`SDF`) is chosen when turning this option on. Among the supported physics suites, the full set of parameterizations can only be used with the ``FV3_HRRR`` option for ``CCPP_PHYS_SUITE``.

The SRW App supports the use of both :term:`GRIB2` and :term:`NEMSIO` input data. The UFS Weather Model ingests initial and lateral boundary condition files produced by :term:`chgres_cube` and outputs files in netCDF format on a specific projection (e.g., Lambert Conformal) in the horizontal direction and model levels in the vertical direction.

Post Processor
==============

The SRW Application is distributed with the Unified Post Processor (:term:`UPP`) included in the workflow as a way to convert the netCDF output on the native model grid to :term:`GRIB2` format on standard isobaric vertical coordinates. The UPP can also be used to compute a variety of useful diagnostic fields, as described in the `UPP User's Guide <https://upp.readthedocs.io/en/latest/>`__.

Output from UPP can be used with visualization, plotting, and verification packages or in further downstream post-processing (e.g., statistical post-processing techniques).

.. _MetplusComponent:

METplus Verification Suite
=============================

The enhanced Model Evaluation Tools (`METplus <https://dtcenter.org/community-code/metplus>`__) verification system has been integrated into the SRW App to facilitate forecast evaluation. METplus is a verification framework that spans a wide range of temporal scales (warn-on-forecast to climate) and spatial scales (storm to global). It is supported by the `Developmental Testbed Center (DTC) <https://dtcenter.org/>`__. 

METplus *installation* is not included as part of the build process for the most recent release of the SRW App. However, METplus is preinstalled on many `Level 1 & 2 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems; existing builds can be viewed `here <https://dtcenter.org/community-code/metplus/metplus-4-1-existing-builds>`__. 

METplus can be installed on other systems individually or as part of :term:`HPC-Stack` installation. Users on systems without a previous installation of METplus can follow the `MET Installation Guide <https://met.readthedocs.io/en/main_v10.1/Users_Guide/installation.html>`__ and `METplus Installation Guide <https://metplus.readthedocs.io/en/main_v4.1/Users_Guide/installation.html>`__ for individual installation. Currently, METplus *installation* is not a supported feature for this release of the SRW App. However, METplus *use* is supported on systems with a functioning METplus installation.

The core components of the METplus framework include the statistical driver, MET, the associated database and display systems known as METviewer and METexpress, and a suite of Python wrappers to provide low-level automation and examples, also called use cases. MET is a set of verification tools developed for use by the :term:`NWP` community. It matches up grids with either gridded analyses or point observations and applies configurable methods to compute statistics and diagnostics. Extensive documentation is available in the `METplus User's Guide <https://metplus.readthedocs.io/en/main_v4.1/Users_Guide/index.html>`__ and `MET User's Guide <https://met.readthedocs.io/en/main_v10.1/index.html>`__. Documentation for all other components of the framework can be found at the Documentation link for each component on the METplus `downloads <https://dtcenter.org/community-code/metplus/download>`__ page.

Among other techniques, MET provides the capability to compute standard verification scores for comparing deterministic gridded model data to point-based and gridded observations. It also provides ensemble and probabilistic verification methods for comparing gridded model data to point-based or gridded observations. Verification tasks to accomplish these comparisons are defined in the SRW App in :numref:`Table %s <VXWorkflowTasksTable>`. Currently, the SRW App supports the use of :term:`NDAS` observation files (which include conventional point-based surface and upper-air data) in `prepBUFR format <https://nomads.ncep.noaa.gov/pub/data/nccf/com/nam/prod/>`__ for point-based verification. It also supports gridded Climatology-Calibrated Precipitation Analysis (:term:`CCPA`) data for accumulated precipitation evaluation and Multi-Radar/Multi-Sensor (:term:`MRMS`) gridded analysis data for composite reflectivity and :term:`echo top` verification. 

METplus is being actively developed by :term:`NCAR`/Research Applications Laboratory (RAL), NOAA/Earth Systems Research Laboratories (ESRL), and NOAA/Environmental Modeling Center (:term:`EMC`), and it is open to community contributions.

Build System and Workflow
=========================

The SRW Application has a portable build system and a user-friendly, modular, and expandable workflow framework.

An umbrella CMake-based build system is used for building the components necessary for running the end-to-end SRW Application, including the UFS Weather Model and the pre- and post-processing software. Additional libraries necessary for the application (e.g., :term:`NCEPLIBS-external` and :term:`NCEPLIBS`) are not included in the SRW Application build system but are available pre-built on pre-configured platforms. On other systems, they can be installed via the HPC-Stack (see :doc:`HPC-Stack Documentation <hpc-stack:index>`). There is a small set of system libraries and utilities that are assumed to be present on the target computer: the CMake build software; a Fortran, C, and C++ compiler; and an :term:`MPI` library.

Once built, the provided experiment generator script can be used to create a Rocoto-based
workflow file that will run each task in the system in the proper sequence (see :numref:`Chapter %s <RocotoInfo>` or the `Rocoto documentation <https://github.com/christopherwharrop/rocoto/wiki/Documentation>`__ for more information on Rocoto). If Rocoto and/or a batch system is not present on the available platform, the individual components can be run in a stand-alone, command line fashion with provided run scripts. The generated namelist for the atmospheric model can be modified in order to vary settings such as forecast starting and ending dates, forecast length hours, the :term:`CCPP` physics suite, integration time step, history file output frequency, and more. It also allows for configuration of other elements of the workflow; for example, users can choose whether to run some or all of the pre-processing, forecast model, and post-processing steps. 

An optional Python plotting task is also included to create basic visualizations of the model output. The task outputs graphics in PNG format for several standard meteorological variables on the pre-defined :term:`CONUS` domain. A difference plotting option is also included to visually compare two runs for the same domain and resolution. These plots may be used to perform a visual check to verify that the application is producing reasonable results. Configuration instructions are provided in :numref:`Section %s <PlotOutput>`. 

The latest SRW Application release has been tested on a variety of platforms widely used by researchers, such as the NOAA Research and Development High-Performance Computing Systems (RDHPCS), including Hera, Orion, and Jet; the National Center for Atmospheric Research (:term:`NCAR`) Cheyenne system; and generic Linux and MacOS systems using Intel and GNU compilers. Four `levels of support <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ have been defined for the SRW Application, including pre-configured (Level 1), configurable (Level 2), limited-test (Level 3), and build-only (Level 4) platforms. Each level is further described below.

On pre-configured (Level 1) computational platforms, all the required libraries for building the SRW Application are available in a central place. That means bundled libraries (NCEPLIBS) and third-party libraries (NCEPLIBS-external) have both been built. The SRW Application is expected to build and run out-of-the-box on these pre-configured platforms. 

A few additional computational platforms are considered configurable for the SRW Application release. Configurable platforms (Level 2) are platforms where all of the required libraries for building the SRW Application are expected to install successfully but are not available in a central location. Applications and models are expected to build and run once the required bundled libraries (e.g., NCEPLIBS) and third-party libraries (e.g., NCEPLIBS-external) are built.

Limited-Test (Level 3) and Build-Only (Level 4) computational platforms are those in which the developers have built the code but little or no pre-release testing has been conducted, respectively. A complete description of the levels of support, along with a list of preconfigured and configurable platforms can be found in the `SRW Application Wiki <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__.
