; **********************************************************************
;
; File name: plot_model_field_generic.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function
;                                                                      *
; **********************************************************************

load "pause.ncl"
load "special_chars.ncl"
load "set_plot_header.ncl"
load "plot_horiz_field.ncl"

undef("plot_model_field_generic")

function plot_model_field_generic( \
         model_name:string, 
         lon_cntrs_by_cell:snumeric, lat_cntrs_by_cell:snumeric, \
         lon_verts_by_cell:snumeric, lat_verts_by_cell:snumeric, \
         field_by_cell:snumeric, \
         field_name:string, field_desc:string, field_units:string, \
         func_t:logical, func_z:logical, \
         fcst_hr:integer, k:integer, \
         draw_grid:logical, \
         plot_options:logical)

;local char_dq  ; Need to add all local variables.

begin
;
; **********************************************************************
;                                                                      *
; Special characters that can't be directly input into an NCL string.
;                                                                      *
; **********************************************************************
;
;  char_dq = integertochar(34)
;  char_nl = str_get_nl()
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  plot_options@draw_grid = draw_grid
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  fn_graphics = plot_options@fn_graphics_base + \
                "_dmn" + plot_options@region_name + \
                "_grd" + model_name
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  inds_region_by_cell \
  := ind((lon_cntrs_by_cell .ge. plot_options@lon_min) .and. \
         (lon_cntrs_by_cell .le. plot_options@lon_max) .and. \
         (lat_cntrs_by_cell .ge. plot_options@lat_min) .and. \
         (lat_cntrs_by_cell .le. plot_options@lat_max))

  lon_cntrs_region_by_cell := lon_cntrs_by_cell(inds_region_by_cell)
  lat_cntrs_region_by_cell := lat_cntrs_by_cell(inds_region_by_cell)
  lon_verts_region_by_cell := lon_verts_by_cell(inds_region_by_cell,:)
  lat_verts_region_by_cell := lat_verts_by_cell(inds_region_by_cell,:)

  field_region_by_cell := field_by_cell(inds_region_by_cell)
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  field_min = min(field_region_by_cell)
  field_max = max(field_region_by_cell)
  print("")
  print("  field_min = " + field_min + " " + field_units + \
        " in region " + char_dq + plot_options@region_name + char_dq)
  print("  field_max = " + field_max + " " + field_units + \
        " in region " + char_dq + plot_options@region_name + char_dq)

  opts := True
;  opts@header_style = "main_only"
  opts@header_style = "main_left_right"
  opts@fcst_hr = fcst_hr
  opts@vert_idx = k
  out := set_plot_header( \
         field_desc, field_units, field_min, field_max, \
         model_name, func_t, func_z, opts)

  if (isatt(out, "main_str")) then
    plot_options@main_str = out@main_str
  end if
  if (isatt(out, "left_str")) then
    plot_options@left_str = out@left_str
  end if
  if (isatt(out, "right_str")) then
    plot_options@right_str = out@right_str
  end if
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  if (.not. isatt(plot_options, "calc_cnLevels")) then
    plot_options@calc_cnLevels = True
  else
    plot_options@calc_cnLevels = False
  end if
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  if (plot_options@calc_cnLevels) then

    print("")
    print("Calculating " + char_dq + "nice" + char_dq + " contour " + \
          "values from the field's minimum and " + char_nl + \
          "maximum values...")
  
    opts := True
    opts@verbose = True
;    opts@verbose = False
    out := set_cnLevels_lbLabels( \
           field_min, field_max, plot_options@num_cnLevels, opts)
    copy_VarAtts(out, plot_options)

  end if
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  out := plot_horiz_field( \
         lon_cntrs_region_by_cell, \
         lat_cntrs_region_by_cell, \
         lon_verts_region_by_cell, \
         lat_verts_region_by_cell, \
         field_region_by_cell, \
         fn_graphics, \
         plot_options)
;
; **********************************************************************
;                                                                      *
; All attributes of the output variable "out" are plotting attributes
; that should be reused for the plot generated by the next call to
; plot_horiz_field(...) (which will plot a regridded version of the 
; field above on the FV3-LAM grid).  For this purpose, here we copy all
; attributes of "out" into the variable plot_options.  We will then use
; plot_options as an input arguemnt to plot_horiz_field(...).
;                                                                      *
; **********************************************************************
;
  copy_VarAtts(out, plot_options)

  return(out)

end


