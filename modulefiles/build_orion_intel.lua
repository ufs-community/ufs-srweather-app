help([[
This module loads libraries for building the UFS SRW App on
the MSU machine Orion using Intel-2022.1.2
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Orion ]===])

prepend_path("MODULEPATH", "/work/noaa/epic/role-epic/spack-stack/orion/spack-stack-1.5.1/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/work/noaa/da/role-da/spack-stack/modulefiles")

load("stack-intel/2022.0.2")
load("stack-intel-oneapi-mpi/2021.5.1")
load("stack-python/3.10.8")
load("cmake/3.22.1")

load("srw_common")

load("nccmp/1.9.0.1")
load("nco/5.0.6")
load("wget")
load(pathJoin("prod_util", os.getenv("prod_util_ver") or "1.2.2"))

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","orion.intel")
