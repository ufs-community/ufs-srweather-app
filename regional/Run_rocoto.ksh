#!/bin/ksh
# Run_rocoto.ksh
# Will run `rocotorun` directive for regional FV3 preprocessing workflow
# To run:
# ./Run_rocoto.ksh

pathnam=`pwd`
pathroc=${ROCOTO_PATH}

# rm ${pathnam}/HRRR_retro.ys.db
echo "${pathroc}/bin/rocotorun -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -v 10"
${pathroc}/bin/rocotorun -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -v 10
