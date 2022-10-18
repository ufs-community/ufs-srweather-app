.. _RunSRW:

===========================
Running the SRW App
=========================== 

This chapter explains how to set up and run the "out-of-the-box" case for the SRW App. However, the steps are relevant to any SRW Application experiment and can be modified to suit user goals. This chapter assumes that users have already built the SRW App by following the steps in :numref:`Chapter %s <BuildSRW>`. These steps are also applicable to containerized versions of the SRW App and assume that the user has completed Steps :numref:`Section %s <DownloadCodeC>` through :numref:`Section %s <RunContainer>`.

The out-of-the-box SRW App case builds a weather forecast for June 15-16, 2019. Multiple convective weather events during these two days produced over 200 filtered storm reports. Severe weather was clustered in two areas: the Upper Midwest through the Ohio Valley and the Southern Great Plains. This forecast uses a predefined 25-km Continental United States (:term:`CONUS`) domain (RRFS_CONUS_25km), the Global Forecast System (:term:`GFS`) version 16 physics suite (FV3_GFS_v16 :term:`CCPP`), and :term:`FV3`-based GFS raw external model data for initialization.

.. attention::

   The SRW Application has `four levels of support <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__. The steps described in this chapter will work most smoothly on preconfigured (Level 1) systems. This chapter can also serve as a starting point for running the SRW App on other systems (including generic Linux/Mac systems), but the user may need to perform additional troubleshooting. 


The overall procedure for generating an experiment is shown in :numref:`Figure %s <AppOverallProc>`, with the scripts to generate and run the workflow shown in red. The steps are as follows:

   #. :ref:`Download and stage data <Data>`
   #. :ref:`Optional: Configure a new grid <GridSpecificConfig>`
   #. :ref:`Generate a regional workflow experiment <GenerateForecast>`

      * :ref:`Configure the experiment parameters <UserSpecificConfig>`
      * :ref:`Load the python environment for the regional workflow <SetUpPythonEnv>`

   #. :ref:`Run the regional workflow <Run>` 
   #. :ref:`Optional: Plot the output <PlotOutput>`

.. _AppOverallProc:

.. figure:: _static/FV3LAM_wflow_overall.png
   :alt: Flowchart describing the SRW App workflow steps. 

   *Overall layout of the SRW App Workflow*

.. _Data:

Download and Stage the Data
============================

The SRW App requires input files to run. These include static datasets, initial and boundary conditions files, and model configuration files. On Level 1 systems, the data required to run SRW App tests are already available. For Level 2-4 systems, the data must be added. Detailed instructions on how to add the data can be found in :numref:`Section %s <DownloadingStagingInput>`. Sections :numref:`%s <Input>` and :numref:`%s <OutputFiles>` contain useful background information on the input and output files used in the SRW App. 

.. _GridSpecificConfig:

Grid Configuration
=======================

The SRW App officially supports four different predefined grids as shown in :numref:`Table %s <PredefinedGrids>`. The out-of-the-box SRW App case uses the ``RRFS_CONUS_25km`` predefined grid option. More information on the predefined and user-generated grid options can be found in :numref:`Chapter %s <LAMGrids>` for those who are curious. Users who plan to utilize one of the four predefined domain (grid) options may continue to :numref:`Step %s <GenerateForecast>`. Users who plan to create a new domain should refer to :numref:`Section %s <UserDefinedGrid>` for details on how to do so. At a minimum, these users will need to add the new grid name to the ``valid_param_vals.yaml`` script and add the corresponding grid-specific parameters in the ``set_predef_grid_params.py`` script. 

.. _PredefinedGrids:

.. table::  Predefined grids in the SRW App

   +----------------------+-------------------+--------------------------------+
   | **Grid Name**        | **Grid Type**     | **Quilting (write component)** |
   +======================+===================+================================+
   | RRFS_CONUS_25km      | ESG grid          | lambert_conformal              |
   +----------------------+-------------------+--------------------------------+
   | RRFS_CONUS_13km      | ESG grid          | lambert_conformal              |
   +----------------------+-------------------+--------------------------------+
   | RRFS_CONUS_3km       | ESG grid          | lambert_conformal              |
   +----------------------+-------------------+--------------------------------+
   | SUBCONUS_Ind_3km     | ESG grid          | lambert_conformal              |
   +----------------------+-------------------+--------------------------------+


.. _GenerateForecast:

Generate the Forecast Experiment 
=================================
Generating the forecast experiment requires three steps:

#. :ref:`Set experiment parameters <ExptConfig>`
#. :ref:`Set Python and other environment parameters <SetUpPythonEnv>`
#. :ref:`Run a script to generate the experiment workflow <GenerateWorkflow>`

The first two steps depend on the platform being used and are described here for each Level 1 platform. Users will need to adjust the instructions to reflect their machine configuration if they are working on a Level 2-4 platform. Information in :numref:`Chapter %s: Configuring the Workflow <ConfigWorkflow>` can help with this. 

.. _ExptConfig:

Set Experiment Parameters
---------------------------- 

Each experiment requires certain basic information to run (e.g., date, grid, physics suite). This information is specified in ``config_defaults.yaml`` and in the user-specified ``config.yaml`` file. When generating a new experiment, the SRW App first reads and assigns default values from the ``config_defaults.yaml`` file. Then, it reads and (re)assigns variables from the user's custom ``config.yaml`` file. 

For background info on ``config_defaults.yaml``, read :numref:`Section %s <DefaultConfigSection>`, or jump to :numref:`Section %s <UserSpecificConfig>` to continue configuring the experiment.

.. _DefaultConfigSection:

Default configuration: ``config_defaults.yaml``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::
   This section provides background information on how the SRW App uses the ``config_defaults.yaml`` file. It is informative, but users do not need to modify ``config_defaults.yaml`` to run the out-of-the-box case for the SRW App. Therefore, users may skip to :numref:`Step %s <UserSpecificConfig>` to continue configuring their experiment. 

Configuration variables in the ``config_defaults.yaml`` file appear in :numref:`Table %s <ConfigVarsDefault>`. Some of these default values are intentionally invalid in order to ensure that the user assigns valid values in the user-specified ``config.yaml`` file. Any settings provided in ``config.yaml`` will override the ``config_defaults.yaml`` 
settings. There is usually no need for a user to modify the default configuration file. Additional information on the default settings can be found in the file itself and in :numref:`Chapter %s <ConfigWorkflow>`. 

.. _ConfigVarsDefault:

.. table::  Configuration variables specified in the config_defaults.yaml script

   +----------------------+--------------------------------------------------------------+
   | **Group Name**       | **Configuration variables**                                  |
   +======================+==============================================================+
   | Experiment mode      | RUN_ENVIR                                                    | 
   +----------------------+--------------------------------------------------------------+
   | Machine and queue    | MACHINE, MACHINE_FILE, ACCOUNT, COMPILER, SCHED,             |
   |                      | LMOD_PATH, NCORES_PER_NODE, BUILD_MOD_FN, WFLOW_MOD_FN,      |
   |                      | PARTITION_DEFAULT, CLUSTERS_DEFAULT, QUEUE_DEFAULT,          |
   |                      | PARTITION_HPSS, CLUSTERS_HPSS, QUEUE_HPSS, PARTITION_FCST,   |
   |                      | CLUSTERS_FCST, QUEUE_FCST                                    |
   +----------------------+--------------------------------------------------------------+
   | Workflow management  | WORKFLOW_MANAGER, RUN_CMD_UTILS, RUN_CMD_FCST, RUN_CMD_POST  |
   +----------------------+--------------------------------------------------------------+
   | Cron                 | USE_CRON_TO_RELAUNCH, CRON_RELAUNCH_INTVL_MNTS               |
   +----------------------+--------------------------------------------------------------+
   | Directory parameters | EXPT_BASEDIR, EXPT_SUBDIR, EXEC_SUBDIR                       |
   +----------------------+--------------------------------------------------------------+
   | NCO mode             | COMINgfs, FIXLAM_NCO_BASEDIR, STMP, NET, envir, RUN, PTMP    |
   +----------------------+--------------------------------------------------------------+
   | Separator            | DOT_OR_USCORE                                                |
   +----------------------+--------------------------------------------------------------+
   | File name            | EXPT_CONFIG_FN, RGNL_GRID_NML_FN, DATA_TABLE_FN,             |
   |                      | DIAG_TABLE_FN, FIELD_TABLE_FN, FV3_NML_BASE_SUITE_FN,        |
   |                      | FV3_NML_YAML_CONFIG_FN, FV3_NML_BASE_ENS_FN,                 |
   |                      | MODEL_CONFIG_FN, NEMS_CONFIG_FN, FV3_EXEC_FN,                |
   |                      | FCST_MODEL, WFLOW_XML_FN, GLOBAL_VAR_DEFNS_FN,               |
   |                      | EXTRN_MDL_ICS_VAR_DEFNS_FN, EXTRN_MDL_LBCS_VAR_DEFNS_FN,     |
   |                      | WFLOW_LAUNCH_SCRIPT_FN, WFLOW_LAUNCH_LOG_FN                  |
   +----------------------+--------------------------------------------------------------+
   | Forecast             | DATE_FIRST_CYCL, DATE_LAST_CYCL, CYCL_HRS, INCR_CYCL_FREQ,   |
   |                      | FCST_LEN_HRS                                                 |
   +----------------------+--------------------------------------------------------------+
   | IC/LBC               | EXTRN_MDL_NAME_ICS, EXTRN_MDL_NAME_LBCS,                     |
   |                      | LBC_SPEC_INTVL_HRS, EXTRN_MDL_ICS_OFFSET_HRS,                |
   |                      | EXTRN_MDL_LBCS_OFFSET_HRS, FV3GFS_FILE_FMT_ICS,              |
   |                      | FV3GFS_FILE_FMT_LBCS                                         |
   +----------------------+--------------------------------------------------------------+
   | NOMADS               | NOMADS, NOMADS_file_type                                     |
   +----------------------+--------------------------------------------------------------+
   | External model       | EXTRN_MDL_SYSBASEDIR_ICS, EXTRN_MDL_SYSBASEDIR_LBCS,         |
   |                      | USE_USER_STAGED_EXTRN_FILES, EXTRN_MDL_SOURCE_BASEDIR_ICS,   |
   |                      | EXTRN_MDL_FILES_ICS, EXTRN_MDL_SOURCE_BASEDIR_LBCS,          |
   |                      | EXTRN_MDL_FILES_LBCS                                         |
   +----------------------+--------------------------------------------------------------+
   | CCPP                 | CCPP_PHYS_SUITE                                              |
   +----------------------+--------------------------------------------------------------+
   | Stochastic physics   | NEW_LSCALE, DO_SHUM, DO_SPPT, DO_SKEB, DO_SPP, DO_LSM_SPP,   |
   |                      | ISEED_SHUM, SHUM_MAG, SHUM_LSCALE, SHUM_TSCALE, SHUM_INT,    |
   |                      | ISEED_SPPT, SPPT_MAG, SPPT_LOGIT, SPPT_LSCALE, SPPT_TSCALE,  |
   |                      | SPPT_INT, SPPT_SFCLIMIT, USE_ZMTNBLCK, ISEED_SKEB,           |
   |                      | SKEB_MAG, SKEB_LSCALE, SKEP_TSCALE, SKEB_INT, SKEBNORM,      |
   |                      | SKEB_VDOF, ISEED_SPP, SPP_MAG_LIST, SPP_LSCALE, SPP_TSCALE,  | 
   |                      | SPP_SIGTOP1, SPP_SIGTOP2, SPP_STDDEV_CUTOFF, SPP_VAR_LIST,   |
   |                      | LSM_SPP_TSCALE, LSM_SPP_LSCALE, ISEED_LSM_SPP,               |
   |                      | LSM_SPP_VAR_LIST, LSM_SPP_MAG_LIST, LSM_SPP_EACH_STEP        |
   +----------------------+--------------------------------------------------------------+
   | GRID                 | GRID_GEN_METHOD, PREDEF_GRID_NAME                            |
   +----------------------+--------------------------------------------------------------+
   | ESG grid             | ESGgrid_LON_CTR, ESGgrid_LAT_CTR, ESGgrid_DELX,              |
   |                      | ESGgrid_DELY, ESGgrid_NX, ESGgrid_NY, ESGgrid_PAZI           |
   |                      | ESGgrid_WIDE_HALO_WIDTH                                      |
   +----------------------+--------------------------------------------------------------+
   | GFDL grid            | GFDLgrid_LON_T6_CTR, GFDLgrid_LAT_T6_CTR, GFDLgrid_RES,      |
   |                      | GFDLgrid_STRETCH_FAC, GFDLgrid_REFINE_RATIO,                 |
   |                      | GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G,                          |
   |                      | GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G,                            |
   |                      | GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G,                          |
   |                      | GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G,                            |
   |                      | GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES                       |
   +----------------------+--------------------------------------------------------------+
   | Input configuration  | DT_ATMOS, RESTART_INTERVAL, WRITE_DOPOST, LAYOUT_X,          |
   |                      | LAYOUT_Y, BLOCKSIZE, QUILTING,                               |
   |                      | PRINT_ESMF, WRTCMP_write_groups,                             |
   |                      | WRTCMP_write_tasks_per_group, WRTCMP_output_grid,            |
   |                      | WRTCMP_cen_lon, WRTCMP_cen_lat, WRTCMP_lon_lwr_left,         |
   |                      | WRTCMP_lat_lwr_left, WRTCMP_lon_upr_rght,                    |
   |                      | WRTCMP_lat_upr_rght, WRTCMP_dlon, WRTCMP_dlat,               |
   |                      | WRTCMP_stdlat1, WRTCMP_stdlat2, WRTCMP_nx, WRTCMP_ny,        |
   |                      | WRTCMP_dx, WRTCMP_dy                                         |
   +----------------------+--------------------------------------------------------------+
   | Experiment generation| PREEXISTING_DIR_METHOD, VERBOSE, DEBUG                       |
   +----------------------+--------------------------------------------------------------+
   | Cycle-independent    | RUN_TASK_MAKE_GRID, GRID_DIR, RUN_TASK_MAKE_OROG,            |
   |                      | OROG_DIR, RUN_TASK_MAKE_SFC_CLIMO, SFC_CLIMO_DIR             |
   +----------------------+--------------------------------------------------------------+
   | Cycle dependent      | RUN_TASK_GET_EXTRN_ICS, RUN_TASK_GET_EXTRN_LBCS,             |
   |                      | RUN_TASK_MAKE_ICS, RUN_TASK_MAKE_LBCS, RUN_TASK_RUN_FCST,    |
   |                      | RUN_TASK_RUN_POST                                            |
   +----------------------+--------------------------------------------------------------+
   | VX run tasks         | RUN_TASK_GET_OBS_CCPA, RUN_TASK_GET_OBS_MRMS,                |
   |                      | RUN_TASK_GET_OBS_NDAS, RUN_TASK_VX_GRIDSTAT,                 |
   |                      | RUN_TASK_VX_POINTSTAT, RUN_TASK_VX_ENSGRID,                  |
   |                      | RUN_TASK_VX_ENSPOINT                                         |
   +----------------------+--------------------------------------------------------------+
   | Fixed File Parameters| FIXgsm, FIXaer, FIXlut, TOPO_DIR, SFC_CLIMO_INPUT_DIR,       |
   |                      | FNGLAC, FNMXIC, FNTSFC, FNSNOC, FNZORC,                      |
   |                      | FNAISC, FNSMCC, FNMSKH, FIXgsm_FILES_TO_COPY_TO_FIXam,       |
   |                      | FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING,                      |
   |                      | FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING,                  |
   |                      | CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING                        |
   +----------------------+--------------------------------------------------------------+
   | Workflow tasks       | MAKE_GRID_TN, MAKE_OROG_TN, MAKE_SFC_CLIMO_TN,               |
   |                      | GET_EXTRN_ICS_TN, GET_EXTRN_LBCS_TN, MAKE_ICS_TN,            |
   |                      | MAKE_LBCS_TN, RUN_FCST_TN, RUN_POST_TN                       |
   +----------------------+--------------------------------------------------------------+
   | Verification tasks   | GET_OBS, GET_OBS_CCPA_TN, GET_OBS_MRMS_TN, GET_OBS_NDAS_TN,  |
   |                      | VX_TN, VX_GRIDSTAT_TN, VX_GRIDSTAT_REFC_TN,                  |
   |                      | VX_GRIDSTAT_RETOP_TN, VX_GRIDSTAT_##h_TN, VX_POINTSTAT_TN,   |
   |                      | VX_ENSGRID_TN, VX_ENSGRID_##h_TN, VX_ENSGRID_REFC_TN,        |
   |                      | VX_ENSGRID_RETOP_TN, VX_ENSGRID_MEAN_TN, VX_ENSGRID_PROB_TN, |
   |                      | VX_ENSGRID_MEAN_##h_TN, VX_ENSGRID_PROB_03h_TN,              |
   |                      | VX_ENSGRID_PROB_REFC_TN, VX_ENSGRID_PROB_RETOP_TN,           |
   |                      | VX_ENSPOINT_TN, VX_ENSPOINT_MEAN_TN, VX_ENSPOINT_PROB_TN     |
   +----------------------+--------------------------------------------------------------+
   | NODE                 | NNODES_MAKE_GRID, NNODES_MAKE_OROG, NNODES_MAKE_SFC_CLIMO,   |
   |                      | NNODES_GET_EXTRN_ICS, NNODES_GET_EXTRN_LBCS,                 |
   |                      | NNODES_MAKE_ICS, NNODES_MAKE_LBCS, NNODES_RUN_FCST,          |
   |                      | NNODES_RUN_POST, NNODES_GET_OBS_CCPA, NNODES_GET_OBS_MRMS,   |
   |                      | NNODES_GET_OBS_NDAS, NNODES_VX_GRIDSTAT,                     |
   |                      | NNODES_VX_POINTSTAT, NNODES_VX_ENSGRID,                      |
   |                      | NNODES_VX_ENSGRID_MEAN, NNODES_VX_ENSGRID_PROB,              |
   |                      | NNODES_VX_ENSPOINT, NNODES_VX_ENSPOINT_MEAN,                 |
   |                      | NNODES_VX_ENSPOINT_PROB                                      |
   +----------------------+--------------------------------------------------------------+
   | MPI processes        | PPN_MAKE_GRID, PPN_MAKE_OROG, PPN_MAKE_SFC_CLIMO,            |
   |                      | PPN_GET_EXTRN_ICS, PPN_GET_EXTRN_LBCS, PPN_MAKE_ICS,         |
   |                      | PPN_MAKE_LBCS, PPN_RUN_FCST, PPN_RUN_POST,                   |
   |                      | PPN_GET_OBS_CCPA, PPN_GET_OBS_MRMS, PPN_GET_OBS_NDAS,        |
   |                      | PPN_VX_GRIDSTAT, PPN_VX_POINTSTAT, PPN_VX_ENSGRID,           |
   |                      | PPN_VX_ENSGRID_MEAN, PPN_VX_ENSGRID_PROB, PPN_VX_ENSPOINT,   |
   |                      | PPN_VX_ENSPOINT_MEAN, PPN_VX_ENSPOINT_PROB                   |
   +----------------------+--------------------------------------------------------------+
   | Walltime             | WTIME_MAKE_GRID, WTIME_MAKE_OROG, WTIME_MAKE_SFC_CLIMO,      |
   |                      | WTIME_GET_EXTRN_ICS, WTIME_GET_EXTRN_LBCS, WTIME_MAKE_ICS,   |
   |                      | WTIME_MAKE_LBCS, WTIME_RUN_FCST, WTIME_RUN_POST,             |
   |                      | WTIME_GET_OBS_CCPA, WTIME_GET_OBS_MRMS, WTIME_GET_OBS_NDAS,  |
   |                      | WTIME_VX_GRIDSTAT, WTIME_VX_POINTSTAT, WTIME_VX_ENSGRID,     |
   |                      | WTIME_VX_ENSGRID_MEAN, WTIME_VX_ENSGRID_PROB,                |
   |                      | WTIME_VX_ENSPOINT, WTIME_VX_ENSPOINT_MEAN,                   |
   |                      | WTIME_VX_ENSPOINT_PROB                                       |
   +----------------------+--------------------------------------------------------------+
   | Maximum attempt      | MAXTRIES_MAKE_GRID, MAXTRIES_MAKE_OROG,                      |
   |                      | MAXTRIES_MAKE_SFC_CLIMO, MAXTRIES_GET_EXTRN_ICS,             |
   |                      | MAXTRIES_GET_EXTRN_LBCS, MAXTRIES_MAKE_ICS,                  |
   |                      | MAXTRIES_MAKE_LBCS, MAXTRIES_RUN_FCST, MAXTRIES_RUN_POST,    |
   |                      | MAXTRIES_GET_OBS_CCPA, MAXTRIES_GET_OBS_MRMS,                |
   |                      | MAXTRIES_GET_OBS_NDAS, MAXTRIES_VX_GRIDSTAT,                 |
   |                      | MAXTRIES_VX_GRIDSTAT_REFC, MAXTRIES_VX_GRIDSTAT_RETOP,       |
   |                      | MAXTRIES_VX_GRIDSTAT_##h, MAXTRIES_VX_POINTSTAT,             |
   |                      | MAXTRIES_VX_ENSGRID, MAXTRIES_VX_ENSGRID_REFC,               |
   |                      | MAXTRIES_VX_ENSGRID_RETOP, MAXTRIES_VX_ENSGRID_##h,          |
   |                      | MAXTRIES_VX_ENSGRID_MEAN, MAXTRIES_VX_ENSGRID_PROB,          |
   |                      | MAXTRIES_VX_ENSGRID_MEAN_##h, MAXTRIES_VX_ENSGRID_PROB_##h,  |
   |                      | MAXTRIES_VX_ENSGRID_PROB_REFC,                               |
   |                      | MAXTRIES_VX_ENSGRID_PROB_RETOP, MAXTRIES_VX_ENSPOINT,        |
   |                      | MAXTRIES_VX_ENSPOINT_MEAN, MAXTRIES_VX_ENSPOINT_PROB         |
   +----------------------+--------------------------------------------------------------+
   | Climatology          | SFC_CLIMO_FIELDS, USE_MERRA_CLIMO                            |
   +----------------------+--------------------------------------------------------------+
   | CRTM                 | USE_CRTM, CRTM_DIR                                           |
   +----------------------+--------------------------------------------------------------+
   | Post configuration   | USE_CUSTOM_POST_CONFIG_FILE, CUSTOM_POST_CONFIG_FP,          |
   |                      | SUB_HOURLY_POST, DT_SUB_HOURLY_POST_MNTS                     |
   +----------------------+--------------------------------------------------------------+
   | METplus              | MODEL, MET_INSTALL_DIR, MET_BIN_EXEC, METPLUS_PATH,          |
   |                      | CCPA_OBS_DIR, MRMS_OBS_DIR, NDAS_OBS_DIR                     |
   +----------------------+--------------------------------------------------------------+
   | Running ensembles    | DO_ENSEMBLE, NUM_ENS_MEMBERS                                 |
   +----------------------+--------------------------------------------------------------+
   | Boundary blending    | HALO_BLEND                                                   |
   +----------------------+--------------------------------------------------------------+
   | FVCOM                | USE_FVCOM, FVCOM_WCSTART, FVCOM_DIR, FVCOM_FILE              |
   +----------------------+--------------------------------------------------------------+
   | Thread Affinity      | KMP_AFFINITY_*, OMP_NUM_THREADS_*, OMP_STACKSIZE_*           |
   +----------------------+--------------------------------------------------------------+


.. _UserSpecificConfig:

User-specific configuration: ``config.yaml``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The user must specify certain basic information about the experiment in a ``config.yaml`` file located in the ``ufs-srweather-app/regional_workflow/ush`` directory. Two example templates are provided in that directory: ``config.community.yaml`` and ``config.nco.yaml``. The first file is a minimal example for creating and running an experiment in the *community* mode (with ``RUN_ENVIR`` set to ``community``). The second is an example for creating and running an experiment in the *NCO* (operational) mode (with ``RUN_ENVIR`` set to ``nco``). The *community* mode is recommended in most cases and is fully supported for this release. The operational/NCO mode is typically used by those at the NOAA/NCEP/Environmental Modeling Center (EMC) and the NOAA/Global Systems Laboratory (GSL) working on pre-implementation testing for the Rapid Refresh Forecast System (RRFS). :numref:`Table %s <ConfigCommunity>` shows the configuration variables that appear in the ``config.community.yaml``, along with their default values in ``config_default.yaml`` and the values defined in ``config.community.yaml``.

.. _ConfigCommunity:

.. table::   Configuration variables specified in the config.community.yaml script

   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | **Parameter**                  | **Default Value** | **config.community.yaml Value**                                                  |
   +================================+===================+==================================================================================+
   | MACHINE                        | "BIG_COMPUTER"    | "hera"                                                                           |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | ACCOUNT                        | "project_name"    | "an_account"                                                                     |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | EXPT_SUBDIR                    | ""                | "test_CONUS_25km_GFSv16"                                                         |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | COMPILER                       | "intel"           | "intel"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | VERBOSE                        | "TRUE"            | "TRUE"                                                                           |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_ENVIR                      | "nco"             | "community"                                                                      |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | PREEXISTING_DIR_METHOD         | "delete"          | "rename"                                                                         |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | PREDEF_GRID_NAME               | ""                | "RRFS_CONUS_25km"                                                                |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | DO_ENSEMBLE                    | "FALSE"           | "FALSE"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | NUM_ENS_MEMBERS                | "1"               | "2"                                                                              |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | QUILTING                       | "TRUE"            | "TRUE"                                                                           |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | CCPP_PHYS_SUITE                | "FV3_GFS_v16"     | "FV3_GFS_v16"                                                                    |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | FCST_LEN_HRS                   | "24"              | "12"                                                                             |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | LBC_SPEC_INTVL_HRS             | "6"               | "6"                                                                              |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | DATE_FIRST_CYCL                | "YYYYMMDD"        | "20190615"                                                                       |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | DATE_LAST_CYCL                 | "YYYYMMDD"        | "20190615"                                                                       |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | CYCL_HRS                       | ("HH1" "HH2")     | "18"                                                                             |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | EXTRN_MDL_NAME_ICS             | "FV3GFS"          | "FV3GFS"                                                                         |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | EXTRN_MDL_NAME_LBCS            | "FV3GFS"          | "FV3GFS"                                                                         |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | FV3GFS_FILE_FMT_ICS            | "nemsio"          | "grib2"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | FV3GFS_FILE_FMT_LBCS           | "nemsio"          | "grib2"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | WTIME_RUN_FCST                 | "04:30:00"        | "02:00:00"                                                                       |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | USE_USER_STAGED_EXTRN_FILES    | "FALSE"           | "TRUE"                                                                           |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | EXTRN_MDL_SOURCE_BASEDIR_ICS   | ""                | "/scratch2/BMC/det/UFS_SRW_App/develop/input_model_data/FV3GFS/grib2/2019061518" |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | EXTRN_MDL_FILES_ICS            | ""                | "gfs.pgrb2.0p25.f000"                                                            |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | EXTRN_MDL_SOURCE_BASEDIR_LBCS  | ""                | "/scratch2/BMC/det/UFS_SRW_App/develop/input_model_data/FV3GFS/grib2/2019061518" |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | EXTRN_MDL_FILES_LBCS           | ""                | "gfs.pgrb2.0p25.f006" "gfs.pgrb2.0p25.f012"                                      |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | MODEL                          | ""                | FV3_GFS_v16_CONUS_25km"                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | METPLUS_PATH                   | ""                | "/path/to/METPlus"                                                               |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | MET_INSTALL_DIR                | ""                | "/path/to/MET"                                                                   |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | CCPA_OBS_DIR                   | ""                | "/path/to/processed/CCPA/data"                                                   |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | MRMS_OBS_DIR                   | ""                | "/path/to/processed/MRMS/data"                                                   |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | NDAS_OBS_DIR                   | ""                | "/path/to/processed/NDAS/data"                                                   |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_MAKE_GRID             | "TRUE"            | "TRUE"                                                                           |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_MAKE_OROG             | "TRUE"            | "TRUE"                                                                           |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_MAKE_SFC_CLIMO        | "TRUE"            | "TRUE"                                                                           |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_GET_OBS_CCPA          | "FALSE"           | "FALSE"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_GET_OBS_MRMS          | "FALSE"           | "FALSE"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_GET_OBS_NDAS          | "FALSE"           | "FALSE"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_VX_GRIDSTAT           | "FALSE"           | "FALSE"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_VX_POINTSTAT          | "FALSE"           | "FALSE"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_VX_ENSGRID            | "FALSE"           | "FALSE"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+
   | RUN_TASK_VX_ENSPOINT           | "FALSE"           | "FALSE"                                                                          |
   +--------------------------------+-------------------+----------------------------------------------------------------------------------+


To get started, make a copy of ``config.community.yaml``. From the ``ufs-srweather-app`` directory, run:

.. code-block:: console

   cd $SRW/regional_workflow/ush
   cp config.community.yaml config.yaml

The default settings in this file include a predefined 25-km :term:`CONUS` grid (RRFS_CONUS_25km), the :term:`GFS` v16 physics suite (FV3_GFS_v16 :term:`CCPP`), and :term:`FV3`-based GFS raw external model data for initialization.

Next, edit the new ``config.yaml`` file to customize it for your machine. At a minimum, change the ``MACHINE`` and ``ACCOUNT`` variables; then choose a name for the experiment directory by setting ``EXPT_SUBDIR``. If you have pre-staged initialization data for the experiment, set ``USE_USER_STAGED_EXTRN_FILES="TRUE"``, and set the paths to the data for ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS``. If the modulefile used to set up the build environment in :numref:`Section %s <BuildExecutables>` uses a GNU compiler, check that the line ``COMPILER="gnu"`` appears in the ``config.yaml`` file. On platforms where Rocoto and :term:`cron` are available, users can automate resubmission of their experiment workflow by adding the following lines to the ``config.yaml`` file:

.. code-block:: console

   USE_CRON_TO_RELAUNCH="TRUE"
   CRON_RELAUNCH_INTVL_MNTS="03"

.. note::

   Generic Linux and MacOS users should refer to :numref:`Section %s <LinuxMacEnvConfig>` for additional details on configuring an experiment and python environment. 

Sample ``config.yaml`` settings are indicated below for Level 1 platforms. Detailed guidance applicable to all systems can be found in :numref:`Chapter %s: Configuring the Workflow <ConfigWorkflow>`, which discusses each variable and the options available. Additionally, information about the four predefined Limited Area Model (LAM) Grid options can be found in :numref:`Chapter %s: Limited Area Model (LAM) Grids <LAMGrids>`.

.. hint::

   To determine an appropriate ACCOUNT field for Level 1 systems, run ``groups``, and it will return a list of projects you have permissions for. Not all of the listed projects/groups have an HPC allocation, but those that do are potentially valid account names. 

Minimum parameter settings for running the out-of-the-box SRW App case on Level 1 machines:

.. _SystemData:

**Cheyenne:**

.. code-block:: console

   MACHINE="cheyenne"
   ACCOUNT="<my_account>"
   EXPT_SUBDIR="<my_expt_name>"
   USE_USER_STAGED_EXTRN_FILES="TRUE"
   EXTRN_MDL_SOURCE_BASEDIR_ICS="/glade/p/ral/jntp/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/<YYYYMMDDHH>"
   EXTRN_MDL_SOURCE_BASEDIR_LBCS="/glade/p/ral/jntp/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/<YYYYMMDDHH>"

where: 
   * ``<my_account>`` refers to a valid account name.
   * ``<my_expt_name>`` is an experiment name of the user's choice.
   * ``<model_type>`` refers to a subdirectory, such as "FV3GFS" or "HRRR", containing the experiment data. 
   * ``<data_type>`` refers to one of 3 possible data formats: ``grib2``, ``nemsio``, or ``netcdf``. 
   * ``<YYYYMMDDHH>`` refers to a subdirectory containing data for the :term:`cycle` date (in YYYYMMDDHH format). 


**Hera, Jet, Orion, Gaea:**

The ``MACHINE``, ``ACCOUNT``, and ``EXPT_SUBDIR`` settings are the same as for Cheyenne, except that ``"cheyenne"`` should be switched to ``"hera"``, ``"jet"``, ``"orion"``, or ``"gaea"``, respectively. Set ``USE_USER_STAGED_EXTRN_FILES="TRUE"``, but replace the file paths to Cheyenne's data with the file paths for the correct machine. ``EXTRN_MDL_SOURCE_BASEDIR_ICS`` and ``EXTRN_MDL_SOURCE_BASEDIR_LBCS`` use the same base file path. 

On Hera: 

.. code-block:: console

   "/scratch2/BMC/det/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/<YYYYMMDDHH>/"

On Jet: 

.. code-block:: console

   "/mnt/lfs4/BMC/wrfruc/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/<YYYYMMDDHH>/"

On Orion: 

.. code-block:: console

   "/work/noaa/fv3-cam/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/<YYYYMMDDHH>/"

On Gaea: 

.. code-block:: console

   "/lustre/f2/pdata/ncep/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/<YYYYMMDDHH>/"

On **WCOSS** systems, edit ``config.yaml`` with these WCOSS-specific parameters, and use a valid WCOSS project code for the account parameter:

.. code-block:: console

   MACHINE="wcoss2"
   ACCOUNT="valid_wcoss_project_code"
   EXPT_SUBDIR="my_expt_name"
   USE_USER_STAGED_EXTRN_FILES="TRUE"

On WCOSS2:

.. code-block:: console

   EXTRN_MDL_SOURCE_BASEDIR_ICS="/lfs/h2/emc/lam/noscrub/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/YYYYMMDDHH/ICS"
   EXTRN_MDL_SOURCE_BASEDIR_LBCS="/lfs/h2/emc/lam/noscrub/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/YYYYMMDDHH/LBCS"

On NOAA Cloud Systems:

.. code-block:: console

   MACHINE="NOAACLOUD"
   ACCOUNT="none"
   EXPT_SUBDIR="<my_expt_name>"
   USE_USER_STAGED_EXTRN_FILES="TRUE"
   EXTRN_MDL_SOURCE_BASEDIR_ICS="/contrib/EPIC/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/<YYYYMMDDHH>/"
   EXTRN_MDL_FILES_ICS=( "gfs.t18z.pgrb2.0p25.f000" )
   EXTRN_MDL_SOURCE_BASEDIR_LBCS="/contrib/EPIC/UFS_SRW_App/develop/input_model_data/<model_type>/<data_type>/<YYYYMMDDHH>/"
   EXTRN_MDL_FILES_LBCS=( "gfs.t18z.pgrb2.0p25.f006" "gfs.t18z.pgrb2.0p25.f012" )

.. note::

   The values of the configuration variables should be consistent with those in the
   ``valid_param_vals.yaml`` script. In addition, various sample configuration files can be found in the ``regional_workflow/tests/baseline_configs`` directory.


To configure an experiment and python environment for a general Linux or Mac system, see the :ref:`next section <LinuxMacEnvConfig>`. To configure an experiment to run METplus verification tasks, see :numref:`Section %s <VXConfig>`. Otherwise, skip to :numref:`Section %s <GenerateWorkflow>`.

.. _LinuxMacEnvConfig:

User-specific Configuration on a General Linux/MacOS System
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The configuration process for Linux and MacOS systems is similar to the process for other systems, but it requires a few extra steps.

.. note::
    Examples in this subsection presume that the user is running Terminal.app with a bash shell environment. If this is not the case, users will need to adjust the commands to fit their command line application and shell environment. 

.. _MacMorePackages:

Install/Upgrade Mac-Specific Packages
````````````````````````````````````````
MacOS requires the installation of a few additional packages and, possibly, an upgrade to bash. Users running on MacOS should execute the following commands:

.. code-block:: console

   bash --version
   brew upgrade bash
   brew install coreutils
   brew gsed

.. _LinuxMacVEnv: 

Creating a Virtual Environment on Linux and Mac
``````````````````````````````````````````````````

Users should ensure that the following packages are installed and up-to-date:

.. code-block:: console

   python3 -m pip --version 
   python3 -m pip install --upgrade pip 
   python3 -m ensurepip --default-pip
   python3 -m pip install ruby             OR(on MacOS only): brew install ruby

Users must create a virtual environment (``regional_workflow``), store it in their ``$HOME/venv/`` directory, and install additional python packages:

.. code-block:: console

   [[ -d $HOME/venv ]] | mkdir -p $HOME/venv
   python3 -m venv $HOME/venv/regional_workflow 
   source $HOME/venv/regional_workflow/bin/activate
   python3 -m pip install jinja2
   python3 -m pip install pyyaml
   python3 -m pip install f90nml

The virtual environment can be deactivated by running the ``deactivate`` command. The virtual environment built here will be reactivated in :numref:`Step %s <LinuxMacActivateWFenv>` and needs to be used to generate the workflow and run the experiment. 

.. _LinuxMacExptConfig:

Configuring an Experiment on General Linux and MacOS Systems
``````````````````````````````````````````````````````````````

**Optional: Install Rocoto**

.. note::
   Users may `install Rocoto <https://github.com/christopherwharrop/rocoto/blob/develop/INSTALL>`__ if they want to make use of a workflow manager to run their experiments. However, this option has not been tested yet on MacOS and has had limited testing on general Linux plaforms. 


**Configure the SRW App:**

Configure an experiment using a template. Copy the contents of ``config.community.yaml`` into ``config.yaml``: 

.. code-block:: console

   cd $SRW/regional_workflow/ush
   cp config.community.yaml config.yaml

In the ``config.yaml`` file, set ``MACHINE="macos"`` or ``MACHINE="linux"``, and modify the account and experiment info. For example: 

.. code-block:: console

   MACHINE="macos"
   ACCOUNT="user" 
   EXPT_SUBDIR="<test_community>"
   COMPILER="gnu"
   VERBOSE="TRUE"
   RUN_ENVIR="community"
   PREEXISTING_DIR_METHOD="rename"

   PREDEF_GRID_NAME="RRFS_CONUS_25km"	
   QUILTING="TRUE"

Due to the limited number of processors on MacOS systems, users must also configure the domain decomposition defaults (usually, there are only 8 CPUs in M1-family chips and 4 CPUs for x86_64). 

For :ref:`Option 1 <MacDetails>`, add the following information to ``config.yaml``:

.. code-block:: console

   LAYOUT_X="${LAYOUT_X:-3}"
   LAYOUT_Y="${LAYOUT_Y:-2}"
   WRTCMP_write_groups="1"
   WRTCMP_write_tasks_per_group="2"

For :ref:`Option 2 <MacDetails>`, add the following information to ``config.yaml``:

.. code-block:: console

   LAYOUT_X="${LAYOUT_X:-3}"
   LAYOUT_Y="${LAYOUT_Y:-1}"
   WRTCMP_write_groups="1"
   WRTCMP_write_tasks_per_group="1"

.. note::
   The number of MPI processes required by the forecast will be equal to ``LAYOUT_X`` * ``LAYOUT_Y`` + ``WRTCMP_write_tasks_per_group``. 

**Configure the Machine File**

Configure a ``macos.yaml`` or ``linux.yaml`` machine file in ``$SRW/regional_workflow/ush/machine/`` based on the number of CPUs (``<ncores>``) in the system (usually 8 or 4 in MacOS; varies on Linux systems). Job scheduler (``SCHED``) options can be viewed :ref:`here <sched>`. Users must also set the path to the fix file directories. 

.. code-block:: console

   # Commands to run at the start of each workflow task.
   PRE_TASK_CMDS='{ ulimit -a; }'

   # Architecture information
   WORKFLOW_MANAGER="none"
   NCORES_PER_NODE=${NCORES_PER_NODE:-<ncores>}	 
   SCHED=${SCHED:-"<sched>"}
   
   # UFS SRW App specific paths
   FIXgsm="path/to/FIXgsm/files"
   FIXaer="path/to/FIXaer/files"
   FIXlut="path/to/FIXlut/files"
   TOPO_DIR="path/to/FIXgsm/files" # (path to location of static input files used by the 
                                     make_orog task) 
   SFC_CLIMO_INPUT_DIR="path/to/FIXgsm/files" # (path to location of static surface climatology
                                                input fields used by sfc_climo_gen)

   # Run commands for executables
   RUN_CMD_SERIAL="time"
   RUN_CMD_UTILS="mpirun -np 4"
   RUN_CMD_FCST='mpirun -np ${PE_MEMBER01}'
   RUN_CMD_POST="mpirun -np 4"


.. _VXConfig:

Configure METplus Verification Suite (Optional)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Users who want to use the METplus verification suite to evaluate their forecasts need to add additional information to their ``config.yaml`` file. Other users may skip to the :ref:`next section <SetUpPythonEnv>`. 

.. attention::
   METplus *installation* is not included as part of the build process for this release of the SRW App. However, METplus is preinstalled on many `Level 1 & 2 <https://dtcenter.org/community-code/metplus/metplus-4-1-existing-builds>`__ systems. For the v2.0.0 release, METplus *use* is supported on systems with a functioning METplus installation, although installation itself is not supported. For more information about METplus, see :numref:`Section %s <MetplusComponent>`.

.. note::
   If METplus users update their METplus installation, they must update the module load statements in ``ufs-srweather-app/regional_workflow/modulefiles/tasks/<machine>/run_vx.local`` file to correspond to their system's updated installation:

   .. code-block:: console
      
      module use -a </path/to/met/modulefiles/>
      module load met/<version.X.X>

To use METplus verification, the path to the MET and METplus directories must be added to ``config.yaml``:

.. code-block:: console

   METPLUS_PATH="</path/to/METplus/METplus-4.1.0>"
   MET_INSTALL_DIR="</path/to/met/10.1.0>"

Users who have already staged the observation data needed for METplus (i.e., the :term:`CCPA`, :term:`MRMS`, and :term:`NDAS` data) on their system should set the path to this data and set the corresponding ``RUN_TASK_GET_OBS_*`` parameters to "FALSE" in ``config.yaml``. 

.. code-block:: console

   CCPA_OBS_DIR="/path/to/UFS_SRW_App/develop/obs_data/ccpa/proc"
   MRMS_OBS_DIR="/path/to/UFS_SRW_App/develop/obs_data/mrms/proc"
   NDAS_OBS_DIR="/path/to/UFS_SRW_App/develop/obs_data/ndas/proc"
   RUN_TASK_GET_OBS_CCPA="FALSE"
   RUN_TASK_GET_OBS_MRMS="FALSE"
   RUN_TASK_GET_OBS_NDAS="FALSE"

If users have access to NOAA :term:`HPSS` but have not pre-staged the data, they can simply set the ``RUN_TASK_GET_OBS_*`` tasks to "TRUE", and the machine will attempt to download the appropriate data from NOAA HPSS. The ``*_OBS_DIR`` paths must be set to the location where users want the downloaded data to reside. 

Users who do not have access to NOAA HPSS and do not have the data on their system will need to download :term:`CCPA`, :term:`MRMS`, and :term:`NDAS` data manually from collections of publicly available data, such as the ones listed `here <https://dtcenter.org/nwp-containers-online-tutorial/publicly-available-data-sets>`__. 

Next, the verification tasks must be turned on according to the user's needs. Users should add some or all of the following tasks to ``config.yaml``, depending on the verification procedure(s) they have in mind:

.. code-block:: console

   RUN_TASK_VX_GRIDSTAT="TRUE"
   RUN_TASK_VX_POINTSTAT="TRUE"
   RUN_TASK_VX_ENSGRID="TRUE"
   RUN_TASK_VX_ENSPOINT="TRUE"

These tasks are independent, so users may set some values to "TRUE" and others to "FALSE" depending on the needs of their experiment. Note that the ENSGRID and ENSPOINT tasks apply only to ensemble model verification. Additional verification tasks appear in :numref:`Table %s <VXWorkflowTasksTable>`. More details on all of the parameters in this section are available in :numref:`Section %s <VXTasks>`. 

.. _SetUpPythonEnv:

Set Up the Python and Other Environment Parameters
----------------------------------------------------

The workflow requires Python 3 with the packages ``PyYAML``, ``Jinja2``, and ``f90nml`` available. This Python environment has already been set up on Level 1 platforms, and it can be activated in the following way:

.. code-block:: console

   module use <path/to/modulefiles>
   module load wflow_<platform>

The ``wflow_<platform>`` modulefile will then output instructions to activate the regional workflow. The user should run the commands specified in the modulefile output. For example, if the output says: 

.. code-block:: console

   Please do the following to activate conda:
       > conda activate regional_workflow

then the user should run ``conda activate regional_workflow``. This will activate the ``regional_workflow`` conda environment. However, the command(s) will vary from system to system. Regardless, the user should see ``(regional_workflow)`` in front of the Terminal prompt at this point. If this is not the case, activate the regional workflow from the ``ush`` directory by running: 

.. code-block:: console

   conda init
   source ~/.bashrc
   conda activate regional_workflow

.. _LinuxMacActivateWFenv:

Activating the Workflow Environment on Non-Level 1 Systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Users on non-Level 1 systems can copy one of the provided ``wflow_<platform>`` files and use it as a template to create a ``wflow_<platform>`` file that works for their system. ``wflow_macos`` and ``wflow_linux`` template files are provided with the release. After making appropriate modifications to a ``wflow_<platform>`` file, users can run the commands from :numref:`Step %s <SetUpPythonEnv>` above to activate the regional workflow. 

On generic Linux or MacOS systems, loading the designated ``wflow_<platform>`` file will output instructions similar to the following:

.. code-block:: console

   Please do the following to activate conda:
       > source $VENV/bin/activate

If that does not work, users can also try:  

.. code-block:: console

   source $HOME/venv/regional_workflow/bin/activate

However, it may instead be necessary to make additional adjustments to the ``wflow_<platform>`` file. 

.. _GenerateWorkflow: 

Generate the Regional Workflow
-------------------------------------------

Run the following command from the ``ufs-srweather-app/regional_workflow/ush`` directory to generate the workflow:

.. code-block:: console

   ./generate_FV3LAM_wflow.py

The last line of output from this script, starting with ``*/1 * * * *`` or ``*/3 * * * *``, can be saved and :ref:`used later <Automate>` to automatically run portions of the workflow if users have the Rocoto workflow manager installed on their system. 

This workflow generation script creates an experiment directory and populates it with all the data needed to run through the workflow. The flowchart in :numref:`Figure %s <WorkflowGeneration>` describes the experiment generation process. First, ``generate_FV3LAM_wflow.py`` runs the ``setup.py`` script to set the configuration parameters. Second, it copies the time-independent (fix) files and other necessary data input files from their location in the ufs-weather-model directory to the experiment directory (``$EXPTDIR``). Third, it copies the weather model executable (``ufs_model``) from the ``bin`` directory to ``$EXPTDIR`` and creates the input namelist file ``input.nml`` based on the ``input.nml.FV3`` file in the regional_workflow/ush/templates directory. Lastly, it creates the workflow XML file ``FV3LAM_wflow.xml`` that is executed when running the experiment with the Rocoto workflow manager.

The ``setup.py`` script reads three other configuration scripts in order: (1) ``config_default.yaml`` (:numref:`Section %s <DefaultConfigSection>`), (2) ``config.yaml`` (:numref:`Section %s <UserSpecificConfig>`), and (3) ``set_predef_grid_params.py``. If a parameter is specified differently in these scripts, the file containing the last defined value will be used.

The generated workflow will appear in ``$EXPTDIR``, where ``EXPTDIR=${EXPT_BASEDIR}/${EXPT_SUBDIR}``. These variables were specified in the ``config.yaml`` file in :numref:`Step %s <UserSpecificConfig>`. The settings for these paths can also be viewed in the console output from the ``./generate_FV3LAM_wflow.py`` script or in the ``log.generate_FV3LAM_wflow`` file, which can be found in ``$EXPTDIR``. 

.. _WorkflowGeneration:

.. figure:: _static/FV3regional_workflow_gen_v2.png
   :alt: Flowchart of the workflow generation process. Scripts are called in the following order: source_util_funcs.sh (which calls bash_utils), then set_FV3nml_sfc_climo_filenames.sh, set_FV3nml_stock_params.sh, create_diag_table_files.sh, and setup.py. setup.py calls several scripts: set_cycle_dates.sh, set_grid_params_GFDLgrid.sh, set_grid_params_ESGgrid.sh, link_fix.sh, set_ozone_param.sh, set_Thompson_mp_fix_files.sh, config_defaults.sh, config.sh, and valid_param_vals.sh. Then, it sets a number of variables, including FIXgsm, TOPO_DIR, and SFC_CLIMO_INPUT_DIR variables. Next, set_predef_grid_params.sh is called, and the FIXam and FIXLAM directories are set, along with the forecast input files. The setup script also calls set_extrn_mdl_params.sh, sets the GRID_GEN_METHOD with HALO, checks various parameters, and generates shell scripts. Then, the workflow generation script sets up YAML-compliant strings and generates the actual Rocoto workflow XML file from the template file (fill_jinja_template.py). The workflow generation script checks the crontab file and, if applicable, copies certain fix files to the experiment directory. Then, it copies templates of various input files to the experiment directory and sets parameters for the input.nml file. Finally, it generates the workflow. Additional information on each step appears in comments within each script. 

   *Experiment generation description*

.. COMMENT: Get updates image/slides from Chan-Hoo!

.. _WorkflowTaskDescription: 

Description of Workflow Tasks
--------------------------------

.. note::
   This section gives a general overview of workflow tasks. To begin running the workflow, skip to :numref:`Step %s <Run>`

:numref:`Figure %s <WorkflowTasksFig>` illustrates the overall workflow. Individual tasks that make up the workflow are specified in the ``FV3LAM_wflow.xml`` file. :numref:`Table %s <WorkflowTasksTable>` describes the function of each baseline task. The first three pre-processing tasks; ``MAKE_GRID``, ``MAKE_OROG``, and ``MAKE_SFC_CLIMO`` are optional. If the user stages pre-generated grid, orography, and surface climatology fix files, these three tasks can be skipped by adding the following lines to the ``config.yaml`` file before running the ``generate_FV3LAM_wflow.py`` script: 

.. code-block:: console

   RUN_TASK_MAKE_GRID="FALSE"
   RUN_TASK_MAKE_OROG="FALSE"
   RUN_TASK_MAKE_SFC_CLIMO="FALSE"


.. _WorkflowTasksFig:

.. figure:: _static/FV3LAM_wflow_flowchart_v2.png
   :alt: Flowchart of the workflow tasks. If the make_grid, make_orog, and make_sfc_climo tasks are toggled off, they will not be run. If toggled on, make_grid, make_orog, and make_sfc_climo will run consecutively by calling the corresponding exregional script in the regional_workflow/scripts directory. The get_ics, get_lbcs, make_ics, make_lbcs, and run_fcst tasks call their respective exregional scripts. The run_post task will run, and if METplus verification tasks have been configured, those will run during post-processing by calling their exregional scripts. 

   *Flowchart of the workflow tasks*


The ``FV3LAM_wflow.xml`` file runs the specific j-job scripts (``regional_workflow/jobs/JREGIONAL_[task name]``) in the prescribed order when the experiment is launched via the ``launch_FV3LAM_wflow.sh`` script or the ``rocotorun`` command. Each j-job task has its own source script (or "ex-script") named ``exregional_[task name].sh`` in the ``regional_workflow/scripts`` directory. Two database files named ``FV3LAM_wflow.db`` and ``FV3LAM_wflow_lock.db`` are generated and updated by the Rocoto calls. There is usually no need for users to modify these files. To relaunch the workflow from scratch, delete these two ``*.db`` files and then call the launch script repeatedly for each task. 


.. _WorkflowTasksTable:

.. table::  Baseline workflow tasks in the SRW App

   +----------------------+------------------------------------------------------------+
   | **Workflow Task**    | **Task Description**                                       |
   +======================+============================================================+
   | make_grid            | Pre-processing task to generate regional grid files. Only  |
   |                      | needs to be run once per experiment.                       |
   +----------------------+------------------------------------------------------------+
   | make_orog            | Pre-processing task to generate orography files. Only      |
   |                      | needs to be run once per experiment.                       |
   +----------------------+------------------------------------------------------------+
   | make_sfc_climo       | Pre-processing task to generate surface climatology files. |
   |                      | Only needs to be run, at most, once per experiment.        |
   +----------------------+------------------------------------------------------------+
   | get_extrn_ics        | Cycle-specific task to obtain external data for the        |
   |                      | initial conditions                                         |
   +----------------------+------------------------------------------------------------+
   | get_extrn_lbcs       | Cycle-specific task to obtain external data for the        |
   |                      | lateral boundary conditions (LBCs)                         |
   +----------------------+------------------------------------------------------------+
   | make_ics             | Generate initial conditions from the external data         |
   +----------------------+------------------------------------------------------------+
   | make_lbcs            | Generate LBCs from the external data                       |
   +----------------------+------------------------------------------------------------+
   | run_fcst             | Run the forecast model (UFS weather model)                 |
   +----------------------+------------------------------------------------------------+
   | run_post             | Run the post-processing tool (UPP)                         |
   +----------------------+------------------------------------------------------------+

In addition to the baseline tasks described in :numref:`Table %s <WorkflowTasksTable>` above, users may choose to run some or all of the METplus verification tasks. These tasks are described in :numref:`Table %s <VXWorkflowTasksTable>` below. 

.. _VXWorkflowTasksTable:

.. table:: Verification (VX) workflow tasks in the SRW App

   +-----------------------+------------------------------------------------------------+
   | **Workflow Task**     | **Task Description**                                       |
   +=======================+============================================================+
   | GET_OBS_CCPA          | Retrieves and organizes hourly :term:`CCPA` data from NOAA |
   |                       | HPSS. Can only be run if ``RUN_TASK_GET_OBS_CCPA="TRUE"``  |
   |                       | *and* user has access to NOAA :term:`HPSS` data.           |
   +-----------------------+------------------------------------------------------------+
   | GET_OBS_NDAS          | Retrieves and organizes hourly :term:`NDAS` data from NOAA |
   |                       | HPSS. Can only be run if ``RUN_TASK_GET_OBS_NDAS="TRUE"``  |
   |                       | *and* user has access to NOAA HPSS data.                   |
   +-----------------------+------------------------------------------------------------+
   | GET_OBS_MRMS          | Retrieves and organizes hourly :term:`MRMS` composite      |
   |                       | reflectivity and :term:`echo top` data from NOAA HPSS. Can |
   |                       | only be run if ``RUN_TASK_GET_OBS_MRMS="TRUE"`` *and* user |
   |                       | has access to NOAA HPSS data.                              |
   +-----------------------+------------------------------------------------------------+
   | VX_GRIDSTAT           | Runs METplus grid-to-grid verification for 1-h accumulated |
   |                       | precipitation                                              |
   +-----------------------+------------------------------------------------------------+
   | VX_GRIDSTAT_REFC      | Runs METplus grid-to-grid verification for composite       |
   |                       | reflectivity                                               |
   +-----------------------+------------------------------------------------------------+
   | VX_GRIDSTAT_RETOP     | Runs METplus grid-to-grid verification for :term:`echo top`|
   +-----------------------+------------------------------------------------------------+
   | VX_GRIDSTAT_##h       | Runs METplus grid-to-grid verification for 3-h, 6-h, and   |
   |                       | 24-h (i.e., daily) accumulated precipitation. Valid values |
   |                       | for ``##`` are ``03``, ``06``, and ``24``.                 |
   +-----------------------+------------------------------------------------------------+
   | VX_POINTSTAT          | Runs METplus grid-to-point verification for surface and    |
   |                       | upper-air variables                                        |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID            | Runs METplus grid-to-grid ensemble verification for 1-h    |
   |                       | accumulated precipitation. Can only be run if              |
   |                       | ``DO_ENSEMBLE="TRUE"`` and ``RUN_TASK_VX_ENSGRID="TRUE"``. |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_REFC       | Runs METplus grid-to-grid ensemble verification for        |
   |                       | composite reflectivity. Can only be run if                 |
   |                       | ``DO_ENSEMBLE="TRUE"`` and                                 |
   |                       | ``RUN_TASK_VX_ENSGRID="TRUE"``.                            |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_RETOP      | Runs METplus grid-to-grid ensemble verification for        |
   |                       | :term:`echo top`. Can only be run if ``DO_ENSEMBLE="TRUE"``|
   |                       | and ``RUN_TASK_VX_ENSGRID="TRUE"``.                        |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_##h        | Runs METplus grid-to-grid ensemble verification for 3-h,   |
   |                       | 6-h, and 24-h (i.e., daily) accumulated precipitation.     |
   |                       | Valid values for ``##`` are ``03``, ``06``, and ``24``.    |
   |                       | Can only be run if ``DO_ENSEMBLE="TRUE"`` and              |
   |                       | ``RUN_TASK_VX_ENSGRID="TRUE"``.                            |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_MEAN       | Runs METplus grid-to-grid verification for ensemble mean   |
   |                       | 1-h accumulated precipitation. Can only be run if          |
   |                       | ``DO_ENSEMBLE="TRUE"`` and ``RUN_TASK_VX_ENSGRID="TRUE"``. |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_PROB       | Runs METplus grid-to-grid verification for 1-h accumulated |
   |                       | precipitation probabilistic output. Can only be run if     |
   |                       | ``DO_ENSEMBLE="TRUE"`` and ``RUN_TASK_VX_ENSGRID="TRUE"``. |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_MEAN_##h   | Runs METplus grid-to-grid verification for ensemble mean   |
   |                       | 3-h, 6-h, and 24h (i.e., daily) accumulated precipitation. |
   |                       | Valid values for ``##`` are ``03``, ``06``, and ``24``.    |
   |                       | Can only be run if ``DO_ENSEMBLE="TRUE"`` and              |
   |                       | ``RUN_TASK_VX_ENSGRID="TRUE"``.                            |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_PROB_##h   | Runs METplus grid-to-grid verification for 3-h, 6-h, and   |
   |                       | 24h (i.e., daily) accumulated precipitation probabilistic  |
   |                       | output. Valid values for ``##`` are ``03``, ``06``, and    |
   |                       | ``24``. Can only be run if ``DO_ENSEMBLE="TRUE"`` and      |
   |                       | ``RUN_TASK_VX_ENSGRID="TRUE"``.                            |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_PROB_REFC  | Runs METplus grid-to-grid verification for ensemble        |
   |                       | probabilities for composite reflectivity. Can only be run  |
   |                       | if ``DO_ENSEMBLE="TRUE"`` and                              |
   |                       | ``RUN_TASK_VX_ENSGRID="TRUE"``.                            |
   +-----------------------+------------------------------------------------------------+
   | VX_ENSGRID_PROB_RETOP | Runs METplus grid-to-grid verification for ensemble        |
   |                       | probabilities for :term:`echo top`. Can only be run if     |
   |                       | ``DO_ENSEMBLE="TRUE"`` and ``RUN_TASK_VX_ENSGRID="TRUE"``. | 
   +-----------------------+------------------------------------------------------------+
   | VX_ENSPOINT           | Runs METplus grid-to-point ensemble verification for       |
   |                       | surface and upper-air variables. Can only be run if        |
   |                       | ``DO_ENSEMBLE="TRUE"`` and ``RUN_TASK_VX_ENSPOINT="TRUE"``.|
   +-----------------------+------------------------------------------------------------+
   | VX_ENSPOINT_MEAN      | Runs METplus grid-to-point verification for ensemble mean  |
   |                       | surface and upper-air variables. Can only be run if        |
   |                       | ``DO_ENSEMBLE="TRUE"`` and ``RUN_TASK_VX_ENSPOINT="TRUE"``.|
   +-----------------------+------------------------------------------------------------+
   | VX_ENSPOINT_PROB      | Runs METplus grid-to-point verification for ensemble       |
   |                       | probabilities for surface and upper-air variables. Can     |
   |                       | only be run if ``DO_ENSEMBLE="TRUE"`` and                  |
   |                       | ``RUN_TASK_VX_ENSPOINT="TRUE"``.                           |
   +-----------------------+------------------------------------------------------------+


.. _Run:

Run the Workflow 
=======================

The workflow can be run using the Rocoto workflow manager (see :numref:`Section %s <UseRocoto>`) or using standalone wrapper scripts (see :numref:`Section %s <RunUsingStandaloneScripts>`). 

.. attention::

   If users are running the SRW App on a system that does not have Rocoto installed (e.g., `Level 3 & 4 <https://github.com/ufs-community/ufs-srweather-app/wiki/Supported-Platforms-and-Compilers>`__ systems, such as MacOS or generic Linux systems), they should follow the process outlined in :numref:`Section %s <RunUsingStandaloneScripts>` instead of the instructions in this section.


.. _UseRocoto:

Run the Workflow Using Rocoto
--------------------------------

The information in this section assumes that Rocoto is available on the desired platform. All official HPC platforms for the UFS SRW App release make use of the Rocoto workflow management software for running experiments. However, Rocoto cannot be used when running the workflow within a container. If Rocoto is not available, it is still possible to run the workflow using stand-alone scripts according to the process outlined in :numref:`Section %s <RunUsingStandaloneScripts>`. 

There are two main ways to run the workflow with Rocoto: (1) with the ``launch_FV3LAM_wflow.sh`` script, and (2) by manually calling the ``rocotorun`` command. Users can also automate the workflow using a crontab. 

.. note::
   Users may find it helpful to review :numref:`Chapter %s <RocotoInfo>` to gain a better understanding of Rocoto commands and workflow management before continuing, but this is not required to run the experiment. 

Optionally, an environment variable can be set to navigate to the ``$EXPTDIR`` more easily. If the login shell is bash, it can be set as follows:

.. code-block:: console

   export EXPTDIR=/<path-to-experiment>/<directory_name>

If the login shell is csh/tcsh, it can be set using:

.. code-block:: console

   setenv EXPTDIR /<path-to-experiment>/<directory_name>


.. _Automate:

Automated Option
^^^^^^^^^^^^^^^^^^^

The simplest way to run the Rocoto workflow is to automate the process using a job scheduler such as :term:`Cron`. For automatic resubmission of the workflow at regular intervals (e.g., every minute), the user can add the following commands to their ``config.yaml`` file *before* generating the experiment:

.. code-block:: console

   USE_CRON_TO_RELAUNCH="TRUE"
   CRON_RELAUNCH_INTVL_MNTS="02"

This will automatically add an appropriate entry to the user's :term:`cron table` and launch the workflow. Alternatively, the user can add a crontab entry using the ``crontab -e`` command. As mentioned in :numref:`Section %s <GenerateWorkflow>`, the last line of output from ``./generate_FV3LAM_wflow.py`` (starting with ``*/1 * * * *`` or ``*/3 * * * *``), can be pasted into the crontab file. It can also be found in the ``$EXPTDIR/log.generate_FV3LAM_wflow`` file. The crontab entry should resemble the following: 

.. code-block:: console

   */3 * * * * cd <path/to/experiment/subdirectory> && ./launch_FV3LAM_wflow.sh called_from_cron="TRUE"

where ``<path/to/experiment/subdirectory>`` is changed to correspond to the user's ``$EXPTDIR``. The number ``3`` can be changed to a different positive integer and simply means that the workflow will be resubmitted every three minutes.

.. hint::

   * On NOAA Cloud instances, ``*/1 * * * *`` is the preferred option for cron jobs because compute nodes will shut down if they remain idle too long. If the compute node shuts down, it can take 15-20 minutes to start up a new one. 
   * On other NOAA HPC systems, admins discourage the ``*/1 * * * *`` due to load problems. ``*/3 * * * *`` is the preferred option for cron jobs on non-NOAA Cloud systems. 

To check the experiment progress:

.. code-block:: console
   
   cd $EXPTDIR
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10



After finishing the experiment, open the crontab using ``crontab -e`` and delete the crontab entry. 

.. note::

   On Orion, *cron* is only available on the orion-login-1 node, so users will need to work on that node when running *cron* jobs on Orion.

.. _Success:

The workflow run is complete when all tasks have "SUCCEEDED". If everything goes smoothly, users will eventually see a workflow status table similar to the following: 

.. code-block:: console

   CYCLE              TASK                   JOBID         STATE        EXIT STATUS   TRIES   DURATION
   ==========================================================================================================
   201906150000       make_grid              4953154       SUCCEEDED         0          1          5.0
   201906150000       make_orog              4953176       SUCCEEDED         0          1         26.0
   201906150000       make_sfc_climo         4953179       SUCCEEDED         0          1         33.0
   201906150000       get_extrn_ics          4953155       SUCCEEDED         0          1          2.0
   201906150000       get_extrn_lbcs         4953156       SUCCEEDED         0          1          2.0
   201906150000       make_ics               4953184       SUCCEEDED         0          1         16.0
   201906150000       make_lbcs              4953185       SUCCEEDED         0          1         71.0
   201906150000       run_fcst               4953196       SUCCEEDED         0          1       1035.0
   201906150000       run_post_f000          4953244       SUCCEEDED         0          1          5.0
   201906150000       run_post_f001          4953245       SUCCEEDED         0          1          4.0
   ...
   201906150000       run_post_f012          4953381       SUCCEEDED         0          1          7.0

If users choose to run METplus verification tasks as part of their experiment, the output above will include additional lines after ``run_post_f012``. The output will resemble the following but may be significantly longer when using ensemble verification: 

.. code-block:: console

   CYCLE              TASK                   JOBID          STATE       EXIT STATUS   TRIES   DURATION
   ==========================================================================================================
   201906150000       make_grid              30466134       SUCCEEDED        0          1          5.0
   ...
   201906150000       run_post_f012          30468271       SUCCEEDED        0          1          7.0
   201906150000       run_gridstatvx         30468420       SUCCEEDED        0          1         53.0
   201906150000       run_gridstatvx_refc    30468421       SUCCEEDED        0          1        934.0
   201906150000       run_gridstatvx_retop   30468422       SUCCEEDED        0          1       1002.0
   201906150000       run_gridstatvx_03h     30468491       SUCCEEDED        0          1         43.0
   201906150000       run_gridstatvx_06h     30468492       SUCCEEDED        0          1         29.0
   201906150000       run_gridstatvx_24h     30468493       SUCCEEDED        0          1         20.0
   201906150000       run_pointstatvx        30468423       SUCCEEDED        0          1        670.0


Launch the Rocoto Workflow Using a Script
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Users who prefer not to automate their experiments can run the Rocoto workflow using the ``launch_FV3LAM_wflow.sh`` script provided. Simply call it without any arguments from the experiment directory: 

.. code-block:: console

   cd $EXPTDIR
   ./launch_FV3LAM_wflow.sh

This script creates a log file named ``log.launch_FV3LAM_wflow`` in ``$EXPTDIR`` or appends information to the file if it already exists. The launch script also creates the ``log/FV3LAM_wflow.log`` file, which shows Rocoto task information. Check the end of the log file periodically to see how the experiment is progressing:

.. code-block:: console

   tail -n 40 log.launch_FV3LAM_wflow

In order to launch additional tasks in the workflow, call the launch script again; this action will need to be repeated until all tasks in the workflow have been launched. To (re)launch the workflow and check its progress on a single line, run: 

.. code-block:: console

   ./launch_FV3LAM_wflow.sh; tail -n 40 log.launch_FV3LAM_wflow

This will output the last 40 lines of the log file, which list the status of the workflow tasks (e.g., SUCCEEDED, DEAD, RUNNING, SUBMITTING, QUEUED). The number 40 can be changed according to the user's preferences. The output will look like this: 

.. code-block:: console

   CYCLE                    TASK                       JOBID        STATE   EXIT STATUS   TRIES  DURATION
   ======================================================================================================
   202006170000        make_grid         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000        make_orog                           -            -             -       -         -
   202006170000   make_sfc_climo                           -            -             -       -         -
   202006170000    get_extrn_ics         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000   get_extrn_lbcs         druby://hfe01:33728   SUBMITTING             -       0       0.0
   202006170000         make_ics                           -            -             -       -         -
   202006170000        make_lbcs                           -            -             -       -         -
   202006170000         run_fcst                           -            -             -       -         -
   202006170000      run_post_00                           -            -             -       -         -
   202006170000      run_post_01                           -            -             -       -         -
   202006170000      run_post_02                           -            -             -       -         -
   202006170000      run_post_03                           -            -             -       -         -
   202006170000      run_post_04                           -            -             -       -         -
   202006170000      run_post_05                           -            -             -       -         -
   202006170000      run_post_06                           -            -             -       -         -

   Summary of workflow status:
   ~~~~~~~~~~~~~~~~~~~~~~~~~~

     0 out of 1 cycles completed.
     Workflow status:  IN PROGRESS

If all the tasks complete successfully, the "Workflow status" at the bottom of the log file will change from "IN PROGRESS" to "SUCCESS". If certain tasks could not complete, the "Workflow status" will instead change to "FAILURE". Error messages for each specific task can be found in the task log files located in ``$EXPTDIR/log``. 

The workflow run is complete when all tasks have "SUCCEEDED", and the ``rocotostat`` command outputs a table similar to the one :ref:`above <Success>`.


.. _RocotoManualRun:

Launch the Rocoto Workflow Manually
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Load Rocoto**

Instead of running the ``./launch_FV3LAM_wflow.sh`` script, users can load Rocoto and any other required modules. This gives the user more control over the process and allows them to view experiment progress more easily. On Level 1 systems, the Rocoto modules are loaded automatically in :numref:`Step %s <SetUpPythonEnv>`. For most other systems, a variant on the following commands will be necessary to load the Rocoto module:

.. code-block:: console

   module use <path_to_rocoto_package>
   module load rocoto

Some systems may require a version number (e.g., ``module load rocoto/1.3.3``)

**Run the Rocoto Workflow**

After loading Rocoto, call ``rocotorun`` from the experiment directory to launch the workflow tasks. This will start any tasks that do not have a dependency. As the workflow progresses through its stages, ``rocotostat`` will show the state of each task and allow users to monitor progress: 

.. code-block:: console

   cd $EXPTDIR
   rocotorun -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10
   rocotostat -w FV3LAM_wflow.xml -d FV3LAM_wflow.db -v 10

The ``rocotorun`` and ``rocotostat`` commands above will need to be resubmitted regularly and repeatedly until the experiment is finished. In part, this is to avoid having the system time out. This also ensures that when one task ends, tasks dependent on it will run as soon as possible, and ``rocotostat`` will capture the new progress. 

If the experiment fails, the ``rocotostat`` command will indicate which task failed. Users can look at the log file in the ``log`` subdirectory for the failed task to determine what caused the failure. For example, if the ``make_grid`` task failed, users can open the ``make_grid.log`` file to see what caused the problem: 

.. code-block:: console

   cd $EXPTDIR/log
   vi make_grid.log

.. note::
   
   If users have the `Slurm workload manager <https://slurm.schedmd.com/documentation.html>`__ on their system, they can run the ``squeue`` command in lieu of ``rocotostat`` to check what jobs are currently running. 


.. _RunUsingStandaloneScripts:

Run the Workflow Using Stand-Alone Scripts
---------------------------------------------

.. note:: 
   The Rocoto workflow manager cannot be used inside a container. 

The regional workflow can be run using standalone shell scripts in cases where the Rocoto software is not available on a given platform. If Rocoto *is* available, see :numref:`Section %s <Run>` to run the workflow using Rocoto. 

#. ``cd`` into the experiment directory

#. Set the environment variable ``$EXPTDIR`` for either bash or csh, respectively:

   .. code-block:: console

      export EXPTDIR=`pwd`
      setenv EXPTDIR `pwd`

#. Copy the wrapper scripts from the ``regional_workflow`` directory into the experiment directory. Each workflow task has a wrapper script that sets environment variables and runs the job script.

   .. code-block:: console

      cp <path-to>/ufs-srweather-app/regional_workflow/ush/wrappers/* .

#. Set the ``OMP_NUM_THREADS`` variable. 

   .. code-block:: console

      export OMP_NUM_THREADS=1

#. Run each of the listed scripts in order.  Scripts with the same stage number (listed in :numref:`Table %s <RegionalWflowTasks>`) may be run simultaneously.

   .. code-block:: console

      ./run_make_grid.sh
      ./run_get_ics.sh
      ./run_get_lbcs.sh
      ./run_make_orog.sh
      ./run_make_sfc_climo.sh
      ./run_make_ics.sh
      ./run_make_lbcs.sh
      ./run_fcst.sh
      ./run_post.sh

Check the batch script output file in your experiment directory for a “SUCCESS” message near the end of the file.

.. _RegionalWflowTasks:

.. table::  List of tasks in the regional workflow in the order that they are executed.
            Scripts with the same stage number may be run simultaneously. The number of
            processors and wall clock time is a good starting point for Cheyenne or Hera 
            when running a 48-h forecast on the 25-km CONUS domain. For a brief description of tasks, see :numref:`Table %s <WorkflowTasksTable>`. 

   +------------+------------------------+----------------+----------------------------+
   | **Stage/** | **Task Run Script**    | **Number of**  | **Wall clock time (H:mm)** |
   | **step**   |                        | **Processors** |                            |             
   +============+========================+================+============================+
   | 1          | run_get_ics.sh         | 1              | 0:20 (depends on HPSS vs   |
   |            |                        |                | FTP vs staged-on-disk)     |
   +------------+------------------------+----------------+----------------------------+
   | 1          | run_get_lbcs.sh        | 1              | 0:20 (depends on HPSS vs   |
   |            |                        |                | FTP vs staged-on-disk)     |
   +------------+------------------------+----------------+----------------------------+
   | 1          | run_make_grid.sh       | 24             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 2          | run_make_orog.sh       | 24             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 3          | run_make_sfc_climo.sh  | 48             | 0:20                       |
   +------------+------------------------+----------------+----------------------------+
   | 4          | run_make_ics.sh        | 48             | 0:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 4          | run_make_lbcs.sh       | 48             | 0:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 5          | run_fcst.sh            | 48             | 0:30                       |
   +------------+------------------------+----------------+----------------------------+
   | 6          | run_post.sh            | 48             | 0:25 (2 min per output     |
   |            |                        |                | forecast hour)             |
   +------------+------------------------+----------------+----------------------------+

Users can access log files for specific tasks in the ``$EXPTDIR/log`` directory. To see how the experiment is progressing, users can also check the end of the ``log.launch_FV3LAM_wflow`` file from the command line:

.. code-block:: console

   tail -n 40 log.launch_FV3LAM_wflow

.. hint:: 
   If any of the scripts return an error that "Primary job terminated normally, but one process returned a non-zero exit code," there may not be enough space on one node to run the process. On an HPC system, the user will need to allocate a(nother) compute node. The process for doing so is system-dependent, and users should check the documentation available for their HPC system. Instructions for allocating a compute node on NOAA Cloud systems can be viewed in :numref:`Section %s <WorkOnHPC>` as an example. 

.. note::
   On most HPC systems, users will need to submit a batch job to run multi-processor jobs. On some HPC systems, users may be able to run the first two jobs (serial) on a login node/command-line. Example scripts for Slurm (Hera) and PBS (Cheyenne) resource managers are provided (``sq_job.sh`` and ``qsub_job.sh``, respectively). These examples will need to be adapted to each user's system. Alternatively, some batch systems allow users to specify most of the settings on the command line (with the ``sbatch`` or ``qsub`` command, for example). 



.. _PlotOutput:

Plot the Output
===============
Two python scripts are provided to generate plots from the :term:`FV3`-LAM post-processed :term:`GRIB2` output. Information on how to generate the graphics can be found in :numref:`Chapter %s <Graphics>`.
