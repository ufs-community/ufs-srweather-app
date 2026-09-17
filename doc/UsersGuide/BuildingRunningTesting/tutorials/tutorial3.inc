
.. _fcst6:

Sample Forecast #6: Choose Your Own Adventure!
================================================

**Objective:** Create a forecast of your choice on a custom grid using publicly available data. 

Weather Summary
--------------------

Weather will vary depending on the case the user chooses. In this example, we use the Gulf Coast Blizzard from January 21, 2025 (2025-01-21), with a custom regional grid centered over New Orleans, LA. 

In this case, the polar vortex stretched far south bringing cold, dry air to the Gulf Coast, where it met the comparatively warm, moist air from the Gulf, leading to unprecedented snowfall followed by record low temperatures. 

**Weather Phenomena:** Record-breaking snow and cold temperatures throughout the region. 

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/nola_blizzard.gif
   :alt: Radar animation of severe weather over New Orleans, LA on January 21, 2021. The animation shows areas of heavy snow moving from west to east over New Orleans and across the Gulf Coast. 

   *Incoming Blizzard Over New Orleans*

Preliminary Steps
-------------------
It is recommended that users create a directory on their system where they will store data and run their forecast. In this example, we make a directory called ``blizzard`` and navigate into it: 

.. code-block:: console

   mkdir blizzard
   cd blizzard
   
Users can save the location of the this directory in an environment variable such as ``$GCB`` (for Gulf Coast Blizzard). This makes it easier to navigate between directories later. For example:

.. code-block:: console

   export GCB=/path/to/blizzard

where ``/path/to/`` is replaced with the full path to the ``blizzard`` directory on the user's system.

Data
-------

Users can set up a forecast for a weather case of their choice using data downloaded from a publicly available source. The SRW App requires:

   * **Fix files** -- Static datasets containing climatological information, terrain, and land use data
   * **Initial and boundary conditions files**
   * **Natural Earth Shapefiles** for use in optional plotting tasks 

Fix Files
^^^^^^^^^^

Fix files are publicly available in the `SRW App Data Bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`_. Users can download the full set of fix files and untar it:

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/experiment-user-cases/release-public-v2.2.0/out-of-the-box/fix_data.tgz
   tar -xzf fix_data.tgz

.. COMMENT: Update path for SRW v3.0.0 release

Initial and Boundary Conditions Files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Initial conditions (ICs) files provide information on the state of the atmosphere at the start of the forecast. Because the SRW App uses regional grids, it needs to update the forecast periodically with information about the state of the atmosphere at the edges of the grid. These are called the lateral boundary conditions (LBCs). 

IC and LBC data must be in ``NetCDF``, ``grib2``, or ``nemsio`` format. There are several potential sources of publicly available data listed in :numref:`Section %s <stage-ics-manually>`. Many of these sources only include data for the last 1-30 days, so it is recommended that users download the data that they think they will need and store the data somewhere so that they are still accessible even when no longer available on these sites. 

When choosing data, users should consider the type of weather they are trying to model, the size of the domain they plan to use, and the compute resources available to them. This will help to determine what grid size and resolution is most appropriate. There is more information on regional (or "limited area model") grids available in :numref:`Section %s <LAMGrids>`. 

When modeling severe weather, it is preferable to use a high-resolution (~1-4km) grid along with physics suites and data designed for these convection-allowing scales. Therefore, High-Resolution Rapid Refresh (HRRR) data were downloaded for this case. According to NOAA, "`HRRR <https://rapidrefresh.noaa.gov/hrrr/>`_ is a NOAA real-time 3-km resolution, hourly updated, cloud-resolving, convection-allowing atmospheric model, initialized by 3km grids with 3km radar assimilation."

To download data for this case, users can create a directory named ``data`` (in ``$GCB`` or an equivalent directory) and place the ``get_data.py`` script in there:

.. code-block:: console

   mkdir data
   cd data

Users can download the ``get_data.py`` :srw-wiki:`utility script <Tutorial/get_data.py>` with ``wget`` or copy-paste the contents of the script into a file on their system to download recent HRRR data from the `Planetary Computer <https://planetarycomputer.microsoft.com/dataset/storage/noaa-hrrr>`_ site. 

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

When creating this experiment, the following command was used to download the data:

.. code-block:: console

   python3 get_data.py -p wrfprsf -d 2025012100 -f 0 3 6 9 12 15 18 21 24 27 30 33 36

Users will need to adjust this command for the specific date(s) and forecast hours they need for their experiment. Although the Gulf Coast Blizzard data is no longer available via Planetary Computer, it has been added to the `SRW Data Bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`_ and placed on :srw-wiki:`Level 1 <Supported-Platforms-and-Compilers>` systems in the usual input model data locations (see :numref:`Section %s <DataLocations>` for a list). Users can retrieve this data from the SRW App data bucket by running:

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/develop-20240618/gulf_coast_blizzard.tar.gz

However, users are encouraged to experiment with downloading their own data for a case of interest!

Natural Earth Shapefiles
^^^^^^^^^^^^^^^^^^^^^^^^^

The small set of Natural Earth shapefiles required for SRW App plotting tasks is publicly available in the `SRW App Data Bucket <https://registry.opendata.aws/noaa-ufs-shortrangeweather/>`_. Users can download and untar the files:

.. code-block:: console

   wget https://noaa-ufs-srw-pds.s3.amazonaws.com/develop-20240618/NaturalEarth.tar.gz
   tar xvfz NaturalEarth.tgz

The full set of Natural Earth shapefiles can also be downloaded from the `Natural Earth website <https://www.naturalearthdata.com/downloads/>`_. 

Download the SRW App
---------------------

To start an experiment, navigate to your working directory. For example:

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

The SRW App already contains several predefined grids, which are well-tested with the supported physics and data sources. While these are a great start for new users, they cover a narrow set of possible grid configurations. Users may be interested in creating their own custom grid instead. :numref:`Section %s <UserDefinedGrid>` explains how to create a custom Extended Schmidt Gnomonic grid (ESGgrid), which is the supported grid type for the SRW App. For this example, we created a grid centered over New Orleans, LA (NOLA), which is located at 29.9509º N, 90.0758º W (29.9509, -90.0758). We thank our colleagues at the Developmental Testbed Center (DTC) for their :srw-wiki:`guidance on this process <Tutorial/DTC_Defining_Custom_Regional_ESGGrid.pdf>`. 

For a custom ESGgrid, users must define three sets of parameters:

   #. ESG grid parameters
   #. Computational parameters
   #. Write-component grid parameters

.. note::

   Users can define the custom grid directly in ``config.yaml``, but in this tutorial, we demonstrate how to add the grid to the set of predefined grids so that it can be reused across multiple experiments. 

First, users must choose a name for the grid. In this example, the grid is named ``SUBCONUS_NOLA_3km``, which describes the domain as being smaller than the continental United States (CONUS); centered over New Orleans, LA; and at a 3-km resolution. Descriptive names are encouraged but not required. 

Users must:

#. Add the grid name to the list of valid grid names in ``ufs-srweather-app/ush/valid_param_vals.yaml``. For example:

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
   
#. Add a stanza describing the parameters for the new grid in ``ufs-srweather-app/ush/predef_grid_params.yaml``. For example: 

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
* ``ESGgrid_DELX`` and ``ESGgrid_DELY``: Grid cell size (in meters) in the x- (west-to-east) and y- (south-to-north) directions. For a 3-km grid, this value is always 3000 (i.e., 3 km). 
* ``ESGgrid_NX`` and ``ESGgrid_NY``: The number of grid cells in the x and y directions. This setting will be based on how much area the grid should cover. For example, a grid that is approximately 1200 km wide by 1200 km tall would have ``ESGgrid_NX`` and ``ESGgrid_NY`` values of approximately 400 --- :math:`1200 km / 3 km` per cell. 
* ``ESGgrid_PAZI``: The rotation of the grid from true north (in degrees). This can generally be set to zero. 
* ``ESGgrid_WIDE_HALO_WIDTH``: Number of :term:`halo` points around the grid with a "wide" halo. This parameter can always be set to ``6`` regardless of the other grid parameters.

**Computational Parameters** 

* ``DT_ATMOS:`` Physics time step (in seconds) to use in the forecast model with this grid. This is the largest time step in the model. It is the time step on which the physics parameterizations are called. In general, ``DT_ATMOS`` must be smaller for higher horizontal grid resolutions to avoid numerical instabilities (specifically, Courant-Friedrichs-Lewy [CFL] conditions). Users can examine predefined grids of similar resolutions to their custom grid for suggested values. 
* ``LAYOUT_X`` and ``LAYOUT_Y``: MPI layout --- the number of MPI processes into which to decompose the grid. 
* ``BLOCKSIZE:`` Machine-dependent parameter that does not have a default value.

.. COMMENT: Would be good to add more about calculating LAYOUT_X and LAYOUT_Y. Also, why is BLOCKSIZE set here instead of in machine files? How do we pick a good blocksize? 

**Quilting Parameters**

.. note::
   
   The :term:`UPP` (called by the ``run_post_*`` tasks) cannot process output on the native grid types (“GFDLgrid” and “ESGgrid”), so output fields are interpolated to a write component grid before writing them to an output file. The output files written by the UFS Weather Model use an Earth System Modeling Framework (ESMF) component, referred to as the write component. This model component is configured with settings in the ``model_configure`` file, as described in :ref:`Section 4.2.3 <ufs-wm:model_configureFile>` of the UFS Weather Model documentation.

Certain quilting parameters will be the same as the ESGgrid parameters. For example: 

* Set ``WRTCMP_cen_lon`` and ``WRTCMP_cen_lat`` to the longitude and latitude for the center of the grid (same as ``ESGgrid_LON_CTR`` and ``ESGgrid_LAT_CTR``). 
* Set ``WRTCMP_dx`` and ``WRTCMP_dy`` to the grid cell size (in meters) in the x- (west-to-east) and y- (south-to-north) directions (same as ``ESGgrid_DELX`` and ``ESGgrid_DELY``). 

Additionally, adjust the following parameters:

* ``WRTCMP_write_groups:`` Each write group consists of a set of dedicated :term:`MPI` processes that writes the fields on the write-component grid to a file on disk while the forecast continues to run on a separate set of processes. This value can usually be set to 1 but may need to be increased for grids with more grid points (larger domain or higher resolution). 
* ``WRTCMP_write_tasks_per_group:`` The number of MPI processes per group. For the Gulf Coast Blizzard case, this can be set to 5, but it may need to be increased for larger grids with more grid points (larger domain or higher resolution). 
* ``WRTCMP_output_grid:`` The type of write-component grid. This can generally be set to ``"lambert_conformal"``. 
* ``WRTCMP_stdlat1`` and ``WRTCMP_stdlat2``: The first and second standard latitudes associated with a Lambert conformal coordinate system. For simplicity, use the latitude of the center of the ESGgrid for both. Using off-center standard latitude values will skew the write-component grid to the east or west, somewhat similar to ``ESGgrid_PAZI``.
* ``WRTCMP_nx`` and ``WRTCMP_ny``: To ensure that the write-component grid lies completely within the ESG grid, set these to ~95% of ``ESGgrid_NX`` and ``ESGgrid_NY``, respectively. 

Then, calculate the values of ``WRTCMP_lon_lwr_left`` and ``WRTCMP_lat_lwr_left``. According to the :srw-wiki:`DTC guidance <Tutorial/DTC_Defining_Custom_Regional_ESGGrid.pdf>`, "approximate values (from a linearization that is more accurate the smaller the horizontal extent of the grid) for these quantities can be obtained using the formulas (for reference)":

* :math:`WRTCMP\_lon\_lwr\_left = WRTCMP\_cen\_lon - (degs\_per\_meter/(2*cos\_phi\_ctr))*WRTCMP\_nx*WRTCMP\_dx`
* :math:`WRTCMP\_lat\_lwr\_left = WRTCMP\_cen\_lat - (degs\_per\_meter/2)*WRTCMP\_ny*WRTCMP\_dy`

where: 

   * :math:`pi\_geom ≈ 3.14`
   * :math:`radius\_Earth ≈ 6371000m`
   * :math:`cos\_phi\_ctr = cos((180/pi\_geom)*WRTCMP\_lat\_lwr\_left)`
   * :math:`degs\_per\_meter = 180/(pi\_geom*radius\_Earth)`

For the NOLA grid, this comes out to:

* ``WRTCMP_lon_lwr_left:`` -93.59904184257404
* ``WRTCMP_lat_lwr_left:`` 27.29340465451015

For supplemental descriptions of the variables that need to be set, see Sections :numref:`%s: ESGgrid Settings <ESGgrid>` and :numref:`%s: Forecast Configuration Parameters <FcstConfigParams>`.

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

Start in the ``user:`` section of ``config.yaml`` and change the ``MACHINE`` and ``ACCOUNT`` variables. For example, when running on a personal Linux device, users might set:

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
     EXPT_SUBDIR: hrrr_nola36
     CCPP_PHYS_SUITE: FV3_HRRR
     PREDEF_GRID_NAME: SUBCONUS_NOLA_3km
     DATE_FIRST_CYCL: '2025012100'
     DATE_LAST_CYCL: '2025012100'
     FCST_LEN_HRS: 36
     PREEXISTING_DIR_METHOD: rename
     VERBOSE: true
     COMPILER: intel

.. include:: ../../doc-snippets/cron-note.rst

``EXPT_SUBDIR:`` This variable can be changed to any name the user wants from "HRRR_physics_fcst" to "forecast1" to "askdfj" (but note that whitespace and some punctuation characters are not allowed). However, the best names will indicate useful information about the experiment. This tutorial uses ``hrrr_nola36`` to indicate that it is a 36-hour forecast over NOLA using HRRR data. 

``CCPP_PHYS_SUITE:`` The FV3_HRRR physics suite was specifically created for convection-allowing scales. Users are welcome to try other physics suites designed for high-resolution grids and storm-scale predictions (e.g., FV3_WoFS_v0). 

``PREDEF_GRID_NAME:`` Replace the default value with the name of the grid you created. For example, we used ``SUBCONUS_NOLA_3km,`` rather than the default RRFS_CONUS_25km grid. 

``DATE_FIRST_CYCL``, ``DATE_LAST_CYCL``, and ``FCST_LEN_HRS`` set parameters related to the date and duration of the forecast. Because this is a one-cycle experiment that does not use cycling or :term:`data assimilation`, the date of the first :term:`cycle` and last cycle are the same. The SRW App will perform best for forecast durations of 48 hours or less, but users can choose longer durations if desired. 

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

Lastly, in the ``task_plot_allvars:`` section, add ``PLOT_FCST_INC: 6`` and  ``PLOT_DOMAINS: ["regional"]``. Users may also want to add ``PLOT_FCST_START: 0`` and ``PLOT_FCST_END: 36`` explicitly, but these can be omitted since the default values are the same as the forecast start and end time respectively. 

.. code-block:: console

   task_plot_allvars:
     COMOUT_REF: ""
     PLOT_FCST_INC: 6
     PLOT_DOMAINS: ["regional"]

``PLOT_FCST_INC:`` This variable indicates the forecast hour increment for the plotting task. By setting the value to ``6``, the task will generate ``.png`` files for every 6th forecast hour. For the Gulf Coast Blizzard forecast, this is 0z on January 21, 2025 (the 0th forecast hour) through the 36th forecast hour (January 22, 2025 at 12z).

``PLOT_DOMAINS:`` The plotting scripts are designed to generate plots over the entire :term:`CONUS` by default, but by setting this variable to ["regional"], the experiment will generate plots for the smaller custom regional domain (e.g., SUBCONUS_NOLA_3km) instead. 

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

   cd $GCB/expt_dirs/hrrr_nola36
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

Users will need to rerun the ``rocotorun`` and ``rocotostat`` commands above regularly and repeatedly to continue submitting workflow tasks and receiving progress updates. 

.. note::

   When using cron to automate the workflow submission (as described :ref:`above <CronNote>`), users can omit the ``rocotorun`` command and simply use ``rocotostat`` to check on progress periodically. 

Users can save the location of the ``hrrr_nola36`` directory in an environment variable (``$NOLA``). This makes it easier to navigate between directories later. For example:

.. code-block:: console

   export NOLA=$GCB/expt_dirs/hrrr_nola36

As long as a user remains logged into their system, they can run ``cd $NOLA``, and it will take them to the ``hrrr_nola36`` experiment directory. The variable will need to be reset for each login session. 

The workflow run is complete when all tasks have “SUCCEEDED”. If everything goes smoothly, users will eventually see a workflow status table similar to the following:

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
   ...
   202501210000  run_post_mem000_f033      4350362   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f034      4350363   SUCCEEDED     0    1   29.0
   202501210000  run_post_mem000_f035      4350382   SUCCEEDED     0    1   28.0
   202501210000  run_post_mem000_f036      4350383   SUCCEEDED     0    1   28.0
   202501210000  plot_allvars_mem000_f000  4350460   SUCCEEDED     0    1   09.0
   202501210000  plot_allvars_mem000_f001  4350461   SUCCEEDED     0    1   87.0
   202501210000  plot_allvars_mem000_f002  4350462   SUCCEEDED     0    1   89.0
   202501210000  plot_allvars_mem000_f003  4350463   SUCCEEDED     0    1   77.0
   ...
   202501210000  plot_allvars_mem000_f033  4350493   SUCCEEDED     0    1   81.0
   202501210000  plot_allvars_mem000_f034  4350494   SUCCEEDED     0    1   80.0
   202501210000  plot_allvars_mem000_f035  4350495   SUCCEEDED     0    1   79.0
   202501210000  plot_allvars_mem000_f036  4350496   SUCCEEDED     0    1   77.0

If tasks fail, examine the log files in the experiment directory (e.g., ``$GCB/expt_dirs/hrrr_nola36/log``). 
To rerun tasks, view information on :ref:`useful Rocoto workflow commands <RocotoInfo>`. 

Analyze Results
----------------

Navigate to the ``postprd`` directory for the date of your forecast (e.g., ``$GCB/expt_dirs/hrrr_nola36/2025012100/postprd``). This directory contains the post-processed data generated by the :term:`UPP` from the forecast. After the ``plot_allvars`` task completes, this directory will contain ``.png`` images for several forecast variables. The most appropriate variables to track will differ for each case. Given the predictions for blizzard conditions and extreme cold, this tutorial examines the progression of the storm via predictions of 2-m temperature, 10-m winds, composite reflectivity, and accumulated precipitation. In layman's terms, 2-m temperature is the temperature close to (2 meters from) the Earth's surface; 10-m wind is the wind velocity at the lowest atmospheric level; reflectivity measures the energy (in decibels [dBZ]) reflected back from radar, and composite reflectivity generates an image based on reflectivity scans at multiple elevation angles, or “tilts”, of the antenna. Accumulated precipitation measures how much precipitation is predicted to fall. 

.. note::

   There are many options for viewing plots, and instructions for this are highly machine-dependent. Users can view the data transfer documentation for their system to secure-copy files from a remote system (such as :term:`RDHPCS`) to their local system. 
   Another option is to download `Xming <https://sourceforge.net/projects/xming/>`_ (for Windows) or `XQuartz <https://www.xquartz.org/>`_ (for Mac), use the ``-X`` option when connecting to a remote system via SSH, and run:

   .. code-block:: console

      module load imagemagick
      display file_name.png

   where ``file_name.png`` is the name of the file to display/view. Depending on the system, users may need to install imagemagick and/or adjust other settings (e.g., for X11 forwarding). Users should contact their machine administrator with any questions. 

Forecast Hour 000
^^^^^^^^^^^^^^^^^^

At forecast hour zero (f000, 6pm local time), the 2-m temperature plot shows that the air over land is significantly colder than the more moist air over the water, creating prime conditions for precipitation along the front. At f000, winds were also predicted to pick up over the Gulf coast, bringing winds of up to 25 knots (~29 mph). For reference, the National Weather Service (NWS) describes these as windy conditions; however, wind damage is unlikely to result (https://www.weather.gov/mlb/seasonal_wind_threat). The composite reflectivity plot shows that areas of precipitation are building along the southern and western edges of the map. At f000, there can be no *accumulated* precipitation. 

.. list-table:: Initial Conditions (2025-01-21 0z)
   :widths: 25 25 25
   :header-rows: 1

   * - 2-m Temperature
     - 10-m Wind
     - Composite Reflectivity
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f000.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/10mwind_regional_f000.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_regional_f000.png
          :align: center
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/temperature_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/wind_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_gradient.png
          :align: center

.. note:: 

   Users may wish to adjust the plotting script to limit the temperature range for this experiment, since this is a cold weather case where temperatures are not likely to increase to the extreme of 128+ºF. This change would show the contrast in temperatures over land and water more clearly. 

At this point, NWS was warning of potential blizzard conditions on a variety of platforms, including social media:

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/gcb_FB.png
   :align: center
   :width: 50%

   *NWS Lake Charles, LA on Facebook*


Forecast Hour 012
^^^^^^^^^^^^^^^^^^

At forecast hour 12, folks in New Orleans normally would have been preparing for their morning commute to work. However, on Jan. 21, 2025 at 6am CT, snow was falling in a place that rarely sees snow, and winds had picked up. By 8am, meteorologist A.J. Mastrangelo noted that the weather "[a]lmost looks like a hurricane... only with snow as the precip type!"

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/gcb_X_blizzard.png
   :align: center
   :width: 50%

   *The morning commute in New Orleans, LA*

The SRW App plots indicate a drop in temperature during the night and an increase in winds and precipitation. The predicted drop in 2-m temperature over land would increase the temperature differential between the relatively warm air over the waters and the colder temperatures over land. This, in turn, would be likely to cause more severe weather. By f012, the wind was also predicted to pick up, and the patch of red in the southeast corner of the plot shows incoming winds reaching 40 knots (~46 mph) off the coast. The composite reflectivity image shows significant precipitation with a few high-energy spots in red-orange popping up. Precipitation was predicted to start accumulating somewhat. For people who are not used to driving in these conditions, it could be dangerous, but the bigger danger would be how to get home. Conditions were deteriorating, and the worst snowfall was expected in the 11 AM -- 6 PM window.

.. list-table:: Conditions at f012 (2025-01-21 12z)
   :widths: 25 25 25 25
   :header-rows: 1

   * - 2-m Temperature
     - 10-m Wind
     - Composite Reflectivity
     - Accumulated Precipitation
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f012.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/10mwind_regional_f012.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_regional_f012.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_regional_f012.png
          :align: center
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/temperature_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/wind_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_gradient.png
          :align: center

Forecast Hour 024
^^^^^^^^^^^^^^^^^^

By f024, or 6pm CT on January 21, most people had enjoyed a snow day --- possibly their first, complete with Mardi Gras snowmen. Check out `more photos here <https://www.axios.com/local/new-orleans/2025/01/21/in-photos-historic-snowstorm-new-orleans-louisiana>`_! 

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/gcb_davidnola.png
          :align: center
          :width: 50%

          *Mardi Gras snowman (by @davidnola on Instagram)*

The SRW App plots show that by f024f (6 PM local time), temperatures were predicted to warm slightly over the course of the day before taking a plunge overnight. Winds were predicted to move eastward and calm somewhat. Composite reflectivity plots show that the snow was anticipated to move eastward and calm over the New Orleans area with fewer high-energy orangey-red areas. At this point, the SRW App forecast shows less than two inches of accumulated precipitation, but note that this is the liquid water equivalent. Depending on the type of snow, the snow liquid ratio (SLR) can be as low as 5:1 in warmer temperatures with very wet snow to 20:1 for dry, powdery snow in colder temperatures. More information would be needed to assess quantitatively how accurate the forecast is, but an SLR of 10:1 can be used as a general rule of thumb (https://www.weather.gov/arx/why_snowratios).  

.. list-table:: Conditions at f024 (2025-01-22 0z)
   :widths: 25 25 25 25
   :header-rows: 1

   * - 2-m Temperature
     - 10-m Wind
     - Composite Reflectivity
     - Accumulated Precipitation
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/10mwind_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_regional_f024.png
          :align: center
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/temperature_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/wind_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_gradient.png
          :align: center

Regardless, NWS was predicting a severe drop in temperatures overnight.

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/gcb_cold.png
   :align: center
   :width: 50%

   *Dangerous drop in temperatures overnight*


Forecast Hour 036
^^^^^^^^^^^^^^^^^^

Like the NWS, the SRW App predicted a drop in temperatures overnight. Plots show the winds dissipating, precipitation trailing off, and a total accumulated precipitation of less than 2 inches. 

.. list-table:: Conditions at f024 (2025-01-22 0z)
   :widths: 25 25 25 25
   :header-rows: 1

   * - 2-m Temperature
     - 10-m Wind
     - Composite Reflectivity
     - Accumulated Precipitation
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/2mt_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/10mwind_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_regional_f024.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_regional_f024.png
          :align: center
   * - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/temperature_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/wind_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/refc_gradient.png
          :align: center
     - .. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/qpf_gradient.png
          :align: center

This generally corresponds with how the storm unfolded, and the accumulated precipitation falls within a reasonable range --- presuming an average SLR of 10:1, the 0.5-1 in of accumulated precipitation in most of the area aligns with the 8 in. of snow seen in New Orleans.  

.. figure:: https://github.com/ufs-community/ufs-srweather-app/wiki/Tutorial/fcst6_plots/gcb_total_snow.png
   :align: center
   :width: 50%

   *Official snowfall for New Orleans, LA*

The Aftermath
^^^^^^^^^^^^^^^

Overall, New Orleans handled the snow reasonably well under the circumstances, but the storm still caused significant challenges, including: 

* A boil water advisory for parts of New Orleans after a brief, cold-related power loss at Carrollton Water Treatment Plant
* 3,500 power outages statewide; 200+ in Orleans Parish
* Shelters reached capacity: New Orleans officials opened Treme Recreation Community Center to accommodate more people.
* Weather-related deaths across the south; 2 in Louisiana


How Did We Do?
---------------

Overall, this configuration of the SRW App produced reasonable snowfall predictions. Plots show a maximum prediction of about ~1.5 inches of accumulated precipitation, with most of the area in a 0.5-1 in. range, and New Orleans received 8 inches of snow. However, due to a lack of publicly available verification data, it is difficult to determine just how accurate snowfall predictions were and whether wind predictions over land were accurate. For example, both NOMADS and Planetary Computer include :term:`MRMS` verification data for the previous 24 hours only, so users would need to plan in advance to download this data before it becomes unavailable for their experiment. Publicly available :term:`CCPA` or :term:`NDAS` data is also limited. Verification data is key to determining precisely how accurate or inaccurate forecasts are, and in what ways they excel or fall short. With concrete skill measurements, scientists can investigate potential improvements to the current forecasting systems and quantify those improvements once implemented. 

Improving the Forecast
------------------------

There are several options available to improve this forecast. In general, *ensemble forecasts* will provide more accurate predictions than any single deterministic forecast. Users can run an ensemble forcast by setting ``DO_ENSEMBLE: true`` and selecting a value for ``NUM_ENS_MEMBERS``, which indicates how many ensemble members will be included in the forecast. Verification capabilities also exist within the SRW App, and users who have access to the requisite data can visit :numref:`Section %s <VXParams>` to explore the relevant variables and perform a quantitative analysis of the forecast's shortcomings so that researchers and developers can work towards improvements. Lastly, the addition of new capabilities, such as data assimilation via :term:`JEDI`, have the potential to vastly improve prediction capabilities. Users and developers are encouraged to explore improvements that are most interesting and relevant to their work. 
