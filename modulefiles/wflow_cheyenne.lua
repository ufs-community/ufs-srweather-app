help([[
This module loads python environement for running the UFS SRW App on
on the CISL machine Cheyenne
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Cheyenne ]===])

load("ncarenv")

append_path("MODULEPATH","/glade/p/ral/jntp/UFS_SRW_app/modules")
load("rocoto")

unload("python")

load("conda")
load("set_pythonpath")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end

