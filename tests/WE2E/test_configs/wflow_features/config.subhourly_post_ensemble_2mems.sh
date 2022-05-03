# 
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test checks the capability of the workflow to run ensemble forecasts
# that require the forecast model to write output files and perform post-
# processing on a sub-hourly time interval.
#
# This test is needed in addition to the one named "subhourly_post" 
# because in the jinja template file from which the rocoto workflow XML
# is generated, the code changes that were made to add the subhourly
# capability also involved changes to the ensemble capability.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUScompact_25km"
CCPP_PHYS_SUITE="FV3_RRFS_v1beta"

EXTRN_MDL_NAME_ICS="HRRR"
EXTRN_MDL_NAME_LBCS="RAP"
USE_USER_STAGED_EXTRN_FILES="TRUE"
EXTRN_MDL_FILES_ICS=( '{yy}{jjj}{hh}00{fcst_hr:02d}00' )
EXTRN_MDL_FILES_LBCS=( '{yy}{jjj}{hh}00{fcst_hr:02d}00' )

DATE_FIRST_CYCL="20200810"
DATE_LAST_CYCL="20200810"
CYCL_HRS=( "00" )

FCST_LEN_HRS="3"
LBC_SPEC_INTVL_HRS="1"

DT_ATMOS="120"

SUB_HOURLY_POST="TRUE"
DT_SUBHOURLY_POST_MNTS="12"

DO_ENSEMBLE="TRUE"
NUM_ENS_MEMBERS="2"
