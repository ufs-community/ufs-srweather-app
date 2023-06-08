help([[
This module loads python environement for running SRW on
the MSU machine Orion
]])

whatis([===[Loads libraries needed for running SRW on Orion ]===])

load("contrib")
load("rocoto")
load("wget")
load("set_pythonpath")

unload("python")
append_path("MODULEPATH","/work/noaa/epic-ps/role-epic-ps/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate workflow_tools
]===])
end

