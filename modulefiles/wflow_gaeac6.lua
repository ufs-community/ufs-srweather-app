help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Gaea C6
]])

whatis([===[Loads libraries needed for running the UFS SRW App on gaea c6 ]===])

unload("python")
prepend_path("MODULEPATH","/ncrc/proj/epic/c6/modulefiles/")
load("rocoto/1.3.7")
load("conda")

if mode() == "load" then
   execute{cmd="conda activate srw_app", modeA={"load"}}
end
