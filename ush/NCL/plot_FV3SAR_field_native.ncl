;
; **********************************************************************
;
; Type "ncl plot_grid.ncl 'help=True'" on the command line to obtain 
; help for this script.
;
; **********************************************************************
;

;
; **********************************************************************
;
; Declare global variables before loading files.  This has the same ef-
; fect as declaring these variables on the command line.
;
; **********************************************************************
;

;help = True

;run_dir = "ABCD"
;run_dir = "/home/Gerard/fv3_regional/fv3sar_workflow/ush/NCL"
run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/C768_S1p5_RR3_EMCCONUS_UUUU"
run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/C384_S0p63_RR3_RAP_no_quilting"
;run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/C384_S1p65_RR5_HRRR_new_chgres_fv3sar12"
;run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/fv3sar_workflow/sorc/regional_grid"
run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/C384_S0p63_RR3_test_new_grid"
run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/C384_S0p63_RR3_test_new_grid05"
run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/C384_S0p63_RR3_test_new_grid05"
run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/C384_S0p63_RR3_test_new_grid06"
;run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/NX960_NY960_A0p21423_Kmns0p23209_HRRR_crap01"
;run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/NX1800_NY1120_A0p21423_Kmns0p23209_HRRR_crap01"
;run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/NX1800_NY1120_A0p21423_Kmns0p23209_HRRR_works"
run_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/run_dirs/C384_S0p63_RR3_test_new_grid05"
run_dir = "/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM_test_instructions/expt_dirs/NX1700_NY1056_A0p21423_Kmns0p23209_HRRR_test_HRRRgrid"
run_dir = "/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM_test_instructions/expt_dirs/NX1700_NY1056_A0p21423_Kmns0p23209_HRRR_test_HRRRgrid02"
run_dir = "/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM_test_instructions/expt_dirs/NX1768_NY1032_A0p21423_Kmns0p23209_HRRR_test_HRRRgrid02"
run_dir = "/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM_test_instructions/expt_dirs/NX1734_NY1008_A0p21423_Kmns0p23209_HRRR_test_HRRRgrid02"
;run_dir = "/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM_test_chgres_cube/expt_dirs/test2"

run_dir = "/scratch4/BMC/gmtb/Linlin.Pan/ice/Linlin.Pan/rtgen.112531/tmp/fv3_regional_control"
run_dir = "/scratch3/BMC/det/beck/FV3-CAM/run_dirs/real_time/2019062300"

tile_inds := (/ 1, 7, 4 /)
;tile_inds := (/ 1, 4 /)
;tile_inds := (/ 5, 6 /)
;tile_inds := (/ 5, 7 /)
tile_inds := (/ 5, 6, 7 /)
tile_inds := (/ 1, 5, 6, 7 /)
;tile_inds := (/ 5 /)
;tile_inds := (/ 6 /)
tile_inds := (/ 7 /)
;tile_inds := (/ 6, 7 /)

show_tile_bdies = True
;show_tile_bdies = False

tile_bdy_color = "blue"

show_tile_grids = True
show_tile_grids = False

file_basename = "atmos_static"
;file_basename = "fv3_history"
file_basename = "fv3_history2d"

file_basename = "phyf000"

; This is a temporary change for plotting ICs.
;file_basename = "sfc_data.tile7"
;file_basename = "gfs_data.tile7"


field_name = "cell_area"
field_name = "sqrt_cell_area"
;field_name = "cell_dx"
;field_name = "cell_dy"
;field_name = "cell_dx_ovr_cell_dy"
;field_name = "min_cell_dx_cell_dy"
;field_name = "angle_cell_dx"
;field_name = "angle_cell_dy"

;field_name = "orog_raw"
;field_name = "orog_filt"

;field_name = "time"
;field_name = "grid_xt"
;field_name = "vflx_ave"
;field_name = "ref3D"

;field_name = "spfh"
;field_name = "cnwat"
;field_name = "zsurf"
field_name = "sltyp"
;field_name = "slc"
;field_name = "smc"
;field_name = "stc"
;field_name = "f10m"
;field_name = "canopy"
;field_name = "vtype"
;field_name = "stype"

;field_name = "rainwat"

;field_name = "none"


map_proj = "cyln"
;map_proj = "ortho"
;
; This should be set to (0,0) for "cyln" map projection.
;
map_proj_ctr = (/ 0.0, 0.0 /) ; This should be set to (0,0) for "cyln" map projection.
;map_proj_ctr = (/ -106.0, 54.0 /) ; RAP domain.
;map_proj_ctr = (/ -97.5, 38.5 /)  ; HRRR domain.

;map_proj_ctr = (/ 6.0, 54.0 /) ; RAP domain corner.

plot_subreg = True
;plot_subreg = False

;subreg_limits := (/ -180, 180, -90, 90 /)
;subreg_limits := (/ -75, -45, 30, 60 /)

subreg_limits := (/ -135, -60, 20, 55 /) ; HRRR domain if using "cyln" map projection.
;subreg_limits := (/ -125, -70, 20, 55 /) ; HRRR domain if using "ortho" map projection.
;subreg_limits := (/ -145, -90, 30, 60 /) ; Northwest corner of HRRR domain.
;subreg_limits := (/ -135, -125, 40, 50 /) ; Northwest corner of HRRR domain, zoomed.
;subreg_limits := (/ -123, -121, 48, 50 /) ; Northwest corner of HRRR domain, zoomed more.
;subreg_limits := (/ -120, -115, 30, 35 /)
;subreg_limits := (/ -125, -120, 15, 25 /) ; Southwest corner of HRRR domain.

;subreg_limits := (/ -15, 0, 0, 15 /)
;subreg_limits := (/ -30, 0, 0, 30 /)
;subreg_limits := (/ -60, -30, 0, 30 /)
;subreg_limits := (/ -75, -60, 0, 15 /)
;subreg_limits := (/ -70, -65, 5, 10 /)
;subreg_limits := (/ -55, -40, 45, 60 /)
;subreg_limits := (/ -50, -45, 50, 55 /)
;subreg_limits := (/ -10, 5, 0, 15 /)
;subreg_limits := (/ -2, 2, 0, 4 /)
;subreg_limits := (/ -90, -60, -20, 10 /)
;subreg_limits := (/ -80, -70, -10, 0 /)
;subreg_limits := (/ -85, -70, -15, 0 /)
;subreg_limits := (/ -76, -72, -12, -8 /)
;subreg_limits := (/ -75, -45, -15, 0 /)
;subreg_limits := (/ -63, -58, -15, -10 /)
;subreg_limits := (/ 15, 30, 30, 45 /)
;subreg_limits := (/ 14, 16, 36, 38 /)
;subreg_limits := (/ -70, -55, -20, -5 /)
;subreg_limits := (/ 10, 20, 30, 40 /)
;subreg_limits := (/ 15, 20, 30, 35 /)

remove_rgnl_halo = True
;remove_rgnl_halo = False




show_RAP_bdy = True
;show_RAP_bdy = False

RAP_bdy_color = "red"

show_RAP_grid = True
show_RAP_grid = False

plot_RAP_field = True
plot_RAP_field = False

field_name_RAP = "cell_area"
field_name_RAP = "sqrt_cell_area"
;field_name_RAP = "MAPFAC_M"
;field_name_RAP = "none"

; This is for HRRR grib2 file.
field_name_RAP = "VGTYP_P0_L1_GLC0"

RAP_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509"
;RAP_grid_fn = "/home/Gerard/fv3_regional/fv3sar_workflow/ush/NCL/plot_grid.ncl"
;RAP_grid_fn = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/geo_em.d01.RAP.nc"
;RAP_grid_fn = RAP_dir + "/geo_em.d01.RAP.nc"
RAP_grid_fn = RAP_dir + "/geo_em.d01.HRRR.nc"

horiz_dist_units = "m"
horiz_dist_units = "km"





time_inds_to_plot := (/ 0, 2 /)
time_inds_to_plot := (/ 2 /)
time_inds_to_plot := (/ 0 /)


fcst_output_hrs := (/ 0, 1, 2, 3, 4, 5, 6 /)  ; Read this in from file, e.g. var_defns.sh.
;fcst_output_hrs := (/ 0, 2, 4, 6 /)  ; Read this in from file, e.g. var_defns.sh.
fcst_hrs_to_plot = fcst_output_hrs(time_inds_to_plot)
;print("" + time_inds_to_plot)
;print("" + fcst_hrs_to_plot)
;pause

vert_inds_to_plot := (/ 0, 10 /)
vert_inds_to_plot := (/ 10 /)
vert_inds_to_plot := (/ 8 /)
;vert_inds_to_plot := (/ 0 /)
;vert_inds_to_plot := (/ 0, 1, 2, 3, 4, 5, 6, 7, 8 /)



separator_line \
:= "************************************************************************"
;:= "========================================================================"


;
; **********************************************************************
;
; Load files.
;
; **********************************************************************
;
lib_location = "lib/"

loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "repeat_str.ncl")
loadscript(lib_location + "calc_field_stats.ncl")
loadscript(lib_location + "get_rect_grid_bdy.ncl")
loadscript(lib_location + "set_cnLevels_lbLabels.ncl")

load "process_plot_params.ncl"
load "read_FV3SAR_grid_native.ncl"
load "read_FV3SAR_gridfield_native.ncl"
load "read_FV3SAR_field_native.ncl"
load "read_FV3SAR_grid_wrtcmp.ncl"
load "read_FV3SAR_field_wrtcmp.ncl"
load "read_RAP_grid.ncl"
load "read_RAP_field.ncl"
load "plot_horiz_field.ncl"
load "set_file_field_names.ncl"
load "get_wrtcmp_grid.ncl"
load "calc_wrtcmp_grid_params_lambert_cnfrml.ncl"
load "make_plot_titles.ncl"

begin
;
; **********************************************************************
;
; Set usage message.
;
; **********************************************************************
;
  usage_msg = \
"  ncl -n plot_grid.ncl \" + char_nl + \
"      'help=False' \" + char_nl + \
"      'grid_dir=" + char_dq + "./some_dir/grid" + char_dq + "' \" + char_nl + \
"      'res=96' \" + char_nl + \
"      'tile_inds=(/1,2,3/)' \" + char_nl + \
"      'show_tile_bdies=True' \" + char_nl + \
"      'show_tile_grids=True' \" + char_nl + \
"      'plot_RAP_field=True' \" + char_nl + \
"      'RAP_grid_fn=" + char_dq + "./some_dir/RAP_grid.nc" + char_dq + "' \" + char_nl + \
"      'show_RAP_bdy=True' \" + char_nl + \
"      'show_RAP_grid=True' \" + char_nl + \
"      'map_proj=" + char_dq + "cyln" + char_dq + "' \" + char_nl + \
"      'map_proj_ctr=(/0,90/)' \" + char_nl + \
"      'subreg_limits=(/-30,30,-25,25/)' \" + char_nl + \
"      'graphics_type=" + char_dq + "ncgm" + char_dq + "'"
;
; **********************************************************************
;
; Set help message.  The help message contains the documentation for 
; this script and thus should reflect any changes to the code.
;
; **********************************************************************
;
  help_msg = char_nl + \
"This script generates a 2-D color plot of one or more of the tiles on" + char_nl + \
"a cubed-sphere grid on top of a map of the continents.  Each tile is" + char_nl + \
"depicted in the output graphics file as a uniformly colored region." + char_nl + \
char_nl + \
"An example of a call to this script from the command line is as fol-" + char_nl + \
"lows:" + char_nl + \
char_nl + \
usage_msg + \
char_nl + \
char_nl + \
"The output is a graphics file named" + char_nl + \
char_nl + \
"  C[res]_grid.[ext]" + char_nl + \
char_nl + \
"where res is the specified resolution and ext is the graphics file ex-" + char_nl + \
"tension (determined by the specified output graphics type graphics_-" + char_nl + \
"type).  The input arguments to this script are:" + char_nl + \
char_nl + \
"help:" + char_nl + \
"This argument specifies whether or not to print out the documentation" + char_nl + \
"for this script and exit.  It is either True or False.  Default is" + char_nl + \
"False.  If this is set to True, this script prints out the documenta-" + char_nl + \
"tion and exits, ignoring all other arguments.  To see the documenta-" + char_nl + \
"tion, type " + char_dq + "ncl plot_grid.ncl 'help=True'" + char_dq + " on the command line in the" + char_nl + \
"directory of this script." + char_nl + \
char_nl + \
"grid_dir:" + char_nl + \
"This argument specifies the directory in which the grid files are lo-" + char_nl + \
"cated.  It is assumed that these are NetCDF files with names of the" + char_nl + \
"form" + char_nl + \
char_nl + \
"   C[res]_grid.tile[N].nc" + char_nl + \
char_nl + \
"where res is the resolution specified on the command line and N is the" + char_nl + \
"tile number.  The tile numbers to consider are specified by the input" + char_nl + \
"argument tile_inds (see below).  Default value is the current directo-" + char_nl + \
"ry, i.e. " + char_dq + "./" + char_dq + "." + char_nl + \
char_nl + \
"res:" + char_nl + \
"This argument specifies the cubed-sphere resolution, i.e. the number" + char_nl + \
"of cells in each of the two horizontal directions on each of the 6" + char_nl + \
"tiles of the global cubed-sphere grid.  Valid values are: 48, 96, 192," + char_nl + \ 
"384, 768, 1152, and 3072." + char_nl + \
char_nl + \
"tile_inds:" + char_nl + \
"This argument specifies the indices of those tiles on the cubed-sphere" + char_nl + \
"grid that are to be plotted.  For example, to plot tiles 1, 3, and 5, " + char_nl + \
"specify" + char_nl + \
char_nl + \
"  tile_inds = (/ 1, 3, 5 /)" + char_nl + \
char_nl + \
"If this is not specified, all available tiles are plotted (where by " + char_nl + \
char_dq + "available" + char_dq + ", we mean all tiles for which there exists a grid file in" + char_nl + \
"grid_dir)." + char_nl + \
char_nl + \
"show_tile_bdies:" + char_nl + \
"This argument specifies whether or not to draw the boundary of each " + char_nl + \
"specified tile.  It is either True or False.  Default is True." + char_nl + \
char_nl + \
"show_tile_grids:" + char_nl + \
"This argument specifies whether or not to draw the boundaries of all" + char_nl + \
"grid cells on each tile that is being plotted.  It is either True or " + char_nl + \
"False.  Default is False.  For a high-resolution grid, this can make" + char_nl + \
"it difficult to see the underlying color of the tile in the output" + char_nl + \
"graphics file (because there would be many grid lines drawn very close" + char_nl + \
"together)." + char_nl + \
char_nl + \
"plot_RAP_field:" + char_nl + \
"This argument specifies whether or not to draw the original [i.e. pre-" + char_nl + \
"FV3 RAP (RAPid Refresh) domain].  It is either True or False.  Default" + char_nl + \
"is False.  If this is set to True, the RAP domain is added to the plot" + char_nl + \
"as a uniformly colored region (with a color that is different from any" + char_nl + \
"of the cubed-sphere tiles)." + char_nl + \
char_nl + \
"RAP_grid_fn:" + char_nl + \
"This argument specifies the full (i.e. including directory) file name" + char_nl + \
"of the NetCDF file that describes the RAP grid.  This is used only if" + char_nl + \
"plot_RAP_field is set to True." + char_nl + \
"" + char_nl + \
"show_RAP_bdy:" + char_nl + \
"This argument specifies whether or not to draw the boundary of the RAP" + char_nl + \
"domain.  It is either True or False.  Default is True.  This has no" + char_nl + \
"effect if plot_RAP_field is set to False." + char_nl + \
char_nl + \
"show_RAP_grid:" + char_nl + \
"This argument specifies whether or not to draw the boundaries of all" + char_nl + \
"grid cells on the RAP domain.  It is either True or False.  Default is" + char_nl + \
"False.  For a high-resolution RAP grid, setting this to True can make" + char_nl + \
"it difficult to see the underlying color of the RAP domain in the out-" + char_nl + \
"put graphics file (because there would be many grid lines drawn very" + char_nl + \
"close together.  This has no effect if plot_RAP_field is set to" + char_nl + \
"False." +  char_nl + \
char_nl + \
"map_proj:" + char_nl + \
"This argument specifies the map projection to use for the plot.  Valid" + char_nl + \
"values are:" + char_nl + \
char_nl + \
"  " + char_dq + "cyln" + char_dq + " - for cylindrical-equidistant projection" + char_nl + \
"  " + char_dq + "ortho" + char_dq + " - for orthographic (i.e. on a sphere) projection" + char_nl + \
;"  " + char_dq + "lamb" + char_dq + " - for Lambert equal-area projection" + char_nl + \
"  " + char_dq + "lamb" + char_dq + " - for Lambert conformal projection" + char_nl + \
char_nl + \
"If this argument is omitted, a cylindrical-equidistant projection is" + char_nl + \
"used.  " + char_nl + \
char_nl + \
"map_proj_ctr:" + char_nl + \
"This argument specifies the point on the sphere at which to center the" + char_nl + \
"map projection used for the plot.  It consists of the point's longi-" + char_nl + \
"tude and latitude (in degrees), as follows:" + char_nl + \
char_nl + \
"  map_proj_ctr = (/ 30, 40 /)" + char_nl + \
char_nl + \
"If this is not specified, it is set to (/0,0/) for the cylindrical-" + char_nl + \
"equidistant and orthographic (i.e. on a sphere) projections and to" + char_nl + \
"(/0,90/) (i.e. the North Pole) for the Lambert equal-area projection." + char_nl + \
char_nl + \
"subreg_limits:" + char_nl + \
"If using a cylindrical-equidistant map projection, this argument spe-" + char_nl + \
"cifies the minimum and maximum longitudes and latitudes (in degrees)" + char_nl + \
"of the subregion to plot.  It has the format" + char_nl + \
char_nl + \
"  subreg_limits = (/ lon_min, lon_max, lat_min, lat_max /)" + char_nl + \
char_nl + \
"where lon_min and lon_max are the minimum and maximum values of the" + char_nl + \
"longitude and lat_min and lat_max are the minimum and maximum values" + char_nl + \
"of the latitude.  If this argument is omitted, the field is plotted on" + char_nl + \
"the whole globe.  It is ignored for projections other than cylindri-" + char_nl + \
"cal-equidistant." + char_nl + \
char_nl + \
"graphics_type:" + char_nl + \
"This argument specifies the type of graphics file to generate as out-" + char_nl + \
"put.  It can be either " + char_dq + "ncgm" + char_dq + " (NCAR Graphics) or " + char_dq + "png" + char_dq + ".  Default is" + char_nl + \
char_dq + "ncgm" + char_dq + "." + char_nl 
;
; **********************************************************************
;
; Playing around with reading in HRRR grib2 files.
;
; **********************************************************************
;
if (True) then
;if (False) then

  fn := "1916021000000"
  fp := addfile(fn + ".grb2", "r")

RAP_fn := fn

  var_names := getfilevarnames(fp)
  num_vars := dimsizes(var_names)
print("")
print("num_vars = " + num_vars)
  var_types := getfilevartypes(fp, var_names)
;  var_dim_sizes := getfilevardimsizes(fp)

  do i=0, num_vars-1

    var_name := var_names(i)

    var_dim_names := getfilevardims(fp, var_name)
    var_dim_names_str := tostring(var_dim_names)
    var_dim_names_str := str_join(var_dim_names_str, ", ")
    var_dim_names_str := "(" + var_dim_names_str + ")"

    var_dim_sizes := getfilevardimsizes(fp, var_name)
    var_dim_sizes_str := tostring(var_dim_sizes)
    var_dim_sizes_str := str_join(var_dim_sizes_str, ", ")
    var_dim_sizes_str := "(" + var_dim_sizes_str + ")"
    
    var_info \
    := char_dq + var_name + char_dq + "; " \
     + var_types(i) + "; " \
     + var_dim_names_str + " = " \
     + var_dim_sizes_str

    print("")
    print("var_info = " + var_info)

  end do

  tmp := fp->$field_name_RAP$
  tmp_min := min(tmp)
  tmp_max := max(tmp)
print("")
print("tmp_min = " + tmp_min)
print("tmp_max = " + tmp_max)
pause

;exit

end if
;
; **********************************************************************
;
; Process the global variables (e.g. set on the command line).
;
; **********************************************************************
;
  plot_params := process_plot_params("plot_grid", usage_msg, help_msg)

  gtype = plot_params@gtype
  num_tiles_to_plot = plot_params@num_tiles_to_plot
  inds_tiles_to_plot = plot_params@inds_tiles_to_plot
  cres = plot_params@cres
  run_dir = plot_params@run_dir
  work_dir = plot_params@work_dir

  horiz_dist_units = plot_params@horiz_dist_units
  horiz_area_units = plot_params@horiz_area_units

  show_tile_bdies = plot_params@show_tile_bdies
  tile_bdy_color = plot_params@tile_bdy_color
  show_tile_grids = plot_params@show_tile_grids
  field_name = plot_params@field_name
  is_gridfield = plot_params@is_gridfield
  file_basename = plot_params@file_basename

  show_RAP_bdy = plot_params@show_RAP_bdy
  RAP_bdy_color = plot_params@RAP_bdy_color
  show_RAP_grid = plot_params@show_RAP_grid
  plot_RAP_field = plot_params@plot_RAP_field
  field_name_RAP = plot_params@field_name_RAP

  graphics_type = plot_params@graphics_type
  map_proj = plot_params@map_proj
  map_proj_ctr = plot_params@map_proj_ctr

  remove_rgnl_halo = plot_params@remove_rgnl_halo

  plot_subreg = plot_params@plot_subreg
  subreg_limits = plot_params@subreg_limits
;
; **********************************************************************
;
; Read in the FV3SAR grid.
;
; **********************************************************************
;
  nhalo_T7 = 4  ; Should this be at the top, i.e. defined as a global variable????
                ; or be a requird input that gets processed along with the other
                ; command linea arguments?

; If the following variable is permanently going to be part of this 
; script, then the name of the script should be changed to NOT include
; "native", since then it will have the flexibility to plot fields on
; either the native or the wrtcmp grid.

;  read_FV3SAR_wrtcmp = True
  read_FV3SAR_wrtcmp = False

  if (read_FV3SAR_wrtcmp) then

  FV3SAR_wrtcmp_fn = run_dir + "/" + CDATE + "/" + "dynf000.nc"
  get_domain_bdy = True
  grid_info := read_FV3SAR_grid_wrtcmp( \
               FV3SAR_wrtcmp_fn, \
               get_domain_bdy)

  fp_wrtcmp = grid_info@fp
  nx = grid_info@nx
  ny = grid_info@ny
  lon_cntrs_unstruc = grid_info@lon_cntrs_unstruc
  lat_cntrs_unstruc = grid_info@lat_cntrs_unstruc
  lon_verts_unstruc = grid_info@lon_verts_unstruc
  lat_verts_unstruc = grid_info@lat_verts_unstruc
  lon_bdy = grid_info@lon_bdy
  lat_bdy = grid_info@lat_bdy
  coord_data_type_FV3SAR = grid_info@coord_data_type

  else

  grid_info := read_FV3SAR_grid_native( \
               work_dir, \
               gtype, \
               cres, \
               inds_tiles_to_plot, \
               show_tile_bdies, \
               nhalo_T7, \
               remove_rgnl_halo)

  grid_fn_tiles_to_plot = grid_info@grid_fn_all_tiles

  nhSG_tiles_to_plot = grid_info@nhSG_all_tiles
  nxhSG_tiles_to_plot = grid_info@nxhSG_all_tiles
  nyhSG_tiles_to_plot = grid_info@nyhSG_all_tiles
  nxSG_tiles_to_plot = grid_info@nxSG_all_tiles
  nySG_tiles_to_plot = grid_info@nySG_all_tiles

  nh_tiles_to_plot = grid_info@nh_all_tiles
  nxh_tiles_to_plot = grid_info@nxh_all_tiles
  nyh_tiles_to_plot = grid_info@nyh_all_tiles
  nx_tiles_to_plot = grid_info@nx_all_tiles
  ny_tiles_to_plot = grid_info@ny_all_tiles

  remove_halo_tiles_to_plot = grid_info@remove_halo_all_tiles

  lon_cntrs_unstruc = grid_info@lon_cntrs_all_tiles_unstruc
  lat_cntrs_unstruc = grid_info@lat_cntrs_all_tiles_unstruc
  lon_verts_unstruc = grid_info@lon_verts_all_tiles_unstruc
  lat_verts_unstruc = grid_info@lat_verts_all_tiles_unstruc

  lon_bdy = grid_info@lon_bdy_all_tiles
  lat_bdy = grid_info@lat_bdy_all_tiles

  lon_tile_cntr_tiles_to_plot = grid_info@lon_tile_cntr_all_tiles
  lat_tile_cntr_tiles_to_plot = grid_info@lat_tile_cntr_all_tiles

  lon_tile_corners_face_midpts_tiles_to_plot \
  = grid_info@lon_tile_corners_face_midpts_all_tiles
  lat_tile_corners_face_midpts_tiles_to_plot \
  = grid_info@lat_tile_corners_face_midpts_all_tiles

  coord_data_type_FV3SAR = grid_info@coord_data_type

  end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  lon_bdy_all_bdies := new(1, coord_data_type_FV3SAR)
  lat_bdy_all_bdies := new(1, coord_data_type_FV3SAR)
;
; **********************************************************************
;
; If show_RAP_bdy, show_RAP_grid, or plot_RAP_field is set to True, read
; in the coordinates of the RAP grid.
;
; **********************************************************************
;
  if (show_RAP_bdy .or. show_RAP_grid .or. plot_RAP_field) then
;
; **********************************************************************
;
; Read in the RAP grid from file.
;
; **********************************************************************
;
    grid_info := read_RAP_grid(RAP_grid_fn, show_RAP_bdy)
  
    fp_RAP_grid = grid_info@fp
    nx_RAP = grid_info@nx
    ny_RAP = grid_info@ny
    lon_cntrs_unstruc_RAP = grid_info@lon_cntrs_unstruc
    lat_cntrs_unstruc_RAP = grid_info@lat_cntrs_unstruc
    lon_verts_unstruc_RAP = grid_info@lon_verts_unstruc
    lat_verts_unstruc_RAP = grid_info@lat_verts_unstruc
    lon_bdy_RAP = grid_info@lon_bdy
    lat_bdy_RAP = grid_info@lat_bdy
    lon_grid_cntr_RAP = grid_info@lon_grid_cntr
    lat_grid_cntr_RAP = grid_info@lat_grid_cntr
    coord_data_type_RAP = grid_info@coord_data_type

    print("")
    print("lon_grid_cntr_RAP = " + lon_grid_cntr_RAP + " deg")
    print("lat_grid_cntr_RAP = " + lat_grid_cntr_RAP + " deg")

  end if
;
; **********************************************************************
;
; Get/construct the write-component grid.
;
; **********************************************************************
;

; These should be at the top and go through the process_...() function.

;  show_wrtcmp_grid = True
  show_wrtcmp_grid = False

  show_wrtcmp_bdy = True
;  show_wrtcmp_bdy = False

  wrtcmp_bdy_color = "green"


  rd := "/scratch3/BMC/det/Gerard.Ketefian/UFS_CAM_test_instructions/expt_dirs/NX1800_NY1120_A0p21423_Kmns0p23209_HRRR_test_cycl_slurm_01/2017090700"
  wrtcmp_config_fn := rd + "/model_configure"
  wrtcmp_config_tmpl_fn = wrtcmp_config_fn + ".tmpl"

if (True) then
;if (False) then

  sys_output = systemfunc("cp " + wrtcmp_config_tmpl_fn + " " + wrtcmp_config_fn) 

  nn = 0
  lon_grid_cntr_native = lon_tile_cntr_tiles_to_plot(nn)
  lat_grid_cntr_native = lat_tile_cntr_tiles_to_plot(nn)
  lon_tile_corners_face_midpts_native := lon_tile_corners_face_midpts_tiles_to_plot(nn,:)
  lat_tile_corners_face_midpts_native := lat_tile_corners_face_midpts_tiles_to_plot(nn,:)

  dx_native = 3.0d+3
  dy_native = 3.0d+3
  angle_units = "deg"

  out := calc_wrtcmp_grid_params_lambert_cnfrml( \
         wrtcmp_config_fn, \
         lon_grid_cntr_native, lat_grid_cntr_native, \
         lon_tile_corners_face_midpts_native, \
         lat_tile_corners_face_midpts_native, \
         dx_native, dy_native, \
         angle_units)

print("HELLO")
pause
end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  if (show_wrtcmp_grid .or. show_wrtcmp_bdy) then

    grid_info := get_wrtcmp_grid(wrtcmp_config_fn, show_wrtcmp_bdy)

    nx_wrtcmp = grid_info@nx
    ny_wrtcmp = grid_info@ny
    lon_cntrs_unstruc_wrtcmp = grid_info@lon_cntrs_unstruc
    lat_cntrs_unstruc_wrtcmp = grid_info@lat_cntrs_unstruc
    lon_verts_unstruc_wrtcmp = grid_info@lon_verts_unstruc
    lat_verts_unstruc_wrtcmp = grid_info@lat_verts_unstruc
    lon_bdy_wrtcmp = grid_info@lon_bdy
    lat_bdy_wrtcmp = grid_info@lat_bdy
    lon_grid_cntr_wrtcmp = grid_info@lon_grid_cntr
    lat_grid_cntr_wrtcmp = grid_info@lat_grid_cntr
    coord_data_type_wrtcmp = grid_info@coord_data_type

    print("")
    print("lon_grid_cntr_wrtcmp = " + lon_grid_cntr_wrtcmp + " deg")
    print("lat_grid_cntr_wrtcmp = " + lat_grid_cntr_wrtcmp + " deg")
pause

  end if
;
; **********************************************************************
;
; Initialize the unstructured coordinate arrays that will contain infor-
; mation for all grids (i.e. all tiles on the FV3 cubed-sphere grid that
; are to be plotted and possibly the RAP grid) to the corresponding ar-
; rays for the FV3 grid (i.e. all tiles to be plotted).  These arrays 
; will be passed to the plotting function(s) to generate plots.
;
; **********************************************************************
;
  lon_cntrs_unstruc_all_grids := lon_cntrs_unstruc
  lat_cntrs_unstruc_all_grids := lat_cntrs_unstruc
  lon_verts_unstruc_all_grids := lon_verts_unstruc
  lat_verts_unstruc_all_grids := lat_verts_unstruc

  num_bdies_to_plot = 0
  if (show_tile_bdies) then

    num_bdies_to_plot = num_bdies_to_plot + num_tiles_to_plot

    lon_bdy_all_bdies \
    := array_append_record(lon_bdy_all_bdies, lon_bdy, 0)
    lat_bdy_all_bdies \
    := array_append_record(lat_bdy_all_bdies, lat_bdy, 0)

  end if
;
; **********************************************************************
;
; If the plots will show the RAP grid and/or a field on the RAP grid, 
; then prepend the RAP coordinate arrays to the coordinate arrays that
; will contain coordinate information for all grids.
;
; **********************************************************************
;
  if (show_RAP_grid .or. plot_RAP_field) then
;
; **********************************************************************
;
; If the RAP coordinate arrays are not of the same data type as the FV3-
; SAR coordinate arrays, convert the data type of the former to that of
; the latter.
;
; **********************************************************************
;
    if (.not. strcmp_exact(coord_data_type_FV3SAR, coord_data_type_RAP)) then

      lon_cntrs_unstruc_RAP \
      := totype(lon_cntrs_unstruc_RAP, coord_data_type_FV3SAR)

      lat_cntrs_unstruc_RAP \
      := totype(lat_cntrs_unstruc_RAP, coord_data_type_FV3SAR)

      lon_verts_unstruc_RAP \
      := totype(lon_verts_unstruc_RAP, coord_data_type_FV3SAR)

      lat_verts_unstruc_RAP \
      := totype(lat_verts_unstruc_RAP, coord_data_type_FV3SAR)

    end if
;
; **********************************************************************
;
; Prepend RAP coordinates to the corresponding arrays for the FV3SAR.
; This is done for plotting convenience.  Note that the RAP coordinates
; are prepended insted of appended so that the RAP grid (and any field
; associated with it) is drawn first and the FV3SAR tiles (and any 
; fields on them) are then drawn on top.
;
; **********************************************************************
;
    lon_cntrs_unstruc_all_grids \
    := array_append_record( \
       lon_cntrs_unstruc_RAP, lon_cntrs_unstruc_all_grids, 0)

    lat_cntrs_unstruc_all_grids \
    := array_append_record( \
       lat_cntrs_unstruc_RAP, lat_cntrs_unstruc_all_grids, 0)

    lon_verts_unstruc_all_grids \
    := array_append_record( \
       lon_verts_unstruc_RAP, lon_verts_unstruc_all_grids, 0)

    lat_verts_unstruc_all_grids \
    := array_append_record( \
       lat_verts_unstruc_RAP, lat_verts_unstruc_all_grids, 0)

  end if
;
; **********************************************************************
;
; 
;
; **********************************************************************
;
  if (show_wrtcmp_grid) then
;
; **********************************************************************
;
; If the write-component coordinate arrays are not of the same data type
; as the FV3SAR coordinate arrays, convert the data type of the former
; to that of the latter.
;
; **********************************************************************
;
    if (.not. strcmp_exact(coord_data_type_FV3SAR, coord_data_type_wrtcmp)) then

      lon_cntrs_unstruc_wrtcmp \
      := totype(lon_cntrs_unstruc_wrtcmp, coord_data_type_FV3SAR)

      lat_cntrs_unstruc_wrtcmp \
      := totype(lat_cntrs_unstruc_wrtcmp, coord_data_type_FV3SAR)

      lon_verts_unstruc_wrtcmp \
      := totype(lon_verts_unstruc_wrtcmp, coord_data_type_FV3SAR)

      lat_verts_unstruc_wrtcmp \
      := totype(lat_verts_unstruc_wrtcmp, coord_data_type_FV3SAR)

    end if
;
; **********************************************************************
;
; Prepend write-component coordinates to the corresponding arrays for the FV3SAR.
; This is done for plotting convenience.  Note that the write-component coordinates
; are prepended insted of appended so that the write-component grid (and any field
; associated with it) is drawn first and the FV3SAR tiles (and any 
; fields on them) are then drawn on top.
;
; **********************************************************************
;
    lon_cntrs_unstruc_all_grids \
    := array_append_record( \
       lon_cntrs_unstruc_wrtcmp, lon_cntrs_unstruc_all_grids, 0)

    lat_cntrs_unstruc_all_grids \
    := array_append_record( \
       lat_cntrs_unstruc_wrtcmp, lat_cntrs_unstruc_all_grids, 0)

    lon_verts_unstruc_all_grids \
    := array_append_record( \
       lon_verts_unstruc_wrtcmp, lon_verts_unstruc_all_grids, 0)

    lat_verts_unstruc_all_grids \
    := array_append_record( \
       lat_verts_unstruc_wrtcmp, lat_verts_unstruc_all_grids, 0)

  end if
;
; **********************************************************************
;
; If the plots will show the RAP domain's boundary, then prepend the RAP
; boundary coordinate arrays to the boundary coordinate arrays that will
; contain coordinate information for all grids.
;
; **********************************************************************
;
  if (show_RAP_bdy) then

    num_bdies_to_plot = num_bdies_to_plot + 1

    if (.not. strcmp_exact(coord_data_type_FV3SAR, coord_data_type_RAP)) then
      lon_bdy_RAP := totype(lon_bdy_RAP, coord_data_type_FV3SAR)
      lat_bdy_RAP := totype(lat_bdy_RAP, coord_data_type_FV3SAR)
    end if

    lon_bdy_all_bdies \
    := array_append_record(lon_bdy_all_bdies, lon_bdy_RAP, 0)
    lat_bdy_all_bdies \
    := array_append_record(lat_bdy_all_bdies, lat_bdy_RAP, 0)

  end if
;
; **********************************************************************
;
; If the plots will show the write-component domain's boundary, then 
; prepend the _write-component boundary coordinate arrays to the bounda-
; ry coordinate arrays that will contain coordinate information for all
; grids.
;
; **********************************************************************
;
  if (show_wrtcmp_bdy) then

    num_bdies_to_plot = num_bdies_to_plot + 1

    if (.not. strcmp_exact(coord_data_type_FV3SAR, coord_data_type_wrtcmp)) then
      lon_bdy_wrtcmp := totype(lon_bdy_wrtcmp, coord_data_type_FV3SAR)
      lat_bdy_wrtcmp := totype(lat_bdy_wrtcmp, coord_data_type_FV3SAR)
    end if

    lon_bdy_all_bdies \
    := array_append_record(lon_bdy_all_bdies, lon_bdy_wrtcmp, 0)
    lat_bdy_all_bdies \
    := array_append_record(lat_bdy_all_bdies, lat_bdy_wrtcmp, 0)

  end if
;
; **********************************************************************
;
; Remove the first elements of lon_bdy_all_bdies and lat_bdy_all_bdies
; (since they are dummy values).
;
; **********************************************************************
;
  num_bdy_pts := dimsizes(lon_bdy_all_bdies)
  if (num_bdy_pts .gt. 1) then
    lon_bdy_all_bdies := lon_bdy_all_bdies(1:)
    lat_bdy_all_bdies := lat_bdy_all_bdies(1:)
  end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  file_field_info \
  := set_file_field_names( \
     gtype, \
     inds_tiles_to_plot, \
     field_name, \
     is_gridfield, \
\
     remove_halo_tiles_to_plot, \
\
     grid_fn_tiles_to_plot, \
     nxhSG_tiles_to_plot, \
     nyhSG_tiles_to_plot, \
     nxSG_tiles_to_plot, \
     nySG_tiles_to_plot, \
\
     run_dir, \
     file_basename, \
     nxh_tiles_to_plot, \
     nyh_tiles_to_plot, \
     nx_tiles_to_plot, \
     ny_tiles_to_plot, \
\
     vert_inds_to_plot, \
     time_inds_to_plot, \
\
     horiz_dist_units, \
     horiz_area_units)

  file_names_by_tile := file_field_info@file_names_by_tile
  field_names_by_tile := file_field_info@field_names_by_tile
  func_xy_only := file_field_info@func_xy_only
  func_xyz_only := file_field_info@func_xyz_only
  func_xyt_only := file_field_info@func_xyt_only
  func_xyzt_only := file_field_info@func_xyzt_only
  average_in_x := file_field_info@average_in_x
  average_in_y := file_field_info@average_in_y
;
; **********************************************************************
;
; Loop through all specified forecast hours and vertical indices and ge-
; nerate plots.
;
; **********************************************************************
;
  num_fcst_hrs = dimsizes(fcst_hrs_to_plot)
  num_vert_inds = dimsizes(vert_inds_to_plot)

  do n=0, num_fcst_hrs-1
    do k=0, num_vert_inds-1
  
      print("")
      print("")
      print("" + separator_line)
      print("" + separator_line)
      print("n = " + n + "; k = " + k)
      print("" + separator_line)
      print("" + separator_line)
  
      vert_indx = vert_inds_to_plot(k)
      time_indx = time_inds_to_plot(n)
      fcst_hr = fcst_hrs_to_plot(n)
;
; **********************************************************************
;
; Read in the FV3SAR field for the current forecast hour and vertical 
; index.
;
; **********************************************************************
;
      if (is_gridfield) then

        field_info \
        := read_FV3SAR_gridfield_native( \
           field_names_by_tile, \
           file_names_by_tile, \
           gtype, inds_tiles_to_plot, \
           nh_tiles_to_plot, \
           nxh_tiles_to_plot, nyh_tiles_to_plot, \
           nx_tiles_to_plot, ny_tiles_to_plot, \
           remove_halo_tiles_to_plot, \
           vert_indx, time_indx, \
           horiz_dist_units, horiz_area_units \
           )

      else

        field_info \
        := read_FV3SAR_field_native( \
           field_names_by_tile, \
           file_names_by_tile, \
           gtype, inds_tiles_to_plot, \
           nh_tiles_to_plot, \
           nxh_tiles_to_plot, nyh_tiles_to_plot, \
           nx_tiles_to_plot, ny_tiles_to_plot, \
           remove_halo_tiles_to_plot, \
           vert_indx, time_indx, \
           func_xy_only, func_xyz_only, func_xyt_only, func_xyzt_only, \
           average_in_x, average_in_y)

      end if

;      fp_field_FV3SAR = field_info@fp  ; This would in general be an array or list of file pointers.
      field_desc := field_info@field_desc
      field_units := field_info@field_units
      nz_by_tile := field_info@nz_by_tile
      nt_by_tile := field_info@nt_by_tile
      field_unstruc := field_info@field_by_tile_unstruc
      field_min_tiles_to_plot := field_info@field_min_by_tile
      field_max_tiles_to_plot := field_info@field_max_by_tile
      field_median_tiles_to_plot := field_info@field_median_by_tile
      field_mean_tiles_to_plot := field_info@field_mean_by_tile
      field_data_type_FV3SAR := field_info@field_data_type
; Not sure why setting field_name to "none" doesn't do this, but do this
; here temporarily to make the field transparent.
;field_unstruc = default_fillvalue(field_data_type_FV3SAR)
;
; **********************************************************************
;
; Calculate and print out basic statistics of the field over all tiles
; to be plotted.
;
; **********************************************************************
;
      inds_tiles_to_plot_str \
      := str_join(tostring(inds_tiles_to_plot), ", ")
      inds_tiles_to_plot_str \
      := str_concat( (/"[tile(s) ", inds_tiles_to_plot_str, "]"/) )

      msg := \
"Calculating statistics of field over all FV3 tiles to be plotted " + char_nl + \
inds_tiles_to_plot_str + " ..."

      print("")
      print("" + separator_line)
      print("" + msg)
     
      print_field_stats = False
      field_stat_info \
      := calc_field_stats( \
         field_unstruc, field_desc, field_units, print_field_stats)
      msg := "  " + field_stat_info@msg
      print("")
      print("" + msg)
     
      msg := \
"Done calculating statistics of field over all FV3 tiles to be plotted."
      print("")
      print("" + msg)
      print("" + separator_line)
;
; **********************************************************************
;
; Save field statistics in appropriate variables.
;
; **********************************************************************
;
      field_min := field_stat_info@field_min
      field_max := field_stat_info@field_max
      field_median := field_stat_info@field_median
      field_mean := field_stat_info@field_mean
;
; **********************************************************************
;
; Initialize the 1-D unstructured array that will contain the field val-
; ues on all grids (FV3SAR and possibly also RAP) and initialize it to 
; the field values on the FV3SAR tile grids.
;
; **********************************************************************
;
      field_unstruc_all_grids := field_unstruc
;
; **********************************************************************
;
; If show_RAP_grid or plot_RAP_field is set to True, read in the speci-
; fied field on the RAP grid.  Note that if show_RAP_grid is True but 
; plot_RAP_field is False, the field retruned on the RAP grid will con-
; sist of missing values, i.e. the plot will not show a field on the RAP
; domain; it will only show the RAP grid (gridlines).  This occurs be-
; cause in this case, during the processing of the variables defined on 
; the command line, the original setting (if any) of field_name_RAP is
; ignored, and field_name_RAP is (re)set to "none", causing the read_-
; RAP_field(...) function below to return a field of missing values in 
; the field_unstruc attribute of the return variable.
;
; **********************************************************************
;
      if (show_RAP_grid .or. plot_RAP_field) then
;
; **********************************************************************
;
; Read in the specified field on the RAP domain.
;
; **********************************************************************
;
        field_info := read_RAP_field( \
                      field_name_RAP, \
                      horiz_dist_units, \
                      horiz_area_units, \
                      RAP_fn, \
                      nx_RAP, \
                      ny_RAP)

;        fp_field_RAP = field_info@fp
        field_desc_RAP := field_info@field_desc
        field_units_RAP := field_info@field_units
        field_unstruc_RAP := field_info@field_unstruc
        field_min_RAP := field_info@field_min
        field_max_RAP := field_info@field_max
        field_median_RAP := field_info@field_median
        field_mean_RAP := field_info@field_mean
        field_data_type_RAP := field_info@field_data_type
;
; **********************************************************************
;
; For plotting convenience, we will combine the fields on the FV3SAR andi
; RAP grids into a single array.  For this purpose, if necessary we 
; first convert the data type of the RAP field to that of the FV3SAR
; field.
;
; **********************************************************************
;
        if (.not. strcmp_exact(field_data_type_FV3SAR, field_data_type_RAP)) then
          field_unstruc_RAP \
          := totype(field_unstruc_RAP, field_data_type_FV3SAR)
        end if
;
; **********************************************************************
;
; For plotting convenience, prepend the RAP field to the array contain-
; ing the FV3SAR field.  We prepend instead of append so that the RAP 
; field is drawn first and the FV3SAR field on the tiles are then drawn
; on top.
;
; **********************************************************************
;
        field_unstruc_all_grids \
        := array_append_record( \
           field_unstruc_RAP, field_unstruc_all_grids, 0)

      end if
;
; **********************************************************************
;
; Calculate and print out basic statistics of the field, now including
; the RAP field.
;
; **********************************************************************
;
      msg := \
"Calculating statistics of combined field on all grids ..."
      print("")
      print("" + separator_line)
      print("" + msg)
    
      print_field_stats = False
      field_stat_info \
      := calc_field_stats( \
         field_unstruc_all_grids, field_desc, field_units, print_field_stats)
      msg := "  " + field_stat_info@msg
      print("")
      print("" + msg)
    
      field_min := field_stat_info@field_min
      field_max := field_stat_info@field_max
      field_median := field_stat_info@field_median
      field_mean := field_stat_info@field_mean
  
      msg := \
"Done calculating statistics of combined field on all grids."
      print("")
      print("" + msg)
      print("" + separator_line)
;
; **********************************************************************
;
; Set the name of the graphics file that will contain the plot.  We al-
; ways include the name of the field on the first tile to be plotted.
; If there is more than one tile to plot and if the field names happen
; to be different on the various tiles, we add the string "ETC" after 
; the field name in the file name to indicate that not all fields are
; the same.
;
; **********************************************************************
;
      fn_graphics = field_names_by_tile(0)
      match_found := strcmp_exact(field_names_by_tile, fn_graphics)
      match_by_elem := match_found@match_by_elem
      if (.not. all(match_by_elem)) then
        fn_graphics := fn_graphics + "ETC"
      end if

      fmt_str = "%03i"
      vert_indx_str = sprinti(fmt_str, vert_indx)
      fcst_hr_str = sprinti(fmt_str, fcst_hr)
      fn_graphics := cres + "_grid_" + fn_graphics \
                   + "_f" + fcst_hr_str + "_k" + vert_indx_str
;
; **********************************************************************
;
; Generate plot title string(s).
;
; **********************************************************************
;
      title_info \
      := make_plot_titles( \
         inds_tiles_to_plot, \
         nz_by_tile, vert_indx, \
\
         field_name, field_desc, field_units, \
         func_xyz_only, func_xyzt_only, \
         field_min_tiles_to_plot, field_max_tiles_to_plot, \
         tile_bdy_color, \
\
         show_RAP_grid, plot_RAP_field, \
         field_name_RAP, field_desc_RAP, field_units_RAP, \
         RAP_bdy_color, \
\
         nn)
      
      left_str := title_info@left_str
      main_str := title_info@main_str
      right_str := title_info@right_str
;
; **********************************************************************
;
; Set general plotting options that will be passed to the plotting func-
; tion.
;
; **********************************************************************
;
      plot_opts := True

      plot_opts@map_proj = map_proj
      plot_opts@map_proj_ctr = map_proj_ctr
;
; Set the flag that determines whether plots will be resized (e.g. to a
; larger area than the default).  This would generally be done using the
; gsnMaximize resource, but it's not clear how to use or reset this re-
; source after adding annotations to the plot (annotations in our case
; are the plot titles).  Thus, we perform the resizing/maximization man-
; ually.
;
      plot_opts@resize_plot = True
;
; Set the size (either width or height) of the bounding box which the 
; resized plot will have.  Note that this is in NDC (non-dimensional co-
; ordinate, aka page) coordinates.  This value must be between 0 and 1.
;
      plot_opts@bounding_box_size_NDC = 0.98

      if (plot_subreg) then
        plot_opts@plot_subreg = plot_subreg
        plot_opts@subreg_limits = subreg_limits
      end if

      plot_opts@left_str = left_str
      plot_opts@main_str = main_str
      plot_opts@right_str = right_str
;
; **********************************************************************
;
; Calculate "nice" contour level values to use for making a color con-
; tour plot of the combined FV3SAR and RAP field.
;
; **********************************************************************
;
      msg := \
"Calculating " + char_dq + "nice" + char_dq + " contour values from " + \
"the field's minimum and maximum " + char_nl + \
"values ..."
      print("")
      print("" + separator_line)
      print("" + msg)

      num_cnLevels = 20
      opts := True
      opts@verbose = False
; Numbers for custom plot for Jeff.
;field_min = 2.65
;field_max = 3.6
;num_cnLevels = 23
;field_min = 9.0
;field_min = 8.0
;field_min = 7.95
;field_max = 15.5
;num_cnLevels = 23
      contour_info := set_cnLevels_lbLabels( \
                      field_min, field_max, num_cnLevels, opts)
      copy_VarAtts(contour_info, plot_opts)

      msg := \
"Done calculating " + char_dq + "nice" + char_dq + " contour values."
      print("")
      print("" + msg)
      print("" + separator_line)
;
; **********************************************************************
;
; Set the arrays containing the number of grid points in the x and y di-
; rections for all tiles and grids to be plotted.
;
; **********************************************************************
;
      nx_all_grids \
      := where(remove_halo_tiles_to_plot, \
               nx_tiles_to_plot, nxh_tiles_to_plot)
      ny_all_grids \
      := where(remove_halo_tiles_to_plot, \
               ny_tiles_to_plot, nyh_tiles_to_plot)

      if (show_RAP_grid .or. plot_RAP_field) then
        nx_all_grids := array_append_record(nx_RAP, nx_all_grids, 0)
        ny_all_grids := array_append_record(ny_RAP, ny_all_grids, 0)
      end if
      if (show_wrtcmp_grid) then
        nx_all_grids := array_append_record(nx_wrtcmp, nx_all_grids, 0)
        ny_all_grids := array_append_record(ny_wrtcmp, ny_all_grids, 0)
      end if
;
; **********************************************************************
;
; Set attributes of the grid_opts variable.  These attributes will be 
; used in the plotting function if plotting the grids (gridlines).
;
; **********************************************************************
;
      num_grids_to_plot = num_tiles_to_plot

      if (show_RAP_grid .or. plot_RAP_field) then
        num_grids_to_plot = num_grids_to_plot + 1
      end if

      if (show_wrtcmp_grid) then
        num_grids_to_plot = num_grids_to_plot + 1
      end if

      if (num_grids_to_plot .gt. 0) then

        plot_grid := new(num_grids_to_plot, "logical")
        plot_grid = show_tile_grids
        gridline_colors := new(num_grids_to_plot, "string")
        gridline_colors = tile_bdy_color
  
        if (show_RAP_grid .or. plot_RAP_field) then
          plot_grid(0) = show_RAP_grid
          gridline_colors(0) = RAP_bdy_color
        end if

        if (show_wrtcmp_grid) then
          plot_grid(1) = show_wrtcmp_grid
          gridline_colors(1) = wrtcmp_bdy_color
        end if

        grid_opts := True
        grid_opts@num_grids = num_grids_to_plot
        grid_opts@plot_grid = plot_grid
        grid_opts@gridline_colors = gridline_colors

      else

        grid_opts := False

      end if
;
; **********************************************************************
;
; If the number of tile/grid boundaries to plot is greater than 0, then
; set the dimensions in the x and y directions of each such tile/grid 
; and various plotting properties.
;
; **********************************************************************
;
      native_tag = "native"
      wrtcmp_tag = "wrtcmp"
      extrnl_tag = "extrnl"

      bdy_plot_order := new(num_bdies_to_plot, "string")
bdy_plot_order(0) = wrtcmp_tag
bdy_plot_order(1) = extrnl_tag
bdy_plot_order(2) = native_tag

      indx_ptr_start := new(num_bdies_to_plot, "integer")
      indx_ptr_end := new(num_bdies_to_plot, "integer")

      bdy_opts := False

      if (num_bdies_to_plot .gt. 0) then

        bdy_plot_order_str := char_dq + bdy_plot_order + char_dq
        bdy_plot_order_str := str_join(bdy_plot_order_str, ", ")
        bdy_plot_order_str := "(/ " + bdy_plot_order_str + " /)"

        nx_all_bdies := new(num_bdies_to_plot, "integer")
        ny_all_bdies := new(num_bdies_to_plot, "integer")
        plot_bdy := new(num_bdies_to_plot, "logical")
        bdy_colors := new(num_bdies_to_plot, "string")
        bdy_line_thicknesses := new(num_bdies_to_plot, "float")
        bdy_dash_patterns := new(num_bdies_to_plot, "integer")

        nbdy = 0

        if (show_tile_bdies) then

          nx_all_bdies(nbdy:num_tiles_to_plot-1) \
          = where(remove_halo_tiles_to_plot, \
                  nx_tiles_to_plot, nxh_tiles_to_plot)
          ny_all_bdies(nbdy:num_tiles_to_plot-1) \
          = where(remove_halo_tiles_to_plot, \
                  ny_tiles_to_plot, nyh_tiles_to_plot)

          plot_bdy(nbdy:num_tiles_to_plot-1) = show_tile_bdies
          bdy_colors(nbdy:num_tiles_to_plot-1) = tile_bdy_color
          bdy_line_thicknesses(nbdy:num_tiles_to_plot-1) = 4.0
          bdy_dash_patterns(nbdy:num_tiles_to_plot-1) = 0

          indx_start_native = nbdy
          indx_end_native = indx_start_native + num_tiles_to_plot - 1
          nbdy = nbdy + num_tiles_to_plot

          tag := native_tag
          if (.not. strcmp_exact(bdy_plot_order, tag)) then
            msg := char_nl + \
"Since show_wrtcmp_bdy is set to True, the string array bdy_plot_order " + char_nl + \
"must include " + char_dq + tag + char_dq + " as one of its elements:" + char_nl + \
"  bdy_plot_order = " + bdy_plot_order_str + char_nl + \
"Stopping."
            print("" + msg)
            exit
          end if

        end if

        if (show_RAP_bdy) then

          nx_all_bdies(nbdy) = nx_RAP
          ny_all_bdies(nbdy) = ny_RAP

          plot_bdy(nbdy) = show_RAP_bdy
          bdy_colors(nbdy) = RAP_bdy_color
          bdy_line_thicknesses(nbdy) = 4.0
          bdy_dash_patterns(nbdy) = 1

          indx_start_extrnl = nbdy
          indx_end_extrnl = indx_start_extrnl
          nbdy = nbdy + 1

          tag := extrnl_tag
          if (.not. strcmp_exact(bdy_plot_order, tag)) then
            msg := char_nl + \
"Since show_wrtcmp_bdy is set to True, the string array bdy_plot_order " + char_nl + \
"must include " + char_dq + tag + char_dq + " as one of its elements:" + char_nl + \
"  bdy_plot_order = " + bdy_plot_order_str + char_nl + \
"Stopping."
            print("" + msg)
            exit
          end if

        end if

        if (show_wrtcmp_bdy) then

          nx_all_bdies(nbdy) = nx_wrtcmp
          ny_all_bdies(nbdy) = ny_wrtcmp

          plot_bdy(nbdy) = show_wrtcmp_bdy
          bdy_colors(nbdy) = wrtcmp_bdy_color
          bdy_line_thicknesses(nbdy) = 4.0
          bdy_dash_patterns(nbdy) = 1

          indx_start_wrtcmp = nbdy
          indx_end_wrtcmp = indx_start_wrtcmp
          nbdy = nbdy + 1

          tag = wrtcmp_tag
          if (.not. strcmp_exact(bdy_plot_order, tag)) then
            msg := char_nl + \
"Since show_wrtcmp_bdy is set to True, the string array bdy_plot_order " + char_nl + \
"must include " + char_dq + tag + char_dq + " as one of its elements:" + char_nl + \
"  bdy_plot_order = " + bdy_plot_order_str + char_nl + \
"Stopping."
            print("" + msg)
            exit
          end if

        end if
;
; Use the tile/grid dimensions in the x and y directions to calculate
; the number of boundary points for each tile/grid.
;
        num_bdy_pts_all_bdies := 2*(nx_all_bdies + ny_all_bdies) + 1      
;
; Set attributes of the bdy_opts variable to the various plotting pro-
; perties set above.  These attributes will be used in the plotting 
; function if plotting tile and/or grid boundaries.
;
        bdy_opts := True
        bdy_opts@num_bdies = num_bdies_to_plot
        bdy_opts@num_bdy_pts_all_bdies = num_bdy_pts_all_bdies
        bdy_opts@plot_bdy = plot_bdy
        bdy_opts@bdy_colors = bdy_colors
        bdy_opts@bdy_line_thicknesses = bdy_line_thicknesses
        bdy_opts@bdy_dash_patterns = bdy_dash_patterns

      end if



if (False) then
do i=0, num_bdies_to_plot-1
print("i = " + i)
  if (strcmp_exact(bdy_plot_order(i), "native")) then
    indx_ptr_start(i) = indx_start_native
    indx_ptr_end(i) = indx_end_native
  else if (strcmp_exact(bdy_plot_order(i), "wrtcmp")) then
    indx_ptr_start(i) = indx_start_wrtcmp
    indx_ptr_end(i) = indx_end_wrtcmp
  else if (strcmp_exact(bdy_plot_order(i), "extrnl")) then
    indx_ptr_start(i) = indx_start_extrnl
    indx_ptr_end(i) = indx_end_extrnl
  end if
  end if
  end if

end do
end if

;
; **********************************************************************
;
; Call the plotting function to generate a color contour plot of speci-
; fied fields, grids, and/or grid boundaries.
;
; **********************************************************************
;
; Does field_unstruc_all_grids need to have a _FilLValue attribute in 
; order for its FillValue points to be ignored?  Not sure...
;field_unstruc_all_grids@_FillValue = default_fillvalue(typeof(field_unstruc))

; Temporarily make the field all missing/fill values, so we can see grids/boundaries.
;field_unstruc_all_grids = field_unstruc_all_grids@_FillValue

      plot_info := plot_horiz_field( \
                   fn_graphics, \
                   nx_all_grids, ny_all_grids, \
                   lon_cntrs_unstruc_all_grids, lat_cntrs_unstruc_all_grids, \
                   lon_verts_unstruc_all_grids, lat_verts_unstruc_all_grids, \
                   lon_bdy_all_bdies, lat_bdy_all_bdies, \
                   field_unstruc_all_grids, \
                   grid_opts, \
                   bdy_opts, \
                   plot_opts)

print("BYE!!!!!!!!!!!!!!!!!!!!!!!")


    end do
  end do


end






