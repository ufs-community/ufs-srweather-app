#!/bin/sh -l
#
#-----------------------------------------------------------------------
#
# This script runs the post-processor (UPP) on the NetCDF output files
# of the write component of the FV3SAR model.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source utility functions.
#
#-----------------------------------------------------------------------
#
. $USHDIR/utility_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#

#module load intel impi netcdf

case $MACHINE in
#
"WCOSS_C" | "WCOSS" )
#
  . $MODULESHOME/init/ksh
  module load PrgEnv-intel ESMF-intel-haswell/3_1_0rp5 cfp-intel-sandybridge iobuf craype-hugepages2M craype-haswell
#  module load cfp-intel-sandybridge/1.1.0
  module use /gpfs/hps/nco/ops/nwprod/modulefiles
  module load prod_envir
#  module load prod_util
  module load prod_util/1.0.23
  module load grib_util/1.0.3
  module load crtm-intel/2.2.5
  module list

# specify computation resource
  export NODES=8
  export ntasks=96
  export ptile=12
  export threads=1
  export MP_LABELIO=yes
  export OMP_NUM_THREADS=$threads

  export APRUN="aprun -j 1 -n${ntasks} -N${ptile} -d${threads} -cc depth"
  ;;
#
"THEIA")
#
  np=$( cat $PBS_NODEFILE | wc -l )

  module purge
  module load intel impi netcdf #mvapich2 netcdf

  export APRUN="mpirun -l -np $np"
  ;;
#
"JET")
#
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

  export APRUN="mpirun -l -np $PBS_NP"
  ;;
#
"ODIN")
#
  export APRUN="srun -n 1"
  ;;
#
esac

#-----------------------------------------------------------------------
#
# Create directory (POSTPRD_DIR) in which to store post-processing out-
# put.  Also, create a temporary work directory (FHR_DIR) for the cur-
# rent output hour being processed.  FHR_DIR will be deleted later be-
# low after the processing for the current hour is complete.
#
#-----------------------------------------------------------------------

POSTPRD_DIR="$RUNDIR/postprd"
FHR_DIR="${POSTPRD_DIR}/$fhr"
mkdir -p ${FHR_DIR}
cd ${FHR_DIR}

#-----------------------------------------------------------------------
#
# Get the cycle hour.  This is just the variable HH set in the setup.sh
# script.
#
#-----------------------------------------------------------------------

cyc=${HH}
tmmark="tm${HH}"

#-----------------------------------------------------------------------
#
# Create text file containing arguments to the post-processing executa-
# ble.
#
#-----------------------------------------------------------------------

dyn_file=${RUNDIR}/dynf0${fhr}.nc
phy_file=${RUNDIR}/phyf0${fhr}.nc

POST_TIME=$( ${UPPDIR}/ndate.exe +${fhr} ${CDATE} )
POST_YYYY=${POST_TIME:0:4}
POST_MM=${POST_TIME:4:2}
POST_DD=${POST_TIME:6:2}
POST_HH=${POST_TIME:8:2}

cat > itag <<EOF
${dyn_file}
netcdf
grib2
${POST_YYYY}-${POST_MM}-${POST_DD}_${POST_HH}:00:00
FV3R
${phy_file}

 &NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,
 /
EOF

rm -f fort.*

#-----------------------------------------------------------------------
#
# Stage files.
#
#-----------------------------------------------------------------------

cp $UPPFIX/nam_micro_lookup.dat ./eta_micro_lookup.dat
cp $UPPFIX/postxconfig-NT-fv3sar.txt ./postxconfig-NT.txt
cp $UPPFIX/params_grib2_tbl_new ./params_grib2_tbl_new

#-----------------------------------------------------------------------
#
# Run the post-processor and move output files from FHR_DIR to POSTPRD_-
# DIR.
#
#-----------------------------------------------------------------------

cp ${UPPDIR}/ncep_post .
${APRUN} ./ncep_post < itag

# If run_title is set to an empty string in config.sh, I think TITLE 
# will also be empty.  Must try out that case...
if [ -n ${predef_domain} ]; then 
 TITLE=${predef_domain}
else 
 TITLE=${run_title:1}
fi

mv BGDAWP.GrbF${fhr} ../${TITLE}.t${cyc}z.bgdawp${fhr}.${tmmark}
mv BGRD3D.GrbF${fhr} ../${TITLE}.t${cyc}z.bgrd3d${fhr}.${tmmark}

#-----------------------------------------------------------------------
#
# Remove work directory.
#
#-----------------------------------------------------------------------

rm -rf ${FHR_DIR}


print_info_msg_verbose "Post-processing completed for fhr = $fhr hr."

#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------

{ restore_shell_opts; } > /dev/null 2>&1

