.. _Glossary:

*************************
Glossary
*************************

.. glossary::

   CCPP
      Model agnostic, vetted, collection of codes containing atmospheric physical parameterizations
      and suites for use in NWP along with a framework that connects the physics to host models

   chgres_cube
       The preprocessing software used to create initial condition files to “coldstart” the forecast
       model. The initial conditions are created from either GFS GRIB2 or NEMSIO data.

   FV3
      The GFDL Finite-Volume Cubed-Sphere Dynamical Core (FV3) is a scalable and flexible dynamical
      core capable of both hydrostatic and non-hydrostatic atmospheric simulations.

   NCEP
      National Centers for Environmental Prediction, an arm of the National Weather Service.

   NCEPLIBS
      The NCEP library source code and utilities required for chgres_cube, the UFS Weather Model, and UPP.

   NCEPLIBS-external
      A collection of third-party libraries required to build NCEPLIBS, chgres_cube, the UFS Weather Model, and UPP.

   NCL
      An interpreted language designed specifically for scientific data analysis and visualization.
      More information can be found at https://www.ncl.ucar.edu.

   NEMS
      The NOAA Environmental Modeling System - a software infrastructure that supports
      NCEP/EMC’s forecast products.

   NEMSIO
      A binary format for atmospheric model output on the native gaussian grid.

   UFS
      A Unified Forecast System (UFS) is a community-based, coupled comprehensive Earth
      system modeling system. The UFS numerical applications span local to global domains
      and predictive time scales from sub-hourly analyses to seasonal predictions. It is
      designed to support the Weather Enterprise and to be the source system for NOAA's
      operational numerical weather prediction applications

   UPP
      The Unified Post Processing System, developed at NCEP and used operationally for models
      maintained by NCEP. The UPP has the capability to post-process output from a variety of NWP
      models, including FV3.

   Weather Model
      A prognostic model that can be used for short- and medium-range research and
      operational forecasts. It can be an atmosphere-only model or be an atmospheric
      model coupled with one or more additional components, such as a wave or ocean model.
