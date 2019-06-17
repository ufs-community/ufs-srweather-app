;
; **********************************************************************
;
; File name: plot_horiz_field.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function 
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "get_resized_viewport_dims.ncl")

undef("plot_horiz_field")

function plot_horiz_field( \
         graphics_fn:string, \
         nx_all_grids:integer, \
         ny_all_grids:integer, \
         lon_cntrs_unstruc:snumeric, \
         lat_cntrs_unstruc:snumeric, \
         lon_verts_unstruc:snumeric, \
         lat_verts_unstruc:snumeric, \
         lon_bdy_all_bdies:snumeric, \
         lat_bdy_all_bdies:snumeric, \
         field_unstruc:snumeric, \
         grid_opts:logical, \
         bdy_opts:logical, \
         plot_opts:logical)

local valid_map_projs, valid_vals, msg, \
      num_grids, num_cells_all_grids, indx_start, indx_end, i, \
      wks_type, wks, \
      all_fields_missing, \
      rsrc, \
      lon_cntrs_crnt_grid_unstruc, lat_cntrs_crnt_grid_unstruc, \
      lon_verts_crnt_grid_unstruc, lat_verts_crnt_grid_unstruc, \
      field_crnt_grid_unstruc, \
      field_missing, \
      contour_map, contour_overlay, \
      vpXF, vpYF, vpWidthF, vpHeightF, \
      FontHeightF_LR, FontColor_LR, FontHeightF_C, FontColor_C, \
      dx_vert_offset_ndc, amOrthogonalPosF_LR, \
      txres, amres, \
      txid_left_str, annotid_left_str, \
      vpXF_left_str, vpYF_left_str, vpWF_left_str, vpHF_left_str, \
      txid_right_str, annotid_right_str, \
      vpXF_right_str, vpYF_right_str, vpWF_right_str, vpHF_right_str, \
      height_max, amOrthogonalPosF_cntr, \
      txid_cntr_str, annotid_cntr_str, \
      pmAnnoViews, lb_object, \
      lbar_x, lbar_y, lbar_h, lbar_w, lbar_fh, \
      opts, \
      viewport_info, vpXF_new, vpYF_new, vpWidthF_new, vpHeightF_new, \
      num_bdies, show_grid_bdy, temp, \
      bdy_indx_start, bdy_indx_end, id_grid_bdies, \
      resp, lon_crnt_bdy, lat_crnt_bdy, \
      plot_info

begin
;
; **********************************************************************
;
; If not already defined, define the string (separator_line) that serves
; as a separator line between different sections of printout.
;
; **********************************************************************
;
  if (.not. isvar("separator_line")) then
    separator_line := repeat_str("=", 72)
  end if
;
; **********************************************************************
;
; If the map projection (map_proj) has not been specified as an attrib-
; ute of plot_opts, set it to a default value.
;
; **********************************************************************
;
  if (.not. isatt(plot_opts, "map_proj")) then 
    plot_opts@map_proj = "cyln"
  end if
;
; **********************************************************************
;
; Verify that plot_opts@map_proj is set to a valid value.
;
; **********************************************************************
;
  valid_map_projs = (/ "cyln", "ortho", "lamb" /)

  if (.not. strcmp_exact(valid_map_projs, plot_opts@map_proj)) then

    valid_vals \
    := char_dq \
    + str_join(valid_map_projs, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"The map projection (plot_opts@map_proj) is not set to a valid value:" + char_nl + \
"  plot_opts@map_proj = " + char_dq + plot_opts@map_proj + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Please provide a valid map projection.  " + \
"Stopping."
    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; If the center of the specified map projection (map_proj_ctr) has not 
; been specified as an attibute of plot_opts, set it to a default that 
; depends on the map projection.  map_proj_ctr should be a 1-D array 
; having two elements.  These two elements are the longitude (in degrees
; east) and latitude (in degrees north), respectively of the center of
; the map projection.
;
; **********************************************************************
;
  if (.not. isatt(plot_opts, "map_proj_ctr")) then 

    plot_opts@map_proj_ctr = new((/ 2 /), "float")

    if (strcmp_exact(plot_opts@map_proj, "cyln")) then
      plot_opts@map_proj_ctr(0) = 0.
      plot_opts@map_proj_ctr(1) = 0.
    else if (strcmp_exact(plot_opts@map_proj, "ortho")) then
      plot_opts@map_proj_ctr(0) = 0.
      plot_opts@map_proj_ctr(1) = 0.
    else if (strcmp_exact(plot_opts@map_proj, "lamb")) then
      plot_opts@map_proj_ctr(0) = 0.
      plot_opts@map_proj_ctr(1) = 90.
    end if
    end if
    end if

  end if
;
; **********************************************************************
;
; If left_str and right_str have not been specified as attributes of 
; plot_opts, set them to default values.
;
; **********************************************************************
;
  if (.not. isatt(plot_opts, "left_str")) then 
    plot_opts@left_str = ""
  end if

  if (.not. isatt(plot_opts, "right_str")) then 
    plot_opts@right_str = ""
  end if
;
; **********************************************************************
;
; If plot_subreg has not been specified as an attribute of plot_opts, 
; set it to a default value.
;
; **********************************************************************
;
  if (.not. isatt(plot_opts, "plot_subreg")) then
    plot_opts@plot_subreg = False
  end if
;
; **********************************************************************
;
; Calculate the starting and ending indices in the unstructured coordi-
; nate and field arrays of the data for each grid.
;
; **********************************************************************
;
  num_grids = dimsizes(nx_all_grids)
  num_cells_all_grids := nx_all_grids*ny_all_grids
  
  indx_start := new(num_grids, "integer")
  indx_end := new(num_grids, "integer")
  
  do i=0, num_grids-1
    if (i .eq. 0) then
      indx_start(i) = 0
    else
      indx_start(i) = sum(num_cells_all_grids(0:i-1))
    end if
    indx_end(i) = sum(num_cells_all_grids(0:i)) - 1
  end do

print("")
print("(nx_all_grids, ny_all_grids) = " + \
      "(" + nx_all_grids + ", " + ny_all_grids + ")")
;
; **********************************************************************
;
; Set workstation file type and dimensions and open the workstation.
;
; **********************************************************************
;
  wks_type := "png"
  wks_type@wkWidth = 1000
  wks_type@wkHeight = 750
  wks := gsn_open_wks(wks_type, graphics_fn)
;
; **********************************************************************
;
; Set the colormap.  To see the various colormaps, go to:
;
; http://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
;
; **********************************************************************
;
  gsn_define_colormap(wks, "BlAqGrYeOrReVi200")

  print("")
  print("" + separator_line)
  print("Generating plot in graphics file:")
  print("  graphics_fn = " + char_dq + graphics_fn + "." + wks_type + char_dq)
;
; **********************************************************************
;
; Set the flag that indicates whether fields on all grids have missing 
; values everywhere.  If this flag gets set to True, reset the contour
; levels and labelbar (colorbar) labels to indicate that there are no
; valid values in the fields.
;
; **********************************************************************
;
  all_fields_missing := all(ismissing(field_unstruc))

  if (all_fields_missing) then
    plot_opts@cnLevels := default_fillvalue(typeof(field_unstruc))
    plot_opts@lbLabels := "No Valid Field Values"
  end if
;
; **********************************************************************
;
; Set contour plot resources and generate color contour plot.
;
; **********************************************************************
;
  do i=0, num_grids-1

print("")
print("i = " + i)
print("indx_start(i) = " + indx_start(i))
print("indx_end(i) = " + indx_end(i))
;
; Initialize variable that specifies plot resources.
;
    rsrc := True
;
; Use full colormap, but start at color index 24.
;
    rsrc@gsnSpreadColors = True
    rsrc@gsnSpreadColorStart = 24
;
; Turn on contour fill.  This causes the regions between contour levels
; to be filled with a solid color and/or, if the fill method permits it,
; a fill pattern.
;
    rsrc@cnFillOn = True
;
; Set the fill mode to "CellFill".  This means each cell has a single 
; color that represents the field value for that cell, and no interpola-
; tion is performed.  Other values for this resource can be "AreaFill" 
; and "RasterFill", but those require interoplation.
;
    rsrc@cnFillMode = "CellFill"
;
; Set sfXArray and sfYArray to the cell center coordinates.
;
    lon_cntrs_crnt_grid_unstruc \
    := lon_cntrs_unstruc(indx_start(i):indx_end(i))
    lat_cntrs_crnt_grid_unstruc \
    := lat_cntrs_unstruc(indx_start(i):indx_end(i))
  
    rsrc@sfXArray = lon_cntrs_crnt_grid_unstruc
    rsrc@sfYArray = lat_cntrs_crnt_grid_unstruc
;
; Set sfXCellBounds and sfYCellBounds to the cell vertex coordinates.
; These resources must be set in order if the cnFillMode resource is set
; to "CellFill".
;
    lon_verts_crnt_grid_unstruc \
    := lon_verts_unstruc(indx_start(i):indx_end(i),:)
    lat_verts_crnt_grid_unstruc \
    := lat_verts_unstruc(indx_start(i):indx_end(i),:)
  
    rsrc@sfXCellBounds = lon_verts_crnt_grid_unstruc
    rsrc@sfYCellBounds = lat_verts_crnt_grid_unstruc
;
; If the grid_opts@plot_grid(i) is set to True, draw the cell edges 
; (gridlines) of the current grid.
;
    if (grid_opts@plot_grid(i)) then
;
; The resource cnCellFillMissingValEdgeColor should ideally set the cell
; edge color of those cells that contain missing values, but it seems to
; have no effect - at least when the field on the current grid contains
; all missing/fill values.  For this reason, when the field on a grid 
; contains all missing/fill values and grid_opts@plot_grid(i) for that 
; grid is set to True (i.e. we want to see the gridlines but not a field
; on that grid), we resort to the method below in which we set the cn-
; CellFillEdgeColor resource to the color we want for the gridlines, and
; (later on) we set at least one value in the field to a non-missing 
; value and we set the opacity of the contour color to 0 (transparent).
;
      rsrc@cnCellFillMissingValEdgeColor = "yellow"
;
; Set the color for the cell edge.  Note that this seems to have an ef-
; fect only if at least one element in the field is not a missing value
; (if all elements in the field are set to missing values, then no grid
; is generated).  For this reason, if all values of the field on the 
; current grid are missing/fill values, we reset at least one element in
; the field array to a non-missing value (e.g. zero), and we set the 
; opacity of the contour color to 0 so that it is transparent (so that 
; no color is shown, as if the field consisted of missing values every-
; where).
;
      rsrc@cnCellFillEdgeColor = grid_opts@gridline_colors(i)
  
    end if
;
; Extract the portion of the field array that contains the field values
; on the current grid.
;
    field_crnt_grid_unstruc \
    := field_unstruc(indx_start(i):indx_end(i))
;
; If all values of the field on the current grid are missing/fill val-
; ues, then reset at least one value to a non-missing value (e.g. zero),
; and set the opacity of the field to 0 (transparent).  We do this in
; order to be able to see the gridlines in cases in which all values in
; the field on the current grid are missing, and grid_opts@plot_grid(i)
; is set to True (because in that case, the cnCellFillMissingValEdgeCo-
; lor resource doesn't seem to have an effect, so we use the cnCellFill-
; EdgeColor resource instead along with setting the opacity to 0).
;
    field_missing := all(ismissing(field_crnt_grid_unstruc))
    if (field_missing) then
;
; At least one value in the field must be non-missing in order for cn-
; CellFillEdgeColor to have an effect.
;
      field_crnt_grid_unstruc(0) = 0
;
; We cause the cells that were artificially reset above to non-missing
; values to not appear in the plot by setting the opacity of the field
; to 0 (transparent).
;
      rsrc@cnFillOpacityF = 0.0

    end if
;
; Set sfDataArray to the field on the current grid (which has one value
; per cell).
;
    rsrc@sfDataArray = field_crnt_grid_unstruc
;
; Set the color for cells containing missing values.  This is by default
; "transparent", but we repeat it here for clarity.
;
    rsrc@cnMissingValFillColor = "transparent"
    rsrc@cnMissingValFillColor = "yellow" ; This has an effect only if not all values in the field are missing.
;
; Specify opacity of cell colors.
;
;    rsrc@cnFillOpacityF = 0.0 ; Transparent.
;    rsrc@cnFillOpacityF = 0.1
;    rsrc@cnFillOpacityF = 0.35
;    rsrc@cnFillOpacityF = 1.0 ; Opaque.
;
; If on the base plot (i.e. not an overlay), draw a labelbar (colorbar).
;
    if (i .eq. 0) then
      rsrc@lbLabelBarOn = True
    else
      rsrc@lbLabelBarOn = False
    end if
;
; Do not draw vertical box separator lines in the labelbar (but this
; doesn't turn off the box around the whole label bar).
;
    rsrc@lbBoxSeparatorLinesOn = False
;
; Turn off displaying of text box that says "CONTOUR FROM AAA TO BBB BY
; CCC".
;
    rsrc@cnInfoLabelOn = False
;
; Make sure the labelbar is fully opaque regardless of what the opacity 
; of the contour plot is set to (via the cnFillOcacityF resource).
;
    rsrc@lbOverrideFillOpacity = True
;
; **********************************************************************
;
; Map-related resources that should be set only for the base plot, not
; for the overlays [since the base plot is the only one that draws a 
; map using the gsn_csm_contour_map() function; the overlays use the 
; gsn_csm_contour() function].
;
; **********************************************************************
;
    if (i .eq. 0) then
;
; Set the latitude and longitude of the center of the map projection co-
; ordinate system.
;
      rsrc@mpCenterLonF = plot_opts@map_proj_ctr(0)
      rsrc@mpCenterLatF = plot_opts@map_proj_ctr(1)
;
; Set the map projection to use.  For the Lambert equal-area projection, 
; we rotate the projection such that it is centered at the North Pole.
;
      if (strcmp_exact(plot_opts@map_proj, "cyln")) then
        rsrc@mpProjection = "CylindricalEquidistant"
      else if (strcmp_exact(plot_opts@map_proj, "ortho")) then
        rsrc@mpProjection = "Orthographic"
      else if (strcmp_exact(plot_opts@map_proj, "lamb")) then
;        rsrc@mpProjection = "LambertEqualArea"
        rsrc@mpProjection = "LambertConformal"
      end if
      end if
      end if
;
; Improve the resolution of the map outlines.  Default is "LowRes".
;
      rsrc@mpDataBaseVersion = "MediumRes"
;      rsrc@mpDataBaseVersion = "HighRes"
;
; Plot curves of constant longitude and latitude (regardless of the plot
; projection).
;
      rsrc@mpGridAndLimbOn = True
;
; If plot_opts@plot_subreg is set to True, plot only a subregion.  Note
; that this has an effect only for the cylindrical-equidistant map pro-
; jection.                                                              <---  Is this True???
;
      if (plot_opts@plot_subreg) then
        rsrc@mpLimitMode = "LatLon"
        rsrc@mpMinLonF = plot_opts@subreg_limits(0)
        rsrc@mpMaxLonF = plot_opts@subreg_limits(1)
        rsrc@mpMinLatF = plot_opts@subreg_limits(2)
        rsrc@mpMaxLatF = plot_opts@subreg_limits(3)
      end if
  
      if (strcmp_exact(plot_opts@map_proj, "lamb")) then
  
        rsrc@mpLimitMode = "LatLon"
;        rsrc@mpMinLonF = -128
;        rsrc@mpMaxLonF = -70
;        rsrc@mpMinLatF = 20
;        rsrc@mpMaxLatF = 53

        rsrc@mpLambertParallel1F = 38.5
        rsrc@mpLambertParallel2F = 38.5
        rsrc@mpLambertMeridianF = -97.5

;        rsrc@mpLimitMode = "Corners"
;        rsrc@mpLeftCornerLonF = plot_opts@lon_min
;        rsrc@mpLeftCornerLatF = plot_opts@lat_min
;        rsrc@mpRightCornerLonF = plot_opts@lon_max
;        rsrc@mpRightCornerLatF = plot_opts@lat_max
        rsrc@mpLeftCornerLonF = -122
        rsrc@mpLeftCornerLatF = 15
        rsrc@mpRightCornerLonF = -65
        rsrc@mpRightCornerLatF = 55

      end if

    end if
;
; **********************************************************************
;
; Turn on nice tickmarks for labeling longitudes and latitudes.
;
; **********************************************************************
;
    rsrc@pmTickMarkDisplayMode = "Always"
;
; **********************************************************************
;
; Turn on or off drawing of contour lines.
;
; Note that when cnFillOn is set to True and cnFillMode is set to "Cell-
; Fill", setting cnLinesOn to True draws dashed contour lines everywhere 
; instead of drawing solid lines for positive contour values and dashed
; lines for negative values (which is the expected behavior).  It is not
; clear why this happens.
;
; It seems the best thing to do is to turn off drawing of contour lines
; since the field may be disontinuous across tiles, in which case the 
; contour line drawing algorithm gets confused and the contour lines are
; a mess.  Even if the field is not discontinuous across tiles, or if 
; there is only one tile, the contour lines don't add much value since
; they are drawn exactly at the transition between colors.
;
; **********************************************************************
;
    rsrc@cnLinesOn = False
;
; **********************************************************************
;
; If contour lines are turned on, set resources related to them.
;
; **********************************************************************
;
    if (rsrc@cnLinesOn) then
;
; The cnLineLabelDensityF resource can be increased to increase the den-
; sity of the contour line labels.
;
      rsrc@cnLineLabelDensityF = 2.0
;
; If we want to label every contour line, set cnLineLabelInterval to 1. 
; If we want to label only every other contour line, set this resource 
; to 2, etc.  Default is 2.
;
      rsrc@cnLineLabelInterval = 1

    end if
;
; **********************************************************************
;
; Turn on or off placement of contour line labels.
; 
; Note that when cnFillOn is set to True and cnFillMode is set to "Cell-
; Fill", setting cnLineLabelsOn to True seems to make no difference, 
; i.e. contour line labels are not placed on the contour lines.  This 
; seems to do with the fact that in this case, the arrays sfXCellBounds
; and sfYCellBounds are defined.
;
; **********************************************************************
;
;    rsrc@cnLineLabelsOn = True
    rsrc@cnLineLabelsOn = False
;
; **********************************************************************
;
; If contour line labels are turned on, Set resources related to them.
;
; **********************************************************************
;
    if (rsrc@cnLineLabelsOn) then
;
; Set the background color of the box that contains each contour line 
; label.  If this color is not specified, it seems to default to trans-
; parent (which corresponds to color index -1), although the online ma-
; nual says it's supposed to default to the background color (color in-
; dex 0).
;
;      rsrc@cnLineLabelBackgroundColor = "white"
      rsrc@cnLineLabelBackgroundColor = "transparent"
;      rsrc@cnLineLabelBackgroundColor = 0
;
; Explicitly set the labels to use for the contour line labels.  These
; will be used only if we are placing labels on the contour lines.  We
; set these to the set of labels retruned by the function set_cnLevels_-
; lbLabels(...) (which are the same labels that will be used for the la-
; belbar/colorbar labels).
;
      rsrc@cnExplicitLineLabelsOn = True
      rsrc@cnLineLabelStrings = plot_opts@lbLabels

    end if
;
; **********************************************************************
;
; Set the method to use for selecting the contour levels.  Then set 
; other resources accordingly.
;
; **********************************************************************
;
;    rsrc@cnLevelSelectionMode = "AutomaticLevels"
;    rsrc@cnLevelSelectionMode = "ManualLevels"
    rsrc@cnLevelSelectionMode = "ExplicitLevels"
;    rsrc@cnLevelSelectionMode = "EqualSpacedLevels"  ; This should not be used!  Investigate further.

    if (strcmp_exact(rsrc@cnLevelSelectionMode, "ManualLevels")) then
      rsrc@cnMinLevelValF = plot_opts@cnLevel_min
      rsrc@cnMaxLevelValF = plot_opts@cnLevel_max
      rsrc@cnLevelSpacingF = plot_opts@cnStep
    else if (strcmp_exact(rsrc@cnLevelSelectionMode, "ExplicitLevels")) then
      rsrc@cnLevels = plot_opts@cnLevels
;    else if (strcmp_exact(rsrc@cnLevelSelectionMode, "EqualSpacedLevels")) then
;      rsrc@cnMaxLevelCount = plot_opts@nLevs
;      rsrc@cnMaxLevelCount = 10
    else
      msg := char_nl + \
"Disallowed value specified for the cnLevelSelectionMode attribute of rsrc:" + char_nl + \
"  rsrc@cnLevelSelectionMode = " + char_dq + rsrc@cnLevelSelectionMode + char_dq + char_nl + \
"Allowed values are:" + char_nl + \
"  " + char_dq + "ManualLevels" + char_dq + char_nl + \
"  " + char_dq + "ExplicitLevels" + char_dq + char_nl + \
"Stopping."
      print("" + msg)
      exit
    end if
    end if
;
; **********************************************************************
;
; Allow the user to explicitly set lbLabelStrings, which specifies the
; set of strings to use as labels for the lablebar (colorbar).  Note 
; that the flag cnExplicitLabelBarLabelsOn must be set to True in order
; for the plotting routine to use the user-specified value of lbLabel-
; Strings (instead of overwriting it with its own values).  Note also
; that the elements of lbLabelStrings may not all appear as labels in 
; the labelbar (colorbar).  This is because by default, the plotting 
; routine ensures that these labels do not overlap by skipping every
; other label, every 2 out of 3 labels, etc, as necessary.  
;
; **********************************************************************
;
    rsrc@cnExplicitLabelBarLabelsOn = True
    rsrc@lbLabelStrings = plot_opts@lbLabels
;
; **********************************************************************
;
; Allow for spatially constant fields to be colored in instead of left
; blank.  Also, for a spatially constant field, by default the constant 
; field informational textbox will appear to inform that the field is
; constant.  Turn this off by setting cnConstFLabelOn to False. 
;
; **********************************************************************
;
    rsrc@cnConstFEnableFill = True
    rsrc@cnConstFLabelOn = False
;
; **********************************************************************
;
; If no data is available to create the contour plot (e.g. if the whole
; field consists of missing values), the default behavior is to display
; on the plot a text box containing the stirng "NO CONTOUR DATA".  Turn
; off displaying of this string.
;
; **********************************************************************
;
    rsrc@cnNoDataLabelOn = False
;
; **********************************************************************
;
; If available (e.g. from a previous call to this function) as attri-
; butes of plot_opts, retrieve the viewport parameters to use for this 
; plot and set them to corresponding attributes in rsrc.  These viewport
; values consist of the NDC coordinates of the lower-left corner of the 
; viewport and the width and height of the viewport (also in NDC units).  
; Note that the viewport for a contour plot conists of the rectagle de-
; lineated by the x and y axes.  If the viewport parameters are not spe-
; cified as attributes of plot_opts, they will be set by the plotting 
; routine [gsn_csm_contour_map(...)].
;
; **********************************************************************
;
    if (isatt(plot_opts, "vpXF") .and. \
        isatt(plot_opts, "vpYF") .and. \
        isatt(plot_opts, "vpWidthF") .and. \
        isatt(plot_opts, "vpHeightF")) then
      rsrc@vpXF = plot_opts@vpXF
      rsrc@vpYF = plot_opts@vpYF
      rsrc@vpWidthF = plot_opts@vpWidthF
      rsrc@vpHeightF = plot_opts@vpHeightF
    end if
;
; **********************************************************************
;
; Do not immediately draw the contour plot nor advance the frame because
; other objects (e.g. overlays, polylines, etc) might still need to be
; added to the plot.
;
; **********************************************************************
;
    rsrc@gsnDraw = False
    rsrc@gsnFrame = False
;
; **********************************************************************
;
; Generate (but not yet draw) the color contour plot (along with a map).
; If on the first grid, draw a map as well [by calling gsn_csm_contour_-
; map(...)].  We refer to the plot with a map for the first grid as the 
; base plot.  If on later grids, do not draw a map [by calling gsn_csm_-
; contour(...)], and overlay the contour plot on the base plot.
;
; **********************************************************************
;
    if (i .eq. 0) then
      contour_map := gsn_csm_contour_map(wks, field_crnt_grid_unstruc, rsrc)
    else
      contour_overlay := gsn_csm_contour(wks, field_crnt_grid_unstruc, rsrc)
      overlay(contour_map, contour_overlay)
    end if
  
  end do
;
; **********************************************************************
;
; Get the viewport upper-left point coordinates and width and height of
; the plot.  Note that the viewport consists only of the region inside 
; the contour plot, i.e. it doesn't include the axis labels, labelbar, 
; any plot titles, etc.  These coordinates and sizes will be used in 
; calculating the coordinates of the locations where the plot title 
; strings (three of them: a left, a right, and a center string) will be
; placed.
;
; **********************************************************************
;
  getvalues contour_map
    "vpXF"      : vpXF
    "vpYF"      : vpYF
    "vpWidthF"  : vpWidthF
    "vpHeightF" : vpHeightF
  end getvalues
;
; **********************************************************************
;
; Set the font height and color of the left, right, and center title
; strings.
;
; **********************************************************************
;
  FontHeightF_LR = 0.01
  FontColor_LR = "black"

  FontHeightF_C = 1.25*FontHeightF_LR
  FontColor_C = "black"
;
; **********************************************************************
;
; Set the vertical distance (in NDC units) of the offset to use between
; the top of the plot viewport and the bottoms of the left and right 
; title strings.  We will also use this distance as the offset between
; the top of the left or right title string (whichever is taller) and
; the bottom of the center title string.
;
; **********************************************************************
;
  dx_vert_offset_ndc = 0.01
;
; **********************************************************************
;
; Set the coordinate of the left and right title strings in coordinates
; normalized with respect to the viewport size.  This will be used in 
; specifying the location at which the left and right title string will
; be annotated to the plot.
;
; **********************************************************************
;
  amOrthogonalPosF_LR = -0.5 - dx_vert_offset_ndc*(1.0/vpHeightF)
;
; **********************************************************************
;
; Create (using gsn_create_text(...)) and then annotate to the plot
; (using gsn_add_annotation(...)) the left title string.
;
; **********************************************************************
;
  txres := True
  txres@txFontHeightF = FontHeightF_LR
  txres@txFontColor = FontColor_LR
  txid_left_str = gsn_create_text(wks, plot_opts@left_str, txres)

  amres := True
  amres@amParallelPosF = -0.5
  amres@amOrthogonalPosF = amOrthogonalPosF_LR
  amres@amJust = "BottomLeft"
  annotid_left_str = gsn_add_annotation(contour_map, txid_left_str, amres)
;
; Get the viewpoint coordinates and width and height of the text box of
; the left title string.
;
  getvalues txid_left_str
    "vpXF"      : vpXF_left_str
    "vpYF"      : vpYF_left_str
    "vpWidthF"  : vpWF_left_str
    "vpHeightF" : vpHF_left_str
  end getvalues
;
; **********************************************************************
;
; Create (using gsn_create_text(...)) and then annotate to the plot
; (using gsn_add_annotation(...)) the left title string.
;
; **********************************************************************
;
  txres := True
  txres@txFontHeightF = FontHeightF_LR
  txres@txFontColor = FontColor_LR
  txres@txJust = "BottomLeft"
  txid_right_str = gsn_create_text(wks, plot_opts@right_str, txres)

  amres := True
  amres@amParallelPosF = 0.5
  amres@amOrthogonalPosF = amOrthogonalPosF_LR
  amres@amJust = "BottomRight"
  annotid_right_str = gsn_add_annotation(contour_map, txid_right_str, amres)
;
; Get the viewpoint coordinates and width and height of the text box of
; the right title string.
;
  getvalues txid_right_str
    "vpXF"      : vpXF_right_str
    "vpYF"      : vpYF_right_str
    "vpWidthF"  : vpWF_right_str
    "vpHeightF" : vpHF_right_str
  end getvalues
;
; **********************************************************************
;
; Get the height of the taller of the left and right title strings.
;
; **********************************************************************
;
  height_max = max((/ vpHF_left_str, vpHF_right_str /))
;
; **********************************************************************
;
; Set the coordinate of the center title string in coordinates normal-
; ized with respect to the viewport size.  This will be used in specify-
; ing the location at which the center title string will be annotated to
; the plot.
;
; **********************************************************************
;
  amOrthogonalPosF_cntr \
  = amOrthogonalPosF_LR - height_max*(1.0/vpHeightF) \
  - dx_vert_offset_ndc*(1.0/vpHeightF)
;
; **********************************************************************
;
; Create (using gsn_create_text(...)) and then annotate to the plot
; (using gsn_add_annotation(...)) the center title string.
;
; **********************************************************************
;
  txres := True
  txres@txFontHeightF = FontHeightF_C
  txres@txFontColor = FontColor_C
  txid_cntr_str = gsn_create_text(wks, plot_opts@main_str, txres)

  amres := True
  amres@amParallelPosF = 0.0  ; Horizontally centered above plot.
  amres@amOrthogonalPosF = amOrthogonalPosF_cntr
  amres@amJust = "BottomCenter"
  annotid_cntr_str = gsn_add_annotation(contour_map, txid_cntr_str, amres)
;
; **********************************************************************
;
; Set labelbar resources to those specified as attributes of plot_op-
; tions, if any.
;
; **********************************************************************
;
  getvalues contour_map@contour 
    "pmAnnoViews" : pmAnnoViews
  end getvalues 
  lb_object = pmAnnoViews(0)

  if (isatt(plot_opts, "lbar_x") .and. \
      isatt(plot_opts, "lbar_y") .and. \
      isatt(plot_opts, "lbar_w") .and. \
      isatt(plot_opts, "lbar_h") .and. \
      isatt(plot_opts, "lbar_fh")) then

    rsrc@lbAutoManage = False

    setvalues lb_object 
      "vpXF"                 : plot_opts@lbar_x
      "vpYF"                 : plot_opts@lbar_y
      "vpHeightF"            : plot_opts@lbar_h
      "vpWidthF"             : plot_opts@lbar_w
      "lbLabelFontHeightF"   : plot_opts@lbar_fh
    end setvalues 

  end if
;
; **********************************************************************
;
; Draw NDC (non-dimensional coordinate, aka page coordinates) grid on
; the plot.  These range from 0 to 1.  This grid helps visualize loca-
; tions of various graphics objects.
;
; **********************************************************************
;
;  drawNDCGrid(wks)
;
; **********************************************************************
;
; Retrieve the viewport values of the drawable object.  These will be
; returned to the calling function/script.
;
; **********************************************************************
;
  getvalues contour_map
    "vpXF"      : vpXF
    "vpYF"      : vpYF
    "vpWidthF"  : vpWidthF
    "vpHeightF" : vpHeightF
  end getvalues

  getvalues lb_object 
    "vpXF"                 : lbar_x
    "vpYF"                 : lbar_y
    "vpHeightF"            : lbar_h
    "vpWidthF"             : lbar_w
    "lbLabelFontHeightF"   : lbar_fh
  end getvalues 
;
; **********************************************************************
;
; Resize the plot (if appropriate flag is set to True).
;
; **********************************************************************
;
  if (isatt(plot_opts, "resize_plot") .and. \
      isatt(plot_opts, "bounding_box_size_NDC") .and. \
      plot_opts@resize_plot) then

    opts := True
    opts@verbose = False
    viewport_info := get_resized_viewport_dims( \
                     contour_map, plot_opts@bounding_box_size_NDC, opts)
  
    vpXF_new = viewport_info@vpXF
    vpYF_new = viewport_info@vpYF
    vpWidthF_new = viewport_info@vpWidthF
    vpHeightF_new = viewport_info@vpHeightF
  
    setvalues contour_map
      "vpXF"      : vpXF_new
      "vpYF"      : vpYF_new
      "vpWidthF"  : vpWidthF_new
      "vpHeightF" : vpHeightF_new
    end setvalues

  end if
;
; **********************************************************************
;
; If bdy_opts is set to True, draw grid boundaries.  Note that bdy_opts
; should be set to True only if there is at least one valid set of 
; boundary coordinates to plot.
;
; **********************************************************************
;
  if (bdy_opts) then

    num_bdies = bdy_opts@num_bdies
    show_grid_bdy = bdy_opts@plot_bdy

    if (.not. isatt(bdy_opts, "bdy_colors")) then
      temp := new((/ num_bdies /), "string")
      temp = "black"
      bdy_opts@bdy_colors := temp
    end if

    if (.not. isatt(bdy_opts, "bdy_line_thicknesses")) then
      temp := new((/ num_bdies /), "float")
      temp = 4.0
      bdy_opts@bdy_line_thicknesses := temp
    end if

    if (.not. isatt(bdy_opts, "bdy_dash_patterns")) then
      temp := new((/ num_bdies /), "integer")
      temp = 0
      bdy_opts@bdy_dash_patterns := temp
    end if

    id_grid_bdies := new(num_bdies, "graphic")
    bdy_indx_end := -1

    do i=0, num_bdies-1

      bdy_indx_start := bdy_indx_end + 1
      bdy_indx_end \
      := bdy_indx_start + bdy_opts@num_bdy_pts_all_bdies(i) - 1

      if (show_grid_bdy(i)) then

        resp := True
        resp@gsLineColor = bdy_opts@bdy_colors(i)
        resp@gsLineThicknessF = bdy_opts@bdy_line_thicknesses(i)
        resp@gsLineDashPattern = bdy_opts@bdy_dash_patterns(i)
        lon_crnt_bdy := lon_bdy_all_bdies(bdy_indx_start:bdy_indx_end)
        lat_crnt_bdy := lat_bdy_all_bdies(bdy_indx_start:bdy_indx_end)

        id_grid_bdies(i) \
        = gsn_add_polyline( \
          wks, contour_map, lon_crnt_bdy, lat_crnt_bdy, resp)

      end if
  
    end do

  end if
;
; **********************************************************************
;
; Draw the plot and advance the frame.
;
; **********************************************************************
;
  draw(contour_map)
  frame(wks)

  print("")
  print("Done generating graphics file.")
  print("" + separator_line)
  print("")
;
; **********************************************************************
;
; Return results as attributes of the logical variable plot_info.  In-
; clude here all variables that we might want to pass to the next call
; to this function.
;
; **********************************************************************
;
  plot_info := True

  plot_info@vpXF := vpXF
  plot_info@vpYF := vpYF
  plot_info@vpWidthF := vpWidthF
  plot_info@vpHeightF := vpHeightF
  plot_info@lbar_x = lbar_x
  plot_info@lbar_y = lbar_y
  plot_info@lbar_h = lbar_h
  plot_info@lbar_w = lbar_w
  plot_info@lbar_fh = lbar_fh

  return(plot_info)

end

