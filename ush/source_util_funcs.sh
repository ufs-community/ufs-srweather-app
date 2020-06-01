function source_util_funcs() {
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
# Set the directory in which the files defining the various utility 
# functions are located.
#
#-----------------------------------------------------------------------
#
  local bashutils_dir="${scrfunc_dir}/bash_utils"
#
#-----------------------------------------------------------------------
#
# Source the file containing functions to save and restore shell op-
# tions.
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/save_restore_shell_opts.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the functions that print out messages.
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/print_msg.sh
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/set_bash_param.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that replaces variable values
# (or value placeholders) in several types of files (e.g. Fortran name-
# list files) with actual values.
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/set_file_param.sh
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/count_files.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that checks for preexisting 
# directories or files and handles them according to a specified method
# (which can be one of "delete", "rename", and "quit").
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/check_for_preexist_dir_file.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing functions that execute filesystem commands
# (e.g. "cp", "mv") with verification (i.e. verifying that the commands
# completed successfully).
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/filesys_cmds_vrfy.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that searches an array for a
# specified string.
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/is_element_of.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that gets the indices of those
# elements of an array that match a given string.
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/get_elem_inds.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that determines whether or not
# a specified variable is an array.
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/is_array.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that interpolates (or extrapo-
# lates) a grid cell size-dependent property to an arbitrary global 
# cubed-sphere resolution.
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/interpol_to_arbit_CRES.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that checks the validity of a
# variable's value (given a set of valid values).
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/check_var_valid_value.sh
#
#-----------------------------------------------------------------------
#
# 
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/print_input_args.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that processes a list of argu-
# ments to a script or function, where the list is comprised of a set of
# argument name-value pairs, e.g. arg1="value1", ...
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/process_args.sh
#
#-----------------------------------------------------------------------
#
# 
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/get_manage_externals_config_property.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that returns to stdout the 
# contents of a character (i.e. string) variable in a netcdf file.
#
#-----------------------------------------------------------------------
#
  . ${bashutils_dir}/get_charvar_from_netcdf.sh

}
source_util_funcs


