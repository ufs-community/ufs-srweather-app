#
# TEST PURPOSE/DESCRIPTION:
# ------------------------
#
# This test checks the capability of the workflow to use user-defined
# template files.
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

DATA_TABLE_TMPL_FN="data_table"
DIAG_TABLE_TMPL_FN="diag_table"
FIELD_TABLE_TMPL_FN="field_table"
MODEL_CONFIG_TMPL_FN="model_configure"
NEMS_CONFIG_TMPL_FN="nems.configure"
