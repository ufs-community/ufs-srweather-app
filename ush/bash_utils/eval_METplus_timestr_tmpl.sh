#
#-----------------------------------------------------------------------
#
# This file defines a function that evaluates a METplus time-string 
# template.
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
        "outvarname_formatted_time" \
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
  local fmt \
        formatted_time \
        hh_init \
        init_time_str \
        lead_hrs \
        len \
        mn_init \
        METplus_time_fmt \
        METplus_time_shift \
        METplus_time_type \
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
  if [ -z "${METplus_timestr_tmpl}" ]; then
    print_err_msg_exit "\
The specified METplus time string template (METplus_timestr_tmpl) cannot be empty:
  METplus_timestr_tmpl = \"${METplus_timestr_tmpl}\""
  fi

  len=${#init_time}
  if [[ ${init_time} =~ ^[0-9]+$ ]]; then
    if [ "$len" -ne 10 ] && [ "$len" -ne 12 ] && [ "$len" -ne 14 ]; then
      print_err_msg_exit "\
The specified initial time string (init_time) must contain exactly 10,
12, or 14 integers (but contains $len):
  init_time = \"${init_time}\""
    fi
  else
    print_err_msg_exit "\
The specified initial time string (init_time) must consist of only
integers and cannot be empty:
  init_time = \"${init_time}\""
  fi

  if ! [[ $fhr =~ ^[0-9]+$ ]]; then
    print_err_msg_exit "\
The specified forecast hour (fhr) must consist of only integers and
cannot be empty:
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
    printf "%s" "${METplus_timestr_tmpl}" | $SED -n -r -e "s/${regex_search}/\1/p" )
  METplus_time_fmt=$( \
    printf "%s" "${METplus_timestr_tmpl}" | $SED -n -r -e "s/${regex_search}/\4/p" )
  METplus_time_shift=$( \
    printf "%s" "${METplus_timestr_tmpl}" | $SED -n -r -e "s/${regex_search}/\7/p" )
#
#-----------------------------------------------------------------------
#
# Get strings for the time format and time shift that can be passed to
# the "date" utility or the "printf" command.
#
#-----------------------------------------------------------------------
#
  case "${METplus_time_fmt}" in
    "%Y%m%d%H"|"%Y%m%d"|"%H%M%S"|"%H")
      fmt="${METplus_time_fmt}"
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
Unsupported METplus time format:
  METplus_time_fmt = \"${METplus_time_fmt}\"
METplus time string template passed to this function is:
  METplus_timestr_tmpl = \"${METplus_timestr_tmpl}\""
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
      formatted_time=$( ${DATE_UTIL} --date="${init_time_str} + ${time_shift_str}" +"${fmt}" )
      ;;
    "valid")
      formatted_time=$( ${DATE_UTIL} --date="${valid_time_str} + ${time_shift_str}" +"${fmt}" )
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
      formatted_time=$( printf "${fmt}" "${lead_hrs}" )
      ;;
    *)
      print_err_msg_exit "\
Unsupported METplus time type:
  METplus_time_type = \"${METplus_time_type}\"
METplus time string template passed to this function is:
  METplus_timestr_tmpl = \"${METplus_timestr_tmpl}\""
      ;;
  esac

  if [ -z "${formatted_time}" ]; then
    print_err_msg_exit "\
The specified METplus time string template (METplus_timestr_tmpl) could
not be evaluated for the given initial time (init_time) and forecast
hour (fhr):
  METplus_timestr_tmpl = \"${METplus_timestr_tmpl}\"
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
  if [ ! -z "${outvarname_formatted_time}" ]; then
    printf -v ${outvarname_formatted_time} "%s" "${formatted_time}"
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
