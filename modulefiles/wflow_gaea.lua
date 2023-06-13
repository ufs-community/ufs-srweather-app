help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Gaea
]])

whatis([===[Loads libraries needed for running the UFS SRW App on gaea ]===])

load("set_pythonpath")
prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))
load("rocoto")
load("alps")

setenv("PROJ_LIB", "/lustre/f2/dev/role.epic/contrib/miniconda3/4.12.0/envs/regional_workflow/share/proj")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate workflow_tools
]===])
end
