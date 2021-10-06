#!/bin/bash

CWD=`pwd`
echo ${CWD}

cd ${CWD}/../src/gsi
./ush/build.comgsi
cp build/bin/gsi.x ../../bin/
#cp build/bin/enkf_wrf.x ../../bin/ 
#cp build/bin/enspreproc.x ../../bin/

cd ../../bin
