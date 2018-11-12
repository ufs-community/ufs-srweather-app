#!/bin/ksh
set -aux

nargv=$#

export inorogexist=0

if [ $nargv -eq 6 ];  then  # lat-lon grid
  export lonb=$1
  export latb=$2
  export outdir=$3
  export script_dir=$4
  export is_latlon=1
  export ntiles=1
  export orogfile="none"
  export hist_dir=$5
  export TMPDIR=$6
  export workdir=$TMPDIR/latlon/orog/latlon_${lonb}x${latb}
elif [ $nargv -eq 7 ]; then  # cubed-sphere grid
  export res=$1 
  export lonb=$1
  export latb=$1
  export tile=$2
  export griddir=$3
  export outdir=$4
  export script_dir=$5
  export ntiles=6
  export is_latlon=0
  export orogfile="none"
  export hist_dir=$6
  export TMPDIR=$7
  export workdir=$TMPDIR/C${res}/orog/tile$tile
# Set workdir_rgnl, which is the work directory for the FV3SAR (i.e. the
# regional FV3).  workdir_rgnl will be set to an empty string if WORK-
# DIR_OROG is unset or empty.
  workdir_rgnl=${WORKDIR_OROG:+$WORKDIR_OROG/tile$tile}
# If workdir_rgnl is set to a non-empty string, set workdir to it.
  export workdir=${workdir_rgnl:-$workdir}
elif [ $nargv -eq 8 ]; then  # input your own orography files
  export res=$1 
  export lonb=$1
  export latb=$1
  export tile=$2
  export griddir=$3
  export outdir=$4
  export ntiles=6
  export is_latlon=0
  export inputorog=$5
  export script_dir=$6
  export orogfile=$inputorog:t
  export inorogexist=1
  export hist_dir=$7
  export TMPDIR=$8
  export workdir=$TMPDIR/C${res}/orog/tile$tile
else
  echo "number of arguments must be 5 or 6 for cubic sphere grid and 4 for lat-lon grid"
  echo "Usage for cubic sphere grid: $0 resolution tile grid_dir out_dir script_dir hist_dir TMPDIR"
  exit 1
fi

export indir=$hist_dir
export executable=$exec_dir/ml01rg2.x
if [ ! -s $executable ]; then
  echo "executable does not exist"
  exit 1 
fi

#
# Changed this so that workdir is first removed if it already exists
# and then recreated.  This is needed because the file gmted2010.30sec.int 
# that is copied into workdir as fort.235 is write-protected (i.e. even
# the owner doesn't have write permission), so if workdir already exists
# (from a previous call to this script) and thus fort.235 already ex-
# ists, it can't get overwritten by the new version of gmted2010.30sec.int 
# file, resulting in possibly incorrect old files being used (bad!).
#
if [ -e $workdir ]; then rm -rf $workdir; fi
mkdir -p $workdir;
if [ ! -s $outdir ]; then mkdir -p $outdir ;fi

#jcap is for Gaussian grid
#jcap=`expr $latb - 2 `
export jcap=0
export NF1=0
export NF2=0
export mtnres=1
export efac=0
export blat=0
export NR=0

if [ $is_latlon -eq 1 ]; then
  export OUTGRID="none"
else
  export OUTGRID="C${res}_grid.tile${tile}.nc"
fi

# Make Orograraphy
echo "OUTGRID = $OUTGRID"
echo "workdir = $workdir"
echo "outdir = $outdir"
echo "indir = $indir"

cd $workdir
#  export MTN_SLM=${indir}/TOP8M_slm.80I1.asc
#  cp ${indir}/a_ocean_mask${lonb}x${latb}.txt  fort.25
#  cp /home/z1l/GFS_tools/orog/a_ocean_mask${lonb}x${latb}.txt  fort.25
#  cp $MTN_SLM fort.14

  cp ${indir}/thirty.second.antarctic.new.bin fort.15
  cp ${indir}/landcover30.fixed .
#  uncomment next line to use the old gtopo30 data.
#   cp ${indir}/gtopo30_gg.fine.nh  fort.235
#  use gmted2020 data.
  cp ${indir}/gmted2010.30sec.int  fort.235
  if [ $inorogexist -eq 1 ]; then
     cp $inputorog .
  fi   
     
  if [ $is_latlon -eq 0 ]; then
     cp ${griddir}/$OUTGRID .
  fi
  cp $executable .

  echo  $mtnres $lonb $latb $jcap $NR $NF1 $NF2 $efac $blat > INPS
  echo $OUTGRID >> INPS
  echo $orogfile >> INPS
  cat INPS
  time $executable < INPS

  if [ $? -ne 0 ]; then
    echo "ERROR in running $executable "
    exit 1
  else
    if [ $is_latlon -eq 1 ]; then
       export outfile=oro.${lonb}x${latb}.nc
    else
       export outfile=oro.C${res}.tile${tile}.nc
    fi

    mv ./out.oro.nc $outdir/$outfile
    echo "file $outdir/$outfile is created"
    echo "Successfully running $executable "
    exit 0
  fi


exit
