help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Jet
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Jet ]===])

prepend_path("MODULEPATH","/mnt/lfs4/HFIP/hfv3gfs/role.epic/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
load("stack-intel/2021.5.0")
load("stack-intel-oneapi-mpi/2021.5.1")

prepend_path("MODULEPATH", "/lfs4/HFIP/hfv3gfs/spack-stack/modulefiles")
load("stack-python/3.9.12")

load("ufs-pyenv")
