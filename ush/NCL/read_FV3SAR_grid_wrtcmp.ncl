;
; **********************************************************************
;
; File name: read_FV3SAR_grid_wrtcmp.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns the dimensions, cell center coordinates, and
; cell vertex coordinates of the grid that discretizes the FV3SAR's 
; write-component output domain.  The file to read is specified by 
; FV3SAR_wrtcmp_fn.  If get_domain_bdy is set to True, this function
; also returns the coordinates of the cell vertices lying on the bounda-
; ry of the domain.
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "get_rect_grid_bdy.ncl")

undef("read_FV3SAR_grid_wrtcmp")

function read_FV3SAR_grid_wrtcmp( \
         FV3SAR_wrtcmp_fn:string, \
         get_domain_bdy:logical)

local fp, \
      coord_data_type, \
      coord_sys, \
      lon_verts, lat_verts, \
      lon_cntrs, lat_cntrs, \
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
; Open the specified FV3SAR wrtcmp-generated output file for reading.
;
; **********************************************************************
;
  print("")
  print("" + separator_line)
  print("Reading in FV3SAR's write-component grid coordinates from file ...")
  print("")
  print("  FV3SAR_wrtcmp_fn = " + char_dq + FV3SAR_wrtcmp_fn + char_dq)

  fp = addfile(FV3SAR_wrtcmp_fn, "r")
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
  coord_data_type = getfilevartypes(fp, "grid_xt")
;
; **********************************************************************
;
; Read in the coordinate system in which the grid is generated.
; 
; **********************************************************************
;
  coord_sys := fp@grid
; 
; **********************************************************************
;
; Read in the cell vertex coordinates.
; 
; **********************************************************************
; 
  if (strcmp_exact(coord_sys, "rotated_latlon") .or. \
      strcmp_exact(coord_sys, "lambert_conformal")) then

    lon_verts := fp->grid_xt(:,:)
    lat_verts := fp->grid_yt(:,:)

lon_verts = lon_verts*degs_per_rad
lat_verts = lat_verts*degs_per_rad

  else

    print("")
    print("This function does not yet support this coordinate system:")
    print("  coord_sys = " + char_dq + coord_sys + char_dq)
    print("Stopping.")
    exit

  end if
;
; **********************************************************************
;
; Get the grid dimensions.
;
; **********************************************************************
;
  dims := dimsizes(lon_verts)
  nx = dims(1) - 1
  ny = dims(0) - 1

  print("")
  print("  nx = " + nx)
  print("  ny = " + ny)
;
; **********************************************************************
;
; Calculate cell center coordinates from cell vertex coordinates.
;
; **********************************************************************
;
;  lon_cntrs := new((/ ny, nx /), coord_data_type)
  lon_cntrs = lon_verts(0:ny-1,0:nx-1) \
            + lon_verts(0:ny-1,1:nx) \
            + lon_verts(1:ny,1:nx) \
            + lon_verts(1:ny,0:nx-1)
  lon_cntrs = 0.25d+0*lon_cntrs

;  lat_cntrs := new((/ ny, nx /), coord_data_type)
  lat_cntrs = lat_verts(0:ny-1,0:nx-1) \
            + lat_verts(0:ny-1,1:nx) \
            + lat_verts(1:ny,1:nx) \
            + lat_verts(1:ny,0:nx-1)
  lat_cntrs = 0.25d+0*lat_cntrs
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
; If get_domain_bdy is True, get the coordinates of the boundary points
; on the grid.  Here, by "boundary points", we mean those cell vertices
; that happen to lie on the grid's boundary.
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
  print("  The write-component grid's corner lon/lat coordinates are:")
  fmt_str = "%7.2f"
  do c=0, dimsizes(corner_lons)-1
    lon_str = sprintf(fmt_str, corner_lons(c))
    lat_str = sprintf(fmt_str, corner_lats(c))
    print("    Corner " + (c+1) + ":  lon = " + lon_str + " deg;  " + \
          "lat = " + lat_str + " deg")
  end do

  print("")
  print("Done reading in FV3SAR's write-component grid coordinates from file.")
  print("" + separator_line)
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
  grid_info@coord_data_type = coord_data_type

  return(grid_info)

end

