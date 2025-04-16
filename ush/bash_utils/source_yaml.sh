
function source_yaml () {

  local func_name line section uw_exit_code uw_output yaml_file

  func_name="${FUNCNAME[0]}"

  if [ "$#" -lt 1 ] ; then
    print_err_msg_exit "
Incorrect number of arguments specified:

  Function name: ${func_name}
  Number of args specified: $#

Usage:

  ${func_name} yaml_file [section]

  yaml_file: path to the YAML file to source
  section:   optional subsection of yaml
"
  fi
  yaml_file=$1
  section=$2

  uw_output=$(uw config realize -i "${yaml_file}" --output-format sh --key-path $section)
  uw_exit_code=$?
  if [[ $uw_exit_code -ne 0 ]]; then
    echo "Error: 'uw config' command failed with exit code $uw_exit_code"
    echo "Error occurred while sourcing the section: $section"
    exit $uw_exit_code
  fi

  while read -r line ; do
    # A regex to match list representations
    line=$(echo "$line" | sed -E "s/='\[(.*)\]'/=(\1)/")
    line=${line//,/}
    line=${line//\"/}
    line=${line/None/}
    source <( echo "${line}" )
  done <<< "$uw_output"
}
