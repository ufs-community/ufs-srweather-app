# 
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test checks the capability of the workflow to have the forecast 
# model's time step (DT_ATMOS), its MPI layout (LAYOUT_X and LAYOUT_Y), 
# and its cache block size be set to user-specified values.
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

DATE_FIRST_CYCL="20200801"
DATE_LAST_CYCL="20200801"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="3"

DT_ATMOS="100"
LAYOUT_X="10"
LAYOUT_Y="4"
BLOCKSIZE="35"
