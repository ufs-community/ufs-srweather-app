#!/bin/bash

CWD=`pwd`
echo ${CWD}

cd ${CWD}/../src/JEDI
mkdir -p build
cd build
module purge
source ${CWD}/../conf_cmaq/fv3gfs_aqm/JEDI_build_hera.env 
module list
ecbuild -DMPIEXEC_EXECUTABLE=‘which srun‘ -DMPIEXEC_NUMPROC_FLAG="-n" ../ 
make -j 8

cd ../../../bin
ln -sf ${CWD}/../src/JEDI/build/bin/fv3jedi* .

