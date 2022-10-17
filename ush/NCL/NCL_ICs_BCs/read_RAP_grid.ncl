; **********************************************************************
;
; File name: read_RAP_grid.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function reads in the RAP grid from the specified file.
;                                                                      *
; **********************************************************************

load "adjust_longitude_range.ncl"

undef("read_RAP_grid")

function read_RAP_grid(RAP_geo_file:string)

local f_geo, \
      lon_cntrs, lat_cntrs, lon_verts, lat_verts, \
      RAP_dims, nx, ny, num_cells, \
      lon_cntrs_by_cell, lat_cntrs_by_cell, \
      lon_verts_by_cell, lat_verts_by_cell, \
      lon, lat, num_verts_per_cell, v, v_ref, \
      abs_del_lon, is_greater, \
      out

begin
;
; **********************************************************************
;                                                                      *
; Open the RAP geo-file containing RAP grid information.
;                                                                      *
; **********************************************************************
;
  f_geo = addfile(RAP_geo_file, "r")
;
; Read in the center coordinates of all cells in the RAP domain.
; 
  lon_cntrs := f_geo->XLONG_M(:,:,:)
  lat_cntrs := f_geo->XLAT_M(:,:,:)
;
; Read in the corner coordinates of all cells in the RAP domain.
; 
  lon_verts := f_geo->XLONG_C(:,:,:)
  lat_verts := f_geo->XLAT_C(:,:,:)
;
; Remove singleton dimensions (e.g. time).
;
  lon_cntrs := rm_single_dims(lon_cntrs)
  lat_cntrs := rm_single_dims(lat_cntrs)

  lon_verts := rm_single_dims(lon_verts)
  lat_verts := rm_single_dims(lat_verts)
;
; Make sure that longitudes are in the range -180 deg <= lon < 180 deg.
;
  lon_min = -180.0
  lon_cntrs := adjust_longitude_range(lon_cntrs, lon_min, "degs")
  lon_verts := adjust_longitude_range(lon_verts, lon_min, "degs")
;
; Get the dimensions of the RAP domain.
;
  RAP_dims := dimsizes(lon_cntrs)
  nx = RAP_dims(1)
  ny = RAP_dims(0)
  num_cells = nx*ny

print("")
print("nx = " + nx)
print("ny = " + ny)
print("num_cells = " + num_cells)
;
; **********************************************************************
;                                                                      *
; Form arrays containing the coordinates of cell centers on a "by-cell"
; basis.
;                                                                      *
; **********************************************************************
;
  lon_cntrs_by_cell := ndtooned(lon_cntrs)
  lat_cntrs_by_cell := ndtooned(lat_cntrs)
;
; **********************************************************************
;                                                                      *
; Form arrays containing the coordinates of cell corners on a "by-cell"
; basis.
;                                                                      *
; **********************************************************************
;
  num_verts_per_cell = 4
  lon_verts_by_cell := new((/ num_cells, num_verts_per_cell /), "double")
  lat_verts_by_cell := new((/ num_cells, num_verts_per_cell /), "double")

  v = 0
  lon := ndtooned(lon_verts(0:ny-1,0:nx-1))
  lat := ndtooned(lat_verts(0:ny-1,0:nx-1))
  lon_verts_by_cell(:,v) = lon
  lat_verts_by_cell(:,v) = lat

  v = 1
  lon := ndtooned(lon_verts(0:ny-1,1:nx))
  lat := ndtooned(lat_verts(0:ny-1,1:nx))
  lon_verts_by_cell(:,v) = lon
  lat_verts_by_cell(:,v) = lat

  v = 2
  lon := ndtooned(lon_verts(1:ny,1:nx))
  lat := ndtooned(lat_verts(1:ny,1:nx))
  lon_verts_by_cell(:,v) = lon
  lat_verts_by_cell(:,v) = lat

  v = 3
  lon := ndtooned(lon_verts(1:ny,0:nx-1))
  lat := ndtooned(lat_verts(1:ny,0:nx-1))
  lon_verts_by_cell(:,v) = lon
  lat_verts_by_cell(:,v) = lat
;
; Delete unneeded arrays.
;
  delete([/ lon, lat /])
;
; For cells that cross over the international date line, modify longi-
; tudes of the vertices so that there is no discontinuity in their val-
; ues.
;
  v_ref = 0
  do v=1, num_verts_per_cell-1
    abs_del_lon := abs(lon_verts_by_cell(:,v) - lon_verts_by_cell(:,v_ref))
    is_greater := (lon_verts_by_cell(:,v) .gt. lon_verts_by_cell(:,v_ref))
    lon_verts_by_cell(:,v) \
    = where((abs_del_lon .gt. 180.0) .and. is_greater, \
            lon_verts_by_cell(:,v) - 360.0, \
            lon_verts_by_cell(:,v))
    lon_verts_by_cell(:,v) \
    = where((abs_del_lon .gt. 180.0) .and. (.not. is_greater), \
            lon_verts_by_cell(:,v) + 360.0, \
            lon_verts_by_cell(:,v))
  end do



if (False) then
  clon_cntrs := f_geo->CLONG
  clat_cntrs := f_geo->CLAT

  lon_min = 180.0
  clon_cntrs = adjust_longitude_range(clon_cntrs, lon_min, "degs")

  temp := dimsizes(clon_cntrs)
  west_east = temp(2)
  south_north = temp(1)

  clon_min = min(clon_cntrs)
  clon_max = max(clon_cntrs)

  clat_min = min(clat_cntrs)
  clat_max = max(clat_cntrs)

  del_clon = (clon_max - clon_min)/(west_east-1)
  del_clat = (clat_max - clat_min)/(south_north-1)

  
  print("")
  print("clon_min = " + clon_min)
  print("clon_max = " + clon_max)
  print("del_clon = " + del_clon)
  print("")
  print("clat_min = " + clat_min)
  print("clat_max = " + clat_max)
  print("del_clat = " + del_clat)
;pause
end if



;
; **********************************************************************
;                                                                      *
; Return various output variables as attributes of the "out" variable.
;                                                                      *
; **********************************************************************
;
  out = True
  out@nx = nx
  out@ny = ny
  out@num_cells = num_cells
  out@lon_cntrs_by_cell = lon_cntrs_by_cell
  out@lat_cntrs_by_cell = lat_cntrs_by_cell
  out@lon_verts_by_cell = lon_verts_by_cell
  out@lat_verts_by_cell = lat_verts_by_cell
  return(out)

end





