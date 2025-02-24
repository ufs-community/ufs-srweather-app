#!/usr/bin/env bash

############################
#
# This is a wrapper script for the srw_ftest.sh script. It was created so we can 
# test all of the wrapper script tasks within the Jenkins pipeline. It determines which 
# workflow manager is installed on the platform and calls the apprioprate job card:
#    sbatch: sbatch_srw_ftest.sh
#    pbs: qsub_srw_ftest.sh
###########################

# Set workflow cmd
declare workflow_cmd
declare arg_1
if [[ "${SRW_PLATFORM}" == cheyenne ]] || [[ "${SRW_PLATFORM}" == derecho ]]; then
    workflow_cmd=qsub
    arg_1=""
else
    workflow_cmd=sbatch
    arg_1="--parsable"
fi

# Customize wrapper scripts
if [[ "${SRW_PLATFORM}" == gaeac5 ]]; then
    sed -i '15i #SBATCH --clusters=c5' ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
    sed -i 's|qos=batch|qos=normal|g' ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
    sed -i 's|00:30:00|00:45:00|g' ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
    sed -i 's|${JOBSdir}/JREGIONAL_RUN_POST|$USHdir/load_modules_run_task.sh "gaeac5" "run_post" ${JOBSdir}/JREGIONAL_RUN_POST|g' ${WORKSPACE}/${SRW_PLATFORM}/ush/wrappers/run_post.sh
fi

if [[ "${SRW_PLATFORM}" == gaeac6 ]]; then
    sed -i '15i #SBATCH --clusters=c6' ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
    sed -i 's|qos=batch|qos=normal|g' ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
    sed -i 's|00:30:00|00:45:00|g' ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
    sed -i 's|${JOBSdir}/JREGIONAL_RUN_POST|$USHdir/load_modules_run_task.sh "gaeac6" "run_post" ${JOBSdir}/JREGIONAL_RUN_POST|g' ${WORKSPACE}/${SRW_PLATFORM}/ush/wrappers/run_post.sh
fi

if [[ "${SRW_PLATFORM}" == hera ]]; then
    if [[ "${SRW_COMPILER}" == gnu ]]; then
        sed -i 's|00:30:00|00:45:00|g' ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
    fi
fi

if [[ "${TASK_DEPTH}" == 0 ]] ; then
    exit 0
fi

# Call job card and return job_id
echo "Running: ${workflow_cmd} -A ${SRW_PROJECT} ${arg_1} ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh"
job_id=$(${workflow_cmd} -A ${SRW_PROJECT} ${arg_1} ${WORKSPACE}/${SRW_PLATFORM}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh)

echo "Waiting ten seconds for node to initialize"
sleep 10

# Check for job and exit when done
while true
do
    if [[ "${SRW_PLATFORM}" == derecho ]]; then
        check_job="qstat -u ${USER} -r ${job_id}"
    else
	check_job="squeue -u ${USER} -j ${job_id} --noheader"
    fi
    job_id_info=$($check_job)
    if [ ! -z "$job_id_info" ]; then
        echo "Job is still running. Check again in two minutes"
        sleep 120
    else
        echo "Job has completed."

        # Return exit code and check for results file first
        results_file="${WORKSPACE}/${SRW_PLATFORM}/functional_test_results_${SRW_PLATFORM}_${SRW_COMPILER}.txt"
        if [ ! -f "$results_file" ]; then
            echo -e "Missing results file! \nexit 1"
            exit 1
        fi

        # Set exit code to number of failures
        set +e
        failures=$(grep ": FAIL" ${results_file} | wc -l)
        if [[ $failures -ne 0 ]]; then
            failures=1
        fi

        set -e
        echo "exit ${failures}"
        exit ${failures}
    fi
done
