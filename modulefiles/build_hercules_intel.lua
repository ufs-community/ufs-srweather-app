help([[
This module loads libraries for building the UFS SRW App on
the MSU machine Hercules using intel-oneapi-compilers/2022.2.1
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Hercules ]===])

prepend_path("MODULEPATH", "/work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.7.0/envs/ue-intel/install/modulefiles/Core")

load("stack-intel/2021.9.0")
load("stack-intel-oneapi-mpi/2021.9.0")
load("stack-python/3.10.13")
load("cmake/3.26.3")

load("srw_common")

load("nccmp/1.9.0.1")
load("nco/5.1.6")

setenv("CFLAGS","-diag-disable=10441")
setenv("FFLAGS","-diag-disable=10441")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","hercules.intel")
