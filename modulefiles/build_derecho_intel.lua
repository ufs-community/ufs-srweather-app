help([[
This module loads libraries for building the UFS SRW App on
the CISL machine Derecho (Cray) using Intel-classic-2023.0.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Cheyenne ]===])

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.26.3"))
load(pathJoin("ncarenv", os.getenv("ncarenv_ver") or "23.06"))
load(pathJoin("craype", os.getenv("craype_ver") or "2.7.20"))

unload("netcdf")
unload("hdf5")
load(pathJoin("intel-classic", os.getenv("intel_classic_ver") or "2023.0.0"))
load(pathJoin("cray-mpich", os.getenv("cray_mpich_ver") or "8.1.25"))

prepend_path("MODULEPATH","/glade/work/epicufsrt/contrib/derecho/hpc-stack/intel-classic-2023.0.0/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-intel-classic", os.getenv("hpc_intel_classic_ver") or "2023.0.0"))
load(pathJoin("hpc-cray-mpich", os.getenv("hpc_cray_mpich_ver") or "8.1.25"))

load(pathJoin("ncarcompilers", os.getenv("ncarcompilers_ver") or "1.0.0"))
load(pathJoin("mkl", os.getenv("mkl_ver") or "2023.0.0"))

load("srw_common")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")

setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_Platform","derecho.intel")

