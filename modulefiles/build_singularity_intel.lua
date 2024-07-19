help([[
This module loads libraries for building the UFS SRW App in
a singularity container
]])

whatis([===[Loads libraries needed for building the UFS SRW App in singularity container ]===])

prepend_path("MODULEPATH","/opt/spack-stack/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core")

load("stack-intel/2021.10.0")
load("intel-oneapi-mpi/2021.9.0")
load("cmake/3.23.1")

load("srw_common")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpicxx")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","singularity.intel")

