help([[
This module loads python environement for running the UFS SRW App on
on the CISL machine Derecho (Cray) 
]])

whatis([===[Loads libraries for running the UFS SRW Workflow on Derecho ]===])

append_path("MODULEPATH","/glade/work/epicufsrt/contrib/derecho/modulefiles")
load("rocoto/1.3.7")

unload("python")

load("conda")


if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate srw_app
]===])
end

