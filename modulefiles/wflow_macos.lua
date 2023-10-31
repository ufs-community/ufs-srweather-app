help([[
This module set a path needed to activate conda environement for running UFS SRW App on general macOS, following miniconda3 module and conda environments installations
]])

whatis([===[This module activates conda environment for running the UFS SRW App on macOS]===])

setenv("CMAKE_Platform", "macos")

prepend_path("MODULEPATH","/Users/username/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "23.9.0"))

-- set python path
load("set_pythonpath")

-- display conda activation message
if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda virtual environment:
       > conda activate workflow_tools
]===])
end

