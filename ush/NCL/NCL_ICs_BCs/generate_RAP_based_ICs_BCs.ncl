;
; **********************************************************************
;                                                                      *
; This script horizontally interpolates the specified 2-D or 3-D field 
;                                                                      *
; **********************************************************************
;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

load "pause.ncl"
load "strcmp.ncl"
load "interpolate_RAP_to_FV3LAM.ncl"
load "read_RAP_grid.ncl"
load "read_FV3LAM_grid_halo.ncl"
load "calc_field_stats.ncl"
load "read_RAP_horiz_field.ncl"
load "adjust_longitude_range.ncl"
load "set_cnLevels_lbLabels.ncl"
load "plot_model_field_generic.ncl"

begin




if (False) then

;print(aaa)
;pause

;bbb := [/ [/ "globe", (/-140,-60,20,55/), True, True /], \
;          [/ "RAP",   (/-140,-60,20,55/), True, True /], \
;          [/ "RAPNW", (/-140,-60,20,55/), False, False /], \
;          [/ "dummy_list_index_dont_remove" /] \
;       /]

bbb := [/ [/ "globe", (/-140,-60,20,55/), True, True /], \
          [/ "RAP",   (/-140,-60,20,55/), True, True /], \
          [/ "RAPNW", (/-140,-60,20,55/), False, False /] \
       /]

;dummy_var = [/ "dummy" /]

;aaa := ListAppend(bbb, dummy_var)

;          [/ "dummy_list_index_dont_remove" /] \

print("")
num_elems_bbb = ListCount(bbb)
print("num_elems_bbb = " + num_elems_bbb)
print("ListGetType(bbb) = " + ListGetType(bbb))
pause
print(bbb)
pause

k = 2
ccc := bbb[k]
;ccc := ListPop(bbb)
num_elems_ccc = ListCount(ccc)
;num_elems_ccc = dimsizes(ccc)
print("")
print("typeof(ccc) = " + typeof(ccc))
pause
print("ccc = bbb[" + k + "]")
print("num_elems_ccc = " + num_elems_ccc)
print(ccc)
pause

do i=0,num_elems_ccc-1
  ddd := ccc[i]
  print("")
  print("i = " + i)
  print("  ddd = ccc[" + i + "]")
  print("  dimsizes(ddd) = " + dimsizes(ddd))
  print("  ddd = " + ddd)
  pause
end do
exit

end if



;
; **********************************************************************
;                                                                      *
; Special characters that can't be directly input into an NCL string.
;                                                                      *
; **********************************************************************
;
  char_dq = integertochar(34)
  char_nl = str_get_nl()
;
; **********************************************************************
;                                                                      *
; Check whether draw_RAP_grid has been specified on the command line.  
; If not, set it to False.  Do same for draw_FV3LAM_grid.
;                                                                      *
; **********************************************************************
;
  if (.not. isvar("draw_RAP_grid")) then
    draw_RAP_grid = False
  end if

  if (.not. isvar("draw_FV3LAM_grid")) then
    draw_FV3LAM_grid = False
  end if
;
; **********************************************************************
;                                                                      *
; Check whether map_proj is specified, and if so, whether the specified
; value is valid.  Default is to use a cylindrical-equidistant project-
; ion.
;                                                                      *
; **********************************************************************
;
if (False) then

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
          " (for Lambert conformal projection)")
    print("Please specify one of these allowed values for " + \
          char_dq + "map_proj" + char_dq + ".")
    print("Stopping.")
    exit
  end if
end if
;
; **********************************************************************
;                                                                      *
; Check whether map_proj_ctr is specified.  If not, set it according to
; the specified map projection.  Note that this variable is not used for
; the cylindrical-equidistant map projection.
;                                                                      *
; **********************************************************************
;
if (False) then
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
end if
;
; **********************************************************************
;                                                                      *
; Check that the initial date and time of the forecast (CDATE), the 
; forecast length in hours (fcst_len_hrs), and the time interval (in 
; hours) between boundary condition updates (BC_interval_hrs) have all
; been specified.  If not, print out a warning and exit.
;                                                                      *
; **********************************************************************
;
  if (.not. isvar("CDATE")) then
    print("")
    print("The initial forecast date and time (CDATE) has not been specified:")
    print("  isvar(" + char_dq + "CDATE" + char_dq + ") = " + isvar("CDATE"))
    print("Stopping.")
    exit
  end if

  if (.not. isvar("fcst_len_hrs")) then
    print("")
    print("The forecast length (fcst_len_hrs) has not been specified:")
    print("  isvar(" + char_dq + "fcst_len_hrs" + char_dq + ") = " + isvar("fcst_len_hrs"))
    print("Stopping.")
    exit
  end if

  if (.not. isvar("BC_interval_hrs")) then
    print("")
    print("The boundary condition time interval (BC_interval_hrs) has not been specified:")
    print("  isvar(" + char_dq + "BC_interval_hrs" + char_dq + ") = " + isvar("BC_interval_hrs"))
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;                                                                      *
; Check that the forecast length (fcst_len_hrs) and the time interval 
; between boundary condition updates (BC_interval_hrs) are both inte-
; gers.  If not, print out a warning and exit.  Note that fcst_len_hrs 
; and BC_interval_hrs are assumed to have units of hours.
;                                                                      *
; **********************************************************************
;
  if (.not. isinteger(fcst_len_hrs)) then
    print("")
    print("The forecast length (fcst_len_hrs) must be an integer (in units of hours):")
    print("  fcst_len_hrs = " + fcst_len_hrs)
    print("  isinteger(fcst_len_hrs) = " + isinteger(fcst_len_hrs))
    print("Stopping.")
    exit
  end if

  if (.not. isinteger(BC_interval_hrs)) then
    print("")
    print("The boundary condition time interval (BC_interval_hrs) must be an integer (in units of hours):")
    print("  BC_interval_hrs = " + BC_interval_hrs)
    print("  isinteger(BC_interval_hrs) = " + isinteger(BC_interval_hrs))
    print("Stopping.")
    exit
  end if
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
if (False) then
  if (.not. isvar("plot_subregs")) then
    plot_subregs = False
  end if
  
  if (plot_subregs) then
  
    if ((.not. isvar("subreg_names")) .or. \
        (.not. isvar("subreg_coords"))) then
      print("")
      print("When plot_subregs is set to True, the arrays subreg_names " + \
            "and subreg_coords " + char_nl + \
            "must both be specified:")
      print("  plot_subregs = " + plot_subregs)
      print("  isvar(subreg_names) = " + isvar("subreg_names"))
      print("  isvar(subreg_coords) = " + isvar("subreg_coords"))
      print("Stopping.")
      exit
    end if
  
    dims_subreg_names = dimsizes(subreg_names)
    numel_subreg_names = dims_subreg_names(0)
    dims_subreg_coords = dimsizes(subreg_coords)
    left_dim_subreg_coords = dims_subreg_coords(0)
    if (numel_subreg_names .ne. left_dim_subreg_coords) then
      print("")
      print("When plot_subregs is set to True, the number of elements " + \
            "in subreg_names must " + char_nl + \
            "be equal to the size of the leftmost dimension of subreg_coords:")
      print("  plot_subregs = " + plot_subregs)
      print("  numel_subreg_names = " + numel_subreg_names)
      print("  left_dim_subreg_coords = " + left_dim_subreg_coords)
      print("Stopping.")
      exit
    end if
  
    num_subregions = numel_subreg_names

  else

    num_subregions = 1

  end if
end if




  if (.not. isvar("regions")) then
    regions=[/ [/ "globe", (/-180, 180, -90,  90/), True,  True /] /]
  end if



  num_regions = ListCount(regions) - 1
  region_names = new((/ num_regions /), "string")
  region_bounds = new((/ num_regions, 4 /), "float")
;  region_draw_RAP_grid = new((/ num_regions /), "logical")
;  region_draw_FV3LAM_grid = new((/ num_regions /), "logical")
  draw_grid_by_region = True
  draw_grid_by_region@RAP = new((/ num_regions /), "logical")
  draw_grid_by_region@FV3LAM = new((/ num_regions /), "logical")

  do i=0, num_regions-1
;print("")
;print("i = " + i)
    curnt_region := regions[i]
;print(curnt_region)
    region_names(i) = curnt_region[0]
    region_bounds(i,:) = curnt_region[1]
;    region_draw_RAP_grid(i) = curnt_region[2]
;    region_draw_FV3LAM_grid(i) = curnt_region[3]
    draw_grid_by_region@RAP(i) = curnt_region[2]
    draw_grid_by_region@FV3LAM(i) = curnt_region[3]
;pause
  end do

;print("")
;print(region_names)
;print("")
;print(region_bounds)
;print("")
;;print(region_draw_RAP_grid)
;print(draw_grid_by_region@RAP)
;print("")
;;print(region_draw_FV3LAM_grid)
;print(draw_grid_by_region@FV3LAM)
;pause






print("")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("Reading in RAP grid...")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("")

;
; **********************************************************************
;                                                                      *
; Read in the RAP grid.
;                                                                      *
; **********************************************************************
;
  file_dir = "./"
;file_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509"

  RAP_geo_file = "geo_em.d01.RAP.nc"
  RAP_geo_file = file_dir + "/" + RAP_geo_file

  out := read_RAP_grid(RAP_geo_file)

  nx_RAP = out@nx
  ny_RAP = out@ny
;  num_cells_RAP = out@num_cells
;  lon_cntrs_by_cell_RAP = out@lon_cntrs_by_cell
;  lat_cntrs_by_cell_RAP = out@lat_cntrs_by_cell
;  lon_verts_by_cell_RAP = out@lon_verts_by_cell
;  lat_verts_by_cell_RAP = out@lat_verts_by_cell

;  lon_min = -180.0
;  lon_cntrs_by_cell_RAP := adjust_longitude_range( \
;                           lon_cntrs_by_cell_RAP, lon_min, "degs")
;  exit

  lon_cntrs_by_cell = True
  lat_cntrs_by_cell = True
  lon_verts_by_cell = True
  lat_verts_by_cell = True
  field_by_cell = True


  lon_cntrs_by_cell@RAP = out@lon_cntrs_by_cell
  lat_cntrs_by_cell@RAP = out@lat_cntrs_by_cell
  lon_verts_by_cell@RAP = out@lon_verts_by_cell
  lat_verts_by_cell@RAP = out@lat_verts_by_cell


print("")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("Reading in FV3LAM grid...")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("")

;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
;  nh = 4
  nh = 50

;  FV3LAM_grid_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/fv3gfs/fix/fix_fv3/rgnl_C384_strch_1p8_rfn_5_HRRR"
  FV3LAM_grid_dir = "/scratch3/BMC/fim/Gerard.Ketefian/regional_FV3_EMC_visit_20180509/work_dirs/rgnl_C384_strch_1p5_rfn_3_descriptive_str/filter_topo"
  CRES = "C384"
  FV3LAM_halo4_grid_file = CRES + "_grid.tile7.halo4.nc"
  FV3LAM_halo4_grid_file_full = FV3LAM_grid_dir + "/" + FV3LAM_halo4_grid_file

  out := read_FV3LAM_grid_halo(FV3LAM_halo4_grid_file_full, nh)

;;  num_cells_FV3LAM = out@num_cells_total
;  lon_cntrs_by_cell_FV3LAM = out@lon_cntrs_by_cell
;  lat_cntrs_by_cell_FV3LAM = out@lat_cntrs_by_cell
;  lon_verts_by_cell_FV3LAM = out@lon_verts_by_cell
;  lat_verts_by_cell_FV3LAM = out@lat_verts_by_cell

  lon_cntrs_by_cell@FV3LAM = out@lon_cntrs_by_cell
  lat_cntrs_by_cell@FV3LAM = out@lat_cntrs_by_cell
  lon_verts_by_cell@FV3LAM = out@lon_verts_by_cell
  lat_verts_by_cell@FV3LAM = out@lat_verts_by_cell











print("")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("Looping over all RAP output times and RAP fields...")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("")

;
; **********************************************************************
;                                                                      *
; Read in the RAP wrfout file for a specified output time.
;                                                                      *
; **********************************************************************
;
  RAP_output_dir := "."

  YYYY = str_get_cols((/CDATE/), 0, 3)
  MM = str_get_cols((/CDATE/), 4, 5)
  DD = str_get_cols((/CDATE/), 6, 7)
  HH = str_get_cols((/CDATE/), 8, 9)

  RAP_init_date := YYYY + "-" + MM + "-" + DD
  RAP_init_hr := HH
print("")
print("RAP_init_date = " + RAP_init_date)
print("RAP_init_hr = " + RAP_init_hr)

  remainder = fcst_len_hrs % BC_interval_hrs
  if (remainder .ne. 0) then
    print("")
    print("Error.  The forecast length is not evenly divisible by the BC time interval:")
    print("  fcst_len_hrs = " + fcst_len_hrs + " hrs")
    print("  BC_interval_hrs = " + BC_interval_hrs + " hrs")
    print("  remander = fcst_len_hrs % BC_interval_hrs = " + remainder)
    print("Exiting script.")
    exit
  else
    RAP_fcst_hrs := ispan(0, fcst_len_hrs, BC_interval_hrs)
  end if
print("")
print("RAP_fcst_hrs = " + RAP_fcst_hrs)

  RAP_fcst_hrs@units = "hours since " + RAP_init_date + " " + RAP_init_hr + ":00:00"
print("")
print("RAP_fcst_hrs@units = " + RAP_fcst_hrs@units)
  RAP_fcst_dates_times = cd_string(RAP_fcst_hrs, "%Y-%N-%D_%H_%M_%S")
print("")
print("RAP_fcst_dates_times = " + RAP_fcst_dates_times)
  num_RAP_output_times := dimsizes(RAP_fcst_dates_times)

;  RAP_field_names := (/ "T", "VAR_SSO" /)
;  RAP_field_names := (/ "T", "PSFC" /)
;  RAP_field_names := (/ "PSFC" /)
;  RAP_field_names := (/ "T" /)
  RAP_field_names := (/ "VAR_SSO" /)

  num_RAP_fields := dimsizes(RAP_field_names)

;  RAP_vert_levels = (/ 5, 10 /)
  RAP_vert_levels = (/ 5 /)
  num_RAP_levels := dimsizes(RAP_vert_levels)

  do n=0, num_RAP_output_times-1

    fcst_hr := RAP_fcst_hrs(n)

    RAP_fcst_date_time = RAP_fcst_dates_times(n)
    wrfout_file = RAP_output_dir + "/wrfout_d01_" + RAP_fcst_date_time + ".nc"
    f_wrfout = addfile(wrfout_file, "r")
;
; **********************************************************************
;                                                                      *
; Loop over fields.
;                                                                      *
; **********************************************************************
;
    do f=0, num_RAP_fields-1

      field_name := RAP_field_names(f)
;
; **********************************************************************
;                                                                      *
; Check whether the specified field exists in the specified file.  If 
; not, print out a message and exit script.
;                                                                      *
; **********************************************************************
;
      if (.not. isfilevar(f_wrfout, field_name)) then
        print("")
        print("Specified field does not exist in specified file:")
        print("  field_name = " + field_name)
        print("  wrfout_file = " + wrfout_file)
        print("Stopping.")
        exit
      end if
;
; **********************************************************************
;                                                                      *
; Get the current field's dimension names and dimension sizes.  Then 
; calculate its rank (i.e. the number of dimensions).
;                                                                      *
; **********************************************************************
;
      field_dim_names := getfilevardims(f_wrfout, field_name)
;      field_dim_sizes := getfilevardimsizes(f_wrfout, field_name)
      field_rank := dimsizes(field_dim_names)
;
; **********************************************************************
;                                                                      *
; Determine whether field is a function of time, altitude, latitude, 
; and/or longitude.
;                                                                      *
; **********************************************************************
;
      func_t = False
      func_z = False
      func_y = False
      func_x = False
    
      do d=0, field_rank-1
    
        dim_name = field_dim_names(d)
    
        idx := str_match_ind(dim_name, "Time")
        if (.not. ismissing(idx)) then
          func_t = True
        end if
    
        idx1 := str_match_ind(dim_name, "bottom_top")
        idx2 := str_match_ind(dim_name, "bottom_top_stag")
        if ((.not. ismissing(idx1)) .or. (.not. ismissing(idx2))) then
          func_z = True
        end if
    
        idx1 := str_match_ind(dim_name, "south_north")
        idx2 := str_match_ind(dim_name, "south_north_stag")
        if ((.not. ismissing(idx1)) .or. (.not. ismissing(idx2))) then
          func_y = True
        end if
    
        idx1 := str_match_ind(dim_name, "west_east")
        idx2 := str_match_ind(dim_name, "west_east_stag")
        if ((.not. ismissing(idx1)) .or. (.not. ismissing(idx2))) then
          func_x = True
        end if
    
      end do

;print("")
;print("func_t = " + func_t)
;print("func_z = " + func_z)
;print("func_y = " + func_y)
;print("func_x = " + func_x)
;pause

;
; **********************************************************************
;                                                                      *
; For a field that is not a function of altitude (e.g. a 2-D field), we
; set the the number of RAP vertical levels to consider to 1 (as opposed
; to the number of levels specified in the array RAP_vert_levels above).
;                                                                      *
; **********************************************************************
;
      kk_max = num_RAP_levels
      if (.not. func_z) then
        kk_max = 1
      end if
;
; **********************************************************************
;                                                                      *
; Loop over all relevant vertical levels.
;                                                                      *
; **********************************************************************
;
      do kk=0, kk_max-1

        k = RAP_vert_levels(kk)
        if (.not. func_z) then
          k = -1
        end if
print("")
print("field_name = " + field_name + "; k = " + k)
pause
        print_field_stats = True
        out := read_RAP_horiz_field( \
               f_wrfout, field_name, func_z, k, print_field_stats)

        field_desc = out@field_desc
        field_units = out@field_units
        field_by_cell@RAP = out@field_by_cell
;        field_min_RAP = out@field_min
;        field_max_RAP = out@field_max





















print("")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("Interpolating RAP field onto halo of FV3LAM regional domain...")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("")

;
; **********************************************************************
;                                                                      *
; The flag gen_weights determines whether NetCDF file containing the in-
; terpolation weights will be generated along with NetCDF files describ-
; ing the source (i.e. RAP) and destination (i.e. latlon) grids.  The 
; names of these files are specified by opt@WgtFileName, opt@SrcFile-
; Name, and opt@DstFileName, respectively.  If gen_weights is set to 
; False on the command line, these three files must already exist in or-
; der for the ESMF interpolation to work; otherwise, the interpolation 
; will fail.  If gen_weights is set to True on the command line, these 
; files will be regenerated whether or not they already exist.  Finally,
; if gen_weights is not yet specified (e.g. somewhere above or on the 
; command line), the "if" statement below will set it to False if all 
; three NetCDF files already exist and to True otherwise.
;                                                                      *
; **********************************************************************
;
;        gen_weights = True
        gen_weights = False

        src_grid_filename = "src_grid_RAP.nc"
        dst_grid_filename = "dst_grid_FV3LAMhalo" + nh + ".nc"
        weights_filename = "weights_RAP_to_FV3LAMhalo" + nh + ".nc"

        print("")
        print("Source grid, destination grid, and weights files are:")
        print("  src_grid_filename = " + src_grid_filename)
        print("  dst_grid_filename = " + dst_grid_filename)
        print("  weights_filename = " + weights_filename)

        if (.not. isvar("gen_weights")) then
       
          if (fileexists(src_grid_filename) .and. \
              fileexists(dst_grid_filename) .and. \
              fileexists(weights_filename)) then
            print("")
            print("Source grid (RAP), destination grid (FV3LAM), and " + \
                  "weights files " + char_nl + \
                  "already exist.  Not regenerating these files.")
            gen_weights = False
          else
            print("")
            print("Source grid (RAP), destination grid (FV3LAM), and/or " + \
                  "weights file do " + char_nl + \
                  "not exist and must be generated.")
            gen_weights = True
          end if
        
        end if

        if (.not. gen_weights .and. \
            (.not. fileexists(src_grid_filename) .or. \
             .not. fileexists(dst_grid_filename) .or. \
             .not. fileexists(weights_filename))) then
          print("")
          print("gen_weights has been set to True, but the source grid (RAP) " + \
                "file, the destination " + char_nl + \
                "grid (FV3LAM) file, and/or the weights file does/do not exist:")
          print("  fileexists(src_grid_filename) = " + fileexists(src_grid_filename))
          print("  fileexists(dst_grid_filename) = " + fileexists(dst_grid_filename))
          print("  fileexists(weights_filename) = " + fileexists(weights_filename))
          print("Set gen_weights to True and rerun.")
          print("Stopping.")
          exit
        end if
;
; **********************************************************************
;                                                                      *
; Perform interpolation (regridding) of the field on the RAP grid to the
; halo of the FV3LAM grid.
;                                                                      *
; **********************************************************************
;
;        out := interpolate_RAP_to_FV3LAM( \
;               lon_cntrs_by_cell_RAP, lat_cntrs_by_cell_RAP, \
;               lon_verts_by_cell_RAP, lat_verts_by_cell_RAP, \
;               lon_cntrs_by_cell_FV3LAM, lat_cntrs_by_cell_FV3LAM, \
;               lon_verts_by_cell_FV3LAM, lat_verts_by_cell_FV3LAM, \
;               field_by_cell_RAP, \
;               gen_weights, \
;               src_grid_filename, dst_grid_filename, weights_filename)

        out := interpolate_RAP_to_FV3LAM( \
               lon_cntrs_by_cell@RAP, lat_cntrs_by_cell@RAP, \
               lon_verts_by_cell@RAP, lat_verts_by_cell@RAP, \
               lon_cntrs_by_cell@FV3LAM, lat_cntrs_by_cell@FV3LAM, \
               lon_verts_by_cell@FV3LAM, lat_verts_by_cell@FV3LAM, \
               field_by_cell@RAP, \
               gen_weights, \
               src_grid_filename, dst_grid_filename, weights_filename)

        field_by_cell@FV3LAM = out@field_by_cell_FV3LAM
;
; **********************************************************************
;                                                                      *
; Calculate and print out basic statistics of the regridded field on the
; FV3LAM grid.
;                                                                      *
; **********************************************************************
;
        print_field_stats = True
        out := calc_field_stats( \
               field_by_cell@FV3LAM, field_desc, field_units, print_field_stats)
;        field_min_FV3LAM = out@field_min
;        field_max_FV3LAM = out@field_max


















;
; **********************************************************************
;                                                                      *
; If plot_RAP_fields or plot_FV3LAM_fields is set to True, plot the 
;                                                                      *
; **********************************************************************
;
        if (plot_RAP_fields .or. plot_FV3LAM_fields) then

print("")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("Plotting RAP and/or (interpolated) FV3LAM fields...")
print("")
print("==============================================================")
print("==============================================================")
print("")
print("")

          fn_graphics_base := field_name
          if (func_z) then
            fn_graphics_base = fn_graphics_base + "_k" + k
          end if
          if (func_t) then
            fn_graphics_base = fn_graphics_base + "_t" + fcst_hr + "hr"
          end if

          num_cnLevels = 10

          plot_options_common := True
          plot_options_common@fn_graphics_base = fn_graphics_base
          plot_options_common@num_cnLevels = num_cnLevels
;
; Set the flag that determines whether plots will be resized (e.g. to a
; larger area than the default).  This would generally be done using the
; gsnMaximize resource, but it's not clear how to use or reset this re-
; source after adding annotations to the plot (annotations in our case
; are the plot titles).  Thus, we perform the resizing/maximization man-
; ually.
;
          plot_options_common@resize_plot = True
;
; Set the size (either width or height) of the bounding box which the 
; resized plot will have.  Note that this is in NDC (non-dimensional co-
; ordinate, aka page) coordinates.  This value must be between 0 and 1.
;
          plot_options_common@bounding_box_size_NDC = 0.98

          if (isvar("map_proj")) then
            plot_options_common@map_proj := map_proj
          end if

          if (isvar("map_proj_ctr")) then
            plot_options_common@map_proj_ctr := map_proj_ctr
          end if
;
; **********************************************************************
;                                                                      *
; Loop over the regions to plot.
;                                                                      *
; **********************************************************************
;
          do s=0,num_regions-1

            plot_options := plot_options_common
  
            plot_options@region_name = region_names(s)
            plot_options@lon_min = region_bounds(s,0)
            plot_options@lon_max = region_bounds(s,1)
            plot_options@lat_min = region_bounds(s,2)
            plot_options@lat_max = region_bounds(s,3)
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
            if (plot_RAP_fields) then

              model_name = "RAP"

              out := plot_model_field_generic( \
                     model_name, \
                     lon_cntrs_by_cell@RAP, lat_cntrs_by_cell@RAP, \
                     lon_verts_by_cell@RAP, lat_verts_by_cell@RAP, \
                     field_by_cell@RAP, \
                     field_name, field_desc, field_units, \
                     func_t, func_z, \
                     fcst_hr, k, \
                     draw_grid_by_region@RAP(s), \
                     plot_options)

              copy_VarAtts(out, plot_options)

            end if
;
; **********************************************************************
;                                                                      *
;
;                                                                      *
; **********************************************************************
;
            if (plot_FV3LAM_fields) then

              model_name = "FV3LAM"

              out := plot_model_field_generic( \
                     model_name, \
                     lon_cntrs_by_cell@FV3LAM, lat_cntrs_by_cell@FV3LAM, \
                     lon_verts_by_cell@FV3LAM, lat_verts_by_cell@FV3LAM, \
                     field_by_cell@FV3LAM, \
                     field_name, field_desc, field_units, \
                     func_t, func_z, \
                     fcst_hr, k, \
                     draw_grid_by_region@FV3LAM(s), \
                     plot_options)

            end if

          end do

        end if



      end do

    end do

  end do


end


