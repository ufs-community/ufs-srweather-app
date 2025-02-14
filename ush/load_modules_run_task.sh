#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# This script loads the appropriate modules for a given task in an
# experiment.
#
# It requires the following global environment variables:
#
#    GLOBAL_VAR_DEFNS_FP
#
# And uses these variables from the GLOBAL_VAR_DEFNS_FP file
#
#  platform:
#    BUILD_MOD_FN
#    RUN_VER_FN
#
#  workflow:
#    VERBOSE
#
#-----------------------------------------------------------------------
#

# Get the location of this file -- it's the USHdir
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
USHdir=$( dirname "${scrfunc_fp}" )
HOMEdir=$( dirname $USHdir )

source $USHdir/source_util_funcs.sh

#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1

#
#-----------------------------------------------------------------------
#
# Check arguments.
#
#-----------------------------------------------------------------------
#
if [ "$#" -ne 3 ]; then

    print_err_msg_exit "
Incorrect number of arguments specified:

  Number of arguments specified:  $#

Usage:

  ${scrfunc_fn} machine task_name  jjob_fp

where the arguments are defined as follows:

  machine: The name of the supported platform

  task_name:
  The name of the rocoto task for which this script will load modules
  and launch the J-job.

  jjob_fp:
  The full path to the J-job script corresponding to task_name.  This
  script will launch this J-job using the \"exec\" command (which will
  first terminate this script and then launch the j-job; see man page of
  the \"exec\" command).
"

fi
#
#-----------------------------------------------------------------------
#
# Save arguments
#
#-----------------------------------------------------------------------
#
machine=$(echo_lowercase $1)
task_name="$2"
jjob_fp="$3"
#
#-----------------------------------------------------------------------
#
# For NCO mode we need to define job and jobid
#
#-----------------------------------------------------------------------
#
set +u
if [ ! -z ${SLURM_JOB_ID} ]; then
    export job=${SLURM_JOB_NAME}
    export pid=${pid:-${SLURM_JOB_ID}}
elif [ ! -z ${PBS_JOBID} ]; then
    export job=${PBS_JOBNAME}
    export pid=${pid:-${PBS_JOBID}}
else
    export job=${task_name}
    export pid=${pid:-$$}
fi
export jobid=${job}.${pid}
set -u
#
#-----------------------------------------------------------------------
#
# Loading ufs-srweather-app build module files
#
#-----------------------------------------------------------------------
#
default_modules_dir="$HOMEdir/modulefiles"
test ! $(module is-loaded ecflow > /dev/null 2>&1) && ecflow_loaded=false

if [ "$ecflow_loaded" = "false" ] ; then
  source "${HOMEdir}/etc/lmod-setup.sh" ${machine}
fi
module use "${default_modules_dir}"

# Load workflow environment

if [ -f ${default_modules_dir}/python_srw.lua ] ; then
  module load python_srw || print_err_msg_exit "\
  Loading SRW common python module failed. Expected python_srw.lua
  in the modules directory here:
  modules_dir = \"${default_modules_dir}\""
fi

# Modules that use conda and need an environment activated will set the
# SRW_ENV variable to the name of the environment to be activated. That
# must be done within the script, and not inside the module. Do that
# now.
if [ -n "${SRW_ENV:-}" ] ; then
  set +u
  conda deactivate
  conda activate ${SRW_ENV}
  set -u
fi

# Source the necessary blocks of the experiment config YAML
for sect in platform workflow ; do
  source_yaml ${GLOBAL_VAR_DEFNS_FP} ${sect}
done

if [ "${machine}" != "wcoss2" ]; then
  module load "${BUILD_MOD_FN}" || print_err_msg_exit "\
  Loading of platform- and compiler-specific module file (BUILD_MOD_FN) 
for the workflow task specified by task_name failed:
  task_name = \"${task_name}\"
  BUILD_MOD_FN = \"${BUILD_MOD_FN}\""
fi

#
#-----------------------------------------------------------------------
#
# Set the directory for the modulefiles included with SRW and the
# specific module for the requested task.
#
# The full path to a module file for a given task is
#
#   $HOMEdir/modulefiles/$machine/${task_name}.local
#
# where HOMEdir is the SRW clone, machine is the name of the platform
# being used, and task_name is the current task to run.
#
#-----------------------------------------------------------------------
#
modules_dir="$default_modules_dir/tasks/$machine"
modulefile_name="${task_name}"
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

# source version file only if it exists in the versions directory
version_file="${HOMEdir}/versions/${RUN_VER_FN}"
if [ -f ${version_file} ]; then
  source ${version_file}
fi
#
# Load the .local module file if available for the given task
#
modulefile_local="${task_name}.local"
if [ -f ${modules_dir}/${modulefile_local}.lua ]; then
  module load "${modulefile_local}" || print_err_msg_exit "\
Loading .local module file (in directory specified by modules_dir) for the 
specified task (task_name) failed:
  task_name = \"${task_name}\"
  modulefile_local = \"${modulefile_local}\"
  modules_dir = \"${modules_dir}\""
fi
module list

# Reactivate the workflow environment to ensure the correct Python
# environment is available first in the environment.
if [ -n "${SRW_ENV:-}" ] ; then
  set +u
  conda deactivate
  conda activate ${SRW_ENV}
  set -u
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

source "${jjob_fp}"

#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

