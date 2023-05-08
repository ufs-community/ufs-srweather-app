load(pathJoin("intel", os.getenv("intel_ver")))
load(pathJoin("python", os.getenv("python_ver")))
load(pathJoin("prod_util", os.getenv("prod_util_ver")))

local mod_path, mod_file = splitFileName(myFileName())
local uwtools_scripts_path =  pathJoin(mod_path, "../../../ush/python_utils/uwtools")
local uwtools_package_path =  pathJoin(mod_path, "../../../ush/python_utils/uwtools/src/")

prepend_path("PYTHONPATH", uwtools_scripts_path)
prepend_path("PYTHONPATH", uwtools_package_path)
