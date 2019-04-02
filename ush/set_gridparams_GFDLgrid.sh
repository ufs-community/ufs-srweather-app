# This file is always sourced by another script (i.e. it's never run in
# its own shell), so there's no need to put the #!/bin/some_shell on the
# first line.

#
#-----------------------------------------------------------------------
#
# The grid generation script grid_gen_scr called below in turn calls the
# make_hgrid utility/executable to construct the regional grid.  make_-
# hgrid accepts as arguments the index limits (i.e. starting and ending
# indices) of the regional grid on the supergrid of the regional grid's
# parent tile.  The regional grid's parent tile is tile 6, and the su-
# pergrid of any given tile is defined as the grid obtained by doubling
# the number of cells in each direction on that tile's grid.  We will
# denote these index limits by
#
#   istart_rgnl_T6SG
#   iend_rgnl_T6SG
#   jstart_rgnl_T6SG
#   jend_rgnl_T6SG
#
# The "_T6SG" suffix in these names is used to indicate that the indices
# are on the supergrid of tile 6.  Recall, however, that we have as in-
# puts the index limits of the regional grid on the tile 6 grid, not its
# supergrid.  These are given by
#
#   istart_rgnl_T6
#   iend_rgnl_T6
#   jstart_rgnl_T6
#   jend_rgnl_T6
#
# We can obtain the former from the latter by recalling that the super-
# grid has twice the resolution of the original grid.  Thus,
#
#   istart_rgnl_T6SG = 2*istart_rgnl_T6 - 1
#   iend_rgnl_T6SG = 2*iend_rgnl_T6
#   jstart_rgnl_T6SG = 2*jstart_rgnl_T6 - 1
#   jend_rgnl_T6SG = 2*jend_rgnl_T6
#
# These are obtained assuming that grid cells on tile 6 must either be
# completely within the regional domain or completely outside of it,
# i.e. the boundary of the regional grid must coincide with gridlines
# on the tile 6 grid; it cannot cut through tile 6 cells.  (Note that
# this implies that the starting indices on the tile 6 supergrid must be
# odd while the ending indices must be even; the above expressions sa-
# tisfy this requirement.)  We perfrom these calculations next.
#
#-----------------------------------------------------------------------
#
istart_rgnl_T6SG=$(( 2*$istart_rgnl_T6 - 1 ))
iend_rgnl_T6SG=$(( 2*$iend_rgnl_T6 ))
jstart_rgnl_T6SG=$(( 2*$jstart_rgnl_T6 - 1 ))
jend_rgnl_T6SG=$(( 2*$jend_rgnl_T6 ))
#
#-----------------------------------------------------------------------
#
# If we simply pass to make_hgrid the index limits of the regional grid
# on the tile 6 supergrid calculated above, make_hgrid will generate a
# regional grid without a halo.  To obtain a regional grid with a halo,
# we must pass to make_hgrid the index limits (on the tile 6 supergrid)
# of the regional grid including a halo.  We will let the variables
#
#   istart_rgnl_wide_halo_T6SG
#   iend_rgnl_wide_halo_T6SG
#   jstart_rgnl_wide_halo_T6SG
#   jend_rgnl_wide_halo_T6SG
#
# denote these limits.  The reason we include "_wide_halo" in these va-
# riable names is that the halo of the grid that we will first generate
# will be wider than the halos that are actually needed as inputs to the
# FV3SAR model (i.e. the 0-cell-wide, 3-cell-wide, and 4-cell-wide halos
# described above).  We will generate the grids with narrower halos that
# the model needs later on by "shaving" layers of cells from this wide-
# halo grid.  Next, we describe how to calculate the above indices.
#
# Let nhw_T7 denote the width of the "wide" halo in units of number of
# grid cells on the regional grid (i.e. tile 7) that we'd like to have
# along all four edges of the regional domain (left, right, bottom, and
# top).  To obtain the corresponding halo width in units of number of
# cells on the tile 6 grid -- which we denote by nhw_T6 -- we simply di-
# vide nhw_T7 by the refinement ratio, i.e.
#
#   nhw_T6 = nhw_T7/refine_ratio
#
# The corresponding halo width on the tile 6 supergrid is then given by
#
#   nhw_T6SG = 2*nhw_T6
#            = 2*nhw_T7/refine_ratio
#
# Note that nhw_T6SG must be an integer, but the expression for it de-
# rived above may not yield an integer.  To ensure that the halo has a
# width of at least nhw_T7 cells on the regional grid, we round up the
# result of the expression above for nhw_T6SG, i.e. we redefine nhw_T6SG
# to be
#
#   nhw_T6SG = ceil(2*nhw_T7/refine_ratio)
#
# where ceil(...) is the ceiling function, i.e. it rounds its floating
# point argument up to the next larger integer.  Since in bash division
# of two integers returns a truncated integer and since bash has no
# built-in ceil(...) function, we perform the rounding-up operation by
# adding the denominator (of the argument of ceil(...) above) minus 1 to
# the original numerator, i.e. by redefining nhw_T6SG to be
#
#   nhw_T6SG = (2*nhw_T7 + refine_ratio - 1)/refine_ratio
#
# This trick works when dividing one positive integer by another.
#
# In order to calculate nhw_T6G using the above expression, we must
# first specify nhw_T7.  Next, we specify an initial value for it by
# setting it to one more than the largest-width halo that the model ac-
# tually needs, which is nh4_T7.  We then calculate nhw_T6SG using the
# above expression.  Note that these values of nhw_T7 and nhw_T6SG will
# likely not be their final values; their final values will be calcula-
# ted later below after calculating the starting and ending indices of
# the regional grid with wide halo on the tile 6 supergrid and then ad-
# justing the latter to satisfy certain conditions.
#
#-----------------------------------------------------------------------
#
nhw_T7=$(( $nh4_T7 + 1 ))
nhw_T6SG=$(( (2*nhw_T7 + refine_ratio - 1)/refine_ratio ))
#
#-----------------------------------------------------------------------
#
# With an initial value of nhw_T6SG now available, we can obtain the
# tile 6 supergrid index limits of the regional domain (including the
# wide halo) from the index limits for the regional domain without a ha-
# lo by simply subtracting nhw_T6SG from the lower index limits and add-
# ing nhw_T6SG to the upper index limits, i.e.
#
#   istart_rgnl_wide_halo_T6SG = istart_rgnl_T6SG - nhw_T6SG
#   iend_rgnl_wide_halo_T6SG = iend_rgnl_T6SG + nhw_T6SG
#   jstart_rgnl_wide_halo_T6SG = jstart_rgnl_T6SG - nhw_T6SG
#   jend_rgnl_wide_halo_T6SG = jend_rgnl_T6SG + nhw_T6SG
#
# We calculate these next.
#
#-----------------------------------------------------------------------
#
istart_rgnl_wide_halo_T6SG=$(( $istart_rgnl_T6SG - $nhw_T6SG ))
iend_rgnl_wide_halo_T6SG=$(( $iend_rgnl_T6SG + $nhw_T6SG ))
jstart_rgnl_wide_halo_T6SG=$(( $jstart_rgnl_T6SG - $nhw_T6SG ))
jend_rgnl_wide_halo_T6SG=$(( $jend_rgnl_T6SG + $nhw_T6SG ))
#
#-----------------------------------------------------------------------
#
# As for the regional grid without a halo, the regional grid with a wide
# halo that make_hgrid will generate must be such that grid cells on
# tile 6 either lie completely within this grid or outside of it, i.e.
# they cannot lie partially within/outside of it.  This implies that the
# starting indices on the tile 6 supergrid of the grid with wide halo
# must be odd while the ending indices must be even.  Thus, below, we
# subtract 1 from the starting indices if they are even (which ensures
# that there will be at least nhw_T7 halo cells along the left and bot-
# tom boundaries), and we add 1 to the ending indices if they are odd
# (which ensures that there will be at least nhw_T7 halo cells along the
# right and top boundaries).
#
#-----------------------------------------------------------------------
#
if [ $(( istart_rgnl_wide_halo_T6SG%2 )) -eq 0 ]; then
  istart_rgnl_wide_halo_T6SG=$(( istart_rgnl_wide_halo_T6SG - 1 ))
fi
if [ $(( iend_rgnl_wide_halo_T6SG%2 )) -eq 1 ]; then
  iend_rgnl_wide_halo_T6SG=$(( iend_rgnl_wide_halo_T6SG + 1 ))
fi

if [ $(( jstart_rgnl_wide_halo_T6SG%2 )) -eq 0 ]; then
  jstart_rgnl_wide_halo_T6SG=$(( jstart_rgnl_wide_halo_T6SG - 1 ))
fi
if [ $(( jend_rgnl_wide_halo_T6SG%2 )) -eq 1 ]; then
  jend_rgnl_wide_halo_T6SG=$(( jend_rgnl_wide_halo_T6SG + 1 ))
fi
#
#-----------------------------------------------------------------------
#
# Save the current shell options and temporarily turn off the xtrace op-
# tion to prevent clutter in stdout.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Now that the starting and ending tile 6 supergrid indices of the re-
# gional grid with the wide halo have been calculated (and adjusted), we
# recalculate the width of the wide halo on:
#
# 1) the tile 6 supergrid;
# 2) the tile 6 grid; and
# 3) the tile 7 grid.
#
# These are the final values of these quantities that are guaranteed to
# correspond to the starting and ending indices on the tile 6 supergrid.
#
#-----------------------------------------------------------------------
#
print_info_msg_verbose "\
Original values of the halo width on the tile 6 supergrid and on the 
tile 7 grid are:
  nhw_T6SG = $nhw_T6SG
  nhw_T7   = $nhw_T7"

nhw_T6SG=$(( $istart_rgnl_T6SG - $istart_rgnl_wide_halo_T6SG ))
nhw_T6=$(( $nhw_T6SG/2 ))
nhw_T7=$(( $nhw_T6*$refine_ratio ))

print_info_msg_verbose "\
Values of the halo width on the tile 6 supergrid and on the tile 7 grid 
AFTER adjustments are:
  nhw_T6SG = $nhw_T6SG
  nhw_T7   = $nhw_T7"
#
#-----------------------------------------------------------------------
#
# Calculate the number of cells that the regional domain (without halo)
# has in each of the two horizontal directions (say x and y).  We denote
# these by nx_T7 and ny_T7, respectively.  These will be needed in the
# "shave" steps later below.
#
#-----------------------------------------------------------------------
#
nx_rgnl_T6SG=$(( $iend_rgnl_T6SG - $istart_rgnl_T6SG + 1 ))
nx_rgnl_T6=$(( $nx_rgnl_T6SG/2 ))
nx_T7=$(( $nx_rgnl_T6*$refine_ratio ))

ny_rgnl_T6SG=$(( $jend_rgnl_T6SG - $jstart_rgnl_T6SG + 1 ))
ny_rgnl_T6=$(( $ny_rgnl_T6SG/2 ))
ny_T7=$(( $ny_rgnl_T6*$refine_ratio ))
#
# The following are set only for informational purposes.
#
nx_T6=$RES
ny_T6=$RES
nx_T6SG=$(( $nx_T6*2 ))
ny_T6SG=$(( $ny_T6*2 ))

prime_factors_nx_T7=$( factor $nx_T7 | sed -r -e 's/^[0-9]+: (.*)/\1/' )
prime_factors_ny_T7=$( factor $ny_T7 | sed -r -e 's/^[0-9]+: (.*)/\1/' )

print_info_msg_verbose "\
The number of cells in the two horizontal directions (x and y) on the 
parent tile's (tile 6) grid and supergrid are:
  nx_T6 = $nx_T6
  ny_T6 = $ny_T6
  nx_T6SG = $nx_T6SG
  ny_T6SG = $ny_T6SG

The number of cells in the two horizontal directions on the tile 6 grid
and supergrid that the regional domain (tile 7) WITHOUT A HALO encompasses
are:
  nx_rgnl_T6 = $nx_rgnl_T6
  ny_rgnl_T6 = $ny_rgnl_T6
  nx_rgnl_T6SG = $nx_rgnl_T6SG
  ny_rgnl_T6SG = $ny_rgnl_T6SG

The starting and ending i and j indices on the tile 6 grid used to 
generate this regional grid are:
  istart_rgnl_T6 = $istart_rgnl_T6
  iend_rgnl_T6   = $iend_rgnl_T6
  jstart_rgnl_T6 = $jstart_rgnl_T6
  jend_rgnl_T6   = $jend_rgnl_T6

The corresponding starting and ending i and j indices on the tile 6 
supergrid are:
  istart_rgnl_T6SG = $istart_rgnl_T6SG
  iend_rgnl_T6SG   = $iend_rgnl_T6SG
  jstart_rgnl_T6SG = $jstart_rgnl_T6SG
  jend_rgnl_T6SG   = $jend_rgnl_T6SG

The refinement ratio (ratio of the number of cells in tile 7 that abut
a single cell in tile 6) is:
  refine_ratio = $refine_ratio

The number of cells in the two horizontal directions on the regional 
tile's/domain's (tile 7) grid WITHOUT A HALO are:
  nx_T7 = $nx_T7
  ny_T7 = $ny_T7

The prime factors of nx_T7 and ny_T7 are (useful for determining an MPI
task layout, i.e. layout_x and layout_y):
  prime_factors_nx_T7: $prime_factors_nx_T7
  prime_factors_ny_T7: $prime_factors_ny_T7"
#
#-----------------------------------------------------------------------
#
# For informational purposes, calculate the number of cells in each di-
# rection on the regional grid that includes the wide halo (of width
# nhw_T7 cells).  We denote these by nx_wide_halo_T7 and ny_wide_halo_-
# T7, respectively.
#
#-----------------------------------------------------------------------
#
nx_wide_halo_T6SG=$(( $iend_rgnl_wide_halo_T6SG - $istart_rgnl_wide_halo_T6SG + 1 ))
nx_wide_halo_T6=$(( $nx_wide_halo_T6SG/2 ))
nx_wide_halo_T7=$(( $nx_wide_halo_T6*$refine_ratio ))

ny_wide_halo_T6SG=$(( $jend_rgnl_wide_halo_T6SG - $jstart_rgnl_wide_halo_T6SG + 1 ))
ny_wide_halo_T6=$(( $ny_wide_halo_T6SG/2 ))
ny_wide_halo_T7=$(( $ny_wide_halo_T6*$refine_ratio ))

print_info_msg_verbose "\
nx_wide_halo_T7 = $nx_T7 \
(istart_rgnl_wide_halo_T6SG = $istart_rgnl_wide_halo_T6SG, \
iend_rgnl_wide_halo_T6SG = $iend_rgnl_wide_halo_T6SG)"

print_info_msg_verbose "\
ny_wide_halo_T7 = $ny_T7 \
(jstart_rgnl_wide_halo_T6SG = $jstart_rgnl_wide_halo_T6SG, \
jend_rgnl_wide_halo_T6SG = $jend_rgnl_wide_halo_T6SG)"
#
#-----------------------------------------------------------------------
#
# Restore the shell options before turning off xtrace.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1



