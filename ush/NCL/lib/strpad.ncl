;
; **********************************************************************
;
; File name: strpad.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function pads each element of the given string array str_array 
; [except for the longest one(s)] with the specified single-character 
; string pad_char such that all elements of the resulting string all 
; have the same length.  Whether these elements are padded on the left 
; or on the right depends on the value of pad_side.
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "repeat_str.ncl")

undef("strpad")

function strpad(str_array[*]:string, pad_char[1]:string, pad_side[1]:string)

local valid_vals_pad_side_left, valid_vals_pad_side_right, \
      valid_vals_pad_side, valid_vals, msg, \
      elem_lens, elem_len_max, num_pad_chars_by_elem, padding_strs, \
      str_array_padded

begin
;
; **********************************************************************
;
; Set the name of the current script or function.  We have to do this
; manually because NCL does not seem to have a built-in method of ob-
; taining this information.
;
; **********************************************************************
;
  curnt_script_proc_func_name \
  := "function strpad"
;
; **********************************************************************
;
; Check that pad_side has a valid value. 
;
; **********************************************************************
;
  valid_vals_pad_side_left \
  := (/ "l", "L", "left", "Left", "LEFT" /)
  valid_vals_pad_side_right \
  := (/ "r", "R", "right", "Right", "RIGHT" /)
  valid_vals_pad_side \
  := array_append_record( \
     valid_vals_pad_side_left, valid_vals_pad_side_right, 0)

  if (.not. strcmp_exact(valid_vals_pad_side, pad_side)) then

    valid_vals \
    := char_dq \
    + str_join(valid_vals_pad_side, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"ERROR:  " + curnt_script_proc_func_name + ":" + char_nl + \
"Input argument " + char_dq + "pad_side" + char_dq + " is not set " + \
"to a valid value:" + char_nl + \
"  pad_side = " + char_dq + pad_side + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Stopping."

    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; Check that pad_char is a string of length 1.
;
; **********************************************************************
;
  pad_char_len = strlen(pad_char)
  if (pad_char_len .ne. 1) then
    msg := char_nl + \
"ERROR:  " + curnt_script_proc_func_name + ":" + char_nl + \
"Input argument " + char_dq + "pad_char" + char_dq + " must be a string " + \
"containing exactly one character:" + char_nl + \
"  pad_char = " + char_dq + pad_char + char_dq + char_nl + \
"  pad_char_len = " + pad_char_len + char_nl + \
"Stopping."
    print("" + msg)
    exit
  end if
;
; **********************************************************************
;
; Create an array whose elements are the padding strings (each consist-
; ing of 0 or more repetitions of pad_char) that need to be prepended or
; appended to the respective elements of str_array such that the result-
; ing array contains elements that all have the same length.
;
; **********************************************************************
;
  elem_lens := strlen(str_array)
  elem_len_max := max(elem_lens)
  num_pad_chars_by_elem := elem_len_max - elem_lens
  padding_strs := repeat_str(pad_char, num_pad_chars_by_elem)
;
; **********************************************************************
;
; Prepend or append the array of padding strings to str_array.
;
; **********************************************************************
;
  if (strcmp_exact(valid_vals_pad_side_left, pad_side)) then
    str_array_padded := padding_strs + str_array
  else if (strcmp_exact(valid_vals_pad_side_right, pad_side)) then
    str_array_padded := str_array + padding_strs
  end if
  end if
;
; **********************************************************************
;
; Return the resulting padded string array.
;
; **********************************************************************
;
  return(str_array_padded)

end


