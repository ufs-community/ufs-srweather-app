;
; **********************************************************************
;
; File name: read_FV3LAM_grid_wrtcmp.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns the dimensions, cell center coordinates, and
; cell vertex coordinates of the grid that discretizes the FV3-LAM's 
; write-component output domain.  The file to read is specified by 
; FV3LAM_wrtcmp_fn.  If get_domain_bdy is set to True, this function
; also returns the coordinates of the cell vertices lying on the boundary 
; of the domain.
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "get_rect_grid_bdy.ncl")
loadscript(lib_location + "interpol_extrapol_linear.ncl")
loadscript(lib_location + "convert_from_to_sphr_coords_to_from_rotated_sphr.ncl")

undef("read_FV3LAM_grid_wrtcmp")

function read_FV3LAM_grid_wrtcmp( \
         FV3LAM_wrtcmp_fn:string, \
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
; Open the specified FV3-LAM wrtcmp-generated output file for reading.
;
; **********************************************************************
;
  print("")
  print("" + separator_line)
  print("Reading in FV3LAM's write-component grid coordinates from file ...")
  print("")
  print("  FV3LAM_wrtcmp_fn = " + char_dq + FV3LAM_wrtcmp_fn + char_dq)

  fp = addfile(FV3LAM_wrtcmp_fn, "r")
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
; Read in the cell center coordinates.
; 
; **********************************************************************
;
  if (strcmp_exact(coord_sys, "rotated_latlon") .or. \
      strcmp_exact(coord_sys, "lambert_conformal")) then

    lon_cntrs := fp->lon(:,:)
    lat_cntrs := fp->lat(:,:)

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
  dims := dimsizes(lon_cntrs)
  nx = dims(1)
  ny = dims(0)

  print("")
  print("  nx = " + nx)
  print("  ny = " + ny)

;
; **********************************************************************
;
; If the grid encompasses the international date line (IDL, e.g. because 
; it includes one of the poles), then the extrapolations performed below 
; to obtain the cell vertex coordinates along the boundary of the grid 
; may be invalid because the coordinates themselves are not continuous on
; the domain (because there will be a jump in longitude across the IDL).
; To get around this problem, transform the write-component coordinates 
; read in above to a rotated latlon coordinate system that has is IDL
; moved such that it is outside of the write-component domain.  In this
; coordinate system, the coordinates will be continuous and thus the 
; extrapolations below will be valid.
;
; Once all quantities that this function needs to return are calculated
; in the rotated latlon coordinate system, they will be transformed back
; to obtain their values in the non-rotated coordinate system (see further
; below).
;
; IMPORTANT:
; Probably will have to include code similar to the following in the file
; read_FV3LAM_grid_native.ncl.
;
; **********************************************************************
;
  nxm1 := nx - 1
  nym1 := ny - 1
  nxp1 := nx + 1
  nyp1 := ny + 1

  diffx_lon_iph := lon_cntrs(:,1:nxm1) - lon_cntrs(:,0:nxm1-1)
  diffy_lon_jph := lon_cntrs(1:nym1,:) - lon_cntrs(0:nym1-1,:)

  diffx_lon_abs_max := max(abs(diffx_lon_iph))
  diffy_lon_abs_max := max(abs(diffy_lon_jph))
  diff_lon_abs_max := 180.0d+0

  transform_to_rotated_latlon = False
  if ((diffx_lon_abs_max .gt. diff_lon_abs_max) .or. \
      (diffy_lon_abs_max .gt. diff_lon_abs_max)) then
; Set the flag to perform the unrotated-to-rotated latlon transformation
; (and back again later on).
    transform_to_rotated_latlon = True
; Read in from the specified file the coordinates of the center of the 
; grid (in non-rotated latlon coordinates).
    file_global_atts = getfileatts(fp)
    lon0 := fp@cen_lon
    lat0 := fp@cen_lat
  end if
;
; If necessary, transform the grid cell center coordinates from the 
; unrotated to a rotated latlon coordinate system.
;
  if (transform_to_rotated_latlon) then

    angle_units = "deg"
    dir = 1
    rotated_sphr_coords \
    := convert_from_to_sphr_coords_to_from_rotated_sphr( \
       lon0, lat0, angle_units, dir, \
       lon_cntrs, lat_cntrs)
    lon_cntrs := rotated_sphr_coords@lon_out
    lat_cntrs := rotated_sphr_coords@lat_out

  end if
;
; **********************************************************************
;
; Calculate cell vertex coordinates from cell center coordinates.  For
; vertices that are in the interior of the write-component domain, we
; simply averate the four neighboring cell center coordinates to obtain
; the coordinates of the vertex.  For vertices that lie on the boundary
; of the domain, we perform linear extrapolation using the coordinates 
; of vertices that lie within the domain (and whose coordinates we have
; already calculated using the coordinates of the cell centers).
;
; **********************************************************************
;
  lon_verts := new((/ nyp1, nxp1 /), coord_data_type)
  lat_verts := new((/ nyp1, nxp1 /), coord_data_type)
;lon_verts = -98.5d+0
;lat_verts = 37.5d+0
;
; Average the coordinates of the four neighboring center points around 
; each vertex that is in the interior of the domain/grid to obtain the 
; coordinates of that internal vertex.
;
  lon_verts(1:nym1,1:nxm1) \
  = (lon_cntrs(0:nym1-1,0:nxm1-1) \
  + lon_cntrs(0:nym1-1,1:nxm1) \
  + lon_cntrs(1:nym1,1:nxm1) \
  + lon_cntrs(1:nym1,0:nxm1-1))/4.0d+0

  lat_verts(1:nym1,1:nxm1) \
  = (lat_cntrs(0:nym1-1,0:nxm1-1) \
  + lat_cntrs(0:nym1-1,1:nxm1) \
  + lat_cntrs(1:nym1,1:nxm1) \
  + lat_cntrs(1:nym1,0:nxm1-1))/4.0d+0
;
; Create integer (index) arrays needed in the extrapolations below in the
; x direction.
;
  ivec1 := new(nym1, "integer")
  ivec2 := new(nym1, "integer")
  ivec3 := new(nym1, "integer")
;
; Extrapolate to obtain coordinates of vertices along the left boundary
; (but not including the vertices on the bottom-left and top-left corners
; of the grid).
;
  i1 = 1
  i2 = 2
  i3 = 0
  ivec1 = i1
  ivec2 = i2
  ivec3 = i3
  lon_verts(1:nym1,i3) \
  = interpol_extrapol_linear( \
    ivec1, lon_verts(1:nym1,i1), ivec2, lon_verts(1:nym1,i2), ivec3)
  lat_verts(1:nym1,i3) \
  = interpol_extrapol_linear( \
    ivec1, lat_verts(1:nym1,i1), ivec2, lat_verts(1:nym1,i2), ivec3)
;
; Extrapolate to obtain coordinates of vertices along the right boundary
; (but not including the vertices on the bottom-right and top-right corners
; of the grid).
;
  i1 = nx - 2
  i2 = nx - 1
  i3 = nx
  ivec1 = i1
  ivec2 = i2
  ivec3 = i3
  lon_verts(1:nym1,i3) \
  = interpol_extrapol_linear( \
    ivec1, lon_verts(1:nym1,i1), ivec2, lon_verts(1:nym1,i2), ivec3)
  lat_verts(1:nym1,i3) \
  = interpol_extrapol_linear( \
    ivec1, lat_verts(1:nym1,i1), ivec2, lat_verts(1:nym1,i2), ivec3)
;
; Create integer (index) arrays needed in the extrapolations below in the
; y direction.
;
  jvec1 := new(nxm1, "integer")
  jvec2 := new(nxm1, "integer")
  jvec3 := new(nxm1, "integer")
;
; Extrapolate to obtain coordinates of vertices along the bottom boundary
; (but not including the vertices on the bottom-left and bottom-right 
; corners of the grid).
;
  j1 = 1
  j2 = 2
  j3 = 0
  jvec1 = j1
  jvec2 = j2
  jvec3 = j3
  lon_verts(j3,1:nxm1) \
  = interpol_extrapol_linear( \
    jvec1, lon_verts(j1,1:nxm1), jvec2, lon_verts(j2,1:nxm1), jvec3)
  lat_verts(j3,1:nxm1) \
  = interpol_extrapol_linear( \
    jvec1, lat_verts(j1,1:nxm1), jvec2, lat_verts(j2,1:nxm1), jvec3)
;
; Extrapolate to obtain coordinates of vertices along the top boundary
; (but not including the vertices on the top-left and top-right corners
; of the grid).
;
  j1 = ny - 2
  j2 = ny - 1
  j3 = ny
  jvec1 = j1
  jvec2 = j2
  jvec3 = j3
  lon_verts(j3,1:nxm1) \
  = interpol_extrapol_linear( \
    jvec1, lon_verts(j1,1:nxm1), jvec2, lon_verts(j2,1:nxm1), jvec3)
  lat_verts(j3,1:nxm1) \
  = interpol_extrapol_linear( \
    jvec1, lat_verts(j1,1:nxm1), jvec2, lat_verts(j2,1:nxm1), jvec3)
;
; **********************************************************************
;
; Extrapolate to obtain the coordinates of the vertex on the bottom-left 
; corner of the grid.
;
; **********************************************************************
;
  i1 = 1
  i2 = 2
  i3 = 0
  j3 = 0
  lon_verts(j3,i3) \
  = interpol_extrapol_linear( \
    i1, lon_verts(j3,i1), i2, lon_verts(j3,i2), i3)

  j1 = 1
  j2 = 2
  j3 = 0
  i3 = 0
  lat_verts(j3,i3) \
  = interpol_extrapol_linear( \
    j1, lat_verts(j1,i3), i2, lat_verts(j2,i3), j3)
;
; **********************************************************************
;
; Extrapolate to obtain the coordinates of the vertex on the bottom-right
; corner of the grid.
;
; **********************************************************************
;
  i1 = nx - 2
  i2 = nx - 1
  i3 = nx
  j3 = 0
  lon_verts(j3,i3) \
  = interpol_extrapol_linear( \
    i1, lon_verts(j3,i1), i2, lon_verts(j3,i2), i3)

  j1 = 1
  j2 = 2
  j3 = 0
  i3 = nx
  lat_verts(j3,i3) \
  = interpol_extrapol_linear( \
    j1, lat_verts(j1,i3), j2, lat_verts(j2,i3), j3)
;
; **********************************************************************
;
; Extrapolate to obtain the coordinates of the vertex on the top-right
; corner of the grid.
;
; **********************************************************************
;
  i1 = nx - 2
  i2 = nx - 1
  i3 = nx
  j3 = ny
  lon_verts(j3,i3) \
  = interpol_extrapol_linear( \
    i1, lon_verts(j3,i1), i2, lon_verts(j3,i2), i3)

  j1 = ny - 2
  j2 = ny - 1
  j3 = ny
  i3 = nx
  lat_verts(j3,i3) \
  = interpol_extrapol_linear( \
    j1, lat_verts(j1,i3), j2, lat_verts(j2,i3), j3)
;
; **********************************************************************
;
; Extrapolate to obtain the coordinates of the vertex on the top-left 
; corner of the grid.
;
; **********************************************************************
;
  i1 = 1
  i2 = 2
  i3 = 0
  j3 = ny
  lon_verts(j3,i3) \
  = interpol_extrapol_linear( \
    i1, lon_verts(j3,i1), i2, lon_verts(j3,i2), i3)

  j1 = ny - 2
  j2 = ny - 1
  j3 = ny
  i3 = 0
  lat_verts(j3,i3) \
  = interpol_extrapol_linear( \
    j1, lat_verts(j1,i3), j2, lat_verts(j2,i3), j3)
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
  := (/ ndtooned(lon_verts(0:nym1,0:nxm1)), \
        ndtooned(lon_verts(0:nym1,1:nx)), \
        ndtooned(lon_verts(1:ny,1:nx)), \
        ndtooned(lon_verts(1:ny,0:nxm1)) /)
  lon_verts_unstruc := transpose(lon_verts_unstruc)

  lat_verts_unstruc \
  := (/ ndtooned(lat_verts(0:nym1,0:nxm1)), \
        ndtooned(lat_verts(0:nym1,1:nx)), \
        ndtooned(lat_verts(1:ny,1:nx)), \
        ndtooned(lat_verts(1:ny,0:nxm1)) /)
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
  print("Done reading in FV3-LAM's write-component grid coordinates from file.")
  print("" + separator_line)
;
; **********************************************************************
;
; If the original latlon grid coordinates read in from the file were 
; transformed above to a rotated coordinate system because they include
; the international date line, then transform the results obtained above
; back to the non-rotated latlon coordinate system before returning them.
;
; **********************************************************************
;
  if (transform_to_rotated_latlon) then

    dir = -1

    sphr_coords \
    := convert_from_to_sphr_coords_to_from_rotated_sphr( \
       lon0, lat0, angle_units, dir, \
       lon_cntrs_unstruc, lat_cntrs_unstruc)
    lon_cntrs_unstruc := sphr_coords@lon_out
    lat_cntrs_unstruc := sphr_coords@lat_out

    sphr_coords \
    := convert_from_to_sphr_coords_to_from_rotated_sphr( \
       lon0, lat0, angle_units, dir, \
       lon_verts_unstruc, lat_verts_unstruc)
    lon_verts_unstruc := sphr_coords@lon_out
    lat_verts_unstruc := sphr_coords@lat_out

    sphr_coords \
    := convert_from_to_sphr_coords_to_from_rotated_sphr( \
       lon0, lat0, angle_units, dir, \
       lon_bdy, lat_bdy)
    lon_bdy := sphr_coords@lon_out
    lat_bdy := sphr_coords@lat_out

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
  grid_info@coord_data_type = coord_data_type

  return(grid_info)

end

