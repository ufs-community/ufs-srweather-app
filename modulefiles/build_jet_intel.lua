help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Jet using Intel-2022.1.2
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Jet ]===])

prepend_path("MODULEPATH","/contrib/sutils/modulefiles")
load("sutils")

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.20.1"))

prepend_path("MODULEPATH","/lfs4/HFIP/hfv3gfs/nwprod/hpc-stack/libs/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel", os.getenv("hpc_intel_ver") or "2022.1.2"))
load(pathJoin("hpc-impi", os.getenv("hpc_impi_ver") or "2022.1.2"))

load("srw_common")

load(pathJoin("prod_util", os.getenv("prod_util_ver") or "1.2.2"))
load(pathJoin("nccmp", os.getenv("nccmp_ver") or "1.8.9.0"))
load(pathJoin("nco", os.getenv("nco_ver") or "4.9.3"))

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","jet.intel")

