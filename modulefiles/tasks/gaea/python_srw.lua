load("darshan-runtime/3.4.0")
unload("python")
load("conda")

setenv("SRW_ENV", "srw_app")
setenv("LD_PRELOAD", "/opt/cray/pe/gcc/12.2.0/snos/lib64/libstdc++.so.6")

