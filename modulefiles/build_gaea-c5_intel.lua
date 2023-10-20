help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Gaea C5 using Intel-2023.1.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Gaea C5 ]===])

prepend_path("MODULEPATH", "/lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c5/spack-stack-1.4.1/envs/unified-env-intel-2023.1.0/install/modulefiles/Core")

load("PrgEnv-intel/8.3.3")
load("stack-intel/2023.1.0")
load("stack-cray-mpich/8.1.25")
load("cmake/3.23.1")

load("srw_common")

unload("darshan-runtime/3.4.0")
unload("cray-pmi/6.1.10")
setenv("CFLAGS","-diag-disable=10441")
setenv("FFLAGS","-diag-disable=10441")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")
setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Platform","gaea-c5.intel")
