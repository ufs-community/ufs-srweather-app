;
; **********************************************************************
;
; File name: calc_sphr_coords_from_lambert_cnfrml.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function calculates the spherical coordinates (longitude and la-
; titude) corresponding to the specified Lambert conformal coordinates 
; x and y.
;
; **********************************************************************
;
loadscript(lib_location + "calc_lambert_cnfrml_proj_auxil_params.ncl")

undef("calc_sphr_coords_from_lambert_cnfrml")

function calc_sphr_coords_from_lambert_cnfrml( \
         lon_ctr:snumeric, lat_ctr:snumeric, \
         lat1:snumeric, lat2:snumeric, radius:snumeric, \
         angle_units:string, \
         x:snumeric, y:snumeric)

local proj_params, \
      lon_ctr_rad, lat_ctr_rad, lat1_rad, lat2_rad, \
      n, F, rho_ctr, \
      rho_ctr_mns_y, rho, theta, lon_rad, lat_rad, \
      angle_units_short_lwr, lon, lat

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
  := "function calc_sphr_coords_from_lambert_cnfrml"
;
; **********************************************************************
;
; Calculate the auxiliary Lambert conformal map projection parameters
; thar are needed in the calculation of the spherical coordinates (lon,
; lat) below.
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
; Calculate the spherical coordinates (lon_rad,lat_rad)  using the pro-
; jection parameters obtained above and the specified Lambert conformal
; coordinates.  Note that lon_rad and lat_rad are in units of radians. 
;
; **********************************************************************
;
  rho_ctr_mns_y = rho_ctr - y
  rho = sign_matlab(n)*sqrt(x^2 + rho_ctr_mns_y^2)
  theta = atan(x/rho_ctr_mns_y)
  lon_rad = lon_ctr_rad + theta/n
  lat_rad = 2.0d+0*atan((F/rho)^(1.0d+0/n)) - 0.5d+0*pi_geom
;
; **********************************************************************
;
; If necessary, convert angles from radians to degrees.
;
; **********************************************************************
;
  angle_units_short_lwr = str_lower(str_get_cols(angle_units, 0, 2))
  if (strcmp_exact(angle_units_short_lwr, "deg")) then
    lon = lon_rad*degs_per_rad
    lat = lat_rad*degs_per_rad
  else
    lon = lon_rad
    lat = lat_rad
  end if
;
; **********************************************************************
;
; Return results as attributes of the logical variable coords_out.
;
; **********************************************************************
;
  coords_out = True
  coords_out@lon = lon
  coords_out@lat = lat
  return(coords_out)

end


