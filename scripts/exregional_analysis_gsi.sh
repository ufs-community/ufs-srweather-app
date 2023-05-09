#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_analysis_gsi|task_run_fcst|task_run_post" ${GLOBAL_VAR_DEFNS_FP}
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
This is the ex-script for the task that runs a analysis with FV3 for the
specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_ANALYSIS}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_ANALYSIS}
export OMP_STACKSIZE=${OMP_STACKSIZE_ANALYSIS}
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

gridspec_dir=${NWGES_BASEDIR}/grid_spec
mkdir_vrfy -p ${gridspec_dir}
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
JJJ=$(date +%j -d "${START_DATE}")

YYYY=${YYYYMMDDHH:0:4}
MM=${YYYYMMDDHH:4:2}
DD=${YYYYMMDDHH:6:2}
HH=${YYYYMMDDHH:8:2}
YYYYMMDD=${YYYYMMDDHH:0:8}
#
# YYYY-MM-DD_meso_uselist.txt and YYYYMMDD_rejects.txt:
# both contain past 7 day OmB averages till ~YYYYMMDD_23:59:59 UTC
# So they are to be used by next day cycles
MESO_USELIST_FN=$(date +%Y-%m-%d -d "${START_DATE} -1 day")_meso_uselist.txt
AIR_REJECT_FN=$(date +%Y%m%d -d "${START_DATE} -1 day")_rejects.txt
#
#-----------------------------------------------------------------------
#
# go to working directory.
# define fix and background path
#
#-----------------------------------------------------------------------

cd_vrfy ${DATA}

pregen_grid_dir=$DOMAIN_PREGEN_BASEDIR/${PREDEF_GRID_NAME}

# set background path
if [ "${RUN_ENVIR}" = "nco" ]; then
    bkpath=$DATAROOT/${TAG}run_fcst_${CYCLE_TYPE}${SLASH_ENSMEM_SUBDIR/\//_}.${share_pid}
else
    bkpath=${COMIN}${SLASH_ENSMEM_SUBDIR}
fi
if [ ${CYCLE_TYPE} == "spinup" ]; then
    bkpath=${bkpath}/fcst_fv3lam_spinup/INPUT
else
    bkpath=${bkpath}/fcst_fv3lam/INPUT
fi

# decide background type
if [ -r "${bkpath}/coupler.res" ]; then
  BKTYPE=0              # warm start
else
  BKTYPE=1              # cold start
fi

#---------------------------------------------------------------------
#
# decide regional_ensemble_option: global ensemble (1) or FV3LAM ensemble (5)
#
#---------------------------------------------------------------------
#
echo "regional_ensemble_option is ",${regional_ensemble_option:-1}

print_info_msg "$VERBOSE" "FIXgsi is $FIXgsi"
print_info_msg "$VERBOSE" "pregen_grid_dir is $pregen_grid_dir"
print_info_msg "$VERBOSE" "default bkpath is $bkpath"
print_info_msg "$VERBOSE" "background type is is $BKTYPE"

#
# Check if we have enough FV3-LAM ensembles when regional_ensemble_option=5
#
if  [[ ${regional_ensemble_option:-1} -eq 5 ]]; then
  ens_nstarthr=$( printf "%02d" ${DA_CYCLE_INTERV} )
  imem=1
  ifound=0
  for hrs in ${CYCL_HRS_HYB_FV3LAM_ENS[@]}; do
  if [ $HH == ${hrs} ]; then

  while [[ $imem -le ${NUM_ENS_MEMBERS} ]];do
    memcharv0=$( printf "%03d" $imem )
    memchar=mem$( printf "%04d" $imem )

    YYYYMMDDHHmInterv=$( date +%Y%m%d%H -d "${START_DATE} ${DA_CYCLE_INTERV} hours ago" )
    restart_prefix="${YYYYMMDD}.${HH}0000."
    SLASH_ENSMEM_SUBDIR=$memchar
    bkpathmem=${RRFSE_NWGES_BASEDIR}/${YYYYMMDDHHmInterv}/${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam/RESTART
    if [ ${DO_SPINUP} == "TRUE" ]; then
      for cycl_hrs in ${CYCL_HRS_PRODSTART_ENS[@]}; do
       if [ $HH == ${cycl_hrs} ]; then
         bkpathmem=${RRFSE_NWGES_BASEDIR}/${YYYYMMDDHHmInterv}/${SLASH_ENSMEM_SUBDIR}/fcst_fv3lam_spinup/RESTART
       fi
      done
    fi
    dynvarfile=${bkpathmem}/${restart_prefix}fv_core.res.tile1.nc
    tracerfile=${bkpathmem}/${restart_prefix}fv_tracer.res.tile1.nc
    phyvarfile=${bkpathmem}/${restart_prefix}phy_data.nc
    if [ -r "${dynvarfile}" ] && [ -r "${tracerfile}" ] && [ -r "${phyvarfile}" ] ; then
      ln_vrfy -snf ${bkpathmem}/${restart_prefix}fv_core.res.tile1.nc       fv3SAR${ens_nstarthr}_ens_mem${memcharv0}-fv3_dynvars
      ln_vrfy -snf ${bkpathmem}/${restart_prefix}fv_tracer.res.tile1.nc     fv3SAR${ens_nstarthr}_ens_mem${memcharv0}-fv3_tracer
      ln_vrfy -snf ${bkpathmem}/${restart_prefix}phy_data.nc                fv3SAR${ens_nstarthr}_ens_mem${memcharv0}-fv3_phyvars
      (( ifound += 1 ))
    else
      print_info_msg "Error: cannot find ensemble files: ${dynvarfile} ${tracerfile} ${phyvarfile} "
    fi
    (( imem += 1 ))
  done
 
  fi
  done

  if [[ $ifound -ne ${NUM_ENS_MEMBERS} ]] || [[ ${BKTYPE} -eq 1 ]]; then
    print_info_msg "Not enough FV3_LAM ensembles, will fall to GDAS"
    regional_ensemble_option=1
  fi
fi
#
if  [[ ${regional_ensemble_option:-1} -eq 1 ]]; then #using GDAS
  #-----------------------------------------------------------------------
  # Make a list of the latest GFS EnKF ensemble
  #-----------------------------------------------------------------------
  stampcycle=$(date -d "${START_DATE}" +%s)
  minHourDiff=100
  loops="009"    # or 009s for GFSv15
  ftype="nc"  # or nemsio for GFSv15
  foundgdasens="false"

  case $MACHINE in

  "WCOSS2")

    for loop in $loops; do
      for timelist in $(ls ${ENKF_FCST}/enkfgdas.*/*/atmos/mem080/gdas*.atmf${loop}.${ftype}); do
        availtimeyyyymmdd=$(echo ${timelist} | cut -d'/' -f9 | cut -c 10-17)
        availtimehh=$(echo ${timelist} | cut -d'/' -f10)
        availtime=${availtimeyyyymmdd}${availtimehh}
        avail_time=$(echo "${availtime}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')
        avail_time=$(date -d "${avail_time}")

        loopfcst=$(echo ${loop}| cut -c 1-3)      # for nemsio 009s to get 009
        stamp_avail=$(date -d "${avail_time} ${loopfcst} hours" +%s)

        hourDiff=$(echo "($stampcycle - $stamp_avail) / (60 * 60 )" | bc);
        if [[ ${stampcycle} -lt ${stamp_avail} ]]; then
           hourDiff=$(echo "($stamp_avail - $stampcycle) / (60 * 60 )" | bc);
        fi

        if [[ ${hourDiff} -lt ${minHourDiff} ]]; then
           minHourDiff=${hourDiff}
           enkfcstname=gdas.t${availtimehh}z.atmf${loop}
           eyyyymmdd=$(echo ${availtime} | cut -c1-8)
           ehh=$(echo ${availtime} | cut -c9-10)
           foundgdasens="true"
        fi
      done
    done

    if [ ${foundgdasens} = "true" ]
    then
      ls ${ENKF_FCST}/enkfgdas.${eyyyymmdd}/${ehh}/atmos/mem???/${enkfcstname}.nc > filelist03
    fi

    ;;
  * )

    for loop in $loops; do
      for timelist in $(ls ${ENKF_FCST}/*.gdas.t*z.atmf${loop}.mem080.${ftype}); do
        availtimeyy=$(basename ${timelist} | cut -c 1-2)
        availtimeyyyy=20${availtimeyy}
        availtimejjj=$(basename ${timelist} | cut -c 3-5)
        availtimemm=$(date -d "${availtimeyyyy}0101 +$(( 10#${availtimejjj} - 1 )) days" +%m)
        availtimedd=$(date -d "${availtimeyyyy}0101 +$(( 10#${availtimejjj} - 1 )) days" +%d)
        availtimehh=$(basename ${timelist} | cut -c 6-7)
        availtime=${availtimeyyyy}${availtimemm}${availtimedd}${availtimehh}
        avail_time=$(echo "${availtime}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/')
        avail_time=$(date -d "${avail_time}")

        loopfcst=$(echo ${loop}| cut -c 1-3)      # for nemsio 009s to get 009
        stamp_avail=$(date -d "${avail_time} ${loopfcst} hours" +%s)

        hourDiff=$(echo "($stampcycle - $stamp_avail) / (60 * 60 )" | bc);
        if [[ ${stampcycle} -lt ${stamp_avail} ]]; then
           hourDiff=$(echo "($stamp_avail - $stampcycle) / (60 * 60 )" | bc);
        fi

        if [[ ${hourDiff} -lt ${minHourDiff} ]]; then
           minHourDiff=${hourDiff}
           enkfcstname=${availtimeyy}${availtimejjj}${availtimehh}00.gdas.t${availtimehh}z.atmf${loop}
           foundgdasens="true"
        fi
      done
    done

    if [ $foundgdasens = "true" ]; then
      ls ${ENKF_FCST}/${enkfcstname}.mem0??.${ftype} >> filelist03
    fi

  esac
fi

#
#-----------------------------------------------------------------------
#
# set default values for namelist
#
#-----------------------------------------------------------------------

ifsatbufr=.false.
ifsoilnudge=.false.
ifhyb=.false.
miter=2
niter1=50
niter2=50
lread_obs_save=.false.
lread_obs_skip=.false.
if_model_dbz=.false.

# Determine if hybrid option is available
memname='atmf009'

if [ ${regional_ensemble_option:-1} -eq 5 ]  && [ ${BKTYPE} != 1  ]; then 
  nummem=$NUM_ENS_MEMBERS
  print_info_msg "$VERBOSE" "Do hybrid with FV3LAM ensemble"
  ifhyb=.true.
  print_info_msg "$VERBOSE" " Cycle ${YYYYMMDDHH}: GSI hybrid uses FV3LAM ensemble with n_ens=${nummem}" 
  grid_ratio_ens="1"
  ens_fast_read=.true.
else    
  nummem=$(more filelist03 | wc -l)
  nummem=$((nummem - 3 ))
  if [[ ${nummem} -ge ${HYBENSMEM_NMIN} ]]; then
    print_info_msg "$VERBOSE" "Do hybrid with ${memname}"
    ifhyb=.true.
    print_info_msg "$VERBOSE" " Cycle ${YYYYMMDDHH}: GSI hybrid uses ${memname} with n_ens=${nummem}"
  else
    print_info_msg "$VERBOSE" " Cycle ${YYYYMMDDHH}: GSI does pure 3DVAR."
    print_info_msg "$VERBOSE" " Hybrid needs at least ${HYBENSMEM_NMIN} ${memname} ensembles, only ${nummem} available"
  fi
fi

#
#-----------------------------------------------------------------------
#
# link or copy background and grib configuration files
#
#  Using ncks to add phis (terrain) into cold start input background.
#           it is better to change GSI to use the terrain from fix file.
#  Adding radar_tten array to fv3_tracer. Should remove this after add this array in
#           radar_tten converting code.
#-----------------------------------------------------------------------

n_iolayouty=$(($IO_LAYOUT_Y-1))
list_iolayout=$(seq 0 $n_iolayouty)

ln_vrfy -snf ${pregen_grid_dir}/fv3_akbk                     fv3_akbk
ln_vrfy -snf ${pregen_grid_dir}/fv3_grid_spec                fv3_grid_spec

if [ ${BKTYPE} -eq 1 ]; then  # cold start uses background from INPUT
  ln_vrfy -snf ${pregen_grid_dir}/phis.nc               phis.nc
  ncks -A -v  phis               phis.nc           ${bkpath}/gfs_data.tile7.halo0.nc 

  ln_vrfy -snf ${bkpath}/sfc_data.tile7.halo0.nc   fv3_sfcdata
  ln_vrfy -snf ${bkpath}/gfs_data.tile7.halo0.nc   fv3_dynvars
  ln_vrfy -s fv3_dynvars                           fv3_tracer

  fv3lam_bg_type=1
else                          # cycle uses background from restart
  if [ "${IO_LAYOUT_Y}" == "1" ]; then
    ln_vrfy  -snf ${bkpath}/fv_core.res.tile1.nc             fv3_dynvars
    ln_vrfy  -snf ${bkpath}/fv_tracer.res.tile1.nc           fv3_tracer
    ln_vrfy  -snf ${bkpath}/sfc_data.nc                      fv3_sfcdata
    ln_vrfy  -snf ${bkpath}/phy_data.nc                      fv3_phyvars
  else
    for ii in ${list_iolayout}
    do
      iii=`printf %4.4i $ii`
      ln_vrfy  -snf ${bkpath}/fv_core.res.tile1.nc.${iii}     fv3_dynvars.${iii}
      ln_vrfy  -snf ${bkpath}/fv_tracer.res.tile1.nc.${iii}   fv3_tracer.${iii}
      ln_vrfy  -snf ${bkpath}/sfc_data.nc.${iii}              fv3_sfcdata.${iii}
      ln_vrfy  -snf ${bkpath}/phy_data.nc.${iii}              fv3_phyvars.${iii}
      ln_vrfy  -snf ${gridspec_dir}/fv3_grid_spec.${iii}      fv3_grid_spec.${iii}
    done
  fi
  fv3lam_bg_type=0
fi

# update times in coupler.res to current cycle time
cp_vrfy ${pregen_grid_dir}/fv3_coupler.res          coupler.res
sed -i "s/yyyy/${YYYY}/" coupler.res
sed -i "s/mm/${MM}/"     coupler.res
sed -i "s/dd/${DD}/"     coupler.res
sed -i "s/hh/${HH}/"     coupler.res

#
#-----------------------------------------------------------------------
#
# link observation files
# copy observation files to working directory 
#
#-----------------------------------------------------------------------
#
obs_source=rap
if [ ${HH} -eq '00' ] || [ ${HH} -eq '12' ]; then
  obs_source=rap_e
fi

# evaluate template path that uses `obs_source`
eval OBSPATH_TEMPLATE=${OBSPATH_TEMPLATE}

if [[ ${GSI_TYPE} == "OBSERVER" || ${OB_TYPE} == "conv" ]]; then

  obs_files_source[0]=${OBSPATH_TEMPLATE}.t${HH}z.prepbufr.tm00
  obs_files_target[0]=prepbufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.satwnd.tm00.bufr_d
  obs_files_target[${obs_number}]=satwndbufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.nexrad.tm00.bufr_d
  obs_files_target[${obs_number}]=l2rwbufr

  if [ ${DO_ENKF_RADAR_REF} == "TRUE" ]; then
    obs_number=${#obs_files_source[@]}
    obs_files_source[${obs_number}]=${COMIN}/process_radarref/00/Gridded_ref.nc
    obs_files_target[${obs_number}]=dbzobs.nc
  fi

else

  if [ ${OB_TYPE} == "radardbz" ]; then

    if [ ${CYCLE_TYPE} == "spinup" ]; then
      obs_files_source[0]=${COMIN}/process_radarref_spinup/00/Gridded_ref.nc
    else
      obs_files_source[0]=${COMIN}/process_radarref/00/Gridded_ref.nc
    fi
    obs_files_target[0]=dbzobs.nc

  fi

fi

#
#-----------------------------------------------------------------------
#
# including satellite radiance data
#
#-----------------------------------------------------------------------
if [ ${DO_RADDA} == "TRUE" ]; then

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.1bamua.tm00.bufr_d
  obs_files_target[${obs_number}]=amsuabufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.esamua.tm00.bufr_d
  obs_files_target[${obs_number}]=amsuabufrears

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.1bmhs.tm00.bufr_d
  obs_files_target[${obs_number}]=mhsbufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.esmhs.tm00.bufr_d
  obs_files_target[${obs_number}]=mhsbufrears

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.atms.tm00.bufr_d
  obs_files_target[${obs_number}]=atmsbufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.esatms.tm00.bufr_d
  obs_files_target[${obs_number}]=atmsbufrears

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.atmsdb.tm00.bufr_d
  obs_files_target[${obs_number}]=atmsbufr_db

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.crisf4.tm00.bufr_d
  obs_files_target[${obs_number}]=crisfsbufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.crsfdb.tm00.bufr_d
  obs_files_target[${obs_number}]=crisfsbufr_db

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.mtiasi.tm00.bufr_d
  obs_files_target[${obs_number}]=iasibufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.esiasi.tm00.bufr_d
  obs_files_target[${obs_number}]=iasibufrears

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.iasidb.tm00.bufr_d
  obs_files_target[${obs_number}]=iasibufr_db

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.gsrcsr.tm00.bufr_d
  obs_files_target[${obs_number}]=abibufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.ssmisu.tm00.bufr_d
  obs_files_target[${obs_number}]=ssmisbufr

  obs_number=${#obs_files_source[@]}
  obs_files_source[${obs_number}]=${OBSPATH_TEMPLATE}.t${HH}z.sevcsr.tm00.bufr_d
  obs_files_target[${obs_number}]=sevcsr

fi

obs_number=${#obs_files_source[@]}
for (( i=0; i<${obs_number}; i++ ));
do
  obs_file=${obs_files_source[$i]}
  obs_file_t=${obs_files_target[$i]}
  if [ -r "${obs_file}" ]; then
    ln -s "${obs_file}" "${obs_file_t}"
  else
    print_info_msg "$VERBOSE" "Warning: ${obs_file} does not exist!"
  fi
done

#
#-----------------------------------------------------------------------
#
# Create links to fix files in the FIXgsi directory.
# Set fixed files
#   berror   = forecast model background error statistics
#   specoef  = CRTM spectral coefficients
#   trncoef  = CRTM transmittance coefficients
#   emiscoef = CRTM coefficients for IR sea surface emissivity model
#   aerocoef = CRTM coefficients for aerosol effects
#   cldcoef  = CRTM coefficients for cloud effects
#   satinfo  = text file with information about assimilation of brightness temperatures
#   satangl  = angle dependent bias correction file (fixed in time)
#   pcpinfo  = text file with information about assimilation of prepcipitation rates
#   ozinfo   = text file with information about assimilation of ozone data
#   errtable = text file with obs error for conventional data (regional only)
#   convinfo = text file with information about assimilation of conventional data
#   bufrtable= text file ONLY needed for single obs test (oneobstest=.true.)
#   bftab_sst= bufr table for sst ONLY needed for sst retrieval (retrieval=.true.)
#
#-----------------------------------------------------------------------

ANAVINFO=${FIXgsi}/${ANAVINFO_FN}
if [ ${DO_ENKF_RADAR_REF} == "TRUE" ]; then
  ANAVINFO=${FIXgsi}/${ANAVINFO_DBZ_FN}
  diag_radardbz=.true.
  beta1_inv=0.0
  if_model_dbz=.true.
fi
if [[ ${GSI_TYPE} == "ANALYSIS" && ${OB_TYPE} == "radardbz" ]]; then
  ANAVINFO=${FIXgsi}/${ENKF_ANAVINFO_DBZ_FN}
  miter=1
  niter1=100
  niter2=0
  bkgerr_vs=0.1
  bkgerr_hzscl="0.4,0.5,0.6"
  beta1_inv=0.0
  ens_h=4.10790
  ens_v=-0.30125
  readin_localization=.false.
  q_hyb_ens=.true.
  if_model_dbz=.true.
fi
CONVINFO=${FIXgsi}/${CONVINFO_FN}
HYBENSINFO=${FIXgsi}/${HYBENSINFO_FN}
OBERROR=${FIXgsi}/${OBERROR_FN}
BERROR=${FIXgsi}/${BERROR_FN}

SATINFO=${FIXgsi}/global_satinfo.txt
OZINFO=${FIXgsi}/global_ozinfo.txt
PCPINFO=${FIXgsi}/global_pcpinfo.txt
ATMS_BEAMWIDTH=${FIXgsi}/atms_beamwidth.txt

# Fixed fields
cp_vrfy ${ANAVINFO} anavinfo
cp_vrfy ${BERROR}   berror_stats
cp_vrfy $SATINFO    satinfo
cp_vrfy $CONVINFO   convinfo
cp_vrfy $OZINFO     ozinfo
cp_vrfy $PCPINFO    pcpinfo
cp_vrfy $OBERROR    errtable
cp_vrfy $ATMS_BEAMWIDTH atms_beamwidth.txt
cp_vrfy ${HYBENSINFO} hybens_info

# Get surface observation provider list
if [ -r ${FIXgsi}/gsd_sfcobs_provider.txt ]; then
  cp_vrfy ${FIXgsi}/gsd_sfcobs_provider.txt gsd_sfcobs_provider.txt
else
  print_info_msg "$VERBOSE" "Warning: gsd surface observation provider does not exist!" 
fi

# Get aircraft reject list
for reject_list in "${AIRCRAFT_REJECT}/current_bad_aircraft.txt" \
                   "${AIRCRAFT_REJECT}/${AIR_REJECT_FN}"
do
  if [ -r $reject_list ]; then
    cp_vrfy $reject_list current_bad_aircraft
    print_info_msg "$VERBOSE" "Use aircraft reject list: $reject_list "
    break
  fi
done
if [ ! -r $reject_list ] ; then 
  print_info_msg "$VERBOSE" "Warning: gsd aircraft reject list does not exist!" 
fi

# Get mesonet uselist
gsd_sfcobs_uselist="gsd_sfcobs_uselist.txt"
for use_list in "${SFCOBS_USELIST}/current_mesonet_uselist.txt" \
                "${SFCOBS_USELIST}/${MESO_USELIST_FN}"      \
                "${SFCOBS_USELIST}/gsd_sfcobs_uselist.txt"
do 
  if [ -r $use_list ] ; then
    cp_vrfy $use_list  $gsd_sfcobs_uselist
    print_info_msg "$VERBOSE" "Use surface obs uselist: $use_list "
    break
  fi
done
if [ ! -r $use_list ] ; then 
  print_info_msg "$VERBOSE" "Warning: gsd surface observation uselist does not exist!" 
fi

#-----------------------------------------------------------------------
#
# CRTM Spectral and Transmittance coefficients
#
#-----------------------------------------------------------------------
emiscoef_IRwater=${FIXcrtm}/Nalli.IRwater.EmisCoeff.bin
emiscoef_IRice=${FIXcrtm}/NPOESS.IRice.EmisCoeff.bin
emiscoef_IRland=${FIXcrtm}/NPOESS.IRland.EmisCoeff.bin
emiscoef_IRsnow=${FIXcrtm}/NPOESS.IRsnow.EmisCoeff.bin
emiscoef_VISice=${FIXcrtm}/NPOESS.VISice.EmisCoeff.bin
emiscoef_VISland=${FIXcrtm}/NPOESS.VISland.EmisCoeff.bin
emiscoef_VISsnow=${FIXcrtm}/NPOESS.VISsnow.EmisCoeff.bin
emiscoef_VISwater=${FIXcrtm}/NPOESS.VISwater.EmisCoeff.bin
emiscoef_MWwater=${FIXcrtm}/FASTEM6.MWwater.EmisCoeff.bin
aercoef=${FIXcrtm}/AerosolCoeff.bin
cldcoef=${FIXcrtm}/CloudCoeff.bin

ln -s ${emiscoef_IRwater} Nalli.IRwater.EmisCoeff.bin
ln -s $emiscoef_IRice ./NPOESS.IRice.EmisCoeff.bin
ln -s $emiscoef_IRsnow ./NPOESS.IRsnow.EmisCoeff.bin
ln -s $emiscoef_IRland ./NPOESS.IRland.EmisCoeff.bin
ln -s $emiscoef_VISice ./NPOESS.VISice.EmisCoeff.bin
ln -s $emiscoef_VISland ./NPOESS.VISland.EmisCoeff.bin
ln -s $emiscoef_VISsnow ./NPOESS.VISsnow.EmisCoeff.bin
ln -s $emiscoef_VISwater ./NPOESS.VISwater.EmisCoeff.bin
ln -s $emiscoef_MWwater ./FASTEM6.MWwater.EmisCoeff.bin
ln -s $aercoef  ./AerosolCoeff.bin
ln -s $cldcoef  ./CloudCoeff.bin


# Copy CRTM coefficient files based on entries in satinfo file
for file in $(awk '{if($1!~"!"){print $1}}' ./satinfo | sort | uniq) ;do
   ln -s ${FIXcrtm}/${file}.SpcCoeff.bin ./
   ln -s ${FIXcrtm}/${file}.TauCoeff.bin ./
done

#-----------------------------------------------------------------------
#
# cycling radiance bias corretion files
#
#-----------------------------------------------------------------------
if [ ${DO_RADDA} == "TRUE" ]; then
  if [ ${CYCLE_TYPE} == "spinup" ]; then
    echo "spin up cycle"
    spinup_or_prod_rrfs=spinup
    for cyc_start in "${CYCL_HRS_SPINSTART[@]}"; do
      if [ ${HH} -eq ${cyc_start} ]; then
        spinup_or_prod_rrfs=prod 
      fi
    done
  else 
    echo " product cycle"
    spinup_or_prod_rrfs=prod
    for cyc_start in "${CYCL_HRS_PRODSTART[@]}"; do
      if [ ${HH} -eq ${cyc_start} ]; then
        spinup_or_prod_rrfs=spinup      
      fi 
    done
  fi

  satcounter=1
  maxcounter=240
  while [ $satcounter -lt $maxcounter ]; do
    SAT_TIME=`date +"%Y%m%d%H" -d "${START_DATE}  ${satcounter} hours ago"`
    echo $SAT_TIME
    if [ -r ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${SAT_TIME}_satbias ]; then
      echo " using satellite bias files from ${SAT_TIME}"

      cp_vrfy ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${SAT_TIME}_satbias ./satbias_in
      cp_vrfy ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${SAT_TIME}_satbias_pc ./satbias_pc
      cp_vrfy ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${SAT_TIME}_radstat ./radstat.rrfs

      break
    fi
    satcounter=` expr $satcounter + 1 `
  done

  ## if satbias files (go back to previous 10 dyas) are not available from ${SATBIAS_DIR}, use satbias files from the ${FIXgsi} 
  if [ $satcounter -eq $maxcounter ]; then
    if [ -r ${FIXgsi}/rrfs.gdas_satbias ]; then
      echo "using satllite satbias_in files from ${FIXgsi}"     
      cp_vrfy ${FIXgsi}/rrfs.starting_satbias ./satbias_in
    fi
    if [ -r ${FIXgsi}/rrfs.gdas_satbias_pc ]; then
      echo "using satllite satbias_pc files from ${FIXgsi}"     
      cp_vrfy ${FIXgsi}/rrfs.starting_satbias_pc ./satbias_pc
    fi
    if [ -r ${FIXgsi}/rrfs.gdas_radstat ]; then
      echo "using satllite radstat files from ${FIXgsi}"     
      cp_vrfy ${FIXgsi}/rrfs.starting_radstat ./radstat.rrfs
    fi
  fi

  listdiag=`tar xvf radstat.rrfs | cut -d' ' -f2 | grep _ges`
  for type in $listdiag; do
    diag_file=`echo $type | cut -d',' -f1`
    fname=`echo $diag_file | cut -d'.' -f1`
    date=`echo $diag_file | cut -d'.' -f2`
    gunzip $diag_file
    fnameanl=$(echo $fname|sed 's/_ges//g')
    mv $fname.$date* $fnameanl
  done
fi

#-----------------------------------------------------------------------
# skip radar reflectivity analysis if no RRFSE ensemble
#-----------------------------------------------------------------------

if [[ ${GSI_TYPE} == "ANALYSIS" && ${OB_TYPE} == "radardbz" ]]; then
  if  [[ ${regional_ensemble_option:-1} -eq 1 ]]; then
     echo "No RRFSE ensemble available, cannot do radar reflectivity analysis"
     exit 0
  fi
fi
#-----------------------------------------------------------------------
#
# Build the GSI namelist on-the-fly
#    most configurable paramters take values from settings in config.sh
#                                             (var_defns.sh in runtime)
#
#-----------------------------------------------------------------------
# 
if [ ${GSI_TYPE} == "OBSERVER" ]; then
  miter=0
  ifhyb=.false.
  if [ ${MEM_TYPE} == "MEAN" ]; then
    lread_obs_save=.true.
    lread_obs_skip=.false.
  else
    lread_obs_save=.false.
    lread_obs_skip=.true.
    ln -s ../../ensmean/observer_gsi/obs_input.* .
  fi
fi
if [ ${BKTYPE} -eq 1 ]; then
  n_iolayouty=1
else
  n_iolayouty=$(($IO_LAYOUT_Y))
fi

. ${FIXgsi}/gsiparm.anl.sh
cat << EOF > gsiparm.anl
$gsi_namelist
EOF

#
#-----------------------------------------------------------------------
#
# Copy the GSI executable to the run directory.
#
#-----------------------------------------------------------------------
#
exec_fn="gsi.x"
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
# Set and export variables.
#
#-----------------------------------------------------------------------
#

#
#-----------------------------------------------------------------------
#
# Run the GSI.  Note that we have to launch the forecast from
# the current cycle's run directory because the GSI executable will look
# for input files in the current directory.
#
#-----------------------------------------------------------------------
#
# comment out for testing
PREP_STEP
eval $RUN_CMD_UTILS ${exec_fp} < gsiparm.anl ${REDIRECT_OUT_ERR} || print_err_msg_exit "\
Call to executable to run GSI returned with nonzero exit code."
POST_STEP

if [ ${GSI_TYPE} == "ANALYSIS" ]; then
  if [ ${OB_TYPE} == "radardbz" ]; then
    cat fort.238 > $COMOUT/${NET}.t${HH}z.fits3.${POST_OUTPUT_DOMAIN_NAME}
  else
    mv fort.207 fit_rad1
    sed -e 's/   asm all/ps asm 900/; s/   rej all/ps rej 900/; s/   mon all/ps mon 900/' fort.201 > fit_p1
    sed -e 's/   asm all/uv asm 900/; s/   rej all/uv rej 900/; s/   mon all/uv mon 900/' fort.202 > fit_w1
    sed -e 's/   asm all/ t asm 900/; s/   rej all/ t rej 900/; s/   mon all/ t mon 900/' fort.203 > fit_t1
    sed -e 's/   asm all/ q asm 900/; s/   rej all/ q rej 900/; s/   mon all/ q mon 900/' fort.204 > fit_q1
    sed -e 's/   asm all/pw asm 900/; s/   rej all/pw rej 900/; s/   mon all/pw mon 900/' fort.205 > fit_pw1
    sed -e 's/   asm all/rw asm 900/; s/   rej all/rw rej 900/; s/   mon all/rw mon 900/' fort.209 > fit_rw1

    cat fit_p1 fit_w1 fit_t1 fit_q1 fit_pw1 fit_rad1 fit_rw1 > $COMOUT/${NET}.t${HH}z.fits.${POST_OUTPUT_DOMAIN_NAME}
    cat fort.208 fort.210 fort.212 fort.213 fort.220 > $COMOUT/${NET}.t${HH}z.fits2.${POST_OUTPUT_DOMAIN_NAME}
  fi
fi
#
#-----------------------------------------------------------------------
#
# touch a file "gsi_complete.txt" after the successful GSI run. This is to inform
# the successful analysis for the EnKF recentering
#
#-----------------------------------------------------------------------
#
touch gsi_complete.txt

#-----------------------------------------------------------------------
# Loop over first and last outer loops to generate innovation
# diagnostic files for indicated observation types (groups)
#
# NOTE:  Since we set miter=2 in GSI namelist SETUP, outer
#        loop 03 will contain innovations with respect to 
#        the analysis.  Creation of o-a innovation files
#        is triggered by write_diag(3)=.true.  The setting
#        write_diag(1)=.true. turns on creation of o-g
#        innovation files.
#-----------------------------------------------------------------------
#

netcdf_diag=${netcdf_diag:-".false."}
binary_diag=${binary_diag:-".true."}

loops="01 03"
for loop in $loops; do

case $loop in
  01) string=ges;;
  03) string=anl;;
   *) string=$loop;;
esac

#  Collect diagnostic files for obs types (groups) below
numfile_rad_bin=0
numfile_cnv=0
numfile_rad=0
if [ $binary_diag = ".true." ]; then
   listall="hirs2_n14 msu_n14 sndr_g08 sndr_g11 sndr_g11 sndr_g12 sndr_g13 sndr_g08_prep sndr_g11_prep sndr_g12_prep sndr_g13_prep sndrd1_g11 sndrd2_g11 sndrd3_g11 sndrd4_g11 sndrd1_g15 sndrd2_g15 sndrd3_g15 sndrd4_g15 sndrd1_g13 sndrd2_g13 sndrd3_g13 sndrd4_g13 hirs3_n15 hirs3_n16 hirs3_n17 amsua_n15 amsua_n16 amsua_n17 amsua_n18 amsua_n19 amsua_metop-a amsua_metop-b amsua_metop-c amsub_n15 amsub_n16 amsub_n17 hsb_aqua airs_aqua amsua_aqua imgr_g08 imgr_g11 imgr_g12 pcp_ssmi_dmsp pcp_tmi_trmm conv sbuv2_n16 sbuv2_n17 sbuv2_n18 omi_aura ssmi_f13 ssmi_f14 ssmi_f15 hirs4_n18 hirs4_metop-a mhs_n18 mhs_n19 mhs_metop-a mhs_metop-b mhs_metop-c amsre_low_aqua amsre_mid_aqua amsre_hig_aqua ssmis_las_f16 ssmis_uas_f16 ssmis_img_f16 ssmis_env_f16 iasi_metop-a iasi_metop-b iasi_metop-c seviri_m08 seviri_m09 seviri_m10 seviri_m11 cris_npp atms_npp ssmis_f17 cris-fsr_npp cris-fsr_n20 atms_n20 abi_g16 abi_g17 radardbz"
   for type in $listall; do
      set +e
      count=$(ls pe*.${type}_${loop} | wc -l)
      set -e
      if [[ $count -gt 0 ]]; then
         $(cat pe*.${type}_${loop} > diag_${type}_${string}.${YYYYMMDDHH})
         echo "diag_${type}_${string}.${YYYYMMDDHH}" >> listrad_bin
         numfile_rad_bin=`expr ${numfile_rad_bin} + 1`
      fi
   done
fi

if [ $netcdf_diag = ".true." ]; then
   nc_diag_cat="nc_diag_cat.x"
   listall_cnv="conv_ps conv_q conv_t conv_uv conv_pw conv_rw conv_sst conv_dbz"
   listall_rad="hirs2_n14 msu_n14 sndr_g08 sndr_g11 sndr_g11 sndr_g12 sndr_g13 sndr_g08_prep sndr_g11_prep sndr_g12_prep sndr_g13_prep sndrd1_g11 sndrd2_g11 sndrd3_g11 sndrd4_g11 sndrd1_g15 sndrd2_g15 sndrd3_g15 sndrd4_g15 sndrd1_g13 sndrd2_g13 sndrd3_g13 sndrd4_g13 hirs3_n15 hirs3_n16 hirs3_n17 amsua_n15 amsua_n16 amsua_n17 amsua_n18 amsua_n19 amsua_metop-a amsua_metop-b amsua_metop-c amsub_n15 amsub_n16 amsub_n17 hsb_aqua airs_aqua amsua_aqua imgr_g08 imgr_g11 imgr_g12 pcp_ssmi_dmsp pcp_tmi_trmm conv sbuv2_n16 sbuv2_n17 sbuv2_n18 omi_aura ssmi_f13 ssmi_f14 ssmi_f15 hirs4_n18 hirs4_metop-a mhs_n18 mhs_n19 mhs_metop-a mhs_metop-b mhs_metop-c amsre_low_aqua amsre_mid_aqua amsre_hig_aqua ssmis_las_f16 ssmis_uas_f16 ssmis_img_f16 ssmis_env_f16 iasi_metop-a iasi_metop-b iasi_metop-c seviri_m08 seviri_m09 seviri_m10 seviri_m11 cris_npp atms_npp ssmis_f17 cris-fsr_npp cris-fsr_n20 atms_n20 abi_g16"

   for type in $listall_cnv; do
      set +e
      count=$(ls pe*.${type}_${loop}.nc4 | wc -l)
      set -e
      if [[ $count -gt 0 ]]; then
         PREP_STEP
         eval $RUN_CMD_UTILS ${nc_diag_cat} -o diag_${type}_${string}.${YYYYMMDDHH}.nc4 pe*.${type}_${loop}.nc4 || print_err_msg "\
         Call to ${nc_diag_cat} returned with nonzero exit code."
         POST_STEP

         cp diag_${type}_${string}.${YYYYMMDDHH}.nc4 $COMOUT
         echo "diag_${type}_${string}.${YYYYMMDDHH}.nc4*" >> listcnv
         numfile_cnv=`expr ${numfile_cnv} + 1`
      fi
   done

   for type in $listall_rad; do
      set +e
      count=$(ls pe*.${type}_${loop}.nc4 | wc -l)
      set -e
      if [[ $count -gt 0 ]]; then
         PREP_STEP
         eval $RUN_CMD_UTILS ${nc_diag_cat} -o diag_${type}_${string}.${YYYYMMDDHH}.nc4 pe*.${type}_${loop}.nc4 || print_err_msg "\
         Call to ${nc_diag_cat} returned with nonzero exit code."
         POST_STEP
         cp diag_${type}_${string}.${YYYYMMDDHH}.nc4 $COMOUT
         echo "diag_${type}_${string}.${YYYYMMDDHH}.nc4*" >> listrad
         numfile_rad=`expr ${numfile_rad} + 1`
      else
         echo 'No diag_' ${type} 'exist'
      fi
   done
fi

done

if [ ${GSI_TYPE} == "OBSERVER" ]; then
  cp_vrfy *diag*ges* ${OBSERVER_NWGES_DIR}/.
  if [ ${MEM_TYPE} == "MEAN" ]; then
  mkdir_vrfy -p ${OBSERVER_NWGES_DIR}/../../../observer_diag/${YYYYMMDDHH}/ensmean/observer_gsi
  cp_vrfy *diag*ges* ${OBSERVER_NWGES_DIR}/../../../observer_diag/${YYYYMMDDHH}/ensmean/observer_gsi/.
  else
  mkdir_vrfy -p ${OBSERVER_NWGES_DIR}/../../../observer_diag/${YYYYMMDDHH}/${SLASH_ENSMEM_SUBDIR}/observer_gsi
  cp_vrfy *diag*ges* ${OBSERVER_NWGES_DIR}/../../../observer_diag/${YYYYMMDDHH}/${SLASH_ENSMEM_SUBDIR}/observer_gsi/.
  fi
fi

#
#-----------------------------------------------------------------------
#
# cycling radiance bias corretion files
#
#-----------------------------------------------------------------------

if [ ${DO_RADDA} == "TRUE" ]; then
  if [ ${CYCLE_TYPE} == "spinup" ]; then
    spinup_or_prod_rrfs=spinup
  else
    spinup_or_prod_rrfs=prod
  fi
  if [ ${numfile_cnv} -gt 0 ]; then
     tar -cvzf rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_cnvstat_nc `cat listcnv`
     cp_vrfy ./rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_cnvstat_nc  ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_cnvstat
  fi
  if [ ${numfile_rad} -gt 0 ]; then
     tar -cvzf rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_radstat_nc `cat listrad`
     cp_vrfy ./rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_radstat_nc  ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_radstat
  fi
  if [ ${numfile_rad_bin} -gt 0 ]; then
     tar -cvzf rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_radstat `cat listrad_bin`
     cp_vrfy ./rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_radstat  ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_radstat
  fi

  cp_vrfy ./satbias_out ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_satbias
  cp_vrfy ./satbias_pc.out ${SATBIAS_DIR}/rrfs.${spinup_or_prod_rrfs}.${YYYYMMDDHH}_satbias_pc
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
ANALYSIS GSI completed successfully!!!
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
