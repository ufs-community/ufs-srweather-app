#!/bin/ksh
# Run_rocoto.ksh
# Will run `rocotorun` directive for regional FV3 preprocessing workflow
# To run:
# ./run_rocoto.ksh

pathnam=`pwd`

echo "rocotorun -w ${pathnam}/FV3_Theia.xml -d ${pathnam}/FV3_Theia.db -v 2"
rocotorun -w ${pathnam}/FV3_Theia.xml -d ${pathnam}/FV3_Theia.db -v 10
