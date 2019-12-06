; **********************************************************************
;
; File name: set_plot_header.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function generates a string containing the plot title.  This
; string contains various NCL function codes to specify the font, new-
; lines, etc.
;                                                                      *
; **********************************************************************

undef("set_plot_header")

function set_plot_header( \
         field_desc:string, \
         field_units:string, \
         field_min:snumeric, \
         field_max:snumeric, \
         model_name:string, \
         func_t:logical, func_z:logical, \
         opts:logical)

local char_dq, \
      title_line1, num_chars_line1, title_line2, num_chars_line2, \
      num_chars_shortest_line, num_chars_longest_line, diff_num_chars, \
      num_spaces_begin, num_spaces_end, \
      pad_begin, pad_end, \
      fc_font, fc_newline, \
      plot_title

begin
;
; **********************************************************************
;                                                                      *
; Special characters that can't be directly input into an NCL string.
;                                                                      *
; **********************************************************************
;
  char_dq = integertochar(34)
;
; **********************************************************************
;                                                                      *
; Get the forecast hour and vertical index from the attributes of the 
; opts variable.  If these are not specified as attributes, set them to
; default values.
;                                                                      *
; **********************************************************************
;
  if (isatt(opts, "header_style")) then
    header_style = opts@header_style
  else
    header_style = "main_only"
    header_style = "main_left_right"
  end if

  if (isatt(opts, "fcst_hr")) then
    fcst_hr = opts@fcst_hr
  else
    fcst_hr = "unspecified"
  end if

  if (isatt(opts, "fcst_hr")) then
    fcst_hr = opts@fcst_hr
  else
    fcst_hr = "unspecified"
  end if

  if (isatt(opts, "vert_idx")) then
    vert_idx = opts@vert_idx
  else
    vert_idx = "unspecified"
  end if
;
; **********************************************************************
;                                                                      *
; Function codes used in strings.
;                                                                      *
; **********************************************************************
;

;  fc_font = "~F7~"   ; complex_roman
  fc_font = "~F29~"  ; courier
;  fc_font = "~F30~"  ; courier-bold
;  fc_font = ""  ; default font

  fc_newline = "~C~"

;  fc_zoom = "~Z50~"
  fc_zoom = ""

  fc_vert_raise = ""
  fc_vert_raise = "~V-15~"
;  fc_vert_raise = "~V-1Q~"
;
; **********************************************************************
;                                                                      *
; Delete pre-defined output variables.
;                                                                      *
; **********************************************************************
;
  if (isvar("main_str")) then
    delete(main_str)
  end if

  if (isvar("left_str")) then
    delete(left_str)
  end if

  if (isvar("right_str")) then
    delete(right_str)
  end if
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  if (func_t) then
    fcst_hr_or_NA = tostring(fcst_hr)
  else
    fcst_hr_or_NA = "N/A"
  end if

  if (func_z) then
    vert_idx_or_NA = tostring(vert_idx)
  else
    vert_idx_or_NA = "N/A"
  end if

  fmt = "%-4.4G"
;  fmt = "%-4.8G"

  min_str = sprintf(fmt, field_min)
  first_char_min = str_get_cols(min_str, 0, 0)

  max_str = sprintf(fmt, field_max)
  first_char_max = str_get_cols(max_str, 0, 0)

  if (strcmp(first_char_min, "-")) then
    if (.not. strcmp(first_char_max, "-")) then
      max_str = "+" + max_str
    end if
  end if

;  if (.not. strcmp(first_char, "-")) then
;    max_str = " " + max_str
;  end if
;
; **********************************************************************
;                                                                      *
; Generate a plot header that has a main title only, i.e. no left-justi-
; fied and right-justified strings.  This main title consists of two 
; lines, with the lines horizontally centered with respect to the plot
; (and each other).
;                                                                      *
; **********************************************************************
;
  if (strcmp(header_style, "main_only")) then
;
; **********************************************************************
;                                                                      *
; Form the first line of the title and get the number of characters in 
; that line.
;                                                                      *
; **********************************************************************
;
    title_line1 := field_desc + " [" + field_units + "]"
    num_chars_line1 = strlen(title_line1)
;
; **********************************************************************
;                                                                      *
; Form the second line of the title and get the number of characters in 
; that line.
;                                                                      *
; **********************************************************************
;
    title_line2 \
    = "fcst_hr = " + fcst_hr_or_NA + " hr" + \
      "; k = " + vert_idx_or_NA
   
    fmt = "%-4.4G"
    minmax_str = "min/max = " + \
                 min_str + " [" + field_units + "]" + \
                 " / " + \
                 max_str + " [" + field_units + "]"
    title_line2 = title_line2 + "; " + minmax_str
    title_line2 = title_line2 + "; " + model_name + " grid"
  
    num_chars_line2 = strlen(title_line2)
;
; **********************************************************************
;                                                                      *
; Get the number of characters in the shorter and longer of the two 
; lines.  Then calculate the difference between the two as well as the 
; number of spaces to add at the beginning and end of the shorter line
; so that it is horizontally centered with respect to the longer line 
; (assuming we're using monospaced fonts).
;                                                                      *
; **********************************************************************
;
    num_chars_shortest_line = min((/ num_chars_line1, num_chars_line2 /))
    num_chars_longest_line = max((/ num_chars_line1, num_chars_line2 /))
  
    diff_num_chars = num_chars_longest_line - num_chars_shortest_line
    if ((diff_num_chars % 2) .eq. 0) then
      num_spaces_begin = diff_num_chars/2
    else
      num_spaces_begin = (diff_num_chars - 1)/2
    end if
    num_spaces_end = diff_num_chars - num_spaces_begin
;
; **********************************************************************
;                                                                      *
; Add the appropriate number of spaces at the beginning and end of the 
; shorter line so that it is horizontally centered with respect to the
; longer line.
;                                                                      *
; **********************************************************************
;
    pad_begin = ""
    do i=1, num_spaces_begin
      pad_begin = pad_begin + " "
    end do
  
    pad_end = ""
    do i=1, num_spaces_end
      pad_end = pad_end + " "
    end do
  
    if (num_chars_line1 .eq. num_chars_shortest_line) then
      title_line1 := pad_begin + title_line1 + pad_end
    else
      title_line2 := pad_begin + title_line2 + pad_end
    end if  

;print("")
;print("title_line1 = " + char_dq + title_line1 + char_dq)
;print("title_line2 = " + char_dq + title_line2 + char_dq)
;pause

;
; **********************************************************************
;                                                                      *
; Use the function codes to generate a complete string for the plot ti-
; tle.
;                                                                      *
; **********************************************************************
;
    main_str = fc_font + fc_zoom + \
               title_line1 + \
               fc_newline + fc_vert_raise + title_line2
;
; **********************************************************************
;                                                                      *
; Generate a plot header that has a main title as well as a left-justi-
; fied and a right-justified string.  
;                                                                      *
; **********************************************************************
;
  else if (strcmp(header_style, "main_left_right")) then
;
; Create the main title string.
;
    main_str = fc_font + fc_zoom + \
               field_desc + " [" + field_units + "]"
;
; Create string that will appear left-justified above the plot (and be-
; low the main title).
;
    left_str = fc_font + fc_zoom + \
               "Grid: " + model_name

    left_str = left_str + fc_newline + fc_vert_raise + \
               "fcst_hr = " + fcst_hr_or_NA + " hr"

    left_str = left_str + fc_newline + fc_vert_raise + fc_vert_raise + \
               "k = " + vert_idx_or_NA
;
; Create string that will appear right-justified above the plot (and be-
; low the main title).
;
    min_str = "min = " + min_str + " [" + field_units + "]"
    max_str = "max = " + max_str + " [" + field_units + "]"

    right_str = fc_font + fc_zoom + min_str + \
                fc_newline + fc_vert_raise + max_str

    right_str = right_str + fc_newline + fc_vert_raise + fc_vert_raise + \
                " "
;
; **********************************************************************
;                                                                      *
; Disallowed value for header_style.
;                                                                      *
; **********************************************************************
;
  else

    print("")
    print("Disallowed value for header_style:")
    print("  header_style = " + char_dq + header_style + char_dq)
    print("Allowed values are:")
    print("  " + char_dq + "main_only" + char_dq)
    print("  " + char_dq + "main_left_right" + char_dq)
    print("Stopping.")
    exit

  end if
  end if
;
; **********************************************************************
;                                                                      *
; Return the plot title.
;                                                                      *
; **********************************************************************
;
  out := True
  if (isvar("main_str")) then
    out@main_str = main_str
  end if
  if (isvar("left_str")) then
    out@left_str = left_str
  end if
  if (isvar("right_str")) then
    out@right_str = right_str
  end if

  return(out)

end

