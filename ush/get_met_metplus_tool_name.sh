#
#-----------------------------------------------------------------------
#
# This file defines a function that uses the given generic name of a MET/
# METplus tool (generic_tool_name; this is a name that does not contain
# any separators like underscores and that may be in upper or lower case)
# to set its name in MET (met_tool_name) and in METplus (metplus_tool_name).
# Note that the tool name in MET is in "snake case" (i.e. uses underscores
# as separators with all lower case) while that in METplus is in "pascal
# case" (i.e. no separators and with first letter of each word capitalized).
#
#-----------------------------------------------------------------------
#
function get_met_metplus_tool_name() {
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
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
        "generic_tool_name" \
        "outvarname_met_tool_name" \
        "outvarname_metplus_tool_name" \
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
  local _generic_tool_name_name_ \
        _metplus_tool_name_
#
#-----------------------------------------------------------------------
#
# Create array containing set of forecast hours for which we will check
# for the existence of corresponding observation or forecast file.
#
#-----------------------------------------------------------------------
#
  generic_tool_name=${generic_tool_name,,}
  valid_vals_generic_tool_name=( \
    "PB2NC" "PCPCOMBINE" "GRIDSTAT" "POINTSTAT" "GENENSPROD" "ENSEMBLESTAT" \
    "pb2nc" "pcpcombine" "gridstat" "pointstat" "genensprod" "ensemblestat" \
    )
  check_var_valid_value "generic_tool_name" "valid_vals_generic_tool_name"

  case "${generic_tool_name}" in
    "pb2nc")
      _met_tool_name_="pb2nc"
      _metplus_tool_name_="Pb2nc"
      ;;
    "pcpcombine")
      _met_tool_name_="pcp_combine"
      _metplus_tool_name_="PcpCombine"
      ;;
    "gridstat")
      _met_tool_name_="grid_stat"
      _metplus_tool_name_="GridStat"
      ;;
    "pointstat")
      _met_tool_name_="point_stat"
      _metplus_tool_name_="PointStat"
      ;;
    "genensprod")
      _met_tool_name_="gen_ens_prod"
      _metplus_tool_name_="GenEnsProd"
      ;;
    "ensemblestat")
      _met_tool_name_="ensemble_stat"
      _metplus_tool_name_="EnsembleStat"
      ;;
    *)
      print_err_msg_exit "\
Generic name specified for MET/METplus tool (generic_tool_name) is
unupported:
  generic_tool_name = \"${generic_tool_name}\""
      ;;
  esac
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_met_tool_name}" ]; then
    printf -v ${outvarname_met_tool_name} "%s" "${_met_tool_name_}"
  fi

  if [ ! -z "${outvarname_metplus_tool_name}" ]; then
    printf -v ${outvarname_metplus_tool_name} "%s" "${_metplus_tool_name_}"
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
