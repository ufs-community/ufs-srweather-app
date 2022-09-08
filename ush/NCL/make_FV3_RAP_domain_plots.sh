#!/bin/sh -l
#==========================================================================
# Description: This script runs plot_fields.ncl and sets all of the command-
#              line arguments.  There are 6 examples.  The default plot is at
#              the bottom on this file and plots FV3 output on a subregion over
#              CONUS with an outline of the RAP boundary.  Parameters that should
#              be modified by the user at the top of this script are:
#
#                 base_name         # Root name of the FV3 netcdf output file
#                                   # .tile[n].nc will be appended in the ncl script
#                 grid_dir          # The location of your input file
#                 fields            # A field to plot from base_name
#                 nlev              # A vertical level for (time,x,y,x) fields
#                 fcst_index        # A time index to plot
#
#              There is more documentation at the top of plot_fields.ncl and
#              in the README file.
#
# Usage: ./make_FV3_RAP_domain_plots.sh
#==========================================================================

set -eux

module load intel
module load ncl/6.4.0

RES="96"
#RES="384"

CRES="C${RES}"

#base_name="atmos_4xdaily"         # Base name of the FV3 output file, .tile[n].nc will be appended
#fields='"u1000", "v1000"'         # Fields to plot
base_name="nggps2d"         # Base name of the FV3 output file, .tile[n].nc will be appended
fields='"PWATclm", "HGTsfc"'         # Fields to plot
nlev="50"                         # Vertical index to plot for 3D fields
fcst_index="1,2"                    # Time index '2' or indices '1, 2' of forecast to plot or '"all"'
#fcst_index='"all"'                    # Time index '2' or indices '1, 2' of forecast to plot or '"all"'

grid_dir="/scratch2/BMC/gmtb/Julie.Schramm/C96fv3gfs2016092900/INPUT"

#RAP_grid_fn="/scratch2/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/geo_em.d01.nc"
RAP_grid_fn="/scratch2/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/geo_em.d01.RAP.nc"

if [ 1 = 1 ]; then
#
# Show FV3 global domain (tiles 1-6) on a global cylindrical projection.
#
ncl -n plot_fields.ncl \
  grid_dir=\"$grid_dir\" \
  base_name=\"$base_name\" \
  fields=\(\/"$fields"/\) \
  nlev=${nlev} \
  fcst_index=\(/${fcst_index}/\) \
  res=${RES} \
  tile_inds=\(/1,2,3,4,5,6/\) \
  draw_tile_bdy=True \
  draw_tile_grid=False \
  draw_RAP_domain=False \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=False \
  draw_RAP_grid=False \
  map_proj=\"cyln\" \
  graphics_type=\"png\"
#
#  tile_inds=\(/4/\) \
fi

if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a global cylindrical projection.
#
ncl -n plot_fields.ncl \
  grid_dir=\"$grid_dir\" \
  base_name=\"$base_name\" \
  'fields=(/"u1000", "v1000"/)' \
  nlev=${nlev} \
  fcst_index=${fcst_index} \
  res=${RES} \
  tile_inds=\(/7/\) \
  draw_tile_bdy=True \
  draw_tile_grid=False \
  draw_RAP_domain=True \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=True \
  draw_RAP_grid=False \
  map_proj=\"cyln\" \
  graphics_type=\"png\"
#
fi

if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a sphere (orthogonal spherical projection).
#
ncl -n plot_fields.ncl \
  grid_dir=\"$grid_dir\" \
  base_name=\"$base_name\" \
  'fields=(/"u1000", "v1000"/)' \
  nlev=${nlev} \
  fcst_index=${fcst_index} \
  res=${RES} \
  tile_inds=\(/7/\) \
  draw_tile_bdy=True \
  draw_tile_grid=False \
  draw_RAP_domain=True \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=True \
  draw_RAP_grid=False \
  map_proj=\"ortho\" \
  map_proj_ctr=\(/-105,50/\) \
  graphics_type=\"png\"
#
fi

if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tiles 5,6,7) and the original RAP domain outline
# on a cylindrical projection.
#
ncl -n plot_fields.ncl \
  grid_dir=\"$grid_dir\" \
  base_name=\"$base_name\" \
  'fields=(/"u1000", "v1000"/)' \
  nlev=${nlev} \
  fcst_index=${fcst_index} \
  res=${RES} \
  tile_inds=\(/5,6,7/\) \
  draw_tile_bdy=True \
  draw_tile_grid=True \
  draw_RAP_domain=True \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=True \
  draw_RAP_grid=True \
  map_proj=\"cyln\" \
  subreg=\(/-47,-40,15,22/\) \
  graphics_type=\"png\"
#
fi

if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a global cylindrical projection (no subregion).
#
ncl -n plot_fields.ncl \
  grid_dir=\"$grid_dir\" \
  base_name=\"$base_name\" \
  'fields=(/"u1000", "v1000"/)' \
  nlev=${nlev} \
  fcst_index=${fcst_index} \
  res=${RES} \
  tile_inds=\(/7/\) \
  draw_tile_bdy=False \
  draw_tile_grid=False \
  draw_RAP_domain=True \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=True \
  draw_RAP_grid=False \
  map_proj=\"cyln\" \
  graphics_type=\"png\"
#

fi

if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a global cylindrical projection (no subregion). Drawing tile boundary
# and grid makes a black tile 7 over CONUS.
#
ncl -n plot_fields.ncl \
  grid_dir=\"$grid_dir\" \
  base_name=\"$base_name\" \
  'fields=(/"u1000", "v1000"/)' \
  nlev=${nlev} \
  fcst_index=${fcst_index} \
  res=${RES} \
  tile_inds=\(/7/\) \
  draw_tile_bdy=True \
  draw_tile_grid=True \
  draw_RAP_domain=False \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=True \
  draw_RAP_grid=False \
  map_proj=\"cyln\" \
  graphics_type=\"png\"
#  subreg=\(/-47,-40,15,22/\) \
#  tile_inds=\(/1,2,3,4,5,6/\) \
#  subreg=\(/-120,-70,20,70/\) \
#  subreg=\(/-150,-40,0,70/\) \
#  subreg=\(/-120,-70,20,70/\) \
#

fi

if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a subregional cylindrical projection centered over CONUS.
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a subregional cylindrical projection centered over CONUS.
#
ncl -n plot_fields.ncl \
  grid_dir=\"$grid_dir\" \
  base_name=\"$base_name\" \
  fields=\(\/"$fields"/\) \
  nlev=${nlev} \
  fcst_index=\(\/"$fcst_index"/\) \
  res=${RES} \
  tile_inds=\(/7/\) \
  draw_tile_bdy=True \
  draw_tile_grid=False \
  draw_RAP_domain=False \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=True \
  draw_RAP_grid=False \
  map_proj=\"cyln\" \
  subreg=\(/-135,-60,10,60/\) \
  graphics_type=\"png\"
#  subreg=\(/-47,-40,15,22/\) \
#  tile_inds=\(/1,2,3,4,5,6/\) \
#  subreg=\(/-120,-70,20,70/\) \
#  subreg=\(/-150,-40,0,70/\) \
#  subreg=\(/-120,-70,20,70/\) \
#

fi
