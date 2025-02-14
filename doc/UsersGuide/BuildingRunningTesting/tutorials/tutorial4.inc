.. _fcst4:

Sample Forecast #4: Halloween Storm
=======================================

**Objective:** 
   * Compare forecast outputs for similar experiments that use different :term:`IC/LBC <ics/lbcs>` sources. 
   * Coming soon: Option to use verification tools to assess forecast quality. 

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