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
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1

RUNDIR="$EXPTDIR/$CDATE"
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "Starting post-processing for fhr = $fhr hr..."

case $MACHINE in
#
"WCOSS_C" | "WCOSS" )
#
#  { save_shell_opts; set +x; } > /dev/null 2>&1
  module purge
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
#  { restore_shell_opts; } > /dev/null 2>&1

# Specify computational resources.
  export NODES=8
  export ntasks=96
  export ptile=12
  export threads=1
  export MP_LABELIO=yes
  export OMP_NUM_THREADS=$threads

  APRUN="aprun -j 1 -n${ntasks} -N${ptile} -d${threads} -cc depth"
  ;;
#
"THEIA")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1
  module purge
  module load intel
  module load impi 
  module load netcdf
  module load contrib wrap-mpi
  { restore_shell_opts; } > /dev/null 2>&1

  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
  ;;
#
"JET")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1
  module purge 
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
  module load contrib wrap-mpi
  { restore_shell_opts; } > /dev/null 2>&1

  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
  ;;
#
"ODIN")
#
  APRUN="srun -n 1"
  ;;
#
esac

#-----------------------------------------------------------------------
#
# If it doesn't already exist, create the directory (POSTPRD_DIR) in 
# which to store post-processing output.  (Note that POSTPRD_DIR may al-
# ready have been created by this post-processing script run for a dif-
# ferent forecast hour.)  Also, create a temporary work directory (FHR_-
# DIR) for the current forecast hour being processed.  FHR_DIR will be 
# deleted later after the processing for the current forecast hour is 
# complete.  Then change location to FHR_DIR.
#
# Note that there may be a preexisting version of FHR_DIR from previous 
# runs of this script for the current forecast hour (e.g. from the work-
# flow task that runs this script failing and then being called again).  
# Thus, we first make sure preexisting versions are deleted.
#
#-----------------------------------------------------------------------

POSTPRD_DIR="$RUNDIR/postprd"
mkdir_vrfy -p "${POSTPRD_DIR}"

FHR_DIR="${POSTPRD_DIR}/$fhr"
check_for_preexist_dir $FHR_DIR "delete"
mkdir_vrfy -p "${FHR_DIR}"

cd_vrfy ${FHR_DIR}

#-----------------------------------------------------------------------
#
# Get the cycle hour.  This is just the variable HH set in the setup.sh
# script.
#
#-----------------------------------------------------------------------

HH=${CDATE:8:2}
cyc=$HH
tmmark="tm$HH"

#-----------------------------------------------------------------------
#
# Create a text file (itag) containing arguments to pass to the post-
# processing executable.
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

#-----------------------------------------------------------------------
#
# Stage files in FHR_DIR.
#
#-----------------------------------------------------------------------

rm_vrfy -f fort.*

cp_vrfy $UPPFIX/nam_micro_lookup.dat ./eta_micro_lookup.dat
cp_vrfy $UPPFIX/postxconfig-NT-fv3sar.txt ./postxconfig-NT.txt
cp_vrfy $UPPFIX/params_grib2_tbl_new ./params_grib2_tbl_new

#-----------------------------------------------------------------------
#
# Copy the UPP executable to FHR_DIR and run the post-processor.
#
#-----------------------------------------------------------------------

cp_vrfy ${UPPDIR}/ncep_post .
${APRUN} ./ncep_post < itag || print_err_msg_exit "\
Call to executable to run post for forecast hour $fhr returned with non-
zero exit code."

#-----------------------------------------------------------------------
#
# Move (and rename) the output files from the work directory to their
# final location (POSTPRD_DIR).  Then delete the work directory. 
#
#-----------------------------------------------------------------------

# If expt_title is set to an empty string in config.sh, I think TITLE 
# will also be empty.  Must try out that case...
if [ -n ${predef_domain} ]; then 
  TITLE=${predef_domain}
else 
  TITLE=${expt_title:1}
fi

mv_vrfy BGDAWP.GrbF${fhr} ${POSTPRD_DIR}/${TITLE}.t${cyc}z.bgdawp${fhr}.${tmmark}
mv_vrfy BGRD3D.GrbF${fhr} ${POSTPRD_DIR}/${TITLE}.t${cyc}z.bgrd3d${fhr}.${tmmark}

#Link output for transfer to Jet

START_DATE=`echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/'`
basetime=`date +%y%j%H%M -d "${START_DATE}"`
ln -s ${POSTPRD_DIR}/${TITLE}.t${cyc}z.bgdawp${fhr}.${tmmark} ${POSTPRD_DIR}/BGDAWP_${basetime}${fhr}00
ln -s ${POSTPRD_DIR}/${TITLE}.t${cyc}z.bgrd3d${fhr}.${tmmark} ${POSTPRD_DIR}/BGRD3D_${basetime}${fhr}00

rm_vrfy -rf ${FHR_DIR}
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

========================================================================
Post-processing for forecast hour $fhr completed successfully.
========================================================================"

#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------

{ restore_shell_opts; } > /dev/null 2>&1

