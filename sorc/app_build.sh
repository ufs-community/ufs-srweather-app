#!/bin/bash

# usage instructions
usage () {
cat << EOF_USAGE
Usage: $0 --platform=PLATFORM [OPTIONS] ... [TARGETS]

OPTIONS
  -h, --help
      show this help guide
  -p, --platform=PLATFORM
      name of machine you are building on
      (e.g. cheyenne | hera | jet | orion | wcoss2)
  -c, --compiler=COMPILER
      compiler to use; default depends on platform
      (e.g. intel | gnu | cray | gccgfortran)
  -a, --app=APPLICATION
      weather model application to build; for example, ATMAQ for Online-CMAQ
      (e.g. ATM | ATMAQ | ATMW | S2S | S2SW)
  --ccpp="CCPP_SUITE1,CCPP_SUITE2..."
      CCPP suites (CCPP_SUITES) to include in build; delimited with ','
  --enable-options="OPTION1,OPTION2,..."
      enable ufs-weather-model options; delimited with ','
      (e.g. 32BIT | INLINE_POST | UFS_GOCART | MOM6 | CICE6 | WW3 | CMEPS)
  --disable-options="OPTION1,OPTION2,..."
      disable ufs-weather-model options; delimited with ','
      (e.g. 32BIT | INLINE_POST | UFS_GOCART | MOM6 | CICE6 | WW3 | CMEPS)
  --extrn
      check out external components
  --continue
      continue with existing build
  --remove
      removes existing build; overrides --continue
  --clean
      does a "make clean"
  --build
      does a "make" (build only)
  --move
      move binaries to final location.
  --build-dir=BUILD_DIR
      build directory
  --install-dir=INSTALL_DIR
      installation prefix
  --bin-dir=BIN_DIR
      installation binary directory name ("exec" by default; any name is available)
  --build-type=BUILD_TYPE
      build type; defaults to Release
      (e.g. Debug | Release | RelWithDebInfo)
  --build-jobs=BUILD_JOBS
      number of build jobs; defaults to 4
  --use-sub-modules
      Use sub-component modules instead of top-level level SRW modules
  -v, --verbose
      build with verbose output

TARGETS
   default = builds the default list of apps (also not passing any target does the same)
   all = builds all apps
   Or any combinations of (ufs, ufs_utils, upp, gsi, rrfs_utils)

NOTE: See User's Guide for detailed build instructions

EOF_USAGE
}

# print settings
settings () {
cat << EOF_SETTINGS
Settings:

  SRW_DIR=${SRW_DIR}
  BUILD_DIR=${BUILD_DIR}
  INSTALL_DIR=${INSTALL_DIR}
  BIN_DIR=${BIN_DIR}
  PLATFORM=${PLATFORM}
  COMPILER=${COMPILER}
  APP=${APPLICATION}
  CCPP=${CCPP_SUITES}
  ENABLE_OPTIONS=${ENABLE_OPTIONS}
  DISABLE_OPTIONS=${DISABLE_OPTIONS}
  EXTRN=${EXTRN}
  REMOVE=${REMOVE}
  CONTINUE=${CONTINUE}
  BUILD_TYPE=${BUILD_TYPE}
  BUILD_JOBS=${BUILD_JOBS}
  VERBOSE=${VERBOSE}
  BUILD_UFS=${BUILD_UFS}
  BUILD_UFS_UTILS=${BUILD_UFS_UTILS}
  BUILD_UPP=${BUILD_UPP}
  BUILD_GSI=${BUILD_GSI}
  BUILD_RRFS_UTILS=${BUILD_RRFS_UTILS}
  BUILD_NEXUS=${BUILD_NEXUS}
  BUILD_AQM_UTILS=${BUILD_AQM_UTILS}

EOF_SETTINGS
}

# print usage error and exit
usage_error () {
  printf "ERROR: $1\n" >&2
  usage >&2
  exit 1
}

# default settings
LCL_PID=$$
SORC_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
SRW_DIR="${SORC_DIR}/.."
BUILD_DIR="${SORC_DIR}/build"
INSTALL_DIR="${SORC_DIR}/build"
BIN_DIR="exec"
COMPILER=""
APPLICATION=""
CCPP_SUITES=""
ENABLE_OPTIONS=""
DISABLE_OPTIONS=""
BUILD_TYPE="Release"
BUILD_JOBS=4
EXTRN=false
REMOVE=false
CONTINUE=false
VERBOSE=false

# Turn off all apps to build and choose default later
DEFAULT_BUILD=true 
BUILD_UFS="off"
BUILD_UFS_UTILS="off"
BUILD_UPP="off"
BUILD_GSI="off"
BUILD_RRFS_UTILS="off"
BUILD_NEXUS="off"
BUILD_AQM_UTILS="off"

# Make options
CLEAN=false
BUILD=false
MOVE=false
USE_SUB_MODULES=false #change default to true later

# process required arguments
if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
  usage
  exit 0
fi

# process optional arguments
while :; do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --platform=?*|-p=?*) PLATFORM=${1#*=} ;;
    --platform|--platform=|-p|-p=) usage_error "$1 requires argument." ;;
    --compiler=?*|-c=?*) COMPILER=${1#*=} ;;
    --compiler|--compiler=|-c|-c=) usage_error "$1 requires argument." ;;
    --app=?*|-a=?*) APPLICATION=${1#*=} ;;
    --app|--app=|-a|-a=) usage_error "$1 requires argument." ;;
    --ccpp=?*) CCPP_SUITES=${1#*=} ;;
    --ccpp|--ccpp=) usage_error "$1 requires argument." ;;
    --enable-options=?*) ENABLE_OPTIONS=${1#*=} ;;
    --enable-options|--enable-options=) usage_error "$1 requires argument." ;;
    --disable-options=?*) DISABLE_OPTIONS=${1#*=} ;;
    --disable-options|--disable-options=) usage_error "$1 requires argument." ;;
    --extrn) EXTRN=true ;;
    --extrn=?*|--extrn=) usage_error "$1 argument ignored." ;;
    --remove) REMOVE=true ;;
    --remove=?*|--remove=) usage_error "$1 argument ignored." ;;
    --continue) CONTINUE=true ;;
    --continue=?*|--continue=) usage_error "$1 argument ignored." ;;
    --clean) CLEAN=true ;;
    --build) BUILD=true ;;
    --move) MOVE=true ;;
    --build-dir=?*) BUILD_DIR=${1#*=} ;;
    --build-dir|--build-dir=) usage_error "$1 requires argument." ;;
    --install-dir=?*) INSTALL_DIR=${1#*=} ;;
    --install-dir|--install-dir=) usage_error "$1 requires argument." ;;
    --bin-dir=?*) BIN_DIR=${1#*=} ;;
    --bin-dir|--bin-dir=) usage_error "$1 requires argument." ;;
    --build-type=?*) BUILD_TYPE=${1#*=} ;;
    --build-type|--build-type=) usage_error "$1 requires argument." ;;
    --build-jobs=?*) BUILD_JOBS=$((${1#*=})) ;;
    --build-jobs|--build-jobs=) usage_error "$1 requires argument." ;;
    --verbose|-v) VERBOSE=true ;;
    --verbose=?*|--verbose=) usage_error "$1 argument ignored." ;;
    --use-sub-modules) USE_SUB_MODULES=true ;;
    # targets
    default) ;;
    all) DEFAULT_BUILD=false; BUILD_UFS="on";
         BUILD_UFS_UTILS="on"; BUILD_UPP="on";
         BUILD_GSI="on"; BUILD_RRFS_UTILS="on";;
    ufs) DEFAULT_BUILD=false; BUILD_UFS="on" ;;
    ufs_utils) DEFAULT_BUILD=false; BUILD_UFS_UTILS="on" ;;
    upp) DEFAULT_BUILD=false; BUILD_UPP="on" ;;
    gsi) DEFAULT_BUILD=false; BUILD_GSI="on" ;;
    rrfs_utils) DEFAULT_BUILD=false; BUILD_RRFS_UTILS="on" ;;
    nexus) DEFAULT_BUILD=false; BUILD_NEXUS="on" ;;
    aqm_utils) DEFAULT_BUILD=false; BUILD_AQM_UTILS="on" ;;
    # unknown
    -?*|?*) usage_error "Unknown option $1" ;;
    *) break
  esac
  shift
done

# Ensure uppercase / lowercase ============================================
APPLICATION="${APPLICATION^^}"
PLATFORM="${PLATFORM,,}"
COMPILER="${COMPILER,,}"
EXTERNALS="${EXTERNALS^^}"

# move the pre-compiled executables to the designated location and exit
if [ "${BUILD}" = false ] && [ "${MOVE}" = true ]; then
  if [[ ! ${SRW_DIR} -ef ${INSTALL_DIR} ]]; then
    printf "... Moving pre-compiled executables to designated location ...\n"
    mkdir -p ${SRW_DIR}/${BIN_DIR}
    cd "${INSTALL_DIR}/${BIN_DIR}"
    for file in *; do
      [ -x "${file}" ] && mv "${file}" "${SRW_DIR}/${BIN_DIR}"
    done
  fi
  exit 0
fi

# check if PLATFORM is set
if [ -z $PLATFORM ] ; then
  printf "\nERROR: Please set PLATFORM.\n\n"
  usage
  exit 0
fi
# set PLATFORM (MACHINE)
MACHINE="${PLATFORM}"
printf "PLATFORM(MACHINE)=${PLATFORM}\n" >&2

# check out external components specified in External.cfg
if [ "${EXTRN}" = true ]; then
  cd ${SORC_DIR}
  # remove existing components
  printf "... checking if external components exist ...\n"
  if [ -d "${SORC_DIR}/AQM-utils" ]; then
    printf "... removing AQM-utils ...\n"
    rm -rf "${SORC_DIR}/AQM-utils"
  fi
  if [ -d "${SORC_DIR}/arl_nexus" ]; then
    printf "... removing arl_nexus ...\n"
    rm -rf "${SORC_DIR}/arl_nexus"
  fi
  if [ -d "${SORC_DIR}/UFS_UTILS" ]; then
    printf "... removing UFS_UTILS ...\n"
    rm -rf "${SORC_DIR}/UFS_UTILS"
  fi
  if [ -d "${SORC_DIR}/ufs-weather-model" ]; then
    printf "... removing ufs-weather-model ...\n"
    rm -rf "${SORC_DIR}/ufs-weather-model"
  fi
  if [ -d "${SORC_DIR}/UPP" ]; then
    printf "... removing UPP ...\n"
    rm -rf "${SORC_DIR}/UPP"
  fi

  # run check-out
  printf "... checking out external components ...\n"
  ./manage_externals/checkout_externals
fi

# choose default apps to build
if [ "${DEFAULT_BUILD}" = true ]; then
  BUILD_UFS="on"
  BUILD_UFS_UTILS="on"
  BUILD_UPP="on"
fi

# Choose components to build for air quality modeling (SRW-AQM)
if [ "${APPLICATION}" = "ATMAQ" ]; then
  if [ "${DEFAULT_BUILD}" = true ]; then
    BUILD_NEXUS="on"
    BUILD_AQM_UTILS="on"
  fi
  if [ "${PLATFORM}" = "wcoss2" ]; then
    BUILD_POST_STAT="on"
  else
    BUILD_POST_STAT="off"
  fi
fi

set -eu

# automatically determine compiler
if [ -z "${COMPILER}" ] ; then
  case ${PLATFORM} in
    jet|hera|gaea) COMPILER=intel ;;
    orion) COMPILER=intel ;;
    wcoss2) COMPILER=intel ;;
    cheyenne) COMPILER=intel ;;
    macos,singularity) COMPILER=gnu ;;
    odin,noaacloud) COMPILER=intel ;;
    *)
      COMPILER=intel
      printf "WARNING: Setting default COMPILER=intel for new platform ${PLATFORM}\n" >&2;
      ;;
  esac
fi

printf "COMPILER=${COMPILER}\n" >&2

# print settings
if [ "${VERBOSE}" = true ] ; then
  settings
fi

# source version file only if it is specified in versions directory
BUILD_VERSION_FILE="${SRW_DIR}/versions/build.ver"
if [ -f ${BUILD_VERSION_FILE} ]; then
  . ${BUILD_VERSION_FILE}
fi

# set MODULE_FILE for this platform/compiler combination
MODULE_FILE="build_${PLATFORM}_${COMPILER}"
if [ ! -f "${SRW_DIR}/modulefiles/${MODULE_FILE}.lua" ]; then
  printf "ERROR: module file does not exist for platform/compiler\n" >&2
  printf "  MODULE_FILE=${MODULE_FILE}\n" >&2
  printf "  PLATFORM=${PLATFORM}\n" >&2
  printf "  COMPILER=${COMPILER}\n\n" >&2
  printf "Please make sure PLATFORM and COMPILER are set correctly\n" >&2
  usage >&2
  exit 64
fi

printf "MODULE_FILE=${MODULE_FILE}\n" >&2

# if build directory already exists then exit
if [ "${REMOVE}" = true ]; then
  printf "Remove build directory\n"
  printf "  BUILD_DIR=${BUILD_DIR}\n\n"
  rm -rf ${BUILD_DIR}
elif [ "${CONTINUE}" = true ]; then
  printf "Continue build in directory\n"
  printf "  BUILD_DIR=${BUILD_DIR}\n\n"
else
  if [ -d "${BUILD_DIR}" ]; then
    while true; do
      if [[ $(ps -o stat= -p ${LCL_PID}) != *"+"* ]] ; then
        printf "ERROR: Build directory already exists\n" >&2
        printf "  BUILD_DIR=${BUILD_DIR}\n\n" >&2
        usage >&2
        exit 64
      fi
      # interactive selection
      printf "Build directory (${BUILD_DIR}) already exists\n"
      printf "Please choose what to do:\n\n"
      printf "[R]emove the existing directory\n"
      printf "[C]ontinue building in the existing directory\n"
      printf "[Q]uit this build script\n"
      read -p "Choose an option (R/C/Q):" choice
      case ${choice} in
        [Rr]* ) rm -rf ${BUILD_DIR}; break ;;
        [Cc]* ) break ;;
        [Qq]* ) exit ;;
        * ) printf "Invalid option selected.\n" ;;
      esac
    done
  fi
fi

# cmake settings
CMAKE_SETTINGS="\
 -DCMAKE_BUILD_TYPE=${BUILD_TYPE}\
 -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}\
 -DCMAKE_INSTALL_BINDIR=${BIN_DIR}\
 -DBUILD_UFS=${BUILD_UFS}\
 -DBUILD_UFS_UTILS=${BUILD_UFS_UTILS}\
 -DBUILD_UPP=${BUILD_UPP}\
 -DBUILD_GSI=${BUILD_GSI}\
 -DBUILD_RRFS_UTILS=${BUILD_RRFS_UTILS}\
 -DBUILD_NEXUS=${BUILD_NEXUS}\
 -DBUILD_AQM_UTILS=${BUILD_AQM_UTILS}"

if [ ! -z "${APPLICATION}" ]; then
  CMAKE_SETTINGS="${CMAKE_SETTINGS} -DAPP=${APPLICATION}"
fi
if [ ! -z "${CCPP_SUITES}" ]; then
  CMAKE_SETTINGS="${CMAKE_SETTINGS} -DCCPP_SUITES=${CCPP_SUITES}"
fi
if [ ! -z "${ENABLE_OPTIONS}" ]; then
  CMAKE_SETTINGS="${CMAKE_SETTINGS} -DENABLE_OPTIONS=${ENABLE_OPTIONS}"
fi
if [ ! -z "${DISABLE_OPTIONS}" ]; then
  CMAKE_SETTINGS="${CMAKE_SETTINGS} -DDISABLE_OPTIONS=${DISABLE_OPTIONS}"
fi
if [ "${APPLICATION}" = "ATMAQ" ]; then
  CMAKE_SETTINGS="${CMAKE_SETTINGS} -DCPL_AQM=ON -DBUILD_POST_STAT=${BUILD_POST_STAT}"
fi

# make settings
MAKE_SETTINGS="-j ${BUILD_JOBS}"
if [ "${VERBOSE}" = true ]; then
  MAKE_SETTINGS="${MAKE_SETTINGS} VERBOSE=1"
fi

# Before we go on load modules, we first need to activate Lmod for some systems
module reset

# source the module file for this platform/compiler combination, then build the code
printf "... Load MODULE_FILE and create BUILD directory ...\n"

if [ $USE_SUB_MODULES = true ]; then
    #helper to try and load module
    function load_module() {

        set +e
        #try most specialized modulefile first
        MODF="$1${PLATFORM}.${COMPILER}"
        if [ $BUILD_TYPE != "Release" ]; then
            MODF="${MODF}.debug"
        else
            MODF="${MODF}.release"
        fi
        module is-avail ${MODF}
        if [ $? -eq 0 ]; then
            module load ${MODF}
            return
        fi
        # without build type
        MODF="$1${PLATFORM}.${COMPILER}"
        module is-avail ${MODF}
        if [ $? -eq 0 ]; then
            module load ${MODF}
            return
        fi
        # without compiler
        MODF="$1${PLATFORM}"
        module is-avail ${MODF}
        if [ $? -eq 0 ]; then
            module load ${MODF}
            return
        fi
        set -e

        # else fallback on app level modulefile
        printf "... Fall back to app level modulefile ...\n"
        module use ${SRW_DIR}/modulefiles
        module load ${MODULE_FILE}
    }
    if [ $BUILD_UFS = "on" ]; then
        printf "... Loading UFS modules ...\n"
        module use ${SRW_DIR}/sorc/ufs-weather-model/modulefiles
        load_module "ufs_"
    fi
    if [ $BUILD_UFS_UTILS = "on" ]; then
        printf "... Loading UFS_UTILS modules ...\n"
        module use ${SRW_DIR}/sorc/UFS_UTILS/modulefiles
        load_module "build."
    fi
    if [ $BUILD_UPP = "on" ]; then
        printf "... Loading UPP modules ...\n"
        module use ${SRW_DIR}/sorc/UPP/modulefiles
        load_module ""
    fi
    if [ $BUILD_GSI = "on" ]; then
        printf "... Loading GSI modules ...\n"
        module use ${SRW_DIR}/sorc/gsi/modulefiles
        load_module "gsi_"
    fi
    if [ $BUILD_RRFS_UTILS = "on" ]; then
        printf "... Loading RRFS_UTILS modules ...\n"
        load_module ""
    fi
    if [ $BUILD_NEXUS = "on" ]; then
        printf "... Loading NEXUS modules ...\n"
        module use ${SRW_DIR}/sorc/arl_nexus/modulefiles
        load_module ""
    fi
    if [ $BUILD_AQM_UTILS = "on" ]; then
        printf "... Loading AQM-utils modules ...\n"
        module use ${SRW_DIR}/sorc/AQM-utils/modulefiles
        load_module ""
    fi
else
    module use ${SRW_DIR}/modulefiles
    module load ${MODULE_FILE}
fi
module list

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

if [ "${CLEAN}" = true ]; then
    if [ -f $PWD/Makefile ]; then
       printf "... Clean executables ...\n"
       make ${MAKE_SETTINGS} clean 2>&1 | tee log.make
    fi
else
    printf "... Generate CMAKE configuration ...\n"
    cmake ${SORC_DIR} ${CMAKE_SETTINGS} 2>&1 | tee log.cmake

    printf "... Compile and install executables in build directory ...\n"
    make ${MAKE_SETTINGS} install 2>&1 | tee log.make

    # move executables to the designated location (HOMEdir/exec) only when 
    # both --build and --move are not set (no additional arguments) or
    # both --build and --move are set in the build command line
    if [[ "${BUILD}" = false && "${MOVE}" = false ]] || 
       [[ "${BUILD}" = true && "${MOVE}" = true ]]; then
      printf "... Moving pre-compiled executables to designated location ...\n"
      mkdir -p ${SRW_DIR}/${BIN_DIR}
      cd "${INSTALL_DIR}/${BIN_DIR}"
      for file in *; do
        [ -x "${file}" ] && mv "${file}" "${SRW_DIR}/${BIN_DIR}"
      done
    fi
fi

exit 0
