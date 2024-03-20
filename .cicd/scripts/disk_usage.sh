#!/usr/bin/env bash

# Output a CSV report of disk usage on subdirs of some path
# Usage: 
#    [JOB_NAME=<ci_job>] [BUILD_NUMBER=<n>] [SRW_COMPILER=<intel>] [SRW_PLATFORM=<machine>] disk_usage path depth size outfile.csv
#
# args:
#    directory=$1
#    depth=$2
#    size=$3
#    outfile=$4

[[ -n ${WORKSPACE} ]] || WORKSPACE=$(pwd)
[[ -n ${SRW_PLATFORM} ]] || SRW_PLATFORM=$(hostname -s 2>/dev/null) || SRW_PLATFORM=$(hostname 2>/dev/null)
[[ -n ${SRW_COMPILER} ]] || SRW_COMPILER=compiler

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Get repository root from Jenkins WORKSPACE variable if set, otherwise, set
# relative to script directory.
declare workspace
if [[ -n "${WORKSPACE}/${SRW_PLATFORM}" ]]; then
    workspace="${WORKSPACE}/${SRW_PLATFORM}"
else
    workspace="$(cd -- "${script_dir}/../.." && pwd)"
fi

echo "STAGE_NAME=${STAGE_NAME}" # from pipeline
outfile="${4:-${workspace}-${SRW_COMPILER}-disk-usage${STAGE_NAME}.csv}"

function disk_usage() {
    local directory=${1:-${PWD}}
    local depth=${2:-1}
    local size=${3:-k}
    echo "Disk usage: ${JOB_NAME:-ci}/${SRW_PLATFORM}/$(basename $directory)"
    (
    cd $directory || exit 1
    echo "Platform,Build,Owner,Group,Inodes,${size:-k}bytes,Access Time,Filename"
    du -Px -d ${depth:-1} --inode --exclude='./workspace' | \
        while read line ; do
            arr=($line); inode=${arr[0]}; filename=${arr[1]};
            echo "${SRW_PLATFORM}-${SRW_COMPILER:-compiler},${JOB_NAME:-ci}/${BUILD_NUMBER:-0},$(stat -c '%U,%G' $filename),${inode:-0},$(du -Px -s -${size:-k} --time $filename)" | tr '\t' ',' ;
        done | sort -t, -k5 -n #-r
    )
    echo ""
}

disk_usage $1 $2 $3 | tee ${outfile}
