help([[
This module sets a path to activate conda environment needed for running the UFS SRW App on Linux
]])

whatis([===[This module sets a path for conda environment needed for running the UFS SRW App on Linux]===])

setenv("CMAKE_Platform", "linux")
setenv("VENV", pathJoin(os.getenv("HOME"), "condaenv/envs/regional_workflow"))

--[[
local ROCOTOmod="/Users/username/modules"
prepend_path("MODULEPATH", ROCOTOmod)
load(rocoto)
--]]

if mode() == "load" then
     LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate $VENV
]===])
end
