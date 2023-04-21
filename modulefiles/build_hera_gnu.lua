help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Hera using GNU 9.2.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Hera using GNU 9.2.0 ]===])

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/scratch1/NCEPDEV/jcsda/jedipara/spack-stack/modulefiles")

load("stack-gcc/9.2.0")
load("stack-openmpi/3.1.4")
load("stack-python/3.9.12")
load("cmake/3.23.1")

load("srw_common_spack")

load("nccmp/1.9.0.1")
load("nco/5.0.6")
load("ufs-pyenv")

setenv("CMAKE_C_COMPILER","mpicc")
setenv("CMAKE_CXX_COMPILER","mpicxx")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","hera.gnu")
