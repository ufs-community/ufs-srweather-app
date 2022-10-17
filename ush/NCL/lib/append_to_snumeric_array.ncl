;
; **********************************************************************
;
; File name: append_to_snumeric_array.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function appends to the snumeric array orig_array the snumeric 
; array array_to_append.  The result is saved in new_array and returned.
; Note that if the two arrays are not of the same snumeric type, then 
; array_to_append is converted to the type of orig_array before appending
; it to orig_array.
;
; **********************************************************************
;
loadscript(lib_location + "strcmp_exact.ncl")

undef("append_to_snumeric_array")

function append_to_snumeric_array( \
         orig_array:snumeric, array_to_append:snumeric)

local dims_orig_array, \
      num_dims_orig_array, \
      dims_orig_array_str, \
\
      dims_array_to_append, \
      num_dims_array_to_append, \
      dims_array_to_append_str, \
\
      msg, \
\
      num_dims, \
      dims_compare, \
      right_dims_equal, \
\
      tmp, \
      new_array

begin
;
; **********************************************************************
;
; Get the dimensions and the number of dimensions of the two input arrays.
;
; **********************************************************************
;
  dims_orig_array := dimsizes(orig_array)
  num_dims_orig_array := dimsizes(dims_orig_array)
  dims_orig_array_str \
  := "(/ " + str_join(tostring(dims_orig_array), ", ") + " /)"

  dims_array_to_append := dimsizes(array_to_append)
  num_dims_array_to_append := dimsizes(dims_array_to_append)
  dims_array_to_append_str \
  := "(/ " + str_join(tostring(dims_array_to_append), ", ") + " /)"
;
; **********************************************************************
;
; Check that the two input arrays have the same number of dimensions.
;
; **********************************************************************
;
  if (num_dims_array_to_append .ne. num_dims_orig_array) then
    msg = "" + char_nl + \
"Error:" + char_nl + \
"The number of dimensions of orig_array (num_dims_orig_array) and of " + char_nl + \
"array_to_append (num_dims_array_to_append) must be the same:" + char_nl + \
"  dims_orig_array = " + dims_orig_array_str + char_nl + \
"  dims_array_to_append = " + dims_array_to_append_str + char_nl + \
"  num_dims_orig_array = " + num_dims_orig_array + char_nl + \
"  num_dims_array_to_append = " + num_dims_array_to_append + char_nl + \
"Stopping."
    print("" + msg)
    exit
  end if
;
; **********************************************************************
;
; Check that all dimensions in the two input arrays after (i.e. to the 
; right of) the first dimension are identical.
;
; **********************************************************************
;
  num_dims = num_dims_orig_array
  if (num_dims .gt. 1) then
    dims_compare := (dims_orig_array .eq. dims_array_to_append)
    right_dims_equal := all(dims_compare(1:))
  else
    right_dims_equal := True
  end if

  if (.not. right_dims_equal) then
    msg = "" + char_nl + \
"Error:" + char_nl + \
"All dimensions of orig_array and array_to_append after the first dimension" + char_nl + \
"must be equal:" + char_nl + \
"  dims_orig_array = " + dims_orig_array_str + char_nl + \
"  dims_array_to_append = " + dims_array_to_append_str + char_nl + \
"Stopping."
    print("" + msg)
    exit
  end if
;
; **********************************************************************
;
; If necessary, convert the type of array_to_append to that of orig_array.
;
; **********************************************************************
;
  tmp := array_to_append
  if (.not. strcmp_exact(typeof(tmp), typeof(orig_array))) then
    tmp := totype(tmp, typeof(orig_array))
  end if
;
; **********************************************************************
;
; Append array_to_append to orig_array and save the result in new_array.
; Then return new_array.
;
; **********************************************************************
;
  new_array := array_append_record(orig_array, tmp, 0)

  return(new_array)

end


