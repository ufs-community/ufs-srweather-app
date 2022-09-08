#!/bin/bash

set -eux

module load intel
module load ncl/6.4.0

#RES="96"
RES="384"

CRES="C${RES}"

#CDATE=2018-08-09_03_00_00.RAP
CDATE="2018080903"

fcst_len_hrs="0"

BC_interval_hrs="3"

plot_RAP_fields="True"
#plot_RAP_fields="False"

plot_FV3LAM_fields="True"
#plot_FV3LAM_fields="False"

#grid_dir="/scratch3/BMC/det/beck/FV3-CAM/work.C384r0p7n3_regional_RAP/INPUT"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_FV3_regional_C96_2018032900/INPUT"
#grid_dir="/scratch3/BMC/fim/Julie.Schramm/regional_FV3_EMC_visit_20180509/work_FV3_regional_C96_2018032900/INPUT"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_FV3_regional_C96_2018032900/INPUT"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/rgnl_C384_strch_1p5_rfn_3_HRRR/grid"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/rgnl_C384_strch_2p0_rfn_3_HRRR/grid"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/rgnl_C384_strch_1p8_rfn_3_HRRR/grid"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/rgnl_C384_strch_1p8_rfn_5_HRRR/grid"
#grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/rgnl_C384_strch_0p7_rfn_3_test_all/grid"
grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/rgnl_C384_strch_1p5_rfn_3_descriptive_str/filter_topo"
grid_dir="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/C384_S0p63_RR3_RAP_new_chgres_fv3sar07/shave"

RAP_grid_fn="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/geo_em.d01.RAP.nc"
#RAP_grid_fn="/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/geo_em.d01.HRRR.nc"

if [ 1 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a cylindrical projection.
#
ncl -n generate_RAP_based_ICs_BCs.ncl \
  CDATE=${CDATE} \
  fcst_len_hrs=${fcst_len_hrs} \
  BC_interval_hrs=${BC_interval_hrs} \
  plot_RAP_fields=${plot_RAP_fields} \
  plot_FV3LAM_fields=${plot_FV3LAM_fields} \
  'regions=[/ [/ "GLOBE",    (/-180,  180, -90,  90/), False, False /], \
              [/ "FV3LAM",   (/-140,  -60,  20,  55/), False, False /], \
              [/ "FV3LAMNW", (/-145, -135,  50,  60/),  True, True  /], \
              [/ "FV3LAMSE", (/ -75,  -70,  20,  25/),  True, False /], \
              [/ "dummy_list_element_dont_remove" /] \
           /]' \
  map_proj=\"cyln\" 

#  'regions=[/ [/ "GLOBE",    (/-180,  180, -90,  90/), False, False /], \
#              [/ "FV3LAM",   (/-140,  -60,  20,  55/), False, False /], \
#              [/ "FV3LAMNW", (/-135, -130,  45,  50/),  True, True  /], \
#              [/ "FV3LAMSE", (/ -75,  -70,  20,  25/),  True, False /], \
#              [/ "dummy_list_element_dont_remove" /] \
#           /]' \

#  'regions=[/ [/ "FV3LAMNW", (/-135, -130,  45,  50/),  True, True  /], \
#              [/ "dummy_list_element_dont_remove" /] \
#           /]' \

#  'regions=[/ [/ "FV3LAM",   (/-140,  -60,  20,  55/), False, False /], \
#              [/ "dummy_list_element_dont_remove" /] \
#           /]' \

#  draw_RAP_grid=False \
#  draw_FV3LAM_grid=True \
#  plot_subregs=True \
#  subreg_names=\(/\"haloAll\",\"haloNW\",\"haloSE\"/\) \
#  subreg_coords=\(/\(/-140,-60,20,55/\),\(/-135,-130,45,50/\),\(/-75,-70,20,25/\)/\) \
#  subreg_draw_RAP_grid=\(/False,True,False/\) \
#  subreg_draw_FV3LAM_grid=\(/False,True,True/\) \

#  bbb=\[/\[/\"globe\",\(/-140,-60,20,55/\),True,True/\],\[/\"RAP\",\(/-140,-60,20,55/\),True,True/\],\[/\"RAPNW\",\(/-140,-60,20,55/\),False,False/\],\[/\"dummy\"/\]/\] \
#  bbb=\[/\[/\"globe\",\(/-140,-60,20,55/\),True,True/\],\
#\[/\"RAP\",\(/-140,-60,20,55/\),True,True/\],\
#\[/\"RAPNW\",\(/-140,-60,20,55/\),False,False/\],\
#\[/\"dummy_list_element_dont_remove\"/\]/\] \
#  subregions=\[/\[/\"haloNW\",-140,-60,20,55/\],\[/\"haloSE\",-75,-70,20,25/\]/\] \
#  subregions=\(/\(/-140,-60,20,55/\),\(/-65,-60,45,50/\)/\) \
#
#  map_proj=\"ortho\" \
#  map_proj_ctr=\(/-105,50/\) \
#  map_proj=\"cyln\" \
#  subreg=\(/-180,-35,-10,80/\) \
#  subreg=\(/-140,-60,45,55/\) \  # Northern portion of halo.
#  subreg=\(/-125,-70,22,23/\) \  # Southern portion of halo.
#  subreg=\(/-133,-122,20,50/\) \  # Western portion of halo.
#  subreg=\(/-73,-62,20,50/\) \  # Eastern portion of halo.
#  subreg=\(/-134,-132,46.5,47.5/\) \
#  subreg=\(/-135,-130,45,50/\) \  # North-west corner of halo.
#  subreg=\(/-65,-60,45,50/\) \  # North-east corner of halo.
#  subreg=\(/-125,-120,20,25/\) \  # South-west corner of halo.
#  subreg=\(/-75,-70,20,25/\) \  # South-east corner of halo.
#
#  subreg=\(/-140,-60,20,55/\) \  # Whole halo.
#
#mv RAP_T.png RAP_T_all.png
#mv FV3_halo.png FV3_halo_all.png


fi
exit



if [ 0 = 1 ]; then
#
# Show FV3 regional domain (tile 7) and the original RAP domain outline
# on a sphere (orthogonal spherical projection).
#
ncl -n plot_fields.ncl \
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
ncl -n plot_fields.ncl \
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
ncl -n plot_fields.ncl \
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

if [ 0 = 1 ]; then
#
ncl -n plot_fields.ncl \
  grid_dir=\"$grid_dir\" \
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
#mv ${CRES}_grid.png ${CRES}rgnl_RAP_grids_cyln_subreg.png
mv ${CRES}_grid.png ${CRES}rgnl_RAP_grids_cyln.png

fi



if [ 0 = 1 ]; then
#
#ncl -n plot_fields.ncl \
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
  subreg=\(/-135,-60,10,60/\) \
  graphics_type=\"png\"
#  subreg=\(/-47,-40,15,22/\) \
#  tile_inds=\(/1,2,3,4,5,6/\) \
#  subreg=\(/-120,-70,20,70/\) \
#  subreg=\(/-150,-40,0,70/\) \
#  subreg=\(/-120,-70,20,70/\) \
#
#mv ${CRES}_grid.png ${CRES}rgnl_RAP_fields_cyln_subreg.png
mv ${CRES}_grid.png ${CRES}rgnl_RAP_fields_cyln.png

fi


if [ 0 = 1 ]; then
#
#ncl -n plot_fields.ncl \
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
  map_proj=\"lamb\" \
  subreg=\(/-128,-70,20,53/\) \
  graphics_type=\"png\"
#  subreg=\(/-47,-40,15,22/\) \
#  tile_inds=\(/1,2,3,4,5,6/\) \
#  subreg=\(/-120,-70,20,70/\) \
#  subreg=\(/-150,-40,0,70/\) \
#  subreg=\(/-120,-70,20,70/\) \
#  map_proj=\"cyln\" \
#  subreg=\(/-135,-60,10,60/\) \
#  subreg=\(/-128,-70,20,53/\) \
#  map_proj=\"lamb\" \
#
#mv ${CRES}_grid.png ${CRES}rgnl_RAP_fields_cyln_subreg.png
#mv ${CRES}_grid.png ${CRES}rgnl_RAP_fields_cyln.png
fi


if [ 0 = 1 ]; then
#
#ncl -n plot_fields.ncl \
ncl -n plot_grid.ncl \
  grid_dir=\"$grid_dir\" \
  res=${RES} \
  tile_inds=\(/7/\) \
  draw_tile_bdy=True \
  draw_tile_grid=False \
  draw_RAP_domain=False \
  RAP_grid_fn=\"$RAP_grid_fn\" \
  draw_RAP_bdy=True \
  draw_RAP_grid=False \
  map_proj=\"ortho\" \
  map_proj_ctr=\(/-105,50/\) \
  subreg=\(/-180,-35,-10,80/\) \
  graphics_type=\"png\"
#  subreg=\(/-47,-40,15,22/\) \
#  tile_inds=\(/1,2,3,4,5,6/\) \
#  subreg=\(/-120,-70,20,70/\) \
#  subreg=\(/-150,-40,0,70/\) \
#  subreg=\(/-120,-70,20,70/\) \
#  map_proj=\"cyln\" \
#  subreg=\(/-135,-60,10,60/\) \
#  subreg=\(/-128,-70,20,53/\) \
#  map_proj=\"lamb\" \
#
#mv ${CRES}_grid.png ${CRES}rgnl_RAP_fields_cyln_subreg.png
#mv ${CRES}_grid.png ${CRES}rgnl_RAP_fields_cyln.png
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




