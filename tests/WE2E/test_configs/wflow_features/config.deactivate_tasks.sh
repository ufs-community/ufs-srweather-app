#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test has two purposes:
#
# 1) It checks that the various workflow tasks can be deactivated, i.e. 
#    removed from the Rocoto XML.
# 2) It checks the capability of the workflow to use "template" experiment 
#    variables, i.e. variables whose definitions include references to 
#    other variables, e.g.
#
#      MY_VAR='\${ANOTHER_VAR}'
#
# Note that we do not deactivate all tasks in the workflow; we leave the 
# MAKE_GRID_TN, MAKE_OROG_TN, and MAKE_SFC_CLIMO_TN activated because:
#
# 1) There is already a WE2E test that runs with these three tasks
#    deactivated (that test is to ensure that pre-generated grid, 
#    orography, and surface climatology files can be used).
# 2) In checking the template variable capability, we want to make sure
#    that the variable defintions file (GLOBAL_VAR_DEFNS_FN) generated
#    does not have syntax or other errors in it by sourcing it in these 
#    three tasks.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
CCPP_PHYS_SUITE="FV3_GFS_v15p2"

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20190701"
DATE_LAST_CYCL="20190701"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="3"

RUN_TASK_GET_EXTRN_ICS="FALSE"
RUN_TASK_GET_EXTRN_LBCS="FALSE"
RUN_TASK_MAKE_ICS="FALSE"
RUN_TASK_MAKE_LBCS="FALSE"
RUN_TASK_RUN_FCST="FALSE"
RUN_TASK_RUN_POST="FALSE"
#
# The following shows examples of how to define template variables.  Here,
# we define RUN_CMD_UTILS, RUN_CMD_FCST, and RUN_CMD_POST as template 
# variables.  Note that during this test, these templates aren't actually 
# expanded/used (something that would be done using bash's "eval" built-in 
# command) anywhere in the scripts.  They are included here only to verify
# that the test completes with some variables defined as templates.
#
RUN_CMD_UTILS='cd $yyyymmdd'
RUN_CMD_FCST='mpirun -np ${PE_MEMBER01}'
RUN_CMD_POST='echo hello $yyyymmdd'
