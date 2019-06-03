;
; **********************************************************************
;
; File name: read_RAP_grid.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns the dimensions, cell center coordinates, and
; cell vertex coordinates of the grid encompassing the RAP domain speci-
; fied in the file RAP_grid_fn.  If get_domain_bdy is set to True, it 
; also returns the coordinates of the cell vertices lying on the bounda-
; ry of the domain.
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "get_rect_grid_bdy.ncl")

undef("read_RAP_grid")

function read_RAP_grid( \
         RAP_grid_fn:string, \
         get_domain_bdy:logical)

local fp, \
      coord_data_type, \
      lon_cntrs, lat_cntrs, \
      lon_verts, lat_verts, \
      dims, nx, ny, \
      lon_cntrs_unstruc, lat_cntrs_unstruc, \
      lon_verts_unstruc, lat_verts_unstruc, \
      repeat_last_point, array_order, bdy_info, lon_bdy, lat_bdy, \
      x_is_longitude, opts, corner_info, corner_lons, corner_lats, \
      fmt_str, c, lon_str, lat_str, \
      grid_info

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
; Open the specified file for reading.
;
; **********************************************************************
;
  print("")
  print("" + separator_line)
  print("Reading in grid coordinates of the RAP domain from file:")
  print("")
  print("  RAP_grid_fn = " + char_dq + RAP_grid_fn + char_dq)

  fp = addfile(RAP_grid_fn, "r")
;
; **********************************************************************
;
; Get the data type (i.e. float or double) of the coordinate arrays in 
; the specified file.  We assume here that all coordinate arrays are of
; the same type, so we read in the type of only one such coordinate ar-
; ray.
;
; **********************************************************************
;
  coord_data_type = getfilevartypes(fp, "XLONG_M") 
;
; **********************************************************************
;
; Read in the cell center coordinates.
;
; **********************************************************************
; 
  lon_cntrs := fp->XLONG_M(:,:,:)
  lat_cntrs := fp->XLAT_M(:,:,:)
;
; **********************************************************************
;
; Read in the cell vertex coordinates.
; 
; **********************************************************************
;
  lon_verts := fp->XLONG_C(:,:,:)
  lat_verts := fp->XLAT_C(:,:,:)
;
; **********************************************************************
;
; Remove singleton dimensions (e.g. time) from the coordinate arrays.
;
; **********************************************************************
;
  lon_cntrs := rm_single_dims(lon_cntrs)
  lat_cntrs := rm_single_dims(lat_cntrs)

  lon_verts := rm_single_dims(lon_verts)
  lat_verts := rm_single_dims(lat_verts)
;
; **********************************************************************
;
; Get the grid dimensions.
;
; **********************************************************************
;
  dims := dimsizes(lon_cntrs)
  nx = dims(1)
  ny = dims(0)

  print("")
  print("  nx = " + nx)
  print("  ny = " + ny)
;
; **********************************************************************
;
; Create arrays in unstructured format that contain the coordinates of
; the center of each cell on the grid.  Note that these are 1-D arrays, 
; and their size (i.e. the number of elements they contain) is equal to
; the number of cells on the grid (i.e. nx*ny).  This unstructured for-
; mat is useful in generating color-contour plots of fields on the grid
; that have one value per cell represented by a flat color in that cell.
;
; **********************************************************************
;
  lon_cntrs_unstruc := ndtooned(lon_cntrs)
  lat_cntrs_unstruc := ndtooned(lat_cntrs)
;
; **********************************************************************
;
; Create arrays in unstructured format that contain the coordinates of
; the vertices of each cell on the grid.  Note that these are 2-D arrays
; whose first dimension size is the number of cells on the grid (i.e. 
; nx*ny) and whose second dimension size is 4 (since each cell has 4 
; vertices).  This unstructured format is useful in generating color-
; contour plots of fields on the grid that have one value per cell re-
; presented by a flat color in that cell.
;
; **********************************************************************
;
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
; rays the coordinates of those cell vertices that lie on the boundary 
; of the grid.
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
; Find and print out the coordinates of the corners of the grid.
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
  print("  The RAP domain's corner lon/lat coordinates are:")
  fmt_str = "%7.2f"
  do c=0, dimsizes(corner_lons)-1
    lon_str = sprintf(fmt_str, corner_lons(c))
    lat_str = sprintf(fmt_str, corner_lats(c))
    print("    Corner " + (c+1) + ":  lon = " + lon_str + " deg;  " + \
          "lat = " + lat_str + " deg")
  end do

  print("")
  print("Done reading in RAP grid coordinates from file.")
  print("" + separator_line)
;
; **********************************************************************
;
; Calculate the coordinates of the center of the RAP grid.
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
    lon_grid_cntr := fp->XLONG_V(:,j_cntr,i_cntr)
    lat_grid_cntr := fp->XLAT_V(:,j_cntr,i_cntr)
  else if ((rem_nx .eq. 0) .and. (rem_ny .eq. 1)) then
    i_cntr = nx/2
    j_cntr = (ny - 1)/2
    lon_grid_cntr := fp->XLONG_U(:,j_cntr,i_cntr)
    lat_grid_cntr := fp->XLAT_U(:,j_cntr,i_cntr)
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

  grid_info@fp = fp
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

