;
; **********************************************************************
;
; Define mathematical and physical constants.
;
; **********************************************************************
;
; Circumference of a circle divided by its diameter.
;
pi_geom = 4.0d*atan(1.0d)
;
; Unit conversion factors.
;
degs_per_rad = 180.0d/pi_geom
rads_per_deg = 1.0d/degs_per_rad

meters_per_km = 1.0d+3
kms_per_meter = 1.0d/meters_per_km

meters2_per_km2 = meters_per_km^2
kms2_per_meter2 = 1.0d/meters2_per_km2

degC_per_degF = 5.0d+0/9.0d+0
degF_per_degC = 1.0d+0/degC_per_degF
;
; Radius of the Earth, in meters.
;
rad_Earth = 6371.0d+3

