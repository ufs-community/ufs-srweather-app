

function source_yaml () {

  local func_name="${FUNCNAME[0]}"

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
  local section
  yaml_file=$1
  section=$2

  while read -r line ; do


    # A regex to match list representations
    line=$(echo "$line" | sed -E "s/='\[(.*)\]'/=(\1)/")
    line=${line//,/}
    line=${line//\"/}
    line=${line/None/}
    source <( echo "${line}" )
  done < <(uw config realize -i "${yaml_file}" --output-format sh --key-path $section)
}
