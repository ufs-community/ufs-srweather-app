; **********************************************************************
;
; File name: adjust_longitude_range.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function adjust the given array of longitude values such that all
; values in the returned array lon_out are in the range 
; 
;   -lon_min <= lon_out < lon_max,
;
; Here, lon_min is the given minimum longitude value and lon_max is ei-
; ther lon_min plus 360 deg (if the units of lon and lon_min are in de-
; grees) or lon_min plus 2*pi (if the units are in radians).  lon and 
; lon_min must have the same units (degrees or radians).  These units
; are specified by the input string degs_or_rads.  This string should be
; set either to "degs" for degrees or to "rads" for radians.
;                                                                      *
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")

undef("adjust_longitude_range")

function adjust_longitude_range( \
         lon:snumeric, lon_min:snumeric, degs_or_rads:string)

local char_dq, pi, lon_domain_size, lon_max, lon_out

begin
;
; **********************************************************************
;                                                                      *
; Set the size of the longitude domain.  This is either 360 deg (if the
; given longitudes are in degrees) or 2*pi (if the given longitudes are
; in radians).
;                                                                      *
; **********************************************************************
;
  if (strcmp_exact(degs_or_rads, "degs")) then
    lon_domain_size = 360.0
  else if (strcmp_exact(degs_or_rads, "rads")) then
    pi = 4.0d*atan(1.0d)
    lon_domain_size = 2.0d*pi
  else
    msg := \
"Disallowed value specified for input argument degs_or_rads:" + char_nl + \
"  degs_or_rads = " + char_dq + degs_or_rads + char_dq + \
"Allowed values are " + char_dq + "degs" + char_dq + \
" and " + char_dq + "rads" + char_dq + "." + char_nl + \
"Stopping."
    print("" + msg)
    exit
  end if
  end if
;
; **********************************************************************
;                                                                      *
; Add the longitude domain size calculated above to the given minimum 
; longitude to obtain the maximum longitude.
;                                                                      *
; **********************************************************************
;
  lon_max = lon_min + lon_domain_size
;
; **********************************************************************
;                                                                      *
; Create a new longitude array (lon_out) that will serve as the output
; of this function.  Then adjust longitudes to ensure that all elements
; of lon_out are in the range lon_min <= lon_out < lon_max.
;                                                                      *
; **********************************************************************
;
  lon_out := lon
  lon_out := where(lon_out .lt. lon_min, lon_out + lon_domain_size, lon_out)
  lon_out := where(lon_out .ge. lon_max, lon_out - lon_domain_size, lon_out)
;
; **********************************************************************
;                                                                      *
; Return the adjusted longitude array lon_out.
;                                                                      *
; **********************************************************************
;
  return(lon_out)

end


