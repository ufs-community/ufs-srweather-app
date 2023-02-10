help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Hera using Intel-2022.1.2
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Hera ]===])

prepend_path("MODULEPATH","/contrib/sutils/modulefiles")
load("sutils")

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.20.1"))

intel_ver=os.getenv("intel_ver") or "2022.1.2"
load(pathJoin("intel", intel_ver))

impi_ver=os.getenv("impi_ver") or "2022.1.2"
load(pathJoin("impi", impi_ver))

prepend_path("MODULEPATH","/scratch1/NCEPDEV/nems/role.epic/hpc-stack/libs/intel-2022.1.2/modulefiles/stack")

load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel", os.getenv("hpc_intel_ver") or "2022.1.2"))
load(pathJoin("hpc-impi", os.getenv("hpc_impi_ver") or "2022.1.2"))

load("srw_common")

load(pathJoin("nccmp", os.getenv("nccmp_ver") or "1.8.9.0"))
load(pathJoin("nco", os.getenv("nco_ver") or "4.9.3"))

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","hera.intel")

