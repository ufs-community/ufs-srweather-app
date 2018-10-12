#!/bin/bash
# Run_rocoto.ksh
# Will run `rocotorun` directive for regional FV3 preprocessing workflow
# To run:
# ./run_rocoto.ksh

#rcroot="/scratch/software/Odin/Rocoto/rocoto-1.2.4/bin"
rcscript="FV3_Odin.xml"

pathnam="/scratch/ywang/external/regionalFV3/fv3gfs/regional"
pathlog="/scratch/ywang/external/regionalFV3"


rcdb="${rcscript%.*}".db

echo "rocotorun -w ${pathnam}/${rcscript} -d ${pathlog}/${rcdb}"
rocotorun -w ${pathnam}/${rcscript} -d ${pathlog}/${rcdb}


if [[ "$1" == "-q" ]]; then
  rocotostat -w ${pathnam}/${rcscript} -d ${pathlog}/${rcdb} ${@:2}
elif [[ "$1" == "-i" ]]; then
  while [[ 1 ]]
  do
    rocotostat -w ${pathnam}/${rcscript} -d ${pathlog}/${rcdb} ${@:2}
    sleep 20
    echo "rocotorun -w ${pathnam}/${rcscript} -d ${pathlog}/${rcdb}"
    rocotorun -w ${pathnam}/${rcscript} -d ${pathlog}/${rcdb}
  done

elif [[ "$1" == "-k" ]]; then
  rocotocheck -w ${pathnam}/${rcscript} -d ${pathlog}/${rcdb} ${@:2}
else
  echo "---- Cycles:"
  grep -oP "(?<=<cycledef>)[^<]+" ${rcscript}

  echo "---- All tasks are:"
  grep -oP "(?<=<task name=\")[^<\"]+" ${rcscript}
fi
