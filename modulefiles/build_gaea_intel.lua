help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Gaea using Intel-2022.1.2
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Gaea ]===])

module load PrgEnv-intel/6.0.5
module rm intel
module rm cray-mpich
module rm netcdf
module load intel/18.0.6.288
module load cray-mpich/7.7.11
module load cray-python/3.7.3.2
# Needed at runtime:
module load alps

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.20.1"))

prepend_path("MODULEPATH","/lustre/f2/pdata/ncep_shared/hpc-stack.epic/libs/intel/2021.3.0/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("intel", os.getenv("intel_ver") or "2021.3.0"))
load(pathJoin("hpc-intel", os.getenv("hpc_intel_ver") or "2021.3.0"))
load(pathJoin("hpc-cray-mpich", os.getenv("hpc_cray_mpich_ver") or "7.7.11"))
load(pathJoin("gcc", os.getenv("gcc_ver") or "8.3.0"))
load(pathJoin("libpng", os.getenv("libpng_ver") or "1.6.37"))

load("srw_common")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")
setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_Platform","gaea.intel")

