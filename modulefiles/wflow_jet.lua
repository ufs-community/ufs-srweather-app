help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Jet
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Jet ]===])

load("rocoto")

prepend_path("MODULEPATH", "/lfs4/HFIP/hfv3gfs/spack-stack/modulefiles")
load("stack-python/3.9.12")
