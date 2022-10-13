help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Hera
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Hera ]===])

load("rocoto")

prepend_path("MODULEPATH","/contrib/miniconda3/modulefiles")
load(pathJoin("miniconda3", os.getenv("miniconda3_ver") or "4.5.12"))

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate regional_workflow
]===])
end
