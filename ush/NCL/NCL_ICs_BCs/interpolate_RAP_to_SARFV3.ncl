; **********************************************************************
;
; File name: interpolate_RAP_to_SARFV3.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function interpolates (regrids) a field on the RAP grid to the 
; halo of the SARFV3 grid.  
;                                                                      *
; **********************************************************************

undef("interpolate_RAP_to_SARFV3")

function interpolate_RAP_to_SARFV3( \
         lon_cntrs_by_cell_RAP:snumeric, \
         lat_cntrs_by_cell_RAP:snumeric, \
         lon_verts_by_cell_RAP:snumeric, \
         lat_verts_by_cell_RAP:snumeric, \
         lon_cntrs_by_cell_SARFV3:snumeric, \
         lat_cntrs_by_cell_SARFV3:snumeric, \
         lon_verts_by_cell_SARFV3:snumeric, \
         lat_verts_by_cell_SARFV3:snumeric, \
         field_by_cell_RAP:snumeric, \
         gen_weights:logical, \
         src_grid_filename:string, dst_grid_filename:string, weights_filename:string)

local opt, field_by_cell_SARFV3, out

begin
;
; **********************************************************************
;                                                                      *
; If gen_weights is set to True, call the function ESMF_regrid(...) to 
; generate a set of weights and interpolate the specified field from the
; RAP to the SARFV3 grid.  The ESMF_regrid(...) function will also save
; the weights it generates in the specified file (opt@WgtFileName), and
; it will save descriptions of the source (RAP) and destination (SARFV3)
; grids in two additional NetCDF files (opt@SrcFileName and opt@ Dst-
; FileName, respectively).  
;                                                                      *
; **********************************************************************
;
  if (gen_weights) then
;
; **********************************************************************
;                                                                      *
; Create the variable whose attributes will contain the options to be 
; passed to NCL's ESMF (Earth System Modeling Framework) regridding 
; functions below.  Then set some of its attributes.
;                                                                      *
; **********************************************************************
;
    opt = True

; If output files already exist, allow them to be overwritten.
    opt@ForceOverwrite = True

; Turn debugging messages on in the calls to ESMF regridding functions.
    opt@Debug = True

; Print the CPU time spent in the individual ESMF routines.
    opt@PrintTimings = True
;
; **********************************************************************
;                                                                      *
; Set the source grid type and specify the coordinates of the source
; grid's cell centers and corners.
;                                                                      *
; **********************************************************************
;
    opt@SrcGridType = "unstructured"
;
    opt@SrcGridLon = lon_cntrs_by_cell_RAP
    opt@SrcGridLat = lat_cntrs_by_cell_RAP
;
    opt@SrcGridCornerLon = lon_verts_by_cell_RAP
    opt@SrcGridCornerLat = lat_verts_by_cell_RAP
;
; **********************************************************************
;                                                                      *
; Set the destination grid type and specify the coordinates of the des-
; tination grid's cell centers and corners.
;                                                                      *
; **********************************************************************
;
    opt@DstGridType = "unstructured"
;
    opt@DstGridLon = lon_cntrs_by_cell_SARFV3
    opt@DstGridLat = lat_cntrs_by_cell_SARFV3
;
    opt@DstGridCornerLon = lon_verts_by_cell_SARFV3
    opt@DstGridCornerLat = lat_verts_by_cell_SARFV3
;
; **********************************************************************
;                                                                      *
; Set the names of the source and destination grid description files 
; and the name of the interpolation weights file.
;                                                                      *
; **********************************************************************
;
    opt@SrcFileName = src_grid_filename
    opt@DstFileName = dst_grid_filename
    opt@WgtFileName = weights_filename

print("")
print("opt@SrcFileName = " + opt@SrcFileName)
print("opt@DstFileName = " + opt@DstFileName)
print("opt@WgtFileName = " + opt@WgtFileName)

    print("")
    print("Generating source grid (RAP), destination grid " + \
          "(SARFV3), and weights file and regridding field " + \
          "to destination (SARFV3) grid...")
    field_by_cell_SARFV3 = ESMF_regrid(field_by_cell_RAP, opt)
;
; **********************************************************************
;                                                                      *
; If gen_weights is set to False, call the function ESMF_regrid_with_-
; weights(...) to interpolate the specified field from the RAP to the 
; SARFV3 grid using the precomputed weights specified in the file opt@
; WgtFileName.
;                                                                      *
; **********************************************************************
;
  else

    print("")
    print("Regridding field to destination (SARFV3) grid...")
    field_by_cell_SARFV3 \
    = ESMF_regrid_with_weights(field_by_cell_RAP, weights_filename, False)

  end if

print("")
printVarSummary(field_by_cell_SARFV3)
;
; **********************************************************************
;                                                                      *
; Return the interpolated field.  This is done as an attribute to the 
; "out" variable to allow this function to return additional variables
; in the future (as other attributes of "out").
;                                                                      *
; **********************************************************************
;
  out = True
  out@field_by_cell_SARFV3 = field_by_cell_SARFV3
  return(out)

end





