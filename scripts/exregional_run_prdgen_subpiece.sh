#!/bin/bash
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:         rrfs_prdgen_namerica.sh
# Script description:  Run RRFS product generation job for NA grid
#
# Author:        Ben Blake       Org: NOAA/EMC         Date: 2022-11-29
#
# Abstract: This script runs the RRFS PRDGEN jobs
#
# Script history log:
# 2022-11-29  Ben Blake
#

set -x

fhr=$1
cyc=$2
subpiece=$3
domain=$4
DATA=$5
comout=$6
export compress_type=c3

cd $DATA/prdgen_${domain}_${subpiece}

if [ $domain == "namerica" ]; then
  # 3-km NPS North American domain
  gridspecs="nps:245:60 206.5:5200:3170 -4.0:3268:3170"
  parmfile=${DATA}/${domain}_${subpiece}.txt
elif [ $domain == "conus" ]; then
  # 3-km Lambert Conformal CONUS domain
  gridspecs="lambert:262.5:38.5:38.5 237.280472:1799:3000 21.138123:1059:3000"
  parmfile=${DATA}/conus_ak_${subpiece}.txt 
elif [ $domain == "ak" ]; then
  # 3-km NPS Alaska domain
  gridspecs="nps:210.0:60.0 181.429:1649:2976.0 40.530:1105:2976.0"
  parmfile=${DATA}/conus_ak_${subpiece}.txt
elif [ $domain == "hi" ]; then
  # 2.5 km Mercator Hawaii domain
  gridspecs="mercator:20.00 198.474999:321:2500.0:206.13099 18.072699:225:2500.0:23.087799"
  parmfile=${DATA}/hi_pr_${subpiece}.txt
elif [ $domain == "pr" ]; then
  # 2.5 km Mercator Puerto Rico domain
  gridspecs="mercator:20 284.5:544:2500:297.491 15.0:310:2500:22.005"
  parmfile=${DATA}/hi_pr_${subpiece}.txt
fi

# Use different parm file for each subpiece
wgrib2 $comout/rrfs.t${cyc}z.prslev.f${fhr}.grib2 | grep -F -f ${parmfile} | wgrib2 -i -grib inputs.grib${domain} $comout/rrfs.t${cyc}z.prslev.f${fhr}.grib2
wgrib2 inputs.grib${domain} -new_grid_vectors "UGRD:VGRD:USTM:VSTM" -submsg_uv inputs.grib${domain}.uv
wgrib2 inputs.grib${domain}.uv -set_bitmap 1 -set_grib_type ${compress_type} \
  -new_grid_winds grid -new_grid_vectors "UGRD:VGRD:USTM:VSTM" \
  -new_grid_interpolation neighbor \
  -if ":(WEASD|APCP|NCPCP|ACPCP|SNOD):" -new_grid_interpolation budget -fi \
  -new_grid ${gridspecs} ${domain}_${subpiece}.grib2

#export err=$?; err_chk

# Send data to COMOUT in the ex-script after the grid is re-assembled

exit
