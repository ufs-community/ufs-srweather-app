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
echo "degs_per_radian = $degs_per_radian"
echo "radius_Earth = $radius_Earth"
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
del_angle_x_SG=$( bc -l <<< "($delx/(2.0*$radius_Earth))*$degs_per_radian" )
del_angle_x_SG=$( printf "%0.10f\n" $del_angle_x_SG )

del_angle_y_SG=$( bc -l <<< "($dely/(2.0*$radius_Earth))*$degs_per_radian" )
del_angle_y_SG=$( printf "%0.10f\n" $del_angle_y_SG )

echo "del_angle_x_SG = $del_angle_x_SG"
echo "del_angle_y_SG = $del_angle_y_SG"

mns_nx_T7_pls_wide_halo=$( bc -l <<< "-($nx_T7 + 2*$nhw_T7)" )
mns_nx_T7_pls_wide_halo=$( printf "%.0f\n" $mns_nx_T7_pls_wide_halo )
echo "mns_nx_T7_pls_wide_halo = $mns_nx_T7_pls_wide_halo"

mns_ny_T7_pls_wide_halo=$( bc -l <<< "-($ny_T7 + 2*$nhw_T7)" )
mns_ny_T7_pls_wide_halo=$( printf "%.0f\n" $mns_ny_T7_pls_wide_halo )
echo "mns_ny_T7_pls_wide_halo = $mns_ny_T7_pls_wide_halo"

}
#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
set_gridparams_JPgrid

