#!/bin/bash 

#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# The current script should be located in the "tests" subdirectory of the
# workflow's top-level directory, which we denote by homerrfs.  Thus,
# homerrfs is the directory one level above the directory in which the
# current script is located.  Set homerrfs accordingly.
#
#-----------------------------------------------------------------------
#
homerrfs=${scrfunc_dir%/*}
#
#-----------------------------------------------------------------------
#
# Set directories.
#
#-----------------------------------------------------------------------
#
ushdir="$homerrfs/ush"
baseline_configs_dir="$homerrfs/tests/baseline_configs"
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
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.
# Then process the arguments provided to this script/function (which
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
"expts_file" \
"machine" \
"account" \
"expt_basedir" \
"testset_name" \
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
# TRUE.
#
#-----------------------------------------------------------------------
#
print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Check arguments.
#
#-----------------------------------------------------------------------
#
if [ 1 = 0 ]; then
  if [ "$#" -ne 1 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Number of arguments specified:  $#

Usage:

  ${scrfunc_fn}  expts_file

where expts_file is the name of the file containing the list of experi-
ments to run.  If expts_file is the absolute path to a file, it is used
as is.  If it is a relative path (including just a file name), it is as-
sumed to be given relative to the path from which this script is called.
"

  fi
fi
#
#-----------------------------------------------------------------------
#
# Verify that an experiments list file has been specified.  If not,
# print out an error message and exit.
#
#-----------------------------------------------------------------------
#
# Note:
# The function process_args() should be modified to look for required
# arguments, which can be denoted by appending to the name of a required
# argument the string "; REQUIRED".  It can then check that all required
# arguments are in fact specified in the arguments list.  That way, the
# following if-statement will not be needed since process_args() will
# catch the case of missing required arguments.
#
if [ -z "${expts_file}" ] || \
   [ -z "${machine}" ] || \
   [ -z "${account}" ]; then
  print_err_msg_exit "\
An experiments list file (expts_file), a machine name (machine), and an
account name (account) must be specified as input arguments to this
script.  One or more of these is currently set to an empty string:
  expts_file = \"${expts_file}\"
  machine = \"${machine}\"
  account = \"${account}\"
Use the following format to specify these in the argument list passed to
this script:
  ${scrfunc_fn}  \\
    expts_file=\"name_of_file_or_full_path_to_file\" \\
    machine=\"name_of_machine_to_run_on\" \\
    account=\"name_of_hpc_account_to_use\" \\
    ..."
fi
#
#-----------------------------------------------------------------------
#
# Get the full path to the experiments list file and verify that it exists.
#
#-----------------------------------------------------------------------
#
expts_list_fp=$( readlink -f "${expts_file}" )

if [ ! -f "${expts_list_fp}" ]; then
  print_err_msg_exit "\
The experiments list file (expts_file) specified as an argument to this
script (and with full path given by expts_list_fp) does not exist:
  expts_file = \"${expts_file}\"
  expts_list_fp = \"${expts_list_fp}\""
fi
#
#-----------------------------------------------------------------------
#
# Read in the list of experiments (which might be baselines) to run.
# This entails reading in each line of the file expts_list.txt in the
# directory of this script and saving the result in the array variable
# expts_list.  Note that each line of expts_list.txt has the form
#
#   BASELINE_NAME  |  VAR_NAME_1="VAR_VALUE_1"  |  ... |  VAR_NAME_N="VAR_VALUE_N"
#
# where BASELINE_NAME is the name of the baseline and the zero or more
# variable name-value pairs following the baseline name are a list of
# variables to modify from the baseline.  Note that:
#
# 1) There must exist a experiment/workflow configuration file named
#    config.BASELINE_NAME.sh in a subdirectory named baseline_configs
#    in the directory of this script.
#
# 2) The variable name-value pairs on each line of the expts_list.txt
#    file are delimited from the baseline and from each other by pipe
#    characters (i.e. "|").
#
#-----------------------------------------------------------------------
#
print_info_msg "
Reading in list of forecast experiments from file
  expts_list_fp = \"${expts_list_fp}\"
and storing result in the array \"all_lines\" (one array element per expe-
riment)..."

readarray -t all_lines < "${expts_list_fp}"

all_lines_str=$( printf "\'%s\'\n" "${all_lines[@]}" )
print_info_msg "
All lines from experiments list file (expts_list_fp) read in, where:
  expts_list_fp = \"${expts_list_fp}\"
Contents of file are (line by line, each line within single quotes, and
before any processing):

${all_lines_str}
"
#
#-----------------------------------------------------------------------
#
# Loop through the elements of all_lines and modify each line to remove
# leading and trailing whitespace and any whitespace before and after the
# field separator character (which is the pipe character, "|").  Also,
# drop any elements that are empty after this processing, and save the
# resulting set of non-empty elements in the array expts_list.
#
#-----------------------------------------------------------------------
#
expts_list=()
field_separator="\|"  # Need backslash as an escape sequence in the sed commands below.

j=0
num_lines="${#all_lines[@]}"
for (( i=0; i<=$((num_lines-1)); i++ )); do
#
# Remove all leading and trailing whitespace from the current element of
# all_lines.
#
  all_lines[$i]=$( printf "%s" "${all_lines[$i]}" | \
                   sed -r -e "s/^[ ]*//" -e "s/[ ]*$//" )
#
# Remove spaces before and after all field separators in the current
# element of all_lines.  Note that we use the pipe symbol, "|", as the
# field separator.
#
  all_lines[$i]=$( printf "%s" "${all_lines[$i]}" | \
                   sed -r -e "s/[ ]*${field_separator}[ ]*/${field_separator}/g" )
#
# If the last character of the current line is a field separator, remove
# it.
#
  all_lines[$i]=$( printf "%s" "${all_lines[$i]}" | \
                   sed -r -e "s/${field_separator}$//g" )
#
# If after the processing above the current element of all_lines is not
# empty, save it as the next element of expts_list.
#
  if [ ! -z "${all_lines[$i]}" ]; then
    expts_list[$j]="${all_lines[$i]}"
    j=$((j+1))
  fi

done
#
#-----------------------------------------------------------------------
#
# Get the number of experiments to run and print out an informational
# message.
#
#-----------------------------------------------------------------------
#
num_expts="${#expts_list[@]}"
expts_list_str=$( printf "  \'%s\'\n" "${expts_list[@]}" )
print_info_msg "
After processing, the number of experiments to run (num_expts) is:
  num_expts = ${num_expts}
The list of forecast experiments to run (one experiment per line) is gi-
ven by:
${expts_list_str}
"
#
#-----------------------------------------------------------------------
#
# Loop through the elements of the array expts_list.  For each element
# (i.e. for each experiment), generate an experiment directory and cor-
# responding workflow and then launch the workflow.
#
#-----------------------------------------------------------------------
#
for (( i=0; i<=$((num_expts-1)); i++ )); do

  print_info_msg "
Processing experiment \"${expts_list[$i]}\" ..."
#
# Get the name of the baseline on which the current experiment is based.
# Then save the remainder of the current element of expts_list in the
# variable "remainder".  Note that if this variable is empty, then the
# current experiment is identical to the current baseline.  If not, then
# "remainder" contains the modifications that need to be made to the
# current baseline to obtain the current experiment.
#
  regex_search="^([^${field_separator}]*)(${field_separator}(.*)|)"
  baseline_name=$( printf "%s" "${expts_list[$i]}" | \
                   sed -r -n -e "s/${regex_search}/\1/p" )
  remainder=$( printf "%s" "${expts_list[$i]}" | \
               sed -r -n -e "s/${regex_search}/\3/p" )
#
# Get the names and corresponding values of the variables that need to
# be modified in the current baseline to obtain the current experiment.
# The following while-loop steps through all the variables listed in
# "remainder".
#
  modvar_name=()
  modvar_value=()
  num_mod_vars=0
  while [ ! -z "${remainder}" ]; do
#
# Get the next variable-value pair in remainder, and save what is left
# of remainder back into itself.
#
    next_field=$( printf "%s" "$remainder" | \
                  sed -r -e "s/${regex_search}/\1/" )
    remainder=$( printf "%s" "$remainder" | \
                 sed -r -e "s/${regex_search}/\3/" )
#
# Save the name of the variable in the variable-value pair obtained
# above in the array modvar_name.  Then save the value in the variable-
# value pair in the array modvar_value.
#
    modvar_name[${num_mod_vars}]=$( printf "%s" "${next_field}" | \
                                    sed -r -e "s/^([^=]*)=(.*)/\1/" )
    modvar_value[${num_mod_vars}]=$( printf "%s" "${next_field}" | \
                                     sed -r -e "s/^([^=]*)=(\")?([^\"]+*)(\")?/\3/" )
#
# Increment the index that keeps track of the number of variables that
# need to be modified in the current baseline to obtain the current ex-
# periment.
#
    num_mod_vars=$((num_mod_vars+1))

  done
#
# Generate the path to the configuration file for the current baseline.
# This will be modified to obtain the configuration file for the current
# experiment.
#
  baseline_config_fp="${baseline_configs_dir}/config.${baseline_name}.sh"
#
# Print out an error message and exit if a configuration file for the
# current baseline does not exist.
#
  if [ ! -f "${baseline_config_fp}" ]; then
    print_err_msg_exit "\
The experiment/workflow configuration file (baseline_config_fp) for the
specified baseline (baseline_name) does not exist:
  baseline_name = \"${baseline_name}\"
  baseline_config_fp = \"${baseline_config_fp}\"
Please correct and rerun."
  fi
#
# Generate a name for the current experiment.  We start with the name of
# the current baseline and modify it to indicate which variables must be
# reset to obtain the current experiment.
#
  expt_name="${baseline_name}"
  for (( j=0; j<${num_mod_vars}; j++ )); do
    if [ $j -lt ${#modvar_name[@]} ]; then
      expt_name="${expt_name}__${modvar_name[$j]}.eq.${modvar_value[$j]}"
    else
      break
    fi
  done
#
# Set the full path to the workflow configuration file for the current 
# experiment that the workflow generation script will read in.  For now, 
# include the name of the test in the file name.  Once this file is 
# constructed below, it will get renamed to the file name that the 
# generation script expects (which is "config.sh").  Also, if a preexisting
# file of this name exists, delete it.
#
  expt_config_fp="$ushdir/config.${expt_name}.sh"
  rm_vrfy -rf "${expt_config_fp}"
#
#-----------------------------------------------------------------------
#
# Source the default workflow configuration file.  Note that we need to
# re-source this file for each WE2E test because the previous test may 
# change these default values when the test-specific configuration file
# is sourced below.  We need to reset the workflow variables because some 
# of the tests rely on the default values.
#
#-----------------------------------------------------------------------
#
  . ${ushdir}/config_defaults.sh
#
#-----------------------------------------------------------------------
#
# Source the WE2E test configuration file.  This will overwrite some of
# the workflow variable values in the default workflow configuration file
# sourced above.
#
#-----------------------------------------------------------------------
#
  . ${baseline_config_fp}
#
#-----------------------------------------------------------------------
#
# Set various workflow variables that depend on inputs to this script (as
# opposed to information in the test-specific configuration file specified 
# by baseline_config_fp).  Note that any values of these parameters 
# specified in the default workflow configuration file (config_defaults.sh) 
# or in the test-specific configuraiton file (baseline_config_fp) that 
# are sourced above will be overwritten by the settings below.
#
# Note that EXPT_BASEDIR is set below as follows:
# * If neither of the command line arguments expt_basedir and testset_name 
#   to this script are specified, EXPT_BASEDIR gets set to a null string.
# * If expt_basedir is specified but testset_name is not, EXPT_BASEDIR
#   gets set to expt_basedir.
# * If expt_basedir is not specified but testset_name is, EXPT_BASEDIR
#   gets set to testset_name.
# * If expt_basedir and testset_name are both specified, EXPT_BASEDIR 
#   gets set to expt_basedir with testset_name appended to it (with a
#   "/" in between).
#
# Note also that if EXPT_BASEDIR ends up getting set to a null string, 
# the workflow generation script that gets called further below will set 
# it to a default path; if it gets set to a relative path, then the workflow 
# generation script will set it to a path consisting of a default path 
# with the relative path appended to it; and if it gets set to an absolute 
# path, then the workflow will leave it set to that path.
#
#-----------------------------------------------------------------------
#
  MACHINE="${machine^^}"
  ACCOUNT="${account}"

# Note that if expt_basedir is a null (or unset) string, ${expt_basedir:+/} 
# gets set to a null string; otherwise, it gets set to "/".
  EXPT_BASEDIR="${expt_basedir}${expt_basedir:+/}${testset_name}"
# Remove any trailing "/" from EXPT_BASEDIR.
  EXPT_BASEDIR="${EXPT_BASEDIR%%/}"

  EXPT_SUBDIR="${expt_name}"
  USE_CRON_TO_RELAUNCH=${use_cron_to_relaunch:-"TRUE"}
  CRON_RELAUNCH_INTVL_MNTS=${cron_relaunch_intvl_mnts:-"02"}
  VERBOSE=${verbose:-"TRUE"}

  str="\
#
# The machine on which to run, the account to which to charge computational
# resources, the base directory in which to create the experiment directory
# (if different from the default location), and the name of the experiment
# subdirectory.
#
MACHINE=\"${MACHINE}\"
ACCOUNT=\"${ACCOUNT}\""

  if [ ! -z "${EXPT_BASEDIR}" ]; then
    str=${str}"
EXPT_BASEDIR=\"${EXPT_BASEDIR}\""
  fi

  str=${str}"
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
# Append test-specific values to the workflow configuration file.
#
#-----------------------------------------------------------------------
#
  str=${str}"
#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
# The following section is a copy of the base configuration of this WE2E 
# test.
#
"
  str=${str}$( cat "${baseline_config_fp}" )
  str=${str}"
#
# End of section from the base configuration file of this WE2E test.
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------"
#
#-----------------------------------------------------------------------
#
# If not running one or more of the grid, orography, and surface climatology
# file generation tasks, specify directories in which pregenerated files
# can be found.
#
#-----------------------------------------------------------------------
#
  if [ ${RUN_TASK_MAKE_GRID} = "FALSE" ] || \
     [ ${RUN_TASK_MAKE_OROG} = "FALSE" ] || \
     [ ${RUN_TASK_MAKE_SFC_CLIMO} = "FALSE" ]; then

# Note:
# Now that the "grid", "orog", and "sfc_climo" sub-subdirectories under
# pregen_basedir have been removed, we don't need the variable pregen_basedir
# and can instead have the variable "pregen_dir" that gets set to 
# ${pregen_basedir}/${PREDEF_GRID_NAME}, and pregen_dir can then be used
# to set GRID_DIR, OROG_DIR, and/or SFC_CLIMO_DIR below.

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

  fi
#
# Directory for pregenerated grid files.
#
  if [ ${RUN_TASK_MAKE_GRID} = "FALSE" ]; then
    GRID_DIR="${pregen_basedir}/${PREDEF_GRID_NAME}"
    str=${str}"
#
# Directory containing the pregenerated grid files.
#
GRID_DIR=\"${GRID_DIR}\""

  fi
#
# Directory for pregenerated orography files.
#
  if [ ${RUN_TASK_MAKE_OROG} = "FALSE" ]; then
    OROG_DIR="${pregen_basedir}/${PREDEF_GRID_NAME}"
    str=${str}"
#
# Directory containing the pregenerated orography files.
#
OROG_DIR=\"${OROG_DIR}\""

  fi
#
# Directory for pregenerated surface climatology files.
#
  if [ ${RUN_TASK_MAKE_SFC_CLIMO} = "FALSE" ]; then
    SFC_CLIMO_DIR="${pregen_basedir}/${PREDEF_GRID_NAME}"
    str=${str}"
#
# Directory containing the pregenerated surface climatology files.
#
SFC_CLIMO_DIR=\"${SFC_CLIMO_DIR}\""

  fi
#
#-----------------------------------------------------------------------
#
# If using the FV3_HRRR physics suite, set the base directory in which 
# the pregenerated orography statistics files needed by the gravity wave 
# drag parameterization in this suite are located.
#
#-----------------------------------------------------------------------
#
  if [ "${CCPP_PHYS_SUITE}" = "FV3_HRRR" ]; then

    if [ "$MACHINE" = "WCOSS_CRAY" ]; then
      GWD_HRRRsuite_BASEDIR="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/FV3LAM_pregen"
    elif [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
      GWD_HRRRsuite_BASEDIR="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/FV3LAM_pregen"
    elif [ "$MACHINE" = "HERA" ]; then
      GWD_HRRRsuite_BASEDIR="/scratch2/BMC/det/FV3LAM_pregen"
    elif [ "$MACHINE" = "JET" ]; then
      GWD_HRRRsuite_BASEDIR="/mnt/lfs4/BMC/wrfruc/FV3-LAM/pregen"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      GWD_HRRRsuite_BASEDIR="/glade/p/ral/jntp/UFS_CAM/FV3LAM_pregen"
    else
      print_err_msg_exit "\
The base directory (GWD_HRRRsuite_BASEDIR) containing the pregenerated 
orography statistics files needed by the gravity wave drag parameterization
in the FV3_HRRR physics suite has not been specified for this machine 
(MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    str=${str}"
#
# Base directory containing the pregenerated orography statistics files 
# needed by the gravity wave drag parameterization in the FV3_HRRR physics 
# suite.
#
GWD_HRRRsuite_BASEDIR=\"${GWD_HRRRsuite_BASEDIR}\""

  fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  if [ "${RUN_ENVIR}" = "nco" ]; then
#
# Set RUN and envir.
#
    str=${str}"
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

    str=${str}"
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
        COMINgfs="/scratch1/NCEPDEV/hwrf/noscrub/hafs-input/COMGFS"
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

      str=${str}"
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

    str=${str}"
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
#
#
#-----------------------------------------------------------------------
#
  if [ ${USE_USER_STAGED_EXTRN_FILES} = "TRUE" ]; then

    if [ "$MACHINE" = "WCOSS_CRAY" ]; then
      extrn_mdl_source_basedir="/gpfs/hps3/emc/meso/noscrub/UFS_SRW_App/extrn_mdl_files"
    elif [ "$MACHINE" = "WCOSS_DELL_P3" ]; then
      extrn_mdl_source_basedir="/gpfs/dell2/emc/modeling/noscrub/UFS_SRW_App/extrn_mdl_files"
    elif [ "$MACHINE" = "HERA" ]; then
      extrn_mdl_source_basedir="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/staged_extrn_mdl_files"
    elif [ "$MACHINE" = "JET" ]; then
      extrn_mdl_source_basedir="/mnt/lfs1/BMC/fim/Gerard.Ketefian/UFS_CAM/staged_extrn_mdl_files"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      extrn_mdl_source_basedir="/glade/p/ral/jntp/UFS_CAM/staged_extrn_mdl_files"
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

    str=${str}"
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
# On some machines (e.g. cheyenne), some tasks take many attempts to 
# succeed.  To make it more convenient to run the WE2E tests on these
# machines without manual intervention, change the number of attempts
# for such tasks on those machines to be more than one.
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

    str=${str}"
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
#
#
#-----------------------------------------------------------------------
#
  printf "%s" "$str" > "${expt_config_fp}"
#
#-----------------------------------------------------------------------
#
# Set the values of those parameters in the experiment configuration file
# that need to be adjusted from their baseline values (as specified in
# the current line of the experiments list file) to obtain the configuration
# file for the current experiment.
#
#-----------------------------------------------------------------------
#
  printf ""
  for (( j=0; j<${num_mod_vars}; j++ )); do
    set_bash_param "${expt_config_fp}" "${modvar_name[$j]}" "${modvar_value[$j]}"
  done
#
# Move the current experiment's configuration file into the directory in
# which the experiment generation script expects to find it, and in the
# process rename the file to the name that the experiment generation script
# expects it to have.
#
  mv_vrfy -f "${expt_config_fp}" "$ushdir/${EXPT_CONFIG_FN}"
#
#-----------------------------------------------------------------------
#
# Call the experiment/workflow generation script to generate an experi-
# ment directory and rocoto workflow XML for the current experiment.
#
#-----------------------------------------------------------------------
#
  $ushdir/generate_FV3LAM_wflow.sh || \
    print_err_msg_exit "\
Could not generate an experiment/workflow for the test specified by
expt_name:
  expt_name = \"${expt_name}\""

done
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

