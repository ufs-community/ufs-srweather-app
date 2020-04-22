#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
#. $USHDIR/source_util_funcs.sh

#
#-----------------------------------------------------------------------
#
# For a description of this function, see the usage message below.
#
#-----------------------------------------------------------------------
#
function get_charvar_from_netcdf() {
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
  num_required_args=2
  if [ "$#" -ne "${num_required_args}" ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments required:   ${num_required_args}
  Number of arguments specified:  $#

Usage:

  ${func_name}  nc_file  nc_var_name

This function searches a specified NetCDF file and extracts from it the
value of the specified scalar variable.

The arguments to this function are defined as follows:

  nc_file:
  The name of the NetCDF file.  This can be just the file name, a relative
  path, or an absolute path.

  nc_var_name:
  The name of the variable in the NetCDF file whose value will be extracted.

"

  fi
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local nc_file \
        nc_var_name \
        nc_var_value
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
  nc_file="$1"
  nc_var_name="$2"
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
  nc_var_value=$( ncdump -v "${nc_var_name}" "${nc_file}" | \
                  sed -r -e '1,/data:/d' \
                         -e '/^[ ]*'${nc_var_name}'/d' \
                         -e '/^}$/d' \
                         -e 's/.*"(.*)".*/\1/' \
                         -e '/^$/d' \
                ) || print_err_msg_exit "\
Attempt to extract the value of the NetCDF variable spcecified by nc_var_name
from the file specified by nc_file failed:
  nc_file = \"${nc_file}\"
  nc_var_name = \"${nc_var_name}\""
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
  if [ -z "${nc_var_value}" ]; then

    print_err_msg_exit "\
In the specified NetCDF file (nc_file), the specified variable (nc_var_name)
was not found:
  nc_file = \"${nc_file}\"
  nc_var_name = \"${nc_var_name}\"
  nc_var_value = \"${nc_var_value}\""
#
#-----------------------------------------------------------------------
#
# If nc_var_value is not empty, it means the sed command above was able to find
# a line in the configuration file that defines the specified property
# for the specified external.  In this case, extract the property value
# from nc_var_value and print it to stdout.
#
#-----------------------------------------------------------------------
#
  else

    printf "%s\n" "${nc_var_value}"

  fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the start of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}
