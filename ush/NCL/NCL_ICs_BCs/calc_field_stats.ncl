; **********************************************************************
;
; File name: calc_field_stats.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function calculates and returns various statistics of the speci-
; fied field.  If the argument print_field_stats is set to True, it will
; also print these statistics to the screen.
;                                                                      *
; **********************************************************************

load "special_chars.ncl"

undef("calc_field_stats")

function calc_field_stats( \
         field:snumeric, field_desc:string, field_units:string, \
         print_field_stats:logical)

local field_dims, field_rank, dim_nums, \
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
  dim_nums := ispan(0, field_rank-1, 1)
;
; **********************************************************************
;
; Calculate the field's minimum and maximum values and its median and
; mean.  Note that the median is calculated over all elements of the
; field (i.e. over all dimensions of the array containing the field).
;
; **********************************************************************
;
  field_min := min(field)
  field_max := max(field)
  field_median := dim_median_n(field, dim_nums)
  field_mean := avg(field)

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

  msg := str_split(msg, char_nl)


  if (print_field_stats) then

if (False) then
    print("")
    print("The specified field's description, units, rank, and dimensions are:")
    print("")
    print("  field_desc = " + char_dq + field_desc + char_dq)
    print("  field_units = " + char_dq + field_units + char_dq)
    print("  field_rank = " + field_rank)
    field_dims_str := tostring(field_dims)
    field_dims_str := str_join(field_dims_str, ", ")
    print("  field_dims = (" + field_dims_str + ")")
    print("")
    print("Statistics of this field are:")
    print("")
    units := " [" + field_units + "]"
    print("  field_min = " + field_min + units)
    print("  field_max = " + field_max + units)
    print("  field_median = " + field_median + units)
    print("  field_mean = " + field_mean + units)
end if

    print("" + msg)

  end if
;
; **********************************************************************
;                                                                      *
; Return various output variables as attributes of the field_stat_info
; variable.
;                                                                      *
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


