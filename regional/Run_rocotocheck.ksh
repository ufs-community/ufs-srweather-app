#!/bin/ksh
# Run_rocotocheck.ksh
# Will run `rocotocheck` directive on specified task for regional FV3 preprocessing workflow
# To run:
# ./Run_rocotocheck.ksh <task_name> -c <cycle>

pathnam=`pwd`
pathroc=${ROCOTO_PATH}

cycle=201705010000

task=prep_task_1
while [ $# -gt 0 ]
do
    if [[ $1 = "--cycle" || $1 = "-c" ]]; then
       shift
       cycle=$1
    else
       task=$1
    fi
    shift
done

echo "Checking task $task"
echo "${pathroc}/bin/rocotocheck -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} -t ${task}"
${pathroc}/bin/rocotocheck -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} -t ${task}
