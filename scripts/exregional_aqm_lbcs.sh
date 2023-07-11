#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. $USHdir/source_util_funcs.sh
source_config_for_task "task_get_extrn_lbcs|task_make_orog|task_make_lbcs|cpl_aqm_parm|task_aqm_lbcs" ${GLOBAL_VAR_DEFNS_FP}
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

if [ -z "${RUN_CMD_AQMLBC:-}" ] ; then
  print_err_msg_exit "\
  Run command was not set in machine file. \
  Please set RUN_CMD_AQM_LBC for your platform"
else
  print_info_msg "$VERBOSE" "
  All executables will be submitted with command \'${RUN_CMD_AQMLBC}\'."
fi
#
#-----------------------------------------------------------------------
#
# Add chemical LBCS
#
#-----------------------------------------------------------------------
#
CDATE_MOD=$( $DATE_UTIL --utc --date "${PDY} ${cyc} UTC - ${EXTRN_MDL_LBCS_OFFSET_HRS} hours" "+%Y%m%d%H" )
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

  chem_lbcs_fp=${DCOMINchem_lbcs}/${chem_lbcs_fn}
  if [ -f ${chem_lbcs_fp} ]; then
    #Copy the boundary condition file to the current location
    cp_vrfy ${chem_lbcs_fp} .
  else
    message_txt="The chemical LBC files do not exist:
    CHEM_BOUNDARY_CONDITION_FILE = \"${chem_lbcs_fp}\""
    if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
      err_exit "${message_txt}"
    else
      print_err_msg_exit "${message_txt}"
    fi
  fi

  for hr in 0 ${LBC_SPEC_FCST_HRS[@]}; do
    fhr=$( printf "%03d" "${hr}" )
    if [ -r ${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fhr}.nc ]; then
      ncks -A ${chem_lbcs_fn} ${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f${fhr}.nc
      export err=$?
      if [ $err -ne 0 ]; then
        message_txt="Call to NCKS returned with nonzero exit code."
        if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
          err_exit "${message_txt}"
        else
          print_err_msg_exit "${message_txt}"
        fi
      fi
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
    AQM_MOFILE_FP="${DCOMINgefs}/${yyyymmdd}/${AQM_GEFS_FILE_CYC}/${AQM_MOFILE_FN}"
  fi  

  # Check if GEFS aerosol files exist
  for hr in 0 ${LBC_SPEC_FCST_HRS[@]}; do
    hr_mod=$(( hr + EXTRN_MDL_LBCS_OFFSET_HRS ))
    fhr=$( printf "%03d" "${hr_mod}" )
    AQM_MOFILE_FHR_FP="${AQM_MOFILE_FP}${fhr}.nemsio"
    if [ ! -e "${AQM_MOFILE_FHR_FP}" ]; then
      message_txt="The GEFS file (AQM_MOFILE_FHR_FP) for LBCs of \"${cycle}\" does not exist:
  AQM_MOFILE_FHR_FP = \"${AQM_MOFILE_FHR_FP}\""
      if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
	message_warning="WARNING: ${message_txt}"
        print_info_msg "${message_warning}"
        if [ ! -z "${maillist}" ]; then
          echo "${message_warning}" | mail.py $maillist
        fi
      else
        print_err_msg_exit "${message_txt}"
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
 lbcfile='${INPUT_DATA}/${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f','.nc'
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
  exec_fp="$EXECdir/${exec_fn}"
  if [ ! -f "${exec_fp}" ]; then
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
  PREP_STEP
  eval ${RUN_CMD_AQMLBC} ${exec_fp} ${REDIRECT_OUT_ERR}
  export err=$?
  if [ "${RUN_ENVIR}" = "nco" ] && [ "${MACHINE}" = "WCOSS2" ]; then
    err_chk
  else
    if [ $err -ne 0 ]; then
      print_err_msg_exit "Call to executable (exec_fp) to generate chemical and 
GEFS LBCs file for RRFS-CMAQ failed:
  exec_fp = \"${exec_fp}\""
    fi
  fi
  POST_STEP

  print_info_msg "
========================================================================
Successfully added GEFS aerosol LBCs !!!
========================================================================"
#
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

