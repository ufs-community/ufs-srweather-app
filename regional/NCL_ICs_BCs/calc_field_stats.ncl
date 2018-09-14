; **********************************************************************
;
; File name: calc_field_stats.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function calculates, prints out, and returns various statistics 
; of the specified field.
;                                                                      *
; **********************************************************************

undef("calc_field_stats")

function calc_field_stats( \
         field:snumeric, field_desc:string, field_units:string, \
         print_field_stats:logical)

local dims, rank, dim_nums, \
      field_min, field_max, field_median, field_mean, \
      i, units, out

begin

  dims := dimsizes(field)
  rank := dimsizes(dims)
  dim_nums := ispan(0, rank-1, 1)

  field_min := min(field)
  field_max := max(field)
; Note that the median is calculated over all elements of the field 
; (i.e. over all dimensions of the array containing the field).
  field_median := dim_median_n(field, dim_nums)
  field_mean := avg(field)

  if (print_field_stats) then
    print("")
    print("Specified field, units, and array dimension are:")
    print("")
    print("  field_desc = " + field_desc)
    print("  field_units = " + field_units)
    print("  rank = " + rank)
    do i=0, rank-1
      print("  dims(" + i + ") = " + dims(i))
    end do
    print("")
    print("Statistics of this field are:")
    print("")
    units := " [" + field_units + "]"
    print("  field_min = " + field_min + units)
    print("  field_max = " + field_max + units)
    print("  field_median = " + field_median + units)
    print("  field_mean = " + field_mean + units)
  end if
;
; **********************************************************************
;                                                                      *
; Return various output variables as attributes of the "out" variable.
;                                                                      *
; **********************************************************************
;
  out := True
  out@rank = rank
  out@dims = dims
  out@field_min = field_min
  out@field_max = field_max
  out@field_median = field_median
  out@field_mean = field_mean
  return(out)

end


