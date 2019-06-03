;
; **********************************************************************
;
; File name: repeat_str.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function repeats the specified string (str_in) the specified num-
; ber of times (num_repeats) and returns the result in a new string 
; (str_out).  If num_repeats is a 1-D array of integers, the result is a
; 1-D array of strings with the ith element of the array containing a 
; string that consists of the input string (str_in) repeated num_-
; repeats(i) times.
;
; **********************************************************************
;
undef("repeat_str")

function repeat_str(str_in:string, num_repeats[*]:integer)

local i, num_strings, str_tmp, str_out

begin

  num_strings = dimsizes(num_repeats)
  str_out := new(num_strings, "string")

  do i=0, num_strings-1
 
    if (num_repeats(i) .eq. 0) then
      str_tmp := ""
    else
      str_tmp := new(num_repeats(i), string)
      str_tmp = str_in                ; This must be an equal sign, not a colon-equal.
      str_tmp := str_concat(str_tmp)  ; This must be a colon-equal sign, not an equal.
    end if

    str_out(i) = str_tmp

  end do

  return(str_out)

end


