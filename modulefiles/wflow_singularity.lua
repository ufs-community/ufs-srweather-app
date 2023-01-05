help([[
This module loads python environement for running the UFS SRW App in
a singularity container
]])

whatis([===[Loads libraries needed for running the UFS SRW App in a singularity container]===])

append_path("MODULEPATH","/opt/miniconda3/modulefiles")
load("miniconda3")


