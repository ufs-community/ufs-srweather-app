;
; **********************************************************************
;
; File name: process_plot_params.ncl
; Author: Gerard Ketefian
;
; Description:
; ^^^^^^^^^^^
; This function 
;
; **********************************************************************
;
loadscript(lib_location + "special_chars.ncl")
loadscript(lib_location + "strcmp_exact.ncl")

undef("process_plot_params")

function process_plot_params( \
  caller:string, \
  usage_msg:string, \
  help_msg:string)

local plot_params

begin
;
; **********************************************************************
;
; Set the name of the current script or function.  We have to do this
; manually because NCL does not seem to have a built-in method of ob-
; taining this information.
;
; **********************************************************************
;
  curnt_script_proc_func_name \
  := "function process_plot_params(caller, usage_msg, help_msg)"
;
; **********************************************************************
;
; Verify that the input argument "caller" that specifies the name of the 
; script, procedure, or function that calls this procedure has a valid 
; value.
;
; **********************************************************************
;
  valid_callers = (/ "plot_grid", "plot_fields" /)

  if (.not. strcmp_exact(valid_callers, caller)) then

    valid_vals \
    := char_dq \
    + str_join(valid_callers, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"ERROR:  " + curnt_script_proc_func_name + ":" + char_nl + \
"Input argument " + char_dq + caller + char_dq + "is not set to a valid value:" + char_nl + \
"  caller = " + char_dq + caller + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Stopping." + char_nl

    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; For convenience, set the variable example_usage_and_help_str to a 
; string containing an example of how the script/procedure/function that
; calls this function (caller) should be used and how to obtain more 
; detailed help.  This variable will be used below in forming error mes-
; sages.
;
; **********************************************************************
;
  example_usage_and_help_str := \
"Example usage:" + char_nl + \
usage_msg + char_nl + \
"For more help, run " + char_dq + caller + ".ncl 'help=True'" + char_dq + \
" on the command line." + char_nl + \
"Stopping."
;
; **********************************************************************
;
; Get the version of NCL being used.  This may be needed later below.
;
; **********************************************************************
;
  ncl_ver = get_ncl_version()
  ncl_ver = str_sub_str(ncl_ver, ".", "")
  ncl_ver = tointeger(ncl_ver)
;
; **********************************************************************
;
; If the variable "help" is specified on the command line and is set to
; True, print out the help message and exit.
;
; **********************************************************************
;
  if (isvar("help")) then
    if (help .eq. True) then
      print("" + help_msg)
      exit
    end if
  else
    help = False
  end if
;
; **********************************************************************
;
; Verify that the run directory (run_dir) has been specified on the com-
; mand line.  If so, verify that it exists.
;
; **********************************************************************
;
  if (.not. isvar("run_dir")) then

    msg := char_nl + \
"The run directory (run_dir) has not been specified on the command line:" + char_nl + \
"  isvar(" + char_dq + "run_dir" + char_dq + ") = " + isvar("run_dir") + char_nl + \
"Please rerun with the run directory specified.  " + \
example_usage_and_help_str

    print("" + msg)
    exit

  else if (.not. fileexists(run_dir)) then

    msg := char_nl + \
"The specified run directory (run_dir) does not exist:" + char_nl + \
"  run_dir = " + char_dq + run_dir + char_dq + char_nl + \
"  fileexists(run_dir) = " + fileexists(run_dir) + char_nl + \
"Please rerun with an existing run directory.  " + \
example_usage_and_help_str

    print("" + msg)
    exit

  end if
  end if
;
; **********************************************************************
;
; Set the work directory, i.e. the temporary directory in which the pre-
; processing tasks of the workflow place their output files.
;
; **********************************************************************
;
  work_dir = str_sub_str(run_dir, "expt_dirs", "work_dirs")



;
; **********************************************************************
;
; Set the full path to the variable definitions file.  This file con-
; tains various run parameters that will be needed below.
;
; **********************************************************************
;
  var_defns_fn = run_dir + "/var_defns.sh"



;
; **********************************************************************
;
; Read in the grid type (gtype) from the variable definitions file.
;
; **********************************************************************
;
  cmd = "sed --silent --regexp-extended --expression " + \
        "'s/(^gtype=)([" + char_dq + "]*)([A-Za-z]+)([" + char_dq + "]*)(.*)/\3/p' " + \
        var_defns_fn
  gtype := systemfunc(cmd)
;
; **********************************************************************
;
; Check that the grid type read in above is valid.
;
; **********************************************************************
;
  valid_gtypes = (/ "uniform", "stretch", "nest", "regional" /)

  if (.not. strcmp_exact(valid_gtypes, gtype)) then

    valid_vals \
    := char_dq \
    + str_join(valid_gtypes, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"The grid type (gtype) is not set to a valid value:" + char_nl + \
"  gtype = " + char_dq + gtype + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Please rerun with a valid grid type.  " + \
example_usage_and_help_str

    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; Set the array of valid tile indices corresponding to the grid type set 
; above.
;
; **********************************************************************
;
  if (strcmp_exact(gtype, "uniform") .or. \
      strcmp_exact(gtype, "stretch")) then

    valid_tile_inds = (/ 1, 2, 3, 4, 5, 6 /)

  else if (strcmp_exact(gtype, "nest")) then

    valid_tile_inds = (/ 1, 2, 3, 4, 5, 6, 7 /)

  else if (strcmp_exact(gtype, "regional")) then
;
; For a regional grid, we can plot the parent grid (tiles 1 through 6) 
; as well as the regional grid (tile 7), but we cannot plot fields on
; the parent grid because that is not used in the time-integration.
;
    if (strcmp_exact(caller, "plot_grid")) then
      valid_tile_inds = (/ 1, 2, 3, 4, 5, 6, 7 /)
    else
      valid_tile_inds = (/ 7 /)
    end if

  end if
  end if
  end if
;
; **********************************************************************
;
; Read in the cubed-sphere resolution (res) from the variable defini-
; tions file.  This is the nubmer of grid cells in the two horizontal 
; directions on each tile of the global and/or regional grid.
;
; **********************************************************************
;
  cmd = "sed --silent --regexp-extended --expression " + \
        "'s/^[ ]*(RES=)([" + char_dq + "]*)([0-9]+)([" + char_dq + "]*)(.*)/\3/p' " + \
        var_defns_fn
  res := systemfunc(cmd)
res := res(0)
print("==>> res = " + res)
;  res := tointeger(systemfunc(cmd))
;print("==>> res = " + res)
pause
;
; **********************************************************************
;
; Check that the cubed-sphere resolution read in above is valid.
;
; **********************************************************************
;
; Note:  Can't use this for JPgrid because that has no such standard values.
if (False) then
  valid_reses = (/ "000", "48", "96", "192", "384", "768", "1152", "3072" /)

  if (.not. any(res .eq. valid_reses)) then

    valid_vals := str_join(tostring(valid_reses), ", ")

    msg := char_nl + \
"The cubed-sphere resolution (res) is not set to a valid value:" + char_nl + \
"  res = " + res + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Please rerun with a valid cubed-sphere resolution.  " + \
example_usage_and_help_str

    print("" + msg)
    exit

  end if
end if
;
; **********************************************************************
;
; Set the C-resolution (cres) of the grid.  This is a convenience varia-
; ble.  It is a string consisting of the character "C" followed by the 
; cubed-sphere resolution.
;
; **********************************************************************
;
;  cres := "C" + tostring_with_format(res, "%i")
  cres := "C" + res
print("==>> cres = " + char_dq + cres + char_dq)
pause
















;
; **********************************************************************
;
; If the array containing the indices of the tiles on the cubed sphere 
; that are to be plotted (tile_inds) has been specified on the command 
; line, make sure that each of these indices is valid, i.e. that each 
; index can be found in the list of valid indices in valid_tile_inds.
;
; **********************************************************************
;
  if (isvar("tile_inds")) then
;
; Check rank here, then keep unique values and sort (move up from below).
; Only then check if each index is valid.
;
    nn_max = dimsizes(tile_inds)

    do nn=0, nn_max-1
 
     indx_tile = tile_inds(nn)

      if (.not. any(valid_tile_inds .eq. indx_tile)) then

        tile_inds_str := "(/ " + str_join(tostring(tile_inds), ", ") + " /)"
        valid_vals := str_join(tostring(valid_tile_inds), ", ")

        msg := char_nl + \
"Tile index " + indx_tile + " (specified in the " + char_dq + "tile_inds" + char_dq + \
" array) is not valid for the current grid type (gtype):" + char_nl + \
"  gtype = " + char_dq + gtype + char_dq + char_nl + \
"  tile_inds = " + tile_inds_str + char_nl + \
"Valid tile indices are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Please rerun with valid tile indices.  " + \
example_usage_and_help_str

        print("" + msg)
        exit

      end if

    end do
;
; **********************************************************************
;
; If tile_inds has not been defined on the command line, set it to the 
; list of valid tile indices (valid_tile_inds).
;
; **********************************************************************
;
  else

    tile_inds := valid_tile_inds

  end if
;
; **********************************************************************
;
; For clarity, rename the tile_inds array inds_tiles_to_plot.  Then keep 
; only unique elements of this renamed array and sort them by increasing
; value.  Also, calculate the number of tiles to be plotted.
;
; **********************************************************************
;
  inds_tiles_to_plot = tile_inds
  delete(tile_inds)
  inds_tiles_to_plot := get_unique_values(inds_tiles_to_plot)
  qsort(inds_tiles_to_plot)
  num_tiles_to_plot = dimsizes(inds_tiles_to_plot)
;
; **********************************************************************
;
; If show_tile_bdies has not been specified on the command line, set it
; to True.  
;
; **********************************************************************
;
  if (.not. isvar("show_tile_bdies")) then
    show_tile_bdies = True
  end if
;
; **********************************************************************
;
; If show_tile_bdies has been set to True and tile_bdy_color has not 
; been specified on the command line, set the latter to a default value.
;
; **********************************************************************
;
  if (show_tile_bdies .and. .not. isvar("tile_bdy_color")) then
    tile_bdy_color := "blue"
  end if
;
; **********************************************************************
;
; If show_tile_grids has not been specified on the command line, set it
; to False.
;
; **********************************************************************
;
  if (.not. isvar("show_tile_grids")) then
    show_tile_grids = False
  end if
;
; **********************************************************************
;
; If plot_RAP_field has not been specified on the command line, set it 
; to False.
;
; **********************************************************************
;
  if (.not. isvar("plot_RAP_field")) then
    plot_RAP_field = False
  end if
;
; **********************************************************************
;
; If plot_RAP_field has been set to True, then...
;
; **********************************************************************
;
  if (plot_RAP_field) then
;
; Make sure that the name of the NetCDF file that describes the RAP grid
; (RAP_grid_fn) has been specified.
;
    if (.not. isvar("RAP_grid_fn")) then

      msg := char_nl + \
"When plot_RAP_field has been set to True, the RAP grid file (RAP_grid_fn) " + char_nl + \
"must be specified on the command line:" + char_nl + \
"  plot_RAP_field = " + plot_RAP_field + char_nl + \
"  isvar(" + char_dq + "RAP_grid_fn" + char_dq + ") = " + isvar("RAP_grid_fn") + char_nl + \
"Please rerun with the RAP grid file specified.  " + \
example_usage_and_help_str
      print("" + msg)
      exit
;
; If RAP_grid_fn has been specified, make sure that it exists.
;
    else if (.not. fileexists(RAP_grid_fn)) then

      msg := char_nl + \
"The specified RAP grid file (RAP_grid_fn) does not exist:" + char_nl + \
"  RAP_grid_fn = " + char_dq + RAP_grid_fn + char_dq + char_nl + \
"  fileexists(RAP_grid_fn) = " + fileexists(RAP_grid_fn) + char_nl + \
"Please rerun with an existing RAP grid file.  " + \
example_usage_and_help_str

      print("" + msg)
      exit

    end if
    end if
;
; Make sure that a field to plot on the RAP grid (field_name_RAP) is 
; specified.
;
    if (.not. isvar("field_name_RAP")) then
      msg := char_nl + \
"When plot_RAP_field has been set to True, a field to plot on the RAP " + char_nl + \
"grid (field_name_RAP) must be specified on the command line:" + char_nl + \
"  plot_RAP_field = " + plot_RAP_field + char_nl + \
"  isvar(" + char_dq + "field_name_RAP" + char_dq + ") = " + isvar("field_name_RAP") + char_nl + \
"Please rerun with a field_name_RAP specified.  " + \
example_usage_and_help_str
      print("" + msg)
      exit
    end if
;
; **********************************************************************
;
; If plot_RAP_field has been set to False, then set or reset field_-
; name_RAP to "none" so that the plot will not show a field on the RAP
; grid.
;
; **********************************************************************
;
  else

    field_name_RAP = "none"

  end if
;
; **********************************************************************
;
; If show_RAP_bdy has not been specified on the command line, set it to 
; False.
;
; **********************************************************************
;
  if (.not. isvar("show_RAP_bdy")) then
    show_RAP_bdy = False
  end if
;
; **********************************************************************
;
; If show_RAP_bdy has been set to True and RAP_bdy_color has not been 
; specified on the command line, set the latter to a default value.
;
; **********************************************************************
;
  if (show_RAP_bdy .and. .not. isvar("RAP_bdy_color")) then
    RAP_bdy_color := "red"
  end if
;
; **********************************************************************
;
; If show_RAP_grid has not been specified, set it to False.
;
; **********************************************************************
;
  if (.not. isvar("show_RAP_grid")) then
    show_RAP_grid = False
  end if
;
; **********************************************************************
;
; If the map projection (map_proj) has not been specified on the command 
; line, set it to a default value.
;
; **********************************************************************
;
  if (.not. isvar("map_proj")) then
    map_proj := "cyln"
  end if
;
; **********************************************************************
;
; Verify that map_proj is set to a valid value.
;
; **********************************************************************
;
  valid_map_projs = (/ "cyln", "ortho", "lamb" /)

  if (.not. strcmp_exact(valid_map_projs, map_proj)) then

    valid_vals \
    := char_dq \
    + str_join(valid_map_projs, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"The map projection (map_proj) is not set to a valid value:" + char_nl + \
"  map_proj = " + char_dq + map_proj + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Please rerun with a valid map projection.  " + \
example_usage_and_help_str

    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; If the center of the specified map projection (map_proj_ctr) has not 
; been specified on the command line, set it to a default that depends 
; on the map projection.  map_proj_ctr should be a 1-D array having two
; elements.  These two elements are the longitude (in degrees east) and 
; latitude (in degrees north), respectively of the center of the map 
; projection.
;
; Note that this variable is not used for        <-- Not sure if this is true.  I think it is used...
; the cylindrical-equidistant map projection.
;
; **********************************************************************
;
  if (.not. isvar("map_proj_ctr")) then

    map_proj_ctr = new((/2/), "float")

    if (strcmp_exact(map_proj, "cyln")) then
      map_proj_ctr(0) = 0.
      map_proj_ctr(1) = 0.
    else if (strcmp_exact(map_proj, "ortho")) then
      map_proj_ctr(0) = 0.
      map_proj_ctr(1) = 0.
    else if (strcmp_exact(map_proj, "lamb")) then
      map_proj_ctr(0) = 0.
      map_proj_ctr(1) = 90.
    end if
    end if
    end if

  end if
;
; **********************************************************************
;
; If the units in which to report horizontal distance (horiz_dist_units)
; has not been specified on the command line, set it to a default value.
;
; **********************************************************************
;
  if (.not. isvar("horiz_dist_units")) then
    horiz_dist_units := "km"
  end if
;
; **********************************************************************
;
; Verify that horiz_dist_units is set to a valid value.
;
; **********************************************************************
;
  valid_horiz_dist_units = (/ "m", "km" /)

  if (.not. strcmp_exact(valid_horiz_dist_units, horiz_dist_units)) then

    valid_vals \
    := char_dq \
    + str_join(valid_horiz_dist_units, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"The units in which to report horizontal distances (horiz_dist_units) is " + char_nl + \
"not set to a valid value:" + char_nl + \
"  horiz_dist_units = " + char_dq + horiz_dist_units + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Please rerun with a valid map projection.  " + \
example_usage_and_help_str

    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; Set the units in which to report horizontal area (horiz_area_units).
; This depends on the the units in which to report horizontal distance 
; (horiz_dist_units).
;
; **********************************************************************
;
  if (strcmp_exact(horiz_dist_units, "m")) then
    horiz_area_units := "m^2"
  else if (strcmp_exact(horiz_dist_units, "km")) then
    horiz_area_units := "km^2"
  end if
  end if
;
; **********************************************************************
;
; If plot_subreg is not specified, set it to False.
;
; **********************************************************************
;
  if (.not. isvar("plot_subreg")) then
    plot_subreg = False
  end if
;
; **********************************************************************
;
; If plot_subreg is set to True, it means we will plot only a subregion, 
; not the whole globe.  In this case, verify that the 4-element array 
; subreg_limits specifying the limits of the subregion exists and con-
; tains non-missing values.
;
; **********************************************************************
;
  if (plot_subreg) then

    if (.not. isvar("subreg_limits")) then

      msg := char_nl + \
"When the option to focus the plot on a subregion (plot_subreg) is set " + char_nl + \
"to True, a 4-element array named " + char_dq + "subreg_limits" + char_dq + \
" must be specified " + char_nl + \
"that contains valid subregion limits [in the form (lon_min, lon_max, " + char_nl + \
"lat_min, lat_max) with units in degrees]:" + char_nl + \
"  plot_subreg = " + plot_subreg + char_nl + \
"  isvar(" + char_dq + "subreg_limits" + char_dq + ") = " + isvar("subreg_limits") + char_nl + \
"Please rerun with valid subregion limits.  " + \
example_usage_and_help_str
      print("" + msg)
      exit

    end if
;
; **********************************************************************
;
; If plot_subreg is set to False, the array subreg_limits will not be 
; needed, but it must exist in order for this function to return it as
; an attribute of the return variable.  Thus, in this case, set subreg_-
; limits to a 4-element array of missing/fill values.
;
; **********************************************************************
;
  else

    subreg_limits := new((/ 4 /), "float")

  end if








;
; **********************************************************************
;
; If the graphics file type (graphics_type) has not been specified on 
; the command line, set it to a default value.
;
; **********************************************************************
;
  if (.not. isvar("graphics_type")) then
    graphics_type := "png"
  end if
;
; **********************************************************************
;
; Verify that graphics_type is set to a valid value.
;
; **********************************************************************
;
  valid_graphics_types = (/ "png", "ncgm" /)
  if (.not. strcmp_exact(valid_graphics_types, graphics_type)) then

    valid_vals \
    := char_dq \
    + str_join(valid_graphics_types, char_dq + ", " + char_dq) \
    + char_dq

    msg := char_nl + \
"The graphics file type (graphics_type) is not set to a valid value:" + char_nl + \
"  graphics_type = " + char_dq + graphics_type + char_dq + char_nl + \
"Valid values are:" + char_nl + \
"  " + valid_vals + char_nl + \
"Please rerun with a valid graphics file type.  " + \
example_usage_and_help_str

    print("" + msg)
    exit

  end if
;
; **********************************************************************
;
; If the grid type is "regional", then remove_rgnl_halo will be used, so 
; it must be defined.  Thus, in this case, if it is not defined on the 
; command line, we set it to a default value.  If the grid type is not 
; "regional", remove_rgnl_halo will not be used, but it still needs to 
; be defined so that it can be returned to the calling program (see la-
; ter below).  Thus, in this case, we set it to False.
;
; **********************************************************************
;
  if (strcmp_exact(gtype, "regional")) then
    if (.not. isvar("remove_rgnl_halo")) then
      remove_rgnl_halo = False
    end if
  else
    remove_rgnl_halo = False
  end if




;
; **********************************************************************
;
; Check whether the field name is one that is found in the grid specifi-
; cation file(s).
;
; **********************************************************************
;
  valid_gridfield_names \
  = (/ "cell_area", \
       "sqrt_cell_area", \
       "cell_dx", \
       "cell_dy", \
       "cell_dx_ovr_cell_dy", \
       "min_cell_dx_cell_dy", \
       "angle_cell_dx", \
       "angle_cell_dy" /)

  is_gridfield = False 
  if (strcmp_exact(valid_gridfield_names, field_name)) then
    is_gridfield = True
  end if
;
; **********************************************************************
;
; If the base name of the file from which to read in fields is not spe-
; cified, set it to a blank string.
;
; **********************************************************************
;
  if (.not. isvar("file_basename")) then

    if (is_gridfield) then

      file_basename = ""

    else

      msg := char_nl + \
"When the field to be plotted is not a grid field [i.e. when is_gridfield " + char_nl + \
"is False; a grid field is a field that is stored in the grid specification " + char_nl + \
"file(s)], the base name of the file from which to read in the field [i.e. " + char_nl + \
"file_basename; this is the file name without an extension (e.g. " + char_dq + ".nc" + char_dq + "), " + char_nl + \
"the tile number (e.g. " + char_dq + ".tile6" + char_dq + "), and possibly also the halo width (e.g. " + char_nl + \
char_dq + ".halo4" + char_dq + ")] must be specified:" + char_nl + \
"  is_gridfield = " + is_gridfield + char_nl + \
"  isvar(" + char_dq + "file_basename" + char_dq + ") = " + isvar("file_basename") + char_nl + \
"Please rerun with a specified file base name.  " + \
example_usage_and_help_str

      print("" + msg)
      exit

    end if

  else

    if (is_gridfield) then

      msg := char_nl + \
"When the field to be plotted is a grid field [i.e. when is_gridfield is " + char_nl + \
"True; a grid field is a field that is stored in the grid specification " + char_nl + \
"file(s)], the base name of the file from which to read in the field [i.e. " + char_nl + \
"file_basename; this is the file name without an extension (e.g. " + char_dq + ".nc" + char_dq + "), " + char_nl + \
"the tile number (e.g. " + char_dq + ".tile6" + char_dq + "), and possibly also the halo width (e.g. " + char_nl + \
char_dq + ".halo4" + char_dq + ")] should not be specified on the command line (this file name " + char_nl + \
"will be formed internally):" + char_nl + \
"  is_gridfield = " + is_gridfield + char_nl + \
"  file_basename = " + char_dq + file_basename + char_dq + " (before resetting to empty string)" + char_nl + \
"Resetting file_basename to an empty string."

      print("" + msg)
      file_basename = ""

    end if

  end if





;
; **********************************************************************
;
; Consider 
;
; **********************************************************************
;
  if (strcmp_exact(caller, "plot_grid")) then
;
; **********************************************************************
;
; If the field to plot (field_name) has not been specified on the command 
; line, set it to a default value.
;
; **********************************************************************
;
    if (.not. isvar("field_name")) then
;      field_name := "sqrt_cell_area"
      field_name := "none"
    end if
;
; **********************************************************************
;
; Verify that field is set to a valid value.
;
; **********************************************************************
;
    valid_gridfield_names \
    = (/ "cell_area", \
         "sqrt_cell_area", \
         "cell_dx", \
         "cell_dy", \
         "cell_dx_ovr_cell_dy", \
         "min_cell_dx_cell_dy", \
         "angle_cell_dx", \
         "angle_cell_dy" /)
 
    is_gridfield = False 
    if (strcmp_exact(valid_gridfield_names, field_name)) then
      is_gridfield = True
    end if
;
; **********************************************************************
;
; Consider 
;
; **********************************************************************
;
  else if (strcmp_exact(caller, "plot_fields")) then
;
; **********************************************************************
;
; Read in the starting date of the forecast (CDATE) from the variable 
; definitions file.
;
; **********************************************************************
;
    cmd = "sed --silent --regexp-extended --expression " + \
          "'s/(^CDATE=)([" + char_dq + "]*)([0-9]+)([" + char_dq + "]*)(.*)/\3/p' " + \
          var_defns_fn
    CDATE := systemfunc(cmd)
;print("CDATE = " + char_dq + CDATE + char_dq)
;exit
;
; **********************************************************************
;
; Verify that an array named fcst_inds has been specified on the 
; command line.  This may contain If so, check for indices or 'all'
;
; **********************************************************************
;
    if (.not. isvar("fcst_inds")) then
  
      print("")
      print("ERROR: fcst_inds has not been specified on the command line:")
      print("")
      print("Please rerun with a specified forecast index.  Example:")
      print("")
      print("" + usage_msg)
      print("")
  
    else
  
      if (isint(fcst_inds)) then    ; Integer indices
        print ("fcst_inds is an integer" + fcst_inds) 
      else if (isstring(fcst_inds))
        print ("fcst_inds is a string" + fcst_inds) 
      else
        print ("ERROR:  Check format of fcst_inds.")
        exit
      end if
      end if
      n_fcst_inds = dimsizes(fcst_inds)
  
    end if
;
; **********************************************************************
;
; Check that the name of the data file has been specified on the command 
; line.  If not, print out a message and exit.
;
; **********************************************************************
;
    if (.not. isvar("base_name")) then
      print("")
      print("The data file has not been specified on the command line:")
      print("  isvar(" + char_dq + "base_name" + char_dq + ") = " + isvar("base_name"))
      print("Please rerun with the data file specified.  Example:")
      print("" + usage_msg)
      print("Stopping.")
      exit
    end if
;
; **********************************************************************
;
; Check that the field(s) to plot has been specified on the command line.  
; If not, print out a message and exit.
;
; **********************************************************************
;
    if (.not. isvar("fields")) then
      print("")
      print("The field(s) to plot has not been specified on the command " + \
            "line:")
      print("  isvar(" + char_dq + "fields" + char_dq + ") = " + \
            isvar("fields"))
      print("Please specify the field(s) to plot on the command line.  " + \
            "Example:")
      print("" + usage_msg)
      print("Stopping.")
      exit
    else
      print ("Fields to be plotted are " + fields)
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
  plot_params := True

  plot_params@gtype = gtype
  plot_params@num_tiles_to_plot = num_tiles_to_plot
  plot_params@inds_tiles_to_plot = inds_tiles_to_plot
  plot_params@cres = cres
  plot_params@run_dir = run_dir
  plot_params@work_dir = work_dir

  plot_params@horiz_dist_units = horiz_dist_units
  plot_params@horiz_area_units = horiz_area_units

  plot_params@show_tile_bdies = show_tile_bdies
  plot_params@tile_bdy_color = tile_bdy_color
  plot_params@show_tile_grids = show_tile_grids
  plot_params@field_name = field_name
  plot_params@is_gridfield = is_gridfield
  plot_params@file_basename = file_basename

  plot_params@show_RAP_bdy = show_RAP_bdy
  plot_params@RAP_bdy_color = RAP_bdy_color
  plot_params@show_RAP_grid = show_RAP_grid
  plot_params@plot_RAP_field = plot_RAP_field
  plot_params@field_name_RAP = field_name_RAP

  plot_params@graphics_type = graphics_type
  plot_params@map_proj = map_proj
  plot_params@map_proj_ctr = map_proj_ctr

  plot_params@remove_rgnl_halo = remove_rgnl_halo

  plot_params@plot_subreg = plot_subreg
  plot_params@subreg_limits = subreg_limits

;  if (strcmp_exact(caller, "plot_grid")) then
;    plot_params@field_name = field_name
;  else if (strcmp_exact(caller, "plot_fields")) then
;; Add attributes specific to calling plot_fields.
;  end if
;  end if

  return(plot_params)


end


