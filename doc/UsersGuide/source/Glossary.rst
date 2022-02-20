.. _Glossary:

*************************
Glossary
*************************

.. glossary::

   CCPP
      A forecast-model agnostic, vetted collection of codes containing atmospheric physical 
      parameterizations and suites of parameterizations for use in Numerical Weather Prediction 
      (NWP) along with a framework that connects the physics to the host forecast model.

   chgres_cube
       The preprocessing software used to create initial and boundary condition files to 
       “coldstart” the forecast model.

   FV3
      The Finite-Volume Cubed-Sphere dynamical core (dycore). Developed at NOAA's Geophysical 
      Fluid Dynamics Laboratory (GFDL), it is a scalable and flexible dycore capable of both 
      hydrostatic and non-hydrostatic atmospheric simulations.  It is the dycore used in the 
      UFS Weather Model.

   GRIB2 
      The second version of the World Meterological Organization's (WMO) standard for distributing gridded data.  

   NCEP
      National Centers for Environmental Prediction, an arm of the National Weather Service,
      consisting of nine centers.  More information can be found at https://www.ncep.noaa.gov.

   NCEPLIBS
      The software libraries created and maintained by :term:`NCEP` that are required for running 
      :term:`chgres_cube`, the UFS Weather Model, and :term:`UPP`.

   NCEPLIBS-external
      A collection of third-party libraries required to build :term:`NCEPLIBS`, :term:`chgres_cube`, 
      the UFS Weather Model, and :term:`UPP`.

   NCL
      An interpreted programming language designed specifically for scientific data analysis and 
      visualization.  More information can be found at https://www.ncl.ucar.edu.

   NEMS
      The NOAA Environmental Modeling System is a common modeling framework whose purpose is 
      to streamline components of operational modeling suites at :term:`NCEP`.

   NEMSIO
      A binary format for atmospheric model output from :term:`NCEP`'s Global Forecast System (GFS).

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

   UPP
      The Unified Post Processor is software developed at :term:`NCEP` and used operationally to 
      post-process raw output from a variety of :term:`NCEP`'s NWP models, including the FV3.

   Weather Model
      A prognostic model that can be used for short- and medium-range research and
      operational forecasts. It can be an atmosphere-only model or an atmospheric
      model coupled with one or more additional components, such as a wave or ocean model.
