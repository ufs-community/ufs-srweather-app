#
#-----------------------------------------------------------------------
#
# This function returns the number of files in the current directory 
# that end with the specified extension (file_extension).
#
#-----------------------------------------------------------------------
#
function count_files() {
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
  if [ "$#" -ne 1 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  file_extension

where file_extension is the file extension to use for counting files.  
The file count returned will be equal to the number of files in the cur-
rent directory that end with \".${file_extension}\".
"

  fi
#
#-----------------------------------------------------------------------
#
# Count the number of files and then print it to stdout.
#
#-----------------------------------------------------------------------
#
  local file_extension="$1"
  local glob_pattern="*.${file_extension}"
  local num_files=$( ls -1 ${glob_pattern} 2>/dev/null | wc -l )
  print_info_msg "${num_files}"
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

