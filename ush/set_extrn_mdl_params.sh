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
    *)
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
