;
; **********************************************************************
;
; Type "ncl plot_grid.ncl 'help=True'" on the command line to obtain 
; help for this script.
;
; **********************************************************************
;

;
; **********************************************************************
;
; Declare global variables before loading files.  This has the same ef-
; fect as declaring these variables on the command line.
;
; **********************************************************************
;

;help = True

;run_dir = "ABCD"
;run_dir = "/home/Gerard/fv3_regional/fv3sar_workflow/ush/NCL"
;run_dir = "/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM_test_instructions/expt_dirs/NX1734_NY1008_A0p21423_Kmns0p23209_HRRR_test_HRRRgrid02"
;run_dir = "/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM_test_instructions/expt_dirs/NX1800_NY1120_A0p21423_Kmns0p23209_HRRR_test_cycl_slurm_01"

expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/regional_001_old001"
expt_dir = "/scratch2/BMC/det/beck/SAR-FV3/run_dirs/real_time2"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/regional_007"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/GFDLgrid_debug_verif"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/GFDLgrid_debug_verif_preprocess_good"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/GFDLgrid_AK_3km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/new_JPgrid"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/RTMA_grid_25km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/regional_003"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/GSD_RAP13km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/GSD_RAP13km_works02"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/RRFS_HRRR3km_from_regional_003"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/regional_002_GSD_HRRR3km"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/expt_dirs/nco_GSD_HRRR3km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_rrfs_v1beta/expt_dirs/regional_002"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_rrfs_v1beta/expt_dirs/FV3_RRFS_v1beta"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_rrfs_v1beta/expt_dirs/FV3_RRFS_v1beta_3km"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/regional_002_25km"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/regional_002_13km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_rrfs_v1beta/expt_dirs/subconus"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_rrfs_v1beta/expt_dirs/nco_GSD_SUBCONUS3km_HRRRX_RAPX_works01"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_WE2E_testing/expt_dirs/try13/regional_002"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_WE2E_testing/expt_dirs/try13/nco_GSD_HRRR3km_HRRRX_RAPX"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_WE2E_testing/expt_dirs/try15/suite_FV3_GSD_SAR_3km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_GSD_HRRR13km"

CDATE="2017090712"
CDATE="2019052000"
;CDATE="2020031212"
;CDATE="2017090700"
CDATE="2019070100"
;CDATE="2020080100"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/suite_FV3_GSD_SAR_3km_works03"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/suite_FV3_GSD_SAR_3km"
CDATE="2019052000"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_GSD_HRRR13km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_CONUS_13km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_CONUS_13km_HRRRX_RAPX"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try01/grid_RRFS_CONUS_13km_FV3GFS_FV3GFS"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try03/grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
CDATE="2019070100"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try01/grid_RRFS_CONUS_13km_HRRRX_RAPX"
;CDATE="2020080100"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try01/grid_RRFS_CONUS_3km_FV3GFS_FV3GFS"
;CDATE="2019070100"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_SUBCONUS_3km"
;CDATE="2019070100"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_CONUS_3km_GFDLgrid"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_maximize_CONUS_grids/expt_dirs/try02/grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
CDATE="2019070100"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_CONUS_25km_GFDLgrid"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try03/grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
;expt_dir = "/work/noaa/gsd-fv3-dev/gsketefia/UFS/PR_release_branch/expt_dirs/try02/grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_maximize_CONUS_grids/expt_dirs/try02/grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
;CDATE="2019070100"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/suite_FV3_GSD_SAR"
;CDATE="2019052000"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_AK_3km"
;expt_dir = "/work/noaa/gsd-fv3-dev/gsketefia/UFS/PR_release_branch/expt_dirs/try01/grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_maximize_CONUS_grids/expt_dirs/try02/grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
;CDATE="2019052000"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_AK_13km"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_AK_13km_old001"
;expt_dir = "/work/noaa/gsd-fv3-dev/gsketefia/UFS/PR_release_branch/expt_dirs/try02/grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
;CDATE="2019052000"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_Jeff_Duda_subhourly_post/expt_dirs/big_grid01/grid_GSD_RAP13km_pregen"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_Jeff_Duda_subhourly_post/expt_dirs/big_grid02/grid_GSD_RAP13km_pregen"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_Jeff_Duda_subhourly_post/expt_dirs/big_grid02/grid_GSD_RAP13km_pregen_old003"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_Jeff_Duda_subhourly_post/expt_dirs/big_grid02/grid_GSD_RAP13km"
CDATE="2019070100"

run_dir = expt_dir + "/" + CDATE
print("AAAAAA  run_dir = " + run_dir)

;tile_inds := (/ 1, 7, 4 /)
;tile_inds := (/ 1, 4 /)
;tile_inds := (/ 5, 6 /)
;tile_inds := (/ 5, 7 /)
;tile_inds := (/ 5, 6, 7 /)
;tile_inds := (/ 5 /)
;tile_inds := (/ 6 /)
tile_inds := (/ 7 /)
;tile_inds := (/ 6, 7 /)

;subreg_limits := (/ -180, 180, -90, 90 /)
;subreg_limits := (/ -75, -45, 30, 60 /)
;subreg_limits := (/ -145, -90, 30, 60 /)
;subreg_limits := (/ -120, -115, 30, 35 /)
;subreg_limits := (/ -15, 0, 0, 15 /)
;subreg_limits := (/ -30, 0, 0, 30 /)
;subreg_limits := (/ -60, -30, 0, 30 /)
;subreg_limits := (/ -75, -60, 0, 15 /)
;subreg_limits := (/ -70, -65, 5, 10 /)
;subreg_limits := (/ -55, -40, 45, 60 /)
;subreg_limits := (/ -50, -45, 50, 55 /)
;subreg_limits := (/ -10, 5, 0, 15 /)
;subreg_limits := (/ -2, 2, 0, 4 /)

remove_rgnl_halo = True
;remove_rgnl_halo = False

plot_RAP_field = True
;plot_RAP_field = False

field_name_RAP = "XLAT_M"
;field_name_RAP = "cell_area"
;field_name_RAP = "VGTYP_P0_L1_GLC0"

show_RAP_bdy = True
RAP_bdy_color = "red"

RAP_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509"
RAP_dir = "/scratch1/BMC/gsd-fv3-dev/Gerard.Ketefian/regional_FV3_EMC_visit_20180509"
;RAP_dir = "/work/noaa/gsd-fv3-dev/gsketefia/UFS" ; This is on Orion.
;RAP_grid_fn = "/home/Gerard/fv3_regional/fv3sar_workflow/ush/NCL/plot_grid.ncl"
;RAP_grid_fn = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/geo_em.d01.RAP.nc"
RAP_grid_fn = RAP_dir + "/geo_em.d01.RAP.nc"
RAP_grid_fn = RAP_dir + "/geo_em.d01.HRRR.nc"


map_proj = "cyln"
;map_proj = "ortho"
;
; This should be set to (0,0) for "cyln" map projection.
;
map_proj_ctr = (/ 0.0, 0.0 /) ; This should be set to (0,0) for "cyln" map projection.
;map_proj_ctr = (/ -106.0, 54.0 /) ; RAP domain.
;map_proj_ctr = (/ -106.0, 84.0 /) ; RAP domain.
;map_proj_ctr = (/ 30.0, 60.0 /) ; RAP domain.
;map_proj_ctr = (/ -97.5, 38.5 /)  ; HRRR domain.
;map_proj_ctr = (/ 6.0, 54.0 /) ; RAP domain corner.

;map_proj_ctr = (/ -161.5, 63.0 /)  ; Alaska

;map_proj_ctr = (/ -98.5, 30.0 /)


plot_subreg = True
;plot_subreg = False

subreg_limits := (/ -180, 180, -90, 90 /)
;subreg_limits := (/ -75, -45, 30, 60 /)
;subreg_limits := (/ -155, -45, 60, 90 /)
;subreg_limits := (/ -155, -45, 60, 100 /)
;subreg_limits := (/ -190, -170, 80, 100 /)
;subreg_limits := (/ -55, -45, 80, 90 /)
;subreg_limits := (/ 45, 55, 60, 70 /)
;subreg_limits := (/ 15, 45, 30, 50 /)


;subreg_limits := (/ -75, -45, -30, 0 /) ; 
;subreg_limits := (/ -40, -35, 25, 30 /) ; 

; The following are to plot regions near the four corners and along two
; of the edges of GSD_RAP13km domain (soon to be renamed to RRFS_NA_13km)
; to ensure that the write-component grid is within the native grid.  It's
; easiest to use map_proj = "cyln" to plot these subregions.
;subreg_limits := (/ -155, -130, -25, 0 /) ; 
;subreg_limits := (/ -80, -55, -25, 0 /) ; 
;subreg_limits := (/ -45, -20, 15, 40 /)
;subreg_limits := (/ 5, 30, 35, 60 /)
;subreg_limits := (/ 125, 150, 35, 60 /)
;subreg_limits := (/ -180, -155, 15, 40 /)


;subreg_limits := (/ -128, -67, 23, 51 /) ; HRRR domain if using "cyln" map projection.
;subreg_limits := (/ -135, -60, 20, 55 /) ; HRRR domain if using "cyln" map projection.
;subreg_limits := (/ -125, -70, 20, 55 /) ; HRRR domain if using "ortho" map projection.
;subreg_limits := (/ -105, -95, 20, 30 /) ; Center of southern edge of HRRR domain.

;subreg_limits := (/ -128, -118, 32, 42 /) ; Center of western edge of HRRR domain.

;subreg_limits := (/ -120, -75, 20, 55 /) ; Center of HRRR domain, zoomed.
;subreg_limits := (/ -110, -85, 30, 45 /) ; Center of HRRR domain, zoomed more.
;subreg_limits := (/ -100, -97, 36, 39 /) ; Center of HRRR domain, zoomed more.

;subreg_limits := (/ -135, -60, 20, 55 /)



; Zoom in on midpoint of southern edge of CONUS domain.
;subreg_limits := (/ -103.5, -93.5, 22.5, 26.5 /) ; 10deg x 4deg
;subreg_limits := (/ -100.0, -95.0, 24.0, 26.0 /) ; 5deg x 2deg
;subreg_limits := (/ -99.5, -97.5, 24, 25 /) ; 2deg x 1deg
;subreg_limits := (/ -99, -98, 24.15, 24.65 /) ; 1deg x 0.5deg

; Zoom in on midpoint of eastern edge of CONUS domain.
;subreg_limits := (/ -71, -66, 33.5, 38.5 /) ; 5deg x 5deg

; Zoom in on midpoint of northern edge of CONUS domain.
;subreg_limits := (/ -103.5, -93.5, 50.2, 54.2 /) ; 10deg x 4deg
;subreg_limits := (/ -100.0, -95.0, 51.3, 53.3 /) ; 5deg x 2deg
;subreg_limits := (/ -99.5, -97.5, 51.9, 52.9 /) ; 2deg x 1deg
;subreg_limits := (/ -99, -98, 52.3, 52.8 /) ; 1deg x 0.5deg

; Zoom in on midpoint of western edge of CONUS domain.
;subreg_limits := (/ -128, -123, 33.5, 38.5 /) ; 5deg x 5deg

; Zoom in on northwest corner of CONUS domain.
;subreg_limits := (/ -129, -99, 32, 52 /) ; 20deg x 20deg
;subreg_limits := (/ -131, -121, 40, 50 /) ; 10deg x 10deg
;subreg_limits := (/ -133, -128, 44, 49 /) ; 5deg x 5deg
;subreg_limits := (/ -133.5, -131.5, 46.2, 48.2 /) ; 2deg x 2deg
;subreg_limits := (/ -134, -133, 47, 48 /) ; 1deg x 1deg

; Zoom in on southwest corner of CONUS domain.
;subreg_limits := (/ -125, -105, 22, 42 /) ; 20deg x 20deg
;subreg_limits := (/ -124, -114, 22, 32 /) ; 10deg x 10deg
;subreg_limits := (/ -124, -119, 21, 26 /) ; 5deg x 5deg
;subreg_limits := (/ -123.3, -121.3, 21.2, 23.2 /) ; 2deg x 2deg
;subreg_limits := (/ -123.1, -122.1, 21.2, 22.2 /) ; 1deg x 1deg
;subreg_limits := (/ -122.95, -122.45, 21.45, 21.95 /) ; 0.5deg x 0.5deg
;subreg_limits := (/ -122.9, -122.8, 21.45, 21.55 /) ; 0.1deg x 0.1deg
;subreg_limits := (/ -122.85, -122.83, 21.49, 21.51 /) ; 0.02deg x 0.02deg

; Zoom in on southeast corner of CONUS domain.
;subreg_limits := (/ -88, -68, 18, 38 /) ; 20deg x 20deg
;subreg_limits := (/ -80, -70, 20, 30 /) ; 10deg x 10deg
;subreg_limits := (/ -76, -71, 21, 26 /) ; 5deg x 5deg
;subreg_limits := (/ -73.9, -71.9, 21.0, 23.0 /) ; 2deg x 2deg
;subreg_limits := (/ -73, -72, 21.2, 22.2 /) ; 1deg x 1deg
;subreg_limits := (/ -72.5, -72.0, 21.45, 21.95 /) ; 0.5deg x 0.5deg
;subreg_limits := (/ -72.25, -72.15, 21.45, 21.55 /) ; 0.1deg x 0.1deg
;subreg_limits := (/ -72.17, -72.15, 21.49, 21.51 /) ; 0.02deg x 0.02deg

; Zoom in on northeast corner of CONUS domain.
;subreg_limits := (/ -78, -58, 32, 52 /) ; 20deg x 20deg
;subreg_limits := (/ -70, -60, 40, 50 /) ; 10deg x 10deg.
;subreg_limits := (/ -65.5, -60.5, 44, 49 /) ; 5deg x 5deg.
;subreg_limits := (/ -63.0, -61.0, 46.2, 48.2 /) ; 2deg x 2deg.
;subreg_limits := (/ -62.2, -61.2, 47, 48 /) ; 1deg x 1deg.




; EMC's 25km BIG CONUS grid.
;subreg_limits := (/ -145, -50, 10, 65 /) 

; Zoom in on northwest corner of BIG CONUS domain.
;subreg_limits := (/ -139, -136, 51, 54 /) ; 3deg x 3deg

; Zoom in on southwest corner of BIG CONUS domain.
;subreg_limits := (/ -123, -120, 14, 17 /) ; 3deg x 3deg

; Zoom in on southeast corner of BIG CONUS domain.
;subreg_limits := (/ -75, -72, 14, 17 /) ; 3deg x 3deg

; Zoom in on northeast corner of BIG CONUS domain.
;subreg_limits := (/ -59, -56, 51, 54 /) ; 3deg x 3deg




; EMC's 3km BIG CONUS grid.
;subreg_limits := (/ -145, -50, 10, 65 /) 

; Zoom in on northwest corner of BIG CONUS domain.
;subreg_limits := (/ -137, -134, 47, 50 /) ; 3deg x 3deg

; Zoom in on southwest corner of BIG CONUS domain.
;subreg_limits := (/ -125, -122, 18.5, 21.5 /) ; 3deg x 3deg

; Zoom in on southeast corner of BIG CONUS domain.
;subreg_limits := (/ -74, -71, 18.5, 21.5 /) ; 3deg x 3deg

; Zoom in on northeast corner of BIG CONUS domain.
;subreg_limits := (/ -61, -58, 47, 50 /) ; 3deg x 3deg




; Alaska domain subregions:
;subreg_limits := (/ -210, -120, 45, 80 /) ; whole AK domain; won't work with cyln projection

; Zoom in on northwest corner of Alaska domain.
;subreg_limits := (/ 141, 145, 66, 70 /) ; 4deg x 4deg
;subreg_limits := (/ 142, 144, 66, 70 /) ; 2deg x 4deg
;subreg_limits := (/ 142, 144, 67, 69 /) ; 2deg x 2deg

; Zoom in on southwest corner of Alaska domain.
;subreg_limits := (/ 170, 174, 44, 48 /) ; 4deg x 4deg
;subreg_limits := (/ 170, 173, 44, 47 /) ; 3deg x 3deg
;subreg_limits := (/ 171, 173, 45, 47 /) ; 2deg x 2deg

; Zoom in on southeast corner of Alaska domain.
;subreg_limits := (/ -137, -133, 44, 48 /) ; 4deg x 4deg
;subreg_limits := (/ -136, -133, 44, 47 /) ; 3deg x 3deg
;subreg_limits := (/ -135.5, -133.5, 44.8, 46.8 /) ; 2deg x 2deg

; Zoom in on northeast corner of Alaska domain.
;subreg_limits := (/ -108, -102, 65, 71 /) ; 6deg x 6deg
;subreg_limits := (/ -107, -103, 66, 70 /) ; 4deg x 4deg
;subreg_limits := (/ -106, -104, 66, 70 /) ; 2deg x 4deg
;subreg_limits := (/ -106, -104, 67, 69 /) ; 2deg x 2deg


;subreg_limits := (/ -135, -60, 15, 60 /) ; RTMA domain if using "ortho" map projection.
;subreg_limits := (/ -128, -126, 34, 36 /) ; Center of western boundary of CONUS

;subreg_limits := (/ -15, 0, 0, 15 /)
;subreg_limits := (/ -30, 0, 0, 30 /)
;subreg_limits := (/ -60, -30, 0, 30 /)
;subreg_limits := (/ -75, -60, 0, 15 /)
;subreg_limits := (/ -70, -65, 5, 10 /)
;subreg_limits := (/ -55, -40, 45, 60 /)
;subreg_limits := (/ -50, -45, 50, 55 /)
;subreg_limits := (/ -10, 5, 0, 15 /)
;subreg_limits := (/ -2, 2, 0, 4 /)
;subreg_limits := (/ -90, -60, -20, 10 /)
;subreg_limits := (/ -80, -70, -10, 0 /)
;subreg_limits := (/ -85, -70, -15, 0 /)
;subreg_limits := (/ -76, -72, -12, -8 /)
;subreg_limits := (/ -75, -45, -15, 0 /)
;subreg_limits := (/ -63, -58, -15, -10 /)
;subreg_limits := (/ 15, 30, 30, 45 /)
;subreg_limits := (/ 14, 16, 36, 38 /)
;subreg_limits := (/ -70, -55, -20, -5 /)
;subreg_limits := (/ 10, 20, 30, 40 /)
;subreg_limits := (/ 15, 20, 30, 35 /)


horiz_dist_units = "m"
horiz_dist_units = "km"

field_name = "area"
;field_name = "sqrt_area"
;field_name = "dx"
;field_name = "dy"
;field_name = "dx_ovr_dy"
;field_name = "min_dx_dy"
;field_name = "angle_dx"
;field_name = "angle_dy"

;field_name = "abcd"

field_name = "orog_raw"
;field_name = "orog_filt"

;field_name = "time"
;field_name = "grid_xt"
;field_name = "vflx_ave"
;field_name = "ref3D"

field_name = "sltyp"
field_name = "dswrf"
field_name = "zsurf"


show_tile_bdies = True
;show_tile_bdies = False

show_tile_grids = True
;show_tile_grids = False


file_basename = "atmos_static"
;file_basename = "fv3_history"
file_basename = "fv3_history2d"


show_wrtcmp_grid = True
show_wrtcmp_grid = False

show_wrtcmp_bdy = True
;show_wrtcmp_bdy = False


separator_line \
:= "************************************************************************"
;:= "========================================================================"


;
; **********************************************************************
;
; Load files.
;
; **********************************************************************
;
lib_location = "lib/"

loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "repeat_str.ncl")
loadscript(lib_location + "calc_field_stats.ncl")
loadscript(lib_location + "get_rect_grid_bdy.ncl")
loadscript(lib_location + "set_cnLevels_lbLabels.ncl")
loadscript(lib_location + "append_to_snumeric_array.ncl")

load "process_plot_params.ncl"
load "read_FV3LAM_grid_native.ncl"
load "read_FV3LAM_field_native.ncl"
load "read_FV3LAM_grid_wrtcmp.ncl"
load "read_FV3LAM_field_wrtcmp.ncl"
load "read_RAP_grid.ncl"
load "read_RAP_field.ncl"
load "plot_horiz_field.ncl"

load "check_filevar_existence_dims.ncl"

begin
;
; **********************************************************************
;
; Set usage message.
;
; **********************************************************************
;
  usage_msg = \
"  ncl -n plot_grid.ncl \" + char_nl + \
"      'help=False' \" + char_nl + \
"      'grid_dir=" + char_dq + "./some_dir/grid" + char_dq + "' \" + char_nl + \
"      'res=96' \" + char_nl + \
"      'tile_inds=(/1,2,3/)' \" + char_nl + \
"      'show_tile_bdies=True' \" + char_nl + \
"      'show_tile_grids=True' \" + char_nl + \
"      'plot_RAP_field=True' \" + char_nl + \
"      'RAP_grid_fn=" + char_dq + "./some_dir/RAP_grid.nc" + char_dq + "' \" + char_nl + \
"      'show_RAP_bdy=True' \" + char_nl + \
"      'show_RAP_grid=True' \" + char_nl + \
"      'map_proj=" + char_dq + "cyln" + char_dq + "' \" + char_nl + \
"      'map_proj_ctr=(/0,90/)' \" + char_nl + \
"      'subreg_limits=(/-30,30,-25,25/)' \" + char_nl + \
"      'graphics_type=" + char_dq + "ncgm" + char_dq + "'"
;
; **********************************************************************
;
; Set help message.  The help message contains the documentation for 
; this script and thus should reflect any changes to the code.
;
; **********************************************************************
;
  help_msg = char_nl + \
"This script generates a 2-D color plot of one or more of the tiles on" + char_nl + \
"a cubed-sphere grid on top of a map of the continents.  Each tile is" + char_nl + \
"depicted in the output graphics file as a uniformly colored region." + char_nl + \
char_nl + \
"An example of a call to this script from the command line is as fol-" + char_nl + \
"lows:" + char_nl + \
char_nl + \
usage_msg + \
char_nl + \
char_nl + \
"The output is a graphics file named" + char_nl + \
char_nl + \
"  C[res]_grid.[ext]" + char_nl + \
char_nl + \
"where res is the specified resolution and ext is the graphics file ex-" + char_nl + \
"tension (determined by the specified output graphics type graphics_-" + char_nl + \
"type).  The input arguments to this script are:" + char_nl + \
char_nl + \
"help:" + char_nl + \
"This argument specifies whether or not to print out the documentation" + char_nl + \
"for this script and exit.  It is either True or False.  Default is" + char_nl + \
"False.  If this is set to True, this script prints out the documenta-" + char_nl + \
"tion and exits, ignoring all other arguments.  To see the documenta-" + char_nl + \
"tion, type " + char_dq + "ncl plot_grid.ncl 'help=True'" + char_dq + " on the command line in the" + char_nl + \
"directory of this script." + char_nl + \
char_nl + \
"grid_dir:" + char_nl + \
"This argument specifies the directory in which the grid files are lo-" + char_nl + \
"cated.  It is assumed that these are NetCDF files with names of the" + char_nl + \
"form" + char_nl + \
char_nl + \
"   C[res]_grid.tile[N].nc" + char_nl + \
char_nl + \
"where res is the resolution specified on the command line and N is the" + char_nl + \
"tile number.  The tile numbers to consider are specified by the input" + char_nl + \
"argument tile_inds (see below).  Default value is the current directo-" + char_nl + \
"ry, i.e. " + char_dq + "./" + char_dq + "." + char_nl + \
char_nl + \
"res:" + char_nl + \
"This argument specifies the cubed-sphere resolution, i.e. the number" + char_nl + \
"of cells in each of the two horizontal directions on each of the 6" + char_nl + \
"tiles of the global cubed-sphere grid.  Valid values are: 48, 96, 192," + char_nl + \ 
"384, 768, 1152, and 3072." + char_nl + \
char_nl + \
"tile_inds:" + char_nl + \
"This argument specifies the indices of those tiles on the cubed-sphere" + char_nl + \
"grid that are to be plotted.  For example, to plot tiles 1, 3, and 5, " + char_nl + \
"specify" + char_nl + \
char_nl + \
"  tile_inds = (/ 1, 3, 5 /)" + char_nl + \
char_nl + \
"If this is not specified, all available tiles are plotted (where by " + char_nl + \
char_dq + "available" + char_dq + ", we mean all tiles for which there exists a grid file in" + char_nl + \
"grid_dir)." + char_nl + \
char_nl + \
"show_tile_bdies:" + char_nl + \
"This argument specifies whether or not to draw the boundary of each " + char_nl + \
"specified tile.  It is either True or False.  Default is True." + char_nl + \
char_nl + \
"show_tile_grids:" + char_nl + \
"This argument specifies whether or not to draw the boundaries of all" + char_nl + \
"grid cells on each tile that is being plotted.  It is either True or " + char_nl + \
"False.  Default is False.  For a high-resolution grid, this can make" + char_nl + \
"it difficult to see the underlying color of the tile in the output" + char_nl + \
"graphics file (because there would be many grid lines drawn very close" + char_nl + \
"together)." + char_nl + \
char_nl + \
"plot_RAP_field:" + char_nl + \
"This argument specifies whether or not to draw the original [i.e. pre-" + char_nl + \
"FV3 RAP (RAPid Refresh) domain].  It is either True or False.  Default" + char_nl + \
"is False.  If this is set to True, the RAP domain is added to the plot" + char_nl + \
"as a uniformly colored region (with a color that is different from any" + char_nl + \
"of the cubed-sphere tiles)." + char_nl + \
char_nl + \
"RAP_grid_fn:" + char_nl + \
"This argument specifies the full (i.e. including directory) file name" + char_nl + \
"of the NetCDF file that describes the RAP grid.  This is used only if" + char_nl + \
"plot_RAP_field is set to True." + char_nl + \
"" + char_nl + \
"show_RAP_bdy:" + char_nl + \
"This argument specifies whether or not to draw the boundary of the RAP" + char_nl + \
"domain.  It is either True or False.  Default is True.  This has no" + char_nl + \
"effect if plot_RAP_field is set to False." + char_nl + \
char_nl + \
"show_RAP_grid:" + char_nl + \
"This argument specifies whether or not to draw the boundaries of all" + char_nl + \
"grid cells on the RAP domain.  It is either True or False.  Default is" + char_nl + \
"False.  For a high-resolution RAP grid, setting this to True can make" + char_nl + \
"it difficult to see the underlying color of the RAP domain in the out-" + char_nl + \
"put graphics file (because there would be many grid lines drawn very" + char_nl + \
"close together.  This has no effect if plot_RAP_field is set to" + char_nl + \
"False." +  char_nl + \
char_nl + \
"map_proj:" + char_nl + \
"This argument specifies the map projection to use for the plot.  Valid" + char_nl + \
"values are:" + char_nl + \
char_nl + \
"  " + char_dq + "cyln" + char_dq + " - for cylindrical-equidistant projection" + char_nl + \
"  " + char_dq + "ortho" + char_dq + " - for orthographic (i.e. on a sphere) projection" + char_nl + \
;"  " + char_dq + "lamb" + char_dq + " - for Lambert equal-area projection" + char_nl + \
"  " + char_dq + "lamb" + char_dq + " - for Lambert conformal projection" + char_nl + \
char_nl + \
"If this argument is omitted, a cylindrical-equidistant projection is" + char_nl + \
"used.  " + char_nl + \
char_nl + \
"map_proj_ctr:" + char_nl + \
"This argument specifies the point on the sphere at which to center the" + char_nl + \
"map projection used for the plot.  It consists of the point's longi-" + char_nl + \
"tude and latitude (in degrees), as follows:" + char_nl + \
char_nl + \
"  map_proj_ctr = (/ 30, 40 /)" + char_nl + \
char_nl + \
"If this is not specified, it is set to (/0,0/) for the cylindrical-" + char_nl + \
"equidistant and orthographic (i.e. on a sphere) projections and to" + char_nl + \
"(/0,90/) (i.e. the North Pole) for the Lambert equal-area projection." + char_nl + \
char_nl + \
"subreg_limits:" + char_nl + \
"If using a cylindrical-equidistant map projection, this argument spe-" + char_nl + \
"cifies the minimum and maximum longitudes and latitudes (in degrees)" + char_nl + \
"of the subregion to plot.  It has the format" + char_nl + \
char_nl + \
"  subreg_limits = (/ lon_min, lon_max, lat_min, lat_max /)" + char_nl + \
char_nl + \
"where lon_min and lon_max are the minimum and maximum values of the" + char_nl + \
"longitude and lat_min and lat_max are the minimum and maximum values" + char_nl + \
"of the latitude.  If this argument is omitted, the field is plotted on" + char_nl + \
"the whole globe.  It is ignored for projections other than cylindri-" + char_nl + \
"cal-equidistant." + char_nl + \
char_nl + \
"graphics_type:" + char_nl + \
"This argument specifies the type of graphics file to generate as out-" + char_nl + \
"put.  It can be either " + char_dq + "ncgm" + char_dq + " (NCAR Graphics) or " + char_dq + "png" + char_dq + ".  Default is" + char_nl + \
char_dq + "ncgm" + char_dq + "." + char_nl 
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  plot_params := process_plot_params("plot_grid", usage_msg, help_msg)

  gtype = plot_params@gtype
  num_tiles_to_plot = plot_params@num_tiles_to_plot
  inds_tiles_to_plot = plot_params@inds_tiles_to_plot
;print("XXXXXXXXXXXXXXX")
;print("inds_tiles_to_plot = " + inds_tiles_to_plot)

  cres = plot_params@cres
  expt_dir = plot_params@expt_dir

  horiz_dist_units = plot_params@horiz_dist_units
  horiz_area_units = plot_params@horiz_area_units

  show_tile_bdies = plot_params@show_tile_bdies
  tile_bdy_color = plot_params@tile_bdy_color
  show_tile_grids = plot_params@show_tile_grids
  field_name = plot_params@field_name
  is_gridfield = plot_params@is_gridfield
  file_basename = plot_params@file_basename

  show_RAP_bdy = plot_params@show_RAP_bdy
  RAP_bdy_color = plot_params@RAP_bdy_color
  show_RAP_grid = plot_params@show_RAP_grid
  plot_RAP_field = plot_params@plot_RAP_field
  field_name_RAP = plot_params@field_name_RAP

  graphics_type = plot_params@graphics_type
  map_proj = plot_params@map_proj
  map_proj_ctr = plot_params@map_proj_ctr

  remove_rgnl_halo = plot_params@remove_rgnl_halo

  plot_subreg = plot_params@plot_subreg
  subreg_limits = plot_params@subreg_limits
;
; **********************************************************************
;
;
;
; **********************************************************************
;
native = True
;native = False
native@plot_gridlines = True
native@plot_gridlines = False
;native@gridline_color = "black"
native@gridline_color = "red"
native@plot_bdy = True
native@bdy_color = native@gridline_color
native@bdy_line_thickness = 4.0
;native@bdy_line_thickness = 16.0
native@bdy_dash_pattern = 1

halo = True
;halo = False
halo@plot_gridlines = True
;halo@plot_gridlines = False
halo@gridline_color = "orange"
halo@plot_bdy = True
;halo@plot_bdy = False 
halo@bdy_color = halo@gridline_color
halo@bdy_line_thickness = 4.0
halo@bdy_dash_pattern = 1

wrtcmp = True
;wrtcmp = False
wrtcmp@plot_gridlines = True
wrtcmp@plot_gridlines = False
;wrtcmp@gridline_color = "green"
wrtcmp@gridline_color = "blue"
wrtcmp@plot_bdy = True
wrtcmp@bdy_color = wrtcmp@gridline_color
wrtcmp@bdy_line_thickness = 6.0
wrtcmp@bdy_dash_pattern = 1

extrnl = True
extrnl = False
;extrnl@plot_gridlines = True
extrnl@plot_gridlines = False
;extrnl@gridline_color = "red"
extrnl@gridline_color = "green"
extrnl@plot_bdy = True
extrnl@bdy_color = extrnl@gridline_color
extrnl@bdy_line_thickness = 4.0
extrnl@bdy_dash_pattern = 1
;
; **********************************************************************
;
;
;
; **********************************************************************
;
grid_opts = True
grid_opts@plot_gridlines := new(1, logical)
grid_opts@gridline_colors := new(1, string)

bdy_opts = True
bdy_opts@num_bdies = 0
bdy_opts@plot_bdy = new(1, logical)
bdy_opts@bdy_colors = new(1, string)
bdy_opts@bdy_line_thicknesses = new(1, float)
bdy_opts@bdy_dash_patterns = new(1, integer)
;
; **********************************************************************
;
; Initialize arrays to single-element arrays.  These will be appended to
; as necessary.
;
; **********************************************************************
;
num_grids := 0

nx_all := new(1, integer)
ny_all := new(1, integer)
lon_cntrs_unstruc := new(1, double)
lat_cntrs_unstruc := new(1, double)
lon_verts_unstruc := new((/1,4/), double)
lat_verts_unstruc := new((/1,4/), double)
lon_bdy := new(1, double)
lat_bdy := new(1, double)
field_unstruc := new(1, double)
;
; **********************************************************************
;
; If native is set to True, read in the native FV3LAM grid.
;
; **********************************************************************
;
if (native .or. halo) then
;if (native) then

  num_grids = num_grids + 1

  nhalo_T7 = 4  ; Should this be at the top, i.e. defined as a global variable????
                ; or be a requird input that gets processed along with the other
                ; command linea arguments?

  grid_info := read_FV3LAM_grid_native( \
               expt_dir, \
               gtype, \
               cres, \
               inds_tiles_to_plot, \
               show_tile_bdies, \
               nhalo_T7, \
               remove_rgnl_halo)

  if (remove_rgnl_halo) then
    nx_all := append_to_snumeric_array(nx_all, grid_info@nx_all_tiles)
    ny_all := append_to_snumeric_array(ny_all, grid_info@ny_all_tiles)
  else
    nx_all := append_to_snumeric_array(nx_all, grid_info@nxh_all_tiles)
    ny_all := append_to_snumeric_array(ny_all, grid_info@nyh_all_tiles)
  end if

  lon_cntrs_unstruc \
  := append_to_snumeric_array(lon_cntrs_unstruc, grid_info@lon_cntrs_all_tiles_unstruc)
  lat_cntrs_unstruc \
  := append_to_snumeric_array(lat_cntrs_unstruc, grid_info@lat_cntrs_all_tiles_unstruc)

  lon_verts_unstruc \
  := append_to_snumeric_array(lon_verts_unstruc, grid_info@lon_verts_all_tiles_unstruc)
  lat_verts_unstruc \
  := append_to_snumeric_array(lat_verts_unstruc, grid_info@lat_verts_all_tiles_unstruc)

  lon_bdy := append_to_snumeric_array(lon_bdy, grid_info@lon_bdy_all_tiles)
  lat_bdy := append_to_snumeric_array(lat_bdy, grid_info@lat_bdy_all_tiles)

  grid_opts@plot_gridlines \
  := array_append_record(grid_opts@plot_gridlines, native@plot_gridlines, 0)
  grid_opts@gridline_colors \
  := array_append_record(grid_opts@gridline_colors, native@gridline_color, 0)

  if (native@plot_bdy) then
    bdy_opts@num_bdies = bdy_opts@num_bdies + 1
    bdy_opts@plot_bdy \
    := array_append_record(bdy_opts@plot_bdy, native@plot_bdy, 0)
    bdy_opts@bdy_colors \
    := array_append_record(bdy_opts@bdy_colors, native@bdy_color, 0)
    bdy_opts@bdy_line_thicknesses \
    := array_append_record(bdy_opts@bdy_line_thicknesses, native@bdy_line_thickness, 0)
    bdy_opts@bdy_dash_patterns \
    := array_append_record(bdy_opts@bdy_dash_patterns, native@bdy_dash_pattern, 0)
  end if

end if
;
; **********************************************************************
;
; If halo is set to True, then ...
;
; **********************************************************************
;
if (halo) then

  num_grids = num_grids + 1

;  nhalo_T7 = 4  ; Should this be at the top, i.e. defined as a global variable????
;                ; or be a requird input that gets processed along with the other
;                ; command linea arguments?
;
;  grid_info := read_FV3LAM_grid_native( \
;               expt_dir, \
;               gtype, \
;               cres, \
;               inds_tiles_to_plot, \
;               show_tile_bdies, \
;               nhalo_T7, \
;               False)

  nx_all := append_to_snumeric_array(nx_all, grid_info@nxh_all_tiles)
  ny_all := append_to_snumeric_array(ny_all, grid_info@nyh_all_tiles)

  lon_cntrs_unstruc \
  := append_to_snumeric_array(lon_cntrs_unstruc, grid_info@lon_halo_cntrs_all_tiles_unstruc)
  lat_cntrs_unstruc \
  := append_to_snumeric_array(lat_cntrs_unstruc, grid_info@lat_halo_cntrs_all_tiles_unstruc)

  lon_verts_unstruc \
  := append_to_snumeric_array(lon_verts_unstruc, grid_info@lon_halo_verts_all_tiles_unstruc)
  lat_verts_unstruc \
  := append_to_snumeric_array(lat_verts_unstruc, grid_info@lat_halo_verts_all_tiles_unstruc)

  lon_bdy := append_to_snumeric_array(lon_bdy, grid_info@lon_halo_bdy_all_tiles)
  lat_bdy := append_to_snumeric_array(lat_bdy, grid_info@lat_halo_bdy_all_tiles)

  grid_opts@plot_gridlines \
  := array_append_record(grid_opts@plot_gridlines, halo@plot_gridlines, 0)
  grid_opts@gridline_colors \
  := array_append_record(grid_opts@gridline_colors, halo@gridline_color, 0)

  if (halo@plot_bdy) then
    bdy_opts@num_bdies = bdy_opts@num_bdies + 1
    bdy_opts@plot_bdy \
    := array_append_record(bdy_opts@plot_bdy, halo@plot_bdy, 0)
    bdy_opts@bdy_colors \
    := array_append_record(bdy_opts@bdy_colors, halo@bdy_color, 0)
    bdy_opts@bdy_line_thicknesses \
    := array_append_record(bdy_opts@bdy_line_thicknesses, halo@bdy_line_thickness, 0)
    bdy_opts@bdy_dash_patterns \
    := array_append_record(bdy_opts@bdy_dash_patterns, halo@bdy_dash_pattern, 0)
  end if

end if
;
; **********************************************************************
;
; If wrtcmp is set to True, read in the write-component grid.
;
; **********************************************************************
;
if (wrtcmp) then

  num_grids = num_grids + 1

  FV3LAM_wrtcmp_fn = run_dir + "/" + "dynf000.nc"
  get_domain_bdy = True
  grid_info := read_FV3LAM_grid_wrtcmp( \
               FV3LAM_wrtcmp_fn, \
               get_domain_bdy)

  nx_all := append_to_snumeric_array(nx_all, grid_info@nx)
  ny_all := append_to_snumeric_array(ny_all, grid_info@ny)

  lon_cntrs_unstruc \
  := append_to_snumeric_array(lon_cntrs_unstruc, grid_info@lon_cntrs_unstruc)
  lat_cntrs_unstruc \
  := append_to_snumeric_array(lat_cntrs_unstruc, grid_info@lat_cntrs_unstruc)

  lon_verts_unstruc \
  := append_to_snumeric_array(lon_verts_unstruc, grid_info@lon_verts_unstruc)
  lat_verts_unstruc \
  := append_to_snumeric_array(lat_verts_unstruc, grid_info@lat_verts_unstruc)

  lon_bdy := append_to_snumeric_array(lon_bdy, grid_info@lon_bdy)
  lat_bdy := append_to_snumeric_array(lat_bdy, grid_info@lat_bdy)

  grid_opts@plot_gridlines \
  := array_append_record(grid_opts@plot_gridlines, wrtcmp@plot_gridlines, 0)
  grid_opts@gridline_colors \
  := array_append_record(grid_opts@gridline_colors, wrtcmp@gridline_color, 0)

  if (wrtcmp@plot_bdy) then
    bdy_opts@num_bdies = bdy_opts@num_bdies + 1
    bdy_opts@plot_bdy \
    := array_append_record(bdy_opts@plot_bdy, wrtcmp@plot_bdy, 0)
    bdy_opts@bdy_colors \
    := array_append_record(bdy_opts@bdy_colors, wrtcmp@bdy_color, 0)
    bdy_opts@bdy_line_thicknesses \
    := array_append_record(bdy_opts@bdy_line_thicknesses, wrtcmp@bdy_line_thickness, 0)
    bdy_opts@bdy_dash_patterns \
    := array_append_record(bdy_opts@bdy_dash_patterns, wrtcmp@bdy_dash_pattern, 0)
  end if

end if

print("")
printVarSummary(wrtcmp)
;
; **********************************************************************
;
; If extrnl is set to True, read in the FV3LAM grid.
;
; **********************************************************************
;
if (extrnl) then

  num_grids = num_grids + 1

  grid_info := read_RAP_grid(RAP_grid_fn, show_RAP_bdy)

  nx_all := append_to_snumeric_array(nx_all, grid_info@nx)
  ny_all := append_to_snumeric_array(ny_all, grid_info@ny)

  lon_cntrs_unstruc \
  := append_to_snumeric_array(lon_cntrs_unstruc, grid_info@lon_cntrs_unstruc)
  lat_cntrs_unstruc \
  := append_to_snumeric_array(lat_cntrs_unstruc, grid_info@lat_cntrs_unstruc)

  lon_verts_unstruc \
  := append_to_snumeric_array(lon_verts_unstruc, grid_info@lon_verts_unstruc)
  lat_verts_unstruc \
  := append_to_snumeric_array(lat_verts_unstruc, grid_info@lat_verts_unstruc)

  lon_bdy := append_to_snumeric_array(lon_bdy, grid_info@lon_bdy)
  lat_bdy := append_to_snumeric_array(lat_bdy, grid_info@lat_bdy)

  grid_opts@plot_gridlines \
  := array_append_record(grid_opts@plot_gridlines, extrnl@plot_gridlines, 0)
  grid_opts@gridline_colors \
  := array_append_record(grid_opts@gridline_colors, extrnl@gridline_color, 0)

  if (extrnl@plot_bdy) then
    bdy_opts@num_bdies = bdy_opts@num_bdies + 1
    bdy_opts@plot_bdy \
    := array_append_record(bdy_opts@plot_bdy, extrnl@plot_bdy, 0)
    bdy_opts@bdy_colors \
    := array_append_record(bdy_opts@bdy_colors, extrnl@bdy_color, 0)
    bdy_opts@bdy_line_thicknesses \
    := array_append_record(bdy_opts@bdy_line_thicknesses, extrnl@bdy_line_thickness, 0)
    bdy_opts@bdy_dash_patterns \
    := array_append_record(bdy_opts@bdy_dash_patterns, extrnl@bdy_dash_pattern, 0)
  end if

end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
nx_all := nx_all(1:)
ny_all := ny_all(1:)
lon_cntrs_unstruc := lon_cntrs_unstruc(1:)
lat_cntrs_unstruc := lat_cntrs_unstruc(1:)
lon_verts_unstruc := lon_verts_unstruc(1:,:)
lat_verts_unstruc := lat_verts_unstruc(1:,:)
lon_bdy := lon_bdy(1:)
lat_bdy := lat_bdy(1:)
;field_unstruc := new(1, double)
;
; **********************************************************************
;
;
;
; **********************************************************************
;
n := dimsizes(grid_opts@plot_gridlines)
if (n .gt. 1) then
  grid_opts@plot_gridlines := grid_opts@plot_gridlines(1:)
  grid_opts@gridline_colors := (/ grid_opts@gridline_colors(1:) /)
end if

bdy_opts@plot_bdy := (/ bdy_opts@plot_bdy(1:) /)
bdy_opts@bdy_colors := bdy_opts@bdy_colors(1:)
bdy_opts@bdy_line_thicknesses := bdy_opts@bdy_line_thicknesses(1:)
bdy_opts@bdy_dash_patterns := bdy_opts@bdy_dash_patterns(1:)
bdy_opts@num_bdy_pts_all_bdies := 2*(nx_all + ny_all) + 1

print("")
printVarSummary(grid_opts)
print("")
printVarSummary(bdy_opts)
;
; **********************************************************************
;
;
;
; **********************************************************************
;

;grid_opts := True
;grid_opts@plot_gridlines := new(1, logical)
;grid_opts@gridline_colors := new(1, string)
;
;bdy_opts := True
;bdy_opts@num_bdies = 0
;bdy_opts@plot_bdy = new(1, logical)
;bdy_opts@bdy_colors = new(1, string)
;bdy_opts@bdy_line_thicknesses = new(1, float)
;bdy_opts@bdy_dash_patterns = new(1, integer)


;print("AAAAAA  native = " + native)
;if (native) then
;
;  grid_opts@plot_gridlines \
;  := array_append_record(grid_opts@plot_gridlines, native@plot_gridlines, 0)
;  grid_opts@gridline_colors \
;  := array_append_record(grid_opts@gridline_colors, native@gridline_color, 0)
;
;  if (native@plot_bdy) then
;    bdy_opts@num_bdies = bdy_opts@num_bdies + 1
;    bdy_opts@plot_bdy \
;    := array_append_record(bdy_opts@plot_bdy, native@plot_bdy, 0)
;    bdy_opts@bdy_colors \
;    := array_append_record(bdy_opts@bdy_colors, native@bdy_color, 0)
;    bdy_opts@bdy_line_thicknesses \
;    := array_append_record(bdy_opts@bdy_line_thicknesses, native@bdy_line_thickness, 0)
;    bdy_opts@bdy_dash_patterns \
;    := array_append_record(bdy_opts@bdy_dash_patterns, native@bdy_dash_pattern, 0)
;  end if
;
;end if

;print("AAAAAA  wrtcmp = " + wrtcmp)
;if (wrtcmp) then
;
;  grid_opts@plot_gridlines \
;  := array_append_record(grid_opts@plot_gridlines, wrtcmp@plot_gridlines, 0)
;  grid_opts@gridline_colors \
;  := array_append_record(grid_opts@gridline_colors, wrtcmp@gridline_color, 0)
;
;  if (wrtcmp@plot_bdy) then
;    bdy_opts@num_bdies = bdy_opts@num_bdies + 1
;    bdy_opts@plot_bdy \
;    := array_append_record(bdy_opts@plot_bdy, wrtcmp@plot_bdy, 0)
;    bdy_opts@bdy_colors \
;    := array_append_record(bdy_opts@bdy_colors, wrtcmp@bdy_color, 0)
;    bdy_opts@bdy_line_thicknesses \
;    := array_append_record(bdy_opts@bdy_line_thicknesses, wrtcmp@bdy_line_thickness, 0)
;    bdy_opts@bdy_dash_patterns \
;    := array_append_record(bdy_opts@bdy_dash_patterns, wrtcmp@bdy_dash_pattern, 0)
;  end if
;
;end if

;print("AAAAAA  extrnl = " + extrnl)
;if (extrnl) then
;
;  grid_opts@plot_gridlines 
;  := array_append_record(grid_opts@plot_gridlines, extrnl@plot_gridlines, 0)
;  grid_opts@gridline_colors \
;  := array_append_record(grid_opts@gridline_colors, extrnl@gridline_color, 0)
;
;  if (extrnl@plot_bdy) then
;    bdy_opts@num_bdies = bdy_opts@num_bdies + 1
;    bdy_opts@plot_bdy \
;    := array_append_record(bdy_opts@plot_bdy, extrnl@plot_bdy, 0)
;    bdy_opts@bdy_colors \
;    := array_append_record(bdy_opts@bdy_colors, extrnl@bdy_color, 0)
;    bdy_opts@bdy_line_thicknesses \
;    := array_append_record(bdy_opts@bdy_line_thicknesses, extrnl@bdy_line_thickness, 0)
;    bdy_opts@bdy_dash_patterns \
;    := array_append_record(bdy_opts@bdy_dash_patterns, extrnl@bdy_dash_pattern, 0)
;  end if
;
;end if

;print("")
;printVarSummary(grid_opts)
;
;n := dimsizes(grid_opts@plot_gridlines)
;if (n .gt. 1) then
;  grid_opts@plot_gridlines := grid_opts@plot_gridlines(1:)
;  grid_opts@gridline_colors := (/ grid_opts@gridline_colors(1:) /)
;end if
;
;bdy_opts@plot_bdy := (/ bdy_opts@plot_bdy(1:) /)
;bdy_opts@bdy_colors := bdy_opts@bdy_colors(1:)
;bdy_opts@bdy_line_thicknesses := bdy_opts@bdy_line_thicknesses(1:)
;bdy_opts@bdy_dash_patterns := bdy_opts@bdy_dash_patterns(1:)
;bdy_opts@num_bdy_pts_all_bdies = 2*(nx_all + ny_all) + 1
;
;print("")
;printVarSummary(grid_opts)
;print("")
;printVarSummary(bdy_opts)

;exit
;
; **********************************************************************
;
; Set general plotting options that will be passed to the plotting func-
; tion.
;
; **********************************************************************
;
      plot_opts := True

      plot_opts@map_proj = map_proj
      plot_opts@map_proj_ctr = map_proj_ctr
;
; Set the flag that determines whether plots will be resized (e.g. to a
; larger area than the default).  This would generally be done using the
; gsnMaximize resource, but it's not clear how to use or reset this re-
; source after adding annotations to the plot (annotations in our case
; are the plot titles).  Thus, we perform the resizing/maximization man-
; ually.
;
      plot_opts@resize_plot = True
;
; Set the size (either width or height) of the bounding box which the 
; resized plot will have.  Note that this is in NDC (non-dimensional co-
; ordinate, aka page) coordinates.  This value must be between 0 and 1.
;
      plot_opts@bounding_box_size_NDC = 0.98

      if (plot_subreg) then
        plot_opts@plot_subreg = plot_subreg
        plot_opts@subreg_limits = subreg_limits
      end if

;left_str = "AAA"
;main_str = "BBB"
;right_str = "CCC"
left_str = ""
main_str = ""
right_str = ""

      plot_opts@left_str = left_str
      plot_opts@main_str = main_str
      plot_opts@right_str = right_str
;
; **********************************************************************
;
;
;
; **********************************************************************
;
nx_big = sum(nx_all)
ny_big = sum(ny_all)
field_unstruc := new(nx_big*ny_big, double)

  field_min := min(field_unstruc)
  field_max := max(field_unstruc)

;print("field_min = " + field_min)
;print("field_max = " + field_max)
;pause

  print("")
  print("" + separator_line)
  msg := \
"Calculating " + char_dq + "nice" + char_dq + " contour values from " + \
"the field's minimum and maximum " + char_nl + \
"values ..."
  print("" + msg)

;  num_cnLevels = 20
  num_cnLevels = 250
  opts := True
;  opts@verbose = True
  opts@verbose = False
  contour_info := set_cnLevels_lbLabels( \
                  field_min, field_max, num_cnLevels, opts)
  copy_VarAtts(contour_info, plot_opts)

  print("")
  print("Done calculating " + char_dq + "nice" + char_dq + " contour values.")
  print("" + separator_line)

;  fn_graphics = cres + "_grid_f" + fcst_hr_str + "_k" + vert_indx_str
  fn_graphics = cres + "_grids"
  plot_info := plot_horiz_field( \
               fn_graphics, \
               nx_all, ny_all, \
               lon_cntrs_unstruc, lat_cntrs_unstruc, \
               lon_verts_unstruc, lat_verts_unstruc, \
               lon_bdy, lat_bdy, \
               field_unstruc, \
               grid_opts, \
               bdy_opts, \
               plot_opts)


print("")
print("BYE")
exit


end






