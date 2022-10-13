#!/bin/bash
  
# usage instructions
usage () {
cat << EOF_USAGE
Clean the UFS-SRW Application build
Usage: $0 [OPTIONS] ...

OPTIONS
  -h, --help
      show this help guide
  -a, --all
      removes bin directory, build directory, and all the submodules
  --remove
      removes existing build directories, including those in submodules
  --clean
      removes existing build directories and all other build artifacts
  --build-dir=BUILD_DIR
      main build directory
  --bin-dir=BIN_DIR
      installation binary directory name ("bin" by default; any name is available)
  --sub-modules
      remove sub-component modules
  -v, --verbose
      build with verbose output


default = show all new files

EOF_USAGE
}

# print settings
settings () {
cat << EOF_SETTINGS
Settings:

  BUILD_DIR=${BUILD_DIR}
  BIN_DIR=${BIN_DIR}
  REMOVE=${REMOVE}
  VERBOSE=${VERBOSE}

EOF_SETTINGS
}

# print usage error and exit
usage_error () {
  printf "ERROR: $1\n" >&2
  usage >&2
  exit 1
}

# default settings
set -x
LCL_PID=$$
BUILD_DIR="build"
BIN_DIR="exec"
REMOVE=false
VERBOSE=false

# Make options
CLEAN=false
BUILD=false
CLEAN_SUB_MODULES=false #change default to true later

set +x
# process requires arguments
if [[ ("$1" == "--help") || ("$1" == "-h") ]]; then
  usage
  exit 0
fi
# process optional arguments
while :; do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --all|-a) ALL_CLEAN=true ;;
    --remove) REMOVE=true ;;
    --remove=?*|--remove=) usage_error "$1 argument ignored." ;;
    --clean) CLEAN=true ;;
    --build-dir=?*) BUILD_DIR=${1#*=} ;;
    --build-dir|--build-dir=) usage_error "$1 requires argument." ;;
    --bin-dir=?*) BIN_DIR=${1#*=} ;;
    --bin-dir|--bin-dir=) usage_error "$1 requires argument." ;;
    --sub-modules) CLEAN_SUB_MODULES=true ;;
    --verbose|-v) VERBOSE=true ;;
    --verbose=?*|--verbose=) usage_error "$1 argument ignored." ;;
    # targets
    default) ALL_CLEAN=false ;;
    # unknown
    -?*|?*) usage_error "Unknown option $1" ;;
    *) break
  esac
  shift
done

# choose defaults to clean
if [ "${ALL_CLEAN}" = true ]; then
  CLEAN=true
  CLEAN_SUB_MODULES=true
fi

# print settings
if [ "${VERBOSE}" = true ] ; then
  settings
fi

# clean if build directory already exists then exit
if [ "${REMOVE}" = true ]; then
  printf "Remove build directory: \n"
  printf "  BUILD_DIR=${BUILD_DIR}\n\n"
  [[ -d ${BUILD_DIR} ]] && rm -rf ${BUILD_DIR} && echo "rm -rf ${BUILD_DIR}"
  build_subdirs=$(find . -type d -name build )
  echo "Remove build subdirectories: "
  for build_sub in ${build_subdirs}; do
    rm -rf ${build_sub} && echo "rm -rf ${build_sub}"
  done
elif [ "${CLEAN}" = true ]; then
  printf "Remove build directory, bin directory \n"
  printf "... and other build artifacts\n"
  printf "  BUILD_DIR=${BUILD_DIR}\n\n"
  printf "  BIN_DIR=${BIN_DIR}\n\n"
  rm -rf share
  rm -rf include
  rm -rf lib
  rm -f manage_externals/manic/*.pyc
  subs=$(find . -name .git -type d | sed 's|\.git$||g' | egrep -v '^.$|^./$')
  if [ ${CLEAN_SUB_MODULES} == true ]; then
    printf "remove submodule clones: ${subs}\n"
    for sub in ${subs}; do ( set -x ; rm -rf $sub ); done
  fi
  [[ -n ${BIN_DIR} ]] && rm -rf ${BIN_DIR} && echo "rm -rf ${BIN_DIR}"
  [[ -n ${BUILD_DIR} ]] && rm -rf ${BUILD_DIR} && echo "rm -rf ${BUILD_DIR}"
  echo "Remove build subdirectories: "
  build_subdirs=$(find . -type d -name build )
  for build_sub in ${build_subdirs}; do
    rm -rf ${build_sub} && echo "rm -rf ${build_sub}"
  done
  echo "... cleaned."
else
  [[ -d "${BUILD_DIR}" ]]  && echo "build directory exists: ${BUILD_DIR}"
  build_subdirs=$(find . -type d -name build )
  for build_sub in ${build_subdirs}; do
    echo "build directory exists in sub-modules: ${build_sub} "
  done
  [[ -d "${BIN_DIR}" ]] && echo "bin directory with executables exists: ${BIN_DIR}"
fi

git status

exit 0
