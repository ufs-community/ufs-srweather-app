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
; (str_out).
;
; **********************************************************************
;
undef("repeat_str")

function repeat_str(str_in:string, num_repeats:integer)

local str_out

begin

  if (num_repeats .eq. 0) then
    str_out = ""
  else
    str_out = new((/num_repeats/), string)
    str_out = str_in                ; This must be an equal sign, not a colon-equal.
    str_out := str_concat(str_out)  ; This must be a colon-equal sign, not an equal.
  end if

  return(str_out)

end


