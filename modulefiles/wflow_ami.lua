help([[
This module loads python environement for running the UFS SRW App on
the NOAA cloud
]])

whatis([===[Loads libraries needed for running the UFS SRW App on NOAA cloud ]===])

setenv("PROJ_LIB","/data/miniconda3/4.12.0/envs/regional_workflow/share/proj")
prepend_path("MODULEPATH","/data/miniconda3/modulefiles")
load("miniconda3")

