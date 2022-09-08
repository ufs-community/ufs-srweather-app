;
; **********************************************************************
;
; Load files.
;
; **********************************************************************
;
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "strpad.ncl")
loadscript(lib_location + "repeat_str.ncl")
loadscript(lib_location + "interpol_extrapol_linear.ncl")
loadscript(lib_location + "calc_rotated_sphr_coords_from_sphr.ncl")
loadscript(lib_location + "calc_sphr_coords_from_rotated_sphr.ncl")
loadscript(lib_location + "convert_from_to_sphr_coords_to_from_rotated_sphr.ncl")

undef("calc_wrtcmp_grid_params_rotated_latlon")

function calc_wrtcmp_grid_params_rotated_latlon( \
         model_config_tmpl_fp:string, \
         lon_ctr_native:snumeric, lat_ctr_native:snumeric, \
         lon_tile_corners_face_midpts_native[8]:snumeric, \
         lat_tile_corners_face_midpts_native[8]:snumeric, \
         lon_bdy_native[*]:snumeric, \
         lat_bdy_native[*]:snumeric, \
         nx_native:snumeric, ny_native:snumeric, \
         dx_native:snumeric, dy_native:snumeric, \
         angle_units:string)

local lon_ctr, lat_ctr, lat1, lat2, \
      x_SW_native, y_SW_native, \
      num_gap_cells, \
      dx, x_SW, x_NE, Lx, Lx_ovr_dx, nx, frac_x, x_increment, \
      dy, y_SW, y_NE, Ly, Ly_ovr_dy, ny, frac_y, y_increment, \
      sphr_coords, lon_SW, lat_SW, \
      param_names, num_params, param_names_and_vals, trailing_comments, \ 
      np, param_name, param_value, param_value_str, \
      regex_search, regex_print, sed_cmd, \
      fmt_str, msg, \
      str_lens, str_len_max, num_delimit_spaces, delimit_spaces, \
      lines_final, regex_replace, sed_output, \
      out

begin
;
; **********************************************************************
;
; If not already defined, define the string (separator_line) that serves
; as a separator line between different sections of printout.
;
; **********************************************************************
;
  if (.not. isvar("separator_line")) then
    separator_line := repeat_str("=", 72)
  end if
;
; **********************************************************************
;
; Set the coordinates of the center of the write-component output grid
; to be equal to those of the native grid.  Also, set the latitudes de-
; fining the two standard parallels of the Lambert conformal projection
; used by the output grid to the latitude of the output grid center.
;
; **********************************************************************
;
  lon_ctr = lon_ctr_native
  lat_ctr = lat_ctr_native
;
; **********************************************************************
;
; The following is a manual intervention to ensure that the first elements
; of lon_tile_corners_face_midpts_native and lat_tile_corners_face_midpts_native
; represent the southwest corner of the grid.  If that is already the case,
; i_start should be set to 0.
;
; Note that this will not be the case for a GFDLgrid type of grid because
; for that case, tile 6 on which the regional grid (tile 7) is based starts
; its numbering such that the northeast corner of the tile is (i,j) = (0,0),
; and i increases going west while j increases going south.  For that case,
; i_start must be set to 4 (since the northwest corner is the first element
; and thus has an index of 0, so we have to march four points forward -
; to the midpoint of the north face, then to the northwest corner, then 
; to the midpoint of the west face, and finally to the southwest corner).
;
; The following may also be needed for grids (of either GFDLgrid or ESGgrid
; type) that straddle the international date line (which is the case if
; they include one or the other pole).  The RAP domain is such an example.
; In such cases, the order of the coordinates must be manually verified 
; and possbily fixed using the code below.
;
; **********************************************************************
;
if (False)
;if (True)

print("")
print("(lon_tile_corners_face_midpts_native, lat_tile_corners_face_midpts_native) = " + \
      lon_tile_corners_face_midpts_native + ", " + \
      lat_tile_corners_face_midpts_native)
pause

  i_start = 4

  nn = dimsizes(lon_tile_corners_face_midpts_native)
  i_end = i_start + nn - 1

  i_vec = ispan(i_start, i_end, 1)
  i_vec = where(i_vec .gt. nn-1, i_vec - nn, i_vec)

  lon_tile_corners_face_midpts_native := lon_tile_corners_face_midpts_native(i_vec)
  lat_tile_corners_face_midpts_native := lat_tile_corners_face_midpts_native(i_vec)
print("")
print("(lon_tile_corners_face_midpts_native, lat_tile_corners_face_midpts_native) = " + \
      lon_tile_corners_face_midpts_native + ", " + \
      lat_tile_corners_face_midpts_native)
pause

end if
;
; **********************************************************************
;
; Calculate the rotated spherical coordinates of the southwest corner of 
; the native grid from its spherical coordinates.
;
; **********************************************************************
;
;print("")
;print("(lon_tile_corners_face_midpts_native, lat_tile_corners_face_midpts_native) = " + \
;      lon_tile_corners_face_midpts_native + ", " + \
;      lat_tile_corners_face_midpts_native)
;pause

  rotated_sphr_coords \
  := convert_from_to_sphr_coords_to_from_rotated_sphr( \               
     lon_ctr, lat_ctr, angle_units, 1, \                              
     lon_tile_corners_face_midpts_native, \
     lat_tile_corners_face_midpts_native)
  x_tile_corners_face_midpts_native = rotated_sphr_coords@lon_out
  y_tile_corners_face_midpts_native = rotated_sphr_coords@lat_out

  rotated_sphr_coords \
  := convert_from_to_sphr_coords_to_from_rotated_sphr( \               
     lon_ctr, lat_ctr, angle_units, 1, \                              
     lon_bdy_native, \
     lat_bdy_native)
  x_bdy_native = rotated_sphr_coords@lon_out
  y_bdy_native = rotated_sphr_coords@lat_out

;print("")
;print("(x_tile_corners_face_midpts_native, y_tile_corners_face_midpts_native) = " + \
;      x_tile_corners_face_midpts_native + ", " + \
;      y_tile_corners_face_midpts_native)
;pause

  i = 0
  x_SW_native = x_tile_corners_face_midpts_native(i)
  y_SW_native = y_tile_corners_face_midpts_native(i)

  i = i + 1
  x_S_native = x_tile_corners_face_midpts_native(i)
  y_S_native = y_tile_corners_face_midpts_native(i)

  i = i + 1
  x_SE_native = x_tile_corners_face_midpts_native(i)
  y_SE_native = y_tile_corners_face_midpts_native(i)

  i = i + 1
  x_E_native = x_tile_corners_face_midpts_native(i)
  y_E_native = y_tile_corners_face_midpts_native(i)
  
  i = i + 1
  x_NE_native = x_tile_corners_face_midpts_native(i)
  y_NE_native = y_tile_corners_face_midpts_native(i)

  i = i + 1
  x_N_native = x_tile_corners_face_midpts_native(i)
  y_N_native = y_tile_corners_face_midpts_native(i)

  i = i + 1
  x_NW_native = x_tile_corners_face_midpts_native(i)
  y_NW_native = y_tile_corners_face_midpts_native(i)

  i = i + 1
  x_W_native = x_tile_corners_face_midpts_native(i)
  y_W_native = y_tile_corners_face_midpts_native(i)
;
; **********************************************************************
;
;
;
; **********************************************************************
;

; Calculate grid size in degrees along the rotated spherical coordinates.
  dx = (dx_native/rad_Earth)*degs_per_rad
  dy = (dy_native/rad_Earth)*degs_per_rad

  num_margin_cells = 1
;  num_margin_cells = 5
;  num_margin_cells = 100
;
; **********************************************************************
;
; Reduce the extent of the write-component grid in both the positive and
; negative x directions until the latitude of the center of the west 
; face of the write-component grid is greater than that of the native 
; grid, and the latitude of the center of the east face of the write-
; component grid is less than that of the native grid (i.e. the write-
; component grid lies within the native grid in the x direction).  Then,
; as an extra safety measure, reduce each of these extents by a further
; nc_reduce_extra_max cells of size dx.
;
; **********************************************************************
;
  x_W_native_max = max((/x_SW_native, x_W_native, x_NW_native/))
  x_E_native_min = min((/x_SE_native, x_E_native, x_NE_native/))

  x_W = x_W_native_max + num_margin_cells*dx
  x_E = x_E_native_min - num_margin_cells*dx

  Lx = x_E - x_W
  Lx_ovr_dx = Lx/dx
  nx = tointeger(Lx_ovr_dx)
  frac_x = Lx_ovr_dx - nx
  x_adj = (0.5d+0*frac_x)*dx
  x_W = x_W + x_adj
  x_E = x_E - x_adj
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  y_S_native_max = max((/y_SW_native, y_S_native, y_SE_native/))
  y_N_native_min = min((/y_NW_native, y_N_native, y_NE_native/))

;
; The following code is for the case in which in the xy-plane [i.e. in the 
; lonp-latp plane, where lonp and latp are the rotated latlon coordinates
; (with the "p" indicating "prime")] the left and right boundaries are 
; concave (bow into the domain) and the bottom and top boundaries are
; convex (bow out of the domain).  It allows the write-component domain
; in the y (i.e. latp) direction to be slightly larger by calculating 
; the lower and upper bounds of the domain in a less conservative way.
; This needs to be generalized to cases in which the left and right
; boundaries are convex and the bottom and top boundaries are convex.
;
; This code (after generalization) needs to be included in the file
; calc_wrtcmp_grid_params_lambert_cnfrml.ncl.
;
if (True) then
;if (False) then

  if ((y_S_native .lt. y_SW_native) .and. (y_S_native .lt. y_SE_native)) then

    indx_start = 0
    indx_end = indx_start + nx_native
    x_bdy_native_bot := x_bdy_native(indx_start:indx_end)
    y_bdy_native_bot := y_bdy_native(indx_start:indx_end)

    inds_sort := dim_pqsort(x_bdy_native_bot, 2)
    y_bdy_native_bot := y_bdy_native_bot(inds_sort)

    indx_nearest = ind_nearest_coord(x_W_native_max, x_bdy_native_bot, 0)
    if (x_W_native_max .lt. x_bdy_native_bot(indx_nearest)) then
      indx_1 = indx_nearest - 1
      indx_2 = indx_nearest
    else if (x_W_native_max .ge. x_bdy_native_bot(indx_nearest)) then
      indx_1 = indx_nearest
      indx_2 = indx_nearest + 1
    end if
    end if

;    y_S_native_max_linear := interpol_extrapol_linear( \
;                     x_SW_native, y_SW_native, \
;                     x_S_native, y_S_native, \
;                     x_W_native_max)
    y_S_native_max = interpol_extrapol_linear( \
                     x_bdy_native_bot(indx_1), y_bdy_native_bot(indx_1), \
                     x_bdy_native_bot(indx_2), y_bdy_native_bot(indx_2), \
                     x_W_native_max)
;print("NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN")
;print("y_S_native_max_linear = " + y_S_native_max_linear)
;print("y_S_native_max = " + y_S_native_max)
;pause

  end if


  if ((y_N_native .gt. y_NW_native) .and. (y_N_native .gt. y_NE_native)) then

    indx_start = nx_native + ny_native
    indx_end = indx_start + nx_native
    x_bdy_native_top := x_bdy_native(indx_start:indx_end)
    y_bdy_native_top := y_bdy_native(indx_start:indx_end)

    inds_sort := dim_pqsort(x_bdy_native_top, 2)
    y_bdy_native_top := y_bdy_native_top(inds_sort)

    indx_nearest = ind_nearest_coord(x_W_native_max, x_bdy_native_top, 0)
    if (x_W_native_max .lt. x_bdy_native_top(indx_nearest)) then
      indx_1 = indx_nearest - 1
      indx_2 = indx_nearest
    else if (x_W_native_max .ge. x_bdy_native_top(indx_nearest)) then
      indx_1 = indx_nearest
      indx_2 = indx_nearest + 1
    end if
    end if

;    y_N_native_min_linear := interpol_extrapol_linear( \
;                     x_NW_native, y_NW_native, \
;                     x_N_native, y_N_native, \
;                     x_W_native_max)
    y_N_native_min = interpol_extrapol_linear( \
                     x_bdy_native_top(indx_1), y_bdy_native_top(indx_1), \
                     x_bdy_native_top(indx_2), y_bdy_native_top(indx_2), \
                     x_W_native_max)
;print("NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN")
;print("y_N_native_min_linear = " + y_N_native_min_linear)
;print("y_N_native_min = " + y_N_native_min)
;pause

  end if

end if



  y_S = y_S_native_max + num_margin_cells*dy
  y_N = y_N_native_min - num_margin_cells*dy
print("")
print("y_S = " + y_S)
print("y_N = " + y_N)

  y_S = -min(abs((/y_S, y_N/)))
  y_N = -y_S

  Ly = y_N - y_S
  Ly_ovr_dy = Ly/dy
  ny = tointeger(Ly_ovr_dy)
  frac_y = Ly_ovr_dy - ny
  y_adj = (0.5d+0*frac_y)*dy
  y_S = y_S + y_adj
  y_N = y_N - y_adj
;
; **********************************************************************
;
; Calculate the spherical coordinates of the southwest corner of the 
; native grid from its rotated latlon coordinates.
;
; **********************************************************************
;
  lon_ctr_ll_cell = x_W + 0.5*dx
  lat_ctr_ll_cell = y_S + 0.5*dy

  lon_ctr_ur_cell = x_E - 0.5*dx
  lat_ctr_ur_cell = y_N - 0.5*dy

;  dlon = dx*degs_per_rad
;  dlat = dy*degs_per_rad

  dlon = dx
  dlat = dy

;  sphr_coords \
;  := calc_sphr_coords_from_rotated_sphr( \
;     lon_ctr, lat_ctr, lat1, lat2, rad_Earth, angle_units, \
;     x_W, y_S)
;  lon_SW = sphr_coords@lon
;  lat_SW = sphr_coords@lat
;
; **********************************************************************
;
; Create a string array containing the names of the Lambert conformal
; output grid parameters that appear in the NEMS model_configure file.
;
; **********************************************************************
;
  param_names = (/ \
    "output_grid", \
    "cen_lon", \
    "cen_lat", \
    "lon1", \
    "lat1", \
    "lon2", \
    "lat2", \
    "dlon", \
    "dlat" /)
;
; **********************************************************************
;
; Get the number of Lambert conformal output grid parameters that need 
; to be se tin the NEMS model_configure file.  Then initialize string 
; arrays needed in setting these parameters.
;
; **********************************************************************
;
  num_params = dimsizes(param_names)
  param_names_and_vals := new(num_params, "string")
  trailing_comments := new(num_params, "string")
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  np = 0
  param_name = param_names(np)
  param_value := char_sq + "rotated_latlon" + char_sq
  param_value_str := tostring(param_value)

  regex_search = "^(\s*" + param_name + ":\s+)('\{\{\s*" + param_name + "\s*\}\}')(\s*)(.*)"

  regex_print = "\1" + param_value_str
  sed_cmd = "sed -n -r -e " + char_dq + "s|" + regex_search + "|" \
          + regex_print + "|p" + char_dq + " " + model_config_tmpl_fp
  param_names_and_vals(np) = systemfunc(sed_cmd)

  regex_print = "\4"
  sed_cmd = "sed -n -r -e " + char_dq + "s|" + regex_search + "|" \
          + regex_print + "|p" + char_dq + " " + model_config_tmpl_fp
  trailing_comments(np) = systemfunc(sed_cmd)
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  do np=1, num_params-1

    param_name := param_names(np)

    if (strcmp_exact(param_name, "cen_lon")) then
      param_value := lon_ctr
      fmt_str = "%16.8f"
    else if (strcmp_exact(param_name, "cen_lat")) then
      param_value := lat_ctr
      fmt_str = "%16.8f"
    else if (strcmp_exact(param_name, "lon1")) then
      param_value := lon_ctr_ll_cell
      fmt_str = "%16.8f"
    else if (strcmp_exact(param_name, "lat1")) then
      param_value := lat_ctr_ll_cell
      fmt_str = "%16.8f"
    else if (strcmp_exact(param_name, "lon2")) then
      param_value := lon_ctr_ur_cell
      fmt_str = "%16.8f"
    else if (strcmp_exact(param_name, "lat2")) then
      param_value := lat_ctr_ur_cell
      fmt_str = "%16.8f"
    else if (strcmp_exact(param_name, "dlon")) then
      param_value := dlon
      fmt_str = "%16.8f"
    else if (strcmp_exact(param_name, "dlat")) then
      param_value := dlat
      fmt_str = "%16.8f"
    else

      msg := char_nl + \
"Unknown parameter name specified for given output_coord_sys:" + char_nl + \
"  output_coord_sys = " + char_dq + output_coord_sys + char_dq + char_nl + \
"  param_name = " + char_dq + param_name + char_dq + char_nl + \
"Stopping."
      print("" + msg)
      exit

    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
;
; Generate a string containing the parameter value and formatted as spe-
; cified by fmt_str.  Then strip any leading and trailing whitespace
; from it.
;
    param_value_str := sprintf(fmt_str, param_value)
    param_value_str := str_strip(param_value_str)
;
; Set the regular expression to search for.
;
    regex_search = "^(\s*" + param_name + ":\s+)(\{\{\s*" + param_name + "\s*\}\})(\s*)(.*)"
;
; Get the parameter name and value without the trailing comment (if any).
;
    regex_print = "\1" + param_value_str
    sed_cmd = "sed -n -r -e " + char_dq + "s|" + regex_search + "|" \
            + regex_print + "|p" + char_dq + " " + model_config_tmpl_fp
    tmp := systemfunc(sed_cmd)
    param_names_and_vals(np) = tmp(0)
;
; Get the trailing name and comment.
;
    regex_print = "\4"
    sed_cmd = "sed -n -r -e " + char_dq + "s|" + regex_search + "|" \
            + regex_print + "|p" + char_dq + " " + model_config_tmpl_fp
    tmp := systemfunc(sed_cmd)
    trailing_comments(np) = tmp(0)

  end do
;
; **********************************************************************
;
; Generate a string array containing each line in the model_configure
; file that specifies a parameter describing the write-component output
; grid.  Each such line will contain the parameter name, value, and an
; trailing comment, with the trailing comments aligned for readability.
;
; **********************************************************************
;
  lines_final := strpad(param_names_and_vals, " ", "right")
  lines_final := lines_final + "  " + trailing_comments
;
; **********************************************************************
;
; Print out the write-component parameter values calculated above.
;
; **********************************************************************
;
  msg := char_nl + \
"Write-component parameters corresponding to this native grid are:" + char_nl
  print("" + msg)
  print("" + lines_final)
;
; **********************************************************************
;
; Loop through the set of parameters and find the line in the template
; file where each is set.  Then replace that line with the corresponding
; line generated above containing the parameter name, its value, and the
; optional aligned comment.
;
; **********************************************************************
;
  do np=0, num_params-1
    param_name = param_names(np)
    regex_search = "^(\s*" + param_name + ":\s+)(<" + param_name + ">)(\s*)(.*)"
    regex_replace = lines_final(np)
    sed_cmd = "sed -i -r -e " + char_dq + "s|" + regex_search + "|" \
            + regex_replace + "|" + char_dq + " " + model_config_tmpl_fp
    sed_output = systemfunc(sed_cmd)
  end do
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  out = True 
  return(out)

end

