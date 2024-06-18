load("conda")
setenv("SRW_ENV", "srw_app")

-- Add missing libstdc binary for Azure
if os.getenv("PW_CSP") == "azure" then
   setenv("LD_PRELOAD","/opt/nvidia/nsight-systems/2023.1.2/host-linux-x64/libstdc++.so.6")
end
