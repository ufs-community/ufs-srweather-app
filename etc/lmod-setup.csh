#!/bin/csh

if ( $# == 0 ) then
   cat << EOF_USAGE
Usage: source etc/lmod-setup.csh PLATFORM

OPTIONS:
   PLATFORM - name of machine you are building on
      (e.g. cheyenne | hera | jet | orion | wcoss2 )
EOF_USAGE
   exit 1
else
   set L_MACHINE=$1
endif
   
if ( "$L_MACHINE" == macos ) then
   set ENV="/opt/homebrew/opt/lmod/init/csh"
   # setenv ENV "/usr/local/opt/lmod/init/csh"
   source $ENV

   module purge

else if ( "$L_MACHINE" == singularity ) then
   set ENV="/usr/share/lmod/lmod/init/csh"
   source $ENV

   module purge

else if ( "$L_MACHINE" == gaea ) then
   set ENV="/lustre/f2/pdata/esrl/gsd/contrib/lua-5.1.4.9/lmod/lmod/init/csh"
   source $ENV

else if ( "$L_MACHINE" == odin ) then
   module unload modules
   unset -f module
   
   set ENV="/usr/local/lmod/8.3.1/init/csh"
   source $ENV

   setenv LMOD_SYSTEM_DEFAULT_MODULES "PrgEnv-intel:cray-mpich:intel:craype"
   module --initial_load --no_redirect restore
   setenv MODULEPATH "/oldscratch/ywang/external/hpc-stack/modulefiles/mpi/intel/2020/cray-mpich/7.7.16:/oldscratch/ywang/external/hpc-stack/modulefiles/compiler/intel/2020:/oldscratch/ywang/external/hpc-stack/modulefiles/core:/oldscratch/ywang/external/hpc-stack/modulefiles/stack:/opt/cray/pe/perftools/21.02.0/modulefiles:/opt/cray/ari/modulefiles:/opt/cray/pe/craype-targets/default/modulefiles:/opt/cray/pe/modulefiles:/opt/cray/modulefiles:/opt/modulefiles"

else
   module purge
endif

