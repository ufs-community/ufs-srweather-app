;
; **********************************************************************
;
; File name: calc_lambert_cnfrml_proj_auxil_params.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function uses the primary parameters that define a Lambert con-
; formal projection with respect to spherical coordinates to calculate a
; set of auxiliary parameters needed in the mathematical expressions for
; calculating the Lambert conformal coordinates (x,y) from the spherical
; coordinates (lon,lat) and vice versa.
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "strcmp_exact.ncl")

undef("calc_lambert_cnfrml_proj_auxil_params")

function calc_lambert_cnfrml_proj_auxil_params( \
         lon_ctr:snumeric, lat_ctr:snumeric, \
         lat1:snumeric, lat2:snumeric, radius:snumeric, \
         angle_units:string)

local curnt_script_proc_func_name, \
      valid_vals_angle_units, valid_vals_str, msg, \
      angle_units_short_lwr, \
      lon_ctr_rad, lat_ctr_rad, lat1_rad, lat2_rad, \
      cos_lat1, cos_lat2, qrtr_pi_geom, tan_ctr, tan1, tan2, \
      n, F, rho_ctr, \
      proj_params

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
  := "function calc_lambert_cnfrml_proj_auxil_params"
;
; **********************************************************************
;
; Verify that the input argument "angle_units" has a valid value.
;
; **********************************************************************
;
  valid_vals_angle_units \
  := (/ "DEG", "DEGS", "DEGREE", "DEGREES", \
        "deg", "degs", "degree", "degrees", \
        "RAD", "RADS", "RADIAN", "RADIANS", \
        "rad", "rads", "radian", "radians" /)

  if (.not. strcmp_exact(valid_vals_angle_units, angle_units)) then

    valid_vals_str \
    := char_dq \
    + str_join(valid_vals_angle_units, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"ERROR:  " + curnt_script_proc_func_name + ":" + char_nl + \
"Input argument " + char_dq + angle_units + char_dq + "is not set to a valid value:" + char_nl + \
"  angle_units = " + char_dq + angle_units + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals_str + char_nl + \
"Stopping." + char_nl
    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; If necessary, convert angles from degrees to radians.
;
; **********************************************************************
;
  angle_units_short_lwr = str_lower(str_get_cols(angle_units, 0, 2))
  if (strcmp_exact(angle_units_short_lwr, "deg")) then
    lon_ctr_rad = lon_ctr*rads_per_deg
    lat_ctr_rad = lat_ctr*rads_per_deg
    lat1_rad = lat1*rads_per_deg
    lat2_rad = lat2*rads_per_deg
  else
    lon_ctr_rad = lon_ctr
    lat_ctr_rad = lat_ctr
    lat1_rad = lat1
    lat2_rad = lat2
  end if
;
; **********************************************************************
;
; Calculate convenience quantities.
;
; **********************************************************************
;
  cos_lat1 = cos(lat1_rad)
  cos_lat2 = cos(lat2_rad)

  qrtr_pi_geom = 0.25d+0*pi_geom
  tan_ctr = tan(qrtr_pi_geom + 0.5d+0*lat_ctr_rad)
  tan1 = tan(qrtr_pi_geom + 0.5d+0*lat1_rad)
  tan2 = tan(qrtr_pi_geom + 0.5d+0*lat2_rad)
;
; **********************************************************************
;
; Calculate the auxiliary (or secondary) Lambert conformal projection
; parameters.
;
; **********************************************************************
;
  if (lat1 .ne. lat2) then
    n = log(cos_lat1/cos_lat2)/log(tan2/tan1)
  else
    n = sin(lat1_rad)
  end if
  F = radius*cos_lat1*(tan1^n)/n
  rho_ctr = F/(tan_ctr^n)
;
; **********************************************************************
;
; Return results as attributes of the logical variable proj_params.
;
; **********************************************************************
;
  proj_params = True

  proj_params@lon_ctr_rad = lon_ctr_rad
  proj_params@lat_ctr_rad = lat_ctr_rad
  proj_params@lat1_rad = lat1_rad
  proj_params@lat2_rad = lat2_rad
  proj_params@n = n
  proj_params@F = F
  proj_params@rho_ctr = rho_ctr

  return(proj_params)

end


