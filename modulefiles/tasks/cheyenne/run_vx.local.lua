--[[
Loading intel is really only necessary when running verification tasks
with the COMPILER experiment parameter set to "gnu" because in that case,
the intel libraries aren't loaded, but the MET/METplus vx software still
needs them because it's built using the intel compiler.  Both the unload
and load("intel") lines can be removed if/when there is a version of
MET/METplus built using GNU.
--]]
unload("build_cheyenne_gnu")
load("intel/2021.2")
unload("python")
load("python_srw")
