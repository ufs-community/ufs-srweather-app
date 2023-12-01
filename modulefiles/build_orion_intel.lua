help([[
This module loads libraries for building the UFS SRW App on
the MSU machine Orion using Intel-2022.1.2
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Orion ]===])

prepend_path("MODULEPATH", "/work/noaa/epic/role-epic/spack-stack/spack-stack-1.4.1/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/work/noaa/da/role-da/spack-stack/modulefiles")

load("stack-intel/2022.0.2")
load("stack-intel-oneapi-mpi/2021.5.1")
load("cmake/3.22.1")

load("srw_common")

load("nccmp/1.9.0.1")
load("nco/5.0.6")
load("ufs-pyenv")
load("wget")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","orion.intel")
