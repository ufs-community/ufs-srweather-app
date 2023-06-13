help([[
This module loads python environement for running the UFS SRW App in
a singularity container
]])

whatis([===[Loads libraries needed for running the UFS SRW App in a singularity container]===])
load("set_pythonpath")

append_path("MODULEPATH","/opt/hpc-modules/modulefiles/core")
load("miniconda3")

if mode() == "load" then
   execute{cmd="conda activate workflow_tools", modeA={"load"}}
end
