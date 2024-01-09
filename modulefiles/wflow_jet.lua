help([[
This module loads python environement for running the UFS SRW App on
the NOAA RDHPC machine Jet
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Jet ]===])

load("rocoto")
load("set_pythonpath")

load("conda")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end
