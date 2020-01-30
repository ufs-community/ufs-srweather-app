;
; **********************************************************************
;
; Load files.
;
; **********************************************************************
;
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "convert_from_to_sphr_coords_to_from_rotated_sphr.ncl")
loadscript(lib_location + "convert_sphr_coords_to_lambert_cnfrml.ncl")
loadscript(lib_location + "convert_lambert_cnfrml_coords_to_sphr.ncl")

undef("get_wrtcmp_grid")

function get_wrtcmp_grid( \
         wrtcmp_config_fn:string, \
         get_domain_bdy:logical)

local proj_params, \
      var_name, regex_search, regex_print, sed_cmd, \
      wrtcmp_coord_sys, valid_vals_wrtcmp_coord_sys, valid_vals, msg, \
      param_names, coord_data_type, num_params, param_name, \
      lon_ctr_rad, lat_ctr_rad, lat1_rad, lat2_rad, \
      nxm, nyp, lon_cell_cntr_SW, lat_cell_cntr_SW, dx, dy, \ 
      angle_units, \
      nx, ny, lambert_coords, x_cell_cntr_SW, y_cell_cntr_SW, \
      i_vec, j_vec, x_verts_vec, y_verts_vec, x_verts, y_verts, \
      sphr_coords, lon_verts, lat_verts, \
      x_cntrs, y_cntrs, lon_cntrs, lat_cntrs, \
      lon_cntrs_unstruc, lat_cntrs_unstruc, \
      lon_verts_unstruc, lat_verts_unstruc, \
      x_is_longitude, opts, corner_info, corner_lons, corner_lats, \
      fmt_str, lon_str, lat_str, \
      rem_nx, rem_ny, i_cntr, j_cntr, lon_grid_cntr, lat_grid_cntr

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
; Get the coordinate system in which the write-component output grid is 
; specified.
;
; **********************************************************************
;
  var_name = "output_grid"
  regex_search = "^\s*" + var_name + ":\s*'([^ #]*)'.*$"
  regex_print = "\1"
  sed_cmd = "sed -r -n -e " + char_dq + "s|" + regex_search + "|" \
          + regex_print + "|p" + char_dq + " " + wrtcmp_config_fn
  wrtcmp_coord_sys = systemfunc(sed_cmd)
;
; **********************************************************************
;
; Check that the output coordinate system read in above is valid.
;
; **********************************************************************
;
  valid_vals_wrtcmp_coord_sys = (/ "rotated_latlon", "lambert_conformal" /)

  if (.not. strcmp_exact(valid_vals_wrtcmp_coord_sys, wrtcmp_coord_sys)) then

    valid_vals \
    := char_dq \
    + str_join(valid_vals_wrtcmp_coord_sys, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"The coordinate system in which the write-component output grid is spe-" + char_nl + \
"cified (wrtcmp_coord_sys) has not been set to a valid value:" + char_nl + \
"  wrtcmp_coord_sys = " + char_dq + wrtcmp_coord_sys + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Please rerun with a valid grid type.  Stopping."
    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; Print out the coordinate system used by the output grid.
;
; **********************************************************************
;
  msg := char_nl + \
"The coordinate system in which the write-component output grid is spe-" + char_nl + \
"cified (wrtcmp_coord_sys) is:" + char_nl + \
"  wrtcmp_coord_sys = " + char_dq + wrtcmp_coord_sys + char_dq + char_nl
  print("" + msg)
;
; **********************************************************************
;
; Set the names of the parameters in the write component configuration
; file that determine the transformation from spherical coordinates to
; the output coordinate system specified above (and vice versa). 
;
; **********************************************************************
;
  if (strcmp_exact(wrtcmp_coord_sys, "rotated_latlon")) then

    param_names = (/ \
      "cen_lon", \
      "cen_lat", \
      "lon1", \
      "lat1", \
      "lon2", \
      "lat2", \
      "dlon", \
      "dlat" /)

  else if (strcmp_exact(wrtcmp_coord_sys, "lambert_conformal")) then

    param_names = (/ \
      "cen_lon", \
      "cen_lat", \
      "stdlat1", \
      "stdlat2", \
      "nx", \
      "ny", \
      "lon1", \
      "lat1", \
      "dx", \
      "dy" /)

  else

    msg := char_nl + \
"param_names has not been set for this value of the write-component out-" + char_nl + \
"put grid coordinate system (wrtcmp_coord_sys):" + char_nl + \
"  wrtcmp_coord_sys = " + char_dq + wrtcmp_coord_sys + char_dq + char_nl + \
"Stopping."
    print("" + msg)
    exit

  end if
  end if
;
; **********************************************************************
;
; Set the data type (i.e. float or double) of the coordinate arrays for
; the write-component output grid to be "double".  Note that here, we 
; are constructing this grid from the "grid" parameters, so we can choose 
; this data type to be whatever we like (i.e. "float" or "double").
;
; **********************************************************************
;
  coord_data_type = "double"
;
; **********************************************************************
;
; Loop through the list of coordinate system parameters specified above
; and get the value of each from the write-component configuration file.
;
; **********************************************************************
;
  num_params = dimsizes(param_names)

  msg = char_nl + \
"Reading in write-component output grid coordinate system parameters " + char_nl + \
"from file wrtcmp_config_fn:" + char_nl + \
"  wrtcmp_config_fn = " + char_dq + wrtcmp_config_fn + char_dq 

  do np=0, num_params-1

    param_name = param_names(np)
    regex_search = "^\s*" + param_name + ":\s*([^ #]*).*$"
    regex_print = "\1"
    sed_cmd = "sed -r -n -e " + char_dq + "s|" + regex_search + "|" \
            + regex_print + "|p" + char_dq + " " + wrtcmp_config_fn
    sed_output = systemfunc(sed_cmd)

    unrecognized_param = False

    if (strcmp_exact(wrtcmp_coord_sys, "rotated_latlon")) then

      if (strcmp_exact(param_name, "cen_lon")) then
        lon_ctr := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "cen_lat")) then
        lat_ctr := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "lon1")) then
        rot_lon_cell_cntr_SW := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "lat1")) then
        rot_lat_cell_cntr_SW := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "lon2")) then
        rot_lon_cell_cntr_NE := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "lat2")) then
        rot_lat_cell_cntr_NE := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "dlon")) then
        dlon := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "dlat")) then
        dlat := totype(sed_output, coord_data_type)
      else
        unrecognized_param = True
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if

    else if (strcmp_exact(wrtcmp_coord_sys, "lambert_conformal")) then

      if (strcmp_exact(param_name, "cen_lon")) then
        lon_ctr := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "cen_lat")) then
        lat_ctr := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "stdlat1")) then
        lat1 := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "stdlat2")) then
        lat2 := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "nx")) then
        nx := totype(sed_output, "integer")
      else if (strcmp_exact(param_name, "ny")) then
        ny := totype(sed_output, "integer")
      else if (strcmp_exact(param_name, "lon1")) then
        lon_cell_cntr_SW := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "lat1")) then
        lat_cell_cntr_SW := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "dx")) then
        dx := totype(sed_output, coord_data_type)
      else if (strcmp_exact(param_name, "dy")) then
        dy := totype(sed_output, coord_data_type)
      else
        unrecognized_param = True
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if

    else

      msg := char_nl + \
"Grid parameters have not yet been specified for this value of the " + char_nl + \
"write-component output grid coordinate system (wrtcmp_coord_sys):" +  char_nl + \
"  wrtcmp_coord_sys = " + char_dq + wrtcmp_coord_sys + char_dq + char_nl + \
"Stopping."
      print("" + msg)
      exit

    end if
    end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
    if (unrecognized_param) then

      msg := char_nl + \
"Unknown parameter name specified for the given write-component output" + char_nl + \
"grid coordinate system (wrtcmp_coord_sys):" + char_nl + \
"  wrtcmp_coord_sys = " + char_dq + wrtcmp_coord_sys + char_dq + char_nl + \
"  param_name = " + char_dq + param_name + char_dq + char_nl + \
"Stopping."
      print("" + msg)
      exit

    end if

  end do



  if (strcmp_exact(wrtcmp_coord_sys, "rotated_latlon")) then
    dx = dlon
    dy = dlat
    nx = (rot_lon_cell_cntr_NE - rot_lon_cell_cntr_SW)/dlon + 1
    nx := round(nx, 3)
    ny = (rot_lat_cell_cntr_NE - rot_lat_cell_cntr_SW)/dlat + 1
    ny := round(ny, 3)
print("")
print("nx = " + nx)
print("ny = " + ny)
pause
  end if

;
; **********************************************************************
;
; Print out values of parameters read in from the write-component con-
; figuration file.
;
; **********************************************************************
;
;  msg = char_nl + \
;"Values of write-component output grid coordinate system parameters read" + char_nl + \
;"in from the model_configure file are:"
;
;  do np=0, num_params-1
;    param_name = param_names(np)
;    param_value = $param_name$
;    msg = char_nl + \
;"  " + param_name + " = " + param_value
;  end do

;  if (strcmp_exact(wrtcmp_coord_sys, "rotated_latlon")) then
;
;  else if (strcmp_exact(wrtcmp_coord_sys, "lambert_conformal")) then
;
;    print("")
;    print("" + separator_line)
;
;    msg = char_nl + \
;"Values of write-component output grid coordinate system parameters read" + char_nl + \
;"in from the model_configure file are:" + char_nl + \
;"  lon_ctr = " + lon_ctr + char_nl + \
;"  lat_ctr = " + lat_ctr + char_nl + \
;"  lat1 = " + lat1 + char_nl + \
;"  lat2 = " + lat2 + char_nl + \
;"  nx = " + nx + char_nl + \
;"  ny = " + ny + char_nl + \
;"  lon_cell_cntr_SW = " + lon_cell_cntr_SW + char_nl + \
;"  lat_cell_cntr_SW = " + lat_cell_cntr_SW + char_nl + \
;"  dx = " + dx + char_nl + \
;"  dy = " + dy + char_nl
;    print("" + msg)
;
;  else
;
;    msg := char_nl + \
;"Grid parameters have not yet been specified for this value of the " + char_nl + \
;"write-component output grid coordinate system (wrtcmp_coord_sys):" +  char_nl + \
;"  wrtcmp_coord_sys = " + char_dq + wrtcmp_coord_sys + char_dq + char_nl + \
;"Stopping."
;    print("" + msg)
;    exit
;
;  end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  angle_units = "deg"
;
; **********************************************************************
;
; Use the given spherical coordinates (lon_cell_cntr_SW, lat_cell_cntr_-
; SW) of the southwest corner of the grid to calculate the Lambert con-
; formal coordinates (x_cell_cntr_SW, y_cell_cntr_SW) of that corner.
;
; **********************************************************************
;
  if (strcmp_exact(wrtcmp_coord_sys, "rotated_latlon")) then
    x_cell_cntr_SW = rot_lon_cell_cntr_SW
    y_cell_cntr_SW = rot_lat_cell_cntr_SW
  else if (strcmp_exact(wrtcmp_coord_sys, "lambert_conformal")) then
    lambert_cnfrml_coords \
    := convert_sphr_coords_to_lambert_cnfrml( \
       lon_ctr, lat_ctr, lat1, lat2, rad_Earth, angle_units, \
       lon_cell_cntr_SW, lat_cell_cntr_SW)
    x_cell_cntr_SW = lambert_cnfrml_coords@x 
    y_cell_cntr_SW = lambert_cnfrml_coords@y
  end if
  end if

  x_min = x_cell_cntr_SW - 0.5d+0*dx
  y_min = y_cell_cntr_SW - 0.5d+0*dy
;
; **********************************************************************
;
; Construct the vectors defining the locations of the grid cell vertices
; in the plane of the Lambert conformal coordinates (x,y).  Note that 
; the write-component output grid is uniform in that plane.
;
; **********************************************************************
;
  i_vec := ispan(0, nx, 1)
  j_vec := ispan(0, ny, 1)

  x_verts_vec := dx*i_vec + x_min
  y_verts_vec := dy*j_vec + y_min
;
; **********************************************************************
;
; Create arrays containing the Lambert conformal coordinates of the cell
; vertices of a uniform grid in the (x,y)-plane.
;
; **********************************************************************
;
  x_verts_vec := transpose(transpose(x_verts_vec))
  x_verts = x_verts_vec
  do j=1, ny
    x_verts := array_append_record(x_verts, x_verts_vec, 0)
  end do

  y_verts_vec := transpose(transpose(y_verts_vec))
  y_verts = y_verts_vec
  do i=1, nx
    y_verts := array_append_record(y_verts, y_verts_vec, 0)
  end do
  y_verts := transpose(y_verts)
;
; **********************************************************************
;
; Calculate the spherical coordinates corresponding to the Lambert con-
; formal coordinates of the grid cell vertices.
;
; **********************************************************************
;
  if (strcmp_exact(wrtcmp_coord_sys, "rotated_latlon")) then
    sphr_coords \
    := convert_from_to_sphr_coords_to_from_rotated_sphr( \
       lon_ctr, lat_ctr, angle_units, -1, \
       x_verts, y_verts)
    lon_verts = sphr_coords@lon_out
    lat_verts = sphr_coords@lat_out
  else if (strcmp_exact(wrtcmp_coord_sys, "lambert_conformal")) then
    sphr_coords \
    := convert_lambert_cnfrml_coords_to_sphr( \
       lon_ctr, lat_ctr, lat1, lat2, rad_Earth, angle_units, \
       x_verts, y_verts)
    lon_verts = sphr_coords@lon
    lat_verts = sphr_coords@lat
  end if
  end if
;
; **********************************************************************
;
; Average the x and y coordinates of the cell vertices in the (x,y) 
; plane to obtain the (x,y) coordinates of the cell centers.
;
; **********************************************************************
;
  x_cntrs := 0.25d+0*( \
             x_verts(0:ny-1,0:nx-1) \
           + x_verts(0:ny-1,1:nx) \
           + x_verts(1:ny,1:nx) \
           + x_verts(1:ny,0:nx-1) \
             )

  y_cntrs := 0.25d+0*( \
             y_verts(0:ny-1,0:nx-1) \
           + y_verts(0:ny-1,1:nx) \
           + y_verts(1:ny,1:nx) \
           + y_verts(1:ny,0:nx-1) \
             )
;
; **********************************************************************
;
; Calculate the spherical coordinates corresponding to the Lambert con-
; formal coordinates of the grid cell centers.
;
; **********************************************************************
;
  if (strcmp_exact(wrtcmp_coord_sys, "rotated_latlon")) then
    sphr_coords \
    := convert_from_to_sphr_coords_to_from_rotated_sphr( \
       lon_ctr, lat_ctr, angle_units, -1, \
       x_cntrs, y_cntrs)
    lon_cntrs = sphr_coords@lon_out
    lat_cntrs = sphr_coords@lat_out
  else if (strcmp_exact(wrtcmp_coord_sys, "lambert_conformal")) then
    sphr_coords \
    := convert_lambert_cnfrml_coords_to_sphr( \
       lon_ctr, lat_ctr, lat1, lat2, rad_Earth, angle_units, \
       x_cntrs, y_cntrs)
    lon_cntrs = sphr_coords@lon
    lat_cntrs = sphr_coords@lat
  end if
  end if
;
; **********************************************************************
;
; Create arrays in unstructured format that contain the spherical coord-
; inates of the vertices of each cell on the grid.  Note that these are
; 2-D arrays whose first dimension size is the number of cells on the 
; grid (i.e. nx*ny) and whose second dimension size is 4 (since each
; cell has 4 vertices).  This unstructured format is useful in generat-
; ing color-contour plots of fields on the grid that have one value per
; cell represented by a flat color in that cell.
;
; **********************************************************************
;
  lon_cntrs_unstruc := ndtooned(lon_cntrs)
  lat_cntrs_unstruc := ndtooned(lat_cntrs)

  lon_verts_unstruc \
  := (/ ndtooned(lon_verts(0:ny-1,0:nx-1)), \
        ndtooned(lon_verts(0:ny-1,1:nx)), \
        ndtooned(lon_verts(1:ny,1:nx)), \
        ndtooned(lon_verts(1:ny,0:nx-1)) /)
  lon_verts_unstruc := transpose(lon_verts_unstruc)

  lat_verts_unstruc \
  := (/ ndtooned(lat_verts(0:ny-1,0:nx-1)), \
        ndtooned(lat_verts(0:ny-1,1:nx)), \
        ndtooned(lat_verts(1:ny,1:nx)), \
        ndtooned(lat_verts(1:ny,0:nx-1)) /)
  lat_verts_unstruc := transpose(lat_verts_unstruc)
;
; **********************************************************************
;
; If get_domain_bdy is specified to be True, save in a pair of 1-D ar-
; rays the spherical coordinates of those cell vertices that lie on the
; boundary of the grid.
;
; **********************************************************************
;
  if (get_domain_bdy) then
    repeat_last_point = True
    array_order = "ji"
    bdy_info := get_rect_grid_bdy( \
                lon_verts, lat_verts, \
                repeat_last_point, array_order)
    lon_bdy := bdy_info@x_bdy
    lat_bdy := bdy_info@y_bdy
  else
    lon_bdy := default_fillvalue(coord_data_type)
    lat_bdy := default_fillvalue(coord_data_type)
  end if
;
; **********************************************************************
;
; Find and print out the spherical coordinates of the corners of the 
; grid.
;
; **********************************************************************
;
  x_is_longitude = True
  opts := True
  opts@verbose = False
  corner_info := get_rect_grid_corners( \
                 lon_verts, lat_verts, \
                 "deg", "deg", x_is_longitude, opts)
  corner_lons := corner_info@x_corners
  corner_lats := corner_info@y_corners

  print("")
  print("  The write-component output grid's corner lon/lat coordinates are:")
  fmt_str = "%7.2f"
  do c=0, dimsizes(corner_lons)-1
    lon_str = sprintf(fmt_str, corner_lons(c))
    lat_str = sprintf(fmt_str, corner_lats(c))
    print("    Corner " + (c+1) + ":  lon = " + lon_str + " deg;  " + \
          "lat = " + lat_str + " deg")
  end do
;
; **********************************************************************
;
; Calculate the coordinates of the center of the write-component grid.
;
; **********************************************************************
;
  rem_nx = mod(nx, 2)
  rem_ny = mod(ny, 2)

  if ((rem_nx .eq. 0) .and. (rem_ny .eq. 0)) then
    i_cntr = nx/2
    j_cntr = ny/2
    lon_grid_cntr := lon_verts(j_cntr,i_cntr)
    lat_grid_cntr := lat_verts(j_cntr,i_cntr)
  else if ((rem_nx .eq. 1) .and. (rem_ny .eq. 0)) then
    i_cntr = (nx - 1)/2
    j_cntr = ny/2
    lon_grid_cntr := lon_cntrs(j_cntr,i_cntr)
    lat_grid_cntr := lat_verts(j_cntr,i_cntr)
  else if ((rem_nx .eq. 0) .and. (rem_ny .eq. 1)) then
    i_cntr = nx/2
    j_cntr = (ny - 1)/2
    lon_grid_cntr := lon_verts(j_cntr,i_cntr)
    lat_grid_cntr := lat_cntrs(j_cntr,i_cntr)
  else if ((rem_nx .eq. 1) .and. (rem_ny .eq. 1)) then
    i_cntr = (nx - 1)/2
    j_cntr = (ny - 1)/2
    lon_grid_cntr := lon_cntrs(j_cntr,i_cntr)
    lat_grid_cntr := lat_cntrs(j_cntr,i_cntr)
  end if
  end if
  end if
  end if
;
; **********************************************************************
;
; Return results as attributes of the logical variable grid_info.
;
; **********************************************************************
;
  grid_info := True

  grid_info@nx = nx
  grid_info@ny = ny
  grid_info@lon_cntrs_unstruc = lon_cntrs_unstruc
  grid_info@lat_cntrs_unstruc = lat_cntrs_unstruc
  grid_info@lon_verts_unstruc = lon_verts_unstruc
  grid_info@lat_verts_unstruc = lat_verts_unstruc
  grid_info@lon_bdy = lon_bdy
  grid_info@lat_bdy = lat_bdy
  grid_info@lon_grid_cntr = lon_grid_cntr
  grid_info@lat_grid_cntr = lat_grid_cntr
  grid_info@coord_data_type = coord_data_type

  return(grid_info)

end

