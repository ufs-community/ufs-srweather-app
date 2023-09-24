help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Gaea C5 using Intel-2023.1.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Gaea C5 ]===])

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.23.1"))

prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/C5/hpc-stack/intel-classic-2023.1.0/modulefiles/stack")
load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("intel-classic", os.getenv("intel_classic_ver") or "2023.1.0"))
load(pathJoin("cray-mpich", os.getenv("cray_mpich_ver") or "8.1.25"))
load(pathJoin("hpc-intel-classic", os.getenv("hpc_intel_classic_ver") or "2023.1.0"))
load(pathJoin("hpc-cray-mpich", os.getenv("hpc_cray_mpich_ver") or "8.1.25"))

load("srw_common")

unload("darshan-runtime/3.4.0")
setenv("CFLAGS","-diag-disable=10441")
setenv("FFLAGS","-diag-disable=10441")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")
setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Platform","gaea-c5.intel")

