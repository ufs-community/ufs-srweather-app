#!/bin/ksh
# Run_rocotorewind.ksh
# Will run `rocotorewind` directive on specified task (or "all") for regional FV3 preprocessor workflow
# To run:
# ./Run_rocotorewind.ksh <task_name>    # will rewind the specified task
# ./Run_rocotorewind.ksh all            # will rewind all tasks
# ./Run_rocotorewind.ksh DEAD           # will rewind all DEAD tasks
# ./Run_rocotorewind.ksh -grep pattern  # will rewind all tasks containing "pattern" in the name
# 
# Other options:
# -c <cycle>    Date/time of this cycle

rewindall=0
task=prep_task_1
pathnam=`pwd`
pathroc=${ROCOTO_PATH}

cycle=""

listoftasks=""
while [ $# -gt 0 ]
do
    if [[ $1 = "all" ]]; then
       rewindall=1
       echo "Rewinding all tasks"
       echo "${pathroc}/bin/rocotorewind -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} -a"
       ${pathroc}/bin/rocotorewind -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} -a
       exit 0 # if rewinding "all", only the above command is needed. Exit with status 0 to indicate success
    elif [[ $1 = "DEAD" ]]; then
       echo "Rewinding all DEAD tasks"
       ./Run_rocotorewind.ksh --cycle ${cycle} `${pathroc}/bin/rocotostat -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} | awk '/DEAD/ {print $2}' | tr '\n' ' '`
       exit $? # This here is some fun recursion, eh?
    elif [[ $1 = "SUBMIT" ]]; then
       echo "Rewinding all SUBMIT tasks"
       ./Run_rocotorewind.ksh --cycle ${cycle} `${pathroc}/bin/rocotostat -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} | awk '/SUBMIT/ {print $2}' | tr '\n' ' '`
       exit $? # Even more recursion!
    elif [[ $1 = "--grep" ]]; then
       shift
       echo "Rewinding all tasks containing '$1' in task name"
       ./Run_rocotorewind.ksh --cycle ${cycle} `${pathroc}/bin/rocotostat -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} | awk '// {print $2}' | grep $1 | tr '\n' ' '`
       exit $? # Recurse all the things!
    elif [[ $1 = "--cycle" || $1 = "-c" ]]; then
       shift
       cycle=$1
       echo "Rewinding tasks for cycle ${cycle}"
    else
       echo "Rewinding task $1"
       listoftasks="${listoftasks} -t $1"
    fi
    shift
done

if [ -z "$cycle" ]; then
   #Default to a random date, it's really dangerous to rewind across all dates as a default behavior so we won't even try
   cycle=201705010000
   echo "No cycle specified, defaulting to ${cycle}"
fi

if [ -z "${listoftasks}" ]; then
   echo "No tasks found, check the options you provided."
   exit 1
fi

echo "${pathroc}/bin/rocotorewind -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} ${listoftasks}"
${pathroc}/bin/rocotorewind -w ${pathnam}/FV3.xml -d ${pathnam}/prep.db -c ${cycle} ${listoftasks}

exit $?

