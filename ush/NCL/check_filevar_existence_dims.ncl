;
; **********************************************************************
;
; File name: check_filevar_existence_dims.ncl
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

undef("check_filevar_existence_dims")

function check_filevar_existence_dims( \
         file_name:string, \
         var_name:string, \
         nx:integer, ny:integer, \
         vert_inds[*]:integer, \
         time_inds[*]:integer)

local fp, \
      all_var_names, \
      var_dim_names, var_dim_sizes, var_rankj, \
      x_filedim_names, y_filedim_names, \
      z_filedim_names, t_filedim_names, \
      x_filedim_names_str, y_filedim_names_str, \
      z_filedim_names_str, t_filedim_names_str, \
      var_dim_names_str, var_dim_sizes_str, \
      func_xy_only, func_xyz_only, func_xyt_only, func_xyzt_only, \
      msg, func_x, func_y, func_z, func_t, \
      nz, vert_inds_min, vert_inds_max, \
      nt, time_inds_min, time_inds_max, \
      x_dim_size, y_dim_size, average_in_x, average_in_y, \
      var_info

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
; Open the specified file for reading.
;
; **********************************************************************
;
  print("")
  print("" + separator_line)
  print("Opening file for reading:")
  print("")
  print("  file_name = " + char_dq + file_name + char_dq)

  fp = addfile(file_name, "r")
;
; **********************************************************************
;
; Get the names of all variables in the file.  Then check if the speci-
; filed variable is one of the ones in the file.  If not, print out an
; error message and exit.
;
; **********************************************************************
;
  all_var_names = getfilevarnames(fp) 

  if (.not. strcmp_exact(all_var_names, var_name)) then
    msg := char_nl + \
"Variable not found in file:" + char_nl + \
"  file_name = " + char_dq + file_name + char_dq + char_nl + \
"  var_name = " + char_dq + var_name + char_dq + char_nl + \
"Stopping."
    print("" + msg)
    exit
  end if
;
; **********************************************************************
;
; Get the variable's dimension names and sizes, and calculate the rank
; of the variable.
;
; **********************************************************************
;
  var_dim_names = getfilevardimnames(fp, var_name)
  var_dim_sizes = getfilevardimsizes(fp, var_name)
  var_rank = dimsizes(var_dim_sizes)
;
; **********************************************************************
;
; Set the dimension names we expect to see in the file(s) from which we
; will read in the FV3SAR field.  This depends on the file base name.  
; These dimension names will be used to check the consistency of the di-
; mensions of the specified field.
;
; **********************************************************************
;
;  x_filedim_names = (/ "grid_x", "grid_xt", "nx", "nxp" /)
;  y_filedim_names = (/ "grid_y", "grid_yt", "ny", "nyp" /)
;  z_filedim_names = (/ "phalf", "pfull" /)
;  t_filedim_names = (/ "time" /)
; The following are temporary to be able to process ICs and surface files.
; Either make these permanent or change the gfs_data.tile7.nc and 
; sfc_data.tile7.nc files to have dimension names that are consistent 
; with other files (e.g. instead of xaxis_1 and lon, should have nx).
  x_filedim_names = (/ "grid_x", "grid_xt", "nx", "nxp", "xaxis_1", "lon" /)
  y_filedim_names = (/ "grid_y", "grid_yt", "ny", "nyp", "yaxis_1", "lat" /)
  z_filedim_names = (/ "phalf", "pfull", "zaxis_1", "lev" /)
  t_filedim_names = (/ "time", "Time" /)
;
; **********************************************************************
;
; Create strings to use in output messages.
;
; **********************************************************************
;
  x_filedim_names_str := char_dq + x_filedim_names + char_dq
  x_filedim_names_str := "(" + str_join(x_filedim_names_str, ", ") + ")"

  y_filedim_names_str := char_dq + y_filedim_names + char_dq
  y_filedim_names_str := "(" + str_join(y_filedim_names_str, ", ") + ")"

  z_filedim_names_str := char_dq + z_filedim_names + char_dq
  z_filedim_names_str := "(" + str_join(z_filedim_names_str, ", ") + ")"

  t_filedim_names_str := char_dq + t_filedim_names + char_dq
  t_filedim_names_str := "(" + str_join(t_filedim_names_str, ", ") + ")"

  var_dim_names_str := char_dq + var_dim_names + char_dq
  var_dim_names_str := "(" + str_join(var_dim_names_str, ", ") + ")"

  var_dim_sizes_str := tostring(var_dim_sizes)
  var_dim_sizes_str := "(" + str_join(var_dim_sizes_str, ", ") + ")"
;
; **********************************************************************
;
; Initialize the logical variables that will indicate the functional de-
; pendence of the specified variable to False.  These variables are:
;
; func_xy_only:
; This will be set to True if the variable is a function of the horizon-
; tal coordinates x and y but not of the verical coordinate (referred to 
; generically here as "z") or of time (referred to here as "t").
;
; func_xyz_only:
; This will be set to True if the variable is a function of x, y, and z
; but not of t.
;
; func_xyt_only:
; This will be set to True if the variable is a function of x, y, and t
; but not of z.
;
; func_xyzt_only:
; This will be set to True if the variable is a function of x, y, z, and
; t.
;
; Note that only one of these variables will eventually get reset to 
; True.
;
; **********************************************************************
;
  func_xy_only = False
  func_xyz_only = False
  func_xyt_only = False
  func_xyzt_only = False
;
; **********************************************************************
;
; We do not consider any variable that is not a function of at least x
; and y (which would mean that its rank is less than 2).  Check for 
; this.
;
; **********************************************************************
;
  if (var_rank .lt. 2) then

    msg := char_nl + \
"The specified variable must have at least two dimensions to be plotted:" + char_nl + \
"  var_name = " + char_dq + var_name + char_dq + char_nl + \
"  var_rank = " + var_rank + char_nl + \
"  var_dim_names = " + var_dim_names_str + char_nl + \
"  var_dim_sizes = " + var_dim_sizes_str + char_nl + \
"Stopping."
    print("" + msg)
    exit
;
; **********************************************************************
;
; Now consider only variables that have a rank of at least 2.
;
; **********************************************************************
;
  else
;
; **********************************************************************
;
; We require that the last dimension of the variable represent x and the
; next to last dimension represent y.  Check for this.
;
; **********************************************************************
;
; Check whether the last dimension represents the x horizontal direction
; (as defined by the string array x_filedim_names; this direction may 
; be, for example, longitude).
;
    func_x = False
    do i=0, dimsizes(x_filedim_names)-1
      if (strcmp_exact(var_dim_names(var_rank-1), x_filedim_names(i))) then
        func_x = True
        break
      end if
    end do
;
; Check whether the next-to-last dimension represents the y horizontal
; direction (as defined by the string array y_filedim_names; this direc-
; tion may be, for example, latitude).
;
    func_y = False
    do i=0, dimsizes(y_filedim_names)-1
      if (strcmp_exact(var_dim_names(var_rank-2), y_filedim_names(i))) then
        func_y = True
        break
      end if
    end do
;
; If the last and next-to-last dimensions do not represent the x and y
; horizontal directions, print out an error message and exit.
;
    if (.not. (func_x .and. func_y)) then
      msg := char_nl + \
"For a variable of rank greater than or equal to 2, the last dimension " + char_nl + \
"must represent the x horizontal direction [i.e. var_dim_names(var_rank-1) " + char_nl + \
"must be equal to one of the elements of x_filedim_names], and the next-" + char_nl + \
"to-last dimension must represent the y horizontal direction [i.e. var_-" + char_nl + \
"dim_names(var_rank-2) must be equal to one of the elements of y_filedim_-" + char_nl + \
"names]:" + char_nl + \
"  var_name = " + char_dq + var_name + char_dq + char_nl + \
"  var_rank = " + var_rank + char_nl + \
"  var_dim_names = " + var_dim_names_str + char_nl + \
"  var_dim_names(var_rank-1) = var_dim_names(" + (var_rank-1) + ") = " + \
char_dq + var_dim_names(var_rank-1) + char_dq + char_nl + \
"  x_filedim_names = " + x_filedim_names_str + char_nl + \
"  var_dim_names(var_rank-2) = var_dim_names(" + (var_rank-2) + ") = " + \
char_dq + var_dim_names(var_rank-2) + char_dq + char_nl + \
"  y_filedim_names = " + y_filedim_names_str + char_nl + \
"Stopping."
      print("" + msg)
      exit
    end if
;
; **********************************************************************
;
; At this point, we know that the specified variable has a rank of at
; least 2 and that its last dimension represents x and its next-to-last
; dimension represents y.  Thus, if the variable has a rank of exactly 
; 2, it must be a function of x and y only.  In this case, set func_xy_-
; only to True.
;
; **********************************************************************
;
    if (var_rank .eq. 2) then

      func_xy_only = True
;
; **********************************************************************
;
; Next, consider a variable of rank 3.  In this case, we want the zeroth 
; dimension to represent either z or t.  Check for this.
;
; **********************************************************************
;
    else if (var_rank .eq. 3) then
;
; Check whether the zeroth dimension represents z.  If so, set func_-
; xyz_only to True.
;
      do i=0, dimsizes(z_filedim_names)-1
        if (strcmp_exact(var_dim_names(0), z_filedim_names(i))) then
          func_xyz_only = True
          break
        end if
      end do
;
; If the zeroth dimension does not represent z, check whether it repre-
; sents z.  If so, set func_xyt_only to True.
;
      if (.not. func_xyz_only) then
        do i=0, dimsizes(t_filedim_names)-1
          if (strcmp_exact(var_dim_names(0), t_filedim_names(i))) then
            func_xyt_only = True
            break
          end if
        end do
      end if
;
; If the zeroth dimension represents neither z nor t, print out an error
; message and exit.
;
      if (.not. (func_xyt_only .or. func_xyz_only)) then
        msg := char_nl + \
"For a variable of rank 3, the first dimension [i.e. var_dim_names(0)] " + char_nl + \
"must represent either time or the vertical direction [i.e. var_dim_names(0) " + char_nl + \
"must be equal to either one of the elements of t_filedim_names or to one " + char_nl + \
"of the elements of z_filedim_names]:" + char_nl + \
"  var_name = " + var_name + char_nl + \
"  var_rank = " + var_rank + char_nl + \
"  var_dim_names = " + var_dim_names_str + char_nl + \
"  var_dim_names(0) = " + char_dq + var_dim_names(0) + char_dq + char_nl + \
"  z_filedim_names = " + z_filedim_names_str + char_nl + \
"  t_filedim_names = " + t_filedim_names_str + char_nl + \
"Stopping."
        print("" + msg)
        exit
      end if
;
; **********************************************************************
;
; Consider a variable of rank 4.  In this case, we require the zeroth 
; dimension to represent t and the first dimension to represent z.  
; Check for this.
;
; **********************************************************************
;
    else if (var_rank .eq. 4) then
;
; Check whether the zeroth dimension represents t.  If so, set the tem-
; porary variable func_t to True.
;
      func_t = False
      do i=0, dimsizes(t_filedim_names)-1
        if (strcmp_exact(var_dim_names(0), t_filedim_names(i))) then
          func_t = True
          break
        end if
      end do
;
; Check whether the first dimension represents z.  If so, set the tempo-
; rary variable func_z to True.
;
      func_z = False
      do i=0, dimsizes(z_filedim_names)-1
        if (strcmp_exact(var_dim_names(1), z_filedim_names(i))) then
          func_z = True
          break
        end if
      end do
;
; If the zeroth dimension represents t and the first dimension repre-
; sents z, then we know that the variable is a function of x, y, z, and
; t (since we already know that the last and next-to-last dimensions 
; represent x and y, respectively).  In this case, we set func_xyzt_only
; to True.  Otherwise, we print out an error message and exit.
;
      if (func_t .and. func_z) then
        func_xyzt_only = True
      else
        msg := char_nl + \
"For a variable of rank 4, the first dimension [i.e. var_dim_names(0)] " + char_nl + \
"must represent time [i.e. var_dim_names(0) must be equal to t_filedim_-" + char_nl + \
"names], the second dimension [i.e. var_dim_names(1)] must represent the " + char_nl + \
"vertical direction [i.e. var_dim_names(1) must be equal to one of the " + char_nl + \
"elements of z_filedim_names], the third dimension [i.e. var_dim_names(2)] " + char_nl + \
"must represent the y horizontal direction [i.e. var_dim_names(2) must " + char_nl + \
"be equal to one of the elements of y_filedim_names], and the fourth di-" + char_nl + \
"mension [i.e. var_dim_names(3)] must represent the x horizontal direc-" + char_nl + \
"tion [i.e. var_dim_names(3) must be equal to one of the elements of x_-" + char_nl + \
"filedim_names]:" + char_nl + \
"  var_name = " + var_name + char_nl + \
"  var_rank = " + var_rank + char_nl + \
"  var_dim_names = " + var_dim_names_str + char_nl + \
"  var_dim_names(0) = " + char_dq + var_dim_names(0) + char_dq + char_nl + \
"  var_dim_names(1) = " + char_dq + var_dim_names(1) + char_dq + char_nl + \
"  var_dim_names(2) = " + char_dq + var_dim_names(2) + char_dq + char_nl + \
"  var_dim_names(3) = " + char_dq + var_dim_names(3) + char_dq + char_nl + \
"  t_filedim_names = " + t_filedim_names_str + char_nl + \
"  z_filedim_names = " + z_filedim_names_str + char_nl + \
"  y_filedim_names = " + y_filedim_names_str + char_nl + \
"  x_filedim_names = " + x_filedim_names_str + char_nl + \
"Stopping."
        print("" + msg)
        exit
      end if
;
; **********************************************************************
;
; We do not allow variables with rank greater than 4.  
;
; **********************************************************************
;
    else

      msg := char_nl + \
"Variables with rank greater than 4 cannot (yet) be handled by this function:" + char_nl + \
"  var_name = " + var_name + char_nl + \
"  var_rank = " + var_rank + char_nl + \
"  var_dim_names = " + var_dim_names_str + char_nl + \
"Stopping."
      print("" + msg)
      exit

    end if
    end if
    end if

  end if
;
; **********************************************************************
;
; For a variable that is a function of the vertical, ensure that the 
; vertical indices at which we will attempt to make a 2-D contour plot
; of the variable are not out of the bounds of its vertical dimension.
;
; **********************************************************************
;
  if (func_xyz_only .or. func_xyzt_only) then

    if (func_xyz_only) then
      nz = var_dim_sizes(0)
    else
      nz = var_dim_sizes(1)
    end if

    vert_inds_min = min(vert_inds)
    vert_inds_max = max(vert_inds)

    if (vert_inds_min .lt. 0) then
      msg := char_nl + \
"The minimum specified vertical index must be greater than or equal to 0:" + char_nl + \
"  vert_inds_min = " + vert_inds_min + char_nl + \
"Stopping."
      print("" + msg)
      exit
    end if

    if (vert_inds_max .ge. nz) then
      msg := char_nl + \
"The maximum specified vertical index must be less than the variable's " + char_nl + \
"vertical dimension size (nz):" + char_nl + \
"  var_name = " + char_dq + var_name + char_dq + char_nl + \
"  nz = " + nz + char_nl + \
"  vert_inds_max = " + vert_inds_max + char_nl + \
"Stopping."
      print("" + msg)
      exit
    end if

  end if
;
; **********************************************************************
;
; For a variable that is a function of time, ensure that the time indi-
; ces at which we will attempt to make a 2-D contour plot of the varia-
; ble are not out of the bounds of its time dimension.
;
; **********************************************************************
;
  if (func_xyt_only .or. func_xyzt_only) then

    nt = var_dim_sizes(0)

    time_inds_min = min(time_inds)
    time_inds_max = max(time_inds)

    if (time_inds_min .lt. 0) then
      msg := char_nl + \
"The minimum specified time index must be greater than or equal to 0:" + char_nl + \
"  time_inds_min = " + time_inds_min + char_nl + \
"Stopping."
      print("" + msg)
      exit
    end if

    if (time_inds_max .ge. nt) then
      msg := char_nl + \
"The maximum specified time index must be less than the variable's time " + char_nl + \
"dimension size (nt):" + char_nl + \
"  var_name = " + char_dq + var_name + char_dq + char_nl + \
"  nt = " + nt + char_nl + \
"  time_inds_max = " + time_inds_max + char_nl + \
"Stopping."
      print("" + msg)
      exit
    end if

  end if
;
; **********************************************************************
;
; A variable may be given at cell centers, on the faces of cells, or at
; cell vertices.  If nx and ny are the number of cells in the x and y 
; directions, respectively (obtained from the grid files), then:
;
; 1) If the variable is given at cell centers, then the variable's x 
;    dimension size should be nx, and its y dimension size should be ny.
;
; 2) If the variable is given on cell faces that lie along curves of 
;    constant x (if x happens to be the west-to-east direction, these
;    would be the western and eastern cell faces), then the variable's
;    x dimension size should be nx+1, and its y dimension size should be
;    ny.
;
; 3) If the variable is given on cell faces that lie along curves of 
;    constant y (if y happens to be the south-to-north direction, these
;    would be the southern and northern cell faces), then the variable's
;    x dimension size should be nx, and its y dimension size should be
;    ny+1.
;
; 4) If the variable is given at cell veritces, then the variable's x
;    dimension size should be nx+1, and its y dimension size should be
;    ny+1.
;
; The plotting approach we use assumes that varaible values are given at
; cell centers.  Thus, if the variable is given on cell faces that lie 
; along curves of constant x, we must average the variable in the x di-
; rection to obtain a field at cell centers.  Similarly, if the variable
; is given on cell faces that lie along curves of constant y, we must 
; average the variable in the y direction to obtain a field at cell cen-
; ters.  Finally, if the variable is given at cell vertices, we must 
; average the variable in both the x and y directions to obtain a field
; at cell centers.  In all cases, the field after averaging will have 
; dimension sizes nx by ny.  Below, we set flags that indicate the di-
; rections in which the averaging needs to be performed.
;
; **********************************************************************
;
  x_dim_size = var_dim_sizes(var_rank-1)
  y_dim_size = var_dim_sizes(var_rank-2)

  if ((x_dim_size .eq. nx) .and. (y_dim_size .eq. ny)) then
    average_in_x = False
    average_in_y = False
  else if ((x_dim_size .eq. (nx+1)) .and. (y_dim_size .eq. ny)) then
    average_in_x = True
    average_in_y = False
  else if ((x_dim_size .eq. nx) .and. (y_dim_size .eq. (ny+1))) then
    average_in_x = False
    average_in_y = True
  else if ((x_dim_size .eq. (nx+1)) .and. (y_dim_size .eq. (ny+1))) then
    average_in_x = True
    average_in_y = True
  else
    msg := char_nl + \
"The horizontal dimensions of the variable read in from file [given by " + char_nl + \
"var_dim_sizes(var_rank-1) in the x direction and var_dim_sizes(var_rank-2) " + char_nl + \
"in the y direction] are not consistent with the dimensions (nx,ny) read " + char_nl + \
"in from the grid file.  The variable dimension sizes must be (nx,ny), " + char_nl + \
"(nx+1,ny), (nx,ny+1), or (nx+1,ny+1):" + char_nl + \
"  (nx, ny) = (" + nx + ", " + ny + ")  [These are the dimensions read from the grid file.]" + char_nl + \
"  file_name = " + char_dq + file_name + char_dq + char_nl + \
"  var_name = " + char_dq + var_name + char_dq + char_nl + \
"  var_rank = " + var_rank + char_nl + \
"  var_dim_names = " + var_dim_names_str + char_nl + \
"  var_dim_sizes = " + var_dim_sizes_str + char_nl + \
"  var_dim_sizes(var_rank-1) = var_dim_sizes(" + tostring(var_rank-1) + ") = " + x_dim_size + char_nl + \
"  var_dim_sizes(var_rank-2) = var_dim_sizes(" + tostring(var_rank-2) + ") = " + y_dim_size + char_nl + \
"Stopping."
    print("" + msg)
    exit
  end if
  end if
  end if
  end if
;
; **********************************************************************
;
; Return results as attributes of the logical variable var_info.
;
; **********************************************************************
;
  var_info := True

  var_info@fp = fp
  var_info@var_rank = var_rank
  var_info@var_dim_names = var_dim_names
  var_info@var_dim_sizes = var_dim_sizes
  var_info@func_xy_only = func_xy_only
  var_info@func_xyz_only = func_xyz_only
  var_info@func_xyt_only = func_xyt_only
  var_info@func_xyzt_only = func_xyzt_only
  var_info@average_in_x = average_in_x
  var_info@average_in_y = average_in_y

  return(var_info)

end

