#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test is to ensure that the workflow running in community mode 
# completes successfully on the GSD_HRRR_AK_50km grid using the GSD_SAR 
# physics suite with ICs and LBCs derived from the RAP.
#
# Note that this test specifies computational resource parameters for 
# the MAKE_ICS_TN, MAKE_LBCS_TN, and RUN_POST_TN rocoto tasks in order 
# allow the chgres_cube and UPP codes to complete these tasks successfully
# on this very coarse grid.
#

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="GSD_HRRR_AK_50km"
CCPP_PHYS_SUITE="FV3_GSD_SAR"

EXTRN_MDL_NAME_ICS="RAP"
EXTRN_MDL_NAME_LBCS="RAP"
USE_USER_STAGED_EXTRN_FILES="TRUE"

DATE_FIRST_CYCL="20190520"
DATE_LAST_CYCL="20190520"
CYCL_HRS=( "00" )

FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="6"
#
# For a coarse grid such as this, the number of MPI processes (= NNODES*PPN) 
# can't be too large for the make_ics and make_lbcs tasks (both of which 
# use chgres_cube); otherwise, the chgres_cube code will fail.
#
NNODES_MAKE_ICS="1"
PPN_MAKE_ICS="12"
WTIME_MAKE_ICS="00:30:00"

NNODES_MAKE_LBCS="1"
PPN_MAKE_LBCS="12"
WTIME_MAKE_LBCS="00:30:00"
#
# For a coarse grid such as this, the number of MPI processes (= NNODES*PPN) 
# can't be too large for the run_post metatask (which uses the UPP code); 
# otherwise, the UPP code will fail.
#
NNODES_RUN_POST="1"
PPN_RUN_POST="12"
WTIME_RUN_POST="00:30:00"
