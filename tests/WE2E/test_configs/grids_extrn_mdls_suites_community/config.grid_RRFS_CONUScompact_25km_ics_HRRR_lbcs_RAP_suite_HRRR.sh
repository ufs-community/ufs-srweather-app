#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in community mode 
# completes successfully on the RRFS_CONUScompact_25km grid using the HRRR
# physics suite with ICs derived from the HRRR and LBCs derived from the RAP.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUScompact_25km"
CCPP_PHYS_SUITE="FV3_HRRR"

EXTRN_MDL_NAME_ICS="HRRR"
EXTRN_MDL_NAME_LBCS="RAP"
USE_USER_STAGED_EXTRN_FILES="TRUE"
EXTRN_MDL_FILES_ICS=( '{yy}{jjj}{hh}00{fcst_hr:02d}00' )
EXTRN_MDL_FILES_LBCS=( '{yy}{jjj}{hh}00{fcst_hr:02d}00' )

DATE_FIRST_CYCL="20200810"
DATE_LAST_CYCL="20200810"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="2"
