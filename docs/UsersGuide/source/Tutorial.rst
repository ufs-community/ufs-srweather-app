.. _Tutorial:

==================================
SRW Application Tutorial
==================================

This chapter walks users through experiment configuration options for various severe weather events. It assumes that users have already (1) built the SRW App successfully and (2) run the out-of-the-box case contained in the ``config.community.yaml`` (and copied to ``config.yaml`` in :numref:`Step %s <QuickBuildRun>` or :numref:`Step %s <UserSpecificConfig>`) to completion. 

Users can run through the entire set of tutorials or jump to the one that interests them most. The five tutorials address different skills:

   #. :ref:`Severe Weather Over Indianapolis <fcst1>`
   #. :ref:`Hurricane Barry <fcst2>`
   #. :ref:`Cold Air Damming <fcst3>`
   #. :ref:`Southern Plains Winter Weather Event <fcst4>`
   #. :ref:`Halloween Storm <fcst5>`

Each section provides a summary of the weather event and instructions for configuring an experiment. 

.. COMMENT: See sample forecast case details in this Google doc: https://docs.google.com/document/d/1TFjSAyI3jBmhzfZBmlIZz5NonBDDTi8x_-g-QVbvMOo/edit

.. _fcst1:

Sample Forecast #1: Severe Weather Over Indianapolis
=======================================================

**Objective:** Modify physics options and compare forecast outputs. 

Weather Summary
--------------------

A surface boundary associated with a vorticity maximum over the northern Great Plains moved into an unstable environment over Indianapolis, which led to the development of isolated severe thunderstorms before it congealed into a convective line. The moist air remained over the southern half of the area on the following day. The combination of moist air with daily surface heating resulted in isolated thunderstorms that produced small hail. 

**Weather Phenomena:** Numerous tornado and wind reports (6/15) and hail reports (6/16)
**Storm Prediction Center (SPC) Storm Reports:** 
   * For `20190615 <https://www.spc.noaa.gov/climo/reports/190615_rpts.html>`__ 
   * For `20190616 <https://www.spc.noaa.gov/climo/reports/190616_rpts.html>`__

.. COMMENT: Radar Loop: include image from Google doc
   See https://mesonet.agron.iastate.edu/current/mcview.phtml to produce images.

Data
-------

The data required for this experiment is the same data used for the out-of-the-box case described in :numref:`Chapter %s <RunSRW>`. It is already available on Level 1 systems (see :numref:`Section %s<Data>` for locations) and can be downloaded from the `UFS SRW Application Data Bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`. 

.. Or should this be the Indy-Severe-Weather data?

Load the Regional Workflow
-------------------------------

Navigate to the ``ufs-srweather-app/ush`` directory. Then, load the regional workflow environment:

.. code-block:: console
   
   source <path/to/etc/lmod-setup.sh>
   module use </path/to/ufs-srweather-app/modulefiles>
   module load wflow_<platform>

Users running a csh/tcsh shell would run ``source <path/to/etc/lmod-setup.csh>`` in place of the first command above. 

After loading the workflow, users should follow the instructions printed to the console. Usually, the instructions will tell the user to run ``conda activate regional_workflow``. 

General Configuration
-------------------------

The default (or "control") configuration for this experiment is the ``config.community.yaml`` file. Users can copy this file into ``config.yaml`` if they have not done so already:

.. code-block:: console

   cd </path/to/ufs-srweather-app/ush>
   cp config.community.yaml config.yaml

Then, edit the configuration file (``config.yaml``) to include the variables and values in the sample configuration excerpt below (variables not listed below do not need to be changed or removed). Users must be sure to substitute values in ``<>`` with values appropriate to their system. 

.. COMMENT: 
   When (fcst start time): 2019-06-16 00z
   Config information
   MACHINE: jet
   PREDEF_GRID_NAME: SUBCONUS_Ind_3km
   CCPP_PHYS_SUITE: FV3_GFS_v16
   FCST_LEN_HRS: 60
   EXTRN_MDL_NAME_ICS: FV3GFS
   EXTRN EXTRN_MDL_NAME_LBCS: FV3GFS
   FV3GFS_FILE_FMT_ICS/LBCS: grib2
   WTIME_RUN_FCST="04:00:00"
   EXTRN_MDL_FILES_ICS: /mnt/lfs4/BMC/wrfruc/UFS_SRW_App/v2p0/input_model_data/FV3GFS/grib2/2019061500
   EXTRN_MDL_FILES_LBCS: /mnt/lfs4/HFIP/hfv3gfs/Edward.Snyder/SRW-Sample-Case-Indy/expt_dirs/gfs-data

Experiment 1
----------------

Experiment 2
----------------

Compare Results
-------------------

Analysis
-----------

.. COMMENT:
   What to compare?
   This is a new UFS Case Study so there isn’t a predefined analysis. Examining the mid-level and surface dynamics along with convective variables would be a good place to start. 
   Things still needed:
   We will need HRRR and RAP ICs for this test case, if we want to run the case with the RRFS_v1beta physics suite.



.. _fcst2:

Sample Forecast #2: Hurricane Barry
=======================================

**Objective:**

Weather Summary
--------------------

WX Summary: Hurricane Barry made landfall in Louisiana on July 11th as a category one hurricane. It produced widespread flooding in the region and had a peak wind speed of 72 mph and minimum pressure of 992 hPa. 
Weather phenomena: Flooding, and wind and tornado reports
SPC Storm Reports: Storm Prediction Center 20190713's Storm Reports (noaa.gov) & Storm Prediction Center 20190714's Storm Reports (noaa.gov)
Radar Loop: https://en.wikipedia.org/wiki/Hurricane_Barry_(2019)#/media/File:Barry_making_landfall.gif

Data
-------


Configuration
----------------

.. COMMENT:
   When (fcst start time): 2019-07-12 00z
   Config information
   MACHINE: 
   PREDEF_GRID_NAME: 
   CCPP_PHYS_SUITE: 
   FCST_LEN_HRS: 
   EXTRN_MDL_NAME_ICS: 
   EXTRN EXTRN_MDL_NAME_LBCS: 
   FV3GFS_FILE_FMT_ICS/LBCS: nemsio
   WTIME_RUN_FCST="04:00:00"
   EXTRN_MDL_FILES_ICS: 
   EXTRN_MDL_FILES_LBCS: 

Analysis
-----------

.. COMMENT:
   What to compare?
   This is an existing case from the UFS Case Studies. Compare hurricane track, intensity, and wind speed after landfall. We can also compare satellite imagery too.
   Things still needed:
   We will need a new subconus domain over LA. We have nemsio IC data, which would work for the GFS_v16 physics suite, but we will need HRRR and RAP ICs if we want to use the RRFS_v1beta physics suite.




.. _fcst3:

Sample Forecast #3: Cold Air Damming
========================================

**Objective:**

Weather Summary
--------------------


WX Summary: Cold air damming occurs when cold dense air is topographically trapped along the leeward side of the mountain.
Weather phenomena: Cold air damming
SPC Storm Reports: N/A
Radar Loop: N/A

Data
-------


Configuration
----------------

.. COMMENT:
   When (fcst start time): 2020-02-03 12z
   Config information
   MACHINE: 
   PREDEF_GRID_NAME: 
   CCPP_PHYS_SUITE: 
   FCST_LEN_HRS: 
   EXTRN_MDL_NAME_ICS: 
   EXTRN EXTRN_MDL_NAME_LBCS: 
   FV3GFS_FILE_FMT_ICS/LBCS: 
   WTIME_RUN_FCST="04:00:00"
   EXTRN_MDL_FILES_ICS: 
   EXTRN_MDL_FILES_LBCS: 


Analysis
-----------

.. COMMENT:
   What to compare?
   This is an existing case from the UFS Case Studies. Compare surface temperature and wind speed.
   Things still needed:
   We will need a new subconus domain over the southeast. We have nemsio IC data, which would work for the GFS_v16 physics suite. We also have access to the HRRR and RAP ICs through a provided script.




.. _fcst4:

Sample Forecast #4: Southern Plains Winter Weather Event
===========================================================

**Objective:**

Weather Summary
--------------------

WX Summary: A polar vortex brought arctic air to much of the US including Mexico. A series of cold fronts and vorticity disturbances helped keep this cold air in place for an extended period of time resulting in record-breaking cold temperatures for many southern states and Mexico. This particular case captures two winter weather disturbances that brought several inches of snow to OKC with a lull on February 16th which resulted in the daily record low being broken and is the second coldest temperature on record for OKC.
Weather phenomena: Snow and record-breaking cold temperatures
SPC Storm Reports: N/A
Radar Loop: 

Data
-------


Configuration
----------------
.. COMMENT:
   When (fcst start time): 2021-02-15 00z
   Config information
   MACHINE: 
   PREDEF_GRID_NAME: 
   CCPP_PHYS_SUITE: 
   FCST_LEN_HRS: 
   EXTRN_MDL_NAME_ICS: 
   EXTRN EXTRN_MDL_NAME_LBCS: 
   FV3GFS_FILE_FMT_ICS/LBCS: 
   WTIME_RUN_FCST="04:00:00"
   EXTRN_MDL_FILES_ICS: 
   EXTRN_MDL_FILES_LBCS: 


Analysis
-----------
.. COMMENT:
   What to compare?
   This isn’t an existing UFS Case Study, so initial analysis of various variables like surface temperature, jet stream, and precipitation type should all be considered.
   Things still needed:
   We will need a new subconus domain over the southern plains, and to collect the FV3GFS, HRRR, and RAP ICs.




.. _fcst5:

Sample Forecast #5: Halloween Storm
=======================================

**Objective:**

Weather Summary
--------------------

WX Summary: A line of severe storms brought strong winds, flash flooding, and tornadoes to the eastern half of the US.
Weather phenomena: Snow and record-breaking cold temperatures
SPC Storm Reports: 
Radar Loop: 


Data
-------



Configuration
----------------
.. COMMENT:
   When (fcst start time): 2019-10-28 12Z
   Config information
   MACHINE: 
   PREDEF_GRID_NAME: 
   CCPP_PHYS_SUITE: 
   FCST_LEN_HRS: 
   EXTRN_MDL_NAME_ICS: 
   EXTRN EXTRN_MDL_NAME_LBCS: 
   FV3GFS_FILE_FMT_ICS/LBCS: 
   WTIME_RUN_FCST="04:00:00"
   EXTRN_MDL_FILES_ICS: 
   EXTRN_MDL_FILES_LBCS: 


Analysis
-----------

.. COMMENT: 
   What to compare?
   This is an existing UFS Case Study. Look at the synoptic dynamics, surface wind and temperatures, and moisture profiles.
   Things still needed:
   We will need a new subconus domain over the north east. We have nemsio IC data, which would work for the GFS_V16 physics suite. We also have access to the HRRR and RAP ICs through a provided script.









.. COMMENT: TICKET INFO (AUS-220)
   Add forecast grading capability. SRW sample forecasts graded accorded to skill - come up with a framework so that people can try running the same forecast with their changes

   Goal: users can download everything they need, they have exactly the configuration we use to generate the forecast, they have our forecasts, and some tools to judge the skill of the forecast. 

   Start with small, high resolution case (like Indianapolis) 200x200 so we can run tests cases. If it shows promise then we can run at 3km.
   Jeff/Curtis/Jacob/Ligia can help determine good cases to run
   How long to run the forecast - 3-6 hours?
   Identify and setup the input data needed to run those scenarios
   Data fetch from HPSS
   Generate grids - can move the center lat/lon of the Indy grid - day or two x4
   Boundary conditions - make sure model includes the grid
   Fix files
   Dates boundary and initial conditions
   Observations for those dates
   Make the input data publicly available
   Run each scenario and post the forecast results somewhere
   Determine how to determine skill - can we use the scorecards (usually done on ensemble forecasts)? POC - Jeff, Michelle Herald, Will Mayfield, Mike Kavulich
   Implement & document skill determination
   Documentation