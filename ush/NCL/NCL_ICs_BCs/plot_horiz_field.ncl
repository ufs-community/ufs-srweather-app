; **********************************************************************
;
; File name: plot_horiz_field.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function reads in (a horizontal slice of) the specified RAP field 
; from the specified file pointer (which should be pointing at a wrfout
; file).
;                                                                      *
; **********************************************************************

load "strcmp.ncl"
load "special_chars.ncl"
load "get_resized_viewport_dims.ncl"

undef("plot_horiz_field")

function plot_horiz_field( \
         lon_cntrs_by_cell:snumeric, \
         lat_cntrs_by_cell:snumeric, \
         lon_verts_by_cell:snumeric, \
         lat_verts_by_cell:snumeric, \
         field_by_cell:snumeric, \
         fn_graphics:string, \
         plot_options:logical)

local fn_graphics, wks_type, wks, \
      rsrc, \
      out

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
; Line to print out in order to more clearly separate different sections
; of the printout.
;                                                                      *
; **********************************************************************
;
  separator_line \
  = "##################################################################"
;
; **********************************************************************
;                                                                      *
; Set local variables to corresponding attributes of plot_options (if
; those attributes are specified) or to default values.
;                                                                      *
; **********************************************************************
;
  if (isatt(plot_options, "map_proj")) then 
    map_proj = plot_options@map_proj
  else
    map_proj = "cyln"
  end if

  if (isatt(plot_options, "map_proj_ctr")) then 
    map_proj_ctr = plot_options@map_proj_ctr
  else
    map_proj_ctr = new((/2/), "float")
  end if

  if (isatt(plot_options, "draw_grid")) then 
    draw_grid = plot_options@draw_grid
  else
    draw_grid = False
  end if

;  if (isatt(plot_options, "subreg_name")) then 
;    plot_subreg = True
;    subreg_name = plot_options@subreg_name
;    lon_min = plot_options@lon_min
;    lon_max = plot_options@lon_max
;    lat_min = plot_options@lat_min
;    lat_max = plot_options@lat_max
;  else
;    plot_subreg = False
;  end if

;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
  idx_cyln := str_match_ind_regex(map_proj, "^" + "cyln" + "$")
  idx_ortho := str_match_ind_regex(map_proj, "^" + "ortho" + "$")
  idx_lamb := str_match_ind_regex(map_proj, "^" + "lamb" + "$")

  if (ismissing(idx_cyln) .and. \
      ismissing(idx_ortho) .and. \
      ismissing(idx_lamb)) then

    print("")
    print("Disallowed value specified for " + char_dq + "map_proj" + \
          char_dq + ":")
    print("  map_proj = " + char_dq + map_proj + char_dq)
    print("Allowed values are:")
    print("  " + char_dq + "cyln" + char_dq + \
          " (for cylindrical-equidistant projection)")
    print("  " + char_dq + "ortho" + char_dq + \
          " (for orthographic (i.e. on a sphere) projection)")
    print("  " + char_dq + "lamb" + char_dq + \
          " (for Lambert conformal projection)")
    print("Please specify one of these allowed values for " + \
          char_dq + "map_proj" + char_dq + ".")
    print("Stopping.")
    exit

  end if

;
; **********************************************************************
;                                                                      *
; Check whether map_proj_ctr is specified.  If not, set it according to
; the specified map projection.  Note that this variable is not used for
; the cylindrical-equidistant map projection.
;                                                                      *
; **********************************************************************
;
  if (.not. ismissing(idx_cyln)) then
    map_proj_ctr(0) = 0.
    map_proj_ctr(1) = 0.
  else if (.not. ismissing(idx_ortho)) then
    map_proj_ctr(0) = 0.
    map_proj_ctr(1) = 0.
  else if (.not. ismissing(idx_lamb)) then
    map_proj_ctr(0) = 0.
    map_proj_ctr(1) = 90.
  end if
  end if
  end if
;
; **********************************************************************
;                                                                      *
; Set workstation file type and dimensions and open the workstation.
;                                                                      *
; **********************************************************************
;
  wks_type := "png"
  wks_type@wkWidth = 1000
  wks_type@wkHeight = 750
  wks := gsn_open_wks(wks_type, fn_graphics)

;
; Set the colormap.  To see the various colormaps, go to:
;
; http://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
;
  gsn_define_colormap(wks, "BlAqGrYeOrReVi200")

  print("")
  print("" + separator_line)
  print("")
  print("Generating plot in graphics file:")
  print("  fn_graphics = " + fn_graphics + "." + wks_type)
;
; **********************************************************************
;                                                                      *
; Set contour plot resources and generate color contour plot.
;                                                                      *
; **********************************************************************
;

; Specify plot resources.
  rsrc = True

; Maximize size of plot in frame.
;  if (.not. isatt(plot_options, "vpXF")) then
;    rsrc@gsnMaximize = True
;  end if

; Use full colormap, but start at color index 24.
  rsrc@gsnSpreadColors = True
  rsrc@gsnSpreadColorStart = 24

; Turn on contour fill.
  rsrc@cnFillOn = True
;  rsrc@cnFillOn = False

;
; Set the fill mode to "CellFill".  This means each cell has a single 
; color that represents the field value for that cell, and no interpola-
; tion is performed.  Other values for this resource can be "AreaFill" 
; and "RasterFill", but those require interoplation.
;
  rsrc@cnFillMode = "CellFill"
;  rsrc@cnFillMode = "AreaFill"

; Set sfXArray and sfYArray to the cell center coordinates.
  rsrc@sfXArray = lon_cntrs_by_cell
  rsrc@sfYArray = lat_cntrs_by_cell

; Set sfXCellBounds and sfYCellBounds to the cell vertex coordinates.
  if (rsrc@cnFillOn .and. strcmp(rsrc@cnFillMode, "CellFill")) then

    rsrc@sfXCellBounds = lon_verts_by_cell
    rsrc@sfYCellBounds = lat_verts_by_cell

; If draw_grid is True, then draw the cell edges.
    if (draw_grid) then
      rsrc@cnCellFillEdgeColor = "black"
    end if

  end if

; Set sfDataArray to the field (which has one value per cell).
  rsrc@sfDataArray = field_by_cell

; Set the color for cells containing missing values.  This is by default
; "transparent", but we repeat it here for clarity.
  rsrc@cnMissingValFillColor = "transparent"

; Specify opacity of cell colors.
;  rsrc@cnFillOpacityF = 0.0 ; Transparent.
;  rsrc@cnFillOpacityF = 0.1
;  rsrc@cnFillOpacityF = 0.35
  rsrc@cnFillOpacityF = 1.0 ; Opaque.

; Draw a labelbar (colorbar).
  rsrc@lbLabelBarOn = True
;  rsrc@lbLabelBarOn = False

; Do not draw vertical box separator lines in the labelbar (but this
; doesn't turn off the box around the whole label bar).
  rsrc@lbBoxSeparatorLinesOn = False

; Turn off text box that says "CONTOUR FROM AAA TO BBB BY CCC".
  rsrc@cnInfoLabelOn = False

; Make sure the labelbar is fully opaque regardless of what the opacity 
; of the contour plot is set to (via the cnFillOcacityF resource).
  rsrc@lbOverrideFillOpacity = True
;
; **********************************************************************
;                                                                      *
; Set the latitude and longitude of the center of the map projection co-
; ordinate system.
;                                                                      *
; **********************************************************************
;
  rsrc@mpCenterLonF = map_proj_ctr(0)
  rsrc@mpCenterLatF = map_proj_ctr(1)

; Set the map projection to use.  For the Lambert equal-area projection, 
; we rotate the projection such that it is centered at the North Pole.
  if (.not. ismissing(idx_cyln)) then
    rsrc@mpProjection = "CylindricalEquidistant"
  else if (.not. ismissing(idx_ortho)) then
    rsrc@mpProjection = "Orthographic"
  else if (.not. ismissing(idx_lamb)) then
;    rsrc@mpProjection = "LambertEqualArea"
    rsrc@mpProjection = "LambertConformal"
  end if
  end if
  end if

; Improve the resolution of the map outlines.  Default is "LowRes".
  rsrc@mpDataBaseVersion = "MediumRes"
;  rsrc@mpDataBaseVersion = "HighRes"

; Turn on map tickmarks.
  rsrc@pmTickMarkDisplayMode = "Always"

; If "plot_subreg" is specified, plot only a subregion.  Note that this has
; an effect only for the cylindrical-equidistant map projection.

  rsrc@mpMinLonF = plot_options@lon_min
  rsrc@mpMaxLonF = plot_options@lon_max
  rsrc@mpMinLatF = plot_options@lat_min
  rsrc@mpMaxLatF = plot_options@lat_max

  if (strcmp(map_proj, "lamb")) then

    rsrc@mpLimitMode = "LatLon"
;    rsrc@mpMinLonF = -128
;    rsrc@mpMaxLonF = -70
;    rsrc@mpMinLatF = 20
;    rsrc@mpMaxLatF = 53

    rsrc@mpLambertParallel1F = 38.5
    rsrc@mpLambertParallel2F = 38.5
    rsrc@mpLambertMeridianF = -97.5

;    rsrc@mpLimitMode = "Corners"
;    rsrc@mpLeftCornerLonF = plot_options@lon_min
;    rsrc@mpLeftCornerLatF = plot_options@lat_min
;    rsrc@mpRightCornerLonF = plot_options@lon_max
;    rsrc@mpRightCornerLatF = plot_options@lat_max
    rsrc@mpLeftCornerLonF = -122
    rsrc@mpLeftCornerLatF = 15
    rsrc@mpRightCornerLonF = -65
    rsrc@mpRightCornerLatF = 55

  end if
;
; **********************************************************************
;                                                                      *
; Turn on or off drawing of contour lines.
;
; Note that when cnFillOn is set to True and nFillMode is set to "Cell-
; Fill", setting cnLinesOn to True draws dashed contour lines everywhere 
; instead of drawing solid lines for positive contour values and dashed
; lines for negative values (which is the expected behavior).  It is not
; clear why this happens.
;                                                                      *
; **********************************************************************
;
  rsrc@cnLinesOn = True
;  rsrc@cnLinesOn = False
;
; **********************************************************************
;                                                                      *
; Turn on or off placement of contour line labels.
; 
; Note that when cnFillOn is set to True and nFillMode is set to "Cell-
; Fill", setting cnLineLabelsOn to True seems to make no difference, 
; i.e. contour line labels are not placed on the contour lines.  This 
; seems to do with the fact that in this case, the arrays sfXCellBounds
; and sfYCellBounds are defined.
;                                                                      *
; **********************************************************************
;
  rsrc@cnLineLabelsOn = True
;  rsrc@cnLineLabelsOn = False
;
; **********************************************************************
;                                                                      *
; Set the background color around contour the line labels.  If this co-
; lor is not specified, it seems to default to transparent (which cor-
; responds to color index -1), although the online manual says it's sup-
; posed to default to the background color (color index 0).
;                                                                      *
; **********************************************************************
;
;  rsrc@cnLineLabelBackgroundColor = "white"
  rsrc@cnLineLabelBackgroundColor = "transparent"
;  rsrc@cnLineLabelBackgroundColor = 0
;
; **********************************************************************
;                                                                      *
; Explicitly set the labels to use for the contour line labels.  These
; will be used only if we are placing labels on the contour lines.  We
; set these to the set of labels retruned by the function set_cnLevels_-
; lbLabels(..) (which are the same labels that will be used for the la-
; belbar/colorbar labels).
;                                                                      *
; **********************************************************************
;
  rsrc@cnExplicitLineLabelsOn = True
  rsrc@cnLineLabelStrings = plot_options@lbLabel_strs

;  rsrc@cnMaxDataValueFormat = "*+.6^sg"


  rsrc@cnLineLabelDensityF = 2.0
; Want every contour line to be labeled.  If we want to label only every
; other contour line, set this to 2, etc.  Default is 2.
  rsrc@cnLineLabelInterval = 1

;
; **********************************************************************
;                                                                      *
; Set the method to use for selecting the contour levels.  Then set 
; other resources accordingly.
;                                                                      *
; **********************************************************************
;
;  rsrc@cnLevelSelectionMode = "AutomaticLevels"
;  rsrc@cnLevelSelectionMode = "ManualLevels"
  rsrc@cnLevelSelectionMode = "ExplicitLevels"
;  rsrc@cnLevelSelectionMode = "EqualSpacedLevels"  ; This should not be used!  Investigate further.

  if (strcmp(rsrc@cnLevelSelectionMode, "ManualLevels")) then
    rsrc@cnMinLevelValF = plot_options@cnLevel_min
    rsrc@cnMaxLevelValF = plot_options@cnLevel_max
    rsrc@cnLevelSpacingF = plot_options@cnStep
  else if (strcmp(rsrc@cnLevelSelectionMode, "ExplicitLevels")) then
    rsrc@cnLevels = plot_options@lbLabel_nums
;  else if (strcmp(rsrc@cnLevelSelectionMode, "EqualSpacedLevels")) then
;    rsrc@cnMaxLevelCount = plot_options@nLevs
;    rsrc@cnMaxLevelCount = 10
  else
    print("")
    print("Disallowed value specified for the cnLevelSelectionMode attribute of rsrc:")
    print("")
    print("  rsrc@cnLevelSelectionMode = " + rsrc@cnLevelSelectionMode)
    print("")
    print("Allowed values are:")
    print("")
    print("  " + char_dq + "ManualLevels" + char_dq)
    print("  " + char_dq + "ExplicitLevels" + char_dq)
;    print("  " + char_dq + "EqualSpacedLevels" + char_dq)
    print("")
    print("Stopping.")
    exit
  end if
  end if
;  end if
;
; **********************************************************************
;                                                                      *
; Allow the user to explicitly set lbLabelStrings, which specifies the
; set of strings to use as labels for the lablebar (colorbar).  Note 
; that the flag cnExplicitLabelBarLabelsOn must be set to True in order
; for the plotting routine to use the user-specified value of lbLabel-
; Strings (instead of overwriting it with its own values).  Note also
; that the elements of lbLabelStrings may not all appear as labels in 
; the plot.  This is because by default, the plotting routine ensures
; that these labels do not overlap by skipping every other label, every
; 2 out of 3 labels, etc, as necessary.  
;                                                                      *
; **********************************************************************
;
  rsrc@cnExplicitLabelBarLabelsOn = True
  rsrc@lbLabelStrings = plot_options@lbLabel_strs
;
; **********************************************************************
;                                                                      *
; Allow for spatially constant fields to be plotted.
;                                                                      *
; **********************************************************************
;
  rsrc@cnConstFEnableFill = True
  rsrc@cnConstFLabelOn = False
;
; **********************************************************************
;                                                                      *
; If available (e.g. from a previous call to this function) as attri-
; butes of the plot_options input argument, retrieve the viewport para-
; meters to use for this plot and set them to corresponding attributes 
; in rsrc.  These viewport values consist of the NDC coordinates of the
; lower-left corner of the viewport and the width and height of the 
; viewport (also in NDC units).  Note that the viewport for a contour
; plot conists of the rectagle delineated by the x and y axes.  If the
; viewport parameters are not specified as attributes of plot_options, 
; they will be set by the plotting routine (gsn_csm_contour_map(...)).
;                                                                      *
; **********************************************************************
;
  if (isatt(plot_options, "vpXF") .and. \
      isatt(plot_options, "vpYF") .and. \
      isatt(plot_options, "vpWidthF") .and. \
      isatt(plot_options, "vpHeightF")) then
    rsrc@vpXF = plot_options@vpXF
    rsrc@vpYF = plot_options@vpYF
    rsrc@vpWidthF = plot_options@vpWidthF
    rsrc@vpHeightF = plot_options@vpHeightF
  end if
;
; **********************************************************************
;                                                                      *
; Do not immediately draw the contour plot nor advance the frame because
; other objects might still need to be added to the plot.
;                                                                      *
; **********************************************************************
;
  rsrc@gsnDraw = False
  rsrc@gsnFrame = False
;
; **********************************************************************
;                                                                      *
; Generate (but not yet draw) the color contour plot (along with a map).
;                                                                      *
; **********************************************************************
;
  map = gsn_csm_contour_map(wks, field_by_cell, rsrc)
;
; **********************************************************************
;                                                                      *
; Get the viewport upper-left point coordinates and width and height of
; the plot.  Note that the viewport consists only of the region inside 
; the contour plot, i.e. it doesn't include the axis labels, labelbar, 
; any plot titles, etc.  These coordinates and sizes will be used in 
; calculating the coordinates of the locations where the plot title 
; strings (three of them: a left, a right, and a center string) will be
; placed.
;                                                                      *
; **********************************************************************
;
  getvalues map
    "vpXF"      : vpXF
    "vpYF"      : vpYF
    "vpWidthF"  : vpWidthF
    "vpHeightF" : vpHeightF
  end getvalues
;
; **********************************************************************
;                                                                      *
; Set the font height and color of the left, right, and center title
; strings.
;                                                                      *
; **********************************************************************
;
  FontHeightF_LR = 0.01
  FontColor_LR = "black"

  FontHeightF_C = 1.25*FontHeightF_LR
  FontColor_C = "black"
;
; **********************************************************************
;                                                                      *
; Set the vertical distance (in NDC units) of the offset to use between
; the top of the plot viewport and the bottoms of the left and right 
; title strings.  We will also use this distance as the offset between
; the top of the left or right title string (whichever is taller) and
; the bottom of the center title string.
;                                                                      *
; **********************************************************************
;
  dx_vert_offset_ndc = 0.01
;
; **********************************************************************
;                                                                      *
; Set the coordinate of the left and right title strings in coordinates
; normalized with respect to the viewport size.  This will be used in 
; specifying the location at which the left and right title string will
; be annotated to the plot.
;                                                                      *
; **********************************************************************
;
  amOrthogonalPosF_LR = -0.5 - dx_vert_offset_ndc*(1.0/vpHeightF)
;
; **********************************************************************
;                                                                      *
; Create (using gsn_create_text(...)) and then annotate to the plot
; (using gsn_add_annotation(...)) the left title string.
;                                                                      *
; **********************************************************************
;
  txres := True
  txres@txFontHeightF = FontHeightF_LR
  txres@txFontColor = FontColor_LR
  txid_left_str = gsn_create_text(wks, plot_options@left_str, txres)

  amres := True
  amres@amParallelPosF = -0.5
  amres@amOrthogonalPosF = amOrthogonalPosF_LR
  amres@amJust = "BottomLeft"
  annotid_left_str = gsn_add_annotation(map, txid_left_str, amres)
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
;print("")
;print("vpXF_left_str = " + vpXF_left_str)
;print("vpYF_left_str = " + vpYF_left_str)
;print("vpWF_left_str = " + vpWF_left_str)
;print("vpHF_left_str = " + vpHF_left_str)
;pause

;
; **********************************************************************
;                                                                      *
; Create (using gsn_create_text(...)) and then annotate to the plot
; (using gsn_add_annotation(...)) the left title string.
;                                                                      *
; **********************************************************************
;
  txres := True
  txres@txFontHeightF = FontHeightF_LR
  txres@txFontColor = FontColor_LR
  txres@txJust = "BottomLeft"
  txid_right_str = gsn_create_text(wks, plot_options@right_str, txres)

  amres := True
  amres@amParallelPosF = 0.5
  amres@amOrthogonalPosF = amOrthogonalPosF_LR
  amres@amJust = "BottomRight"
  annotid_right_str = gsn_add_annotation(map, txid_right_str, amres)
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
;print("")
;print("vpXF_right_str = " + vpXF_right_str)
;print("vpYF_right_str = " + vpYF_right_str)
;print("vpWF_right_str = " + vpWF_right_str)
;print("vpHF_right_str = " + vpHF_right_str)
;pause

;
; **********************************************************************
;                                                                      *
; Get the height of the taller of the left and right title strings.
;                                                                      *
; **********************************************************************
;
  height_max = max((/ vpHF_left_str, vpHF_right_str /))
;
; **********************************************************************
;                                                                      *
; Set the coordinate of the center title string in coordinates normal-
; ized with respect to the viewport size.  This will be used in specify-
; ing the location at which the center title string will be annotated to
; the plot.
;                                                                      *
; **********************************************************************
;
  amOrthogonalPosF_cntr \
  = amOrthogonalPosF_LR - height_max*(1.0/vpHeightF) \
  - dx_vert_offset_ndc*(1.0/vpHeightF)
;
; **********************************************************************
;                                                                      *
; Create (using gsn_create_text(...)) and then annotate to the plot
; (using gsn_add_annotation(...)) the center title string.
;                                                                      *
; **********************************************************************
;
  txres := True
  txres@txFontHeightF = FontHeightF_C
  txres@txFontColor = FontColor_C
  txid_cntr_str = gsn_create_text(wks, plot_options@main_str, txres)

  amres := True
  amres@amParallelPosF = 0.0  ; Horizontally centered above plot.
  amres@amOrthogonalPosF = amOrthogonalPosF_cntr
  amres@amJust = "BottomCenter"
  annotid_cntr_str = gsn_add_annotation(map, txid_cntr_str, amres)
;
; **********************************************************************
;                                                                      *
; Set labelbar resources to those specified as attributes of plot_op-
; tions, if any.
;                                                                      *
; **********************************************************************
;
  getvalues map@contour 
    "pmAnnoViews" : pmAnnoViews
  end getvalues 
  lb_object = pmAnnoViews(0)

  if (isatt(plot_options, "lbar_x") .and. \
      isatt(plot_options, "lbar_y") .and. \
      isatt(plot_options, "lbar_w") .and. \
      isatt(plot_options, "lbar_h") .and. \
      isatt(plot_options, "lbar_fh")) then

    rsrc@lbAutoManage = False

    setvalues lb_object 
      "vpXF"                 : plot_options@lbar_x
      "vpYF"                 : plot_options@lbar_y
      "vpHeightF"            : plot_options@lbar_h
      "vpWidthF"             : plot_options@lbar_w
      "lbLabelFontHeightF"   : plot_options@lbar_fh
    end setvalues 

  end if
;
; **********************************************************************
;                                                                      *
; Draw NDC (non-dimensional coordinate, aka page coordinates) grid on
; the plot.  These range from 0 to 1.  This grid helps visualize loca-
; tions of various graphics objects.
;                                                                      *
; **********************************************************************
;
;  drawNDCGrid(wks)
;
; **********************************************************************
;                                                                      *
; Retrieve the viewport values of the drawable object.  These will be
; returned to the calling function/script.
;                                                                      *
; **********************************************************************
;
  getvalues map
    "vpXF"      : vpXF
    "vpYF"      : vpYF
    "vpWidthF"  : vpWidthF
    "vpHeightF" : vpHeightF
  end getvalues
;  print("")
;  print("vpXF = " + vpXF)
;  print("vpYF = " + vpYF)
;  print("vpWidthF = " + vpWidthF)
;  print("vpHeightF = " + vpHeightF)
;  pause

  getvalues lb_object 
    "vpXF"                 : lbar_x
    "vpYF"                 : lbar_y
    "vpHeightF"            : lbar_h
    "vpWidthF"             : lbar_w
    "lbLabelFontHeightF"   : lbar_fh
  end getvalues 
;
; **********************************************************************
;                                                                      *
; Resize the plot (if appropriate flag is set to True).
;                                                                      *
; **********************************************************************
;
  if (isatt(plot_options, "resize_plot") .and. \
      isatt(plot_options, "bounding_box_size_NDC") .and. \
      plot_options@resize_plot) then

    opts := True
;    opts@verbose = True
    opts@verbose = False
    out := get_resized_viewport_dims( \
           map, plot_options@bounding_box_size_NDC, opts)
  
    vpXF_new = out@vpXF
    vpYF_new = out@vpYF
    vpWidthF_new = out@vpWidthF
    vpHeightF_new = out@vpHeightF
  
    setvalues map
      "vpXF"      : vpXF_new
      "vpYF"      : vpYF_new
      "vpWidthF"  : vpWidthF_new
      "vpHeightF" : vpHeightF_new
    end setvalues

  end if
;
; **********************************************************************
;                                                                      *
; Draw the plot and advance the frame.
;                                                                      *
; **********************************************************************
;
  draw(map)
  frame(wks)

  print("")
  print("Done generating graphics file.")
  print("")
  print("" + separator_line)
  print("")
;
; **********************************************************************
;                                                                      *
; Return various output variables as attributes of the "out" variable.
; Include here all variables that we want to pass to the next call to
; this function.
;                                                                      *
; **********************************************************************
;
  out := True
  out@vpXF := vpXF
  out@vpYF := vpYF
  out@vpWidthF := vpWidthF
  out@vpHeightF := vpHeightF
  out@lbar_x = lbar_x
  out@lbar_y = lbar_y
  out@lbar_h = lbar_h
  out@lbar_w = lbar_w
  out@lbar_fh = lbar_fh

  return(out)

end

