.. _Glossary:

*************************
Glossary
*************************

.. glossary::

   advect
      To transport substances in the atmostphere by :term:`advection`.

   advection
      According to the American Meteorological Society (AMS) `definition <https://glossary.ametsoc.org/wiki/Advection>`__, advection is "The process of transport of an atmospheric property solely by the mass motion (velocity field) of the atmosphere." In common parlance, advection is movement of atmospheric substances that are carried around by the wind.

   AQM
      The `Air Quality Model <https://github.com/NOAA-EMC/AQM>`__ (AQM) is a UFS Application that dynamically couples the Community Multiscale Air Quality (:term:`CMAQ`) model with the UFS Weather Model through the :term:`NUOPC` Layer to simulate temporal and spatial variations of atmospheric compositions (e.g., ozone and aerosol compositions). The CMAQ, treated as a column chemistry model, updates concentrations of chemical species (e.g., ozone and aerosol compositions) at each integration time step. The transport terms (e.g., :term:`advection` and diffusion) of all chemical species are handled by the UFS Weather Model as :term:`tracers<tracer>`.

   CAPE
      Convective Available Potential Energy. 

   CCPA
      Climatology-Calibrated Precipitation Analysis (CCPA) data. This data is required for METplus precipitation verification tasks within the SRW App. The most recent 8 days worth of data are publicly available and can be accessed `here <https://ftp.ncep.noaa.gov/data/nccf/com/ccpa/prod/>`__. 

   CCPP
      The `Common Community Physics Package <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`__ is a forecast-model agnostic, vetted collection of code containing atmospheric physical parameterizations and suites of parameterizations for use in Numerical Weather Prediction (NWP) along with a framework that connects the physics to the host forecast model.

   chgres_cube
       The preprocessing software used to create initial and boundary condition files to 
       “cold start” the forecast model. It is part of :term:`UFS_UTILS`.

   CIN
      Convective Inhibition.

   CMAQ
      The `Community Multiscale Air Quality Model <https://www.epa.gov/cmaq/cmaq-models-0>`__ (CMAQ, pronounced "cee-mak") is a numerical air quality model that predicts the concentration of airborne gases and particles and the deposition of these pollutants back to Earth's surface. The purpose of CMAQ is to provide fast, technically sound estimates of ozone, particulates, toxics, and acid deposition. CMAQ is an active open-source development project of the U.S. Environmental Protection Agency (EPA). Code is publicly available at https://github.com/USEPA/CMAQ. 

   cron
   crontab
   cron table
      Cron is a job scheduler accessed through the command-line on UNIX-like operating systems. It is useful for automating tasks such as the ``rocotorun`` command, which launches each workflow task in the SRW App (see :numref:`Chapter %s <RocotoInfo>` for details). Cron periodically checks a cron table (aka crontab) to see if any tasks are are ready to execute. If so, it runs them. 

   CRTM
      The `Community Radiative Transfer Model <https://www.jcsda.org/jcsda-project-community-radiative-transfer-model>`__ (CRTM) is a fast and accurate radiative transfer model developed at the `Joint Center for Satellite Data Assimilation <https://www.jcsda.org/>`__ (JCSDA) in the United States. It is a sensor-based radiative transfer model and supports more than 100 sensors, including sensors on most meteorological satellites and some from other remote sensing satellites. 

   Component
      A software element that has a clear function and interface. In Earth system models, components are often single portions of the Earth system (e.g. atmosphere, ocean, or land surface) that are assembled to form a whole.

   Component Repository
      A :term:`repository` that contains, at a minimum, source code for a single component.

   Container
      `Docker <https://www.docker.com/resources/what-container>`__ describes a container as "a standard unit of software that packages up code and all its dependencies so the application runs quickly and reliably from one computing environment to another."

   CONUS
      Continental United States

   CAM
   convection-allowing models
      Convection-allowing models (CAMs) are models that run on high-resolution grids (usually with grid spacing at 4km or less). They are able to resolve the effects of small-scale convective processes. They typically run several times a day to provide frequent forecasts (e.g., hourly or subhourly). 

   cycle
      An hour of the day on which a forecast is started. 

   cycle-dependent 
      Describes a workflow task that needs to be run at the start of each :term:`cycle` of an experiment.
   
   cycle-independent
      Describes a workflow task that only needs to be run once per experiment, regardless of the number of cycles in the experiment.
   
   data assimilation
      Data assimilation is the process of combining observations, model data, and error statistics to achieve the best estimate of the state of a system. One of the major sources of error in weather and climate forecasts is uncertainty related to the initial conditions that are used to generate future predictions. Even the most precise instruments have a small range of unavoidable measurement error, which means that tiny measurement errors (e.g., related to atmospheric conditions and instrument location) can compound over time. These small differences result in very similar forecasts in the short term (i.e., minutes, hours), but they cause widely divergent forecasts in the long term. Errors in weather and climate forecasts can also arise because models are imperfect representations of reality. Data assimilation systems seek to mitigate these problems by combining the most timely observational data with a "first guess" of the atmospheric state (usually a previous forecast) and other sources of data to provide a "best guess" analysis of the atmospheric state to start a weather or climate simulation. When combined with an "ensemble" of model runs (many forecasts with slightly different conditions), data assimilation helps predict a range of possible atmospheric states, giving an overall measure of uncertainty in a given forecast.

   dycore
   dynamical core
      Global atmospheric model based on fluid dynamics principles, including Euler's equations of motion.

   echo top
      The radar-indicated top of an area of precipitation. Specifically, it contains the height of the 18 dBZ reflectivity value.

   EMC
      The `Environmental Modeling Center <https://www.emc.ncep.noaa.gov/emc_new.php>`__. 

   EPIC
      The `Earth Prediction Innovation Center <https://epic.noaa.gov/>`__ seeks to accelerate scientific research and modeling contributions through continuous and sustained community engagement in order to produce the most accurate and reliable operational modeling system in the world. 

   ESG
      Extended Schmidt Gnomonic (ESG) grid. The ESG grid uses the map projection developed by Jim Purser of NOAA :term:`EMC` (:cite:t:`Purser_2020`). 

   ESMF
      `Earth System Modeling Framework <https://earthsystemmodeling.org/docs/release/latest/ESMF_usrdoc/>`__. The ESMF defines itself as “a suite of software tools for developing high-performance, multi-component Earth science modeling applications.” 

   ex-scripts
      Scripting layer (contained in ``ufs-srweather-app/scripts/``) that should be called by a :term:`J-job <J-jobs>` for each workflow componentto run a specific task or sub-task in the workflow. The different scripting layers are described in detail in the :nco:`NCO Implementation Standards document <ImplementationStandards.v11.0.0.pdf>`

   FV3
      The Finite-Volume Cubed-Sphere :term:`dynamical core` (dycore). Developed at NOAA's `Geophysical 
      Fluid Dynamics Laboratory <https://www.gfdl.noaa.gov/>`__ (GFDL), it is a scalable and flexible dycore capable of both hydrostatic and non-hydrostatic atmospheric simulations. It is the dycore used in the UFS Weather Model.

   FVCOM
      `Finite Volume Community Ocean Model <https://www.fvcom.org/>`__. FVCOM is used in modeling work for the `Great Lakes Coastal Forecasting System (next-gen FVCOM) <https://www.glerl.noaa.gov/res/glcfs/>`__ conducted by the `Great Lakes Environmental Research Laboratory <https://www.glerl.noaa.gov/>`__.

   GFS
      `Global Forecast System <https://www.ncei.noaa.gov/products/weather-climate-models/global-forecast>`_. The GFS is a National Centers for Environmental Prediction (:term:`NCEP`) weather forecast model that generates data for dozens of atmospheric and land-soil variables, including temperatures, winds, precipitation, soil moisture, and atmospheric ozone concentration. The system couples four separate models (atmosphere, ocean, land/soil, and sea ice) that work together to accurately depict weather conditions.

   GOCART
      NASA's Goddard Chemistry Aerosol Radiation and Transport (GOCART) model simulates the distribution of major tropospheric aerosol types, including sulfate, dust, organic carbon (OC), black carbon (BC), and sea salt aerosols. The UFS Weather Model integrates a prognostic aerosol component using GOCART. The code is publicly available on GitHub at https://github.com/GEOS-ESM/GOCART. 

   GRIB2 
      The second version of the World Meterological Organization's (WMO) standard for distributing gridded data.  

   GSL
      NOAA `Global Systems Laboratory <https://gsl.noaa.gov/>`__ is one of ten NOAA Research laboratories and is located in Boulder, Colorado. Its research improves environmental prediction models, develops state-of-the-science decision support tools and visualization systems, and uses high-performance computing technology to support a Weather-Ready Nation. 

   halo
      A strip of cells on the edge of the regional grid. The :ref:`wide halo <WideHalo>` surrounds the regional grid and is used to feed the lateral boundary conditions into the grid. The :ref:`HALO_BLEND <HaloBlend>` parameter refers to a strip of cells *inside* the boundary of the native grid. This halo smooths out mismatches between the external and internal solutions. 

   HPC
      High-Performance Computing.

   HPC-Stack
      The `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__ is a repository that provides a unified, shell script-based build system for building the software stack required for numerical weather prediction (NWP) tools such as the `Unified Forecast System (UFS) <https://ufscommunity.org/>`__ and the `Joint Effort for Data assimilation Integration (JEDI) <https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/>`__ framework. View the HPC-Stack documentation :doc:`here <hpc-stack:index>`.

   HPSS
      High Performance Storage System (HPSS).

   HRRR
      `High Resolution Rapid Refresh <https://rapidrefresh.noaa.gov/hrrr/>`__. The HRRR is a NOAA real-time 3-km resolution, hourly updated, cloud-resolving, convection-allowing atmospheric model initialized by 3km grids with 3km radar assimilation. Radar data is assimilated in the HRRR every 15 min over a 1-h period adding further detail to that provided by the hourly data assimilation from the 13km radar-enhanced Rapid Refresh.

   ICs/LBCs
      Initial conditions/lateral boundary conditions

   ICs
      Initial conditions

   J-jobs
      Scripting layer (contained in ``ufs-srweather-app/jobs/``) that should be directly called for each workflow component (either on the command line or by the workflow manager) to run a specific task in the workflow. The different scripting layers are described in detail in the :nco:`NCO Implementation Standards document <ImplementationStandards.v11.0.0.pdf>`

   JEDI
      The Joint Effort for Data assimilation Integration (`JEDI <https://www.jcsda.org/jcsda-project-jedi>`__) is a unified and versatile data assimilation (DA) system for Earth System Prediction. It aims to enable efficient research and accelerated transition from research to operations by providing a framework that takes into account all components of the Earth system in a consistent manner. The JEDI software package can run on a variety of platforms and for a variety of purposes, and it is designed to readily accommodate new atmospheric and oceanic models and new observation systems. The `JEDI User's Guide <https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/>`__ contains extensive information on the software. 

      JEDI is developed and distributed by the `Joint Center for Satellite Data Assimilation <https://www.jcsda.org/>`__, a multi-agency research center hosted by the University Corporation for Atmospheric Research (`UCAR <https://www.ucar.edu/>`__). JCSDA is dedicated to improving and accelerating the quantitative use of research and operational satellite data in weather, ocean, climate, and environmental analysis and prediction systems.

   LAM
      Limited Area Model (grid type), formerly known as the "Stand-Alone Regional Model," or SAR. LAM grids use a regional (rather than global) configuration of the :term:`FV3` :term:`dynamical core`. 

   LBCs
      Lateral boundary conditions

   MEGAN
      The Model of Emissions of Gases and Aerosols from Nature (`MEGAN <https://bai.ess.uci.edu/megan>`__) is a modeling system for estimating the emission of gases and aerosols from terrestrial ecosystems into the atmosphere. It has been integrated into a number of chemistry and transport models, including :ref:`NEXUS <nexus>`. 

   MERRA2
      The `Modern-Era Retrospective analysis for Research and Applications, Version 2 <https://gmao.gsfc.nasa.gov/reanalysis/MERRA-2/>`__ provides satellite observation data back to 1980. According to NASA, "It was introduced to replace the original MERRA dataset because of the advances made in the assimilation system that enable assimilation of modern hyperspectral radiance and microwave observations, along with GPS-Radio Occultation datasets. It also uses NASA's ozone profile observations that began in late 2004. Additional advances in both the GEOS model and the GSI assimilation system are included in MERRA-2. Spatial resolution remains about the same (about 50 km in the latitudinal direction) as in MERRA."

   MPI
      MPI stands for Message Passing Interface. An MPI is a standardized communication system used in parallel programming. It establishes portable and efficient syntax for the exchange of messages and data between multiple processors that are used by a single computer program. An MPI is required for high-performance computing (HPC) systems.

   MRMS
      Multi-Radar/Multi-Sensor (MRMS) System Analysis data. This data is required for METplus composite reflectivity or :term:`echo top` verification tasks within the SRW App. A two-day archive of precipitation, radar, and aviation and severe weather fields is publicly available and can be accessed `here <https://mrms.ncep.noaa.gov/data/>`__.

   NAM
      `North American Mesoscale Forecast System <https://www.ncei.noaa.gov/products/weather-climate-models/north-american-mesoscale>`_. NAM generates multiple grids (or domains) of weather forecasts over the North American continent at various horizontal resolutions. Each grid contains data for dozens of weather parameters, including temperature, precipitation, lightning, and turbulent kinetic energy. NAM uses additional numerical weather models to generate high-resolution forecasts over fixed regions, and occasionally to follow significant weather events like hurricanes.

   namelist
      A namelist defines a group of variables or arrays. Namelists are an I/O feature for format-free input and output of variables by key-value assignments in Fortran compilers. Fortran variables can be read from and written to plain-text files in a standardised format, usually with a ``.nml`` file ending.

   NCAR
      The `National Center for Atmospheric Research <https://ncar.ucar.edu/>`__. 

   NCEP
      National Centers for Environmental Prediction (NCEP) is an arm of the National Weather Service
      consisting of nine centers. More information can be found at https://www.ncep.noaa.gov.

   NCEPLIBS
      The software libraries created and maintained by :term:`NCEP` that are required for running 
      :term:`chgres_cube`, the UFS Weather Model, and the :term:`UPP`. They are included in the `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__. 

   NCEPLIBS-external
      A collection of third-party libraries required to build :term:`NCEPLIBS`, :term:`chgres_cube`, 
      the UFS Weather Model, and :term:`UPP`. They are included in the :term:`HPC-Stack`.  

   NCL
      An interpreted programming language designed specifically for scientific data analysis and 
      visualization. Stands for NCAR Command Language. More information can be found at https://www.ncl.ucar.edu.

   NDAS
      :term:`NAM` Data Assimilation System (NDAS) data. This data is required for METplus surface and upper-air verification tasks within the SRW App. The most recent 1-2 days worth of data are publicly available in PrepBufr format and can be accessed `here <ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/rap/prod>`__. The most recent 8 days of data can be accessed `here <https://nomads.ncep.noaa.gov/pub/data/nccf/com/nam/prod/>`__.

   NEMS
      The NOAA Environmental Modeling System is a common modeling framework whose purpose is 
      to streamline components of operational modeling suites at :term:`NCEP`.

   NEMSIO
      A binary format for atmospheric model output from :term:`NCEP`'s Global Forecast System (:term:`GFS`).

   netCDF
      NetCDF (`Network Common Data Form <https://www.unidata.ucar.edu/software/netcdf/>`__) is a file format and community standard for storing multidimensional scientific data. It includes a set of software libraries and machine-independent data formats that support the creation, access, and sharing of array-oriented scientific data.

   NOHRSC
      The National Operational Hydrologic Remote Sensing Center, which provides the National Snowfall Analysis, an observation-based, gridded estimate of recent snowfall, now an operational product. 

   NSSL
      The `National Severe Storms Laboratory <https://www.nssl.noaa.gov/>`__. 

   NUOPC
      The `National Unified Operational Prediction Capability <https://earthsystemmodeling.org/nuopc/>`__ Layer "defines conventions and a set of generic components for building coupled models using the Earth System Modeling Framework (:term:`ESMF`)." 

   NWP
      Numerical Weather Prediction (NWP) takes current observations of weather and processes them with computer models to forecast the future state of the weather. 

   NWS
      The `National Weather Service <https://www.weather.gov/>`__ (NWS) is an agency of the United States government that is tasked with providing weather forecasts, warnings of hazardous weather, and other weather-related products to organizations and the public for the purposes of protection, safety, and general information. It is a part of the National Oceanic and Atmospheric Administration (NOAA) branch of the Department of Commerce.

   Orography
      The branch of physical geography dealing with mountains.

   Parameterizations
      Simplified functions that approximate the effects of small-scale processes (e.g., microphysics, gravity wave drag) that cannot be explicitly resolved by a model grid’s representation of the earth.

   RAP
      `Rapid Refresh <https://rapidrefresh.noaa.gov/>`__. The continental-scale NOAA hourly-updated assimilation/modeling system operational at :term:`NCEP`. RAP covers North America and is comprised primarily of a numerical forecast model and an analysis/assimilation system to initialize that model. RAP is complemented by the higher-resolution 3km High-Resolution Rapid Refresh (:term:`HRRR`) model.

   RDHPCS
      NOAA Research & Development High-Performance Computing Systems.

   Repository
      A central location in which files (e.g., data, code, documentation) are stored and managed. 

   RRFS
      The `Rapid Refresh Forecast System <https://gsl.noaa.gov/focus-areas/unified_forecast_system/rrfs>`__ (RRFS) is NOAA's next-generation convection-allowing, rapidly-updated, ensemble-based data assimilation and forecasting system currently scheduled for operational implementation in 2024. It is designed to run forecasts on a 3-km :term:`CONUS` domain. 

   SDF
      Suite Definition File. An external file containing information about the construction of a physics suite. It describes the schemes that are called, in which order they are called, whether they are subcycled, and whether they are assembled into groups to be called together.

   Spack
      `Spack <https://spack.readthedocs.io/en/latest/>`__ is a package management tool designed to support multiple versions and configurations of software on a wide variety of platforms and environments. It was designed for large supercomputing centers, where many users and application teams share common installations of software on clusters with exotic architectures. 

   spack-stack
      The `spack-stack <https://github.com/JCSDA/spack-stack>`__ is a collaborative effort between the NOAA Environmental Modeling Center (EMC), the UCAR Joint Center for Satellite Data Assimilation (JCSDA), and the Earth Prediction Innovation Center (EPIC). *spack-stack* is a repository that provides a :term:`Spack`-based method for building the software stack required for numerical weather prediction (NWP) tools such as the `Unified Forecast System (UFS) <https://ufscommunity.org/>`__ and the `Joint Effort for Data assimilation Integration (JEDI) <https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/>`__ framework. *spack-stack* uses the Spack package manager along with custom Spack configuration files and Python scripts to simplify installation of the libraries required to run various applications. The *spack-stack* can be installed on a range of platforms and comes pre-configured for many systems. Users can install the necessary packages for a particular application and later add the missing packages for another application without having to rebuild the entire stack. To get started, check out the documentation :doc:`here <spack-stack:index>`.

   tracer
      According to the American Meteorological Society (AMS) `definition <https://glossary.ametsoc.org/wiki/Tracer>`__, a tracer is "Any substance in the atmosphere that can be used to track the history [i.e., movement] of an air mass." Tracers are carried around by the motion of the atmosphere (i.e., by :term:`advection`). These substances are usually gases (e.g., water vapor, CO2), but they can also be non-gaseous (e.g., rain drops in microphysics parameterizations). In weather models, temperature (or potential temperature), absolute humidity, and radioactivity are also usually treated as tracers. According to AMS, "The main requirement for a tracer is that its lifetime be substantially longer than the transport process under study."

   UFS
      The Unified Forecast System is a community-based, coupled, comprehensive Earth modeling 
      system consisting of several applications (apps). These apps span regional to global 
      domains and sub-hourly to seasonal time scales. The UFS is designed to support the :term:`Weather Enterprise` and to be the source system for NOAA's operational numerical weather prediction applications. For more information, visit https://ufscommunity.org/.

   UFS_UTILS
      A collection of code used by multiple :term:`UFS` apps (e.g., the UFS Short-Range Weather App,
      the UFS Medium-Range Weather App). The grid, orography, surface climatology, and initial 
      and boundary condition generation codes used by the UFS Short-Range Weather App are all 
      part of this collection. The code is `publicly available <https://github.com/ufs-community/UFS_UTILS>`__ on Github.

   Umbrella repository
      A repository that houses external code, or "externals," from additional repositories.

   Updraft helicity
      Helicity measures the rotation in a storm's updraft (rising) air. Significant rotation increases the probability that the storm will produce severe weather, including tornadoes. See http://ww2010.atmos.uiuc.edu/(Gh)/guides/mtr/svr/modl/fcst/params/hel.rxml for more details on updraft helicity. 

   UPP
      The `Unified Post Processor <https://github.com/NOAA-EMC/UPP>`__ is software developed at :term:`NCEP` and used operationally to 
      post-process raw output from a variety of :term:`NCEP`'s :term:`NWP` models, including the :term:`FV3`. See https://epic.noaa.gov/unified-post-processor/ for more information. 

   Weather Enterprise
      Individuals and organizations from public, private, and academic sectors that contribute to the research, development, and production of weather forecast products; primary consumers of these weather forecast products.

   Weather Model
      A prognostic model that can be used for short- and medium-range research and
      operational forecasts. It can be an atmosphere-only model or an atmospheric
      model coupled with one or more additional components, such as a wave or ocean model. The SRW App uses the `UFS Weather Model <https://github.com/ufs-community/ufs-weather-model/wiki>`__.

   Workflow
      The sequence of steps required to run an experiment from start to finish.
