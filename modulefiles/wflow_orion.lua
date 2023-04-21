help([[
This module loads python environement for running SRW on
the MSU machine Orion
]])

whatis([===[Loads libraries needed for running SRW on Orion ]===])

load("contrib")
load("rocoto")

prepend_path("MODULEPATH", "/work/noaa/epic-ps/role-epic-ps/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")

load("stack-intel/2022.0.2")
load("stack-intel-oneapi-mpi/2021.5.1")
load("stack-python/3.9.7")

load("ufs-pyenv")

