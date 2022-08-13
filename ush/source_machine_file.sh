#!/bin/bash

#
#-----------------------------------------------------------------------
#
# This script is a wrapper that sources the machine file but also allows
# for certain pre- and post-source commands to be executed (e.g. setting 
# of "set -x" shell option depending on the DEBUG variable).
#
#-----------------------------------------------------------------------
#

{ save_shell_opts; . $USHrrfs/preamble.sh; } > /dev/null 2>&1

source ${MACHINE_FILE}

{ restore_shell_opts; } > /dev/null 2>&1
