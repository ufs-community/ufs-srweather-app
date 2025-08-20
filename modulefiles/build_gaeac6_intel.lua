help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Gaea C6 using Intel-2023.2.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Gaea C6 ]===])

prepend_path("MODULEPATH", "/ncrc/proj/epic/spack-stack/c6/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")
prepend_path("MODULEPATH", "/ncrc/proj/epic/spack-stack/c6/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/cray-mpich/8.1.32-64uo344/gcc/12.3.0")
prepend_path("MODULEPATH", "/ncrc/proj/epic/spack-stack/c6/modulefiles")

stack_intel_ver=os.getenv("stack_intel_ver") or "2024.2.1"
load(pathJoin("stack-oneapi", stack_intel_ver))

stack_mpich_ver=os.getenv("stack_mpich_ver") or "8.1.32"
load(pathJoin("stack-cray-mpich", stack_mpich_ver))

stack_python_ver=os.getenv("stack_python_ver") or "3.11.7"
load(pathJoin("stack-python", stack_python_ver))

cmake_ver=os.getenv("cmake_ver") or "3.27.9"
load(pathJoin("cmake", cmake_ver))

load("srw_common")
load("zlib/1.2.13")

load(pathJoin("nco", os.getenv("nco_ver") or "5.2.4"))
load(pathJoin("prod_util", os.getenv("prod_util_ver") or "2.1.1"))

setenv("LD_PRELOAD", "/usr/lib64/libstdc++.so.6")

unload("darshan-runtime")

setenv("CFLAGS","-diag-disable=10441")
setenv("FFLAGS","-diag-disable=10441")

setenv("CC","cc")
setenv("FC","ftn")
setenv("CXX","CC")
setenv("CMAKE_C_COMPILER","cc")
setenv("CMAKE_Fortran_COMPILER","ftn")
setenv("CMAKE_CXX_COMPILER","CC")
setenv("CMAKE_Platform","gaea-c6.intel")
