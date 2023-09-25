--[[
Compiler-specific modules are used for met and metplus libraries
--]]
load(pathJoin("met", os.getenv("met_ver") or "10.1.1"))
load(pathJoin("metplus", os.getenv("metplus_ver") or "4.1.1"))
load("python_srw")

setenv("MET_INSTALL_DIR", os.getenv("met_ROOT"))
setenv("MET_BASE", pathJoin(os.getenv("met_ROOT"), "share", "met"))
setenv("METPLUS_PATH", os.getenv("metplus_ROOT"))

