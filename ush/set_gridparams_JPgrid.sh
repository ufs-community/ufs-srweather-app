# This file is always sourced by another script (i.e. it's never run in
# its own shell), so there's no need to put the #!/bin/some_shell on the
# first line.

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


