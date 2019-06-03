;
; **********************************************************************
;
; File name: calc_lambert_cnfrml_coords_from_sphr.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function calculates the Lambert conformal coordinates x and y
; corresponding to the specified spherical coordinates lon (longitude)
; and lat (latitude).
;
; **********************************************************************
;
loadscript(lib_location + "calc_lambert_cnfrml_proj_auxil_params.ncl")

undef("calc_lambert_cnfrml_coords_from_sphr")

function calc_lambert_cnfrml_coords_from_sphr( \
         lon_ctr:snumeric, lat_ctr:snumeric, \
         lat1:snumeric, lat2:snumeric, radius:snumeric, \
         angle_units:string, \
         lon:snumeric, lat:snumeric)

local proj_params, \
      lon_ctr_rad, lat_ctr_rad, lat1_rad, lat2_rad, \
      n, F, rho_ctr, \
      angle_units_short_lwrcase, \
      lon_rad, lat_rad, rho, n_dlon_rad, \
      x, y, coords_out

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
  := "function calc_lambert_cnfrml_coords_from_sphr"
;
; **********************************************************************
;
; Calculate the auxiliary Lambert conformal map projection parameters
; that are needed in the calculation of the Lambert conformal coordi-
; nates (x,y) below.
;
; **********************************************************************
;
  proj_params := calc_lambert_cnfrml_proj_auxil_params( \
                 lon_ctr, lat_ctr, lat1, lat2, radius, angle_units)

  lon_ctr_rad = proj_params@lon_ctr_rad
  lat_ctr_rad = proj_params@lat_ctr_rad
  lat1_rad = proj_params@lat1_rad
  lat2_rad = proj_params@lat2_rad
  n = proj_params@n
  F = proj_params@F
  rho_ctr = proj_params@rho_ctr
;
; **********************************************************************
;
; If necessary, convert longitude and latitude from degrees to radians.
;
; **********************************************************************
;
  angle_units_short_lwrcase = str_lower(str_get_cols(angle_units, 0, 2))
  if (strcmp_exact(angle_units_short_lwrcase, "deg")) then
    lon_rad = lon*rads_per_deg
    lat_rad = lat*rads_per_deg
  else
    lon_rad = lon
    lat_rad = lat
  end if
;
; **********************************************************************
;
; Calculate the Lambert conformal coordinates (x,y) using the projection
; parameters obtained above and the specified spherical coordinates.
;
; **********************************************************************
;
  rho = F/((tan(0.25d+0*pi_geom + 0.5d+0*lat_rad))^n)
  n_dlon_rad = n*(lon_rad - lon_ctr_rad)
  x = rho*sin(n_dlon_rad)
  y = rho_ctr - rho*cos(n_dlon_rad)
;
; **********************************************************************
;
; Return results as attributes of the logical variable coords_out.
;
; **********************************************************************
;
  coords_out = True
  coords_out@x = x
  coords_out@y = y
  return(coords_out)

end


