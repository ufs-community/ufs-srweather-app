.. _Components:

===============
SRW Components
===============

The SRW Application v2.0 release assembles a variety of components, including:
* Pre-processor Utilities & Initial Conditions
* Forecast Model
* Post-Processor
* Visualization Example
* Build System and Workflow

These components are documented within this User's Guide and supported through a `community forum <https://forums.ufscommunity.org/>`_. 


Pre-processor Utilities and Initial Conditions
==============================================

The SRW Application includes a number of pre-processing utilities that initialize and prepare the
model. Since the SRW App provides forecast predictions over a limited area (rather than globally), it is necessary to first generate a regional grid ``regional_esg_grid/make_hgrid`` along with orography ``orog`` and surface climatology ``sfc_climo_gen`` files on that grid. Grids include a strip, or "halo," of six cells that surround the regional grid and feed in lateral boundary condition data. Since different grid and orography files require different numbers of halo cells, additional utilities handle the correct number of halo shave points and topography filtering. The pre-processing software ``chgres_cube`` is used to convert the raw external model data into initial and lateral boundary condition files in netCDF format, needed as input to the FV3-LAM. Additional information about the UFS pre-processor utilities can be found in the `UFS_UTILS User’s Guide <https://noaa-emcufs-utils.readthedocs.io/en/ufs-v2.0.0/>`_.

The SRW Application can be initialized from a range of operational initial condition files. It is
possible to initialize the model from the Global Forecast System (:term:`GFS`), North American Mesoscale (:term:`NAM`) Forecast System, Rapid Refresh (:term:`RAP`), and High-Resolution Rapid Refresh (:term:`HRRR`) files in Gridded Binary v2 (:term:`GRIB2`) format. GFS files also come in :term:`NEMSIO` format for past dates. 

.. WARNING::
   For GFS data, dates prior to 1 January 2018 may work but are not guaranteed. Public archives of model data can be accessed through the `National Centers for Environmental Information <https://www.ncdc.noaa.gov/data-access/model-data/model-datasets/global-forcast-system-gfs>`_ (NCEI) or through the `NOAA Operational Model Archive and Distribution System <https://nomads.ncep.noaa.gov/>`_ (NOMADS). Raw external model data may be pre-staged on disk by the user.


Forecast Model
==============

The prognostic atmospheric model in the UFS SRW Application is the Finite-Volume Cubed-Sphere
(:term:`FV3`) dynamical core configured with a Limited Area Model (:term:`LAM`) capability :cite:`BlackEtAl2020`. The dynamical core is the computational part of a model that solves the equations of fluid motion. A User’s Guide for the UFS :term:`Weather Model` is `here <https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/>`__. 

Supported model resolutions in this release include 3-, 13-, and 25-km predefined Contiguous U.S. (:term:`CONUS`) domains, each with 64 vertical levels. Preliminary tools for users to define their own domain are also available in the release with full, formal support of these tools to be provided in future releases. The Extended Schmidt Gnomonic (ESG) grid is used with the FV3-LAM, which features relatively uniform grid cells across the entirety of the domain. Additional information about the FV3 dynamical core can be found `here <https://noaa-emc.github.io/FV3_Dycore_ufs-v2.0.0/html/index.html>`__ and on the `NOAA Geophysical Fluid Dynamics Laboratory website <https://www.gfdl.noaa.gov/fv3/>`_.

Interoperable atmospheric physics, along with the Noah Multi-parameterization (Noah MP) Land Surface Model options, are supported through the Common Community Physics Package (:term:`CCPP`; described `here <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`__).Atmospheric physics are a set of numerical methods describing small-scale processes such as clouds, turbulence, radiation, and their interactions. There are two physics options supported for the release. The first is an experimental physics suite being tested for use in the future operational implementation of the Rapid Refresh Forecast System (RRFS) planned for 2023-2024, and the second is an updated version of the physics suite used in the operational Global Forecast System (GFS) v15. A scientific description of the CCPP parameterizations and suites can be found in the `CCPP Scientific Documentation <https://dtcenter.ucar.edu/GMTB/v5.0.0/sci_doc/index.html>`_, and CCPP technical aspects are described in the `CCPP Technical Documentation <https://ccpp-techdoc.readthedocs.io/en/v5.0.0/>`_. The model namelist has many settings beyond the physics options that can optimize various aspects of the model for use with each
of the supported suites. 

The SRW App supports the use of both :term:`GRIB2` and :term:`NEMSIO` input data. The UFS Weather Model
ingests initial and lateral boundary condition files produced by :term:`chgres_cube` and outputs files in
netCDF format on a specific projection (e.g., Lambert Conformal) in the horizontal direction and model levels in the vertical direction.

Post-processor
==============

The SRW Application is distributed with the Unified Post Processor (:term:`UPP`) included in the
workflow as a way to convert the netCDF output on the native model grid to :term:`GRIB2` format on
standard isobaric vertical coordinates. UPP can also be used to compute a variety of useful
diagnostic fields, as described in the `UPP User’s Guide <https://upp.readthedocs.io/en/upp-v9.0.0/>`_.

Output from UPP can be used with visualization, plotting, and verification packages, or for
further downstream post-processing, e.g. statistical post-processing techniques.

Visualization Example
=====================
A Python script is provided to create basic visualization of the model output. The script
is designed to output graphics in PNG format for 14 standard meteorological variables
when using the pre-defined :term:`CONUS` domain. In addition, a difference plotting script is included
to visually compare two runs for the same domain and resolution. These scripts are provided only
as an example for users familiar with Python and may be used to do a visual check to verify
that the application is producing reasonable results. 

After running ``manage_externals/checkout_externals``, the visualization scripts will be available in the `regional_workflow repository <https://github.com/NOAA-EMC/regional_workflow/tree/release/public-v1/ush/Python>`_ under ush/Python. Usage information and instructions are described in :numref:`Chapter %s <Graphics>` and are also included at the top of the script. 

Build System and Workflow
=========================

The SRW Application has a portable build system and a user-friendly, modular, and
expandable workflow framework.

An umbrella CMake-based build system is used for building the components necessary for running the end-to-end SRW Application: the UFS Weather Model and the pre- and post-processing software. Additional libraries necessary for the application (e.g., :term:`NCEPLIBS-external` and :term:`NCEPLIBS`) are not included in the SRW Application build system but are available pre-built on pre-configured platforms. On other systems, they can be installed via the HPC-Stack. There is a small set of system libraries and utilities that are assumed to be present on the target computer: the CMake build software, a Fortran,
C, and C++ compiler, and an MPI library.

Once built, the provided experiment generator script can be used to create a Rocoto-based
workflow file that will run each task in the system in the proper sequence (see `Rocoto documentation
<https://github.com/christopherwharrop/rocoto/wiki/Documentation>`_). If Rocoto and/or a batch system is not present on the available platform, the individual components can be run in a stand-alone, command line fashion with provided run scripts. The generated namelist for the atmospheric model can be modified in order to vary settings such as forecast starting and ending dates, forecast length hours, the :term:`CCPP` physics suite, integration time step, history file output frequency, and more. It also allows for configuration of other elements of the workflow; for example, whether to run some or all of the pre-processing, forecast model, and post-processing steps.

This SRW Application release has been tested on a variety of platforms widely used by
researchers, such as the NOAA Research and Development High-Performance Computing Systems
(RDHPCS), including  Hera, Orion, and Jet; NOAA’s Weather and Climate Operational
Supercomputing System (WCOSS); the National Center for Atmospheric Research (NCAR) Cheyenne
system; the National Severe Storms Laboratory (NSSL) HPC machine called Odin; the National Science Foundation Stampede2 system; and generic Linux and macOS systems using Intel and GNU compilers. Four `levels of support <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_ have been defined for the SRW Application, including pre-configured (Level 1), configurable (Level 2), limited test platforms (Level 3), and build only platforms (Level 4). Each level is further described below.

For the selected computational platforms that have been pre-configured (Level 1), all the
required libraries for building the SRW Application are available in a central place. That
means bundled libraries (NCEPLIBS) and third-party libraries (NCEPLIBS-external) have both
been built. The SRW Application is expected to build and run out-of-the-box on these
pre-configured platforms, and users can proceed directly to the using the workflow, as
described in the Quick Start (:numref:`Section %s <GenerateForecast>`).

A few additional computational platforms are considered configurable for the SRW Application release. Configurable platforms (Level 2) are platforms where all of the required libraries for building the SRW Application are expected to install successfully but are not available in a central location. Applications and models are expected to build and run once the required bundled libraries (e.g., NCEPLIBS) and third-party libraries (e.g., NCEPLIBS-external) are built.

Limited-Test (Level 3) and Build-Only (Level 4) computational platforms are those in which the developers have built the code but little or no pre-release testing has been conducted, respectively. A complete description of the levels of support, along with a list of preconfigured and configurable platforms can be found in the `SRW Application wiki page <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`_.
