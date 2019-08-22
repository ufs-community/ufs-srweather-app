#!/bin/bash

set -u
#
#-----------------------------------------------------------------------
#
# Define directories.
#
#-----------------------------------------------------------------------
#
BASEDIR="$(pwd)/../.."
FV3SAR_WFLOW_DIR="$BASEDIR/regional_workflow"
USHDIR="$FV3SAR_WFLOW_DIR/ush"
TESTSDIR="$FV3SAR_WFLOW_DIR/tests"
#
#-----------------------------------------------------------------------
#
# Source useful functions (sort of like a library).
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Check the number of arguments.
#
#-----------------------------------------------------------------------
#
if [ "$#" -ne 1 ]; then

  print_err_msg_exit "\
Script \"$0\":  
Incorrect number of arguments specified.  Usage:

  $0  \${test_suite}

where \${test_suite} is the name of the test suite to run.  Each test 
suite consists of one or more sets of FV3SAR experiment parameter val-
ues.  The values that each parameter will take on in a given test suite
must be specified in a file named \"param_arrays.\${test_suite}.sh\" in the
same directory as this script."

fi
#
#-----------------------------------------------------------------------
#
# Set the name of the test suite.  Then set the name of the file that
# specifies the values that each parameter will take on and check that
# that file exists.
#
#-----------------------------------------------------------------------
#
test_suite=${1:-""}

PARAM_ARRAYS_FN="param_arrays.${test_suite}.sh"
PARAM_ARRAYS_FP="$TESTSDIR/$PARAM_ARRAYS_FN"

if [ ! -f ${PARAM_ARRAYS_FP} ]; then
  print_err_msg_exit "\
Script \"$0\": 
The file specified by PARAM_ARRAYS_FP defining the arrays that specify
the values that each experiment parameter will take on does not exist:
  PARAM_ARRAYS_FP = \"$PARAM_ARRAYS_FP\"
"
else
  . ${PARAM_ARRAYS_FP}
fi
#
#-----------------------------------------------------------------------
#
# Print out information about the test suite to be run.
#
#-----------------------------------------------------------------------
#
all_vals_predef_domain_str=$(printf "\"%s\" " "${all_vals_predef_domain[@]}")
all_vals_grid_gen_method_str=$(printf "\"%s\" " "${all_vals_grid_gen_method[@]}")
all_vals_CCPP_str=$(printf "\"%s\" " "${all_vals_CCPP[@]}")
all_vals_phys_suite_str=$(printf "\"%s\" " "${all_vals_phys_suite[@]}")
all_vals_CDATE_str=$(printf "\"%s\" " "${all_vals_CDATE[@]}")
all_vals_fcst_len_hrs_str=$(printf "\"%s\" " "${all_vals_fcst_len_hrs[@]}")
all_vals_quilting_str=$(printf "\"%s\" " "${all_vals_quilting[@]}")

print_info_msg "\
Creating and launching workflows for test suite:

  test_suite = \"$test_suite\"

The values that each experiment parameter will take on are:

  all_vals_predef_domain = ( $all_vals_predef_domain_str )
  all_vals_grid_gen_method = ( $all_vals_grid_gen_method_str )
  all_vals_CCPP = ( $all_vals_CCPP_str )
  all_vals_phys_suite = ( $all_vals_phys_suite_str )
  all_vals_CDATE = ( $all_vals_CDATE_str )
  all_vals_fcst_len_hrs = ( $all_vals_fcst_len_hrs_str )
  all_vals_quilting = ( $all_vals_quilting_str )"
#
#-----------------------------------------------------------------------
#
# Loop through all possible combinations of the specified parameter val-
# ues and create and run a workflow for each combination.
#
#-----------------------------------------------------------------------
#
for predef_domain in "${all_vals_predef_domain[@]}"; do
  for grid_gen_method in "${all_vals_grid_gen_method[@]}"; do
    for CCPP in "${all_vals_CCPP[@]}"; do
      for phys_suite in "${all_vals_phys_suite[@]}"; do
        for CDATE in "${all_vals_CDATE[@]}"; do
          for quilting in "${all_vals_quilting[@]}"; do
            for fcst_len_hrs in "${all_vals_fcst_len_hrs[@]}"; do
#
# In the call to the run_one_expt.sh script below, we place each varia-
# ble being passed in as an argument in double quotes.  This ensures 
# that empty variables are still recognized as arguments by the script
# (instead of being skipped over).
#
  ./run_one_expt.sh \
  "$predef_domain" \
  "$grid_gen_method" \
  "$CCPP" \
  "$phys_suite" \
  "$CDATE" \
  "$fcst_len_hrs" \
  "$quilting"

            done
          done
        done
      done
    done
  done
done


