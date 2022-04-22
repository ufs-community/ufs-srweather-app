#!/bin/bash

#
#-----------------------------------------------------------------------
#
# This file defines a function that gathers and returns information about 
# the WE2E tests available in the WE2E testing system.  This information
# consists of the test names, the category subdirectories in which the 
# test configuration files are located (relative to a base directory), 
# the test IDs, and the test descriptions.  This function optionally 
# also creates a CSV (Comma-Separated Value) file containing various
# pieces of information about each of the workflow end-to-end (WE2E)
# tests.  These are described in more detail below.  
#
# The function takes as inputs the following arguments:
#
# WE2Edir:
# Directory in which the WE2E testing system is located.  This system
# consists of the main script for running WE2E tests, various auxiliary 
# scripts, and the test configuration files.
#
# generate_csv_file:
# Flag that specifies whether or not a CSV (Comma-Separated Value) file
# containing information about the WE2E tests should be generated.
#
# verbose:
# Optional verbosity flag.  Should be set to "TRUE" or "FALSE".  Default
# is "FALSE".
#
# output_varname_test_configs_basedir:
# Name of output variable in which to return the base directory of the 
# WE2E test configuration files.
#
# output_varname_test_names:
# Name of output array variable in which to return the names of the WE2E 
# tests.
#
# output_varname_test_subdirs:
# Name of output array variable in which to return the category subdirectories 
# in which the WE2E tests are located. 
#
# output_varname_test_ids:
# Name of output array variable in which to return the IDs of the WE2E 
# tests. 
#
# output_varname_test_descs:
# Name of output array variable in which to return the descriptions of
# the WE2E tests.
#
# Note that any input argument that is not specified in the call to this
# function gets set to a null string in the body of the function.  In
# particular, if any of the arguments that start with "output_varname_"
# (indicating that they specify the name of an output variable) are not
# set in the call, the values corresponding to those variables are not 
# returned to the calling script or function.
#
# In order to gather information about the available WE2E tests, this
# function sets the local variable test_configs_basedir to the full path
# of the base directory in which the test configuration files (which may
# be ordinary files or symlinks) are located.  It sets this as follows:
#
#   test_configs_basedir="${WE2Edir}/test_configs"
#
# If the argument output_varname_test_configs_basedir is specified in 
# the call to this function, then the value of test_configs_basedir will 
# be returned to the calling script or function (in the variable specified 
# by output_varname_test_configs_basedir).
#
# The WE2E test configuration files are located in subdirectories under
# the base directory.  This function sets the names of these subdirectories
# in the local array category_subdirs.  We refer to these as "category" 
# subdirectories because they are used for clarity to group the tests 
# into categories (instead of putting them all directly under the base
# directory).  For example, one category of tests might be those that 
# test workflow capabilities such as running multiple cycles and ensemble
# forecasts, another might be those that run various combinations of 
# grids, physics suites, and external models for ICs/LBCs, etc.  Note 
# that if a new category subdirectory is added under test_configs_basedir, 
# its name must be added below as a new element in category_subdirs; 
# otherwise, this new subdirectory will not be searched for test 
# configuration files.  Note also that if one of the elements of 
# category_subdirs is ".", then this function will also search directly 
# under the base directory itself for test configuration files.
# 
# Once test_configs_basedir and category_subdirs are set, this function 
# searches the category subdirectories for WE2E test configuration files.  
# In doing so, it assumes that any ordinary file or symlink in the category 
# subdirectories having a name of the form
#
#   config.${test_name}.sh
#
# is a test configuration file, and it takes the name of the corresponding
# test to be given by whatever test_name in the above file name happens 
# to be.  Here, by "ordinary" file we mean an item in the file system 
# that is not a symlink (or a directory or other more exotic entity).  
# Also, for simplicity, we require that any configuration file that is a 
# symlink have a target that is an ordinary configuration file, i.e. not 
# a symlink.
#
# We allow test configuration files to be symlinks in order to avoid the 
# presence of identical configuration files with different names in the 
# WE2E testing system.  For example, assume there is a test named 
# "test_grid1" that is used to test whether the forecast model can run
# on a grid named "grid1", and assume that the configuration file for 
# this test is an ordinary file located in a category subdirectory named 
# "grids" that contains tests for various grids.  Then the full path to 
# this configuration file will be 
#
#   ${test_configs_basedir}/grids/config.test_grid1.sh
#
# Now assume that there is another category subdirectory named "suites"
# that contains configuration files for tests that check whether the 
# forecast model can run with various physics suites.  Thus, in order to 
# have a test that checks whether the forecast model can run successfully 
# with a physics suite named "suite1", we might create an ordinary
# configuration file named "config.test_suite1.sh" in "suites" (so that
# the corresponding test name is "test_suite1").  Thus, the full path to
# this configuration file would be
#
#   ${test_configs_basedir}/suites/config.test_suite1.sh
# 
# Now if test "test_grid1" happens to use physics suite "suite1", then 
# we may be able to use that test for testing both "grid1" and "suite1".
# However, we'd still want to have a configuration file in the "suites"
# subdirectory with a test name that makes it clear that the purpose of 
# the test is to run using "suite1".  Then, since the WE2E testing system
# allows configuration files to by symlinks, instead of copying 
# "config.test_grid1.sh" from the "grids" to the "suites" subdirectory 
# and renaming it to "config.test_suite1.sh" (which would create two
# identical ordinary configuration files), we could simply make 
# "config.test_suite1.sh" in "suites" a symlink to "config.test_grid1.sh"
# in "grids", i.e.
#
#   ${test_configs_basedir}/suites/config.test_suite1.sh
#     --> ${test_configs_basedir}/grids/config.test_grid1.sh
#
# With this approach, there will be only one ordinary configuration file 
# to maintain.  Note that there may be more than one symlink pointing to
# the same ordinary configuration file.  For example, there may be another
# category subdirectory named "wflow_features" containing tests for 
# various workflow features.  Then if the test "test_grid1" runs a test
# that, in addition to running the forecast model on "grid1" using the
# "suite1" physics suite also performs subhourly output, then a symlink
# named "config.test_subhourly.sh" can be created under "wflow_features"
# that points to the configuration file "config.test_grid1.sh", i.e.
#
#   ${test_configs_basedir}/wflow_features/config.test_subhourly.sh
#     --> ${test_configs_basedir}/grids/config.test_grid1.sh
#
# Since the WE2E testing system allows configuration files to be symlinks, 
# the same WE2E test may be referred to via multiple test names -- the
# test name corresponding to the ordinary configuration file ("test_grid1" 
# in the example above) and any one of the test names corresponding to 
# any symlinks that have this ordinary file as their target ("test_suite1" 
# and "test_subhourly" in the example above).  Here, for clarity we will 
# refer to the test name derived from the name of the ordinary configuration 
# file as the "primary" test name, and we will refer to the test names 
# dervied from the symlinks as the alternate test names.  Since these 
# test names all represent the same actual test, we also assign to each 
# group of primary and alternate test names a single test ID.  This is 
# simply an integer that uniquely identifies each group of primary and 
# alternate test names.
#
# For each configuration file (which may be an ordinary file or a symlink)
# found in the category subdirectories, this function saves in local 
# arrays the following information about the WE2E files:
#
# 1) The list of all available WE2E test names, both primary and alternate.
# 2) The category subdirectories under the base directory test_configs_basedir 
#    in which the test configuration files corresponding to each test 
#    name are located.
# 3) The IDs corresponding to each of the test names.
# 4) The test descriptions (if output_varname_test_descs is specified in
#    the call to this function or if generate_csv_file is or gets set to
#    "TRUE"; see below).
#
# These local arrays are sorted in order of increasing test ID.  Within
# each group of tests that have the same ID, the primary test name is
# listed first followed by zero or more alternate test names.  Note also
# that to reduce confusion, we do not allow two or more configuration
# files of the same name anywere under test_configs_basedir (either 
# representing the same actual test or different ones).  In other words, 
# the list of all test names that this function generates cannot contain 
# any duplicate names (either primary or alternate).  After assembling 
# the full list of test names, this function checks for such duplicates 
# and exits with an error message if any are found.
#
# The following input arguments to this function specify the names of 
# the arrays in which each of the quantities listed above should be 
# returned (to the calling script or function):
#
#   output_varname_test_names
#   output_varname_test_subdirs
#   output_varname_test_ids
#   output_varname_test_descs
#
# If any of these is not specified in the call to this function, then 
# the corresponding quantity will not be returned to the calling script
# or function.
#
# The test descriptions are headers consisting of one or more bash-style
# comment lines at the top of each ordinary test configuraiton file.
# They are extracted from each such file and placed in a local array only 
# if one or both of the following conditions are met:
#
# 1) The user explicitly asks for the descriptions to be returned by 
#    specifying in the call to this function the name of the array in 
#    which to return them (by setting a value for the argument 
#    output_varname_test_descs).  
# 2) A CSV file summarizing the WE2E tests will be generated (see below)
#
# For convenience, this function can generate a CSV (comma-separated 
# value) file containing information about the WE2E tests.  If it does,
# the file will be placed in the main WE2E testing system directory 
# specified by the input argument WE2Edir.  The CSV file can be read 
# into a spreadsheet in Google Sheets (or another similar tool) to get
# an overview of all the available WE2E tests.  The rows of the CSV file 
# correspond to the primary WE2E tests, and the columns correspond to 
# the (primary) test name, alternate test names (if any), test description, 
# number of times the test calls the forecast model, and values of various 
# SRW App experiment variables for that test.
#
# A CSV file will be generated in the directory specified by WE2Edir if 
# one or more of the following conditions hold:
#
# 1) The input argument generate_csv_file is set to "TRUE" in the call
#    to this function.
# 2) The input argument generate_csv_file is not set in the call to this 
#    function, and a CSV file does not already exist. 
# 3) The input argument generate_csv_file is not set in the call to this 
#    function, a CSV file already exists, and the modification time of 
#    at least one category subdirectory in category_subdirs is later 
#    than that of the CSV file, i.e. the existing CSV file needs to be 
#    updated because the test configuration files may have changed in 
#    some way.
#
# A CSV file is not generated if generate_csv_file is explicitly set to 
# "FALSE" in the call to this function (regardless of whether or not a 
# CSV file already exists).  If a CSV file is generated, it is placed in 
# the directory specified by the input argment WE2Edir, and it overwrites 
# any existing copies of the file in that directory.  The contents of
# each column of the CSV file are described below.
#
#-----------------------------------------------------------------------
#
function get_WE2Etest_names_subdirs_descs() {
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
# Specify the set of valid argument names for this script or function.  
# Then process the arguments provided to it on the command line (which 
# should consist of a set of name-value pairs of the form arg1="value1", 
# arg2="value2", etc).
#
#-----------------------------------------------------------------------
#
  local valid_args=( \
    "WE2Edir" \
    "generate_csv_file" \
    "verbose" \
    "output_varname_test_configs_basedir" \
    "output_varname_test_names" \
    "output_varname_test_subdirs" \
    "output_varname_test_ids" \
    "output_varname_test_descs" \
    )
  process_args "valid_args" "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
  print_input_args "valid_args"
#
#-----------------------------------------------------------------------
#
# Make the default value of "verbose" "FALSE".  Then make sure "verbose" 
# is set to a valid value.
#
#-----------------------------------------------------------------------
#
  verbose=${verbose:-"FALSE"}
  check_var_valid_value "verbose" "valid_vals_BOOLEAN"
  verbose=$(boolify $verbose)
#
#-----------------------------------------------------------------------
#
# Declare local variables.
#
#-----------------------------------------------------------------------
#
  local all_items \
        alt_test_name \
        alt_test_names \
        alt_test_names_subdirs \
        alt_test_prim_test_names \
        alt_test_subdir \
        alt_test_subdirs \
        array_names_vars_to_extract \
        array_names_vars_to_extract_orig \
        category_subdirs \
        cmd \
        column_titles \
        config_fn \
        crnt_item \
        csv_delimiter \
        csv_fn \
        csv_fp \
        cwd \
        default_val \
        hash_or_null \
        i \
        ii \
        j \
        jp1 \
        k \
        line \
        mod_time_csv \
        mod_time_subdir \
        msg \
        num_alt_tests \
        num_category_subdirs \
        num_cdates \
        num_cycles_per_day \
        num_days \
        num_fcsts \
        num_fcsts_orig \
        num_items \
        num_occurrences \
        num_prim_tests \
        num_tests \
        num_vars_to_extract \
        prim_array_names_vars_to_extract \
        prim_test_descs \
        prim_test_ids \
        prim_test_name_subdir \
        prim_test_names \
        prim_test_num_fcsts \
        prim_test_subdirs \
        get_test_descs \
        regex_search \
        row_content \
        sort_inds \
        stripped_line \
        subdir \
        subdir_fp \
        subdirs \
        target_dir \
        target_fn \
        target_fp \
        target_prim_test_name \
        target_rp \
        target_test_name_or_null \
        test_configs_basedir \
        test_desc \
        test_descs \
        test_descs_esc_sq \
        test_descs_orig \
        test_descs_str \
        test_id \
        test_id_next \
        test_ids \
        test_ids_and_inds \
        test_ids_and_inds_sorted \
        test_ids_orig \
        test_ids_str \
        test_name \
        test_name_or_null \
        test_names \
        test_names_orig \
        test_names_str \
        test_subdirs \
        test_subdirs_orig \
        test_subdirs_str \
        test_type \
        val \
        valid_vals_generate_csv_file \
        var_name \
        var_name_at \
        vars_to_extract
#
#-----------------------------------------------------------------------
#
# Set variables associated with the CSV (comma-separated value) file that 
# this function may generate.  The conditions under which such a file is 
# generated are described above in the description of this function.
#
#-----------------------------------------------------------------------
#
# Set the name and full path to the CSV file.
#
  csv_fn="WE2E_test_info.csv"
  csv_fp="${WE2Edir}/${csv_fn}"
#
# If generate_csv_file is specified as an input argument in the call to
# this function, make sure that it is set to a valid value.
#
  if [ ! -z "${generate_csv_file}" ]; then

    valid_vals_generate_csv_file=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
    check_var_valid_value "generate_csv_file" "valid_vals_generate_csv_file"

    generate_csv_file=${generate_csv_file^^}
    if [ "${generate_csv_file}" = "TRUE" ] || \
       [ "${generate_csv_file}" = "YES" ]; then
      generate_csv_file="TRUE"
    elif [ "${generate_csv_file}" = "FALSE" ] || \
         [ "${generate_csv_file}" = "NO" ]; then
      generate_csv_file="FALSE"
    fi
#
# If generate_csv_file was not specified as an input argument in the 
# call to this function, then it will have been set above to a null 
# string.  In this case, if a CSV file doesn't already exsit, reset 
# generate_csv_file to "TRUE" so that one will be generated.  If a CSV 
# file does exist, get its modification time so that later below, we can 
# compare it to the modification times of the category subdirectories 
# and determine whether a new CSV file needs to be generated.
#
# Note that the modification "times" obtained here and later below using 
# the "stat" utility are the seconds elapsed between Epoch (which is a
# fixed point in time) and the last modification time of the specified 
# file, not the dates/times at which the file was last modified.  This 
# is due to the use of the "--format=%Y" flag in the call to "stat".  We 
# choose these "seconds since Epoch" units because they make it easier 
# to determine which of two files is younger/older (the one with the 
# larger seconds-since-Epoch will be the more recently modified file.)
#
  else

    if [ ! -f "${csv_fp}" ]; then
      mod_time_csv="0"
      generate_csv_file="TRUE"
    else
      mod_time_csv=$( stat --format=%Y "${csv_fp}" )
    fi

  fi

  if [ "${generate_csv_file}" = "TRUE" ]; then
    print_info_msg "
Will generate a CSV (Comma Separated Value) file (csv_fp) containing
information on all WE2E tests:
  csv_fp = \"${csv_fp}\""
  fi
#
#-----------------------------------------------------------------------
#
# Set the base directory containing the WE2E test configuration files
# (or, more precisely, containing the category subdirectories in which
# the configuration files are located).
#
#-----------------------------------------------------------------------
#
  test_configs_basedir="${WE2Edir}/test_configs"
#
#-----------------------------------------------------------------------
#
# Set the array category_subdirs that specifies the subdirectories under 
# test_configs_basedir in which to search for WE2E test configuration 
# files.  Note that if "." is included as one of the elements of this 
# array, then the base directory itself will also be searched.
#
#-----------------------------------------------------------------------
#
  category_subdirs=( \
    "." \
    "grids_extrn_mdls_suites_community" \
    "grids_extrn_mdls_suites_nco" \
    "release_SRW_v1" \
    "wflow_features" \
    )
  num_category_subdirs="${#category_subdirs[@]}"
#
#-----------------------------------------------------------------------
#
# Loop over the category subdirectories under test_configs_basedir 
# (possibly including the base directory itself).  In each subdirectory, 
# consider all items that have names of the form
#
#   config.${test_name}.sh
#
# and that are either ordinary files (i.e. not symlinks) or are symlinks 
# whose targets are ordinary files having names of the form above.  For 
# each item that is an ordinary file, save the corresponding primary test 
# name, the category subdirectory in which the item is located, and the 
# test ID in the arrays
#
#   prim_test_names
#   prim_test_subdirs
#   prim_test_ids
#
# respectively.  For each item that is a symlink to an ordinary file, 
# save the alternate test name corresponding to the symlink name, the 
# category subdirectory in which the symlink is located, and the test 
# name derived from the name of the symlink's target (i.e. the primary 
# test name that this alternate test name corresponds to) in the arrays
#
#   alt_test_names
#   alt_test_subdirs
#   alt_test_prim_test_names
#
# respectively.
#
#-----------------------------------------------------------------------
#
  prim_test_names=()
  prim_test_ids=()
  prim_test_subdirs=()
  prim_test_num_fcsts=()

  alt_test_names=()
  alt_test_subdirs=()
  alt_test_prim_test_names=()
#
# Initialize the counter that will be used to assign test IDs to the 
# primary test names.  This will be incremented below every time a new 
# primary test name is found.  Note that we do not yet assign IDs to the 
# alternate test names.  These will be assigned IDs later below that 
# will be identical to the IDs of the primary thest names they correspond 
# to.
#
  test_id="0"

  for (( i=0; i<=$((num_category_subdirs-1)); i++ )); do

    subdir="${category_subdirs[$i]}"
    subdir_fp="${test_configs_basedir}/$subdir"
#
# If at this point in the code generate_csv_file is still set to a null 
# string, it means that a CSV file containing information about the WE2E 
# tests already exists.  In this case, a new version of this file needs 
# to be generated only if one or more of the category subdirectories 
# have modification times that are later than that of the existing CSV 
# file.  Check for this condition and set generate_csv_file accordingly.
# Note that this if-statement will be executed at most once since it sets
# generate_csv_file to "TRUE", after which the test for entering the if-
# statement will be false.
#
    if [ -z "${generate_csv_file}" ]; then
      mod_time_subdir=$( stat --format=%Y "${subdir_fp}" )
      if [ "${mod_time_subdir}" -gt "${mod_time_csv}" ]; then
        generate_csv_file="TRUE"
        print_info_msg "
The current category subdirectory (subdir) has a modification time 
(mod_time_subdir) that is later than the modification time (mod_time_csv) 
of the existing CSV file (csv_fp) containing WE2E test information:
  subdir = \"${subdir}\"
  mod_time_subdir = \"${mod_time_subdir}\" (in units of seconds since Epoch)
  mod_time_csv = \"${mod_time_csv}\" (in units of seconds since Epoch)
  csv_fp = \"${csv_fp}\"
Thus, the CSV file must be updated.  Setting generate_csv_file to \"TRUE\" 
to generate a new CSV file:
  generate_csv_file = \"${generate_csv_file}\""
      fi
    fi
#
# Change location to the current category subdirectory.
#
    cd_vrfy "${subdir_fp}"
#
# Get the contents of the current subdirectory.  We consider each item
# that has a name of the form
#
#   config.${test_name}.sh
#
# to be a WE2E test configuration file, and we take the name of the test
# to be whatever ${test_name} in the above expression corresponds to.  
# We ignore all other items in the subdirectory.
#
    all_items=( $(ls -1) )
    num_items="${#all_items[@]}"
    for (( j=0; j<=$((num_items-1)); j++ )); do

      crnt_item="${all_items[$j]}"
#
# Try to extract the name of the test from the name of the current item
# and place the result in test_name_or_null.  test_name_or_null will
# contain the name of the test only if the item has a name of the form
# "config.${test_name}.sh", in which case it will be equal to ${test_name}.
# Otherwise, it will be a null string.
#
      regex_search="^config\.(.*)\.sh$"
      test_name_or_null=$( printf "%s\n" "${crnt_item}" | \
                           sed -n -r -e "s/${regex_search}/\1/p" )
#
#-----------------------------------------------------------------------
#
# Take further action for this item only if it has a name of the form
# above expected for a WE2E test configuration file, which will be the
# case only if test_name_or_null is not a null string.
#
#-----------------------------------------------------------------------
#
      if [ ! -z "${test_name_or_null}" ]; then
#
#-----------------------------------------------------------------------
#
# Use bash's -h conditional operator to check whether the current item
# (which at this point is taken to be a test configuration file) is a 
# symlink.  If it is a symlink, the only type of entity we allow the 
# target to be is an existing ordinary file.  In particular, to keep the 
# WE2E testing system simple, we do not allow the target to be a symlink.  
# Of course, it also cannot be a directory or other exotic entity.  Below, 
# we check for these various possibilities and only allow the case of the 
# target being an existing ordinary file.
#
#-----------------------------------------------------------------------
#
        if [ -h "${crnt_item}" ]; then
#
# Extract the name of the test from the name of the symlink and append
# it to the array alt_test_names.  Also, append the category subdirectory 
# under test_configs_basedir in which the symlink is located to the array 
# alt_test_subdirs.
#
          alt_test_names+=("${test_name_or_null}")
          alt_test_subdirs+=("$subdir")
#
# Get the full path to the target of the symlink without following targets
# that are themselves symlinks.  The "readlink" utility without any flags
# (such as -f) can do this, but when -f is omitted, it returns a relative
# path.  To convert that relative path to an absolute path without resolving
# symlinks, use the "realpath" utility with the -s flag.
#
          target_rp=$( readlink "${crnt_item}" )
          target_fp=$( realpath -s "${target_rp}" )
#
# Use bash's -h conditional operator to check whether the target itself
# is a symlink.  For simplicity, this is not allowed.  Thus, in this 
# case, print out an error message and exit.
#
          if [ -h "${target_fp}" ]; then
            cwd="$(pwd)"
            print_err_msg_exit "\
The symlink (crnt_item) in the current directory (cwd) has a target
(target_fp) that is itself a symlink:
  cwd = \"${cwd}\"
  crnt_item = \"${crnt_item}\"
  target_fp = \"${target_fp}\"
This is not allowed.  Please ensure that the current item points to an
ordinary file (i.e. not a symlink) and rerun."
          fi
#
# Now use bash's -f conditional operator to check whether the target is
# a "regular" file (as defined by bash).  Note that this test will return
# false if the target is a directory or does not exist and true otherwise.
# Thus, the negation of this test applied to the target (i.e. ! -f) that 
# we use below will be true if the target is not an existing file.  In 
# this case, we print out an error message and exit.
#
# Note also that the -f operator recursively follows a symlink passed to 
# it as an argument.  For this reason, we need to first perform the -h 
# test above to check that the target (without resolving symlinks) is 
# itself not a symlink.  The -f test below does not help in this regard.
#
          if [ ! -f "${target_fp}" ]; then
            cwd="$(pwd)"
            print_err_msg_exit "\
The symlink (crnt_item) in the current directory (cwd) has a target
(target_fp) that is not an existing ordinary file:
  cwd = \"${cwd}\"
  crnt_item = \"${crnt_item}\"
  target_fp = \"${target_fp}\"
This is probably because either the target doesn't exist or is a directory,
neither of which is allowed because the symlink must point to an ordinary
(i.e. non-symlink) WE2E test configuration file.  Please either point the 
symlink to such a file or remove it, then rerun."
          fi
#
# Get the name of the directory in which the target is located.
#
          target_dir=$( dirname "${target_fp}" )
#
# Next, check whether the directory in which the target is located is
# under the base directory of the WE2E test configuration files (i.e.
# test_configs_basedir).  We require that the target be located in one 
# of the subdirectories under test_configs_basedir (or directly under 
# test_configs_basedir itself) because we don't want to deal with tests 
# that have configuration files that may be located anywhere in the file 
# system; for simplicity, we want all configuration files to be placed 
# somewhere under test_configs_basedir.
#
# Note that the bash parameter expansion ${var/search/replace} returns
# $var but with the first instance of "search" replaced by "replace" if
# the former is found in $var.  Otherwise, it returns the original $var.
# If "replace" is omitted, then "search" is simply deleted.  Thus, in
# the if-statement below, if ${target_dir/${test_configs_basedir}/}
# returns ${target_dir} without changes (in which case the test in the
# if-statment will evaluate to true), it means ${test_configs_basedir}
# was not found within ${target_dir}.  That in turn means ${target_dir}
# is not a location under ${test_configs_basedir}.  In this case, print 
# out a warning and exit.
#
          if [ "${target_dir}" = "${target_dir/${test_configs_basedir}/}" ]; then
            cwd="$(pwd)"
            print_err_msg_exit "\
The symlink (crnt_item) in the current directory (cwd) has a target
(target_fp) located in a directory (target_dir) that is not somewhere
under the WE2E tests base directory (test_configs_basedir):
  cwd = \"${cwd}\"
  crnt_item = \"${crnt_item}\"
  target_fp = \"${target_fp}\"
  target_dir = \"${target_dir}\"
  test_configs_basedir = \"${test_configs_basedir}\"
For clarity, we require all WE2E test configuration files to be located
somewhere under test_configs_basedir (either directly in this base 
directory on in a subdirectory).  Please correct and rerun."
          fi
#
# Finally, check whether the name of the target file is in the expected
# format "config.${test_name}.sh" for a WE2E test configuration file.
# If not, print out a warning and exit.
#
          target_fn=$( basename "${target_fp}" )
          target_test_name_or_null=$( printf "%s\n" "${target_fn}" | \
                                      sed -n -r -e "s/${regex_search}/\1/p" )
          if [ -z "${target_test_name_or_null}" ]; then
            cwd="$(pwd)"
            print_err_msg_exit "\
The symlink (crnt_item) in the current directory (cwd) has a target
(target_fn; located in the directory target_dir) with a name that is
not in the form \"config.[test_name].sh\" expected for a WE2E test
configuration file:
  cwd = \"${cwd}\"
  crnt_item = \"${crnt_item}\"
  target_dir = \"${target_dir}\"
  target_fn = \"${target_fn}\"
Please either rename the target to have the form specified above or
remove the symlink, then rerun."
          fi
#
# Now that all the checks above have succeeded, for later use save the
# name of the WE2E test that the target represents in the array
# alt_test_prim_test_names.
#
          alt_test_prim_test_names+=("${target_test_name_or_null}")
#
#-----------------------------------------------------------------------
#
# If the current item is not a symlink...
#
#-----------------------------------------------------------------------
#
        else
#
# Check if the current item is a "regular" file (as defined by bash) and 
# thus not a directory or some other exotic entity.  If it is a regular 
# file, save the corresponding WE2E test name and category subdirectory 
# in the arrays prim_test_names and prim_test_subdirs, respectively.  
# Also, set its test ID and save it in the array prim_test_ids.  If the 
# current item is not a regular file, print out a warning and exit.
#
          if [ -f "${crnt_item}" ]; then
            prim_test_names+=("${test_name_or_null}")
            prim_test_subdirs+=("${subdir}")
            test_id=$((test_id+1))
            prim_test_ids+=("${test_id}")
          else
            cwd="$(pwd)"
            print_err_msg_exit "\
The item (crnt_item) in the current directory (cwd) is not a symlink,
but it is also not a \"regular\" file (i.e. it fails bash's -f conditional
operator):
  cwd = \"${cwd}\"
  crnt_item = \"${crnt_item}\"
  [ -f "${crnt_item}" ] = $([ -f "${crnt_item}" ])
This is probably because it is a directory.  Please correct and rerun."
          fi

        fi

      fi

    done

  done
#
# For later use, save the number of primary and alternate test names in
# variables.
#
  num_prim_tests="${#prim_test_names[@]}"
  num_alt_tests="${#alt_test_names[@]}"
#
#-----------------------------------------------------------------------
#
# Create the array test_names that contains both the primary and alternate 
# test names found above (with the list of primary names first followed 
# by the list of alternate names).  Also, create the array test_subdirs
# that contains the category subdirectories corresponding to these test
# names.
#
#-----------------------------------------------------------------------
#
  test_names=("${prim_test_names[@]}")
  test_subdirs=("${prim_test_subdirs[@]}")
  if [ "${num_alt_tests}" -gt "0" ]; then
    test_names+=("${alt_test_names[@]:-}")
    test_subdirs+=("${alt_test_subdirs[@]:-}")
  fi
#
#-----------------------------------------------------------------------
#
# For simplicity, make sure that each test name (either primary or 
# alternate) appears exactly once in the array test_names.  This is 
# equivalent to requiring that a test configuration file (ordinary file 
# or symlink) corresponding to each name appear exactly once anywhere 
# under the base directory test_configs_basedir.  
#
#-----------------------------------------------------------------------
#
  num_tests="${#test_names[@]}"
  for (( i=0; i<=$((num_tests-1)); i++ )); do

    test_name="${test_names[$i]}"

    subdirs=()
    num_occurrences=0
    for (( j=0; j<=$((num_tests-1)); j++ )); do
      if [ "${test_names[$j]}" = "${test_name}" ]; then
        num_occurrences=$((num_occurrences+1))
        subdirs+=("${test_subdirs[$j]}")
      fi
    done

    if [ "${num_occurrences}" -ne "1" ]; then
      print_err_msg_exit "\
There must be exactly one WE2E test configuration file (which may be a
ordinary file or a symlink) corresponding to each test name anywhere 
under the base directory test_configs_basedir.  However, the number of 
configuration files (num_occurences) corresponding to the current test 
name (test_name) is not 1:
  test_configs_basedir = \"${test_configs_basedir}\"
  test_name = \"${test_name}\"
  num_occurrences = ${num_occurrences}
These configuration files all have the name
  \"config.${test_name}.sh\"
and are located in the following category subdirectories under 
test_configs_basedir:
  subdirs = ( $( printf "\"%s\" " "${subdirs[@]}" ))
Please rename or remove all but one of these configuration files so that 
they correspond to unique test names and rerun."
    fi

  done
#
#-----------------------------------------------------------------------
#
# If the input argument output_varname_test_descs is not set to a null 
# string (meaning that the name of the array in which to return the WE2E 
# test descriptions is specified in the call to this function), or if 
# the flag generate_csv_file is set to "TRUE", we need to obtain the 
# WE2E test descriptions from the test configuration files.  In these
# cases, set the local variable get_test_descs to "TRUE".  Otherwise,
# set it to "FALSE".
#
#-----------------------------------------------------------------------
#
  get_test_descs="FALSE"
  if [ ! -z "${output_varname_test_descs}" ] || \
     [ "${generate_csv_file}" = "TRUE" ]; then
    get_test_descs="TRUE"
  fi
#
#-----------------------------------------------------------------------
#
# If get_test_descs is set to "TRUE", loop through all the primary test 
# names and extract from the configuration file of each the description 
# of the test.  This is assumed to be a section of (bash) comment lines 
# at the top of the configuration file.  Then append the test description 
# to the array prim_test_descs.  Note that we assume the first non-comment 
# line at the top of the configuration file indicates the end of the test 
# description header.
#
#-----------------------------------------------------------------------
#
  if [ "${get_test_descs}" = "TRUE" ]; then
#
# Specify in "vars_to_extract" the list of experiment variables to extract 
# from each test configuration file (and later to place in the CSV file).  
# Recall that the rows of the CSV file correspond to the various WE2E 
# tests, and the columns correspond to the test name, description, and 
# experiment variable values.  The elements of "vars_to_extract" should 
# be the names of SRW App experiment variables that are (or can be) 
# specified in the App's configuration file.  Note that if a variable is 
# not specified in the test configuration file, in most cases its value 
# is set to an empty string (and recorded as such in the CSV file).  In
# some cases, it is set to some other value (e.g. for the number of 
# ensemble members NUM_ENS_MEMBERS, it is set to 1).
#
    vars_to_extract=( "PREDEF_GRID_NAME" \
                      "CCPP_PHYS_SUITE" \
                      "EXTRN_MDL_NAME_ICS" \
                      "EXTRN_MDL_NAME_LBCS" \
                      "DATE_FIRST_CYCL" \
                      "DATE_LAST_CYCL" \
                      "CYCL_HRS" \
                      "INCR_CYCL_FREQ" \
                      "FCST_LEN_HRS" \
                      "LBC_SPEC_INTVL_HRS" \
                      "NUM_ENS_MEMBERS" \
                    )
    num_vars_to_extract="${#vars_to_extract[@]}"
#
# Create names of local arrays that will hold the value of the corresponding
# variable for each test.  Then use these names to define them as empty 
# arrays.  [The arrays named "prim_..." are to hold values for only the
# primary tests, while other arrays are to hold values for all (primary
# plus alternate) tests.]
#
    prim_array_names_vars_to_extract=( $( printf "prim_test_%s_vals " "${vars_to_extract[@]}" ) )
    array_names_vars_to_extract=( $( printf "%s_vals " "${vars_to_extract[@]}" ) )
    for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do
      cmd="${prim_array_names_vars_to_extract[$k]}=()"
      eval $cmd
      cmd="${array_names_vars_to_extract[$k]}=()"
      eval $cmd
    done

    print_info_msg "
Gathering test descriptions and experiment variable values from the 
configuration files of the primary WE2E tests...
"

    prim_test_descs=()
    for (( i=0; i<=$((num_prim_tests-1)); i++ )); do

      test_name="${prim_test_names[$i]}"
      print_info_msg "\
  Reading in the test description for primary WE2E test:  \"${test_name}\"
  In category (subdirectory):  \"${subdir}\"
"
      subdir=("${prim_test_subdirs[$i]}")
      cd_vrfy "${test_configs_basedir}/$subdir"
#
# Keep reading lines from the current test's configuration line until
# a line is encountered that does not start with zero or more spaces,
# followed by the hash symbol (which is the bash comment character)
# possibly followed by a single space character.
#
# In the while-loop below, we read in every such line, strip it of any
# leading spaces, the hash symbol, and possibly another space and append
# what remains to the local variable test_desc.
#
      config_fn="config.${test_name}.sh"
      test_desc=""
      while read -r line; do

        regex_search="^[ ]*(#)([ ]{0,1})(.*)"
        hash_or_null=$( printf "%s" "${line}" | \
                        sed -n -r -e "s/${regex_search}/\1/p" )
#
# If the current line is part of the file header containing the test
# description, then...
#
        if [ "${hash_or_null}" = "#" ]; then
#
# Strip from the current line any leading whitespace followed by the
# hash symbol possibly followed by a single space.  If what remains is
# empty, it means there are no comments on that line and it is just a
# separator line.  In that case, simply add a newline to test_desc.
# Otherwise, append what remains after stripping to what test_desc
# already contains, followed by a single space in preparation for
# appending the next (stripped) line.
#
          stripped_line=$( printf "%s" "${line}" | \
                           sed -n -r -e "s/${regex_search}/\3/p" )
          if [ -z "${stripped_line}" ]; then
            test_desc="\
${test_desc}

"
          else
            test_desc="\
${test_desc}${stripped_line} "
          fi
#
# If the current line is not part of the file header containing the test
# description, break out of the while-loop (and thus stop reading the
# file).
#
        else
          break
        fi

      done < "${config_fn}"
#
# At this point, test_desc contains a description of the current test.
# Note that:
#
# 1) It will be empty if the configuration file for the current test
#    does not contain a header describing the test.
# 2) It will contain newlines if the description header contained lines
#    that start with the hash symbol and contain no other characters.
#    These are used to delimit paragraphs within the description.
# 3) It may contain leading and trailing whitespace.
#
# Next, for clarity, we remove any leading and trailing whitespace using
# bash's pattern matching syntax.
#
# Note that the right-hand sides of the following two lines are NOT
# regular expressions.  They are expressions that use bash's pattern
# matching syntax (gnu.org/software/bash/manual/html_node/Pattern-Matching.html,
# wiki.bash-hackers.org/syntax/pattern) used in substring removal
# (tldp.org/LDP/abs/html/string-manipulation.html).  For example,
#
#   ${var%%[![:space:]]*}
#
# says "remove from var its longest substring that starts with a non-
# space character".
#
# First remove leading whitespace.
#
      test_desc="${test_desc#"${test_desc%%[![:space:]]*}"}"
#
# Now remove trailing whitespace.
#
      test_desc="${test_desc%"${test_desc##*[![:space:]]}"}"
#
# Finally, save the description of the current test as the next element
# of the array prim_test_descs.
#
      prim_test_descs+=("${test_desc}")
#
# Get from the current test's configuration file the values of the 
# variables specified in "vars_to_extract".  Then save the value in the
# arrays specified by "prim_array_names_vars_to_extract".
#
      for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do

        var_name="${vars_to_extract[$k]}"
        cmd=$( grep "^[ ]*${var_name}=" "${config_fn}" )
        eval $cmd

        if [ -z "${!var_name+x}" ]; then

          msg="
  The variable \"${var_name}\" is not defined in the current test's
  configuration file (config_fn):
    config_fn = \"${config_fn}\"
  Setting the element in the array \"${prim_array_names_vars_to_extract[$k]}\"
  corresponding to this test to"

          case "${var_name}" in

          "NUM_ENS_MEMBERS")
            default_val="1"
            msg=$msg":
    ${var_name} = \"${default_val}\""
            ;;

          "INCR_CYCL_FREQ")
            default_val="24"
            msg=$msg":
    ${var_name} = \"${default_val}\""
            ;;

          *)
            default_val=""
            msg=$msg" an empty string."
            ;;

          esac
          cmd="${var_name}=\"${default_val}\""
          eval $cmd

          print_info_msg "$verbose" "$msg" 
          cmd="${prim_array_names_vars_to_extract[$k]}+=(\"'${default_val}\")"

        else
#
# The following are important notes regarding how the variable "cmd" 
# containing the command that will append an element to the array 
# specified by ${prim_array_names_vars_to_extract[$k]} is formulated: 
#
# 1) If all the experiment variables were scalars, then the more complex
#    command below could be replaced with the following:
#
#    cmd="${prim_array_names_vars_to_extract[$k]}+=(\"${!var_name}\")"
#
#    But some variables are arrays, so we need the more complex approach
#    to cover those cases.
#
# 2) The double quotes (which need to be escaped here, i.e. \") are needed
#    so that for any experiment variables that are arrays, all the elements 
#    of the array are combined together and treated as a single element.  
#    If the experiment variable is CYCL_HRS (cycle hours) and is set to
#    the array ("00" "12"), we want the value saved in the local array
#    here to be a single element consisting of "00 12".  Otherwise, "00" 
#    and "12" will be treated as separate elements, and more than one 
#    element would be added to the array (which would be incorrect here).
#
# 3) The single quote (which needs to be escaped here, i.e. \') is needed
#    so that any numbers (e.g. a set of cycle hours such as "00 12") are 
#    treated as strings when the CSV file is opened in Google Sheets.  
#    If this is not done, Google Sheets will remove leading zeros.
#
          var_name_at="${var_name}[@]"
          cmd="${prim_array_names_vars_to_extract[$k]}+=(\'\"${!var_name_at}\")"
        fi
        eval $cmd

      done
#
# Calculate the number of forecasts that will be launched by the current
# test.  The "10#" forces bash to treat the following number as a decimal
# (not hexadecimal, etc).
#
      num_cycles_per_day=${#CYCL_HRS[@]}
      num_days=$(( (${DATE_LAST_CYCL} - ${DATE_FIRST_CYCL} + 1)*24/10#${INCR_CYCL_FREQ} ))
      num_cdates=$(( ${num_cycles_per_day}*${num_days} ))
      nf=$(( ${num_cdates}*10#${NUM_ENS_MEMBERS} ))
#
# In the following, the single quote at the beginning forces Google Sheets 
# to interpret this quantity as a string.  This prevents any automatic 
# number fomatting from being applied when the CSV file is imported into
# Google Sheets.
#
      prim_test_num_fcsts+=( "'$nf" )
#
# Unset the experiment variables defined for the current test so that 
# they are not accidentally used for the next one.
#
      for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do
        var_name="${vars_to_extract[$k]}"
        cmd="unset ${var_name}"
        eval $cmd
      done

    done

  fi
#
#-----------------------------------------------------------------------
#
# Create the arrays test_ids and test_descs that initially contain the 
# test IDs and descriptions corresponding to the primary test names
# (those of the alternate test names will be appended below).  Then, in
# the for-loop, do same for the arrays containing the experiment variable 
# values for each test.
#
#-----------------------------------------------------------------------
#
  test_ids=("${prim_test_ids[@]}")
  if [ "${get_test_descs}" = "TRUE" ]; then
    test_descs=("${prim_test_descs[@]}")
    num_fcsts=("${prim_test_num_fcsts[@]}")
    for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do
      cmd="${array_names_vars_to_extract[$k]}=(\"\${${prim_array_names_vars_to_extract[$k]}[@]}\")"
      eval $cmd
    done
  fi
#
#-----------------------------------------------------------------------
#
# Append to the arrays test_ids and test_descs the test IDs and descriptions
# of the alternate test names.  We set the test ID and description of 
# each alternate test name to those of the corresponding primary test
# name.  Then, in the inner for-loop, do the same for the arrays containing
# the experiment variable values.
#
#-----------------------------------------------------------------------
#
  for (( i=0; i<=$((num_alt_tests-1)); i++ )); do

    alt_test_name="${alt_test_names[$i]}"
    alt_test_subdir=("${alt_test_subdirs[$i]}")
    target_prim_test_name="${alt_test_prim_test_names[$i]}"

    num_occurrences=0
    for (( j=0; j<=$((num_prim_tests-1)); j++ )); do
      if [ "${prim_test_names[$j]}" = "${target_prim_test_name}" ]; then
        test_ids+=("${prim_test_ids[$j]}")
        if [ "${get_test_descs}" = "TRUE" ]; then
          test_descs+=("${prim_test_descs[$j]}")
          num_fcsts+=("${prim_test_num_fcsts[$j]}")
          for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do
            cmd="${array_names_vars_to_extract[$k]}+=(\"\${${prim_array_names_vars_to_extract[$k]}[$j]}\")"
            eval $cmd
          done
        fi
        num_occurrences=$((num_occurrences+1))
      fi
    done

    if [ "${num_occurrences}" -ne 1 ]; then
      print_err_msg_exit "\
Each alternate test name must have a corresponding primary test name that
occurs exactly once in the full list of primary test names.  For the 
current alternate test name (alt_test_name), the number of occurrences
(num_occurrences) of the corresponding primary test name (target_prim_test_name)
is not 1:
  alt_test_name = \"${alt_test_name}\"
  target_prim_test_name = \"${target_prim_test_name}\"
  num_occurrences = \"${num_occurrences}\"
Please correct and rerun."
    fi

  done
#
#-----------------------------------------------------------------------
#
# Sort in order of increasing test ID the arrays containing the names, 
# IDs, category subdirectories, and descriptions of the WE2E tests as
# well as the arrays containing the experiment variable values for each
# test.
#
# For this purpose, we first create an array (test_ids_and_inds) each
# of whose elements consist of the test ID, the test type, and the index 
# of the array element (with a space used as delimiter).  The test type
# is simply an identifier to distinguish between primary test names and
# alternate (symlink-derived) ones.  For the former, we set the test 
# type to "A", and for the latter, we set it to "B".  We do this in order
# to obtain a sorted result in which the elements are not only sorted by
# test ID but also sorted by test type such that within each group of
# elements/tests that has the same test ID, the primary test name is 
# listed first followed by zero or more alternte test names.
#
# Next, we sort the array test_ids_and_inds using the "sort" utility 
# and save the result in the new array test_ids_and_inds_sorted.  The
# latter will be sorted according to test ID because that is the first 
# quantity on each line (element) of the original array test_ids_and_inds.  
# Also, as described above, for each group of test names that have the
# same ID, the names will be sorted such that the primary test name is
# listed first.  
#
# Finally, we extract from test_ids_and_inds_sorted the second number 
# in each element (the one after the first number, which is the test ID,
# and the test type, which we no longer need), which is the original 
# array index before sorting, and save the results in the array sort_inds.  
# This array will contain the original indices in sorted order that we 
# then use to sort the arrays containing the WE2E test names, IDs, 
# subdirectories, descriptions, and experiment variable values.
#
#-----------------------------------------------------------------------
#
  test_ids_and_inds=()
  for (( i=0; i<=$((num_tests-1)); i++ )); do
    test_type="A"
    if [ "$i" -ge "${num_prim_tests}" ]; then
      test_type="B"
    fi
    test_ids_and_inds[$i]="${test_ids[$i]} ${test_type} $i"
  done

  readarray -t "test_ids_and_inds_sorted" < \
    <( printf "%s\n" "${test_ids_and_inds[@]}" | sort --numeric-sort )

  sort_inds=()
  regex_search="^[ ]*([0-9]*)[ ]*[AB][ ]*([0-9]*)$"
  for (( i=0; i<=$((num_tests-1)); i++ )); do
    sort_inds[$i]=$( printf "%s" "${test_ids_and_inds_sorted[$i]}" | \
                     sed -n -r -e "s/${regex_search}/\2/p" )
  done

  test_names_orig=( "${test_names[@]}" )
  test_subdirs_orig=( "${test_subdirs[@]}" )
  test_ids_orig=( "${test_ids[@]}" )
  for (( i=0; i<=$((num_tests-1)); i++ )); do
    ii="${sort_inds[$i]}"
    test_names[$i]="${test_names_orig[$ii]}"
    test_subdirs[$i]="${test_subdirs_orig[$ii]}"
    test_ids[$i]="${test_ids_orig[$ii]}"
  done

  if [ "${get_test_descs}" = "TRUE" ]; then

    test_descs_orig=( "${test_descs[@]}" )
    num_fcsts_orig=( "${num_fcsts[@]}" )
    for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do
      cmd="${array_names_vars_to_extract[$k]}_orig=(\"\${${array_names_vars_to_extract[$k]}[@]}\")"
      eval $cmd
    done

    for (( i=0; i<=$((num_tests-1)); i++ )); do
      ii="${sort_inds[$i]}"
      test_descs[$i]="${test_descs_orig[$ii]}"
      num_fcsts[$i]="${num_fcsts_orig[$ii]}"
      for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do
        cmd="${array_names_vars_to_extract[$k]}[$i]=\"\${${array_names_vars_to_extract[$k]}_orig[$ii]}\""
        eval $cmd
      done
    done

  fi
#
#-----------------------------------------------------------------------
#
# If generate_csv_file is set to "TRUE", generate a CSV (comma-separated
# value) file containing information about the WE2E tests.  This file
# can be opened in a spreadsheet in Google Sheets (and possibly Microsoft
# Excel as well) to view information about all the WE2E tests.  Note that
# in doing so, the user must specify the field delimiter to be the same
# character that csv_delimiter is set to below.
#
#-----------------------------------------------------------------------
#
  if [ "${generate_csv_file}" = "TRUE" ]; then
#
# If a CSV file already exists, delete it.
#
    rm_vrfy -f "${csv_fp}"
#
# Set the character used to delimit columns in the CSV file.  This has
# to be something that would normally not appear in the fields being 
# written to the CSV file.
#
    csv_delimiter="|"
#
# Set the titles of the columns that will be in the file.  Then write 
# them to the file.  The contents of the columns are described in more 
# detail further below.
#
    column_titles="\
\"Test Name (Subdirectory)\" ${csv_delimiter} \
\"Alternate Test Names (Subdirectories)\" ${csv_delimiter} \
\"Test Purpose/Description\" ${csv_delimiter} \
\"Number of Forecast Model Runs\""
    for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do
      column_titles="\
${column_titles} ${csv_delimiter} \
\"${vars_to_extract[$k]}\""
    done
    printf "%s\n" "${column_titles}" >> "${csv_fp}"
#
# Loop through the arrays containing the WE2E test information.  Extract 
# the necessary information and record it to the CSV file row-by-row.
# Note that each row corresponds to a primary test.  When an alternate
# test is encountered, its information is stored in the row of the 
# corresponding primary test (i.e. a new row is not created).
#
    j=0
    jp1=$((j+1))
    while [ "$j" -lt "${num_tests}" ]; do
#
# Get the primary name of the test and the category subdirectory in which
# it is located.
#
      prim_test_name_subdir="${test_names[$j]} (${test_subdirs[$j]})"
#
# Get the test ID.
#
      test_id="${test_ids[$j]}"
#
# Get the test description.
#
      test_desc="${test_descs[$j]}"
#
# Replace any double-quotes in the test description with two double-quotes
# since this is the way a double-quote is escaped in a CSV file, at least
# a CSV file that is read in by Google Sheets.
#
      test_desc=$( printf "%s" "${test_desc}" | sed -r -e "s/\"/\"\"/g" )
#
# Get the number of forecasts (number of times the forcast model is run,
# due to a unique starting date, an ensemble member, etc).
#
      nf="${num_fcsts[$j]}"
#
# In the following inner while-loop, we step through all alternate test 
# names (if any) that follow the current primary name and construct a 
# string (alt_test_names_subdirs) consisting of all the alternate test 
# names for this primary name, with each followed by the subdirectory 
# the corresponding symlink is in.  Note that when the CSV file is opened
# as a spreadsheet (e.g. in Google Sheets), this alternate test name 
# information all appears in one cell of the spreadsheet.
#
      alt_test_names_subdirs=""
      while [ "$jp1" -lt "${num_tests}" ]; do
        test_id_next="${test_ids[$jp1]}"
        if [ "${test_id_next}" -eq "${test_id}" ]; then
          alt_test_names_subdirs="\
${alt_test_names_subdirs}
${test_names[$jp1]} (${test_subdirs[$jp1]})"
          j="$jp1"
          jp1=$((j+1))
        else
          break
        fi
      done
#
# Write a line to the CSV file representing a single row of the spreadsheet.
# This row contains the following columns:
#
# Column 1:
# The primary test name followed by the category subdirectory it is
# located in (the latter in parentheses).
#
# Column 2:
# The alternate test names (if any) followed by their subdirectories
# (in parentheses).  Each alternate test name and subdirectory pair is
# followed by a newline, but all lines will appear in a single cell of
# the spreadsheet.
#
# Column 3:
# The test description.
#
# Column 4:
# The number of times the forecast model will be run by the test.  This
# has been calculated above using the quantities that go in Columns 5, 
# 6, ....
#
# Columns 5...:
# The values of the experiment variables specified in vars_to_extract.
#
      row_content="\
\"${prim_test_name_subdir}\" ${csv_delimiter} \
\"${alt_test_names_subdirs}\" ${csv_delimiter} \
\"${test_desc}\" ${csv_delimiter} \
\"${nf}\""

      for (( k=0; k<=$((num_vars_to_extract-1)); k++ )); do
        unset "val"
        cmd="val=\"\${${array_names_vars_to_extract[$k]}[$j]}\""
        eval $cmd
        row_content="\
${row_content} ${csv_delimiter} \
\"${val}\""
      done

      printf "%s\n" "${row_content}" >> "${csv_fp}"
#
# Update loop indices.
#
      j="$jp1"
      jp1=$((j+1))

    done

    print_info_msg "\
Successfully generated a CSV (Comma Separated Value) file (csv_fp) 
containing information on all WE2E tests:
  csv_fp = \"${csv_fp}\""
    
  fi
#
#-----------------------------------------------------------------------
#
# Use the eval function to set this function's output variables.  Note
# that each of these is set only if the corresponding input variable
# specifying the name to use for the output variable is not empty.
#
#-----------------------------------------------------------------------
#
  if [ ! -z "${output_varname_test_configs_basedir}" ]; then
    eval ${output_varname_test_configs_basedir}="${test_configs_basedir}"
  fi

  if [ ! -z "${output_varname_test_names}" ]; then
    test_names_str="( "$( printf "\"%s\" " "${test_names[@]}" )")"
    eval ${output_varname_test_names}="${test_names_str}"
  fi

  if [ ! -z "${output_varname_test_subdirs}" ]; then
    test_subdirs_str="( "$( printf "\"%s\" " "${test_subdirs[@]}" )")"
    eval ${output_varname_test_subdirs}="${test_subdirs_str}"
  fi

  if [ ! -z "${output_varname_test_ids}" ]; then
    test_ids_str="( "$( printf "\"%s\" " "${test_ids[@]}" )")"
    eval ${output_varname_test_ids}="${test_ids_str}"
  fi

  if [ ! -z "${output_varname_test_descs}" ]; then
#
# We want to treat all characters in the test descriptions literally
# when evaluating the array specified by output_varname_test_descs
# below using the eval function because otherwise, characters such as
# "$", "(", ")", etc will be interpreted as indicating the value of a
# variable, the start of an array, the end of an array, etc, and lead to
# errors.  Thus, below, when forming the array that will be passed to
# eval, we will surround each element of the local array test_descs
# in single quotes.  However, the test descriptions themselves may
# include single quotes (e.g. when a description contains a phrase such
# as "Please see the User's Guide for...").  In order to treat these
# single quotes literally (as opposed to as delimiters indicating the
# start or end of array elements), we have to pass them as separate
# strings by replacing each single quote with the following series of
# characters:
#
#   '"'"'
#
# In this, the first single quote indicates the end of the previous
# single-quoted string, the "'" indicates a string containing a literal
# single quote, and the last single quote inidicates the start of the
# next single-quoted string.
#
# For example, let's assume there are only two WE2E tests to consider.
# Assume the description of the first is
#
#   Please see the User's Guide.
#
# and that of the second is:
#
#   See description of ${DOT_OR_USCORE} in the configuration file.
#
# Then, if output_varname_test_descs is set to "some_array", the
# exact string we want to pass to eval is:
#
#   some_array=('Please see the User'"'"'s Guide.' 'See description of ${DOT_OR_USCORE} in the configuration file.')
#
    test_descs_esc_sq=()
    for (( i=0; i<=$((num_tests-1)); i++ )); do
      test_descs_esc_sq[$i]=$( printf "%s" "${test_descs[$i]}" | \
                               sed -r -e "s/'/'\"'\"'/g" )
    done
    test_descs_str="( "$( printf "'%s' " "${test_descs_esc_sq[@]}" )")"
    eval ${output_varname_test_descs}="${test_descs_str}"
  fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script or 
# function.
#
#-----------------------------------------------------------------------
#
  { restore_shell_opts; } > /dev/null 2>&1

}

