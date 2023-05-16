--[[
Loading intel is really only necessary when running verification tasks
with the COMPILER experiment parameter set to "gnu" because in that case,
the intel libraries aren't loaded, but the MET/METplus vx software still
needs them because it's built using the intel compiler.  This line can
be removed if/when there is a version of MET/METplus built using GNU.
--]]
load(pathJoin("intel", os.getenv("intel_ver") or "18.0.5.274"))
load("python_srw")
