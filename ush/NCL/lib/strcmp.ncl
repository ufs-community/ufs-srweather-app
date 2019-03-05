;
; **********************************************************************
;
; File name: strcmp.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function compares two strings.  It returns True if they are iden-
; tical and False otherwise.  It is called as follows:
;
;   are_equal = strcmp(str1, str2)
;
; **********************************************************************
;
undef("strcmp")

function strcmp(str1:string, str2:string)

local len1, len2, match_result, are_equal

begin

  len1 = strlen(str1)
  len2 = strlen(str2)
  match_result = str_match(str1, str2)
  are_equal = False
  if ((.not. ismissing(match_result)) .and. (len1 .eq. len2)) then
    are_equal = True
  end if
  return(are_equal)

end


