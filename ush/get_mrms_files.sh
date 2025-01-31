#!/usr/bin/env bash
#
# -----------------------------------------------------------------------
#
# This function copies MRMS observation files from supported data
# streams on disk to the specified directory. Files will be gathered for
# a given time level, or minutes from a valid time.
#
# It's expected that this function will be called once for each time
# level.
#
# A filelist of copied files will be prepared in the specified
# directory.
#
# Global input variables from job
#    PDY
#    cyc
#
# Global input variables from var_defns
#    RADARREFL_MINS
#    NSSLMOSAIC
#    OBS_SUFFIX
#
# -----------------------------------------------------------------------
#

function get_mrms_files () {

  timelevel=$1
  output_path=$2
  mrms=$3

  YYYY=${PDY:0:4}
  MM=${PDY:4:2}
  DD=${PDY:6:2}

  echo "RADARREFL_MINS = ${RADARREFL_MINS[@]}"
  NSSL=${NSSLMOSAIC}

  # Link to the MRMS operational data
  # This loop finds files closest to the given "timelevel"
  for min in ${RADARREFL_MINS[@]}
  do
    min=$( printf %2.2i $((timelevel+min)) )
    echo "Looking for data valid:${YYYY}-${MM}-${DD} ${cyc}:${min}"
    nsslfiles=${NSSL}/*${mrms}_00.50_${YYYY}${MM}${DD}-${cyc}${min}??.${OBS_SUFFIX}
    for nsslfile in ${nsslfiles} ; do
      if [ -s $nsslfile ]; then
        echo 'Found '${nsslfile}
        file_matches=*${mrms}_*_${YYYY}${MM}${DD}-${cyc}${min}*.${OBS_SUFFIX}
        nsslfile1=${NSSL}/$file_matches
        numgrib2=${#nsslfile1}
        echo 'Number of GRIB-2 files: '${numgrib2}

        # 10 represents a significant number of vertical levels of data
        if [ ${numgrib2} -ge 10 ] && [ ! -e filelist_mrms ]; then
          cp ${nsslfile1} ${output_path}
          ls ${output_path}/${file_matches} > ${output_path}/filelist_mrms
          echo "Copying mrms files for ${YYYY}${MM}${DD}-${cyc}${min}"
        fi
      fi
    done
  done
}


