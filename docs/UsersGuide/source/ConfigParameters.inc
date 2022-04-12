.. This is a continuation of the ConfigWorkflow.rst chapter

.. _ConfigParameters:

Grid Generation Parameters
==========================
``GRID_GEN_METHOD``: (Default: "")
   This variable specifies the method to use to generate a regional grid in the horizontal plane. The values that it can take on are:

   * **"ESGgrid":** This will generate a regional version of the Extended Schmidt Gnomonic grid using the map projection developed by Jim Purser(1) of EMC. ESGgrid is the preferred grid option. 

   * **"GFDLgrid":** This setting will generate a regional grid by first generating a "parent" global cubed-sphere grid and then taking a portion of tile 6 of that global grid and using it as the regional grid (referred to in the grid generation scripts as "tile 7" even though it doesn't correspond to a complete tile).  Note that the forecast is run on only on the regional grid (i.e., on tile 7, not on tiles 1 through 6). This is the legacy grid generation method and is not supported in *all* predefined domains. 

(1) Purser, R. J., D. Jovic, G. Ketefian, T. Black, J. Beck, J. Dong, and J. Carley, 2020: The Extended Schmidt Gnomonic Grid for Regional Applications. Unified Forecast System (UFS) Users’ Workshop. July 27-29, 2020.

..
   COMMENT: Should I delete or add a BibTeX entry?:
   @misc{PurserEtAl,
      title        = "The Extended Schmidt Gnomonic Grid for Regional Applications",
      author       = "{Purser, R. J. and D. Jovic and G. Ketefian and T. Black and J. Beck and J. Dong, and J. Carley}",
      howpublished = "\url{https://dtcenter.org/sites/default/files/events/2020/2-purser-james.pdf}",
      year         = 2020,
      note         = "Unified Forecast System (UFS) Users’ Workshop"
   }

.. attention::

   If the experiment uses a **predefined grid** (i.e., if ``PREDEF_GRID_NAME`` is set to the name of a valid predefined grid), then ``GRID_GEN_METHOD`` will be reset to the value of ``GRID_GEN_METHOD`` for that grid. This will happen regardless of whether ``GRID_GEN_METHOD`` is assigned a value in the experiment configuration file; any value assigned will be overwritten.

.. note::

   If the experiment uses a **user-defined grid** (i.e. if ``PREDEF_GRID_NAME`` is set to a null string), then ``GRID_GEN_METHOD`` must be set in the experiment configuration file. Otherwise, the experiment generation will fail because the generation scripts check to ensure that the grid name is set to a non-empty string before creating the experiment directory.


ESGgrid Settings
-------------------

The following parameters must be set if using the "ESGgrid" method of generating a regional grid (i.e., when ``GRID_GEN_METHOD="ESGgrid"``). 

``ESGgrid_LON_CTR``: (Default: "")
   The longitude of the center of the grid (in degrees).

``ESGgrid_LAT_CTR``: (Default: "")
   The latitude of the center of the grid (in degrees).

``ESGgrid_DELX``: (Default: "")
   The cell size in the zonal direction of the regional grid (in meters).

``ESGgrid_DELY``: (Default: "")
   The cell size in the meridional direction of the regional grid (in meters).

``ESGgrid_NX``: (Default: "")
   The number of cells in the zonal direction on the regional grid.

``ESGgrid_NY``: (Default: "")
   The number of cells in the meridional direction on the regional grid.

``ESGgrid_WIDE_HALO_WIDTH``: (Default: "")
   The width (in units of number of grid cells) of the :term:`halo` to add around the regional grid before shaving the halo down to the width(s) expected by the forecast model. 

``ESGgrid_PAZI``: (Default: "")
   The rotational parameter for the ESG grid (in degrees).

A :term:`halo` is the strip of cells surrounding the regional grid; the halo is used to feed in the lateral boundary conditions to the grid. The forecast model requires **grid** files containing 3-cell- and 4-cell-wide halos and **orography** files with 0-cell- and 3-cell- wide halos. In order to generate grid and orography files with appropriately-sized halos, the grid and orography tasks create preliminary files with halos around the regional domain of width ``ESGgrid_WIDE_HALO_WIDTH`` cells. The files are then read in and "shaved" down to obtain grid files with 3-cell-wide and 4-cell-wide halos and orography files with 0-cell-wide and 3-cell-wide halos. The original halo that gets shaved down is referred to as the "wide" halo because it is wider than the 0-cell-wide, 3-cell-wide, and 4-cell-wide halos that we eventually end up with. Note that the grid and orography files with the wide halo are only needed as intermediates in generating the files with 0-cell-, 3-cell-, and 4-cell-wide halos; they are not needed by the forecast model.

..
   COMMENT: There's a note that we "probably don't need to make ESGgrid_WIDE_HALO_WIDTH a user-specified variable.  Just set it in the function set_gridparams_ESGgrid.sh". Has this been done? I thought there was a default value of 6. Does this come from set_gridparams_ESGgrid.sh? Will it overwirte what's added here?


GFDLgrid Settings
---------------------

The following parameters must be set if using the "GFDLgrid" method of generating a regional grid (i.e., when ``GRID_GEN_METHOD="GFDLgrid"``). Note that the regional grid is defined with respect to a "parent" global cubed-sphere grid. Thus, all the parameters for a global cubed-sphere grid must be specified even though the model equations are integrated only on the regional grid. Tile 6 has arbitrarily been chosen as the tile to use to orient the global parent grid on the sphere (Earth). For convenience, the regional grid is denoted as "tile 7" even though it is embedded within tile 6 (i.e. it doesn't extend beyond the boundary of tile 6). Its exact location within tile 6 is determined by specifying the starting and ending i and j indices of the regional grid on tile 6, where i is the grid index in the x direction and j is the grid index in the y direction. All of this information is set in the variables below. 

``GFDLgrid_LON_T6_CTR``: (Default: "")
   Longitude of the center of tile 6 (in degrees).

``GFDLgrid_LAT_T6_CTR``: (Default: "")
   Latitude of the center of tile 6 (in degrees).

``GFDLgrid_RES``: (Default: "")
   Number of points in either of the two horizontal directions (x and y) on each tile of the parent global cubed-sphere grid. 
   
   .. note::
      ``GFDLgrid_RES`` is a misnomer because it specifies *number* of grid cells, not grid size (in meters or kilometers). However, we keep this name in order to remain consistent with the usage of the word "resolution" in the global forecast model and auxiliary codes. The mapping from ``GFDLgrid_RES`` to a nominal resolution (grid cell size) for several values of ``GFDLgrid_RES`` is as follows (assuming a uniform global grid, i.e., with Schmidt stretch factor ``GFDLgrid_STRETCH_FAC="1"``):
         +----------------+--------------------+
         | GFDLgrid_RES   | typical cell size  |
         +================+====================+
         | 192            |      50 km         |
         +----------------+--------------------+
         | 384            |      25 km         |
         +----------------+--------------------+
         | 768            |      13 km         |
         +----------------+--------------------+
         | 1152           |      8.5 km        |
         +----------------+--------------------+
         | 3072           |      3.2 km        |
         +----------------+--------------------+

      Note that these are only typical cell sizes. The actual cell size on the global grid tiles varies somewhat as we move across a tile.


``GFDLgrid_STRETCH_FAC``: (Default: "")
   Stretching factor used in the Schmidt transformation applied to the parent cubed-sphere grid. Setting the Schmidt stretching factor ``GFDLgrid_STRETCH_FAC`` to a value greater than 1 shrinks tile 6, while setting it to a value less than 1 (but still greater than 0) expands it. The remaining 5 tiles change shape as necessary to maintain global coverage of the grid.

``GFDLgrid_REFINE_RATIO``: (Default: "")
   Cell refinement ratio for the regional grid, i.e., the number of cells in either the x or y direction on the regional grid (tile 7) that abut one cell on its parent tile (tile 6).

``GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G``: (Default: "")
   i-index on tile 6 at which the regional grid (tile 7) starts.

``GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G``: (Default: "")
   i-index on tile 6 at which the regional grid (tile 7) ends.

``GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G``: (Default: "")
   j-index on tile 6 at which the regional grid (tile 7) starts.

``GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G``: (Default: "")
   j-index on tile 6 at which the regional grid (tile 7) ends.

``GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES``: (Default: "")
   Flag that determines the file naming convention to use for grid, orography, and surface climatology files (or, if using pregenerated files, the naming convention that was used to name these files).  These files usually start with the string "C${RES}_", where RES is an integer. In the global forecast model, ``RES`` is the number of points in each of the two horizontal directions (x and y) on each tile of the global grid (defined here as GFDLgrid_RES). If this flag is set to "TRUE", RES will be set to GFDLgrid_RES just as in the global forecast model. If it is set to "FALSE", we calculate (in the grid generation task) an "equivalent global uniform cubed-sphere resolution" -- call it RES_EQUIV -- and then set RES equal to it. RES_EQUIV is the number of grid points in each of the x and y directions on each tile that a global UNIFORM (i.e., stretch factor of 1) cubed-sphere grid would need to have in order to have the same average grid size as the regional grid. This is a more useful indicator of the grid size because it takes into account the effects of GFDLgrid_RES, GFDLgrid_STRETCH_FAC, and GFDLgrid_REFINE_RATIO in determining the regional grid's typical grid size, whereas simply setting RES to GFDLgrid_RES doesn't take into account the effects of GFDLgrid_STRETCH_FAC and GFDLgrid_REFINE_RATIO on the regional grid's resolution. Nevertheless, some users still prefer to use GFDLgrid_RES in the file names, so we allow for that here by setting this flag to "TRUE".

Computational Forecast Parameters
=================================

``LAYOUT_X, LAYOUT_Y``: (Default: "")
   The number of MPI tasks (processes) to use in the two horizontal directions (x and y) of the regional grid when running the forecast model.

``BLOCKSIZE``: (Default: "")
   The amount of data that is passed into the cache at a time.

.. note::

   In ``config_defaults.sh`` these parameters are set to null strings so that:

   #. If the experiment is using a predefined grid and the user sets the parameter in the user-specified experiment configuration file (``EXPT_CONFIG_FN``), that value will be used in the forecast(s). Otherwise, the default value of the parameter for that predefined grid will be used.

   #. If the experiment is not using a predefined grid (i.e., it is using a custom grid whose parameters are specified in the experiment configuration file), then the user must specify a value for the parameter in that configuration file. Otherwise, the parameter will remain set to a null string, and the experiment generation will fail, because the generation scripts check to ensure that all the parameters defined in this section are set to non-empty strings before creating the experiment directory.


Write-Component (Quilting) Parameters
======================================

.. note::
   The :term:`UPP` (called by the ``run_post`` task) cannot process output on the native grid types ("GFDLgrid" and "ESGgrid"), so output fields are interpolated to a write-component grid before writing them to an output file. The output history files written by the UFS Weather Model model use an Earth System Modeling Framework (ESMF) component, referred to as the write component. This model component is configured with settings in the model_configure file, as described in `Section 4.2.3 <https://ufs-weather-model.readthedocs.io/en/latest/InputsOutputs.html?highlight=write-component#model-configurefile>`__ of the UFS Weather Model documentation.  

``QUILTING``: (Default: "TRUE")
   Flag that determines whether or not to use the write-component for writing forecast output files to disk. If set to "TRUE", the forecast model will output files named ``dynf$HHH.nc`` and ``phyf$HHH.nc`` (where HHH is the 3-hour output forecast hour) containing dynamics and physics fields, respectively, on the write-component grid (the regridding from the native FV3-LAM grid to the write-component grid is done by the forecast model). If ``QUILTING`` is set to "FALSE", then the output file names are ``fv3_history.nc`` and ``fv3_history2d.nc`` and contain fields on the native grid. Note that if ``QUILTING`` is set to "FALSE", then the ``RUN_POST_TN`` (meta)task cannot be run because the :term:`UPP` code that this task calls cannot process fields on the native grid. In that case, the ``RUN_POST_TN`` (meta)task will be automatically removed from the Rocoto workflow XML. 

..
   COMMENT: Still don't undertand what HHH refers to... can we give an example?

``PRINT_ESMF``: (Default: "FALSE")
   Flag for whether or not to output extra (debugging) information from ESMF routines. Must be "TRUE" or "FALSE". Note that the write-component uses ESMF library routines to interpolate from the native forecast model grid to the user-specified output grid (which is defined in the model configuration file ``model_configure`` in the forecast run directory).

``WRTCMP_write_groups``: (Default: "1")
   The number of write groups (i.e., groups of :term:`MPI` tasks) to use in the write-component.

``WRTCMP_write_tasks_per_group``: (Default: "20")
   The number of MPI tasks to allocate for each write group.

``WRTCMP_output_grid``: (Default: "''")
   Sets the type (coordinate system) of the write-component grid. The default empty string forces the user to set a valid valid ``WRTCMP_output_grid`` in ``config.sh`` if specifying a custom grid. Otherwise, the ordinary "regional_latlon" grid will be used. Valid values: "rotated_latlon" "lambert_conformal" "regional_latlon" 

..
   COMMENT: If no value is specified in config.sh, would setup.sh (or some other script?) use the ordinary "regional_latlon"? Or would the experiment just fail?

``WRTCMP_cen_lon``: (Default: "")
   Longitude (in degrees) of the center of the write-component grid. Can usually set to corresponding value from the native grid.

``WRTCMP_cen_lat``: (Default: "")
   Latitude (in degrees) of the center of the write-component grid. Can usually set to corresponding value from the native grid.

``WRTCMP_lon_lwr_left``: (Default: "")
   Longitude (in degrees) of the center of the lower-left (southwest) cell on the write-component grid. If using "rotated_latlon" coordinate system, this is expressed in terms of the rotated longitude. Must be set manually.
   
..
   COMMENT: Has this changed? Or still manual?

``WRTCMP_lat_lwr_left``: (Default: "")
   Latitude (in degrees) of the center of the lower-left (southwest) cell on the write-component grid. If using "rotated_latlon" coordinate system, this is expressed in terms of the rotated latitude. Must be set manually.

The following parameters must be set when ``WRTCMP_output_grid`` is set to "rotated_latlon":

``WRTCMP_lon_upr_rght``: (Default: "")
   Longitude (in degrees) of the center of the upper-left (northeast) cell on the write-component grid (expressed in terms of the rotated longitude).

``WRTCMP_lat_upr_rght``: (Default: "")
   Latitude (in degrees) of the center of the upper-left (northeast) cell on the write-component grid (expressed in terms of the rotated latitude).

``WRTCMP_dlon``: (Default: "")
   Size of grid cell (in degrees) of a grid cell on the write-component grid (expressed in terms of the rotated longitude).

``WRTCMP_dlat``: (Default: "")
   Size of grid cell (in degrees) of a grid cell on the write-component grid (expressed in terms of the rotated latitude).

The following parameters must be set when ``WRTCMP_output_grid`` is set to "lambert_conformal":

``WRTCMP_stdlat1``: (Default: "")
   First standard latitude (in degrees) in definition of Lambert conformal projection.

``WRTCMP_stdlat2``: (Default: "")
   Second standard latitude (in degrees) in definition of Lambert conformal projection.

``WRTCMP_nx``: (Default: "")
   Number of grid points in the x coordinate of the Lambert conformal projection.

``WRTCMP_ny``: (Default: "")
   Number of grid points in the y coordinate of the Lambert conformal projection.

``WRTCMP_dx``: (Default: "")
   Grid cell size (in meters) along the x axis of the Lambert conformal projection.

``WRTCMP_dy``: (Default: "")
   Grid cell size (in meters) along the y axis of the Lambert conformal projection. 


Predefined Grid Parameters
==========================
``PREDEF_GRID_NAME``: (Default: "")
   This parameter specifies the name of a predefined regional grid. Setting PREDEF_GRID_NAME provides a convenient method of specifying a commonly used set of grid-dependent parameters. The predefined grid parameters are specified in the script ``ush/set_predef_grid_params.sh``. Currently supported ``PREDEF_GRID_NAME`` options are "RRFS_CONUS_25km," "RRFS_CONUS_13km," and "RRFS_CONUS_3km." 
   Other valid values include: 
   "RRFS_SUBCONUS_3km" 
   "RRFS_AK_13km" 
   "RRFS_AK_3km" 
   "CONUS_25km_GFDLgrid" 
   "CONUS_3km_GFDLgrid" 
   "EMC_AK" 
   "EMC_HI" 
   "EMC_PR" 
   "EMC_GU" 
   "GSL_HAFSV0.A_25km" 
   "GSL_HAFSV0.A_13km" 
   "GSL_HAFSV0.A_3km" 
   "GSD_HRRR_AK_50km" 
   "RRFS_NA_13km" 
   "RRFS_NA_3km"

..
   COMMENT: Are all of these now being supported or still just the three main ones?

.. note::

   * If ``PREDEF_GRID_NAME`` is set to a valid predefined grid name, the grid generation method ``GRID_GEN_METHOD``, the (native) grid parameters, and the write-component grid parameters are set to predefined values for the specified grid, overwriting any settings of these parameters in the user-specified experiment configuration file (``config.sh``).  In addition, if the time step ``DT_ATMOS`` and the computational parameters ``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE`` are not specified in that configuration file, they are also set to predefined values for the specified grid.

   * If ``PREDEF_GRID_NAME`` is set to an empty string, it implies the user is providing the native grid parameters in the user-specified experiment configuration file (``EXPT_CONFIG_FN``).  In this case, the grid generation method ``GRID_GEN_METHOD``, the native grid parameters, and the write-component grid parameters as well as the main time step (``DT_ATMOS``) and the computational parameters ``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE`` must be set in that configuration file. Otherwise, the values of all of these parameters in this default experiment configuration file will be used.


Pre-existing Directory Parameter
================================
``PREEXISTING_DIR_METHOD``: (Default: "delete")
   This variable determines the method to use to deal with pre-existing directories (generated by previous calls to the experiment generation script using the same experiment name (``EXPT_SUBDIR``) as the current experiment). This variable must be set to one of three valid values: "delete", "rename", and "quit".  The resulting behavior for each of these values is as follows:

   * "delete": The preexisting directory is deleted and a new directory (having the same name as the original preexisting directory) is created.

   * "rename": The preexisting directory is renamed and a new directory (having the same name as the original pre-existing directory) is created. The new name of the preexisting directory consists of its original name and the suffix "_oldNNN", where NNN is a 3-digit integer chosen to make the new name unique.

   * "quit": The preexisting directory is left unchanged, but execution of the currently running script is terminated. In this case, the preexisting directory must be dealt with manually before rerunning the script.


Verbose Parameter
=================
``VERBOSE``: (Default: "TRUE")
   This is a flag that determines whether or not the experiment generation and workflow task scripts print out extra informational messages. Valid values: "TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no"

Debug Parameter
=================
``DEBUG``: (Default: "FALSE")
   This is a flag that determines whether or not very detailed debugging messages are printed out.  Note that if DEBUG is set to TRUE, then VERBOSE will also get reset to TRUE if it isn't already. Valid values: "TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no"

Rocoto Workflow Tasks
========================

Set the names of the various Rocoto workflow tasks. The baseline tasks are:

``MAKE_GRID_TN``: (Default: "make_grid")
``MAKE_OROG_TN``: (Default: make_orog")
``MAKE_SFC_CLIMO_TN``: (Default: "make_sfc_climo")
``GET_EXTRN_ICS_TN``: (Default: "get_extrn_ics")
``GET_EXTRN_LBCS_TN``: (Default: "get_extrn_lbcs")
``MAKE_ICS_TN``: (Default: "make_ics")
``MAKE_LBCS_TN``: (Default: "make_lbcs")
``RUN_FCST_TN``: (Default: "run_fcst")
``RUN_POST_TN``: (Default: "run_post")

When running METplus verification tasks, the following task names are also added to the Rocoto workflow:

``GET_OBS``: (Default: "get_obs")
``GET_OBS_CCPA_TN``: (Default: "get_obs_ccpa")
``GET_OBS_MRMS_TN``: (Default: "get_obs_mrms")
``GET_OBS_NDAS_TN``: (Default: "get_obs_ndas")
``VX_TN``: (Default: "run_vx")
``VX_GRIDSTAT_TN``: (Default: "run_gridstatvx")
``VX_GRIDSTAT_REFC_TN``: (Default: "run_gridstatvx_refc")
``VX_GRIDSTAT_RETOP_TN``: (Default: "run_gridstatvx_retop")
``VX_GRIDSTAT_03h_TN``: (Default: "run_gridstatvx_03h")
``VX_GRIDSTAT_06h_TN``: (Default: "run_gridstatvx_06h")
``VX_GRIDSTAT_24h_TN``: (Default: "run_gridstatvx_24h")
``VX_POINTSTAT_TN``: (Default: "run_pointstatvx")
``VX_ENSGRID_TN``: (Default: "run_ensgridvx")
``VX_ENSGRID_03h_TN``: (Default: "run_ensgridvx_03h")
``VX_ENSGRID_06h_TN``: (Default: "run_ensgridvx_06h")
``VX_ENSGRID_24h_TN``: (Default: "run_ensgridvx_24h")
``VX_ENSGRID_REFC_TN``: (Default: "run_ensgridvx_refc")
``VX_ENSGRID_RETOP_TN``: (Default: "run_ensgridvx_retop")
``VX_ENSGRID_MEAN_TN``: (Default: "run_ensgridvx_mean")
``VX_ENSGRID_PROB_TN``: (Default: "run_ensgridvx_prob")
``VX_ENSGRID_MEAN_03h_TN``: (Default: "run_ensgridvx_mean_03h")
``VX_ENSGRID_PROB_03h_TN``: (Default: "run_ensgridvx_prob_03h")
``VX_ENSGRID_MEAN_06h_TN``: (Default: "run_ensgridvx_mean_06h")
``VX_ENSGRID_PROB_06h_TN``: (Default: "run_ensgridvx_prob_06h")
``VX_ENSGRID_MEAN_24h_TN``: (Default: "run_ensgridvx_mean_24h")
``VX_ENSGRID_PROB_24h_TN``: (Default: "run_ensgridvx_prob_24h")
``VX_ENSGRID_PROB_REFC_TN``: (Default: "run_ensgridvx_prob_refc")
``VX_ENSGRID_PROB_RETOP_TN``: (Default: "run_ensgridvx_prob_retop")
``VX_ENSPOINT_TN``: (Default: "run_enspointvx")
``VX_ENSPOINT_MEAN_TN``: (Default: "run_enspointvx_mean")
``VX_ENSPOINT_PROB_TN``: (Default: "run_enspointvx_prob")


Pre-Processing Parameters
=========================
These parameters set flags (and related directories) that determine whether various workflow tasks should be run. Note that the ``MAKE_GRID_TN``, ``MAKE_OROG_TN``, and ``MAKE_SFC_CLIMO_TN`` are all :term:`cycle-independent` tasks, i.e., if they are to be run, they do so only once at the beginning of the workflow before any cycles are run. Definitions:

``RUN_TASK_MAKE_GRID``: (Default: "TRUE")
   Flag that determines whether the grid file generation task (``MAKE_GRID_TN``) is to be run. If this is set to "TRUE", the grid generation task is run and new grid files are generated. If it is set to "FALSE", then the scripts look for pre-generated grid files in the directory specified by ``GRID_DIR`` (see below).

``GRID_DIR``: (Default: "/path/to/pregenerated/grid/files")
   The directory in which to look for pre-generated grid files if ``RUN_TASK_MAKE_GRID`` is set to "FALSE".

``RUN_TASK_MAKE_OROG``: (Default: "TRUE")
   Flag that determines whether the 
   Same as ``RUN_TASK_MAKE_GRID`` but for the orography generation task (``MAKE_OROG_TN``).

``OROG_DIR``: (Default: "/path/to/pregenerated/orog/files")
   Same as ``GRID_DIR`` but for the orography generation task (``MAKE_OROG_TN``).

``RUN_TASK_MAKE_SFC_CLIMO``: (Default: "TRUE")
   Same as ``RUN_TASK_MAKE_GRID`` but for the surface climatology generation task (``MAKE_SFC_CLIMO_TN``).

``SFC_CLIMO_DIR``: (Default: "/path/to/pregenerated/surface/climo/files")
   Same as ``GRID_DIR`` but for the surface climatology generation task.

``RUN_TASK_GET_EXTRN_ICS``: (Default: "TRUE")
   Flag that determines whether the GET_EXTRN_ICS_TN task is to be run.

``RUN_TASK_GET_EXTRN_LBCS``: (Default: "TRUE")
   Flag that determines whether the GET_EXTRN_LBCS_TN task is to be run.

``RUN_TASK_MAKE_ICS``: (Default: "TRUE")
   Flag that determines whether the MAKE_ICS_TN task is to be run.

``RUN_TASK_MAKE_LBCS``: (Default: "TRUE")
   Flag that determines whether the MAKE_LBCS_TN task is to be run.

``RUN_TASK_RUN_FCST``: (Default: "TRUE")
   Flag that determines whether the RUN_FCST_TN task is to be run.

``RUN_TASK_RUN_POST``: (Default: "TRUE")
   Flag that determines whether the RUN_POST_TN task is to be run.

Verification Tasks
--------------------

``RUN_TASK_GET_OBS_CCPA``: (Default: "FALSE")
   Flag that determines whether to run the ``GET_OBS_CCPA`` task, which retrieves the CCPA hourly precipitation files used by METplus. 

``RUN_TASK_GET_OBS_MRMS``: (Default: "FALSE")
   Flag that determines whether to run the ``GET_OBS_MRMS`` task, which retrieves the MRMS composite reflectivity files used by METplus. 

``RUN_TASK_GET_OBS_NDAS``: (Default: "FALSE")
   Flag that determines whether to run the ``GET_OBS_NDAS`` task, which retrieves the NDAS PREPBUFR files used by METplus are located. 

..
   COMMENT: Need confirmation that the above 3 task explanations are correct. 


``RUN_TASK_VX_GRIDSTAT``: (Default: "FALSE")
   Flag that determines whether the grid-stat verification task is to be run.

``RUN_TASK_VX_POINTSTAT``: (Default: "FALSE")
   Flag that determines whether the point-stat verification task is to be run.

``RUN_TASK_VX_ENSGRID``: (Default: "FALSE")
   Flag that determines whether the ensemble-stat verification for gridded data task is to be run. 

``RUN_TASK_VX_ENSPOINT``: (Default: "FALSE")
   Flag that determines whether the ensemble point verification task is to be run. If this flag is set, both ensemble-stat point verification and point verification of ensemble-stat output is computed.

Aerosol Climatology Parameter
================================

``USE_MERRA_CLIMO``: (Default: "FALSE")
   Flag that determines whether MERRA2 aerosol climatology data and lookup tables for optics properties are obtained. 


Surface Climatology Parameter
=============================
``SFC_CLIMO_FIELDS``: (Default: "("facsf" "maximum_snow_albedo" "slope_type" "snowfree_albedo" "soil_type" "substrate_temperature" "vegetation_greenness" "vegetation_type")")
   Array containing the names of all the fields for which the ``MAKE_SFC_CLIMO_TN`` task generates files on the native FV3-LAM grid.

Fixed File Parameters
=====================
Set parameters associated with the fixed (i.e., static) files. On the main `Level 1 & 2 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, fixed files are prestaged with paths defined in the ``setup.sh`` script. Because the default values are dependent on the platform, we set these to a null string which will then be overwritten in ``setup.sh`` unless the user has specified a different value in ``config.sh``.

``FIXgsm``: (Default: "")
   System directory in which the majority of fixed (i.e. time-independent) files that are needed to run the FV3-LAM model are located.

``FIXaer``: (Default: "")
   System directory where MERRA2 aerosol climatology files are located

``FIXlut``: (Default: "")
   System directory where the lookup tables for optics properties are located

``TOPO_DIR``: (Default: "")
   The location on disk of the static input files used by the ``make_orog task`` (``orog.x`` and ``shave.x``). Can be the same as ``FIXgsm``.

``SFC_CLIMO_INPUT_DIR``: (Default: "")
   The location on disk of the static surface climatology input fields, used by ``sfc_climo_gen``. These files are only used if ``RUN_TASK_MAKE_SFC_CLIMO=TRUE``.

``FNGLAC, ..., FNMSKH``: (Default: see below)
   .. code-block:: console

     (FNGLAC="global_glacier.2x2.grb"
      FNMXIC="global_maxice.2x2.grb"
      FNTSFC="RTGSST.1982.2012.monthly.clim.grb"
      FNSNOC="global_snoclim.1.875.grb"
      FNZORC="igbp"
      FNAISC="CFSR.SEAICE.1982.2012.monthly.clim.grb"
      FNSMCC="global_soilmgldas.t126.384.190.grb"
      FNMSKH="seaice_newland.grb")

   Names of (some of the) global data files that are assumed to exist in a system directory specified (this directory is machine-dependent; the experiment generation scripts will set it and store it in the variable ``FIXgsm``). These file names also appear directly in the forecast model's input namelist file.

``FIXgsm_FILES_TO_COPY_TO_FIXam``: (Default: see below)
   .. code-block:: console

     ("$FNGLAC" \
      "$FNMXIC" \
      "$FNTSFC" \
      "$FNSNOC" \
      "$FNAISC" \
      "$FNSMCC" \
      "$FNMSKH" \
      "global_climaeropac_global.txt" \
      "fix_co2_proj/global_co2historicaldata_2010.txt" \
      "fix_co2_proj/global_co2historicaldata_2011.txt" \
      "fix_co2_proj/global_co2historicaldata_2012.txt" \
      "fix_co2_proj/global_co2historicaldata_2013.txt" \
      "fix_co2_proj/global_co2historicaldata_2014.txt" \
      "fix_co2_proj/global_co2historicaldata_2015.txt" \
      "fix_co2_proj/global_co2historicaldata_2016.txt" \
      "fix_co2_proj/global_co2historicaldata_2017.txt" \
      "fix_co2_proj/global_co2historicaldata_2018.txt" \
      "fix_co2_proj/global_co2historicaldata_2019.txt" \
      "fix_co2_proj/global_co2historicaldata_2020.txt" \
      "fix_co2_proj/global_co2historicaldata_2021.txt" \
      "global_co2historicaldata_glob.txt" \
      "co2monthlycyc.txt" \
      "global_h2o_pltc.f77" \
      "global_hyblev.l65.txt" \
      "global_zorclim.1x1.grb" \
      "global_sfc_emissivity_idx.txt" \
      "global_tg3clim.2.6x1.5.grb" \
      "global_solarconstant_noaa_an.txt" \
      "global_albedo4.1x1.grb" \
      "geo_em.d01.lat-lon.2.5m.HGT_M.nc" \
      "HGT.Beljaars_filtered.lat-lon.30s_res.nc" \
      "replace_with_FIXgsm_ozone_prodloss_filename")

   If not running in NCO mode, this array contains the names of the files to copy from the ``FIXgsm`` system directory to the ``FIXam`` directory under the experiment directory. Note that the last element has a dummy value. This last element will get reset by the workflow generation scripts to the name of the ozone production/loss file to copy from ``FIXgsm``. The name of this file depends on the ozone parameterization being used, and that in turn depends on the CCPP physics suite specified for the experiment. Thus, the CCPP physics suite XML must first be read in to determine the ozone parameterization and then the name of the ozone production/loss file. These steps are carried out elsewhere (in one of the workflow generation scripts/functions).

``FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING``: (Default: see below)
   .. code-block:: console

      ("FNGLAC | $FNGLAC" \
       "FNMXIC | $FNMXIC" \
       "FNTSFC | $FNTSFC" \
       "FNSNOC | $FNSNOC" \
       "FNAISC | $FNAISC" \
       "FNSMCC | $FNSMCC" \
       "FNMSKH | $FNMSKH" )

   This array is used to set some of the namelist variables in the forecast model's namelist file that represent the relative or absolute paths of various fixed files (the first column of the array, where columns are delineated by the pipe symbol "|") to the full paths to these files in the FIXam directory derived from the corresponding workflow variables containing file names (the second column of the array). It is possible to remove this as a workflow variable and make it only a local one since it is used in only one script.

..
   COMMENT: Why is #"FNZORC | $FNZORC" \ commented out in config_defaults.sh?


``FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING``: (Default: see below)
   .. code-block:: console

      ("FNALBC  | snowfree_albedo" \
       "FNALBC2 | facsf" \
       "FNTG3C  | substrate_temperature" \
       "FNVEGC  | vegetation_greenness" \
       "FNVETC  | vegetation_type" \
       "FNSOTC  | soil_type" \
       "FNVMNC  | vegetation_greenness" \
       "FNVMXC  | vegetation_greenness" \
       "FNSLPC  | slope_type" \
       "FNABSC  | maximum_snow_albedo" )

   This array is used to set some of the namelist variables in the forecast model's namelist file that represent the relative or absolute paths of various fixed files (the first column of the array, where columns are delineated by the pipe symbol "|") to the full paths to surface climatology files (on the native FV3-LAM grid) in the ``FIXLAM`` directory derived from the corresponding surface climatology fields (the second column of the array).


``CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING``: (Default: see below)
   .. code-block:: console

      ("aerosol.dat            	  | global_climaeropac_global.txt" \
       "co2historicaldata_2010.txt | fix_co2_proj/global_co2historicaldata_2010.txt" \
       "co2historicaldata_2011.txt | fix_co2_proj/global_co2historicaldata_2011.txt" \
       "co2historicaldata_2012.txt | fix_co2_proj/global_co2historicaldata_2012.txt" \
       "co2historicaldata_2013.txt | fix_co2_proj/global_co2historicaldata_2013.txt" \
       "co2historicaldata_2014.txt | fix_co2_proj/global_co2historicaldata_2014.txt" \
       "co2historicaldata_2015.txt | fix_co2_proj/global_co2historicaldata_2015.txt" \
       "co2historicaldata_2016.txt | fix_co2_proj/global_co2historicaldata_2016.txt" \
       "co2historicaldata_2017.txt | fix_co2_proj/global_co2historicaldata_2017.txt" \
       "co2historicaldata_2018.txt | fix_co2_proj/global_co2historicaldata_2018.txt" \
       "co2historicaldata_2019.txt | fix_co2_proj/global_co2historicaldata_2019.txt" \
       "co2historicaldata_2020.txt | fix_co2_proj/global_co2historicaldata_2020.txt" \
       "co2historicaldata_2021.txt | fix_co2_proj/global_co2historicaldata_2021.txt" \
       "co2historicaldata_glob.txt | global_co2historicaldata_glob.txt" \
       "co2monthlycyc.txt      	  | co2monthlycyc.txt" \
       "global_h2oprdlos.f77   	  | global_h2o_pltc.f77" \
       "global_albedo4.1x1.grb     | global_albedo4.1x1.grb" \
       "global_zorclim.1x1.grb 	  | global_zorclim.1x1.grb" \
       "global_tg3clim.2.6x1.5.grb | global_tg3clim.2.6x1.5.grb" \
       "sfc_emissivity_idx.txt 	  | global_sfc_emissivity_idx.txt" \
       "solarconstant_noaa_an.txt  | global_solarconstant_noaa_an.txt" \
       "global_o3prdlos.f77    	  | " )

   This array specifies the mapping to use between the symlinks that need to be created in each cycle directory (these are the "files" that FV3 looks for) and their targets in the ``FIXam`` directory. The first column of the array specifies the symlink to be created, and the second column specifies its target file in ``FIXam`` (where columns are delineated by the pipe symbol "|").


Workflow Task Parameters
========================
These parameters set the names of the various workflow tasks and usually do not need to be changed.  For each task, additional values set the parameters to pass to the job scheduler (e.g. slurm) that will submit a job for each task to be run.  Parameters include the number of nodes to use to run the job, the number of MPI processes per node, the maximum walltime to allow for the job to complete, and the maximum number of times to attempt to run each task.

Task names:

| ``MAKE_GRID_TN``: (Default: "make_grid")
| ``MAKE_OROG_TN``: (Default: "make_orog")
| ``MAKE_SFC_CLIMO_TN``: (Default: "make_sfc_climo")
| ``GET_EXTRN_ICS_TN``: (Default: "get_extrn_ics")
| ``GET_EXTRN_LBCS_TN``: (Default: "get_extrn_lbcs")
| ``MAKE_ICS_TN``: (Default: "make_ics")
| ``MAKE_LBCS_TN``: (Default: "make_lbcs")
| ``RUN_FCST_TN``: (Default: "run_fcst")
| ``RUN_POST_TN``: (Default: "run_post")

Number of nodes:

| ``NNODES_MAKE_GRID``: (Default: "1")
| ``NNODES_MAKE_OROG``: (Default: "1")
| ``NNODES_MAKE_SFC_CLIMO``: (Default: "2")
| ``NNODES_GET_EXTRN_ICS``: (Default: "1")
| ``NNODES_GET_EXTRN_LBCS``: (Default: "1")
| ``NNODES_MAKE_ICS``: (Default: "4")
| ``NNODES_MAKE_LBCS``: (Default: "4")
| ``NNODES_RUN_FCST``: (Default: "")  # Calculated in the workflow generation scripts.
| ``NNODES_RUN_POST``: (Default: "2")
| ``NNODES_GET_OBS_CCPA``: (Default: "1")
| ``NNODES_GET_OBS_MRMS``: (Default: "1")
| ``NNODES_GET_OBS_NDAS``: (Default: "1")
| ``NNODES_VX_GRIDSTAT``: (Default: "1")
| ``NNODES_VX_POINTSTAT``: (Default: "1")
| ``NNODES_VX_ENSGRID``: (Default: "1")
| ``NNODES_VX_ENSGRID_MEAN``: (Default: "1")
| ``NNODES_VX_ENSGRID_PROB``: (Default: "1")
| ``NNODES_VX_ENSPOINT``: (Default: "1")
| ``NNODES_VX_ENSPOINT_MEAN``: (Default: "1")
| ``NNODES_VX_ENSPOINT_PROB``: (Default: "1")

Number of MPI processes per node:

| ``PPN_MAKE_GRID``: (Default: "24")
| ``PPN_MAKE_OROG``: (Default: "24")
| ``PPN_MAKE_SFC_CLIMO``: (Default: "24")
| ``PPN_GET_EXTRN_ICS``: (Default: "1")
| ``PPN_GET_EXTRN_LBCS``: (Default: "1")
| ``PPN_MAKE_ICS``: (Default: "12")
| ``PPN_MAKE_LBCS``: (Default: "12")
| ``PPN_RUN_FCST``: (Default: "")    # will be calculated from ``NCORES_PER_NODE`` and ``OMP_NUM_THREADS`` in ``setup.sh``
| ``PPN_RUN_POST``: (Default: "24")
| ``PPN_GET_OBS_CCPA``: (Default: "1")
| ``PPN_GET_OBS_MRMS``: (Default: "1")
| ``PPN_GET_OBS_NDAS``: (Default: "1")
| ``PPN_VX_GRIDSTAT``: (Default: "1")
| ``PPN_VX_POINTSTAT``: (Default: "1")
| ``PPN_VX_ENSGRID``: (Default: "1")
| ``PPN_VX_ENSGRID_MEAN``: (Default: "1")
| ``PPN_VX_ENSGRID_PROB``: (Default: "1")
| ``PPN_VX_ENSPOINT``: (Default: "1")
| ``PPN_VX_ENSPOINT_MEAN``: (Default: "1")
| ``PPN_VX_ENSPOINT_PROB``: (Default: "1")


Wall times:

| ``WTIME_MAKE_GRID``: (Default: "00:20:00")
| ``WTIME_MAKE_OROG``: (Default: "01:00:00")
| ``WTIME_MAKE_SFC_CLIMO``: (Default: "00:20:00")
| ``WTIME_GET_EXTRN_ICS``: (Default: "00:45:00")
| ``WTIME_GET_EXTRN_LBCS``: (Default: "00:45:00")
| ``WTIME_MAKE_ICS``: (Default: "00:30:00")
| ``WTIME_MAKE_LBCS``: (Default: "00:30:00")
| ``WTIME_RUN_FCST``: (Default: "04:30:00")
| ``WTIME_RUN_POST``: (Default: "00:15:00")
| ``WTIME_GET_OBS_CCPA``: (Default: "00:45:00")
| ``WTIME_GET_OBS_MRMS``: (Default: "00:45:00")
| ``WTIME_GET_OBS_NDAS``: (Default: "02:00:00")
| ``WTIME_VX_GRIDSTAT``: (Default: "02:00:00")
| ``WTIME_VX_POINTSTAT``: (Default: "01:00:00")
| ``WTIME_VX_ENSGRID``: (Default: "01:00:00")
| ``WTIME_VX_ENSGRID_MEAN``: (Default: "01:00:00")
| ``WTIME_VX_ENSGRID_PROB``: (Default: "01:00:00")
| ``WTIME_VX_ENSPOINT``: (Default: "01:00:00")
| ``WTIME_VX_ENSPOINT_MEAN``: (Default: "01:00:00")
| ``WTIME_VX_ENSPOINT_PROB``: (Default: "01:00:00")

Maximum number of attempts.

| ``MAXTRIES_MAKE_GRID``: (Default: "2")
| ``MAXTRIES_MAKE_OROG``: (Default: "2")
| ``MAXTRIES_MAKE_SFC_CLIMO``: (Default: "2")
| ``MAXTRIES_GET_EXTRN_ICS``: (Default: "1")
| ``MAXTRIES_GET_EXTRN_LBCS``: (Default: "1")
| ``MAXTRIES_MAKE_ICS``: (Default: "1")
| ``MAXTRIES_MAKE_LBCS``: (Default: "1")
| ``MAXTRIES_RUN_FCST``: (Default: "1")
| ``MAXTRIES_RUN_POST``: (Default: "2")
| ``MAXTRIES_GET_OBS_CCPA``: (Default: "1")
| ``MAXTRIES_GET_OBS_MRMS``: (Default: "1")
| ``MAXTRIES_GET_OBS_NDAS``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_REFC``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_RETOP``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_03h``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_06h``: (Default: "1")
| ``MAXTRIES_VX_GRIDSTAT_24h``: (Default: "1")
| ``MAXTRIES_VX_POINTSTAT``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_REFC``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_RETOP``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_03h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_06h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_24h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_MEAN``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_MEAN_03h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_03h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_MEAN_06h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_06h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_MEAN_24h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_24h``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_REFC``: (Default: "1")
| ``MAXTRIES_VX_ENSGRID_PROB_RETOP``: (Default: "1")
| ``MAXTRIES_VX_ENSPOINT``: (Default: "1")
| ``MAXTRIES_VX_ENSPOINT_MEAN``: (Default: "1")
| ``MAXTRIES_VX_ENSPOINT_PROB``: (Default: "1")


Subhourly Forecast Parameters
=================================

``SUB_HOURLY_POST``: (Default: "FALSE")
   Flag that indicates whether the forecast model will generate output files on a sub-hourly time interval (e.g., 10 minutes, 15 minutes, etc). This will also cause the post-processor to process these sub-hourly files. If ths is set to "TRUE", then ``DT_SUBHOURLY_POST_MNTS`` should be set to a value between "01" and "59".

``DT_SUB_HOURLY_POST_MNTS``: (Default: "00")
   Time interval in minutes between the forecast model output files. If ``SUB_HOURLY_POST`` is set to "TRUE", this needs to be set to a two-digit integer between "00" and "59". Note that if ``SUB_HOURLY_POST`` is set to "TRUE" but ``DT_SUB_HOURLY_POST_MNTS`` is set to "00", ``SUB_HOURLY_POST`` will get reset to "FALSE" in the experiment generation scripts (there will be an informational message in the log file to emphasize this). 


Customized Post Configuration Parameters
========================================

``USE_CUSTOM_POST_CONFIG_FILE``: (Default: "FALSE")
   Flag that determines whether a user-provided custom configuration file should be used for post-processing the model data. If this is set to "TRUE", then the workflow will use the custom post-processing (UPP) configuration file specified in ``CUSTOM_POST_CONFIG_FP``. Otherwise, a default configuration file provided in the UPP repository will be used.

``CUSTOM_POST_CONFIG_FP``: (Default: "")
   The full path to the custom post flat file, including filename, to be used for post-processing. This is only used if ``CUSTOM_POST_CONFIG_FILE`` is set to "TRUE".


Community Radiative Transfer Model (CRTM) Parameters
=======================================================

These variables set parameters associated with outputting satellite fields in the :term:`UPP` :term:`grib2` files using the Community Radiative Transfer Model (CRTM).

``USE_CRTM``: (Default: "FALSE")
   Flag that defines whether external CRTM coefficient files have been staged by the user in order to output synthetic satellite products available within the UPP. If this is set to "TRUE", then the workflow will check for these files in the directory CRTM_DIR. Otherwise, it is assumed that no satellite fields are being requested in the UPP configuration.

``CRTM_DIR``: (Default: "")
   This is the path to the top CRTM fix file directory. This is only used if USE_CRTM is set to "TRUE".

Ensemble Model Parameters
============================

``DO_ENSEMBLE``: (Default: "FALSE")
   Flag that determines whether to run a set of ensemble forecasts (for each set of specified cycles).  If this is set to "TRUE", ``NUM_ENS_MEMBERS`` forecasts are run for each cycle, each with a different set of stochastic seed values. Otherwise, a single forecast is run for each cycle.

``NUM_ENS_MEMBERS``: (Default: "1")
   The number of ensemble members to run if ``DO_ENSEMBLE`` is set to "TRUE". This variable also controls the naming of the ensemble member directories. For example, if ``NUM_ENS_MEMBERS`` is set to "8", the member directories will be named mem1, mem2, ..., mem8.  If it is set to "08" (with a leading zero), the member directories will be named mem01, mem02, ..., mem08. However, after reading in the number of characters in this string (in order to determine how many leading zeros, if any, should be placed in the names of the member directories), the workflow generation scripts strip away those leading zeros. Thus, in the variable definitions file (``GLOBAL_VAR_DEFNS_FN``), this variable appears with its leading zeros stripped. This variable is not used if ``DO_ENSEMBLE`` is not set to "TRUE".


Stochastic Physics Parameters
================================

..
   COMMENT: Move all physic params up with CCPP section.

For the most updated and detailed documentation of these parameters, see the `UFS Stochastic Physics Documentation <https://stochastic-physics.readthedocs.io/en/latest/namelist_options.html>`__.

General Stochastic Physics Options
--------------------------------------


``NEW_LSCALE``: (Default: "TRUE") 
   #

..
   COMMENT: Cannot find information on NEW_LSCALE variable in the stochastic physics docs. 

Specific Humidity (SHUM) Perturbation Parameters
---------------------------------------------------

``DO_SHUM``: (Default: "FALSE")
   Specific Humidity (SHUM) perturbations multiply the low-level specific humidity by a small random number at each time-step. The SHUM scheme attempts to address missing physics phenomena (e.g., cold pools, gust fronts) most active in convective regions. 

``ISEED_SHUM``: (Default: "2")
   Seed for setting the SHUM random number sequence.

``SHUM_MAG``: (Default: "0.006") 
   Amplitudes of random patterns. Corresponds to the variable ``shum`` in ``input.nml``.

``SHUM_LSCALE``: (Default: "150000")
   Decorrelation spatial scale in meters.

``SHUM_TSCALE``: (Default: "21600")
   Decorrelation timescale in seconds. Corresponds to the variable ``shum_tau`` in ``input.nml``.

``SHUM_INT``: (Default: "3600")
   Interval in seconds to update random pattern (optional). Perturbations still get applied at every time-step. Corresponds to the variable ``shumint`` in ``input.nml``.

Stochastically Perturbed Physics Tendencies (SPPT) Parameters
-----------------------------------------------------------------

``DO_SPPT``: (Default: "FALSE")
   Stochastically Perturbed Physics Tendencies (SPPT) multiplies the physics tendencies by a random number O [0,2] before updating the model state. Addresses error in the physics parameterizations (either missing physics or unresolved subgrid processes). It is most active in the boundary layer and convective regions. 

..
   COMMENT: Does it need to be O? can it be X? or some other variable/letter that doesn't look like the number zero? 

``ISEED_SPPT``: (Default: "1") 
   Seed for setting the SPPT random number sequence.

``SPPT_MAG``: (Default: "0.7")
   Amplitude of random patterns. Corresponds to the variable ``sppt`` in ``input.nml``.

``SPPT_LOGIT``: (Default: "TRUE")
   Limits the SPPT perturbations to between 0 and 2. Should be "TRUE"; otherwise the model will crash.

``SPPT_LSCALE``: (Default: "150000")
   Decorrelation spatial scales in meters. 

``SPPT_TSCALE``: (Default: "21600") 
   Decorrelation timescale in seconds. Corresponds to the variable ``sppt_tau`` in ``input.nml``.
   
``SPPT_INT``: (Default: "3600") 
   Interval in seconds to update random pattern (optional parameter). Perturbations still get applied at every time-step. Corresponds to the variable ``spptint`` in ``input.nml``.

``SPPT_SFCLIMIT``: (Default: "TRUE")
   When "TRUE", tapers the SPPT perturbations to zero at the model’s lowest level, which helps reduce model crashes. 

``USE_ZMTNBLCK``: (Default: "FALSE")
   When "TRUE", do not apply perturbations below the dividing streamline that is diagnosed by the gravity wave drag, mountain blocking scheme

Stochastic Kinetic Energy Backscatter (SKEB) Parameters
----------------------------------------------------------

``DO_SKEB``: (Default: "FALSE")
   Stochastic Kinetic Energy Backscatter (SKEB) adds wind perturbations to the model state. Perturbations are random in space/time, but amplitude is determined by a smoothed dissipation estimate provided by the :term:`dynamical core`. SKEB addresses errors in the dynamics more active in the mid-latitudes.

``ISEED_SKEB``: (Default: "3")
   Seed for setting the SHUM random number sequence.

``SKEB_MAG``: (Default: "0.5") 
   Amplitude of random patterns. Corresponds to the variable ``skeb`` in ``input.nml``.

``SKEB_LSCALE``: (Default: "150000")
   Decorrelation spatial scale in meters. 

``SKEB_TSCALE``: (Default: "21600")
   Decorrelation timescale in seconds. Corresponds to the variable ``skeb_tau`` in ``input.nml``.

``SKEB_INT``: (Default: "3600")
   Interval in seconds to update random pattern (optional). Perturbations still get applied every time-step. Corresponds to the variable ``skebint`` in ``input.nml``.

``SKEBNORM``: (Default: "1")
   Patterns:
      * 0-random pattern is stream function
      * 1-pattern is K.E. norm
      * 2-pattern is vorticity

..
   COMMENT: Stochastic physics docs say the default is zero... Have the numbers changed? Or did the default change?


``SKEB_VDOF``: (Default: "10")
   The number of degrees of freedom in the vertical for the SKEB random pattern. 

..
   COMMENT: The vertical what?


SPP Stochastic Physics Parameters
------------------------------------

Set default SPP stochastic physics options. Each SPP option is an array, applicable (in order) to the scheme/parameter listed in ``SPP_VAR_LIST``. Enter each value of the array in ``config.sh`` as shown below without commas or single quotes (e.g., ``SPP_VAR_LIST=( "pbl" "sfc" "mp" "rad" "gwd"`` ). Both commas and single quotes will be added by Jinja when creating the namelist.

.. note::
   SPP is currently only available for specific physics schemes used in the RAP/HRRR physics suite. Users need to be aware of which :term:`SDF` is chosen when turning this option on. 

..
   COMMENT: Is this still the case? 
   COMMENT: What is the difference between SPPT (above) and SPP?

# Patterns evolve and are applied at each time step.

..
   COMMENT: What does that mean?


``DO_SPP``: (Default: "false")
   Turn on the SPP Stochastic Physics Parameters. 

..
   COMMENT: What does SPP do? Need a description similar to the SKEB/SHUM/SPPT descriptions. 
   COMMENT: How are SPPT and SPP different? 

``SPP_VAR_LIST``: (Default: ( "pbl" "sfc" "mp" "rad" "gwd" ) )

..
   COMMENT: Need an explanation of these default variables. 

``SPP_MAG_LIST``: (Default: ( "0.2" "0.2" "0.75" "0.2" "0.2" ) ) 
   Corresponds to the variable ``spp_prt_list`` in ``input.nml``

``SPP_LSCALE``: (Default: ( "150000.0" "150000.0" "150000.0" "150000.0" "150000.0" ) )
   Decorrelation spatial scale in meters.
   
``SPP_TSCALE``: (Default: ( "21600.0" "21600.0" "21600.0" "21600.0" "21600.0" ) ) 
   Corresponds to the variable ``spp_tau`` in ``input.nml``.

``SPP_SIGTOP1``: (Default: ( "0.1" "0.1" "0.1" "0.1" "0.1") )
   Lower sigma level to taper perturbations to zero. 

..
   COMMENT: This is a guess. Needs review. 

``SPP_SIGTOP2``: (Default: ( "0.025" "0.025" "0.025" "0.025" "0.025" ) )
   Upper sigma level to taper perturbations to zero.

..
   COMMENT: This is a guess. Needs review. 

``SPP_STDDEV_CUTOFF``: (Default: ( "1.5" "1.5" "2.5" "1.5" "1.5" ) )

..
   COMMENT: Need an explanation of this variable. 

``ISEED_SPP``: (Default: ( "4" "4" "4" "4" "4" ) )
   Seed for setting the SPP random number sequence.

..
   COMMENT: This is a guess. Needs review. 

Land Surface Model (LSM) SPP
-------------------------------

Turn on SPP in Noah or RUC LSM (support for Noah MP is in progress). Please be aware of the :term:`SDF` that you choose if you wish to turn on Land Surface Model (LSM) SPP. SPP in LSM schemes is handled in the ``&nam_sfcperts`` namelist block instead of in ``&nam_sppperts``, where all other SPP is implemented. The default perturbation frequency is determined by the ``fhcyc`` namelist entry. Since that parameter is set to zero in the SRW App, use ``LSM_SPP_EACH_STEP`` to perturb every time step. 

LSM perturbations include soil moisture content [SMC] (volume fraction), vegetation fraction (VGF), albedo (ALB), salinity (SAL), emissivity (EMI), surface roughness (ZOL) (in cm), and soil temperature (STC). Perturbations to soil moisture content (SMC) are only applied at the first time step. Only five perturbations at a time can be applied currently, but all seven are shown below. In addition, only one unique *iseed* value is allowed at the moment, and it is used for each pattern.

``DO_LSM_SPP``: (Default: "false") 
   Turns on LSM SPP. When "TRUE", sets ``lndp_type=2``.

..
   COMMENT: What does LSM SPP do? Need a description similar to the SKEB/SHUM/SPPT descriptions. Also, where is lndp_type set? The weather model?

``LSM_SPP_TSCALE``: (Default: ( ( "21600" "21600" "21600" "21600" "21600" "21600" "21600" ) )
   Decorrelation timescale in seconds. 

``LSM_SPP_LSCALE``: (Default: ( ( "150000" "150000" "150000" "150000" "150000" "150000" "150000" ) )
   Decorrelation spatial scale in meters.

``ISEED_LSM_SPP``: (Default: ("9") )
   Seed for setting the LSM SPP random number sequence.

``LSM_SPP_VAR_LIST``: (Default: ( ( "smc" "vgf" "alb" "sal" "emi" "zol" "stc" ) )
   Indicates which LSM variables to perturb. 

``LSM_SPP_MAG_LIST``: (Default: ( ( "0.2" "0.001" "0.001" "0.001" "0.001" "0.001" "0.2" ) )
   Sets the amplitude of random patterns for each of the LSM perturbations. 

``LSM_SPP_EACH_STEP``: (Default: "true") 
   When set to "TRUE", it sets ``lndp_each_step=.true.`` and perturbs each time step. 

..
   COMMENT: Where is lndp_each_step found?
   COMMENT: All definitions in this section are my best guess and need revision. 


Halo Blend Parameter
====================
``HALO_BLEND``: (Default: "10")
   Number of rows into the computational domain that should be blended with the LBCs.  To shut :term:`halo` blending off, set this to zero.

FVCOM Parameter
===============
``USE_FVCOM``: (Default: "FALSE")
   Flag that specifies whether or not to update surface conditions in FV3-LAM with fields generated from the Finite Volume Community Ocean Model (FVCOM). If set to "TRUE", lake/sea surface temperatures, ice surface temperatures, and ice placement will be overwritten using data provided by FVCOM. This is done by running the executable ``process_FVCOM.exe`` in the ``MAKE_ICS_TN`` task to modify the file ``sfc_data.nc`` generated by ``chgres_cube``.  Note that the FVCOM data must already be interpolated to the desired FV3-LAM grid. 

``FVCOM_WCSTART``: (Default: "cold")
   Define if this is a "warm" start or a "cold" start. Setting this to "warm" will read in ``sfc_data``.nc generated in a RESTART directory. Setting this to "cold" will read in the ``sfc_data``.nc generated from ``chgres_cube`` in the ``make_ics`` portion of the workflow. Valid values: "cold" "warm"

``FVCOM_DIR``: (Default: "/user/defined/dir/to/fvcom/data")
   User-defined directory where the ``fvcom.nc`` file containing FVCOM data on the FV3-LAM native grid is located. The file name in this directory must be ``fvcom.nc``.

``FVCOM_FILE``: (Default: "fvcom.nc")
   Name of file located in ``FVCOM_DIR`` that has FVCOM data interpolated to the FV3-LAM grid. This file will be copied later to a new location and the name changed to ``fvcom.nc`` if a name other than ``fvcom.nc`` is selected.

Compiler Parameter
==================
``COMPILER``: (Default: "intel")
   Type of compiler invoked during the build step. Currently, this must be set manually (i.e., it is not inherited from the build system in the ``ufs-srweather-app`` directory).


Thread Affinity interface
===========================

.. note::
   Note that settings for the make_grid and make_orog tasks are not included below as they do not use parallelized code.

..
   COMMENT: The note above is in config_defaults.sh comments, but make_orog does seem to be included below... should I remove it? 

``KMP_AFFINITY_*``: (Default: see below)

   .. code-block:: console

      KMP_AFFINITY_MAKE_OROG="disabled"
      KMP_AFFINITY_MAKE_SFC_CLIMO="scatter"
      KMP_AFFINITY_MAKE_ICS="scatter"
      KMP_AFFINITY_MAKE_LBCS="scatter"
      KMP_AFFINITY_RUN_FCST="scatter"
      KMP_AFFINITY_RUN_POST="scatter"

   Intel's runtime library can bind OpenMP threads to physical processing units. The interface is controlled using the KMP_AFFINITY environment variable. Thread affinity restricts execution of certain threads to a subset of the physical processing units in a multiprocessor computer. Depending on the system (machine) topology, application, and operating system, thread affinity can have a dramatic effect on the application speed and on the execution speed of a program." Valid values: "scatter" "disabled" "balanced" "compact" "explicit" "none"

   For more information, see the `Intel Development Reference Guide <https://software.intel.com/content/www/us/en/develop/documentation/cpp-compiler-developer-guide-and-reference/top/optimization-and-programming-guide/openmp-support/openmp-library-support/thread-affinity-interface-linux-and-windows.html>`__. 

``OMP_NUM_THREADS_*``: (Default: see below)

   .. code-block:: console

      OMP_NUM_THREADS_MAKE_OROG="6"
      OMP_NUM_THREADS_MAKE_SFC_CLIMO="1"
      OMP_NUM_THREADS_MAKE_ICS="1"
      OMP_NUM_THREADS_MAKE_LBCS="1"
      OMP_NUM_THREADS_RUN_FCST="2"    # atmos_nthreads in model_configure
      OMP_NUM_THREADS_RUN_POST="1"

   The number of OpenMP threads to use for parallel regions.

``OMP_STACKSIZE_*``: (Default: see below)

   .. code-block:: console

      OMP_STACKSIZE_MAKE_OROG="2048m"
      OMP_STACKSIZE_MAKE_SFC_CLIMO="1024m"
      OMP_STACKSIZE_MAKE_ICS="1024m"
      OMP_STACKSIZE_MAKE_LBCS="1024m"
      OMP_STACKSIZE_RUN_FCST="1024m"
      OMP_STACKSIZE_RUN_POST="1024m"

   Controls the size of the stack for threads created by the OpenMP implementation.

