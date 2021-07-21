#
#-----------------------------------------------------------------------
#
# This file defines a function that detects if a python or miniconds3
# module is loaded, and if so, unloads that module.  This may be
# necessary on machines where the loaded python environment isn't
# compatible with environment set for the compiler.
#
#-----------------------------------------------------------------------
#
function unload_python() {
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
  if [ "$#" -ne 0 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}

"

  fi
#
#-----------------------------------------------------------------------
#
# If the miniconda or python modules are loaded, unload them
#
#-----------------------------------------------------------------------
#

  modules_to_unload=( python miniconda3 )
  loaded_modules=$(module list 2>&1)

  for module_to_unload in ${modules_to_unload[@]}; do
    if [[ "${loaded_modules}" =~ "${module_to_unload}" ]]; then
  print_info_msg "\
Unloading module ${module_to_unload} libraries needed for workflow generation but not for running the workflow... "
      module unload ${module_to_unload}
    fi
  done

  loaded_modules=$(module list 2>&1)
  print_info_msg "\
Loaded modules are: $loaded_modules "

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

