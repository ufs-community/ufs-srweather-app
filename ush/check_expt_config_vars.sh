#
#-----------------------------------------------------------------------
#
# This file defines a function that checks that all experiment variables 
# set in the user-specified experiment configuration file are defined (by 
# being assigned default values) in the default experiment configuration 
# file.  If a variable is found in the former that is not defined in the 
# latter, this function exits with an error message.  
#
# This check is performed in order to prevent the user from defining 
# arbitrary variables in the user-specified configuration file; the 
# latter should be used to specify only varaibles that have already been 
# defined in the default configuration file.  
#
# Arguments are as follows:
#
# default_config_fp:
# The relative or full path to the default experiment configuration file.
#
# config_fp:
# The relative or full path to the user-specified experiment configuration 
# file.
#
#-----------------------------------------------------------------------
#
function check_expt_config_vars() {

  . ${scrfunc_dir}/source_util_funcs.sh

  { save_shell_opts; set -u +x; } > /dev/null 2>&1

  local valid_args=( \
    "default_config_fp" \
    "config_fp" \
    )
  process_args valid_args "$@"
  print_input_args "valid_args"

  local var_list_default \
        var_list_user \
        crnt_line \
        var_name \
        regex_search
  #
  # Get the list of variable definitions, first from the default experiment
  # configuration file and then from the user-specified experiment
  # configuration file.
  #
  get_bash_file_contents fp="${default_config_fp}" \
                         output_varname_contents="var_list_default"

  get_bash_file_contents fp="${config_fp}" \
                         output_varname_contents="var_list_user"
  #
  # Loop through each line/variable in var_list_user.  For each line,
  # extract the the name of the variable that is being set (say VAR) and
  # check that this variable is set somewhere in the default configuration
  # file by verifying that a line that starts with "VAR=" exists in
  # var_list_default.
  #
  while read crnt_line; do
    #
    # Note that a variable name will be found only if the equal sign immediately
    # follows the variable name.
    #
    var_name=$( printf "%s" "${crnt_line}" | $SED -n -r -e "s/^([^ =\"]*)=.*/\1/p")

    if [ -z "${var_name}" ]; then

      print_info_msg "
The current line (crnt_line) of the user-specified experiment configuration
file (config_fp) does not contain a variable name (i.e. var_name is empty):
  config_fp = \"${config_fp}\"
  crnt_line = \"${crnt_line}\"
  var_name = \"${var_name}\"
Skipping to next line."

    else
      #
      # Use grep to search for the variable name (followed by an equal sign, 
      # all at the beginning of a line) in the list of variables in the default
      # configuration file.  
      #
      # Note that we use a herestring to input into grep the list of variables 
      # in the default configuration file.  grep will return with a zero status 
      # if the specified string (regex_search) is not found in the default 
      # variables list and a nonzero status otherwise.  Note also that we 
      # redirect the output of grep to null because we are only interested in 
      # its exit status.
      #
      regex_search="^${var_name}="
      grep "${regex_search}" <<< "${var_list_default}" > /dev/null 2>&1 || \
      print_err_msg_exit "\
The variable (var_name) defined on the current line (crnt_line) of the 
user-specified experiment configuration file (config_fp) does not appear 
in the default experiment configuration file (default_config_fp):
  config_fp = \"${config_fp}\"
  default_config_fp = \"${default_config_fp}\"
  crnt_line = \"${crnt_line}\"
  var_name = \"${var_name}\"
Please assign a default value to this variable in the default configuration
file and rerun."

    fi

  done <<< "${var_list_user}"

  { restore_shell_opts; } > /dev/null 2>&1

}
