#!/usr/bin/env python3

import unittest
import os
import glob

from python_utils import import_vars, set_env_var, print_input_args, \
                         print_info_msg, print_err_msg_exit, create_symlink_to_file, \
                         define_macos_utilities, check_var_valid_value, \
                         cd_vrfy, mkdir_vrfy, find_pattern_in_str

def link_fix(verbose, file_group):
    """ This file defines a function that ...
    Args:
        verbose: True or False
        file_group: could be on of ["grid", "orog", "sfc_climo"]
    Returns:
        a string: resolution
    """

    print_input_args(locals())

    valid_vals_file_group=["grid", "orog", "sfc_climo"]
    check_var_valid_value(file_group, valid_vals_file_group)

    #import all environement variables
    import_vars()

    #
    #-----------------------------------------------------------------------
    #
    # Create symlinks in the FIXLAM directory pointing to the grid files.
    # These symlinks are needed by the make_orog, make_sfc_climo, make_ic,
    # make_lbc, and/or run_fcst tasks.
    #
    # Note that we check that each target file exists before attempting to 
    # create symlinks.  This is because the "ln" command will create sym-
    # links to non-existent targets without returning with a nonzero exit
    # code.
    #
    #-----------------------------------------------------------------------
    #
    print_info_msg(f'Creating links in the FIXLAM directory to the grid files...',
        verbose=verbose)
    #
    #-----------------------------------------------------------------------
    #
    # Create globbing patterns for grid, orography, and surface climatology
    # files.
    #
    #
    # For grid files (i.e. file_group set to "grid"), symlinks are created
    # in the FIXLAM directory to files (of the same names) in the GRID_DIR.
    # These symlinks/files and the reason each is needed is listed below:
    #
    # 1) "C*.mosaic.halo${NHW}.nc"
    #    This mosaic file for the wide-halo grid (i.e. the grid with a ${NHW}-
    #    cell-wide halo) is needed as an input to the orography filtering 
    #    executable in the orography generation task.  The filtering code
    #    extracts from this mosaic file the name of the file containing the
    #    grid on which it will generate filtered topography.  Note that the
    #    orography generation and filtering are both performed on the wide-
    #    halo grid.  The filtered orography file on the wide-halo grid is then
    #    shaved down to obtain the filtered orography files with ${NH3}- and
    #    ${NH4}-cell-wide halos.
    #
    #    The raw orography generation step in the make_orog task requires the
    #    following symlinks/files:
    #
    #    a) C*.mosaic.halo${NHW}.nc
    #       The script for the make_orog task extracts the name of the grid
    #       file from this mosaic file; this name should be 
    #       "C*.grid.tile${TILE_RGNL}.halo${NHW}.nc".
    #
    #    b) C*.grid.tile${TILE_RGNL}.halo${NHW}.nc
    #       This is the 
    #       The script for the make_orog task passes the name of the grid 
    #       file (extracted above from the mosaic file) to the orography 
    #       generation executable.  The executable then
    #       reads in this grid file and generates a raw orography
    #       file on the grid.  The raw orography file is initially renamed "out.oro.nc",
    #       but for clarity, it is then renamed "C*.raw_orog.tile${TILE_RGNL}.halo${NHW}.nc".
    #
    #    c) The fixed files thirty.second.antarctic.new.bin, landcover30.fixed, 
    #       and gmted2010.30sec.int.
    #
    #    The orography filtering step in the make_orog task requires the 
    #    following symlinks/files:
    #
    #    a) C*.mosaic.halo${NHW}.nc
    #       This is the mosaic file for the wide-halo grid.  The orography
    #       filtering executable extracts from this file the name of the grid
    #       file containing the wide-halo grid (which should be 
    #       "${CRES}.grid.tile${TILE_RGNL}.halo${NHW}.nc").  The executable then
    #       looks for this grid file IN THE DIRECTORY IN WHICH IT IS RUNNING.
    #       Thus, before running the executable, the script creates a symlink in this run directory that
    #       points to the location of the actual wide-halo grid file.
    #
    #    b) C*.raw_orog.tile${TILE_RGNL}.halo${NHW}.nc
    #       This is the raw orography file on the wide-halo grid.  The script
    #       for the make_orog task copies this file to a new file named 
    #       "C*.filtered_orog.tile${TILE_RGNL}.halo${NHW}.nc" that will be
    #       used as input to the orography filtering executable.  The executable
    #       will then overwrite the contents of this file with the filtered orography.
    #       Thus, the output of the orography filtering executable will be
    #       the file C*.filtered_orog.tile${TILE_RGNL}.halo${NHW}.nc.
    #
    #    The shaving step in the make_orog task requires the following:
    #
    #    a) C*.filtered_orog.tile${TILE_RGNL}.halo${NHW}.nc
    #       This is the filtered orography file on the wide-halo grid.
    #       This gets shaved down to two different files:
    #
    #        i) ${CRES}.oro_data.tile${TILE_RGNL}.halo${NH0}.nc
    #           This is the filtered orography file on the halo-0 grid.
    #
    #       ii) ${CRES}.oro_data.tile${TILE_RGNL}.halo${NH4}.nc
    #           This is the filtered orography file on the halo-4 grid.
    #
    #       Note that the file names of the shaved files differ from that of
    #       the initial unshaved file on the wide-halo grid in that the field
    #       after ${CRES} is now "oro_data" (not "filtered_orog") to comply
    #       with the naming convention used more generally.
    #
    # 2) "C*.mosaic.halo${NH4}.nc"
    #    This mosaic file for the grid with a 4-cell-wide halo is needed as
    #    an input to the surface climatology generation executable.  The 
    #    surface climatology generation code reads from this file the number
    #    of tiles (which should be 1 for a regional grid) and the tile names.
    #    More importantly, using the ESMF function ESMF_GridCreateMosaic(),
    #    it creates a data object of type esmf_grid; the grid information
    #    in this object is obtained from the grid file specified in the mosaic
    #    file, which should be "C*.grid.tile${TILE_RGNL}.halo${NH4}.nc".  The
    #    dimensions specified in this grid file must match the ones specified
    #    in the (filtered) orography file "C*.oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
    #    that is also an input to the surface climatology generation executable.
    #    If they do not, then the executable will crash with an ESMF library
    #    error (something like "Arguments are incompatible").
    #
    #    Thus, for the make_sfc_climo task, the following symlinks/files must
    #    exist:
    #    a) "C*.mosaic.halo${NH4}.nc"
    #    b) "C*.grid.tile${TILE_RGNL}.halo${NH4}.nc"
    #    c) "C*.oro_data.tile${TILE_RGNL}.halo${NH4}.nc"
    #
    # 3) 
    #
    #
    #-----------------------------------------------------------------------
    #
    #
    if file_group == "grid":
        fns=[
        f"C*{DOT_OR_USCORE}mosaic.halo{NHW}.nc",
        f"C*{DOT_OR_USCORE}mosaic.halo{NH4}.nc",
        f"C*{DOT_OR_USCORE}mosaic.halo{NH3}.nc",
        f"C*{DOT_OR_USCORE}grid.tile{TILE_RGNL}.halo{NHW}.nc",
        f"C*{DOT_OR_USCORE}grid.tile{TILE_RGNL}.halo{NH3}.nc",
        f"C*{DOT_OR_USCORE}grid.tile{TILE_RGNL}.halo{NH4}.nc"
            ]
        fps=[ os.path.join(GRID_DIR,itm) for itm in fns]
        run_task=f"{RUN_TASK_MAKE_GRID}"
    #
    elif file_group == "orog":
        fns=[
        f"C*{DOT_OR_USCORE}oro_data.tile{TILE_RGNL}.halo{NH0}.nc",
        f"C*{DOT_OR_USCORE}oro_data.tile{TILE_RGNL}.halo{NH4}.nc"
            ]
        if CCPP_PHYS_SUITE == "FV3_HRRR":
          fns+=[
          f"C*{DOT_OR_USCORE}oro_data_ss.tile{TILE_RGNL}.halo{NH0}.nc",
          f"C*{DOT_OR_USCORE}oro_data_ls.tile{TILE_RGNL}.halo{NH0}.nc",
               ]
        fps=[ os.path.join(OROG_DIR,itm) for itm in fns]
        run_task=f"{RUN_TASK_MAKE_OROG}"
    #
    # The following list of symlinks (which have the same names as their
    # target files) need to be created made in order for the make_ics and
    # make_lbcs tasks (i.e. tasks involving chgres_cube) to work.
    #
    elif file_group == "sfc_climo":
        num_fields=len(SFC_CLIMO_FIELDS)
        fns=[None] * (2 * num_fields)
        for i in range(num_fields):
          ii=2*i
          fns[ii]=f"C*.{SFC_CLIMO_FIELDS[i]}.tile{TILE_RGNL}.halo{NH0}.nc"
          fns[ii+1]=f"C*.{SFC_CLIMO_FIELDS[i]}.tile{TILE_RGNL}.halo{NH4}.nc"
        fps=[ os.path.join(SFC_CLIMO_DIR,itm) for itm in fns]
        run_task=f"{RUN_TASK_MAKE_SFC_CLIMO}"
    #

    #
    #-----------------------------------------------------------------------
    #
    # Find all files matching the globbing patterns and make sure that they
    # all have the same resolution (an integer) in their names.
    #
    #-----------------------------------------------------------------------
    #
    i=0
    res_prev=""
    res=""
    fp_prev=""
    
    for pattern in fps:
      files = glob.glob(pattern)
      for fp in files:
    
        fn = os.path.basename(fp)
      
        regex_search = "^C([0-9]*).*"
        res = find_pattern_in_str(regex_search, fn)
        if res is None:
          print_err_msg_exit(f'''
                The resolution could not be extracted from the current file's name.  The
                full path to the file (fp) is:
                  fp = \"{fp}\"
                This may be because fp contains the * globbing character, which would
                imply that no files were found that match the globbing pattern specified
                in fp.''')
        else:
          res = res[0]
    
        if ( i > 0 ) and ( res != res_prev ):
          print_err_msg_exit(f'''
                The resolutions (as obtained from the file names) of the previous and 
                current file (fp_prev and fp, respectively) are different:
                  fp_prev = \"{fp_prev}\"
                  fp      = \"{fp}\"
                Please ensure that all files have the same resolution.''')
    
        i=i+1
        fp_prev=f"{fp}"
        res_prev=res
    #
    #-----------------------------------------------------------------------
    #
    # Replace the * globbing character in the set of globbing patterns with 
    # the resolution.  This will result in a set of (full paths to) specific
    # files.
    #
    #-----------------------------------------------------------------------
    #
    fps=[ itm.replace('*',res) for itm in fps]
    #
    #-----------------------------------------------------------------------
    #
    # In creating the various symlinks below, it is convenient to work in 
    # the FIXLAM directory.  We will change directory back to the original
    # later below.
    #
    #-----------------------------------------------------------------------
    #
    SAVE_DIR=os.getcwd()
    cd_vrfy(FIXLAM)
    #
    #-----------------------------------------------------------------------
    #
    # Use the set of full file paths generated above as the link targets to 
    # create symlinks to these files in the FIXLAM directory.
    #
    #-----------------------------------------------------------------------
    #
    # If the task in consideration (which will be one of the pre-processing
    # tasks MAKE_GRID_TN, MAKE_OROG_TN, and MAKE_SFC_CLIMO_TN) was run, then
    # the target files will be located under the experiment directory.  In
    # this case, we use relative symlinks in order the experiment directory
    # more portable and the symlinks more readable.  However, if the task
    # was not run, then pregenerated grid, orography, or surface climatology
    # files will be used, and those will be located in an arbitrary directory 
    # (specified by the user) that is somwehere outside the experiment 
    # directory.  Thus, in this case, there isn't really an advantage to using 
    # relative symlinks, so we use symlinks with absolute paths.
    #
    if run_task:
      relative_link_flag=True
    else:
      relative_link_flag=False
    
    for fp in fps:
      fn=os.path.basename(fp)
      create_symlink_to_file(fp,fn,relative_link_flag)
    #
    #-----------------------------------------------------------------------
    #
    # Set the C-resolution based on the resolution appearing in the file
    # names.
    #
    #-----------------------------------------------------------------------
    #
    cres=f"C{res}"
    #
    #-----------------------------------------------------------------------
    #
    # If considering grid files, create a symlink to the halo4 grid file
    # that does not contain the halo size in its name.  This is needed by
    # the tasks that generate the initial and lateral boundary condition
    # files.
    #
    #-----------------------------------------------------------------------
    #
    if file_group == "grid":
    
        target=f"{cres}{DOT_OR_USCORE}grid.tile{TILE_RGNL}.halo{NH4}.nc"
        symlink=f"{cres}{DOT_OR_USCORE}grid.tile{TILE_RGNL}.nc"
        create_symlink_to_file(target,symlink,True)
    #
    # The surface climatology file generation code looks for a grid file
    # having a name of the form "C${GFDLgrid_RES}_grid.tile7.halo4.nc" (i.e.
    # the C-resolution used in the name of this file is the number of grid 
    # points per horizontal direction per tile, just like in the global model).
    # Thus, if we are running the MAKE_SFC_CLIMO_TN task, if the grid is of 
    # GFDLgrid type, and if we are not using GFDLgrid_RES in filenames (i.e. 
    # we are using the equivalent global uniform grid resolution instead), 
    # then create a link whose name uses the GFDLgrid_RES that points to the 
    # link whose name uses the equivalent global uniform resolution.
    #
        if RUN_TASK_MAKE_SFC_CLIMO and \
           GRID_GEN_METHOD == "GFDLgrid" and \
           not GFDLgrid_USE_GFDLgrid_RES_IN_FILENAMES:
          target=f"{cres}{DOT_OR_USCORE}grid.tile{TILE_RGNL}.halo{NH4}.nc"
          symlink=f"C{GFDLgrid_RES}{DOT_OR_USCORE}grid.tile{TILE_RGNL}.nc"
          create_symlink_to_file(target,symlink,relative)
    #
    #-----------------------------------------------------------------------
    #
    # If considering surface climatology files, create symlinks to the surface 
    # climatology files that do not contain the halo size in their names.  
    # These are needed by the task that generates the initial condition files.
    #
    #-----------------------------------------------------------------------
    #
    if file_group == "sfc_climo":
    
        tmp=[ f"{cres}.{itm}" for itm in SFC_CLIMO_FIELDS]
        fns_sfc_climo_with_halo_in_fn=[ f"{itm}.tile{TILE_RGNL}.halo{NH4}.nc" for itm in tmp]
        fns_sfc_climo_no_halo_in_fn=[ f"{itm}.tile{TILE_RGNL}.nc" for itm in tmp]
    
        for i in range(num_fields):
          target=f"{fns_sfc_climo_with_halo_in_fn[i]}"
          symlink=f"{fns_sfc_climo_no_halo_in_fn[i]}"
          create_symlink_to_file(target, symlink, True)
    #
    # In order to be able to specify the surface climatology file names in
    # the forecast model's namelist file, in the FIXLAM directory a symlink
    # must be created for each surface climatology field that has "tile1" in
    # its name (and no "halo") and which points to the corresponding "tile7.halo0"
    # file.
    #
        tmp=[ f"{cres}.{itm}" for itm in SFC_CLIMO_FIELDS ]
        fns_sfc_climo_tile7_halo0_in_fn=[ f"{itm}.tile{TILE_RGNL}.halo{NH0}.nc" for itm in tmp ]
        fns_sfc_climo_tile1_no_halo_in_fn=[ f"{itm}.tile1.nc" for itm in tmp ]
    
        for i in range(num_fields):
          target=f"{fns_sfc_climo_tile7_halo0_in_fn[i]}"
          symlink=f"{fns_sfc_climo_tile1_no_halo_in_fn[i]}"
          create_symlink_to_file(target,symlink,True)
    #
    #-----------------------------------------------------------------------
    #
    # Change directory back to original one.
    #
    #-----------------------------------------------------------------------
    #
    cd_vrfy(SAVE_DIR)

    return res
   
class Testing(unittest.TestCase):
    def test_link_fix(self):
        res = link_fix(verbose=True, file_group="grid")
        self.assertTrue( res == "3357")
    def setUp(self):
        define_macos_utilities()
        TEST_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "test_data");
        FIXLAM = os.path.join(TEST_DIR, "expt", "fix_lam")
        mkdir_vrfy("-p",FIXLAM)
        set_env_var("FIXLAM",FIXLAM)
        set_env_var("DOT_OR_USCORE","_")
        set_env_var("TILE_RGNL",7)
        set_env_var("NH0",0)
        set_env_var("NHW",6)
        set_env_var("NH4",4)
        set_env_var("NH3",3)
        set_env_var("GRID_DIR",TEST_DIR + os.sep + "RRFS_CONUS_3km")
        set_env_var("RUN_TASK_MAKE_GRID","FALSE")
        set_env_var("OROG_DIR",TEST_DIR + os.sep + "RRFS_CONUS_3km")
        set_env_var("RUN_TASK_MAKE_OROG","FALSE")
        set_env_var("SFC_CLIMO_DIR",TEST_DIR + os.sep + "RRFS_CONUS_3km")
        set_env_var("RUN_TASK_MAKE_SFC_CLIMO","FALSE")
        set_env_var("CCPP_PHYS_SUITE","FV3_GSD_SAR")
