#!/bin/bash

#
#-----------------------------------------------------------------------
#
# This script loads the appropriate modules for a given task in an
# experiment.
#
#-----------------------------------------------------------------------
#

# Get the location of this file
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
PARMsrw=$( dirname "${scrfunc_fp}" )
HOMEdir=$( dirname $PARMsrw )

source ${PARMsrw}/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
#{ save_shell_opts; set -xue; } > /dev/null 2>&1
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
print_info_msg "Loading modules for task \"${task_name}\" ..."

modules_dir="${HOMEdir}/modulefiles/tasks/$machine"
module use "${modules_dir}"

# source version file only if it exists in the versions directory
version_file="${HOMEdir}/versions/run.ver_${machine}"
if [ -f ${version_file} ]; then
  source ${version_file}
fi

# Load the .local module file if available for the given task
modulefile_local="${task_name}.local"
if [ -f ${modules_dir}/${modulefile_local}.lua ]; then
  module load "${modulefile_local}"
else
  print_err_msg_exit "\
Loading .local module file (in directory specified by modules_dir) for the 
specified task (task_name) failed:
  task_name = \"${task_name}\"
  modulefile_local = \"${modulefile_local}\"
  modules_dir = \"${modules_dir}\""
fi
# temporary solution for esmpy
if [ "${task_name}" = "smoke_dust" ]; then
  set +u
  if [ "${machine}" = "hera" ]; then
    module unload python
    module use /contrib/miniconda3/modulefiles
    module load miniconda3/4.12.0
    export ESMFMKFILE="/home/Chan-hoo.Jeon/.conda/envs/esmpy/lib/esmf.mk"
    source /scratch2/NCEPDEV/naqfc/Chan-hoo.Jeon/PyVENV/main_aqm_pyenv/bin/activate
  fi
  set -u
fi

module list
#
#-----------------------------------------------------------------------
#
# Use the exec command to terminate the current script and launch the
# J-job for the specified task.
#
#-----------------------------------------------------------------------
#
print_info_msg "Launching J-job (jjob_fp) for task \"${task_name}\" ...
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
#{ restore_shell_opts; } > /dev/null 2>&1

