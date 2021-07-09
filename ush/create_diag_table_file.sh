#
#-----------------------------------------------------------------------
#
# This file defines a function that creates a diagnostic table file for
# each cycle to be run.
#
#-----------------------------------------------------------------------
#
function create_diag_table_file() {
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
  { save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
  local scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
  local scrfunc_fn=$( basename "${scrfunc_fp}" )
  local scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
  local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then
# process the arguments provided to this script/function (which should
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
    "run_dir" \
    )
  process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
  print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local i \
        diag_table_fp \
        settings
#
#-----------------------------------------------------------------------
#
# Create a diagnostics table file within the specified run directory.
#
#-----------------------------------------------------------------------
#
  print_info_msg "$VERBOSE" "                                            
Creating a diagnostics table file (\"${DIAG_TABLE_FN}\") in the specified
run directory...

  run_dir = \"${run_dir}\""

    diag_table_fp="${run_dir}/${DIAG_TABLE_FN}"
    print_info_msg "$VERBOSE" "

Using the template diagnostics table file:

    diag_table_tmpl_fp = ${DIAG_TABLE_TMPL_FP}

to create:

    diag_table_fp = \"${diag_table_fp}\""

    settings="
starttime: !datetime ${CDATE}
cres: ${CRES}"

    $USHDIR/fill_jinja_template.py -q -u "${settings}" -t "${DIAG_TABLE_TMPL_FP}" -o "${diag_table_fp}" || \
    print_err_msg_exit "
!!!!!!!!!!!!!!!!!

fill_jinja_template.py failed!

!!!!!!!!!!!!!!!!!
"

#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

