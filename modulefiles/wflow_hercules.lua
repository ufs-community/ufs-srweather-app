help([[
This module loads python environement for running SRW on
the MSU machine Hercules
]])

whatis([===[Loads libraries needed for running SRW on Hercules ]===])

load("contrib")
load("rocoto")


unload("python")
load("conda")

if mode() == "load" then
   execute{cmd="conda activate srw_app", modeA={"load"}}
end

