help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Hera using GNU 13.3.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Hera using GNU 13.3.0 ]===])

prepend_path("MODULEPATH", "/scratch2/NCEPDEV/stmp1/role.epic/installs/gnu/modulefiles")
prepend_path("MODULEPATH", "/scratch2/NCEPDEV/stmp1/role.epic/installs/openmpi/modulefiles")
prepend_path("MODULEPATH", "/scratch2/NCEPDEV/stmp1/role.epic/spack-stack/spack-stack-1.6.0_gnu13/envs/fms-2024.01/install/modulefiles/Core")

load("stack-gcc/13.3.0")
load("stack-openmpi/4.1.6")
load("stack-python/3.10.13")
load("cmake/3.23.1")

load("srw_common")

load(pathJoin("nccmp", os.getenv("nccmp_ver") or "1.9.0.1"))
load(pathJoin("nco", os.getenv("nco_ver") or "5.1.6"))
load(pathJoin("openblas", os.getenv("openblas_ver") or "0.3.24"))

prepend_path("CPPFLAGS", " -I/apps/slurm_hera/23.11.3/include/slurm"," ")
prepend_path("LD_LIBRARY_PATH", "/apps/slurm_hera/23.11.3/lib")
setenv("LD_PRELOAD", "/scratch2/NCEPDEV/stmp1/role.epic/installs/gnu/13.3.0/lib64/libstdc++.so.6")

setenv("CC", "mpicc")
setenv("CXX", "mpic++")
setenv("FC", "mpif90")
setenv("CMAKE_Platform", "hera.gnu")
