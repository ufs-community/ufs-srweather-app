#
#-----------------------------------------------------------------------
# This file defines function that sources a config file (yaml/json etc)
# into the calling shell script
#-----------------------------------------------------------------------
#
tmpfn="bbbbbb.txt"
function config_to_str() {
  echo "cccccccccccccccc" >> ${tmpfn}
  echo "  $1" >> ${tmpfn}
  echo "  $2" >> ${tmpfn}
  echo "  ${@:3}" >> ${tmpfn}
  $USHdir/config_utils.py -o $1 -c $2 "${@:3}"
}

#
#-----------------------------------------------------------------------
# Define functions for different file formats
#-----------------------------------------------------------------------
#
function config_to_shell_str() {
    echo "bbbbbbbbbbbbbbbb" >> ${tmpfn}
    echo "  $@" >> ${tmpfn}
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

  rm ${tmpfn}
  echo "aaaaaaaaaaaaaaa" >> ${tmpfn}
  echo "  $@" >> ${tmpfn}
  source <( config_to_shell_str "${@:2}" -k "(^(?!task_)|$1).*" )

}
