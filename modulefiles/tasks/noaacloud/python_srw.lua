prepend_path("PATH", "/contrib/EPIC/miniconda3/4.12.0/envs/regional_workflow/bin")

local mod_path, mod_file = splitFileName(myFileName())
local uwtools_scripts_path =  pathJoin(mod_path, "../../../ush/python_utils/uwtools")
local uwtools_package_path =  pathJoin(mod_path, "../../../ush/python_utils/uwtools/src/")

prepend_path("PYTHONPATH", uwtools_scripts_path)
prepend_path("PYTHONPATH", uwtools_package_path)
