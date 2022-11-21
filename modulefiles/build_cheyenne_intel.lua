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
load(pathJoin("python", os.getenv("python_ver") or "3.7.9"))
load(pathJoin("ncarcompilers", os.getenv("ncarcompilers_ver") or "0.5.0"))
unload("netcdf")

prepend_path("MODULEPATH","/glade/work/epicufsrt/GMTB/tools/intel/2022.1/hpc-stack-v1.2.0_6eb6/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel", os.getenv("hpc_intel_ver") or "2022.1"))
load(pathJoin("hpc-mpt", os.getenv("hpc_mpt_ver") or "2.25"))

load("srw_common")

load(pathJoin("g2", os.getenv("g2_ver") or "3.4.5"))
load(pathJoin("esmf", os.getenv("esmf_ver") or "8.3.0b09"))
load(pathJoin("netcdf", os.getenv("netcdf_ver") or "4.7.4"))
load(pathJoin("libpng", os.getenv("libpng_ver") or "1.6.37"))
load(pathJoin("pio", os.getenv("pio_ver") or "2.5.3"))
load(pathJoin("fms", os.getenv("fms_ver") or "2022.01"))

setenv("CMAKE_C_COMPILER","mpicc")
setenv("CMAKE_CXX_COMPILER","mpicpc")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","cheyenne.intel")

