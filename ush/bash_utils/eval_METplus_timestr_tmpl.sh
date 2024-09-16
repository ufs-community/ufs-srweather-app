#
#-----------------------------------------------------------------------
#
# This function evaluates a METplus time-string template, i.e. a string
# (e.g. a file name template) containing one or more METplus time-
# formatting strings.
#
#-----------------------------------------------------------------------
#
function eval_METplus_timestr_tmpl() {
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
        "init_time" \
        "fhr" \
        "METplus_timestr_tmpl" \
        "outvarname_evaluated_timestr" \
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
  print_input_args "valid_args"
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local crnt_timefmt \
        crnt_timefmt_esc \
        evaluated_timestr \
        regex_search_tmpl \
        the_time \
        tmpl_remainder
#
#-----------------------------------------------------------------------
#
# Loop over all METplus time-formatting strings in the given METplus
# template and evaluate each using the given initial time (init_time) and
# forecast hour (fhr).
#
# Note that the while-loop below is over all METplus time-formatting
# strings of the form {...} in the template METplus_timestr_tmpl; it
# continues until all such time-formatting strings have been evaluated
# to actual times.
#
#-----------------------------------------------------------------------
#
# Regular expression used by the sed utility below to pick out the next
# METplus time-formatting string in the given METplus time-string template.
#
  regex_search_tmpl="(.*)(\{.*\})(.*)"
#
# Initialize while-loop variables.
#
  evaluated_timestr="${METplus_timestr_tmpl}"

  crnt_timefmt=$( printf "%s" "${METplus_timestr_tmpl}" | \
                  $SED -n -r -e "s|${regex_search_tmpl}|\2|p" )
  tmpl_remainder=$( printf "%s" "${METplus_timestr_tmpl}" | \
                    $SED -n -r -e "s|${regex_search_tmpl}|\1\3|p" )

  while [ ! -z "${crnt_timefmt}" ]; do

    eval_single_METplus_timefmt \
      init_time="${init_time}" \
      fhr="${fhr}" \
      METplus_timefmt="${crnt_timefmt}" \
      outvarname_evaluated_timefmt="the_time"
#
# Replace the next METplus time string in evaluated_timestr with an actual
# time.
#
# Note that when using sed, we need to escape various characters (question
# mark, closing and opening curly braces, etc) in the METplus template in
# order for the sed command below to work properly.
#
     crnt_timefmt_esc=$( echo "${crnt_timefmt}" | \
                         $SED -r -e "s/\?/\\\?/g" -e "s/\{/\\\{/g" -e "s/\}/\\\}/g" )
     evaluated_timestr=$( echo "${evaluated_timestr}" | \
                          $SED -n -r "s|(.*)(${crnt_timefmt_esc})(.*)|\1${the_time}\3|p" )
#
# Set up values for the next iteration of the while-loop.
#
     crnt_timefmt=$( printf "%s" "${tmpl_remainder}" | \
                     $SED -n -r -e "s|${regex_search_tmpl}|\2|p" )
     tmpl_remainder=$( printf "%s" "${tmpl_remainder}" | \
                       $SED -n -r -e "s|${regex_search_tmpl}|\1\3|p" )

   done
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_evaluated_timestr}" ]; then
    printf -v ${outvarname_evaluated_timestr} "%s" "${evaluated_timestr}"
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
# This function uses the specified initial forecast time and forecast
# hour to evaluate a single METplus time-formatting string and return
# the corresponding time.
#
#-----------------------------------------------------------------------
#
function eval_single_METplus_timefmt() {
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
        "init_time" \
        "fhr" \
        "METplus_timefmt" \
        "outvarname_evaluated_timefmt" \
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
  print_input_args "valid_args"
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local evaluated_timefmt \
        fmt \
        hh_init \
        init_time_str \
        lead_hrs \
        len \
        METplus_time_codes \
        METplus_time_shift \
        METplus_time_type \
        mn_init \
        regex_search \
        ss_init \
        valid_time_str \
        yyyymmdd_init
#
#-----------------------------------------------------------------------
#
# Run checks on input arguments.
#
#-----------------------------------------------------------------------
#
  if [ -z "${METplus_timefmt}" ]; then
    print_err_msg_exit "\
The specified METplus time-formatting string (METplus_timefmt) cannot be
empty:
  METplus_timefmt = \"${METplus_timefmt}\""
  fi

  len=${#init_time}
  if [[ ${init_time} =~ ^[0-9]+$ ]]; then
    if [ "$len" -ne 10 ] && [ "$len" -ne 12 ] && [ "$len" -ne 14 ]; then
      print_err_msg_exit "\
The specified initial time (init_time) must contain 10, 12, or 14 digits
but instead contains $len:
  init_time = \"${init_time}\""
    fi
  else
    print_err_msg_exit "\
The specified initial time (init_time) must consist of digits only and
cannot be empty:
  init_time = \"${init_time}\""
  fi

  if ! [[ $fhr =~ ^[0-9]+$ ]]; then
    print_err_msg_exit "\
The specified forecast hour (fhr) must consist of digits only and cannot
be empty:
  fhr = \"${fhr}\""
  fi
#
#-----------------------------------------------------------------------
#
# Set strings for the initial and valid times that can be passed to the
# "date" utility for evaluation.
#
#-----------------------------------------------------------------------
#
  yyyymmdd_init=${init_time:0:8}
  hh_init=${init_time:8:2}

  mn_init="00"
  if [ "$len" -gt "10" ]; then
    mn_init=${init_time:10:2}
  fi

  ss_init="00"
  if [ "$len" -gt "12" ]; then
    ss_init=${init_time:12:2}
  fi

  init_time_str=$( printf "%s" "${yyyymmdd_init} + ${hh_init} hours + ${mn_init} minutes + ${ss_init} seconds" )
  valid_time_str=$( printf "%s" "${init_time_str} + ${fhr} hours" )
#
#-----------------------------------------------------------------------
#
# Parse the input METplus time string template.
#
#-----------------------------------------------------------------------
#
  regex_search="^\{(init|valid|lead)(\?)(fmt=)([^\?]*)(\?)?(shift=)?([^\?]*)?\}"
  METplus_time_type=$( \
    printf "%s" "${METplus_timefmt}" | $SED -n -r -e "s/${regex_search}/\1/p" )
  METplus_time_codes=$( \
    printf "%s" "${METplus_timefmt}" | $SED -n -r -e "s/${regex_search}/\4/p" )
  METplus_time_shift=$( \
    printf "%s" "${METplus_timefmt}" | $SED -n -r -e "s/${regex_search}/\7/p" )
#
#-----------------------------------------------------------------------
#
# Get strings for the time format and time shift that can be passed to
# the "date" utility or the "printf" command.
#
#-----------------------------------------------------------------------
#
  case "${METplus_time_codes}" in
    "%Y%m%d%H"|"%Y%m%d"|"%H%M%S")
      fmt="${METplus_time_codes}"
      ;;
    "%H")
#
# The "%H" format needs to be treated differently depending on if it's
# formatting a "lead" time type or another (e.g. "init" or "vald") because
# for "lead", the printf function is used below (which doesn't understand
# the "%H" format) whereas for the others, the date utility is used (which
# does understand "%H").
#
      if [ "${METplus_time_type}" = "lead" ]; then
        fmt="%02.0f"
      else
        fmt="${METplus_time_codes}"
      fi
      ;;
    "%HHH")
#
# Print format assumes that the argument to printf (i.e. the number to 
# print out) may be a float.  If we instead assume an integer and use
# "%03d" as the format, the printf function below will fail if the argument
# happens to be a float.  The "%03.0f" format will work for both a float
# and an integer argument (and will truncate the float and print out a
# 3-digit integer).
#
      fmt="%03.0f"
      ;;
    *)
      print_err_msg_exit "\
Unsupported METplus time codes:
  METplus_time_codes = \"${METplus_time_codes}\"
METplus time-formatting string passed to this function is:
  METplus_timefmt = \"${METplus_timefmt}\""
      ;;
  esac
#
# Calculate the time shift as an integer in units of seconds.
#
  time_shift_str=$(( $(printf "%.0f" "${METplus_time_shift}") + 0 ))" seconds"
#
#-----------------------------------------------------------------------
#
# Set the formatted time string.
#
#-----------------------------------------------------------------------
#
  case "${METplus_time_type}" in
    "init")
      evaluated_timefmt=$( ${DATE_UTIL} --date="${init_time_str} + ${time_shift_str}" +"${fmt}" )
      ;;
    "valid")
      evaluated_timefmt=$( ${DATE_UTIL} --date="${valid_time_str} + ${time_shift_str}" +"${fmt}" )
      ;;
    "lead")
      lead_secs=$(( $( ${DATE_UTIL} --date="${valid_time_str} + ${time_shift_str}" +"%s" ) \
               - $( ${DATE_UTIL} --date="${init_time_str}" +"%s" ) ))
      lead_hrs=$( bc -l <<< "${lead_secs}/${SECS_PER_HOUR}" )
#
# Check to make sure lead_hrs is an integer.
#
      lead_hrs_trunc=$( bc <<< "${lead_secs}/${SECS_PER_HOUR}" )
      lead_hrs_rem=$( bc -l <<< "${lead_hrs} - ${lead_hrs_trunc}" )
      if [ "${lead_hrs_rem}" != "0" ]; then
        print_err_msg_exit "\
The lead in hours (lead_hrs) must be an integer but isn't:
  lead_hrs = ${lead_hrs}
The lead in seconds (lead_secs) is:
  lead_secs = ${lead_secs}
The remainder (lead_hrs_rem) after dividing the lead_secs by SECS_PER_HOUR
= ${SECS_PER_HOUR} is:
  lead_hrs_rem = ${lead_hrs_rem}"
      fi
#
# Get the lead in the proper format.
#
      evaluated_timefmt=$( printf "${fmt}" "${lead_hrs}" )
      ;;
    *)
      print_err_msg_exit "\
Unsupported METplus time type:
  METplus_time_type = \"${METplus_time_type}\"
METplus time-formatting string passed to this function is:
  METplus_timefmt = \"${METplus_timefmt}\""
      ;;
  esac

  if [ -z "${evaluated_timefmt}" ]; then
    print_err_msg_exit "\
The specified METplus time-formatting string (METplus_timefmt) could not
be evaluated for the given initial time (init_time) and forecast hour
(fhr):
  METplus_timefmt = \"${METplus_timefmt}\"
  init_time = \"${init_time}\"
  fhr = \"${fhr}\""
  fi
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_evaluated_timefmt}" ]; then
    printf -v ${outvarname_evaluated_timefmt} "%s" "${evaluated_timefmt}"
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
