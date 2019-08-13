#
#-----------------------------------------------------------------------
#
# This function processes a list of variable name and value pairs passed
# to it as a set of arguments (starting with the second argument).  Each
# name-value pair must have the form
#
#   VAR_NAME=VAR_VALUE
#
# where VAR_NAME is the name of a variable and VAR_VALUE is the value it
# should have.  For each name-value pair, this function creates a varia-
# ble of the specified name and assigns to it its corresponding value.
#
# The first argument to this function (valid_var_names) is the name of 
# an array defined in the calling script that contains a list of valid 
# variable values.  The variable name specified in each name-value pair
# must correspond to one of the elements of this array.  If it isn't, 
# this function prints out an error message and exits with a nonzero 
# exit code.  Any variable in the list of valid variable names that is 
# not assigned a value in a name-value pair gets set to the null string.
#
# This function may be called from a script as follows:
#
#   valid_args=( "arg1" "arg2" "arg3" "arg4" )
#   process_args valid_args \
#                arg1="hello" \
#                arg3="goodbye"
#
# After the call to process_args in this script, there will exist four
# new (or reset) variables: arg1, arg2, arg3, and arg4.  arg1 will be 
# set to the string "hello", arg3 will be set to the string "goodby", 
# and arg2 and arg4 will be set to the null string, i.e. "".
#
# The purpose of this function is to allow a script to process a set of
# arguments passed to it as variable name-and-value pairs by another 
# script (aka the calling script) such that:
#
# 1) The calling script can only pass one of a restricted set of varia-
#    bles to the child script.  This set is specified within the child
#    script and is known as the
#
# 2) The calling script can specify a subset of the allowed variables in
#    the child script.  Variables that are not specified are set to the
#    null string.
# 
# 1) The "export" feature doesn't have to be used
#.  For exam-
# ple, assume the script outer_script.sh calls a second script named in-
# ner_script.sh as follows:
#
#   inner_script.sh \
#     arg1="hi there" \
#     arg2="all done"
#
# To process the arguments arg1 and arg2 passed to it, inner_script.sh
# may contain the following code:
#
#   valid_args=( "arg1" "arg2" "arg3" "arg4" )
#   process_args valid_args "$@"
#
# The call to process_args here would cause arg1 and arg2 to be created
# and set to "hi_there" and "all done", respectively, and for arg3 and 
# arg4 to be created and set to "".  Note that arg1 through arg4 would
# not be defined in the environment of outer_script.sh; they would only
# be defined in the environment of inner_script.sh.
#
# Note that variables may also be set to arrays.  For example, the call
# in outer_script.sh to inner_script.sh may be modified to
#
#   inner_script.sh \
#     arg1="hi there" \
#     arg2="all done"
#     arg4='( "dog" "cat" )'
#
# This would cause the scalar variables arg1 and arg2 to be created in
# the environment of inner_script.sh and set to "hi there" and "all 
# done", respectively, for arg3 to be created and set to "", and for 
# arg4 to be created (as an array) and set to the array ( "dog" "cat" ).
#   

#   process_args valid_args "$@"
# The variable may be set to a scalar or
# array value.  
# creating a variable of the same name as the one specified in each 
# name-value pair and assigning to it the value specified in that pair.
# The variable in each name-value pair can be a scalar or an array.
#
#-----------------------------------------------------------------------
#
function process_args() {
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
# Check arguments.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -lt 1 ]; then

    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]}  valid_var_names_array  var_name_val_pair1 ... var_name_val_pairN

where the arguments are defined as follows:

  valid_var_names_arrray:
  The name of the array containing a list of valid variable names.

  var_name_val_pair1 ... var_name_val_pairN:
  A list of N variable name-value pairs.  These have the form
    var_name1=\"var_val1\" ... var_nameN=\"var_valN\"
  where each variable name (var_nameI) needs to be in the list of valid
  variable names specified in valid_var_names_array.  Note that not all
  the valid variables listed in valid_var_names_array need to be set, 
  and the name-value pairs can be in any order (i.e. they don't have to
  follow the order of variables listed in valid_var_names_array).\n"

  fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  local valid_var_names_at \
        valid_var_names \
        valid_var_names_str \
        num_valid_var_names \
        num_name_val_pairs \
        i valid_var_name name_val_pair var_name var_value is_array

  valid_var_names_at="$1[@]"
  valid_var_names=("${!valid_var_names_at}")
  valid_var_names_str=$(printf "\"%s\" " "${valid_var_names[@]}");
  num_valid_var_names=${#valid_var_names[@]}
#
#-----------------------------------------------------------------------
#
# Get the number of name-value pairs specified as inputs to this func-
# tion.  These consist of the all arguments starting with the 2nd, so
# we subtract 1 from the total number of arguments.
#
#-----------------------------------------------------------------------
#
  num_name_val_pairs=$(( $#-1 ))
#
#-----------------------------------------------------------------------
#
# Make sure that the number of name-value pairs is less than or equal to
# the number of valid variable names.
#
#-----------------------------------------------------------------------
#
  if [ "${num_name_val_pairs}" -gt "${num_valid_var_names}" ]; then
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":
The number of variable name-value pairs specified on the command line
must be less than or equal to the number of valid variable names speci-
fied in the array valid_var_names:
  num_name_val_pairs = \"$num_name_val_pairs\"
  num_valid_var_names = \"$num_valid_var_names\"
"

  fi
#
#-----------------------------------------------------------------------
#
# Initialize all valid variables to the null string.
#
#-----------------------------------------------------------------------
#
  for (( i=0; i<$num_valid_var_names; i++ )); do
    valid_var_name="${valid_var_names[$i]}"
    eval ${valid_var_name}=""
    valid_var_specified[$i]="false"
  done
#
#-----------------------------------------------------------------------
#
# Loop over the list of variable name-value pairs and set variable val-
# ues.
#
#-----------------------------------------------------------------------
#
  for name_val_pair in "${@:2}"; do

    var_name=$(echo ${name_val_pair} | cut -f1 -d=)
    var_value=$(echo ${name_val_pair} | cut -f2 -d=)

    is_array="false"
    if [ "${var_value:0:1}" = "(" ] && \
       [ "${var_value: -1}" = ")" ]; then
      is_array="true"
    fi 
#
#-----------------------------------------------------------------------
#
# Make sure that the specified variable name is valid.
#
#-----------------------------------------------------------------------
#
    iselementof "${var_name}" valid_var_names || { \
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":
The specified variable name in the current variable name-and-value pair
is not valid:
  name_val_pair = \"${name_val_pair}\"
  var_name = \"${var_name}\"
var_name must be set to one of the following:
  $valid_var_names_str
"; }
#
#-----------------------------------------------------------------------
#
# Loop through the list of valid variable names and find the one that 
# the current name-value pair corresponds to.  Then set that variable to
# the specified value.
#
#-----------------------------------------------------------------------
#
    for (( i=0; i<${num_valid_var_names}; i++ )); do

      valid_var_name="${valid_var_names[$i]}"
      if [ "${var_name}" = "${valid_var_name}" ]; then

        if [ "${valid_var_specified[$i]}" = "false" ]; then
          valid_var_specified[$i]="true"
          if [ "${is_array}" = "true" ]; then
            eval ${var_name}=${var_value}
          else
            eval ${var_name}=\"${var_value}\"
          fi
        else
          cmd_line=$( printf "\'%s\' " "${@:1}" )
          print_err_msg_exit "\
The current variable has already been assigned a value on the command
line:
  var_name = \"${var_name}\"
  cmd_line = ${cmd_line}
Please assign values to variables only once on the command line.
"
        fi
      fi

    done

  done
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

