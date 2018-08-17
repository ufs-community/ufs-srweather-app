#!/bin/bash

#Source variables from user-defined file
. ${BASEDIR}/fv3gfs/ush/setup_grid_orog_ICs_BCs.sh

#Run the run.regional script to execute FV3
${BASEDIR}/run_dirs/${subdir_name}/run.regional
