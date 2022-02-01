#
#-----------------------------------------------------------------------
#
# This file sets some parameters that are model or mode specific.
#
#-----------------------------------------------------------------------
#
function set_extrn_mdl_params() {
  #
  #-----------------------------------------------------------------------
  #
  # Use known locations or COMINgfs as default, depending on RUN_ENVIR
  #
  #-----------------------------------------------------------------------
  #
  if [ "${RUN_ENVIR}" = "nco" ]; then
    EXTRN_MDL_SYSBASEDIR_ICS="${EXTRN_MDL_SYSBASEDIR_ICS:-$COMINgfs}"
    EXTRN_MDL_SYSBASEDIR_LBCS="${EXTRN_MDL_SYSBASEDIR_LBCS:-$COMINgfs}"
  else
    EXTRN_MDL_SYSBASEDIR_ICS="${EXTRN_MDL_SYSBASEDIR_ICS:-$(set_known_sys_dir \
    ${EXTRN_MDL_NAME_ICS})}"
    EXTRN_MDL_SYSBASEDIR_LBCS="${EXTRN_MDL_SYSBASEDIR_LBCS:-$(set_known_sys_dir \
    ${EXTRN_MDL_NAME_LBCS})}"
  fi

  #
  #-----------------------------------------------------------------------
  #
  # Set EXTRN_MDL_LBCS_OFFSET_HRS, which is the number of hours to shift 
  # the starting time of the external model that provides lateral boundary 
  # conditions.
  #
  #-----------------------------------------------------------------------
  #
  case "${EXTRN_MDL_NAME_LBCS}" in
    "RAP")
      EXTRN_MDL_LBCS_OFFSET_HRS=${EXTRN_MDL_LBCS_OFFSET_HRS:-"3"}
      ;;
    "*")
      EXTRN_MDL_LBCS_OFFSET_HRS=${EXTRN_MDL_LBCS_OFFSET_HRS:-"0"}
      ;;
  esac
}

#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
set_extrn_mdl_params
