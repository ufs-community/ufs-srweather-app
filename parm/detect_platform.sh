#!/bin/sh
#
# Detect HPC platforms
#
if [[ -d /scratch1 ]] ; then
  PLATFORM="hera"
elif [[ -d /mnt ]] ; then
  PLATFORM="jet"
elif [[ -d /work ]]; then
  hoststr=$(hostname)
  if [[ "$hoststr" == "hercules"* ]]; then
    PLATFORM="hercules"
  else
    PLATFORM="orion"
  fi
elif [[ -d /ncrc ]]; then
  PLATFORM="gaea"
elif [[ -d /glade ]]; then
  PLATFORM="derecho"
elif [[ -d /lfs/h2 ]] ; then
  PLATFORM="wcoss2"
else
  PLATFORM="unknown"
fi
MACHINE="${PLATFORM}"
