#
# MACHINE will be set by the workflow launch script (launch_FV3SAR_-
# wflow.sh) to value passed in as an argument to that script.
#
MACHINE=""
#
# ACCOUNT will be set by the workflow launch script (launch_FV3SAR_-
# wflow.sh) to value passed in as an argument to that script.
#
ACCOUNT=""
#
# EXPT_SUBDIR will be set by the workflow launch script (launch_FV3SAR_-
# wflow.sh) to a value obtained from the name of this file.
#
EXPT_SUBDIR=""
#
# USE_CRON_TO_RELAUNCH may be reset by the workflow launch script
# (launch_FV3SAR_wflow.sh) to value passed in as an argument to that
# script, but in case it is not, we give it a default value here.
#
USE_CRON_TO_RELAUNCH="TRUE"
#
# CRON_RELAUNCH_INTVL_MNTS may be reset by the workflow launch script
# (launch_FV3SAR_wflow.sh) to value passed in as an argument to that
# script, but in case it is not, we give it a default value here.
#
CRON_RELAUNCH_INTVL_MNTS="02"


QUEUE_DEFAULT="batch"
QUEUE_HPSS="service"
QUEUE_FCST="batch"

VERBOSE="TRUE"

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="GSD_RAP13km"
GRID_GEN_METHOD="JPgrid"
QUILTING="TRUE"
USE_CCPP="TRUE"
CCPP_PHYS_SUITE="FV3_GSD_v0"
FCST_LEN_HRS="06"
LBC_SPEC_INTVL_HRS="3"

DATE_FIRST_CYCL="20190701"
DATE_LAST_CYCL="20190701"
CYCL_HRS=( "00" )

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"

RUN_TASK_MAKE_GRID="TRUE"
RUN_TASK_MAKE_OROG="TRUE"
RUN_TASK_MAKE_SFC_CLIMO="TRUE"

