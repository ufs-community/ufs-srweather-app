#
#-----------------------------------------------------------------------
#
# Mathematical and physical constants.
#
#-----------------------------------------------------------------------
#

# Pi.
pi_geom="3.14159265358979323846264338327"

# Degrees per radian.
degs_per_radian=$( bc -l <<< "360.0/(2.0*${pi_geom})" )

# Radius of the Earth in meters.
radius_Earth="6371200.0"
#
#-----------------------------------------------------------------------
#
# Valid values that a user may set a boolean variable to (e.g. in the
# SRW App's experiment configuration file).
#
#-----------------------------------------------------------------------
#
valid_vals_BOOLEAN=("TRUE" "true" "YES" "yes" "FALSE" "false" "NO" "no")
#
#-----------------------------------------------------------------------
#
# Any regional model must be supplied lateral boundary conditions (in
# addition to initial conditions) to be able to perform a forecast.  In
# the FV3-LAM model, these boundary conditions (BCs) are supplied using
# a "halo" of grid cells around the regional domain that extend beyond
# the boundary of the domain.  The model is formulated such that along
# with files containing these BCs, it needs as input the following files
# (in NetCDF format):
#
# 1) A grid file that includes a halo of 3 cells beyond the boundary of
#    the domain.
# 2) A grid file that includes a halo of 4 cells beyond the boundary of
#    the domain.
# 3) A (filtered) orography file without a halo, i.e. a halo of width
#    0 cells.
# 4) A (filtered) orography file that includes a halo of 4 cells beyond
#    the boundary of the domain.
#
# Note that the regional grid is referred to as "tile 7" in the code.
# We will let:
#
# * NH0 denote the width (in units of number of cells on tile 7) of
#   the 0-cell-wide halo, i.e. NH0 = 0;
#
# * NH3 denote the width (in units of number of cells on tile 7) of
#   the 3-cell-wide halo, i.e. NH3 = 3; and
#
# * NH4 denote the width (in units of number of cells on tile 7) of
#   the 4-cell-wide halo, i.e. NH4 = 4.
#
# We define these variables next.
#
#-----------------------------------------------------------------------
#
NH0=0
NH3=3
NH4=4

