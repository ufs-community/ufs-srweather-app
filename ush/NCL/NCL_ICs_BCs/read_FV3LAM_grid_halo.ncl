;
; **********************************************************************
;
; File name: read_FV3LAM_grid_halo.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function reads in the coordinates of the FV3-LAM regional grid 
; from the specified grid file and extracts from it the coordinates of
; the halo.
;
; **********************************************************************
;
load "strcmp.ncl"
load "adjust_longitude_range.ncl"

undef("read_FV3LAM_grid_halo")

function read_FV3LAM_grid_halo(grid_file:string, nh:integer)

local f_grid, \
      two_nx, two_ny, nx, ny, nxp, nyp, \
;
      i_bottom, j_bottom, i_top, j_top, i_left, j_left, i_right, j_right, \
      i_s_bottom, j_s_bottom, i_s_top, j_s_top, i_s_left, j_s_left, i_s_right, j_s_right, \
      i_w_bottom, j_w_bottom, i_w_top, j_w_top, i_w_left, j_w_left, i_w_right, j_w_right, \
;
      lon_verts_supergrid, lat_verts_supergrid, \
;
      lon_cntrs, lat_cntrs, lon_verts, lat_verts, \
      lon_cntrs_bottom, lat_cntrs_bottom, lon_verts_bottom, lat_verts_bottom, \
      lon_cntrs_top, lat_cntrs_top, lon_verts_top, lat_verts_top, \
      lon_cntrs_left, lat_cntrs_left, lon_verts_left, lat_verts_left, \
      lon_cntrs_right, lat_cntrs_right, lon_verts_right, lat_verts_right, \
;
      dims_bottom, nx_bottom, ny_bottom, num_cells_bottom, \
      dims_top, nx_top, ny_top, num_cells_top, \
      dims_left, nx_left, ny_left, num_cells_left, \
      dims_right, nx_right, ny_right, num_cells_right, \
;
      num_cells_total, num_verts_per_cell, \
;
      lon_cntrs_by_cell, lat_cntrs_by_cell, \
      lon_verts_by_cell, lat_verts_by_cell, \
;
      num_halo_portions, dims_halo_portions, \
      v, p, \
;
      lon_verts_halo_portions, lat_verts_halo_portions, \
;
      nx, ny, i_start, i_end, j_start, j_end, \
      inds_x, inds_y, lon_crnt_portion, lat_crnt_portion, \
      lon, lat, num_verts_per_cell, v, v_ref, \
;
      abs_del_lon, is_greater, \
      out

begin
;
; **********************************************************************
;
; Open the FV3-LAM grid file containing grid information.
;
; **********************************************************************
;
  f_grid = addfile(grid_file, "r")
;
; Get the dimensions of the tile 7 supergrid.
;
  dim_sizes = getfiledimsizes(f_grid)
  two_nx = dim_sizes(1)
  two_ny = dim_sizes(2)
;
; **********************************************************************
;
; Calculate the dimensions of the tile 7 computational grid.
;
; **********************************************************************
;
  nx = two_nx/2
  ny = two_ny/2
  nxp = nx + 1
  nyp = ny + 1

;print("")
;print("nx = " + nx)
;print("ny = " + ny)

;
; Set variable containing one plus the number of cells in the halo.
;
  nhp = nh + 1
;
; Generate Fortran i and j indices of mass points in the bottom, top, 
; left, and right portions of the halo.
;
  i_bottom = ispan(1, nx, 1)
  j_bottom = ispan(1, nh, 1)

  i_top = i_bottom
  j_top = ispan(ny - nh + 1, ny, 1)

  i_left = ispan(1, nh, 1)
  j_left = ispan(nh + 1, ny - nh, 1)

  i_right = ispan(nx - nh + 1, nx, 1)
  j_right = j_left
;
; Generate Fortran i and j indices of west cell faces in the bottom, 
; top, left, and right portions of the halo.
;
  i_w_bottom = ispan(1, nxp, 1)
  j_w_bottom = ispan(1, nh, 1)

  i_w_top = i_w_bottom
  j_w_top = ispan(ny - nh + 1, ny, 1)

  i_w_left = ispan(1, nhp, 1)
  j_w_left = ispan(nh + 1, ny - nh, 1)

  i_w_right = ispan(nxp - nhp + 1, nxp, 1)
  j_w_right = j_w_left
;
; Generate Fortran i and j indices of south cell faces in the bottom, 
; top, left, and right portions of the halo.
;
  i_s_bottom = ispan(1, nx, 1)
  j_s_bottom = ispan(1, nhp, 1)

  i_s_top = i_s_bottom
  j_s_top = ispan(nyp - nhp + 1, nyp, 1)

  i_s_left = ispan(1, nh, 1)
  j_s_left = ispan(nhp + 1, nyp - nhp, 1)

  i_s_right = ispan(nxp - nhp + 1, nxp, 1)
  j_s_right = j_s_left
;
; The following are indices to generate coordinates that include an ex-
; tra row below and an extra row above the south-face coordinates of the 
; left and right portions of the halo.
;
  j_s_left_plot = ispan(nhp, nyp - nhp + 1, 1)
  j_s_right_plot = j_s_left_plot
;
; Read in the supergrid coordinates.  The supergrid of a given tile is a
; grid having twice the resolution of the actual (i.e. computational)
; grid of that tile.  It is used to store the coordintes of both the
; centers and the vertices of the cells on the computational grid.
;
  lon_verts_supergrid := f_grid->x(:,:)
  lat_verts_supergrid := f_grid->y(:,:)
;
; Make sure that longitudes are in the range -180 deg <= lon < 180 deg.
;
  lon_min = -180.0
  lon_verts_supergrid := adjust_longitude_range( \
                         lon_verts_supergrid, lon_min, "degs")
;
; Get the coordinates of the cell vertices on the current tile.
;
  lon_verts := lon_verts_supergrid(0::2,0::2)
  lat_verts := lat_verts_supergrid(0::2,0::2)
;
; Get the coordinates of the cell centers on the current tile.
;
  lon_cntrs := lon_verts_supergrid(1::2,1::2)
  lat_cntrs := lat_verts_supergrid(1::2,1::2)
;
; Delete supergrid coordinates to save memory.
;
  delete([/ lon_verts_supergrid, lat_verts_supergrid /])
;
; Set cell center and cell vertex coordinates of cells in the bottom 
; portion of the halo.
;
  lon_cntrs_bottom = (/ lon_cntrs(j_bottom-1, i_bottom-1) /)
  lat_cntrs_bottom = (/ lat_cntrs(j_bottom-1, i_bottom-1) /)

  lon_verts_bottom = (/ lon_verts(j_s_bottom-1, i_w_bottom-1) /)
  lat_verts_bottom = (/ lat_verts(j_s_bottom-1, i_w_bottom-1) /)
;
; Set cell center and cell vertex coordinates of cells in the top por-
; tion of the halo.
;
  lon_cntrs_top = (/ lon_cntrs(j_top-1, i_top-1) /)
  lat_cntrs_top = (/ lat_cntrs(j_top-1, i_top-1) /)

  lon_verts_top = (/ lon_verts(j_s_top-1, i_w_top-1) /)
  lat_verts_top = (/ lat_verts(j_s_top-1, i_w_top-1) /)
;
; Set cell center and cell vertex coordinates of cells in the left por-
; tion of the halo.
;
  lon_cntrs_left = (/ lon_cntrs(j_left-1, i_left-1) /)
  lat_cntrs_left = (/ lat_cntrs(j_left-1, i_left-1) /)

  lon_verts_left = (/ lon_verts(j_s_left-1, i_w_left-1) /)
  lat_verts_left = (/ lat_verts(j_s_left-1, i_w_left-1) /)

  lon_verts_left_plot = (/ lon_verts(j_s_left_plot-1, i_w_left-1) /)
  lat_verts_left_plot = (/ lat_verts(j_s_left_plot-1, i_w_left-1) /)
;
; Set cell center and cell vertex coordinates of cells in the right por-
; tion of the halo.
;
  lon_cntrs_right = (/ lon_cntrs(j_right-1, i_right-1) /)
  lat_cntrs_right = (/ lat_cntrs(j_right-1, i_right-1) /)

  lon_verts_right = (/ lon_verts(j_s_right-1, i_w_right-1) /)
  lat_verts_right = (/ lat_verts(j_s_right-1, i_w_right-1) /)

  lon_verts_right_plot = (/ lon_verts(j_s_right_plot-1, i_w_right-1) /)
  lat_verts_right_plot = (/ lat_verts(j_s_right_plot-1, i_w_right-1) /)
;
; Get the dimensions of the grids for the bottom, top, left, and right
; portions of the halo around regional domain.  Then calculate the num-
; ber of cells in each of these four portions.
;
  dims_bottom = dimsizes(lon_cntrs_bottom)
  nx_bottom = dims_bottom(1)
  ny_bottom = dims_bottom(0)
  num_cells_bottom = nx_bottom*ny_bottom

  dims_top = dimsizes(lon_cntrs_top)
  nx_top = dims_top(1)
  ny_top = dims_top(0)
  num_cells_top = nx_top*ny_top

  dims_left = dimsizes(lon_cntrs_left)
  nx_left = dims_left(1)
  ny_left = dims_left(0)
  num_cells_left = nx_left*ny_left

  dims_right = dimsizes(lon_cntrs_right)
  nx_right = dims_right(1)
  ny_right = dims_right(0)
  num_cells_right = nx_right*ny_right
;
; Calculate the total number of cells in the halo.
;
  num_cells_total = num_cells_bottom + num_cells_top \
                  + num_cells_left + num_cells_right

print("")
print("num_cells_bottom = " + num_cells_bottom)
print("num_cells_top = " + num_cells_top)
print("num_cells_left = " + num_cells_left)
print("num_cells_right = " + num_cells_right)
print("")
print("num_cells_total = " + num_cells_total)

;
; For plotting purposes, allocate arrays to hold the coordinates of the 
; four corners of each cell to be plotted (i.e. of each cell in the ha-
; lo).  The first dimension of these arrays is the number of cells in 
; the halo.  This is simply the sum of the number of cells in the bot-
; tom, top, left, and right portions of the halo.  The second dimension
; of these arrays is the number of vertices per cell, which in the case
; of the cubed-sphere grid is always 4.
;
  num_verts_per_cell = 4
  lon_cntrs_by_cell := new((/ num_cells_total /), "double")
  lat_cntrs_by_cell := new((/ num_cells_total /), "double")
  lon_verts_by_cell := new((/ num_cells_total, num_verts_per_cell /), "double")
  lat_verts_by_cell := new((/ num_cells_total, num_verts_per_cell /), "double")
;
; Create string array containing a descriptive name for each of the four
; portions of the halo.  Then set the number of halo portions (which is
; just 4).  Finally, for convenience, set a 2-D array containing the di-
; mensions of these four portions.
;
;  halo_portion_names = (/"bottom", "top", "left", "right"/)
;  num_halo_portions = dimsizes(halo_portion_names)
  num_halo_portions = 4
  dims_halo_portions = (/ (/ ny_bottom, nx_bottom /), \
                          (/ ny_top, nx_top /), \
                          (/ ny_left, nx_left /), \
                          (/ ny_right, nx_right /) /)
;
; Create lists containing the longitudes and latitudes of the centers of
; cells in each portion of the halo.  Then loop through these lists and
; generate arrays
;
  lon_cntrs_halo_portions := [/ lon_cntrs_bottom, lon_cntrs_top, \
                                lon_cntrs_left, lon_cntrs_right /]
  lat_cntrs_halo_portions := [/ lat_cntrs_bottom, lat_cntrs_top, \
                                lat_cntrs_left, lat_cntrs_right /]

  do p=0,num_halo_portions-1
    lon_crnt_portion := ndtooned(lon_cntrs_halo_portions[p])
    lat_crnt_portion := ndtooned(lat_cntrs_halo_portions[p])
    if (p .eq. 0) then
      lon_cntrs_by_cell := lon_crnt_portion
      lat_cntrs_by_cell := lat_crnt_portion
    else
      lon_cntrs_by_cell := array_append_record(lon_cntrs_by_cell, lon_crnt_portion, 0)
      lat_cntrs_by_cell := array_append_record(lat_cntrs_by_cell, lat_crnt_portion, 0)
    end if
  end do

  delete([/ lon_cntrs_halo_portions, lat_cntrs_halo_portions /])
;
; Create lists containing the longitudes and latitudes of the vertices
; of cells in each portion of the halo.
;
  lon_verts_halo_portions \
  := [/ lon_verts_bottom, lon_verts_top, \
        lon_verts_left_plot, lon_verts_right_plot /]  ; Notice the _plot.  Rename?
  lat_verts_halo_portions \
  := [/ lat_verts_bottom, lat_verts_top, \
        lat_verts_left_plot, lat_verts_right_plot /]  ; Notice the _plot.  Rename?
;
; Loop over the four vertices of each cell and over the four regions of
; the halo and assign the coordinates of vertices of each cell.
;
  do v=0, num_verts_per_cell-1

    do p=0,num_halo_portions-1
;
; Get the dimensions of the current halo portion.
;
      nx = dims_halo_portions(p,1)
      ny = dims_halo_portions(p,0)
;
; Set the range of indices in each direction of the subarrays to extract
; from the full coordinate arrays.
;
      if (v .eq. 0) then
        i_start = 0
        i_end = nx - 1
        j_start = 0
        j_end = ny - 1
      else if (v .eq. 1) then
        i_start = 1
        i_end = nx
        j_start = 0
        j_end = ny - 1
      else if (v .eq. 2) then
        i_start = 1
        i_end = nx
        j_start = 1
        j_end = ny
      else if (v .eq. 3) then
        i_start = 0
        i_end = nx - 1
        j_start = 1
        j_end = ny
      end if
      end if
      end if
      end if

      inds_x := ispan(i_start, i_end, 1)
      inds_y := ispan(j_start, j_end, 1)
;
; Get longitudes of the current vertex of all cells in the current halo 
; portion.
;
      lon_crnt_portion := lon_verts_halo_portions[p]
      lon_crnt_portion := ndtooned(lon_crnt_portion(inds_y, inds_x))
;
; Get latitudes of the current vertex of all cells in the current halo 
; portion.
;
      lat_crnt_portion := lat_verts_halo_portions[p]
      lat_crnt_portion := ndtooned(lat_crnt_portion(inds_y, inds_x))
;
; Construct the arrays containing the coordinates of the current vertex
; of all cells in the halo.
;
      if (p .eq. 0) then
        lon := lon_crnt_portion
        lat := lat_crnt_portion
      else
        lon := array_append_record(lon, lon_crnt_portion, 0)
        lat := array_append_record(lat, lat_crnt_portion, 0)
      end if

    end do

;print("")
;print("v = " + v)
;print("max(lon) = " + max(lon))
;print("max(lat) = " + max(lat))
;pause

    lon_verts_by_cell(:,v) = lon
    lat_verts_by_cell(:,v) = lat

  end do
;
; Delete unneeded work arrays.
;
  delete([/ lon_verts_halo_portions, lat_verts_halo_portions, lon, lat /])
;
; For cells that cross over the international date line, modify longi-
; tudes of the vertices so that there is no discontinuity in their val-
; ues.
;
if (False) then
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
  delete([/ abs_del_lon, is_greater /])
end if
;
; **********************************************************************
;
; Return various output variables as attributes of the "out" variable.
;
; **********************************************************************
;
  out = True
  out@num_cells_total = num_cells_total
  out@lon_cntrs_by_cell = lon_cntrs_by_cell
  out@lat_cntrs_by_cell = lat_cntrs_by_cell
  out@lon_verts_by_cell = lon_verts_by_cell
  out@lat_verts_by_cell = lat_verts_by_cell
  return(out)

end






