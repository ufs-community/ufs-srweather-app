;
; **********************************************************************
;
; File name: set_file_field_names.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function 
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")

load "check_filevar_existence_dims.ncl"

undef("set_file_field_names")

function set_file_field_names( \
         gtype:string, \
         tile_inds[*]:integer, \
         field_name:string, \
         is_gridfield:logical, \
;
         remove_halo_by_tile[*]:logical, \
;
         grid_files_by_tile[*]:string, \
         nxhSG_by_tile[*]:integer, \
         nyhSG_by_tile[*]:integer, \
         nxSG_by_tile[*]:integer, \
         nySG_by_tile[*]:integer, \
;
         run_dir:string, \
         file_basename:string, \
         nxh_by_tile[*]:integer, \
         nyh_by_tile[*]:integer, \
         nx_by_tile[*]:integer, \
         ny_by_tile[*]:integer, \
;
         vert_inds[*]:integer, \
         time_inds[*]:integer, \
;
         horiz_dist_units:string, \
         horiz_area_units:string)


local num_tiles, \
      file_names_by_tile, \
      field_names_by_tile, \
      msg, \
      nn, \
      underline, \
      n_tile, \
      file_name, \
      gridfield_info, \
      filevar_names, \
      nxhSG_or_nxh_by_tile, \
      nyhSG_or_nyh_by_tile, \
      filevar_names_str, \
      num_filevars, \
      indx_fv, \
      var_info_prev_tile, \
      var_info, \

      fp_field_file, \
      var_rank, \
      var_dim_names, \
      var_dim_sizes, \
      func_xy_only, \
      func_xyz_only, \
      func_xyt_only, \
      func_xyzt_only, \
      average_in_x, \
      average_in_y, \
\
      n_tile_prev, \
\
      fp_field_file_prev_tile, \
      var_rank_prev_tile, \
      var_dim_names_prev_tile, \
      var_dim_sizes_prev_tile, \
      func_xy_only_prev_tile, \
      func_xyz_only_prev_tile, \
      func_xyt_only_prev_tile, \
      func_xyzt_only_prev_tile, \
      average_in_x_prev_tile, \
      average_in_y_prev_tile, \
\
      var_dim_names_differ, \
      var_dim_names_prev_tile_str, \
      var_dim_names_str, \
      var_dim_sizes_prev_tile_str, \
      var_dim_sizes_str, \
\
      file_field_info

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
;
;
; **********************************************************************
;
  if (is_gridfield) then

    gridfield_info \
    := get_gridfield_info(field_name, horiz_dist_units, horiz_area_units)
    filevar_names := gridfield_info@filevar_names

    xdim_by_tile \
    := where(remove_halo_by_tile, nxSG_by_tile, nxhSG_by_tile)
    ydim_by_tile \
    := where(remove_halo_by_tile, nySG_by_tile, nyhSG_by_tile)

  else

    filevar_names := field_name

    xdim_by_tile \
    := where(remove_halo_by_tile, nx_by_tile, nxh_by_tile)
    ydim_by_tile \
    := where(remove_halo_by_tile, ny_by_tile, nyh_by_tile)

  end if

print("")
print("xdim_by_tile = " + xdim_by_tile)
print("")
print("ydim_by_tile = " + ydim_by_tile)

  filevar_names_str \
  := "(" + char_dq \
  + str_join(filevar_names, char_dq + ", " + char_dq) \
  + char_dq + ")"
  print("  filevar_names = " + filevar_names_str)
pause
;
; **********************************************************************
;
; Loop through the specified tiles and form the file name corresponding
; to each tile.  Also, set the field name for each tile.  Note that the
; reason for having a separate field name for each tile is that the 
; files corresponding to certain tiles may not exist (e.g. if we're con-
; sidering a tile other than tile 7 for a regional grid).  In that case,
; the field on those tiles will not be available, so for those tiles, we
; must set the field name to "none" to obtain a field array filled with
; missing/fill values.
;
; **********************************************************************
;
  num_tiles := dimsizes(tile_inds)

  file_names_by_tile = new((/ num_tiles /), "string")
  field_names_by_tile = new((/ num_tiles /), "string")

  print("")
  print("" + separator_line)
  msg := \
"Setting file and field name for each specified tile ..." + char_nl + \
"[The field name for a tile will be set to " + char_dq + "none" + char_dq + \
" if a file for that tile " + char_nl + \
"does not exist, e.g. if the tile in consideration is #5, but we are on a " + char_nl + \
"regional grid (in which case files/fields are only available on tile #7).]"
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
; Generate the file name for the current tile.
;
; **********************************************************************
;
    if (is_gridfield) then

      file_name := grid_files_by_tile(nn)
      file_names_by_tile(nn) = file_name

    else

      file_name := run_dir + "/" + file_basename
      if (.not. strcmp_exact(gtype, "regional")) then
        file_name := file_name + ".tile" + tostring(n_tile)
      end if
      file_name := file_name + ".nc"
      file_names_by_tile(nn) = file_name

    end if

    print("  file_names_by_tile(" + nn + ") = " + \
          char_dq + file_names_by_tile(nn) + char_dq) 
;
; **********************************************************************
;
; Generate the field name for the current tile.
;
; **********************************************************************
;
    field_names_by_tile(nn) = field_name
;
; If we're dealing with a regional grid (for which physical fields are
; available only on tile 7), and if we're not on tile 7 (i.e. we are on
; one of the "parent" global tiles 1 through 6), then only grid-related
; fields (such as horizontal area of cells) will be available on this 
; tile.  Thus, if we're not considering a grid-rleated field, we must
; set the field name on this tile to "none".
;
    if (strcmp_exact(gtype, "regional") .and. \
        (n_tile .ne. 7) .and. \
        (.not. is_gridfield)) then

      field_names_by_tile(nn) = "none"
      msg := char_nl + \
"  The specified field is not available on the current tile:" + char_nl + \
"    n_tile = " + n_tile + char_nl + \
"    field_name = " + char_dq + field_name + char_dq + char_nl + \
"  Setting the field name for the current tile to " + char_dq + "none" + char_dq + ":" + char_nl + \
"    field_names_by_tile(" + nn + ") = " + char_dq + field_names_by_tile(nn) + char_dq
      print("" + msg)

    else

      print("  field_names_by_tile(" + nn + ") = " + \
            char_dq + field_names_by_tile(nn) + char_dq)

    end if

  end do

  print("")
  print("Done setting file and field name for each specified tile.")
  print("" + separator_line)
;
; **********************************************************************
;
; Call a function that runs various checks on the specified field.  This
; function will:
;
; 1) Verify that the field exists as a as a variable in the file.
; 2) Verify that its functional dependence on space and time is one of
;    the following:
;    a) Function of only the two horizontal directions but not the ver-
;       tical direction or time.  In this case, the func_xy_only attrib-
;       ute of the returned variable will be set to True. 
;    b) Function of only the two horizontal directions and the vertical
;       direction but not time.  In this case, the func_xyz_only attrib-
;       ute of the returned variable will be set to True. 
;    c) Function of only the two horizontal directions and time but not
;       the vertical direction.  In this case, the func_xyt_only attrib-
;       ute of the returned variable will be set to True. 
;    d) Function of the two horizontal directions, the vertical direc-
;       tion, and time.  In this case, the func_xyzt_only attribute of
;       the returned variable will be set to True. 
; 3) Verify that the specified vertical and/or time indices do not ex-
;    ceed the array bounds of the variable that represents the specified
;    field.
; 4) Return:
;    a) The rank, dimension names, and dimension sizes of the variable
;       that represents the field.
;    b) The functional dependence of the field on x, y, z, and t.
;
; **********************************************************************
;
;
; **********************************************************************
;
; If the name of the field to be plotted on the current tile is NOT 
; "none" (i.e. it is a valid field), perfrom some basic checks on the
; variable and set the logical variables that describe the functional
; dependence of the field on space and time (i.e. its dependence on the
; independent variables) and those that describe whether the field needs
; to be averaged in the x and y directions.
;
; **********************************************************************
;
  msg := \
"Checking existence and dimensions of all variables in all specified tiles..."
  print("")
  print("" + separator_line)
  print("" + msg)

  num_filevars = dimsizes(filevar_names)
  do indx_fv=0, num_filevars-1

print("")
print("indx_fv = " + indx_fv)
print("filevar_names(indx_fv) = " + char_dq + filevar_names(indx_fv) + char_dq)
;pause
;
; Delete var_info and/or var_info_prev_tile if they already exist from 
; loop over variables.
;
    if (isvar("var_info")) then
      delete(var_info)
    end if

    if (isvar("var_info_prev_tile")) then
      delete(var_info_prev_tile)
    end if

    do nn=0, num_tiles-1
;print("")
;print("  nn = " + nn)
;print("  field_names_by_tile(nn) = " + char_dq + field_names_by_tile(nn) + char_dq)
;pause

      if (.not. strcmp_exact(field_names_by_tile(nn), "none")) then

        if ((nn .gt. 0) .and. isvar("var_info")) then
          var_info_prev_tile := var_info
        end if
  
        var_info := check_filevar_existence_dims( \
                    file_names_by_tile(nn), \
                    filevar_names(indx_fv), \
                    xdim_by_tile(nn), \
                    ydim_by_tile(nn), \
                    vert_inds_to_plot, \
                    time_inds_to_plot)
  
        fp_field_file = var_info@fp  
        var_rank = var_info@var_rank
        var_dim_names = var_info@var_dim_names
        var_dim_sizes = var_info@var_dim_sizes
        func_xy_only = var_info@func_xy_only
        func_xyz_only = var_info@func_xyz_only
        func_xyt_only = var_info@func_xyt_only
        func_xyzt_only = var_info@func_xyzt_only
        average_in_x = var_info@average_in_x
        average_in_y = var_info@average_in_y
;
; **********************************************************************
;
; If we've called for the previous tile the function that performs 
; checks on the variable, then...
;
; **********************************************************************
;
        if ((nn .gt. 0) .and. isvar("var_info_prev_tile")) then
  
          n_tile_prev = tile_inds(nn-1)
  
          var_rank_prev_tile := var_info_prev_tile@var_rank
          var_dim_names_prev_tile := var_info_prev_tile@var_dim_names
          var_dim_sizes_prev_tile := var_info_prev_tile@var_dim_sizes
          func_xy_only_prev_tile := var_info_prev_tile@func_xy_only
          func_xyz_only_prev_tile := var_info_prev_tile@func_xyz_only
          func_xyt_only_prev_tile := var_info_prev_tile@func_xyt_only
          func_xyzt_only_prev_tile := var_info_prev_tile@func_xyzt_only
          average_in_x_prev_tile := var_info_prev_tile@average_in_x
          average_in_y_prev_tile := var_info_prev_tile@average_in_y
  
          if (var_rank .eq. var_rank_prev_tile) then
            var_dim_names_differ := False
            do i=0, var_rank_prev_tile-1
              if (.not. strcmp_exact(var_dim_names, var_dim_names_prev_tile(i))) then
                var_dim_names_differ := True
                break
              end if
            end do
          end if
  
          if (var_rank .ne. var_rank_prev_tile) then
  
            msg := char_nl + \
"The variable's rank (var_rank) changed from tile " + n_tile_prev + \
" to tile " + n_tile + ":" + char_nl + \
"  var_rank_prev_tile = " + var_rank_prev_tile + char_nl + \
"  var_rank = " + var_rank + char_nl + \
"Stopping."
            print("" + msg)
            exit
  
          else if (var_dim_names_differ) then
  
            var_dim_names_prev_tile_str \
            := str_join(var_dim_names_prev_tile, char_dq + ", " + char_dq)
            var_dim_names_prev_tile_str \
            := "(" + char_dq + var_dim_names_prev_tile_str + char_dq + ")"
  
            var_dim_names_str \
            := str_join(var_dim_names, char_dq + ", " + char_dq)
            var_dim_names_str \
            := "(" + char_dq + var_dim_names_str + char_dq + ")"
  
            msg := char_nl + \
"The variable's dimension names (var_dim_names) changed from tile " + \
n_tile_prev + " to " + char_nl + \
"tile " + n_tile + ":" + char_nl + \
"  var_dim_names_prev_tile = " + var_dim_names_prev_tile_str + char_nl + \
"  var_dim_names = " + var_dim_names_str + char_nl + \
"Stopping."
            print("" + msg)
            exit
;
; The following check may have to be removed since for a nested grid, 
; the global tiles will not have the same dimensions as the nested tile,
; so requiring them to be the same doesn't make sense.  Not sure why I
; put this in...  I think for a given tile, the fields in filevar_names
; all need to have the same dimensions since they may be used together
; to calculate a new variable (e.g. filevar_names may contain dx and dy,
; and we may want to plot dy/dx).  In that case, this check has to be
; fixed so that it compares fields within a tile, not a field between
; tiles.  So, need to fix this...
; 
          else if (any(var_dim_sizes .ne. var_dim_sizes_prev_tile)) then
  
            var_dim_sizes_prev_tile_str \
            := "(" + str_join(tostring(var_dim_sizes_prev_tile), ", ") + ")"
            var_dim_sizes_str \
            := "(" + str_join(tostring(var_dim_sizes), ", ") + ")"
  
            msg := char_nl + \
"The variable's dimension sizes (var_dim_sizes) changed from tile " + \
n_tile_prev + " to " + char_nl + \
"tile " + n_tile + ":" + char_nl + \
"  var_dim_sizes_prev_tile = " + var_dim_sizes_prev_tile_str + char_nl + \
"  var_dim_sizes = " + var_dim_sizes_str + char_nl + \
"Stopping."
            print("" + msg)
            exit
  
          else if (func_xy_only .ne. func_xy_only_prev_tile) then
  
            msg := char_nl + \
"The variable's functional dependence status on only the horizontal " + char_nl + \
"coordinates x and y (func_xy_only) changed from tile " + n_tile_prev + " to " + \
"tile " + n_tile + ":" + char_nl + \
"  func_xy_only_prev_tile = " + func_xy_only_prev_tile + char_nl + \
"  func_xy_only = " + func_xy_only + char_nl + \
"Stopping."
            print("" + msg)
            exit
  
          else if (func_xyz_only .ne. func_xyz_only_prev_tile) then
  
            msg := char_nl + \
"The variable's functional dependence status on only the horizontal " + char_nl + \
"coordinates x and y and the vertical coordinate (func_xyz_only) " + char_nl + \
"changed from tile " + n_tile_prev + " to tile " + n_tile + ":" + char_nl + \
"  func_xyz_only_prev_tile = " + func_xyz_only_prev_tile + char_nl + \
"  func_xyz_only = " + func_xyz_only + char_nl + \
"Stopping."
            print("" + msg)
            exit
  
          else if (func_xyt_only .ne. func_xyt_only_prev_tile) then
  
            msg := char_nl + \
"The variable's functional dependence status on only the horizontal " + char_nl + \
"coordinates x and y and time (func_xyt_only) changed from tile " + n_tile_prev + char_nl + \
"to tile " + n_tile + ":" + char_nl + \
"  func_xyt_only_prev_tile = " + func_xyt_only_prev_tile + char_nl + \
"  func_xyt_only = " + func_xyt_only + char_nl + \
"Stopping."
            print("" + msg)
            exit
  
          else if (func_xyzt_only .ne. func_xyzt_only_prev_tile) then
  
            msg := char_nl + \
"The variable's functional dependence status on the horizontal coordinates " + char_nl + \
"x and y, the vertical coordinate, and time (func_xyzt_only) changed from " + char_nl + \
"tile " + n_tile_prev + " to tile " + n_tile + ":" + char_nl + \
"  func_xyzt_only_prev_tile = " + func_xyzt_only_prev_tile + char_nl + \
"  func_xyzt_only = " + func_xyzt_only + char_nl + \
"Stopping."
            print("" + msg)
            exit
  
          else if (average_in_x .ne. average_in_x_prev_tile) then
  
            msg := char_nl + \
"The averaging in the x direction needed to obtain the variable's values " + char_nl + \
"at cell centers (average_in_x) changed from tile " + n_tile_prev + \
" to tile " + n_tile + ":" + char_nl + \
"  average_in_x_prev_tile = " + average_in_x_prev_tile + char_nl + \
"  average_in_x = " + average_in_x + char_nl + \
"Stopping."
            print("" + msg)
            exit
  
          else if (average_in_y .ne. average_in_y_prev_tile) then
  
            msg := char_nl + \
"The averaging in the x direction needed to obtain the variable's values " + char_nl + \
"at cell centers (average_in_y) changed from tile " + n_tile_prev + \
" to tile " + n_tile + ":" + char_nl + \
"  average_in_y_prev_tile = " + average_in_y_prev_tile + char_nl + \
"  average_in_y = " + average_in_y + char_nl + \
"Stopping."
            print("" + msg)
            exit
  
          end if
          end if
          end if
          end if
          end if
          end if
          end if
          end if
          end if
  
        end if  ; Closes "if ((nn .gt. 0) .and. isvar("var_info_prev_tile")) then"
;
; **********************************************************************
;
; If the name of the field to be plotted on the current tile is "none"
; (i.e. it is not a valid field), set the logical variables that de-
; scribe the functional dependence of the field on space and time (i.e.
; its dependence on the independent variables) and those that describe
; whether the field needs to be averaged in the x and y directions all
; to False.
;
; **********************************************************************
;
      else
  
;        var_rank = default_fillvalue("integer")
;        var_dim_names = default_fillvalue("integer")
;        var_dim_sizes = default_fillvalue("integer")
        func_xy_only = False
        func_xyz_only = False
        func_xyt_only = False
        func_xyzt_only = False
        average_in_x = False
        average_in_y = False
  
      end if  ; Closes "if (.not. strcmp_exact(field_names_by_tile(nn), "none")) then

    end do

  end do

  msg := \
"Done checking existence and dimensions of all variables in all speci-" + char_nl + \
"fied tiles."
  print("")
  print("" + msg)
  print("" + separator_line)
;pause
;
; **********************************************************************
;
; Return results as attributes of the logical variable file_field_info.
;
; **********************************************************************
;
  file_field_info := True

  file_field_info@file_names_by_tile = file_names_by_tile
  file_field_info@field_names_by_tile = field_names_by_tile
  file_field_info@func_xy_only = func_xy_only
  file_field_info@func_xyz_only = func_xyz_only
  file_field_info@func_xyt_only = func_xyt_only
  file_field_info@func_xyzt_only = func_xyzt_only
  file_field_info@average_in_x = average_in_x
  file_field_info@average_in_y = average_in_y

  return(file_field_info)

end

