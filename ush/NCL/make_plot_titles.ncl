;
; **********************************************************************
;
; File name: make_plot_titles.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function generates titles for the plot.  These consist of the 
; following three strings:
;
; left_str:
; This will be placed at the top left of the plot.
;
; main_str:
; This will be placed at the top center corner of the plot.
;
; right_str:
; This will be placed at the top right of the plot.
;
; Note that these strings will in general contain NCL formatting func-
; tion codes.
;
; **********************************************************************
;

undef("make_plot_titles")

function make_plot_titles( \
         inds_tiles_to_plot[*]:integer, \
         nz_by_tile[*]:integer, \
         vert_indx[1]:integer, \
\
         field_name[1]:string, \
         field_desc[1]:string, \
         field_units[1]:string, \
         func_xyz_only[1]:logical, \
         func_xyzt_only[1]:logical, \
         field_min_by_tile[*]:snumeric, \
         field_max_by_tile[*]:snumeric, \
         tile_bdy_color[1]:string, \
\
         show_RAP_grid[1]:logical, \
         plot_RAP_field[1]:logical, \
         field_name_RAP[1]:string, \
         field_desc_RAP[1]:string, \
         field_units_RAP[1]:string, \
         RAP_bdy_color[1]:string, \
\
         nn[1]:integer)

local inds_tiles_to_plot_str, fmt_str, vert_indx_str, \
      func_code_zoom, \
      left_str, right_str, main_str, \
      num_newlines_FV3SAR, num_newlines_RAP, num_newlines_to_add, \
      line, field_min_str, field_max_str, \
      num_lines, line_lengths, line_length_max, num_pad_spaces_before, \
      add_half_horiz_space, vert_offset_one_line, vert_offsets, \
      vert_offsets_str

begin
;
; **********************************************************************
;
; Create strings containing a list of the tiles being plotted and the 
; vertical index.
;
; **********************************************************************
;
  inds_tiles_to_plot_str \
  := str_join(tostring(inds_tiles_to_plot), ",")

  fmt_str = "%i"
  vert_indx_str = sprinti(fmt_str, vert_indx)
;
; **********************************************************************
;
; Set the function code that specifies the factor (in percent) by which
; to change the font size.
;
; **********************************************************************
;
;  func_code_zoom = "~Z100Q~"
  func_code_zoom = "~Z75Q~"
;
; **********************************************************************
;
; First, consider the case in which the RAP grid and/or a RAP field is
; displayed in the plot.  In this case, the main middle string will be
; blank, the left string will contain the FV3SAR grid and/or field in-
; formation, and the right string will contain the RAP grid and/or field
; information.
;
; **********************************************************************
;
  if (show_RAP_grid .or. plot_RAP_field) then

    main_str = ""

    left_str \
    := "~F30~FV3SAR field info:~C~" \
     + "~F29~" + field_desc + " (" + char_dq + field_name + char_dq + ")" \
     + " [" + field_units + "]"

    if (func_xyz_only .or. func_xyzt_only) then
      left_str := left_str + ", k = " + vert_indx_str
    end if

    left_str \
    := left_str + "~C~" \
     + "Tile(s) shown: " + inds_tiles_to_plot_str

    if (show_tile_bdies) then
      left_str = left_str + "~C~" + "Tile boundaries in " + tile_bdy_color
    end if
    num_newlines_FV3SAR \
    = dimsizes(str_index_of_substr(left_str, "~C~", 0))

    right_str \
    := "~F30~RAP field info:~C~" \
    + "~F29~" + field_desc_RAP + " (" + char_dq + field_name_RAP + char_dq + ")" \
    + " [" + field_units_RAP + "]"
    if (show_RAP_bdy) then
      right_str = right_str + "~C~" + "RAP boundary in " + RAP_bdy_color
    end if
    num_newlines_RAP \
    = dimsizes(str_index_of_substr(right_str, "~C~", 0))
;
; right_str may have fewer newlines than left_str.  In that case, add
; newlines so that they both have the same number (looks better in the
; plot.
;
    num_newlines_to_add = num_newlines_FV3SAR - num_newlines_RAP
    if (num_newlines_to_add .ge. 1) then
      right_str = right_str + repeat_str("~C~ ", num_newlines_to_add)
; For some reason, after the last newline (~C~), the spacing isn't quite
; correct and some extra vertical space is needed.  Insert  that here.
      right_str = right_str + "~V-10~ "
    end if
;
; Prepend the function zoom code to adjust the font size.
;
    left_str := func_code_zoom + left_str
    right_str := func_code_zoom + right_str
;
; **********************************************************************
;
; Now consider the case in which the RAP grid and/or a RAP field is not
; displayed in the plot.
;
; **********************************************************************
;
  else
;
; Title at top-left of plot.
;
    left_str := new(1, "string")

    line := "Tile(s) shown: " + inds_tiles_to_plot_str
    left_str := array_append_record(left_str, line, 0)

    if (show_tile_bdies) then
      line := "Tile boundaries in " + tile_bdy_color
      left_str := array_append_record(left_str, line, 0)
    end if

    if (func_xyz_only .or. func_xyzt_only) then
      line := "Vert. index: " + vert_indx_str \
            + " [0,...," + (nz_by_tile(nn)-1) + "]"
    else
      line := "Vert. indx: N/A"
    end if
    left_str := array_append_record(left_str, line, 0)

    left_str := left_str(1:)
    num_lines = dimsizes(left_str)
    if (num_lines .gt. 1) then
      left_str(0:num_lines-2) = left_str(0:num_lines-2) + "~C~"
      left_str := str_concat(left_str)
    end if
    left_str := "~F29~" + left_str
    left_str := func_code_zoom + left_str
;
; Title at top-right of plot.
;
   right_str := new(1, "string")

   line := "Units: " + field_units
   right_str := array_append_record(right_str, line, 0)

   fmt_str = "%-11.6g"

   field_min_str = sprintf(fmt_str, field_min_by_tile(nn))
   line := "field_min = " + field_min_str
   right_str := array_append_record(right_str, line, 0)

   field_max_str = sprintf(fmt_str, field_max_by_tile(nn))
   line := "field_max = " + field_max_str
   right_str := array_append_record(right_str, line, 0)

   right_str := right_str(1:)
   num_lines = dimsizes(right_str)
   if (num_lines .gt. 1) then
     right_str(0:num_lines-2) = right_str(0:num_lines-2) + "~C~"
     right_str := str_concat(right_str)
   end if
   right_str := "~F29~" + right_str
   right_str := func_code_zoom + right_str
;
; Main title at top-center of plot.
;
    main_str := new(1, "string")

    line := field_desc + " (" + char_dq + field_name + char_dq \
          + ") on FV3SAR grid"
    main_str := array_append_record(main_str, line, 0)

    main_str := main_str(1:)
    num_lines = dimsizes(main_str)
    line_lengths := strlen(main_str)
    line_length_max := max(line_lengths)
    num_pad_spaces_before := (line_length_max - line_lengths)/2
    add_half_horiz_space := ((line_length_max - line_lengths)%2 .eq. 1)

    do i=0, num_lines-1
      main_str(i) = repeat_str(" ", num_pad_spaces_before(i)) + main_str(i)
    end do

    if (num_lines .gt. 1) then
      main_str(0:num_lines-2) = main_str(0:num_lines-2) + "~C~"
      main_str := where(add_half_horiz_space, "~H10~" + main_str, main_str)
      vert_offset_one_line := -7
      vert_offsets := vert_offset_one_line*ispan(1, num_lines-1, 1)
      vert_offsets_str := "~V" + tostring(vert_offsets) + "~"
      main_str(1:num_lines-1) = vert_offsets_str + main_str(1:num_lines-1)
      main_str := str_concat(main_str)
    end if
    main_str := "~F29~" + main_str
    main_str := func_code_zoom + main_str

  end if
;
; **********************************************************************
;
; Return results as attributes of the logical variable title_info.
;
; **********************************************************************
;
  title_info := True

  title_info@left_str = left_str
  title_info@main_str = main_str
  title_info@right_str = right_str

  return(title_info)

end


