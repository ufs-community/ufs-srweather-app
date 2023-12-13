help([[
This module loads python environement for running SRW on
the MSU machine Hercules
]])

whatis([===[Loads libraries needed for running SRW on Hercules ]===])

load("contrib")
load("rocoto")
load("set_pythonpath")

unload("python")
load("conda")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end

