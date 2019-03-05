; **********************************************************************
;
; File name: get_resized_viewport_dims.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function
;                                                                      *
; **********************************************************************

undef("get_resized_viewport_dims")

function get_resized_viewport_dims( \
         plot:graphic, 
         bb_size_new:snumeric, \
         opts:logical)

local char_dq, char_nl, verbose, \
      bb_old, bb_top_old, bb_bot_old, bb_lft_old, bb_rgt_old, \
      bb_width_old, bb_height_old, \
      bb_new, bb_top_new, bb_bot_new, bb_lft_new, bb_rgt_new, \
      bb_width_new, bb_height_new, \
      vpXF_old, vpYF_old, vpWidthF_old, vpHeightF_old, \
      vpXF_new, vpYF_new, vpWidthF_new, vpHeightF_new, \
      dx_old, dy_old, dx_new, dy_new, \
      x_ratio_new_to_old, y_ratio_new_to_old, \
      out

begin
;
; **********************************************************************
;                                                                      *
; Special characters that can't be directly input into an NCL string.
;                                                                      *
; **********************************************************************
;
  char_dq = integertochar(34)
  char_nl = str_get_nl()
;
; **********************************************************************
;                                                                      *
; The local variable "verbose" determines whether informational messag-
; es are printed out to the screen.  If the options argument opts has an
; attribute named verbose, then set the local variable verbose to this 
; attribute.  Otherwise, set verbose to False.
;                                                                      *
; **********************************************************************
;
  if (isatt(opts, "verbose")) then
    verbose = opts@verbose
  else
    verbose = False
  end if

  if (verbose) then
    print("")
    print("Start of output from function get_resized_viewport_dims(...):")
    print("=======================================================")
  end if
;
; **********************************************************************
;                                                                      *
; Check that bb_size_new has a valid value.
;                                                                      *
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
;                                                                      *
; Get the NDC coordinates of the bounding box of the original plot.
;                                                                      *
; **********************************************************************
;
  bb_old = NhlGetBB(plot)
  bb_top_old = bb_old(0)
  bb_bot_old = bb_old(1)
  bb_lft_old = bb_old(2)
  bb_rgt_old = bb_old(3)

  if (verbose) then
    print("")
    print("bb_top_old = " + bb_top_old)
    print("bb_bot_old = " + bb_bot_old)
    print("bb_lft_old = " + bb_lft_old)
    print("bb_rgt_old = " + bb_rgt_old)
  end if
;
; **********************************************************************
;                                                                      *
; Calculate the NDC width and height of the bounding box of the original
; (old) plot.
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
;                                                                      *
; **********************************************************************
;
  bb_width_old = bb_rgt_old - bb_lft_old
  bb_height_old = bb_top_old - bb_bot_old
;
; **********************************************************************
;                                                                      *
; Set or calculate the NDC width, height, and coordinates of the bound-
; ing box of the new resized plot.
;                                                                      *
; **********************************************************************
;
  if (bb_width_old .le. bb_height_old) then
    bb_height_new = bb_size_new
    bb_width_new = (bb_width_old/bb_height_old)*bb_height_new
  else
    bb_width_new = bb_size_new
    bb_height_new = (bb_height_old/bb_width_old)*bb_width_new
  end if
  bb_lft_new = (1 - bb_width_new)/2.0
  bb_rgt_new = bb_lft_new + bb_width_new
  bb_top_new = (1 + bb_height_new)/2.0
  bb_bot_new = bb_top_new - bb_height_new

  if (verbose) then
    print("")
    print("bb_width_old = " + bb_width_old)
    print("bb_height_old = " + bb_height_old)
    print("bb_width_new = " + bb_width_new)
    print("bb_height_new = " + bb_height_new)
    print("bb_lft_new = " + bb_lft_new)
    print("bb_top_new = " + bb_top_new)
  end if
;
; **********************************************************************
;                                                                      *
; Get the NDC coordinates of the top left point of the viewport of the
; original plot and the NDC width and height of the original plot.
;                                                                      *
; **********************************************************************
;
  getvalues plot
    "vpXF"      : vpXF_old
    "vpYF"      : vpYF_old
    "vpWidthF"  : vpWidthF_old
    "vpHeightF" : vpHeightF_old
  end getvalues

  if (verbose) then
    print("")
    print("vpXF_old = " + vpXF_old)
    print("vpYF_old = " + vpYF_old)
    print("vpWidthF_old = " + vpWidthF_old)
    print("vpHeightF_old = " + vpHeightF_old)
  end if
;
; **********************************************************************
;                                                                      *
; Calculate the NDC coordinates of the top left point of the viewport of
; the new (resized) plot and the NDC width and height of the new plot.
;
; Recall that the bounding box is larger than the viewport; in particu-
; lar, it includes the viewport as well as the axis titles, plot title, 
; etc.  Thus, the variables dx_old and dy_old calculated below are the
; horizontal and vertical offsets in the original plot from the bounda-
; ries of the bounding box to those of the viewport, and dx_new and dy_-
; new are the analogous quantities for the new (resized) plot.
;                                                                      *
; **********************************************************************
;
  dx_old = vpXF_old - bb_lft_old
  dy_old = bb_top_old - vpYF_old

  x_ratio_new_to_old = bb_width_new/bb_width_old
  y_ratio_new_to_old = bb_height_new/bb_height_old

  dx_new = dx_old*x_ratio_new_to_old
  dy_new = dy_old*y_ratio_new_to_old

  vpXF_new = bb_lft_new + dx_new
  vpYF_new = bb_top_new - dy_new

  vpWidthF_new = vpWidthF_old*x_ratio_new_to_old
  vpHeightF_new = vpHeightF_old*y_ratio_new_to_old
;
; **********************************************************************
;                                                                      *
; Resize the plot to its new size by changing its viewport coordinates.
;
; Apparently, can't maximize from within function.  Not sure why.
;                                                                      *
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
;                                                                      *
; Return viewport of new plot.
;                                                                      *
; **********************************************************************
;
  out := True
  out@vpXF = vpXF_new
  out@vpYF = vpYF_new
  out@vpWidthF = vpWidthF_new
  out@vpHeightF = vpHeightF_new
  return(out)

end


