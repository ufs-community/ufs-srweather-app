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
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "calc_field_stats.ncl")

load "get_gridfield_info.ncl"

undef("read_FV3SAR_field_native")

function read_FV3SAR_field_native( \
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
         func_xy_only:logical, \
         func_xyz_only:logical, \
         func_xyt_only:logical, \
         func_xyzt_only:logical, \
         average_in_x:logical, \
         average_in_y:logical)

local num_tiles, \
      nn, msg, underline, n_tile, nx, ny, msg_adden, \
      file_name, field_name, \
      fp, \
      field_crnt_tile, field_desc, field_units, \
      field_by_tile_unstruc, \
      field_data_type, \
      print_field_stats, field_stat_info, \
      field_min_by_tile, field_max_by_tile, \
      field_median_by_tile, field_mean_by_tile, \
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
  id_str := "Message from procedure/function read_FV3SAR_field_native():"
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

  nz_by_tile := new(num_tiles, "integer")
  nt_by_tile := new(num_tiles, "integer")

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
; Get the field to plot and store it in the array field_crnt_tile.  Al-
; so, set the strings describing the field (field_desc) and its units 
; (field_units).
;
; **********************************************************************
;
; If field_name is set to "none", we create a 2-D array of missing val-
; ues of data type specified by field_data_type_default (e.g. "float" or
; "double").  Note that it doesn't really matter what this default type 
; is set to because once non-missing field values are found on any tile,
; the missing values of this default type will be converted to the type
; of the non-missing values.
;
    if (strcmp_exact(field_name, "none")) then

      field_data_type_default = "float"

      msg := char_nl + id_str + char_nl + \
"  The field name (field_name) is set to " + char_dq + field_name + char_dq + "." + \
"  Thus, the field will be " + char_nl + \
"  set to an array of missing/fill values of specified default type (" + \
char_dq + field_data_type_default + char_dq + ") ..."
      print("" + msg)

      field_crnt_tile := new((/ ny, nx /), field_data_type_default)
      field_desc = "Empty Field"
      field_units = "-"

      msg := "  Done setting field to an array of missing/fill values."
      print("" + msg)
;
; **********************************************************************
;
; If field_name is not set to "none", we read in the field information
; from file.
;
; **********************************************************************
;
    else

      msg := char_nl + \
"  Reading field from file:" + char_nl + \
"    field_name = " + char_dq + field_name + char_dq + char_nl + \
"    file_name = " + char_dq + file_name + char_dq
      print("" + msg)

      dim_sizes = getfilevardimsizes(fp, field_name)
      if (func_xy_only) then
        field_crnt_tile := fp->$field_name$(:,:)
      else if (func_xyz_only) then
        nz_by_tile(nn) = dim_sizes(0)
        field_crnt_tile := fp->$field_name$(vert_indx,:,:)
      else if (func_xyt_only) then
        nt_by_tile(nn) = dim_sizes(0)
        field_crnt_tile := fp->$field_name$(time_indx,:,:)
      else if (func_xyzt_only) then
        nz_by_tile(nn) = dim_sizes(1)
        nt_by_tile(nn) = dim_sizes(0)
        field_crnt_tile := fp->$field_name$(time_indx,vert_indx,:,:)
      end if
      end if
      end if
      end if

      field_desc = field_crnt_tile@long_name
      field_units = field_crnt_tile@units

      msg := "  Done reading field from file."
      print("" + msg)

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
    msg := \
"  Calculating statistics of field on the tile " + n_tile + " grid ..."
    print("")
    print("" + msg)

    print_field_stats = False
    field_stat_info \
    := calc_field_stats( \
       field_crnt_tile, field_desc, field_units, print_field_stats)
    msg := "  " + field_stat_info@msg
    print("")
    print("" + msg)

    msg := \
"  Done calculating statistics of field on the tile " + n_tile + " grid."
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
; Return results as attributes of the logical variable field_info.
;
; **********************************************************************
;
  field_info = True

  field_info@field_desc = field_desc
  field_info@field_units = field_units
  field_info@nz_by_tile = nz_by_tile
  field_info@nt_by_tile = nt_by_tile
  field_info@field_by_tile_unstruc = field_by_tile_unstruc
  field_info@field_min_by_tile = field_min_by_tile
  field_info@field_max_by_tile = field_max_by_tile
  field_info@field_median_by_tile = field_median_by_tile
  field_info@field_mean_by_tile = field_mean_by_tile
  field_info@field_data_type = field_data_type

  return(field_info)

end


