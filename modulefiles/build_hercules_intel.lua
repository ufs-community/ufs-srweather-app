help([[
This module loads libraries for building the UFS SRW App on
the MSU machine Hercules using intel-oneapi-compilers/2022.2.1
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Orion ]===])

load("contrib")
load("noaatools")

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.26.3"))

prepend_path("MODULEPATH","/work/noaa/epic/role-epic/contrib/hercules/hpc-stack/intel-2022.2.1/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel-oneapi-compilers", os.getenv("hpc_intel_ver") or "2022.2.1"))
load(pathJoin("hpc-intel-oneapi-mpi", os.getenv("hpc_mpi_ver") or "2021.7.1"))

load("srw_common")

load(pathJoin("nccmp", os.getenv("nccmp_ver") or "1.8.9.0"))
load(pathJoin("nco", os.getenv("nco_ver") or "5.0.6"))

setenv("CFLAGS","-diag-disable=10441")
setenv("FFLAGS","-diag-disable=10441")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","hercules.intel")

