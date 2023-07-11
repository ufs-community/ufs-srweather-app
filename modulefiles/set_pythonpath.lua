help([[
This module sets the PYTHONPATH in the user environment to allow the
workflow tools to be imported
]])

whatis([===[Sets paths for using workflow-tools with SRW]===])

local mod_path, mod_file = splitFileName(myFileName())
local uwtools_scripts_path =  pathJoin(mod_path, "/../ush/python_utils/workflow-tools")
local uwtools_package_path =  pathJoin(mod_path, "/../ush/python_utils/workflow-tools/src/")

prepend_path("PYTHONPATH", uwtools_scripts_path)
prepend_path("PYTHONPATH", uwtools_package_path)
