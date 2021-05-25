valid_vals_RUN_ENVIR=("nco" "community")
valid_vals_VERBOSE=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_MACHINE=("WCOSS_CRAY" "WCOSS_DELL_P3" "HERA" "ORION" "JET" "ODIN" "CHEYENNE" "STAMPEDE")
valid_vals_SCHED=("slurm" "pbspro" "lsf" "lsfcray" "none")
valid_vals_PREDEF_GRID_NAME=( \
"RRFS_CONUS_25km" \
"RRFS_CONUS_13km" \
"RRFS_CONUS_3km" \
"RRFS_SUBCONUS_3km" \
"RRFS_AK_13km" \
"RRFS_AK_3km" \
"CONUS_25km_GFDLgrid" \
"CONUS_3km_GFDLgrid" \
"EMC_AK" \
"EMC_HI" \
"EMC_PR" \
"EMC_GU" \
"GSL_HAFSV0.A_25km" \
"GSL_HAFSV0.A_13km" \
"GSL_HAFSV0.A_3km" \
"GSD_HRRR_AK_50km" \
"RRFS_NA_13km" \
"RRFS_NA_3km" \
)
valid_vals_CCPP_PHYS_SUITE=( \
"FV3_CPT_v0" \
"FV3_GFS_2017_gfdlmp" \
"FV3_GFS_2017_gfdlmp_regional" \
"FV3_GSD_SAR" \
"FV3_GSD_v0" \
"FV3_GFS_v15p2" \
"FV3_GFS_v16" \
"FV3_RRFS_v1beta" \
"FV3_RRFS_v1alpha" \
"FV3_HRRR" \
) 
valid_vals_GFDLgrid_RES=("48" "96" "192" "384" "768" "1152" "3072")
valid_vals_EXTRN_MDL_NAME_ICS=("GSMGFS" "FV3GFS" "RAP" "HRRR" "NAM")
valid_vals_EXTRN_MDL_NAME_LBCS=("GSMGFS" "FV3GFS" "RAP" "HRRR" "NAM")
valid_vals_USE_USER_STAGED_EXTRN_FILES=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_FV3GFS_FILE_FMT_ICS=("nemsio" "grib2" "netcdf")
valid_vals_FV3GFS_FILE_FMT_LBCS=("nemsio" "grib2" "netcdf")
valid_vals_GRID_GEN_METHOD=("GFDLgrid" "ESGgrid")
valid_vals_PREEXISTING_DIR_METHOD=("delete" "rename" "quit")
valid_vals_GTYPE=("regional")
valid_vals_WRTCMP_output_grid=("rotated_latlon" "lambert_conformal" "regional_latlon")
valid_vals_RUN_TASK_MAKE_GRID=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_RUN_TASK_MAKE_OROG=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_RUN_TASK_MAKE_SFC_CLIMO=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_RUN_TASK_VX_GRIDSTAT=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_RUN_TASK_VX_POINTSTAT=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_QUILTING=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_PRINT_ESMF=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_USE_CRON_TO_RELAUNCH=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_DOT_OR_USCORE=("." "_")
valid_vals_NOMADS=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_NOMADS_file_type=("GRIB2" "grib2" "NEMSIO" "nemsio")
valid_vals_DO_ENSEMBLE=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_USE_CUSTOM_POST_CONFIG_FILE=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_DO_SHUM=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_DO_SPPT=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_DO_SPP=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_DO_SKEB=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_USE_ZMTNBLCK=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_USE_FVCOM=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
valid_vals_COMPILER=("intel" "gnu")
valid_vals_SUB_HOURLY_POST=("TRUE" "true" "FALSE" "false" "YES" "yes" "NO" "no")
valid_vals_DT_SUBHOURLY_POST_MNTS=("1" "01" "2" "02" "3" "03" "4" "04" "5" "05" "6" "06" "10" "12" "15" "20" "30")
