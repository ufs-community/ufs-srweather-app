help([[
This module loads python environement for running the UFS SRW-AQM/SD/FB on
the NOAA RDHPC machine Gaea C6
]])

whatis([===[Loads libraries needed for running the UFS SRW-AQM/SD/FB on Gaea C6 ]===])

unload("python")
prepend_path("MODULEPATH","/ncrc/proj/epic/rocoto/modulefiles")
load("rocoto")
prepend_path("MODULEPATH","/ncrc/proj/epic/miniconda3/modulefiles")
load("miniconda3")

pushenv("MKLROOT", "/opt/intel/oneapi/mkl/2023.2.0")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end
