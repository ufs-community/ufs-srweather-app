#!/bin/bash

#
#-----------------------------------------------------------------------
#
# This file defines a function that creates a grid mosaic file from the
# specified grid file. 
#
#-----------------------------------------------------------------------
#
function make_grid_mosaic_file() {
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
  local scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
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
# Specify the set of valid argument names that this script/function can
# accept.  Then process the arguments provided to it (which should con-
# sist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
"grid_dir" \
"grid_fn" \
"mosaic_fn" \
  )
  process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local exec_fn \
        exec_fp \
        grid_fp \
        mosaic_fp \
        mosaic_fp_prefix
#
#-----------------------------------------------------------------------
#
# Set the name and path to the executable that creates a grid mosaic file
# and make sure that it exists.
#
#-----------------------------------------------------------------------
#
  exec_fn="make_solo_mosaic"
  exec_fp="$EXECDIR/${exec_fn}"
  if [ ! -f "${exec_fp}" ]; then
    print_err_msg_exit "\
The executable (exec_fp) for generating the grid mosaic file does not 
exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
  fi
#
#-----------------------------------------------------------------------
#
# Create the grid mosaic file for the grid with a NH4-cell-wide halo.
#
#-----------------------------------------------------------------------
#
  grid_fp="${grid_dir}/${grid_fn}"
  mosaic_fp="${grid_dir}/${mosaic_fn}"
  mosaic_fp_prefix="${mosaic_fp%.*}"
#
# Call the make_solo_mosaic executable/code to generate a mosaic file.
# Note the following about this code: 
#
# 1) The code attempts to open the grid file specified by the argument 
#    of --tile_file in the directory specified by the argument of --dir.  
#    If it cannot find this file, it will fail.
#
#    Note that:
#
#    a) The argument of --grid may or may not contain a "/" at the end.  
#       The code will add a "/" if necessary when appending the argument
#       of --tile_file to that of --grid to form the full path to the 
#       grid file.
#
#    b) The code creates a string variable named "gridlocation" in the
#       mosaic file that contains the argument of --dir followed if 
#       necessary by a "/".
#
#    c) The code creates a string array variable named "gridfiles" in the
#       mosaic file that has only a single element (for the case of a 
#       global or nested grid, it would contain more elements).  This
#       element contains the argument of --grid, i.e. the name of the 
#       grid file.
#
# 2) The argument of --mosaic must be the absolute or relative path to
#    the netcdf mosaic file that is to be created but without the ".nc"
#    file extension.  For example, if we want the mosaic file to be in
#    the directory /abc/def and be called ghi.nc, then we would specify
#
#      --mosaic "/abc/def/ghi"
#
#    Note that:
#
#    a) All parts of the specified path except the last one (i.e. the
#       substring after the last "/", which is the name of the mosaic
#       file without the ".nc" extension) must exist.  If they don't,
#       the code will fail.
#
#    b) If the argument of --mosaic is a relative path, then the code
#       assumes that this path is relative to the current working directory, 
#       i.e. the directory from which the make_solo_mosaic executable is 
#       called.
#
#    c) If the argument of --mosaic ends with a "/", then it is the path
#       to a directory, not to a file.  In this case, a mosaic file named
#       ".nc" will be created in this absolute or relative  directory.  
#       For example, if the argument of --mosaic is "/abc/def/", then a
#       file named ".nc" will be created in the directory /abc/def
#       (assuming the directory /abc/def exists).  This is generally not
#       what we want, so the argument to --mosaic should not end with a
#       "/"
#
# 3) The code creates a string variable named "mosaic" in the mosaic file.
#    This gets set exactly to the argument of --mosaic without any 
#    modifications.  Thus, if this argument is a relative path, "mosaic"
#    will be set to that relative path without the current working directory
#    prepended to it.  Similarly, "mosaic" will normally not contain at
#    its end the ".nc" extension of the mosaic file (unless the argument
#    to --mosaic itself contains that extension, e.g. if the argument is
#    "/abc/def/ghi.nc", but in that case the mosaic file will be in the
#    directory /abc/def and named ghi.nc.nc -- note the double ".nc" 
#    extensions).
#
    $APRUN "${exec_fp}" \
      --num_tiles 1 \
      --dir "${grid_dir}" \
      --tile_file "${grid_fn}" \
      --mosaic "${mosaic_fp_prefix}" || \
    print_err_msg_exit "\
Call to executable (exec_fp) that generates a grid mosaic file for a 
regional grid returned with nonzero exit code:
  exec_fp = \"${exec_fp}\"" 
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the start of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

