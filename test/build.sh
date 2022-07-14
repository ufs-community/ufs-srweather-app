#!/bin/bash
#=======================================================================
# Description:  This script runs a build test for the
#               UFS Short-Range Weather App. The executables
#               built are listed below in $executables_created.
#               A pass/fail message is printed at the end of the output.
#
# Usage:  see function usage below
#
# Examples: ./build.sh hera >& test.out &
#
set -eux    # Uncomment for debugging
#=======================================================================

fail() { echo -e "\n$1\n" >> ${TEST_OUTPUT} && exit 1; }

function usage() {
  echo
  echo "Usage: $0 machine"
  echo
  exit 1
}

machines=( hera jet cheyenne orion wcoss2 gaea odin singularity macos noaacloud )

[[ $# -eq 2 ]] && usage


#-----------------------------------------------------------------------
# Set some directories
#-----------------------------------------------------------------------
PID=$$
TEST_DIR=$( pwd )                   # Directory with this script
TOP_DIR=${TEST_DIR}/..              # Top level (umbrella repo) directory
TEST_OUTPUT=${TEST_DIR}/build_test${PID}.out

# set PLATFORM (MACHINE)
MACHINE="$1"
PLATFORM="${MACHINE}"
printf "PLATFORM(MACHINE)=${PLATFORM}\n" >&2

machine=$(echo "${MACHINE}" | tr '[A-Z]' '[a-z]')  # scripts in sorc need lower case machine name

#-----------------------------------------------------------------------
# Check that machine is valid
#-----------------------------------------------------------------------
if [[ "${machines[@]}" =~ "$machine" ]]; then
  echo "machine ${machine} is valid"
else
  echo "ERROR: machine ${machine} is NOT valid"
  exit 1
fi

#-----------------------------------------------------------------------
# Set compilers to be tested depending on machine
#-----------------------------------------------------------------------
if [ "${machine}" == "cheyenne" ] ; then
  compilers=( intel gnu )
elif [ "${machine}" == "macos" ] || [ "${machine}" == "singularity" ] ; then
  compilers=( gnu )
else
  compilers=( intel )
fi


build_it=0        # Set to 1 to skip build (for testing pass/fail criteria)
#-----------------------------------------------------------------------
# Create the output file if it doesn't exist
#-----------------------------------------------------------------------
if [ ! -f "$TEST_OUTPUT" ]; then
   touch ${TEST_OUTPUT}
fi

cd ${TOP_DIR}

ENV_DIR=${TOP_DIR}/env
#-----------------------------------------------------------------------
# Array of all required executables built
#-----------------------------------------------------------------------
declare -a executables_created=( chgres_cube \
                                 emcsfc_ice_blend \
                                 emcsfc_snow2mdl \
                                 filter_topo \
                                 fregrid \
                                 fvcom_to_FV3 \
                                 global_cycle \
                                 global_equiv_resol \
                                 inland \
                                 lakefrac \
                                 make_hgrid \
                                 make_solo_mosaic \
                                 upp.x \
                                 orog \
                                 orog_gsl \
                                 regional_esg_grid \
                                 sfc_climo_gen \
                                 shave \
                                 ufs_model \
                                 vcoord_gen )


#-----------------------------------------------------------------------
# Array of all optional GSI executables built
#-----------------------------------------------------------------------
declare -a executables_gsi_created=( enkf.x \
                                     gsi.x \
                                     nc_diag_cat.x \
                                     ncdiag_cat_serial.x \
                                     test_nc_unlimdims.x )

#-----------------------------------------------------------------------
# Array of all optional rrfs_utl executables built
#-----------------------------------------------------------------------
declare -a executables_rrfs_utl_created=( adjust_soiltq.exe \
                                          check_imssnow_fv3lam.exe \
                                          fv3lam_nonvarcldana.exe \
                                          gen_annual_maxmin_GVF.exe \
                                          gen_cs.exe \
                                          gen_ensmean_recenter.exe \
                                          lakesurgery.exe \
                                          process_imssnow_fv3lam.exe \
                                          process_larccld.exe \
                                          process_Lightning.exe \
                                          process_metarcld.exe \
                                          process_NSSL_mosaic.exe \
                                          process_updatesst.exe \
                                          ref2tten.exe \
                                          update_bc.exe \
                                          update_GVF.exe \
                                          update_ice.exe \
                                          use_raphrrr_sfc.exe )

#-----------------------------------------------------------------------
# Set up the build environment and run the build script.
#-----------------------------------------------------------------------
  for compiler in "${compilers[@]}"; do
    BUILD_DIR=${TOP_DIR}/build_${compiler}
    BIN_DIR=${TOP_DIR}/bin_${compiler}
    EXEC_DIR=${BIN_DIR}/bin
    if [ $build_it -eq 0 ] ; then
      ./devbuild.sh --platform=${machine} --compiler=${compiler} --build-dir=${BUILD_DIR} --install-dir=${BIN_DIR} \
        --clean --rrfs || fail "Build ${machine} ${compiler} FAILED"
    fi    # End of skip build for testing

  #-----------------------------------------------------------------------
  # check for existence of executables.
  #-----------------------------------------------------------------------
  n_fail=0
  for file in "${executables_created[@]}" "${executables_gsi_created[@]}" "${executables_rrfs_utl_created[@]}" ; do
    exec_file=${EXEC_DIR}/${file}
    if [ -f ${exec_file} ]; then
      echo "SUCCEED: ${compiler} executable file ${exec_file} exists" >> ${TEST_OUTPUT}
    else
      echo "FAIL: ${compiler} executable file ${exec_file} does NOT exist" >> ${TEST_OUTPUT}
      let "n_fail=n_fail+1"
    fi
  done
done   # End compiler loop
#-----------------------------------------------------------------------
# Set message for output
#-----------------------------------------------------------------------
msg="????"
if [[ $n_fail -gt 0 ]] ; then
  echo "BUILD(S) FAILED" >> ${TEST_OUTPUT}
  msg="FAIL"
else
  echo "ALL BUILDS SUCCEEDED" >> ${TEST_OUTPUT}
  msg="PASS"
fi
echo "$msg" >> ${TEST_OUTPUT}
