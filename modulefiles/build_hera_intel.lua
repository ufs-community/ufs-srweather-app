help([[
This module loads libraries for building the UFS SRW-AQM/SD/FB on
the NOAA RDHPC machine Hera.
]])

whatis([===[Loads libraries needed for building the UFS SRW-AQM/SD/FB on Hera ]===])

prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))

load(pathJoin("cmake", cmake_ver))

load("srw_common")

load(pathJoin("nccmp", nccmp_ver))
load(pathJoin("nco", nco_ver))
load(pathJoin("prod_util", prod_util_ver))

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","hera.intel")
