#!/bin/bash

set -eu

MACHINE_upper=${MACHINE^^}

echo "MACHINE:" ${MACHINE}
echo "COMPILER:" ${COMPILER}

case "${MACHINE_upper}" in
#
  "WCOSS_CRAY")
#    module load cmake/3.20.2
    export CMAKE_C_COMPILER=cc
    export CMAKE_CXX_COMPILER=CC
    export CMAKE_Fortran_COMPILER=ftn
    export CMAKE_Platform=wcoss_cray
    ;;
#
  "WCOSS_DELL_P3")
#    module load cmake/3.20.0
    export CMAKE_C_COMPILER=mpiicc
    export CMAKE_CXX_COMPILER=mpiicpc
    export CMAKE_Fortran_COMPILER=mpiifort
    export CMAKE_Platform=wcoss_dell_p3
    ;;
#
  "HERA")
#    module load cmake/3.20.1
    export CMAKE_C_COMPILER=mpiicc
    export CMAKE_CXX_COMPILER=mpiicpc
    export CMAKE_Fortran_COMPILER=mpiifort
    export CMAKE_Platform=hera.intel
    ;;
#
  "ORION")
#    module load cmake/3.18.1
    export CMAKE_C_COMPILER=mpiicc
    export CMAKE_CXX_COMPILER=mpiicpc
    export CMAKE_Fortran_COMPILER=mpiifort
    export CMAKE_Platform=orion.intel
    ;;
#
  "JET")
#    module load cmake/3.20.1
    export CMAKE_C_COMPILER=mpiicc
    export CMAKE_CXX_COMPILER=mpiicpc
    export CMAKE_Fortran_COMPILER=mpiifort
    export CMAKE_Platform=jet.intel
    ;;
#
  "CHEYENNE")
#    module load cmake/3.18.2
    export CMAKE_C_COMPILER=mpicc
    export CMAKE_CXX_COMPILER=mpicxx
    export CMAKE_Fortran_COMPILER=mpif90
    if [ "${COMPILER}" = "intel" ]; then
      export CMAKE_Platform=cheyenne.intel  
    elif [ "${COMPILER}" = "gnu" ]; then
      export CMAKE_Platform=cheyenne.gnu
    fi
    ;;
  "MACOS")
    export CMAKE_C_COMPILER=mpicc
    export CMAKE_CXX_COMPILER=mpicxx
    export CMAKE_Fortran_COMPILER=mpifort
    export CMAKE_Platform=macosx.gnu
    ;;
#
  *)
    printf "The current machine is not detected."
    ;;
#
esac

echo "CMAKE_C_COMPILER:" ${CMAKE_C_COMPILER}
echo "CMAKE_CXX_COMPILER:" ${CMAKE_CXX_COMPILER}
echo "CMAKE_Fortran_COMPILER:" ${CMAKE_Fortran_COMPILER}
echo "CMAKE_Platform:" ${CMAKE_Platform}

