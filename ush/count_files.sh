#!/bin/bash

#
#-----------------------------------------------------------------------
#
# This function returns the number of files in the current directory 
# that end with the specified extension (file_extension).
#
#-----------------------------------------------------------------------
#
. ./source_funcs.sh

function count_files() {

  if [ "$#" -ne 1 ]; then
    print_err_msg_exit "\
Function \"${FUNCNAME[0]}\":  Incorrect number of arguments specified.
Usage:

  ${FUNCNAME[0]} file_extension

where file_extension is the file extension to use for counting files.  
The file count returned will be equal to the number of files in the cur-
rent directory that end with \".${file_extension}\"."
  fi

  local file_extension="$1"
  local glob_pattern="*.${file_extension}"
  local num_files=$( ls -1 ${glob_pattern} 2>/dev/null | wc -l )
  print_info_msg "${num_files}"

}


