;
; **********************************************************************
;
; File name: get_resized_viewport_dims.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function calculates the viewport information [consisting of the 
; coordinates of the top-left corner and the dimensions, all in NDC 
; units (NDC = Non-Dimensional Coordinates)] for the new viewport that 
; a specified plot (plot) must have after it is resized in order for its
; new bounding box to have the specified size (bb_size_new; also in NDC
; units).  
; 
; Note that bb_size_new is interpreted as the larger of the two dimen-
; sions the the bounding box of the new (i.e. resized plot) assuming the
; aspect ratio of the plot doesn't change during resizing.  This means
; that it will be interpreted as the height that we would like the new 
; bounding box to have if the original plot is taller than it is wide 
; (i.e. if it is in portrait mode), and it will be interpreted as the 
; width that we would like the new bounding box to have if the original
; plot is wider than it is tall (i.e. if it is in landscape mode).
;
; Note also that the actual resizing of the plot is not performed by 
; this function (because NCL doesn't seem to allow it).  That action 
; must be performed by the calling script/function/subroutine using the
; viewport information that this function generates.
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")

undef("get_resized_viewport_dims")

function get_resized_viewport_dims( \
         plot:graphic, 
         bb_size_new:snumeric, \
         opts:logical)

local bb_orig, 
      bb_lft_orig, bb_rgt_orig, bb_top_orig, bb_bot_orig, 
      bb_width_orig, bb_height_orig, \
      bb_lft_new, bb_rgt_new, bb_top_new, bb_bot_new, \
      bb_width_new, bb_height_new, \
      vpXF_orig, vpYF_orig, vpWidthF_orig, vpHeightF_orig, \
      vpXF_new, vpYF_new, vpWidthF_new, vpHeightF_new, \
      dx_orig, dy_orig, dx_new, dy_new, \
      x_ratio_new_to_orig, y_ratio_new_to_orig, \
      viewport_info

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
    separator_line \
    := "========================================================================"
  end if
;
; **********************************************************************
;
; The logical attribute verbose of the options argument (opts) deter-
; mines whether informational messages are printed out to the screen.  
; If this attribute is not defined, set it to False.
;
; **********************************************************************
;
  if (.not. isatt(opts, "verbose")) then
    opts@verbose = False
  end if

  if (opts@verbose) then
    print("")
    print("" + separator_line)
    print("Start of output from function get_resized_viewport_dims(...):")
  end if
;
; **********************************************************************
;
; Check that bb_size_new has a valid value.
;
; **********************************************************************
;
  if ((bb_size_new .lt. 0) .or. (bb_size_new .gt. 1)) then
    print("")
    print("Error: The bounding box size of the resized plot " + \
          "(bb_size_new) must be " + char_nl + \
          "between 0 and 1:")
    print("  bb_size_new = " + bb_size_new)
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;
; Get the NDC coordinates of the bounding box of the original plot.
;
; **********************************************************************
;
  bb_orig = NhlGetBB(plot)
  bb_lft_orig = bb_orig(2)
  bb_rgt_orig = bb_orig(3)
  bb_top_orig = bb_orig(0)
  bb_bot_orig = bb_orig(1)

  if (opts@verbose) then
    print("")
    print("The bounds (in NDC units) of the bounding box of the original plot are:")
    print("")
    print("bb_lft_orig = " + bb_lft_orig)
    print("bb_rgt_orig = " + bb_rgt_orig)
    print("bb_top_orig = " + bb_top_orig)
    print("bb_bot_orig = " + bb_bot_orig)
  end if
;
; **********************************************************************
;
; Calculate the NDC width and height of the bounding box of the original
; plot.
;
; Note that a bounding box is the smallest rectangle in NDC space that
; contains all of a particular object's attributes.  For a 2-D XY or 
; contour plot (which is what we're considering here), this would in-
; clude the area containing the tickmarks, tickmark labels, the main 
; title, axis titles, legend, and anything else associated with the 
; plot.  This is in contrast to the viewport (which we will also consi-
; der below), which contains only the area within the axes.  See 
;
;   https://www.ncl.ucar.edu/Applications/viewport.shtml
; 
; for examples.
;
; **********************************************************************
;
  bb_width_orig = bb_rgt_orig - bb_lft_orig
  bb_height_orig = bb_top_orig - bb_bot_orig

  if (opts@verbose) then
    print("")
    print("The dimensions (in NDC units) of the bounding box of the original plot are:")
    print("")
    print("bb_width_orig = " + bb_width_orig)
    print("bb_height_orig = " + bb_height_orig)
  end if
;
; **********************************************************************
;
; Set or calculate the NDC width, height, and coordinates of the bound-
; ing box of the new resized plot.
;
; **********************************************************************
;
; If the original plot is taller than it is wide (i.e. in portrait
; mode), take bb_size_new to be the height of the new plot.
;
  if (bb_width_orig .le. bb_height_orig) then
    bb_height_new = bb_size_new
    bb_width_new = (bb_width_orig/bb_height_orig)*bb_height_new
;
; If the original plot is wider than it is tall (i.e. in landscape 
; mode), take bb_size_new to be the width of the new plot.
;
  else
    bb_width_new = bb_size_new
    bb_height_new = (bb_height_orig/bb_width_orig)*bb_width_new
  end if

  if (opts@verbose) then
    print("")
    print("The dimensions (in NDC units) of the bounding box of the new plot are:")
    print("")
    print("bb_width_new = " + bb_width_new)
    print("bb_height_new = " + bb_height_new)
  end if

  bb_lft_new = (1 - bb_width_new)/2.0
  bb_rgt_new = bb_lft_new + bb_width_new
  bb_top_new = (1 + bb_height_new)/2.0
  bb_bot_new = bb_top_new - bb_height_new

  if (opts@verbose) then
    print("")
    print("The dimensions (in NDC units) of the bounding box of the new plot are:")
    print("")
    print("bb_lft_new = " + bb_lft_new)
    print("bb_rgt_new = " + bb_rgt_new)
    print("bb_top_new = " + bb_top_new)
    print("bb_bot_new = " + bb_bot_new)
  end if
;
; **********************************************************************
;
; Get the NDC coordinates of the top left point of the viewport of the
; original plot and the NDC width and height of the original plot.
;
; **********************************************************************
;
  getvalues plot
    "vpXF"      : vpXF_orig
    "vpYF"      : vpYF_orig
    "vpWidthF"  : vpWidthF_orig
    "vpHeightF" : vpHeightF_orig
  end getvalues

  if (opts@verbose) then
    print("")
    print("The coordinates of the top-left corner and the dimensions (in NDC units) " + char_nl + \
          "of the viewport of the original plot are:")
    print("")
    print("vpXF_orig = " + vpXF_orig)
    print("vpYF_orig = " + vpYF_orig)
    print("vpWidthF_orig = " + vpWidthF_orig)
    print("vpHeightF_orig = " + vpHeightF_orig)
  end if
;
; **********************************************************************
;
; Calculate the NDC coordinates of the top left point of the viewport of
; the new (resized) plot and the NDC width and height of the new plot.
;
; Recall that the bounding box is larger than the viewport; in particu-
; lar, it includes the viewport as well as the axis titles, plot title, 
; etc.  Thus, the variables dx_orig and dy_orig calculated below are the
; horizontal and vertical offsets in the original plot from the bounda-
; ries of the bounding box to those of the viewport, and dx_new and dy_-
; new are the analogous quantities for the new (resized) plot.
;
; **********************************************************************
;
  dx_orig = vpXF_orig - bb_lft_orig
  dy_orig = bb_top_orig - vpYF_orig

  x_ratio_new_to_orig = bb_width_new/bb_width_orig
  y_ratio_new_to_orig = bb_height_new/bb_height_orig

  dx_new = dx_orig*x_ratio_new_to_orig
  dy_new = dy_orig*y_ratio_new_to_orig

  vpXF_new = bb_lft_new + dx_new
  vpYF_new = bb_top_new - dy_new

  vpWidthF_new = vpWidthF_orig*x_ratio_new_to_orig
  vpHeightF_new = vpHeightF_orig*y_ratio_new_to_orig

  if (opts@verbose) then
    print("")
    print("The coordinates of the top-left corner and the dimensions (in NDC units) " + char_nl + \
          "of the viewport of the new plot are:")
    print("")
    print("vpXF_new = " + vpXF_new)
    print("vpYF_new = " + vpYF_new)
    print("vpWidthF_new = " + vpWidthF_new)
    print("vpHeightF_new = " + vpHeightF_new)
  end if
;
; **********************************************************************
;
; Resize the plot to its new size by changing its viewport coordinates.
;
; Apparently, we can't change the viewport from within a function (why
; not?), so this must be done from the calling script/procedure/func-
; tion.
;
; **********************************************************************
;
;  setvalues plot
;    "vpXF"      : vpXF_new
;    "vpYF"      : vpYF_new
;    "vpWidthF"  : vpWidthF_new
;    "vpHeightF" : vpHeightF_new
;  end setvalues
;
; **********************************************************************
;
; Return results as attributes of the logical variable viewport_info.
;
; **********************************************************************
;
  viewport_info := True

  viewport_info@vpXF = vpXF_new
  viewport_info@vpYF = vpYF_new
  viewport_info@vpWidthF = vpWidthF_new
  viewport_info@vpHeightF = vpHeightF_new

  if (opts@verbose) then
    print("")
    print("End of output from function set_cnLevels_lbLabels(...).")
    print("" + separator_line)
  end if

  return(viewport_info)

end


