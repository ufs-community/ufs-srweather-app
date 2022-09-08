#!/bin/bash
# Command line arguments
if [ -z "$1" -o -z "$2" ]; then
   echo "Usage: $0 yyyymmdd hh file_fmt nfcst nfcst_int"
   echo "yyymmdd and hh are required and other variables are optional"
   exit
fi
## date (year month day) and time (hour)
yyyymmdd=$1 #i.e. "20191224"
hh=$2 #i.e. "12"
##
## file format (grib2 or nemsio), the default format is grib2
if [ "$#" -ge 3 ]; then
   file_fmt=$3
else 
   file_fmt="grib2"
fi
## forecast length, the default value are 6 hours
if [ "$#" -ge 4 ]; then
   nfcst=$4
else 
   nfcst=6
fi
## forecast interval, the default interval are 3 hours
if [ "$#" -ge 5 ]; then
   nfcst_int=$5
else 
   nfcst_int=3
fi

# Get the data (do not need to edit anything after this point!)
yyyymm=$((yyyymmdd/100))
#din_loc_ic=`./xmlquery DIN_LOC_IC --value`
mkdir -p gfs.$yyyymmdd/$hh
echo "Download files to $din_loc_ic/$yyyymm/$yyyymmdd ..."
cd gfs.$yyyymmdd/$hh

#getting online analysis data
if [ $file_fmt == "grib2" ] || [ $file_fmt == "GRIB2" ]; then
   wget --tries=2 -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.pgrb2.0p25.f000
else
   wget --tries=2 -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.atmanl.nemsio
   wget --tries=2 -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.sfcanl.nemsio
fi

#getting online forecast data
ifcst=$nfcst_int
while [ $ifcst -le $nfcst ] 
do
echo $ifcst
  if [ $ifcst -le 99 ]; then 
     if [ $ifcst -le 9 ]; then
        ifcst_str="00"$ifcst
     else
        ifcst_str="0"$ifcst
     fi
  else
        ifcst_str="$ifcst"
 fi
 echo $ifcst_str
#
if [ $file_fmt == "grib2" ] || [ $file_fmt == "GRIB2" ]; then
  wget --tries=2 -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.pgrb2.0p25.f${ifcst_str}
else
  wget --tries=2 -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.atmf${ifcst_str}.nemsio
  wget --tries=2 -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.sfcf${ifcst_str}.nemsio
fi
#
ifcst=$[$ifcst+$nfcst_int]
done
