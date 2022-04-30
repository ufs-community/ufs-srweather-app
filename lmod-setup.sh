#!/bin/bash

L_MACHINE=${MACHINE:-$1}

if [ "$L_MACHINE" = macos ]; then
   # Choose lmod install location
   export BASH_ENV="/opt/homebrew/opt/lmod/init/bash"
   # export BASH_ENV="/usr/local/opt/lmod/init/bash"
   source $BASH_ENV
elif [ "$L_MACHINE" = gaea ]; then
   source "/lustre/f2/pdata/esrl/gsd/contrib/lua-5.1.4.9/init/init_lmod.sh"
elif [ "$L_MACHINE" = odin ]; then
   module unload modules
   unset -f module
   
   export BASH_ENV=/usr/local/lmod/8.3.1/init/bash
   source $BASH_ENV
   export LMOD_SYSTEM_DEFAULT_MODULES=PrgEnv-intel:cray-mpich:intel:craype
   module --initial_load --no_redirect restore
   #module use <$HOME>/<your-modulefiles-dir>
   export MODULEPATH=/oldscratch/ywang/external/hpc-stack/modulefiles/mpi/intel/2020/cray-mpich/7.7.16:/oldscratch/ywang/external/hpc-stack/modulefiles/compiler/intel/2020:/oldscratch/ywang/external/hpc-stack/modulefiles/core:/oldscratch/ywang/external/hpc-stack/modulefiles/stack:/opt/cray/pe/perftools/21.02.0/modulefiles:/opt/cray/ari/modulefiles:/opt/cray/pe/craype-targets/default/modulefiles:/opt/cray/pe/modulefiles:/opt/cray/modulefiles:/opt/modulefiles
else
   module purge
fi

