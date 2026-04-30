help([[
This load("s libraries for building the UFS SRW App on
the NOAA cloud using Intel-oneapi
]])

whatis([===[Loads libraries needed for building the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH", "/contrib/spack-stack-rocky8/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")
prepend_path("MODULEPATH", "/contrib/spack-stack-rocky8/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/intel-oneapi-mpi/2021.13-mg3hegm/gcc/13.2.0")  -- path for NOAA AWS
prepend_path("MODULEPATH", "/contrib/spack-stack-rocky8/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/intel-oneapi-mpi/2021.13-fosayin/gcc/13.2.0")  -- path for NOAA GCP
prepend_path("MODULEPATH", "/contrib/spack-stack-rocky8/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/intel-oneapi-mpi/2021.13-u7pshji/gcc/13.2.0")  -- path for NOAA Azure
prepend_path("MODULEPATH", "/apps/modules/modulefiles")

gnu_ver=os.getenv("gnu_ver") or "14.2.0"
load(pathJoin("gnu", gnu_ver))

stack_intel_ver=os.getenv("stack_intel_ver") or "2024.2.1"
load(pathJoin("stack-oneapi", stack_intel_ver))

stack_impi_ver=os.getenv("stack_impi_ver") or "2021.13"
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))

gnu_ver=os.getenv("gnu_ver") or "14.2.0"
unload(pathJoin("gnu", gnu_ver))

load("cmake/3.27.9")

load("srw_common")
load("zlib/1.2.11")

load(pathJoin("nco", os.getenv("nco_ver") or "5.2.4"))
load(pathJoin("prod_util", os.getenv("prod_util_ver") or "2.1.1"))

setenv("LD_PRELOAD", "/apps/gnu/gcc-13.2.0/lib64/libstdc++.so.6")
setenv("CC", "mpiicx")
setenv("CXX", "mpiicpx")
setenv("FC", "mpiifort")
