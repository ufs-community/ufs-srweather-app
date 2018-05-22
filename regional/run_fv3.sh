#!/bin/bash
rootdir="/scratch/ywang/external/regionalFV3"
WORKDIRDF="/scratch/ywang/test_runs/FV3_regional"
eventdateDF=$(date +%Y%m%d)
#export eventdate="20180214"

function usage {
  echo " "
  echo "$0 [YYYYMMDD] [WORKDIR]"
  echo " "
  exit 0
}

export WORKDIR="$WORKDIRDF"
export eventdate="$eventdateDF"
if [[ $# > 1 ]]; then
  export WORKDIR="$2"
  export eventdate="$1"
elif [[ $# > 0 ]]; then
  export eventdate="$1"
fi

export FV3DIR="$rootdir/fv3gfs"
export FIXDIR="/scratch/ywang/external/fix_am"

export CASE="C768"               # resolution of tile: 48, 96, 192, 384, 768, 1152, 3072
export ENDHOUR=24                # integration end hours
export INTHOUR=3                 # Interval hour of external dataset

EXEPRO="$FV3DIR/NEMSfv3gfs/tests/fv3_32bit.exe"
FV3TEM="$FV3DIR/regional/templates"
gfs_dir="$WORKDIR/gfs/${eventdate}"

echo "---- Jobs started at $(date +%m-%d_%H:%M:%S) for Event: $eventdate; Using ----"
echo "  FV3DIR  = ${FV3DIR}    # fv3gfs workflow"
echo "  EXEPRO  = $EXEPRO      # executable of fv3"
echo "  FV3TEM  = $FV3TEM      # run-time template files"
echo "  WORKDIR = $WORKDIR     # Working dir"
echo "  gfs_dir = $gfs_dir     # GFS data directory"
echo "  FIXDIR  = $FIXDIR      # FV3 static data directory"
echo " "
echo "  CASE     = $CASE "
echo "  ENDHOUR  = $ENDHOUR "
echo " "

totalhour=$(( ENDHOUR/INTHOUR + 1 ))

#-----------------------------------------------------------------------
#
# 0. get GFS datasets
#
#-----------------------------------------------------------------------
echo "-- 0: download GFS data file at $(date +%m-%d_%H:%M:%S) ----"

if [[ ! -r ${gfs_dir} ]]; then
  mkdir -p ${gfs_dir}
fi

cd ${gfs_dir}

atmfile="${gfs_dir}/gfs.t00z.atmanl.nemsio"
sfcfile="${gfs_dir}/gfs.t00z.sfcanl.nemsio"

ncepurl="http://ftpprd.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.${eventdate}00"

while true; do
  if [ ! -f $atmfile ]; then
    wget ${ncepurl}/gfs.t00z.atmanl.nemsio > /dev/null 2>&1
  fi

  if [ ! -f $sfcfile ]; then
    wget ${ncepurl}/gfs.t00z.sfcanl.nemsio > /dev/null 2>&1
  fi

  for hour in $(seq ${INTHOUR} ${INTHOUR} ${ENDHOUR}); do
    bchour=$(printf %03d $hour)
    gfsfile=gfs.t00z.atmf${bchour}.nemsio
    if [ ! -f "${gfs_dir}/$gfsfile" ]; then
      wget ${ncepurl}/${gfsfile} > /dev/null 2>&1
    fi
  done

  if [ -f $atmfile -a -f $sfcfile ]; then
    ls -l ${gfs_dir}/
    break
  else
    #echo "No GFS file found."
    #exit 1
    sleep 10
    #echo "Waiting for GFS datasets ..."
  fi
done

echo " "
#-----------------------------------------------------------------------
#
# 1. run chgres
#
#-----------------------------------------------------------------------

echo "-- 1: run chgres at $(date +%m-%d_%H:%M:%S) ----"

chgresfile="$WORKDIR/chgres_${CASE}_${eventdate}/done.chgres"
if [ ! -f $chgresfile ]; then

  $FV3DIR/regional/run_chgres.sh ${eventdate}

  echo "Waiting for ${chgresfile} ..."
  while [[ ! -f ${chgresfile} ]]; do
    sleep 10
    #echo "Waiting for ${chgresfile} ..."
    count=0
    for hour in $(seq 0 ${INTHOUR} ${ENDHOUR}); do
      bchour=$(printf %03d $hour)
      donefile="done.chgres_${bchour}"
      if [ -f "$WORKDIR/chgres_${CASE}_${eventdate}/$donefile" ]; then
        echo "Found $donefile"
        count=$((count+1))
      fi
    done
    if [[ $count -ge $totalhour ]]; then
      touch $chgresfile
    fi
  done
  ls -l ${chgresfile}
fi

echo " "

#-----------------------------------------------------------------------
#
# 2. run fv3 model
#
#-----------------------------------------------------------------------

echo "-- 2: run fv3 model at $(date +%m-%d_%H:%M:%S) ----"

donefv3="$WORKDIR/fv3_${CASE}_${eventdate}00/done.fv3"

if [ ! -f $donefv3 ]; then

  cd $WORKDIR

  jobscript="tmp/fv3_${CASE}_$eventdate.job"
  cp $FV3TEM/run_on_odin_${CASE}.job $jobscript

  sed -i -e "/WWWDDD/s#WWWDDD#$WORKDIR#;s#EEEDDD#$eventdate#;s#FV3TTT#$FV3TEM#;s#EXEPPP#$EXEPRO#;s#CCCCCC#$CASE#;s#HHHHHH#$ENDHOUR#" ${jobscript}

  echo "sbatch $jobscript"
  sbatch $jobscript

  echo "Waiting for ${donefv3} ..."
  while [[ ! -f ${donefv3} ]]; do
    sleep 10
    #echo "Waiting for ${donefv3} ..."
  done
  ls -l ${donefv3}
fi

echo " "

#% #-----------------------------------------------------------------------
#% #
#% # 3. post-processing
#% #
#% #-----------------------------------------------------------------------
#%
#% echo "-- 3: run post-processing at $(date +%m-%d_%H:%M:%S) ----"
#%
#% donepost="$WORKDIR/C384_${eventdate}00_VLab/done.post"
#% # to be run on wof-post2
#% #
#% if [ ! -f $donepost ]; then
#%   #echo "Waiting for ${donefv3} ..."
#%   #while [[ ! -f ${donefv3} ]]; do
#%   #  sleep 10
#%   #  #echo "Waiting for ${donefv3} ..."
#%   #done
#%   #ls -l ${donefv3}
#%
#%   echo "ssh wof-post2 /scratch/ywang/external/fv3gfs.mine/CAPS_post_C384/postprocess.csh"
#%   ssh wof-post2 "/scratch/ywang/external/fv3gfs.mine/CAPS_post_C384/postprocess.csh $eventdate"
#%
#%   #echo "Waiting for ${donepost} ..."
#%   #while [[ ! -f ${donepost} ]]; do
#%   #  sleep 10
#%   #  #echo "Waiting for ${donepost} ..."
#%   #done
#%   #ls -l ${donepost}
#%
#% fi
#%
#% echo " "
#%
#% #
#% # 4. Transfer grib files
#% #
#%
#% echo "-- 4: Transfer grib2 file to bigbang at $(date +%m-%d_%H:%M:%S) ----"
#%
#% donetransfer="$WORKDIR/C384_${eventdate}00_VLab/done.transfer"
#%
#% if [ ! -f $donetransfer ]; then
#%
#%   echo "Waiting for ${donepost} ..."
#%   while [[ ! -f ${donepost} ]]; do
#%     sleep 10
#%     #echo "Waiting for ${donepost} ..."
#%   done
#%   ls -l ${donepost}
#%
#%   cd $WORKDIR/C384_${eventdate}00_VLab
#%   echo "scp *.grb2 bigbang:/raid/efp/se2018/ftp/nssl/fv3_test"
#%   scp *.grb2 bigbang:/raid/efp/se2018/ftp/nssl/fv3_test
#%
#%   touch $donetransfer
#% fi

echo " "

echo "==== Jobs done at $(date +%m-%d_%H:%M:%S) ===="
echo " "
exit 0
