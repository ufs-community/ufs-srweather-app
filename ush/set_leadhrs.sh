#
#-----------------------------------------------------------------------
#
# This file defines functions used to generate sets of lead hours for
# which verification will be performed.
#
#-----------------------------------------------------------------------
#

function set_leadhrs_no_missing() {
#
#-----------------------------------------------------------------------
#
# This function sets the lead hours (relative to some unspecified initial/
# reference time) for which verification will be performed under the
# assumption that the data file (which may be a forecast output file or
# an observation file) for each hour is available (i.e. it assumes that
# there are no missing files).
#
#-----------------------------------------------------------------------
#

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
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
        "lhr_min" \
        "lhr_max" \
        "lhr_intvl" \
        "outvarname_lhrs_list_no_missing" \
        )
  process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local lhrs_array \
        lhrs_list
#
#-----------------------------------------------------------------------
#
# Create the array of lead hours.
#
#-----------------------------------------------------------------------
#
  lhrs_array=($( seq ${lhr_min} ${lhr_intvl} ${lhr_max} ))

  # Express the array of lead hours as a (scalar) string containing a comma
  # (and space) separated list of the elements of lhrs_array.
  lhrs_list=$( printf "%s, " "${lhrs_array[@]}" )
  lhrs_list=$( echo "${lhrs_list}" | $SED "s/, $//g" )
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_lhrs_list_no_missing}" ]; then
    printf -v ${outvarname_lhrs_list_no_missing} "%s" "${lhrs_list}"
  fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}


#
#-----------------------------------------------------------------------
#
# This function generates a list of lead hours (relative to an initial or
# reference time yyyymmddhh_init) such that for each such hour, there
# exists a corresponding data file with a name of the form specified by
# the template fn_template.  Depending on fn_template, this file may
# contain forecast or observation data.
#
#-----------------------------------------------------------------------
#
function set_leadhrs() {
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
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
        "yyyymmddhh_init" \
        "lhr_min" \
        "lhr_max" \
        "lhr_intvl" \
        "base_dir" \
        "fn_template" \
        "num_missing_files_max" \
        "outvarname_lhrs_list" \
        )
  process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local crnt_tmpl \
        crnt_tmpl_esc \
        fn \
        fp \
        i \
        lhr \
        lhrs_array \
        lhrs_list \
        num_hrs \
        num_missing_files \
        remainder \
        skip_this_hour
#
#-----------------------------------------------------------------------
#
# For the specified field, generate the set of lead hours at which
# verification will be performed under the assumption that for each such
# hour, the corresponding or observation file exists.  Thus, this set is
# an initial guess for the lead hours at which vx will be performed.
#
#-----------------------------------------------------------------------
#
  set_leadhrs_no_missing \
    lhr_min="${lhr_min}" \
    lhr_max="${lhr_max}" \
    lhr_intvl="${lhr_intvl}" \
    outvarname_lhrs_list_no_missing="lhrs_list_no_missing"

  # For convenience, save the scalar variable lhrs_list_no_missing to a
  # bash array.
  lhrs_array=($( printf "%s" "${lhrs_list_no_missing}" | $SED "s/,//g" ))

  print_info_msg "$VERBOSE" "\
Initial (i.e. before filtering for missing files) set of lead hours
(relative to ${yyyymmddhh_init}) is:
  lhrs_array = ( $( printf "\"%s\" " "${lhrs_array[@]}" ))
"
#
#-----------------------------------------------------------------------
#
# Loop through the array of lead hours generated above and construct the
# variable lhrs_list that will be scalar (string) containing a comma-
# separated list of hours for which corresponding forecast or observation
# files have been confirmed to exist.  Also, use the variable
# num_missing_files to keep track of the number of files that are missing.
#
#-----------------------------------------------------------------------
#
  lhrs_list=""
  num_missing_files="0"
  num_hrs=${#lhrs_array[@]}
  for (( i=0; i<${num_hrs}; i++ )); do

    lhr="${lhrs_array[$i]}"
    skip_this_hour="FALSE"
#
# Evaluate the METplus file name template containing METplus timestrings
# for the specified yyyymmddhh_init and current hour (lhr) to obtain the
# name of the current file (including possibly a relative directory).
#
    eval_METplus_timestr_tmpl \
      init_time="${yyyymmddhh_init}" \
      fhr="${lhr}" \
      METplus_timestr_tmpl="${fn_template}" \
      outvarname_evaluated_timestr="fn"
#
# Get the full path to the file and check if it exists.
#
    fp="${base_dir}/${fn}"
    if [ -f "${fp}" ]; then
      print_info_msg "\
Found file (fp) for lead hour ${lhr} (relative to ${yyyymmddhh_init}):
  fp = \"${fp}\"
"
    else
      skip_this_hour="TRUE"
      num_missing_files=$(( ${num_missing_files} + 1 ))
      print_info_msg "\
The file (fp) for lead hour ${lhr} (relative to ${yyyymmddhh_init}) is MISSING:
  fp = \"${fp}\"
Excluding this hour from the list of lead hours to return.
"
      break
    fi

    if [[ ! $(boolify "${skip_this_hour}") == "TRUE" ]]; then
      lhrs_list="${lhrs_list},${lhr}"
    fi

  done
#
# Remove leading comma from lhrs_list.
#
  lhrs_list=$( echo "${lhrs_list}" | $SED "s/^,//g" )
  print_info_msg "$VERBOSE" "\
Final (i.e. after filtering for missing files) set of lead hours relative
to ${yyyymmddhh_init} (saved in a scalar string variable) is:
  lhrs_list = \"${lhrs_list}\"
"
#
#-----------------------------------------------------------------------
#
# If the number of missing files is greater than the maximum allowed
# (specified by num_missing_files_max), print out an error message and
# exit.
#
#-----------------------------------------------------------------------
#
  if [ "${num_missing_files}" -gt "${num_missing_files_max}" ]; then
    print_err_msg_exit "\
The number of missing files (num_missing_files) is greater than the
maximum allowed number (num_missing_files_max):
  num_missing_files = ${num_missing_files}
  num_missing_files_max = ${num_missing_files_max}"
  fi
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_lhrs_list}" ]; then
    printf -v ${outvarname_lhrs_list} "%s" "${lhrs_list}"
  fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}
