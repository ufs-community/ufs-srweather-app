#
#-----------------------------------------------------------------------
#
# This is a generic function that executes the specified command (e.g. 
# "cp", "mv", etc) with the specified options/arguments and then veri-
# fies that the command executed without errors.  The first argument to
# this function is the command to execute while the remaining ones are 
# the options/arguments to be passed to that command.
#
#-----------------------------------------------------------------------
#
function filesys_cmd_vrfy() {
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
# Get information about the script or function that calls this function.
# Note that caller_name will be set as follows:
#
# 1) If the caller is a function, caller_name will be set to the name of 
#    that function.
# 2) If the caller is a sourced script, caller_name will be set to 
#    "script".  Note that a sourced script cannot be the top level 
#    script since by defintion, it is sourced by another script or func-
#    tion.
# 3) If the caller is the top-level script, caller_name will be set to
#    "main".
#
# Thus, if caller_name is set to "script" or "main", the caller is a 
# script, and if it is set to anything else, the caller is a function.
#
# Below, the index into FUNCNAME and BASH_SOURCE is 2 (not 1 as is usu-
# ally the case) because this function is called by functions such as
# cp_vrfy, mv_vrfy, rm_vrfy, ln_vrfy, mkdir_vrfy, and cd_vrfy, but these
# are just wrappers, and in the error and informational messages, we are
# really interested in the scripts/functions that in turn call these 
# wrappers. 
#
#-----------------------------------------------------------------------
#
  local caller_fp=$( readlink -f "${BASH_SOURCE[2]}" )
  local caller_fn=$( basename "${caller_fp}" )
  local caller_dir=$( dirname "${caller_fp}" )
  local caller_name="${FUNCNAME[2]}"
#
#-----------------------------------------------------------------------
#
# Check that at least one argument is supplied.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -lt 1 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name:  \"${func_name}\"
  Number of arguments specified:  $#

Usage:

  ${func_name}  cmd  [args_to_cmd]

where \"cmd\" is the name of the command to execute and \"args_to_cmd\"
are zero or more options and arguments to pass to that command.
"

  fi
#
#-----------------------------------------------------------------------
#
# The first argument to this function is the command to execute while
# the remaining ones are the arguments to that command.  Extract the
# command and save it in the variable "cmd".  Then shift the argument
# list so that $@ contains the arguments to the command but not the 
# name of the command itself.
#
#-----------------------------------------------------------------------
#
  local cmd="$1"
  shift
#
#-----------------------------------------------------------------------
#
# Pass the arguments to the command and execute it, saving the outputs
# to stdout and stderr in the variable "output".  Also, save the exit
# code from the execution.
#
#-----------------------------------------------------------------------
#
  output=$( "$cmd" "$@" 2>&1 )
  exit_code=$?
#
#-----------------------------------------------------------------------
#
# If output is not empty, it will be printed to stdout below either as
# an error message or an informational message.  In either case, format
# it by adding a double space to the beginning of each line.
#
#-----------------------------------------------------------------------
#
  if [ -n "$output" ]; then
    double_space="  "
    output="${double_space}${output}"
    output=${output/$'\n'/$'\n'${double_space}}
  fi
#
#-----------------------------------------------------------------------
#
# If the exit code from the execution of cmd above is nonzero, print out
# an error message and exit.
#
#-----------------------------------------------------------------------
#
  if [ "${caller_name}" = "main" ] || \
     [ "${caller_name}" = "script" ]; then
    script_or_function="the script"
  else
    script_or_function="function \"${caller_name}\""
  fi

  if [ ${exit_code} -ne 0 ]; then

    print_err_msg_exit "\
Call to function \"${cmd}_vrfy\" failed.  This function was called from
${script_or_function} in file:

  \"${caller_fp}\"

Error message from \"${cmd}_vrfy\" function's \"$cmd\" operation:
$output"

  fi
#
#-----------------------------------------------------------------------
#
# If the exit code from the execution of cmd above is zero, continue.
#
# First, check if cmd is set to "cd".  If so, the execution of cmd above
# in a separate subshell [which is what happens when using the $("$cmd")
# construct above] will change directory in that subshell but not in the
# current shell.  Thus, rerun the "cd" command in the current shell.
#
#-----------------------------------------------------------------------
#
  if [ "$cmd" = "cd" ]; then
    "$cmd" "$@" 2>&1 > /dev/null
  fi
#
#-----------------------------------------------------------------------
#
# If output is not empty, print out whatever message it contains (e.g. 
# it might contain a warning or other informational message).
#
#-----------------------------------------------------------------------
#
  if [ -n "$output" ]; then

    print_info_msg "
\"${cmd}_vrfy\" operation returned with a message.  This command was 
issued from ${script_or_function} in file:

  \"${caller_fp}\"

Message from \"${cmd}_vrfy\" function's \"$cmd\" operation:
$output"

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


#
#-----------------------------------------------------------------------
#
# The following are functions are counterparts of common filesystem com-
# mands "with verification", i.e. they execute a filesystem command
# (such as "cp" and "mv") and then verify that the execution was suc-
# cessful.
#
# These functions are called using the "filesys_cmd_vrfy" function de-
# fined above.  In each of these functions, we:
#
# 1) Save current shell options (in a global array) and then set new op-
#    tions for this script/function.
# 2) Call the generic function "filesys_cmd_vrfy" with the command of
#    interest (e.g. "cp") as the first argument and the arguments passed
#    in as the rest.
# 3) Restore the shell options saved at the beginning of the function.
#
#-----------------------------------------------------------------------
#

function cp_vrfy() {
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
  filesys_cmd_vrfy "cp" "$@"
  { restore_shell_opts; } > /dev/null 2>&1
}

function mv_vrfy() {
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
  filesys_cmd_vrfy "mv" "$@"
  { restore_shell_opts; } > /dev/null 2>&1
}

function rm_vrfy() {
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
  filesys_cmd_vrfy "rm" "$@"
  { restore_shell_opts; } > /dev/null 2>&1
}

function ln_vrfy() {
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
  filesys_cmd_vrfy "ln" "$@"
  { restore_shell_opts; } > /dev/null 2>&1
}

function mkdir_vrfy() {
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
  filesys_cmd_vrfy "mkdir" "$@"
  { restore_shell_opts; } > /dev/null 2>&1
}

function cd_vrfy() {
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
  filesys_cmd_vrfy "cd" "$@"
  { restore_shell_opts; } > /dev/null 2>&1
}

