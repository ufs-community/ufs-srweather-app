load("conda")
setenv("SRW_ENV", "srw_app")

-- Declare Intel library variable for Azure
if os.getenv("PW_CSP") == "azure" then
   setenv("FI_PROVIDER","tcp")
end

setenv("LD_PRELOAD", "/apps/gnu/gcc-13.2.0/lib64/libstdc++.so.6")
