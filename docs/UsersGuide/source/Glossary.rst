.. _Glossary:

*************************
Glossary
*************************

.. glossary::

   CCPP
      The `Common Community Physics Package <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`_ is a forecast-model agnostic, vetted collection of codes containing atmospheric physical parameterizations and suites of parameterizations for use in Numerical Weather Prediction (NWP) along with a framework that connects the physics to the host forecast model.

   chgres_cube
       The preprocessing software used to create initial and boundary condition files to 
       “coldstart” the forecast model.

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

   cycle
      An hour of the day on which a forecast is started. 

   cycle-dependent 
      Describes a workflow task that needs to be run at the start of each :term:`cycle` of an experiment.
   
   cycle-independent
      Describes a workflow task that only needs to be run once per experiment, regardless of the number of cycles in the experiment.
   
   dynamical core
      Global atmospheric model based on fluid dynamics principles, including Euler's equations of motion.

   EPIC
      EPIC stands for the `Earth Prediction Innovation Center <https://epic.noaa.gov/>`__. EPIC seeks to accelerate scientific research and modeling contributions through continuous and sustained community engagement to produce the most accurate and reliable operational modeling system in the world. 

   FV3
      The Finite-Volume Cubed-Sphere dynamical core (dycore). Developed at NOAA's Geophysical 
      Fluid Dynamics Laboratory (GFDL), it is a scalable and flexible dycore capable of both 
      hydrostatic and non-hydrostatic atmospheric simulations.  It is the dycore used in the 
      UFS Weather Model.

   FVCOM
      `Finite Volume Community Ocean Model <http://fvcom.smast.umassd.edu/>`__. FVCOM is used in modeling work for the `Great Lakes Coastal Forecasting System (next-gen FVCOM) <https://www.glerl.noaa.gov/res/glcfs/>`__ conducted by the `Great Lakes Environmental Research Laboratory <https://www.glerl.noaa.gov/>`__. 

   GFS
      `Global Forecast System <https://www.ncei.noaa.gov/products/weather-climate-models/global-forecast>`_. The GFS is a National Centers for Environmental Prediction (NCEP) weather forecast model that generates data for dozens of atmospheric and land-soil variables, including temperatures, winds, precipitation, soil moisture, and atmospheric ozone concentration. The system couples four separate models (atmosphere, ocean model, land/soil model, and sea ice) that work together to accurately depict weather conditions.

   GRIB2 
      The second version of the World Meterological Organization's (WMO) standard for distributing gridded data.  

   halo
      A strip of cells on the edge of the regional grid. The `wide halo <WideHalo>` surrounds the regional grid and is used to feed the lateral boundary conditions into the grid. The `HALO_BLEND <HaloBlend>` parameter refers to a strip of cells on the *inside* the boundary of the native grid. This halo smooths out mismatches between the external and internal solutions. 

   HPC-Stack
      The `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__ is a repository that provides a unified, shell script-based build system for building the software stack required for numerical weather prediction (NWP) tools such as the `Unified Forecast System (UFS) <https://ufscommunity.org/>`__ and the `Joint Effort for Data assimilation Integration (JEDI) <https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/>`__ framework.

   HRRR
      `High Resolution Rapid Refresh <https://rapidrefresh.noaa.gov/hrrr/>`__. The HRRR is a NOAA real-time 3-km resolution, hourly updated, cloud-resolving, convection-allowing atmospheric model, initialized by 3km grids with 3km radar assimilation. Radar data is assimilated in the HRRR every 15 min over a 1-h period adding further detail to that provided by the hourly data assimilation from the 13km radar-enhanced Rapid Refresh.

   IC/LBC
      Initial conditions/lateral boundary conditions

   LAM
      Limited Area Model, formerly known as the "Stand-Alone Regional Model," or SAR. LAM grids use a regional (rather than global) configuration of the FV3 dynamical core. 

   LBCs
      Lateral boundary conditions.

   MPI
      MPI stands for Message Passing Interface. An MPI is a standardized communication system used in parallel programming. It establishes portable and efficient syntax for the exchange of messages and data between multiple processors that are used by a single computer program. An MPI is required for high-performance computing (HPC).

   NAM
      `North American Mesoscale Forecast System <https://www.ncei.noaa.gov/products/weather-climate-models/north-american-mesoscale>`_. NAM generates multiple grids (or domains) of weather forecasts over the North American continent at various horizontal resolutions. Each grid contains data for dozens of weather parameters, including temperature, precipitation, lightning, and turbulent kinetic energy. NAM uses additional numerical weather models to generate high-resolution forecasts over fixed regions, and occasionally to follow significant weather events like hurricanes.

   NCEP
      National Centers for Environmental Prediction, an arm of the National Weather Service,
      consisting of nine centers. More information can be found at https://www.ncep.noaa.gov.

   NCEPLIBS
      The software libraries created and maintained by :term:`NCEP` that are required for running 
      :term:`chgres_cube`, the UFS Weather Model, and :term:`UPP`. They are included in the `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__. 

   NCEPLIBS-external
      A collection of third-party libraries required to build :term:`NCEPLIBS`, :term:`chgres_cube`, 
      the UFS Weather Model, and :term:`UPP`. They are included in the `HPC-Stack <https://github.com/NOAA-EMC/hpc-stack>`__.  

   NCL
      An interpreted programming language designed specifically for scientific data analysis and 
      visualization. Stands for NCAR Command Language. More information can be found at https://www.ncl.ucar.edu.

   NEMS
      The NOAA Environmental Modeling System is a common modeling framework whose purpose is 
      to streamline components of operational modeling suites at :term:`NCEP`.

   NEMSIO
      A binary format for atmospheric model output from :term:`NCEP`'s Global Forecast System (GFS).

   NWP
      Numerical Weather Prediction (NWP) takes current observations of weather and processes them with computer models to forecast the future state of the weather. 

   Orography
      The branch of physical geography dealing with mountains.

   RAP
      `Rapid Refresh <https://rapidrefresh.noaa.gov/>`__. The continental-scale NOAA hourly-updated assimilation/modeling system operational at NCEP. RAP covers North America and is comprised primarily of a numerical forecast model and an analysis/assimilation system to initialize that model. RAP is complemented by the higher-resolution 3km High-Resolution Rapid Refresh (HRRR) model.

   Repository
      A central location in which files (e.g., data, code, documentation) are stored and managed. 

   SDF
      Suite Definition File. An external file containing information about the construction of a physics suite. It describes the schemes that are called, in which order they are called, whether they are subcycled, and whether they are assembled into groups to be called together.

   UFS
      The Unified Forecast System is a community-based, coupled comprehensive Earth modeling 
      system consisting of several applications (apps). These apps span regional to global 
      domains and sub-hourly to seasonal time scales. The UFS is designed to support the Weather 
      Enterprise and to be the source system for NOAA's operational numerical weather prediction 
      applications.  More information can be found at http://ufs-dev.rap.ucar.edu/index.html.

   UFS_UTILS
      A collection of codes used by multiple :term:`UFS` apps (e.g. the UFS Short-Range Weather App,
      the UFS Medium-Range Weather App). The grid, orography, surface climatology, and initial 
      and boundary condition generation codes used by the UFS Short-Range Weather App are all 
      part of this collection.

   Umbrella repository
      A repository that houses external code, or “externals,” from additional repositories.

   UPP
      The `Unified Post Processor <https://dtcenter.org/community-code/unified-post-processor-upp>`__ is software developed at :term:`NCEP` and used operationally to 
      post-process raw output from a variety of :term:`NCEP`'s NWP models, including the FV3.

   Weather Enterprise
      Individuals and organizations from public, private, and academic sectors that contribute to the research, development, and production of weather forecast products; primary consumers of these weather forecast products.

   Weather Model
      A prognostic model that can be used for short- and medium-range research and
      operational forecasts. It can be an atmosphere-only model or an atmospheric
      model coupled with one or more additional components, such as a wave or ocean model.
