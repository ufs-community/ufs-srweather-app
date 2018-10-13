#!/bin/ksh --login

set -x

module purge
module load intel mvapich2 netcdf
#module load intel impi netcdf

WGRIB2=wgrib2

#Source variables from user-defined file
. ${TMPDIR}/../fv3gfs/ush/setup_grid_orog_ICs_BCs.sh

cd /scratch3/BMC/det/beck/FV3-CAM/run_dirs/rgnl_C384_strch_1p65_rfn_5_HRRR
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

dyn=/scratch3/BMC/det/beck/FV3-CAM/run_dirs/rgnl_C384_strch_1p65_rfn_5_HRRR/dynf0${fhr}.nc
phy=/scratch3/BMC/det/beck/FV3-CAM/run_dirs/rgnl_C384_strch_1p65_rfn_5_HRRR/phyf0${fhr}.nc

# CONUS domain
#gridspecs="lambert:262.5:38.5:38.5 237.280:1799:3000 21.138:1059:3000"
# Grid for nested model output
#gridspecs="lambert:262.5:34.0:34.0 240.16287231:1728:2888.8889 13.73298645:1440:2888.8889"

export POST_TIME=`/scratch4/BMC/hmtb/beck/rapid-refresh/UPP/comupp/src/ndate/ndate.exe +${fhr} ${CDATE}`
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
mpirun -l -np $PBS_NP ./ncep_post < itag

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

rm -rf ${fhr}

echo "PROGRAM IS COMPLETE!!!!!"

exit
