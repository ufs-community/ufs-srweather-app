#
#-----------------------------------------------------------------------
#
# This file defines a function that is used to interpolate (or extrapo-
# late) a grid cell size-dependent property to an arbitrary cubed-sphere
# resolution using arrays that specify a set of property values for a 
# corresponding set of resolutions.
# 
#-----------------------------------------------------------------------
#
function interpol_to_arbit_CRES() { 
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
  local scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
  local scrfunc_fn=$( basename "${scrfunc_fp}" )
  local scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Check arguments.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -ne 3 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  RES  RES_array  prop_array

where the arguments are defined as follows:

  RES:
  The cubed-sphere resolution at which to find the value of a property.
  This is in units of number of cells (in either of the two horizontal
  directions) on any one of the tiles of a cubed-sphere grid.

  RES_array:
  The name of the array containing the cubed-sphere resolutions for
  which corresponding property values are given (in prop_array).  These
  are assumed to be given from smallest to largest.
 
  prop_array:
  The name of the array containing the values of the property corres-
  ponding to the cubed-sphere resolutions in RES_array.
"

  fi
#
#-----------------------------------------------------------------------
#
# Declare local variables and initialize some.
#
#-----------------------------------------------------------------------
#
  local RES="$1"
  local RES_array_name_at="$2[@]"
  local prop_array_name_at="$3[@]"

  local RES_array=("${!RES_array_name_at}")
  local prop_array=("${!prop_array_name_at}")

  local num_valid_RESes i_min i_max i RES1 RES2 prop1 prop2 \
        m_slope y_intcpt prop
#
#-----------------------------------------------------------------------
#
# If RES is less than or equal to the smallest value in RES_array, set 
# the property value to the one corresponding to the smallest value in
# RES_array.  Similarly, if RES is larger than the largest value in 
# RES_array, set the property value to the one corresponding to the 
# largest value in RES_array.  If RES is somewhere in between the small-
# est and largest values in RES_array, find the property value by line-
# arly interpolating between the two RES_array elements between which 
# RES lies.
#
#-----------------------------------------------------------------------
#
  num_valid_RESes="${#RES_array[@]}"

  i_min=0
  i_max=$( bc -l <<< "$num_valid_RESes - 1" )

  if [ "${RES}" -le "${RES_array[$i_min]}" ]; then

    prop="${prop_array[$i_min]}"

  elif [ "${RES}" -gt "${RES_array[$i_max]}" ]; then

    prop="${prop_array[$i_max]}"

  else

    for (( i=0; i<$((num_valid_RESes-1)); i++ )); do
    
      if [ "$RES" -gt "${RES_array[$i]}" ] && \
         [ "$RES" -le "${RES_array[$i+1]}" ]; then
        RES1="${RES_array[$i]}"
        RES2="${RES_array[$i+1]}"
        prop1="${prop_array[$i]}"
        prop2="${prop_array[$i+1]}"
        m_slope=$( bc -l <<< "($prop2 - $prop1)/($RES2 - $RES1)" )
        y_intcpt=$( bc -l <<< "($RES2*$prop1 - $RES1*$prop2)/($RES2 - $RES1)" )
        prop=$( bc -l <<< "$m_slope*$RES + $y_intcpt" )
        break
      fi
    
    done

  fi

  prop=$( printf "%e\n" $prop )
  echo "$prop"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

