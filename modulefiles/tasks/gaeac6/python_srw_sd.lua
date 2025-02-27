load("darshan-runtime/3.4.4")
unload("python")
load("conda")

setenv("SRW_ENV", "srw_sd")
setenv("LD_PRELOAD", "/usr/lib64/libstdc++.so.6")
setenv("FI_VERBS_PREFER_XRC", "0")

