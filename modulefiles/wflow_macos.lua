help([[
This module activates python environement for running the UFS SRW App on general macOS
]])

whatis([===[This module activates python environment for running the UFS SRW App on macOS]===])

setenv("CMAKE_Platform", "macos")
setenv("VENV", pathJoin(os.getenv("HOME"), "venv/regional_workflow"))

--[[
local ROCOTOmod="/Users/username/modules"
prepend_path("MODULEPATH", ROCOTOmod)
load(rocoto)
--]]

if mode() == "load" then
   LmodMsgRaw([===[Verify the Python virtual environment path \$VENV shown below is correct, "
set to the correct path otherwise: "
VENV=$env(VENV) "
Please do the following to activate python virtual environment:
       > source \$VENV/bin/activate "
]===])
end
if mode() == "unload" then
   execute{cmd="deactivate", modeA={"unload"}}
end
