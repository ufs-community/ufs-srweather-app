#!/bin/bash 
#
set -ax
#
export dev_fix=/lfs/h2/emc/physics/noscrub/UFS_SRW_App/aqm.v7.0.8/fix
cd ../

export HOMEaqm=$(pwd)

cd $HOMEaqm

cp -rp ${dev_fix} .

