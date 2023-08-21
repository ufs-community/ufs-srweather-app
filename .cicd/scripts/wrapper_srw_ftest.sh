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
if [[ "${SRW_PLATFORM}" == cheyenne ]] || [[ "${SRW_PLATFORM}" == derecho ]]; then
  workflow_cmd=qsub  
else
  workflow_cmd=sbatch
fi

# Customize wrapper scripts
if [[ "${SRW_PLATFORM}" == gaea ]]; then
  sed -i '15i #SBATCH --clusters=c4' ${WORKSPACE}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
  sed -i 's|qos=batch|qos=windfall|g' ${WORKSPACE}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
fi

# Call job card
echo "Running: ${workflow_cmd} -A ${SRW_PROJECT} ${WORKSPACE}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh"
${workflow_cmd} -A ${SRW_PROJECT} ${WORKSPACE}/.cicd/scripts/${workflow_cmd}_srw_ftest.sh
