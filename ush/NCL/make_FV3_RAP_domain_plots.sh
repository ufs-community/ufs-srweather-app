#!/bin/sh

set -eux

module load ncl/6.4.0

#NCARG_ROOT="/scratch4/BMC/fim/Gerard.Ketefian/ncl_stuff/ncl_ncarg-6.4.0-28Jun2016_0233.Linux_RHEL6.4_x86_64_gcc447"
#NCARG_ROOT="/scratch4/BMC/fim/Gerard.Ketefian/ncl_stuff/ncl_ncarg-6.4.0-RHEL6.4_64bit_nodap_gnu447"
#alias ncl="$NCARG_ROOT/bin/ncl"


#ncl plot_grid_simple.ncl
#exit



RES="96"
#RES="384"

CRES="C${RES}"

#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/${CRES}r7.n3_regional_RAP/grid"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/${CRES}r0p7n3_regional_RAP/grid"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/C384r0p7n2_regional_RAP/grid"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/C384r0p7n3_regional_RAP/grid"
grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/C96r1p5n3_regional_AAAAA/grid"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_FV3_regional_C96_2018032900/INPUT"

RAP_grid_fn="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/geo_em.d01.nc"


if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a cylindrical projection.
#
ncl -n plot_grid.ncl \
  grid_dir=\"$grid_dir\" \
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
mv ${CRES}_grid.png ${CRES}rgnl_grid_size_and_RAP_domain_cyln.png
fi


if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a sphere (orthogonal spherical projection).
#
ncl -n plot_grid.ncl \
  grid_dir=\"$grid_dir\" \
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
mv ${CRES}_grid.png ${CRES}rgnl_grid_size_and_RAP_domain_sphr.png
fi


if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a sphere (orthogonal spherical projection).
#
ncl -n plot_grid.ncl \
  grid_dir=\"$grid_dir\" \
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
mv ${CRES}_grid.png ${CRES}rgnl_and_RAP_gridlines_cyln_closeup.png
fi












if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a cylindrical projection.
#
ncl -n plot_grid.ncl \
  grid_dir=\"$grid_dir\" \
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
mv ${CRES}_grid.png ${CRES}rgnl_RAP_grids_cyln.png

fi


if [ 0 = 1 ]; then
#
#
ncl -n plot_grid.ncl \
  grid_dir=\"$grid_dir\" \
  res=${RES} \
  tile_inds=\(/7/\) \
  draw_tile_bdy=False \
  draw_tile_grid=False \
  draw_RAP_domain=True \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=True \
  draw_RAP_grid=True \
  map_proj=\"cyln\" \
  subreg=\(/-130,-60,25,55/\) \
  graphics_type=\"png\"
#
mv ${CRES}_grid.png ${CRES}rgnl_RAP_grids_cyln_subreg_CONUS.png

fi

if [ 1 = 1 ]; then
#
ncl -n plot_grid.ncl \
  grid_dir=\"$grid_dir\" \
  res=${RES} \
  tile_inds=\(/6/\) \
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
#mv ${CRES}_grid.png ${CRES}rgnl_RAP_grids_cyln_subreg.png
mv ${CRES}_grid.png ${CRES}rgnl_RAP_grids_cyln.png

fi



if [ 0 = 1 ]; then
#
ncl -n plot_grid_Curtis.ncl \
  grid_dir=\"$grid_dir\" \
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
#mv ${CRES}_grid.png ${CRES}rgnl_RAP_grids_cyln_subreg.png
mv ${CRES}_grid.png ${CRES}rgnl_RAP_grids_cyln.png

fi





if [ 0 = 1 ]; then
ncl -n plot_grid.ncl \
    'grid_dir="./some_dir/grid"' \
    'res=96' \
    'tile_inds=(/1,2,3/)' \
    'draw_tile_bdy=True' \
    'draw_tile_grid=True' \
    'draw_RAP_domain=True' \
    'RAP_grid_fn="./some_dir/RAP_grid.nc"' \
    'draw_RAP_bdy=True' \
    'draw_RAP_grid=True' \
    'map_proj="cyln"' \
    'map_proj_ctr=(/0,90/)' \
    'subreg=(/-30,30,-25,25/)' \
    'graphics_type="ncgm"'
fi




