help([[
This module loads python environement for running the UFS SRW App on
on the CISL machine Derecho (Cray) 
]])

whatis([===[Loads libraries for running the UFS SRW Workflow on Derecho ]===])

load("ncarenv")

append_path("MODULEPATH","/glade/work/epicufsrt/contrib/derecho/rocoto/modulefiles")
load("rocoto")

unload("python")

load("conda")
load("set_pythonpath")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end

