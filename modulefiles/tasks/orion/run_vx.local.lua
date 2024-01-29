--[[
Compiler-specific modules are used for met and metplus libraries
--]]
local met_ver = (os.getenv("met_ver") or "10.1.1")
local metplus_ver = (os.getenv("metplus_ver") or "4.1.1")
if (mode() == "load") then 
  load(pathJoin("met", met_ver))
  load(pathJoin("metplus",metplus_ver))
end
local base_met = os.getenv("met_ROOT") or os.getenv("MET_ROOT")
local base_metplus = os.getenv("metplus_ROOT") or os.getenv("METPLUS_ROOT")

setenv("MET_INSTALL_DIR", base_met)
setenv("MET_BIN_EXEC",    pathJoin(base_met,"bin"))
setenv("MET_BASE",        pathJoin(base_met,"share/met"))
setenv("MET_VERSION",     met_ver)
setenv("METPLUS_VERSION", metplus_ver)
setenv("METPLUS_ROOT",    base_metplus)
setenv("METPLUS_PATH",    base_metplus)


if (mode() == "unload") then 
  unload(pathJoin("met", met_ver))
  unload(pathJoin("metplus",metplus_ver))
end
load("stack-python/3.9.7")
load("python_srw")
