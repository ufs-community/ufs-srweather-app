#
#-----------------------------------------------------------------------
#
# This script defines MacOS-specific UNIX command-line utilities that 
# mimic the functionality of the GNU equivalents.
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
# Check if we are on a Darwin machine; if so we need to use the gnu-like
# equivalent of readlink and sed.
#
#-----------------------------------------------------------------------
#
darwinerror () {

  utility=$1
  echo >&2 "
For Darwin-based operating systems (MacOS), the '${utility}' utility is required to run the UFS SRW Application.
Reference the User's Guide for more information about platform requirements.
Aborting.
"
  exit 1
}

  if [[ $(uname -s) == Darwin ]]; then
    export READLINK=greadlink
    command -v $READLINK >/dev/null 2>&1 || darwinerror $READLINK
    export SED=gsed
    command -v $SED >/dev/null 2>&1 || darwinerror $SED
    export DATE_UTIL=gdate
    command -v $DATE_UTIL >/dev/null 2>&1 || darwinerror $DATE_UTIL
    export LN_UTIL=gln
    command -v $LN_UTIL >/dev/null 2>&1 || darwinerror $LN_UTIL
  else
    export READLINK=readlink
    export SED=sed
    export DATE_UTIL=date
    export LN_UTIL=ln
  fi

