
.. _fcst6:

Sample Forecast #6: Choose Your Own Adventure!
================================================

**Objective:** Create a forecast of your choice on a custom grid using publicly available data. 

Weather Summary
--------------------

Weather will vary depending on the case the user chooses. In this example, we use the Gulf Coast Blissard from January 21, 2025 (2025-01-21), with a custom regional grid centered over New Orleans, LA. 

In this case, the polar vortex stretched far south bringing cold, dry air to the Gulf Coast, where it met the comparatively warm, moist air from the Gulf, leading to unprecedented snowfall followed by record low temperatures. 

**Weather Phenomena:** Record-breaking snow and cold temperatures throughout the region. 

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/nola_blizzard.gif
   :alt: Radar animation of severe weather over New Orleans, LA on January 21, 2021. The animation shows areas of heavy snow moving from west to east over New Orleans and across the Gulf Coast. 

   *Incoming Blizzard Over New Orleans*

Preliminary Steps
-------------------
It is suggested that users create a directory on their system where they will store data and run their forecast. In this example, we make a directory called ``blizzard`` and navigate into it: 

.. code-block:: console

   mkdir blizzard
   cd blizzard
   
Users can save the location of the this directory in an environment variable such as $GCB (for Gulf Coast Blizzard). This makes it easier to navigate between directories later. For example:

.. code-block:: console

   export GCB=/path/to/blizzard

Data
-------

Users can set up a forecast for a weather case of their choice using data downloaded from a publicly available source. The SRW App requires:

   * Fix files -- Static datasets containing climatological information, terrain, and land use data
   * Initial and boundary conditions files
   * Natural Earth Shapefiles (optional) for use in plotting tasks 

Fix Files
^^^^^^^^^^

Fix files are publicly available in the `SRW App Data Bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`_. Users can download the full set of fix files and untar it:

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/experiment-user-cases/release-public-v2.2.0/out-of-the-box/fix_data.tgz
   tar -xzf fix_data.tgz

Initial and Boundary Conditions Files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Initial conditions (ICs) files provide information on the state of the atmosphere at the start of the forecast. Because the SRW App uses regional grids, it needs to update the forecast periodically with information about the state of the atmosphere at the edges of the grid. These are called the lateral boundary conditions (LBCs). 

IC and LBC data must be in ``NetCDF``, ``grib2``, or ``nemsio`` format. There are several potential sources of publicly available data listed in :numref:`Section %s <stage-ics-manually>`. Many of these sources only include data for the last 1-30 days, so it is recommended that users download the data that they think they will need and store the data somewhere so that they are still accessible even when no longer available on these sites. 

When choosing data, users should consider the type of weather they are trying to model, the size of the domain they plan to use, and the compute resources available to them. This will help to determine what grid resolution is most appropriate. There is more information on regional (or "limited area model") grids available in :numref:`Section %s <LAMGrids>`. 

When modeling severe weather, it is preferable to use a high-resolution (~1-4km) grid along with physics suites and data designed for these convection-allowing scales. Therefore, we downloaded High-Resolution Rapid Refresh (HRRR) data for this case. According to NOAA, "`HRRR <https://rapidrefresh.noaa.gov/hrrr/>`_ is a NOAA real-time 3-km resolution, hourly updated, cloud-resolving, convection-allowing atmospheric model, initialized by 3km grids with 3km radar assimilation."

To download data for this case, we first created a directory named ``data`` (in our ``$GCB`` directory) and placed the ``get_data.py`` script in there:

.. code-block:: console

   mkdir data
   cd data

We then used a :srw-wiki:`utility script <Tutorial/get_data.py>` to download HRRR data from the `Planetary Computer <https://planetarycomputer.microsoft.com/dataset/storage/noaa-hrrr>`_ site.  

Users can download the utility script with ``wget`` or copy paste the contents of the script into a file on their system. 

.. code-block:: console

   wget https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/get_data.py

.. note::

   Users will need at least Python 3.10 and the ``requests`` library to run the script as-is. 

Call the script with the ``-h`` option to see usage information: 

.. code-block:: console

   $ python3 get_data.py -h
   usage: get_data.py [-h] --date DATE --product
                   {wrfsfcf,wrfprsf,wrfnatf,wrfsubhf} [--fhour [FH ...]]

   Utility for retrieving HRRR data

   options:
   -h, --help            show this help message and exit
   --date DATE, -d DATE  Date of requested data in YYYYMMDDHH format
   --product {wrfsfcf,wrfprsf,wrfnatf,wrfsubhf}, -p {wrfsfcf,wrfprsf,wrfnatf,wrfsubhf}
                           Product type (e.g., "wrfsfcf", "wrfprsf")
   --fhour [FH ...], -f [FH ...]
                           Forecast hours

Users are welcome to adapt the script to work for other data sources, such as RAP or GFS data. 

Then we ran the following command to download the data:

.. code-block:: console

   python3 get_data.py -p wrfprsf -d 2025012100 -f 0 3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48

Users will need to adjust this command for the specific date(s) and forecast hours they need for their experiment. We provide the data for the Gulf Coast Blizzard experiment in the `SRW Data Bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`_ and on :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems in the usual input model data locations (see :numref:`Section %s <DataLocations>` for a list). Users can retrieve this data from the SRW bucket by running:

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/index.html#develop-20240618/gulf_coast_blizzard.tgz

.. COMMENT: Add data to bucket and Level 1 systems!!! 

However, users are encouraged to experiment with downloading their own data for a case of interest!

Natural Earth Shapefiles
^^^^^^^^^^^^^^^^^^^^^^^^^

The small set of Natural Earth shapefiles required for SRW App plotting tasks are publicly available in the `SRW App Data Bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`_. Users can download and untar the files:

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/develop-20240618/NaturalEarth/NaturalEarth.tgz
   tar -xzf NaturalEarth.tgz

The full set of Natural Earth shapefiles can also be downloaded from the `Natural Earth website <https://www.naturalearthdata.com/downloads/>`_. 

Download the SRW App
---------------------

Navigate to the working directory. For example:

.. code-block:: console

   cd $GCB

Users who do not already have the SRW App can download the code by running:

.. include:: ../../doc-snippets/clone.rst

Then check out the external repositories:

.. include:: ../../doc-snippets/externals.rst

Then build the SRW App:

.. include:: ../../doc-snippets/devbuild.rst

This process will likely take 20-30 min. Users who do not have access to a :srw-wiki:`Level 1 system <Supported-Platforms-and-Compilers>` may need to use the :ref:`CMake Approach <CMakeApproach>` to build the App instead. 

Create a Regional Grid
------------------------

The SRW App already contains several predefined grids, which are well-tested with the supported physics and data sources. While these are a great start for new users, they cover a narrow set of possible grid configurations. Depending on their goals, users may be interested in creating their own custom grid. :numref:`Section %s <UserDefinedGrid>` explains how to create a custom Extended Schmidt Gnomonic grid (ESGgrid), which is the supported grid type for the SRW App. For this example, we created a grid centered over New Orleans, LA (NOLA), which is located at 29.9509 N, 90.0758 W (29.9509, -90.0758). We thank our colleagues at the Developmental Testbed Center (DTC) for their `guidance on this process <https://dtcenter.org/ufs-short-range-weather-srw-practical-session-guide/session-2/3-defining-custom-regional-esg-grid>`_. 

For a custom ESGgrid, users must define three sets of parameters:

   * ESG grid parameters
   * Computational parameters
   * Write-component grid parameters

.. note::

   Users can define the custom grid directly in ``config.yaml``, but in this tutorial, we demonstrate how to add the grid to the set of predefined grids so that it can be reused across multiple experiments. 

First, users must choose a name for the grid. In this example, the grid is named ``SUBCONUS_NOLA_3km``, which describes the domain as being smaller than the continental United States (CONUS), centered over New Orleans, and at a 3-km resolution. Descriptive names are encouraged but not required. 

Users must:

* Add the grid name to the list of valid grid names in ``ufs-srweather-app/ush/valid_param_vals.yaml``. For example:

   .. code-block:: console
      :emphasize-lines: 10

      valid_vals_PREDEF_GRID_NAME: [
      "RRFS_CONUS_25km",
      "RRFS_CONUS_13km",
      "RRFS_CONUS_3km",
      ...
      "SUBCONUS_Ind_3km",
      "WoFS_3km",
      "SUBCONUS_CO_3km",
      "SUBCONUS_CO_1km",
      "SUBCONUS_NOLA_3km"
      ]
   
* Add a stanza describing the parameters for the new grid in ``ufs-srweather-app/ush/predef_grid_params.yaml``. For example: 

   .. code-block:: console

      "SUBCONUS_NOLA_3km":
        GRID_GEN_METHOD: "ESGgrid"
        ESGgrid_LON_CTR: -90.0758
        ESGgrid_LAT_CTR: 29.9509
        ESGgrid_DELX: 3000.0
        ESGgrid_DELY: 3000.0
        ESGgrid_NX: 200
        ESGgrid_NY: 200
        ESGgrid_PAZI: 0.0
        ESGgrid_WIDE_HALO_WIDTH: 6
        DT_ATMOS: 36
        LAYOUT_X: 5
        LAYOUT_Y: 5
        BLOCKSIZE: 40
        QUILTING:
          WRTCMP_write_groups: 1
          WRTCMP_write_tasks_per_group: 5
          WRTCMP_output_grid: "lambert_conformal"
          WRTCMP_cen_lon: -90.0758
          WRTCMP_cen_lat: 29.9509
          WRTCMP_stdlat1: 29.9509
          WRTCMP_stdlat2: 29.9509
          WRTCMP_nx: 197
          WRTCMP_ny: 197
          WRTCMP_lon_lwr_left: -93.59904184257404
          WRTCMP_lat_lwr_left: 27.29340465451015
          WRTCMP_dx: 3000.0
          WRTCMP_dy: 3000.0

.. COMMENT: Explain more about how to determine the grid parameters!!! Including lower left corner! 

**ESGgrid Parameters**

* ``GRID_GEN_METHOD: "ESGgrid"``: This will generate a regional version of the :srw-wiki:`Extended Schmidt Gnomonic (ESG) grid <Purser_UIFCW_2023.pdf>`, which is the supported grid type for the SRW App.
* ``ESGgrid_LON_CTR`` and ``ESGgrid_LAT_CTR``: The longitude and latitude for the center of the grid. 
* ``ESGgrid_DELX`` and ``ESGgrid_DELY``: Grid cell size (in meters) in the x (west-to-east) and y (south-to-north) directions. For a 3-km grid, this value is always 3000 (i.e., 3km). 
* ``ESGgrid_NX`` and ``ESGgrid_NY``: The number of grid cells in the x and y directions.
   .. COMMENT: How do you pick this? Are there limitations?
* ``ESGgrid_PAZI: 0.0``
   .. COMMENT: What is this?
* ``ESGgrid_WIDE_HALO_WIDTH``: Number of :term:`halo` points around the grid with a "wide" halo. This parameter can always be set to ``6`` regardless of the other grid parameters.

**Computational Parameters** 

* ``DT_ATMOS:`` Physics time step (in seconds) to use in the forecast model with this grid. This is the largest time step in the model. It is the time step on which the physics parameterizations are called. In general, ``DT_ATMOS`` depends on the horizontal resolution of the grid. The finer the grid, the smaller it needs to be to avoid numerical instabilities.

   .. COMMENT: See what's in configparams already instead of taking DTC def?

* ``LAYOUT_X`` and ``LAYOUT_Y``: MPI layout --- the number of MPI processes into which to decompose the grid.

   .. COMMENT: Add more about calculating this. 

* ``BLOCKSIZE:`` Machine-dependent parameter that does not have a default value.

   .. COMMENT: Then why is it set here instead of in machine files? How do we pick a good blcoksize? 

**Quilting Parameters**

Certain quilting parameters will be the same as the ESGgrid parameters. For example: 

* Set ``WRTCMP_cen_lon`` and ``WRTCMP_cen_lat`` to the longitude and latitude for the center of the grid (same as ``ESGgrid_LON_CTR`` and ``ESGgrid_LAT_CTR``). 
* Set ``WRTCMP_dx`` and ``WRTCMP_dy`` to the grid cell size (in meters) in the x (west-to-east) and y (south-to-north) directions (same as ``ESGgrid_DELX`` and ``ESGgrid_DELY``). 

Additionally, adjust the following parameters:

* ``WRTCMP_write_groups: 1``
* ``WRTCMP_write_tasks_per_group: 5``
* ``WRTCMP_output_grid:`` The type of write-component grid. This can generally be set to ``"lambert_conformal"``.

   .. COMMENT: Will anything else work?

* ``WRTCMP_stdlat1`` and ``WRTCMP_stdlat2``: The first and second standard latitudes associated with a Lambert conformal coordinate system. For simplicity, use the latitude of the center of the ESGgrid for both.
* ``WRTCMP_nx`` and ``WRTCMP_ny``: To ensure that the write-component grid lies completely within the ESG grid, set these to ~95% of ``ESGgrid_NX`` and ``ESGgrid_NY``, respectively. 


Calculate:

* ``WRTCMP_lon_lwr_left:`` -93.59904184257404
* ``WRTCMP_lat_lwr_left:`` 27.29340465451015


The quilting parameters are used to remap output fields from the native ESG grid onto the write-component grid and then write the remapped grids to a file using a dedicated set of MPI processes.
The UPP (called by the ``run_post`` tasks) cannot process output on the native grid types (“GFDLgrid” and “ESGgrid”), so output fields are interpolated to a write component grid before writing them to an output file. The output files written by the UFS Weather Model use an Earth System Modeling Framework (ESMF) component, referred to as the write component. This model component is configured with settings in the model_configure file, as described in :ref:`Section 4.2.3 <ufs-wm:model_configureFile>` of the UFS Weather Model documentation.


For additional descriptions of the variables that need to be set, see Sections :numref:`%s: ESGgrid Settings <ESGgrid>` and :numref:`%s: Forecast Configuration Parameters <FcstConfigParams>`.

Load the Workflow
--------------------

To load the workflow environment, source the lmod-setup file and load the workflow conda environment by running:

.. include:: ../../doc-snippets/load-env.rst

Then follow the instructions printed to the console and run |activate|. For example, a user on Hercules may issue the following commands to load the workflow:

.. code-block:: console
   
   source $GCB/ufs-srweather-app/etc/lmod-setup.sh hercules
   module use $GCB/ufs-srweather-app/modulefiles
   module load wflow_hercules
   conda activate srw_app

Configuration
---------------

.. include:: ../../doc-snippets/expt-conf-intro.rst

Edit the configuration file (``config.yaml``) to include the variables and values in the sample configuration excerpts below:

.. include:: ../../doc-snippets/file-edit-hint.rst

Start in the ``user:`` section and change the ``MACHINE`` and ``ACCOUNT`` variables. For example, when running on a personal Linux device, users might set:

.. code-block:: console

   user:
      RUN_ENVIR: community
      MACHINE: linux
      ACCOUNT: none

For a detailed description of these variables, see :numref:`Section %s <user>`.

In the ``workflow:`` section of ``config.yaml``, update ``EXPT_SUBDIR``, ``CCPP_PHYS_SUITE:``, ``PREDEF_GRID_NAME``, ``DATE_FIRST_CYCL``, ``DATE_LAST_CYCL``, and ``FCST_LEN_HRS``.

.. code-block:: console

   workflow:
     USE_CRON_TO_RELAUNCH: true
     CRON_RELAUNCH_INTVL_MNTS: 3
     EXPT_SUBDIR: hrrr_nola48
     CCPP_PHYS_SUITE: FV3_RRFS_v1beta
     PREDEF_GRID_NAME: SUBCONUS_NOLA_3km
     DATE_FIRST_CYCL: '2025012100'
     DATE_LAST_CYCL: '2025012100'
     FCST_LEN_HRS: 48
     PREEXISTING_DIR_METHOD: rename
     VERBOSE: true
     COMPILER: intel

.. include:: ../../doc-snippets/cron-note.rst

``EXPT_SUBDIR:`` This variable can be changed to any name the user wants from "RRFSv1_physics_fcst" to "forecast1" to "askdfj" (but note that whitespace and some punctuation characters are not allowed). However, the best names will indicate useful information about the experiment. This tutorial uses ``hrrr_nola48`` to indicate that it is a 48-hour forecast over NOLA using HRRR data. 

``CCPP_PHYS_SUITE:`` The FV3_RRFS_v1beta physics suite was specifically created for convection-allowing scales and is the precursor to the operational physics suite that will be used in the Rapid Refresh Forecast System (:term:`RRFS`). 

.. hint:: 
   
   Later, users may want to conduct additional experiments using the FV3_HRRR and FV3_WoFS_v0 physics suites. Like FV3_RRFS_v1beta, these physics suites were designed for use with high-resolution grids for storm-scale predictions.

``PREDEF_GRID_NAME:`` Replace the default value with the name of the grid you created. For example, we used ``SUBCONUS_NOLA_3km,`` rather than the default RRFS_CONUS_25km grid. 

``DATE_FIRST_CYCL``, ``DATE_LAST_CYCL``, and ``FCST_LEN_HRS`` set parameters related to the date and duration of the forecast. Because this is a one-cycle experiment that does not use cycling or :term:`data assimilation`, the date of the first :term:`cycle` and last cycle are the same. For the Gulf Coast Blizzard forecast, we ran a 48-hour forecast, but 36 hours would have been sufficient. 

For a detailed description of other ``workflow:`` variables, see :numref:`Section %s <workflow>`.

In the ``task_get_extrn_ics:`` section, add ``USE_USER_STAGED_EXTRN_FILES`` and ``EXTRN_MDL_SOURCE_BASEDIR_ICS``. Users will need to adjust the file path to reflect the location of data on their system (see :numref:`Section %s <Data>` for locations on :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems). 

.. code-block:: console
   
   task_get_extrn_ics:
     EXTRN_MDL_NAME_ICS: HRRR
     FV3GFS_FILE_FMT_ICS: grib2
     USE_USER_STAGED_EXTRN_FILES: true
     EXTRN_MDL_SOURCE_BASEDIR_ICS: /path/to/blizzard/data/HRRR

For a detailed description of the ``task_get_extrn_ics:`` variables, see :numref:`Section %s <task_get_extrn_ics>`. 

Similarly, in the ``task_get_extrn_lbcs:`` section, add ``USE_USER_STAGED_EXTRN_FILES`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS``. Users will need to adjust the file path to reflect the location of data on their system (see :numref:`Section %s <Data>` for locations on Level 1 systems). 

.. code-block:: console
   
   task_get_extrn_lbcs:
     EXTRN_MDL_NAME_LBCS: HRRR
     LBC_SPEC_INTVL_HRS: 3
     FV3GFS_FILE_FMT_LBCS: grib2
     USE_USER_STAGED_EXTRN_FILES: true
     EXTRN_MDL_SOURCE_BASEDIR_LBCS: /path/to/blizzard/data/HRRR


For a detailed description of the ``task_get_extrn_lbcs:`` variables, see :numref:`Section %s <task_get_extrn_lbcs>`. 

Users do not need to modify the ``task_run_fcst:`` section for this tutorial. 

Lastly, in the ``task_plot_allvars:`` section, add ``PLOT_FCST_INC: 6`` and  ``PLOT_DOMAINS: ["regional"]``. Users may also want to add ``PLOT_FCST_START: 0`` and ``PLOT_FCST_END: 48`` explicitly, but these can be omitted since the default values are the same as the forecast start and end time respectively. 

.. code-block:: console

   task_plot_allvars:
     COMOUT_REF: ""
     PLOT_FCST_INC: 6
     PLOT_DOMAINS: ["regional"]

``PLOT_FCST_INC:`` This variable indicates the forecast hour increment for the plotting task. By setting the value to ``6``, the task will generate a ``.png`` file for every 6th forecast hour. For the Gulf Coast Blizzard forecast, this is 0z on January 21, 2025 (the 0th forecast hour) through the 48th forecast hour (January 23, 2025 at 0z).

``PLOT_DOMAINS:`` The plotting scripts are designed to generate plots over the entire :term:`CONUS` by default, but by setting this variable to ["regional"], the experiment will generate plots for the smaller SUBCONUS_NOLA_3km regional domain instead. 

To turn on the plotting for the experiment, the plotting YAML file
should be included in the ``rocoto:tasks:taskgroups:`` section, like this:

.. code-block:: console

   rocoto:
     tasks:
       taskgroups: '{{ ["parm/wflow/prep.yaml", "parm/wflow/coldstart.yaml", "parm/wflow/post.yaml", "parm/wflow/plot.yaml"]|include }}'
       metatask_run_ensemble:
         task_run_fcst_mem#mem#:
           walltime: 02:00:00

For more information on how to turn on/off tasks in the workflow, please
see :numref:`Section %s <ConfigTasks>`.

After configuring the forecast, users can generate the forecast by running:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

To see experiment progress, users should navigate to their experiment directory. Then, use the ``rocotorun`` command to launch new workflow tasks and ``rocotostat`` to check on experiment progress. 

.. code-block:: console

   cd /path/to/expt_dirs/hrrr_nola48
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Users will need to rerun the ``rocotorun`` and ``rocotostat`` commands above regularly and repeatedly to continue submitting workflow tasks and receiving progress updates. 

.. note::

   When using cron to automate the workflow submission (as described :ref:`above <CronNote>`), users can omit the ``rocotorun`` command and simply use ``rocotostat`` to check on progress periodically. 

Users can save the location of the ``hrrr_nola48`` directory in an environment variable (``$NOLA``). This makes it easier to navigate between directories later. For example:

.. code-block:: console

   export NOLA=/path/to/expt_dirs/hrrr_nola48

Users should substitute ``/path/to/expt_dirs/hrrr_nola48`` with the actual path on their system. As long as a user remains logged into their system, they can run ``cd $NOLA``, and it will take them to the ``hrrr_nola48`` experiment directory. The variable will need to be reset for each login session. 

.. code-block:: console

         CYCLE                  TASK        JOBID       STATE  EXIT TRIES  DURATION
                                                               STATUS
   =================================================================================
   202501210000             make_grid      4348919   SUCCEEDED     0    1   24.0
   202501210000             make_orog      4348937   SUCCEEDED     0    1   48.0
   202501210000        make_sfc_climo      4349065   SUCCEEDED     0    1   41.0
   202501210000         get_extrn_ics      4348920   SUCCEEDED     0    1   29.0
   202501210000        get_extrn_lbcs      4348921   SUCCEEDED     0    1   62.0
   202501210000       make_ics_mem000      4349103   SUCCEEDED     0    1   46.0
   202501210000      make_lbcs_mem000      4349104   SUCCEEDED     0    1   26.0
   202501210000       run_fcst_mem000      4349747   SUCCEEDED     0    1   46.0
   202501210000  run_post_mem000_f000      4349918   SUCCEEDED     0    1   38.0
   202501210000  run_post_mem000_f001      4349919   SUCCEEDED     0    1   25.0
   202501210000  run_post_mem000_f002      4349920   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f003      4350024   SUCCEEDED     0    1   29.0
   202501210000  run_post_mem000_f004      4350025   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f005      4350026   SUCCEEDED     0    1   23.0
   202501210000  run_post_mem000_f006      4350053   SUCCEEDED     0    1   43.0
   202501210000  run_post_mem000_f007      4350054   SUCCEEDED     0    1   42.0
   202501210000  run_post_mem000_f008      4350091   SUCCEEDED     0    1   27.0
   202501210000  run_post_mem000_f009      4350092   SUCCEEDED     0    1   27.0
   202501210000  run_post_mem000_f010      4350093   SUCCEEDED     0    1   25.0
   202501210000  run_post_mem000_f011      4350123   SUCCEEDED     0    1   44.0
   202501210000  run_post_mem000_f012      4350124   SUCCEEDED     0    1   44.0
   202501210000  run_post_mem000_f013      4350125   SUCCEEDED     0    1   44.0
   202501210000  run_post_mem000_f014      4350165   SUCCEEDED     0    1   26.0
   202501210000  run_post_mem000_f015      4350166   SUCCEEDED     0    1   38.0
   202501210000  run_post_mem000_f016      4350202   SUCCEEDED     0    1   35.0
   202501210000  run_post_mem000_f017      4350203   SUCCEEDED     0    1   24.0
   202501210000  run_post_mem000_f018      4350215   SUCCEEDED     0    1   24.0
   202501210000  run_post_mem000_f019      4350216   SUCCEEDED     0    1   25.0
   202501210000  run_post_mem000_f020      4350217   SUCCEEDED     0    1   35.0
   202501210000  run_post_mem000_f021      4350243   SUCCEEDED     0    1   29.0
   202501210000  run_post_mem000_f022      4350244   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f023      4350281   SUCCEEDED     0    1   24.0
   202501210000  run_post_mem000_f024      4350282   SUCCEEDED     0    1   25.0
   202501210000  run_post_mem000_f025      4350312   SUCCEEDED     0    1   27.0
   202501210000  run_post_mem000_f026      4350313   SUCCEEDED     0    1   27.0
   202501210000  run_post_mem000_f027      4350314   SUCCEEDED     0    1   26.0
   202501210000  run_post_mem000_f028      4350333   SUCCEEDED     0    1   25.0
   202501210000  run_post_mem000_f029      4350334   SUCCEEDED     0    1   26.0
   202501210000  run_post_mem000_f030      4350346   SUCCEEDED     0    1   26.0
   202501210000  run_post_mem000_f031      4350347   SUCCEEDED     0    1   30.0
   202501210000  run_post_mem000_f032      4350348   SUCCEEDED     0    1   30.0
   202501210000  run_post_mem000_f033      4350362   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f034      4350363   SUCCEEDED     0    1   29.0
   202501210000  run_post_mem000_f035      4350382   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f036      4350383   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f037      4350384   SUCCEEDED     0    1   25.0
   202501210000  run_post_mem000_f038      4350404   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f039      4350405   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f040      4350406   SUCCEEDED     0    1   25.0
   202501210000  run_post_mem000_f041      4350430   SUCCEEDED     0    1   43.0
   202501210000  run_post_mem000_f042      4350431   SUCCEEDED     0    1   43.0
   202501210000  run_post_mem000_f043      4350442   SUCCEEDED     0    1   45.0
   202501210000  run_post_mem000_f044      4350443   SUCCEEDED     0    1   45.0
   202501210000  run_post_mem000_f045      4350444   SUCCEEDED     0    1   45.0
   202501210000  run_post_mem000_f046      4350445   SUCCEEDED     0    1   42.0
   202501210000  run_post_mem000_f047      4350446   SUCCEEDED     0    1   42.0
   202501210000  run_post_mem000_f048      4350447   SUCCEEDED     0    1   41.0
   202501210000  plot_allvars_mem000_f000  4350460   SUCCEEDED     0    1   09.0
   202501210000  plot_allvars_mem000_f001  4350461   SUCCEEDED     0    1   87.0
   202501210000  plot_allvars_mem000_f002  4350462   SUCCEEDED     0    1   89.0
   202501210000  plot_allvars_mem000_f003  4350463   SUCCEEDED     0    1   77.0
   202501210000  plot_allvars_mem000_f004  4350464   SUCCEEDED     0    1   73.0
   202501210000  plot_allvars_mem000_f005  4350465   SUCCEEDED     0    1   96.0
   202501210000  plot_allvars_mem000_f006  4350466   SUCCEEDED     0    1   79.0
   202501210000  plot_allvars_mem000_f007  4350467   SUCCEEDED     0    1   84.0
   202501210000  plot_allvars_mem000_f008  4350468   SUCCEEDED     0    1   00.0
   202501210000  plot_allvars_mem000_f009  4350469   SUCCEEDED     0    1   98.0
   202501210000  plot_allvars_mem000_f010  4350470   SUCCEEDED     0    1   81.0
   202501210000  plot_allvars_mem000_f011  4350471   SUCCEEDED     0    1   81.0
   202501210000  plot_allvars_mem000_f012  4350472   SUCCEEDED     0    1   81.0
   202501210000  plot_allvars_mem000_f013  4350473   SUCCEEDED     0    1   80.0
   202501210000  plot_allvars_mem000_f014  4350474   SUCCEEDED     0    1   01.0
   202501210000  plot_allvars_mem000_f015  4350475   SUCCEEDED     0    1   98.0
   202501210000  plot_allvars_mem000_f016  4350476   SUCCEEDED     0    1   98.0
   202501210000  plot_allvars_mem000_f017  4350477   SUCCEEDED     0    1   07.0
   202501210000  plot_allvars_mem000_f018  4350478   SUCCEEDED     0    1   08.0
   202501210000  plot_allvars_mem000_f019  4350479   SUCCEEDED     0    1   65.0
   202501210000  plot_allvars_mem000_f020  4350480   SUCCEEDED     0    1   62.0
   202501210000  plot_allvars_mem000_f021  4350481   SUCCEEDED     0    1   89.0
   202501210000  plot_allvars_mem000_f022  4350482   SUCCEEDED     0    1   89.0
   202501210000  plot_allvars_mem000_f023  4350483   SUCCEEDED     0    1   08.0
   202501210000  plot_allvars_mem000_f024  4350484   SUCCEEDED     0    1   88.0
   202501210000  plot_allvars_mem000_f025  4350485   SUCCEEDED     0    1   85.0
   202501210000  plot_allvars_mem000_f026  4350486   SUCCEEDED     0    1   84.0
   202501210000  plot_allvars_mem000_f027  4350487   SUCCEEDED     0    1   11.0
   202501210000  plot_allvars_mem000_f028  4350488   SUCCEEDED     0    1   11.0
   202501210000  plot_allvars_mem000_f029  4350489   SUCCEEDED     0    1   96.0
   202501210000  plot_allvars_mem000_f030  4350490   SUCCEEDED     0    1   97.0
   202501210000  plot_allvars_mem000_f031  4350491   SUCCEEDED     0    1   96.0
   202501210000  plot_allvars_mem000_f032  4350492   SUCCEEDED     0    1   85.0
   202501210000  plot_allvars_mem000_f033  4350493   SUCCEEDED     0    1   81.0
   202501210000  plot_allvars_mem000_f034  4350494   SUCCEEDED     0    1   80.0
   202501210000  plot_allvars_mem000_f035  4350495   SUCCEEDED     0    1   79.0
   202501210000  plot_allvars_mem000_f036  4350496   SUCCEEDED     0    1   77.0
   202501210000  plot_allvars_mem000_f037  4350497   SUCCEEDED     0    1   77.0
   202501210000  plot_allvars_mem000_f038  4350498   SUCCEEDED     0    1   30.0
   202501210000  plot_allvars_mem000_f039  4350499   SUCCEEDED     0    1   03.0
   202501210000  plot_allvars_mem000_f040  4350500   SUCCEEDED     0    1   81.0
   202501210000  plot_allvars_mem000_f041  4350501   SUCCEEDED     0    1   71.0
   202501210000  plot_allvars_mem000_f042  4350502   SUCCEEDED     0    1   61.0
   202501210000  plot_allvars_mem000_f043  4350503   SUCCEEDED     0    1   90.0
   202501210000  plot_allvars_mem000_f044  4350504   SUCCEEDED     0    1   73.0
   202501210000  plot_allvars_mem000_f045  4350505   SUCCEEDED     0    1   37.0
   202501210000  plot_allvars_mem000_f046  4350506   SUCCEEDED     0    1   78.0
   202501210000  plot_allvars_mem000_f047  4350507   SUCCEEDED     0    1   85.0
   202501210000  plot_allvars_mem000_f048  4350508   SUCCEEDED     0    1   93.0

Analyze Results
----------------

Navigate to the ``postprd`` directory for the date of your forecast (e.g. ``$GCB/expt_dirs/hrrr_nola48/2025012100/postprd``). This directory contains the post-processed data generated by the :term:`UPP` from the ``hrrr_nola48`` forecast. After the ``plot_allvars`` task completes, this directory will contain ``.png`` images for several forecast variables including 2-m temperature, 10-m winds, accumulated precipitation, and composite reflectivity. 

.. note::

   There are many options for viewing plots, and instructions for this are highly machine-dependent. Users should view the data transfer documentation for their system to secure copy files from a remote system (such as :term:`RDHPCS`) to their local system. 
   Another option is to download `Xming <https://sourceforge.net/projects/xming/>`_ (for Windows) or `XQuartz <https://www.xquartz.org/>`_ (for Mac), use the ``-X`` option when connecting to a remote system via SSH, and run:

   .. code-block:: console

      module load imagemagick
      display file_name.png

   where ``file_name.png`` is the name of the file to display/view. Depending on the system, users may need to install imagemagick and/or adjust other settings (e.g., for X11 forwarding). Users should contact their machine administrator with any questions. 

2m-Temperature
^^^^^^^^^^^^^^^^

.. list-table:: 2-m Temperature by Forecast Hour
   :widths: 25 25 25 25
   :header-rows: 1

   * - f000
     - f012
     - f024
     - f036
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f000.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f012.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f036.png
          :align: center

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/temperature_gradient.png
   :align: center
   :width: 50%

.. COMMENT: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f000.png

10m-Winds
^^^^^^^^^^^

.. list-table:: 10-m Wind by Forecast Hour
   :widths: 25 25 25 25
   :header-rows: 1

   * - f000
     - f012
     - f024
     - f036
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/10mwind_regional_f000.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/10mwind_regional_f012.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/10mwind_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/10mwind_regional_f036.png
          :align: center

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/wind_gradient.png
   :align: center
   :width: 50%

Composite Reflectivity
^^^^^^^^^^^^^^^^^^^^^^^^

.. list-table:: Composite Reflectivity by Forecast Hour
   :widths: 25 25 25 25
   :header-rows: 1

   * - f000
     - f012
     - f024
     - f036
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_regional_f000.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_regional_f012.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_regional_f036.png
          :align: center

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_gradient.png
   :align: center
   :width: 50%

Accumulated Precipitation
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. list-table:: Accumulated Precipitation by Forecast Hour
   :widths: 25 25 25
   :header-rows: 1

   * - f012
     - f024
     - f036
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_regional_f012.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_regional_f036.png
          :align: center

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_gradient.png
   :align: center
   :width: 50%
