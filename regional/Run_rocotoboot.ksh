#!/bin/ksh
pathnam=`pwd`
pathroc=${ROCOTO_PATH}
#cycle=201705040000

task=prep_task_1

pwd
#${pathroc}/bin/rocotoboot -w ${pathnam}/HRRR_retro_start2.ys.xml -d ${pathnam}/HRRR_retro_start2.ys.db -c ${cycle} -t ${task}
echo "${pathroc}/bin/rocotoboot -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} -t ${task}"
${pathroc}/bin/rocotoboot -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} -t ${task}


