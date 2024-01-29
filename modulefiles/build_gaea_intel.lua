help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Gaea using Intel-2022.0.2
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Gaea ]===])

unload("intel")
unload("cray-mpich")
unload("cray-python")
unload("darshan")

prepend_path("MODULEPATH", "/lustre/f2/dev/wpo/role.epic/contrib/spack-stack/spack-stack-1.4.1-c4/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/lustre/f2/pdata/esrl/gsd/spack-stack/modulefiles")

load("stack-intel/2022.0.2")
load("stack-cray-mpich/7.7.20")
load("cmake/3.23.1")

load("srw_common")
-- Need at runtime
load("alps")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")
setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_Platform","gaea.intel")

setenv("CFLAGS","-diag-disable=10441")
setenv("FFLAGS","-diag-disable=10441 -fp-model source")
