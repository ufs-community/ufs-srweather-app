#!/bin/bash 

#
#-----------------------------------------------------------------------
#
# This script checks the workflow status of all forecast experiments 
# with directories located under a given base directory (expts_subdir).
# It must be supplied exactly one argument -- the experiments base 
# directory.  It assumes that all subdirectories under this base directory
# are experiment directories and checks each one's workflow status.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Do not allow uninitialized variables.
#
#-----------------------------------------------------------------------
#
set -u
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# The current script should be located in the "tests" subdirectory of the
# workflow's top-level directory, which we denote by homerrfs.  Thus,
# homerrfs is the directory one level above the directory in which the
# current script is located.  Set homerrfs accordingly.
#
#-----------------------------------------------------------------------
#
homerrfs=${scrfunc_dir%/*}
#
#-----------------------------------------------------------------------
#
# Set directories.
#
#-----------------------------------------------------------------------
#
ushdir="$homerrfs/ush"
#
#-----------------------------------------------------------------------
#
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
. $ushdir/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Exactly one argument must be specified that consists of the full path
# to the experiments base directory (i.e. the directory containing the 
# experiment subdirectories).  Ensure that the number of arguments is 
# one.
#
#-----------------------------------------------------------------------
#
num_args="$#"
if [ "${num_args}" -eq 1 ]; then
  expts_basedir="$1"
else
  print_err_msg_exit "
The number of arguments to this script must be exacty one, and that 
argument must specify the experiments base directory, i.e. the directory
containing the experiment subdirectories.  The acutal number of arguments 
is:
  num_args = ${num_args}"  
fi
#
#-----------------------------------------------------------------------
#
# Check that the specified experiments base directory exists and is 
# actually a directory.  If not, print out an error message and exit.
# If so, print out an informational message.
#
#-----------------------------------------------------------------------
#
if [ ! -d "${expts_basedir}" ]; then
  print_err_msg_exit "
The experiments base directory (expts_basedir) does not exit or is not 
actually a directory:
  expts_basedir = \"${expts_basedir}\""
else
  print_info_msg "
Checking the workflow status of all forecast experiments in the following
specified experiments base directory: 
  expts_basedir = \"${expts_basedir}\""
fi
#
#-----------------------------------------------------------------------
#
# Create an array containing the names of the subdirectories in the 
# experiment base directory.
#
#-----------------------------------------------------------------------
#
cd "${expts_basedir}"
# Get a list of all subdirectories (but not files) in the experiment base 
# directory.  Note that the ls command below will return a string containing
# the subdirectory names, with each name followed by a backslash and a 
# newline.
expts_list=$( \ls -1 -d */ )
# Remove all backslashes from the ends of the subdirectory names.
expts_list=$( printf "${expts_list}" "%s" | sed -r 's|/||g' )
# Create an array out of the string containing the newline-separated list
# of experiment subdirectories.
expts_list=( ${expts_list} )
#
#-----------------------------------------------------------------------
#
# Get the number of experiments for which to check the workflow status
# and print out an informational message.
#
#-----------------------------------------------------------------------
#
num_expts="${#expts_list[@]}"
expts_list_str=$( printf "  \'%s\'\n" "${expts_list[@]}" )
print_info_msg "
The number of experiments found is:
  num_expts = ${num_expts}
The list of experiments whose workflow status will be checked is:
${expts_list_str}
"
#
#-----------------------------------------------------------------------
#
# Set the name and full path of the file in which the status report will
# be saved.  If such a file already exists, rename it.
#
#-----------------------------------------------------------------------
#
yyyymmddhhmn=$( date +%Y%m%d%H%M )
expts_status_fn="expts_status_${yyyymmddhhmn}.txt"
expts_status_fp="${expts_basedir}/${expts_status_fn}"

# Note that the check_for_preexist_dir_file function assumes that there
# is a variable named "VERBOSE" in the environment.  Set that before 
# calling the function.
VERBOSE="TRUE"
check_for_preexist_dir_file "${expts_status_fp}" "rename"
#
#-----------------------------------------------------------------------
#
# Loop through the elements of the array expts_list.  For each element
# (i.e. for each experiment), change location to the experiment directory
# and call the script launch_FV3LAM_wflow.sh to update the log file
# log.launch_FV3LAM_wflow.  Then take the last num_tail_lines of this
# log file (along with an appropriate message) and add it to the status 
# report file.
#
#-----------------------------------------------------------------------
#
num_tail_lines="40"

for (( i=0; i<=$((num_expts-1)); i++ )); do

  expt_subdir="${expts_list[$i]}"
  msg="
======================================
Checking workflow status of experiment: \"${expt_subdir}\""
  print_info_msg "$msg"
#
# Change location to the experiment subdirectory, call the workflow launch
# script to update the launch log file, and capture the output from that
# call.
#
  cd_vrfy "${expt_subdir}"
  launch_msg=$( launch_FV3LAM_wflow.sh 2>&1 )
  log_tail=$( tail -n ${num_tail_lines} log.launch_FV3LAM_wflow )
#
# Record the tail from the log file into the status report file.
#
  print_info_msg "$msg" >> "${expts_status_fp}"
  print_info_msg "${log_tail}" >> "${expts_status_fp}"
#
# Print the workflow status to the screen.
  wflow_status=$( printf "${log_tail}" | grep "Workflow status:" )
#  wflow_status="${wflow_status## }"  # Not sure why this doesn't work to strip leading spaces.
  wflow_status=$( printf "${wflow_status}" "%s" | sed -r 's|^[ ]*||g' )
  msg="\
${wflow_status}
======================================
"
  print_info_msg "$msg"
#
# Change location back to the experiments base directory.
#
  cd_vrfy "${expts_basedir}"

done

print_info_msg "\
DONE."
