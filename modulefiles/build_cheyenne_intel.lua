help([[
This module loads libraries for building the UFS SRW App on
the CISL machine Cheyenne using Intel-2022.1
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Cheyenne ]===])

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.22.0"))
load(pathJoin("ncarenv", os.getenv("ncarenv_ver") or "1.3"))
load(pathJoin("intel", os.getenv("intel_ver") or "2022.1"))
load(pathJoin("mpt", os.getenv("mpt_ver") or "2.25"))
load(pathJoin("mkl", os.getenv("mkl_ver") or "2022.1"))
load(pathJoin("ncarcompilers", os.getenv("ncarcompilers_ver") or "0.5.0"))
unload("netcdf")

prepend_path("MODULEPATH","/glade/work/epicufsrt/contrib/hpc-stack/intel2022.1_ncdf492/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel", os.getenv("hpc_intel_ver") or "2022.1"))
load(pathJoin("hpc-mpt", os.getenv("hpc_mpt_ver") or "2.25"))

load("srw_common")

setenv("CMAKE_C_COMPILER","mpicc")
setenv("CMAKE_CXX_COMPILER","mpicpc")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","cheyenne.intel")

