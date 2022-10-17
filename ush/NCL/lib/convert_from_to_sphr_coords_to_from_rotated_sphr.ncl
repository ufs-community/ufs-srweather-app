;
; **********************************************************************
;
; File name: convert_from_to_sphr_coords_to_from_rotated_sphr.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function transforms the given longitudes and latitudes from sphe-
; rical to rotated spherical coordinates or vice versa.  The positive X-
; axis of the rotated spherical coordinate system intersects the sphere
; at the (non-rotated) longitude and latitude (lon0, lat0).  
;
; The input argument dir determines the direction of the transformation, 
; as follows.  If dir is set to 1, this function assumes that the input 
; longitudes and latitudes (lon_in, lat_in) are in non-rotated spherical coor-
; dinates and calculates the corresponding output longitudes and lati-
; tudes (lon_out, lat_out) in rotated spherical coordinates.  If dir is
; set to -1, this function assumes that (lon_in, lat_in) are specified in ro-
; tated coordinates and calculates the corresponding output coordinates
; (lon_out, lat_out) in non-rotated spherical coordinates.  No other 
; values of dir are allowed.
;
; **********************************************************************
;
undef("convert_from_to_sphr_coords_to_from_rotated_sphr")

function convert_from_to_sphr_coords_to_from_rotated_sphr( \
         lon0:snumeric, lat0:snumeric, \
         angle_units:string, dir:integer, \
         lon_in:snumeric, lat_in:snumeric)

local lon0_rad, lat0_rad, \
      lon_in_rad, lat_in_rad, \
      lon_in_offset_rad, pmlat0_rad, msg, \
      sin_lon_in_offset, cos_lon_in_offset, \
      sin_pmlat0_rad, cos_pmlat0_rad, \
      sin_lat_in, cos_lat_in, tan_lat_in, \
      numer_atan, denom_atan, \
      lon_out, lat_out, coords_out

begin
;
; **********************************************************************
;
; If necessary, convert longitude and latitude from degrees to radians.
;
; **********************************************************************
;
  angle_units_short_lwrcase = str_lower(str_get_cols(angle_units, 0, 2))
  if (strcmp_exact(angle_units_short_lwrcase, "deg")) then
    lon0_rad = lon0*rads_per_deg
    lat0_rad = lat0*rads_per_deg
    lon_in_rad = lon_in*rads_per_deg
    lat_in_rad = lat_in*rads_per_deg
  else
    lon0_rad = lon0
    lat0_rad = lat0
    lon_in_rad = lon_in
    lat_in_rad = lat_in
  end if
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  if (dir .eq. 1) then
    lon_in_offset_rad = lon_in_rad - lon0_rad
    pmlat0_rad = lat0_rad
  else if (dir .eq. -1) then
    lon_in_offset_rad = lon_in_rad
    pmlat0_rad = -lat0_rad
  else
    msg := char_nl + \
"Disallowed value specified for dir:" + char_nl + \
"  dir = " + dir + char_nl + \
"Set dir to 1 to transform from spherical to rotated spherical coordi-" + char_nl + \
"nates, or set dir to -1 to transform from rotated spherical to spheri-" + char_nl + \
"cal coordinates." + char_nl + \
"Stopping."
    print(msg + "")
    exit
  end if
  end if
;
; **********************************************************************
;                                                                      *
; Calculate sines, cosines, and tangents of various angles.
;                                                                      *
; **********************************************************************
;
  sin_lon_in_offset = sin(lon_in_offset_rad)
  cos_lon_in_offset = cos(lon_in_offset_rad)

  sin_pmlat0_rad = sin(pmlat0_rad)
  cos_pmlat0_rad = cos(pmlat0_rad)
  sin_lat_in = sin(lat_in_rad)
  cos_lat_in = cos(lat_in_rad)
  tan_lat_in = sin_lat_in/cos_lat_in
;
; **********************************************************************
;                                                                      *
; Calculate the transformed longitude lon_out.
;                                                                      *
; **********************************************************************
;
  numer_atan = sin_lon_in_offset
  denom_atan = sin_pmlat0_rad*tan_lat_in + cos_pmlat0_rad*cos_lon_in_offset
  lon_out = atan2(numer_atan, denom_atan)
  if (dir .eq. -1) then
    lon_out = lon_out + lon0_rad
  end if
;
; **********************************************************************
;                                                                      *
; Make sure that the output value of longitude are in the range -pi <= 
; lon < pi.
;                                                                      *
; **********************************************************************
;
  lon_out := where(lon_out .lt. -pi_geom, lon_out + 2.0d+0*pi_geom, lon_out) 
  lon_out := where(lon_out .ge. pi_geom, lon_out - 2.0d+0*pi_geom, lon_out) 
;
; **********************************************************************
;                                                                      *
; Calculate the transformed latitude lat_out.
;                                                                      *
; **********************************************************************
;
  lat_out = asin(cos_pmlat0_rad*sin_lat_in \
          - sin_pmlat0_rad*cos_lon_in_offset*cos_lat_in)
;
; **********************************************************************
;
; If necessary, convert output longitude and latitude from radians back
; to degrees.
;
; **********************************************************************
;
  if (strcmp_exact(angle_units_short_lwrcase, "deg")) then
    lon_out = lon_out*degs_per_rad
    lat_out = lat_out*degs_per_rad
  end if
;
; **********************************************************************
;
; Return results as attributes of the logical variable coords_out.
;
; **********************************************************************
;
  coords_out = True
  coords_out@lon_out = lon_out
  coords_out@lat_out = lat_out
  return(coords_out)

end




