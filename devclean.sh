#!/bin/bash
  
# usage instructions
usage () {
cat << EOF_USAGE

Clean the UFS-SRW Application build, when located under the main SRW tree
Usage: $0 [OPTIONS] ...

OPTIONS
  -h, --help
      show this help guide
  -a, --all
      removes "bin", "build" directories, and other build artifacts
  --bin-dir=BIN_DIR
      binaries directory name under the SRW tree ("exec" default)
  --build-dir=BUILD_DIR
      build directory name under the SRW tree ("build" default)
  --clean
      removes "bin", "build" directories, and other build artifacts (same as "-a", "--all")
  --conda-dir=CONDA_DIR
      directory name under the SRW tree where conda is installed ("conda" default)
  --remove
      remove the BUILD_DIR only ("build" default), keep the BIN_DIR ("exec" default), "lib" and other build artifacts intact
  --remove-conda
      removes CONDA_DIR ("conda" default) directory and conda_loc file from the SRW tree
  --sub-modules
      remove sub-module directories. They need to be checked out again by sourcing "\${SRW_DIR}/manage_externals/checkout_externals" before attempting subsequent builds
  -v, --verbose
      provide more verbose output

EOF_USAGE
}

# print settings
settings () {
cat << EOF_SETTINGS
Settings:

  SRW_DIR=${SRW_DIR}
  BUILD_DIR=${BUILD_DIR}
  BIN_DIR=${BIN_DIR}
  CONDA_DIR=${CONDA_DIR}
  REMOVE=${REMOVE}
  REMOVE_CONDA=${REMOVE_CONDA}
  VERBOSE=${VERBOSE}

Default cleaning options: (if no arguments provided, then nothing is cleaned)
 REMOVE=${REMOVE}
 CLEAN=${CLEAN}
 REMOVE_CONDA=${REMOVE_CONDA}
 REMOVE_SUB_MODULES=${REMOVE_SUB_MODULES}

EOF_SETTINGS
}

# print usage error and exit
usage_error () {
  printf "ERROR: $1\n" >&2
  usage >&2
  exit 1
}

# default settings
SRW_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
BUILD_DIR=${BUILD_DIR:-"build"}
BIN_DIR=${BIN_DIR:-"exec"}
CONDA_DIR=${CONDA_DIR:-"conda"}
REMOVE=false
REMOVE_CONDA=false
VERBOSE=false

# default clean options
REMOVE=false
CLEAN=false
REMOVE_SUB_MODULES=false #changes to true if '--sub-modules' option is provided

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
    --build-dir=?*) BUILD_DIR=${1#*=} ;;
    --build-dir|--build-dir=) usage_error "$1 requires argument." ;;
    --bin-dir=?*) BIN_DIR=${1#*=} ;;
    --bin-dir|--bin-dir=) usage_error "$1 requires argument." ;;
    --clean) CLEAN=true ;;
    --conda-dir=?*) CONDA_DIR=${1#*=} ;;
    --conda-dir|--conda-dir=) usage_error "$1 requires argument." ;;
    --remove) REMOVE=true ;;
    --remove=?*|--remove=) usage_error "$1 argument ignored." ;;
    --remove-conda) REMOVE_CONDA=true ;;
    --sub-modules) REMOVE_SUB_MODULES=true ;;
    --verbose|-v) VERBOSE=true ;;
    --verbose=?*|--verbose=) usage_error "$1 argument ignored." ;;
    # targets
    default) ALL_CLEAN=false ;;
    # unknown
    -?*|?*) usage_error "Unknown option $1" ;;
    *) break ;;
  esac
  shift
done

# Make sure to be in the SRW main directory before any removing or cleaning
cd ${SRW_DIR}

# choose defaults to clean
if [ "${ALL_CLEAN}" = true ]; then
  CLEAN=true
fi

# print settings
if [ "${VERBOSE}" = true ] ; then
  settings
fi

# clean if build directory already exists 
if [ "${REMOVE}" = true ] && [ "${CLEAN}" = false ] ; then
  printf '%s\n' "Remove the \"build\" directory only, BUILD_DIR = $BUILD_DIR "
  [[ -d ${BUILD_DIR} ]] && rm -rf ${BUILD_DIR} && printf '%s\n' "rm -rf ${BUILD_DIR}"
elif [ "${CLEAN}" = true ]; then
  printf '%s\n' "Remove build directory, binaries directory, and other build artifacts "
  printf '%s\n' " from the ${SRW_DIR} "

  directories=( \
    "${BUILD_DIR}" \
    "${BIN_DIR}" \
    "$share" \
    "$include" \
    "$lib" \
    "$lib64" \
  )
  if [ ${#directories[@]} -ge 1 ]; then
    for dir in ${directories[@]}; do 
     [[ -d "${dir}" ]] && ( rm -rf ${dir} &&  printf '%s\n' "Removing ${dir} directory") 
    done
  echo " "
  fi
fi
# Clean all the submodules if requested. Note: Need to check out them again before attempting subsequent builds, by sourcing ${SRW_DIR}/manage_externals/checkout_externals
if [ ${REMOVE_SUB_MODULES} == true ]; then
  printf '%s\n' "Removing submodules ..."
  declare -a submodules='()'
  submodules=(./sorc/*) 
# echo " submodules are: ${submodules[@]} (total of ${#submodules[@]}) "
  if [ ${#submodules[@]} -ge 1 ]; then
    for sub in ${submodules[@]}; do [[ -d "${sub}" ]] && ( rm -rf ${sub} && printf '%s\n' "Removing ${sub} directory" ); done
  fi
  printf '%s\n' "Note: Need to check out submodules again for any subsequent builds, " \
    " by sourcing ${SRW_DIR}/manage_externals/checkout_externals "
fi
#

# Clean conda if requested
if [ "${REMOVE_CONDA}" = true ] ; then
  [[ -d "${CONDA_DIR}" ]] &&  rm -rf ${CONDA_DIR} && printf '%s\n' "Removing conda installation directory, ${CONDA_DIR}, from the SRW directory tree"
  [[ -f "conda_loc" ]] &&  rm -f "conda_loc" && printf '%s\n' "Removing conda_loc file"
fi

echo " "
echo "All the requested cleaning tasks have been completed"
echo " "

