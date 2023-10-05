help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Gaea
]])

whatis([===[Loads libraries needed for running the UFS SRW App on gaea ]===])

unload("python")
load("set_pythonpath")
prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))
prepend_path("MODULEPATH","/lustre/f2/dev/role.epic/contrib/rocoto/modulefiles")
load("rocoto")
load("alps")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate workflow_tools
]===])
end
