help([[
This module loads python environement for running the UFS SRW App on
the NOAA operational machine WCOSS2 (Cactus/Dogwood)"
]])

whatis([===[Loads libraries needed for running the UFS SRW App on WCOSS2 ]===])

load(pathJoin("intel", os.getenv("intel_ver")))
load(pathJoin("python", os.getenv("python_ver")))
load("set_pythonpath")

prepend_path("MODULEPATH","/apps/ops/test/nco/modulefiles")
load(pathJoin("core/rocoto", os.getenv("rocoto_ver")))

