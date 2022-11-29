.. _VXCases:

============================
Verification Sample Cases
============================

Introduction
===============

The goal of these sample cases is to provide the UFS community with datasets that they can modify and run to see if their changes can improve the forecast and/or reduce the model biases. Each case covers an interesting weather event. The case that was added with the v2.1.0 release was a severe weather event over Indianapolis on June 15-16, 2019. 

Each sample case contains module output from a control run, which consists of ``postprd`` (post-processed) and ``metprd`` (MET verification-processed) directories. Under the ``postprd`` directory, users will find the :term:`UPP` output of the model run along with plots for several forecast variables. These can be used for a visual/qualitative comparison of forecasts. The ``metprd`` directory contains METplus verification statistics files, which can be used for a quantitative comparison of forecast outputs. 

Indianapolis Severe Weather: 2019-06-16
==========================================

.. COMMENT: Why only 06-16 in heading? 

Description
--------------

A severe weather event over the Indianapolis Metropolitan Area during the summer of 2019 resulted from a frontal passage, which led to the development of isolated severe thunderstorms that subsequently organized into a convective squall line. The frontal line was associated with a vorticity maximum originating over the northern Great Plains that moved into an unstable environment over Indianapolis. The moist air remained over the southern part of the area on the following day, when the diurnal heating caused isolated thunderstorms producing small hail.

.. COMMENT: Edit above for clarity. 

There were many storm reports for this event with the majority of tornadoes and severe winds being reported on June 15th, while more severe hail was reported on June 16th. A link to the Storm Prediction Center's Storm Reports can be found here: 

   * `Storm Prediction Center Storm Report for 20190615 <https://www.spc.noaa.gov/climo/reports/190615_rpts.html>`__
   * `Storm Prediction Center Storm Report for 20190616 <https://www.spc.noaa.gov/climo/reports/190616_rpts.html>`__

Set Up Verification
======================

Follow the instructions below to reproduce this event using your own model setup! Make sure to install the latest version of the SRW Application (v2.1.0). ``develop`` branch code is constantly changing, so it does not provide a consistent baseline of comparison. 

#. **Get Data:** Download the ``Indy-Severe-Weather.tgz`` file using any of the following methods: 

   * Download directly from the S3 bucket using a browser. The data is available at https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#sample_cases/release-public-v2.1.0/.
   * From a terminal using the AWS command line interface (cli) if installed:

      .. code-block:: console

         aws s3 cp https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#sample_cases/release-public-v2.1.0/Indy-Severe-Weather.tgz Indy-Severe-Weather.tgz
   
   * From a terminal using wget: 

      .. code-block:: console

         wget https://noaa-ufs-srw-pds.s3.amazonaws.com/sample_cases/release-public-v2.1.0/Indy-Severe-Weather.tgz

   After downloading, untar the downloaded compressed archive file: 

   .. code-block:: console

      tar xvfz Indy-Severe-Weather.tgz

   Record the path to this file output by the ``pwd`` command: 
   
   .. code-block:: console 

      cd Indy-Severe-Weather
      pwd
   
#. Follow the instructions in :numref:`Section %s <UserSpecificConfig>` to set up the configuration file (``config.yaml``). First, navigate to the ``ufs-srweather-app/ush`` directory and copy the out-of-the-box configuration:

   .. code-block:: console

      cd </path/to/ufs-srweather-app/ush>
      cp config.community.yaml config.yaml
   
   where ``<path/to/ufs-srweather-app/ush>`` is replaced by the actual path to the ``ufs-srweather-app/ush`` directory on the user's system. 
   
   * Then, edit the ``config.yaml`` file substituting values in ``<>`` with values appropriate to your system. 
   
      .. note::
         Users working on a `Level 1 platform <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ do not need to add or update the following variables: ``MET_INSTALL_DIR``, ``METPLUS_PATH``, ``MET_BIN_EXEC``, ``CCPA_OBS_DIR``, ``MRMS_OBS_DIR``, and ``NDAS_OBS_DIR``
   
      .. note::
         To open a file, users may run the command: 

         .. code-block::console

            vi config.yaml
         
         To close and save, hit the ``esc`` key and type ``:wq``.

         Users may opt to use their preferred code editor and should modify the commands above accordingly. 
            
      .. code-block:: console

         user:
            ACCOUNT: <my_account>
         platform:
            MODEL: FV3_GFS_v16_SUBCONUS_3km
            # Example: MET_INSTALL_DIR: /contrib/met/10.1.1
            MET_INSTALL_DIR: </path/to/met/x.x.x>
            # Example: METPLUS_PATH: /contrib/METplus/METplus-4.1.1
            METPLUS_PATH: </path/to/METplus/METplus-x.x.x>
            # Add MET_BIN_EXEC variable to config.yaml
            MET_BIN_EXEC: bin
            CCPA_OBS_DIR: </path/to/Indy-Severe-Weather/obs_data/ccpa/proc>
            MRMS_OBS_DIR: </path/to/Indy-Severe-Weather/obs_data/mrms/proc>
            NDAS_OBS_DIR: </path/to/Indy-Severe-Weather/obs_data/ndas/proc>
         workflow:
            EXPT_SUBDIR: <any_name_you_like>
            DATE_FIRST_CYCL: '2019061500'
            DATE_LAST_CYCL: '2019061500'
            FCST_LEN_HRS: 60
         workflow_switches:
            RUN_TASK_VX_GRIDSTAT: true
            RUN_TASK_VX_POINTSTAT: true
         task_get_extrn_ics:
            # Add EXTRN_MDL_SOURCE_BASEDIR_ICS variable to config.yaml
            EXTRN_MDL_SOURCE_BASEDIR_ICS: </path/to/Indy-Severe-Weather/input_model_data/FV3GFS/grib2/2019061500>
            USE_USER_STAGED_EXTRN_FILES: true
         task_get_extrn_lbcs:
            # Add EXTRN_MDL_SOURCE_BASEDIR_LBCS variable to config.yaml
            EXTRN_MDL_SOURCE_BASEDIR_LBCS:  </path/to/Indy-Severe-Weather/input_model_data/FV3GFS/grib2/2019061500>
            USE_USER_STAGED_EXTRN_FILES: true
         task_run_fcst:
            WTIME_RUN_FCST: 03:00:00
            PREDEF_GRID_NAME: SUBCONUS_Ind_3km


Once the changes above are completed, load the regional workflow environment:

.. code-block:: console
   
   module use /path/to/ufs-srweather-app/modulefiles
   module load <your_env>

Generate experiment by running this command in the ush directory:

.. code-block:: console
   
   ./generate_FV3LAM_wflow.py

``cd`` into the experiment directory and run the launch script:

./launch_FV3LAM_wflow.sh

Keep running the launch script until the experiment completes. Refer to :ref:` Chapter %s: Rocoto <RocotoInfo>` if you run into any issues running this experiment.

Set Up Plots
---------------

The plots are created using the graphic generation script that comes with the SRW App. Instructions on how to run the script as well as information on the plots can be found here: https://ufs-srweather-app.readthedocs.io/en/release-public-v2.1.0/Graphics.html

Compare
----------

Once your experiment has completed, you can compare it against our experiment that ran from one of our release branches. 

If you do not already have the Indy-Severe-Weather tar file downloaded, please go `here <https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#sample_cases/release-public-v2.1.0/>`__. As mentioned earlier, this tar file contains the forecast output and plots under the ``postprd`` directory, and METplus verification files under the ``metprd`` directory. 

Comparing the plots is quite easy since they are in the png format and most computers can render them in their default image viewer. The following are the plots available every 6 hours for the forecast: 

.. table:: Sample Indianapolis Forecast Plots

   +-----------------------------------------+-----------------------------------+
   | Field                                   | File Name                         |
   +=========================================+===================================+
   | Sea level pressure                      | slp_conus_fhhh.png                |
   +-----------------------------------------+-----------------------------------+
   | Surface-based CAPE/CIN                  | sfcape_conus_fhhh.png             |
   +-----------------------------------------+-----------------------------------+
   | 2 meter temperature                     | 2mt_conus_fhhh.png                |
   +-----------------------------------------+-----------------------------------+
   | 2 meter dew point temperature           | 2mdew_conus_fhhh.png              |
   +-----------------------------------------+-----------------------------------+
   | 10 meter winds                          | 10mwind_conus_fhhh.png            |
   +-----------------------------------------+-----------------------------------+
   | 250 hPa winds                           | 250wind_conus_fhhh.png            |
   +-----------------------------------------+-----------------------------------+
   | 500 hPa heights, winds, and vorticity   | 500_conus_fhhh.png                |
   +-----------------------------------------+-----------------------------------+
   | Max/Min 2 - 5 km updraft helicity       | uh25_conus_fhhh.png               |
   +-----------------------------------------+-----------------------------------+
   | Composite reflectivity                  | refc_conus_fhhh.png               |
   +-----------------------------------------+-----------------------------------+
   | Accumulated precipitation               | qpf_conus_fhhh.png                |
   +-----------------------------------------+-----------------------------------+
   
METplus verification STAT files provide the user the opportunity to compare their model run to a baseline using quantitative measures. The file format is ``(grid|point)_stat_PREFIX_HHMMSSL_YYYYMMDD_HHMMSSV.stat``, where PREFIX indicates the user-defined output prefix, HHMMSSL indicates the forecast lead time and YYYYMMDD_HHMMSSV indicates the forecast valid time. The following is the list of METplus output files users can use during the comparison process:

.. COMMENT: Explain meaning of prefix, lead time, and valid time and/or give example

.. code-block:: console 
   
   point_stat_FV3_GFS_v16_SUBCONUS_3km_NDAS_ADPSFC_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   point_stat_FV3_GFS_v16_SUBCONUS_3km_NDAS_ADPUPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat

   grid_stat_FV3_GFS_v16_SUBCONUS_3km_REFC_MRMS_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_GFS_v16_SUBCONUS_3km_RETOP_MRMS_HHMMSSL_YYYYMMDD_HHMMSSV.stat

   grid_stat_FV3_GFS_v16_SUBCONUS_3km_APCP_01h_CCPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_GFS_v16_SUBCONUS_3km_APCP_03h_CCPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_GFS_v16_SUBCONUS_3km_APCP_06h_CCPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_GFS_v16_SUBCONUS_3km_APCP_24h_CCPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat

Point STAT Files
^^^^^^^^^^^^^^^^^^^

The point STAT files contain continuous variables like temperature, pressure, and wind speed. A description of the point STAT file can be found `here <https://met.readthedocs.io/en/latest/Users_Guide/point-stat.html#introduction>`__. 

The point STAT files contain quite a bit of information and could be overwhelming for the user to go through. To simplify this we suggest the users to focus on the CNT MET test which contains the `RMSE <https://met.readthedocs.io/en/latest/Users_Guide/appendixC.html#root-mean-squared-error-rmse>`__ and `MBIAS <https://met.readthedocs.io/en/latest/Users_Guide/appendixC.html?highlight=csi#multiplicative-bias>`__ statistics. The MET tests are defined in column 24 ‘LINE_TYPE’ of the STAT file. Look for ‘CNT’ in this column. Then find column 66-68 for MBIAS and 78-80 for RMSE statistics. A full description of this file can be found `here <https://met.readthedocs.io/en/latest/Users_Guide/point-stat.html#point-stat-output>`__.

.. COMMENT: Use/add intersphinx to link to MET docs?

To narrow down the variable field even further, we suggest that users focus on these weather variables: 

   * 250 mb - wind speed, temperature
   * 500 mb - wind speed, temperature
   * 700 mb - wind speed, temperature, relative humidity
   * 850 mb - wind speed, temperature, relative humidity
   * Surface  - wind speed, temperature, pressure, dewpoint

**Interpretation:**

* A lower RMSE indicates that the model forecast value is closer to the observation value.
* If MBIAS > 1, then the forecast is too high on average by (MBIAS - 1)%. If MBIAS < 1, then the forecast is too low on average by (1 - MBIAS)%.

Grid STAT Files
^^^^^^^^^^^^^^^^^^^

The grid STAT files contain gridded variables like reflectivity and precipitation. A description of the grid STAT file can be found `here <https://met.readthedocs.io/en/latest/Users_Guide/grid-stat.html#introduction>`__. 

As with the point STAT file, there are several MET tests and statistics in the grid STAT file. Again, to simplify this dataset we suggest that users focus on the MET tests and statistics found in the table below. As before, the MET tests are found in column 24 ‘LINE_TYPE’ of the grid STAT file. The table also shows the user the columns for the statistics of interest. For a more detailed description of the grid STAT files look here: 11. Grid-Stat Tool — MET 10.1.2 documentation

.. table:: Grid-Stat Statistics

   +----------------+----------+-----------------+----------------------+
   | File Type      | MET Test | Statistic       | Statistic Column     |
   +================+==========+=================+======================+
   | APCP           | NBRCTS   | FBIAS           | 41-43                |
   +----------------+----------+-----------------+----------------------+
   | APCP           | NBRCNT   | FSS             | 29-31                |
   +----------------+----------+-----------------+----------------------+
   | REFC and RETOP | NBRCTS   | FBIAS, FAR, CSI | 41-43, 59-63, 64-68  |
   +----------------+----------+-----------------+----------------------+

**Interpretation:**

* If FBIAS > 1, then the event is over forecast. If FBIAS < 1, then the event is under forecast. If 1, then the forecast matched the observation.

.. COMMENT: What does over or under forecast mean?

* FSS values > 0.5 indicates a useful score. On a scale from 0 to 1 with 0 being no overlap between forecast and observation and 1 being a complete overlap.
* FAR ranges from 0 to 1; a perfect forecast would have FAR = 0 with 1 indicating no skill in the forecast.
* CSI ranges from 0 to 1, with 1 being a perfect forecast and 0 representing no skill in the forecast.
