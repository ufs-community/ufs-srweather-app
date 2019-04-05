#
#-----------------------------------------------------------------------
#
# Set the location to look for the sourced function definition files.
#
#-----------------------------------------------------------------------
#
#FUNCS_DIR=${USHDIR:-"."}
FUNCS_DIR=${FUNCS_DIR:-${USHDIR:-"."}}
#
#-----------------------------------------------------------------------
#
# Source the file containing functions to save and restore shell op-
# tions.
#
#-----------------------------------------------------------------------
#
. ${FUNCS_DIR}/save_restore_shell_opts.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the functions that print out messages.
#
#-----------------------------------------------------------------------
#
. ${FUNCS_DIR}/print_msg.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that replaces variable values
# (or value placeholders) in several types of files (e.g. Fortran name-
# list files) with actual values.
#
#-----------------------------------------------------------------------
#
. ${FUNCS_DIR}/set_file_param.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that checks for preexisting 
# directories and handles them according to the setting of the variable
# preexisting_dir_method [which is specified in the configuration 
# script(s)].
#
#-----------------------------------------------------------------------
#
. ${FUNCS_DIR}/check_for_preexist_dir.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing functions that execute filesystem commands
# (e.g. "cp", "mv") with verification (i.e. verifying that the commands
# completed successfully).
#
#-----------------------------------------------------------------------
#
. ${FUNCS_DIR}/filesys_cmds_vrfy.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that searches an array for a
# specified string.
#
#-----------------------------------------------------------------------
#
. ${FUNCS_DIR}/iselementof.sh
#
#-----------------------------------------------------------------------
#
# Source the file containing the function that interpolates (or extrapo-
# lates) a grid cell size-dependent property to an arbitrary global 
# cubed-sphere resolution.
#
#-----------------------------------------------------------------------
#
. ${FUNCS_DIR}/interpol_to_arbit_CRES.sh

