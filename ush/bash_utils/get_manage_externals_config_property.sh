#
#-----------------------------------------------------------------------
#
# For a description of this function, see the usage message below.
# 
#-----------------------------------------------------------------------
#
function get_manage_externals_config_property() { 
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

  ${func_name}  externals_cfg_fp  external_name  property_name

This function searches a specified manage_externals configuration file
and extracts from it the value of the specified property of the external
with the specified name (e.g. the relative path in which the external
has been/will be cloned by the manage_externals utility).

The arguments to this function are defined as follows:

  externals_cfg_fp:
  The absolute or relative path to the manage_externals configuration
  file that will be searched.

  external_name:
  The name of the external to search for in the manage_externals confi-
  guration file specified by externals_cfg_fp.

  property_name:
  The name of the property whose value to obtain (for the external spe-
  cified by external_name).
"

  fi
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local externals_cfg_fp \
        external_name \
        property_name \
        regex_search \
        line \
        property_value
#
#-----------------------------------------------------------------------
#
# Set the name of the manage_externals configuration file [which may be
# the absolute path to the file or a relative path (relative to the cur-
# rent working directory)], the name of the external in that file whose
# property value we want to extract, and the name of the property under
# that external.
#
#-----------------------------------------------------------------------
#
  externals_cfg_fp="$1"
  external_name="$2"
  property_name="$3"
#
#-----------------------------------------------------------------------
#
# Check that the specified manage_externals configuration file exists.
# If not, print out an error message and exit.
#
#-----------------------------------------------------------------------
#
  if [ ! -f "${externals_cfg_fp}" ]; then
    print_err_msg_exit "\
The specified manage_externals configuration file (externals_cfg_fp) 
does not exist:
  externals_cfg_fp = \"${externals_cfg_fp}\""
  fi
#
#-----------------------------------------------------------------------
#
# Use "sed" to extract the line in the configuration file containing the
# value of the specified property for the specified external (if such a
# line exists).  To explain how the "sed" command below does this, we
# first number the lines in that command, as follows:
#
# (1)  line=$( sed -r -n \
# (2)              -e "/^[ ]*\[${external_name}\]/!b" \
# (3)              -e ":SearchForLine" \
# (4)              -e "s/(${regex_search})/\1/;t FoundLine" \
# (5)              -e "n;bSearchForLine" \
# (6)              -e ":FoundLine" \
# (7)              -e "p;q" \
# (8)              "${externals_cfg_fp}" \
# (9)        )
#
# This command works as follows.  First, on line (1), the -r flag speci-
# fies that extended regular expressions should be allowed, and the -n
# flag suppresses the printing of each line in the file that sed pro-
# cesses.
#
# Line (2) checks for all lines in the file [which is specified on line 
# (8)] that do NOT start with zero or more spaces followed by the exter-
# nal name in square brackets.  (The ! before the "b" causes the nega-
# tion.)  For each such line, the "b" causes the rest of the sed com-
# mands [specified by the arguments to the "-e" flags on lines (3) 
# through (7)] to be skipped and for sed to read in the next line in the
# file.  Note that if no line is found that starts with zero or more 
# spaces followed by the external name in square brackets, sed will 
# reach the end of the file and quit [and lines (3) through (6) will ne-
# ver be executed], and the variable "line" will get assigned to a null
# string.
#
# Lines (3) through (5) form a while-loop.  After finding a line in the
# file that does start with zero or more spaces followed by the external
# name in square brackets, we pass through line (3) (which just defines
# the location of the SearchForLine label; it does not execute any com-
# mands) and execute line (4).  This line checks whether the current 
# line in the file has the form specified by the regular expression in
# regex_search but doesn't change the line (since the whole line is 
# substuted back in via the parentheses around ${regex_search} and the 
# \1).  If not, sed moves on to line (5), which clears the contents of
# the pattern buffer and reads the next line in the file into it (be-
# cause of the "n" command).  Execution then moves back to line 3 (be-
# cause of the "bSearchForLine" command).  If the current line in the
# file does have the form specified by regex_search, line (5) places the
# current line in the file in the pattern buffer (whithout modifying
# it), and execution moves on to line (6) [because a substitution was 
# successfully made on line 4, so the "t FoundLine" command moves the
# execution to line (6)].  Thus, once line (1) finds the start of the 
# section for the specified external, lines (3) through (6) loop until a
# line defining the specified property is found (or the end of the file
# is reached).  If and when this happens, sed execution moves to line
# (6).
#
# Line (6) just defines the location of the FoundLine label, so it 
# doesn't actually execute any commands, and execution moves to line 
# (7).  On this line, the "p" command prints out the contents of the 
# pattern buffer, which is the first line in the file after the start
# of the specified external that defines the property.  Then the "q" 
# command simply quits execution since we have found the line we are 
# looking for.
#
#-----------------------------------------------------------------------
#
  regex_search="^[ ]*(${property_name})[ ]*=[ ]*([^ ]*).*"
  line=$( sed -r -n \
              -e "/^[ ]*\[${external_name}\]/!b" \
              -e ":SearchForLine" \
              -e "s/(${regex_search})/\1/;t FoundLine" \
              -e "n;bSearchForLine" \
              -e ":FoundLine" \
              -e "p;q" \
              "${externals_cfg_fp}" \
        )
#
#-----------------------------------------------------------------------
#
# If the variable "line" is empty, it means the sed command above was 
# not able to find a line in the configuration file that defines the 
# specified property for the specified external.  In this case, print
# out an error messge and exit.
#
#-----------------------------------------------------------------------
#
  if [ -z "${line}" ]; then

    print_err_msg_exit "\
In the specified manage_externals configuration file (externals_cfg_fp), 
the specified property (property_name) was not found for the the speci-
fied external (external_name): 
  externals_cfg_fp = \"${externals_cfg_fp}\"
  external_name = \"${external_name}\"
  property_name = \"${property_name}\""
#
#-----------------------------------------------------------------------
#
# If line is not empty, it means the sed command above was able to find
# a line in the configuration file that defines the specified property
# for the specified external.  In this case, extract the property value
# from line and print it to stdout.
#
#-----------------------------------------------------------------------
#
  else

    property_value=$( printf "%s" "${line}" | \
                      sed -r -n -e "s/${regex_search}/\2/p" )
    printf "%s\n" "${property_value}"

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
