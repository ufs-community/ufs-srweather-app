;
; **********************************************************************
;
; File name: get_1Dindx_from_2Dinds.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns the 1D index of the (j,i)-th element in a 2D ar-
; ray having dimensions given by dims_2Darray.  This 1D index is the in-
; dex of the element in the 1D array obtained by applying the built-in 
; ndtooned(...) function to the 2D array of specified dimensions.
;
; **********************************************************************
;
undef("get_1Dindx_from_2Dinds")

function get_1Dindx_from_2Dinds( \
         i:integer, j:integer, dims2D[2]:integer)

local nx, ny, indx1D

begin
;
; **********************************************************************
;
; Extract the dimensions of the 2D array for which the specified i and j
; indices are valid.
;
; **********************************************************************
;
  nx = dims2D(1)
  ny = dims2D(0)
;
; **********************************************************************
;
; Calculate the 1D index corresonding to the given i and j indices and 
; array dimensions.
;
; **********************************************************************
;
  indx1D := j*nx + i
;
; **********************************************************************
;
; Return the 1D index.
;
; **********************************************************************
;
  return(indx1D)

end

