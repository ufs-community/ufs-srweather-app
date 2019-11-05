#
#-----------------------------------------------------------------------
#
# This file defines and then calls a function that sets the parameters
# for a grid that is to be generated using the "JPgrid" grid generation 
# method (i.e. GRID_GEN_METHOD set to "JPgrid").
#
#-----------------------------------------------------------------------
#
function set_gridparams_JPgrid() {
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
local scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
local scrfunc_fn=$( basename "${scrfunc_fp}" )
local scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Get the name of this function.
#
#-----------------------------------------------------------------------
#
local func_name="${FUNCNAME[0]}"
#
#-----------------------------------------------------------------------
#
# Source the file containing various mathematical, physical, etc cons-
# tants.
#
#-----------------------------------------------------------------------
#
. ${USHDIR}/constants.sh
echo
echo "pi_geom = $pi_geom"
echo "degs_per_radian = ${degs_per_radian}"
echo "radius_Earth = ${radius_Earth}"
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
DEL_ANGLE_X_SG=$( bc -l <<< "($DELX/(2.0*${radius_Earth}))*${degs_per_radian}" )
DEL_ANGLE_X_SG=$( printf "%0.10f\n" ${DEL_ANGLE_X_SG} )

DEL_ANGLE_Y_SG=$( bc -l <<< "($DELY/(2.0*${radius_Earth}))*${degs_per_radian}" )
DEL_ANGLE_Y_SG=$( printf "%0.10f\n" ${DEL_ANGLE_Y_SG} )

echo "DEL_ANGLE_X_SG = ${DEL_ANGLE_X_SG}"
echo "DEL_ANGLE_Y_SG = ${DEL_ANGLE_Y_SG}"

MNS_NX_T7_PLS_WIDE_HALO=$( bc -l <<< "-(${NX_T7} + 2*${NHW_T7})" )
MNS_NX_T7_PLS_WIDE_HALO=$( printf "%.0f\n" ${MNS_NX_T7_PLS_WIDE_HALO} )
echo "MNS_NX_T7_PLS_WIDE_HALO = ${MNS_NX_T7_PLS_WIDE_HALO}"

MNS_NY_T7_PLS_WIDE_HALO=$( bc -l <<< "-(${NY_T7} + 2*${NHW_T7})" )
MNS_NY_T7_PLS_WIDE_HALO=$( printf "%.0f\n" ${MNS_NY_T7_PLS_WIDE_HALO} )
echo "MNS_NY_T7_PLS_WIDE_HALO = ${MNS_NY_T7_PLS_WIDE_HALO}"

}
#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
set_gridparams_JPgrid

