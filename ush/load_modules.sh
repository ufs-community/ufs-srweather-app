#!/bin/bash

#set -x -u -e
#date
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
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
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
#
#
#-----------------------------------------------------------------------
#
task_name="$1"

#. ${HOMErrfs}/rocoto/machine-setup.sh
#export machine=${target}

#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
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
#
#
#-----------------------------------------------------------------------
#
module use ${HOMErrfs}/modulefiles/${MACHINE}
module load ${task_name}
module list

#exec "$@"

