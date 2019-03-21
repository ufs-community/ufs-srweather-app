;
; **********************************************************************
;
; File name: get_rect_grid_corners.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns the coordinates of the four corners of a logi-
; cally rectangular grid whose cell vertex coordinates are specified by
; the 2-D arrays x_verts and y_verts.  We let x and y refere to the co-
; ordinates in the two directions.  If the x coordinate represents lon-
; gitude (which is the case if the logical variable x_is_longitude is 
; set to True), this function ensures that the longitudes of the grid 
; corners are within the longitude range (-180 deg, 180 deg) or (-pi, 
; pi).
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")

undef("get_rect_grid_corners")

function get_rect_grid_corners( \
         x_verts[*][*]:snumeric, y_verts[*][*]:snumeric, \
         x_units:string, y_units:string, \
         x_is_longitude:logical, \
         opts:logical)

local dims_x, dims_y, dims_are_equal, dims_x_str, dims_y_str, \
      nx, ny, \
      corner_i_inds, corner_j_inds, num_corners, \
      x_corners, y_corners, \
      valid_lon_units, max_lon_allowed, valid_vals, msg, lon_range, \
      fmt_str, x_str, y_str, \
      corner_info

begin
;
; **********************************************************************
;
; Get the dimensions of the coordinate arrays and check that they are 
; identical.
;
; **********************************************************************
;
  dims_x = dimsizes(x_verts)
  dims_y = dimsizes(y_verts)

  dims_are_equal = all(dims_x .eq. dims_y)
  if (.not. dims_are_equal) then
    dims_x_str = str_join(tostring(dims_x), ", ")
    dims_y_str = str_join(tostring(dims_y), ", ")
    print("")
    print("The dimensions of the x-coordinate array do not match those of the y-coordinate array:")
    print("  dims_x = (" + dims_x_str + ")")
    print("  dims_y = (" + dims_y_str + ")")
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;
; For convenience, set nx and ny to the number of grid cells in the x
; and y directions, respectively.  Note that since we assume that the 
; specified coordinates are those of the cell vertices, the number of 
; grid cells in each direction is one less than the dimensions of the 
; specified arrays.
;
; **********************************************************************
;
  nx = dims_x(1) - 1
  ny = dims_x(0) - 1
;
; **********************************************************************
;
; Find the coordinates of the corners of the grid.
;
; **********************************************************************
;
  corner_i_inds := (/ 0, nx, nx, 0 /)
  corner_j_inds := (/ 0, 0, ny, ny /)
  num_corners = 4
  x_corners := new((/ num_corners /), "double")
  y_corners := new((/ num_corners /), "double")

  do c=0, num_corners-1
    x_corners(c) = x_verts(corner_j_inds(c), corner_i_inds(c))
    y_corners(c) = y_verts(corner_j_inds(c), corner_i_inds(c))
  end do
;
; **********************************************************************
;
; If the x coordinate represents longitude (in which case the logical
; variable x_is_longitude will be True), ensure that the longitudes of
; the corners determined above are all within the valid longitude range.
;
; **********************************************************************
;
  if (x_is_longitude) then

    valid_lon_units = (/ "deg", "degs", "rad", "rads" /)

    if (strcmp_exact(valid_lon_units, x_units)) then

      if (strcmp_exact(x_units, "deg") .or. \
          strcmp_exact(x_units, "degs")) then
        max_lon_allowed = 180.0
      else if (strcmp_exact(x_units, "rad") .or. \
               strcmp_exact(x_units, "rads")) then
        max_lon_allowed = pi_geom
      else
        msg := char_nl + \
"Don't know what the maximum allowed value (max_lon_allowed) should be " + char_nl + \
"for these units:" + char_nl + \
"  x_units = " + char_dq + x_units + char_dq + char_nl + \
"Stopping."
        print("" + msg)
        exit
      end if
      end if

    else

      valid_vals \
      := char_dq \
      + str_join(valid_lon_units, char_dq + ", " + char_dq) \
      + char_dq

      msg := char_nl + \
"Unknown units specified for the longitude (x):" + char_nl + \
"  x_units = " + char_dq + x_units + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Stopping."
      print("" + msg)
      exit

    end if

    lon_range = 2.0*max_lon_allowed

    do c=0, num_corners-1
      if (x_corners(c) .gt. max_lon_allowed) then
        x_corners(c) = x_corners(c) - lon_range
      end if
    end do

  end if
;
; **********************************************************************
;
; Create a (multiline) string containing the coordinates of the grid 
; corners.  Then, if opts@verbose exists and is set to True, print this
; string to screen. 
;
; **********************************************************************
;
  fmt_str = "%7.2f"
  msg := char_nl + "The specified grid's corner coordinates are:"
  do c=0, num_corners-1
    x_str = sprintf(fmt_str, x_corners(c))
    y_str = sprintf(fmt_str, y_corners(c))
    msg := msg + char_nl \
         + "  Corner " + (c+1) + ":  " \
         + "x = " + x_str + " " + x_units + ";  " \
         + "y = " + y_str + " " + y_units
  end do
;
; Recast msg as an array (one line per element).  This allows for extra
; spaces to be easily prepended at the beginning of each line.
;
  msg := str_split(msg, char_nl)

  if (isatt(opts, "verbose") .and. (opts@verbose .eq. True)) then
    print("" + msg)
  end if
;
; **********************************************************************
;
; Return results as attributes of the logical variable corner_info.
;
; **********************************************************************
;
  corner_info := True

  corner_info@x_corners = x_corners
  corner_info@y_corners = y_corners
  corner_info@msg = msg

  return(corner_info)

end


