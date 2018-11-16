#!/bin/ksh --login

set -ux

module purge
module load intel mvapich2 netcdf
#module load intel impi netcdf

WGRIB2=wgrib2

#Source variables from user-defined file
. ${TMPDIR}/../fv3gfs/ush/setup_grid_orog_ICs_BCs.sh

if [ "$machine" = "Odin" ]; then
  export APRUN="srun -n 1"
elif [ "$machine" = "Jet" ]; then
  . /apps/lmod/lmod/init/sh 
  module load newdefaults
  module load intel/15.0.3.187
  module load impi/5.1.1.109
  module load szip
  module load hdf5
  module load netcdf4/4.2.1.1
  
  set libdir /mnt/lfs3/projects/hfv3gfs/gwv/ljtjet/lib
  
  export NCEPLIBS=/mnt/lfs3/projects/hfv3gfs/gwv/ljtjet/lib
  module use /mnt/lfs3/projects/hfv3gfs/gwv/ljtjet/lib/modulefiles
  
  module load bacio-intel-sandybridge
  module load sp-intel-sandybridge
  module load ip-intel-sandybridge
  module load w3nco-intel-sandybridge
  module load w3emc-intel-sandybridge
  module load nemsio-intel-sandybridge
  module load sfcio-intel-sandybridge
  module load sigio-intel-sandybridge
  module load g2-intel-sandybridge
  module load g2tmpl-intel-sandybridge
  module load gfsio-intel-sandybridge
  module load crtm-intel-sandybridge
  
  module use /lfs3/projects/hfv3gfs/emc.nemspara/soft/modulefiles
  module load esmf/7.1.0r_impi_optim

  export APRUN="mpirun -np 1"
else
  export APRUN="mpiexec -l -np 1"
fi

RUNDIR="${BASEDIR}/run_dirs/${subdir_name}"

cd ${RUNDIR}
mkdir -p postprd
cd postprd

mkdir -p ${fhr}
cd ${fhr}

echo "starting time"
date

export tmmark=tm00

# forecast hour is input from Rocoto
export fhr=${fhr}

echo "${fhr} is fhr."

dyn=${RUNDIR}/dynf0${fhr}.nc
phy=${RUNDIR}/phyf0${fhr}.nc

# CONUS domain
#gridspecs="lambert:262.5:38.5:38.5 237.280:1799:3000 21.138:1059:3000"
# Grid for nested model output
#gridspecs="lambert:262.5:34.0:34.0 240.16287231:1728:2888.8889 13.73298645:1440:2888.8889"

export POST_TIME=`${BASEDIR}/UPP/comupp/src/ndate/ndate.exe +${fhr} ${CDATE}`
export YYYY=`echo $POST_TIME | cut -c1-4`
export MM=`echo $POST_TIME | cut -c5-6`
export DD=`echo $POST_TIME | cut -c7-8`
export HH=`echo $POST_TIME | cut -c9-10`

cat > itag <<EOF
${dyn}
netcdf
grib2
${YYYY}-${MM}-${DD}_${HH}:00:00
GFS
${phy}

 &NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,
 /
EOF

rm -f fort.*

cp ${FIX}/nam_micro_lookup.dat ./eta_micro_lookup.dat

# copy flat files
cp ${FIX}/postxconfig-NT-NMM_new.txt ./postxconfig-NT.txt
cp ${FIX}/params_grib2_tbl_new ./params_grib2_tbl_new

# Run the post processor
cp ${UPPDIR}/ncep_post .
${APRUN} ./ncep_post < itag

# Rename output
mv BGDAWP.GrbF${fhr} ../${TITLE}.t${cyc}z.bgdawp${fhr}.${tmmark}
mv BGRD3D.GrbF${fhr} ../${TITLE}.t${cyc}z.bgrd3d${fhr}.${tmmark}
#mv BGRDSF.GrbF${fhr} ${TITLE}.t${cyc}z.bgrdsf${fhr}.${tmmark}

# Convert native grid files to grid ??? using wgrib2
#${WGRIB2} ${RUN}.t${cyc}z.bgdawp${fhr}.${tmmark} | grep -F -f ${FIX}/wgrib2.txtlists/nam_nests.hiresf_nn.txt | ${WGRIB2} -i -grib inputs.grib ${RUN}.t${cyc}z.bgdawp${fhr}.${tmmark}
#${WGRIB2} inputs.grib -new_grid_vectors "UGRD:VGRD:USTM:VSTM" -submsg_uv inputs.grib.uv
#${WGRIB2} ${RUN}.t${cyc}z.bgdawp${fhr}.${tmmark} -match ":(APCP|WEASD|SNOD):" -grib inputs.grib.uv_budget

#${WGRIB2} inputs.grib.uv -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid -new_grid_interpolation neighbor -new_grid_vectors "UGRD:VGRD:USTM:VSTM" -new_grid ${gridspecs} conusf${fhr}.${tmmark}.uv
#${WGRIB2} conusf${fhr}.${tmmark}.uv -new_grid_vectors "UGRD:VGRD:USTM:VSTM" -submsg_uv conusf${fhr}.${tmmark}.nn

#${WGRIB2} inputs.grib.uv_budget -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid -new_grid_interpolation budget -new_grid ${gridspecs} conusf${fhr}.${tmmark}.budget
#cat conusf${fhr}.${tmmark}.nn conusf${fhr}.${tmmark}.budget > conusf${fhr}.${tmmark}

#${WGRIB2} conusf${fhr}.${tmmark} -s > conusf${fhr}.${tmmark}.idx

cd ..

#rm -rf ${fhr}

echo "PROGRAM IS COMPLETE!!!!!"

exit
