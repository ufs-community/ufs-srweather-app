help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Gaea C5 using Intel-2023.1.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Gaea C5 ]===])

prepend_path("MODULEPATH","/ncrc/proj/epic/spack-stack/spack-stack-1.5.0/envs/unified-env/install/modulefiles/Core")
stack_intel_ver=os.getenv("stack_intel_ver") or "2023.1.0"
load(pathJoin("stack-intel", stack_intel_ver))

stack_mpich_ver=os.getenv("stack_mpich_ver") or "8.1.25"
load(pathJoin("stack-cray-mpich", stack_mpich_ver))

stack_python_ver=os.getenv("stack_python_ver") or "3.10.8"
load(pathJoin("stack-python", stack_python_ver))

cmake_ver=os.getenv("cmake_ver") or "3.23.1"
load(pathJoin("cmake", cmake_ver))

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
setenv("CMAKE_Platform","gaea.intel")
