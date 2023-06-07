help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Hera using GNU 9.2.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Hera using GNU 9.2.0 ]===])

prepend_path("MODULEPATH","/contrib/sutils/modulefiles")
load("sutils")

load(pathJoin("cmake", os.getenv("cmake_ver") or "3.20.1"))

gnu_ver=os.getenv("gnu_ver") or "9.2.0"
load(pathJoin("gnu", gnu_ver))

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/hpc-stack/libs/gnu-9.2/modulefiles/stack")

load(pathJoin("hpc", os.getenv("hpc_ver") or "1.2.0"))
load(pathJoin("hpc-gnu", os.getenv("hpc-gnu_ver") or "9.2"))
load(pathJoin("hpc-mpich", os.getenv("hpc-mpich_ver") or "3.3.2"))

load("srw_common")

load(pathJoin("nccmp", os.getenv("nccmp_ver") or "1.8.9"))
load(pathJoin("nco", os.getenv("nco_ver") or "4.9.3"))
load(pathJoin("openblas", os.getenv("openblas_ver") or "0.3.23"))

unsetenv("MKLROOT")
setenv("CMAKE_C_COMPILER","mpicc")
setenv("CMAKE_CXX_COMPILER","mpicxx")
setenv("CMAKE_Fortran_COMPILER","mpif90")
setenv("CMAKE_Platform","hera.gnu")
