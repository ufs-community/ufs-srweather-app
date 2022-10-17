;
; **********************************************************************
;
; File name: calc_field_stats.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function calculates and returns various statistics of the speci-
; fied field.  These statistics consist of the minimum, maximum, median,
; and mean.  This function also returns the field's rank and dimension
; sizes as well as a multiline string containing information about the
; field and its statistics.  If the argument print_field_stats is set to
; True, this function will also print this string to the screen.
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")

undef("calc_field_stats")

function calc_field_stats( \
         field:snumeric, field_desc:string, field_units:string, \
         print_field_stats:logical)

local field_dims, field_rank, dim_inds, \
      field_min, field_max, field_median, field_mean, \
      field_dims_str, units, msg, field_stat_info

begin
;
; **********************************************************************
;
; Get the field's dimensions and rank.
;
; **********************************************************************
;
  field_dims := dimsizes(field)
  field_rank := dimsizes(field_dims)
  dim_inds := ispan(0, field_rank-1, 1)
;
; **********************************************************************
;
; If the given field consists solely of missing values, set the minimum, 
; maximum, median, and mean for the field to this missing value.  Other-
; wise, call functions to calculate the minimum, maximum, median, and 
; mean.  Note that the median is calculated over all elements of the 
; field (i.e. over all dimensions of the array containing the field).
;
; **********************************************************************
;
  if (all(ismissing(field))) then
    field_missing_value = default_fillvalue(typeof(field))
    field_min := field_missing_value
    field_max := field_missing_value
    field_median := field_missing_value
    field_mean := field_missing_value
  else
    field_min := min(field)
    field_max := max(field)
    field_median := dim_median_n(field, dim_inds)
    field_mean := avg(field)
  end if
;
; **********************************************************************
;
; Create a (multiline) string describing the field and summarizing its 
; statistics.  Then, if print_field_stats is set to True, print this 
; string to screen. 
;
; **********************************************************************
;
  field_dims_str := tostring(field_dims)
  field_dims_str := str_join(field_dims_str, ", ")
  units := " [" + field_units + "]"

  msg := char_nl + \
"The specified field's description, units, rank, and dimensions are:" + char_nl + \
char_nl + \
"  field_desc = " + char_dq + field_desc + char_dq + char_nl + \
"  field_units = " + char_dq + field_units + char_dq + char_nl + \
"  field_rank = " + field_rank + char_nl + \
"  field_dims = (" + field_dims_str + ")" + char_nl + \
char_nl + \
"Statistics of this field are:" + char_nl + \
char_nl + \
"  field_min = " + field_min + units + char_nl + \
"  field_max = " + field_max + units + char_nl + \
"  field_median = " + field_median + units + char_nl + \
"  field_mean = " + field_mean + units
;
; Recast msg as an array (one line per element).  This allows for extra
; spaces to be easily prepended at the beginning of each line.
;
  msg := str_split(msg, char_nl)

  if (print_field_stats) then
    print("" + msg)
  end if
;
; **********************************************************************
;
; Return results as attributes of the logical variable field_stat_info.
;
; **********************************************************************
;
  field_stat_info := True

  field_stat_info@field_rank = field_rank
  field_stat_info@field_dims = field_dims
  field_stat_info@field_min = field_min
  field_stat_info@field_max = field_max
  field_stat_info@field_median = field_median
  field_stat_info@field_mean = field_mean
  field_stat_info@msg = msg

  return(field_stat_info)

end


