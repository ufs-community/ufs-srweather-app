#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script and the function definitions
# file.
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
# Call the script that defines the module() function.  This is needed so
# we can perform "module load ..." calls later below.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Initializing the shell function \"module()\" (and others) in order to be
able to use \"module load ...\" to load necessary modules ..."

case "$MACHINE" in
#
  "WCOSS_C")
    . /opt/modules/default/init/sh
    ;;
#
  "DELL")
    . /usrx/local/prod/lmod/lmod/init/sh
    ;;
#
  "HERA")
    . /apps/lmod/lmod/init/sh
    ;;
#
  "JET")
    . /apps/lmod/lmod/init/sh
    ;;
#
  *) 
    print_err_msg_exit "
The script to source to initialize lmod (module loads) has not yet been
specified for the current machine (MACHINE):
  MACHINE = \"$MACHINE\""
    ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Get the task name.  Then shift the argument list so that the firs ar-
# gument (the task name) gets dropped from the start of the arguments
# list.  This results in the shell variable $@ containing only the re-
# maining arguments (which in this case should consist of the full path
# to the J-job to call).
#
#-----------------------------------------------------------------------
#
task_name="$1"
jjob_fp="$2"
#
#-----------------------------------------------------------------------
#
# Purge modules and load the module file for the specified task on the 
# current machine.  Note that the path to this module file is given by
#
#   $HOMErrfs/modulefiles/$machine/${task_name}
#
# where HOMErrfs is the workflow home directory, machine is the name of
# the current machine in lowercase, and task_name is the name of the 
# task that this script will launch (via the exec command below).
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Loading modules for task \"${task_name}\" ..."

machine=${MACHINE,,}
module purge
module use $HOMErrfs/modulefiles/$machine
module load ${task_name}
module list
#
#-----------------------------------------------------------------------
#
# Use the exec ocmmand to terminate the current script and launch the
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


