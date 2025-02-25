help([[
This load("s libraries for building the UFS SRW App on
the NOAA cloud using Intel-oneapi
]])

whatis([===[Loads libraries needed for building the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH", "/contrib/spack-stack-rocky8/spack-stack-1.6.0/envs/fms-2024.01/install/modulefiles/Core")
prepend_path("MODULEPATH", "/apps/modules/modulefiles")
load("gnu")
load("stack-intel")
load("stack-intel-oneapi-mpi")
unload("gnu")
load("cmake/3.23.1") 

load("srw_common")

load(pathJoin("nco", os.getenv("nco_ver") or "5.0.6"))
load(pathJoin("prod_util", os.getenv("prod_util_ver") or "2.1.1"))
