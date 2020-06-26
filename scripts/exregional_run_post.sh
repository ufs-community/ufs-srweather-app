#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHDIR/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
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

This is the ex-script for the task that runs the post-processor (UPP) on
the output files corresponding to a specified forecast hour.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
"cycle_dir" \
"postprd_dir" \
"fhr_dir" \
"fhr" \
)
process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Starting post-processing for fhr = $fhr hr..."

case $MACHINE in

"WCOSS_CRAY")

# Specify computational resources.
  export NODES=2
  export ntasks=48
  export ptile=24
  export threads=1
  export MP_LABELIO=yes
  export OMP_NUM_THREADS=$threads

  APRUN="aprun -j 1 -n${ntasks} -N${ptile} -d${threads} -cc depth"
  ;;

"WCOSS_DELL_P3")

# Specify computational resources.
  export NODES=2
  export ntasks=48
  export ptile=24
  export threads=1
  export MP_LABELIO=yes
  export OMP_NUM_THREADS=$threads
 
  APRUN="mpirun"
  ;;

"HERA")
  APRUN="srun"
  ;;

"JET")
  APRUN="srun"
  ;;

"ODIN")
  APRUN="srun -n 1"
  ;;

"CHEYENNE")
  module list
  nprocs=$(( NNODES_RUN_POST*PPN_RUN_POST ))
  APRUN="mpirun -np $nprocs"
  ;;

"STAMPEDE")
  nprocs=$(( NNODES_RUN_POST*PPN_RUN_POST ))
  APRUN="ibrun -n $nprocs"
  ;;

esac
#
#-----------------------------------------------------------------------
#
# Remove any files from previous runs and stage necessary files in fhr_dir.
#
#-----------------------------------------------------------------------
#
rm_vrfy -f fort.*
cp_vrfy $FIXupp/nam_micro_lookup.dat ./eta_micro_lookup.dat
cp_vrfy $FIXupp/postxconfig-NT-fv3sar.txt ./postxconfig-NT.txt
cp_vrfy $FIXupp/params_grib2_tbl_new ./params_grib2_tbl_new
cp_vrfy ${EXECDIR}/ncep_post .
#
#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respect-
# ively) from CDATE.
#
#-----------------------------------------------------------------------
#
yyyymmdd=${CDATE:0:8}
hh=${CDATE:8:2}
cyc=$hh
tmmark="tm$hh"
#
#-----------------------------------------------------------------------
#
# Create a text file (itag) containing arguments to pass to the post-
# processing executable.
#
#-----------------------------------------------------------------------
#
dyn_file="${cycle_dir}/dynf0${fhr}.nc"
phy_file="${cycle_dir}/phyf0${fhr}.nc"

#POST_TIME=$( ${NDATE} +${fhr} ${CDATE} )
POST_TIME=$( date --utc --date "${yyyymmdd} ${hh} UTC + ${fhr} hours" "+%Y%m%d%H" )
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
#
#-----------------------------------------------------------------------
#
# Copy the UPP executable to fhr_dir and run the post-processor.
#
#-----------------------------------------------------------------------
#
${APRUN} ./ncep_post < itag || print_err_msg_exit "\
Call to executable to run post for forecast hour $fhr returned with non-
zero exit code."
#
#-----------------------------------------------------------------------
#
# Move (and rename) the output files from the work directory to their
# final location (postprd_dir).  Then delete the work directory. 
#
#-----------------------------------------------------------------------
#
if [ -n "${PREDEF_GRID_NAME}" ]; then 

  grid_name="${PREDEF_GRID_NAME}"

else 

  grid_name="${GRID_GEN_METHOD}"

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then
    stretch_str="S$( printf "%s" "${STRETCH_FAC}" | sed "s|\.|p|" )"
    refine_str="RR${GFDLgrid_REFINE_RATIO}"
    grid_name="${grid_name}_${CRES}_${stretch_str}_${refine_str}"
  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then
    nx_str="NX$( printf "%s" "$NX" | sed "s|\.|p|" )"
    ny_str="NY$( printf "%s" "$NY" | sed "s|\.|p|" )"
    JPgrid_alpha_param_str="A"$( printf "%s" "${JPgrid_ALPHA_PARAM}" | \
                                 sed "s|-|mns|" | sed "s|\.|p|" )
    JPgrid_kappa_param_str="K"$( printf "%s" "${JPgrid_KAPPA_PARAM}" | \
                                 sed "s|-|mns|" | sed "s|\.|p|" )
    grid_name="${grid_name}_${nx_str}_${ny_str}_${JPgrid_alpha_param_str}_${JPgrid_kappa_param_str}"
  fi

fi

mv_vrfy BGDAWP.GrbF${fhr} ${postprd_dir}/RRFS.t${cyc}z.bgdawp${fhr}.${tmmark}
mv_vrfy BGRD3D.GrbF${fhr} ${postprd_dir}/RRFS.t${cyc}z.bgrd3d${fhr}.${tmmark}

#Link output for transfer to Jet

START_DATE=`echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/'`
basetime=`date +%y%j%H%M -d "${START_DATE}"`
ln_vrfy -fs ${postprd_dir}/RRFS.t${cyc}z.bgdawp${fhr}.${tmmark} \
            ${postprd_dir}/BGDAWP_${basetime}${fhr}00
ln_vrfy -fs ${postprd_dir}/RRFS.t${cyc}z.bgrd3d${fhr}.${tmmark} \
            ${postprd_dir}/BGRD3D_${basetime}${fhr}00

rm_vrfy -rf ${fhr_dir}
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Post-processing for forecast hour $fhr completed successfully.

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

