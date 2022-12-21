help([[
This module set a path needed to activate conda environement for running UFS SRW App on general macOS
]])

whatis([===[This module activates conda environment for running the UFS SRW App on macOS]===])

setenv("CMAKE_Platform", "macos")
setenv("VENV", pathJoin(os.getenv("HOME"), "condaenv/envs/regional_workflow"))

--[[
local ROCOTOmod="/Users/username/modules"
prepend_path("MODULEPATH", ROCOTOmod)
load(rocoto)
--]]

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda virtual environment:
       > conda activate $VENV "
]===])
end

