help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Hera
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Hera ]===])

load("rocoto")

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/scratch1/NCEPDEV/jcsda/jedipara/spack-stack/modulefiles")

load("stack-intel/2021.5.0")
load("stack-intel-oneapi-mpi/2021.5.1")
load("stack-python/3.9.12")

load("ufs-pyenv")
