#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_run_enkf" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Define some support functions.
#
#-----------------------------------------------------------------------
#
function ncvarlst_noaxis_time {
    ncks --trd -m ${1} | grep -E ': type' | \
    cut -f 1 -d ' ' | sed 's/://' | \
    sort |grep -v -i -E "axis|time" ;
}
function ncvarlst_noaxis_time_new {
    ncks -m  ${1} | \
    grep -E 'float' | \
    cut -d "(" -f 1 | cut -c 10- ;
}
export  HDF5_USE_FILE_LOCKING=FALSE #clt to avoild recenter's error "NetCDF: HDF error"
export MPICH_COLL_OPT_OFF=1  # to fix non-physical EnKF analysis increments
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"
This is the ex-script for the task that runs EnKF analysis with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_RUN_ENKF}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_RUN_ENKF}
export OMP_STACKSIZE=${OMP_STACKSIZE_RUN_ENKF}
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

nprocs=$((NNODES_RUN_ENKF*PPN_RUN_ENKF))
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
START_DATE=$(echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')

YYYYMMDDHH=$(date +%Y%m%d%H -d "${START_DATE}")

vlddate=$CDATE
l_fv3reg_filecombined=.false.
#
#-----------------------------------------------------------------------
#
# Go to working directory.
# Define fix path
#
#-----------------------------------------------------------------------
#
cd_vrfy $DATA
fixgriddir=$FIXgsi/${PREDEF_GRID_NAME}

if [ ${CYCLE_TYPE} == "spinup" ]; then
   enkfanal_nwges_dir="${NWGES_DIR}/anal_enkf_spinup"
else
   enkfanal_nwges_dir="${NWGES_DIR}/anal_enkf"
fi
mkdir_vrfy -p ${enkfanal_nwges_dir}
#
#-----------------------------------------------------------------------
#
 cp_vrfy ${fixgriddir}/fv3_coupler.res    coupler.res
 cp_vrfy ${fixgriddir}/fv3_akbk           fv3sar_tile1_akbk.nc
 cp_vrfy ${fixgriddir}/fv3_grid_spec      fv3sar_tile1_grid_spec.nc

#
#-----------------------------------------------------------------------
#
# Loop through the members, link the background and copy over
#  observer output (diag*ges*) files to the running directory
#
#-----------------------------------------------------------------------
#
 for imem in  $(seq 1 $nens) ensmean; do

     if [ ${imem} == "ensmean" ]; then
        memchar="ensmean"
        memcharv0="ensmean"
     else
        memchar="mem"$(printf %04i $imem)
        memcharv0="mem"$(printf %03i $imem)
     fi
     SLASH_ENSMEM_SUBDIR=$memchar
     if [ ${CYCLE_TYPE} == "spinup" ]; then
        bkpath=${COMIN}/${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam_spinup/INPUT
        observer_nwges_dir="${NWGES_DIR}/${SLASH_ENSMEM_SUBDIR}/observer_gsi_spinup"
     else
        bkpath=${COMIN}/${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam/INPUT
        observer_nwges_dir="${NWGES_DIR}/${SLASH_ENSMEM_SUBDIR}/observer_gsi"
     fi

     ln_vrfy  -snf  ${bkpath}/fv_core.res.tile1.nc         fv3sar_tile1_${memcharv0}_dynvars
     ln_vrfy  -snf  ${bkpath}/fv_tracer.res.tile1.nc       fv3sar_tile1_${memcharv0}_tracer
     ln_vrfy  -snf  ${bkpath}/sfc_data.nc                  fv3sar_tile1_${memcharv0}_sfcdata
     ln_vrfy  -snf  ${bkpath}/phy_data.nc                  fv3sar_tile1_${memcharv0}_phyvar

#
#-----------------------------------------------------------------------
#
# Copy observer outputs (diag*ges*) to the working directory
#
#-----------------------------------------------------------------------
#

  if [ ${netcdf_diag} == ".true." ] ; then
    if [ ${OB_TYPE} == "conv" ]; then
      list_OB_TYPE="conv_ps conv_q conv_t conv_uv conv_pw conv_rw conv_sst"
    fi
    if [ ${OB_TYPE} == "radardbz" ]; then
      list_OB_TYPE="conv_dbz"
    fi
    for sub_OB_TYPE in ${list_OB_TYPE} ; do
      diagfile0=${observer_nwges_dir}/diag_${sub_OB_TYPE}_ges.${YYYYMMDDHH}.nc4
      if [ -s $diagfile0 ]; then
        diagfile=$(basename  $diagfile0)
        cp_vrfy  $diagfile0  $diagfile
        ncfile=$(basename -s .nc4 $diagfile)
        mv_vrfy $ncfile.nc4 ${ncfile}_${memcharv0}.nc4
      fi
    done
  else
    for diagfile0 in $(ls  ${observer_nwges_dir}/diag*${OB_TYPE}*ges* ) ; do
      if [ -s $diagfile0 ]; then
         diagfile=$(basename  $diagfile0)
         cp_vrfy  $diagfile0   diag_conv_ges.$memcharv0
      fi
    done
  fi

done

#
#-----------------------------------------------------------------------
#
# Set GSI fix files
#
#----------------------------------------------------------------------
#
found_OB_TYPE=0

CONVINFO=${FIXgsi}/convinfo.rrfs

if [ ${OB_TYPE} == "conv" ]; then
  ANAVINFO=${FIXgsi}/${ENKF_ANAVINFO_FN}
  CORRLENGTH=400
  LNSIGCUTOFF=0.5
  found_OB_TYPE=1
fi
if [ ${OB_TYPE} == "radardbz" ]; then
  ANAVINFO=${FIXgsi}/${ENKF_ANAVINFO_DBZ_FN}
  CORRLENGTH=18
  LNSIGCUTOFF=0.5
  found_OB_TYPE=1
fi
if [ ${found_OB_TYPE} == 0 ]; then
  print_err_msg_exit "Error: unknown observation type: ${OB_TYPE}"
fi
stdout_name=stdout.${OB_TYPE}
stderr_name=stderr.${OB_TYPE}

SATINFO=${FIXgsi}/global_satinfo.txt
OZINFO=${FIXgsi}/global_ozinfo.txt

cp_vrfy ${ANAVINFO} anavinfo
cp_vrfy $SATINFO    satinfo
cp_vrfy $CONVINFO   convinfo
cp_vrfy $OZINFO     ozinfo

#
#-----------------------------------------------------------------------
#
# Get nlons (NX_RES), nlats (NY_RES) and nlevs
#
#-----------------------------------------------------------------------
#
NX_RES=$(ncdump -h fv3sar_tile1_grid_spec.nc | grep "grid_xt =" | cut -f3 -d" " )
NY_RES=$(ncdump -h fv3sar_tile1_grid_spec.nc | grep "grid_yt =" | cut -f3 -d" " )
nlevs=$(ncdump -h fv3sar_tile1_mem001_tracer | grep "zaxis_1 =" | cut -f3 -d" " )
#
#----------------------------------------------------------------------
#
# Set namelist parameters for EnKF
#
#----------------------------------------------------------------------
#

EnKFTracerVars=${EnKFTracerVar:-"sphum,o3mr"}
ldo_enscalc_option=${ldo_enscalc_option:-0}

# We expect 81 total files to be present (80 enkf + 1 mean)
nens=${nens:-81}
USEGFSO3=.false.
# Not using FGAT or 4DEnVar, so hardwire nhr_assimilation to 3
nhr_assimilation=3.
vs=1.
fstat=.false.
i_gsdcldanal_type=0
use_gfs_nemsio=.true.,

#
#----------------------------------------------------------------------
#
# Make enkf namelist
#
#----------------------------------------------------------------------
#
    cat > enkf.nml << EOFnml
    &nam_enkf
    datestring="$vlddate",datapath="$DATA/",
    analpertwtnh=0.85,analpertwtsh=0.85,analpertwttr=0.85,
    covinflatemax=1.e2,covinflatemin=1,pseudo_rh=.true.,iassim_order=0,
        corrlengthnh=$CORRLENGTH,corrlengthsh=$CORRLENGTH,corrlengthtr=$CORRLENGTH,
        lnsigcutoffnh=$LNSIGCUTOFF,lnsigcutoffsh=$LNSIGCUTOFF,lnsigcutofftr=$LNSIGCUTOFF,
        lnsigcutoffpsnh=$LNSIGCUTOFF,lnsigcutoffpssh=$LNSIGCUTOFF,lnsigcutoffpstr=$LNSIGCUTOFF,
        lnsigcutoffsatnh=$LNSIGCUTOFF,lnsigcutoffsatsh=$LNSIGCUTOFF,lnsigcutoffsattr=$LNSIGCUTOFF,
    obtimelnh=1.e30,obtimelsh=1.e30,obtimeltr=1.e30,
    saterrfact=1.0,numiter=1,
    sprd_tol=1.e30,paoverpb_thresh=0.98,
    nlons=${NX_RES:-396},nlats= ${NY_RES:-232}, nlevs= ${nlevs:-65},nanals=$nens,
    deterministic=.true.,sortinc=.true.,lupd_satbiasc=.false.,
    reducedgrid=.true.,readin_localization=.false.,
    use_gfs_nemsio=.true.,imp_physics=99,lupp=.false.,
    univaroz=.false.,adp_anglebc=.true.,angord=4,use_edges=.false.,emiss_bc=.true.,
    lobsdiag_forenkf=.false.,
    write_spread_diag=.false.,
    netcdf_diag=${netcdf_diag:-.false.},
        fv3_native=.true.,
    /
    &satobs_enkf
    sattypes_rad(1) = 'amsua_n15',     dsis(1) = 'amsua_n15',
    sattypes_rad(2) = 'amsua_n18',     dsis(2) = 'amsua_n18',
    sattypes_rad(3) = 'amsua_n19',     dsis(3) = 'amsua_n19',
    sattypes_rad(4) = 'amsub_n16',     dsis(4) = 'amsub_n16',
    sattypes_rad(5) = 'amsub_n17',     dsis(5) = 'amsub_n17',
    sattypes_rad(6) = 'amsua_aqua',    dsis(6) = 'amsua_aqua',
    sattypes_rad(7) = 'amsua_metop-a', dsis(7) = 'amsua_metop-a',
    sattypes_rad(8) = 'airs_aqua',     dsis(8) = 'airs_aqua',
    sattypes_rad(9) = 'hirs3_n17',     dsis(9) = 'hirs3_n17',
    sattypes_rad(10)= 'hirs4_n19',     dsis(10)= 'hirs4_n19',
    sattypes_rad(11)= 'hirs4_metop-a', dsis(11)= 'hirs4_metop-a',
    sattypes_rad(12)= 'mhs_n18',       dsis(12)= 'mhs_n18',
    sattypes_rad(13)= 'mhs_n19',       dsis(13)= 'mhs_n19',
    sattypes_rad(14)= 'mhs_metop-a',   dsis(14)= 'mhs_metop-a',
    sattypes_rad(15)= 'goes_img_g11',  dsis(15)= 'imgr_g11',
    sattypes_rad(16)= 'goes_img_g12',  dsis(16)= 'imgr_g12',
    sattypes_rad(17)= 'goes_img_g13',  dsis(17)= 'imgr_g13',
    sattypes_rad(18)= 'goes_img_g14',  dsis(18)= 'imgr_g14',
    sattypes_rad(19)= 'goes_img_g15',  dsis(19)= 'imgr_g15',
    sattypes_rad(20)= 'avhrr_n18',     dsis(20)= 'avhrr3_n18',
    sattypes_rad(21)= 'avhrr_metop-a', dsis(21)= 'avhrr3_metop-a',
    sattypes_rad(22)= 'avhrr_n19',     dsis(22)= 'avhrr3_n19',
    sattypes_rad(23)= 'amsre_aqua',    dsis(23)= 'amsre_aqua',
    sattypes_rad(24)= 'ssmis_f16',     dsis(24)= 'ssmis_f16',
    sattypes_rad(25)= 'ssmis_f17',     dsis(25)= 'ssmis_f17',
    sattypes_rad(26)= 'ssmis_f18',     dsis(26)= 'ssmis_f18',
    sattypes_rad(27)= 'ssmis_f19',     dsis(27)= 'ssmis_f19',
    sattypes_rad(28)= 'ssmis_f20',     dsis(28)= 'ssmis_f20',
    sattypes_rad(29)= 'sndrd1_g11',    dsis(29)= 'sndrD1_g11',
    sattypes_rad(30)= 'sndrd2_g11',    dsis(30)= 'sndrD2_g11',
    sattypes_rad(31)= 'sndrd3_g11',    dsis(31)= 'sndrD3_g11',
    sattypes_rad(32)= 'sndrd4_g11',    dsis(32)= 'sndrD4_g11',
    sattypes_rad(33)= 'sndrd1_g12',    dsis(33)= 'sndrD1_g12',
    sattypes_rad(34)= 'sndrd2_g12',    dsis(34)= 'sndrD2_g12',
    sattypes_rad(35)= 'sndrd3_g12',    dsis(35)= 'sndrD3_g12',
    sattypes_rad(36)= 'sndrd4_g12',    dsis(36)= 'sndrD4_g12',
    sattypes_rad(37)= 'sndrd1_g13',    dsis(37)= 'sndrD1_g13',
    sattypes_rad(38)= 'sndrd2_g13',    dsis(38)= 'sndrD2_g13',
    sattypes_rad(39)= 'sndrd3_g13',    dsis(39)= 'sndrD3_g13',
    sattypes_rad(40)= 'sndrd4_g13',    dsis(40)= 'sndrD4_g13',
    sattypes_rad(41)= 'sndrd1_g14',    dsis(41)= 'sndrD1_g14',
    sattypes_rad(42)= 'sndrd2_g14',    dsis(42)= 'sndrD2_g14',
    sattypes_rad(43)= 'sndrd3_g14',    dsis(43)= 'sndrD3_g14',
    sattypes_rad(44)= 'sndrd4_g14',    dsis(44)= 'sndrD4_g14',
    sattypes_rad(45)= 'sndrd1_g15',    dsis(45)= 'sndrD1_g15',
    sattypes_rad(46)= 'sndrd2_g15',    dsis(46)= 'sndrD2_g15',
    sattypes_rad(47)= 'sndrd3_g15',    dsis(47)= 'sndrD3_g15',
    sattypes_rad(48)= 'sndrd4_g15',    dsis(48)= 'sndrD4_g15',
    sattypes_rad(49)= 'iasi_metop-a',  dsis(49)= 'iasi_metop-a',
    sattypes_rad(50)= 'seviri_m08',    dsis(50)= 'seviri_m08',
    sattypes_rad(51)= 'seviri_m09',    dsis(51)= 'seviri_m09',
    sattypes_rad(52)= 'seviri_m10',    dsis(52)= 'seviri_m10',
    sattypes_rad(53)= 'amsua_metop-b', dsis(53)= 'amsua_metop-b',
    sattypes_rad(54)= 'hirs4_metop-b', dsis(54)= 'hirs4_metop-b',
    sattypes_rad(55)= 'mhs_metop-b',   dsis(55)= 'mhs_metop-b',
    sattypes_rad(56)= 'iasi_metop-b',  dsis(56)= 'iasi_metop-b',
    sattypes_rad(57)= 'avhrr_metop-b', dsis(57)= 'avhrr3_metop-b',
    sattypes_rad(58)= 'atms_npp',      dsis(58)= 'atms_npp',
    sattypes_rad(59)= 'atms_n20',      dsis(59)= 'atms_n20',
    sattypes_rad(60)= 'cris_npp',      dsis(60)= 'cris_npp',
    sattypes_rad(61)= 'cris-fsr_npp',  dsis(61)= 'cris-fsr_npp',
    sattypes_rad(62)= 'cris-fsr_n20',  dsis(62)= 'cris-fsr_n20',
    sattypes_rad(63)= 'gmi_gpm',       dsis(63)= 'gmi_gpm',
    sattypes_rad(64)= 'saphir_meghat', dsis(64)= 'saphir_meghat',
    /
    &ozobs_enkf
    sattypes_oz(1) = 'sbuv2_n16',
    sattypes_oz(2) = 'sbuv2_n17',
    sattypes_oz(3) = 'sbuv2_n18',
    sattypes_oz(4) = 'sbuv2_n19',
    sattypes_oz(5) = 'omi_aura',
    sattypes_oz(6) = 'gome_metop-a',
    sattypes_oz(7) = 'gome_metop-b',
    sattypes_oz(8) = 'mls30_aura',
    /
    &nam_fv3
    fv3fixpath="XXX",nx_res=${NX_RES:-396},ny_res=${NY_RES-232},ntiles=1,
        l_fv3reg_filecombined=${l_fv3reg_filecombined},
    /
EOFnml

#
#-----------------------------------------------------------------------
#
# Copy the EnKF executable to the run directory.
#
#-----------------------------------------------------------------------
#
echo pwd is `pwd`

exec_fn="enkf.x"
exec_fp="$EXECdir/${exec_fn}"

if [ ! -f "${exec_fp}" ]; then
  print_err_msg_exit "\
The executable specified in exec_fp does not exist:
  exec_fp = \"${exec_fp}\"
Build lightning process and rerun."
fi
#
#-----------------------------------------------------------------------
#
# Run the EnKF
#
#-----------------------------------------------------------------------
#
countdiag=$(ls diag*conv* | wc -l)
if [ $countdiag -gt $nens ]; then

PREP_STEP
eval ${RUN_CMD_UTILS} ${exec_fp}  < enkf.nml ${REDIRECT_OUT_ERR} || print_err_msg_exit "\
Call to executable to run EnKF returned with nonzero exit code."
POST_STEP


cp_vrfy ${stdout_name} ${enkfanal_nwges_dir}/.
cp_vrfy ${stderr_name} ${enkfanal_nwges_dir}/.
if [ ! -d ${NWGES_DIR}/../enkf_diag ]; then
  mkdir -p ${NWGES_DIR}/../enkf_diag
fi
cp_vrfy ${stdout_name} ${NWGES_DIR}/../enkf_diag/${stdout_name}.$vlddate
cp_vrfy ${stderr_name} ${NWGES_DIR}/../enkf_diag/${stderr_name}.$vlddate

else
  echo "Warning: EnKF not running due to lack of ${OB_TYPE} obs for cycle $vlddate !!!"
fi
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
EnKF PROCESS completed successfully!!!
Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
