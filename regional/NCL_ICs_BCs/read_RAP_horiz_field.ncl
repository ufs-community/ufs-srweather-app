; **********************************************************************
;
; File name: read_RAP_horiz_field.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function reads in (a horizontal slice of) the specified RAP field 
; from the specified file pointer (which should be pointing at a wrfout
; file).
;                                                                      *
; **********************************************************************

load "calc_field_stats.ncl"

undef("read_RAP_horiz_field")

function read_RAP_horiz_field( \
         f_wrfout:file, field_name:string, func_z:logical, k:integer, \
         print_field_stats:logical)

local field, field_by_cell, \
      field_desc, field_units, \
      field_min, field_max, \
      out

begin
;
; **********************************************************************
;                                                                      *
; Read in the field from the specified RAP wrfout file.
;                                                                      *
; **********************************************************************
;
  if (func_z) then
    field = f_wrfout->$field_name$(0,k,:,:)
  else
    field = f_wrfout->$field_name$(0,:,:)
  end if
;
; Convert the field to a cell-based one for plotting on an unstructured
; grid.
;
  field_by_cell := ndtooned(field)
;
; Get the description and units of the field.
;
  field_desc = f_wrfout->$field_name$@description
  field_units = f_wrfout->$field_name$@units
;
; **********************************************************************
;                                                                      *
; Calculate and print out basic statistics of the field on the RAP grid.
;                                                                      *
; **********************************************************************
;
  out := calc_field_stats( \
         field_by_cell, field_desc, field_units, print_field_stats)
  field_min = out@field_min
  field_max = out@field_max
;
; **********************************************************************
;                                                                      *
; Return various output variables as attributes of the "out" variable.
;                                                                      *
; **********************************************************************
;
  out := True
  out@field_desc = field_desc
  out@field_units = field_units
  out@field_by_cell = field_by_cell
  out@field_min = field_min
  out@field_max = field_max
  return(out)

end
