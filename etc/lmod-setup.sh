#!/bin/sh

if [ $# = 0 ]; then
   L_MACHINE=${MACHINE}
   cat << EOF_USAGE
Usage: source etc/lmod-setup.sh PLATFORM

OPTIONS:
   PLATFORM - name of machine you are building on
      (e.g. cheyenne | hera | jet | orion | hercules | wcoss2 )
EOF_USAGE
   exit 1
else
   L_MACHINE=$1
fi

if [ "$L_MACHINE" != wcoss2 ]; then
  [[ ${SHELLOPTS} =~ nounset ]] && has_mu=true || has_mu=false
  [[ ${SHELLOPTS} =~ errexit ]] && has_me=true || has_me=false
  $has_mu && set +u
  $has_me && set +e
  source /etc/profile
  $has_mu && set -u
  $has_me && set -e
fi

if [ "$L_MACHINE" = macos ]; then
   arch=$(uname -m)
   [[ "$arch" = arm64 ]] && export BASH_ENV="/opt/homebrew/opt/lmod/init/bash"
   [[ "$arch" = x86_64 ]] && export BASH_ENV="/usr/local/opt/lmod/init/bash"
   source $BASH_ENV

   module purge

elif [ "$L_MACHINE" = linux ]; then
   export BASH_ENV="/usr/share/lmod/lmod/init/bash"
   source $BASH_ENV

   module purge

elif [ "$L_MACHINE" = singularity ]; then
   export BASH_ENV="/usr/share/lmod/lmod/init/bash"
   source $BASH_ENV

   module purge

elif [ "$L_MACHINE" = gaea ]; then
   module reset 

elif [ "$L_MACHINE" = derecho ]; then
   module purge

elif [ "$L_MACHINE" = odin ]; then
   module unload modules
   unset -f module
   
   export BASH_ENV="/usr/local/lmod/8.3.1/init/bash"
   source $BASH_ENV

   export LMOD_SYSTEM_DEFAULT_MODULES="PrgEnv-intel:cray-mpich:intel:craype"
   module --initial_load --no_redirect restore
   export MODULEPATH="/oldscratch/ywang/external/hpc-stack/modulefiles/mpi/intel/2020/cray-mpich/7.7.16:/oldscratch/ywang/external/hpc-stack/modulefiles/compiler/intel/2020:/oldscratch/ywang/external/hpc-stack/modulefiles/core:/oldscratch/ywang/external/hpc-stack/modulefiles/stack:/opt/cray/pe/perftools/21.02.0/modulefiles:/opt/cray/ari/modulefiles:/opt/cray/pe/craype-targets/default/modulefiles:/opt/cray/pe/modulefiles:/opt/cray/modulefiles:/opt/modulefiles"

elif [ "$L_MACHINE" = wcoss2 ]; then
   module reset

else
   module purge
fi
