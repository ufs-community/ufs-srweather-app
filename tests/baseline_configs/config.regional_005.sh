#
# The values of the variables MACHINE, ACCOUNT, and EXPT_SUBDIR are required
# inputs to the script that launces the WE2E test experiments.  That script 
# will use those inputs to fill in the values of these variables below.
#
MACHINE=""
ACCOUNT=""
EXPT_SUBDIR=""
#
# The values of the variables USE_CRON_TO_RELAUNCH and CRON_RELAUNCH_INTVL_MNTS
# are optional inputs to the script that launces the WE2E test experiments.  
# If one or both of these values are specified, then that script will 
# replace the default values of these variables below with those values.
# Otherwise, it will keep the default values.
#
USE_CRON_TO_RELAUNCH="TRUE"
CRON_RELAUNCH_INTVL_MNTS="02"


QUEUE_DEFAULT="batch"
QUEUE_HPSS="service"
QUEUE_FCST="batch"

VERBOSE="TRUE"

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="GSD_HRRR_AK_50km"
GRID_GEN_METHOD="JPgrid"
QUILTING="TRUE"
USE_CCPP="TRUE"
CCPP_PHYS_SUITE="FV3_GSD_SAR"
FCST_LEN_HRS="06"
LBC_SPEC_INTVL_HRS="6"

DATE_FIRST_CYCL="20190520"
DATE_LAST_CYCL="20190520"
CYCL_HRS=( "00" )

EXTRN_MDL_NAME_ICS="RAPX"
EXTRN_MDL_NAME_LBCS="RAPX"

RUN_TASK_MAKE_GRID="TRUE"
RUN_TASK_MAKE_OROG="TRUE"
RUN_TASK_MAKE_SFC_CLIMO="TRUE"

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


