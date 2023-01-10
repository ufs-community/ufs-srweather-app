.. _Tutorial:

=============
Tutorials
=============

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

   * `Storm Prediction Center (SPC) Storm Report for 20190615 <https://www.spc.noaa.gov/climo/reports/190615_rpts.html>`__ 
   * `Storm Prediction Center (SPC) Storm Report for 20190616 <https://www.spc.noaa.gov/climo/reports/190616_rpts.html>`__

.. COMMENT: Radar Loop: include image from Google doc
   See https://mesonet.agron.iastate.edu/current/mcview.phtml to produce images.

Data
-------

The data required for this experiment is the same data used for the Indy-Sever-Weather Verification sample case described in :numref:`Chapter %s <VXCases>`. It is already available on `Level 1 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems (see :numref:`Section %s<Data>` for locations) and can be downloaded from the `UFS SRW Application Data Bucket <https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html>`__. 

.. Or should this be the Indy-Severe-Weather data? Specify where in the bucket the data is!
   https://noaa-ufs-srw-pds.s3.amazonaws.com/sample_cases/release-public-v2.1.0/Indy-Severe-Weather.tgz

   NEED HRRR/RAP data for this tutorial! 

Load the Regional Workflow
-------------------------------

Navigate to the ``ufs-srweather-app/ush`` directory. Then, load the regional workflow environment:

.. code-block:: console
   
   source <path/to/etc/lmod-setup.sh>
   # OR: source <path/to/etc/lmod-setup.csh> when running in a csh/tcsh shell
   module use </path/to/ufs-srweather-app/modulefiles>
   module load wflow_<platform>

After loading the workflow, users should follow the instructions printed to the console. Usually, the instructions will tell the user to run ``conda activate regional_workflow``. 

Configuration
-------------------------

The default (or "control") configuration for this experiment is the ``config.community.yaml`` file. Users can copy this file into ``config.yaml`` if they have not done so already:

.. code-block:: console

   cd </path/to/ufs-srweather-app/ush>
   cp config.community.yaml config.yaml

Then, edit the configuration file (``config.yaml``) to include the variables and values in the sample configuration excerpts below. 

Experiment 1: Control
^^^^^^^^^^^^^^^^^^^^^^^^

Start in the ``user:`` section and change the ``MACHINE`` and ``ACCOUNT`` variables. For example, when running on a personal MacOS device, users might set:

.. code-block:: console

   user:
      RUN_ENVIR: community
      MACHINE: macos
      ACCOUNT: none

For this tutorial, users do not need to change the ``platform:`` section. The default parameters in this section pertain to METplus verification, which is not addressed here. For more information on verification, see :numref:`Chapter %s <VXCases>`.

In the ``workflow:`` section of ``config.yaml``, update ``EXPT_SUBDIR``, ``PREDEF_GRID_NAME``, ``DATE_FIRST_CYCL``, ``DATE_LAST_CYCL``, and ``FCST_LEN_HRS``.

.. code-block:: console

   workflow:
     USE_CRON_TO_RELAUNCH: false
     EXPT_SUBDIR: control
     CCPP_PHYS_SUITE: FV3_GFS_v16
     PREDEF_GRID_NAME: SUBCONUS_Ind_3km
     DATE_FIRST_CYCL: '2019061500'
     DATE_LAST_CYCL: '2019061500'
     FCST_LEN_HRS: 60
     PREEXISTING_DIR_METHOD: rename
     VERBOSE: true
     COMPILER: intel

``EXPT_SUBDIR`` can be changed to any name the user wants. This tutorial uses ``control`` to establish a baseline, or "control", experiment. However, users can choose any name they want, from "gfsv16_physics_fcst" to "forecast1" to "a;skdfj". However, the best names will indicate useful information about the experiment. For example, this tutorial helps users to compare the output from two different forecasts: one that uses the FV3_GFS_v16 physics suite and one that uses the FV3_RRFS_v1beta physics suite. Therefore, "gfsv16_physics_fcst" could be a good alternative.

.. COMMENT: for EXPT_SUBDIR, are there certain characters that aren't allowed?

This experiment uses the SUBCONUS_Ind_3km grid, rather than the default RRFS_CONUS_25km grid. The SUBCONUS_Ind_3km grid is a high-resolution grid (with grid cell size of approximately 3-km) that covers a small area of the U.S. centered over Indianapolis, IN. For more information on this grid, see :numref:`Section %s <SUBCONUS_Ind_3km>`.

In this experiment, ``DATE_FIRST_CYCL`` and ``DATE_LAST_CYCL`` are the same: June 15, 2019. A cycle refers to the hour of the day on which a forecast is started. This experiment has a single cycle. Multiple cycles are typically used with :term:`data assimilation` to update/adjust a forecast based on new data/observations. 

.. COMMENT: Edit above section on reasoning for cycles
   Maybe the event they are researching is a long-lived event and the user wants to know how the 6, 12, 18 models handled the event or maybe they wanted to see which cycle picked up on the atmospheric changes that lead to an evening's severe thunderstorms. To me, these vars exists so the user won't have to rerun an experiment x-number times, they can run it just once with the cycles they want. 

   Multiple cycles can also be used in research...

In the ``workflow_switches:`` section, turn the plotting task on by changing ``RUN_TASK_PLOT_ALLVARS`` to true. This section of ``config.yaml`` will look like this:

.. code-block:: console

   workflow_switches:
     RUN_TASK_MAKE_GRID: true
     RUN_TASK_MAKE_OROG: true
     RUN_TASK_MAKE_SFC_CLIMO: true
     RUN_TASK_GET_OBS_CCPA: false
     RUN_TASK_GET_OBS_MRMS: false
     RUN_TASK_GET_OBS_NDAS: false
     RUN_TASK_VX_GRIDSTAT: false
     RUN_TASK_VX_POINTSTAT: false
     RUN_TASK_VX_ENSGRID: false
     RUN_TASK_VX_ENSPOINT: false
     RUN_TASK_PLOT_ALLVARS: true

In the ``task_get_extrn_ics:`` section, add ``USE_USER_STAGED_EXTRN_FILES`` and ``EXTRN_MDL_SOURCE_BASEDIR_ICS``. Users will need to adjust the file path to reflect the location of data on their system (see :numref:`Section %s <Data>` for locations on Level 1 systems). This section of the ``config.yaml`` file will look like this:

.. code-block:: console

   task_get_extrn_ics:
     EXTRN_MDL_NAME_ICS: FV3GFS
     FV3GFS_FILE_FMT_ICS: grib2
     USE_USER_STAGED_EXTRN_FILES: true
     EXTRN_MDL_SOURCE_BASEDIR_ICS: </path/to/UFS_SRW_App/develop/input_model_data/FV3GFS/grib2/${yyyymmddhh}>
   
Similarly, in the ``task_get_extrn_lbcs:`` section, add ``USE_USER_STAGED_EXTRN_FILES`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS``. Users will need to adjust the file path to reflect the location of data on their system (see :numref:`Section %s <Data>` for locations on Level 1 systems). This section of the ``config.yaml`` file will look like this:

.. code-block:: console

   task_get_extrn_lbcs:
     EXTRN_MDL_NAME_LBCS: FV3GFS
     LBC_SPEC_INTVL_HRS: 6
     FV3GFS_FILE_FMT_LBCS: grib2
     USE_USER_STAGED_EXTRN_FILES: true
     EXTRN_MDL_SOURCE_BASEDIR_LBCS: </path/to/UFS_SRW_App/develop/input_model_data/FV3GFS/grib2/${yyyymmddhh}>

In the ``task_run_fcst:`` section, change the forecast walltime (``WTIME_RUN_FCST``) from 2:00:00 to 4:00:00. If the ``run_fcst`` task takes longer than four hours to run, it will go DEAD. However, four hours should be more than enough time to run this particular forecast. Depending on the system in use, two hours may be insufficient. This section of the ``config.yaml`` should appear as follows:

.. code-block:: console

   task_run_fcst:
     WTIME_RUN_FCST: 04:00:00
     QUILTING: true

Lastly, in the ``task_plot_allvars:`` section, add ``PLOT_FCST_INC`` and set it to 6. Users may also want to add ``PLOT_FCST_START`` and ``PLOT_FCST_END`` explicitly, but these can be omitted since the values below are the same as the default values. The settings below will generate a ``.png`` file for every 6th forecast hour starting from 00z on June 15, 2019 through the 60th forecast hour (June 17, 2019 at 12z).

.. code-block:: console

   task_plot_allvars:
     COMOUT_REF: ""
     PLOT_FCST_START: 0
     PLOT_FCST_INC: 6
     PLOT_FCST_END: 60

After configuring the forecast, users can generate the forecast by running:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

To see experiment progress, users should navigate to their experiment directory. Then, use the ``rocotorun`` command to launch new workflow tasks and ``rocotostat`` to check on experiment progress. 

.. code-block:: console

   cd </path/to/expt_dirs/control>
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Experiment 2: Comparison
---------------------------

Once the control case is running, users can return to the ``config.yaml`` file (in ``ufs-srweather-app/ush``) and adjust the parameters for a new forecast. Most of the variables will remain the same. However, users will need to adjust ``EXPT_SUBDIR`` and ``CCPP_PHYS_SUITE`` in the ``workflow`` section as follows:

.. code-block:: console

   workflow:
     EXPT_SUBDIR: test_expt
     CCPP_PHYS_SUITE: FV3_RRFS_v1beta

Additionally, users will need to modify the data parameters in ``task_get_extrn_ics:`` and ``task_get_extrn_lbcs:`` to use HRRR and RAP data rather than FV3GFS data:

.. code-block:: console

   task_get_extrn_ics:
     EXTRN_MDL_NAME_ICS: HRRR
     EXTRN_MDL_SOURCE_BASEDIR_ICS: </path/to/UFS_SRW_App/develop/input_model_data/HRRR/grib2/${yyyymmddhh}>
   task_get_extrn_lbcs:
     EXTRN_MDL_NAME_LBCS: RAP
     EXTRN_MDL_SOURCE_BASEDIR_LBCS: </path/to/UFS_SRW_App/develop/input_model_data/RAP/grib2/${yyyymmddhh}>

.. COMMENT: Why do we use HRRR/RAP data with FV3_RRFS_v1beta?

Lastly, users must set the ``COMOUT_REF`` variable in the ``task_plot_allvars:`` section to create difference plots that compare output from the two experiments. ``COMOUT_REF`` is a template variable, so it references other workflow variables within it (see :numref:`Section %s <TemplateFiles>` for details on template variables). The path to the forecast output must be set using single quotes as shown below:

.. code-block:: console

   task_plot_allvars:
     COMOUT_REF: '${EXPT_BASEDIR}/${EXPT_SUBDIR}/${PDY}${cyc}/postprd'

Setting ``COMOUT_REF`` this way (i.e., using ``$EXPT_SUBDIR``) ensures that the plotting task can access the forecast output data in both the ``control`` directory and the ``test_expt`` directory. ``$PDY`` refers to the cycle date in YYYYMMDD format, and ``$cyc`` refers to the starting hour of the cycle. ``postprd`` contains the post-processed data from the experiment. Therefore, ``COMOUT_REF`` will refer to both ``control/2019061500/postprd`` and ``test_expt/2019061500/postprd``. 

Compare Results
-------------------

Navigate to ``test_expt/2019061500/postprd``. 




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

Coming soon! 

.. COMMENT: 
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

.. COMMENT: 
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

Coming soon! 

.. COMMENT: 

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

.. COMMENT:

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