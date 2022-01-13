#
#-----------------------------------------------------------------------
#
# This file defines a function that returns the contents of a bash script/
# function with all empty lines, comment lines, and leading and trailing 
# whitespace removed.  Arguments are as follows:
#
# fp:
# The relative or full path to the file containing the bash script or 
# function.
#
# output_varname_contents:
# Name of the output variable that will contain the (processed) contents 
# of the file.  This is the output of the function.
# 
#-----------------------------------------------------------------------
#
function get_bash_file_contents() { 

  { save_shell_opts; set -u +x; } > /dev/null 2>&1

  local valid_args=( \
    "fp" \
    "output_varname_contents" \
    )
  process_args valid_args "$@"
  print_input_args "valid_args"
  #
  # Verify that the required arguments to this function have been specified.
  # If not, print out an error message and exit.
  #
  if [ -z "$fp" ]; then
    print_err_msg_exit "\
The argument \"fp\" specifying the relative or full path to the file to
read was not specified in the call to this function:
  fp = \"$fp\""
  fi

  local contents \
        crnt_line
  #
  # Read in all lines in the file.  In doing so:
  #
  # 1) Concatenate any line ending with the bash line continuation character
  #    (a backslash) with the following line.
  # 2) Remove any leading and trailing whitespace.
  #
  # Note that these two actions are automatically performed by the "read"
  # utility in the while-loop below.
  #
  contents=""
  while read crnt_line; do
    contents="${contents}${crnt_line}
"
  done < "$fp"
  #
  # Strip out any comment and empty lines from contents.
  #
  contents=$( printf "${contents}" | \
              $SED -r -e "/^#.*/d"  `# Remove comment lines.` \
                      -e "/^$/d"    `# Remove empty lines.` \
            )
  #
  # Set output variables.
  #
  printf -v ${output_varname_contents} "${contents}"

  { restore_shell_opts; } > /dev/null 2>&1

}

