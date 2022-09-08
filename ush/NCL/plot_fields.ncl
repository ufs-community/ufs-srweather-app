;==========================================================================
; Description: This script reads FV3 grid information and model output
;              fields and generated a 2-D color plot of the required fields
;              on top of a map of the continents. The script can be run
;              from the command line or the make_FV3_RAP_domain_plots.sh
;              script.
;
; Necessary input files: pause.ncl, README, strcmp.ncl
;                        geo_em.d01.nc    (if draw_RAP_domain)
;                        INPUT/C[res]_grid.tile[].nc
;                        INPUT/grid_spec.nc
;                        INPUT/oro_data.nc
;                        a model output file specified by 'base_name' on the command line
;
; Necessary input parameters: 
;
; Output file(s): C[res]_[map_proj]_[field]_hr[hour]_lev[n].png
;
; Usage: See README file

; Assumptions: You have an FV3 model run directory with an INPUT directory
;              containing the grid files for the tiles.
;
; Examples:
;       ncl -n plot_fields.ncl 'help=True'    # print help using this script
;
;       ncl -n plot_fields.ncl \
;           'help=False' \
;           'grid_dir="./some_dir/grid"' \
;           'base_name="nppgs2d"' \
;           'fields=(/"u1000", "v1000"/)' \
;           'nlev="60"' \
;           'fcst_index="(/6/)"' \
;           'res=96' \
;           'tile_inds=(/1,2,3/)' \
;           'draw_tile_bdy=True' \
;           'draw_tile_grid=True' \
;           'draw_RAP_domain=True' \
;           'RAP_grid_fn="./some_dir/RAP_grid.nc"' \
;           'draw_RAP_bdy=True' \
;           'draw_RAP_grid=True' \
;           'map_proj="cyln"' \
;           'map_proj_ctr=(/0,90/)' \
;           'subreg=(/-30,30,-25,25/)' \
;           'graphics_type="ncgm"'
;==========================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

load "pause.ncl"
load "read_namelist.ncl"
load "strcmp.ncl"

begin
;
; **********************************************************************
;
; If not already defined, define the string (separator_line) that serves
; as a separator line between different sections of printout.
;
; **********************************************************************
;
  if (.not. isvar("separator_line")) then
    separator_line := repeat_str("=", 72)
  end if
;
; **********************************************************************
;
;
;
; **********************************************************************
;
  pwd = systemfunc("pwd")
  check_files = (/"README"/)   ; Add files to check here
  nfiles = dimsizes(check_files)

  do i=0,nfiles-1
    ret = systemfunc("test -f " + pwd + "/" + check_files(i) + "; echo $?")
    if(ret .eq. 0) then
      print("--> " + check_files(i) + ": exists")
    else if(ret .eq.1) then
      print("Error: " + check_files(i) + ": doesn't exist")
      print("Copy  " + check_files(i) + " from your original directory to your working directory")
      exit
    end if
    end if
  end do
;
; **********************************************************************
;
; Define special characters that can't be directly input into an NCL 
; string.
;
; **********************************************************************
;
  char_dq = integertochar(34)
  char_nl = str_get_nl()
;
; **********************************************************************
;
; Create usage message.
;
; **********************************************************************
;
  usage_msg = \
"  ncl -n plot_fields.ncl \" + char_nl + \
"      'help=False' \" + char_nl + \
"      'grid_dir=" + char_dq + "./some_dir/grid" + char_dq + "' \" + char_nl + \
"      'base_name=" + char_dq + "nggps2d.nc" + char_dq + "' \" + char_nl + \
"      'fields=(u1000,v1000/)' \" + char_nl + \
"      'nlev=60' \" + char_nl + \
"      'fcst_index=(/6/)' \" + char_nl + \
"      'res=96' \" + char_nl + \
"      'tile_inds=(/1,2,3/)' \" + char_nl + \
"      'draw_tile_bdy=True' \" + char_nl + \
"      'draw_tile_grid=True' \" + char_nl + \
"      'draw_RAP_domain=True' \" + char_nl + \
"      'RAP_grid_fn=" + char_dq + "./some_dir/RAP_grid.nc" + char_dq + "' \" + char_nl + \
"      'draw_RAP_bdy=True' \" + char_nl + \
"      'draw_RAP_grid=True' \" + char_nl + \
"      'map_proj=" + char_dq + "cyln" + char_dq + "' \" + char_nl + \
"      'map_proj_ctr=(/0,90/)' \" + char_nl + \
"      'subreg=(/-30,30,-25,25/)' \" + char_nl + \
"      'graphics_type=" + char_dq + "ncgm" + char_dq + "'" 
;
; **********************************************************************
;
; If the variable help is specified to be True on the command line, 
; print out the documentation and exit.
;
; **********************************************************************
;
  if (isvar("help")) then
    if (help .eq. True) then
      help_msg = systemfunc("cat " + pwd + "/" + "README")
      print("" + help_msg)
      exit
    end if
  end if
;
; **********************************************************************
;
; Check whether grid_dir has been specified.  If not, set it to the cur-
; rent directory.
;
; **********************************************************************
;
  if (.not. isvar("grid_dir")) then
    grid_dir = "./"
  end if

; **********************************************************************
;
; Check whether the fcst_index has been specified on the command line.
; If not, print out a message and exit. If so, check for indices or 'all'
;
; **********************************************************************
  if (.not. isvar("fcst_index")) then
    print("")
    print("ERROR: fcst_index has not been specified on the command line:")
    print("")
    print("Please rerun with a specified resolution.  Example:")
    print("")
    print("" + usage_msg)
    print("")
  else
    if (isint(fcst_index)) then    ; Integer indices
      print ("fcst_index is an integer" + fcst_index) 
    else if (isstring(fcst_index))
      print ("fcst_index is a string" + fcst_index) 
    else
      print ("ERROR:  Check format of fcst_index.")
      exit
    end if
    end if
    n_fcst_index = dimsizes(fcst_index)
  end if
;
; **********************************************************************
;
; Check whether the cubed-sphere resolution (res) has been specified on
; the command line.  If not, print out a message and exit.
;
; **********************************************************************
;
  if (.not. isvar("res")) then
    print("")
    print("The cubed-sphere resolution (res) has not been specified on the command line:")
    print("")
    print("  isvar(" + char_dq + "res" + char_dq + ") = " + isvar("res"))
    print("")
    print("Please rerun with a specified resolution.  Example:")
    print("")
    print("" + usage_msg)
    print("")
    print("For more help, type " + char_dq + "ncl plot_fields.ncl 'help=True'" + char_dq + " on the command line.")
    print("Stopping.")
    exit
  end if

  Cres := "C" + tostring_with_format(res, "%i")
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
; Open the grid mosaic file and read in the number of tiles for which a
; grid description file is available.  Then use that number (possibly 
; along with the options passed to the make_hgrid command used to gene-
; rate the grid description files) to determine the cubed-sphere grid 
; type, gtype.  gtype can be "uniform" (for a globally uniform grid), 
; "stretch" (for a global grid that has been stretched/compressed to 
; achieve variable resolution), "nest" (for a stretched global grid with
; a nested grid within tile 6), or "regional" (for a regional stand-
; alone grid).  Also, set valid_tile_inds, which is an array contain-
; ing the set of valid tile indices for a given gtype.
;
; **********************************************************************
;
;  fn_mosaic := grid_dir + "/" + Cres + "_mosaic.nc"
  fn_mosaic := grid_dir + "/grid_spec.nc"
  fm = addfile(fn_mosaic, "r")
  num_tiles_avail := getfilevardimsizes(fm, "gridtiles")
  print("num_tiles_avail = " + num_tiles_avail)
  num_tiles_avail := num_tiles_avail(0)

  print("num_tiles_avail = " + num_tiles_avail)
  if (num_tiles_avail .eq. 6) then

; Read in file attributes from the tile 1 grid file.  The attribute we
; are interested in is the string containing the call to make_hgrid that
; created the grid.  It has information that determines whether this is
; a uniform or a stretched grid (if it is a stretched grid, the call to
; make_hgrid will contain the --do_schmidt flag).
    n_tile = 1
    grid_fn := grid_dir + "/" + Cres + "_grid.tile" + n_tile + ".nc"
    fg1 = addfile(grid_fn, "r")

    if (ncl_ver .ge. 650) then
; NCL V6.5.0 and later.
      file_atts = getfileatts(fg1)
    else
; NCL V6.4.0 and earlier.
      file_atts = getvaratts(fg1)
    end if

    make_hgrid_command = fg1@history
    idx_do_schmidt := str_match_ind_regex(make_hgrid_command, "--do_schmidt")
    if (ismissing(idx_do_schmidt)) then
      gtype = "uniform"
    else
      gtype = "stretch"
    end if
    valid_tile_inds = (/ 1, 2, 3, 4, 5, 6 /)

  else if (num_tiles_avail .eq. 7) then

    gtype = "nest"
    valid_tile_inds = (/ 1, 2, 3, 4, 5, 6, 7 /)

  else if (num_tiles_avail .eq. 1) then

    gtype = "regional"
; For a regional grid, although tiles 1 through 6 are not used in the 
; time-integration, they are still available for visualization.  ;    valid_tile_inds = (/ 7 /)
    valid_tile_inds = (/ 1, 2, 3, 4, 5, 6, 7 /)

  else

    print("")
    print("Disallowed total number of tiles on grid:")
    print("  num_tiles_avail = " + num_tiles_avail)
    print("Cannot set gtype.  Stopping.")
    exit

  end if
  end if
  end if

print("")
print("========>>>> gtype = " + gtype)
;
; **********************************************************************
;
; Check whether the indices of the tiles (on the cubed sphere) that are 
; to be plotted have been specified on the command line in the array 
; tile_inds. If so, for clarity, first change the name of the array to 
; inds_tiles_to_plot.  Then make sure that the tile indices in this ar-
; ray are all valid, i.e. that each index can be found in the list of 
; valid indices in valid_tile_inds.  If the indices of the tiles to be 
; plotted have not been specified on the command line, set them to the
; contents of inds_valid_tiles.
;
; **********************************************************************
;
  if (isvar("tile_inds")) then

; Change array name.
    inds_tiles_to_plot = tile_inds
    delete(tile_inds)

; Keep only unique tile indices and sort them.
    inds_tiles_to_plot := get_unique_values(inds_tiles_to_plot)
    qsort(inds_tiles_to_plot)

; Check that each tile index in inds_tiles_to_plot can be found in 
; valid_tile_inds.
    num_tiles_to_plot = dimsizes(inds_tiles_to_plot)
    do nn=0, num_tiles_to_plot-1
      n_tile = inds_tiles_to_plot(nn)
      if (.not. any(valid_tile_inds .eq. n_tile)) then
        print("")
        print("Tile #" + n_tile + " is not a valid tile for the current grid type (gtype):")
        print("")
        print("  gtype = " + gtype)
        print("  valid_tile_inds = " + valid_tile_inds)
        print("  inds_tiles_to_plot = " + inds_tiles_to_plot)
        print("")
        print("Stopping.")
        exit
      end if
    end do

  else

    inds_tiles_to_plot := valid_tile_inds
    num_tiles_to_plot = dimsizes(inds_tiles_to_plot)

  end if
;
; **********************************************************************
;
; Check whether draw_tile_bdy has been specified on the command line.  
; If not, set it to True.
;
; **********************************************************************
;
  if (.not. isvar("draw_tile_bdy")) then
    draw_tile_bdy = True
  end if
;
; **********************************************************************
;
; Check whether draw_tile_grid has been specified on the command line.  
; If not, set it to False.
;
; **********************************************************************
;
  if (.not. isvar("draw_tile_grid")) then
    draw_tile_grid = False
  end if
;
; **********************************************************************
;
; Check whether draw_RAP_domain has been specified on the command line.  
; If not, set it to False.
;
; **********************************************************************
;
  if (.not. isvar("draw_RAP_domain")) then
    draw_RAP_domain = False
  end if
;
; **********************************************************************
;
; If draw_RAP_domain has been specified to be True on the command line, 
; make sure that the name of the NetCDF file that describes the RAP grid
; (RAP_grid_fn) has also been specified.  If not, print a message and 
; exit.
;
; **********************************************************************
;
  if (draw_RAP_domain .and. .not. isvar("RAP_grid_fn")) then
    print("")
    print("The name of the NetCDF file that describes the RAP grid (RAP_grid_fn) has not been specified on the command line:")
    print("")
    print("  draw_RAP_domain = " + draw_RAP_domain)
    print("  isvar(" + char_dq + "RAP_grid_fn" + char_dq + ") = " + isvar("RAP_grid_fn"))
    print("")
    print("Please rerun with a specified RAP_grid_fn.  Example:")
    print("")
    print("" + usage_msg)
    print("")
    print("For more help, type " + char_dq + "ncl plot_fields.ncl 'help=True'" + char_dq + " on the command line.")
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;
; Check whether draw_RAP_bdy has been specified on the command line.  If
; not, set it to True.
;
; **********************************************************************
;
  if (.not. isvar("draw_RAP_bdy")) then
    draw_RAP_bdy = True
  end if
;
; **********************************************************************
;
; Check whether draw_RAP_grid has been specified on the command line.  
; If not, set it to False.
;
; **********************************************************************
;
  if (.not. isvar("draw_RAP_grid")) then
    draw_RAP_grid = False
  end if

; **********************************************************************
;
; Check whether map_proj is specified, and if so, whether the specified
; value is valid.  Default is to use a cylindrical-equidistant project-
; ion.
;
; **********************************************************************
;
  if (.not. isvar("map_proj")) then
    map_proj := "cyln"
  end if

  idx_cyln := str_match_ind_regex(map_proj, "^" + "cyln" + "$")
  idx_ortho := str_match_ind_regex(map_proj, "^" + "ortho" + "$")
  idx_lamb := str_match_ind_regex(map_proj, "^" + "lamb" + "$")

  if (ismissing(idx_cyln) .and. \
      ismissing(idx_ortho) .and. \
      ismissing(idx_lamb)) then
    print("")
    print("Disallowed value specified for " + char_dq + "map_proj" + \
          char_dq + ":")
    print("  map_proj = " + char_dq + map_proj + char_dq)
    print("Allowed values are:")
    print("  " + char_dq + "cyln" + char_dq + \
          " (for cylindrical-equidistant projection)")
    print("  " + char_dq + "ortho" + char_dq + \
          " (for orthographic (i.e. on a sphere) projection)")
    print("  " + char_dq + "lamb" + char_dq + \
          " (for Lambert equal-area projection)")
    print("Please specify one of these allowed values for " + \
          char_dq + "map_proj" + char_dq + ".")
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;
; Check whether map_proj_ctr is specified.  If not, set it according to
; the specified map projection.  Note that this variable is not used for
; the cylindrical-equidistant map projection.
;
; **********************************************************************
;
  if (.not. isvar("map_proj_ctr")) then

    map_proj_ctr = new((/2/), "float")

    if (.not. ismissing(idx_cyln)) then
      map_proj_ctr(0) = 0.
      map_proj_ctr(1) = 0.
    else if (.not. ismissing(idx_ortho)) then
      map_proj_ctr(0) = 0.
      map_proj_ctr(1) = 0.
    else if (.not. ismissing(idx_lamb)) then
      map_proj_ctr(0) = 0.
      map_proj_ctr(1) = 90.
    end if
    end if
    end if

  end if
;
; **********************************************************************
;
; If the array subreg is specified on the command line, it means we will
; plot only a subregion, not the whole globe.  In this case, get the 
; minimum and maximum values of the longitude and latitude for the sub-
; region to be plotted.
;
; **********************************************************************
;
  if (isvar("subreg")) then
    lon_min = subreg(0)
    lon_max = subreg(1)
    lat_min = subreg(2)
    lat_max = subreg(3)
  end if
;
; **********************************************************************
;
; Check whether graphics_type has been specified on the command line.  
; If not, set it to "ncgm".
;
; **********************************************************************
;
  if (.not. isvar("graphics_type")) then
    graphics_type := "ncgm"
  end if

  idx_ncgm := str_match_ind_regex(graphics_type, "^" + "ncgm" + "$")
  idx_png := str_match_ind_regex(graphics_type, "^" + "png" + "$")

  if (ismissing(idx_ncgm) .and. ismissing(idx_png)) then
    print("")
    print("Disallowed value specified for " + char_dq + "graphics_type" + \
          char_dq + ":")
    print("  graphics_type = " + char_dq + graphics_type + char_dq)
    print("Allowed values are:")
    print("  " + char_dq + "ncgm" + char_dq + \
          " (for type NCAR Graphics output graphics file)")
    print("  " + char_dq + "png" + char_dq + \
          " (for type png output graphics file)")
    print("Please specify one of these allowed values for " + \
          char_dq + "graphics_type" + char_dq + ".")
    print("Stopping.")
    exit
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
    print("Please specify the data file on the command line.  Example:")
    print("" + usage_msg)
    print("Stopping.")
    exit
  end if

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
;
; **********************************************************************
;
; Read in the coupler_nml namelist from the file input.nml.  From this
; namelist, get the starting date of the simulation and construct a date
; string out of it.  This string is needed in forming the names of the 
; data files.
;
; **********************************************************************
;
  if (False) then  ; JLS keep for later
    fn_nml = "input.nml"
    nl_name = "coupler_nml"
    nl := read_namelist(fn_nml, nl_name)
    current_date := nl@current_date
    yyyy := tostring_with_format(current_date(0), "%04i")
    mo := tostring_with_format(current_date(1), "%02i")
    dd := tostring_with_format(current_date(2), "%02i")
    hh := tostring_with_format(current_date(3), "%02i")
    mn := tostring_with_format(current_date(4), "%02i")
    ss := tostring_with_format(current_date(5), "%02i")
    date_str := yyyy + mo + dd + hh + mn + ss
  else
    date_str := "yyyymoddhhmnss"
  end if
;
; **********************************************************************
;
; Get tile dimensions and calculate the total number of cells to be 
; plotted (i.e. summed over all tiles to be plotted).
;
; **********************************************************************
;
  nx_by_tile = new((/ num_tiles_to_plot /), "integer")
  ny_by_tile = new((/ num_tiles_to_plot /), "integer")

  do nn=0, num_tiles_to_plot-1
    n_tile = inds_tiles_to_plot(nn)
    grid_fn := grid_dir + "/" + Cres + "_grid.tile" + n_tile + ".nc"
    print("")
    print("Reading tile dimensions from file:")
    print("  grid_fn = " + grid_fn)
    fg = addfile(grid_fn, "r")
    tile_dims := getfilevardimsizes(fg, "area") 
    ny_by_tile(nn) = tile_dims(0)/2
    nx_by_tile(nn) = tile_dims(1)/2
  end do

; **********************************************************************
; For a regional grid, strip away 3 halo points.
; **********************************************************************
  halo_T7 = 0
  if (strcmp(gtype, "regional")) then
    halo_T7 = 3
  end if

  nx_by_tile = nx_by_tile - 2*halo_T7
  ny_by_tile = ny_by_tile - 2*halo_T7

  nx_tms_ny_by_tile = nx_by_tile*ny_by_tile
  num_cells_to_plot_all_tiles = sum(nx_tms_ny_by_tile)
;
; Create arrays to hold the coordinates of the vertices of all cells
; on all tiles to be plotted.  Also, create work arrays xpoly and ypoly.
;
  num_edges_per_cell = 4
  lon_verts_by_cell := new((/ num_cells_to_plot_all_tiles, num_edges_per_cell /), "double")
  lat_verts_by_cell := new((/ num_cells_to_plot_all_tiles, num_edges_per_cell /), "double")
  xpoly = new((/ num_edges_per_cell /), "double")
  ypoly = new((/ num_edges_per_cell /), "double")
;
; The following is needed in plotting the tile boundaries (i.e. if 
; draw_tile_bdy is set to True).
;
  if (draw_tile_bdy) then
    nx_pls_ny_by_tile = nx_by_tile + ny_by_tile
    nx_pls_ny_max = max(nx_pls_ny_by_tile)
    lon_bdy_by_tile := new((/ num_tiles_to_plot, 2*nx_pls_ny_max+1 /), "double")
    lat_bdy_by_tile := new((/ num_tiles_to_plot, 2*nx_pls_ny_max+1 /), "double")
  end if

;------------------------------------------------------
; Loop over fields
;------------------------------------------------------
  do ifield = 0, dimsizes(fields) - 1 
    field_name = fields(ifield)
;
;------------------------------------------------------
; Loop over times
;------------------------------------------------------
    file_name = grid_dir + "/../" + base_name + ".tile" + inds_tiles_to_plot(0) + ".nc"

    if (fileexists(file_name)) then
      f_unit = addfile(file_name, "r")
    else
      print ("ERROR:  The input file " + file_name + " does not exist")
    end if

    if (isfilevar(f_unit, "time")) then
      time = f_unit->time
      num_times = dimsizes(time)     ; Number of time indices in file
      if ( fcst_index(0) .eq. "all" ) then
        time_inds = ispan(0, num_times-1, 1)    ; Use all time indices
      else                                    ; Test if user input times are
        time_inds = new((/ n_fcst_index /), "integer")
        do itest = 0, n_fcst_index-1             ; in the range in file
          if (fcst_index(itest) .ge. 1 .and. fcst_index(itest) .le. num_times) then
            time_inds(itest) = fcst_index(itest)
          else
            print ("ERROR:  fcst_index is out of the range of 1 and " + num_times)
            exit
          end if
        end do
      end if
    else
      print ("WARNING:  No time variable in file " + file_name)
    end if
    print ("Time indices to plot = " + time_inds)
;------------------------------------------------------
; Loop over times
; JLS TODO indent two spaces for time loop
;------------------------------------------------------
    do itime = 0, dimsizes(time_inds) - 1 

      tindex = time_inds(itime)
      print("Time loop " + itime + " tindex = " + tindex)
; **********************************************************************
;
; Loop through the specified tiles and read in the grid geometry (i.e.
; coordinates of the cell center and cell vertices) and the value of the
; specified field for each cell.
;
; **********************************************************************
;
      field_min := new((/ num_tiles_to_plot /), "double")
      field_max := new((/ num_tiles_to_plot /), "double")
      field_median := new((/ num_tiles_to_plot /), "double")
      field_mean := new((/ num_tiles_to_plot /), "double")

      n_cell = 0

      do nn=0, num_tiles_to_plot-1

        print("")
        print("" + separator_line)
        print("")
        print("nn = " + nn)

        n_tile = inds_tiles_to_plot(nn)

        print("")
        print("n_tile = " + n_tile)

; Get the number of cells in each of the two directions on the current
; tile.
        nx = nx_by_tile(nn)
        ny = ny_by_tile(nn)
        print("")
        print("nx = " + nx)
        print("ny = " + ny)
;
; Open the NetCDF file containing the grid geometry.
;
        grid_fn := grid_dir + "/" + Cres + "_grid.tile" + n_tile + ".nc"
        print("")
        print("Reading grid geometry from file:")
        print("  grid_fn = " + grid_fn)
        fg = addfile(grid_fn, "r")
;
; Read in the supergrid coordinates.  The supergrid of a given tile is a
; grid having twice the resolution of the actual (i.e. computational) 
; grid of that tile.  It is used to store the coordintes of both the 
; centers and the vertices of the cells on the computational grid.
; 
        lon_verts_supergrid_crnt_tile := fg->x(:,:)
        lat_verts_supergrid_crnt_tile := fg->y(:,:)
; Shave off halo.
        print("")
        print(dimsizes(lon_verts_supergrid_crnt_tile))
;pause
        temp := dimsizes(lon_verts_supergrid_crnt_tile)
        nx_SG = temp(1)
        ny_SG = temp(0)
;    halo_SGT7 = 7
;    lon_verts_supergrid_crnt_tile \
;    := lon_verts_supergrid_crnt_tile(halo_SGT7:ny_SG-halo_SGT7, halo_SGT7:nx_SG-halo_SGT7)
        lon_verts_supergrid_crnt_tile \
        := lon_verts_supergrid_crnt_tile(2*halo_T7:ny_SG-1-2*halo_T7, 2*halo_T7:nx_SG-1-2*halo_T7)
       print("")
       print(dimsizes(lon_verts_supergrid_crnt_tile))
;pause
;    lat_verts_supergrid_crnt_tile \
;    := lat_verts_supergrid_crnt_tile(halo_SGT7:ny_SG-halo_SGT7, halo_SGT7:nx_SG-halo_SGT7)
        lat_verts_supergrid_crnt_tile \
        := lat_verts_supergrid_crnt_tile(2*halo_T7:ny_SG-1-2*halo_T7, 2*halo_T7:nx_SG-1-2*halo_T7)
;
; Get the coordinates of the cell vertices on the current tile.
;
        lon_verts_crnt_tile := lon_verts_supergrid_crnt_tile(0::2,0::2)
        lat_verts_crnt_tile := lat_verts_supergrid_crnt_tile(0::2,0::2)
;
; Get the coordinates of the cell centers on the current tile.
;
        lon_cntrs_crnt_tile := lon_verts_supergrid_crnt_tile(1::2,1::2)
        lat_cntrs_crnt_tile := lat_verts_supergrid_crnt_tile(1::2,1::2)
;
; Delete supergrid coordinates to save memory.
;
        delete([/ lon_verts_supergrid_crnt_tile, lat_verts_supergrid_crnt_tile /])

        plot_title = "" 
        plot_subtitle = "" 
        field_crnt_tile := new((/ ny, nx /), "double")
        field_crnt_tile = default_fillvalue("double")
        field_crnt_tile@_FillValue = default_fillvalue("double")
        field_crnt_tile(0,0) = 2.2
        field_crnt_tile(ny/2,nx/2) = 5
        field_crnt_tile(ny-1,nx-1) = 10.0

;------------------------------------------------------
; Open input file requested from command line using base_name
; that contains field data
;------------------------------------------------------
        file_name = grid_dir + "/../" + base_name + ".tile" + n_tile + ".nc"
        if (fileexists(file_name)) then
          f_unit = addfile(file_name, "r")
        else
          print ("ERROR:  The input file " + file_name + " does not exist")
        end if
;------------------------------------------------------
; Check if each field exists in file, if so, get dimensions
;------------------------------------------------------
        if (isfilevar(f_unit, field_name)) then
          print ( field_name + " exists in file " + file_name )
          field_dim_names = getfilevardims(f_unit, field_name)
          print ("field_dim_names = " + field_dim_names)
          field_dim_sizes = getfilevardimsizes(f_unit, field_name)
          print ("field_dim_sizes = " + field_dim_sizes)
          num_field_dims = dimsizes(field_dim_sizes)
          print ("num_field_dims = " + num_field_dims)
        else
          print ( "Error: " + field_name + " does NOT exist in file " + file_name )
          print ( "Check " + file_name + " for available fields ")
          exit
        end if
;------------------------------------------------------
; Check for time variable, read if it exists, check units and convert to hours
;------------------------------------------------------
        if (isfilevar(f_unit, "time")) then
          time = f_unit->time
          time_units = f_unit->time@units
          print ("Time units are in " + time_units)
          if ( .not. ismissing(str_index_of_substr(time_units, "hours since", 0)) ) then
            print ("Time is in hours")
	  	    else if ( .not. ismissing(str_index_of_substr(time_units, "days since", 0)) ) then
            print ("Time is in days, convert to hours")
            time = time*24.
          else
            print ("I am not sure what the time units are")
            exit
          end if
          end if
          start_date = str_split(time_units, "since")
        else
          print ("WARNING:  No time variable in file " + file_name)
        end if
        print ("Time in hours = " + time(:))
;------------------------------------------------------
; Check if field is 4d (time, pfull, yt, xy) which requires a vertical index
;------------------------------------------------------
        if (num_field_dims.eq.4) then
          if (.not. isvar("nlev")) then
            print ( "Error: Array " + field_name + " is 3D and needs a vertical index")
            print ("Set nlev in command line arguments")
            exit
          else 
            ilev = stringtointeger(nlev)  ; nlev exists, convert to integer
          end if

          ref_pres_full = f_unit->pfull(:)
          field_crnt_tile = f_unit->$field_name$(tindex,ilev,:,:)
          field_desc = f_unit->$field_name$@long_name
          field_units = f_unit->$field_name$@units
          plot_title = field_desc + " at pref = " + ref_pres_full(ilev) + " mb (" + field_units + ")"
          plot_subtitle = "  Start date: " + start_date(2) + " Hour " + time(tindex)
          fn_graphics = Cres + "_" + map_proj + "_" + field_name + "_hr" + time(tindex) + "_lev" + nlev

        else if (num_field_dims.eq.3) then       ; (time, yt, xt)

          if (strcmp(field_name, "PRESsfc")) then
            field_crnt_tile = f_unit->$field_name$(tindex,:,:)
            pascals_per_millibar = 100.0d
            field_crnt_tile := field_crnt_tile/pascals_per_millibar
            plot_title = "Surface pressure (mb)"
          else
            field_crnt_tile = f_unit->$field_name$(tindex,:,:)
            field_desc = f_unit->$field_name$@long_name
            field_units = f_unit->$field_name$@units
            plot_title = field_desc + " (" + field_units + ")"
          end if

          plot_subtitle = "  Start date: " + start_date(2) + " Hour " + time(tindex)
          fn_graphics = Cres + "_" + map_proj + "_" + field_name + "_hr" + time(tindex)

        else                           ; num_field_dims is 2 or less

          if (strcmp(field_name, "grid_size")) then

            cell_area_supergrid_crnt_tile := fg->area(:,:)

            do jj=0, 2*ny-2, 2
              do ii=0, 2*nx-2, 2
                j = jj/2
                i = ii/2
                field_crnt_tile(j,i) \
                = cell_area_supergrid_crnt_tile(jj,ii) \
                + cell_area_supergrid_crnt_tile(jj,ii+1) \
                + cell_area_supergrid_crnt_tile(jj+1,ii+1) \
                + cell_area_supergrid_crnt_tile(jj+1,ii)
              end do
            end do
            field_crnt_tile := sqrt(field_crnt_tile)
; Convert distance from meters to kilometers
            field_crnt_tile := field_crnt_tile/1000.0
            delete(cell_area_supergrid_crnt_tile)
            plot_title = "Grid Size (km)"

; The following works with tile 7 only!!
          else if (strcmp(field_name, "orog_raw")) then
            orog_file = grid_dir + "/oro_data.nc"
            f_orog = addfile(orog_file, "r")
            field_crnt_tile = f_orog->orog_raw
            plot_title = "Raw Orography (m)"

; The following works with tile 7 only!!
          else if (strcmp(field_name, "orog_filt")) then
            orog_file = grid_dir + "/oro_data.nc"
            f_orog = addfile(orog_file, "r")
            field_crnt_tile = f_orog->orog_filt
            plot_title = "Filtered Orography (m)"

          end if
          end if
          end if
          fn_graphics = Cres + "_" + map_proj + "_" + field_name

        end if  ; End if num_field_dims is 4 or less
        end if  ; End if num_field_dims is 3 or less

        print("plot_title = " + plot_title)
;---------------------------------------------------
; Done reading data field
;---------------------------------------------------
;
; If on the first tile, convert the 2-D arrays containing the coordi-
; nates of the cell centers and the field values at cell centers to 1-D
; arrays that will be passed to the plotting routines.  If on the se-
; cond, third, etc tile, perform this conversion and then concatenate 
; the results to the 1-D arrays generated for previous tiles.
;
        if (nn .eq. 0) then
          lon_cntrs_by_cell := ndtooned(lon_cntrs_crnt_tile)
          lat_cntrs_by_cell := ndtooned(lat_cntrs_crnt_tile)
          field_by_cell := ndtooned(field_crnt_tile)
        else
          lon_cntrs_by_cell := array_append_record(lon_cntrs_by_cell, ndtooned(lon_cntrs_crnt_tile), 0)
          lat_cntrs_by_cell := array_append_record(lat_cntrs_by_cell, ndtooned(lat_cntrs_crnt_tile), 0)
          field_by_cell := array_append_record(field_by_cell, ndtooned(field_crnt_tile), 0)
        end if
;
; Print out some basic statistics of the field.
;
        field_min(nn) = min(field_crnt_tile)
        field_max(nn) = max(field_crnt_tile)
        field_median(nn) = dim_median_n(field_crnt_tile, (/0,1/))
        field_mean(nn) = avg(field_crnt_tile)

        print("")
        print("Field min and max values over current tile are:")
        print("  field_min = " + field_min(nn))
        print("  field_max = " + field_max(nn))
        print("  field_median = " + field_median(nn))
        print("  field_mean = " + field_mean(nn))
;       print("  dimsizes(field_crnt_tile) = " + dimsizes(field_crnt_tile))

;pause
;
; **********************************************************************
;
; Save the coordinates of the vertices of each cell on the current tile 
; in the arrays that will be passed to the plotting functions.
;
; Note that the loop over j must be the outer loop in order for the ver-
; tex coordinates lon_verts_by_cell and lat_verts_by_cell to map cor-
; rectly to the elements of field_by_cell [which is set above using the 
; ndtooned(...) function].  Alternatively, the elements of field_by_cell 
; can be set in the loop below using
;
;   field_by_cell(n_cell-1) = field_crnt_tile(j,i)
;
; **********************************************************************
;
        if (nn .eq. 0) then
          indx_start = 0
        else
          indx_start = sum(nx_tms_ny_by_tile(0:nn-1))
        end if
        indx_end = indx_start + nx_tms_ny_by_tile(nn) - 1

        v = 0
        lon := ndtooned(lon_verts_crnt_tile(0:ny-1,0:nx-1))
        lat := ndtooned(lat_verts_crnt_tile(0:ny-1,0:nx-1))
        lon_verts_by_cell(indx_start:indx_end,v) = lon
        lat_verts_by_cell(indx_start:indx_end,v) = lat

        v = 1
        lon := ndtooned(lon_verts_crnt_tile(0:ny-1,1:nx))
        lat := ndtooned(lat_verts_crnt_tile(0:ny-1,1:nx))
        lon_verts_by_cell(indx_start:indx_end,v) = lon
        lat_verts_by_cell(indx_start:indx_end,v) = lat

        v = 2
        lon := ndtooned(lon_verts_crnt_tile(1:ny,1:nx))
        lat := ndtooned(lat_verts_crnt_tile(1:ny,1:nx))
        lon_verts_by_cell(indx_start:indx_end,v) = lon
        lat_verts_by_cell(indx_start:indx_end,v) = lat

        v = 3
        lon := ndtooned(lon_verts_crnt_tile(1:ny,0:nx-1))
        lat := ndtooned(lat_verts_crnt_tile(1:ny,0:nx-1))
        lon_verts_by_cell(indx_start:indx_end,v) = lon
        lat_verts_by_cell(indx_start:indx_end,v) = lat

        delete([/ lon, lat /])
;
; For cells that cross over the international date line, modify longi-
; tudes of the vertices so that there is no discontinuity in their val-
; ues.
;
; This may not be necessary since NCL might be smart enough to figure 
; this out, but I'm not sure.  Needs more testing.
;
        v_ref = 0
        do v=1, num_edges_per_cell-1
          abs_del_lon := abs(lon_verts_by_cell(indx_start:indx_end,v) \
                       - lon_verts_by_cell(indx_start:indx_end,v_ref))
          is_greater := (lon_verts_by_cell(indx_start:indx_end,v) .gt. \
                         lon_verts_by_cell(indx_start:indx_end,v_ref))
          lon_verts_by_cell(indx_start:indx_end,v) \
          = where((abs_del_lon .gt. 180.0) .and. is_greater, \
                  lon_verts_by_cell(indx_start:indx_end,v) - 360.0, \
                  lon_verts_by_cell(indx_start:indx_end,v))
          lon_verts_by_cell(indx_start:indx_end,v) \
          = where((abs_del_lon .gt. 180.0) .and. (.not. is_greater), \
                  lon_verts_by_cell(indx_start:indx_end,v) + 360.0, \
                  lon_verts_by_cell(indx_start:indx_end,v))
        end do
        delete([/ abs_del_lon, is_greater /])
;
; **********************************************************************
;
; If draw_tile_bdy is specified as True, save in an array the coordi-
; nates of those cell vertices that lie on the boundary of the current
; tile.
;
; **********************************************************************
;
        if (draw_tile_bdy) then

          lon_bdy_crnt_tile := new((/ 1 /), "double")
          lat_bdy_crnt_tile := new((/ 1 /), "double")
;
; Copy in coordinate of point at (i,j) = (0,0).
;
          i = 0
          j = 0
          lon_bdy_crnt_tile(0) = lon_verts_crnt_tile(j,i)
          lat_bdy_crnt_tile(0) = lat_verts_crnt_tile(j,i)
;
; Append coordinate values along j=0.
;
          j = 0
          lon_bdy_crnt_tile := array_append_record(lon_bdy_crnt_tile, lon_verts_crnt_tile(j,1:), 0)
          lat_bdy_crnt_tile := array_append_record(lat_bdy_crnt_tile, lat_verts_crnt_tile(j,1:), 0)
;
; Append coordinate values along i=nx.
;
          i = nx
          lon_bdy_crnt_tile := array_append_record(lon_bdy_crnt_tile, lon_verts_crnt_tile(1:,i), 0)
          lat_bdy_crnt_tile := array_append_record(lat_bdy_crnt_tile, lat_verts_crnt_tile(1:,i), 0)
;
; Append coordinate values along j=ny.  Note that in specifying the i-
; index range, i.e. nx-1:0, we do not specify a negative stride, i.e.
; we do not use nx-1:0:-1 because the order of the elements is automati-
; cally reversed if the starting index is larger than the ending index.
;
          j = ny
          lon_bdy_crnt_tile := array_append_record(lon_bdy_crnt_tile, lon_verts_crnt_tile(j,nx-1:0), 0)
          lat_bdy_crnt_tile := array_append_record(lat_bdy_crnt_tile, lat_verts_crnt_tile(j,nx-1:0), 0)
;
; Append coordinate values along i=0.  Note that in specifying the j-
; index range, i.e. ny-1:1, we do not specify a negative stride, i.e.
; we do not use ny-1:1:-1 because the order of the elements is automati-
; cally reversed if the starting index is larger than the ending index.
;
          i = 0
          lon_bdy_crnt_tile := array_append_record(lon_bdy_crnt_tile, lon_verts_crnt_tile(ny-1:1,i), 0)
          lat_bdy_crnt_tile := array_append_record(lat_bdy_crnt_tile, lat_verts_crnt_tile(ny-1:1,i), 0)
;
; Repeat the first point on the tile boundary also as the last point so 
; that the polyline object representing the tile boundary closes on it-
; self.
;
          lon_bdy_crnt_tile := array_append_record(lon_bdy_crnt_tile, (/ lon_bdy_crnt_tile(0) /), 0)
          lat_bdy_crnt_tile := array_append_record(lat_bdy_crnt_tile, (/ lat_bdy_crnt_tile(0) /), 0)
;
; Copy the coordinates of the current tile's boundary from the temporary 
; work arrays to the arrays that will be passed to the plotting func-
; tions.
;
          nx_pls_ny = nx_pls_ny_by_tile(nn)
          lon_bdy_by_tile(nn,0:2*nx_pls_ny) = lon_bdy_crnt_tile
          lat_bdy_by_tile(nn,0:2*nx_pls_ny) = lat_bdy_crnt_tile

        end if
;
; **********************************************************************
;
; Print out the coordinates of the corners of the current tile.
;
; **********************************************************************
;
        corner_i_inds := (/ 0, nx, nx, 0 /)
        corner_j_inds := (/ 0, 0, ny, ny /)
        num_corners = 4
        corner_lons := new((/ num_corners /), "double")
        corner_lats := new((/ num_corners /), "double")

        do c=0, num_corners-1
          corner_lons(c) = lon_verts_crnt_tile(corner_j_inds(c), corner_i_inds(c))
          corner_lats(c) = lat_verts_crnt_tile(corner_j_inds(c), corner_i_inds(c))
          if (corner_lons(c) .gt. 180.0) then
            corner_lons(c) = corner_lons(c) - 360.0
          end if
        end do
;print("")
;print("lon = " + corner_lons + " deg;  lat = " + corner_lats + " deg")
;pause

        print("")
        print("Tile corner lon/lat coordinates are:")
        do c=0, num_corners-1
          lon := corner_lons(c)
          lat := corner_lats(c)
          fmt_str = "%7.2f"
          lon_str = sprintf(fmt_str, lon)
          lat_str = sprintf(fmt_str, lat)
          print("Corner " + (c+1) + ":  lon = " + lon_str + " deg;  lat = " + lat_str + " deg")
        end do

      end do   ; End loop over tiles
;
; **********************************************************************
;
; Done with loop over tiles.  Print out min and max values of the field
; being plotted.
;
; **********************************************************************
;
      field_min := min(field_by_cell)
      field_max := max(field_by_cell)
      field_median := dim_median_n(field_by_cell, (/0/))
      field_mean := avg(field_by_cell)

      print("")
      print("" + separator_line)
      print("")
      print("Field min and max values over all tiles to be plotted are:")
      print("  field_min = " + field_min)
      print("  field_max = " + field_max)
      print("  field_median = " + field_median)
      print("  field_mean = " + field_mean)
      print("  dimsizes(field_by_cell) = " + dimsizes(field_by_cell))
;
; **********************************************************************
;
; RAP domain.
;
; **********************************************************************
;
      field_RAP_fillvalue = default_fillvalue("double")
      field_RAP_fillvalue@_FillValue = field_RAP_fillvalue

      field_RAP_min = field_RAP_fillvalue
      field_RAP_max = field_RAP_fillvalue
;print("field_RAP_max@_FillValue = " + field_RAP_max@_FillValue)
;printVarSummary(field_RAP_max)
;print("ismissing(field_RAP_max = " + ismissing(field_RAP_max))
;pause
      field_RAP_median = field_RAP_fillvalue
      field_RAP_mean = field_RAP_fillvalue

      if (draw_RAP_domain) then

        print("")
        print("" + separator_line)
;
; Open the NetCDF file describing the RAP grid.
;
        print("")
        print("Reading RAP grid geometry from file:")
        print("  RAP_grid_fn = " + RAP_grid_fn)
        fg = addfile(RAP_grid_fn, "r")
;
; Read in the cell center coordinates of the RAP domain.
; 
        lon_cntrs_RAP := fg->XLONG_M(:,:,:)
        lat_cntrs_RAP := fg->XLAT_M(:,:,:)
;
; Read in the cell corner coordinates of the RAP domain.
; 
        lon_verts_RAP := fg->XLONG_C(:,:,:)
        lat_verts_RAP := fg->XLAT_C(:,:,:)
;
; Remove singleton dimensions (e.g. time) and convert to double preci-
; sion.
;
        lon_cntrs_RAP := todouble(rm_single_dims(lon_cntrs_RAP))
        lat_cntrs_RAP := todouble(rm_single_dims(lat_cntrs_RAP))

        lon_verts_RAP := todouble(rm_single_dims(lon_verts_RAP))
        lat_verts_RAP := todouble(rm_single_dims(lat_verts_RAP))
;
; Get the dimensions of the RAP domain.
;
        RAP_dims := dimsizes(lon_cntrs_RAP)
        nx_RAP = RAP_dims(1)
        ny_RAP = RAP_dims(0)

        print("")
        print("nx_RAP = " + nx_RAP)
        print("ny_RAP = " + ny_RAP)
;
; Define a field on the RAP grid (at cell centers).
;
        field_RAP := new((/ ny_RAP, nx_RAP /), typeof(field_RAP_fillvalue))
        field_RAP = 50

;
; Read in the cell edge distances.
; 

;    make_hgrid_command = fg1@history
        dx = fg@DX
        dy = fg@DY
        dx_tms_dy = dx*dy
        mapfac_mx := fg->MAPFAC_MX(:,:,:)
        mapfac_my := fg->MAPFAC_MY(:,:,:)
        mapfac_mx := rm_single_dims(mapfac_mx)
        mapfac_my := rm_single_dims(mapfac_my)
        cell_area := dx_tms_dy/(mapfac_mx*mapfac_my)
; Grid distance in km.
        field_RAP = sqrt(cell_area)/1000.0


;
; Add to the arrays containing cell center coordinates (which currently 
; contain the center coordinates of cells on the tiles of the cubed-
; sphere grid) the center coordinates of cells on the RAP grid.
;
;    lon_cntrs_by_cell := array_append_record(lon_cntrs_by_cell, ndtooned(lon_cntrs_RAP), 0)
;    lat_cntrs_by_cell := array_append_record(lat_cntrs_by_cell, ndtooned(lat_cntrs_RAP), 0)
        lon_cntrs_by_cell_RAP := ndtooned(lon_cntrs_RAP)
        lat_cntrs_by_cell_RAP := ndtooned(lat_cntrs_RAP)
;
; Add to the array containing field values at cell centers (which cur-
; rently contains values for cells on the tiles of the cubed-sphere 
; grid) the field values at the centers of cells on the RAP grid.
;
;    field := array_append_record(field, ndtooned(field_RAP), 0)
        field_by_cell_RAP := ndtooned(field_RAP)
;
; Print out some basic statistics of the field.
;
        field_RAP_min = min(field_RAP)
        field_RAP_max = max(field_RAP)
;print("field_RAP_max@_FillValue = " + field_RAP_max@_FillValue)
;printVarSummary(field_RAP_max)
;print("ismissing(field_RAP_max = " + ismissing(field_RAP_max))
;pause
        field_RAP_median = dim_median_n(field_RAP, (/0,1/))
        field_RAP_mean = avg(field_RAP)

        print("")
        print("Field min and max values over the RAP domain are:")
        print("  dimsizes(field_by_cell_RAP) = " + dimsizes(field_by_cell_RAP))
        print("  field_RAP_min = " + field_RAP_min)
        print("  field_RAP_max = " + field_RAP_max)
        print("  field_RAP_median = " + field_RAP_median)
        print("  field_RAP_mean = " + field_RAP_mean)
;
; **********************************************************************
;
; Save the coordinates of the vertices of each cell on the RAP grid in 
; the arrays that will be passed to the plotting functions.  
;
; Note that the loop over j must be the outer loop in order for the ver-
; tex coordinates lon_verts_by_cell_RAP and lat_verts_by_cell_RAP to map 
; correctly to the elements of field_by_cell_RAP [which is set above 
; using the ndtooned(...) function].  Alternatively, the elements of 
; field_by_cell_RAP can be set in the loop below using
;
;   field_by_cell_RAP(n_cell-1) = field_RAP(j,i)
;
; **********************************************************************
;
        num_cells_to_plot_RAP = nx_RAP*ny_RAP
        lon_verts_by_cell_RAP := new((/ num_cells_to_plot_RAP, num_edges_per_cell /), "double")
        lat_verts_by_cell_RAP := new((/ num_cells_to_plot_RAP, num_edges_per_cell /), "double")

        v = 0
        lon := ndtooned(lon_verts_RAP(0:ny_RAP-1,0:nx_RAP-1))
        lat := ndtooned(lat_verts_RAP(0:ny_RAP-1,0:nx_RAP-1))
        lon_verts_by_cell_RAP(:,v) = lon
        lat_verts_by_cell_RAP(:,v) = lat

        v = 1
        lon := ndtooned(lon_verts_RAP(0:ny_RAP-1,1:nx_RAP))
        lat := ndtooned(lat_verts_RAP(0:ny_RAP-1,1:nx_RAP))
        lon_verts_by_cell_RAP(:,v) = lon
        lat_verts_by_cell_RAP(:,v) = lat

        v = 2
        lon := ndtooned(lon_verts_RAP(1:ny_RAP,1:nx_RAP))
        lat := ndtooned(lat_verts_RAP(1:ny_RAP,1:nx_RAP))
        lon_verts_by_cell_RAP(:,v) = lon
        lat_verts_by_cell_RAP(:,v) = lat

        v = 3
        lon := ndtooned(lon_verts_RAP(1:ny_RAP,0:nx_RAP-1))
        lat := ndtooned(lat_verts_RAP(1:ny_RAP,0:nx_RAP-1))
        lon_verts_by_cell_RAP(:,v) = lon
        lat_verts_by_cell_RAP(:,v) = lat

        delete([/ lon, lat /])
;
; For cells that cross over the international date line, modify longi-
; tudes of the vertices so that there is no discontinuity in their val-
; ues.
;
        v_ref = 0
        do v=1, num_edges_per_cell-1
          abs_del_lon := abs(lon_verts_by_cell_RAP(:,v) - lon_verts_by_cell_RAP(:,v_ref))
          is_greater := (lon_verts_by_cell_RAP(:,v) .gt. lon_verts_by_cell_RAP(:,v_ref))
          lon_verts_by_cell_RAP(:,v) \
          = where((abs_del_lon .gt. 180.0) .and. is_greater, \
                  lon_verts_by_cell_RAP(:,v) - 360.0, \
                  lon_verts_by_cell_RAP(:,v))
          lon_verts_by_cell_RAP(:,v) \
          = where((abs_del_lon .gt. 180.0) .and. (.not. is_greater), \
                  lon_verts_by_cell_RAP(:,v) + 360.0, \
                  lon_verts_by_cell_RAP(:,v))
        end do
        delete([/ abs_del_lon, is_greater /])
;
; **********************************************************************
;
; If draw_RAP_bdy is set to True, save the coordinates of the RAP do-
; main's boundary in arrays that will be passed to the plotting rou-
; tines. 
;
; **********************************************************************
;
        if (draw_RAP_bdy) then
;
; Create arrays that will contain the coordinates of points on the boun-
; dary of the RAP domain.  Initially, these contain only one element 
; each.
; 
          lon_bdy_RAP := new((/ 1 /), "double")
          lat_bdy_RAP := new((/ 1 /), "double")
;
; Copy in coordinate of point at (i,j) = (0,0).
;
          i = 0
          j = 0
          lon_bdy_RAP(0) = lon_verts_RAP(j,i)
          lat_bdy_RAP(0) = lat_verts_RAP(j,i)
;
; Append coordinate values along j=0.
;
          j = 0
          lon_bdy_RAP := array_append_record(lon_bdy_RAP, lon_verts_RAP(j,1:), 0)
          lat_bdy_RAP := array_append_record(lat_bdy_RAP, lat_verts_RAP(j,1:), 0)
;
; Append coordinate values along i=nx_RAP.
;
          i = nx_RAP
          lon_bdy_RAP := array_append_record(lon_bdy_RAP, lon_verts_RAP(1:,i), 0)
          lat_bdy_RAP := array_append_record(lat_bdy_RAP, lat_verts_RAP(1:,i), 0)
;
; Append coordinate values along j=ny_RAP.  Note that in specifying the 
; i-index range, i.e. nx_RAP-1:0, we do not specify a negative stride, 
; i.e. we do not use nx_RAP-1:0:-1 because the order of the elements is 
; automatically reversed if the starting index is larger than the ending 
; index.
;
          j = ny_RAP
          lon_bdy_RAP := array_append_record(lon_bdy_RAP, lon_verts_RAP(j,nx_RAP-1:0), 0)
          lat_bdy_RAP := array_append_record(lat_bdy_RAP, lat_verts_RAP(j,nx_RAP-1:0), 0)
;
; Append coordinate values along i=0.  Note that in specifying the j-in-
; dex range, i.e. ny_RAP-1:1, we do not specify a negative stride, i.e.
; we do not use ny_RAP-1:1:-1 because the order of the elements is auto-
; matically reversed if the starting index is larger than the ending in-
; dex.
;
          i = 0
          lon_bdy_RAP := array_append_record(lon_bdy_RAP, lon_verts_RAP(ny_RAP-1:1,i), 0)
          lat_bdy_RAP := array_append_record(lat_bdy_RAP, lat_verts_RAP(ny_RAP-1:1,i), 0)
;
; Repeat the first point on the RAP boundary also as the last point so 
; that the polyline object representing the tile boundary closes on it-
; self.
;
          lon_bdy_RAP := array_append_record(lon_bdy_RAP, (/ lon_bdy_RAP(0) /), 0)
          lat_bdy_RAP := array_append_record(lat_bdy_RAP, (/ lat_bdy_RAP(0) /), 0)

        end if  ; end if draw_RAP_bdy
;
; **********************************************************************
;
; Print out the coordinates of the corners of the RAP domain.
;
; **********************************************************************
;
        nx = nx_RAP
        ny = ny_RAP

        corner_i_inds := (/ 0, nx, nx, 0 /)
        corner_j_inds := (/ 0, 0, ny, ny /)
        num_corners = 4
        corner_lons := new(( num_corners ), "double")
        corner_lats := new(( num_corners ), "double")

        do c=0, num_corners-1
          corner_lons(c) = lon_verts_RAP(corner_j_inds(c), corner_i_inds(c))
          corner_lats(c) = lat_verts_RAP(corner_j_inds(c), corner_i_inds(c))
          if (corner_lons(c) .gt. 180.0) then
            corner_lons(c) = corner_lons(c) - 360.0
          end if
        end do
;print("")
;print("lon = " + corner_lons + " deg;  lat = " + corner_lats + " deg")
;pause

        print("")
        print("RAP domain corner lon/lat coordinates are:")
        do c=0, num_corners-1
          lon := corner_lons(c)
          lat := corner_lats(c)
          fmt_str = "%7.2f"
          lon_str = sprintf(fmt_str, lon)
          lat_str = sprintf(fmt_str, lat)
          print("Corner " + (c+1) + ":  lon = " + lon_str + " deg;  lat = " + lat_str + " deg")
        end do

        rem_x = mod(nx_RAP, 2)
        rem_y = mod(ny_RAP, 2)
        if ((rem_x .eq. 0) .and. (rem_y .eq. 0)) then
          i_cntr = nx_RAP/2
          j_cntr = ny_RAP/2
          lon_RAP_cntr = lon_verts_RAP(j_cntr,i_cntr)
          lat_RAP_cntr = lat_verts_RAP(j_cntr,i_cntr)
        else if ((rem_x .eq. 1) .and. (rem_y .eq. 0)) then
          i_cntr = (nx_RAP - 1)/2
          j_cntr = ny_RAP/2
          lon_vpts_RAP := fg->XLONG_V(:,:,:)
          lat_vpts_RAP := fg->XLAT_V(:,:,:)
          lon_vpts_RAP := todouble(rm_single_dims(lon_vpts_RAP))
          lat_vpts_RAP := todouble(rm_single_dims(lat_vpts_RAP))
          lon_RAP_cntr = lon_vpts_RAP(j_cntr,i_cntr)
          lat_RAP_cntr = lat_vpts_RAP(j_cntr,i_cntr)
        else if ((rem_x .eq. 0) .and. (rem_y .eq. 1)) then
          i_cntr = nx_RAP/2
          j_cntr = (ny_RAP - 1)/2
          lon_upts_RAP := fg->XLONG_U(:,:,:)
          lat_upts_RAP := fg->XLAT_U(:,:,:)
          lon_upts_RAP := todouble(rm_single_dims(lon_upts_RAP))
          lat_upts_RAP := todouble(rm_single_dims(lat_upts_RAP))
          lon_RAP_cntr = lon_upts_RAP(j_cntr,i_cntr)
          lat_RAP_cntr = lat_upts_RAP(j_cntr,i_cntr)
        else if ((rem_x .eq. 1) .and. (rem_y .eq. 1)) then
          i_cntr = (nx_RAP - 1)/2
          j_cntr = (ny_RAP - 1)/2
          lon_RAP_cntr = lon_cntrs_RAP(j_cntr,i_cntr)
          lat_RAP_cntr = lat_cntrs_RAP(j_cntr,i_cntr)
        end if
        end if
        end if
        end if

        print("")
        print("lon_RAP_cntr = " + lon_RAP_cntr + " deg")
        print("lat_RAP_cntr = " + lat_RAP_cntr + " deg")

      end if   ; end if draw_RAP_domain
;
; **********************************************************************
;
; Open a workstation and specify the type of graphics file to generate.
; The type can be "ps", "pdf", "x11", "png", or "ncgm" (and maybe more).
;
; **********************************************************************
;
      if (.not. ismissing(idx_ncgm)) then
        wks_type := "ncgm"
      else if (.not. ismissing(idx_png)) then
        wks_type := "png"
        wks_type@wkWidth = 1000
        wks_type@wkHeight = 750
      end if
      end if

      wks := gsn_open_wks(wks_type, fn_graphics)

; Set the colormap.  To see the various colormaps, go to:
;
; http://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
;
      gsn_define_colormap(wks, "BlAqGrYeOrReVi200")

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
      rsrc@sfXArray = lon_cntrs_by_cell
      rsrc@sfYArray = lat_cntrs_by_cell

; Set sfXCellBounds and sfYCellBounds to the cell vertex coordinates.
      rsrc@sfXCellBounds = lon_verts_by_cell
      rsrc@sfYCellBounds = lat_verts_by_cell

; Set sfDataArray to the field (which has one value per cell).
      rsrc@sfDataArray = field_by_cell

; If draw_tile_grid is True, then draw the cell edges.
      if (draw_tile_grid) then
        rsrc@cnCellFillEdgeColor = "black"
      end if

; Set the color for cells containing missing values.  This is by default
; "transparent", but we repeat it here for clarity.
      rsrc@cnMissingValFillColor = "transparent"

; Specify opacity of cell colors.
;  rsrc@cnFillOpacityF = 0.0 ; Transparent.
;  rsrc@cnFillOpacityF = 0.35
      rsrc@cnFillOpacityF = 1.0 ; Opaque.

; Turn off contour lines (we just want to see colors).
      rsrc@cnLinesOn = False
; Turn off contour line labels.
      rsrc@cnLineLabelsOn = False

;  rsrc@lbLabelBarOn = False

; Prevent overlap of labelbar labels.  Actually, the default value of 
; lbLabelAutoStride is already True for NCL V6.1.0 and later.
;  rsrc@lbLabelAutoStride = True
; Turn off labelbar box lines.
;  rsrc@lbBoxLinesOn = False

; Set the plot title.
      rsrc@tiMainString = plot_title + plot_subtitle

; Set the title font size.
      rsrc@tiMainFontHeightF = 0.015

; Set the latitude and longitude of the center of the map projection co-
; ordinate system.
      rsrc@mpCenterLonF = map_proj_ctr(0)
      rsrc@mpCenterLatF = map_proj_ctr(1)

; Set the map projection to use.  For the Lambert equal-area projection, 
; we rotate the projection such that it is centered at the North Pole.
      if (.not. ismissing(idx_cyln)) then
        rsrc@mpProjection = "CylindricalEquidistant"
      else if (.not. ismissing(idx_ortho)) then
        rsrc@mpProjection = "Orthographic"
      else if (.not. ismissing(idx_lamb)) then
        rsrc@mpProjection = "LambertEqualArea"
      end if
      end if
      end if

; Improve the resolution of the map outlines.  Default is "LowRes".
      rsrc@mpDataBaseVersion = "MediumRes"

; Turn on map tickmarks.
      rsrc@pmTickMarkDisplayMode = "Always"

; If "subreg" is specified, plot only a subregion.  Note that this has
; an effect only for the cylindrical-equidistant map projection.
      if (isvar("subreg")) then
        rsrc@mpMinLonF = lon_min
        rsrc@mpMaxLonF = lon_max
        rsrc@mpMinLatF = lat_min
        rsrc@mpMaxLatF = lat_max
      end if

; Set the minimum and maximum countour levels to plot manually.
; Do this for the first time so it is consistent for all plots
    if (itime.eq.0) then
        cplot_min = floor(min((/ field_min, field_RAP_min /)))
        print("field_min = " + field_min)
        print("field_RAP_min = " + field_RAP_min)
        print("cplot_min = " + cplot_min)
        cplot_max = ceil(max((/ field_max, field_RAP_max /)))
        print("")
        print("field_max = " + field_max)
        print("field_RAP_max = " + field_RAP_max)
        print("cplot_max = " + cplot_max)
        maxlev = 16
        mnmxint = nice_mnmxintvl( cplot_min, cplot_max, maxlev, False)
        rsrc@cnLevelSelectionMode = "ManualLevels"
        rsrc@cnMinLevelValF = mnmxint(0)
        rsrc@cnMaxLevelValF = mnmxint(1)
        rsrc@cnLevelSpacingF = mnmxint(2)
      end if

; Allow for spatially constant fields to be plotted.
      rsrc@cnConstFEnableFill = True
      rsrc@cnConstFLabelOn = False

; Do not immediately draw the contour plot nor advance the frame because
; other objects might still need to be added to the plot.
      rsrc@gsnDraw = False
      rsrc@gsnFrame = False

; Draw the color contour plot (along with a map).
      map = gsn_csm_contour_map(wks, field_by_cell, rsrc)
;
; **********************************************************************
;
; If draw_tile_bdy is specified as True, draw the boundary of each tile.
;
; **********************************************************************
;
      if (draw_tile_bdy) then

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
        do nn=0, num_tiles_to_plot-1
          n_tile = inds_tiles_to_plot(nn)
;         print("Drawing boundary of tile #" + n_tile + "...")
          id_tile_bdy(nn) = gsn_add_polyline( wks, map, \
                            lon_bdy_by_tile(nn,:), lat_bdy_by_tile(nn,:), resp)
        end do

      end if
;
; **********************************************************************
;
; If draw_RAP_domain is specified as True, draw a contour plot on the 
; RAP domain.
;
; **********************************************************************
;
      if (draw_RAP_domain) then

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
        rsrc_RAP@sfXArray = lon_cntrs_by_cell_RAP
        rsrc_RAP@sfYArray = lat_cntrs_by_cell_RAP

; Set sfXCellBounds and sfYCellBounds to the cell vertex coordinates.
        rsrc_RAP@sfXCellBounds = lon_verts_by_cell_RAP
        rsrc_RAP@sfYCellBounds = lat_verts_by_cell_RAP

; Set sfDataArray to the field (which has one value per cell).
        rsrc_RAP@sfDataArray = field_by_cell_RAP

; If draw_RAP_grid is True, then draw the cell edges.
        if (draw_RAP_grid) then
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
        rsrc_RAP@lbBoxLinesOn = False

; Turn on map tickmarks.
        rsrc_RAP@pmTickMarkDisplayMode = "Always"

; Allow for spatially constant fields to be plotted.
        rsrc_RAP@cnConstFEnableFill = True
        rsrc_RAP@cnConstFLabelOn = False

; Set the minimum and maximum countour levels to plot manually.
        rsrc_RAP@lbLabelBarOn = False
        rsrc_RAP@cnLevelSelectionMode = "ManualLevels"
        rsrc_RAP@cnMinLevelValF = cplot_min
        rsrc_RAP@cnMaxLevelValF = cplot_max

; Do not immediately draw the contour plot nor advance the frame because
; other objects might still need to be added to the plot.
        rsrc_RAP@gsnDraw = False
        rsrc_RAP@gsnFrame = False

; Draw the color contour plot (without a map since that has already been
; drawn above while generating the FV3 tiles).
        map_RAP = gsn_csm_contour(wks, field_by_cell_RAP, rsrc_RAP)

; If draw_RAP_bdy is set to True, draw a boundary around the RAP domain.
        if (draw_RAP_bdy) then
          resp := True
          resp@gsLineColor = "red"
          resp@gsLineThicknessF = 4.0
          id_RAP_bdy = gsn_add_polyline(wks, map, lon_bdy_RAP, lat_bdy_RAP, resp)
        end if

; Overlay the contour plot of the RAP domain on top of the one for the
; cubed-sphere tile(s).
        overlay(map, map_RAP)

      end if   ; end if draw_RAP_domain
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

    end do    ; End of loop over times
  end do    ; End of loop over fields

end

