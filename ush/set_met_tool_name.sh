#
#-----------------------------------------------------------------------
#
# This file defines a function that uses the specified name of the MET
# METplus tool without separators (e.g. underscores) and in either lower
# or upper case (met_tool) to set its name in "snake case" (i.e. using
# underscores as separators) and "pascal case" (i.e. no separators but
# first letter of each word capitalized.)
#
#-----------------------------------------------------------------------
#
function set_met_tool_name() {
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
        "met_tool" \
        "outvarname_met_tool_sc" \
        "outvarname_met_tool_pc" \
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
  local _met_tool_sc_ \
        _met_tool_pc_
#
#-----------------------------------------------------------------------
#
# Create array containing set of forecast hours for which we will check
# for the existence of corresponding observation or forecast file.
#
#-----------------------------------------------------------------------
#
  met_tool=${met_tool,,}
  valid_vals_met_tool=( \
    "PB2NC" "PCPCOMBINE" "GRIDSTAT" "POINTSTAT" "ENSEMBLESTAT" \
    "pb2nc" "pcpcombine" "gridstat" "pointstat" "ensemblestat" \
    )
  check_var_valid_value "met_tool" "valid_vals_met_tool"

  case "${met_tool}" in
    "pb2nc")
      _met_tool_sc_="pb2nc"
      _met_tool_pc_="Pb2nc"
      ;;
    "pcpcombine")
      _met_tool_sc_="pcp_combine"
      _met_tool_pc_="PcpCombine"
      ;;
    "gridstat")
      _met_tool_sc_="grid_stat"
      _met_tool_pc_="GridStat"
      ;;
    "pointstat")
      _met_tool_sc_="point_stat"
      _met_tool_pc_="PointStat"
      ;;
    "ensemblestat")
      _met_tool_sc_="ensemble_stat"
      _met_tool_pc_="EnsembleStat"
      ;;
    *)
      print_err_msg_exit "\
Value specified for met_tool is unupported:
  met_tool = \"${met_tool}\""
      ;;
  esac
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_met_tool_sc}" ]; then
    printf -v ${outvarname_met_tool_sc} "%s" "${_met_tool_sc_}"
  fi

  if [ ! -z "${outvarname_met_tool_pc}" ]; then
    printf -v ${outvarname_met_tool_pc} "%s" "${_met_tool_pc_}"
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
