;
; **********************************************************************
;
; File name: read_namelist.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function reads in the specified Fortran namelist in the speci-
; fied file.  It is called as follows:
;
;   nl = read_namelist(filename, nl_name)
;
; Here, filename is a string containing the name of (or the full path 
; to) the Fortran namelist file, and nl_name is a string containing the 
; name of the namelist (since the file may contain more than one name-
; list).  The function returns a string nl containing the name of the 
; namelist and having attributes with the same names as the member vari-
; ables of the namelist (specified in the file) and having the values 
; specified in the file.
;
; This function was inspired by the function "namelist" written by Den-
; nis Shea.  
;
; **********************************************************************
;
load "pause.ncl"

undef ("read_namelist")
function read_namelist(filename:string, namelist:string)
local \
  ampers_char, \
  comma_char, \
  decimal_char, \
  equal_char, \
  exclam_char, \
  fwdslash_char, \
  newline_char, \
  null_char, \
  quot1_char, \
  quot2_char, \
  space_char, \
\
  cmmnt_char, \
  elem_delim_char, \
elem_delim_chars, \
  first_char, \
  last_char, \
  quot_char, \
\
  num_chars, \
  num_cmmnts, \
  num_decimals, \
  num_lines, \
  num_strings, \
\
  inds_cmmnts, \
  inds_equals, \
  inds_False, \
  indx_first_equal, \
  indx_line_start, \
  indx_line_end, \
  inds_True, \
\
  all_lines, \
  all_words, \
  first_word, \
  line, \
\
  true_str, \
  false_str, \
  RHS_str, \
\
  attr_name, \
  i, \
  in_quotes, \
  n, \
  pls_mns_pt_digit_chars, \
  RHS, \
  rhs, \
  temp
     

begin
;
; **********************************************************************
;
; Create the output variable.  We will attach to this as attributes the 
; values read in from the specified file.  The variable itself is set 
; to the specified name of the namelist.
;
; **********************************************************************
;
  nl = namelist
;
; **********************************************************************
;
; Set special characters needed during processing of the namelist file.
;
; **********************************************************************
;
; Space (int 32).
  space_char = tochar(" ")

; Equal sign (int 61).
  equal_char = tochar("=")

; Comma as value separator (int 44).
  comma_char = tochar(",")

; Period or decimal point to indicate float (int 46).
  decimal_char = tochar(".")

; Ampersand (int 38).
  ampers_char = tochar("&")

; Single quote (int 39).
  quot1_char = tochar("'")

; Forward slash.
  fwdslash_char = tochar("/")

; Exclamation point as comment character.
  exclam_char = tochar("!")

; Double quote (int 34).
  quot2_char = integertochar(34)

; Newline (int 10).
  newline_char = integertochar(10)

; Null character (int 0)
  null_char = integertochar(0)
;
; **********************************************************************
;
; Set the character to assume to be the comment character in the name-
; list file.  Also, set the character to assume to be the delimiter 
; between array elements in the namelist file.  
;
; **********************************************************************
;
  cmmnt_char = exclam_char

; GSK: 01/18/2017
; The variable elem_delim_char needs to be removed and replaced by 
; the array variable elem_delim_chars everywhere, but that requires 
; rewriting some code and testing, so I haven't done it yet.  I've only
; performed the replacement in one location where it was needed for 
; reading in the FV3 namelist.

  elem_delim_char = space_char
;  elem_delim_char = comma_char
elem_delim_chars = (/ space_char, comma_char /)
;elem_delim_chars = (/ comma_char, comma_char /)
;
; **********************************************************************
;
; Read in the namelist file and save it as a 1-D array of strings.  
; Then get the number of lines in the file.
;
; **********************************************************************
;
  all_lines = asciiread(filename, -1, "string")
  num_lines = dimsizes(all_lines)
;
; **********************************************************************
;
; Loop over lines in the file until we get the line on which the speci-
; fied namelist starts.  Such a line will start with optional white-
; space, then an @, then followed immediately by the name of the name-
; list, followed by additional optional whitespace and variable specifi-
; cations.  Here, we assume that there are no variable specifications
; following the whitespace after the name of the namelist.
;
; **********************************************************************
;
  indx_line_start = -1
  
  do n=0, num_lines-1

; Strip off leading and trailing spaces and tabs from the current line, 
; and replace multiple spaces and/or tabs with a single space.
    line := str_squeeze(all_lines(n))
; If there are no characters in the current line, just move on to the 
; next line.
    if (strlen(line) .eq. 0) then
      continue
; Otherwise, get the first non-whitespace character in the line.
    else

      all_words := str_split(line, " ")
      first_word := tochar(all_words(0))
      first_char := first_word(0)
; If the first non-whitespace character on the current line is an amper-
; sand, and the word following the ampersand is the name of the speci-
; fied namelist, then this line marks the beginning of the namelist spe-
; cification.  Thus, save the line number and exit the loop over all 
; lines in the file.
      if ((first_char .eq. ampers_char) .and. \
          (first_word(1:) .eq. namelist)) then
        indx_line_start = n
        break
      end if
      
    end if
    
  end do
  
;print("")
;print("############################################################################################")
;print("indx_line_start = " + indx_line_start)
;print("############################################################################################")
;pause

  if (indx_line_start .eq. -1) then
    print("")
    print("Could not find starting line of namelist in file:")
    print("  filename = " + filename)
    print("  namelist = " + namelist)
    print("  indx_line_start = " + indx_line_start)
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;
; Loop over lines in the file, starting with the one after the one that 
; that marks the start of the namelist, until we get the line on which 
; the specified namelist ends.  Such a line will be the first one after 
; the namelist start line that has as its last character a forward 
; slash (which is not part of a character string or part of a comment
; at the end of the line).  For simplicity, we assume here that the end-
; ing forward slash is on a line of its own (possibly preceded by white-
; space and followed by other characters).
;
; **********************************************************************
;
  indx_line_end = -1

  do n=indx_line_start+1, num_lines-1

; Strip off leading and trailing spaces and tabs from the current line, 
; and replace multiple spaces and/or tabs with a single space.
    line := str_squeeze(all_lines(n))
; If there are no characters in the current line, just move on to the 
; next line.
    if (strlen(line) .eq. 0) then
      continue
; Otherwise, get the first non-whitespace character in the line.
    else
    
      all_words := str_split(line, " ")
      first_word := tochar(all_words(0))
      first_char := first_word(0)
; If the first non-whitespace character on the current line is a for-
; ward slash, then the line marks the end of the namelist specifica-
; tion.  Thus, save the line number and exit the loop over all lines 
; in the file.
      if (first_char .eq. fwdslash_char) then
        indx_line_end = n
        break
      end if
      
    end if

  end do
  
;print("")
;print("############################################################################################")
;print("indx_line_end = " + indx_line_end)
;print("############################################################################################")
;pause

  if (indx_line_end .eq. -1) then
    print("")
    print("Could not find ending line of namelist in file:")
    print("  filename = " + filename)
    print("  namelist = " + namelist)
    print("  indx_line_end = " + indx_line_end)
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;
; Loop through those lines of the file that define the namelist and pro-
; cess each line.
;
; **********************************************************************
;
  do n=indx_line_start+1, indx_line_end-1
;
; **********************************************************************
;
; Strip leading and trailing whitespace from the current line and con-
; vert the result to a 1-D array of characters.  
;
; Note that the str_strip(...) function removes leading and trailing 
; whitespace, but it does not remove the newline character at the end 
; of the string if such a character is present.  Thus, we have to re-
; move it separately.  From trial-and-error, it seems that even the 
; last line in the file will have a newline at the end even if there is 
; no blank line after it.
;
; **********************************************************************
;
    line := stringtochar(str_strip(all_lines(n)))

;print("")
;print("")
;print("############################################################################################")
;print("===>> n = " + n)
;print("line:")
;print("" + line)

;
; **********************************************************************
;
; Don't process the current line if any of the following is true:
;
; 1) The line is empty.
; 2) The line starts with the Fortran comment character.
;
; In these cases, simply move on to the next line.
;
; **********************************************************************
;
    if ((strlen(tostring(line)) .eq. 0) .or. \
        (line(0) .eq. cmmnt_char)) then
      continue
    end if
;
; **********************************************************************
;
; Get the location of all equal signs in the line.  Then keep only the 
; location of the first one since this is the only one that can indi-
; cate the separation between the variable name (on the left of it) and 
; the value (on the right).  If there is no equal sign, print out a 
; warning and exit
;
; **********************************************************************
;
    inds_equals := ind(line .eq. equal_char)
    if (ismissing(inds_equals(0))) then
      print("")
      print("No equal sign found on line:")
      print("  line = " + line)
      print("Stopping.")
      exit
    else
      indx_first_equal := inds_equals(0)
    end if
;
; **********************************************************************
;
; Get the name of the variable from the portion of the current line be-
; fore the first equal sign (which we refer to as the left-hand side).  
; This will be the name of an attribute of the output variable of this
; function.
;
; **********************************************************************
;
    attr_name = str_strip(tostring(line(:indx_first_equal-1)))
;
; **********************************************************************
;
; Extract the string to the right of the equal sign.  We refer to this
; as the right-hand side.  This right-hand side represents the value
; that the attribute on the left-hand side is to be assigned.
;
; **********************************************************************
;
    RHS := tochar(str_strip(tostring(line(indx_first_equal+1:))))
;print("HELLO 1111:  RHS = " + RHS)
;pause
;
; **********************************************************************
;
; Get the first (non-whitespace) character on the right-hand side and 
; check if it has an allowed value.  Note that if this character is ei-
; ther a single or a double quote, it indicates that the right-hand side 
; represents a character value and that the single (double) quote is the
; quotation character used to denote character strings (either is valid 
; in Fortran, although not simultaneously).
;
; **********************************************************************
;
    first_char := RHS(0)

    pls_mns_pt_digit_chars \
      = (/ "+", "-", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" /)

    quote_char = null_char
    if (first_char .eq. quot1_char) then
      is_char_value = True
      quote_char = quot1_char
    else if  (first_char .eq. quot2_char) then
      is_char_value = True
      quote_char = quot2_char
    else if (any(first_char .eq. pls_mns_pt_digit_chars)) then
      is_char_value = False
    else
      print("")
      print("Disallowed first character on right-hand side of equal sign:")
      print("  first_char = " + first_char)
      print("Stopping.")
      exit
    end if
    end if
    end if
;
; **********************************************************************
;
; Consider the case of the right-hand side being of type string.
;
; **********************************************************************
;
    if (is_char_value) then
;
; **********************************************************************
;
; Split the string containing the right-hand side into several sub-
; strings as determined by the array element delimiter character.
;
; **********************************************************************
;
      RHS_str := tostring(RHS)
      if (quote_char .eq. quot1_char) then
        rhs := str_split_csv(RHS_str, tostring(elem_delim_char), 1)
      else if (quote_char .eq. quot2_char) then
        rhs := str_split_csv(RHS_str, tostring(elem_delim_char), 2)
      end if
      end if
;
; **********************************************************************
;
; The str_split_csv(...) function returns a 2-D array with the first di-
; mension equal to the number of strings in the input string array.  
; Since here we alway pass in a single line (a 1-D string array), this
; first dimension is degenerate (i.e. it is a singleton dimension).  
; Use the rm_single_dims(...) function to get rid of this dimension.
;
; **********************************************************************
;
      rhs := rm_single_dims(rhs)
;
; **********************************************************************
;
; Remove leading and trailing whitespace (which, if present, will be 
; outside the quotation marks) and thus unimportant.
;
; **********************************************************************
;
      rhs := str_strip(rhs)
;
; **********************************************************************
;
; Remove all elements of the string array rhs that are either blank or
; contain missing values.  The blank values show up if there are two ar-
; ray element delimiters separated by only whitespace, and the missing
; values show up if there are two delimiters without any other charac-
; ters between them.  In either case, there is no information to retain. 
;
; **********************************************************************
;
      rhs := rhs(ind(.not. ismissing(rhs) .and. .not. str_is_blank(rhs)))
;
; **********************************************************************
;
; Process the strings in the rhs array.
;
; **********************************************************************
;
      in_quotes = True
      num_strings = dimsizes(rhs)
      i = 0    
      do while ((i .le. num_strings-1) .and. in_quotes)

        temp := tochar(rhs(i))
        num_chars := strlen(rhs(i))

        first_char := temp(0)
        last_char := temp(num_chars-1)
;
; **********************************************************************
;
; First, check whether the current string in rhs starts and ends with a
; quotation character.  If so, retain only the characters between the 
; quotes.
;
; **********************************************************************
;
        if ((first_char .eq. quote_char) .and. \
            (last_char .eq. quote_char)) then

          temp := tochar(rhs(i))
          rhs(i) = tostring(temp(ind(temp .ne. quote_char)))
          i = i + 1
;
; **********************************************************************
;
; Next, check whether at least the first character is a quotation cha-
; racter.  If so, search for the second quote somewhere in the string.  
; If it exists and if the characters after it are optional whitespace 
; followed by a comment character, then we discard all characters after
; the second quote (and then we also discard the quotes).  Otherwise, 
; we print out a warning message and stop execution.
;
; **********************************************************************
;
        else if ((first_char .eq. quote_char) .and. \
                 (last_char .ne. quote_char)) then
;
; **********************************************************************
;
; Find the index of the second occurrence of the quotation character, 
; if any.  Note that we know there will be at least one because the 
; first character is a quotation character.
;
; **********************************************************************
;
          temp := ind(tochar(rhs(i)) .eq. quote_char)
          num_quotes = dimsizes(temp)
          if (num_quotes .gt. 1) then
            indx_second_quote := temp(1)
          else
            print("")
            print("Improperly formatted character specification.  Cannot " + \
                  "find matching quotation character:")
            print("  RHS = " + RHS)
            print("  quote_char = " + quote_char)
            print("  elem_delim_char = " + elem_delim_char)
            print("  i = " + i)
            print("  rhs(i) = " + rhs(i))
            print("Stopping.")
            exit
          end if
;
; **********************************************************************
;
; If here, second quotation character exists.
;
; **********************************************************************
;
          temp := tochar(rhs(i))
          temp := tochar(str_strip(tostring(temp(indx_second_quote+1:))))
          first_char := temp(0)
          if (first_char .eq. cmmnt_char) then
            temp := tochar(rhs(i))
            temp := temp(:indx_second_quote)
            rhs(i) = tostring(temp(ind(temp .ne. quote_char)))
            i = i + 1
            break
          else
            print("")
            print("Improperly formatted character specification.  Characters " + \
                  "are not quoted:")
            print("  RHS = " + RHS)
            print("  quote_char = " + quote_char)
            print("  elem_delim_char = " + elem_delim_char)
            print("  i = " + i)
            print("  rhs(i) = " + rhs(i))
            print("Stopping.")
            exit
          end if
;
; **********************************************************************
;
; If the first character in the current string is a comment character, 
; it signals the end of the meaningful portion of the line, so we move
; on to the next line (i.e. no need to look at the remaining strings in 
; rhs).
;
; **********************************************************************
;
        else if (first_char .eq. cmmnt_char) then

          in_quotes = False
          break
;
; **********************************************************************
;
; If the first character is not a quotation or comment character, some-
; thing must be wrong.  In this case, print out a warning and stop exe-
; cution.
;
; **********************************************************************
;
        else

          print("")
          print("Improperly formatted character specification.  Characters " + \
                "are not quoted:")
          print("  RHS = " + RHS)
          print("  quote_char = " + quote_char)
          print("  elem_delim_char = " + elem_delim_char)
          print("  i = " + i)
          print("  rhs(i) = " + rhs(i))
          print("Stopping.")
          exit
        
        end if
        end if
        end if
      
      end do
;
; **********************************************************************
;
; Keep only those strings in rhs that were processed as meaningful ele-
; ments of a string array (e.g. don't keep portions that are comments
; in the namelist file).
;
; **********************************************************************
;
      rhs := rhs(:i-1)
;
; **********************************************************************
;
; Consider the case of the right-hand side being of type logical, inte-
; ger, or float.
;
; **********************************************************************
;
    else
;
; **********************************************************************
;
; Get the number of comment characters on the right-hand side.  If there
; is at least one comment character, keep as the right-hand side only 
; those characters before the first comment character.
;
; **********************************************************************
;
      inds_cmmnts := ind(RHS .eq. cmmnt_char)
      num_cmmnts = dimsizes(inds_cmmnts)
      if ((num_cmmnts .eq. 1) .and. ismissing(inds_cmmnts(0)))
        num_cmmnts = 0
      end if

      if (num_cmmnts .ne. 0) then
        RHS := RHS(:inds_cmmnts(0)-1)
      end if
;
; **********************************************************************
;
; Squeeze out any extra (repeated) spaces and tabs, e.g. between array
; elements.
;
; **********************************************************************
;
      RHS_str := str_squeeze(tostring(RHS))
      RHS := tochar(RHS_str)
;print("HELLO 2222:  RHS = " + RHS)
;
; **********************************************************************
;
; Consider the case of the right-hand side being of type logical.
;
; **********************************************************************
;
; The str_match_ic_regex(...) function is only available in NCL version
; 6.3.0 and later, which may not be available for various reasons.  So
; try using another method to check whether the right-hand side contains
; logical values.

;      true_str := str_match_ic_regex(RHS_str, "\.t(rue)?\.")
;      false_str := str_match_ic_regex(RHS_str, "\.f(alse)?\.")

      true_str := str_match_ic(RHS_str, ".t.")
      if (ismissing(true_str)) then
        true_str := str_match_ic(RHS_str, ".true.")
      end if

      false_str := str_match_ic(RHS_str, ".f.")
      if (ismissing(false_str)) then
        false_str := str_match_ic(RHS_str, ".false.")
      end if
      
      if ( (.not. ismissing(true_str)) .or. \
           (.not. ismissing(false_str)) ) then

        RHS_str := str_upper(RHS_str)
        rhs := str_strip(str_split(RHS_str, tostring(elem_delim_char)))
        inds_True := ind((rhs .eq. ".T.") .or. (rhs .eq. ".TRUE."))
        inds_False := ind((rhs .eq. ".F.") .or. (rhs .eq. ".FALSE."))

        rhs := new(dimsizes(rhs), "logical")
        if (.not. ismissing(inds_True(0))) then
          rhs(inds_True) = True
        end if
        if (.not. ismissing(inds_False(0))) then
          rhs(inds_False) = False
        end if
;
; **********************************************************************
;
; Consider the right-hand side being of type integer or float.  First,
; get the number of decimal points (periods) on the right-hand side.  If
; any are present, we will treat the right-hand side as of type float.  
; Otherwise, we will treat the right-hand side as of type integer.
;
; **********************************************************************
;
      else

        num_elem_delim_chars := product(dimsizes(elem_delim_chars))
        num_elems := new(num_elem_delim_chars, "integer")
;print("num_elem_delim_chars = " + num_elem_delim_chars)
        do i=0, num_elem_delim_chars-1
          temp := str_strip(str_split(RHS_str, tostring(elem_delim_chars(i))))
          num_elems(i) = product(dimsizes(temp))
;print("BYE 0000:  i = " + i)
;print("BYE 1111:  num_elems(i) = " + num_elems(i))
        end do

        inds_num_elems_gt_one := ind(num_elems .gt. 1)
        ne := product(dimsizes(inds_num_elems_gt_one))

        if (ne .gt. 1)

          print("")
          print("More than one array delimiter character yields " + \
                "a number of array elements that " + newline_char + \
                "is greater than one:")
          print("  RHS_str = " + RHS_str)
          do i=0, num_elem_delim_chars-1
            print("  i = " + i + \
                  "; elem_delim_chars(i) = " + quot2_char + elem_delim_chars(i) + quot2_char + \
                  "; num_elems(i) = " + num_elems(i))
          end do
          print("Stopping.")
          exit

        else if (ne .eq. 1) 

          if (.not. ismissing(inds_num_elems_gt_one))
            num_elems := num_elems(inds_num_elems_gt_one)
          else
            num_elems := 1
          end if

        else

          print("")
          print("The variable ne should not be less than 1:")
          print("  ne = " + ne)
          print("Stopping.")
          exit

        end if
        end if


;a(ind(ismissing(a))) = 0;

;print("BYE 2222:  num_elems = " + num_elems)
;print("BYE 3333:  inds_num_elems_gt_one = " + inds_num_elems_gt_one)
;print("BYE 4444:  ne = " + ne)
;        num_elems := num_elems(inds_num_elems_gt_one)
;print("BYE 5555:  num_elems = " + num_elems)

;print("HELLO 3333:  RHS_str = " + RHS_str)
;print("HELLO 4444:  temp = " + temp)

        num_decimals = num(RHS .eq. decimal_char)
        if (num_decimals .eq. 0) then
          rhs := stringtointeger(temp)
        else
          rhs := stringtofloat(temp)
        end if
;print("HELLO 5555:  rhs = " + rhs)
;pause
      end if
      
    end if
;
; **********************************************************************
;
; Assign attribute to the value specified on the right-hand side.
;
; **********************************************************************
;
    nl@$attr_name$ = rhs
    
  end do
;
; **********************************************************************
;
; Done with loop over lines in namelist file.  Now return the output va-
; riable.
;
; **********************************************************************
;
;list_vars()
  return(nl)

end


