help([[
This module loads python environement for running the UFS SRW App on
the NOAA cloud
]])

whatis([===[Loads libraries needed for running the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH","/apps/modules/modulefiles")
load("rocoto")
load("set_pythonpath")


load("conda")

setenv("PROJ_LIB","/contrib/EPIC/miniconda3/4.12.0/envs/regional_workflow/share/proj")
setenv("OPT","/contrib/EPIC/hpc-modules")
append_path("PATH","/contrib/EPIC/miniconda3/4.12.0/envs/regional_workflow/bin")
prepend_path("PATH","/contrib/EPIC/bin")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end
