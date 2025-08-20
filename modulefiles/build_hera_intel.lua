help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Hera using Intel-2022.1.2
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Hera ]===])

prepend_path("MODULEPATH","/contrib/sutils/modulefiles")
load("sutils")

prepend_path("MODULEPATH", "/contrib/spack-stack/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")
prepend_path("MODULEPATH", "/contrib/spack-stack/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/intel-oneapi-mpi/2021.13-sbi3u54/gcc/13.3.0")

stack_intel_ver=os.getenv("stack_intel_ver") or "2024.2.1"
load(pathJoin("stack-oneapi", stack_intel_ver))

stack_impi_ver=os.getenv("stack_impi_ver") or "2021.13"
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))

stack_python_ver=os.getenv("stack_python_ver") or "3.11.7"
load(pathJoin("stack-python", stack_python_ver))

cmake_ver=os.getenv("cmake_ver") or "3.27.9"
load(pathJoin("cmake", cmake_ver))

load("srw_common")
load("zlib/1.2.11")

load(pathJoin("nccmp", os.getenv("nccmp_ver") or "1.9.0.1"))
load(pathJoin("nco", os.getenv("nco_ver") or "5.2.4"))
load(pathJoin("prod_util", os.getenv("prod_util_ver") or "2.1.1"))

setenv("LD_PRELOAD", "/contrib/spack-stack/installs/gnu/13.3.0/lib64/libstdc++.so.6")

setenv("FC", "mpiifort")

setenv("CMAKE_C_COMPILER","mpiicx")
setenv("CMAKE_CXX_COMPILER","mpiicpx")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("I_MPI_CC", "icx")
setenv("I_MPI_CXX", "icpx")
setenv("I_MPI_F90", "ifort")

setenv("CMAKE_Platform","hera.intel")
