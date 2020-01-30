#
#-----------------------------------------------------------------------
#
# For a description of this function, see the usage message below.
# 
#-----------------------------------------------------------------------
#
function get_elem_inds() {
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
  if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  array_name  str_to_match  [inds_to_return]

This function prints to stdout the indices of those elements of a given
array that match (i.e. are equal to) a given string.  It can return the
index of the first matched element, the index of the last matched ele-
ment, or the indices of all matched elements.  The return code
from this function will be zero if at least one match is found and non-
zero if no matches are found.  

The arguments to this function are defined as follows:

  array_name:
  The name of the array in which to search for str_to_match.  Note that
  this is the name of the array, not the array itself.

  str_to_match:
  The string to match in array_name.

  inds_to_return:
  Optional argument that specifies the subset of the indices of the ar-
  ray elements that match str_to_match to print to stdout.  Must be set
  to \"first\", \"last\", or \"all\" (but is case insensitive).  If set to 
  \"first\", the index of only the first matched element is printed.  If 
  set to \"last\", the index of only the last matched element is printed.
  If set to \"all\", the indices of all matched elements are printed.  De-
  fault is \"all\".
"

  fi
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local array_name \
        str_to_match \
        inds_to_return \
        array_name_at \
        array \
        valid_vals_inds_to_return \
        match_inds \
        num_matches \
        num_elems \
        n
#
#-----------------------------------------------------------------------
#
# Set local variables to appropriate input arguments.
#
#-----------------------------------------------------------------------
#
  array_name="$1"
  str_to_match="$2"

  inds_to_return="all"
  if [ "$#" -eq 3 ]; then
    inds_to_return="$3"
  fi

  array_name_at="$array_name[@]"
  array=("${!array_name_at}")
#
#-----------------------------------------------------------------------
#
# Change all letters in inds_to_return to lower case.  Then check whe-
# ther it has a valid value.
#
#-----------------------------------------------------------------------
#
  inds_to_return="${inds_to_return,,}"
  valid_vals_inds_to_return=( "first" "last" "all" )
  check_var_valid_value "inds_to_return" "valid_vals_inds_to_return"
#
#-----------------------------------------------------------------------
#
# Initialize the array match_inds to an empty array.  This will contain
# the indices of any matched elements.  Then loop through the elements 
# of the given array and check whether each element is equal to str_to_-
# match.  If so, save the index of that element as an element of match_-
# inds.  If inds_to_return is set to "first", we break out of the loop
# after finding the first match in order to not waste computation.
#
#-----------------------------------------------------------------------
#
  match_inds=()
  num_matches=0

  num_elems=${#array[@]}
  for (( n=0; n<${num_elems}; n++ )); do
    if [ "${array[$n]}" = "${str_to_match}" ]; then
      match_inds[${num_matches}]=$n
      num_matches=$((num_matches+1))
      if [ "${inds_to_return}" = "first" ]; then
        break
      fi
    fi
  done
#
#-----------------------------------------------------------------------
#
# Find the number of matches.  If it is more than zero, print the indi-
# ces of the matched elements to stdout.
#
#-----------------------------------------------------------------------
#
  num_matches=${#match_inds[@]}
  if [ ${num_matches} -gt 0 ]; then
    if [ "${inds_to_return}" = "last" ]; then
      printf "%s\n" "${match_inds[-1]}"
    else
      printf "%s\n" "${match_inds[@]}"
    fi
  fi
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
