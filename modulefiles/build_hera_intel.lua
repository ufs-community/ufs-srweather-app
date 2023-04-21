help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Hera using Intel-2021.5.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Hera ]===])

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/scratch1/NCEPDEV/jcsda/jedipara/spack-stack/modulefiles")

load("stack-intel/2021.5.0")
load("stack-intel-oneapi-mpi/2021.5.1")
load("stack-python/3.9.12")
load("cmake/3.23.1")

load("srw_common_spack")

load("nccmp/1.9.0.1")
load("nco/5.0.6")
load("ufs-pyenv")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","hera.intel")

