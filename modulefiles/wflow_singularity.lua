help([[
This module loads python environement for running the UFS SRW App in
a singularity container
]])

whatis([===[Loads libraries needed for running the UFS SRW App in a singularity container]===])
load("set_pythonpath")

load("conda")

if mode() == "load" then
   execute{cmd="conda activate srw_app", modeA={"load"}}
end
