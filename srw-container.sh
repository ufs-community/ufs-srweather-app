#!/bin/bash 
export SINGULARITYENV_FI_PROVIDER=tcp
export SINGULARITY_SHELL=/usr/lmod/lmod/init/bash
export SINGULARITYENV_PREPEND_PATH="/home/ubuntu/ufs-srweather-app/container-bin"
img="/home/ubuntu/ubuntu22.04-intel-srw-ss-v1.6.0.img"
cmd=$(basename "$0")
arg="$@"
#echo running: singularity exec "${img}" $cmd $arg
/usr/local/bin/singularity exec -B /home -B /scratch "${img}" $cmd $arg

