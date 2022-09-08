;
; **********************************************************************
;
; File name: strcmp_exact.ncl
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
undef("strcmp_exact")

function strcmp_exact(str_array[*]:string, str[1]:string)

local match_found, dims, match_by_elem, \
      lens_str_array, len_str, same_num_chars, \
      substr_found, match_found

begin
;
; **********************************************************************
;
; Initialize the return variable (match_found) to False.  Also, create a
; logical array (match_by_elem) of the same size as str_array and set 
; all its elements to False.  
;
; Note that ideally, we would like match_by_elem to be an attribute of 
; match_found, i.e. match_found@match_by_elem, but apparently NCL does
; not allow arrays that are attributes of another variable to be set to
; the same value everywhere by setting them to a scalar value.  Thus, we 
; cannot do the following:
;
;   match_found@match_by_elem = new(dims, logical)
;   match_found@match_by_elem = False
;   
; The second line will generate an error.  For this reason, below we in-
; stead first work with the non-attribute array match_by_elem and then 
; set it to an attribute of match_found later on.
;
; **********************************************************************
;
  match_found = False
  dims = dimsizes(str_array)
  match_by_elem = new(dims, logical)
  match_by_elem = False
;
; **********************************************************************
;
; Generate a 1-D logical array (same_num_chars) of the same length as 
; str_array that is True for those elements of str_array that have the
; same number of characters as str and False for all other elements.
;
; **********************************************************************
;
  lens_str_array = strlen(str_array)
  len_str = strlen(str)
  same_num_chars = where(lens_str_array .eq. len_str, True, False)
;
; **********************************************************************
;
; If any of the elements of str_array have the same length as str, then 
; continue to try to find exact matches.  If not, we already know that
; there are no exact matches and can exit the function with a False re-
; sult.
;
; **********************************************************************
;
  if (any(same_num_chars)) then
;
; **********************************************************************
;
; Generate a logical array (substr_found) of the same dimensions as 
; str_array that is True for those elements of str_array that contain
; str as a substring and False everywhere else.
;
; **********************************************************************
;
    substr_found = str_match_bool(str_array, str)
;
; **********************************************************************
;
; Set match_by_elem to True for those elements of str_array that are 
; identical to str [or, equivalently, for those elements of str_array 
; that (1) contain str as a substring and (2) have the same number of 
; characters as str] and False everywhere else.
;
; **********************************************************************
;
    match_by_elem \
    = where(substr_found .and. same_num_chars, True, False)
    if (any(match_by_elem)) then
      match_found = True
    end if

  end if
;
; **********************************************************************
;
; Return result as an attribute of the logical variable match_found.
;
; **********************************************************************
;
  match_found@match_by_elem = match_by_elem

  return(match_found)

end


