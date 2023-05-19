help([[
This module loads python environement for running the UFS SRW App on
the NOAA cloud
]])

whatis([===[Loads libraries needed for running the UFS SRW App on NOAA cloud ]===])

prepend_path("MODULEPATH","/apps/modules/modulefiles")
load("rocoto")
load("set_pythonpath")


prepend_path("MODULEPATH","/contrib/EPIC/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

setenv("PROJ_LIB","/contrib/EPIC/miniconda3/4.12.0/envs/regional_workflow/share/proj")
setenv("OPT","/contrib/EPIC/hpc-modules")
append_path("PATH","/contrib/EPIC/miniconda3/4.12.0/envs/regional_workflow/bin")
prepend_path("PATH","/contrib/EPIC/bin")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate regional_workflow
]===])
end
