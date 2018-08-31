; **********************************************************************
;
; File name: set_cnLevels_lbLabels.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function generates and returns a numeric array containing the le-
; vels at which to draw contours for a field having the specified mini-
; mum and maximum values (field_min and field_max).  The number of such
; levels (i.e. the size of the array) is specified by the input argument
; num_cnLevels.  
;
; This function also generates (and returns) a string array containing
; the labels corresponding to the calculated levels.  These labels can 
; be used to annotate the contour lines (using the cnLineLabelStrings
; resource) and/or to annotate the labelbar (using the lbLabelStrings
; resource) in case a labelbar is to be generated for the contour plot.
;                                                                      *
; **********************************************************************

load "pause.ncl"
load "strcmp.ncl"

undef("set_cnLevels_lbLabels")

function set_cnLevels_lbLabels( \
         field_min:snumeric, field_max:snumeric, num_cnLevels:integer, \
         opts:logical)

local char_dq, char_nl, \
      verbose, \
      field_type, \
      field_range, nLevs, cnIntvl, \
      precision, fmt, cnIntvl_E_fmt_str, \
      idx_E, mntsa_cnIntvl_str, expnt_cnIntvl_str, \
      mntsa_cnIntvl, expnt_cnIntvl, expnt_cnIntvl_factor, \
      mntsa_cnLevel_min, cnLevel_min, cnLevel_max, \
      lbLabel_nums, lbLabel_strs, \
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
; attribute.  Otherwise, set the local verbose variable to False.
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
    print("Start of output from function set_cnLevels_lbLabels(...):")
    print("========================================================")
  end if
;
; **********************************************************************
;                                                                      *
; Check that field_min is less than or equal to field_max.  If not, 
; print out a warning and stop.
;                                                                      *
; **********************************************************************
;
  if (field_min .gt. field_max) then
    print("")
    print("Error: field_min must be less than or equal to field_max:")
    print("  field_min = " + field_min)
    print("  field_max = " + field_max)
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;                                                                      *
; Get the data type of the field and store it in the variable field_-
; type.  In doing so, we first check whether field_min and field_max are
; of the same type.  If so, we set field_type to this type.  If not, we
; print out an error message and stop.
;                                                                      *
; **********************************************************************
;
  if (strcmp(typeof(field_min), typeof(field_max))) then
    field_type = typeof(field_min)
  else
    print("")
    print("Error: field_min and field_max must have the same data type:")
    print("  typeof(field_min) = " + typeof(field_min))
    print("  typeof(field_max) = " + typeof(field_max))
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;                                                                      *
; Calculate the range of values for the field, i.e. the difference be-
; tween the maximum and minimum values.  Then use this range to calcu-
; late an initial estimate for the contour interval (i.e. the difference
; between any two contour level values), which we denote by cnIntvl.
;                                                                      *
; **********************************************************************
;
  field_range = field_max - field_min
  nLevs = num_cnLevels
  cnIntvl = field_range/(nLevs - 1)

  if (verbose) then
    print("")
    print("Input parameters and initial estimate of contour interval:")
    print("  field_min = " + field_min)
    print("  field_max = " + field_max)
    print("  field_range = " + field_range)
    print("  field_type = " + field_type)
    print("  nLevs = " + nLevs)
    print("  cnIntvl = " + cnIntvl)
  end if
;
; **********************************************************************
;                                                                      *
; No variation in the field (i.e. constant field).
;                                                                      *
; **********************************************************************
;
  if (field_range .eq. 0) then

    print("")
    print("Encountered constant field.")
    print("Setting all nLevs = " + tostring(nLevs) + \
          " contour levels to same value.")

    lbLabel_nums := new((/nLevs/), field_type)
    lbLabel_nums = field_min

    fmt = "%0.2f"
    lbLabel_strs = sprintf(fmt, lbLabel_nums)

    out := True
    out@lbLabel_nums = lbLabel_nums
    out@lbLabel_strs = lbLabel_strs

    if (verbose) then
      print("")
      print("End of output from function set_cnLevels_lbLabels(...).")
      print("=======================================================")
    end if

    return(out)
    
  end if
;
; **********************************************************************
;                                                                      *
; Generate a string containing the contour interval (cnIntvl) expressed
; in scientific notation, i.e. in the form
;
;   [-]m.ddE±xx,
;
; where the number of "d"s (i.e. the precision) is 2.
;                                                                      *
; **********************************************************************
;
  precision = 2
  fmt = "%0." + precision + "E"
  cnIntvl_E_fmt_str := sprintf(fmt, cnIntvl)
;
; **********************************************************************
;                                                                      *
; Get the portions of the string before the "E" (the mantissa) and after 
; (the exponent).
;                                                                      *
; **********************************************************************
;
  idx_E = str_index_of_substr(cnIntvl_E_fmt_str, "E", 1)
  mntsa_cnIntvl_str := str_get_cols(cnIntvl_E_fmt_str, 0, idx_E-1)
  expnt_cnIntvl_str := str_get_cols(cnIntvl_E_fmt_str, idx_E+1, -1)

  if (verbose) then
    print("")
    print("After conversion of cnIntvl to a string using formatted " + \
          "sprintf(...):")
    print("  fmt = " + char_dq + fmt + char_dq)
    print("  cnIntvl_E_fmt_str = " + cnIntvl_E_fmt_str)
    print("  mntsa_cnIntvl_str = " + mntsa_cnIntvl_str)
    print("  expnt_cnIntvl_str = " + expnt_cnIntvl_str)
  end if
;
; **********************************************************************
;                                                                      *
; Calculate the mantissa and the exponent of cnIntvl by converting their
; string representations back to numerical representations.  Note that:
;
; *) The mantissa will be rounded to 3 significant digits.  This is be-
;    cause in expressing the mantissa in scientific notation above using
;    the sprintf(...) function, we set the precision to 2.  This is a 
;    minor adjustment to the mantissa.
;
; *) Due to the output format used in the call to sprintf(...) above,
;    the mantissa of cnIntvl is guaranteed to be greater than or equal
;    to 1 and less than 10.
;
; Then use the mantissa and exponent of cnIntvl to calculate cnIntvl to 
; 3 significant digits.
;                                                                      *
; **********************************************************************
;
  mntsa_cnIntvl = totype(mntsa_cnIntvl_str, field_type)
  expnt_cnIntvl = tointeger(expnt_cnIntvl_str)
  cnIntvl = mntsa_cnIntvl*10^expnt_cnIntvl

  if (verbose) then
    print("")
    print("After rounding cnIntvl to " + tostring(precision+1) + \
          " significant digits:")
    print("  mntsa_cnIntvl = " + mntsa_cnIntvl)
    print("  expnt_cnIntvl = " + expnt_cnIntvl)
    print("  cnIntvl = " + cnIntvl)
  end if
;
; **********************************************************************
;                                                                      *
; We now adjust the mantissa of the contour interval (mntsa_cnIntvl) to
; obtain a value that will (later below) generate "nice" values for the
; contour levels, i.e. values that are easily comprehensible in a con-
; tour plot.  In this adjustment, we require that mntsa_cnIntvl be one
; of the integers 1, 2, 4, 5, and 10.  To determine which of these inte-
; gers mntsa_cnIntvl be set to, we first find the one it is is closest 
; to and then reset it to that integer.  Thus, the adjustment procedure
; for mntsa_cnIntvl is as follows:
;
; *) If 1.0 <= mntsa_cnIntvl < 1.5, reset mntsa_cnIntvl to 1.
; *) If 1.5 <= mntsa_cnIntvl < 3.0, reset mntsa_cnIntvl to 2.
; *) If 3.0 <= mntsa_cnIntvl < 4.5, reset mntsa_cnIntvl to 4.
; *) If 4.5 <= mntsa_cnIntvl < 7.5, reset mntsa_cnIntvl to 5.
; *) If 7.5 <= mntsa_cnIntvl < 10, reset mntsa_cnIntvl to 10.
;                                                                      *
; **********************************************************************
;
  if ((1.0 .le. mntsa_cnIntvl) .and. (mntsa_cnIntvl .lt. 1.5)) then
    mntsa_cnIntvl = 1
  else if ((1.5 .le. mntsa_cnIntvl) .and. (mntsa_cnIntvl .lt. 3.0)) then
    mntsa_cnIntvl = 2
  else if ((3.0 .le. mntsa_cnIntvl) .and. (mntsa_cnIntvl .lt. 4.5)) then
    mntsa_cnIntvl = 4
  else if ((4.5 .le. mntsa_cnIntvl) .and. (mntsa_cnIntvl .lt. 7.5)) then
    mntsa_cnIntvl = 5
  else if ((7.5 .le. mntsa_cnIntvl) .and. (mntsa_cnIntvl .lt. 10.0)) then
; Resetting the mntsa_cnIntvl to 10 is the same as resetting it to 1 and 
; incrementing the exponent of cnIntvl (expnt_cnIntvl) by 1.
    mntsa_cnIntvl = 1
    expnt_cnIntvl = expnt_cnIntvl + 1
  end if
  end if
  end if
  end if
  end if
;
; **********************************************************************
;                                                                      *
; Since mntsa_cnIntvl is now an integer and will be treated as such in 
; the following code, we now change its type to an integer.
;                                                                      *
; **********************************************************************
;
  mntsa_cnIntvl := tointeger(mntsa_cnIntvl)
;
; **********************************************************************
;                                                                      *
; Use the new integer value of mntsa_cnIntvl to calculate a new cnIntvl.  
;                                                                      *
; **********************************************************************
;
  expnt_cnIntvl_factor := 10^expnt_cnIntvl
  cnIntvl := mntsa_cnIntvl*expnt_cnIntvl_factor

  if (verbose) then
    print("")
    print("After adjusting cnIntvl to a " + char_dq + "nice" + char_dq + \
          " integer value:")
    print("  mntsa_cnIntvl = " + mntsa_cnIntvl)
    print("  expnt_cnIntvl = " + expnt_cnIntvl + \
          "  (expnt_cnIntvl_factor = " + expnt_cnIntvl_factor + ")")
    print("  cnIntvl = " + cnIntvl)
  end if
;
; **********************************************************************
;                                                                      *
; In order to obtain "nice" values for the contour levels, not only must
; the contour interval have a nice value but so must the minimum contour
; line value cnLevel_min (because we will add multiples of cnIntvl to 
; cnLevel_min to obtain all the contour line values).  To derive a nice
; value for cnLevel_min, we start by deriving such a value for its man-
; tissa, as described below.
;
; Calculate an initial estimate for the mantissa of the minimum contour 
; line value cnLevel_min if cnLevel_min were expressed with an exponent
; that is equal to that of cnIntvl.  We denote this mantissa by mntsa_-
; cnLevel_min.  Thus, mntsa_cnLevel_min is defined by the expression
;
;   cnLevel_min = mntsa_cnLevel_min*10^(expnt_cnIntvl)
;
; Solving this for mntsa_cnLevel_min gives
;
;   mntsa_cnLevel_min = cnLevel_min/10^(expnt_cnIntvl)
; 
; To obtain an initial estimate for mntsa_cnLevel_min, we set cnLevel_-
; min on the right-hand side to field_min.  This gives
;
;   mntsa_cnLevel_min = field_min/10^(expnt_cnIntvl)
;
; We use this expression below.
;                                                                      *
; **********************************************************************
;
  mntsa_cnLevel_min = field_min/expnt_cnIntvl_factor
;
; **********************************************************************
;                                                                      *
; To obtain a "nice" value for cnLevel_min (i.e. a value that is easily
; comprehensible when displayed in a contour plot), we will require that
; its mantissa be an integer.  Also, we would like cnLevel_min to be 
; less than or equal to field_min (so that all values of the field are 
; included in the range [cnLevel_min, cnLevel_max] that we will calcu-
; late).  Thus, we now truncate the mntsa_cnLevel_min calculated above
; using NCL's floor(...) function.
;                                                                      *
; **********************************************************************
;
  mntsa_cnLevel_min := tointeger(floor(mntsa_cnLevel_min))
;
; **********************************************************************
;                                                                      *
; We do not necessary yet have a "nice" value for mntsa_cnLevel_min, 
; i.e. a value that will correspond to a "nice" value for cnLevel_min in
; the contour plot to be generated.  Thus, we now decrement our previous
; estimate for mntsa_cnLevel_min (which is now an integer) by 1 as many
; times as necessary until we obtain one that corresponds to a "nice" 
; value.  (Note that we decrement, not increment, by 1 in order to be 
; sure that the value of cnLevel_min we end up with is less than or 
; equal to field_min.)  What constitutes a "nice" value for mntsa_cnLe-
; vel_min depends on the mantissa of cnIntvl (i.e. mntsa_cnIntvl; recall
; that this is now one of the following integers: 1, 2, 4, and 5) as
; follows:
;
; *) If mntsa_cnIntvl is 1, we define a "nice" value for mntsa_cnLevel_-
;    min to be any integer.  Since mntsa_cnLevel_min is already an inte-
;    ger, we do not need to make any adjustments to it.
;
; *) If mntsa_cnIntvl is 2 or 4, we define a "nice" value for mntsa_cn-
;    Level_min to be an even integer.  Thus, if mntsa_cnLevel_min is al-
;    ready even, we do not make any adjustments to it.  If mntsa_cnLe-
;    vel_min is odd, we decrement it by 1 to obtain an even integer.
;
; *) If mntsa_cnIntvl is 5, we define a "nice" value for mntsa_cnLevel_-
;    min_to be an integer that ends in a 0 or a 5 (i.e. an integer that
;    is evenly divisible by 5).  Thus, if mntsa_cnLevel_min is already 
;    divisible by 5, we do not make any adjustments to it.  If mntsa_-
;    cnLevel_min is not divisible by 5, we repeatedly decrement it by 1
;    until we obtain a value that is divisible by 5.
;                                                                      *
; **********************************************************************
;
  if (mntsa_cnIntvl .eq. 1) then

; Do nothing.

  else if ((mntsa_cnIntvl .eq. 2) .or. (mntsa_cnIntvl .eq. 4)) then

    if ((mntsa_cnLevel_min%2) .ne. 0) then
      mntsa_cnLevel_min = mntsa_cnLevel_min - 1
    end if

  else if (mntsa_cnIntvl .eq. 5) then

    do while ((mntsa_cnLevel_min%5) .ne. 0)
      mntsa_cnLevel_min = mntsa_cnLevel_min - 1
    end do

  else

    print("")
    print("Error: Disallowed value for mntsa_cnIntvl:")
    print("  mntsa_cnIntvl = " + mntsa_cnIntvl)
    print("mntsa_cnIntvl must be 1, 2, 4, or 5.")
    print("Stopping.")
    exit

  end if
  end if
  end if
;
; **********************************************************************
;                                                                      *
; Now that we've determined the mantissa and exponent of the first 
; (i.e. smallest or minimum) contour level cnLevel_min (the mantissa 
; being mntsa_cnLevel_min and the exponent being the same as that of 
; cnIntvl, i.e. expnt_cnIntvl), we proceed to calculate cnLevel_min it-
; self.  Note that since mntsa_cnLevel_min and expnt_cnIntvl_factor are
; both integers, cnLevel_min will also be an integer.  Note also that 
; cnLevel_min will be less than field_min by some amount that is less 
; than or equal to cnIntvl.
;                                                                      *
; **********************************************************************
;
  cnLevel_min := mntsa_cnLevel_min*expnt_cnIntvl_factor
;
; **********************************************************************
;                                                                      *
; Now calculate the value of the last (i.e. largest or maximum) contour 
; level (cnLevel_max).  We do this by first setting cnLevel_max to cnLe-
; vel_min and then repeatedly incrementing it by cnIntvl until it be-
; comes greater than or equal to field_max.  Then calculate the number
; of contour levels between cnLevel_min and cnLevel_max, inclusive.
;                                                                      *
; **********************************************************************
;
  cnLevel_max := cnLevel_min
  do while (cnLevel_max .lt. field_max)
    cnLevel_max = cnLevel_max + cnIntvl
  end do
  nLevs = tointeger(round((cnLevel_max - cnLevel_min)/cnIntvl + 1, 0))

  if (verbose) then
    print("")
    print("Contour level min/max values that include field_min and field_max:")
    print("  cnLevel_min = " + cnLevel_min + " (field_min = " + field_min + ")")
    print("  cnLevel_max = " + cnLevel_max + " (field_max = " + field_max + ")")
    print("  cnIntvl = " + cnIntvl)
    print("  nLevs = " + nLevs)
  end if
;
; **********************************************************************
;                                                                      *
; Check that cnLevel_min is indeed less than or equal to field_min and 
; that cnLevel_max is indeed greater than or equal to field_max.  This 
; should be the case by design, but we test to be sure.
;                                                                      *
; **********************************************************************
;
  if (cnLevel_min .gt. field_min) then
    print("")
    print("cnLevel_min must be less than or equal to field_min in " + \
          "order for the " + char_nl + \
          "contour plot to include all values of the field:")
    print("  cnLevel_min = " + cnLevel_min)
    print("  field_min = " + field_min)
    print("Stopping.")
    exit
  end if

  if (cnLevel_max .lt. field_max) then
    print("")
    print("cnLevel_max must be greater than or equal to field_max in " + \
          "order for the " + char_nl + \
          "contour plot to include all values of the field:")
    print("  cnLevel_max = " + cnLevel_max)
    print("  field_max = " + field_max)
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;                                                                      *
; Check that the difference between field_min and cnLevel_min is indeed
; less than or equal to cnIntv.  Similary, check that the difference be-
; tween field_max and cnLevel_max is indeed less than or equal to cn-
; Intv.  These constraints should be satisfied, but test to be sure.
;                                                                      *
; **********************************************************************
;
  abs_diff = abs(field_min - cnLevel_min)
  if (abs_diff .gt. cnIntvl) then
    print("")
    print("cnLevel_min must be within cnIntvl of field_min:")
    print("  field_min = " + field_min)
    print("  cnLevel_min = " + cnLevel_min)
    print("  cnIntvl = " + cnIntvl)
    print("  abs(field_min - cnLevel_min))= " + abs_diff)
    print("Stopping.")
    exit
  end if

  abs_diff = abs(field_max - cnLevel_max)
  if (abs_diff .gt. cnIntvl) then
    print("")
    print("cnLevel_max must be within cnIntvl of field_max:")
    print("  field_max = " + field_max)
    print("  cnLevel_max = " + cnLevel_max)
    print("  cnIntvl = " + cnIntvl)
    print("  abs(field_max - cnLevel_max))= " + abs_diff)
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;                                                                      *
; We now have a cnLevel_min and a cnLevel_max that satisfy the inequali-
; ties
;
;   cnLevel_min <= field_min <= field_max <= cnLevel_max
;
; and
;
;   0 <= field_min - cnLevel_min <= cnIntvl
;
; and
;
;   0 <= cnLevel_max - field_max <= cnIntvl
;
; Note that during the generation a contour plot in NCL, if the contour
; levels are specified, the contour plot routines add a bin (or color if
; color-filling between contour levels) before the minimum specified 
; contour value (to hold field values that are less than the minimum 
; contour value) and a bin (or color) after the maximum specified con-
; tour value (to hold field values that are greater than the maximum
; contour value).  Thus, if the range [cnLevel_min, cnLevel_max] already
; includes field_min and field_max, no values of the field will fall in
; these two new bins, making them irrelevant.  To make these bins rele-
; vant, we now increase cnLevel_min by cnIntvl and decrease cnLevel_max
; by cnIntvl such that we have
;
;   field_min <= cnLevel_min <= cnLevel_max <= field_max
;
; and
;
;   0 <= cnLevel_min - field_min <= cnIntvl
;
; and
;
;   0 <= field_max - cnLevel_max <= cnIntvl
;
; With this modification, at least some values of the field will fall 
; within the two bins that the NCL contour plotting routines add.
;                                                                      *
; **********************************************************************
;
  cnLevel_min := cnLevel_min + cnIntvl
  cnLevel_max := cnLevel_max - cnIntvl
  nLevs = tointeger(round((cnLevel_max - cnLevel_min)/cnIntvl + 1, 0))
  
  if (verbose) then
    print("")
    print("Contour level min/max values that exclude field_min and " + \
          "field_max " + char_nl + \
          "(by less than a contour interval):")
    print("  cnLevel_min = " + cnLevel_min + " (field_min = " + field_min + ")")
    print("  cnLevel_max = " + cnLevel_max + " (field_max = " + field_max + ")")
    print("  cnIntvl = " + cnIntvl)
    print("  nLevs = " + nLevs)
  end if
;
; **********************************************************************
;                                                                      *
; Construct the numeric array containing the contour levels.
;                                                                      *
; **********************************************************************
;
  lbLabel_nums := fspan(cnLevel_min, cnLevel_max, nLevs)
;  lbLabel_nums := ispan(cnLevel_min, cnLevel_max, cnIntvl)  ; cnIntvl is not necessarily an integer, so can't use this.

  if (verbose) then
    print("")
    print("Contour level values:")
    print("  lbLabel_nums = " + lbLabel_nums)
  end if
;
; **********************************************************************
;                                                                      *
; Construct the string array containing the contour labels.
;                                                                      *
; **********************************************************************
;
  precision = 0
  if (expnt_cnIntvl .lt. 0) then
    precision = abs(expnt_cnIntvl)
  end if
  fmt = "%0." + tostring(precision) + "f"
  lbLabel_strs = sprintf(fmt, lbLabel_nums)

  if (verbose) then
    print("")
    print("Contour level labels (strings) generated using fmt = " + \
          char_dq + fmt + char_dq + ":")
    print("  lbLabel_strs = " + lbLabel_strs)
  end if
;
; **********************************************************************
;                                                                      *
; Return various output variables as attributes of the "out" variable.
; Note that we convert types back to that of the specified field.
;                                                                      *
; **********************************************************************
;
  out := True
  out@lbLabel_nums = totype(lbLabel_nums, field_type)
  out@lbLabel_strs = lbLabel_strs

  if (verbose) then
    print("")
    print("End of output from function set_cnLevels_lbLabels(...).")
    print("=======================================================")
  end if

  return(out)

end


