help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Jet
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Jet ]===])

load("rocoto")
load("set_pythonpath")

prepend_path("MODULEPATH","/mnt/lfs4/HFIP/hfv3gfs/role.epic/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.12.0"))

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate workflow_tools
]===])
end
