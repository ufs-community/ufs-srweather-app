.. _fcst4:

Sample Forecast #4: Halloween Storm
=======================================

**Objectives:** 
   * Compare forecast outputs for similar experiments that use different :term:`IC/LBC <ics/lbcs>` sources. 
   * Use verification tools to assess forecast quality. 

Weather Summary
--------------------

A line of severe storms brought strong winds, flash flooding, and tornadoes to the eastern half of the US.

**Weather Phenomena:** Flooding and high winds

   * `Storm Prediction Center (SPC) Storm Report for 20191031 <https://www.spc.noaa.gov/climo/reports/191031_rpts.html>`_

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/HalloweenStorm.gif
   :alt: Radar animation of the Halloween Storm that swept across the Eastern United States in 2019. 

   *Halloween Storm 2019*

Data
-------

Data for the Halloween Storm is publicly available in S3 data buckets. The Rapid Refresh (`RAP <https://rapidrefresh.noaa.gov/>`_) data can be downloaded from the `SRW App data bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`_ using ``wget``. Make sure to issue the command from the folder where you want to place the data.

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/develop-20240618/halloween_rap.tgz
   tar -xzf halloween_rap.tgz
   
This will untar the ``halloween_rap.tgz`` data into a directory named ``RAP``.

The SRW App can pull HRRR data directly from the `HRRR data bucket <https://registry.opendata.aws/noaa-hrrr-pds/>`_. Users do not need to download the data separately. 

Load the workflow
---------------------

To load the workflow environment, source the lmod-setup file and load the workflow conda environment by running:

.. include:: ../../doc-snippets/load-env.rst

After loading the workflow, users should follow the instructions printed to the console. Usually, the instructions will tell the user to run |activate|. For example, a user on Hera with permissions on the ``nems`` project may issue the following commands to load the workflow (replacing ``User.Name`` with their actual username):

.. code-block:: console
   
   source /scratch1/NCEPDEV/nems/User.Name/ufs-srweather-app/etc/lmod-setup.sh hera
   module use /scratch1/NCEPDEV/nems/User.Name/ufs-srweather-app/modulefiles
   module load wflow_hera
   conda activate srw_app

Configuration
-------------------------

.. include:: ../../doc-snippets/expt-conf-intro.rst

Experiment 1: RAP Data
^^^^^^^^^^^^^^^^^^^^^^^^

Edit the configuration file (``config.yaml``) to include the variables and values in the sample configuration excerpts below. 

.. include:: ../../doc-snippets/file-edit-hint.rst

Start in the ``user:`` section and change the ``MACHINE`` and ``ACCOUNT`` variables. For example, when running on a personal MacOS device, users might set:

.. code-block:: console

   user:
      RUN_ENVIR: community
      MACHINE: macos
      ACCOUNT: none

For a detailed description of these variables, see :numref:`Section %s <user>`.

Users do not need to change the ``platform:`` section of the configuration file for this tutorial. 

In the ``workflow:`` section of ``config.yaml``, update ``EXPT_SUBDIR``, ``CCPP_PHYS_SUITE``, ``PREDEF_GRID_NAME``, ``DATE_FIRST_CYCL``, ``DATE_LAST_CYCL``, and ``FCST_LEN_HRS``.

.. code-block:: console

   workflow:
     USE_CRON_TO_RELAUNCH: false
     EXPT_SUBDIR: halloweenRAP
     CCPP_PHYS_SUITE: FV3_RAP
     PREDEF_GRID_NAME: RRFS_CONUS_13km
     DATE_FIRST_CYCL: '2019103012'
     DATE_LAST_CYCL: '2019103012'
     FCST_LEN_HRS: 36
     PREEXISTING_DIR_METHOD: rename
     VERBOSE: true
     COMPILER: intel

.. include:: ../../doc-snippets/cron-note.rst

``EXPT_SUBDIR:`` This variable can be changed to any name the user wants from "halloweenRAP" to "HalloweenStorm1" to "askdfj" (but note that whitespace and some punctuation characters are not allowed). However, the best names will indicate useful information about the experiment. Since this tutorial helps users to compare the output from RAP and HRRR forecast input data, this tutorial will use ``halloweenRAP`` for the Halloween Storm experiment that uses RAP forecast data.

``PREDEF_GRID_NAME:`` This experiment uses the RRFS_CONUS_13km, rather than the default RRFS_CONUS_25km grid. This 13-km resolution is used in the NOAA operational Rapid Refresh (`RAP <https://rapidrefresh.noaa.gov/>`_) model and is the resolution envisioned for the initial operational implementation of the Rapid Refresh Forecast System (:term:`RRFS`). For more information on this grid, see :numref:`Section %s <RRFS_CONUS_13km>`.

``CCPP_PHYS_SUITE:`` The FV3_RAP physics suite contains the evolving :term:`parameterizations` used operationally in the NOAA Rapid Refresh (`RAP <https://rapidrefresh.noaa.gov/>`_) model; the suite is also a prime candidate under consideration for initial RRFS implementation and has been well-tested at the 13-km resolution. It is therefore an appropriate physics choice when using the RRFS_CONUS_13km grid. 

``DATE_FIRST_CYCL``, ``DATE_LAST_CYCL``, and ``FCST_LEN_HRS`` set parameters related to the date and duration of the forecast. Because this is a one-cycle experiment that does not use cycling or :term:`data assimilation`, the date of the first :term:`cycle` and last cycle are the same. 

For a detailed description of other ``workflow:`` variables, see :numref:`Section %s <workflow>`.

In the ``task_get_extrn_ics:`` section, add ``USE_USER_STAGED_EXTRN_FILES`` and ``EXTRN_MDL_SOURCE_BASEDIR_ICS``. Users will need to adjust the file path to point to the location of the data on their system. 

.. code-block:: console

   task_get_extrn_ics:
     EXTRN_MDL_NAME_ICS: RAP
     USE_USER_STAGED_EXTRN_FILES: true
     EXTRN_MDL_SOURCE_BASEDIR_ICS: /path/to/RAP/for_ICS

For a detailed description of the ``task_get_extrn_ics:`` variables, see :numref:`Section %s <task_get_extrn_ics>`. 

Similarly, in the ``task_get_extrn_lbcs:`` section, add ``USE_USER_STAGED_EXTRN_FILES`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS``. Users will need to adjust the file path to point to the location of the data on their system. 

.. code-block:: console

   task_get_extrn_lbcs:
     EXTRN_MDL_NAME_LBCS: RAP
     LBC_SPEC_INTVL_HRS: 3
     USE_USER_STAGED_EXTRN_FILES: true
     EXTRN_MDL_SOURCE_BASEDIR_LBCS: /path/to/RAP/for_LBCS

For a detailed description of the ``task_get_extrn_lbcs:`` variables, see :numref:`Section %s <task_get_extrn_lbcs>`. 

Users do not need to modify the ``task_run_fcst:`` section for this tutorial. 

.. COMMENT: Do we need to set QUILTING to true?

In the ``rocoto:tasks:`` section, increase the walltime for the data-related tasks and metatasks. Then include the YAML configuration file containing the plotting task in the ``rocoto:tasks:taskgroups:`` section, like this:

.. code-block:: console

  rocoto:
    tasks:
      task_get_extrn_ics:
        walltime: 06:00:00
      task_get_extrn_lbcs:
        walltime: 06:00:00
      metatask_run_ensemble:
        task_make_lbcs_mem#mem#:
          walltime: 06:00:00
        task_run_fcst_mem#mem#:
          walltime: 06:00:00
      taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/plot.yaml"]|include }}'

.. note::

   Rocoto tasks are run once each. A :ref:`Rocoto <RocotoInfo>` metatask expands into one or more similar tasks by replacing the values between ``#`` symbols with the values under the ``var:`` key. See the `Rocoto documentation <https://christopherwharrop.github.io/rocoto/>`_ for more information. 

For more information on how to turn on/off tasks in the workflow, please see :numref:`Section %s <ConfigTasks>`.

In the ``task_plot_allvars:`` section, add ``PLOT_FCST_INC: 6``. Users may also want to add ``PLOT_FCST_START: 0`` and ``PLOT_FCST_END: 36`` explicitly, but these can be omitted since the default values are the same as the forecast start and end time respectively. 

.. code-block:: console

   task_plot_allvars:
     COMOUT_REF: ""
     PLOT_FCST_INC: 6

``PLOT_FCST_INC:`` This variable indicates the forecast hour increment for the plotting task. By setting the value to ``6``, the task will generate a ``.png`` file for every 6th forecast hour starting from 12z on October 30, 2019 (the 0th forecast hour) through the 36th forecast hour (November 1, 2019 at 0z). 

After configuring the forecast, users can generate the forecast by running:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

To see experiment progress, users should navigate to their experiment directory. Then, use the ``rocotorun`` command to launch new workflow tasks and ``rocotostat`` to check on experiment progress. 

.. code-block:: console

   cd /path/to/expt_dirs/halloweenRAP
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Users will need to rerun the ``rocotorun`` and ``rocotostat`` commands above regularly and repeatedly to continue submitting workflow tasks and receiving progress updates. 

.. note::

   When using cron to automate the workflow submission (as described :ref:`above <CronNote>`), users can omit the ``rocotorun`` command and simply use ``rocotostat`` to check on progress periodically. 

Users can save the location of the ``halloweenRAP`` directory in an environment variable (e.g., ``$HRAP``). This makes it easier to navigate between directories later. For example:

.. code-block:: console

   export HRAP=/path/to/expt_dirs/halloweenRAP

Users should substitute ``/path/to/expt_dirs/halloweenRAP`` with the actual path to the experiment directory on their system. As long as a user remains logged into their system, they can run ``cd $HRAP``, and it will take them to the ``halloweenRAP`` experiment directory. The variable will need to be reset for each login session. 

Experiment 2: Changing the Forecast Input
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Once the ``halloweenRAP`` case is running, users can return to the ``config.yaml`` file (in ``$USH``) and adjust the parameters for a new forecast. In this forecast, users will change the forecast input to use ``HRRR`` data and alter a few associated parameters. 

In the ``workflow:`` section of ``config.yaml``, update ``EXPT_SUBDIR`` and ``PREDEF_GRID_NAME``. Other parameters should remain the same.

.. code-block:: console

   workflow:
     EXPT_SUBDIR: halloweenHRRR
     PREDEF_GRID_NAME: RRFS_CONUScompact_13km

.. note::

   Relative to the original CONUS domain, the "compact" CONUS domains are slightly smaller. The original CONUS domains were a bit too large to run with :term:`LBCs` from HRRR, so the "compact" domains were created to be just small enough to work with HRRR data. 

In the ``task_get_extrn_ics:`` section, update the values for ``EXTRN_MDL_NAME_ICS`` and ``USE_USER_STAGED_EXTRN_FILES`` and add ``EXTRN_MDL_FILES_ICS``. Users may choose to comment out or remove ``EXTRN_MDL_SOURCE_BASEDIR_ICS``, but this is not necessary. 

.. code-block:: console

   task_get_extrn_ics:
     EXTRN_MDL_NAME_ICS: HRRR
     USE_USER_STAGED_EXTRN_FILES: false
     EXTRN_MDL_FILES_ICS:
     - '{yy}{jjj}{hh}00{fcst_hr:02d}00'

For a detailed description of the ``task_get_extrn_ics:`` variables, see :numref:`Section %s <task_get_extrn_ics>`. 

Update the same values in the ``task_get_extrn_lbcs:`` section: 

.. code-block:: console

   task_get_extrn_lbcs:
     EXTRN_MDL_NAME_LBCS: HRRR
     LBC_SPEC_INTVL_HRS: 3
     USE_USER_STAGED_EXTRN_FILES: false
     EXTRN_MDL_FILES_LBCS:
     - '{yy}{jjj}{hh}00{fcst_hr:02d}00'


For a detailed description of the ``task_get_extrn_lbcs:`` variables, see :numref:`Section %s <task_get_extrn_lbcs>`. 

After configuring the forecast, users can generate the second forecast by running:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

To see experiment progress, users should navigate to their experiment directory. As in the first forecast, the following commands allow users to launch new workflow tasks and check on experiment progress. 

.. code-block:: console

   cd /path/to/expt_dirs/halloweenHRRR
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

.. note::

   When using cron to automate the workflow submission (as described :ref:`above <CronNote>`), users can omit the ``rocotorun`` command and simply use ``rocotostat`` to check on progress periodically. 

.. note::
   
   If users have not automated their workflow using cron, they will need to ensure that they continue issuing ``rocotorun`` commands to launch all of the tasks in each experiment. While switching between experiment directories to run ``rocotorun`` and ``rocotostat`` commands in both directories is possible, it may be easier to finish the ``halloweenRAP`` experiment's tasks before starting on ``halloweenHRRR``. 

As with the ``halloweenRAP`` experiment, users can save the location of the ``halloweenHRRR`` directory in an environment variable (e.g., ``$HHRRR``). This makes it easier to navigate between directories later. For example:

.. code-block:: console

   export HHRRR=/path/to/expt_dirs/halloweenHRRR

Users should substitute ``/path/to/expt_dirs/halloweenHRRR`` with the actual path on their system. 


How to Analyze Results
-----------------------
Navigate to ``halloweenHRRR/2019103012/postprd`` and/or ``halloweenRAP/2019203012/postprd``. These directories contain the post-processed data generated by the :term:`UPP` from the Halloween Storm forecasts. After the ``plot_allvars`` task completes, this directory will contain ``.png`` images for several forecast variables. 

Copy ``.png`` Files onto Local System
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: ../../doc-snippets/scp-files.rst

Examining Forecast Plots at Peak Intensity 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This experiment will be looking at plots from HRRR and RAP input files while the Halloween Storm is at or approaching peak intensity. 

.. _fcst4_250wind:

250mb Wind
``````````
An effective weather forecast begins with analyzing a 250mb wind chart. By using this wind plot, forecasters can identify key features such as jet stream placement, jet maxima, troughs, ridges, and more. This analysis also helps pinpoint areas with the potential for the strongest severe weather.

In the 250mb wind plots below, the ``halloweenHRRR`` and ``halloweenRAP`` plots are nearly identical at forecast hour f036. This shows great model agreement. Analyzing this chart we can see multiple ingredients signaling a significant severe weather event over the eastern CONUS. The first thing to notice is the placement of the jet streak along with troughing approaching the eastern US. Also notice an extreme 150KT jet max over southern Ohio further fueling severe weather. The last thing to notice is the divergence aloft present over the eastern CONUS; seeing divergence present all the way up to 250mb indicates a strong system.

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst4_plots/250wind_rap_conus_f036.png
      :align: center
      :width: 75%

      *RAP Plot for 250mb Wind*

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst4_plots/250wind_hrrr_conus_f036.png
      :align: center
      :width: 75%

      *HRRR Plot for 250mb Wind*

.. _fcst4_10mwind:

10m Wind
``````````
The 10m wind plots allows forecasters to pick up on patterns closer to the surface. It shows features such as convergence and pressure areas.

In the 10m wind plots below, the ``halloweenHRRR`` and ``halloweenRAP`` are once again very similar, which makes sense given that the 250mb wind plots are also so similar. We can see a few key features on this chart. The most important is the area of convergence taking place over the east coast which is driving the line of severe storms. 

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst4_plots/10mwind_rap_conus_f036.png
      :align: center
      :width: 75%

      *RAP Plot for 10m Winds*

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst4_plots/10mwind_hrrr_conus_f036.png
      :align: center
      :width: 75%

      *HRRR Plot for 10m Winds*

.. _fcst4_refc:

Composite Reflectivity 
````````````````````````
Reflectivity images visually represent the weather based on the energy (measured in decibels [dBZ]) reflected back from radar. Composite reflectivity generates an image based on reflectivity scans at multiple elevation angles, or "tilts", of the antenna. See https://www.noaa.gov/jetstream/reflectivity for a more detailed explanation of composite reflectivity. 

In the composite reflectivity plots below, the ``halloweenHRRR`` and ``halloweenRAP`` models remain quite similar, as expected. Utilizing the reflectivity plots provides the final piece of the puzzle. From the previous analyses, we already had a good understanding of where the storms were likely to occur. Composite reflectivity serves as an additional tool, allowing us to visualize where the models predict storm placement. In this case, the strongest storms are indicated by higher dBZ values and appear to be concentrated in the NC/VA region.

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst4_plots/refc_rap_conus_f036.png
      :align: center
      :width: 75%

      *RAP Plot for Composite Reflectivity*

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst4_plots/refc_hrrr_conus_f036.png
      :align: center
      :width: 75%

      *HRRR Plot for Composite Reflectivity*

Experiment 3: Performing METplus Verification 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In this experiment, we will use the METplus verification framework to evaluate the accuracy of the HRRR forecasts for the Halloween Storm Case. The METplus tools provide a robust and customizable way to assess forecast skill by comparing model output against observational data. This section will guide you through the steps to perform METplus verification for this case.

.. note::

   For tutorial purposes we will only run this test using HRRR data, but users should feel free to do the same experiment with RAP data.

Set Up Verification
-----------------------

Follow the instructions below to reproduce a forecast for this event using your own model setup! Make sure to install and build the latest version of the SRW Application (|latestr|). ``develop`` branch code is constantly changing, so it does not provide a consistent baseline for comparison.

.. _GetData:

On :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems, users can find data for the Indianapolis Severe Weather Forecast in the usual data locations (see :numref:`Section %s <DataLocations>` for a list). 

On other systems, users need to download the ``HalloweenStormData.tar.gz`` file using any of the following methods:

    #. Download directly from the S3 bucket using a browser. The data is available at https://noaa-ufs-srw-pds.s3.amazonaws.com/HalloweenStormData/HalloweenStormData.tar.gz

    #. Download from a terminal using the AWS command line interface (CLI), if installed:

      .. code-block:: console

         aws s3 cp https://noaa-ufs-srw-pds.s3.amazonaws.com/HalloweenStormData/HalloweenStormData.tar.gz HalloweenStormData.tar.gz
    
    #. Download from a terminal using ``wget``: 

      .. code-block:: console

         wget https://noaa-ufs-srw-pds.s3.amazonaws.com/HalloweenStormData/HalloweenStormData.tar.gz

This tar file contains :term:`IC/LBC <ICs/LBCs>` files, observation data, model/forecast output, and MET verification output for the sample forecast. Users who have never run the SRW App on their system before will also need to download (1) the fix files required for SRW App forecasts and (2) the NaturalEarth shapefiles required for plotting. Users can download the fix file data from a browser at https://noaa-ufs-srw-pds.s3.amazonaws.com/experiment-user-cases/release-public-v3.0.0/out-of-the-box/fix_data.tgz or visit :numref:`Section %s <StaticFixFiles>` for instructions on how to download the data with ``wget``. NaturalEarth files are available at https://noaa-ufs-srw-pds.s3.amazonaws.com/experiment-user-cases/release-public-v3.0.0/NaturalEarth/NaturalEarth.tar.gz. See the :numref:`Section %s <PlotOutput>` for more information on plotting.

After downloading ``HalloweenStormData.tar.gz`` using one of the three methods above, untar the downloaded compressed archive file: 

.. code-block:: console

   tar xvfz HalloweenStormData.tar.gz

Save the path to this file in the ``HalloweenDATA`` environment variable:
   
.. code-block:: console 

   cd HalloweenStormData
   export HalloweenDATA=$PWD

.. note::

   Users can untar the fix files and Natural Earth files by substituting those file names in the commands above.

Load the Workflow
^^^^^^^^^^^^^^^^^^^^

To load the workflow environment, run:

.. include:: ../../doc-snippets/load-env.rst
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

.. code-block:: console

   user:
      MACHINE: <your_machine_name>
      ACCOUNT: <my_account>
   platform:
      # Add EXTRN_MDL_DATA_STORES variable to config.yaml
      EXTRN_MDL_DATA_STORES: aws
   workflow:
      USE_CRON_TO_RELAUNCH: true
      EXPT_SUBDIR: halloweenstormHRRRMETPLUS
      CCPP_PHYS_SUITE: FV3_RAP
      PREDEF_GRID_NAME: RRFS_CONUScompact_13km
      DATE_FIRST_CYCL: '2019103012'
      DATE_LAST_CYCL: '2019103012'
      FCST_LEN_HRS: 24
      PREEXISTING_DIR_METHOD: rename
      VERBOSE: true
      # Change to gnu if using a gnu compiler; otherwise, no change
      COMPILER: intel
   task_get_extrn_ics:
      # Add EXTRN_MDL_NAME_ICS and EXTRN_MDL_FILES_ICS variables to config.yaml
      EXTRN_MDL_NAME_ICS: HRRR
      USE_USER_STAGED_EXTRN_FILES: false
      EXTRN_MDL_FILES_ICS:
      -  '{yy}{jjj}{hh}00{fcst_hr:02d}00'
   task_get_extrn_lbcs:
      # Add EXTRN_MDL_NAME_LBCS, USE_USER_STAGED_EXTRN_FILES, and EXTRN_MDL_FILES_LBCS variables to config.yaml
      EXTRN_MDL_NAME_LBCS: HRRR
      LBC_SPEC_INTVL_HRS: 3
      USE_USER_STAGED_EXTRN_FILES: false
      EXTRN_MDL_FILES_LBCS:
      -  '{yy}{jjj}{hh}00{fcst_hr:02d}00'
   task_plot_allvars:
     COMOUT_REF: ""
     PLOT_FCST_INC: 6
   verification:
     VX_FCST_MODEL_NAME: FV3_GFS_v16_CONUS_25km
     CCPA_OBS_DIR: /path/to/HalloweenStormData/obs_data/ccpa/proc
     MRMS_OBS_DIR: /path/to/HalloweenStormData/obs_data/mrms/proc
     NDAS_OBS_DIR: /path/to/HalloweenStormData/obs_data/ndas/proc
   rocoto:
  tasks:
   task_get_extrn_ics:
     walltime: 06:00:00
   task_get_extrn_lbcs:
     walltime: 06:00:00
   metatask_run_ensemble:
     task_make_lbcs_mem#mem#:
       walltime: 06:00:00
     task_run_fcst_mem#mem#:
       walltime: 06:00:00
   taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/verify_pre.yaml", "parm/wflow/verify_det.yaml", "parm/wflow/test.yaml"]|include }}'

.. hint::
   To open the configuration file in the command line, users may run the command: 

   .. code-block:: console

      vi config.yaml
         
   To modify the file, hit the ``i`` key and then make any changes required. To close and save, hit the ``esc`` key and type ``:wq``. Users may opt to use their preferred code editor instead. 

For additional configuration guidance, refer to the |latestr| release documentation on :ref:`configuring the SRW App <srw_v3.0.0:UserSpecificConfig>`.

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

To see experiment progress, users should navigate to their experiment directory. The following commands allow users to launch new workflow tasks and check on experiment progress.

.. code-block:: console

   cd path/to/expt_dirs/halloweenstormHRRRMETPLUS
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Users who prefer to automate the workflow via :term:`crontab` or who need guidance for running without the Rocoto workflow manager should refer to :numref:`Section %s <Run>` for these options. 

If a problem occurs and a task goes DEAD, view the task log files in ``$EXPTDIR/log`` to determine the problem. Then refer to :numref:`Section %s <RestartTask>` to restart a DEAD task once the problem has been resolved. For troubleshooting assistance, users are encouraged to post questions on the new SRW App `GitHub Discussions <https://github.com/ufs-community/ufs-srweather-app/discussions/categories/q-a>`__ Q&A page. 

Compare
----------

Once the experiment has completed (i.e., all tasks have "SUCCEEDED" and the end of the ``log.launch_FV3LAM_wflow`` file lists "Workflow status: SUCCESS"), users can see how the forecast verified. From the ``expt_dirs`` users should navigate to their experiment (e.g., ``halloweenstormHRRRMETPLUS``). Then, navigate to the ``2019103012`` subdirectory, and finally, enter the ``metprd`` directory to view your experiment's results.

MetPlus File Types
^^^^^^^^^^^^^^^^^^^^

For information on different file types found in the ``metprd`` directory users should reference :numref:`Section %s <AvailablePlots>`. 

Analyzing HRRR Results
^^^^^^^^^^^^^^^^^^^^^^^^

This section, will analyze how different variables were verified in the HRRR forecast. To do this, users will be examining the RMSE and MBIAS scores for Temperature and Dew Point (DPT) on the surface using the ``point_stat`` file type.

**Interpretation:**

* A lower RMSE indicates that the model forecast value is closer to the observed value.
* If MBIAS > 1, then the value for a given forecast variable is too high on average by (MBIAS - 1)%. If MBIAS < 1, then the forecasted value is too low on average by (1 - MBIAS)%.
* Find column 66-68 for MBIAS and 78-80 for RMSE statistics.

Temperature
------------

To begin examining the temperature variable, navigate to ``path/to/2019103012/metprd``. Use ``vi`` to open ``PointStat/``, where a menu of files will appear. Navigate using the arrow and enter keys on your. Select this file:

.. code-block:: console

   point_stat_FV3_GFS_v16_CONUS_25km_mem000_ADPSFC_NDAS_240000L_20191031_120000V.stat

Press ``Enter`` to open this file. You will now be able to see verification data for different types of variables. 

We can see that on October 31st, at 2400L, temperature received an MBIAS score of 1.7212 and an RMSE score of 2.38512. Looking at these scores, we can conclude that for this forecast hour, the temperature was over forecasted and was greater than the observed temperature.

Dew Point
----------

Good news! The DPT variable can be examined within the same point_stat file, so there is no need to switch files. DPT received an MBIAS score of 1.5978 and an RMSE score of 2.51836. Looking at these scores, we can see that, similar to temperature, the DPT was over forecasted and was greater than the observed dewpoint.
