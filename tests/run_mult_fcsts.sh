#!/bin/sh -l

#
#-----------------------------------------------------------------------
#
# Define directories.
#
#-----------------------------------------------------------------------
#
BASEDIR="/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM"
USHDIR="$BASEDIR/fv3sar_workflow/ush"
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
# Check arguments.
#
#-----------------------------------------------------------------------
#
if [ "$#" -ne 1 ]; then

  print_err_msg_exit "\
Script \"$0\":  Incorrect number of arguments specified.
Usage:

  $0  test_suite

where test_suite is the name of the test suite to run.  A test suite 
consists of one or more sets of FV3SAR experiment input parameters.  Va-
lid values of 
See
this script for valid values for test_suite."

fi
#
#-----------------------------------------------------------------------
#
# Set the name of the test suite and arrays containing all possible val-
# ues for each parameter.  These will be narrowed down later below de-
# pending on the test suite specified.
#
#-----------------------------------------------------------------------
#
test_suite=$1

predef_domains=( "RAP" "HRRR" )
grid_gen_methods=( "GFDLgrid" "JPgrid" )
ccpp_tf=( "true" "false" )
phys_suites=( "GFS" "GSD" )
cdates=( "2017090700" )
fcst_lens=( "6" )
quilting_tf=( "true" "false" )
#
#-----------------------------------------------------------------------
#
# Depending on the test suite specified, reset one or more of the para-
# meter arrays above.
#
#-----------------------------------------------------------------------
#
case $test_suite in
#
  RAP)
  predef_domains=( "RAP" )
  ;;
#
  HRRR)
  predef_domains=( "HRRR" )
  ;;
#
  GFDLgrid)
  grid_gen_methods=( "GFDLgrid" )
  ;;
#
  JPgrid)
  grid_gen_methods=( "JPgrid" )
  ;;
#
  with_CCPP)
  ccpp_tf=( "true" )
  ;;
#
  no_CCPP)
  ccpp_tf=( "false" )
  phys_suites=( "GFS" )  # Without CCPP, the only physics suite we can run is GFS.
  ;;
#
  GFSphys)
  phys_suites=( "GFS" )
  ;;
#
  GSDphys)
  ccpp_tf=( "true" )  # We can run the GSD physics suite only if CCPP is enabled.
  phys_suites=( "GSD" )
  ;;
#
  GFSphys_noCCPP)
  ccpp_tf=( "false" )
  phys_suites=( "GFS" )
  ;;
#
  GFSphys_withCCPP)
  ccpp_tf=( "true" )
  phys_suites=( "GFS" )
  ;;
#
  all)
  ;;
#
  custom)
#
#  predef_domains=( "RAP" )
  predef_domains=( "HRRR" )
#
#  grid_gen_methods=( "GFDLgrid" )
  grid_gen_methods=( "JPgrid" )
#
  ccpp_tf=( "true" )
#  ccpp_tf=( "false" )
#
#  phys_suites=( "GFS" )
  phys_suites=( "GSD" )
#
  cdates=( "2017090700" )
#
  fcst_lens=( "6" )
  quilting_tf=( "true" )
#
#  echo
#  echo "For test_suite set to \"custom\", set the parameters of the"
#  echo "test suite in the \"custom\" section of the case statement."
#  echo "in this script.  Then remove the following \"exit\" statement"
#  echo "and rerun."
#  echo "Exiting script."
#  exit 1;
  ;;
#
  *)
  print_err_msg_exit "\
Disallowed value for test_suite:
  test_suite = \"${test_suite}\"
Check script for allowed values."
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Print out information about the test suite to be run.
#
#-----------------------------------------------------------------------
#
predef_domains_str=$(printf "\"%s\" " "${predef_domains[@]}")
grid_gen_methods_str=$(printf "\"%s\" " "${grid_gen_methods[@]}")
ccpp_tf_str=$(printf "\"%s\" " "${ccpp_tf[@]}")
phys_suites_str=$(printf "\"%s\" " "${phys_suites[@]}")
cdates_str=$(printf "\"%s\" " "${cdates[@]}")
fcst_lens_str=$(printf "\"%s\" " "${fcst_lens[@]}")
quilting_tf_str=$(printf "\"%s\" " "${quilting_tf[@]}")

print_info_msg "\
Creating and launching workflows for test suite:

  test_suite = \"$test_suite\"

Parameter combinations for this test suite consist of:

  predef_domains = ( $predef_domains_str )
  grid_gen_methods = ( $grid_gen_methods_str )
  ccpp_tf = ( $ccpp_tf_str )
  phys_suites = ( $phys_suites_str )
  cdates = ( $cdates_str )
  fcst_lens = ( $fcst_lens_str )
  quilting_tf = ( $quilting_tf_str )"
#
#-----------------------------------------------------------------------
#
# Loop through all possible combinations of the specified parameters and
# create and run a workflow for each.
#
#-----------------------------------------------------------------------
#
for predef_domain in "${predef_domains[@]}"; do
  for grid_gen_method in "${grid_gen_methods[@]}"; do
    for CCPP in "${ccpp_tf[@]}"; do
      for CCPP_phys_suite in "${phys_suites[@]}"; do
        for CDATE in "${cdates[@]}"; do
          for quilting in "${quilting_tf[@]}"; do
            for fcst_len_hrs in "${fcst_lens[@]}"; do
#
# Can't run GSD physics without CCPP, so skip over that combination.
#
if [ $CCPP = "false" ] && [ $CCPP_phys_suite = "GSD" ]; then

  echo
  echo "The GSD physics suite cannot be run without CCPP:"
  echo "  CCPP = \"${CCPP}\""
  echo "  CCPP_phys_suite = \"${CCPP_phys_suite}\""
  echo "Skipping this test."
  continue  

else
#
# Note that in the call to the run_one_fcst.sh script below, we place 
# each variable being passed in as an argument in double quotes.  This
# ensures that empty variables are still recognized as arguments by the
# script (instead of being skipped over).
#
  ./run_one_fcst.sh \
  "$BASEDIR" \
  "$predef_domain" \
  "$grid_gen_method" \
  "$CCPP" \
  "$CCPP_phys_suite" \
  "$CDATE" \
  "$fcst_len_hrs" \
  "$quilting"

fi

            done
          done
        done
      done
    done
  done
done


