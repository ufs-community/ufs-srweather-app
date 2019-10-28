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
# Get the name of this function as well as information about the calling
# script or function.
#
#-----------------------------------------------------------------------
#
  local crnt_func="${FUNCNAME[0]}"
# Note:
# Below, the index into BASH_SOURCE and FUNCNAME is 2 (not 1 as is usu-
# ally the case) because this function is called by functions such as
# cp_vrfy, mv_vrfy, rm_vrfy, ln_vrfy, mkdir_vrfy, and cd_vrfy, but these
# are just wrappers, and in the error and informational messages we are
# really interested in the scripts/functions that call these wrappers. 
  local caller_path=$( readlink -f "${BASH_SOURCE[2]}" )
  local caller_filename=$( basename "${caller_path}" )
  local caller_dir=$( dirname "${caller_path}" )
  local caller_name="${FUNCNAME[2]}"
#
#-----------------------------------------------------------------------
#
# Check that at least one argument is supplied.
#
#-----------------------------------------------------------------------
#
  if [ "$#" -lt 2 ]; then

    print_err_msg_exit "
At least two arguments must be specified:

  script/function name = \"${crnt_func}\"
  number of arguments specified = $#

Usage:

  ${crnt_func}  cmd  args_to_cmd

where \"cmd\" is the command to execute and \"args_to_cmd\" are the options
and arguments to pass to that command.
"

  fi
#
#-----------------------------------------------------------------------
#
# The first argument to this function is the command to execute while
# the remaining ones are the arguments to that command.  Extract the
# command and save it in the variable "cmd".  Then shift the argument
# list so that $@ contains the arguments to the command but not the com-
# mand itself.
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
  if [ $exit_code -ne 0 ]; then
    print_err_msg_exit "\
Call to function \"${cmd}_vrfy\" failed.  This function was called:
  From script/function:  \"${caller_name}\"  (This gets set to \"source\" for a script, or to \"main\" for the top-level script.)
  In file:  \"${caller_path}\" 
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
issued:
  From script/function:  \"${caller_name}\"  (This gets set to \"source\" for a script, or to \"main\" for the top-level script.)
  In file:  \"${caller_path}\" 
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

