help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Jet using Intel-2021.5.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Jet ]===])

prepend_path("MODULEPATH","/contrib/spack-stack/spack-stack-1.6.0/envs/fms-2024.01/install/modulefiles/Core")

load("stack-intel/2021.5.0")
load("stack-intel-oneapi-mpi/2021.5.1")
load("stack-python/3.10.13")
load("cmake/3.23.1")

load("srw_common")

load("nccmp/1.9.0.1")
load("nco/5.0.6")

setenv("FC", "mpiifort")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","jet.intel")

