#
#-----------------------------------------------------------------------
#
# This file defines a function that generates a list of forecast hours
# such that for each hour there exist a corresponding obs file.  It does
# this by first generating a generic sequence of forecast hours and then
# removing from that sequence any hour for which there is no obs file.
#
#-----------------------------------------------------------------------
#
function set_vx_fhr_list() {
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
        "cdate" \
        "fcst_len_hrs" \
        "field" \
        "accum_hh" \
        "base_dir" \
        "fn_template" \
        "check_hourly_files" \
        "outvarname_fhr_list" \
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
        fhr \
        fhr_array \
        fhr_int \
        fhr_list \
        fhr_min \
        fhr_max \
        fn \
        fp \
        i \
        num_fcst_hrs \
        num_missing_files \
        regex_search_tmpl \
        remainder \
        skip_this_fhr
#
#-----------------------------------------------------------------------
#
# Create array containing set of forecast hours for which we will check
# for the existence of corresponding observation or forecast file.
#
#-----------------------------------------------------------------------
#
  case "${field}" in
    "APCP")
      fhr_min="${accum_hh}"
      fhr_int="${accum_hh}"
      ;;
    "REFC")
      fhr_min="01"
      fhr_int="01"
      ;;
    "RETOP")
      fhr_min="01"
      fhr_int="01"
      ;;
    "SFC")
      fhr_min="01"
      fhr_int="01"
      ;;
    "UPA")
      fhr_min="06"
      fhr_int="06"
      ;;
    *)
      print_err_msg_exit "\
A method for setting verification parameters has not been specified for
this field (field):
  field = \"${field}\""
      ;;
  esac
  fhr_max="${fcst_len_hrs}"

  fhr_array=($( seq ${fhr_min} ${fhr_int} ${fhr_max} ))
  print_info_msg "$VERBOSE" "\
Initial (i.e. before filtering for missing files) set of forecast hours
is:
  fhr_array = ( $( printf "\"%s\" " "${fhr_array[@]}" ))
"
#
#-----------------------------------------------------------------------
#
# Loop through all forecast hours.  For each one for which a corresponding
# file exists, add the forecast hour to fhr_list.  fhr_list will be a
# scalar containing a comma-separated list of forecast hours for which
# corresponding files exist.  Also, use the variable num_missing_files
# to keep track of the number of files that are missing.
#
#-----------------------------------------------------------------------
#
  fhr_list=""
  num_missing_files="0"
  num_fcst_hrs=${#fhr_array[@]}
  for (( i=0; i<${num_fcst_hrs}; i++ )); do

    fhr_orig="${fhr_array[$i]}"

    if [ "${check_hourly_files}" = "TRUE" ]; then
      fhr=$(( ${fhr_orig} - ${accum_hh} + 1 ))
      num_back_hrs=${accum_hh}
    else
      fhr=${fhr_orig}
      num_back_hrs=1
    fi

    skip_this_fhr="FALSE"
    for (( j=0; j<${num_back_hrs}; j++ )); do
#
# Use the provided template to set the name of/relative path to the file 
#
      fn="${fn_template}"
      regex_search_tmpl="(.*)(\{.*\})(.*)"
      crnt_tmpl=$( printf "%s" "${fn_template}" | \
                   $SED -n -r -e "s|${regex_search_tmpl}|\2|p" )
      remainder=$( printf "%s" "${fn_template}" | \
                   $SED -n -r -e "s|${regex_search_tmpl}|\1\3|p" )
      while [ ! -z "${crnt_tmpl}" ]; do

        eval_METplus_timestr_tmpl \
          init_time="$cdate" \
          fhr="$fhr" \
          METplus_timestr_tmpl="${crnt_tmpl}" \
          outvarname_formatted_time="actual_value"
#
# Replace METplus time templates in fn with actual times.  Note that
# when using sed, we need to escape various characters (question mark,
# closing and opening curly braces, etc) in the METplus template in 
# order for the sed command below to work properly.
#
        crnt_tmpl_esc=$( echo "${crnt_tmpl}" | \
                         $SED -r -e "s/\?/\\\?/g" -e "s/\{/\\\{/g" -e "s/\}/\\\}/g" )
        fn=$( echo "${fn}" | \
              $SED -n -r "s|(.*)(${crnt_tmpl_esc})(.*)|\1${actual_value}\3|p" )
#
# Set up values for the next iteration of the while-loop.
#
        crnt_tmpl=$( printf "%s" "${remainder}" | \
                     $SED -n -r -e "s|${regex_search_tmpl}|\2|p" )
        remainder=$( printf "%s" "${remainder}" | \
                     $SED -n -r -e "s|${regex_search_tmpl}|\1\3|p" )

      done
#
# Get the full path to the file and check if it exists.
#
      fp="${base_dir}/${fn}"

      if [ -f "${fp}" ]; then
        print_info_msg "\
Found file (fp) for the current forecast hour (fhr; relative to the cycle
date cdate):
  fhr = \"$fhr\"
  cdate = \"$cdate\"
  fp = \"${fp}\"
"
      else
        skip_this_fhr="TRUE"
        num_missing_files=$(( ${num_missing_files} + 1 ))
        print_info_msg "\
The file (fp) for the current forecast hour (fhr; relative to the cycle
date cdate) is missing:
  fhr = \"$fhr\"
  cdate = \"$cdate\"
  fp = \"${fp}\"
Excluding the current forecast hour from the list of hours passed to the
METplus configuration file.
"
        break
      fi

      fhr=$(( $fhr + 1 ))

    done

    if [ "${skip_this_fhr}" != "TRUE" ]; then
      fhr_list="${fhr_list},${fhr_orig}"
    fi

  done
#
# Remove leading comma from fhr_list.
#
  fhr_list=$( echo "${fhr_list}" | $SED "s/^,//g" )
  print_info_msg "$VERBOSE" "\
Final (i.e. after filtering for missing files) set of foreast hours is
(written as a single string):
  fhr_list = \"${fhr_list}\"
"
#
#-----------------------------------------------------------------------
#
# If the number of missing files is greater than the user-specified
# variable NUM_MISSING_OBS_FILES_MAX, print out an error message and
# exit.
#
#-----------------------------------------------------------------------
#
  if [ "${num_missing_files}" -gt "${NUM_MISSING_OBS_FILES_MAX}" ]; then
    print_err_msg_exit "\
The number of missing files (num_missing_files) is greater than the
maximum allowed number (NUM_MISSING_OBS_FILES_MAX):
  num_missing_files = ${num_missing_files}
  NUM_MISSING_OBS_FILES_MAX = ${NUM_MISSING_OBS_FILES_MAX}"
  fi
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_fhr_list}" ]; then
    printf -v ${outvarname_fhr_list} "%s" "${fhr_list}"
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
