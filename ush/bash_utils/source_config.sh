#
#-----------------------------------------------------------------------
# This file defines function that sources a config file (yaml/json etc)
# into the calling shell script
#-----------------------------------------------------------------------
#

function config_to_str() {
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; . ${USHdir}/preamble.sh; } > /dev/null 2>&1

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
# Get the contents of a config file as shell string
#-----------------------------------------------------------------------
#
  local ushdir=${scrfunc_dir%/*}

  $ushdir/config_utils.py -o $1 -c $2 "${@:3}"

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
# Define functions for different file formats
#-----------------------------------------------------------------------
#
function config_to_shell_str() {
    config_to_str shell "$@"
}
function config_to_ini_str() {
    config_to_str ini "$@"
}
function config_to_yaml_str() {
    config_to_str yaml "$@"
}
function config_to_json_str() {
    config_to_str json "$@"
}
function config_to_xml_str() {
    config_to_str xml "$@"
}

#
#-----------------------------------------------------------------------
# Source contents of a config file to shell script
#-----------------------------------------------------------------------
#
function source_config() {

  source <( config_to_shell_str "$@" )

}
#
#-----------------------------------------------------------------------
# Source partial contents of a config file to shell script.
#   Only those variables needed by the task are sourced
#-----------------------------------------------------------------------
#
function source_config_for_task() {

  source <( config_to_shell_str "${@:2}" -k "(^(?!task_)|$1).*" )

}
