#!/bin/bash

set -x

msg="JOB $job HAS BEGUN"
postmsg "$msg"

export pgm=aqm_lbcs

EMAIL_SDM=${EMAIL_SDM:-YES}
GEFS_AERO_LBCS_CHECK=${GEFS_AERO_LBCS_CHECK:-YES}

#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHaqm/source_util_funcs.sh
source_config_for_task "task_get_extrn_lbcs|task_make_orog|task_make_lbcs|cpl_aqm_parm|task_aqm_lbcs" ${GLOBAL_VAR_DEFNS_FP}
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHaqm/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
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

This is the ex-script for the task that generates chemical and GEFS
lateral boundary conditions.
========================================================================"
#
# Set OpenMP variables.
#
#-----------------------------------------------------------------------
#
export KMP_AFFINITY=${KMP_AFFINITY_MAKE_LBCS}
export OMP_NUM_THREADS=${OMP_NUM_THREADS_MAKE_LBCS}
export OMP_STACKSIZE=${OMP_STACKSIZE_MAKE_LBCS}
#
#-----------------------------------------------------------------------
#
# Set run command.
#
#-----------------------------------------------------------------------
#
eval ${PRE_TASK_CMDS}

nprocs=$(( NNODES_AQM_LBCS*PPN_AQM_LBCS ))

if [ -z "${RUN_CMD_UTILS:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_UTILS for your platform"
else
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_UTILS}\'."
fi
#
#-----------------------------------------------------------------------
#
# Add chemical LBCS
#
#-----------------------------------------------------------------------
#
CDATE_MOD=`$NDATE -${EXTRN_MDL_LBCS_OFFSET_HRS} ${PDY}${cyc}`
yyyymmdd=${CDATE_MOD:0:8}
mm="${CDATE_MOD:4:2}"
hh="${CDATE_MOD:8:2}"

if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
LBC_SPEC_FCST_HRS=()
for i_lbc in $(seq ${LBC_SPEC_INTVL_HRS} ${LBC_SPEC_INTVL_HRS} ${FCST_LEN_HRS} ); do
  LBC_SPEC_FCST_HRS+=("$i_lbc")
done

if [ ${DO_AQM_CHEM_LBCS} = "TRUE" ]; then

  ext_lbcs_file=${AQM_LBCS_FILES}
  chem_lbcs_fn=${ext_lbcs_file//<MM>/${mm}}

  chem_lbcs_fp=${FIXaqmchem_lbcs}/${chem_lbcs_fn}
  if [ -s ${chem_lbcs_fp} ]; then
    #Copy the boundary condition file to the current location
    cpreq ${chem_lbcs_fp} .
  else
    message_txt="WARNING The chemical LBC files do not exist:
    CHEM_BOUNDARY_CONDITION_FILE = \"${chem_lbcs_fp}\""
      err_exit "${message_txt}"
  fi

  # Function to check if the file exists
    function check_file_existence() {
    if [ -s "$1" ]; then
      echo "Found netCDF file: $1"
      cpreq "$1" .
    else
      echo "Error: NetCDF file not found: $1"
     return 1
    fi
    }

  for hr in 0 ${LBC_SPEC_FCST_HRS[@]}; do
    fhr=$( printf "%03d" "${hr}" )
   # Check if the file exists, retry three times with 5-second delay between attempts
     netcdf_file="${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fhr}.nc"

     echo "Checking file: $netcdf_file"
     echo "Current working directory: $(pwd)"

     retries=5
     while [ $retries -gt 0 ]; do
       if check_file_existence "$netcdf_file"; then
          break
       else
     # File doesn't exist, wait for 5 seconds and decrement the retry count
         sync
         sleep 20
        ((retries--))
       fi
     done
      # If file not found after three retries, exit with an error
     if [ $retries -eq 0 ]; then
       echo "Error: File not found after multiple retries: $netcdf_file"
        exit 1
     fi

    echo "Checking file: ${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fhr}.nc"
      cpreq "$netcdf_file" .

      ncks -A ${chem_lbcs_fn} ${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fhr}.nc
      cpreq ${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fhr}.nc ${INPUT_DATA} 
      export err=$?
      if [ $err -ne 0 ]; then
        message_txt="FATAL ERROR Call to NCKS returned with nonzero exit code."
          err_exit "${message_txt}"
      fi
  done

  print_info_msg "
========================================================================
Successfully added chemical LBCs !!!
========================================================================"
fi
#
#-----------------------------------------------------------------------
#
# Add GEFS-LBCS
#
#-----------------------------------------------------------------------
#
#
if [ ${DO_AQM_GEFS_LBCS} = "TRUE" ]; then
  AQM_GEFS_FILE_CYC=${AQM_GEFS_FILE_CYC:-"${hh}"}
  AQM_GEFS_FILE_CYC=$( printf "%02d" "${AQM_GEFS_FILE_CYC}" )

  GEFS_CYC_DIFF=$(( cyc - AQM_GEFS_FILE_CYC ))
  if [ "${GEFS_CYC_DIFF}" -lt "0" ]; then
    TSTEPDIFF=$( printf "%02d" $(( 24 + ${GEFS_CYC_DIFF} )) )
  else
    TSTEPDIFF=$( printf "%02d" ${GEFS_CYC_DIFF} )
  fi

  AQM_MOFILE_FN="${AQM_GEFS_FILE_PREFIX}.t${AQM_GEFS_FILE_CYC}z.atmf"
  if [ "${DO_REAL_TIME}" = "TRUE" ]; then
    AQM_MOFILE_FP="${COMINgefs}/gefs.${yyyymmdd}/${AQM_GEFS_FILE_CYC}/chem/sfcsig/${AQM_MOFILE_FN}"
  else
    AQM_MOFILE_FP="${COMINgefs}/${yyyymmdd}/${AQM_GEFS_FILE_CYC}/${AQM_MOFILE_FN}"
  fi  

check_file_with_recheck() {
  local file_path="$1"
  local max_rechecks=5
  local wait_time=5

  for recheck_count in $(seq 1 $max_rechecks); do
    if [ -e "$file_path" ]; then
       return 0  # File found
    else
     if [ $recheck_count -lt $max_rechecks ]; then
       sleep $wait_time
     fi
    fi
  done
 return 1  # File not found even after rechecks
}

  # Check if GEFS aerosol files exist
  for hr in 0 ${LBC_SPEC_FCST_HRS[@]}; do
    hr_mod=$(( hr + EXTRN_MDL_LBCS_OFFSET_HRS ))
    fhr=$( printf "%03d" "${hr_mod}" )
    AQM_MOFILE_FHR_FP="${AQM_MOFILE_FP}${fhr}.nemsio"
    ln -sf ${AQM_MOFILE_FHR_FP}  .
    if [ -e "${AQM_MOFILE_FHR_FP}" ]; then
      # File exists, perform "ls" or "touch" action
      ls "$AQM_MOFILE_FHR_FP"    # Replace this with your desired action
      echo "File exists: $AQM_MOFILE_FHR_FP"
    else
      # File doesn't exist, try rechecking the file with waiting mechanism
      if check_file_with_recheck "$AQM_MOFILE_FHR_FP"; then
        # File found after recheck, perform "ls" or "touch" action
	ls "$AQM_MOFILE_FHR_FP"    # Replace this with your desired action
	echo "File exists after recheck: $AQM_MOFILE_FHR_FP"
       else
        # File not found even after rechecks
        echo "WARNING File was not found even after rechecks: $AQM_MOFILE_FHR_FP"
        
	GEFS_AERO_LBCS_CHECK="NO"
	 
        if [ "${EMAIL_SDM^^}" = "YES" ] ; then
          MAILFROM=${MAILFROM:-"nco.spa@noaa.gov"}
          #MAILTO=${MAILTO:-"sdm@noaa.gov"}
          MAILTO=${MAILTO:-"${maillist}"}
          subject="${cyc}Z ${RUN^^} Output for ${basinname:-} GEFS_AERO LBCS "
          mail.py -s "${subject}" -v "${MAILTO}" 
        fi

       fi
      fi
  done

  NUMTS="$(( FCST_LEN_HRS / LBC_SPEC_INTVL_HRS + 1 ))"

cat > gefs2lbc-nemsio.ini <<EOF
&control
 tstepdiff=${TSTEPDIFF}
 dtstep=${LBC_SPEC_INTVL_HRS}
 bndname='aothrj','aecj','aorgcj','asoil','numacc','numcor'
 mofile='${AQM_MOFILE_FP}','.nemsio'
 lbcfile='${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f','.nc'
 topofile='${OROG_DIR}/${CRES}_oro_data.tile7.halo4.nc'
&end

Species converting Factor
# Gocart ug/m3 to regional ug/m3
'dust1'    2  ## 0.2-2um diameter: assuming mean diameter is 0.3 um (volume= 0.01414x10^-18 m3) and density is 2.6x10^3 kg/m3 or 2.6x10^12 ug/m3.so 1 particle = 0.036x10^-6 ug
'aothrj'  1.0   'numacc' 27205909.
'dust2'    4  ## 2-4um
'aothrj'  0.45    'numacc'  330882.  'asoil'  0.55   'numcor'  50607.
'dust3'    2  ## 4-6um
'asoil'   1.0   'numcor' 11501.
'dust4'    2   ## 6-12um
'asoil'  0.7586   'numcor' 1437.
'bc1'      2     # kg/kg
'aecj'     1.0   'numacc' 6775815.
'bc2'  2     # kg/kg
'aecj'     1.0   'numacc' 6775815.
'oc1'  2     # kg/kg OC -> organic matter
'aorgcj'    1.0   'numacc' 6775815.
'oc2'  2
'aorgcj'  1.0   'numacc' 6775815.
EOF

  exec_fn="gefs2lbc_para"
  exec_fp="$EXECaqm/${exec_fn}"
  if [ ! -s "${exec_fp}" ]; then
    print_err_msg_exit "\
The executable (exec_fp) for GEFS LBCs does not exist:
  exec_fp = \"${exec_fp}\"
Please ensure that you've built this executable."
  fi
#
#----------------------------------------------------------------------
#
# Run the executable
#
#----------------------------------------------------------------------
#
 if [ ${GEFS_AERO_LBCS_CHECK} = "YES" ]; then    
  startmsg
  sync
   eval ${RUN_CMD_AQMLBC} ${exec_fp} ${REDIRECT_OUT_ERR} >> $pgmout 2>errfile
  export err=$?; err_chk
  if [ -e "${pgmout}" ]; then
   cat ${pgmout}
  fi
  cpreq -rp ${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f*.nc  ${INPUT_DATA}

  print_info_msg "
========================================================================
Successfully added GEFS aerosol LBCs !!!
========================================================================"
#
 else
  cpreq -rp ${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f*.nc  ${INPUT_DATA}

  print_info_msg "
========================================================================
 Failed to add GEFS aerosol LBCs due to missing GEFS LBCS ! 
========================================================================"
 fi
fi
#
print_info_msg "
========================================================================
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

