#!/usr/bin/env bash

set -xue
#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${PARMsrw}/source_util_funcs.sh
task_global_vars=( "AQM_GEFS_FILE_CYC" "AQM_GEFS_FILE_PREFIX" \
  "AQM_LBCS_FILES" "CRES" "DATE_FIRST_CYCL" "DO_AQM_CHEM_LBCS" \
  "DO_AQM_GEFS_LBCS" "DO_REAL_TIME" "EXTRN_MDL_LBCS_OFFSET_HRS" \
  "FCST_LEN_CYCL" "FCST_LEN_HRS" "FIXaqm" "INCR_CYCL_FREQ" \
  "LBC_SPEC_INTVL_HRS" "MACHINE" "OMP_NUM_THREADS_MAKE_LBCS" \
  "OROG_DIR" "PRE_TASK_CMDS" "RUN_CMD_AQMLBC" )
for var in ${task_global_vars[@]}; do
  source_config_for_task ${var} ${GLOBAL_VAR_DEFNS_FP}
done
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
#{ save_shell_opts; set -xue; } > /dev/null 2>&1
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
export KMP_AFFINITY="scatter"
export OMP_NUM_THREADS=${OMP_NUM_THREADS_MAKE_LBCS}
export OMP_STACKSIZE="1024m"
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
  print_info_msg "All executables will be submitted with \'${RUN_CMD_AQMLBC}\'."
fi
#
#-----------------------------------------------------------------------
#
# Add chemical LBCS
#
#-----------------------------------------------------------------------
#
CDATE_MOD=`$NDATE -${EXTRN_MDL_LBCS_OFFSET_HRS} ${PDY}${cyc}`
YYYYMMDD="${CDATE_MOD:0:8}"
MM="${CDATE_MOD:4:2}"
HH="${CDATE_MOD:8:2}"

if [ ${#FCST_LEN_CYCL[@]} -gt 1 ]; then
  cyc_mod=$(( ${cyc} - ${DATE_FIRST_CYCL:8:2} ))
  CYCLE_IDX=$(( ${cyc_mod} / ${INCR_CYCL_FREQ} ))
  FCST_LEN_HRS=${FCST_LEN_CYCL[$CYCLE_IDX]}
fi
LBC_SPEC_FCST_HRS=()
for i_lbc in $(seq ${LBC_SPEC_INTVL_HRS} ${LBC_SPEC_INTVL_HRS} ${FCST_LEN_HRS} ); do
  LBC_SPEC_FCST_HRS+=("$i_lbc")
done

# Copy lbcs files from DATA_SHARE
aqm_lbcs_fn_prefix="${NET}.${cycle}${dot_ensmem}.gfs_bndy.tile7.f"
for hr in 0 ${LBC_SPEC_FCST_HRS[@]}; do
  fhr=$( printf "%03d" "${hr}" )
  aqm_lbcs_fn="${aqm_lbcs_fn_prefix}${fhr}.nc"
  cp -p "${DATA_SHARE}/${aqm_lbcs_fn}" ${DATA}
done

if [ $(boolify "${DO_AQM_CHEM_LBCS}") = "TRUE" ]; then
  ext_lbcs_file="${AQM_LBCS_FILES}"
  chem_lbcs_fn=${ext_lbcs_file//<MM>/${MM}}
  chem_lbcs_fp="${FIXaqm}/chemlbc/${chem_lbcs_fn}"
  if [ -f ${chem_lbcs_fp} ]; then
    #Copy the boundary condition file to the current location
    cp -p ${chem_lbcs_fp} .
  else
    message_txt="The chemical LBC files do not exist:
    CHEM_BOUNDARY_CONDITION_FILE = \"${chem_lbcs_fp}\""
    err_exit "${message_txt}"
    print_err_msg_exit "${message_txt}"
  fi

  for hr in 0 ${LBC_SPEC_FCST_HRS[@]}; do
    fhr=$( printf "%03d" "${hr}" )
    aqm_lbcs_fn="${aqm_lbcs_fn_prefix}${fhr}.nc"
    if [ -r "${aqm_lbcs_fn}" ]; then
      ncks -A ${chem_lbcs_fn} ${aqm_lbcs_fn}
      export err=$?
      if [ $err -ne 0 ]; then
        message_txt="Call to NCKS returned with nonzero exit code."
        err_exit "${message_txt}"
        print_err_msg_exit "${message_txt}"
      fi
      cp -p ${aqm_lbcs_fn} "${aqm_lbcs_fn}_chemlbc"
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
if [ $(boolify "${DO_AQM_GEFS_LBCS}") = "TRUE" ]; then
  AQM_GEFS_FILE_CYC=${AQM_GEFS_FILE_CYC:-"${HH}"}
  AQM_GEFS_FILE_CYC=$( printf "%02d" "${AQM_GEFS_FILE_CYC}" )

  gefs_cyc_diff=$(( cyc - AQM_GEFS_FILE_CYC ))
  if [ "${YYYYMMDD}" = "${PDY}" ]; then
    tstepdiff=$( printf "%02d" ${gefs_cyc_diff} )
  else
    tstepdiff=$( printf "%02d" $(( 24 + ${gefs_cyc_diff} )) )
  fi

  aqm_mofile_fn="${AQM_GEFS_FILE_PREFIX}.t${AQM_GEFS_FILE_CYC}z.atmf"
  if [ $(boolify "${DO_REAL_TIME}") = "TRUE" ]; then
    aqm_mofile_fp="${COMINgefs}/gefs.${YYYYMMDD}/${AQM_GEFS_FILE_CYC}/chem/sfcsig/${aqm_mofile_fn}"
  else
    aqm_mofile_fp="${COMINgefs}/${YYYYMMDD}/${AQM_GEFS_FILE_CYC}/${aqm_mofile_fn}"
  fi  

  # Check if GEFS aerosol files exist
  for hr in 0 ${LBC_SPEC_FCST_HRS[@]}; do
    hr_mod=$(( hr + EXTRN_MDL_LBCS_OFFSET_HRS ))
    fhr=$( printf "%03d" "${hr_mod}" )
    aqm_mofile_fhr_fp="${aqm_mofile_fp}${fhr}.nemsio"
    if [ ! -e "${aqm_mofile_fhr_fp}" ]; then
      message_txt="WARNING: The GEFS file (AQM_MOFILE_FHR_FP) for LBCs of \"${cycle}\" does not exist:
  aqm_mofile_fhr_fp = \"${aqm_mofile_fhr_fp}\""
      if [ ! -z "${MAILTO}" ] && [ "${MACHINE}" = "WCOSS2" ]; then
        echo "${message_txt}" | mail.py $maillist
      else
        print_err_msg_exit "${message_txt}"
      fi
    fi
  done

  numts="$(( FCST_LEN_HRS / LBC_SPEC_INTVL_HRS + 1 ))"

cat > gefs2lbc-nemsio.ini <<EOF
&control
 tstepdiff=${tstepdiff}
 dtstep=${LBC_SPEC_INTVL_HRS}
 bndname='aothrj','aecj','aorgcj','asoil','numacc','numcor'
 mofile='${aqm_mofile_fp}','.nemsio'
 lbcfile='${DATA}/${aqm_lbcs_fn_prefix}','.nc'
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

#
#----------------------------------------------------------------------
#
# Run the executable
#
#----------------------------------------------------------------------
#
  export pgm="gefs2lbc_para"

  . prep_step
  eval ${RUN_CMD_AQMLBC} -n ${numts} ${EXECsrw}/$pgm >>$pgmout 2>errfile
  export err=$?; err_chk

  print_info_msg "
========================================================================
Successfully added GEFS aerosol LBCs !!!
========================================================================"
fi

for hr in 0 ${LBC_SPEC_FCST_HRS[@]}; do
  fhr=$( printf "%03d" "${hr}" )
  aqm_lbcs_fn="${aqm_lbcs_fn_prefix}${fhr}.nc"
  cp -p "${DATA}/${aqm_lbcs_fn}" ${COMOUT}
done
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
#{ restore_shell_opts; } > /dev/null 2>&1
