#!/bin/bash
#=======================================================================
#=======================================================================

#
source path.sh

# download data
wget https://dl.dropboxusercontent.com/s/76ec5q3dtlt0twl/exp.tar.gz
tar -xzvf exp.tar.gz

# run fcst case
cd ./test_fcst/2019061500
export OMP_NUM_THREADS=1
ulimit -s unlimited
mpirun --allow-run-as-root -np 2 ufs_model

# check all the restart files
#-----------------------------------------------------------------------
# Array of all restarts
#-----------------------------------------------------------------------
declare -a restarts_created=( coupler.res \
                              fv_core.res.nc \
                              fv_core.res.tile1.nc \
                              fv_srf_wnd.res.tile1.nc \
                              fv_tracer.res.tile1.nc \
                              phy_data.nc \
                              sfc_data.nc )

#
#-----------------------------------------------------------------------
# check for existence of restarts.
#-----------------------------------------------------------------------
n_fail=0
for file in "${restarts_created[@]}" ; do
  rst_file=./RESTART/${file}
  if [ -f ${rst_file} ]; then
    echo "SUCCEED: file ${rst_file} exists"
  else
    echo "FAIL: file ${rst_file} does NOT exist"
    let "n_fail=n_fail+1"
  fi
done

if [[ $n_fail -gt 0 ]] ; then
  echo "TEST FAILED"
  exit 1
else
  echo "TEST SUCCEEDED"
fi
