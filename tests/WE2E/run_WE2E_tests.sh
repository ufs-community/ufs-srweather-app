#!/bin/bash 

#
#-----------------------------------------------------------------------
#
# This script runs the specified WE2E tests.  Type
#
#   run_WE2E_tests.sh --help
#
# for a full description of how to use this script.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script or function is 
# located (scrfunc_fp), the name of that file (scrfunc_fn), and the 
# directory in which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Set the full path to the top-level directory of the regional_workflow 
# repository.  We denote this path by homerrfs.  The current script 
# should be located in the "tests/WE2E" subdirectory under this directory.
# Thus, homerrfs is the directory two levels above the directory in which 
# the current script is located.
#
#-----------------------------------------------------------------------
#
homerrfs=${scrfunc_dir%/*/*}
#
#-----------------------------------------------------------------------
#
# Set other directories that depend on homerrfs.
#
#-----------------------------------------------------------------------
#
ushdir="$homerrfs/ush"
testsdir="$homerrfs/tests"
WE2Edir="$testsdir/WE2E"
#
#-----------------------------------------------------------------------
#
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
. $ushdir/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Source other needed files.
#
#-----------------------------------------------------------------------
#
. ${WE2Edir}/get_WE2Etest_names_subdirs_descs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script or function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Set the usage message.
#
#-----------------------------------------------------------------------
#
usage_str="\
Usage:

  ${scrfunc_fn} \\
    tests_file=\"...\" \\
    machine=\"...\" \\
    account=\"...\" \\
    [expt_basedir=\"...\"] \\
    [use_cron_to_relaunch=\"...\"] \\
    [cron_relaunch_intvl_mnts=\"...\"] \\
    [verbose=\"...\"] \\
    [stmp=\"...\"] \\
    [ptmp=\"...\"]

The arguments in brackets are optional.  The arguments are defined as 
follows:

tests_file:
Name of file or relative or absolute path to file containing the list of
WE2E tests to run.  This file must contain one test name per line, with 
no repeated names.  This is a required argument.

machine:
Argument used to explicitly set the experiment variable MACHINE in the
experiment configuration files of all the WE2E tests the user wants to 
run.  (A description of MACHINE can be found in the default experiment 
configuration file.)  This is a required argument.

account:
Argument used to explicitly set the experiment variable ACCOUNT in the
experiment configuration files of all the WE2E tests the user wants to 
run.  (A description of ACCOUNT can be found in the default experiment 
configuration file.)  This is a required argument.

expt_basedir:
Argument used to explicitly set the experiment variable EXPT_BASEDIR in 
the experiment configuration files of all the WE2E tests the user wants
to run.  (A description of EXPT_BASEDIR can be found in the default 
experiment configuration file.)  If expt_basedir is specified in the call 
to this script, its value is used to set EXPT_BASEDIR in the configuration 
files.  If it is not specified, EXPT_BASEDIR is not set in the configuration 
files, in which case the workflow generation script sets it to a default 
value.  Note that if expt_basedir is set to a relative path (e.g. 
expt_basedir=\"testset1\" in the call to this script), then the workflow 
generation script will set EXPT_BASEDIR for the experiment to a default 
absolute path followed by \${expt_basedir}.  This feature can be used to 
group the WE2E tests into subdirectories for convenience, e.g. a set of 
tests under subdirectory testset1, another set of tests under testset2, 
etc.

use_cron_to_relaunch:
Argument used to explicitly set the experiment variable USE_CRON_TO_RELAUNCH
in the experiment configuration files of all the WE2E tests the user wants 
to run.  (A description of USE_CRON_TO_RELAUNCH can be found in the default 
experiment configuration file.)  If use_cron_to_relaunch is specified in 
the call to this script, its value is used to set USE_CRON_TO_RELAUNCH 
in the configuration files.  If it is not specified, USE_CRON_TO_RELAUNCH 
is set to \"TRUE\" in the configuration files, in which case cron jobs 
are used to (re)launch the workflows for all tests (one cron job per test).  
Thus, use_cron_to_relaunch needs to be specified only if the user wants 
to turn off use of cron jobs for all tests (by specifying use_cron_to_relaunch=
\"FALSE\" on the command line).  Note that it is not possible to specify 
a different value for USE_CRON_TO_RELAUNCH for each test via this argument; 
either all tests use cron jobs or none do.

cron_relaunch_intvl_mnts:
Argument used to explicitly set the experiment variable CRON_RELAUNCH_INTVL_MNTS
in the experiment configuration files of all the WE2E tests the user wants 
to run.  (A description of CRON_RELAUNCH_INTVL_MNTS can be found in the 
default experiment configuration file.)  If cron_relaunch_intvl_mnts is 
specified in the call to this script, its value is used to set 
CRON_RELAUNCH_INTVL_MNTS in the configuration files.  If it is not 
specified, CRON_RELAUNCH_INTVL_MNTS is set to \"02\" (i.e. two minutes) 
in the configuration files.  Note that it is not possible to specify a 
different value for CRON_RELAUNCH_INTVL_MNTS for each test via this 
argument; all tests will use the same value for USE_CRON_TO_RELAUNCH 
(either the value specified in the call to this script or the default 
value of \"02\").  Note also that the value of this argument matters only 
if the argument use_cron_to_relaunch is not explicitly set to \"FALSE\" 
in the call to this script.

verbose:
Argument used to explicitly set the experiment variable VERBOSE in the
experiment configuration files of all the WE2E tests the user wants to
run.  (A description of VERBOSE can be found in the default experiment 
configuration file.)  If verbose is specified in the call to this script, 
its value is used to set VERBOSE in the configuration files.  If it is 
not specified, VERBOSE is set to \"TRUE\" in the configuration files.
Note that it is not possible to specify a different value for VERBOSE 
for each test via this argument; either all tests will have VERBOSE set 
to \"TRUE\" or all will have it set to \"FALSE\".

stmp:
Argument used to explicitly set the experiment variable STMP in the 
experiment configuration files of all the WE2E tests the user wants to 
run that are in NCO mode, i.e. they have test configuration files that
set the experiment variable RUN_ENVIR to \"nco\".  (A description of 
STMP can be found in the default experiment configuration file.)  If 
stmp is specified in the call to this script, its value is used to set 
STMP in the configuration files of all tests that will run in NCO mode.  
If it is not specified, STMP is (effectively) set as follows in the 
configuration files (of all NCO mode tests to be run):

    STMP=\$( readlink -f \"\$homerrfs/../../nco_dirs/stmp\" \)

Here, homerrfs is the base directory in which the regional_workflow
repository is cloned.  Note that it is not possible to specify a different 
value for STMP for each test via this argument; all tests will use the
same value for STMP (either the value specified in the call to this 
script or the default value above).  Note also that the value of this 
argument is not used for any tests that are not in NCO mode.

ptmp:
Same as the argument \"stmp\" described above but for setting the 
experiment variable PTMP for all tests that will run in NCO mode.
"
#
#-----------------------------------------------------------------------
#
# Check to see if usage help for this script is being requested.  If so,
# print it out and exit with a 0 exit code (success).
#
#-----------------------------------------------------------------------
#
help_flag="--help"
if [ "$#" -eq 1 ] && [ "$1" = "${help_flag}" ]; then
  print_info_msg "${usage_str}"
  exit 0
fi
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script or function.
# Then process the arguments provided to it on the command line (which
# should consist of a set of name-value pairs of the form arg1="value1", 
# arg2="value2", etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
  "tests_file" \
  "machine" \
  "account" \
  "expt_basedir" \
  "use_cron_to_relaunch" \
  "cron_relaunch_intvl_mnts" \
  "verbose" \
  "stmp" \
  "ptmp" \
  )
process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# "TRUE".
#
#-----------------------------------------------------------------------
#
print_input_args "valid_args"
#
#-----------------------------------------------------------------------
#
# Verify that the required arguments to this script have been specified.
# If not, print out an error message and exit.
#
#-----------------------------------------------------------------------
#
help_msg="\
Use
  ${scrfunc_fn} ${help_flag}
to get help on how to use this script."

if [ -z "${tests_file}" ]; then
  print_err_msg_exit "\
The argument \"tests_file\" specifying the file containing a list of the 
WE2E tests to run was not specified in the call to this script.  \
${help_msg}"
fi

if [ -z "${machine}" ]; then
  print_err_msg_exit "\
The argument \"machine\" specifying the machine or platform on which to
run the WE2E tests was not specified in the call to this script.  \
${help_msg}"
fi

if [ -z "${account}" ]; then
  print_err_msg_exit "\
The argument \"account\" specifying the account under which to submit 
jobs to the queue when running the WE2E tests was not specified in the 
call to this script.  \
${help_msg}"
fi
#
#-----------------------------------------------------------------------
#
# Get the full path to the file containing the list of user-specified 
# WE2E tests to run.  Then verify that the file exists.
#
#-----------------------------------------------------------------------
#
user_spec_tests_fp=$( readlink -f "${tests_file}" )

if [ ! -f "${user_spec_tests_fp}" ]; then
  print_err_msg_exit "\
The file containing the user-specified list of WE2E tests to run 
(tests_file) that is passed in as an argument to this script does not
exit:
  tests_file = \"${tests_file}\"
The full path to this script is:
  user_spec_tests_fp = \"${user_spec_tests_fp}\"
Please ensure that this file exists and rerun."
fi
#
#-----------------------------------------------------------------------
#
# Read in each line of the file specified by user_spec_tests_fp and add 
# each non-empty line to the array user_spec_tests.  Note that the read 
# command will remove any leading and trailing whitespace from each line 
# in user_spec_tests_fp [because it treats whatever character(s) the bash 
# variable IFS (Internal Field Separator) is set to as word separators 
# on each line, and IFS is by default set to a space, a tab, and a 
# newline].
#
#-----------------------------------------------------------------------
#
user_spec_tests=()
while read -r line; do
  if [ ! -z "$line" ]; then
    user_spec_tests+=("$line")
  fi
done < "${user_spec_tests_fp}"
#
#-----------------------------------------------------------------------
#
# Call a function to obtain the names of all available WE2E tests (i.e. 
# not just the ones the user wants to run but all that are part of the 
# WE2E testing system), the test IDs, and the category subdirectory in 
# which each corresponding test configuration file is located.  
#
# The array of test names (avail_WE2E_test_names) that the function 
# called below returns contains both primary and alternate test names.  
# A primary test name is a test name obtained from the name of a WE2E 
# test configuration file that is an ordinary file, i.e. not a symlink, 
# whereas an alternate name is one that is derived from the name of a 
# symlink whose target is an ordinary test configuration file (but not
# another symlink).  To be able to determine the set of test names that 
# correspond to the same primary test, the function called also returns 
# an array of test IDs (avail_WE2E_test_IDs) such that the IDs for a 
# primary test name and all the alternate names that map to it (if any) 
# are the same.  These IDs will be used later below to ensure that the 
# user does not list in the set of test names to run a given test more 
# than once, e.g. by accidentally including in the list its primary name 
# as well as one of its alternate names.
#
# The category subdirectories in the array avail_WE2E_test_subdirs 
# returned by the function called below are relative to the base 
# directory under which the WE2E test configuration files are located.
# This base directory is set by the function call below and is returned
# in the output variable avail_WE2E_test_configs_basedir.  The i-th 
# element of avail_WE2E_test_subdirs specifies the subdirectory under 
# this base directory that contains the ordinary test configuration file 
# (for a primary test name) or the symlink (for an alternate test name) 
# corresponding to the i-th element (which may be a primary or alternate 
# test name) in avail_WE2E_test_names.  We refer to these subdirectories 
# as "category" subdirectories because they are used for clarity to group 
# the WE2E tests into types or categories.
#
# Finally, note that the returned arrays 
#
#   avail_WE2E_test_names
#   avail_WE2E_test_ids
#   avail_WE2E_test_subdirs
#
# are sorted in order of increasing test ID and such that for a given 
# set of test names that share the same ID, the primary test name is 
# listed first followed by zero or more alternate names.  As an example,
# assume that there are three category subdirectories under the base
# directory specified by avail_WE2E_test_configs_basedir: dir1, dir2, 
# and dir3.  Also, assume that dir1 contains a test configuration file 
# named config.primary_name.sh that is an ordinary file, and dir2 and dir3 
# contain the following symlinks that point config.primary_name.sh:
#
#   ${avail_WE2E_test_configs_basedir}/dir2/config.alt_name_1.sh 
#     --> ${avail_WE2E_test_configs_basedir}/dir1/config.primary_name.sh
#
#   ${avail_WE2E_test_configs_basedir}/dir3/config.alt_name_2.sh
#     --> ${avail_WE2E_test_configs_basedir}/dir1/config.primary_name.sh
#
# Finally, assume that the ID of the test primary_name is 21 and that
# this ID is at indices 7, 8, and 9 in avail_WE2E_test_ids.  Then indices
# 7, 8, and 9 of the three arrays returned by the function call below
# may be as follows:
#
#   avail_WE2E_test_names[7]="primary_name"
#   avail_WE2E_test_names[8]="alt_name_1"
#   avail_WE2E_test_names[9]="alt_name_2"
#
#   avail_WE2E_test_ids[7]="21"
#   avail_WE2E_test_ids[8]="21"
#   avail_WE2E_test_ids[9]="21"
#
#   avail_WE2E_test_subdirs[7]="dir1"
#   avail_WE2E_test_subdirs[8]="dir2"
#   avail_WE2E_test_subdirs[9]="dir3"
#   
#-----------------------------------------------------------------------
#
print_info_msg "
Getting information about all available WE2E tests..."

get_WE2Etest_names_subdirs_descs \
  WE2Edir="${WE2Edir}" \
  output_varname_test_configs_basedir="avail_WE2E_test_configs_basedir" \
  output_varname_test_names="avail_WE2E_test_names" \
  output_varname_test_subdirs="avail_WE2E_test_subdirs" \
  output_varname_test_ids="avail_WE2E_test_ids"
#
# Get the total number of available WE2E test names (including alternate
# names).
#
num_avail_WE2E_tests="${#avail_WE2E_test_names[@]}"
#
#-----------------------------------------------------------------------
#
# Loop through the elements of the array user_spec_tests and perform
# sanity checks.  For each such element (i.e. for each WE2E test to run 
# specified by the user), make sure that:
#
# 1) The name of the test exists in the complete list of available WE2E
#    tests in avail_WE2E_test_names.
# 2) The test does not have an ID that is identical to a previously 
#    considered test in the user-specified list of tests to run (because
#    if so, it would be identical to that previously considered test,
#    and it would be a waste of computational resources to run). 
#
# If these requirements are met, add the test name to the list of tests 
# to run in the array names_tests_to_run, and add the test's category 
# subdirectory to subdirs_tests_to_run.
#
#-----------------------------------------------------------------------
#
print_info_msg "
Performing sanity checks on user-specified list of WE2E tests to run..."

names_tests_to_run=()
ids_tests_to_run=()
subdirs_tests_to_run=()
#
# Initialize the array that will contain the remaining available WE2E
# test names (including alternate names, if any) after finding a match
# for the i-th user-specified test name to run in user_spec_tests.
#
remaining_avail_WE2E_test_names=( "${avail_WE2E_test_names[@]}" )

num_user_spec_tests="${#user_spec_tests[@]}"
for (( i=0; i<=$((num_user_spec_tests-1)); i++ )); do

  user_spec_test="${user_spec_tests[$i]}"

  print_info_msg "\
  Checking user-specified WE2E test:  \"${user_spec_test}\""
#
# For the current user-specified WE2E test (user_spec_test), loop through 
# the list of all remaining available WE2E test names (i.e. the ones that 
# haven't yet been matched to any of the user-specified test names to 
# run) and make sure that:
#
# 1) The name of the test exists (either as a primary test name or an
#    alternate test name) in the list of all available WE2E test names.
# 2) The test is not repeated in the user-specified list of tests to run, 
#    either under the same name or an alternate name (i.e. make sure that
#    it does not have the same test ID as a previously considered test).
# 
# Note that in the loop below, the index j gets set to only those elements
# of remaining_avail_WE2E_test_names that are defined [the syntax 
# "${!some_array[@]}" expands to the indices of some_array that have 
# defined elements].  We do this for efficiency; we unset elements of 
# remaining_avail_WE2E_test_names that have already been matched with 
# one of the user-specified test names to run because we know that any
# remaining user-specified test names will not match those elements.
#
  match_found="FALSE"
  for j in "${!remaining_avail_WE2E_test_names[@]}"; do

    test_name="${avail_WE2E_test_names[$j]}"
    test_id="${avail_WE2E_test_ids[$j]}"
#
# Check whether the name of the current user-specified test (user_spec_test) 
# matches any of the names in the full list of WE2E tests.  If so:
#
# 1) Set match_found to "TRUE".
# 2) Make sure that the test to run doesn't have a test ID that is 
#    identical to a previously considered test in the user-specified 
#    list of tests to run (which would mean the two tests are identical).
#    If so, print out an error message and exit.
# 
    if [ "${test_name}" = "${user_spec_test}" ]; then

      match_found="TRUE"

      is_element_of "ids_tests_to_run" "${test_id}" && {

        user_spec_tests_str=$(printf "    \"%s\"\n" "${user_spec_tests[@]}")
        user_spec_tests_str=$(printf "(\n%s\n    )" "${user_spec_tests_str}")

        all_names_for_test=()
        for (( k=0; k<=$((num_avail_WE2E_tests-1)); k++ )); do
          if [ "${avail_WE2E_test_ids[$k]}" = "${test_id}" ]; then
            all_names_for_test+=("${avail_WE2E_test_names[$k]}")
          fi
        done
        all_names_for_test_str=$(printf "  \"%s\"\n" "${all_names_for_test[@]}")

        print_err_msg_exit "\
The current user-specified test to run (user_spec_test) is already included 
in the list of tests to run (user_spec_tests), either under the same name 
or an alternate name:
  user_spec_test = \"${user_spec_test}\"
  user_spec_tests = ${user_spec_tests_str}
This test has the following primary and possible alternate names:
${all_names_for_test_str}
In order to avoid repeating the same WE2E test (and thus waste computational 
resources), only one of these test names can be specified in the list of 
tests to run.  Please modify this list in the file
  user_spec_tests_fp = \"${user_spec_tests_fp}\"
accordingly and rerun."

      }
#
# Append the name of the current user-specified test, its ID, and its
# category subdirectory to the arrays that contain the sanity-checked 
# versions of of these quantities.  
#
      names_tests_to_run+=("${user_spec_test}")
      ids_tests_to_run+=("${test_id}")
      subdirs_tests_to_run+=("${avail_WE2E_test_subdirs[$j]}")
# 
# Remove the j-th element of remaining_avail_WE2E_test_names so that for
# the next user-specified test to run, we do not need to check whether
# the j-th test is a match.  Then break out of the loop over all remaining
# available WE2E tests.
#
      unset remaining_avail_WE2E_test_names[$j]
      break

    fi

  done
#
# If match_found is still "FALSE" after exiting the loop above, then a
# match for the current user-specifed test to run was not found in the 
# list of all WE2E tests -- neither as a primary test name nor as an 
# alternate name.  In this case, print out an error message and exit.
#
  if [ "${match_found}" = "FALSE" ]; then
    avail_WE2E_test_names_str=$( printf "  \"%s\"\n" "${avail_WE2E_test_names[@]}" )
    print_err_msg_exit "\
The name current user-specified test to run (user_spec_test) does not 
match any of the names (either primary or alternate) of the available
WE2E tests:
  user_spec_test = \"${user_spec_test}\"
Valid values for user_spec_test consist of the names (primary or alternate)
of the available WE2E tests, which are:
${avail_WE2E_test_names_str}
Each name in the user-specified list of tests to run:
  1) Must match one of the (primary or alternate) test names of the 
     availabe WE2E tests.
  2) Must not be the primary or alternate name of a test that has its
     primary or one of its alternate names already included in the user-
     specified list of test to run, i.e. tests must not be repeated (in
     order not to waste computational resources).
Please modify the user-specified list of tests to run such that it adheres 
to the rules above and rerun.  This list is in the file specified by the
input variable tests_file:
  tests_file = \"${tests_file}\"
The full path to this file is:
  user_spec_tests_fp = \"${user_spec_tests_fp}\""
  fi

done
#
#-----------------------------------------------------------------------
#
# Get the number of WE2E tests to run and print out an informational
# message.
#
#-----------------------------------------------------------------------
#
num_tests_to_run="${#names_tests_to_run[@]}"
tests_to_run_str=$( printf "  \'%s\'\n" "${names_tests_to_run[@]}" )
print_info_msg "
After processing the user-specified list of WE2E tests to run, the number 
of tests to run (num_tests_to_run) is
  num_tests_to_run = ${num_tests_to_run}
and the list of WE2E tests to run (one test per line) is
${tests_to_run_str}"
#
#-----------------------------------------------------------------------
#
# Loop through the WE2E tests to run.  For each test, use the corresponding
# test configuration file to generate a temporary experiment file and
# launch the experiment generation script using that file.
#
#-----------------------------------------------------------------------
#
for (( i=0; i<=$((num_tests_to_run-1)); i++ )); do

  test_name="${names_tests_to_run[$i]}"
  test_subdir="${subdirs_tests_to_run[$i]}"
#
# Generate the full path to the current WE2E test's configuration file.
# Then ensure that this file exists.
#
  test_config_fp="${avail_WE2E_test_configs_basedir}/${test_subdir}/config.${test_name}.sh"

  if [ ! -f "${test_config_fp}" ]; then
    print_err_msg_exit "\
The experiment configuration file (test_config_fp) for the current WE2E
test (test_name) does not exist:
  test_name = \"${test_name}\"
  test_config_fp = \"${test_config_fp}\"
Please correct and rerun."
  fi
#
#-----------------------------------------------------------------------
#
# Source the default experiment configuration file to set values of 
# various experiment variables to their defaults.  Then source the 
# current WE2E test's configuration file to overwrite certain variables' 
# default values with test-specific ones.
#
#-----------------------------------------------------------------------
#
  . ${ushdir}/config_defaults.sh
  . ${test_config_fp}
#
#-----------------------------------------------------------------------
#
# We will now construct a multiline variable consisting of the contents 
# that we want the experiment configuration file for this WE2E test to
# have.  Once this variable is constructed, we will write its contents
# to the generic configuration file that the experiment generation script
# reads in (specified by the variable EXPT_CONFIG_FN in the default 
# configuration file config_defaults.sh sourced above) and then run that
# script to generate an experiment for the current WE2E test.
#
# We name the multiline variable that will contain the contents of the
# experiment configuration file "expt_config_str" (short for "experiment
# configuration string").  Here, we initialize this to a null string,
# and we append to it later below.
#
#-----------------------------------------------------------------------
# 
  expt_config_str=""
#
#-----------------------------------------------------------------------
#
# Set (and then write to expt_config_str) various experiment variables 
# that depend on the input arguments to this script (as opposed to 
# variable settings in the test configuration file specified by 
# test_config_fp).  Note that any values of these parameters specified 
# in the default experiment configuration file (config_defaults.sh) 
# or in the test configuraiton file (test_config_fp) that were sourced 
# above will be overwritten by the settings below.
#
# Note also that if EXPT_BASEDIR ends up getting set to a null string, 
# the experiment generation script that gets called further below will 
# set it to a default path; if it gets set to a relative path, then the 
# experiment generation script will set it to a path consisting of a 
# default path with the relative path appended to it; and if it gets set 
# to an absolute path, then the workflow will leave it set to that path.
#
#-----------------------------------------------------------------------
#
  MACHINE="${machine^^}"
  ACCOUNT="${account}"

  EXPT_BASEDIR="${expt_basedir}"
  EXPT_SUBDIR="${test_name}"
  USE_CRON_TO_RELAUNCH=${use_cron_to_relaunch:-"TRUE"}
  CRON_RELAUNCH_INTVL_MNTS=${cron_relaunch_intvl_mnts:-"02"}
  VERBOSE=${verbose:-"TRUE"}

  expt_config_str=${expt_config_str}"\
#
# The machine on which to run, the account to which to charge computational
# resources, the base directory in which to create the experiment directory
# (if different from the default location), and the name of the experiment
# subdirectory.
#
MACHINE=\"${MACHINE}\"
ACCOUNT=\"${ACCOUNT}\""

  if [ ! -z "${EXPT_BASEDIR}" ]; then
    expt_config_str=${expt_config_str}"
EXPT_BASEDIR=\"${EXPT_BASEDIR}\""
  fi

  expt_config_str=${expt_config_str}"
EXPT_SUBDIR=\"${EXPT_SUBDIR}\"
#
# Flag specifying whether or not to automatically resubmit the worfklow
# to the batch system via cron and, if so, the frequency (in minutes) of
# resubmission.
#
USE_CRON_TO_RELAUNCH=\"${USE_CRON_TO_RELAUNCH}\"
CRON_RELAUNCH_INTVL_MNTS=\"${CRON_RELAUNCH_INTVL_MNTS}\"
#
# Flag specifying whether to run in verbose mode.
#
VERBOSE=\"${VERBOSE}\""
#
#-----------------------------------------------------------------------
#
# Append the contents of the current WE2E test's configuration file to
# the experiment configuration string.
#
#-----------------------------------------------------------------------
#
  expt_config_str=${expt_config_str}"
#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
# The following section is a copy of this WE2E test's configuration file.
#
"
  expt_config_str=${expt_config_str}$( cat "${test_config_fp}" )
  expt_config_str=${expt_config_str}"
#
# End of section from this test's configuration file.
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------"
#
#-----------------------------------------------------------------------
#
# Modifications to the experiment configuration file if the WE2E test 
# uses pre-generated grid, orography, or surface climatology files.
#
# If not running one or more of the grid, orography, and surface 
# climatology file generation tasks, specify directories in which 
# pregenerated versions of these files can be found.
#
#-----------------------------------------------------------------------
#
  if [ "${RUN_TASK_MAKE_GRID}" = "FALSE" ] || \
     [ "${RUN_TASK_MAKE_OROG}" = "FALSE" ] || \
     [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "FALSE" ]; then

    if [ "$MACHINE" = "WCOSS_CRAY" ]; then
      pregen_basedir="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/FV3LAM_pregen"
    elif [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
      pregen_basedir="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/FV3LAM_pregen"
    elif [ "$MACHINE" = "HERA" ]; then
      pregen_basedir="/scratch2/BMC/det/FV3LAM_pregen"
    elif [ "$MACHINE" = "JET" ]; then
      pregen_basedir="/mnt/lfs4/BMC/wrfruc/FV3-LAM/pregen"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      pregen_basedir="/glade/p/ral/jntp/UFS_CAM/FV3LAM_pregen"
    else
      print_err_msg_exit "\
The base directory (pregen_basedir) in which the pregenerated grid,
orography, and/or surface climatology files are located has not been
specified for this machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    pregen_dir="${pregen_basedir}/${PREDEF_GRID_NAME}"

  fi
#
# Directory for pregenerated grid files.
#
  if [ "${RUN_TASK_MAKE_GRID}" = "FALSE" ]; then
    GRID_DIR="${pregen_dir}"
    expt_config_str=${expt_config_str}"
#
# Directory containing the pregenerated grid files.
#
GRID_DIR=\"${GRID_DIR}\""
  fi
#
# Directory for pregenerated orography files.
#
  if [ "${RUN_TASK_MAKE_OROG}" = "FALSE" ]; then
    OROG_DIR="${pregen_dir}"
    expt_config_str=${expt_config_str}"
#
# Directory containing the pregenerated orography files.
#
OROG_DIR=\"${OROG_DIR}\""
  fi
#
# Directory for pregenerated surface climatology files.
#
  if [ "${RUN_TASK_MAKE_SFC_CLIMO}" = "FALSE" ]; then
    SFC_CLIMO_DIR="${pregen_dir}"
    expt_config_str=${expt_config_str}"
#
# Directory containing the pregenerated surface climatology files.
#
SFC_CLIMO_DIR=\"${SFC_CLIMO_DIR}\""
  fi
#
#-----------------------------------------------------------------------
#
# Modifications to the experiment configuration file if running the WE2E 
# test in NCO mode.
#
#-----------------------------------------------------------------------
#
  if [ "${RUN_ENVIR}" = "nco" ]; then
#
# Set RUN and envir.
#
    expt_config_str=${expt_config_str}"
#
# In order to prevent simultaneous WE2E (Workflow End-to-End) tests that
# are running in NCO mode and which run the same cycles from interfering
# with each other, for each cycle, each such test must have a distinct
# path to the following two directories:
#
# 1) The directory in which the cycle-dependent model input files, symlinks
#    to cycle-independent input files, and raw (i.e. before post-processing)
#    forecast output files for a given cycle are stored.  The path to this
#    directory is
#
#      \$STMP/tmpnwprd/\$RUN/\$cdate
#
#    where cdate is the starting year (yyyy), month (mm), day (dd) and
#    hour of the cycle in the form yyyymmddhh.
#
# 2) The directory in which the output files from the post-processor (UPP)
#    for a given cycle are stored.  The path to this directory is
#
#      \$PTMP/com/\$NET/\$envir/\$RUN.\$yyyymmdd/\$hh
#
# Here, we make the first directory listed above unique to a WE2E test
# by setting RUN to the name of the current test.  This will also make
# the second directory unique because it also conains the variable RUN
# in its full path, but if this directory -- or set of directories since
# it involves a set of cycles and forecast hours -- already exists from
# a previous run of the same test, then it is much less confusing to the
# user to first move or delete this set of directories during the workflow
# generation step and then start the experiment (whether we move or delete
# depends on the setting of PREEXISTING_DIR_METHOD).  For this purpose,
# it is most convenient to put this set of directories under an umbrella
# directory that has the same name as the experiment.  This can be done
# by setting the variable envir to the name of the current test.  Since
# as mentiond above we will store this name in RUN, below we simply set
# envir to the same value as RUN (which is just EXPT_SUBDIR).  Then, for
# this test, the UPP output will be located in the directory
#
#   \$PTMP/com/\$NET/\$RUN/\$RUN.\$yyyymmdd/\$hh
#
RUN=\"\${EXPT_SUBDIR}\"
envir=\"\${EXPT_SUBDIR}\""
#
# Set FIXLAM_NCO_BASEDIR.
#
    if [ "$MACHINE" = "WCOSS_CRAY" ]; then
      FIXLAM_NCO_BASEDIR="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/FV3LAM_pregen"
    elif [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
      FIXLAM_NCO_BASEDIR="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/FV3LAM_pregen"
    elif [ "$MACHINE" = "HERA" ]; then
      FIXLAM_NCO_BASEDIR="/scratch2/BMC/det/FV3LAM_pregen"
    elif [ "$MACHINE" = "JET" ]; then
      FIXLAM_NCO_BASEDIR="/mnt/lfs4/BMC/wrfruc/FV3-LAM/pregen"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      FIXLAM_NCO_BASEDIR="/needs/to/be/specified"
    else
      print_err_msg_exit "\
The base directory (FIXLAM_NCO_BASEDIR) in which the pregenerated grid, 
orography, and surface climatology \"fixed\" files used in NCO mode are 
located has not been specified for this machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    expt_config_str=${expt_config_str}"
#
# The base directory in which the pregenerated grid, orography, and surface 
# climatology \"fixed\" files used in NCO mode are located.  In NCO mode,
# the workflow scripts will create symlinks (in the directory specified 
# by FIXLAM) to files in a subdirectory under FIXLAM_NCO_BASDEDIR, where
# the name of the subdirectory is the name of the predefined grid specified 
# by PREDEF_GRID_NAME.
#
FIXLAM_NCO_BASEDIR=\"${FIXLAM_NCO_BASEDIR}\""
#
# Set COMINgfs if using the FV3GFS or the GSMGFS as the external model 
# for ICs or LBCs.
#
    if [ "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ] || \
       [ "${EXTRN_MDL_NAME_ICS}" = "GSMGFS" ] || \
       [ "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ] || \
       [ "${EXTRN_MDL_NAME_LBCS}" = "GSMGFS" ]; then

      if [ "$MACHINE" = "WCOSS_CRAY" ]; then
        COMINgfs="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/COMGFS"
      elif [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
        COMINgfs="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/COMGFS"
      elif [ "$MACHINE" = "HERA" ]; then
        COMINgfs="/scratch2/NCEPDEV/fv3-cam/noscrub/UFS_SRW_App/COMGFS"
      elif [ "$MACHINE" = "JET" ]; then
        COMINgfs="/lfs1/HFIP/hwrf-data/hafs-input/COMGFS"
      elif [ "$MACHINE" = "CHEYENNE" ]; then
        COMINgfs="/glade/scratch/ketefian/NCO_dirs/COMGFS"
      else
        print_err_msg_exit "\
The directory (COMINgfs) that needs to be specified when running the
workflow in NCO mode (RUN_ENVIR set to \"nco\") AND using the FV3GFS or
the GSMGFS as the external model for ICs and/or LBCs has not been specified
for this machine (MACHINE):
  MACHINE= \"${MACHINE}\""
      fi

      expt_config_str=${expt_config_str}"
#
# Directory that needs to be specified when running the workflow in NCO
# mode (RUN_ENVIR set to \"nco\") AND using the FV3GFS or the GSMGFS as
# the external model for ICs and/or LBCs.
#
COMINgfs=\"${COMINgfs}\""

    fi
#
# Set STMP and PTMP.
#
    nco_basedir=$( readlink -f "$homerrfs/../../nco_dirs" )
    STMP=${stmp:-"${nco_basedir}/stmp"}
    PTMP=${ptmp:-"${nco_basedir}/ptmp"}

    expt_config_str=${expt_config_str}"
#
# Directories STMP and PTMP that need to be specified when running the
# workflow in NCO-mode (i.e. RUN_ENVIR set to "nco").
#
STMP=\"${STMP}\"
PTMP=\"${PTMP}\""

  fi
#
#-----------------------------------------------------------------------
#
# Modifications to the experiment configuration file if the WE2E test 
# uses user-staged external model files.
#
#-----------------------------------------------------------------------
#
  if [ "${USE_USER_STAGED_EXTRN_FILES}" = "TRUE" ]; then

    if [ "$MACHINE" = "WCOSS_CRAY" ]; then
      extrn_mdl_source_basedir="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/extrn_mdl_files"
    elif [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
      extrn_mdl_source_basedir="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/extrn_mdl_files"
    elif [ "$MACHINE" = "HERA" ]; then
      extrn_mdl_source_basedir="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/staged_extrn_mdl_files"
    elif [ "$MACHINE" = "JET" ]; then
      extrn_mdl_source_basedir="/mnt/lfs1/BMC/fim/Gerard.Ketefian/UFS_CAM/staged_extrn_mdl_files"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      extrn_mdl_source_basedir="/glade/p/ral/jntp/UFS_SRW_app/staged_extrn_mdl_files"
    elif [ "$MACHINE" = "ORION" ]; then
      extrn_mdl_source_basedir="/work/noaa/gsd-fv3-dev/gsketefia/UFS/staged_extrn_mdl_files"
    else
      print_err_msg_exit "\
The base directory (extrn_mdl_source_basedir) in which the user-staged
external model files should be located has not been specified for this
machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    EXTRN_MDL_SOURCE_BASEDIR_ICS="${extrn_mdl_source_basedir}/${EXTRN_MDL_NAME_ICS}"
    if [ "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ] && [ "$MACHINE" = "HERA" ]; then
      EXTRN_MDL_SOURCE_BASEDIR_ICS="${EXTRN_MDL_SOURCE_BASEDIR_ICS}/${FV3GFS_FILE_FMT_ICS}"
    fi
    if [ "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ] || \
       [ "${EXTRN_MDL_NAME_ICS}" = "GSMGFS" ]; then
      if [ "${FV3GFS_FILE_FMT_ICS}" = "nemsio" ]; then
        EXTRN_MDL_FILES_ICS=( "gfs.atmanl.nemsio" "gfs.sfcanl.nemsio" )
      elif [ "${FV3GFS_FILE_FMT_ICS}" = "grib2" ]; then
        EXTRN_MDL_FILES_ICS=( "gfs.pgrb2.0p25.f000" )
      fi
    elif [ "${EXTRN_MDL_NAME_ICS}" = "HRRR" ] || \
         [ "${EXTRN_MDL_NAME_ICS}" = "RAP" ]; then
      EXTRN_MDL_FILES_ICS=( "${EXTRN_MDL_NAME_ICS,,}.out.for_f000" )
    elif [ "${EXTRN_MDL_NAME_ICS}" = "NAM" ]; then
      EXTRN_MDL_FILES_ICS=( "${EXTRN_MDL_NAME_ICS,,}.out.for_f000" )
    fi

    EXTRN_MDL_SOURCE_BASEDIR_LBCS="${extrn_mdl_source_basedir}/${EXTRN_MDL_NAME_LBCS}"
    if [ "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ] && [ "$MACHINE" = "HERA" ]; then
      EXTRN_MDL_SOURCE_BASEDIR_LBCS="${EXTRN_MDL_SOURCE_BASEDIR_LBCS}/${FV3GFS_FILE_FMT_LBCS}"
    fi
#
# Make sure that the forecast length is evenly divisible by the interval
# between the times at which the lateral boundary conditions will be
# specified.
#
    rem=$(( 10#${FCST_LEN_HRS} % 10#${LBC_SPEC_INTVL_HRS} ))
    if [ "$rem" -ne "0" ]; then
      print_err_msg_exit "\
The forecast length (FCST_LEN_HRS) must be evenly divisible by the lateral
boundary conditions specification interval (LBC_SPEC_INTVL_HRS):
  FCST_LEN_HRS = ${FCST_LEN_HRS}
  LBC_SPEC_INTVL_HRS = ${LBC_SPEC_INTVL_HRS}
  rem = FCST_LEN_HRS%%LBC_SPEC_INTVL_HRS = $rem"
    fi
    lbc_spec_times_hrs=( $( seq "${LBC_SPEC_INTVL_HRS}" "${LBC_SPEC_INTVL_HRS}" "${FCST_LEN_HRS}" ) )
    EXTRN_MDL_FILES_LBCS=( $( printf "%03d " "${lbc_spec_times_hrs[@]}" ) ) 
    if [ "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ] || \
       [ "${EXTRN_MDL_NAME_LBCS}" = "GSMGFS" ]; then
      if [ "${FV3GFS_FILE_FMT_LBCS}" = "nemsio" ]; then
        EXTRN_MDL_FILES_LBCS=( "${EXTRN_MDL_FILES_LBCS[@]/#/gfs.atmf}" )
        EXTRN_MDL_FILES_LBCS=( "${EXTRN_MDL_FILES_LBCS[@]/%/.nemsio}" )
      elif [ "${FV3GFS_FILE_FMT_LBCS}" = "grib2" ]; then
        EXTRN_MDL_FILES_LBCS=( "${EXTRN_MDL_FILES_LBCS[@]/#/gfs.pgrb2.0p25.f}" )
      fi
    elif [ "${EXTRN_MDL_NAME_LBCS}" = "HRRR" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "RAP" ]; then
      EXTRN_MDL_FILES_LBCS=( "${EXTRN_MDL_FILES_LBCS[@]/#/${EXTRN_MDL_NAME_LBCS,,}.out.for_f}" )
    elif [ "${EXTRN_MDL_NAME_LBCS}" = "NAM" ]; then
      EXTRN_MDL_FILES_LBCS=( "${EXTRN_MDL_FILES_LBCS[@]/#/${EXTRN_MDL_NAME_LBCS,,}.out.for_f}" )
    fi

    expt_config_str=${expt_config_str}"
#
# Locations and names of user-staged external model files for generating
# ICs and LBCs.
#
EXTRN_MDL_SOURCE_BASEDIR_ICS=\"${EXTRN_MDL_SOURCE_BASEDIR_ICS}\"
EXTRN_MDL_FILES_ICS=( $( printf "\"%s\" " "${EXTRN_MDL_FILES_ICS[@]}" ))
EXTRN_MDL_SOURCE_BASEDIR_LBCS=\"${EXTRN_MDL_SOURCE_BASEDIR_LBCS}\"
EXTRN_MDL_FILES_LBCS=( $( printf "\"%s\" " "${EXTRN_MDL_FILES_LBCS[@]}" ))"

  fi
#
#-----------------------------------------------------------------------
#
# Set MET and MET+ paths, if necessary.
#
#-----------------------------------------------------------------------
#
  if [ "${RUN_TASK_VX_GRIDSTAT}" = "TRUE" ] || \
     [ "${RUN_TASK_VX_POINTSTAT}" = "TRUE" ]; then

    if [ "$MACHINE" = "WCOSS_CRAY" ]; then
      met_install_dir="/gpfs/hps3/emc/meso/noscrub/emc.metplus/met/10.0.0"
      metplus_path="/gpfs/hps3/emc/meso/noscrub/emc.metplus/METplus/METplus-4.0.0"
      ccpa_obs_dir="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/obs_data/ccpa/proc"
      mrms_obs_dir="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/obs_data/mrms/proc"
      ndas_obs_dir="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/obs_data/ndas/proc"
      met_bin_exec="exec"
    elif [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
      met_install_dir="/gpfs/dell2/emc/verification/noscrub/emc.metplus/met/10.0.0"
      metplus_path="/gpfs/dell2/emc/verification/noscrub/emc.metplus/METplus/METplus-4.0.0"
      ccpa_obs_dir="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/obs_data/ccpa/proc"
      mrms_obs_dir="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/obs_data/mrms/proc"
      ndas_obs_dir="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/obs_data/ndas/proc"
      met_bin_exec="exec"
    elif [ "$MACHINE" = "HERA" ]; then
      met_install_dir="/contrib/met/10.0.0"
      metplus_path="/contrib/METplus/METplus-4.0.0"
      ccpa_obs_dir="/scratch2/BMC/det/UFS_SRW_app/develop/obs_data/ccpa/proc"
      mrms_obs_dir="/scratch2/BMC/det/UFS_SRW_app/develop/obs_data/mrms/proc"
      ndas_obs_dir="/scratch2/BMC/det/UFS_SRW_app/develop/obs_data/ndas/proc"
      met_bin_exec="bin"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      met_install_dir="/glade/p/ral/jntp/MET/MET_releases/10.0.0"
      metplus_path="/glade/p/ral/jntp/MET/METplus/METplus-4.0.0"
      ccpa_obs_dir="/glade/p/ral/jntp/UFS_SRW_app/develop/obs_data/ccpa/proc"
      mrms_obs_dir="/glade/p/ral/jntp/UFS_SRW_app/develop/obs_data/mrms/proc"
      ndas_obs_dir="/glade/p/ral/jntp/UFS_SRW_app/develop/obs_data/ndas/proc"
      met_bin_exec="bin"
    else
      print_err_msg_exit "\
The MET and MET+ paths (MET_INSTALL_DIR and MET_INSTALL_DIR) or the observation directories
(CCPA_OBS_DIR, MRMS_OBS_DIR, NDAS_OBS_DIR) have not been specified for this machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    expt_config_str=${expt_config_str}"
#
# MET and MET+ paths.
#
METPLUS_PATH=\"${metplus_path}\"
MET_INSTALL_DIR=\"${met_install_dir}\"
CCPA_OBS_DIR=\"${ccpa_obs_dir}\"
MRMS_OBS_DIR=\"${mrms_obs_dir}\"
NDAS_OBS_DIR=\"${ndas_obs_dir}\"
MET_BIN_EXEC=\"${met_bin_exec}\""

  fi
#
#-----------------------------------------------------------------------
#
# On some machines (e.g. cheyenne), some tasks often require multiple
# tries before they succeed.  To make it more convenient to run the WE2E 
# tests on these machines without manual intervention, change the number 
# of attempts for such tasks on those machines to be more than one.
#
#-----------------------------------------------------------------------
#
  add_maxtries="FALSE"

  if [ "$MACHINE" = "HERA" ]; then
    add_maxtries="TRUE"
    MAXTRIES_MAKE_ICS="2"
    MAXTRIES_MAKE_LBCS="2"
    MAXTRIES_RUN_POST="2"
  elif [ "$MACHINE" = "CHEYENNE" ]; then
    add_maxtries="TRUE"
    MAXTRIES_MAKE_SFC_CLIMO="3"
    MAXTRIES_MAKE_ICS="5"
    MAXTRIES_MAKE_LBCS="10"
    MAXTRIES_RUN_POST="10"
  fi

  if [ "${add_maxtries}" = "TRUE" ]; then

    expt_config_str=${expt_config_str}"
#
# Maximum number of attempts at running each task.
#
MAXTRIES_MAKE_GRID=\"${MAXTRIES_MAKE_GRID}\"
MAXTRIES_MAKE_OROG=\"${MAXTRIES_MAKE_OROG}\"
MAXTRIES_MAKE_SFC_CLIMO=\"${MAXTRIES_MAKE_SFC_CLIMO}\"
MAXTRIES_GET_EXTRN_ICS=\"${MAXTRIES_GET_EXTRN_ICS}\"
MAXTRIES_GET_EXTRN_LBCS=\"${MAXTRIES_GET_EXTRN_LBCS}\"
MAXTRIES_MAKE_ICS=\"${MAXTRIES_MAKE_ICS}\"
MAXTRIES_MAKE_LBCS=\"${MAXTRIES_MAKE_LBCS}\"
MAXTRIES_RUN_FCST=\"${MAXTRIES_RUN_FCST}\"
MAXTRIES_RUN_POST=\"${MAXTRIES_RUN_POST}\""

  fi
#
#-----------------------------------------------------------------------
#
# Set the full path to the configuration file that the experiment 
# generation script reads in.  Then write the contents of expt_config_str 
# to that file.
#
#-----------------------------------------------------------------------
#
  expt_config_fp="$ushdir/${EXPT_CONFIG_FN}"
  printf "%s" "${expt_config_str}" > "${expt_config_fp}"
#
#-----------------------------------------------------------------------
#
# The following are changes that need to be made directly to the 
# experiment configuration file created above (as opposed to the 
# experiment configuration string expt_config_str) because they involve
# resetting of values that have already been set in the experiment 
# configuration file.
#
# If EXTRN_MDL_SYSBASEDIR_ICS has been specified in the current WE2E
# test's base configuration file, it must be set to one of the following:
#
# 1) The string "set_to_non_default_location_in_testing_script" in order
#    to allow this script to set it to a valid location depending on the
#    machine and external model (for ICs).
#
# 2) To an existing directory.  If it is set to a directory, then this
#    script ensures that the directory exists (via the check below).
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${EXTRN_MDL_SYSBASEDIR_ICS}" ]; then

    if [ "${EXTRN_MDL_SYSBASEDIR_ICS}" = "set_to_non_default_location_in_testing_script" ]; then

      EXTRN_MDL_SYSBASEDIR_ICS=""
      if [ "$MACHINE" = "HERA" ]; then
        if [ "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ]; then
          EXTRN_MDL_SYSBASEDIR_ICS="/scratch2/BMC/det/UFS_SRW_app/dummy_FV3GFS_sys_dir"
        fi
      fi

      if [ -z "${EXTRN_MDL_SYSBASEDIR_ICS}" ]; then
        print_err_msg_exit "\
A non-default location for EXTRN_MDL_SYSBASEDIR_ICS for testing purposes
has not been specified for this machine (MACHINE) and external model for 
initial conditions (EXTRN_MDL_NAME_ICS) combination:
  MACHINE= \"${MACHINE}\"
  EXTRN_MDL_NAME_ICS = \"${EXTRN_MDL_NAME_ICS}\""
      fi

    else 

      if [ ! -d "${EXTRN_MDL_SYSBASEDIR_ICS}" ]; then
        print_err_msg_exit "\
The non-default location specified by EXTRN_MDL_SYSBASEDIR_ICS does not 
exist or is not a directory:
  EXTRN_MDL_NAME_ICS = \"${EXTRN_MDL_NAME_ICS}\""
      fi

    fi

    set_bash_param "${expt_config_fp}" \
                   "EXTRN_MDL_SYSBASEDIR_ICS" "${EXTRN_MDL_SYSBASEDIR_ICS}"

  fi
#
#-----------------------------------------------------------------------
#
# Same as above but for EXTRN_MDL_SYSBASEDIR_LBCS.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${EXTRN_MDL_SYSBASEDIR_LBCS}" ]; then

    if [ "${EXTRN_MDL_SYSBASEDIR_LBCS}" = "set_to_non_default_location_in_testing_script" ]; then

      EXTRN_MDL_SYSBASEDIR_LBCS=""
      if [ "$MACHINE" = "HERA" ]; then
        if [ "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ]; then
          EXTRN_MDL_SYSBASEDIR_LBCS="/scratch2/BMC/det/UFS_SRW_app/dummy_FV3GFS_sys_dir"
        fi
      fi

      if [ -z "${EXTRN_MDL_SYSBASEDIR_LBCS}" ]; then
        print_err_msg_exit "\
A non-default location for EXTRN_MDL_SYSBASEDIR_LBCS for testing purposes
has not been specified for this machine (MACHINE) and external model for 
initial conditions (EXTRN_MDL_NAME_LBCS) combination:
  MACHINE= \"${MACHINE}\"
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\""
      fi

    else 

      if [ ! -d "${EXTRN_MDL_SYSBASEDIR_LBCS}" ]; then
        print_err_msg_exit "\
The non-default location specified by EXTRN_MDL_SYSBASEDIR_LBCS does not 
exist or is not a directory:
  EXTRN_MDL_NAME_LBCS = \"${EXTRN_MDL_NAME_LBCS}\""
      fi

    fi

    set_bash_param "${expt_config_fp}" \
                   "EXTRN_MDL_SYSBASEDIR_LBCS" "${EXTRN_MDL_SYSBASEDIR_LBCS}"

  fi
#
#-----------------------------------------------------------------------
#
# Call the experiment generation script to generate an experiment 
# directory and a rocoto workflow XML for the current WE2E test to run. 
#
#-----------------------------------------------------------------------
#
  $ushdir/generate_FV3LAM_wflow.sh || \
    print_err_msg_exit "\
Could not generate an experiment for the test specified by test_name:
  test_name = \"${test_name}\""

done
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script or 
# function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

