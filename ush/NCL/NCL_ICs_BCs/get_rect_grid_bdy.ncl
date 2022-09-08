; **********************************************************************
;
; File name: get_rect_grid_bdy.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns 1-D arrays containing the 2-D coordinates (say x
; and y) of the points (cells) along the boundary of the rectangular 
; grid specified by the given arrays.
;                                                                      *
; **********************************************************************

load "special_chars.ncl"
load "strcmp.ncl"

undef("get_rect_grid_bdy")

function get_rect_grid_bdy( \
         x_coords:snumeric, y_coords:snumeric, \
         repeat_last_point:logical, array_order:string)

local x, y, dims, nx, ny, x_bdy, y_bdy, i, j, out

begin
;
; **********************************************************************
;
; Check that array_order has a valid value.
;
; **********************************************************************
;
  if (.not. strcmp(array_order, "ij") .and. \
      .not. strcmp(array_order, "ji")) then
    print("")
    print("The input argument array_order must be set to either " + \
          char_dq + "ji" + char_dq + " or " + \
          char_dq + "ij" + char_dq + ":")
    print("  array_order = " + char_dq + array_order + char_dq)
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;
; The code below assumes that the coordinate arrays use the index order
; (j,i) [as opposed to (i,j)].  Thus, if the given arrays use the order
; (i,j), transpose them to get back to (j,i) order.
;
; **********************************************************************
;
  x = x_coords
  y = y_coords
  if (strcmp(array_order, "ij")) then
    x = transpose(x)
    y = transpose(y)
  end if
;
; **********************************************************************
;
; Get the dimensions of the coordinate arrays and check that they are 
; identical.
;
; **********************************************************************
;
  dims_x = dimsizes(x)
  dims_y = dimsizes(y)

  dims_are_equal = (dims_x .eq. dims_y)
  if (.not. all(dims_are_equal)) then
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
; For convenience, set nx and ny to the number of grid points in the x
; and y directions, respectively.
;
; **********************************************************************
;
  nx = dims_x(1)
  ny = dims_x(0)
;
; **********************************************************************
;
; Create 1-D arrays to hold the x and y coordinates of the boundary 
; points of the grid.  Note that initially, these arrays will contain 
; only one element; more elements will be appended later below.
;
; **********************************************************************
;
  x_bdy := new((/1/), typeof(x))
  y_bdy := new((/1/), typeof(y))
;
; **********************************************************************
;
; Copy in the coordinates of the point at (i,j) = (0,0).
;
; **********************************************************************
;
  i = 0
  j = 0
  x_bdy(0) = x(j,i)
  y_bdy(0) = y(j,i)
;
; **********************************************************************
;
; Append the coordinates of the points along the "southern" boundary 
; (j = 0).
;
; **********************************************************************
;
  j = 0
  x_bdy := array_append_record(x_bdy, x(j,1:), 0)
  y_bdy := array_append_record(y_bdy, y(j,1:), 0)
;
; **********************************************************************
;
; Append the coordinates of the points along the "eastern" boundary 
; (i = nx).
;
; **********************************************************************
;
  i = nx - 1
  x_bdy := array_append_record(x_bdy, x(1:,i), 0)
  y_bdy := array_append_record(y_bdy, y(1:,i), 0)
;
; **********************************************************************
;
; Append the coordinates of the points along the "northern" boundary 
; (j = ny).  Note that in specifying the i-index range [i.e. (nx-1:0)], 
; we do not specify a negative stride, i.e. we do not use (nx-1:0:-1),
; because in NCL, the order of the elements is automatically reversed if
; the starting index is larger than the ending index.
;
; **********************************************************************
;
  j = ny - 1
  x_bdy := array_append_record(x_bdy, x(j,nx-2:0), 0)
  y_bdy := array_append_record(y_bdy, y(j,nx-2:0), 0)
;
; **********************************************************************
;
; Append the coordinates of the points along the "western" boundary 
; (i = 0).  Note that in specifying the j-index range [i.e. (ny-1:1)],
; we do not specify a negative stride, i.e. we do not use (ny-1:1:-1),
; because in NCL, the order of the elements is automatically reversed if
; the starting index is larger than the ending index.
;
; **********************************************************************
;
  i = 0
  x_bdy := array_append_record(x_bdy, x(ny-2:1,i), 0)
  y_bdy := array_append_record(y_bdy, y(ny-2:1,i), 0)
;
; **********************************************************************
;
; If repeat_last_point is set to True, repeat the first point on the 
; boundary again as the last point.  This is done so that if a polyline 
; object is used to plot the tile boundary, the boundary closes on it-
; self.
;
; **********************************************************************
;
  if (repeat_last_point) then
    x_bdy := array_append_record(x_bdy, (/ x_bdy(0) /), 0)
    y_bdy := array_append_record(y_bdy, (/ y_bdy(0) /), 0)
  end if
;
; **********************************************************************
;                                                                      *
; Return the arrays containing the coordinates of the boundary points as
; as attributes of the "out" variable.
;                                                                      *
; **********************************************************************
;
  out := True
  out@x_bdy = x_bdy
  out@y_bdy = y_bdy
  return(out)

end

