help([[
This module loads libraries for building the UFS SRW-AQM/SD/FB on
the NOAA RDHPC machine Gaea-C6.
]])

whatis([===[Loads libraries needed for building the UFS SRW-AQM/SD/FB on Gaea-C6 ]===])

prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-cray-mpich", stack_cray_mpich_ver))

load(pathJoin("cmake", cmake_ver))

load("srw_common")

unload(pathJoin("darshan-runtime", darshan_runtime_ver))
unload(pathJoin("cray-pmi", cray_pmi_ver))

setenv("CFLAGS","-diag-disable=10441")
setenv("FFLAGS","-diag-disable=10441")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")
setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Platform","gaea-c6.intel")
