.. This is a continuation of the ConfigWorkflow.rst chapter

.. _ConfigParameters:

Grid Generation Parameters
==========================
``GRID_GEN_METHOD``: (Default: “”)
   This variable specifies the method to use to generate a regional grid in the horizontal.  The only supported value of this parameter is “ESGgrid”, in which case the Extended Schmidt Gnomonic grid generation method developed by Jim Purser(1) of EMC will be used. 

(1)Purser, R. J., D. Jovic, G. Ketefian, T. Black, J. Beck, J. Dong, and J. Carley, 2020: The Extended Schmidt Gnomonic Grid for Regional Applications. Unified Forecast System (UFS) Users’ Workshop. July 27-29, 2020.

.. note::

   #. If the experiment is using one of the predefined grids (i.e. if ``PREDEF_GRID_NAME`` is set to the name of one of the valid predefined grids), then ``GRID_GEN_METHOD`` will be reset to the value of ``GRID_GEN_METHOD`` for that grid.  This will happen regardless of whether or not ``GRID_GEN_METHOD`` is assigned a value in the user-specified experiment configuration file, i.e. any value it may be assigned in the experiment configuration file will be overwritten.

   #. If the experiment is not using one of the predefined grids (i.e. if ``PREDEF_GRID_NAME`` is set to a null string), then ``GRID_GEN_METHOD`` must be set in the experiment configuration file.  Otherwise, it will remain set to a null string, and the experiment generation will fail because the generation scripts check to ensure that it is set to a non-empty string before creating the experiment directory.

The following parameters must be set if using the "ESGgrid" method of generating a regional grid (i.e. for ``GRID_GEN_METHOD`` set to "ESGgrid").  

``ESGgrid_LON_CTR``: (Default: “”)
   The longitude of the center of the grid (in degrees).

``ESGgrid_LAT_CTR``: (Default: “”)
   The latitude of the center of the grid (in degrees).

``ESGgrid_DELX``: (Default: “”)
   The cell size in the zonal direction of the regional grid (in meters).

``ESGgrid_DELY``: (Default: “”)
   The cell size in the meridional direction of the regional grid (in meters).

``ESGgrid_NX``: (Default: “”)
   The number of cells in the zonal direction on the regional grid.

``ESGgrid_NY``: (Default: “”)
   The number of cells in the meridional direction on the regional grid.

``ESGgrid_WIDE_HALO_WIDTH``: (Default: “”)
   The width (in units of number of grid cells) of the halo to add around the regional grid before shaving the halo down to the width(s) expected by the forecast model.  

In order to generate grid files containing halos that are 3-cell and 4-cell wide and orography files with halos that are 0-cell and 3-cell wide (all of which are required as inputs to the forecast model), the grid and orography tasks first create files with halos around the regional domain of width ``ESGgrid_WIDE_HALO_WIDTH`` cells.  These are first stored in files.  The files are then read in and "shaved" down to obtain grid files with 3-cell-wide and 4-cell-wide halos and orography files with 0-cell-wide (i.e. no halo) and 3-cell-wide halos.  For this reason, we refer to the original halo that then gets shaved down as the "wide" halo, i.e. because it is wider than the 0-cell-wide, 3-cell-wide, and 4-cell-wide halos that we will eventually end up with.  Note that the grid and orography files with the wide halo are only needed as intermediates in generating the files with 0-cell-, 3-cell-, and 4-cell-wide halos; they are not needed by the forecast model.

Computational Forecast Parameters
=================================
``DT_ATMOS``: (Default: “”)
   The main forecast model integration time step.  As described in the forecast model documentation, "It corresponds to the frequency with which the top level routine in the dynamics is called as well as the frequency with which the physics is called."

``LAYOUT_X, LAYOUT_Y``: (Default: “”)
   The number of MPI tasks (processes) to use in the two horizontal directions (x and y) of the regional grid when running the forecast model.

``BLOCKSIZE``: (Default: “”)
   The amount of data that is passed into the cache at a time.

Here, we set these parameters to null strings. This is so that, for any one of these parameters:

#. If the experiment is using a predefined grid and the user sets the parameter in the user-specified experiment configuration file (``EXPT_CONFIG_FN``), that value will be used in the forecast(s). Otherwise, the default value of the parameter for that predefined grid will be used.

#. If the experiment is not using a predefined grid (i.e. it is using a custom grid whose parameters are specified in the experiment configuration file), then the user must specify a value for the parameter in that configuration file.  Otherwise, the parameter will remain set to a null string, and the experiment generation will fail, because the generation scripts check to ensure that all the parameters defined in this section are set to non-empty strings before creating the experiment directory.

Write-Component (Quilting) Parameters
=====================================
``QUILTING``: (Default: “TRUE”)
   Flag that determines whether or not to use the write-component for writing forecast output files to disk.  If set to “TRUE”, the forecast model will output files named ``dynf$HHH.nc`` and ``phyf$HHH.nc`` (where HHH is the 3-hour output forecast hour) containing dynamics and physics fields, respectively, on the write-component grid (the regridding from the native FV3-LAM grid to the write-component grid is done by the forecast model).  If ``QUILTING`` is set to "FALSE", then the output file names are ``fv3_history.nc`` and ``fv3_history2d.nc`` and contain fields on the native grid.  Note that if ``QUILTING`` is set to “FALSE”, then the ``RUN_POST_TN`` (meta)task cannot be run because the Unified Post Processor (UPP) code that this task calls cannot process fields on the native grid.  In that case, the ``RUN_POST_TN`` (meta)task will be automatically removed from the Rocoto workflow XML.

``PRINT_ESMF``: (Default: “FALSE”)
   Flag for whether or not to output extra (debugging) information from ESMF routines.  Must be "TRUE" or "FALSE".  Note that the write-component uses ESMF library routines to interpolate from the native forecast model grid to the user-specified output grid (which is defined in the model configuration file (model_configure) in the forecast run directory).

``WRTCMP_write_groups``: (Default: “1”)
   The number of write groups (i.e. groups of MPI tasks) to use in the write-component.

``WRTCMP_write_tasks_per_group``: (Default: “20”)
   The number of MPI tasks to allocate for each write group.

Predefined Grid Parameters
==========================
``PREDEF_GRID_NAME``: (Default: “”)
   This parameter specifies the name of a predefined regional grid.

.. note::

   * If ``PREDEF_GRID_NAME`` is set to a valid predefined grid name, the grid generation method ``GRID_GEN_METHOD``, the (native) grid parameters, and the write-component grid parameters are set to predefined values for the specified grid, overwriting any settings of these parameters in the user-specified experiment configuration file (``config.sh``).  In addition, if the time step ``DT_ATMOS`` and the computational parameters ``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE`` are not specified in that configuration file, they are also set to predefined values for the specified grid.

   * If ``PREDEF_GRID_NAME`` is set to an empty string, it implies the user is providing the native grid parameters in the user-specified experiment configuration file (``EXPT_CONFIG_FN``).  In this case, the grid generation method ``GRID_GEN_METHOD``, the native grid parameters, and the write-component grid parameters as well as the main time step (``DT_ATMOS``) and the computational parameters ``LAYOUT_X``, ``LAYOUT_Y``, and ``BLOCKSIZE`` must be set in that configuration file.

Setting ``PREDEF_GRID_NAME`` provides a convenient method of specifying a commonly used set of grid-dependent parameters.  The predefined grid parameters are specified in the script

.. code-block:: console

  ush/set_predef_grid_params.sh

Currently supported ``PREDEF_GRID_NAME`` options are "RRFS_CONUS_25km," "RRFS_CONUS_13km," and "RRFS_CONUS_3km."

Pre-existing Directory Parameter
================================
``PREEXISTING_DIR_METHOD``: (Default: “delete”)
   This variable determines the method to deal with pre-existing directories [e.g ones generated by previous calls to the experiment generation script using the same experiment name (``EXPT_SUBDIR``) as the current experiment].  This variable must be set to one of "delete", "rename", and "quit".  The resulting behavior for each of these values is as follows:

   * "delete": The preexisting directory is deleted and a new directory (having the same name as the original preexisting directory) is created.

   * "rename": The preexisting directory is renamed and a new directory (having the same name as the original pre-existing directory) is created.  The new name of the preexisting directory consists of its original name and the suffix "_oldNNN", where NNN is a 3-digit integer chosen to make the new name unique.

   * "quit": The preexisting directory is left unchanged, but execution of the currently running script is terminated.  In this case, the preexisting directory must be dealt with manually before rerunning the script.

Verbose Parameter
=================
``VERBOSE``: (Default: “TRUE”)
   This is a flag that determines whether or not the experiment generation and workflow task scripts print out extra informational messages.

Pre-Processing Parameters
=========================
These parameters set flags (and related directories) that determine whether the grid, orography, and/or surface climatology file generation tasks should be run.  Note that these are all cycle-independent tasks, i.e. if they are to be run, they do so only once at the beginning of the workflow before any cycles are run.

``RUN_TASK_MAKE_GRID``: (Default: “TRUE”)
   Flag that determines whether the grid file generation task (``MAKE_GRID_TN``) is to be run. If this is set to "TRUE", the grid generation task is run and new grid  files are generated.  If it is set to "FALSE", then the scripts look for pre-generated grid files in the directory specified by ``GRID_DIR`` (see below).

``GRID_DIR``: (Default: "/path/to/pregenerated/grid/files")
   The directory in which to look for pre-generated grid files if ``RUN_TASK_MAKE_GRID`` is set to "FALSE".
 
``RUN_TASK_MAKE_OROG``: (Default: “TRUE”)
   Same as ``RUN_TASK_MAKE_GRID`` but for the orography generation task (``MAKE_OROG_TN``).

``OROG_DIR``: (Default: "/path/to/pregenerated/orog/files")
   Same as ``GRID_DIR`` but for the orography generation task.

``RUN_TASK_MAKE_SFC_CLIMO``: (Default: “TRUE”)
   Same as ``RUN_TASK_MAKE_GRID`` but for the surface climatology generation task (``MAKE_SFC_CLIMO_TN``).

``SFC_CLIMO_DIR``: (Default: "/path/to/pregenerated/surface/climo/files")
   Same as ``GRID_DIR`` but for the surface climatology generation task.

Surface Climatology Parameter
=============================
``SFC_CLIMO_FIELDS``: (Default: “("facsf" "maximum_snow_albedo" "slope_type" "snowfree_albedo" "soil_type" "substrate_temperature" "vegetation_greenness" "vegetation_type")”)
   Array containing the names of all the fields for which the ``MAKE_SFC_CLIMO_TN`` task generates files on the native FV3-LAM grid.

Fixed File Parameters
=====================
Set parameters associated with the fixed (i.e. static) files.  For the main NOAA HPC platforms, as well as Cheyenne, Odin, and Stampede, fixed files are prestaged with paths defined in the ``setup.sh`` script.

``FIXgsm``: (Default: “”)
   System directory in which the majority of fixed (i.e. time-independent) files that are needed to run the FV3-LAM model are located.

``TOPO_DIR``: (Default: “”)
   The location on disk of the static input files used by the ``make_orog task`` (``orog.x`` and ``shave.x``). Can be the same as ``FIXgsm``.

``SFC_CLIMO_INPUT_DIR``: (Default: “”)
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

   Names of (some of the) global data files that are assumed to exist in a system directory specified (this directory is machine-dependent; the experiment generation scripts will set it and store it in the variable ``FIXgsm``).  These file names also appear directly in the forecast model's input namelist file.

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
      "global_co2historicaldata_glob.txt" \
      "co2monthlycyc.txt" \
      "global_h2o_pltc.f77" \
      "global_hyblev.l65.txt" \
      "global_zorclim.1x1.grb" \
      "global_sfc_emissivity_idx.txt" \
      "global_solarconstant_noaa_an.txt" \
      "replace_with_FIXgsm_ozone_prodloss_filename")

   If not running in NCO mode, this array contains the names of the files to copy from the ``FIXgsm`` system directory to the ``FIXam`` directory under the experiment directory.  Note that the last element has a dummy value. This last element will get reset by the workflow generation scripts to the name of the ozone production/loss file to copy from ``FIXgsm``.  The name of this file depends on the ozone parameterization being used, and that in turn depends on the CCPP physics suite specified for the experiment.  Thus, the CCPP physics suite XML must first be read in to determine the ozone parameterization and then the name of the ozone production/loss file.  These steps are carried out elsewhere (in one of the workflow generation scripts/functions).

``FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING``: (Default: see below)
   .. code-block:: console

      ("FNGLAC | $FNGLAC" \
       "FNMXIC | $FNMXIC" \
       "FNTSFC | $FNTSFC" \
       "FNSNOC | $FNSNOC" \
       "FNAISC | $FNAISC" \
       "FNSMCC | $FNSMCC" \
       "FNMSKH | $FNMSKH" )

   This array is used to set some of the namelist variables in the forecast model's namelist file that represent the relative or absolute paths of various fixed files (the first column of the array, where columns are delineated by the pipe symbol "|") to the full paths to these files in the FIXam directory derived from the corresponding workflow variables containing file names (the second column of the array).

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

      ("aerosol.dat            	   | global_climaeropac_global.txt" \
       "co2historicaldata_2010.txt | fix_co2_proj/global_co2historicaldata_2010.txt" \
       "co2historicaldata_2011.txt | fix_co2_proj/global_co2historicaldata_2011.txt" \
       "co2historicaldata_2012.txt | fix_co2_proj/global_co2historicaldata_2012.txt" \
       "co2historicaldata_2013.txt | fix_co2_proj/global_co2historicaldata_2013.txt" \
       "co2historicaldata_2014.txt | fix_co2_proj/global_co2historicaldata_2014.txt" \
       "co2historicaldata_2015.txt | fix_co2_proj/global_co2historicaldata_2015.txt" \
       "co2historicaldata_2016.txt | fix_co2_proj/global_co2historicaldata_2016.txt" \
       "co2historicaldata_2017.txt | fix_co2_proj/global_co2historicaldata_2017.txt" \
       "co2historicaldata_2018.txt | fix_co2_proj/global_co2historicaldata_2018.txt" \
       "co2historicaldata_glob.txt | global_co2historicaldata_glob.txt" \
       "co2monthlycyc.txt      	   | co2monthlycyc.txt" \
       "global_h2oprdlos.f77   	   | global_h2o_pltc.f77" \
       "global_zorclim.1x1.grb 	   | global_zorclim.1x1.grb" \
       "sfc_emissivity_idx.txt 	   | global_sfc_emissivity_idx.txt" \
       "solarconstant_noaa_an.txt  | global_solarconstant_noaa_an.txt" \
       "global_o3prdlos.f77    	   | " )

   This array specifies the mapping to use between the symlinks that need to be created in each cycle directory (these are the "files" that FV3 looks for) and their targets in the ``FIXam`` directory.  The first column of the array specifies the symlink to be created, and the second column specifies its target file in ``FIXam`` (where columns are delineated by the pipe symbol "|").

Workflow Task Parameters
========================
These parameters set the names of the various workflow tasks and usually do not need to be changed.  For each task, additional values set the parameters to pass to the job scheduler (e.g. slurm) that will submit a job for each task to be run.  Parameters include the number of nodes to use to run the job, the number of MPI processes per node, the maximum walltime to allow for the job to complete, and the maximum number of times to attempt to run each task.

Task names:

| ``MAKE_GRID_TN``: (Default: "make_grid")
| ``MAKE_OROG_TN``: (Default: “make_orog")
| ``MAKE_SFC_CLIMO_TN``: (Default: “make_sfc_climo")
| ``GET_EXTRN_ICS_TN``: (Default: "get_extrn_ics")
| ``GET_EXTRN_LBCS_TN``: (Default: "get_extrn_lbcs")
| ``MAKE_ICS_TN``: (Default: "make_ics")
| ``MAKE_LBCS_TN``: (Default: "make_lbcs")
| ``RUN_FCST_TN``: (Default: "run_fcst")
| ``RUN_POST_TN``: (Default: "run_post")

Number of nodes:

| ``NODES_MAKE_GRID``: (Default: "1")
| ``NODES_MAKE_OROG``: (Default: "1")
| ``NODES_MAKE_SFC_CLIMO``: (Default: "2")
| ``NODES_GET_EXTRN_ICS``: (Default: "1")
| ``NODES_GET_EXTRN_LBCS``: (Default: "1")
| ``NODES_MAKE_ICS``: (Default: "4")
| ``NODES_MAKE_LBCS``: (Default: "4”)
| ``NODES_RUN_FCST``: (Default: "")  # Calculated in the workflow generation scripts.
| ``NODES_RUN_POST``: (Default: "2")

Number of MPI processes per node:

| ``PPN_MAKE_GRID``: (Default: "24")
| ``PPN_MAKE_OROG``: (Default: "24")
| ``PPN_MAKE_SFC_CLIMO``: (Default: "24")
| ``PPN_GET_EXTRN_ICS``: (Default: "1")
| ``PPN_GET_EXTRN_LBCS``: (Default: "1")
| ``PPN_MAKE_ICS``: (Default: "12")
| ``PPN_MAKE_LBCS``: (Default: "12")
| ``PPN_RUN_FCST``: (Default: "24")  # Can be changed depending on the number of threads used.
| ``PPN_RUN_POST``: (Default: "24")

Wall times:

| ``TIME_MAKE_GRID``: (Default: "00:20:00")
| ``TIME_MAKE_OROG``: (Default: "00:20:00”)
| ``TIME_MAKE_SFC_CLIMO``: (Default: "00:20:00")
| ``TIME_GET_EXTRN_ICS``: (Default: "00:45:00")
| ``TIME_GET_EXTRN_LBCS``: (Default: "00:45:00")
| ``TIME_MAKE_ICS``: (Default: "00:30:00")
| ``TIME_MAKE_LBCS``: (Default: "00:30:00")
| ``TIME_RUN_FCST``: (Default: "04:30:00")
| ``TIME_RUN_POST``: (Default: "00:15:00")

Maximum number of attempts.

| ``MAXTRIES_MAKE_GRID``: (Default: "1")
| ``MAXTRIES_MAKE_OROG``: (Default: "1")
| ``MAXTRIES_MAKE_SFC_CLIMO``: (Default: "1")
| ``MAXTRIES_GET_EXTRN_ICS``: (Default: "1")
| ``MAXTRIES_GET_EXTRN_LBCS``: (Default: "1")
| ``MAXTRIES_MAKE_ICS``: (Default: "1")
| ``MAXTRIES_MAKE_LBCS``: (Default: "1")
| ``MAXTRIES_RUN_FCST``: (Default: "1")
| ``MAXTRIES_RUN_POST``: (Default: "1")

Customized Post Configuration Parameters
========================================
``USE_CUSTOM_POST_CONFIG_FILE``: (Default: “FALSE”)
   Flag that determines whether a user-provided custom configuration file should be used for post-processing the model data. If this is set to "TRUE", then the workflow will use the custom post-processing (UPP) configuration file specified in ``CUSTOM_POST_CONFIG_FP``. Otherwise, a default configuration file provided in the UPP repository will be used.

``CUSTOM_POST_CONFIG_FP``: (Default: “”)
   The full path to the custom post flat file, including filename, to be used for post-processing. This is only used if ``CUSTOM_POST_CONFIG_FILE`` is set to "TRUE".

Halo Blend Parameter
====================
``HALO_BLEND``: (Default: “10”)
   Number of rows into the computational domain that should be blended with the LBCs.  To shut halo blending off, set this to zero.

FVCOM Parameter
===============
``USE_FVCOM``: (Default: “FALSE”)
   Flag that specifies whether or not to update surface conditions in FV3-LAM with fields generated from the Finite Volume Community Ocean Model (FVCOM). If set to “TRUE”, lake/sea surface temperatures, ice surface temperatures, and ice placement will be overwritten by data provided by FVCOM. This is done by running the executable ``process_FVCOM.exe`` in the ``MAKE_ICS_TN`` task to modify the file ``sfc_data.nc`` generated by ``chgres_cube``.  Note that the FVCOM data must already be interpolated to the desired FV3-LAM grid. 

``FVCOM_DIR``: (Default: “/user/defined/dir/to/fvcom/data")
   User defined directory in which the file ``fvcom.nc`` containing FVCOM data on the FV3-LAM native grid is located. The file name in this directory must be ``fvcom.nc``.

``FVCOM_FILE``: (Default: “fvcom.nc”)
   Name of file located in ``FVCOM_DIR`` that has FVCOM data interpolated to FV3-LAM grid. This file will be copied later to a new location and the name changed to ``fvcom.nc``.

Compiler Parameter
==================
``COMPILER``: (Default: “intel”)
   Type of compiler invoked during the build step.  Currently, this must be set manually (i.e. it is not inherited from the build system in the ``ufs-srweather-app`` directory).

