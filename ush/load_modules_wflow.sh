#!/bin/bash

#
#-----------------------------------------------------------------------
#
# This script loads the workflow modulefile for a given machine.
# It is a central place for all other scripts so that this is the only
# place workflow module loading can be modified.
#
#-----------------------------------------------------------------------
#

function usage() {
  cat << EOF_USAGE
Usage: source $0 PLATFORM

OPTIONS:
   PLATFORM - name of machine you are on
      (e.g. cheyenne | hera | jet | orion | wcoss2 )
EOF_USAGE
}

# Make sure machine name is passed as first argument
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

# help message
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  usage
  exit 0
fi

# Set machine name to lowercase
machine=${1,,}

# Get home directory
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
HOMEdir=$( dirname "${scrfunc_dir}" )

# source version file (run) only if it is specified in versions directory
RUN_VER_FN="run.ver.${machine}"
VERSION_FILE="${HOMEdir}/versions/${RUN_VER_FN}"
if [ -f ${VERSION_FILE} ]; then
  . ${VERSION_FILE}
fi

# Source modulefile for this machine
WFLOW_MOD_FN="wflow_${machine}"
source "${HOMEdir}/etc/lmod-setup.sh" ${machine}
module use "${HOMEdir}/modulefiles"
module load "${WFLOW_MOD_FN}" > /dev/null 2>&1 || { echo "ERROR:
Loading of platform-specific module file (WFLOW_MOD_FN) for the workflow 
task failed:
  WFLOW_MOD_FN = \"${WFLOW_MOD_FN}\""; exit 1; }

# Activate conda
[[ ${SHELLOPTS} =~ nounset ]] && has_mu=true || has_mu=false

$has_mu && set +u

if [ ! -z $(command -v conda) ]; then
  conda activate srw_app
fi

$has_mu && set -u

# List loaded modulefiles
module --version
module list

