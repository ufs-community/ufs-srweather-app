#!/usr/bin/env bash
#
# A unified test script for the SRW application. This script is expected to
# test the SRW application for all supported platforms. NOTE: At this time,
# this script is a placeholder for a more robust test framework.
#
set -e -u -x

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Get repository root from Jenkins WORKSPACE variable if set, otherwise, set
# relative to script directory.
declare workspace
if [[ -n "${WORKSPACE}" ]]; then
    workspace="${WORKSPACE}"
else
    workspace="$(cd -- "${script_dir}/../.." && pwd)"
fi

# Verify that there is a non-zero sized weather model executable.
[[ -s "${workspace}/bin/ufs_model" ]] || [[ -s "${workspace}/bin/NEMS.exe" ]]
