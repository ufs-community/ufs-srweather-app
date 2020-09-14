#!/bin/bash -l

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
# The current script should be located in the "tests" subdirectory of 
# the workflow directory, which we denote by homerrfs.  Thus, the work-
# flow directory (homerrfs) is the one above the directory of the cur-
# rent script.  Set HOMRErrfs accordingly.
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
"use_cron_to_relaunch" \
"cron_relaunch_intvl_mnts" \
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
  regex_search="^([^\|]*)(\|(.*)|)"
  baseline_name=$( printf "%s" "${expts_list[$i]}" | \
                   sed -r -n -e "s/${regex_search}/\1/p" )
  remainder=$( printf "%s" "${expts_list[$i]}" | \
               sed -r -n -e "s/${regex_search}/\3/p" )
#
# Get the names and corresponding values of the variables that need to
# be modified in the current baseline to obtain the current experiment.
# The following while-loop steps through all the variables listed in 
# "remainder"
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
# We require that EXPT_SUBDIR in the configuration file for the baseline 
# be set to the name of the baseline.  Check for this by extracting the
# value of EXPT_SUBDIR from the baseline configuration file and compa-
# ring it to baseline_name.
#
if [ 0 = 1 ]; then
  regex_search="^[ ]*EXPT_SUBDIR=(\")?([^ =\"]+)(.*)"
  EXPT_SUBDIR=$( sed -r -n -e "s/${regex_search}/\2/p" \
                 "${baseline_config_fp}" )
  if [ "${EXPT_SUBDIR}" != "${baseline_name}" ]; then
    print_err_msg_exit "\
The name of the experiment subdirectory (EXPT_SUBDIR) in the configura-
tion file (baseline_config_fp) for the current baseline does not match
the name of the baseline (baseline_name):
  baseline_name = \"${baseline_name}\"
  baseline_config_fp = \"${baseline_config_fp}\"
  EXPT_SUBDIR = \"${EXPT_SUBDIR}\""
  fi
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
# Set expt_subdir to the name of the current experiment.  Below, we will
# write this to the configuration file for the current experiment.
#
  expt_subdir="${expt_name}"
#
# Create a configuration file for the current experiment.  We do this by
# first copying the baseline configuration file and then modifying the 
# the values of those variables within it that are different between the
# baseline and the experiment.
#
  expt_config_fp="$ushdir/config.${expt_name}.sh"
  cp_vrfy "${baseline_config_fp}" "${expt_config_fp}"
#
#-----------------------------------------------------------------------
#
# Set the name of the experiment subdirectory (EXPT_SUBDIR) in the expe-
# riment configuration file to the name of the current experiment.
#
#-----------------------------------------------------------------------
#
  set_bash_param "${expt_config_fp}" "EXPT_SUBDIR" "${expt_subdir}"
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  MACHINE="${machine^^}"
#
#-----------------------------------------------------------------------
#
# Set any parameters in the experiment configuration file that have been
# assigned a value in the arguments list to this script (and thus are 
# not empty).  Any parameters that have not been assigned a value in the
# arguments list will retain their values in the baseline configuration
# file if they are specified in that file.  If not, they will take on
# the default values specified in the default experiment configuration
# file in the workflow repository (config_defaults.sh).
#
#-----------------------------------------------------------------------
#
  if [ ! -z "$machine" ]; then
    set_bash_param "${expt_config_fp}" "MACHINE" "${MACHINE}"
  fi

  if [ ! -z "$account" ]; then
    set_bash_param "${expt_config_fp}" "ACCOUNT" "$account"
  fi

  if [ ! -z "${use_cron_to_relaunch}" ]; then
    set_bash_param "${expt_config_fp}" "USE_CRON_TO_RELAUNCH" "${use_cron_to_relaunch}"
  fi

  if [ ! -z "${cron_relaunch_intvl_mnts}" ]; then
    set_bash_param "${expt_config_fp}" "CRON_RELAUNCH_INTVL_MNTS" "${cron_relaunch_intvl_mnts}"
  fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
# Might be better to source both config_defaults.sh and the configuration
# file for the test.  That way, variables will have default values and 
# we don't have to check whether or not they're set.  Also, do the sourcing
# just once if possible instead of many times as below.
#

  PREDEF_GRID_NAME=$( 
    . ${expt_config_fp} 
    if [ -z "${PREDEF_GRID_NAME+x}" ]; then
      echo ""
    else
      echo "${PREDEF_GRID_NAME}" 
    fi
  )
#echo "PREDEF_GRID_NAME = \"${PREDEF_GRID_NAME}\""
#exit

  RUN_TASK_MAKE_GRID=$( . ${expt_config_fp} ; echo "${RUN_TASK_MAKE_GRID}" )

  if [ ${RUN_TASK_MAKE_GRID} = "FALSE" ]; then

    if [ "$MACHINE" = "HERA" ]; then
      GRID_DIR="/scratch2/BMC/det/FV3LAM_pregen/grid/${PREDEF_GRID_NAME}"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      GRID_DIR="/glade/p/ral/jntp/UFS_CAM/FV3LAM_pregen/grid/${PREDEF_GRID_NAME}"
    else
      print_err_msg_exit "\
The directory (GRID_DIR) in which the pregenerated grid files are located
has not been specified for this machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    { cat << EOM >> ${expt_config_fp}
#
# Directory containing the pregenerated grid files.
#
GRID_DIR="${GRID_DIR}"
EOM
    } || print_err_msg_exit "\
Heredoc (cat) command to append the variable GRID_DIR containing the 
pregenerated grid files to the workflow configuration file returned 
with a nonzero status."

  fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  RUN_TASK_MAKE_OROG=$( . ${expt_config_fp} ; echo "${RUN_TASK_MAKE_OROG}" )

  if [ ${RUN_TASK_MAKE_OROG} = "FALSE" ]; then

    if [ "$MACHINE" = "HERA" ]; then
      OROG_DIR="/scratch2/BMC/det/FV3LAM_pregen/orog/${PREDEF_GRID_NAME}"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      OROG_DIR="/glade/p/ral/jntp/UFS_CAM/FV3LAM_pregen/orog/${PREDEF_GRID_NAME}"
    else
      print_err_msg_exit "\
The directory (OROG_DIR) in which the pregenerated grid files are located
has not been specified for this machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    { cat << EOM >> ${expt_config_fp}
#
# Directory containing the pregenerated grid files.
#
OROG_DIR="${OROG_DIR}"
EOM
    } || print_err_msg_exit "\
Heredoc (cat) command to append the variable OROG_DIR containing the 
pregenerated orography files to the workflow configuration file returned 
with a nonzero status."

  fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  RUN_TASK_MAKE_SFC_CLIMO=$( . ${expt_config_fp} ; echo "${RUN_TASK_MAKE_SFC_CLIMO}" )

  if [ ${RUN_TASK_MAKE_SFC_CLIMO} = "FALSE" ]; then

    if [ "$MACHINE" = "HERA" ]; then
      SFC_CLIMO_DIR="/scratch2/BMC/det/FV3LAM_pregen/sfc_climo/${PREDEF_GRID_NAME}"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      SFC_CLIMO_DIR="/glade/p/ral/jntp/UFS_CAM/FV3LAM_pregen/sfc_climo/${PREDEF_GRID_NAME}"
    else
      print_err_msg_exit "\
The directory (SFC_CLIMO_DIR) in which the pregenerated grid files are 
located has not been specified for this machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    { cat << EOM >> ${expt_config_fp}
#
# Directory containing the pregenerated grid files.
#
SFC_CLIMO_DIR="${SFC_CLIMO_DIR}"
EOM
    } || print_err_msg_exit "\
Heredoc (cat) command to append the variable SFC_CLIMO_DIR containing 
the pregenerated grid files to the workflow configuration file returned 
with a nonzero status."

  fi

#On hera:

#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  CCPP_PHYS_SUITE=$( . ${expt_config_fp} ; echo "${CCPP_PHYS_SUITE}" )

  if [ "${CCPP_PHYS_SUITE}" = "FV3_RRFS_v1beta" ]; then

    if [ "$MACHINE" = "HERA" ]; then
      GWD_RRFS_v1beta_BASEDIR="/scratch2/BMC/det/FV3LAM_pregen/orog"
    elif [ "$MACHINE" = "JET" ]; then
      GWD_RRFS_v1beta_BASEDIR="/lfs4/BMC/wrfruc/FV3LAM_pregen/orog"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      GWD_RRFS_v1beta_BASEDIR="/glade/p/ral/jntp/UFS_CAM/FV3LAM_pregen/orog"
    else
      print_err_msg_exit "\
The base directory (GWD_RRFS_v1beta_BASEDIR) in which the orography 
statistics files needed by the gravity wave drag parameterization in 
the current physics suite (CCPP_PHYS_SUITE) should be located has not 
been specified for this machine (MACHINE):
  CCPP_PHYS_SUITE= \"${CCPP_PHYS_SUIT}\"
  MACHINE= \"${MACHINE}\""
    fi

    { cat << EOM >> ${expt_config_fp}
#
# Directory containing the orography statistics files needed by the 
# gravity wave drag parameterization.
#
GWD_RRFS_v1beta_BASEDIR="${GWD_RRFS_v1beta_BASEDIR}"
EOM
    } || print_err_msg_exit "\
Heredoc (cat) command to append the variable GWD_RRFS_v1beta_BASEDIR 
containing the orography statistics files needed by the gravity wave 
drag parameterization to the workflow configuration file returned with 
a nonzero status."

  fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  RUN_ENVIR=$( . ${expt_config_fp} ; echo "${RUN_ENVIR}" )

  if [ "${RUN_ENVIR}" = "nco" ]; then

# Note:  Need COMINgfs only if using FV3GFS or GSMGFS as the external 
# model for ICs or LBCs.  Modify the logic below later.

    if [ "$MACHINE" = "HERA" ]; then
      COMINgfs="/scratch1/NCEPDEV/hwrf/noscrub/hafs-input/COMGFS"
      STMP="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/NCO_dirs/stmp"
      PTMP="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/NCO_dirs/ptmp"
    elif [ "$MACHINE" = "JET" ]; then
      COMINgfs="/lfs1/HFIP/hwrf-data/hafs-input/COMGFS"
      STMP="/mnt/lfs1/BMC/fim/Gerard.Ketefian/UFS_CAM/NCO_dirs/stmp"
      PTMP="/mnt/lfs1/BMC/fim/Gerard.Ketefian/UFS_CAM/NCO_dirs/ptmp"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      COMINgfs="/glade/scratch/ketefian/NCO_dirs/COMGFS"
      STMP="/glade/scratch/ketefian/NCO_dirs/stmp"
      PTMP="/glade/scratch/ketefian/NCO_dirs/ptmp"
    else
      print_err_msg_exit "\
The directories COMINgfs, STMP, and PTMP that need to be specified when
running the workflow in NCO-mode (i.e. RUN_ENVIR set to \"nco\") have 
not been specified for this machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    { cat << EOM >> ${expt_config_fp}
#
# Directories COMINgfs, STMP, and PTMP that need to be specified when
# running the workflow in NCO-mode (i.e. RUN_ENVIR set to "nco").
#
COMINgfs="${COMINgfs}"
STMP="${STMP}"
PTMP="${PTMP}"
EOM
    } || print_err_msg_exit "\
Heredoc (cat) command to append variables specifying user-staged external 
model files and locations to the workflow configuration file returned with 
a nonzero status."

  fi
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
  do_user_staged_extrn="TRUE"  # Change this to an input argument at some point.

  if [ ${do_user_staged_extrn} = "TRUE" ]; then

    EXTRN_MDL_NAME_ICS=$( . ${expt_config_fp} ; echo "${EXTRN_MDL_NAME_ICS}" )
    EXTRN_MDL_NAME_LBCS=$( . ${expt_config_fp} ; echo "${EXTRN_MDL_NAME_LBCS}" )
    FCST_LEN_HRS=$( . ${expt_config_fp} ; echo "${FCST_LEN_HRS}" )
    LBC_SPEC_INTVL_HRS=$( . ${expt_config_fp} ; echo "${LBC_SPEC_INTVL_HRS}" )

    if [ "$MACHINE" = "HERA" ]; then
      extrn_mdl_source_baseir="/scratch2/BMC/det/Gerard.Ketefian/UFS_CAM/staged_extrn_mdl_files"
    elif [ "$MACHINE" = "JET" ]; then
      extrn_mdl_source_baseir="/mnt/lfs1/BMC/fim/Gerard.Ketefian/UFS_CAM/staged_extrn_mdl_files"
    elif [ "$MACHINE" = "CHEYENNE" ]; then
      extrn_mdl_source_baseir="/glade/p/ral/jntp/UFS_CAM/staged_extrn_mdl_files"
    else
      print_err_msg_exit "\
The base directory (extrn_mdl_source_baseir) in which the user-staged 
external model files should be located has not been specified for this 
machine (MACHINE):
  MACHINE= \"${MACHINE}\""
    fi

    EXTRN_MDL_SOURCE_DIR_ICS="${extrn_mdl_source_baseir}/${EXTRN_MDL_NAME_ICS}"
    if [ "${EXTRN_MDL_NAME_ICS}" = "FV3GFS" ] || \
       [ "${EXTRN_MDL_NAME_ICS}" = "GSMGFS" ]; then
      EXTRN_MDL_FILES_ICS=( "gfs.atmanl.nemsio" "gfs.sfcanl.nemsio" )
    elif [ "${EXTRN_MDL_NAME_ICS}" = "HRRRX" ] || \
         [ "${EXTRN_MDL_NAME_ICS}" = "RAPX" ]; then
      EXTRN_MDL_FILES_ICS=( "${EXTRN_MDL_NAME_ICS,,}.out.for_f000" )
    fi

    EXTRN_MDL_SOURCE_DIR_LBCS="${extrn_mdl_source_baseir}/${EXTRN_MDL_NAME_LBCS}"
    EXTRN_MDL_FILES_LBCS=( $( seq ${LBC_SPEC_INTVL_HRS} ${LBC_SPEC_INTVL_HRS} ${FCST_LEN_HRS} ) )
    if [ "${EXTRN_MDL_NAME_LBCS}" = "FV3GFS" ] || \
       [ "${EXTRN_MDL_NAME_LBCS}" = "GSMGFS" ]; then
      EXTRN_MDL_FILES_LBCS=( "${EXTRN_MDL_FILES_LBCS[@]/#/gfs.atmf00}" )
      EXTRN_MDL_FILES_LBCS=( "${EXTRN_MDL_FILES_LBCS[@]/%/.nemsio}" )
    elif [ "${EXTRN_MDL_NAME_LBCS}" = "HRRRX" ] || \
         [ "${EXTRN_MDL_NAME_LBCS}" = "RAPX" ]; then
      EXTRN_MDL_FILES_LBCS=( "${EXTRN_MDL_FILES_LBCS[@]/#/${EXTRN_MDL_NAME_LBCS,,}.out.for_f00}" )
    fi

    { cat << EOM >> ${expt_config_fp}
#
# Locations and names of user-staged external model files for generating
# ICs and LBCs.
#
EXTRN_MDL_SOURCE_DIR_ICS="${EXTRN_MDL_SOURCE_DIR_ICS}"
EXTRN_MDL_FILES_ICS=( $( printf "\"%s\" " "${EXTRN_MDL_FILES_ICS[@]}" ))
EXTRN_MDL_SOURCE_DIR_LBCS="${EXTRN_MDL_SOURCE_DIR_LBCS}"
EXTRN_MDL_FILES_LBCS=( $( printf "\"%s\" " "${EXTRN_MDL_FILES_LBCS[@]}" ))
EOM
    } || print_err_msg_exit "\
Heredoc (cat) command to append variables specifying user-staged external 
model files and locations to the workflow configuration file returned with 
a nonzero status."

  fi
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
  mv_vrfy -f "${expt_config_fp}" "$ushdir/config.sh"
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

