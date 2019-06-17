;
; **********************************************************************
;
; File name: read_FV3SAR_gridfield_native.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns 
;
; **********************************************************************
;
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "calc_field_stats.ncl")

load "get_gridfield_info.ncl"

undef("read_FV3SAR_gridfield_native")

function read_FV3SAR_gridfield_native( \
         field_names_by_tile[*]:string, \
         file_names_by_tile[*]:string, \
         gtype:string, \
         tile_inds[*]:integer, \
         nh_by_tile[*]:integer, \
         nxh_by_tile[*]:integer, \
         nyh_by_tile[*]:integer, \
         nx_by_tile[*]:integer, \
         ny_by_tile[*]:integer, \
         remove_halo_by_tile[*]:logical, \
         vert_indx:integer, \
         time_indx:integer, \
         horiz_dist_units:string, \
         horiz_area_units:string \
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
      field_min_by_tile, field_max_by_tile, \
      field_median_by_tile, field_mean_by_tile, \
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
      field_by_tile_unstruc, \
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
; Create a string that can be used at the beginning of messages to iden-
; tify this procedure/function as the one generating the messge.
;
; **********************************************************************
;
  id_str := "Message from procedure/function read_FV3SAR_gridfield_native():"
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

  msg := "Looping over tiles to read field(s) from specified file(s) ..."
  print("")
  print("" + separator_line)
  print("" + msg)

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
    if (remove_halo_by_tile(nn)) then
      nx = nx_by_tile(nn)
      ny = ny_by_tile(nn)
      msg_adden \
      = "  (after removing halo of " + nh_by_tile(nn) + " cells)"
    else
      nx = nxh_by_tile(nn)
      ny = nyh_by_tile(nn)
      msg_adden = ""
    end if

    print("")
    print("  Current tile's grid dimensions" + msg_adden + " are:")
    print("    nx = " + nx)
    print("    ny = " + ny)
;
; **********************************************************************
;
; Get the file name and field name for the current tile.
;
; **********************************************************************
;
    file_name := file_names_by_tile(nn)
    field_name := field_names_by_tile(nn)
;
; **********************************************************************
;
; Open the file for the current tile for reading.
;
; **********************************************************************
;
    fp = addfile(file_name, "r")
;
; **********************************************************************
;
; Set the logical variables that determine the field to be calculated
; (or simply obtained from file).  Also, set the strings describing the
; field (field_desc) and its units (field_units).
;
; **********************************************************************
;
    gridfield_info \
    := get_gridfield_info(field_name, horiz_dist_units, horiz_area_units)

    field_desc := gridfield_info@gridfield_desc
    field_units := gridfield_info@gridfield_units
    filevar_names := gridfield_info@filevar_names
    calc_dA_cell_cntrs := gridfield_info@calc_dA_cell_cntrs
    calc_dx_cell_cntrs := gridfield_info@calc_dx_cell_cntrs
    calc_dy_cell_cntrs := gridfield_info@calc_dy_cell_cntrs
    calc_dx_cell_faces := gridfield_info@calc_dx_cell_faces
    calc_dy_cell_faces := gridfield_info@calc_dy_cell_faces
    calc_angle_dx_cell_cntrs := gridfield_info@calc_angle_dx_cell_cntrs
    calc_angle_dy_cell_cntrs := gridfield_info@calc_angle_dy_cell_cntrs
;
; **********************************************************************
;
; Read one or more fields from the grid file.
;
; **********************************************************************
;
    print("")
    print("  Reading field(s) from file:")
    print("    file_names_by_tile(" + nn + ") = " + char_dq + file_name + char_dq)
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

    end if
;
; **********************************************************************
;
; Calculate cell size in x direction along cell centerlines.
;
; **********************************************************************
;
    if (calc_dx_cell_cntrs) then

      dx_SG_crnt_tile := fp->dx(:,:)

      half_dx_left_crnt_tile := dx_SG_crnt_tile(1::2,0::2)
      half_dx_right_crnt_tile := dx_SG_crnt_tile(1::2,1::2)

      dx_cntr_crnt_tile \
      := half_dx_left_crnt_tile + half_dx_right_crnt_tile

      delete([/ dx_SG_crnt_tile, \
                half_dx_left_crnt_tile, \
                half_dx_right_crnt_tile /])

    end if
;
; **********************************************************************
;
; Calculate cell size in y direction along cell centerlines.
;
; **********************************************************************
;
    if (calc_dy_cell_cntrs) then

      dy_SG_crnt_tile := fp->dy(:,:)

      half_dy_bot_crnt_tile := dy_SG_crnt_tile(0::2,1::2)
      half_dy_top_crnt_tile := dy_SG_crnt_tile(1::2,1::2)

      dy_cntr_crnt_tile \
      := half_dy_bot_crnt_tile + half_dy_top_crnt_tile

      delete([/ dy_SG_crnt_tile, \
                half_dy_bot_crnt_tile, \
                half_dy_top_crnt_tile /])

    end if
;
; **********************************************************************
;
; Calculate cell size in x direction along cell faces.
;
; **********************************************************************
;
    if (calc_dx_cell_faces) then

      dx_SG_crnt_tile := fp->dx(:,:)

      half_dx_left_crnt_tile := dx_SG_crnt_tile(0::2,0::2)
      half_dx_right_crnt_tile := dx_SG_crnt_tile(0::2,1::2)

      dx_face_crnt_tile \
      := half_dx_left_crnt_tile + half_dx_right_crnt_tile

      delete([/ dx_SG_crnt_tile, \
                half_dx_left_crnt_tile, \
                half_dx_right_crnt_tile /])

    end if
;
; **********************************************************************
;
; Calculate cell size in y direction along cell faces.
;
; **********************************************************************
;
    if (calc_dy_cell_faces) then

      dy_SG_crnt_tile := fp->dy(:,:)

      half_dy_bot_crnt_tile := dy_SG_crnt_tile(0::2,0::2)
      half_dy_top_crnt_tile := dy_SG_crnt_tile(1::2,0::2)

      dy_face_crnt_tile \
      := half_dy_bot_crnt_tile + half_dy_top_crnt_tile

      delete([/ dy_SG_crnt_tile, \
                half_dy_bot_crnt_tile, \
                half_dy_top_crnt_tile /])

    end if
;
; **********************************************************************
;
; Calculate grid x-angle with respect to geographic east.
;
; **********************************************************************
;
    if (calc_angle_dx_cell_cntrs) then

      angle_dx_SG_crnt_tile := fp->angle_dx(:,:)
      angle_dx_cntr_crnt_tile := angle_dx_SG_crnt_tile(1::2,1::2)
      delete([/ angle_dx_SG_crnt_tile /])

    end if
;
; **********************************************************************
;
; Calculate grid y-angle with respect to geographic north.
;
; **********************************************************************
;
    if (calc_angle_dy_cell_cntrs) then

      angle_dy_SG_crnt_tile := fp->angle_dy(:,:)
      angle_dy_cntr_crnt_tile := angle_dy_SG_crnt_tile(1::2,1::2)
      delete([/ angle_dy_SG_crnt_tile /])

    end if

    print("  Done reading field(s) from file.")
;
; **********************************************************************
;
; Get or calculate the field to plot and store it in the array field_-
; crnt_tile.
;
; **********************************************************************
;
; If field_name is set to "none", we create a 2-D array of missing val-
; ues of whatever data type the fields are in the file.  Note that if 
; the current tile is tile 7, the dimensions of this array will include
; the halo.  The halo will be removed later below if the grid type is 
; regional, the current tile is tile 7, and remove_rgnl_halo is set to 
; True.
;
    if (strcmp_exact(field_name, "none")) then

      dims_SG_with_halo = getfilevardimsizes(fp, "area")
      dims_with_halo = dims_SG_with_halo/2
      field_data_type_default = getfilevartypes(fp, "area")
      field_crnt_tile := new(dims_with_halo, field_data_type_default)

    else if (strcmp_exact(field_name, "cell_area")) then

      field_crnt_tile := dA_crnt_tile
      delete(dA_crnt_tile)
      if (strcmp_exact(field_units, "km^2")) then
        field_crnt_tile := field_crnt_tile*kms2_per_meter2
      end if

    else if (strcmp_exact(field_name, "sqrt_cell_area")) then

      field_crnt_tile := sqrt(dA_crnt_tile)
      delete(dA_crnt_tile)
      if (strcmp_exact(field_units, "km")) then
        field_crnt_tile := field_crnt_tile*kms_per_meter
      end if

    else if (strcmp_exact(field_name, "cell_dx")) then

      field_crnt_tile := dx_cntr_crnt_tile
      delete(dx_cntr_crnt_tile)
      if (strcmp_exact(field_units, "km")) then
        field_crnt_tile := field_crnt_tile*kms_per_meter
      end if

    else if (strcmp_exact(field_name, "cell_dy")) then

      field_crnt_tile := dy_cntr_crnt_tile
      delete(dy_cntr_crnt_tile)
      if (strcmp_exact(field_units, "km")) then
        field_crnt_tile := field_crnt_tile*kms_per_meter
      end if

    else if (strcmp_exact(field_name, "cell_dx_ovr_cell_dy")) then

      field_crnt_tile := dx_cntr_crnt_tile/dy_cntr_crnt_tile
      delete([/ dx_cntr_crnt_tile, dy_cntr_crnt_tile /])

    else if (strcmp_exact(field_name, "min_cell_dx_cell_dy")) then

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
        field_crnt_tile := field_crnt_tile*kms_per_meter
      end if

    else if (strcmp_exact(field_name, "angle_cell_dx")) then

      field_crnt_tile := angle_dx_cntr_crnt_tile
      delete(angle_dx_cntr_crnt_tile)

    else if (strcmp_exact(field_name, "angle_cell_dy")) then

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
; If on a regional grid and on tile 7 and if remove_rgnl_halo is set to
; True, remove the halo from the field calculated above (field_crnt_-
; tile).
;
; **********************************************************************
;
    if (remove_halo_by_tile(nn)) then

      print("")
      print("  Removing halo cells from field (" + \
            char_dq + field_name + char_dq + \
            ") on tile " + n_tile + " ...")

      field_crnt_tile \
      := field_crnt_tile( \
         nh_by_tile(nn):nyh_by_tile(nn)-1-nh_by_tile(nn), \
         nh_by_tile(nn):nxh_by_tile(nn)-1-nh_by_tile(nn))

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

      field_by_tile_unstruc := ndtooned(field_crnt_tile)

    else

      field_data_type_prev_tiles = typeof(field_by_tile_unstruc)
      field_data_type_crnt_tile = typeof(field_crnt_tile)
;
; If the data type of the field on the tiles considered thus far is not
; the same as that of the field on the current tile, we either perform 
; type conversions or exit with an error (depending on the inconsisten-
; cy).
;
      if (.not. strcmp_exact(field_data_type_prev_tiles, \
                             field_data_type_crnt_tile)) then

        prev_tiles_all_missing := all(ismissing(field_by_tile_unstruc))
        crnt_tile_all_missing := all(ismissing(field_crnt_tile))

        if (prev_tiles_all_missing .and. (.not. crnt_tile_all_missing)) then

          field_by_tile_unstruc \
          := totype(field_by_tile_unstruc, field_data_type_crnt_tile)

        else if ((.not. prev_tiles_all_missing) .and. crnt_tile_all_missing) then

          field_crnt_tile \
          := totype(field_crnt_tile, field_data_type_prev_tiles)

        else if (prev_tiles_all_missing .and. crnt_tile_all_missing) then

          msg := char_nl + id_str + char_nl + \
"The field on all previous tiles and on the current tile consists of all " + char_nl + \
"missing values.  In this case, the data type of the missing values on " + char_nl + \
"the previous tiles should be the same as the data type of the missing " + char_nl + \
"values on the current tile but is not:" + char_nl + \
"  prev_tiles_all_missing = " + prev_tiles_all_missing + char_nl + \
"  crnt_tile_all_missing = " + crnt_tile_all_missing + char_nl + \
"  field_data_type_prev_tiles = " + char_dq + field_data_type_prev_tiles + char_dq + char_nl + \
"  field_data_type_crnt_tile = " + char_dq + field_data_type_crnt_tile + char_dq + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if ((.not. prev_tiles_all_missing) .and. \
                 (.not. crnt_tile_all_missing)) then

          msg := char_nl + id_str + char_nl + \
"The field does not contain any missing values on any of the previous " + char_nl + \
"tiles or on the current tile.  In this case, the data type of the values " + char_nl + \
"on the previous tiles should be the same as the data type of the values " + char_nl + \
"on current tiles but is not:" + char_nl + \
"  prev_tiles_all_missing = " + prev_tiles_all_missing + char_nl + \
"  crnt_tile_all_missing = " + crnt_tile_all_missing + char_nl + \
"  field_data_type_prev_tiles = " + char_dq + field_data_type_prev_tiles + char_dq + char_nl + \
"  field_data_type_crnt_tile = " + char_dq + field_data_type_crnt_tile + char_dq + char_nl + \
"Stopping."
          print("" + msg)
          exit

        end if
        end if
        end if
        end if

      end if

      field_by_tile_unstruc \
      := array_append_record(field_by_tile_unstruc, ndtooned(field_crnt_tile), 0)

    end if
;
; **********************************************************************
;
; Get the field's data type (usually "float" or "double").
;
; **********************************************************************
;
    field_data_type = typeof(field_by_tile_unstruc)
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
      field_min_by_tile := new((/ num_tiles /), field_data_type)
      field_max_by_tile := new((/ num_tiles /), field_data_type)
      field_median_by_tile := new((/ num_tiles /), field_data_type)
      field_mean_by_tile := new((/ num_tiles /), field_data_type)
    end if

    field_min_by_tile(nn) = field_stat_info@field_min
    field_max_by_tile(nn) = field_stat_info@field_max
    field_median_by_tile(nn) = field_stat_info@field_median
    field_mean_by_tile(nn) = field_stat_info@field_mean

  end do

  print("")
  print("Done reading field(s) from grid files.")
  print("" + separator_line)
;
; **********************************************************************
;
; Set to missing values the variables containing the vertical and time
; dimensions of the field on each tile.  These need to be returned only
; for consistency with the read_FV3SAR_field_native(...) function.
;
; **********************************************************************
;
  nz_by_tile := new(num_tiles, "integer")
  nt_by_tile := new(num_tiles, "integer")
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
  field_info@field_by_tile_unstruc = field_by_tile_unstruc
  field_info@nz_by_tile = nz_by_tile
  field_info@nt_by_tile = nt_by_tile
  field_info@field_min_by_tile = field_min_by_tile
  field_info@field_max_by_tile = field_max_by_tile
  field_info@field_median_by_tile = field_median_by_tile
  field_info@field_mean_by_tile = field_mean_by_tile
  field_info@field_data_type = field_data_type

  return(field_info)

end







