.. _VXCases:

===================================
METplus Verification Sample Cases
===================================

Introduction
===============

The goal of these sample cases is to provide the UFS community with datasets that they can modify and run to see if their changes can improve the forecast and/or reduce the model biases. Each case covers an interesting weather event. The case that was added ahead of the v2.1.0 release was a severe weather event over Indianapolis on June 15-16, 2019. Content was updated for the v2.2.0 release. In the future, additional sample cases will be provided. 

Each sample case contains model output from a control run; this output includes ``postprd`` (post-processed) and ``metprd`` (MET verification-processed) directories. Under the ``postprd`` directory, users will find the :term:`UPP` output of the model run along with plots for several forecast variables (when plotting tasks are run). These can be used for a visual/qualitative comparison of forecasts. The ``metprd`` directory contains METplus verification statistics files, which can be used for a quantitative comparison of forecast outputs. 

Prerequisites
================

This chapter assumes that users have already (1) built the SRW App |latestr| release successfully and (2) installed MET and METplus on their system (e.g., as part of :term:`spack-stack` installation). For instructions on how to build the |latestr| release, see :numref:`Section %s <BuildSRW>`. Users will have an easier time if they run through the out-of-the-box case described in :numref:`Section %s <RunSRW>` before attempting to run any verification sample cases, but doing so is optional.

For information on MET and METplus, see :numref:`Section %s <MetplusComponent>`, which contains information on METplus, links to a list of existing MET/METplus builds on :srw-wiki:`Level 1 & 2 <Supported-Platforms-and-Compilers>` systems, and links to installation instructions and documentation for users on other systems. 

Indianapolis Severe Weather Case
==========================================

Description
--------------

A severe weather event over the Indianapolis Metropolitan Area in June 2019 resulted from a frontal passage that led to the development of isolated severe thunderstorms. These thunderstorms subsequently congealed into a convective squall line. The frontal line was associated with a vorticity maximum originating over the northern Great Plains that moved into an unstable environment over Indianapolis. The moist air remained over the southern part of the area on the following day, when the diurnal heating caused isolated thunderstorms producing small hail.

There were many storm reports for this event with the majority of tornadoes and severe winds being reported on June 15th, while more severe hail was reported on June 16th. A link to the Storm Prediction Center's Storm Reports can be found here: 

   * `Storm Prediction Center Storm Report for 20190615 <https://www.spc.noaa.gov/climo/reports/190615_rpts.html>`__
   * `Storm Prediction Center Storm Report for 20190616 <https://www.spc.noaa.gov/climo/reports/190616_rpts.html>`__

Set Up Verification
-----------------------

Follow the instructions below to reproduce a forecast for this event using your own model setup! Make sure to install and build the latest version of the SRW Application (|latestr|). ``develop`` branch code is constantly changing, so it does not provide a consistent baseline for comparison.

.. _GetSampleData:

Get Data
^^^^^^^^^^^

On :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems, users can find data for the Indianapolis Severe Weather Forecast in the usual data locations (see :numref:`Section %s <DataLocations>` for a list). 

On other systems, users need to download the ``Indy-Severe-Weather.tgz`` file using any of the following methods: 

   #. Download directly from the S3 bucket using a browser. The data is available at https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#sample_cases/release-public-v2.2.0/.

   #. Download from a terminal using the AWS command line interface (CLI), if installed:

      .. code-block:: console

         aws s3 cp https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#sample_cases/release-public-v2.2.0/Indy-Severe-Weather.tgz Indy-Severe-Weather.tgz
   
   #. Download from a terminal using ``wget``: 

      .. code-block:: console

         wget https://noaa-ufs-srw-pds.s3.amazonaws.com/sample_cases/release-public-v2.2.0/Indy-Severe-Weather.tgz

This tar file contains :term:`IC/LBC <ICs/LBCs>` files, observation data, model/forecast output, and MET verification output for the sample forecast. Users who have never run the SRW App on their system before will also need to download (1) the fix files required for SRW App forecasts and (2) the NaturalEarth shapefiles required for plotting. Users can download the fix file data from a browser at https://noaa-ufs-srw-pds.s3.amazonaws.com/current_srw_release_data/fix_data.tgz or visit :numref:`Section %s <StaticFixFiles>` for instructions on how to download the data with ``wget``. NaturalEarth files are available at https://noaa-ufs-srw-pds.s3.amazonaws.com/NaturalEarth/NaturalEarth.tgz. See the :numref:`Section %s <PlotOutput>` for more information on plotting. 

After downloading ``Indy-Severe-Weather.tgz`` using one of the three methods above, untar the downloaded compressed archive file: 

.. code-block:: console

   tar xvfz Indy-Severe-Weather.tgz

Save the path to this file in and ``INDYDATA`` environment variable:
   
.. code-block:: console 

   cd Indy-Severe-Weather
   export INDYDATA=$PWD

.. note::

   Users can untar the fix files and Natural Earth files by substituting those file names in the commands above. 

Load the Workflow
^^^^^^^^^^^^^^^^^^^^

First, navigate to the ``ufs-srweather-app/ush`` directory. Then, load the workflow environment:

.. code-block:: console
   
   source /path/to/etc/lmod-setup.sh <platform>
   module use /path/to/ufs-srweather-app/modulefiles
   module load wflow_<platform>

Users running a csh/tcsh shell would run ``source /path/to/etc/lmod-setup.csh <platform>`` in place of the first command above. 

After loading the workflow, users should follow the instructions printed to the console. Usually, the instructions will tell the user to run |activate|. 

Configure the Verification Sample Case
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Once the workflow environment is loaded, copy the out-of-the-box configuration:

.. code-block:: console

   cd /path/to/ufs-srweather-app/ush
   cp config.community.yaml config.yaml
   
where ``/path/to/ufs-srweather-app/ush`` is replaced by the actual path to the ``ufs-srweather-app/ush`` directory on the user's system. 
   
Then, edit the configuration file (``config.yaml``) to include the variables and values in the sample configuration excerpt below (variables not listed below do not need to be changed or removed). Users must be sure to substitute values in ``<>`` with values appropriate to their system.  

.. note::
   Users working on a :srw-wiki:`Level 1 platform <Supported-Platforms-and-Compilers>` do not need to add or update the following variables: ``CCPA_OBS_DIR``, ``MRMS_OBS_DIR``, and ``NDAS_OBS_DIR``.

.. code-block:: console

   user:
      MACHINE: <your_machine_name>
      ACCOUNT: <my_account>
   platform:
      MODEL: FV3_GFS_v16_SUBCONUS_3km
      MET_INSTALL_DIR: /path/to/met/x.x.x           # Example: MET_INSTALL_DIR: /contrib/met/10.1.1
      METPLUS_PATH: /path/to/METplus/METplus-x.x.x  # Example: METPLUS_PATH: /contrib/METplus/METplus-4.1.1
      # Add MET_BIN_EXEC variable to config.yaml
      MET_BIN_EXEC: bin
      CCPA_OBS_DIR: /path/to/Indy-Severe-Weather/obs_data/ccpa/proc
      MRMS_OBS_DIR: /path/to/Indy-Severe-Weather/obs_data/mrms/proc
      NDAS_OBS_DIR: /path/to/Indy-Severe-Weather/obs_data/ndas/proc
   workflow:
      EXPT_SUBDIR: <any_name_you_like>
      CCPP_PHYS_SUITE: FV3_RRFS_v1beta
      PREDEF_GRID_NAME: SUBCONUS_Ind_3km
      DATE_FIRST_CYCL: '2019061500'
      DATE_LAST_CYCL: '2019061500'
      FCST_LEN_HRS: 60
      # Change to gnu if using a gnu compiler; otherwise, no change
      COMPILER: intel
   task_get_extrn_ics:
      # Add EXTRN_MDL_SOURCE_BASEDIR_ICS variable to config.yaml
      EXTRN_MDL_SOURCE_BASEDIR_ICS: /path/to/Indy-Severe-Weather/input_model_data/FV3GFS/grib2/2019061500
      USE_USER_STAGED_EXTRN_FILES: true
   task_get_extrn_lbcs:
      # Add EXTRN_MDL_SOURCE_BASEDIR_LBCS variable to config.yaml
      EXTRN_MDL_SOURCE_BASEDIR_LBCS: /path/to/Indy-Severe-Weather/input_model_data/FV3GFS/grib2/2019061500
      USE_USER_STAGED_EXTRN_FILES: true
   task_plot_allvars:
     PLOT_FCST_INC: 6
     PLOT_DOMAINS: ["regional"]
   verification:
     VX_FCST_MODEL_NAME: FV3_RRFS_v1beta_SUBCONUS_Ind_3km
   rocoto:
     tasks:
       metatask_run_ensemble:
         task_run_fcst_mem#mem#:
           walltime: 02:00:00
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/plot.yaml", "parm/wflow/verify_pre.yaml", "parm/wflow/verify_det.yaml"]|include }}'

.. hint::
   To open the configuration file in the command line, users may run the command: 

   .. code-block:: console

      vi config.yaml
         
   To modify the file, hit the ``i`` key and then make any changes required. To close and save, hit the ``esc`` key and type ``:wq``. Users may opt to use their preferred code editor instead. 

For additional configuration guidance, refer to the |latestr| release documentation on :ref:`configuring the SRW App <srw_v2.2.0:UserSpecificConfig>`.

Generate the Experiment
^^^^^^^^^^^^^^^^^^^^^^^^^^

Generate the experiment by running this command from the ``ush`` directory:

.. code-block:: console
   
   ./generate_FV3LAM_wflow.py

Run the Experiment
^^^^^^^^^^^^^^^^^^^^^

Navigate (``cd``) to the experiment directory (``$EXPTDIR``) and run the launch script:

.. code-block:: console

   ./launch_FV3LAM_wflow.sh

Run the launch script regularly and repeatedly until the experiment completes. 

To check progress, run:

.. code-block:: console

   tail -n 40 log.launch_FV3LAM_wflow

Users who prefer to automate the workflow via :term:`crontab` or who need guidance for running without the Rocoto workflow manager should refer to :numref:`Section %s <Run>` for these options. 

If a problem occurs and a task goes DEAD, view the task log files in ``$EXPTDIR/log`` to determine the problem. Then refer to :numref:`Section %s <RestartTask>` to restart a DEAD task once the problem has been resolved. For troubleshooting assistance, users are encouraged to post questions on the new SRW App `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ Q&A page. 

Compare
----------

Once the experiment has completed (i.e., all tasks have "SUCCEEDED" and the end of the ``log.launch_FV3LAM_wflow`` file lists "Workflow status: SUCCESS"), users can compare their forecast results against the forecast results provided in the ``Indy-Severe-Weather`` directory downloaded in :numref:`Section %s <GetSampleData>`. This directory contains the forecast output and plots from NOAA developers under the ``postprd`` subdirectory and METplus verification files under the ``metprd`` subdirectory. 

Qualitative Comparison of the Plots
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Comparing the plots is relatively straightforward since they are in ``.png`` format, and most computers can render them in their default image viewer. :numref:`Table %s <AvailablePlots>` lists plots that are available every 6 hours of the forecast (where ``hhh`` is replaced by the three-digit forecast hour): 

.. _AvailablePlots:

.. table:: Sample Indianapolis Forecast Plots

   +-----------------------------------------+-----------------------------------+
   | Field                                   | File Name                         |
   +=========================================+===================================+
   | Sea level pressure                      | slp_regional_fhhh.png             |
   +-----------------------------------------+-----------------------------------+
   | Surface-based CAPE/CIN                  | sfcape_regional_fhhh.png          |
   +-----------------------------------------+-----------------------------------+
   | 2-meter temperature                     | 2mt_regional_fhhh.png             |
   +-----------------------------------------+-----------------------------------+
   | 2-meter dew point temperature           | 2mdew_regional_fhhh.png           |
   +-----------------------------------------+-----------------------------------+
   | 10-meter winds                          | 10mwind_regional_fhhh.png         |
   +-----------------------------------------+-----------------------------------+
   | 250-hPa winds                           | 250wind_regional_fhhh.png         |
   +-----------------------------------------+-----------------------------------+
   | 500-hPa heights, winds, and vorticity   | 500_regional_fhhh.png             |
   +-----------------------------------------+-----------------------------------+
   | Max/Min 2 - 5 km updraft helicity       | uh25_regional_fhhh.png            |
   +-----------------------------------------+-----------------------------------+
   | Composite reflectivity                  | refc_regional_fhhh.png            |
   +-----------------------------------------+-----------------------------------+
   | Accumulated precipitation               | qpf_regional_fhhh.png             |
   +-----------------------------------------+-----------------------------------+

Users can visually compare their plots with the plots produced by NOAA developers to see how close they are. 

Quantitative Forecast Comparision
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

METplus verification ``.stat`` files provide users the opportunity to compare their model run with a baseline using quantitative measures. The file format is ``(grid|point)_stat_PREFIX_HHMMSSL_YYYYMMDD_HHMMSSV.stat``, where PREFIX indicates the user-defined output prefix, HHMMSSL indicates the forecast *lead time*, and YYYYMMDD_HHMMSSV indicates the forecast *valid time*. For example, one of the ``.stat`` files for the 30th hour of a forecast starting at midnight (00Z) on June 15, 2019 would be:

.. code-block:: console

   point_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_NDAS_ADPSFC_300000L_20190616_060000V.stat

The 30th hour of the forecast occurs at 6am (06Z) on June 16, 2019. The lead time is 30 hours (300000L in HHMMSSL format) because this is the 30th hour of the forecast. The valid time is 06Z (060000V in HHMMSSV format).

The following is the list of METplus output files users can reference during the comparison process:

.. code-block:: console 
   
   # Point-Stat Files
   point_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_NDAS_ADPSFC_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   point_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_NDAS_ADPUPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat

   # Grid-Stat Files
   grid_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_REFC_MRMS_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_RETOP_MRMS_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_APCP_01h_CCPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_APCP_03h_CCPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_APCP_06h_CCPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat
   grid_stat_FV3_RRFS_v1beta_SUBCONUS_Ind_3km_APCP_24h_CCPA_HHMMSSL_YYYYMMDD_HHMMSSV.stat


Point STAT Files
```````````````````

The Point-Stat files contain continuous variables like temperature, pressure, and wind speed. A description of the Point-Stat file can be found :ref:`here <met:point-stat>` in the MET documentation. 

The Point-Stat files contain a potentially overwhelming amount of information. Therefore, it is recommended that users focus on the CNT MET test, which contains the `RMSE <https://met.readthedocs.io/en/latest/Users_Guide/appendixC.html#root-mean-squared-error-rmse>`__ and `MBIAS <https://met.readthedocs.io/en/latest/Users_Guide/appendixC.html#multiplicative-bias>`__ statistics. The MET tests are defined in column 24 'LINE_TYPE' of the ``.stat`` file. Look for 'CNT' in this column. Then find column 66-68 for MBIAS and 78-80 for RMSE statistics. A full description of this file can be found :ref:`here <met:point_stat-output>`.

To narrow down the variable field even further, users can focus on these weather variables: 

   * 250 mb - wind speed, temperature
   * 500 mb - wind speed, temperature
   * 700 mb - wind speed, temperature, relative humidity
   * 850 mb - wind speed, temperature, relative humidity
   * Surface  - wind speed, temperature, pressure, dewpoint

**Interpretation:**

* A lower RMSE indicates that the model forecast value is closer to the observed value.
* If MBIAS > 1, then the value for a given forecast variable is too high on average by (MBIAS - 1)%. If MBIAS < 1, then the forecasted value is too low on average by (1 - MBIAS)%.

Grid-Stat Files
````````````````````

The Grid-Stat files contain gridded variables like reflectivity and precipitation. A description of the Grid-Stat file can be found :ref:`here <met:grid-stat>`. 

As with the Point-Stat file, there are several MET tests and statistics available in the Grid-Stat file. To simplify this dataset, users can focus on the MET tests and statistics found in :numref:`Table %s <GridStatStatistics>` below. The MET tests are found in column 24 ‘LINE_TYPE’ of the Grid-Stat file. The table also shows the user the columns for the statistics of interest. For a more detailed description of the Grid-Stat files, view the :ref:`MET Grid-Stat Documentation <met:grid-stat>`.

.. _GridStatStatistics:

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

* If FBIAS > 1, then the event is over forecast, meaning that the prediction for a particular variable (e.g., precipitation, reflectivity) was higher than the observed value. If FBIAS < 1, then the event is under forecast, so the predicted value was lower than the observed value. If FBIAS = 1, then the forecast matched the observation.
* FSS values > 0.5 indicate a useful score. FSS values range from 0 to 1, where 0 means that there is no overlap between the forecast and observation, and 1 means that the forecast and observation are the same (complete overlap).
* FAR ranges from 0 to 1; 0 indicates a perfect forecast, and 1 indicates no skill in the forecast.
* CSI ranges from 0 to 1; 1 indicates a perfect forecast, and 0 represents no skill in the forecast.
