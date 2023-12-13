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
      removes "bin", "build" directories, and other build artifacts
  --remove
      removes the "build" directory, keeps the "bin", "lib" and other build artifacts intact
  --clean
      removes "bin", "build" directories, and other build artifacts (same as "-a", "--all")
  --conda
      removes "conda" directory and conda_loc file in SRW
  --install-dir=INSTALL_DIR
      installation  directory name (\${SRW_DIR} by default)
  --build-dir=BUILD_DIR
      main build directory, absolute path (\${SRW_DIR}/build/ by default)
  --bin-dir=BIN_DIR
      binary directory name ("exec" by default); full path is \${INSTALL_DIR}/\${BIN_DIR})
  --conda-dir=CONDA_DIR
      directory where conda is installed. caution: if outside the SRW clone, it may have broader use
  --sub-modules
      remove sub-module directories. They will need to be checked out again by sourcing "\${SRW_DIR}/manage_externals/checkout_externals" before attempting subsequent builds
  -v, --verbose
      provide more verbose output

EOF_USAGE
}

# print settings
settings () {
cat << EOF_SETTINGS
Settings:

  INSTALL_DIR=${INSTALL_DIR}
  BUILD_DIR=${BUILD_DIR}
  BIN_DIR=${BIN_DIR}
  CONDA_DIR=${CONDA_DIR}
  REMOVE=${REMOVE}
  VERBOSE=${VERBOSE}

Default cleaning options: (if no arguments provided, then nothing is cleaned)
 REMOVE=${REMOVE}
 CLEAN=${CLEAN}
 INCLUDE_SUB_MODULES=${INCLUDE_SUB_MODULES}

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
INSTALL_DIR=${INSTALL_DIR:-${SRW_DIR}}
BUILD_DIR=${BUILD_DIR:-"${SRW_DIR}/build"}
BIN_DIR="exec"
CONDA_DIR=${CONDA_DIR:-"${SRW_DIR}/conda"}
REMOVE=false
VERBOSE=false

# default clean options
REMOVE=false
CLEAN=false
INCLUDE_SUB_MODULES=false #changes to true if '--sub-modules' option is provided

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
    --conda) REMOVE_CONDA=true ;;
    --install-dir=?*) INSTALL_DIR=${1#*=} ;;
    --install-dir|--install-dir=) usage_error "$1 requires argument." ;;
    --build-dir=?*) BUILD_DIR=${1#*=} ;;
    --build-dir|--build-dir=) usage_error "$1 requires argument." ;;
    --bin-dir=?*) BIN_DIR=${1#*=} ;;
    --bin-dir|--bin-dir=) usage_error "$1 requires argument." ;;
    --conda-dir=?*) CONDA_DIR=${1#*=} ;;
    --conda-dir|--conda-dir=) usage_error "$1 requires argument." ;;
    --sub-modules) INCLUDE_SUB_MODULES=true ;;
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
  printf '%s\n' "Remove build directory, bin directory, and other build artifacts "
  printf '%s\n' " from the installation directory = ${INSTALL_DIR} "

  directories=( \
    "${BUILD_DIR}" \
    "${INSTALL_DIR}/${BIN_DIR}" \
    "${INSTALL_DIR}/share" \
    "${INSTALL_DIR}/include" \
    "${INSTALL_DIR}/lib" \
    "${INSTALL_DIR}/lib64" \
    "${SRW_DIR}/manage_externals/manic" \
  )
  for directory in $directories; do
    [[ -d $directory ]] && rm -rfv $directory
  done
  echo " "
fi
# Clean all the submodules if requested. Note: Need to check out them again before attempting subsequent builds, by sourcing ${SRW_DIR}/manage_externals/checkout_externals
if [ ${INCLUDE_SUB_MODULES} == true ]; then
  printf '%s\n' "Removing submodules ..."
  declare -a submodules='()'
  submodules=(${SRW_DIR}/sorc/*) 
# echo " submodules are: ${submodules[@]} (total of ${#submodules[@]}) "
  if [ ${#submodules[@]} -ge 1 ]; then
    for sub in ${submodules[@]}; do [[ -d "${sub}" ]] && ( rm -rf ${sub} && printf '%s\n' "rm -rf ${sub}" ); done
  fi
  printf '%s\n' "Note: Need to check out submodules again for any subsequent builds, " \
    " by sourcing ${SRW_DIR}/manage_externals/checkout_externals "
fi
#

# Clean conda if requested
if [ "${REMOVE_CONDA}" = true ] ; then
  printf '%s\n' "Removing conda location file"
  rm -rf ${SRW_DIR}/conda_loc
  printf '%s\n' "Removing conda installation"
  rm -rf ${CONDA_DIR}
fi



echo " "
echo "All the requested cleaning tasks have been completed"
echo " "

exit 0

