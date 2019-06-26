;
; **********************************************************************
;
; File name: read_FV3SAR_field_wrtcmp.ncl
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
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "calc_field_stats.ncl")

undef("read_FV3SAR_field_wrtcmp")

function read_FV3SAR_field_wrtcmp( \
         field_name:string, \
         horiz_dist_units:string, \
         horiz_area_units:string, \
         wrtcmp_fn:string, \
         nx:integer, \
         ny:integer, \
         vert_indx:integer, \
         time_indx:integer, \
         func_xy_only:logical, \
         func_xyz_only:logical, \
         func_xyt_only:logical, \
         func_xyzt_only:logical \
         )

local fp, \
      field_data_type, \
      field_desc, field_units, \
      field_vert, field_cntr, \
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
  print("Reading write-component field from file:")
  print("")
  print("  wrtcmp_fn = " + char_dq + wrtcmp_fn + char_dq)

  fp = addfile(wrtcmp_fn, "r")
;
; **********************************************************************
;
; Get the data type (i.e. float or double) of the fields in the speci-
; fied file.  We assume here that all real-numbered fields are of the 
; same type, so we read in the type of only one such field.
;
; **********************************************************************
;
  field_data_type = getfilevartypes(fp, field_name) 
;
; **********************************************************************
;
; Set field-related parameters.
;
; **********************************************************************
;
  if (strcmp_exact(field_name, "none")) then

    field_vert := new((/ ny, nx /), field_data_type)

    field_desc = "Empty Field"
    field_units = "-"

  else
;
; Read in the field at grid cell vertices.
;
    if (func_xy_only) then
      field_vert := fp->$field_name$(:,:)
    else if (func_xyz_only) then
      field_vert := fp->$field_name$(vert_indx,:,:)
    else if (func_xyt_only) then
      field_vert := fp->$field_name$(time_indx,:,:)
    else if (func_xyzt_only) then
      field_vert := fp->$field_name$(time_indx,vert_indx,:,:)
    end if
    end if
    end if
    end if

    field_vert := rm_single_dims(field_vert)

    field_desc = field_vert@long_name
    field_units = field_vert@units

  end if
;
; **********************************************************************
;
; Calculate field at cell centers from its values at cell vertices.
;
; **********************************************************************
;
  field_cntr = field_vert(0:ny-1,0:nx-1) \
              + field_vert(0:ny-1,1:nx) \
              + field_vert(1:ny,1:nx) \
              + field_vert(1:ny,0:nx-1)
  field_cntr = 0.25*field_cntr
;
; **********************************************************************
;
; Convert the 2-D array containing the field to a 1-D array in unstruc-
; tured format. 
;
; **********************************************************************
;
  field_unstruc := ndtooned(field_cntr)
;
; **********************************************************************
;
; Calculate (and possibly print out) basic statistics of the field.
;
; **********************************************************************
;
  msg := "  Calculating statistics of field on write-component grid ..."
  print("")
  print("" + msg)

;  print_field_stats = True
  print_field_stats = False
  field_stat_info \
  := calc_field_stats( \
     field_cntr, field_desc, field_units, print_field_stats)
  msg := "  " + field_stat_info@msg
  print("")
  print("" + msg)

  msg := "  Done calculating statistics of field on write_component grid."
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
  print("Done reading field from write-component file.")
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


