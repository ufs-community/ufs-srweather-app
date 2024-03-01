help([[
This module loads libraries for building the UFS SRW App on
the NOAA RDHPC machine Jet using Intel-2021.5.0
]])

whatis([===[Loads libraries needed for building the UFS SRW App on Jet ]===])

-- When Jet switches from CentOS to Rocky, replace line withh correct path to spack-stack
-- If you want to use Rocky OS now on Jet:
-- 1. login to one of Rocky Jet nodes: fe5 - fe8
-- 2. uncomment line to Rocky spack-stack, and comment current line with path to spack-stack
-- 3. in file  ush/machine/jet.yaml set PARTITION_FCST=xjet
--prepend_path("MODULEPATH","/mnt/lfs4/HFIP/hfv3gfs/role.epic/spack-stack/spack-stack-1.5.0/envs/unified-env-rocky8/install/modulefiles/Core")
prepend_path("MODULEPATH","/mnt/lfs4/HFIP/hfv3gfs/role.epic/spack-stack/spack-stack-1.5.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/lfs4/HFIP/hfv3gfs/spack-stack/modulefiles")

load("stack-intel/2021.5.0")
load("stack-intel-oneapi-mpi/2021.5.1")
load("stack-python/3.10.8")
load("cmake/3.23.1")

load("srw_common")

load("nccmp/1.9.0.1")
load("nco/5.0.6")

setenv("CMAKE_C_COMPILER","mpiicc")
setenv("CMAKE_CXX_COMPILER","mpiicpc")
setenv("CMAKE_Fortran_COMPILER","mpiifort")
setenv("CMAKE_Platform","jet.intel")

