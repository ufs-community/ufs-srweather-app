help([[
This module loads python environement for running the UFS SRW-AQM/SD/FB on
the NOAA RDHPC machine Gaea C6
]])

whatis([===[Loads libraries needed for running the UFS SRW-AQM/SD/FB on Gaea c6 ]===])

unload("python")
prepend_path("MODULEPATH","/ncrc/proj/epic/rocoto/modulefiles/")
load("rocoto")
load("conda")

pushenv("MKLROOT", "/opt/intel/oneapi/mkl/2023.2.0/")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end
