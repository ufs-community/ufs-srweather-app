#
#-----------------------------------------------------------------------
# This file defines function that sources a config file (yaml/json etc)
# into the calling shell script
#-----------------------------------------------------------------------
#

function config_to_str() {
  ${PARMsrw}/config_utils.py -o $1 -c $2 "${@:3}"
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
  var_defn_file=$2
  var=$1

  value=$( ${PARMsrw}/read_var_yaml.py -i $var -f $var_defn_file )

  eval "$var=$value"

}
