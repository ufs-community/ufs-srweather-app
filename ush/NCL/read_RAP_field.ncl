;
; **********************************************************************
;
; File name: read_RAP_field.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns 
;
; **********************************************************************
;
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "constants.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "calc_field_stats.ncl")

undef("read_RAP_field")

function read_RAP_field( \
         field_name:string, \
         horiz_dist_units:string, \
         horiz_area_units:string, \
         RAP_fn:string, \
         nx:integer, \
         ny:integer \
         )

local fp, \
      field_data_type, \
      calc_dx_cell_cntrs, calc_dy_cell_cntrs, \
      field_desc, field_units, \
      dx_nondim, mapfac_mx, dx_cntr, \
      dy_nondim, mapfac_my, dy_cntr, \
      field, dxmin, dymin, min_dx_dy, \
      field_unstruc, \
      msg, print_field_stats, field_stat_info, \
      field_min, field_max, field_median, field_mean, \
      field_info

begin
;
; **********************************************************************
;
; Open the specified file for reading.
;
; **********************************************************************
;
  print("")
  print("" + separator_line)
  print("Reading RAP field from file:")
  print("")
  print("  RAP_fn = " + char_dq + RAP_fn + char_dq)

; Modify for grib2 file.
RAP_fn = RAP_fn + ".grb2"

  fp = addfile(RAP_fn, "r")
;
; **********************************************************************
;
; Get the data type (i.e. float or double) of the fields in the speci-
; fied file.  We assume here that all real-numbered fields are of the 
; same type, so we read in the type of only one such field.
;
; **********************************************************************
;
;  field_data_type = getfilevartypes(fp, "MAPFAC_M")
; Modify for grib2 file.
  field_data_type = getfilevartypes(fp, field_name)
;
; **********************************************************************
;
; Set field-related parameters.
;
; **********************************************************************
;
  calc_dx_cell_cntrs = False
  calc_dy_cell_cntrs = False
  
  if (strcmp_exact(field_name, "none")) then
  
    field_desc = "Empty Field"
    field_units = "-"
  
  else if (strcmp_exact(field_name, "cell_area")) then
  
    calc_dx_cell_cntrs = True
    calc_dy_cell_cntrs = True
    field_desc = "Cell Area"
    field_units = horiz_area_units
  
  else if (strcmp_exact(field_name, "sqrt_cell_area")) then
  
    calc_dx_cell_cntrs = True
    calc_dy_cell_cntrs = True
    field_desc = "Square Root of Cell Area"
    field_units = horiz_dist_units
  
  else if (strcmp_exact(field_name, "cell_dx")) then
  
    calc_dx_cell_cntrs = True
    field_desc = "Cell Size in x-Direction Along Cell Centerline"
    field_units = horiz_dist_units
  
  else if (strcmp_exact(field_name, "cell_dy")) then
  
    calc_dy_cell_cntrs = True
    field_desc = "Cell Size in y-Direction Along Cell Centerline"
    field_units = horiz_dist_units
  
  else if (strcmp_exact(field_name, "cell_dx_ovr_cell_dy")) then
  
    calc_dx_cell_cntrs = True
    calc_dy_cell_cntrs = True
    field_desc = "Ratio of dx to dy (dx/dy)"
    field_units = "-"
  
  else if (strcmp_exact(field_name, "min_cell_dx_cell_dy")) then
  
    calc_dx_cell_cntrs = True
    calc_dy_cell_cntrs = True
    field_desc = "MIN(dx, dy)"
    field_units = horiz_dist_units

  else if (strcmp_exact(field_name, "VGTYP_P0_L1_GLC0")) then
  
    field_desc = "Vegetation type"
    field_units = "-"

  else
  
    field_desc = "Unknown Field"
    field_units = "?"
  
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
;
; **********************************************************************
;
; Calculate cell size in x direction along cell centerlines.
;
; **********************************************************************
;
  if (calc_dx_cell_cntrs) then

    dx_nondim := fp@DX
    mapfac_mx := fp->MAPFAC_MX(:,:,:)
    mapfac_mx := rm_single_dims(mapfac_mx)
    dx_cntr := dx_nondim/mapfac_mx
    delete([/ mapfac_mx /])

  end if
;
; **********************************************************************
;
; Calculate cell size in y direction along cell centerlines.
;
; **********************************************************************
;
  if (calc_dy_cell_cntrs) then

    dy_nondim := fp@DY
    mapfac_my := fp->MAPFAC_MY(:,:,:)
    mapfac_my := rm_single_dims(mapfac_my)
    dy_cntr := dy_nondim/mapfac_my
    delete([/ mapfac_my /])

  end if
;
; **********************************************************************
;
; Get or calculate the field to plot and store it in the array RAP.  
;
; **********************************************************************
;
  if (strcmp_exact(field_name, "none")) then

    field := new((/ ny, nx /), field_data_type)

  else if (strcmp_exact(field_name, "cell_area")) then

    field := dx_cntr*dy_cntr
    delete([/ dx_cntr, dy_cntr /])

  else if (strcmp_exact(field_name, "sqrt_cell_area")) then

    field := sqrt(dx_cntr*dy_cntr)
    delete([/ dx_cntr, dy_cntr /])

  else if (strcmp_exact(field_name, "cell_dx")) then

    field := dx_cntr
    delete([/ dx_cntr /])

  else if (strcmp_exact(field_name, "cell_dy")) then

    field := dy_cntr
    delete([/ dy_cntr /])

  else if (strcmp_exact(field_name, "cell_dx_ovr_cell_dy")) then

    field := dx_cntr/dy_cntr
    delete([/ dx_cntr, dy_cntr /])

  else if (strcmp_exact(field_name, "min_cell_dx_cell_dy")) then

    field := sqrt(dx_cntr*dy_cntr)
    delete([/ dx_cntr, dy_cntr /])

    dxmin := where(dx_cntr(0:ny-1,:) .lt. dx_cntr(1:,:), \
                   dx_cntr(0:ny-1,:), dx_cntr(1:,:))

    dymin := where(dy_cntr(:,0:nx-1) .lt. dy_cntr(:,1:), \
                   dy_cntr(:,0:nx-1), dy_cntr(:,1:))

    min_dx_dy := where(dxmin .lt. dymin, dxmin, dymin)

    field := min_dx_dy

    delete([/ dxmin, dymin, min_dx_dy /])

  else

;    field := new((/ ny, nx /), field_data_type)
; Modify for HRRR grib2 file.
    field := fp->$field_name$

  end if
  end if
  end if
  end if
  end if
  end if
  end if
;
; **********************************************************************
;
; Perform unit conversions if necessary.
;
; **********************************************************************
;
  if (strcmp_exact(field_name, "cell_area")) then

    if (strcmp_exact(field_units, "km^2")) then
      field := field*totype(kms2_per_meter2, field_data_type)
    end if

  else if (strcmp_exact(field_name, "sqrt_cell_area") .or. \
           strcmp_exact(field_name, "cell_dx") .or. \
           strcmp_exact(field_name, "cell_dy") .or. \
           strcmp_exact(field_name, "min_cell_dx_cell_dy"))

    if (strcmp_exact(field_units, "km")) then
      field := field*totype(kms_per_meter, field_data_type)
    end if

  end if
  end if
;
; **********************************************************************
;
; Convert the 2-D array containing the field to a 1-D array in unstruc-
; tured format. 
;
; **********************************************************************
;
  field_unstruc := ndtooned(field)
;
; **********************************************************************
;
; Calculate (and possibly print out) basic statistics of the field.
;
; **********************************************************************
;
  msg := "  Calculating statistics of field on RAP grid ..."
  print("")
  print("" + msg)

;  print_field_stats = True
  print_field_stats = False
  field_stat_info \
  := calc_field_stats( \
     field, field_desc, field_units, print_field_stats)
  msg := "  " + field_stat_info@msg
  print("")
  print("" + msg)

  msg := "  Done calculating statistics of field on RAP grid."
  print("")
  print("" + msg)
;
; **********************************************************************
;
; Save field statistics in appropriate variables.
;
; **********************************************************************
;
  field_min := field_stat_info@field_min
  field_max := field_stat_info@field_max
  field_median := field_stat_info@field_median
  field_mean := field_stat_info@field_mean

  print("")
  print("Done reading RAP field from file.")
  print("" + separator_line)
;
; **********************************************************************
;
; Return results as attributes of the logical variable field_info.
;
; **********************************************************************
;
  field_info = True

  field_info@fp = fp
  field_info@field_desc = field_desc
  field_info@field_units = field_units
  field_info@field_unstruc = field_unstruc
  field_info@field_min = field_min
  field_info@field_max = field_max
  field_info@field_median = field_median
  field_info@field_mean = field_mean
  field_info@field_data_type = field_data_type

  return(field_info)

end

