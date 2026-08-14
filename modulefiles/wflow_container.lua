help([[
This module loads python environement for running the UFS SRW App in
a singularity/apptainer container
]])

whatis([===[Loads libraries needed for running the UFS SRW App in
a singularity/apptainer container]===])

load("conda")
load("rocoto")
--load("singularity")

if mode() == "load" then
   execute{cmd="conda activate srw_app", modeA={"load"}}
end
