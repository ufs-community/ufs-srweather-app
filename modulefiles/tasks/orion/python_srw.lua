unload("python")
append_path("MODULEPATH","/work/noaa/epic-ps/role-epic-ps/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("SRW_ENV", "regional_workflow")

local mod_path, mod_file = splitFileName(myFileName())
local uwtools_scripts_path =  pathJoin(mod_path, "../../../ush/python_utils/uwtools")
local uwtools_package_path =  pathJoin(mod_path, "../../../ush/python_utils/uwtools/src/")

prepend_path("PYTHONPATH", uwtools_scripts_path)
prepend_path("PYTHONPATH", uwtools_package_path)
