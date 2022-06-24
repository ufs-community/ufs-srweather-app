.. _Glossary:

*************************
Glossary
*************************

.. glossary::

   advect
      To transport substances in the atmostphere by :term:`advection`.

   advection
      According to the American Meteorological Society (AMS) `definition <https://glossary.ametsoc.org/wiki/Advection>`__, advection is "The process of transport of an atmospheric property solely by the mass motion (velocity field) of the atmosphere." In common parlance, advection is movement of atmospheric substances that are carried around by the wind.

   CAPE
      Convective Available Potential Energy. 

   CCPA
      Climatology-Calibrated Precipitation Analysis (CCPA) data. This data is required for METplus precipitation verification tasks within the SRW App. The most recent 8 days worth of data are publicly available and can be accessed `here <https://ftp.ncep.noaa.gov/data/nccf/com/ccpa/prod/>`__. 

   CCPP
      The `Common Community Physics Package <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`_ is a forecast-model agnostic, vetted collection of code containing atmospheric physical parameterizations and suites of parameterizations for use in Numerical Weather Prediction (NWP) along with a framework that connects the physics to the host forecast model.

   chgres_cube
       The preprocessing software used to create initial and boundary condition files to 
       “coldstart” the forecast model.

   CIN
      Convective Inhibition.

   cron
   crontab
   cron table
      Cron is a job scheduler accessed through the command-line on UNIX-like operating systems. It is useful for automating tasks such as the ``rocotorun`` command, which launches each workflow task in the SRW App. Cron periodically checks a cron table (aka crontab) to see if any tasks are are ready to execute. If so, it runs them. 

   CRTM
      `Community Radiative Transfer Model <https://www.jcsda.org/jcsda-project-community-radiative-transfer-model>`__. CRTM is a fast and accurate radiative transfer model developed at the `Joint Center for Satellite Data Assimilation <https://www.jcsda.org/>`__ (JCSDA) in the United States. It is a sensor-based radiative transfer model and supports more than 100 sensors, including sensors on most meteorological satellites and some from other remote sensing satellites. 

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
   cycles
      An hour of the day on which a forecast is started. 

   cycle-dependent 
      Describes a workflow task that needs to be run at the start of each :term:`cycle` of an experiment.
   
   cycle-independent
      Describes a workflow task that only needs to be run once per experiment, regardless of the number of cycles in the experiment.
   
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

   FV3
      The Finite-Volume Cubed-Sphere :term:`dynamical core` (dycore). Developed at NOAA's `Geophysical 
      Fluid Dynamics Laboratory <https://www.gfdl.noaa.gov/>`__ (GFDL), it is a scalable and flexible dycore capable of both hydrostatic and non-hydrostatic atmospheric simulations. It is the dycore used in the UFS Weather Model.

   FVCOM
      `Finite Volume Community Ocean Model <http://fvcom.smast.umassd.edu/fvcom/>`__. FVCOM is used in modeling work for the `Great Lakes Coastal Forecasting System (next-gen FVCOM) <https://www.glerl.noaa.gov/res/glcfs/>`__ conducted by the `Great Lakes Environmental Research Laboratory <https://www.glerl.noaa.gov/>`__. 

   GFS
      `Global Forecast System <https://www.ncei.noaa.gov/products/weather-climate-models/global-forecast>`_. The GFS is a National Centers for Environmental Prediction (NCEP) weather forecast model that generates data for dozens of atmospheric and land-soil variables, including temperatures, winds, precipitation, soil moisture, and atmospheric ozone concentration. The system couples four separate models (atmosphere, ocean, land/soil, and sea ice) that work together to accurately depict weather conditions.

   GRIB2 
      The second version of the World Meterological Organization's (WMO) standard for distributing gridded data.  

   halo
      A strip of cells on the edge of the regional grid. The :ref:`wide halo <WideHalo>` surrounds the regional grid and is used to feed the lateral boundary conditions into the grid. The :ref:`HALO_BLEND <HaloBlend>` parameter refers to a strip of cells *inside* the boundary of the native grid. This halo smooths out mismatches between the external and internal solutions. 

   HPC
   HPCs
      High-Performance Computing.

   HPC-Stack
      The `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__ is a repository that provides a unified, shell script-based build system for building the software stack required for numerical weather prediction (NWP) tools such as the `Unified Forecast System (UFS) <https://ufscommunity.org/>`__ and the `Joint Effort for Data assimilation Integration (JEDI) <https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/>`__ framework.

   HPSS
      High Performance Storage System (HPSS).

   HRRR
      `High Resolution Rapid Refresh <https://rapidrefresh.noaa.gov/hrrr/>`__. The HRRR is a NOAA real-time 3-km resolution, hourly updated, cloud-resolving, convection-allowing atmospheric model initialized by 3km grids with 3km radar assimilation. Radar data is assimilated in the HRRR every 15 min over a 1-h period adding further detail to that provided by the hourly data assimilation from the 13km radar-enhanced Rapid Refresh.

   IC/LBC
   IC/LBCs
      Initial conditions/lateral boundary conditions

   IC
   ICs
      Initial conditions

   LAM
      Limited Area Model (grid type), formerly known as the "Stand-Alone Regional Model," or SAR. LAM grids use a regional (rather than global) configuration of the :term:`FV3` :term:`dynamical core`. 

   LBC
   LBCs
      Lateral boundary conditions

   MERRA2
      The `Modern-Era Retrospective analysis for Research and Applications, Version 2 <https://gmao.gsfc.nasa.gov/reanalysis/MERRA-2/>`__ provides satellite observation data back to 1980. According to NASA, "It was introduced to replace the original MERRA dataset because of the advances made in the assimilation system that enable assimilation of modern hyperspectral radiance and microwave observations, along with GPS-Radio Occultation datasets. It also uses NASA's ozone profile observations that began in late 2004. Additional advances in both the GEOS model and the GSI assimilation system are included in MERRA-2. Spatial resolution remains about the same (about 50 km in the latitudinal direction) as in MERRA."

   MPI
      MPI stands for Message Passing Interface. An MPI is a standardized communication system used in parallel programming. It establishes portable and efficient syntax for the exchange of messages and data between multiple processors that are used by a single computer program. An MPI is required for high-performance computing (HPC).

   MRMS
      Multi-Radar/Multi-Sensor (MRMS) System Analysis data. This data is required for METplus composite reflectivity or :term:`echo top` verification tasks within the SRW App. A two-day archive of precipitation, radar, and aviation and severe weather fields is publicly available and can be accessed `here <https://mrms.ncep.noaa.gov/data/>`__.

   NAM
      `North American Mesoscale Forecast System <https://www.ncei.noaa.gov/products/weather-climate-models/north-american-mesoscale>`_. NAM generates multiple grids (or domains) of weather forecasts over the North American continent at various horizontal resolutions. Each grid contains data for dozens of weather parameters, including temperature, precipitation, lightning, and turbulent kinetic energy. NAM uses additional numerical weather models to generate high-resolution forecasts over fixed regions, and occasionally to follow significant weather events like hurricanes.

   namelist
      A namelist defines a group of variables or arrays. Namelists are an I/O feature for format-free input and output of variables by key-value assignments in FORTRAN compilers. Fortran variables can be read from and written to plain-text files in a standardised format, usually with a ``.nml`` file ending.

   NCAR
      The `National Center for Atmospheric Research <https://ncar.ucar.edu/>`__. 

   NCEP
      National Centers for Environmental Prediction (NCEP) is an arm of the National Weather Service
      consisting of nine centers. More information can be found at https://www.ncep.noaa.gov.

   NCEPLIBS
      The software libraries created and maintained by :term:`NCEP` that are required for running 
      :term:`chgres_cube`, the UFS Weather Model, and :term:`UPP`. They are included in the `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__. 

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

   NUOPC
      The `National Unified Operational Prediction Capability <https://earthsystemmodeling.org/nuopc/>`__ Layer "defines conventions and a set of generic components for building coupled models using the Earth System Modeling Framework (:term:`ESMF`)." 

   NWP
      Numerical Weather Prediction (NWP) takes current observations of weather and processes them with computer models to forecast the future state of the weather. 

   Orography
      The branch of physical geography dealing with mountains.

   Parameterization
   Parameterizations
      Simplified functions that approximate the effects of small-scale processes (e.g., microphysics, gravity wave drag) that cannot be explicitly resolved by a model grid’s representation of the earth.

   RAP
      `Rapid Refresh <https://rapidrefresh.noaa.gov/>`__. The continental-scale NOAA hourly-updated assimilation/modeling system operational at NCEP. RAP covers North America and is comprised primarily of a numerical forecast model and an analysis/assimilation system to initialize that model. RAP is complemented by the higher-resolution 3km High-Resolution Rapid Refresh (:term:`HRRR`) model.

   Repository
      A central location in which files (e.g., data, code, documentation) are stored and managed. 

   SDF
      Suite Definition File. An external file containing information about the construction of a physics suite. It describes the schemes that are called, in which order they are called, whether they are subcycled, and whether they are assembled into groups to be called together.

   spack-stack
      The `spack-stack <https://github.com/NOAA-EMC/spack-stack>`__ is a collaborative effort between the NOAA Environmental Modeling Center (EMC), the UCAR Joint Center for Satellite Data Assimilation (JCSDA), and the Earth Prediction Innovation Center (EPIC). *spack-stack* is a repository that provides a Spack-based method for building the software stack required for numerical weather prediction (NWP) tools such as the `Unified Forecast System (UFS) <https://ufscommunity.org/>`__ and the `Joint Effort for Data assimilation Integration (JEDI) <https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/>`__ framework. spack-stack uses the Spack package manager along with custom Spack configuration files and Python scripts to simplify installation of the libraries required to run various applications. The *spack-stack* can be installed on a range of platforms and comes pre-configured for many systems. Users can install the necessary packages for a particular application and later add the missing packages for another application without having to rebuild the entire stack.

   tracer
   tracers
      According to the American Meteorological Society (AMS) `definition <https://glossary.ametsoc.org/wiki/Tracer>`__, a tracer is "Any substance in the atmosphere that can be used to track the history [i.e., movement] of an air mass." Tracers are carried around by the motion of the atmosphere (i.e., by :term:`advection`). These substances are usually gases (e.g., water vapor, CO2), but they can also be non-gaseous (e.g., rain drops in microphysics parameterizations). In weather models, temperature (or potential temperature), absolute humidity, and radioactivity are also usually treated as tracers. According to AMS, "The main requirement for a tracer is that its lifetime be substantially longer than the transport process under study."

   UFS
      The Unified Forecast System is a community-based, coupled, comprehensive Earth modeling 
      system consisting of several applications (apps). These apps span regional to global 
      domains and sub-hourly to seasonal time scales. The UFS is designed to support the :term:`Weather Enterprise` and to be the source system for NOAA's operational numerical weather prediction applications. For more information, visit https://ufscommunity.org/.

   UFS_UTILS
      A collection of code used by multiple :term:`UFS` apps (e.g., the UFS Short-Range Weather App,
      the UFS Medium-Range Weather App). The grid, orography, surface climatology, and initial 
      and boundary condition generation codes used by the UFS Short-Range Weather App are all 
      part of this collection.

   Umbrella repository
      A repository that houses external code, or "externals," from additional repositories.

   UPP
      The `Unified Post Processor <https://dtcenter.org/community-code/unified-post-processor-upp>`__ is software developed at :term:`NCEP` and used operationally to 
      post-process raw output from a variety of :term:`NCEP`'s :term:`NWP` models, including the :term:`FV3`.

   Weather Enterprise
      Individuals and organizations from public, private, and academic sectors that contribute to the research, development, and production of weather forecast products; primary consumers of these weather forecast products.

   Weather Model
      A prognostic model that can be used for short- and medium-range research and
      operational forecasts. It can be an atmosphere-only model or an atmospheric
      model coupled with one or more additional components, such as a wave or ocean model. The SRW App uses the fully-coupled `UFS Weather Model <https://github.com/ufs-community/ufs-weather-model>`__.

   Workflow
      The sequence of steps required to run an experiment from start to finish. 