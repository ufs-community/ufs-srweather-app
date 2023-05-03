#!/usr/bin/env bash
#
# A test script for running the SRW application unittest tests that
# should be tested on-prem.
#
set -e -u -x

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Get repository root from Jenkins WORKSPACE variable if set, otherwise,
# set relative to script directory.
declare workspace
if [[ -n "${WORKSPACE}" ]]; then
  workspace="${WORKSPACE}"
else
  workspace="$(cd -- "${script_dir}/../.." && pwd)"
fi

# Only run this on machines with hpss access
hpss_machines=( jet hera )
if [ $hpss_machines =~ ${SRW_PLATFORM} ] ; then

  module load hpss
  module use ${workspace}/modulefiles
  module load wflow_${SRW_PLATFORM}

  conda activate regional_workflow

  export PYTHONPATH=${workspace}/ush
  python -m unittest $workspace/tests/test_python/test_retrieve_data.py

fi
