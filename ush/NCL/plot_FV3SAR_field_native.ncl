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

show_tile_grids = True
show_tile_grids = False

file_basename = "atmos_static"
;file_basename = "fv3_history"

field_name = "area"
;field_name = "sqrt_area"
;field_name = "dx"
;field_name = "dy"
;field_name = "dx_ovr_dy"
;field_name = "min_dx_dy"
;field_name = "angle_dx"
;field_name = "angle_dy"

;field_name = "orog_raw"
;field_name = "orog_filt"

;field_name = "time"
;field_name = "grid_xt"
;field_name = "vflx_ave"
;field_name = "ref3D"

;field_name = "spfh"
field_name = "zsurf"

;field_name = "none"


map_proj = "cyln"
;map_proj = "ortho"

;map_proj_ctr = (/ -98.5, 30.0 /) ; This should be set to (0,0) for "cyln" map projection.


plot_subreg = True
plot_subreg = False

;subreg_limits := (/ -180, 180, -90, 90 /)
;subreg_limits := (/ -75, -45, 30, 60 /)
;subreg_limits := (/ -145, -90, 30, 60 /)
;subreg_limits := (/ -120, -115, 30, 35 /)
;subreg_limits := (/ -15, 0, 0, 15 /)
;subreg_limits := (/ -30, 0, 0, 30 /)
;subreg_limits := (/ -60, -30, 0, 30 /)
subreg_limits := (/ -75, -60, 0, 15 /)
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
subreg_limits := (/ -70, -55, -20, -5 /)

remove_rgnl_halo = True
;remove_rgnl_halo = False






show_RAP_bdy = True
;show_RAP_bdy = False

show_RAP_grid = True
show_RAP_grid = False

plot_RAP_field = True
;plot_RAP_field = False

field_name_RAP = "none"
field_name_RAP = "area"
;field_name_RAP = "MAPFAC_M"

RAP_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509"
;RAP_grid_fn = "/home/Gerard/fv3_regional/fv3sar_workflow/ush/NCL/plot_grid.ncl"
;RAP_grid_fn = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/geo_em.d01.RAP.nc"
RAP_grid_fn = RAP_dir + "/geo_em.d01.RAP.nc"

horiz_dist_units = "m"
;horiz_dist_units = "km"





time_inds_to_plot := (/ 0, 2 /)
time_inds_to_plot := (/ 2 /)


fcst_output_hrs := (/ 0, 1, 2, 3, 4, 5, 6 /)  ; Read this in from file, e.g. var_defns.sh.
;fcst_output_hrs := (/ 0, 2, 4, 6 /)  ; Read this in from file, e.g. var_defns.sh.
fcst_hrs_to_plot = fcst_output_hrs(time_inds_to_plot)
;print("" + time_inds_to_plot)
;print("" + fcst_hrs_to_plot)
;pause

vert_inds_to_plot := (/ 0, 10 /)
vert_inds_to_plot := (/ 10 /)



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
;lib_location = "lib/"
lib_location = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/fv3sar_workflow/ush/NCL/lib/"

loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "pause.ncl")
loadscript(lib_location + "strcmp_exact.ncl")
loadscript(lib_location + "repeat_str.ncl")
loadscript(lib_location + "calc_field_stats.ncl")
loadscript(lib_location + "get_rect_grid_bdy.ncl")
loadscript(lib_location + "set_cnLevels_lbLabels.ncl")

load "process_plot_params.ncl"
load "read_FV3SAR_grid_native.ncl"
load "read_FV3SAR_field_native.ncl"
load "read_FV3SAR_grid_wrtcomp.ncl"
load "read_FV3SAR_field_wrtcomp.ncl"
load "read_RAP_grid.ncl"
load "read_RAP_field.ncl"
load "plot_horiz_field.ncl"

load "check_var_existence_dims.ncl"

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
;
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
  show_tile_grids = plot_params@show_tile_grids
  show_RAP_bdy = plot_params@show_RAP_bdy
  show_RAP_grid = plot_params@show_RAP_grid
  plot_RAP_field = plot_params@plot_RAP_field
  field_name_RAP = plot_params@field_name_RAP
  graphics_type = plot_params@graphics_type
  map_proj = plot_params@map_proj
  map_proj_ctr = plot_params@map_proj_ctr
  remove_rgnl_halo = plot_params@remove_rgnl_halo
  plot_subreg = plot_params@plot_subreg
  subreg_limits = plot_params@subreg_limits
  field_name = plot_params@field_name
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

  grid_info := read_FV3SAR_grid_native( \
               work_dir, \
               gtype, \
               cres, \
               inds_tiles_to_plot, \
               show_tile_bdies, \
               nhalo_T7, \
               remove_rgnl_halo)

  grid_files_tiles_to_plot = grid_info@grid_files
  nx_tiles_to_plot = grid_info@nx_all_tiles
  ny_tiles_to_plot = grid_info@ny_all_tiles
  lon_cntrs_unstruc = grid_info@lon_cntrs_all_tiles_unstruc
  lat_cntrs_unstruc = grid_info@lat_cntrs_all_tiles_unstruc
  lon_verts_unstruc = grid_info@lon_verts_all_tiles_unstruc
  lat_verts_unstruc = grid_info@lat_verts_all_tiles_unstruc
  lon_bdy = grid_info@lon_bdy_all_tiles
  lat_bdy = grid_info@lat_bdy_all_tiles
  coord_data_type_FV3SAR = grid_info@coord_data_type
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

  lon_bdy_all_grids := lon_bdy
  lat_bdy_all_grids := lat_bdy
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
if (insert_missing_delimiter) then
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
; If the plots will show the RAP domain's boundary, then prepend the RAP
; boundary coordinate arrays to the boundary coordinate arrays that will
; contain coordinate information for all grids.
;
; **********************************************************************
;
  if (show_RAP_bdy) then
;
; If the RAP boundary coordinates are not the same data type as the FV3-
; SAR coordinates, convert the type of the former to that of the latter.
;
    if (.not. strcmp_exact(coord_data_type_FV3SAR, coord_data_type_RAP)) then
      lon_bdy_RAP := totype(lon_bdy_RAP, coord_data_type_FV3SAR)
      lat_bdy_RAP := totype(lat_bdy_RAP, coord_data_type_FV3SAR)
    end if
;  Note
; that unlike the grid point coordinates, the boundary coordinates of 
; the FV3SAR and RAP in lon_bdy_all_grids and lat_bdy_all_grids are delmimited by missing 
; values (as are the boundary coordinates of individual tiles of the 
; FV3SAR).  This is done so that lines are not drawn from the last point
; on the boundary of one tile or grid to the starting point on the next
; one.
;
    lon_bdy_RAP \
    := array_append_record( \
       lon_bdy_RAP, default_fillvalue(coord_data_type_FV3SAR), 0)

    lat_bdy_RAP \
    := array_append_record( \
       lat_bdy_RAP, default_fillvalue(coord_data_type_FV3SAR), 0)
;
; If show_tile_bdies is set to True, then the arrays lon_bdy_all_grids
; and lat_bdy_all_grids will already contain the boundary coordinates of
; all the FV3 grid tiles to be plotted.  In this case, prepend the RAP
; boundary coordinates to those of the FV3SAR and store the results in
; lon_bdy_all_grids and lat_bdy_all_grids.  We prepend instead of append
; in order to be consistent with the way the grid point coordinates of
; the FV3SAR and RAP grids are combined.
;
    if (show_tile_bdies) then

      lon_bdy_all_grids \
      := array_append_record(lon_bdy_RAP, lon_bdy_all_grids, 0)

      lat_bdy_all_grids \
      := array_append_record(lat_bdy_RAP, lat_bdy_all_grids, 0)
;
; If show_tile_bdies is set to False, then the arrays lon_bdy_all_grids
; and lat_bdy_all_grids will not contain the boundary coordinates of the
; FV3SAR tiles but instead will contain single missing values.  In this
; case, redefine them to be equal to the boundary coordinates of the RAP
; grid.
;
    else

      lon_bdy_all_grids := lon_bdy_RAP
      lat_bdy_all_grids := lat_bdy_RAP

    end if

  end if
;
; **********************************************************************
;
; Set the dimension names we expect to see in the file(s) from which we
; will read in the field.  This depends on the file base name.  These
; dimension names will be used to check the consistency of the dimen-
; sions of the specified field.
;
; **********************************************************************
;
  if (strcmp_exact(file_basename, "grid_spec")) then
    x_filedim_names = (/ "grid_x", "grid_xt" /)
    y_filedim_names = (/ "grid_y", "grid_yt" /)
    z_filedim_names = (/ "phalf", "pfull" /)
    t_filedim_names = (/ "time" /)
  else if (strcmp_exact(file_basename, "atmos_static") .or. \
           strcmp_exact(file_basename, "fv3_history") .or. \
           strcmp_exact(file_basename, "fv3_history2d") .or. \
           strcmp_exact(file_basename, "ref3D")) then
    x_filedim_names = (/ "grid_xt" /)
    y_filedim_names = (/ "grid_yt" /)
    z_filedim_names = (/ "phalf", "pfull" /)
    t_filedim_names = (/ "time" /)
  else
    msg := char_nl + \
"Unknown file base name (file_basename) specified:" + char_nl + \
"  file_basename = " + char_dq + file_basename + char_dq + char_nl + \
"Stopping."
    print("" + msg)
    exit
  end if
  end if
;
; **********************************************************************
;
; Loop through the specified tiles and form the file name corresponding
; to each tile.  Also, set the field name for each tile.
;
; **********************************************************************
;
  file_names_by_tile = new((/ num_tiles_to_plot /), "string")
  field_names_by_tile = new((/ num_tiles_to_plot /), "string")

  print("")
  print("" + separator_line)
  msg := \
"Setting file and field name for each specified tile ..." + char_nl + \
"[The field name for a tile will be set to " + char_dq + "none" + char_dq + \
" if a file for that tile " + char_nl + \
"does not exist, e.g. if the tile in consideration is #5, but we are on a " + char_nl + \
"regional grid (in which case files/fields are only available on tile #7).]"
  print("" + msg)

  do nn=0, num_tiles_to_plot-1

    print("")
    msg := "nn = " + nn
    print("" + msg)
    underline = repeat_str("-", strlen(msg))
    print("" + underline)

    n_tile = inds_tiles_to_plot(nn)
    print("")
    print("  n_tile = " + n_tile)
;
; **********************************************************************
;
; Generate the file name for the current tile.
;
; **********************************************************************
;
    file_name := run_dir + "/" + file_basename
    if (.not. strcmp_exact(gtype, "regional")) then
      file_name := file_name + ".tile" + tostring(n_tile)
    end if
    file_name := file_name + ".nc"
    file_names_by_tile(nn) = file_name

    print("  file_names_by_tile(" + nn + ") = " + \
          char_dq + file_names_by_tile(nn) + char_dq) 
;
; **********************************************************************
;
;
;
; **********************************************************************
;
    field_names_by_tile(nn) = field_name
    if (strcmp_exact(gtype, "regional") .and. (n_tile .ne. 7)) then
      field_names_by_tile(nn) = "none"
      msg := char_nl + \
"  The specified field is not available on the current tile:" + char_nl + \
"    n_tile = " + n_tile + char_nl + \
"    field_name = " + char_dq + field_name + char_dq + char_nl + \
"  Setting the field name for the current tile to " + char_dq + "none" + char_dq + ":" + char_nl + \
"    field_names_by_tile(" + nn + ") = " + char_dq + field_names_by_tile(nn) + char_dq
      print("" + msg)
    else
      print("  field_names_by_tile(" + nn + ") = " + \
            char_dq + field_names_by_tile(nn) + char_dq)
    end if
;
; **********************************************************************
;
; Call a function that runs various checks on the specified field.  This
; function will:
;
; 1) Verify that the field exists as a as a variable in the file.
; 2) Verify that its functional dependence on space and time is one of
;    the following:
;    a) Function of only the two horizontal directions but not the ver-
;       tical direction or time.  In this case, the func_xy_only attrib-
;       ute of the returned variable will be set to True. 
;    b) Function of only the two horizontal directions and the vertical
;       direction but not time.  In this case, the func_xyz_only attrib-
;       ute of the returned variable will be set to True. 
;    c) Function of only the two horizontal directions and time but not
;       the vertical direction.  In this case, the func_xyt_only attrib-
;       ute of the returned variable will be set to True. 
;    d) Function of the two horizontal directions, the vertical direc-
;       tion, and time.  In this case, the func_xyzt_only attribute of
;       the returned variable will be set to True. 
; 3) Verify that the specified vertical and/or time indices do not ex-
;    ceed the array bounds of the variable that represents the specified
;    field.
; 4) Return:
;    a) The rank, dimension names, and dimension sizes of the variable
;       that represents the field.
;    b) The functional dependence of the field on x, y, z, and t.
;
; **********************************************************************
;
;
; **********************************************************************
;
; Perform checks on variable.
;
; **********************************************************************
;
    if (.not. strcmp_exact(field_names_by_tile(nn), "none")) then

      if ((nn .gt. 0) .and. isvar("var_info")) then
        var_info_prev_tile := var_info
      end if

      var_info := check_var_existence_dims( \
                  file_names_by_tile(nn), \
                  field_names_by_tile(nn), \
                  x_filedim_names, \
                  y_filedim_names, \
                  z_filedim_names, \
                  t_filedim_names, \
                  nx_tiles_to_plot(nn), ny_tiles_to_plot(nn), \
                  vert_inds_to_plot, \
                  time_inds_to_plot)

      fp_field_file = var_info@fp  
      var_rank = var_info@var_rank
      var_dim_names = var_info@var_dim_names
      var_dim_sizes = var_info@var_dim_sizes
      func_xy_only = var_info@func_xy_only
      func_xyz_only = var_info@func_xyz_only
      func_xyt_only = var_info@func_xyt_only
      func_xyzt_only = var_info@func_xyzt_only
      average_in_x = var_info@average_in_x
      average_in_y = var_info@average_in_y

      if ((nn .gt. 0) .and. isvar("var_info_prev_tile")) then

        n_tile_prev = inds_tiles_to_plot(nn-1)

        var_rank_prev_tile := var_info_prev_tile@var_rank
        var_dim_names_prev_tile := var_info_prev_tile@var_dim_names
        var_dim_sizes_prev_tile := var_info_prev_tile@var_dim_sizes
        func_xy_only_prev_tile := var_info_prev_tile@func_xy_only
        func_xyz_only_prev_tile := var_info_prev_tile@func_xyz_only
        func_xyt_only_prev_tile := var_info_prev_tile@func_xyt_only
        func_xyzt_only_prev_tile := var_info_prev_tile@func_xyzt_only
        average_in_x_prev_tile := var_info_prev_tile@average_in_x
        average_in_y_prev_tile := var_info_prev_tile@average_in_y

        if (var_rank .eq. var_rank_prev_tile) then
          var_dim_names_differ := False
          do i=0, var_rank_prev_tile-1
            if (.not. strcmp_exact(var_dim_names, var_dim_names_prev_tile(i))) then
              var_dim_names_differ := True
              break
            end if
          end do
        end if

        if (var_rank .ne. var_rank_prev_tile) then

          msg := char_nl + \
"The variable's rank (var_rank) changed from tile " + n_tile_prev + \
" to tile " + n_tile + ":" + char_nl + \
"  var_rank_prev_tile = " + var_rank_prev_tile + char_nl + \
"  var_rank = " + var_rank + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if (var_dim_names_differ) then

          var_dim_names_prev_tile_str \
          := str_join(var_dim_names_prev_tile, char_dq + ", " + char_dq)
          var_dim_names_prev_tile_str \
          := "(" + char_dq + var_dim_names_prev_tile_str + char_dq + ")"

          var_dim_names_str \
          := str_join(var_dim_names, char_dq + ", " + char_dq)
          var_dim_names_str \
          := "(" + char_dq + var_dim_names_str + char_dq + ")"

          msg := char_nl + \
"The variable's dimension names (var_dim_names) changed from tile " + \
n_tile_prev + " to " + char_nl + \
"tile " + n_tile + ":" + char_nl + \
"  var_dim_names_prev_tile = " + var_dim_names_prev_tile_str + char_nl + \
"  var_dim_names = " + var_dim_names_str + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if (any(var_dim_sizes .ne. var_dim_sizes_prev_tile)) then

          var_dim_sizes_prev_tile_str \
          := "(" + str_join(tostring(var_dim_sizes_prev_tile), ", ") + ")"
          var_dim_sizes_str \
          := "(" + str_join(tostring(var_dim_sizes), ", ") + ")"

          msg := char_nl + \
"The variable's dimension sizes (var_dim_sizes) changed from tile " + \
n_tile_prev + " to " + char_nl + \
"tile " + n_tile + ":" + char_nl + \
"  var_dim_sizes_prev_tile = " + var_dim_sizes_prev_tile_str + char_nl + \
"  var_dim_sizes = " + var_dim_sizes_str + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if (func_xy_only .ne. func_xy_only_prev_tile) then

          msg := char_nl + \
"The variable's functional dependence status on only the horizontal " + char_nl + \
"coordinates x and y (func_xy_only) changed from tile " + n_tile_prev + " to " + \
"tile " + n_tile + ":" + char_nl + \
"  func_xy_only_prev_tile = " + func_xy_only_prev_tile + char_nl + \
"  func_xy_only = " + func_xy_only + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if (func_xyz_only .ne. func_xyz_only_prev_tile) then

          msg := char_nl + \
"The variable's functional dependence status on only the horizontal " + char_nl + \
"coordinates x and y and the vertical coordinate (func_xyz_only) " + char_nl + \
"changed from tile " + n_tile_prev + " to tile " + n_tile + ":" + char_nl + \
"  func_xyz_only_prev_tile = " + func_xyz_only_prev_tile + char_nl + \
"  func_xyz_only = " + func_xyz_only + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if (func_xyt_only .ne. func_xyt_only_prev_tile) then

          msg := char_nl + \
"The variable's functional dependence status on only the horizontal " + char_nl + \
"coordinates x and y and time (func_xyt_only) changed from tile " + n_tile_prev + char_nl + \
"to tile " + n_tile + ":" + char_nl + \
"  func_xyt_only_prev_tile = " + func_xyt_only_prev_tile + char_nl + \
"  func_xyt_only = " + func_xyt_only + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if (func_xyzt_only .ne. func_xyzt_only_prev_tile) then

          msg := char_nl + \
"The variable's functional dependence status on the horizontal coordinates " + char_nl + \
"x and y, the vertical coordinate, and time (func_xyzt_only) changed from " + char_nl + \
"tile " + n_tile_prev + " to tile " + n_tile + ":" + char_nl + \
"  func_xyzt_only_prev_tile = " + func_xyzt_only_prev_tile + char_nl + \
"  func_xyzt_only = " + func_xyzt_only + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if (average_in_x .ne. average_in_x_prev_tile) then

          msg := char_nl + \
"The averaging in the x direction needed to obtain the variable's values " + char_nl + \
"at cell centers (average_in_x) changed from tile " + n_tile_prev + \
" to tile " + n_tile + ":" + char_nl + \
"  average_in_x_prev_tile = " + average_in_x_prev_tile + char_nl + \
"  average_in_x = " + average_in_x + char_nl + \
"Stopping."
          print("" + msg)
          exit

        else if (average_in_y .ne. average_in_y_prev_tile) then

          msg := char_nl + \
"The averaging in the x direction needed to obtain the variable's values " + char_nl + \
"at cell centers (average_in_y) changed from tile " + n_tile_prev + \
" to tile " + n_tile + ":" + char_nl + \
"  average_in_y_prev_tile = " + average_in_y_prev_tile + char_nl + \
"  average_in_y = " + average_in_y + char_nl + \
"Stopping."
          print("" + msg)
          exit

        end if
        end if
        end if
        end if
        end if
        end if
        end if
        end if
        end if

      end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
    else

      func_xy_only = False
      func_xyz_only = False
      func_xyt_only = False
      func_xyzt_only = False
      average_in_x = False
      average_in_y = False

    end if

  end do

  print("")
  print("Done setting file and field name for each specified tile.")
  print("" + separator_line)
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
;pause
  
      vert_indx = vert_inds_to_plot(k)
      time_indx = time_inds_to_plot(n)
      fcst_hr = fcst_hrs_to_plot(n)
  
      fmt_str = "%03i"
      vert_indx_str = sprinti(fmt_str, vert_indx)
      fcst_hr_str = sprinti(fmt_str, fcst_hr)

;print("")
;    print("fcst_hr = " + fcst_hr)
;    print("fcst_hr_str = " + fcst_hr_str)
;print("")
;    print("vert_indx = " + vert_indx)
;    print("vert_indx_str = " + vert_indx_str)
;pause
;
; **********************************************************************
;
;
;
; **********************************************************************
;
      field_info \
      := read_FV3SAR_field_native( \
         field_names_by_tile, \
         file_names_by_tile, \
         gtype, \
         inds_tiles_to_plot, nx_tiles_to_plot, ny_tiles_to_plot, \
         vert_indx, time_indx, \
         remove_rgnl_halo, nhalo_T7, \
         func_xy_only, func_xyz_only, func_xyt_only, func_xyzt_only, \
         average_in_x, average_in_y)

;      fp_field_FV3SAR = field_info@fp  ; This would in general be an array or list of file pointers.
      field_desc := field_info@field_desc
      field_units := field_info@field_units
      field_unstruc := field_info@field_all_tiles_unstruc
      field_min_all_tiles := field_info@field_min_all_tiles
      field_max_all_tiles := field_info@field_max_all_tiles
      field_median_all_tiles := field_info@field_median_all_tiles
      field_mean_all_tiles := field_info@field_mean_all_tiles
      field_data_type_FV3SAR := field_info@field_data_type
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
     
;      print_field_stats = True
      print_field_stats = False
      field_stat_info \
      := calc_field_stats( \
         field_unstruc, field_desc, field_units, print_field_stats)
      msg := "  " + field_stat_info@msg
      print("")
      print("" + msg)
     
      msg := "Done calculating statistics of field over all FV3 tiles to be plotted."
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
;
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
                      RAP_grid_fn, \
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
; For plotting convenience we will 
; combine the fields on the FV3SAR and RAP grids into a single array.  
; For this purpose, if necessary we first convert the data type of the 
; RAP field to that of the FV3SAR field.
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
;
;
; **********************************************************************
;
if (True) then
;if (False) then

      fn_graphics = cres + "_grid_f" + fcst_hr_str + "_k" + vert_indx_str
;
; **********************************************************************
;
;
;
; **********************************************************************
;
      plot_options := True

      plot_options@map_proj = map_proj
      plot_options@map_proj_ctr = map_proj_ctr
      plot_options@draw_grid = show_tile_grids
;      plot_options@show_grid_bdies = show_tile_bdies
;;      plot_options@gtype = gtype
;;      plot_options@inds_tiles_to_plot = inds_tiles_to_plot

;
; Set the flag that determines whether plots will be resized (e.g. to a
; larger area than the default).  This would generally be done using the
; gsnMaximize resource, but it's not clear how to use or reset this re-
; source after adding annotations to the plot (annotations in our case
; are the plot titles).  Thus, we perform the resizing/maximization man-
; ually.
;
      plot_options@resize_plot = True
;
; Set the size (either width or height) of the bounding box which the 
; resized plot will have.  Note that this is in NDC (non-dimensional co-
; ordinate, aka page) coordinates.  This value must be between 0 and 1.
;
      plot_options@bounding_box_size_NDC = 0.98

      if (plot_subreg) then
        plot_options@plot_subreg = plot_subreg
        plot_options@subreg_limits = subreg_limits
      end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
      if (show_RAP_grid .or. plot_RAP_field) then

        inds_tiles_to_plot_str \
        := str_join(tostring(inds_tiles_to_plot), ",")

        FV3SAR_str \
        := "~F30~FV3SAR field info:~C~" \
        + "~F29~" + field_desc + " (" + char_dq + field_name + char_dq + ")" \
        + " [" + field_units + "]" + "~C~" \
        + "Tile(s) shown: " + inds_tiles_to_plot_str
        if (show_tile_bdies) then
          FV3SAR_str = FV3SAR_str + "~C~" + "Tile boundaries in blue"
        end if
        num_newlines_FV3SAR \
        = dimsizes(str_index_of_substr(FV3SAR_str, "~C~", 0))

        RAP_str \
        := "~F30~RAP field info:~C~" \
        + "~F29~" + field_desc_RAP + " (" + char_dq + field_name_RAP + char_dq + ")" \
        + " [" + field_units_RAP + "]"
        if (show_RAP_bdy) then
          RAP_str = RAP_str + "~C~" + "RAP boundary in red"
        end if
        num_newlines_RAP \
        = dimsizes(str_index_of_substr(RAP_str, "~C~", 0))
;
; RAP_str may have fewer newlines than FV3SAR_str.  In that case, add
; newlines so that they both have the same number (looks better in the
; plot.
;
        num_newlines_to_add = num_newlines_FV3SAR - num_newlines_RAP
        if (num_newlines_to_add .ge. 1) then
          RAP_str = RAP_str + repeat_str("~C~ ", num_newlines_to_add)
; For some reason, after the last newline (~C~), the spacing isn't quite
; correct and some extra vertical space is needed.  Insert  that here.
          RAP_str = RAP_str + "~V-10~ "
        end if

        plot_options@left_str = FV3SAR_str
        plot_options@main_str = ""
        plot_options@right_str = RAP_str


      else

        plot_title = field_desc + " [" + field_units + "]"

        plot_options@left_str = ""
        plot_options@main_str = plot_title
        plot_options@right_str = ""

      end if
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
      contour_info := set_cnLevels_lbLabels( \
                      field_min, field_max, num_cnLevels, opts)
      copy_VarAtts(contour_info, plot_options)
    
      msg := \
"Done calculating " + char_dq + "nice" + char_dq + " contour values."
      print("")
      print("" + msg)
      print("" + separator_line)

;plot_options@show_RAP_bdy = show_RAP_bdy
;plot_options@nx_RAP = nx_RAP
;plot_options@ny_RAP = ny_RAP

;
; **********************************************************************
;
;
;
; **********************************************************************
;
      nx_all_grids := nx_tiles_to_plot
      ny_all_grids := ny_tiles_to_plot
      if (show_RAP_grid .or. plot_RAP_field) then
        nx_all_grids := array_append_record(nx_RAP, nx_all_grids, 0)
        ny_all_grids := array_append_record(ny_RAP, ny_all_grids, 0)
      end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
      num_grids_to_plot = num_tiles_to_plot

      if (show_RAP_grid .or. plot_RAP_field) then
        num_grids_to_plot = num_grids_to_plot + 1
      end if

      if (num_grids_to_plot .gt. 0) then

        plot_grid := new(num_grids_to_plot, "logical")
        plot_grid = show_tile_grids
        gridline_colors := new(num_grids_to_plot, "string")
        gridline_colors = "blue"
  
        if (show_RAP_grid .or. plot_RAP_field) then
          plot_grid(0) = show_RAP_grid
          gridline_colors(0) = "red"
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
;
;
; **********************************************************************
;
      num_bdies_to_plot = 0
      if (show_tile_bdies) then
        num_bdies_to_plot = num_tiles_to_plot
      end if

      if (show_RAP_bdy) then
        num_bdies_to_plot = num_bdies_to_plot + 1
      end if

      if (num_bdies_to_plot .gt. 0) then

        plot_bdy = new(num_bdies_to_plot, "logical")
        bdy_colors = new(num_bdies_to_plot, "string")
        bdy_line_thicknesses = new(num_bdies_to_plot, "float")
        bdy_dash_patterns = new(num_bdies_to_plot, "integer")
  
        plot_bdy = show_tile_bdies
        bdy_colors = "blue"
        bdy_line_thicknesses = 4.0
        bdy_dash_patterns = 0
  
        if (show_RAP_bdy) then
          plot_bdy(0) = show_RAP_bdy
          bdy_colors(0) = "red"
          bdy_line_thicknesses(0) = 4.0
          bdy_dash_patterns(0) = 1
        end if

        bdy_opts := True
        bdy_opts@num_bdies = num_bdies_to_plot
        bdy_opts@plot_bdy = plot_bdy
        bdy_opts@bdy_colors = bdy_colors
        bdy_opts@bdy_line_thicknesses = bdy_line_thicknesses
        bdy_opts@bdy_dash_patterns = bdy_dash_patterns

      else

        bdy_opts := False

      end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
      plot_info := plot_horiz_field( \
                   fn_graphics, \
                   nx_all_grids, ny_all_grids, \
                   lon_cntrs_unstruc_all_grids, lat_cntrs_unstruc_all_grids, \
                   lon_verts_unstruc_all_grids, lat_verts_unstruc_all_grids, \
                   lon_bdy_all_grids, lat_bdy_all_grids, \
                   field_unstruc_all_grids, \
                   grid_opts, \
                   bdy_opts, \
                   plot_options)

print("BYE!!!!!!!!!!!!!!!!!!!!!!!")



else









;
; **********************************************************************
;
; Open a workstation and specify the type of graphics file to generate.
; The type can be "ps", "pdf", "x11", "png", or "ncgm" (and maybe more).
;
; **********************************************************************
;
  fn_graphics = cres + "_grid"

  if (strcmp_exact(graphics_type, "png")) then
    wks_type := "png"
    wks_type@wkWidth = 1000
    wks_type@wkHeight = 750
  else if (strcmp_exact(graphics_type, "ncgm")) then
    wks_type := "ncgm"
  end if
  end if

  wks := gsn_open_wks(wks_type, fn_graphics)

; Set the colormap.  To see the various colormaps, go to:
;
; http://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
;
  gsn_define_colormap(wks, "BlAqGrYeOrReVi200")
;  gsn_define_colormap(wks, "BlAqGrYeOrReVi100")

;
; **********************************************************************
;
; Set contour plot resources and generate color contour plot.
;
; **********************************************************************
;
  print("")
  print("#############################################################")
  print("")
  print("Generating plot in file:")
  print("  " + fn_graphics + "." + graphics_type)

; Specify resources.
  rsrc = True

; Maximize size of plot in frame.
  rsrc@gsnMaximize = True

; Use full colormap, but start at color index 24.
  rsrc@gsnSpreadColors = True
  rsrc@gsnSpreadColorStart = 24

; Turn on contour fill.
  rsrc@cnFillOn = True
; Set the fill mode to "CellFill".  This means each cell has a single 
; color that represents the field value for that cell, and no interopla-
; tion is performed.  Other values for this resource can be "AreaFill" 
; and "RasterFill", but those require interoplation.
  rsrc@cnFillMode = "CellFill"

; Set sfXArray and sfYArray to the cell center coordinates.
  rsrc@sfXArray = lon_cntrs_unstruc
  rsrc@sfYArray = lat_cntrs_unstruc

; Set sfXCellBounds and sfYCellBounds to the cell vertex coordinates.
  rsrc@sfXCellBounds = lon_verts_unstruc
  rsrc@sfYCellBounds = lat_verts_unstruc

; Set sfDataArray to the field (which has one value per cell).
  rsrc@sfDataArray = field_unstruc

; If show_tile_grids is True, then draw the cell faces.
  if (show_tile_grids) then
    rsrc@cnCellFillEdgeColor = "black"
;    rsrc@cnCellFillMissingValEdgeColor = "red"  ; This seems to have no effect.
  end if

; Set the color for cells containing missing values.  This is by default
; "transparent", but we repeat it here for clarity.
  rsrc@cnMissingValFillColor = "transparent"

; Specify opacity of cell colors.
;  rsrc@cnFillOpacityF = 0.0 ; Transparent.
;  rsrc@cnFillOpacityF = 0.1
;  rsrc@cnFillOpacityF = 0.35
  rsrc@cnFillOpacityF = 1.0 ; Opaque.

; Turn off contour lines (we just want to see colors).
  rsrc@cnLinesOn = False
; Turn off contour line labels.
  rsrc@cnLineLabelsOn = False

  if (rsrc@cnFillOpacityF .eq. 0.0) then
print("Turning off LabelBar (color bar) for the FV3 contour plot.")
;pause
    rsrc@lbLabelBarOn = False
  end if
  rsrc@lbLabelBarOn = True

;  rsrc@lbBoxLinesOn = False
  rsrc@lbBoxSeparatorLinesOn = False

; Turn off text box that says "CONTOUR FROM AAA TO BBB BY CCC".
  rsrc@cnInfoLabelOn = False

;  rsrc@lbLabelAlignment = "BoxCenters"
  rsrc@lbOverrideFillOpacity = True

; Prevent overlap of labelbar labels.  Actually, the default value of 
; lbLabelAutoStride is already True for NCL V6.1.0 and later.
;  rsrc@lbLabelAutoStride = True
; Turn off labelbar box lines.
;  rsrc@lbBoxLinesOn = False

; Output interval in hours.  This should be read in from the namelist 
; file (fdiag), although FV3 seems to always use 6 hours (4xdaily) 
; regardless of the namelist value
output_interval = 6.0
; Set the plot title.
field_desc = "VVVVVVVVVVVVVV"
field_units = "VVVVVVVVVVVVVV"

  rsrc@tiMainString = field_desc + " [" + field_units + "]"
;  rsrc@tiMainString = "Sample Stretched Grid (one color per tile)"
;  rsrc@tiMainString = "SAR-FV3 (Orange) and RAP (Red Outline) Domains/Grids"
;  rsrc@tiMainString = "Grid Size (km) for CRES = " + cres
;  rsrc@tiMainString = "Grid Size (km)"
  rsrc@tiMainString = plot_title

; Set the title font size.
  rsrc@tiMainFontHeightF = 0.015

; Set the latitude and longitude of the center of the map projection co-
; ordinate system.
  rsrc@mpCenterLonF = map_proj_ctr(0)
  rsrc@mpCenterLatF = map_proj_ctr(1)

; Set the map projection to use.  For the Lambert equal-area projection, 
; we rotate the projection such that it is centered at the North Pole.
  if (strcmp_exact(map_proj, "cyln")) then
    rsrc@mpProjection = "CylindricalEquidistant"
  else if (strcmp_exact(map_proj, "ortho")) then
    rsrc@mpProjection = "Orthographic"
  else if (strcmp_exact(map_proj, "lamb")) then
;    rsrc@mpProjection = "LambertEqualArea"
    rsrc@mpProjection = "LambertConformal"
  end if
  end if
  end if

; Improve the resolution of the map outlines.  Default is "LowRes".
  rsrc@mpDataBaseVersion = "MediumRes"
;  rsrc@mpDataBaseVersion = "HighRes"

; Turn on map tickmarks.
  rsrc@pmTickMarkDisplayMode = "Always"

; Plot curves of constant longitude and latitude (regardless of the plot
; projection).
  rsrc@mpGridAndLimbOn = True

; If "subreg_limits" is specified, plot only a subregion.  Note that this has
; an effect only for the cylindrical-equidistant map projection.

  if (.not. any(ismissing(subreg_limits))) then

    rsrc@mpMinLonF = subreg_limits(0)
    rsrc@mpMaxLonF = subreg_limits(1)
    rsrc@mpMinLatF = subreg_limits(2)
    rsrc@mpMaxLatF = subreg_limits(3)

    rsrc@mpLimitMode = "LatLon"

    if (strcmp_exact(map_proj, "lamb")) then

      rsrc@mpLimitMode = "LatLon"
;      rsrc@mpMinLonF = -128
;      rsrc@mpMaxLonF = -70
;      rsrc@mpMinLatF = 20
;      rsrc@mpMaxLatF = 53

      rsrc@mpLambertParallel1F = 38.5
      rsrc@mpLambertParallel2F = 38.5
      rsrc@mpLambertMeridianF = -97.5

;      rsrc@mpLimitMode = "Corners"
;      rsrc@mpLeftCornerLonF = lon_min
;      rsrc@mpLeftCornerLatF = lat_min
;      rsrc@mpRightCornerLonF = lon_max
;      rsrc@mpRightCornerLatF = lat_max
      rsrc@mpLeftCornerLonF = -122
      rsrc@mpLeftCornerLatF = 15
      rsrc@mpRightCornerLonF = -65
      rsrc@mpRightCornerLatF = 55

    end if

  end if

; Set the minimum and maximum countour levels to plot manually.
if (True) then
;if (False) then
  factor = 10

  cplot_min = floor(min(factor*(/ field_min_all_tiles, field_min_RAP /)))/factor
;  cplot_min = min((/ field_min_all_tiles, field_min_RAP /))
print("field_min_all_tiles = " + field_min_all_tiles)
print("field_min_RAP = " + field_min_RAP)
print("cplot_min = " + cplot_min)


  cplot_max = ceil(max(factor*(/ field_max_all_tiles, field_max_RAP /)))/factor
;  cplot_max = max((/ field_max_all_tiles, field_max_RAP /))
print("")
print("field_max_all_tiles = " + field_max_all_tiles)
print("field_max_RAP = " + field_max_RAP)
print("cplot_max = " + cplot_max)

  num_levels = 20
  rsrc@cnLevelSelectionMode = "ManualLevels"
  rsrc@cnMinLevelValF = cplot_min
  rsrc@cnMaxLevelValF = cplot_max
  rsrc@cnLevelSpacingF = (cplot_max - cplot_min)/num_levels

end if

; Allow for spatially constant fields to be plotted.
  rsrc@cnConstFEnableFill = True
  rsrc@cnConstFLabelOn = False

; Do not immediately draw the contour plot nor advance the frame because
; other objects might still need to be added to the plot.
  rsrc@gsnDraw = False
  rsrc@gsnFrame = False

; Draw the color contour plot (along with a map).
  map = gsn_csm_contour_map(wks, field_unstruc, rsrc)


;
; Retrieve contour levels.
;
  getvalues map@contour
    "cnLevels" : levels
  end getvalues

;  print("")
;  print("levels = " + levels)
;  pause

;  rsrc@lbLabelStrings = sprintf("%3.1f",levels)   ; Format the labels
  rsrc@lbLabelStrings = sprintf("%4.2f",levels)   ; Format the labels
;  print("")
;  print("rsrc@lbLabelStrings = " + rsrc@lbLabelStrings)
;  pause

;  rsrc@lbLabelStrings = sprintf("%4.2g",levels)   ; Format the labels
;  print("")
;  print("rsrc@lbLabelStrings = " + rsrc@lbLabelStrings)
;  pause

  map = gsn_csm_contour_map(wks, field_unstruc, rsrc)

;
; **********************************************************************
;
; If show_tile_bdies is specified as True, draw the boundary of each tile.
;
; **********************************************************************
;
  if (show_tile_bdies) then

    resp := True
    resp@gsLineColor = "blue"
    resp@gsLineThicknessF = 4.0
;
; Note that the graphical id returned by the gsn_add_polyline(...) for
; each tile must be saved at least until the plot is drawn.  If it is 
; overwritten by the id for the next tile, then the polyline that the 
; overwritted graphical id represents will not be drawn.  For that rea-
; son, we first define an array of graphical ids and then save the id
; for each tile in an element of the array.
;
    id_tile_bdy := new((/ num_tiles_to_plot /), graphic)
    print("")
    do nn=0, num_tiles_to_plot-1
      n_tile = inds_tiles_to_plot(nn)
;      print("Drawing boundary of tile #" + n_tile + " ...")
      print("Adding boundary of tile #" + n_tile + " to array of boundary coordinates ...")
      lon_bdy_crnt_tile := lon_bdy_by_tile[nn]
      lat_bdy_crnt_tile := lat_bdy_by_tile[nn]

      if (nn .eq. 0) then
        lon_bdy := lon_bdy_crnt_tile
        lat_bdy := lat_bdy_crnt_tile
      else

        lon_bdy := array_append_record( \
                   lon_bdy, default_fillvalue(typeof(lon_bdy)), 0)
        lon_bdy := array_append_record(lon_bdy, lon_bdy_crnt_tile, 0)

        lat_bdy := array_append_record( \
                   lat_bdy, default_fillvalue(typeof(lat_bdy)), 0)
        lat_bdy := array_append_record(lat_bdy, lat_bdy_crnt_tile, 0)

      end if

;      id_tile_bdy(nn) \
;      = gsn_add_polyline( \
;        wks, map, \
;        lon_bdy_crnt_tile, lat_bdy_crnt_tile, \
;        resp)

    end do

    id_tile_bdies \
    = gsn_add_polyline(wks, map, lon_bdy, lat_bdy, resp)

  end if









;
; **********************************************************************
;
; If plot_RAP_field is specified as True, draw a contour plot on the 
; RAP domain.
;
; **********************************************************************
;
  if (plot_RAP_field) then

if (False) then
getvalues map ; Get plot size for use in 
   "vpHeightF" : vph ; creating labelbar. 
   "vpWidthF" : vpw 
end getvalues 

print("")
print(map@contour)
pause

print("")
print(map)
pause

print("")
printVarSummary(map)
pause

;print("")
;printVarSummary(map@contour)
;pause

getvalues map@contour 
   "cnMinLevelValF" : lb0 ; low label value 
   "cnMinLevelValF" : lb1 ; high label value 
   "cnLevelSpacingF" : spcF ; 
   "lbLabelStride" : strd ; 
;   "lbFillColors"   : colors
;   "lbLabelStrings" : labels
;   "lbBoxCount" : boxcount
end getvalues 
print("")
print("vph = " + vph)
print("vpw = " + vpw)
print("lb0 = " + lb0)
print("lb1 = " + lb1)
print("spcF = " + spcF)
print("strd = " + strd)
;print("colors = " + colors)
;print("labels = " + labels)
;print("boxcount = " + boxcount)
pause

;  getvalues plt
;    "pmAnnoViews" : anno_ids
;  end getvalues
;
;;---Find the labelbar, and reverse it.
;  do i=0,dimsizes(anno_ids)-1
;    if(NhlClassName(anno_ids(i)).eq."labelBarClass") then
;
;;---Get the colors and the strings
;      getvalues anno_ids(i)
;        "lbFillColors"   : colors
;        "lbLabelStrings" : labels
;      end getvalues
end if


; Specify resources.
    rsrc_RAP = True

; Maximize size of plot in frame.
    rsrc_RAP@gsnMaximize = True

; Use full colormap, but start at color index 24.
    rsrc_RAP@gsnSpreadColors = True
    rsrc_RAP@gsnSpreadColorStart = 24

; Turn on contour fill.
    rsrc_RAP@cnFillOn = True
; Set the fill mode to "CellFill".  This means each cell has a single 
; color that represents the field value for that cell, and no interopla-
; tion is performed.  Other values for this resource can be "AreaFill" 
; and "RasterFill", but those require interoplation.
    rsrc_RAP@cnFillMode = "CellFill"

; Specify opacity of cell colors.
    rsrc_RAP@cnFillOpacityF = 0.0 ; Transparent.
;    rsrc_RAP@cnFillOpacityF = 0.35
;    rsrc_RAP@cnFillOpacityF = 1.0 ; Opaque.

; Set sfXArray and sfYArray to the cell center coordinates.
    rsrc_RAP@sfXArray = lon_cntrs_unstruc_RAP
    rsrc_RAP@sfYArray = lat_cntrs_unstruc_RAP

; Set sfXCellBounds and sfYCellBounds to the cell vertex coordinates.
    rsrc_RAP@sfXCellBounds = lon_verts_unstruc_RAP
    rsrc_RAP@sfYCellBounds = lat_verts_unstruc_RAP

; Set sfDataArray to the field (which has one value per cell).
    rsrc_RAP@sfDataArray = field_unstruc_RAP

; If show_RAP_grid is True, then draw the cell faces.
    if (show_RAP_grid) then
;      rsrc_RAP@cnCellFillEdgeColor = "black"
;      rsrc_RAP@cnCellFillEdgeColor = "green"
      rsrc_RAP@cnCellFillEdgeColor = "red"
    end if

; Turn off contour lines (we just want to see colors).
    rsrc_RAP@cnLinesOn = False
; Turn off contour line labels.
    rsrc_RAP@cnLineLabelsOn = False

; Prevent overlap of labelbar labels.  Actually, the default value of 
; lbLabelAutoStride is already True for NCL V6.1.0 and later.
    rsrc_RAP@lbLabelAutoStride = True
; Turn off labelbar box lines.
;    rsrc_RAP@lbBoxLinesOn = False



;    rsrc_RAP@lbBoxCount = 5

; Turn on map tickmarks.
    rsrc_RAP@pmTickMarkDisplayMode = "Always"

; Allow for spatially constant fields to be plotted.
    rsrc_RAP@cnConstFEnableFill = True
    rsrc_RAP@cnConstFLabelOn = False

; Turn off text box that says "CONTOUR FROM AAA TO BBB BY CCC".
    rsrc_RAP@cnInfoLabelOn = False

; Set the title font size.
    rsrc_RAP@tiMainFontHeightF = rsrc@tiMainFontHeightF

    rsrc_RAP@lbLabelBarOn = False
; Set the minimum and maximum countour levels to plot manually.
    if (rsrc_RAP@cnFillOpacityF .eq. 0.0) then
print("Turning off LabelBar (color bar) for the RAP contour plot.")
;pause
      rsrc_RAP@lbLabelBarOn = False
    end if
    rsrc_RAP@cnLevelSelectionMode = "ManualLevels"
    rsrc_RAP@cnMinLevelValF = cplot_min
    rsrc_RAP@cnMaxLevelValF = cplot_max
;    rsrc_RAP@cnLevelSpacingF = rsrc@cnLevelSpacingF

; Do not immediately draw the contour plot nor advance the frame because
; other objects might still need to be added to the plot.
    rsrc_RAP@gsnDraw = False
    rsrc_RAP@gsnFrame = False

; Draw the color contour plot (without a map since that has already been
; drawn above while generating the FV3 tiles).
    map_RAP = gsn_csm_contour(wks, field_unstruc_RAP, rsrc_RAP)

; If show_RAP_bdy is set to True, draw a boundary around the RAP domain.
    if (show_RAP_bdy) then
      resp := True
      resp@gsLineColor = "red"
      resp@gsLineThicknessF = 4.0
      id_RAP_bdy \
      = gsn_add_polyline(wks, map, lon_bdy_RAP, lat_bdy_RAP, resp)
    end if

; Overlay the contour plot of the RAP domain on top of the one for the
; cubed-sphere tile(s).
    overlay(map, map_RAP)

  end if
;
; **********************************************************************
;
; Draw the plot and advance the frame.
;
; **********************************************************************
;
  draw(map)
  frame(wks)

  print("")
  print("Done generating plot in file:")
  print("  " + fn_graphics + "." + graphics_type)

end if


    end do
  end do


end






