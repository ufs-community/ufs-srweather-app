#!/bin/bash

#
# This script is a wrapper that sources the machine file but also allows
# for certain pre- and post-source commands to be executed (e.g. setting 
# of "set -x" shell option depending on the DEBUG variable).
#

if [ -z ${DEBUG+x} ] || [ "$DEBUG" != "TRUE" ]; then
  { save_shell_opts; set -u +x; } > /dev/null 2>&1
else
  { save_shell_opts; set -u -x; } > /dev/null 2>&1
fi

source ${MACHINE_FILE}

{ restore_shell_opts; } > /dev/null 2>&1
