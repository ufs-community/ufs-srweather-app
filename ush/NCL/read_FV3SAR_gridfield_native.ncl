;
; **********************************************************************
;
; File name: read_FV3SAR_field_native.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns 
;
; **********************************************************************
;
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "calc_field_stats.ncl")

load "check_var_existence_dims.ncl"

undef("read_FV3SAR_field_native")

function read_FV3SAR_field_native( \
         field_name:string, \
         horiz_dist_units:string, \
         horiz_area_units:string, \
         gtype:string, \
         grid_files[*]:string, \
         tile_inds[*]:integer, \
         nx_by_tile[*]:integer, \
         ny_by_tile[*]:integer, \
         vert_inds_to_plot[*]:integer, \
         time_inds_to_plot[*]:integer, \
         vert_indx:integer, \
         time_indx:integer, \
         remove_rgnl_halo:logical, \
         nhalo_T7:integer \
         )

local calc_dA_cell_cntrs, \
      calc_dx_cell_cntrs, \
      calc_dy_cell_cntrs, \
      calc_dx_cell_faces, \
      calc_dy_cell_faces, \
      calc_angle_dx_cell_cntrs, \
      calc_angle_dy_cell_cntrs, \
;
      field_desc, field_units, \
;
      num_tiles, \
      field_min_all_tiles, field_max_all_tiles, \
      field_median_all_tiles, field_mean_all_tiles, \
      nn, msg, underline, n_tile, nx, ny, msg_adden, \
      fp, \
      field_data_type, \
;
      dA_SG_crnt_tile, \
      quarter_dA_lb_crnt_tile, quarter_dA_rb_crnt_tile, \
      quarter_dA_rt_crnt_tile, quarter_dA_lt_crnt_tile, \
      dA_crnt_tile, \
;
      dx_SG_crnt_tile, \
      half_dx_left_crnt_tile, half_dx_right_crnt_tile, \
      dx_cntr_crnt_tile, \
;
      dy_SG_crnt_tile, \
      half_dy_bot_crnt_tile, half_dy_top_crnt_tile, \
      dy_cntr_crnt_tile, \
;
      dx_face_crnt_tile, \
      dy_face_crnt_tile, \
;
      angle_dx_SG_crnt_tile, angle_dx_cntr_crnt_tile, \
;
      angle_dy_SG_crnt_tile, angle_dy_cntr_crnt_tile, \
;
      dims_SG_with_halo, dims_with_halo, \
;
      field_crnt_tile, \
;
      dxmin_crnt_tile, dymin_crnt_tile, min_dx_dy_crnt_tile, \
;
      dims_with_halo, nx_with_halo, ny_with_halo, \
;
      field_all_tiles_unstruc, \
;
      print_field_stats, field_stat_info, msg, \
;
      field_info

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
; Set field-related parameters.
;
; **********************************************************************
;
  calc_dA_cell_cntrs = False
  calc_dx_cell_cntrs = False
  calc_dy_cell_cntrs = False
  calc_dx_cell_faces = False
  calc_dy_cell_faces = False
  calc_angle_dx_cell_cntrs = False
  calc_angle_dy_cell_cntrs = False

  if (strcmp_exact(field_name, "none")) then

    field_desc = "Empty Field"
    field_units = "-"

  else if (strcmp_exact(field_name, "area")) then

    calc_dA_cell_cntrs = True
    field_desc = "Cell Area"
    field_units = horiz_area_units

  else if (strcmp_exact(field_name, "sqrt_area")) then

    calc_dA_cell_cntrs = True
    field_desc = "Square Root of Cell Area"
    field_units = horiz_dist_units

  else if (strcmp_exact(field_name, "dx")) then

    calc_dx_cell_cntrs = True
    field_desc = "Cell Size in x-Direction Along Cell Centerline"
    field_units = horiz_dist_units

  else if (strcmp_exact(field_name, "dy")) then

    calc_dy_cell_cntrs = True
    field_desc = "Cell Size in y-Direction Along Cell Centerline"
    field_units = horiz_dist_units

  else if (strcmp_exact(field_name, "dx_ovr_dy")) then

    calc_dx_cell_cntrs = True
    calc_dy_cell_cntrs = True
    field_desc = "Ratio of dx to dy (dx/dy)"
    field_units = "-"

  else if (strcmp_exact(field_name, "min_dx_dy")) then

    calc_dx_cell_faces = True
    calc_dy_cell_faces = True
    field_desc = "MIN(dx, dy)"
    field_units = horiz_dist_units

  else if (strcmp_exact(field_name, "angle_dx")) then

    calc_angle_dx_cell_cntrs = True
    field_desc = "Grid Vertex x-Angle with Respect to Geographic East"
    field_units = "deg east"

  else if (strcmp_exact(field_name, "angle_dy")) then

    calc_angle_dy_cell_cntrs = True
    field_desc = "Grid Vertex y-Angle with Respect to Geographic North"
    field_units = "deg north"

;  else
;
;    field_desc = "Unknown Field"
;    field_units = "?"

  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
;
; **********************************************************************
;
; Loop through the specified tiles and read in the grid geometry (i.e.
; coordinates of the cell center and cell vertices) and the value of the
; specified field for each cell.
;
; **********************************************************************
;
  num_tiles = dimsizes(tile_inds)

  print("")
  print("" + separator_line)
  print("Reading field(s) from grid files ...")

  do nn=0, num_tiles-1

    print("")
    msg := "nn = " + nn
    print("" + msg)
    underline = repeat_str("-", strlen(msg))
    print("" + underline)

    n_tile = tile_inds(nn)
    print("")
    print("  n_tile = " + n_tile)
;
; **********************************************************************
;
; Get the number of cells in each of the two (horizontal) directions on
; the current tile.
;
; **********************************************************************
;
    nx = nx_by_tile(nn)
    ny = ny_by_tile(nn)

    msg_adden = ""
    if (strcmp_exact(gtype, "regional") .and. \
        (n_tile .eq. 7) .and. remove_rgnl_halo) then
      msg_adden = " (AFTER removing halo of " + nhalo_T7 + " cells)"
    end if

    print("")
    print("  Current tile's dimensions" + msg_adden + " are:")
    print("    nx = " + nx)
    print("    ny = " + ny)




;
; **********************************************************************
;
;
;
; **********************************************************************
;
    x_filedim_names = (/ "grid_xt" /)
    y_filedim_names = (/ "grid_yt" /)
    z_filedim_names = (/ "pfull", "phalf" /)
    t_filedim_names = (/ "time" /)
  
    var_info := check_var_existence_dims( \
                grid_files, \
                field_name, \
                x_filedim_names, \
                y_filedim_names, \
                z_filedim_names, \
                t_filedim_names, \
                vert_inds_to_plot, \
                time_inds_to_plot)
  
    var_rank = var_info@var_rank
    var_dim_names = var_info@var_dim_names
    var_dim_sizes = var_info@var_dim_sizes
    func_xy_only = var_info@func_xy_only
    func_xyz_only = var_info@func_xyz_only
    func_xyt_only = var_info@func_xyt_only
    func_xyzt_only = var_info@func_xyzt_only
;
; **********************************************************************
;
; Open the NetCDF file containing the grid specification for the current 
; tile.  This file also includes certain grid-related fields (e.g. cell
; area).
;
; **********************************************************************
;
    fp = addfile(grid_files(nn), "r")
;
; **********************************************************************
;
; Get the data type of the various fields in the grid file (i.e. float
; or double).  We assume all fields in the file have the same data type.
; Thus, we need to find the data type of only one such field.  Here, we
; use the "area" field for this purpose.
;
; **********************************************************************
;
;    field_data_type = getfilevartypes(fp, "area")
    field_data_type = getfilevartypes(fp, "ugrd")  ; The variable used here will depend on the file being opened.
;
; **********************************************************************
;
; Read one or more fields from the grid file.
;
; **********************************************************************
;
    print("")
    print("  Reading field(s) from file:")
    print("    grid_files(" + nn + ") = " + char_dq + grid_files(nn) + char_dq) 
;
; **********************************************************************
;
; Calculate cell areas.
;
; **********************************************************************
;
    if (calc_dA_cell_cntrs) then

      dA_SG_crnt_tile := fp->area(:,:)

      quarter_dA_lb_crnt_tile := dA_SG_crnt_tile(0::2,0::2)
      quarter_dA_rb_crnt_tile := dA_SG_crnt_tile(0::2,1::2)
      quarter_dA_rt_crnt_tile := dA_SG_crnt_tile(1::2,1::2)
      quarter_dA_lt_crnt_tile := dA_SG_crnt_tile(1::2,0::2)

      dA_crnt_tile := quarter_dA_lb_crnt_tile \
                    + quarter_dA_rb_crnt_tile \
                    + quarter_dA_rt_crnt_tile \
                    + quarter_dA_lt_crnt_tile 

      delete([/ dA_SG_crnt_tile, \
                quarter_dA_lb_crnt_tile, \
                quarter_dA_rb_crnt_tile, \
                quarter_dA_rt_crnt_tile, \
                quarter_dA_lt_crnt_tile /])
;
; **********************************************************************
;
; Calculate cell size in x direction along cell centerlines.
;
; **********************************************************************
;
    else if (calc_dx_cell_cntrs) then

      dx_SG_crnt_tile := fp->dx(:,:)

      half_dx_left_crnt_tile := dx_SG_crnt_tile(1::2,0::2)
      half_dx_right_crnt_tile := dx_SG_crnt_tile(1::2,1::2)

      dx_cntr_crnt_tile \
      := half_dx_left_crnt_tile + half_dx_right_crnt_tile

      delete([/ dx_SG_crnt_tile, \
                half_dx_left_crnt_tile, \
                half_dx_right_crnt_tile /])
;
; **********************************************************************
;
; Calculate cell size in y direction along cell centerlines.
;
; **********************************************************************
;
    else if (calc_dy_cell_cntrs) then

      dy_SG_crnt_tile := fp->dy(:,:)

      half_dy_bot_crnt_tile := dy_SG_crnt_tile(0::2,1::2)
      half_dy_top_crnt_tile := dy_SG_crnt_tile(1::2,1::2)

      dy_cntr_crnt_tile \
      := half_dy_bot_crnt_tile + half_dy_top_crnt_tile

      delete([/ dy_SG_crnt_tile, \
                half_dy_bot_crnt_tile, \
                half_dy_top_crnt_tile /])
;
; **********************************************************************
;
; Calculate cell size in x direction along cell faces.
;
; **********************************************************************
;
    else if (calc_dx_cell_faces) then

      dx_SG_crnt_tile := fp->dx(:,:)

      half_dx_left_crnt_tile := dx_SG_crnt_tile(0::2,0::2)
      half_dx_right_crnt_tile := dx_SG_crnt_tile(0::2,1::2)

      dx_face_crnt_tile \
      := half_dx_left_crnt_tile + half_dx_right_crnt_tile

      delete([/ dx_SG_crnt_tile, \
                half_dx_left_crnt_tile, \
                half_dx_right_crnt_tile /])
;
; **********************************************************************
;
; Calculate cell size in y direction along cell faces.
;
; **********************************************************************
;
    else if (calc_dy_cell_faces) then

      dy_SG_crnt_tile := fp->dy(:,:)

      half_dy_bot_crnt_tile := dy_SG_crnt_tile(0::2,0::2)
      half_dy_top_crnt_tile := dy_SG_crnt_tile(1::2,0::2)

      dy_face_crnt_tile \
      := half_dy_bot_crnt_tile + half_dy_top_crnt_tile

      delete([/ dy_SG_crnt_tile, \
                half_dy_bot_crnt_tile, \
                half_dy_top_crnt_tile /])
;
; **********************************************************************
;
; Calculate grid x-angle with respect to geographic east.
;
; **********************************************************************
;
    else if (calc_angle_dx_cell_cntrs) then

      angle_dx_SG_crnt_tile := fp->angle_dx(:,:)
      angle_dx_cntr_crnt_tile := angle_dx_SG_crnt_tile(1::2,1::2)
      delete([/ angle_dx_SG_crnt_tile /])
;
; **********************************************************************
;
; Calculate grid y-angle with respect to geographic north.
;
; **********************************************************************
;
    else if (calc_angle_dy_cell_cntrs) then

      angle_dy_SG_crnt_tile := fp->angle_dy(:,:)
      angle_dy_cntr_crnt_tile := angle_dy_SG_crnt_tile(1::2,1::2)
      delete([/ angle_dy_SG_crnt_tile /])

    end if
    end if
    end if
    end if
    end if
    end if
    end if

    print("  Done reading field(s) from file.")
;
; **********************************************************************
;
; Get or calculate the field to plot and store it in the array field_-
; crnt_tile.  Also, set the strings describing the field (field_desc), 
; its units (field_units), and the plot title (plot_title).
;
; **********************************************************************
;
    if (strcmp_exact(field_name, "none")) then
;
; If field_name is set to "none", we create a 2-D array of missing val-
; ues of whatever data type the fields are in the file.  Note that if 
; the current tile is tile 7, the dimensions of this array will include
; the halo.  The halo will be removed later below if the grid type is 
; regional, the current tile is tile 7, and remove_rgnl_halo is set to 
; True.
;
      dims_SG_with_halo = getfilevardimsizes(fp, "area")
      dims_with_halo = dims_SG_with_halo/2
      field_crnt_tile := new(dims_with_halo, field_data_type)

    else if (strcmp_exact(field_name, "area")) then

      field_crnt_tile := dA_crnt_tile
      delete(dA_crnt_tile)
      if (strcmp_exact(field_units, "km^2")) then
        field_crnt_tile := field_crnt_tile/1.0d+6
      end if

    else if (strcmp_exact(field_name, "sqrt_area")) then

      field_crnt_tile := sqrt(dA_crnt_tile)
      delete(dA_crnt_tile)
      if (strcmp_exact(field_units, "km")) then
        field_crnt_tile := field_crnt_tile/1.0d+3
      end if

    else if (strcmp_exact(field_name, "dx")) then

      field_crnt_tile := dx_cntr_crnt_tile
      delete(dx_cntr_crnt_tile)
      if (strcmp_exact(field_units, "km")) then
        field_crnt_tile := field_crnt_tile/1.0d+3
      end if

    else if (strcmp_exact(field_name, "dy")) then

      field_crnt_tile := dy_cntr_crnt_tile
      delete(dy_cntr_crnt_tile)
      if (strcmp_exact(field_units, "km")) then
        field_crnt_tile := field_crnt_tile/1.0d+3
      end if

    else if (strcmp_exact(field_name, "dx_ovr_dy")) then

      field_crnt_tile := dx_cntr_crnt_tile/dy_cntr_crnt_tile
      delete([/ dx_cntr_crnt_tile, dy_cntr_crnt_tile /])

    else if (strcmp_exact(field_name, "min_dx_dy")) then

      dxmin_crnt_tile \
      := where(dx_face_crnt_tile(0:ny-1,:) .lt. dx_face_crnt_tile(1:,:), \
               dx_face_crnt_tile(0:ny-1,:), dx_face_crnt_tile(1:,:))

      dymin_crnt_tile \
      := where(dy_face_crnt_tile(:,0:nx-1) .lt. dy_face_crnt_tile(:,1:), \
               dy_face_crnt_tile(:,0:nx-1), dy_face_crnt_tile(:,1:))

      min_dx_dy_crnt_tile \
      := where(dxmin_crnt_tile .lt. dymin_crnt_tile, \
               dxmin_crnt_tile, dymin_crnt_tile)

      field_crnt_tile := min_dx_dy_crnt_tile

      delete([/ dxmin_crnt_tile, \
                dymin_crnt_tile, \
                min_dx_dy_crnt_tile /])

      if (strcmp_exact(field_units, "km")) then
        field_crnt_tile := field_crnt_tile/1.0d+3
      end if

    else if (strcmp_exact(field_name, "angle_dx")) then

      field_crnt_tile := angle_dx_cntr_crnt_tile
      delete(angle_dx_cntr_crnt_tile)

    else if (strcmp_exact(field_name, "angle_dy")) then

      field_crnt_tile := angle_dy_cntr_crnt_tile
      delete(angle_dy_cntr_crnt_tile)
;
; **********************************************************************
;
;
;
; **********************************************************************
;
    else

      if (func_xy_only) then
        field_crnt_tile := fp->$field_name$(:,:)
      else if (func_xyz_only) then
        field_crnt_tile := fp->$field_name$(vert_indx,:,:)
      else if (func_xyt_only) then
        field_crnt_tile := fp->$field_name$(time_indx,:,:)
      else if (func_xyzt_only) then
        field_crnt_tile := fp->$field_name$(time_indx,vert_indx,:,:)
      end if
      end if
      end if
      end if

      field_desc = field_crnt_tile@long_name
      field_units = field_crnt_tile@units

    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
;
; **********************************************************************
;
; Consider fields in the orography file.
;
; **********************************************************************
;
if (False) then

; The following works with tile 7 only!!
;    else if (strcmp_exact(field_name, "orog_raw")) then
    if (strcmp_exact(field_name, "orog_filt")) then

;      orog_file = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/C384r0p7n3_regional_RAP/orog/oro.C384.tile7.nc"
;      orog_file = grid_dir + "/oro_data.nc"
;      orog_file = work_dir + "/filtered_topo/oro." + cres + ".tile" + n_tile + ".halo6.nc"
      orog_file = work_dir + "/orog/oro." + cres + ".tile" + n_tile + ".halo6.nc"
      f_orog = addfile(orog_file, "r")
;      field_crnt_tile = f_orog->orog_raw
      field_crnt_tile = f_orog->orog_filt

      field_desc = "Raw Orography"
      field_units = "m"
      plot_title = field_desc + " [" + field_units + "]"

      dims_with_halo = dimsizes(field_crnt_tile)
      nx_with_halo = dims_with_halo(1)
      ny_with_halo = dims_with_halo(0)
hh = 2
      field_crnt_tile \
      := field_crnt_tile( \
         hh:ny_with_halo-1-hh, \
         hh:nx_with_halo-1-hh)

; The following works with tile 7 only!!
    else if (strcmp_exact(field_name, "orog_filt")) then

      orog_file = grid_dir + "/oro_data.nc"
      f_orog = addfile(orog_file, "r")
      field_crnt_tile = f_orog->orog_filt

      field_desc = "Filtered Orography"
      field_units = "m"
      plot_title = field_desc + " [" + field_units + "]"

    else if (strcmp_exact(field_name, "PRESsfc")) then

      file_name = grid_dir + "/../nggps2d.nc"
      f_unit = addfile(file_name, "r")
      field_crnt_tile = f_unit->$field_name$(fcst_hr-1,:,:)
      pascals_per_millibar = 100.0d
      field_crnt_tile := field_crnt_tile/pascals_per_millibar

      field_desc = f_unit->$field_name$@long_name
      field_units = f_unit->$field_name$@units
      plot_title = field_desc + " [" + field_units + "]"

    else if (strcmp_exact(field_name, "slp") .or. \
             strcmp_exact(field_name, "u1000") .or. \
             strcmp_exact(field_name, "v1000") .or. \
             strcmp_exact(field_name, "t1000") .or. \
             strcmp_exact(field_name, "q1000") .or. \
             strcmp_exact(field_name, "rh1000") .or. \
             strcmp_exact(field_name, "us") .or. \
             strcmp_exact(field_name, "vs") .or. \
             strcmp_exact(field_name, "vort850")) then

      file_name = grid_dir + "/../atmos_4xdaily.nc"
      f_unit = addfile(file_name, "r")
      field_crnt_tile = f_unit->$field_name$(1,:,:)
      field_desc = f_unit->$field_name$@long_name
      field_units = f_unit->$field_name$@units
      plot_title = field_desc + " [" + field_units + "]"

    else if (strcmp_exact(field_name, "ucomp") .or. \
             strcmp_exact(field_name, "vcomp") .or. \
             strcmp_exact(field_name, "nhpres"))

      file_name = grid_dir + "/../nggps3d_4xdaily.nc"
      f_unit = addfile(file_name, "r")
      k = 60
      ref_pres_full = f_unit->pfull(:)
      field_crnt_tile = f_unit->$field_name$(1,k,:,:)
      field_desc = f_unit->$field_name$@long_name
      field_units = f_unit->$field_name$@units
      plot_title = field_desc + " at pref = " + ref_pres_full(k) + " mb [" + field_units + "]"

    else

      dims_SG_with_halo = getfilevardimsizes(fp, "area")
      dims_with_halo = dims_SG_with_halo/2
      field_crnt_tile := new(dims_with_halo, field_data_type)

    end if
    end if
    end if
    end if
    end if

end if
;
; **********************************************************************
;
; If on a regional grid and on tile 7 and if remove_rgnl_halo is set to
; True, remove the halo from the field calculated above (field_crnt_-
; tile).
;
; **********************************************************************
;
    if (strcmp_exact(gtype, "regional") .and. \
        (n_tile .eq. 7) .and. remove_rgnl_halo) then

      print("")
      print("  Removing halo cells from field (" + \
            char_dq + field_name + char_dq + \
            ") on tile " + n_tile + " ...")

      dims_with_halo = dimsizes(field_crnt_tile)
      nx_with_halo = dims_with_halo(1)
      ny_with_halo = dims_with_halo(0)

      field_crnt_tile \
      := field_crnt_tile( \
         nhalo_T7:ny_with_halo-1-nhalo_T7, \
         nhalo_T7:nx_with_halo-1-nhalo_T7)

      print("  Done removing halo cells from field on tile " + n_tile + ".")

    end if
;
; **********************************************************************
;
; If on the first tile, convert the 2-D array containing the field val-
; ues at cell centers to a 1-D unstructured array.  If on the second, 
; third, etc tile, perform this conversion and then concatenate the re-
; sult to the 1-D unstructured array containing the field values on the
; previous tile(s).
;
; **********************************************************************
;
    if (nn .eq. 0) then
      field_all_tiles_unstruc := ndtooned(field_crnt_tile)
    else
      field_all_tiles_unstruc \
      := array_append_record(field_all_tiles_unstruc, ndtooned(field_crnt_tile), 0)
    end if
;
; **********************************************************************
;
; Calculate (and possibly print out) basic statistics of the field.
;
; **********************************************************************
;
    msg := "  Calculating statistics of field on the tile " + n_tile \
         + " grid ..."
    print("")
    print("" + msg)

;    print_field_stats = True
    print_field_stats = False
    field_stat_info \
    := calc_field_stats( \
       field_crnt_tile, field_desc, field_units, print_field_stats)
    msg := "  " + field_stat_info@msg
    print("")
    print("" + msg)

    msg := "  Done calculating statistics of field on the tile " + n_tile \
         + " grid."
    print("")
    print("" + msg)
;
; **********************************************************************
;
; Save field statistics in appropriate arrays.
;
; **********************************************************************
;
    if (nn .eq. 0) then
      field_min_all_tiles := new((/ num_tiles /), field_data_type)
      field_max_all_tiles := new((/ num_tiles /), field_data_type)
      field_median_all_tiles := new((/ num_tiles /), field_data_type)
      field_mean_all_tiles := new((/ num_tiles /), field_data_type)
    end if

    field_min_all_tiles(nn) = field_stat_info@field_min
    field_max_all_tiles(nn) = field_stat_info@field_max
    field_median_all_tiles(nn) = field_stat_info@field_median
    field_mean_all_tiles(nn) = field_stat_info@field_mean

  end do

  print("")
  print("Done reading field(s) from grid files.")
  print("" + separator_line)
;
; **********************************************************************
;
; Return results as attributes of the logical variable field_info.
;
; **********************************************************************
;
  field_info = True

  field_info@field_desc = field_desc
  field_info@field_units = field_units
  field_info@field_all_tiles_unstruc = field_all_tiles_unstruc
  field_info@field_min_all_tiles = field_min_all_tiles
  field_info@field_max_all_tiles = field_max_all_tiles
  field_info@field_median_all_tiles = field_median_all_tiles
  field_info@field_mean_all_tiles = field_mean_all_tiles
  field_info@field_data_type = field_data_type

  return(field_info)

end







