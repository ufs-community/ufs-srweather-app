#!/bin/ksh
# Run_rocotostat.ksh
# Will run `rocotostat` directive on specified task for regional FV3 preprocessing workflow
# To run:
# ./Run_rocotostat.ksh -t <task_name> -c <cycle>
# All arguments are optional, if no task or cycle are specified than all tasks and/or cycles will be displayed

pathnam=`pwd`
pathroc=${ROCOTO_PATH}

task=""
cycle=":"
while [ $# -gt 0 ]
do
   if [[ $1 = "--cycle" || $1 = "-c" ]]; then
      shift
      cycle=$1
   elif [[ $1 = "--task" || $1 = "-t" ]]; then
      shift
      task=$1
   else
      echo "ERROR: unknown argument $1"
      exit 1
   fi
   shift
done

if [ -z "$task" ]
then
   echo "${pathroc}/bin/rocotostat -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle}"
   ${pathroc}/bin/rocotostat -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle}
else
   echo "${pathroc}/bin/rocotostat -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} -t ${task}"
   ${pathroc}/bin/rocotostat -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} -t ${task}
fi
