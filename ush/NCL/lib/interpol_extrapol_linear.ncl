;
; **********************************************************************
;
; File name: interpol_extrapol_linear.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function compares each element of the string array str_array to 
; the string (scalar) str.  It returns a variable (match_found) that
; will be set to True if at least one element of str_array is identical
; to str and False otherwise (i.e. it will be set to False if none of 
; the elements of str_array are identical to str).  This function also
; returns (as an attribute of match_found) a 1-D logical array (exact_-
; match) having the same dimensions as str_array that will be True at 
; those indices at which str_array is identical to str and False every-
; where else.
;
; Note that str_array may be a scalar string, in which case this func-
; tion simply compares two strings.  If the two strings are identical, 
; then this function returns True in match_found as well as its attri-
; bute match_found@str_array (which in this case will be a scalar).  If
; the two strings are not identical, then match_found and match_found@-
; match_by_elem will both be False.
;
; **********************************************************************
;
undef("interpol_extrapol_linear")

function interpol_extrapol_linear( \
         x1[*]:snumeric, y1[*]:snumeric, \
         x2[*]:snumeric, y2[*]:snumeric, \
         x[*]:snumeric)

local slope, y_int, y

begin
;
; **********************************************************************
;
; Perform linear interpolation and return the result.
;
; **********************************************************************
;
  slope := (y2 - y1)/(x2 - x1)
  y_int := (x2*y1 -  x1*y2)/(x2 - x1)
  y := slope*x + y_int
  return(y)

end


