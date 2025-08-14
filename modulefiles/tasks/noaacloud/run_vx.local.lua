--[[
Compiler-specific modules are used for met and metplus libraries
--]]
local met_ver = (os.getenv("met_ver") or "12.0.1")
local metplus_ver = (os.getenv("metplus_ver") or "6.0.0")
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
load("ufs-pyenv")
load("conda")
setenv("SRW_ENV", "srw_app")

-- Declare Intel library variable for Azure
if os.getenv("PW_CSP") == "azure" then
   setenv("FI_PROVIDER","tcp")
end
