help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Hera
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Hera ]===])

load("rocoto")
load("set_pythonpath")
load("conda")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end
