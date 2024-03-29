#!/bin/csh

if ( $# == 0 ) then
   cat << EOF_USAGE
Usage: source etc/lmod-setup.csh PLATFORM

OPTIONS:
   PLATFORM - name of machine you are building on
      (e.g. cheyenne | hera | jet | orion | hercules | wcoss2 )
EOF_USAGE
   exit 1
else
   set L_MACHINE=$1
endif

if ( "$L_MACHINE" != wcoss2 ) then
  source /etc/csh.login
endif
   
if ( "$L_MACHINE" == macos ) then
   arch=$(uname -m)
   [[ "$arch" = arm64 ]] && export ENV="/opt/homebrew/opt/lmod/init/csh"
   [[ "$arch" = x86_64 ]] && export ENV="/usr/local/opt/lmod/init/csh"
   source $ENV

   module purge

else if ( "$L_MACHINE" == linux ) then
   setenv ENV "/usr/share/lmod/lmod/init/csh"
   source $ENV

   module purge

else if ( "$L_MACHINE" == singularity ) then
   set ENV="/usr/share/lmod/lmod/init/csh"
   source $ENV

   module purge

else if ( "$L_MACHINE" == gaea ) then
   module reset

else if ( "$L_MACHINE" == derecho ) then
   module purge

else if ( "$L_MACHINE" == odin ) then
   module unload modules
   unset -f module
   
   set ENV="/usr/local/lmod/8.3.1/init/csh"
   source $ENV

   setenv LMOD_SYSTEM_DEFAULT_MODULES "PrgEnv-intel:cray-mpich:intel:craype"
   module --initial_load --no_redirect restore
   setenv MODULEPATH "/oldscratch/ywang/external/hpc-stack/modulefiles/mpi/intel/2020/cray-mpich/7.7.16:/oldscratch/ywang/external/hpc-stack/modulefiles/compiler/intel/2020:/oldscratch/ywang/external/hpc-stack/modulefiles/core:/oldscratch/ywang/external/hpc-stack/modulefiles/stack:/opt/cray/pe/perftools/21.02.0/modulefiles:/opt/cray/ari/modulefiles:/opt/cray/pe/craype-targets/default/modulefiles:/opt/cray/pe/modulefiles:/opt/cray/modulefiles:/opt/modulefiles"

else if ( "$L_MACHINE" = wcoss2 ) then
   module reset

else
   module purge
endif

