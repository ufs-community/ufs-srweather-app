#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHDIR/source_util_funcs.sh
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
# Check arguments.
#
#-----------------------------------------------------------------------
#
if [ "$#" -ne 2 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Number of arguments specified:  $#

Usage:

  ${scrfunc_fn}  task_name  jjob_fp

where the arguments are defined as follows:

  task_name:
  The name of the rocoto task for which this script will load modules
  and launch the J-job.

  jjob_fp
  The full path to the J-job script corresponding to task_name.  This
  script will launch this J-job using the \"exec\" command (which will
  first terminate this script and then launch the j-job; see man page of
  the \"exec\" command).
"

fi
#
#-----------------------------------------------------------------------
#
# Source the script that initializes the Lmod (Lua-based module) system/
# software for handling modules.  This script defines the module() and
# other functions.  These are needed so we can perform the "module use
# ..." and "module load ..." calls later below that are used to load the
# appropriate module file for the specified task.
#
# Note that the build of the FV3 forecast model code generates the shell
# script at
#
#   ${UFS_WTHR_MDL_DIR}/NEMS/src/conf/module-setup.sh
#
# that can be used to initialize the Lmod (Lua-based module) system/
# software for handling modules.  This script:
#
# 1) Detects the shell in which it is being invoked (i.e. the shell of
#    the "parent" script in which it is being sourced).
# 2) Detects the machine it is running on and and calls the appropriate
#    (shell- and machine-dependent) initalization script to initialize
#    Lmod.
# 3) Purges all modules.
# 4) Uses the "module use ..." command to prepend or append paths to
#    Lmod's search path (MODULEPATH).
#
# We could use this module-setup.sh script to initialize Lmod, but since
# it is only found in the forecast model's directory tree, here we pre-
# fer to perform our own initialization.  Ideally, there should be one
# module-setup.sh script that is used by all external repos/codes, but
# such a script does not exist.  If/when it does, we will consider
# switching to it instead of using the case-statement below.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Initializing the shell function \"module()\" (and others) in order to be
able to use \"module load ...\" to load necessary modules ..."

case "$MACHINE" in
#
  "WCOSS_CRAY")
    . /opt/modules/default/init/sh
    ;;
#
  "WCOSS_DELL_P3")
    . /usrx/local/prod/lmod/lmod/init/sh
    ;;
#
  "HERA")
    . /apps/lmod/lmod/init/sh
    ;;
#
  "ORION")
    . /apps/lmod/lmod/init/sh
    ;;
#
  "JET")
    . /apps/lmod/lmod/init/sh
    ;;
#
  "CHEYENNE")
    . /glade/u/apps/ch/opt/lmod/8.1.7/lmod/8.1.7/init/sh
    ;;
#
  *)
    print_err_msg_exit "\
The script to source to initialize lmod (module loads) has not yet been
specified for the current machine (MACHINE):
  MACHINE = \"$MACHINE\""
    ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Get the task name and the name of the J-job script.
#
#-----------------------------------------------------------------------
#
task_name="$1"
jjob_fp="$2"
#
#-----------------------------------------------------------------------
#
# Sourcing ufs-srweather-app README file (in directory specified by mod-
# ules_dir) for the specified task
#
#-----------------------------------------------------------------------
#
machine=${MACHINE,,}
env_fn="build_${machine}_${COMPILER}.env"
env_fp="${SR_WX_APP_TOP_DIR}/env/${env_fn}"
source "${env_fp}" || print_err_msg_exit "\
Sourcing platform- and compiler-specific environment file (env_fp) for the 
workflow task specified by task_name failed:
  task_name = \"${task_name}\"
  env_fp = \"${env_fp}\""
#
#-----------------------------------------------------------------------
#
# Set the directory (modules_dir) in which the module files for the va-
# rious workflow tasks are located.  Also, set the name of the module
# file for the specified task.
#
# A module file is a file whose first line is the "magic cookie" string
# '#%Module'.  It is interpreted by the "module load ..." command.  It
# sets environment variables (including prepending/appending to paths)
# and loads modules.
#
# The regional_workflow repository contains module files for all the
# workflow tasks in the template rocoto XML file for the FV3-LAM work-
# flow.  The full path to a module file for a given task is
#
#   $HOMErrfs/modulefiles/$machine/${task_name}
#
# where HOMErrfs is the base directory of the workflow, machine is the
# name of the machine that we're running on (in lowercase), and task_-
# name is the name of the current task (an input to this script). The
# collection of modulefiles is staged by the generate_workflow.sh
# script. Please see that script for information on their creation.
#
#-----------------------------------------------------------------------
#
modules_dir="$HOMErrfs/modulefiles/tasks/$machine"
modulefile_name="${task_name}"
default_modules_dir="$HOMErrfs/modulefiles"
default_modulefile_name="${machine}.default"
use_default_modulefile=0
#######
####### The following lines (199-276) can be removed once we confirm
####### that the new method of setting environment variables and loading
####### modules will remain permanent.
#######
#
#-----------------------------------------------------------------------
#
# This comment needs to be updated:
#
# Use the "readlink" command to resolve the full path to the module file
# and then verify that the file exists.  This is not necessary for most
# tasks, but for the run_fcst task, when CCPP is enabled, the module
# file in the modules directory is not a regular file but a symlink to a
# file in the ufs_weather_model external repo.  This latter target file
# will exist only if the forecast model code has already been built.
# Thus, we now check to make sure that the module file exits.
#
#-----------------------------------------------------------------------
#
#if [ "${machine}" = "unknown" ]; then
#
# This if-statement allows for a graceful exit in the case in which module 
# files are not needed for the task.
# This is not currently used but reserved for future development.
#
#  print_info_msg "
#Module files are not needed for this task (task_name) and machine (machine):
#  task_name = \"${task_name}\"
#  machine = \"${machine}\""

#else

#  modulefile_path=$( readlink -f "${modules_dir}/${modulefile_name}" )

#  if [ ! -f "${modulefile_path}" ]; then

#    default_modulefile_path=$( readlink -f "${default_modules_dir}/${default_modulefile_name}" )
#    if [ -f "${default_modulefile_path}" ]; then
#
# If the task-specific modulefile does not exist but a default one does, 
# use it!
#
#      print_info_msg "$VERBOSE" "
#A task-specific modulefile (modulefile_path) does not exist for this task 
#(task_name) and machine (machine) combination:
#  task_name = \"${task_name}\"
#  machine = \"${machine}\"
#  modulefile_path = \"${modulefile_path}\"
#Will attempt to use the default modulefile (default_modulefile_path):
#  default_modulefile_path = \"${default_modulefile_path}\""
#
#      modules_dir="${default_modules_dir}"
#      use_default_modulefile=1
#
#    elif [ "${task_name}" = "${MAKE_OROG_TN}" ] || \
#         [ "${task_name}" = "${MAKE_SFC_CLIMO_TN}" ] || \
#         [ "${task_name}" = "${MAKE_ICS_TN}" ] || \
#         [ "${task_name}" = "${MAKE_LBCS_TN}" ] || \
#         [ "${task_name}" = "${RUN_FCST_TN}" ]; then
#
#      print_err_msg_exit "\
#The target (modulefile_path) of the symlink (modulefile_name) in the task
#modules directory (modules_dir) that points to module file for this task
#(task_name) does not exist:
#  task_name = \"${task_name}\"
#  modulefile_name = \"${modulefile_name}\"
#  modules_dir = \"${modules_dir}\"
#  modulefile_path = \"${modulefile_path}\"
#This is likely because the forecast model code has not yet been built."
#
#   else
#
#      print_err_msg_exit "\
#The module file (modulefile_path) specified for this task (task_name)
#does not exist:
#  task_name = \"${task_name}\"
#  modulefile_path = \"${modulefile_path}\"
#  machine = \"${machine}\""
#
#    fi
#
#  fi
#
#-----------------------------------------------------------------------
#
# Load the module file for the specified task on the current machine.
#
#-----------------------------------------------------------------------
#
  print_info_msg "$VERBOSE" "
Loading modules for task \"${task_name}\" ..."

  module use "${modules_dir}" || print_err_msg_exit "\
Call to \"module use\" command failed."

  #
  # If NOT using the default modulefile...
  #
#  if [ ${use_default_modulefile} -eq 0 ]; then
#
#     module use -a "${modules_dir}" || print_err_msg_exit "\
#Call to \"module use\" command failed."
#    
    #
    # Load the .local module file if available for the given task
    #
    modulefile_local="${task_name}.local"
    if [ -f ${modules_dir}/${modulefile_local} ]; then
      module load "${modulefile_local}" || print_err_msg_exit "\
Loading .local module file (in directory specified by mod-
ules_dir) for the specified task (task_name) failed:
  task_name = \"${task_name}\"
  modulefile_local = \"${modulefile_local}\"
  modules_dir = \"${modules_dir}\""    
    fi

#  else # using default modulefile
#
#    module load "${default_modulefile_name}" || print_err_msg_exit "\
#Loading of default module file failed:
#  task_name = \"${task_name}\"
#  default_modulefile_name = \"${default_modulefile_name}\"
#  default_modules_dir = \"${default_modules_dir}\""
#
#  fi

  module list

#fi #End if statement for tasks that load no modules

# Modules that use conda and need an environment activated will set the
# SRW_ENV variable to the name of the environment to be activated. That
# must be done within the script, and not inside the module. Do that
# now.

if [ -n "${SRW_ENV:-}" ] ; then
  conda activate ${SRW_ENV}
fi


#
#-----------------------------------------------------------------------
#
# Use the exec command to terminate the current script and launch the
# J-job for the specified task.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Launching J-job (jjob_fp) for task \"${task_name}\" ...
  jjob_fp = \"${jjob_fp}\"
"
exec "${jjob_fp}"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1


