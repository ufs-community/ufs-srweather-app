#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in community mode 
# completes successfully on the RRFS_NA_3km grid using the RRFS_v1beta
# physics suite with ICs and LBCs derived from the FV3GFS.
#
# Note that this test also sets various resource parameters for several
# of the rocoto tasks in order to more efficiently run the code on this
# (very large) grid.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_NA_3km"
CCPP_PHYS_SUITE="FV3_RRFS_v1beta"

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20190701"
DATE_LAST_CYCL="20190701"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="6"

#########################################################################
# The following code/namelist/workflow setting changes are necessary to #
# run/optimize end-to-end experiments using the 3-km NA grid            #
#########################################################################

# The model should be built in 32-bit mode (64-bit will result in much
# longer run times.

# Use k_split=2 and n_split=5, the previous namelist values (k_split=4
# and n_split=5) will result in significantly longer run times.

NNODES_MAKE_ICS="12"
NNODES_MAKE_LBCS="12"
PPN_MAKE_ICS="4"
PPN_MAKE_LBCS="4"
WTIME_MAKE_LBCS="01:00:00"

NNODES_RUN_POST="8"
PPN_RUN_POST="12"

OMP_STACKSIZE_MAKE_ICS="2048m"
OMP_STACKSIZE_RUN_FCST="2048m"

###############################################################################
