;
; **********************************************************************
;
; Declare global variables before loading files.  This has the same ef-
; fect as declaring these variables on the command line.
;
; **********************************************************************
;
;help = True

expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/test_latest_20191002/expt_dirs/test_sheleg_GSD_HRRR3km_01"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_GSD_HRRR13km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/suite_FV3_GSD_SAR"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/suite_FV3_GSD_SAR_3km_works03"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/suite_FV3_GSD_SAR_3km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_SUBCONUS_3km"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_CONUS_25km_GFDLgrid"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_CONUS_3km_GFDLgrid"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_AK_3km"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_AK_13km"
;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_predef_grids/expt_dirs/try01/grid_RRFS_AK_13km_old001"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try01/grid_RRFS_CONUS_13km_HRRRX_RAPX"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try01/grid_RRFS_CONUS_3km_FV3GFS_FV3GFS"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try03/grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"
expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_bugfix_adjust_CONUS_grids/expt_dirs/try03/grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"

expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_maximize_CONUS_grids/expt_dirs/try01/grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"

;expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_maximize_CONUS_grids/expt_dirs/try01/grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"

expt_dir = "/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/PR_feature_maximize_CONUS_grids/expt_dirs/try01/grid_RRFS_CONUS_3km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2"

;
; **********************************************************************
;
; Load external files.
;
; **********************************************************************
;
lib_location = "lib/"

loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "strcmp_exact.ncl")

load "calc_wrtcmp_grid_params_rotated_latlon.ncl"
load "calc_wrtcmp_grid_params_lambert_cnfrml.ncl"
load "read_FV3LAM_grid_native.ncl"

begin
;
; **********************************************************************
;
; Set the name of the current script or function.  We have to do this
; manually because NCL does not seem to have a built-in method of ob-
; taining this information.
;
; **********************************************************************
;
  curnt_script_proc_func_name := "find_wrtcmp_grid_params(...)"
;
; **********************************************************************
;
; Set usage message.
;
; **********************************************************************
;
  usage_msg = \
"  ncl -n find_wrtcmp_grid_params.ncl \" + char_nl + \
"      need to fill in the rest of this message"
;
; **********************************************************************
;
; Set help message.  The help message contains the documentation for 
; this script and thus should reflect any changes to the code.
;
; **********************************************************************
;
  help_msg = char_nl + \
"Need to fill in this help message."
;
; **********************************************************************
;
; If the variable "help" is specified on the command line and is set to
; True, print out the help message and exit.
;
; **********************************************************************
;
  if (isvar("help")) then
    if (help .eq. True) then
      print("" + help_msg)
      exit
    end if
  else
    help = False
  end if
;
; **********************************************************************
;
; Set the full path to the varible defintions file for this experiment.  
; Then read various parameters from it.
;
; **********************************************************************
;
  var_defns_fp = expt_dir + "/var_defns.sh"

  param_names = (/ \
"MODEL_CONFIG_TMPL_FP", \
"WRTCMP_output_grid", \
"GTYPE", \
"CRES", \
"ESGgrid_DELX", \
"ESGgrid_DELY", \
"NH4" /)

  num_params = dimsizes(param_names)
  do np=0, num_params-1
print("np = " + np)

    param_name = param_names(np)
    regex_search = "^\s*" + param_name + "=(" + char_dq + "([^" \
                 + char_dq + "]+)" + char_dq + "|([^ " + char_dq + "]+))(.*)$"
    regex_print = "\2\3"
    sed_cmd = "sed --regexp-extended --silent --expression " + char_sq \
            + "s/" + regex_search + "/" + regex_print + "/p" + char_sq \
            + " " + var_defns_fp
    sed_output = systemfunc(sed_cmd)
print("sed_output = " + sed_output)
;
; Convert the output from the sed command (which will be a string) to 
; the appropriate NCL data type.
;
    if (strcmp_exact(param_name, "MODEL_CONFIG_TMPL_FP")) then
      MODEL_CONFIG_TMPL_FP = tostring(sed_output)
    else if (strcmp_exact(param_name, "WRTCMP_output_grid")) then
      WRTCMP_output_grid = tostring(sed_output)
    else if (strcmp_exact(param_name, "GTYPE")) then
      GTYPE = tostring(sed_output)
    else if (strcmp_exact(param_name, "CRES")) then
      CRES = tostring(sed_output)
    else if (strcmp_exact(param_name, "ESGgrid_DELX")) then
      dx_native = todouble(sed_output)
;dx_native = 25122.693954919   ; Need if using the CONUS_25km_GFDLgrid grid
;dx_native = 2964.19334212185  ; Need if using the CONUS_3km_GFDLgrid grid
    else if (strcmp_exact(param_name, "ESGgrid_DELY")) then
      dy_native = todouble(sed_output)
;dy_native = 25122.693954919   ; Need if using the CONUS_25km_GFDLgrid grid
;dy_native = 2964.19334212185  ; Need if using the CONUS_3km_GFDLgrid grid
    else if (strcmp_exact(param_name, "NH4")) then
      nhalo_T7 = tointeger(sed_output)
    else

      msg := char_nl + \
"ERROR:  " + curnt_script_proc_func_name + ":" + char_nl + \
"The data type to convert the current variable defintions file parameter" + char_nl + \
"to has not been spedified:" + char_nl + \
"  param_name = " + char_dq + param_name + char_dq + char_nl + \
"Stopping." + char_nl
      print("" + msg)
      exit

    end if
    end if
    end if
    end if
    end if
    end if
    end if

  end do
;
; **********************************************************************
;
; Check that GTYPE has the proper value.
;
; **********************************************************************
;
print("AAAAAAAAAAAAAAAAAAAAAAAAAAA")
  if (strcmp_exact(GTYPE, "regional")) then

    inds_tiles_to_plot = (/ 7 /)

  else

    msg := char_nl + \
"ERROR:  " + curnt_script_proc_func_name + ":" + char_nl + \
"This script is designed to handle only regional grids.  Thus, GTYPE" + char_nl + \
"may only be set to " + char_dq + "regional" + char_dq + ":" + char_nl + \
"  GTYPE = " + char_dq + GTYPE + char_dq + char_nl + \
"Stopping." + char_nl

    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; Read in the native FV3-LAM grid.
;
; **********************************************************************
;
print("BBBBBBBBBBBBBBBBBBBBBBBBBBB")
  remove_rgnl_halo = True
  get_tile_bdies = False

  grid_info := read_FV3LAM_grid_native( \
               expt_dir, \
               GTYPE, \
               CRES, \
               inds_tiles_to_plot, \
               get_tile_bdies, \
               nhalo_T7, \
               remove_rgnl_halo)

  lon_tile_cntr_tiles_to_plot = grid_info@lon_tile_cntr_all_tiles
  lat_tile_cntr_tiles_to_plot = grid_info@lat_tile_cntr_all_tiles

  lon_tile_corners_face_midpts_tiles_to_plot \
  = grid_info@lon_tile_corners_face_midpts_all_tiles
  lat_tile_corners_face_midpts_tiles_to_plot \
  = grid_info@lat_tile_corners_face_midpts_all_tiles

;lon_tile_corners_face_midpts_tiles_to_plot \
;= where(lon_tile_corners_face_midpts_tiles_to_plot .gt. 0.0d+0, \
;  lon_tile_corners_face_midpts_tiles_to_plot - 360.0d+0, \
;  lon_tile_corners_face_midpts_tiles_to_plot)
;print("lon_tile_corners_face_midpts_tiles_to_plot, lat_tile_corners_face_midpts_tiles_to_plot = " + \
;      lon_tile_corners_face_midpts_tiles_to_plot + ", " + lat_tile_corners_face_midpts_tiles_to_plot)
;pause
;
; **********************************************************************
;
; Extract and save into new, appropriately dimensioned variables the 
; output from the grid-read operation above.  Then call the function 
; that calculates the write-component grid parameters for a lambert-
; conformal grid that is guaranteed to lie completely inside the native
; FV3-LAM grid.
;
; **********************************************************************
;
  nn = 0

  lon_grid_cntr_native = lon_tile_cntr_tiles_to_plot(nn)
  lat_grid_cntr_native = lat_tile_cntr_tiles_to_plot(nn)

  lon_tile_corners_face_midpts_native \
  := lon_tile_corners_face_midpts_tiles_to_plot(nn,:)
  lat_tile_corners_face_midpts_native \
  := lat_tile_corners_face_midpts_tiles_to_plot(nn,:)

  angle_units = "deg"

  valid_vals_WRTCMP_output_grid \
  := (/ "rotated_latlon", "lambert_conformal" /)
;WRTCMP_output_grid = "rotated_latlon"

  if (strcmp_exact(valid_vals_WRTCMP_output_grid, WRTCMP_output_grid)) then

    if (strcmp_exact(WRTCMP_output_grid, "rotated_latlon")) then

      out := calc_wrtcmp_grid_params_rotated_latlon( \
             MODEL_CONFIG_TMPL_FP, \
             lon_grid_cntr_native, lat_grid_cntr_native, \
             lon_tile_corners_face_midpts_native, \
             lat_tile_corners_face_midpts_native, \
             dx_native, dy_native, \
             angle_units)

    else if (strcmp_exact(WRTCMP_output_grid, "lambert_conformal")) then

      out := calc_wrtcmp_grid_params_lambert_cnfrml( \
             MODEL_CONFIG_TMPL_FP, \
             lon_grid_cntr_native, lat_grid_cntr_native, \
             lon_tile_corners_face_midpts_native, \
             lat_tile_corners_face_midpts_native, \
             dx_native, dy_native, \
             angle_units)

;    else if (strcmp_exact(WRTCMP_output_grid, "rotated_latlon")) then
;
;      msg := char_nl + \
;"ERROR:  " + curnt_script_proc_func_name + ":" + char_nl + \
;"Function to calculate write-component output grid parameters for an " + char_nl + \
;"output grid of type " + char_dq + "rotated_latlon" + char_dq + " has " + \
;"not yet been written:" + char_nl + \
;"  WRTCMP_output_grid = " + char_dq + WRTCMP_output_grid + char_dq + char_nl + \
;"Stopping." + char_nl
;      print("" + msg)
;      exit

    end if
    end if

  else

    valid_vals_str := tostring(valid_vals_WRTCMP_output_grid)
    valid_vals_str := str_join(valid_vals_str, char_dq + ", " + char_dq)
    valid_vals_str := "(/ " + char_dq + valid_vals_str + char_dq + " /)"

    msg := char_nl + \
"ERROR:  " + curnt_script_proc_func_name + ":" + char_nl + \
"Specified type of write-component output grid is not currently support-" + char_nl + \
"ed:" + char_nl + \
"  WRTCMP_output_grid = " + char_dq + WRTCMP_output_grid + char_dq + char_nl + \
"Currently, this script can generate write-component parameters only for" + char_nl + \
"output grids of the following types:" + char_nl + \
"  valid_vals_WRTCMP_output_grid = " + valid_vals_str + char_nl + \
"Stopping." + char_nl
    print("" + msg)
    exit

  end if

  print("")
  print("Done calculating write-component grid parameters.")

end
