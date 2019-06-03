;
; **********************************************************************
;
; Load files.
;
; **********************************************************************
;
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "calc_lambert_cnfrml_coords_from_sphr.ncl")
loadscript(lib_location + "calc_sphr_coords_from_lambert_cnfrml.ncl")

undef("get_wrtcmp_grid")

function get_wrtcmp_grid( \
         wrtcmp_config_fn:string, \
         get_domain_bdy:logical)

local proj_params, \
      var_name, regex_search, regex_print, sed_cmd, \
      output_coord_sys, valid_vals_output_coord_sys, valid_vals, msg, \
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
; Get the coordinate system used by the write-component output grid.
;
; **********************************************************************
;
  var_name = "output_grid"
  regex_search = "^\s*" + var_name + ":\s*'([^ #]*)'.*$"
  regex_print = "\1"
  sed_cmd = "sed -r -n -e " + char_dq + "s|" + regex_search + "|" \
          + regex_print + "|p" + char_dq + " " + wrtcmp_config_fn
  output_coord_sys = systemfunc(sed_cmd)
;
; **********************************************************************
;
; Check that the output coordinate system read in above is valid.
;
; **********************************************************************
;
  valid_vals_output_coord_sys = (/ "rotated_latlon", "lambert_conformal" /)

  if (.not. strcmp_exact(valid_vals_output_coord_sys, output_coord_sys)) then

    valid_vals \
    := char_dq \
    + str_join(valid_vals_output_coord_sys, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"The ouput coordinate system (output_coord_sys) is not set to a valid " + char_nl + \
"value:" + char_nl + \
"  output_coord_sys = " + char_dq + output_coord_sys + char_dq + char_nl + \
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
"The ouput coordinate system (output_coord_sys) used by the write-compo-" + char_nl + \
"nent is:" + char_nl + \
"  output_coord_sys = " + char_dq + output_coord_sys + char_dq + char_nl
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
  if (strcmp_exact(output_coord_sys, "lambert_conformal")) then

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
"param_names has not been set for this output coordinate system:" + char_nl + \
"  output_coord_sys = " + char_dq + output_coord_sys + char_dq + char_nl + \
"Stopping."
    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; Set the data type (i.e. float or double) of the coordinate arrays for
; the write-component output grid to be "double".  Note that here, we 
; constructing this grid from the "grid" parameters, so we can choose 
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

  do np=0, num_params-1

    param_name = param_names(np)
    regex_search = "^\s*" + param_name + ":\s*([^ #]*).*$"
    regex_print = "\1"
    sed_cmd = "sed -r -n -e " + char_dq + "s|" + regex_search + "|" \
            + regex_print + "|p" + char_dq + " " + wrtcmp_config_fn
    sed_output = systemfunc(sed_cmd)

    if (strcmp_exact(param_name, "cen_lon")) then
      lon_ctr := totype(sed_output, coord_data_type)
    else if (strcmp_exact(param_name, "cen_lat")) then
      lat_ctr := totype(sed_output, coord_data_type)
    else if (strcmp_exact(param_name, "stdlat1")) then
      lat1 := totype(sed_output, coord_data_type)
    else if (strcmp_exact(param_name, "stdlat2")) then
      lat2 := totype(sed_output, coord_data_type)
    else if (strcmp_exact(param_name, "nx")) then
;      nxp := totype(sed_output, "integer")
      nx := totype(sed_output, "integer")
    else if (strcmp_exact(param_name, "ny")) then
;      nyp := totype(sed_output, "integer")
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
    end if
    end if

  end do
;
; **********************************************************************
;
; Print out values of parameters read in from the write-component con-
; figuration file.
;
; **********************************************************************
;
  if (strcmp_exact(output_coord_sys, "lambert_conformal")) then

    print("")
    print("" + separator_line)

    msg = char_nl + \
"Values of write-component output grid coordinate system parameters read" + char_nl + \
"in from the model_configure file are:" + char_nl + \
"  lon_ctr = " + lon_ctr + char_nl + \
"  lat_ctr = " + lat_ctr + char_nl + \
"  lat1 = " + lat1 + char_nl + \
"  lat2 = " + lat2 + char_nl + \
"  nx = " + nx + char_nl + \
"  ny = " + ny + char_nl + \
"  lon_cell_cntr_SW = " + lon_cell_cntr_SW + char_nl + \
"  lat_cell_cntr_SW = " + lat_cell_cntr_SW + char_nl + \
"  dx = " + dx + char_nl + \
"  dy = " + dy + char_nl
    print("" + msg)

  else

    msg := char_nl + \
"Values of write-component output grid coordinate system parameters have" + \
"not been set for this output coordinate system:" + char_nl + \
"  output_coord_sys = " + char_dq + output_coord_sys + char_dq + char_nl + \
"Stopping."
    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  angle_units = "deg"

;  nx = nxp - 1
;  ny = nyp - 1

;
; **********************************************************************
;
; Use the given spherical coordinates (lon_cell_cntr_SW, lat_cell_cntr_SW) of the southwest
; corner of the grid to calculate the Lambert conformal coordinates 
; (x_cell_cntr_SW, y_cell_cntr_SW) of that corner.
;
; **********************************************************************
;
  lambert_coords \
  := calc_lambert_cnfrml_coords_from_sphr( \
     lon_ctr, lat_ctr, lat1, lat2, rad_Earth, angle_units, \
     lon_cell_cntr_SW, lat_cell_cntr_SW)
  x_cell_cntr_SW = lambert_coords@x 
  y_cell_cntr_SW = lambert_coords@y

  x_min = x_cell_cntr_SW - 0.5d+0*dx
  y_min = y_cell_cntr_SW - 0.5d+0*dy

print("")
print("x_cell_cntr_SW = " + x_cell_cntr_SW)
print("x_min = " + x_min)
print("dx = " + dx)
print("nx = " + nx)
;print("2*x_min/dx = " + 2*x_min/dx)

print("")
print("y_cell_cntr_SW = " + y_cell_cntr_SW)
print("y_min = " + y_min)
print("dy = " + dy)
print("ny = " + ny)
;print("2*y_min/dy = " + 2*y_min/dy)
pause
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

print("")
;print("x_verts_vec = " + x_verts_vec)
print("x_verts_vec(0) = " + x_verts_vec(0))
print("x_verts_vec(nx) = " + x_verts_vec(nx))
print("(x_verts_vec(nx) - x_verts_vec(0))/dx = " + (x_verts_vec(nx) - x_verts_vec(0))/dx)
pause
print("")
;print("y_verts_vec = " + y_verts_vec)
print("y_verts_vec(0) = " + y_verts_vec(0))
print("y_verts_vec(ny) = " + y_verts_vec(ny))
print("(y_verts_vec(ny) - y_verts_vec(0))/dy = " + (y_verts_vec(ny) - y_verts_vec(0))/dy)
pause
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
  sphr_coords := calc_sphr_coords_from_lambert_cnfrml( \
                 lon_ctr, lat_ctr, lat1, lat2, rad_Earth, angle_units, \
                 x_verts, y_verts)
  lon_verts = sphr_coords@lon
  lat_verts = sphr_coords@lat
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
;print("")
;print("x_cntrs = " + x_cntrs)
;pause

  sphr_coords := calc_sphr_coords_from_lambert_cnfrml( \
                 lon_ctr, lat_ctr, lat1, lat2, rad_Earth, angle_units, \
                 x_cntrs, y_cntrs)
  lon_cntrs = sphr_coords@lon
  lat_cntrs = sphr_coords@lat
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
print("")
print("rem_nx = " + rem_nx)
print("rem_ny = " + rem_ny)
pause

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
print("")
print("lon_cntrs(j_cntr-2:j_cntr+2, i_cntr-2:i_cntr+2) = " + lon_cntrs(j_cntr-2:j_cntr+2, i_cntr-2:i_cntr+2))
print("")
print("lon_verts(j_cntr-2:j_cntr+2, i_cntr-2:i_cntr+2) = " + lon_verts(j_cntr-2:j_cntr+2, i_cntr-2:i_cntr+2))
pause

print("")
print("lat_cntrs(j_cntr-2:j_cntr+2, i_cntr-2:i_cntr+2) = " + lat_cntrs(j_cntr-2:j_cntr+2, i_cntr-2:i_cntr+2))
print("")
print("lat_verts(j_cntr-2:j_cntr+2, i_cntr-2:i_cntr+2) = " + lat_verts(j_cntr-2:j_cntr+2, i_cntr-2:i_cntr+2))
pause
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

