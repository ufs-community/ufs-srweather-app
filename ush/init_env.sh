#
#-----------------------------------------------------------------------
#
# This file defines a function that sources scripts (usually system 
# scripts) to initialize various commands in the environment, e.g. the 
# "module" command.  The full paths to these scripts are specified in 
# the machine files in the array ENV_INIT_SCRIPTS_FPS.
#
# env_init_scripts_fps:
# Full paths to the system scripts to source.
# 
#-----------------------------------------------------------------------
#
function init_env() { 

  { save_shell_opts; set -u +x; } > /dev/null 2>&1

  local valid_args=( \
    "env_init_scripts_fps" \
    )
  process_args valid_args "$@"
  print_input_args "valid_args"

  local num_scripts \
        n \
        fp

  num_scripts="${#env_init_scripts_fps[@]}"
  for (( n=0; n<${num_scripts}; n++ )); do
    fp="${env_init_scripts_fps[$n]}"
    print_info_msg "$DEBUG" "\
Attempting to source script:
  fp = \"$fp\""
    if [ -f "$fp" ]; then
      # The scripts being sourced here may have undefined variables, but since
      # they are system scripts outside of the SRW App, they cannot be changed.
      # Thus, we allow for undefined variables by temporarily using "set +u".
      set +u
      source "$fp" && print_info_msg "$DEBUG" "Succeeded."
      set -u
    else
      print_err_msg_exit "\
The script to source does not exist or is not a regular file:
  fp = \"$fp\""
    fi

  done

  { restore_shell_opts; } > /dev/null 2>&1

}
