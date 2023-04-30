help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Gaea
]])

whatis([===[Loads libraries needed for running the UFS SRW App on gaea ]===])

unload("intel")
unload("cray-mpich")
unload("cray-python")
unload("darshan")

prepend_path("MODULEPATH", "/lustre/f2/dev/wpo/role.epic/contrib/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/lustre/f2/pdata/esrl/gsd/spack-stack/modulefiles")
prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/modulefiles")

load("stack-intel/2021.3.0")
load("stack-cray-mpich/7.7.11")
load("stack-python/3.9.12")

load("ufs-pyenv")
load("rocoto")
load("alps")
