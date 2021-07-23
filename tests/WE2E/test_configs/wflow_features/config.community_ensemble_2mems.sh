#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test checks the capability of the workflow to run ensemble forecasts
# (i.e. DO_ENSEMBLE set to "TRUE") in community mode (i.e. RUN_ENVIR set 
# to "community") with the number of ensemble members (NUM_ENS_MEMBERS) 
# set to "2".  The lack of leading zeros in this "2" should cause the 
# ensemble members to be named "mem1" and "mem2" (instead of, for instance, 
# "mem01" and "mem02").
#
# Note also that this test uses two cycle hours ("00" and "12") to test
# the capability of the workflow to run ensemble forecasts for more than
# one cycle hour in community mode.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_GFS_2017_gfdlmp"

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20190701"
DATE_LAST_CYCL="20190702"
CYCL_HRS=( "00" "12" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="3"

DO_ENSEMBLE="TRUE"
NUM_ENS_MEMBERS="2"
