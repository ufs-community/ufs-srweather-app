help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Ursa using GNU 12.4.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Ursa using GNU 12.4.0 ]===])

prepend_path("MODULEPATH", "/contrib/spack-stack/spack-stack-1.9.2/envs/ue-gcc-12.4.0/install/modulefiles/Core")

load("stack-gcc/12.4.0")
load("stack-openmpi/4.1.6")
load("stack-python/3.11.7")
load("cmake/3.27.9")

load("srw_common")

load(pathJoin("nccmp", os.getenv("nccmp_ver") or "1.9.0.1"))
load(pathJoin("nco", os.getenv("nco_ver") or "5.2.4"))
load(pathJoin("prod_util", os.getenv("prod_util_ver") or "2.1.1"))
load(pathJoin("openblas", os.getenv("openblas_ver") or "0.3.24"))

setenv("MPI_CC", "mpicc")
setenv("MPI_CXX", "mpic++")
setenv("MPI_FC", "mpifort")
setenv("FC", "mpifort")
setenv("CMAKE_Platform", "ursa.gnu")
