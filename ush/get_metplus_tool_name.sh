#
#-----------------------------------------------------------------------
#
# This file defines a function that takes as input the name of a MET/METplus
# tool spelled in upper flat case, i.e. all-caps and without separators
# (e.g. METPLUSTOOLNAME) and returns that name converted to the following
# cases:
#
# 1) Snake case, i.e. in all lower-case with underscores as word separators,
#    e.g. metplus_tool_name.
# 2) Pascal case, i.e. without separators and with the first letter of
#    each word capitalized, e.g. MetplusToolName.
# 3) Screaming snake case, i.e. in all upper-case with underscores as
#    word separators, e.g. METPLUS_TOOL_NAME.
#
#-----------------------------------------------------------------------
#
function get_metplus_tool_name() {
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
        "METPLUSTOOLNAME" \
        "outvarname_metplus_tool_name" \
        "outvarname_MetplusToolName" \
        "outvarname_METPLUS_TOOL_NAME" \
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
  local _metplus_tool_name_ \
        _MetplusToolName_ \
        _METPLUS_TOOL_NAME_
#
#-----------------------------------------------------------------------
#
# Create array containing set of forecast hours for which we will check
# for the existence of corresponding observation or forecast file.
#
#-----------------------------------------------------------------------
#
  valid_vals_METPLUSTOOLNAME=( \
    "ASCII2NC" "PB2NC" "PCPCOMBINE" "GRIDSTAT" "POINTSTAT" "GENENSPROD" "ENSEMBLESTAT" \
    )
  check_var_valid_value "METPLUSTOOLNAME" "valid_vals_METPLUSTOOLNAME"

  case "${METPLUSTOOLNAME}" in
    "ASCII2NC")
      _metplus_tool_name_="ascii2nc"
      _MetplusToolName_="Ascii2nc"
      ;;
    "PB2NC")
      _metplus_tool_name_="pb2nc"
      _MetplusToolName_="Pb2nc"
      ;;
    "PCPCOMBINE")
      _metplus_tool_name_="pcp_combine"
      _MetplusToolName_="PcpCombine"
      ;;
    "GRIDSTAT")
      _metplus_tool_name_="grid_stat"
      _MetplusToolName_="GridStat"
      ;;
    "POINTSTAT")
      _metplus_tool_name_="point_stat"
      _MetplusToolName_="PointStat"
      ;;
    "GENENSPROD")
      _metplus_tool_name_="gen_ens_prod"
      _MetplusToolName_="GenEnsProd"
      ;;
    "ENSEMBLESTAT")
      _metplus_tool_name_="ensemble_stat"
      _MetplusToolName_="EnsembleStat"
      ;;
    *)
      print_err_msg_exit "\
Generic name specified for MET/METplus tool (METPLUSTOOLNAME) is
unupported:
  METPLUSTOOLNAME = \"${METPLUSTOOLNAME}\""
      ;;
  esac

  _METPLUS_TOOL_NAME_=$(echo_uppercase ${_metplus_tool_name_})
#
#-----------------------------------------------------------------------
#
# Set output variables.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${outvarname_metplus_tool_name}" ]; then
    printf -v ${outvarname_metplus_tool_name} "%s" "${_metplus_tool_name_}"
  fi

  if [ ! -z "${outvarname_MetplusToolName}" ]; then
    printf -v ${outvarname_MetplusToolName} "%s" "${_MetplusToolName_}"
  fi

  if [ ! -z "${outvarname_METPLUS_TOOL_NAME}" ]; then
    printf -v ${outvarname_METPLUS_TOOL_NAME} "%s" "${_METPLUS_TOOL_NAME_}"
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
