;
; **********************************************************************
;
; File name: get_gridfield_info.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function returns 
;
; **********************************************************************
;

undef("get_gridfield_info")

function get_gridfield_info( \
         field_name:string, \
         horiz_dist_units:string, \
         horiz_area_units:string)

local calc_dA_cell_cntrs, \
      calc_dx_cell_cntrs, \
      calc_dy_cell_cntrs, \
      calc_dx_cell_faces, \
      calc_dy_cell_faces, \
      calc_angle_dx_cell_cntrs, \
      calc_angle_dy_cell_cntrs, \
      filevar_names, \
      gridfield_desc, \
      gridfield_units

begin
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  calc_dA_cell_cntrs = False
  calc_dx_cell_cntrs = False
  calc_dy_cell_cntrs = False
  calc_dx_cell_faces = False
  calc_dy_cell_faces = False
  calc_angle_dx_cell_cntrs = False
  calc_angle_dy_cell_cntrs = False

  filevar_names := default_fillvalue("string")

  if (strcmp_exact(field_name, "cell_area")) then

    gridfield_desc = "Cell Area"
    gridfield_units = horiz_area_units
    calc_dA_cell_cntrs = True
    filevar_names := (/ "area" /)

  else if (strcmp_exact(field_name, "sqrt_cell_area")) then

    gridfield_desc = "Square Root of Cell Area"
    gridfield_units = horiz_dist_units
    calc_dA_cell_cntrs = True
    filevar_names := (/ "area" /)

  else if (strcmp_exact(field_name, "cell_dx")) then

    gridfield_desc = "Cell Size in x-Direction Along Cell Centerline"
    gridfield_units = horiz_dist_units
    calc_dx_cell_cntrs = True
    filevar_names := (/ "dx" /)

  else if (strcmp_exact(field_name, "cell_dy")) then

    gridfield_desc = "Cell Size in y-Direction Along Cell Centerline"
    gridfield_units = horiz_dist_units
    calc_dy_cell_cntrs = True
    filevar_names := (/ "dy" /)

  else if (strcmp_exact(field_name, "cell_dx_ovr_cell_dy")) then

    gridfield_desc = "Ratio of dx to dy (dx/dy)"
    gridfield_units = "-"
    calc_dx_cell_cntrs = True
    calc_dy_cell_cntrs = True
    filevar_names := (/ "dx", "dy" /)

  else if (strcmp_exact(field_name, "min_cell_dx_cell_dy")) then

    gridfield_desc = "MIN(dx, dy)"
    gridfield_units = horiz_dist_units
    calc_dx_cell_faces = True
    calc_dy_cell_faces = True
    filevar_names := (/ "dx", "dy" /)

  else if (strcmp_exact(field_name, "angle_cell_dx")) then

    gridfield_desc = "Grid Vertex x-Angle with Respect to Geographic East"
    gridfield_units = "deg east"
    calc_angle_dx_cell_cntrs = True
    filevar_names := (/ "angle_dx" /)

  else if (strcmp_exact(field_name, "angle_cell_dy")) then

    gridfield_desc = "Grid Vertex y-Angle with Respect to Geographic North"
    gridfield_units = "deg north"
    calc_angle_dy_cell_cntrs = True
    filevar_names := (/ "angle_dy" /)

  else if (strcmp_exact(field_name, "none")) then

    gridfield_desc = "Empty Field"
    gridfield_units = "-"

  else

    gridfield_desc = "Unknown Field"
    gridfield_units = "?"

  end if
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
; Return results as attributes of the logical variable gridfield_info.
;
; **********************************************************************
;
  gridfield_info := True

  gridfield_info@gridfield_desc := gridfield_desc
  gridfield_info@gridfield_units := gridfield_units
  gridfield_info@filevar_names := filevar_names
  gridfield_info@calc_dA_cell_cntrs := calc_dA_cell_cntrs
  gridfield_info@calc_dx_cell_cntrs := calc_dx_cell_cntrs
  gridfield_info@calc_dy_cell_cntrs := calc_dy_cell_cntrs
  gridfield_info@calc_dx_cell_faces := calc_dx_cell_faces
  gridfield_info@calc_dy_cell_faces := calc_dy_cell_faces
  gridfield_info@calc_angle_dx_cell_cntrs := calc_angle_dx_cell_cntrs
  gridfield_info@calc_angle_dy_cell_cntrs := calc_angle_dy_cell_cntrs

  return(gridfield_info)

end
