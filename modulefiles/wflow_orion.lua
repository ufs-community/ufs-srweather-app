help([[
This module loads python environement for running SRW on
the MSU machine Orion
]])

whatis([===[Loads libraries needed for running SRW on Orion ]===])

load("contrib")
load("ruby/3.2.3")
load("rocoto/1.3.7")

unload("python")
load("conda")

if mode() == "load" then
   execute{cmd="conda activate srw_app", modeA={"load"}}
end

