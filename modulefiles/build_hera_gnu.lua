help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Hera using GNU 9.2.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Hera using GNU 9.2.0 ]===])

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.7.0/envs/ue-gcc/install/modulefiles/Core")

load("stack-gcc/9.2.0")
load("stack-openmpi/4.1.6")
load("stack-python/3.10.13")
load("cmake/3.23.1")

load("srw_common")

load(pathJoin("nccmp", os.getenv("nccmp_ver") or "1.9.0.1"))
load(pathJoin("nco", os.getenv("nco_ver") or "5.1.6"))
load(pathJoin("openblas", os.getenv("openblas_ver") or "0.3.24"))

setenv("CC", "mpicc")
setenv("CXX", "mpic++")
setenv("FC", "mpif90")
setenv("CMAKE_Platform", "hera.gnu")
