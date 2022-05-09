#!/usr/bin/env python3

import os
import sys
import datetime
from textwrap import dedent

from python_utils import cd_vrfy, mkdir_vrfy, rm_vrfy, check_var_valid_value,\
                         lowercase,uppercase,check_for_preexist_dir_file,\
                         list_to_str, type_to_str, \
                         import_vars, export_vars, get_env_var, print_info_msg,\
                         print_err_msg_exit, load_config_file, cfg_to_shell_str,\
                         load_shell_config, load_ini_config, get_ini_value

from set_cycle_dates import set_cycle_dates
from set_predef_grid_params import set_predef_grid_params
from set_ozone_param import set_ozone_param
from set_extrn_mdl_params import set_extrn_mdl_params
from set_gridparams_ESGgrid import set_gridparams_ESGgrid
from set_gridparams_GFDLgrid import set_gridparams_GFDLgrid
from link_fix import link_fix
from check_ruc_lsm import check_ruc_lsm
from set_thompson_mp_fix_files import set_thompson_mp_fix_files

def setup():
    """ Function that sets a secondary set
    of parameters needed by the various scripts that are called by the 
    FV3-LAM rocoto community workflow.  This secondary set of parameters is 
    calculated using the primary set of user-defined parameters in the de-
    fault and custom experiment/workflow configuration scripts (whose file
    names are defined below).  This script then saves both sets of parame-
    ters in a global variable definitions file (really a bash script) in 
    the experiment directory.  This file then gets sourced by the various 
    scripts called by the tasks in the workflow.

    Args:
      None
    Returns:
      None
    """

    ushdir=os.path.dirname(os.path.abspath(__file__))
    cd_vrfy(ushdir)

    # import all environment variables
    import_vars()

    # print message
    print_info_msg(f'''
        ========================================================================
        Starting function setup() in \"{os.path.basename(__file__)}\"...
        ========================================================================''')
    #
    #-----------------------------------------------------------------------
    #
    # Set the name of the configuration file containing default values for
    # the experiment/workflow variables.  Then source the file.
    #
    #-----------------------------------------------------------------------
    #
    EXPT_DEFAULT_CONFIG_FN="config_defaults.yaml"
    cfg_d = load_config_file(EXPT_DEFAULT_CONFIG_FN)
    import_vars(dictionary=cfg_d)
    #
    #-----------------------------------------------------------------------
    #
    # If a user-specified configuration file exists, source it.  This file
    # contains user-specified values for a subset of the experiment/workflow 
    # variables that override their default values.  Note that the user-
    # specified configuration file is not tracked by the repository, whereas
    # the default configuration file is tracked.
    #
    #-----------------------------------------------------------------------
    #
    if os.path.exists(EXPT_CONFIG_FN):
    #
    # We require that the variables being set in the user-specified configu-
    # ration file have counterparts in the default configuration file.  This
    # is so that we do not introduce new variables in the user-specified 
    # configuration file without also officially introducing them in the de-
    # fault configuration file.  Thus, before sourcing the user-specified 
    # configuration file, we check that all variables in the user-specified
    # configuration file are also assigned default values in the default 
    # configuration file.
    #
      cfg_u = load_config_file(os.path.join(ushdir,EXPT_CONFIG_FN))
      cfg_d.update(cfg_u)
      if cfg_u.items() > cfg_d.items():
        print_err_msg_exit(f'''
            User specified config file {EXPT_CONGIG_FN} has variables that are
            not defined in the default configuration file {EXPT_DEFAULT_CONFIG_FN}''')
      import_vars(dictionary=cfg_u)

    #
    #-----------------------------------------------------------------------
    #
    # If PREDEF_GRID_NAME is set to a non-empty string, set or reset parameters
    # according to the predefined domain specified.
    #
    #-----------------------------------------------------------------------
    #

    # export env vars before calling another module 
    export_vars()

    if PREDEF_GRID_NAME:
      set_predef_grid_params()

    import_vars()

    #
    #-----------------------------------------------------------------------
    #
    # Make sure different variables are set to their corresponding valid value
    #
    #-----------------------------------------------------------------------
    #
    global VERBOSE
    if DEBUG and not VERBOSE:
        print_info_msg('''
            Resetting VERBOSE to \"TRUE\" because DEBUG has been set to \"TRUE\"...''')
        VERBOSE=False

    #
    #-----------------------------------------------------------------------
    #
    # Set magnitude of stochastic ad-hoc schemes to -999.0 if they are not
    # being used. This is required at the moment, since "do_shum/sppt/skeb"
    # does not override the use of the scheme unless the magnitude is also
    # specifically set to -999.0.  If all "do_shum/sppt/skeb" are set to
    # "false," then none will run, regardless of the magnitude values. 
    #
    #-----------------------------------------------------------------------
    #
    global SHUM_MAG, SKEB_MAG, SPPT_MAG
    if not DO_SHUM:
        SHUM_MAG=-999.0
    if not DO_SKEB:
        SKEB_MAG=-999.0
    if not DO_SPPT:
        SPPT_MAG=-999.0
    #
    #-----------------------------------------------------------------------
    #
    # If running with SPP in MYNN PBL, MYNN SFC, GSL GWD, Thompson MP, or 
    # RRTMG, count the number of entries in SPP_VAR_LIST to correctly set 
    # N_VAR_SPP, otherwise set it to zero. 
    #
    #-----------------------------------------------------------------------
    #
    global N_VAR_SPP
    N_VAR_SPP=0
    if DO_SPP:
      N_VAR_SPP = len(SPP_VAR_LIST)
    #
    #-----------------------------------------------------------------------
    #
    # If running with Noah or RUC-LSM SPP, count the number of entries in 
    # LSM_SPP_VAR_LIST to correctly set N_VAR_LNDP, otherwise set it to zero.
    # Also set LNDP_TYPE to 2 for LSM SPP, otherwise set it to zero.  Finally,
    # initialize an "FHCYC_LSM_SPP" variable to 0 and set it to 999 if LSM SPP
    # is turned on.  This requirement is necessary since LSM SPP cannot run with 
    # FHCYC=0 at the moment, but FHCYC cannot be set to anything less than the
    # length of the forecast either.  A bug fix will be submitted to 
    # ufs-weather-model soon, at which point, this requirement can be removed
    # from regional_workflow. 
    #
    #-----------------------------------------------------------------------
    #
    global N_VAR_LNDP, LNDP_TYPE, FHCYC_LSM_SPP_OR_NOT
    N_VAR_LNDP=0
    LNDP_TYPE=0
    FHCYC_LSM_SPP_OR_NOT=0
    if DO_LSM_SPP:
      N_VAR_LNDP=len(LSM_SPP_VAR_LIST)
      LNDP_TYPE=2
      FHCYC_LSM_SPP_OR_NOT=999
    #
    #-----------------------------------------------------------------------
    #
    # If running with SPP, confirm that each SPP-related namelist value 
    # contains the same number of entries as N_VAR_SPP (set above to be equal
    # to the number of entries in SPP_VAR_LIST).
    #
    #-----------------------------------------------------------------------
    #
    if DO_SPP:
      if ( len(SPP_MAG_LIST) != N_VAR_SPP ) or \
         ( len(SPP_LSCALE) != N_VAR_SPP) or \
         ( len(SPP_TSCALE) != N_VAR_SPP) or \
         ( len(SPP_SIGTOP1) != N_VAR_SPP) or \
         ( len(SPP_SIGTOP2) != N_VAR_SPP) or \
         ( len(SPP_STDDEV_CUTOFF) != N_VAR_SPP) or \
         ( len(ISEED_SPP) != N_VAR_SPP):
        print_err_msg_exit(f'''
            All MYNN PBL, MYNN SFC, GSL GWD, Thompson MP, or RRTMG SPP-related namelist 
            variables set in {CONFIG_FN} must be equal in number of entries to what is 
            found in SPP_VAR_LIST:
              Number of entries in SPP_VAR_LIST = \"{len(SPP_VAR_LIST)}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # If running with LSM SPP, confirm that each LSM SPP-related namelist
    # value contains the same number of entries as N_VAR_LNDP (set above to
    # be equal to the number of entries in LSM_SPP_VAR_LIST).
    #
    #-----------------------------------------------------------------------
    #
    if DO_LSM_SPP:
      if ( len(LSM_SPP_MAG_LIST) != N_VAR_LNDP) or \
         ( len(LSM_SPP_LSCALE) != N_VAR_LNDP) or \
         ( len(LSM_SPP_TSCALE) != N_VAR_LNDP):
        print_err_msg_exit(f'''
            All Noah or RUC-LSM SPP-related namelist variables (except ISEED_LSM_SPP) 
            set in {CONFIG_FN} must be equal in number of entries to what is found in 
            SPP_VAR_LIST:
              Number of entries in SPP_VAR_LIST = \"{len(LSM_SPP_VAR_LIST)}\"''')
    #
    # The current script should be located in the ush subdirectory of the 
    # workflow directory.  Thus, the workflow directory is the one above the
    # directory of the current script.
    #
    SR_WX_APP_TOP_DIR=os.path.abspath( os.path.dirname(__file__) + \
                      os.sep + os.pardir + os.sep + os.pardir)
    
    #
    #-----------------------------------------------------------------------
    #
    # Set the base directories in which codes obtained from external reposi-
    # tories (using the manage_externals tool) are placed.  Obtain the rela-
    # tive paths to these directories by reading them in from the manage_ex-
    # ternals configuration file.  (Note that these are relative to the lo-
    # cation of the configuration file.)  Then form the full paths to these
    # directories.  Finally, make sure that each of these directories actu-
    # ally exists.
    #
    #-----------------------------------------------------------------------
    #
    mng_extrns_cfg_fn = os.path.join(SR_WX_APP_TOP_DIR, "Externals.cfg")
    try:
      mng_extrns_cfg_fn = os.readlink(mng_extrns_cfg_fn)
    except:
      pass
    property_name="local_path"
    cfg = load_ini_config(mng_extrns_cfg_fn)
    #
    # Get the path to the workflow scripts
    #
    external_name="regional_workflow"
    HOMErrfs = get_ini_value(cfg, external_name, property_name)

    if not HOMErrfs:
        print_err_msg_exit(f'''
            Externals.cfg does not contain "{external_name}".''')

    HOMErrfs = os.path.join(SR_WX_APP_TOP_DIR, HOMErrfs)
    #
    # Get the base directory of the FV3 forecast model code.
    #
    external_name=FCST_MODEL
    UFS_WTHR_MDL_DIR = get_ini_value(cfg, external_name,property_name)

    if not UFS_WTHR_MDL_DIR:
        print_err_msg_exit(f'''
            Externals.cfg does not contain "{external_name}".''')

    UFS_WTHR_MDL_DIR=os.path.join(SR_WX_APP_TOP_DIR, UFS_WTHR_MDL_DIR)
    if not os.path.exists(UFS_WTHR_MDL_DIR):
        print_err_msg_exit(f'''
            The base directory in which the FV3 source code should be located
            (UFS_WTHR_MDL_DIR) does not exist:
              UFS_WTHR_MDL_DIR = \"{UFS_WTHR_MDL_DIR}\"
            Please clone the external repository containing the code in this directory,
            build the executable, and then rerun the workflow.''')
    #
    # Get the base directory of the UFS_UTILS codes.
    #
    external_name="ufs_utils"
    UFS_UTILS_DIR=get_ini_value(cfg, external_name, property_name)

    if not UFS_UTILS_DIR:
        print_err_msg_exit(f'''
            Externals.cfg does not contain "{external_name}".''')
    
    UFS_UTILS_DIR=os.path.join(SR_WX_APP_TOP_DIR, UFS_UTILS_DIR)
    if not os.path.exists(UFS_UTILS_DIR):
        print_err_msg_exit(f'''
            The base directory in which the UFS utilities source codes should be lo-
            cated (UFS_UTILS_DIR) does not exist:
              UFS_UTILS_DIR = \"{UFS_UTILS_DIR}\"
            Please clone the external repository containing the code in this direct-
            ory, build the executables, and then rerun the workflow.''')
    #
    # Get the base directory of the UPP code.
    #
    external_name="UPP"
    UPP_DIR=get_ini_value(cfg,external_name,property_name )
    if not UPP_DIR:
        print_err_msg_exit(f'''
            Externals.cfg does not contain "{external_name}".''')
    
    UPP_DIR=os.path.join(SR_WX_APP_TOP_DIR, UPP_DIR)
    if not os.path.exists(UPP_DIR):
        print_err_msg_exit(f'''
            The base directory in which the UPP source code should be located
            (UPP_DIR) does not exist:
              UPP_DIR = \"{UPP_DIR}\"
            Please clone the external repository containing the code in this directory,
            build the executable, and then rerun the workflow.''')

    #
    # Define some other useful paths
    #
    global USHDIR, SCRIPTSDIR, JOBSDIR,SORCDIR, SRC_DIR, PARMDIR, MODULES_DIR, EXECDIR, TEMPLATE_DIR, \
           VX_CONFIG_DIR, METPLUS_CONF, MET_CONFIG

    USHDIR = os.path.join(HOMErrfs,"ush")
    SCRIPTSDIR = os.path.join(HOMErrfs,"scripts")
    JOBSDIR = os.path.join(HOMErrfs,"jobs")
    SORCDIR = os.path.join(HOMErrfs,"sorc")
    SRC_DIR = os.path.join(SR_WX_APP_TOP_DIR,"src")
    PARMDIR = os.path.join(HOMErrfs,"parm")
    MODULES_DIR = os.path.join(HOMErrfs,"modulefiles")
    EXECDIR = os.path.join(SR_WX_APP_TOP_DIR,"bin")
    TEMPLATE_DIR = os.path.join(USHDIR,"templates")
    VX_CONFIG_DIR = os.path.join(TEMPLATE_DIR,"parm")
    METPLUS_CONF = os.path.join(TEMPLATE_DIR,"parm","metplus")
    MET_CONFIG = os.path.join(TEMPLATE_DIR,"parm","met")
    
    #
    #-----------------------------------------------------------------------
    #
    # Source the machine config file containing architechture information,
    # queue names, and supported input file paths.
    #
    #-----------------------------------------------------------------------
    #
    global MACHINE
    global MACHINE_FILE
    global FIXgsm, FIXaer, FIXlut, TOPO_DIR, SFC_CLIMO_INPUT_DIR, DOMAIN_PREGEN_BASEDIR, \
           RELATIVE_LINK_FLAG, WORKFLOW_MANAGER, NCORES_PER_NODE, SCHED, \
           QUEUE_DEFAULT, QUEUE_HPSS, QUEUE_FCST, \
           PARTITION_DEFAULT, PARTITION_HPSS, PARTITION_FCST

    MACHINE = uppercase(MACHINE)
    RELATIVE_LINK_FLAG="--relative"
    MACHINE_FILE=MACHINE_FILE or os.path.join(USHDIR,"machine",f"{lowercase(MACHINE)}.sh")
    machine_cfg = load_shell_config(MACHINE_FILE)
    import_vars(dictionary=machine_cfg)
    
    if not NCORES_PER_NODE:
      print_err_msg_exit(f"""
        NCORES_PER_NODE has not been specified in the file {MACHINE_FILE}
        Please ensure this value has been set for your desired platform. """)
    
    if not (FIXgsm and FIXaer and FIXlut and TOPO_DIR and SFC_CLIMO_INPUT_DIR):
      print_err_msg_exit(f'''
        One or more fix file directories have not been specified for this machine:
          MACHINE = \"{MACHINE}\"
          FIXgsm = \"{FIXgsm or ""}
          FIXaer = \"{FIXaer or ""}
          FIXlut = \"{FIXlut or ""}
          TOPO_DIR = \"{TOPO_DIR or ""}
          SFC_CLIMO_INPUT_DIR = \"{SFC_CLIMO_INPUT_DIR or ""}
          DOMAIN_PREGEN_BASEDIR = \"{DOMAIN_PREGEN_BASEDIR or ""}
        You can specify the missing location(s) in config.sh''')

    #
    #-----------------------------------------------------------------------
    #
    # Set the names of the build and workflow module files (if not 
    # already specified by the user).  These are the files that need to be 
    # sourced before building the component SRW App codes and running various 
    # workflow scripts, respectively.
    #
    #-----------------------------------------------------------------------
    #
    global WFLOW_MOD_FN, BUILD_MOD_FN
    machine=lowercase(MACHINE)
    WFLOW_MOD_FN=WFLOW_MOD_FN or f"wflow_{machine}"
    BUILD_MOD_FN=BUILD_MOD_FN or f"build_{machine}_{COMPILER}"
    #
    #-----------------------------------------------------------------------
    #
    # Calculate a default value for the number of processes per node for the
    # RUN_FCST_TN task.  Then set PPN_RUN_FCST to this default value if 
    # PPN_RUN_FCST is not already specified by the user.
    #
    #-----------------------------------------------------------------------
    #
    global PPN_RUN_FCST
    ppn_run_fcst_default = NCORES_PER_NODE // OMP_NUM_THREADS_RUN_FCST
    PPN_RUN_FCST=PPN_RUN_FCST or ppn_run_fcst_default
    #
    #-----------------------------------------------------------------------
    #
    # If we are using a workflow manager check that the ACCOUNT variable is
    # not empty.
    #
    #-----------------------------------------------------------------------
    #
    if WORKFLOW_MANAGER != "none":
        if not ACCOUNT:
            print_err_msg_exit(f'''
                The variable ACCOUNT cannot be empty if you are using a workflow manager:
                  ACCOUNT = \"ACCOUNT\"
                  WORKFLOW_MANAGER = \"WORKFLOW_MANAGER\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Set the grid type (GTYPE).  In general, in the FV3 code, this can take
    # on one of the following values: "global", "stretch", "nest", and "re-
    # gional".  The first three values are for various configurations of a
    # global grid, while the last one is for a regional grid.  Since here we
    # are only interested in a regional grid, GTYPE must be set to "region-
    # al".
    #
    #-----------------------------------------------------------------------
    #
    global TILE_RGNL, GTYPE
    GTYPE="regional"
    TILE_RGNL="7"

    #-----------------------------------------------------------------------
    #
    # Set USE_MERRA_CLIMO to either "TRUE" or "FALSE" so we don't
    # have to consider other valid values later on.
    #
    #-----------------------------------------------------------------------
    global USE_MERRA_CLIMO
    if CCPP_PHYS_SUITE == "FV3_GFS_v15_thompson_mynn_lam3km":
      USE_MERRA_CLIMO=True
    #
    #-----------------------------------------------------------------------
    #
    # Set CPL to TRUE/FALSE based on FCST_MODEL.
    #
    #-----------------------------------------------------------------------
    #
    global CPL
    if FCST_MODEL == "ufs-weather-model":
      CPL=False
    elif FCST_MODEL == "fv3gfs_aqm":
      CPL=True
    else:
      print_err_msg_exit(f'''
        The coupling flag CPL has not been specified for this value of FCST_MODEL:
          FCST_MODEL = \"{FCST_MODEL}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Make sure RESTART_INTERVAL is set to an integer value if present
    #
    #-----------------------------------------------------------------------
    #
    if not isinstance(RESTART_INTERVAL,int):
      print_err_msg_exit(f'''
        RESTART_INTERVAL must be set to an integer number of hours.
          RESTART_INTERVAL = \"{RESTART_INTERVAL}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Check that DATE_FIRST_CYCL and DATE_LAST_CYCL are strings consisting 
    # of exactly 8 digits.
    #
    #-----------------------------------------------------------------------
    #
    if not isinstance(DATE_FIRST_CYCL,datetime.date):
      print_err_msg_exit(f'''
        DATE_FIRST_CYCL must be a string consisting of exactly 8 digits of the 
        form \"YYYYMMDD\", where YYYY is the 4-digit year, MM is the 2-digit 
        month, and DD is the 2-digit day-of-month.
          DATE_FIRST_CYCL = \"{DATE_FIRST_CYCL}\"''')
    
    if not isinstance(DATE_LAST_CYCL,datetime.date):
      print_err_msg_exit(f'''
        DATE_LAST_CYCL must be a string consisting of exactly 8 digits of the 
        form \"YYYYMMDD\", where YYYY is the 4-digit year, MM is the 2-digit 
        month, and DD is the 2-digit day-of-month.
          DATE_LAST_CYCL = \"{DATE_LAST_CYCL}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Check that all elements of CYCL_HRS are strings consisting of exactly
    # 2 digits that are between "00" and "23", inclusive.
    #
    #-----------------------------------------------------------------------
    #
    i=0
    for CYCL in CYCL_HRS:
      if CYCL < 0 or CYCL > 23:
        print_err_msg_exit(f'''
            Each element of CYCL_HRS must be an integer between \"00\" and \"23\", in-
            clusive (including a leading \"0\", if necessary), specifying an hour-of-
            day.  Element #{i} of CYCL_HRS (where the index of the first element is 0) 
            does not have this form:
              CYCL_HRS = {CYCL_HRS}
              CYCL_HRS[{i}] = \"{CYCL_HRS[i]}\"''')
    
      i=i+1
    #
    #-----------------------------------------------------------------------
    # Check cycle increment for cycle frequency (cycl_freq).
    # only if INCR_CYCL_FREQ < 24.
    #-----------------------------------------------------------------------
    #
    if INCR_CYCL_FREQ < 24 and i > 1:
      cycl_intv=(24//i)
      if cycl_intv != INCR_CYCL_FREQ:
        print_err_msg_exit(f'''
            The number of CYCL_HRS does not match with that expected by INCR_CYCL_FREQ:
              INCR_CYCL_FREQ = {INCR_CYCL_FREQ}
              cycle interval by the number of CYCL_HRS = {cycl_intv}
              CYCL_HRS = {CYCL_HRS} ''')
    
      for itmp in range(1,i):
        itm1=itmp-1
        cycl_next_itmp=CYCL_HRS[itm1] + INCR_CYCL_FREQ
        if cycl_next_itmp != CYCL_HRS[itmp]:
          print_err_msg_exit(f'''
            Element {itmp} of CYCL_HRS does not match with the increment of cycle
            frequency INCR_CYCL_FREQ:
              CYCL_HRS = {CYCL_HRS}
              INCR_CYCL_FREQ = {INCR_CYCL_FREQ}
              CYCL_HRS[{itmp}] = \"{CYCL_HRS[itmp]}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Call a function to generate the array ALL_CDATES containing the cycle 
    # dates/hours for which to run forecasts.  The elements of this array
    # will have the form YYYYMMDDHH.  They are the starting dates/times of 
    # the forecasts that will be run in the experiment.  Then set NUM_CYCLES
    # to the number of elements in this array.
    #
    #-----------------------------------------------------------------------
    #

    ALL_CDATES = set_cycle_dates( \
      date_start=DATE_FIRST_CYCL,
      date_end=DATE_LAST_CYCL,
      cycle_hrs=CYCL_HRS,
      incr_cycl_freq=INCR_CYCL_FREQ)
    
    NUM_CYCLES=len(ALL_CDATES)
    
    if NUM_CYCLES > 90:
      ALL_CDATES=None
      print_info_msg(f'''
        Too many cycles in ALL_CDATES to list, redefining in abbreviated form."
        ALL_CDATES="{DATE_FIRST_CYCL}{CYCL_HRS[0]}...{DATE_LAST_CYCL}{CYCL_HRS[-1]}''')
    #
    #-----------------------------------------------------------------------
    #
    # If using a custom post configuration file, make sure that it exists.
    #
    #-----------------------------------------------------------------------
    #
    if USE_CUSTOM_POST_CONFIG_FILE:
      if not os.path.exists(CUSTOM_POST_CONFIG_FP):
        print_err_msg_exit(f'''
            The custom post configuration specified by CUSTOM_POST_CONFIG_FP does not 
            exist:
              CUSTOM_POST_CONFIG_FP = \"{CUSTOM_POST_CONFIG_FP}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # If using external CRTM fix files to allow post-processing of synthetic
    # satellite products from the UPP, then make sure the fix file directory
    # exists.
    #
    #-----------------------------------------------------------------------
    #
    if USE_CRTM:
      if not os.path.exists(CRTM_DIR):
        print_err_msg_exit(f'''
            The external CRTM fix file directory specified by CRTM_DIR does not exist:
                CRTM_DIR = \"{CRTM_DIR}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # The forecast length (in integer hours) cannot contain more than 3 cha-
    # racters.  Thus, its maximum value is 999.  Check whether the specified
    # forecast length exceeds this maximum value.  If so, print out a warn-
    # ing and exit this script.
    #
    #-----------------------------------------------------------------------
    #
    fcst_len_hrs_max=999
    if FCST_LEN_HRS > fcst_len_hrs_max:
      print_err_msg_exit(f'''
        Forecast length is greater than maximum allowed length:
          FCST_LEN_HRS = {FCST_LEN_HRS}
          fcst_len_hrs_max = {fcst_len_hrs_max}''')
    #
    #-----------------------------------------------------------------------
    #
    # Check whether the forecast length (FCST_LEN_HRS) is evenly divisible
    # by the BC update interval (LBC_SPEC_INTVL_HRS).  If not, print out a
    # warning and exit this script.  If so, generate an array of forecast
    # hours at which the boundary values will be updated.
    #
    #-----------------------------------------------------------------------
    #
    rem=FCST_LEN_HRS%LBC_SPEC_INTVL_HRS
    
    if rem != 0:
      print_err_msg_exit(f'''
        The forecast length (FCST_LEN_HRS) is not evenly divisible by the lateral
        boundary conditions update interval (LBC_SPEC_INTVL_HRS):
          FCST_LEN_HRS = {FCST_LEN_HRS}
          LBC_SPEC_INTVL_HRS = {LBC_SPEC_INTVL_HRS}
          rem = FCST_LEN_HRS%%LBC_SPEC_INTVL_HRS = {rem}''')
    #
    #-----------------------------------------------------------------------
    #
    # Set the array containing the forecast hours at which the lateral 
    # boundary conditions (LBCs) need to be updated.  Note that this array
    # does not include the 0-th hour (initial time).
    #
    #-----------------------------------------------------------------------
    #
    LBC_SPEC_FCST_HRS=[ i for i in range(LBC_SPEC_INTVL_HRS, \
                            LBC_SPEC_INTVL_HRS + FCST_LEN_HRS, \
                            LBC_SPEC_INTVL_HRS ) ]
    #
    #-----------------------------------------------------------------------
    #
    # Check to make sure that various computational parameters needed by the 
    # forecast model are set to non-empty values.  At this point in the 
    # experiment generation, all of these should be set to valid (non-empty) 
    # values.
    #
    #-----------------------------------------------------------------------
    #
    if not DT_ATMOS:
      print_err_msg_exit(f'''
        The forecast model main time step (DT_ATMOS) is set to a null string:
          DT_ATMOS = {DT_ATMOS}
        Please set this to a valid numerical value in the user-specified experiment
        configuration file (EXPT_CONFIG_FP) and rerun:
          EXPT_CONFIG_FP = \"{EXPT_CONFIG_FP}\"''')
    
    if not LAYOUT_X:
      print_err_msg_exit(f'''
        The number of MPI processes to be used in the x direction (LAYOUT_X) by 
        the forecast job is set to a null string:
          LAYOUT_X = {LAYOUT_X}
        Please set this to a valid numerical value in the user-specified experiment
        configuration file (EXPT_CONFIG_FP) and rerun:
          EXPT_CONFIG_FP = \"{EXPT_CONFIG_FP}\"''')
    
    if not LAYOUT_Y:
      print_err_msg_exit(f'''
        The number of MPI processes to be used in the y direction (LAYOUT_Y) by 
        the forecast job is set to a null string:
          LAYOUT_Y = {LAYOUT_Y}
        Please set this to a valid numerical value in the user-specified experiment
        configuration file (EXPT_CONFIG_FP) and rerun:
          EXPT_CONFIG_FP = \"{EXPT_CONFIG_FP}\"''')
    
    if not BLOCKSIZE:
      print_err_msg_exit(f'''
        The cache size to use for each MPI task of the forecast (BLOCKSIZE) is 
        set to a null string:
          BLOCKSIZE = {BLOCKSIZE}
        Please set this to a valid numerical value in the user-specified experiment
        configuration file (EXPT_CONFIG_FP) and rerun:
          EXPT_CONFIG_FP = \"{EXPT_CONFIG_FP}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # If performing sub-hourly model output and post-processing, check that
    # the output interval DT_SUBHOURLY_POST_MNTS (in minutes) is specified
    # correctly.
    #
    #-----------------------------------------------------------------------
    #
    global SUB_HOURLY_POST

    if SUB_HOURLY_POST:
    #
    # Check that DT_SUBHOURLY_POST_MNTS is between 0 and 59, inclusive.
    #
      if DT_SUBHOURLY_POST_MNTS < 0 or DT_SUBHOURLY_POST_MNTS > 59:
        print_err_msg_exit(f'''
            When performing sub-hourly post (i.e. SUB_HOURLY_POST set to \"TRUE\"), 
            DT_SUBHOURLY_POST_MNTS must be set to an integer between 0 and 59, 
            inclusive but in this case is not:
              SUB_HOURLY_POST = \"{SUB_HOURLY_POST}\"
              DT_SUBHOURLY_POST_MNTS = \"{DT_SUBHOURLY_POST_MNTS}\"''')
    #
    # Check that DT_SUBHOURLY_POST_MNTS (after converting to seconds) is 
    # evenly divisible by the forecast model's main time step DT_ATMOS.
    #
      rem=( DT_SUBHOURLY_POST_MNTS*60 % DT_ATMOS )
      if rem != 0:
        print_err_msg_exit(f'''
            When performing sub-hourly post (i.e. SUB_HOURLY_POST set to \"TRUE\"), 
            the time interval specified by DT_SUBHOURLY_POST_MNTS (after converting 
            to seconds) must be evenly divisible by the time step DT_ATMOS used in 
            the forecast model, i.e. the remainder (rem) must be zero.  In this case, 
            it is not:
              SUB_HOURLY_POST = \"{SUB_HOURLY_POST}\"
              DT_SUBHOURLY_POST_MNTS = \"{DT_SUBHOURLY_POST_MNTS}\"
              DT_ATMOS = \"{DT_ATMOS}\"
              rem = (DT_SUBHOURLY_POST_MNTS*60) %% DT_ATMOS = {rem}
            Please reset DT_SUBHOURLY_POST_MNTS and/or DT_ATMOS so that this remainder 
            is zero.''')
    #
    # If DT_SUBHOURLY_POST_MNTS is set to 0 (with SUB_HOURLY_POST set to 
    # True), then we're not really performing subhourly post-processing.
    # In this case, reset SUB_HOURLY_POST to False and print out an 
    # informational message that such a change was made.
    #
      if DT_SUBHOURLY_POST_MNTS == 0:
        print_info_msg(f'''
            When performing sub-hourly post (i.e. SUB_HOURLY_POST set to \"TRUE\"), 
            DT_SUBHOURLY_POST_MNTS must be set to a value greater than 0; otherwise,
            sub-hourly output is not really being performed:
              SUB_HOURLY_POST = \"{SUB_HOURLY_POST}\"
              DT_SUBHOURLY_POST_MNTS = \"{DT_SUBHOURLY_POST_MNTS}\"
            Resetting SUB_HOURLY_POST to \"FALSE\".  If you do not want this, you 
            must set DT_SUBHOURLY_POST_MNTS to something other than zero.''')
        SUB_HOURLY_POST=False
    #
    #-----------------------------------------------------------------------
    #
    # If the base directory (EXPT_BASEDIR) in which the experiment subdirectory 
    # (EXPT_SUBDIR) will be located does not start with a "/", then it is 
    # either set to a null string or contains a relative directory.  In both 
    # cases, prepend to it the absolute path of the default directory under 
    # which the experiment directories are placed.  If EXPT_BASEDIR was set 
    # to a null string, it will get reset to this default experiment directory, 
    # and if it was set to a relative directory, it will get reset to an 
    # absolute directory that points to the relative directory under the 
    # default experiment directory.  Then create EXPT_BASEDIR if it doesn't 
    # already exist.
    #
    #-----------------------------------------------------------------------
    #
    global EXPT_BASEDIR
    if (not EXPT_BASEDIR) or (EXPT_BASEDIR[0] != "/"):
      if not EXPT_BASEDIR:
        EXPT_BASEDIR = ""
      EXPT_BASEDIR = os.path.join(SR_WX_APP_TOP_DIR,"..","expt_dirs",EXPT_BASEDIR)
    try:
      EXPT_BASEDIR = os.path.realpath(EXPT_BASEDIR)
    except:
      pass
    EXPT_BASEDIR = os.path.abspath(EXPT_BASEDIR)
    
    mkdir_vrfy(f' -p "{EXPT_BASEDIR}"')
    #
    #-----------------------------------------------------------------------
    #
    # If the experiment subdirectory name (EXPT_SUBDIR) is set to an empty
    # string, print out an error message and exit.
    #
    #-----------------------------------------------------------------------
    #
    if not EXPT_SUBDIR:
      print_err_msg_exit(f'''
        The name of the experiment subdirectory (EXPT_SUBDIR) cannot be empty:
          EXPT_SUBDIR = \"{EXPT_SUBDIR}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Set the full path to the experiment directory.  Then check if it already
    # exists and if so, deal with it as specified by PREEXISTING_DIR_METHOD.
    #
    #-----------------------------------------------------------------------
    #
    global EXPTDIR
    EXPTDIR = os.path.join(EXPT_BASEDIR, EXPT_SUBDIR)
    check_for_preexist_dir_file(EXPTDIR,PREEXISTING_DIR_METHOD)
    #
    #-----------------------------------------------------------------------
    #
    # Set other directories, some of which may depend on EXPTDIR (depending
    # on whether we're running in NCO or community mode, i.e. whether RUN_ENVIR 
    # is set to "nco" or "community").  Definitions:
    #
    # LOGDIR:
    # Directory in which the log files from the workflow tasks will be placed.
    #
    # FIXam:
    # This is the directory that will contain the fixed files or symlinks to
    # the fixed files containing various fields on global grids (which are
    # usually much coarser than the native FV3-LAM grid).
    #
    # FIXclim:
    # This is the directory that will contain the MERRA2 aerosol climatology 
    # data file and lookup tables for optics properties
    #
    # FIXLAM:
    # This is the directory that will contain the fixed files or symlinks to
    # the fixed files containing the grid, orography, and surface climatology
    # on the native FV3-LAM grid.
    #
    # CYCLE_BASEDIR:
    # The base directory in which the directories for the various cycles will
    # be placed.
    #
    # COMROOT:
    # In NCO mode, this is the full path to the "com" directory under which 
    # output from the RUN_POST_TN task will be placed.  Note that this output
    # is not placed directly under COMROOT but several directories further
    # down.  More specifically, for a cycle starting at yyyymmddhh, it is at
    #
    #   $COMROOT/$NET/$envir/$RUN.$yyyymmdd/$hh
    #
    # Below, we set COMROOT in terms of PTMP as COMROOT="$PTMP/com".  COMOROOT 
    # is not used by the workflow in community mode.
    #
    # COMOUT_BASEDIR:
    # In NCO mode, this is the base directory directly under which the output 
    # from the RUN_POST_TN task will be placed, i.e. it is the cycle-independent 
    # portion of the RUN_POST_TN task's output directory.  It is given by
    #
    #   $COMROOT/$NET/$model_ver
    #
    # COMOUT_BASEDIR is not used by the workflow in community mode.
    #
    #-----------------------------------------------------------------------
    #
    global LOGDIR, FIXam, FIXclim, FIXLAM, CYCLE_BASEDIR, \
           COMROOT, COMOUT_BASEDIR

    LOGDIR = os.path.join(EXPTDIR, "log")
    
    FIXam = os.path.join(EXPTDIR, "fix_am")
    FIXclim = os.path.join(EXPTDIR, "fix_clim")
    FIXLAM = os.path.join(EXPTDIR, "fix_lam")
    
    if RUN_ENVIR == "nco":
    
      CYCLE_BASEDIR = os.path.join(STMP, "tmpnwprd", RUN)
      check_for_preexist_dir_file(CYCLE_BASEDIR,PREEXISTING_DIR_METHOD)
      COMROOT = os.path.join(PTMP, "com")
      COMOUT_BASEDIR = os.path.join(COMROOT, NET, model_ver)
      check_for_preexist_dir_file(COMOUT_BASEDIR,PREEXISTING_DIR_METHOD)
    
    else:
    
      CYCLE_BASEDIR=EXPTDIR
      COMROOT=""
      COMOUT_BASEDIR=""
    #
    #-----------------------------------------------------------------------
    #
    # The FV3 forecast model needs the following input files in the run di-
    # rectory to start a forecast:
    #
    #   (1) The data table file
    #   (2) The diagnostics table file
    #   (3) The field table file
    #   (4) The FV3 namelist file
    #   (5) The model configuration file
    #   (6) The NEMS configuration file
    #
    # If using CCPP, it also needs:
    #
    #   (7) The CCPP physics suite definition file
    #
    # The workflow contains templates for the first six of these files.  
    # Template files are versions of these files that contain placeholder
    # (i.e. dummy) values for various parameters.  The experiment/workflow 
    # generation scripts copy these templates to appropriate locations in 
    # the experiment directory (either the top of the experiment directory
    # or one of the cycle subdirectories) and replace the placeholders in
    # these copies by actual values specified in the experiment/workflow 
    # configuration file (or derived from such values).  The scripts then
    # use the resulting "actual" files as inputs to the forecast model.
    #
    # Note that the CCPP physics suite defintion file does not have a cor-
    # responding template file because it does not contain any values that
    # need to be replaced according to the experiment/workflow configura-
    # tion.  If using CCPP, this file simply needs to be copied over from 
    # its location in the forecast model's directory structure to the ex-
    # periment directory.
    #
    # Below, we first set the names of the templates for the first six files
    # listed above.  We then set the full paths to these template files.  
    # Note that some of these file names depend on the physics suite while
    # others do not.
    #
    #-----------------------------------------------------------------------
    #
    global DATA_TABLE_TMPL_FN, DIAG_TABLE_TMPL_FN, FIELD_TABLE_TMPL_FN, \
           MODEL_CONFIG_TMPL_FN, NEMS_CONFIG_TMPL_FN
    global DATA_TABLE_TMPL_FP, DIAG_TABLE_TMPL_FP, FIELD_TABLE_TMPL_FP, \
           MODEL_CONFIG_TMPL_FP, NEMS_CONFIG_TMPL_FP
    global FV3_NML_BASE_SUITE_FP, FV3_NML_YAML_CONFIG_FP,FV3_NML_BASE_ENS_FP

    dot_ccpp_phys_suite_or_null=f".{CCPP_PHYS_SUITE}"
    
    # Names of input files that the forecast model (ufs-weather-model) expects 
    # to read in.  These should only be changed if the input file names in the 
    # forecast model code are changed.
    #----------------------------------
    DATA_TABLE_FN = "data_table"
    DIAG_TABLE_FN = "diag_table"
    FIELD_TABLE_FN = "field_table"
    MODEL_CONFIG_FN = "model_configure"
    NEMS_CONFIG_FN = "nems.configure"
    #----------------------------------

    if DATA_TABLE_TMPL_FN is None:
       DATA_TABLE_TMPL_FN = DATA_TABLE_FN
    if DIAG_TABLE_TMPL_FN is None:
       DIAG_TABLE_TMPL_FN = f"{DIAG_TABLE_FN}{dot_ccpp_phys_suite_or_null}"
    if FIELD_TABLE_TMPL_FN is None:
       FIELD_TABLE_TMPL_FN = f"{FIELD_TABLE_FN}{dot_ccpp_phys_suite_or_null}"
    if MODEL_CONFIG_TMPL_FN is None:
       MODEL_CONFIG_TMPL_FN = MODEL_CONFIG_FN
    if NEMS_CONFIG_TMPL_FN is None:
       NEMS_CONFIG_TMPL_FN = NEMS_CONFIG_FN
    
    DATA_TABLE_TMPL_FP = os.path.join(TEMPLATE_DIR,DATA_TABLE_TMPL_FN)
    DIAG_TABLE_TMPL_FP = os.path.join(TEMPLATE_DIR,DIAG_TABLE_TMPL_FN)
    FIELD_TABLE_TMPL_FP = os.path.join(TEMPLATE_DIR,FIELD_TABLE_TMPL_FN)
    FV3_NML_BASE_SUITE_FP = os.path.join(TEMPLATE_DIR,FV3_NML_BASE_SUITE_FN)
    FV3_NML_YAML_CONFIG_FP = os.path.join(TEMPLATE_DIR,FV3_NML_YAML_CONFIG_FN)
    FV3_NML_BASE_ENS_FP = os.path.join(EXPTDIR,FV3_NML_BASE_ENS_FN)
    MODEL_CONFIG_TMPL_FP = os.path.join(TEMPLATE_DIR,MODEL_CONFIG_TMPL_FN)
    NEMS_CONFIG_TMPL_FP = os.path.join(TEMPLATE_DIR,NEMS_CONFIG_TMPL_FN)
    #
    #-----------------------------------------------------------------------
    #
    # Set:
    #
    # 1) the variable CCPP_PHYS_SUITE_FN to the name of the CCPP physics 
    #    suite definition file.
    # 2) the variable CCPP_PHYS_SUITE_IN_CCPP_FP to the full path of this 
    #    file in the forecast model's directory structure.
    # 3) the variable CCPP_PHYS_SUITE_FP to the full path of this file in 
    #    the experiment directory.
    #
    # Note that the experiment/workflow generation scripts will copy this
    # file from CCPP_PHYS_SUITE_IN_CCPP_FP to CCPP_PHYS_SUITE_FP.  Then, for
    # each cycle, the forecast launch script will create a link in the cycle
    # run directory to the copy of this file at CCPP_PHYS_SUITE_FP.
    #
    #-----------------------------------------------------------------------
    #
    global CCPP_PHYS_SUITE_FN, CCPP_PHYS_SUITE_IN_CCPP_FP, CCPP_PHYS_SUITE_FP
    CCPP_PHYS_SUITE_FN=f"suite_{CCPP_PHYS_SUITE}.xml"
    CCPP_PHYS_SUITE_IN_CCPP_FP=os.path.join(UFS_WTHR_MDL_DIR, "FV3","ccpp","suites",CCPP_PHYS_SUITE_FN)
    CCPP_PHYS_SUITE_FP=os.path.join(EXPTDIR, CCPP_PHYS_SUITE_FN)
    if not os.path.exists(CCPP_PHYS_SUITE_IN_CCPP_FP):
      print_err_msg_exit(f'''
        The CCPP suite definition file (CCPP_PHYS_SUITE_IN_CCPP_FP) does not exist
        in the local clone of the ufs-weather-model:
          CCPP_PHYS_SUITE_IN_CCPP_FP = \"{CCPP_PHYS_SUITE_IN_CCPP_FP}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Set:
    #
    # 1) the variable FIELD_DICT_FN to the name of the field dictionary
    #    file.
    # 2) the variable FIELD_DICT_IN_UWM_FP to the full path of this
    #    file in the forecast model's directory structure.
    # 3) the variable FIELD_DICT_FP to the full path of this file in
    #    the experiment directory.
    #
    #-----------------------------------------------------------------------
    #
    global FIELD_DICT_FN, FIELD_DICT_IN_UWM_FP, FIELD_DICT_FP
    FIELD_DICT_FN = "fd_nems.yaml"
    FIELD_DICT_IN_UWM_FP = os.path.join(UFS_WTHR_MDL_DIR, "tests", "parm", FIELD_DICT_FN)
    FIELD_DICT_FP = os.path.join(EXPTDIR, FIELD_DICT_FN)
    if not os.path.exists(FIELD_DICT_IN_UWM_FP):
      print_err_msg_exit(f'''
        The field dictionary file (FIELD_DICT_IN_UWM_FP) does not exist
        in the local clone of the ufs-weather-model:
          FIELD_DICT_IN_UWM_FP = \"{FIELD_DICT_IN_UWM_FP}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Call the function that sets the ozone parameterization being used and
    # modifies associated parameters accordingly. 
    #
    #-----------------------------------------------------------------------
    #
   
    # export env vars before calling another module 
    export_vars()

    OZONE_PARAM = set_ozone_param( \
      ccpp_phys_suite_fp=CCPP_PHYS_SUITE_IN_CCPP_FP)

    IMPORTS = ["CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING", "FIXgsm_FILES_TO_COPY_TO_FIXam"]
    import_vars(env_vars=IMPORTS)
    #
    #-----------------------------------------------------------------------
    #
    # Set the full paths to those forecast model input files that are cycle-
    # independent, i.e. they don't include information about the cycle's 
    # starting day/time.  These are:
    #
    #   * The data table file [(1) in the list above)]
    #   * The field table file [(3) in the list above)]
    #   * The FV3 namelist file [(4) in the list above)]
    #   * The NEMS configuration file [(6) in the list above)]
    #
    # Since they are cycle-independent, the experiment/workflow generation
    # scripts will place them in the main experiment directory (EXPTDIR).
    # The script that runs each cycle will then create links to these files
    # in the run directories of the individual cycles (which are subdirecto-
    # ries under EXPTDIR).  
    # 
    # The remaining two input files to the forecast model, i.e.
    #
    #   * The diagnostics table file [(2) in the list above)]
    #   * The model configuration file [(5) in the list above)]
    #
    # contain parameters that depend on the cycle start date.  Thus, custom
    # versions of these two files must be generated for each cycle and then
    # placed directly in the run directories of the cycles (not EXPTDIR).
    # For this reason, the full paths to their locations vary by cycle and
    # cannot be set here (i.e. they can only be set in the loop over the 
    # cycles in the rocoto workflow XML file).
    #
    #-----------------------------------------------------------------------
    #
    global DATA_TABLE_FP, FIELD_TABLE_FP, FV3_NML_FN, FV3_NML_FP, NEMS_CONFIG_FP
    DATA_TABLE_FP = os.path.join(EXPTDIR, DATA_TABLE_FN)
    FIELD_TABLE_FP = os.path.join(EXPTDIR, FIELD_TABLE_FN)
    FV3_NML_FN = os.path.splitext(FV3_NML_BASE_SUITE_FN)[0]
    FV3_NML_FP = os.path.join(EXPTDIR, FV3_NML_FN)
    NEMS_CONFIG_FP = os.path.join(EXPTDIR, NEMS_CONFIG_FN)
    #
    #-----------------------------------------------------------------------
    #
    # If USE_USER_STAGED_EXTRN_FILES is set to TRUE, make sure that the user-
    # specified directories under which the external model files should be 
    # located actually exist.
    #
    #-----------------------------------------------------------------------
    #
    if USE_USER_STAGED_EXTRN_FILES:
    
      if not os.path.exists(EXTRN_MDL_SOURCE_BASEDIR_ICS):
      # Check for the base directory up to the first templated field.
      idx = EXTRN_MDL_SOURCE_BASEDIR_ICS.find("$")
      if not os.path.exists(EXTRN_MDL_SOURCE_BASEDIR_ICS[:idx]):
        print_err_msg_exit(f'''
            The directory (EXTRN_MDL_SOURCE_BASEDIR_ICS) in which the user-staged 
            external model files for generating ICs should be located does not exist:
              EXTRN_MDL_SOURCE_BASEDIR_ICS = \"{EXTRN_MDL_SOURCE_BASEDIR_ICS}\"''')
    
      if not os.path.exists(EXTRN_MDL_SOURCE_BASEDIR_LBCS):
      idx = EXTRN_MDL_SOURCE_BASEDIR_LBCS.find("$")
      if not os.path.exists(EXTRN_MDL_SOURCE_BASEDIR_LBCS[:idx]): 
        print_err_msg_exit(f'''
            The directory (EXTRN_MDL_SOURCE_BASEDIR_LBCS) in which the user-staged 
            external model files for generating LBCs should be located does not exist:
              EXTRN_MDL_SOURCE_BASEDIR_LBCS = \"{EXTRN_MDL_SOURCE_BASEDIR_LBCS}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Make sure that DO_ENSEMBLE is set to a valid value.  Then set the names
    # of the ensemble members.  These will be used to set the ensemble member
    # directories.  Also, set the full path to the FV3 namelist file corresponding
    # to each ensemble member.
    #
    #-----------------------------------------------------------------------
    #
    global NDIGITS_ENSMEM_NAMES,ENSMEM_NAMES,FV3_NML_ENSMEM_FPS,NUM_ENS_MEMBERS
    NDIGITS_ENSMEM_NAMES=0
    ENSMEM_NAMES=[]
    FV3_NML_ENSMEM_FPS=[]
    if DO_ENSEMBLE:
      NDIGITS_ENSMEM_NAMES=len(str(NUM_ENS_MEMBERS))
      fmt=f"0{NDIGITS_ENSMEM_NAMES}d"
      for i in range(NUM_ENS_MEMBERS):
        ENSMEM_NAMES.append(f"mem{fmt}".format(i+1))
        FV3_NML_ENSMEM_FPS.append(os.path.join(EXPTDIR, f"{FV3_NML_FN}_{ENSMEM_NAMES[i]}"))
    #
    #-----------------------------------------------------------------------
    #
    # Set the full path to the forecast model executable.
    #
    #-----------------------------------------------------------------------
    #
    global FV3_EXEC_FP
    FV3_EXEC_FP = os.path.join(EXECDIR, FV3_EXEC_FN)
    #
    #-----------------------------------------------------------------------
    #
    # Set the full path to the script that can be used to (re)launch the 
    # workflow.  Also, if USE_CRON_TO_RELAUNCH is set to TRUE, set the line
    # to add to the cron table to automatically relaunch the workflow every
    # CRON_RELAUNCH_INTVL_MNTS minutes.  Otherwise, set the variable con-
    # taining this line to a null string.
    #
    #-----------------------------------------------------------------------
    #
    global WFLOW_LAUNCH_SCRIPT_FP, WFLOW_LAUNCH_LOG_FP, CRONTAB_LINE
    WFLOW_LAUNCH_SCRIPT_FP = os.path.join(USHDIR, WFLOW_LAUNCH_SCRIPT_FN)
    WFLOW_LAUNCH_LOG_FP = os.path.join(EXPTDIR, WFLOW_LAUNCH_LOG_FN)
    if USE_CRON_TO_RELAUNCH:
      CRONTAB_LINE=f'''*/{CRON_RELAUNCH_INTVL_MNTS} * * * * cd {EXPTDIR} && ./{WFLOW_LAUNCH_SCRIPT_FN} called_from_cron="TRUE" >> ./{WFLOW_LAUNCH_LOG_FN} 2>&1'''
    else:
      CRONTAB_LINE=""
    #
    #-----------------------------------------------------------------------
    #
    # Set the full path to the script that, for a given task, loads the
    # necessary module files and runs the tasks.
    #
    #-----------------------------------------------------------------------
    #
    global LOAD_MODULES_RUN_TASK_FP
    LOAD_MODULES_RUN_TASK_FP = os.path.join(USHDIR, "load_modules_run_task.sh")
    #
    #-----------------------------------------------------------------------
    #
    # Define the various work subdirectories under the main work directory.
    # Each of these corresponds to a different step/substep/task in the pre-
    # processing, as follows:
    #
    # GRID_DIR:
    # Directory in which the grid files will be placed (if RUN_TASK_MAKE_GRID 
    # is set to True) or searched for (if RUN_TASK_MAKE_GRID is set to 
    # False).
    #
    # OROG_DIR:
    # Directory in which the orography files will be placed (if RUN_TASK_MAKE_OROG 
    # is set to True) or searched for (if RUN_TASK_MAKE_OROG is set to 
    # False).
    #
    # SFC_CLIMO_DIR:
    # Directory in which the surface climatology files will be placed (if
    # RUN_TASK_MAKE_SFC_CLIMO is set to True) or searched for (if 
    # RUN_TASK_MAKE_SFC_CLIMO is set to False).
    #
    #----------------------------------------------------------------------
    #
    global RUN_TASK_MAKE_GRID, RUN_TASK_MAKE_OROG, RUN_TASK_MAKE_SFC_CLIMO
    global GRID_DIR, OROG_DIR, SFC_CLIMO_DIR
    global RUN_TASK_VX_GRIDSTAT, RUN_TASK_VX_POINTSTAT, RUN_TASK_VX_ENSGRID

    #
    #-----------------------------------------------------------------------
    #
    # Make sure that DO_ENSEMBLE is set to TRUE when running ensemble vx.
    #
    #-----------------------------------------------------------------------
    #
    if (not DO_ENSEMBLE) and (RUN_TASK_VX_ENSGRID or RUN_TASK_VX_ENSPOINT):
      print_err_msg_exit(f'''
        Ensemble verification can not be run unless running in ensemble mode:
           DO_ENSEMBLE = \"{DO_ENSEMBLE}\"
           RUN_TASK_VX_ENSGRID = \"{RUN_TASK_VX_ENSGRID}\"
           RUN_TASK_VX_ENSPOINT = \"{RUN_TASK_VX_ENSPOINT}\"''')

    if RUN_ENVIR == "nco":
    
      nco_fix_dir = os.path.join(DOMAIN_PREGEN_BASEDIR, PREDEF_GRID_NAME)
      if not os.path.exists(nco_fix_dir):
        print_err_msg_exit(f'''
            The directory (nco_fix_dir) that should contain the pregenerated grid,
            orography, and surface climatology files does not exist:
              nco_fix_dir = \"{nco_fix_dir}\"''')
    
      if RUN_TASK_MAKE_GRID or \
         ( not RUN_TASK_MAKE_GRID and \
           GRID_DIR != nco_fix_dir ):
    
        msg=f'''
            When RUN_ENVIR is set to \"nco\", the workflow assumes that pregenerated
            grid files already exist in the directory 
            
              {DOMAIN_PREGEN_BASEDIR}/{PREDEF_GRID_NAME}
            
            where
            
              DOMAIN_PREGEN_BASEDIR = \"{DOMAIN_PREGEN_BASEDIR}\"
              PREDEF_GRID_NAME = \"{PREDEF_GRID_NAME}\"
            
            Thus, the MAKE_GRID_TN task must not be run (i.e. RUN_TASK_MAKE_GRID must 
            be set to \"FALSE\"), and the directory in which to look for the grid 
            files (i.e. GRID_DIR) must be set to the one above.  Current values for 
            these quantities are:
            
              RUN_TASK_MAKE_GRID = \"{RUN_TASK_MAKE_GRID}\"
              GRID_DIR = \"{GRID_DIR}\"
            
            Resetting RUN_TASK_MAKE_GRID to \"FALSE\" and GRID_DIR to the one above.
            Reset values are:
        '''
    
        RUN_TASK_MAKE_GRID=False
        GRID_DIR=nco_fix_dir
    
        msg+=f'''
            RUN_TASK_MAKE_GRID = \"{RUN_TASK_MAKE_GRID}\"
            GRID_DIR = \"{GRID_DIR}\"
        '''
    
        print_info_msg(msg)
    
    
      if RUN_TASK_MAKE_OROG or \
         ( not RUN_TASK_MAKE_OROG and \
           OROG_DIR != nco_fix_dir ):
    
        msg=f'''
            When RUN_ENVIR is set to \"nco\", the workflow assumes that pregenerated
            orography files already exist in the directory 
              {DOMAIN_PREGEN_BASEDIR}/{PREDEF_GRID_NAME}
            
            where
            
              DOMAIN_PREGEN_BASEDIR = \"{DOMAIN_PREGEN_BASEDIR}\"
              PREDEF_GRID_NAME = \"{PREDEF_GRID_NAME}\"
            
            Thus, the MAKE_OROG_TN task must not be run (i.e. RUN_TASK_MAKE_OROG must 
            be set to \"FALSE\"), and the directory in which to look for the orography 
            files (i.e. OROG_DIR) must be set to the one above.  Current values for 
            these quantities are:
            
              RUN_TASK_MAKE_OROG = \"{RUN_TASK_MAKE_OROG}\"
              OROG_DIR = \"{OROG_DIR}\"
            
            Resetting RUN_TASK_MAKE_OROG to \"FALSE\" and OROG_DIR to the one above.
            Reset values are:
        '''
    
        RUN_TASK_MAKE_OROG=False
        OROG_DIR=nco_fix_dir
    
        msg+=f'''
            RUN_TASK_MAKE_OROG = \"{RUN_TASK_MAKE_OROG}\"
            OROG_DIR = \"{OROG_DIR}\"
        '''
    
        print_info_msg(msg)
    
    
      if RUN_TASK_MAKE_SFC_CLIMO or \
         ( not RUN_TASK_MAKE_SFC_CLIMO and \
           SFC_CLIMO_DIR != nco_fix_dir ):
    
        msg=f'''
            When RUN_ENVIR is set to \"nco\", the workflow assumes that pregenerated
            surface climatology files already exist in the directory 
            
              {DOMAIN_PREGEN_BASEDIR}/{PREDEF_GRID_NAME}
            
            where
            
              DOMAIN_PREGEN_BASEDIR = \"{DOMAIN_PREGEN_BASEDIR}\"
              PREDEF_GRID_NAME = \"{PREDEF_GRID_NAME}\"
            
            Thus, the MAKE_SFC_CLIMO_TN task must not be run (i.e. RUN_TASK_MAKE_SFC_CLIMO 
            must be set to \"FALSE\"), and the directory in which to look for the 
            surface climatology files (i.e. SFC_CLIMO_DIR) must be set to the one 
            above.  Current values for these quantities are:
            
              RUN_TASK_MAKE_SFC_CLIMO = \"{RUN_TASK_MAKE_SFC_CLIMO}\"
              SFC_CLIMO_DIR = \"{SFC_CLIMO_DIR}\"
            
            Resetting RUN_TASK_MAKE_SFC_CLIMO to \"FALSE\" and SFC_CLIMO_DIR to the 
            one above.  Reset values are:
        '''
    
        RUN_TASK_MAKE_SFC_CLIMO=False
        SFC_CLIMO_DIR=nco_fix_dir
    
        msg+=f'''
            RUN_TASK_MAKE_SFC_CLIMO = \"{RUN_TASK_MAKE_SFC_CLIMO}\"
            SFC_CLIMO_DIR = \"{SFC_CLIMO_DIR}\"
        '''
    
        print_info_msg(msg)
    
      if RUN_TASK_VX_GRIDSTAT:
    
        msg=f'''
            When RUN_ENVIR is set to \"nco\", it is assumed that the verification
            will not be run.
              RUN_TASK_VX_GRIDSTAT = \"{RUN_TASK_VX_GRIDSTAT}\"
            Resetting RUN_TASK_VX_GRIDSTAT to \"FALSE\"
            Reset value is:'''

        RUN_TASK_VX_GRIDSTAT=False

        msg+=f'''
            RUN_TASK_VX_GRIDSTAT = \"{RUN_TASK_VX_GRIDSTAT}\"
        '''
    
        print_info_msg(msg)
    
      if RUN_TASK_VX_POINTSTAT:
    
        msg=f'''
            When RUN_ENVIR is set to \"nco\", it is assumed that the verification
            will not be run.
              RUN_TASK_VX_POINTSTAT = \"{RUN_TASK_VX_POINTSTAT}\"
            Resetting RUN_TASK_VX_POINTSTAT to \"FALSE\"
            Reset value is:'''

        RUN_TASK_VX_POINTSTAT=False

        msg=f'''
            RUN_TASK_VX_POINTSTAT = \"{RUN_TASK_VX_POINTSTAT}\"
        '''
    
        print_info_msg(msg)
    
      if RUN_TASK_VX_ENSGRID:
    
        msg=f'''
            When RUN_ENVIR is set to \"nco\", it is assumed that the verification
            will not be run.
              RUN_TASK_VX_ENSGRID = \"{RUN_TASK_VX_ENSGRID}\"
            Resetting RUN_TASK_VX_ENSGRID to \"FALSE\" 
            Reset value is:'''
    
        RUN_TASK_VX_ENSGRID=False
    
        msg+=f'''
            RUN_TASK_VX_ENSGRID = \"{RUN_TASK_VX_ENSGRID}\"
        '''
    
        print_info_msg(msg)
    
    #
    #-----------------------------------------------------------------------
    #
    # Now consider community mode.
    #
    #-----------------------------------------------------------------------
    #
    else:
      #
      # If RUN_TASK_MAKE_GRID is set to False, the workflow will look for 
      # the pregenerated grid files in GRID_DIR.  In this case, make sure that 
      # GRID_DIR exists.  Otherwise, set it to a predefined location under the 
      # experiment directory (EXPTDIR).
      #
      if not RUN_TASK_MAKE_GRID:
        if not os.path.exists(GRID_DIR):
          print_err_msg_exit(f'''
            The directory (GRID_DIR) that should contain the pregenerated grid files 
            does not exist:
              GRID_DIR = \"{GRID_DIR}\"''')
      else:
        GRID_DIR=os.path.join(EXPTDIR,"grid")
      #
      # If RUN_TASK_MAKE_OROG is set to False, the workflow will look for 
      # the pregenerated orography files in OROG_DIR.  In this case, make sure 
      # that OROG_DIR exists.  Otherwise, set it to a predefined location under 
      # the experiment directory (EXPTDIR).
      #
      if not RUN_TASK_MAKE_OROG:
        if not os.path.exists(OROG_DIR):
          print_err_msg_exit(f'''
            The directory (OROG_DIR) that should contain the pregenerated orography
            files does not exist:
              OROG_DIR = \"{OROG_DIR}\"''')
      else:
        OROG_DIR=os.path.join(EXPTDIR,"orog")
      #
      # If RUN_TASK_MAKE_SFC_CLIMO is set to False, the workflow will look 
      # for the pregenerated surface climatology files in SFC_CLIMO_DIR.  In
      # this case, make sure that SFC_CLIMO_DIR exists.  Otherwise, set it to
      # a predefined location under the experiment directory (EXPTDIR).
      #
      if not RUN_TASK_MAKE_SFC_CLIMO:
        if not os.path.exists(SFC_CLIMO_DIR):
          print_err_msg_exit(f'''
            The directory (SFC_CLIMO_DIR) that should contain the pregenerated surface
            climatology files does not exist:
              SFC_CLIMO_DIR = \"{SFC_CLIMO_DIR}\"''')
      else:
        SFC_CLIMO_DIR=os.path.join(EXPTDIR,"sfc_climo")

    #-----------------------------------------------------------------------
    #
    # Set cycle-independent parameters associated with the external models
    # from which we will obtain the ICs and LBCs.
    #
    #-----------------------------------------------------------------------
    #

    # export env vars before calling another module 
    export_vars()

    set_extrn_mdl_params()

    IMPORTS = ["EXTRN_MDL_SYSBASEDIR_ICS", "EXTRN_MDL_SYSBASEDIR_LBCS", "EXTRN_MDL_LBCS_OFFSET_HRS"]
    import_vars(env_vars=IMPORTS)
    #
    #-----------------------------------------------------------------------
    #
    # Any regional model must be supplied lateral boundary conditions (in
    # addition to initial conditions) to be able to perform a forecast.  In
    # the FV3-LAM model, these boundary conditions (BCs) are supplied using a
    # "halo" of grid cells around the regional domain that extend beyond the
    # boundary of the domain.  The model is formulated such that along with
    # files containing these BCs, it needs as input the following files (in
    # NetCDF format):
    #
    # 1) A grid file that includes a halo of 3 cells beyond the boundary of
    #    the domain.
    # 2) A grid file that includes a halo of 4 cells beyond the boundary of
    #    the domain.
    # 3) A (filtered) orography file without a halo, i.e. a halo of width
    #    0 cells.
    # 4) A (filtered) orography file that includes a halo of 4 cells beyond
    #    the boundary of the domain.
    #
    # Note that the regional grid is referred to as "tile 7" in the code.
    # We will let:
    #
    # * NH0 denote the width (in units of number of cells on tile 7) of
    #   the 0-cell-wide halo, i.e. NH0 = 0;
    #
    # * NH3 denote the width (in units of number of cells on tile 7) of
    #   the 3-cell-wide halo, i.e. NH3 = 3; and
    #
    # * NH4 denote the width (in units of number of cells on tile 7) of
    #   the 4-cell-wide halo, i.e. NH4 = 4.
    #
    # We define these variables next.
    #
    #-----------------------------------------------------------------------
    #
    global NH0,NH3,NH4
    NH0=0
    NH3=3
    NH4=4

    # export env vars
    EXPORTS = ["NH0","NH3","NH4"]
    export_vars(env_vars = EXPORTS)
    #
    #-----------------------------------------------------------------------
    #
    # Set parameters according to the type of horizontal grid generation 
    # method specified.  First consider GFDL's global-parent-grid based 
    # method.
    #
    #-----------------------------------------------------------------------
    #
    global LON_CTR,LAT_CTR,NX,NY,NHW,STRETCH_FAC,\
        ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,\
        IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,\
        JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,\
        JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG
    global PAZI,DEL_ANGLE_X_SG,DEL_ANGLE_Y_SG,\
        NEG_NX_OF_DOM_WITH_WIDE_HALO,\
        NEG_NY_OF_DOM_WITH_WIDE_HALO

    if GRID_GEN_METHOD == "GFDLgrid":
    
      (\
      LON_CTR,LAT_CTR,NX,NY,NHW,STRETCH_FAC,
      ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,
      IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,
      JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG,
      JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG \
      ) = \
        set_gridparams_GFDLgrid( \
        lon_of_t6_ctr=GFDLgrid_LON_T6_CTR, \
        lat_of_t6_ctr=GFDLgrid_LAT_T6_CTR, \
        res_of_t6g=GFDLgrid_RES, \
        stretch_factor=GFDLgrid_STRETCH_FAC, \
        refine_ratio_t6g_to_t7g=GFDLgrid_REFINE_RATIO, \
        istart_of_t7_on_t6g=GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G, \
        iend_of_t7_on_t6g=GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G, \
        jstart_of_t7_on_t6g=GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G, \
        jend_of_t7_on_t6g=GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G)
    #
    #-----------------------------------------------------------------------
    #
    # Now consider Jim Purser's map projection/grid generation method.
    #
    #-----------------------------------------------------------------------
    #
    elif GRID_GEN_METHOD == "ESGgrid":
    
      (\
      LON_CTR,LAT_CTR,NX,NY,PAZI,
      NHW,STRETCH_FAC,DEL_ANGLE_X_SG,DEL_ANGLE_Y_SG,
      NEG_NX_OF_DOM_WITH_WIDE_HALO,
      NEG_NY_OF_DOM_WITH_WIDE_HALO \
      ) = \
        set_gridparams_ESGgrid( \
        lon_ctr=ESGgrid_LON_CTR, \
        lat_ctr=ESGgrid_LAT_CTR, \
        nx=ESGgrid_NX, \
        ny=ESGgrid_NY, \
        pazi=ESGgrid_PAZI, \
        halo_width=ESGgrid_WIDE_HALO_WIDTH, \
        delx=ESGgrid_DELX, \
        dely=ESGgrid_DELY)

    #
    #-----------------------------------------------------------------------
    #
    # Create a new experiment directory.  Note that at this point we are 
    # guaranteed that there is no preexisting experiment directory. For
    # platforms with no workflow manager, we need to create LOGDIR as well,
    # since it won't be created later at runtime.
    #
    #-----------------------------------------------------------------------
    #
    mkdir_vrfy(f' -p "{EXPTDIR}"')
    mkdir_vrfy(f' -p "{LOGDIR}"')
    #
    #-----------------------------------------------------------------------
    #
    # If not running the MAKE_GRID_TN, MAKE_OROG_TN, and/or MAKE_SFC_CLIMO
    # tasks, create symlinks under the FIXLAM directory to pregenerated grid,
    # orography, and surface climatology files.  In the process, also set 
    # RES_IN_FIXLAM_FILENAMES, which is the resolution of the grid (in units
    # of number of grid points on an equivalent global uniform cubed-sphere
    # grid) used in the names of the fixed files in the FIXLAM directory.
    #
    #-----------------------------------------------------------------------
    #
    mkdir_vrfy(f' -p "{FIXLAM}"')
    RES_IN_FIXLAM_FILENAMES=""
    #
    #-----------------------------------------------------------------------
    #
    # If the grid file generation task in the workflow is going to be skipped
    # (because pregenerated files are available), create links in the FIXLAM
    # directory to the pregenerated grid files.
    #
    #-----------------------------------------------------------------------
    #

    # export env vars
    export_vars()

    # link fix files
    res_in_grid_fns=""
    if not RUN_TASK_MAKE_GRID:
    
      res_in_grid_fns = link_fix( \
        verbose=VERBOSE, \
        file_group="grid")

      RES_IN_FIXLAM_FILENAMES=res_in_grid_fns
    #
    #-----------------------------------------------------------------------
    #
    # If the orography file generation task in the workflow is going to be
    # skipped (because pregenerated files are available), create links in
    # the FIXLAM directory to the pregenerated orography files.
    #
    #-----------------------------------------------------------------------
    #
    res_in_orog_fns=""
    if not RUN_TASK_MAKE_OROG:
    
      res_in_orog_fns = link_fix( \
        verbose=VERBOSE, \
        file_group="orog")

      if not RES_IN_FIXLAM_FILENAMES and \
         ( res_in_orog_fns != RES_IN_FIXLAM_FILENAMES):
        print_err_msg_exit(f'''
            The resolution extracted from the orography file names (res_in_orog_fns)
            does not match the resolution in other groups of files already consi-
            dered (RES_IN_FIXLAM_FILENAMES):
              res_in_orog_fns = {res_in_orog_fns}
              RES_IN_FIXLAM_FILENAMES = {RES_IN_FIXLAM_FILENAMES}''')
      else:
        RES_IN_FIXLAM_FILENAMES=res_in_orog_fns
    #
    #-----------------------------------------------------------------------
    #
    # If the surface climatology file generation task in the workflow is
    # going to be skipped (because pregenerated files are available), create
    # links in the FIXLAM directory to the pregenerated surface climatology
    # files.
    #
    #-----------------------------------------------------------------------
    #
    res_in_sfc_climo_fns=""
    if not RUN_TASK_MAKE_SFC_CLIMO:
    
      res_in_sfc_climo_fns = link_fix( \
        verbose=VERBOSE, \
        file_group="sfc_climo")

      if RES_IN_FIXLAM_FILENAMES and \
         res_in_sfc_climo_fns != RES_IN_FIXLAM_FILENAMES:
        print_err_msg_exit(f'''
            The resolution extracted from the surface climatology file names (res_-
            in_sfc_climo_fns) does not match the resolution in other groups of files
            already considered (RES_IN_FIXLAM_FILENAMES):
              res_in_sfc_climo_fns = {res_in_sfc_climo_fns}
              RES_IN_FIXLAM_FILENAMES = {RES_IN_FIXLAM_FILENAMES}''')
      else:
        RES_IN_FIXLAM_FILENAMES=res_in_sfc_climo_fns
    #
    #-----------------------------------------------------------------------
    #
    # The variable CRES is needed in constructing various file names.  If 
    # not running the make_grid task, we can set it here.  Otherwise, it 
    # will get set to a valid value by that task.
    #
    #-----------------------------------------------------------------------
    #
    global CRES
    CRES=""
    if not RUN_TASK_MAKE_GRID:
      CRES=f"C{RES_IN_FIXLAM_FILENAMES}"
    #
    #-----------------------------------------------------------------------
    #
    # Make sure that WRITE_DOPOST is set to a valid value.
    #
    #-----------------------------------------------------------------------
    #
    global RUN_TASK_RUN_POST
    if WRITE_DOPOST:
      # Turn off run_post
      RUN_TASK_RUN_POST=False
    
      # Check if SUB_HOURLY_POST is on
      if SUB_HOURLY_POST:
        print_err_msg_exit(f'''
            SUB_HOURLY_POST is NOT available with Inline Post yet.''')
    #
    #-----------------------------------------------------------------------
    #
    # Calculate PE_MEMBER01.  This is the number of MPI tasks used for the
    # forecast, including those for the write component if QUILTING is set
    # to True.
    #
    #-----------------------------------------------------------------------
    #
    global PE_MEMBER01
    PE_MEMBER01=LAYOUT_X*LAYOUT_Y
    if QUILTING:
      PE_MEMBER01 = PE_MEMBER01 + WRTCMP_write_groups*WRTCMP_write_tasks_per_group
    
    print_info_msg(f'''
        The number of MPI tasks for the forecast (including those for the write
        component if it is being used) are:
          PE_MEMBER01 = {PE_MEMBER01}''', verbose=VERBOSE)
    #
    #-----------------------------------------------------------------------
    #
    # Calculate the number of nodes (NNODES_RUN_FCST) to request from the job
    # scheduler for the forecast task (RUN_FCST_TN).  This is just PE_MEMBER01
    # dividied by the number of processes per node we want to request for this
    # task (PPN_RUN_FCST), then rounded up to the nearest integer, i.e.
    #
    #   NNODES_RUN_FCST = ceil(PE_MEMBER01/PPN_RUN_FCST)
    #
    # where ceil(...) is the ceiling function, i.e. it rounds its floating
    # point argument up to the next larger integer.  Since in bash, division
    # of two integers returns a truncated integer, and since bash has no
    # built-in ceil(...) function, we perform the rounding-up operation by
    # adding the denominator (of the argument of ceil(...) above) minus 1 to
    # the original numerator, i.e. by redefining NNODES_RUN_FCST to be
    #
    #   NNODES_RUN_FCST = (PE_MEMBER01 + PPN_RUN_FCST - 1)/PPN_RUN_FCST
    #
    #-----------------------------------------------------------------------
    #
    global NNODES_RUN_FCST
    NNODES_RUN_FCST= (PE_MEMBER01 + PPN_RUN_FCST - 1)//PPN_RUN_FCST
    
    #
    #-----------------------------------------------------------------------
    #
    # Call the function that checks whether the RUC land surface model (LSM)
    # is being called by the physics suite and sets the workflow variable 
    # SDF_USES_RUC_LSM to True or False accordingly.
    #
    #-----------------------------------------------------------------------
    #
    global SDF_USES_RUC_LSM
    SDF_USES_RUC_LSM = check_ruc_lsm( \
      ccpp_phys_suite_fp=CCPP_PHYS_SUITE_IN_CCPP_FP)
    #
    #-----------------------------------------------------------------------
    #
    # Set the name of the file containing aerosol climatology data that, if
    # necessary, can be used to generate approximate versions of the aerosol 
    # fields needed by Thompson microphysics.  This file will be used to 
    # generate such approximate aerosol fields in the ICs and LBCs if Thompson 
    # MP is included in the physics suite and if the exteranl model for ICs
    # or LBCs does not already provide these fields.  Also, set the full path
    # to this file.
    #
    #-----------------------------------------------------------------------
    #
    THOMPSON_MP_CLIMO_FN="Thompson_MP_MONTHLY_CLIMO.nc"
    THOMPSON_MP_CLIMO_FP=os.path.join(FIXam,THOMPSON_MP_CLIMO_FN)
    #
    #-----------------------------------------------------------------------
    #
    # Call the function that, if the Thompson microphysics parameterization
    # is being called by the physics suite, modifies certain workflow arrays
    # to ensure that fixed files needed by this parameterization are copied
    # to the FIXam directory and appropriate symlinks to them are created in
    # the run directories.  This function also sets the workflow variable
    # SDF_USES_THOMPSON_MP that indicates whether Thompson MP is called by 
    # the physics suite.
    #
    #-----------------------------------------------------------------------
    #
    SDF_USES_THOMPSON_MP = set_thompson_mp_fix_files( \
      ccpp_phys_suite_fp=CCPP_PHYS_SUITE_IN_CCPP_FP, \
      thompson_mp_climo_fn=THOMPSON_MP_CLIMO_FN)

    IMPORTS = [ "CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING", "FIXgsm_FILES_TO_COPY_TO_FIXam" ]
    import_vars(env_vars=IMPORTS)
    #
    #-----------------------------------------------------------------------
    #
    # Generate the shell script that will appear in the experiment directory
    # (EXPTDIR) and will contain definitions of variables needed by the va-
    # rious scripts in the workflow.  We refer to this as the experiment/
    # workflow global variable definitions file.  We will create this file
    # by:
    #
    # 1) Copying the default workflow/experiment configuration file (speci-
    #    fied by EXPT_DEFAULT_CONFIG_FN and located in the shell script di-
    #    rectory specified by USHDIR) to the experiment directory and rena-
    #    ming it to the name specified by GLOBAL_VAR_DEFNS_FN.
    #
    # 2) Resetting the default variable values in this file to their current
    #    values.  This is necessary because these variables may have been 
    #    reset by the user-specified configuration file (if one exists in 
    #    USHDIR) and/or by this setup script, e.g. because predef_domain is
    #    set to a valid non-empty value.
    #
    # 3) Appending to the variable definitions file any new variables intro-
    #    duced in this setup script that may be needed by the scripts that
    #    perform the various tasks in the workflow (and which source the va-
    #    riable defintions file).
    #
    # First, set the full path to the variable definitions file and copy the
    # default configuration script into it.
    #
    #-----------------------------------------------------------------------
    #

    # update dictionary with globals() values
    update_dict = {k: globals()[k] for k in cfg_d.keys() if k in globals() }
    cfg_d.update(update_dict)

    # write the updated default dictionary
    global GLOBAL_VAR_DEFNS_FP
    GLOBAL_VAR_DEFNS_FP=os.path.join(EXPTDIR,GLOBAL_VAR_DEFNS_FN)
    all_lines=cfg_to_shell_str(cfg_d)
    with open(GLOBAL_VAR_DEFNS_FP,'w') as f:
        msg = f"""            #
            #-----------------------------------------------------------------------
            #-----------------------------------------------------------------------
            # Section 1:
            # This section contains (most of) the primary experiment variables, i.e. 
            # those variables that are defined in the default configuration file 
            # (config_defaults.sh) and that can be reset via the user-specified 
            # experiment configuration file (config.sh).
            #-----------------------------------------------------------------------
            #-----------------------------------------------------------------------
            #
            """
        f.write(dedent(msg))
        f.write(all_lines)
    
    # print info message
    msg=dedent(f'''
        Before updating default values of experiment variables to user-specified
        values, the variable \"line_list\" contains:

        ''')

    msg +=dedent(f'''
        {all_lines}''')

    print_info_msg(msg,verbose=DEBUG)
    #
    # print info message
    #
    print_info_msg(f'''
        Generating the global experiment variable definitions file specified by
        GLOBAL_VAR_DEFNS_FN:
          GLOBAL_VAR_DEFNS_FN = \"{GLOBAL_VAR_DEFNS_FN}\"
        Full path to this file is:
          GLOBAL_VAR_DEFNS_FP = \"{GLOBAL_VAR_DEFNS_FP}\"
        For more detailed information, set DEBUG to \"TRUE\" in the experiment
        configuration file (\"{EXPT_CONFIG_FN}\").''')
    
    #
    #-----------------------------------------------------------------------
    #
    # Append additional variable definitions (and comments) to the variable
    # definitions file.  These variables have been set above using the vari-
    # ables in the default and local configuration scripts.  These variables
    # are needed by various tasks/scripts in the workflow.
    #
    #-----------------------------------------------------------------------
    #
    msg = f"""
        #
        #-----------------------------------------------------------------------
        #-----------------------------------------------------------------------
        # Section 2:
        # This section defines variables that have been derived from the primary
        # set of experiment variables above (we refer to these as \"derived\" or
        # \"secondary\" variables).
        #-----------------------------------------------------------------------
        #-----------------------------------------------------------------------
        #
        
        #
        #-----------------------------------------------------------------------
        #
        # Full path to workflow (re)launch script, its log file, and the line 
        # that gets added to the cron table to launch this script if the flag 
        # USE_CRON_TO_RELAUNCH is set to \"TRUE\".
        #
        #-----------------------------------------------------------------------
        #
        WFLOW_LAUNCH_SCRIPT_FP='{WFLOW_LAUNCH_SCRIPT_FP}'
        WFLOW_LAUNCH_LOG_FP='{WFLOW_LAUNCH_LOG_FP}'
        CRONTAB_LINE='{CRONTAB_LINE}'
        #
        #-----------------------------------------------------------------------
        #
        # Directories.
        #
        #-----------------------------------------------------------------------
        #
        SR_WX_APP_TOP_DIR='{SR_WX_APP_TOP_DIR}'
        HOMErrfs='{HOMErrfs}'
        USHDIR='{USHDIR}'
        SCRIPTSDIR='{SCRIPTSDIR}'
        JOBSDIR='{JOBSDIR}'
        SORCDIR='{SORCDIR}'
        SRC_DIR='{SRC_DIR}'
        PARMDIR='{PARMDIR}'
        MODULES_DIR='{MODULES_DIR}'
        EXECDIR='{EXECDIR}'
        FIXam='{FIXam}'
        FIXclim='{FIXclim}'
        FIXLAM='{FIXLAM}'
        FIXgsm='{FIXgsm}'
        FIXaer='{FIXaer}'
        FIXlut='{FIXlut}'
        COMROOT='{COMROOT}'
        COMOUT_BASEDIR='{COMOUT_BASEDIR}'
        TEMPLATE_DIR='{TEMPLATE_DIR}'
        VX_CONFIG_DIR='{VX_CONFIG_DIR}'
        METPLUS_CONF='{METPLUS_CONF}'
        MET_CONFIG='{MET_CONFIG}'
        UFS_WTHR_MDL_DIR='{UFS_WTHR_MDL_DIR}'
        UFS_UTILS_DIR='{UFS_UTILS_DIR}'
        SFC_CLIMO_INPUT_DIR='{SFC_CLIMO_INPUT_DIR}'
        TOPO_DIR='{TOPO_DIR}'
        UPP_DIR='{UPP_DIR}'
        
        EXPTDIR='{EXPTDIR}'
        LOGDIR='{LOGDIR}'
        CYCLE_BASEDIR='{CYCLE_BASEDIR}'
        GRID_DIR='{GRID_DIR}'
        OROG_DIR='{OROG_DIR}'
        SFC_CLIMO_DIR='{SFC_CLIMO_DIR}'
        
        NDIGITS_ENSMEM_NAMES='{NDIGITS_ENSMEM_NAMES}'
        ENSMEM_NAMES={list_to_str(ENSMEM_NAMES)}
        FV3_NML_ENSMEM_FPS={list_to_str(FV3_NML_ENSMEM_FPS)}
        #
        #-----------------------------------------------------------------------
        #
        # Files.
        #
        #-----------------------------------------------------------------------
        #
        GLOBAL_VAR_DEFNS_FP='{GLOBAL_VAR_DEFNS_FP}'
        
        DATA_TABLE_FN='{DATA_TABLE_FN}'
        DIAG_TABLE_FN='{DIAG_TABLE_FN}'
        FIELD_TABLE_FN='{FIELD_TABLE_FN}'
        MODEL_CONFIG_FN='{MODEL_CONFIG_FN}'
        NEMS_CONFIG_FN='{NEMS_CONFIG_FN}'

        DATA_TABLE_TMPL_FN='{DATA_TABLE_TMPL_FN}'
        DIAG_TABLE_TMPL_FN='{DIAG_TABLE_TMPL_FN}'
        FIELD_TABLE_TMPL_FN='{FIELD_TABLE_TMPL_FN}'
        MODEL_CONFIG_TMPL_FN='{MODEL_CONFIG_TMPL_FN}'
        NEMS_CONFIG_TMPL_FN='{NEMS_CONFIG_TMPL_FN}'
        
        DATA_TABLE_TMPL_FP='{DATA_TABLE_TMPL_FP}'
        DIAG_TABLE_TMPL_FP='{DIAG_TABLE_TMPL_FP}'
        FIELD_TABLE_TMPL_FP='{FIELD_TABLE_TMPL_FP}'
        FV3_NML_BASE_SUITE_FP='{FV3_NML_BASE_SUITE_FP}'
        FV3_NML_YAML_CONFIG_FP='{FV3_NML_YAML_CONFIG_FP}'
        FV3_NML_BASE_ENS_FP='{FV3_NML_BASE_ENS_FP}'
        MODEL_CONFIG_TMPL_FP='{MODEL_CONFIG_TMPL_FP}'
        NEMS_CONFIG_TMPL_FP='{NEMS_CONFIG_TMPL_FP}'
        
        CCPP_PHYS_SUITE_FN='{CCPP_PHYS_SUITE_FN}'
        CCPP_PHYS_SUITE_IN_CCPP_FP='{CCPP_PHYS_SUITE_IN_CCPP_FP}'
        CCPP_PHYS_SUITE_FP='{CCPP_PHYS_SUITE_FP}'
        
        FIELD_DICT_FN='{FIELD_DICT_FN}'
        FIELD_DICT_IN_UWM_FP='{FIELD_DICT_IN_UWM_FP}'
        FIELD_DICT_FP='{FIELD_DICT_FP}'
        
        DATA_TABLE_FP='{DATA_TABLE_FP}'
        FIELD_TABLE_FP='{FIELD_TABLE_FP}'
        FV3_NML_FN='{FV3_NML_FN}'   # This may not be necessary...
        FV3_NML_FP='{FV3_NML_FP}'
        NEMS_CONFIG_FP='{NEMS_CONFIG_FP}'
        
        FV3_EXEC_FP='{FV3_EXEC_FP}'
        
        LOAD_MODULES_RUN_TASK_FP='{LOAD_MODULES_RUN_TASK_FP}'
        
        THOMPSON_MP_CLIMO_FN='{THOMPSON_MP_CLIMO_FN}'
        THOMPSON_MP_CLIMO_FP='{THOMPSON_MP_CLIMO_FP}'
        #
        #-----------------------------------------------------------------------
        #
        # Flag for creating relative symlinks (as opposed to absolute ones).
        #
        #-----------------------------------------------------------------------
        #
        RELATIVE_LINK_FLAG='{RELATIVE_LINK_FLAG}'
        #
        #-----------------------------------------------------------------------
        #
        # Parameters that indicate whether or not various parameterizations are 
        # included in and called by the physics suite.
        #
        #-----------------------------------------------------------------------
        #
        SDF_USES_RUC_LSM='{type_to_str(SDF_USES_RUC_LSM)}'
        SDF_USES_THOMPSON_MP='{type_to_str(SDF_USES_THOMPSON_MP)}'
        #
        #-----------------------------------------------------------------------
        #
        # Grid configuration parameters needed regardless of grid generation
        # method used.
        #
        #-----------------------------------------------------------------------
        #
        GTYPE='{GTYPE}'
        TILE_RGNL='{TILE_RGNL}'
        NH0='{NH0}'
        NH3='{NH3}'
        NH4='{NH4}'
        
        LON_CTR='{LON_CTR}'
        LAT_CTR='{LAT_CTR}'
        NX='{NX}'
        NY='{NY}'
        NHW='{NHW}'
        STRETCH_FAC='{STRETCH_FAC}'
        
        RES_IN_FIXLAM_FILENAMES='{RES_IN_FIXLAM_FILENAMES}'
        #
        # If running the make_grid task, CRES will be set to a null string during
        # the grid generation step.  It will later be set to an actual value after
        # the make_grid task is complete.
        #
        CRES='{CRES}'"""
    with open(GLOBAL_VAR_DEFNS_FP,'a') as f:
        f.write(dedent(msg))
    #
    #-----------------------------------------------------------------------
    #
    # Append to the variable definitions file the defintions of grid parame-
    # ters that are specific to the grid generation method used.
    #
    #-----------------------------------------------------------------------
    #
    if GRID_GEN_METHOD == "GFDLgrid":
    
      msg=f"""
        #
        #-----------------------------------------------------------------------
        #
        # Grid configuration parameters for a regional grid generated from a
        # global parent cubed-sphere grid.  This is the method originally 
        # suggested by GFDL since it allows GFDL's nested grid generator to be 
        # used to generate a regional grid.  However, for large regional domains, 
        # it results in grids that have an unacceptably large range of cell sizes
        # (i.e. ratio of maximum to minimum cell size is not sufficiently close
        # to 1).
        #
        #-----------------------------------------------------------------------
        #
        ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG='{ISTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}'
        IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG='{IEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}'
        JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG='{JSTART_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}'
        JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG='{JEND_OF_RGNL_DOM_WITH_WIDE_HALO_ON_T6SG}'"""
      with open(GLOBAL_VAR_DEFNS_FP,'a') as f:
        f.write(dedent(msg))
    
    elif GRID_GEN_METHOD == "ESGgrid":
    
      msg=f"""
        #
        #-----------------------------------------------------------------------
        #
        # Grid configuration parameters for a regional grid generated independently 
        # of a global parent grid.  This method was developed by Jim Purser of 
        # EMC and results in very uniform grids (i.e. ratio of maximum to minimum 
        # cell size is very close to 1).
        #
        #-----------------------------------------------------------------------
        #
        DEL_ANGLE_X_SG='{DEL_ANGLE_X_SG}'
        DEL_ANGLE_Y_SG='{DEL_ANGLE_Y_SG}'
        NEG_NX_OF_DOM_WITH_WIDE_HALO='{NEG_NX_OF_DOM_WITH_WIDE_HALO}'
        NEG_NY_OF_DOM_WITH_WIDE_HALO='{NEG_NY_OF_DOM_WITH_WIDE_HALO}'
        PAZI='{PAZI or ''}'"""
      with open(GLOBAL_VAR_DEFNS_FP,'a') as f:
        f.write(dedent(msg))
    #
    #-----------------------------------------------------------------------
    #
    # Continue appending variable definitions to the variable definitions 
    # file.
    #
    #-----------------------------------------------------------------------
    #
    msg = f"""
        #
        #-----------------------------------------------------------------------
        #
        # Flag in the \"{MODEL_CONFIG_FN}\" file for coupling the ocean model to 
        # the weather model.
        #
        #-----------------------------------------------------------------------
        #
        CPL='{type_to_str(CPL)}'
        #
        #-----------------------------------------------------------------------
        #
        # Name of the ozone parameterization.  The value this gets set to depends 
        # on the CCPP physics suite being used.
        #
        #-----------------------------------------------------------------------
        #
        OZONE_PARAM='{OZONE_PARAM}'
        #
        #-----------------------------------------------------------------------
        #
        # If USE_USER_STAGED_EXTRN_FILES is set to \"FALSE\", this is the system 
        # directory in which the workflow scripts will look for the files generated 
        # by the external model specified in EXTRN_MDL_NAME_ICS.  These files will 
        # be used to generate the input initial condition and surface files for 
        # the FV3-LAM.
        #
        #-----------------------------------------------------------------------
        #
        EXTRN_MDL_SYSBASEDIR_ICS='{EXTRN_MDL_SYSBASEDIR_ICS}'
        #
        #-----------------------------------------------------------------------
        #
        # If USE_USER_STAGED_EXTRN_FILES is set to \"FALSE\", this is the system 
        # directory in which the workflow scripts will look for the files generated 
        # by the external model specified in EXTRN_MDL_NAME_LBCS.  These files 
        # will be used to generate the input lateral boundary condition files for 
        # the FV3-LAM.
        #
        #-----------------------------------------------------------------------
        #
        EXTRN_MDL_SYSBASEDIR_LBCS='{EXTRN_MDL_SYSBASEDIR_LBCS}'
        #
        #-----------------------------------------------------------------------
        #
        # Shift back in time (in units of hours) of the starting time of the ex-
        # ternal model specified in EXTRN_MDL_NAME_LBCS.
        #
        #-----------------------------------------------------------------------
        #
        EXTRN_MDL_LBCS_OFFSET_HRS='{EXTRN_MDL_LBCS_OFFSET_HRS}'
        #
        #-----------------------------------------------------------------------
        #
        # Boundary condition update times (in units of forecast hours).  Note that
        # LBC_SPEC_FCST_HRS is an array, even if it has only one element.
        #
        #-----------------------------------------------------------------------
        #
        LBC_SPEC_FCST_HRS={list_to_str(LBC_SPEC_FCST_HRS)}
        #
        #-----------------------------------------------------------------------
        #
        # The number of cycles for which to make forecasts and the list of 
        # starting dates/hours of these cycles.
        #
        #-----------------------------------------------------------------------
        #
        NUM_CYCLES='{NUM_CYCLES}'
        ALL_CDATES={list_to_str(ALL_CDATES)}
        #
        #-----------------------------------------------------------------------
        #
        # Parameters that determine whether FVCOM data will be used, and if so, 
        # their location.
        #
        # If USE_FVCOM is set to \"TRUE\", then FVCOM data (in the file FVCOM_FILE
        # located in the directory FVCOM_DIR) will be used to update the surface 
        # boundary conditions during the initial conditions generation task 
        # (MAKE_ICS_TN).
        #
        #-----------------------------------------------------------------------
        #
        USE_FVCOM='{type_to_str(USE_FVCOM)}'
        FVCOM_DIR='{FVCOM_DIR}'
        FVCOM_FILE='{FVCOM_FILE}'
        #
        #-----------------------------------------------------------------------
        #
        # Computational parameters.
        #
        #-----------------------------------------------------------------------
        #
        NCORES_PER_NODE='{NCORES_PER_NODE}'
        PE_MEMBER01='{PE_MEMBER01}'
        #
        #-----------------------------------------------------------------------
        #
        # IF DO_SPP is set to "TRUE", N_VAR_SPP specifies the number of physics 
        # parameterizations that are perturbed with SPP.  If DO_LSM_SPP is set to
        # "TRUE", N_VAR_LNDP specifies the number of LSM parameters that are 
        # perturbed.  LNDP_TYPE determines the way LSM perturbations are employed
        # and FHCYC_LSM_SPP_OR_NOT sets FHCYC based on whether LSM perturbations
        # are turned on or not.
        #
        #-----------------------------------------------------------------------
        #
        N_VAR_SPP='{N_VAR_SPP}'
        N_VAR_LNDP='{N_VAR_LNDP}'
        LNDP_TYPE='{LNDP_TYPE}'
        FHCYC_LSM_SPP_OR_NOT='{FHCYC_LSM_SPP_OR_NOT}'
        """

    with open(GLOBAL_VAR_DEFNS_FP,'a') as f:
      f.write(dedent(msg))

    # export all vars
    export_vars()

    #
    #-----------------------------------------------------------------------
    #
    # Check validity of parameters in one place, here in the end.
    #
    #-----------------------------------------------------------------------
    #

    # update dictionary with globals() values
    update_dict = {k: globals()[k] for k in cfg_d.keys() if k in globals() }
    cfg_d.update(update_dict)

    # loop through cfg_d and check validity of params
    cfg_v = load_config_file("valid_param_vals.yaml")
    for k,v in cfg_d.items():
        if v == None:
            continue
        vkey = 'valid_vals_' + k
        if (vkey in cfg_v) and not (v in cfg_v[vkey]):
            print_err_msg_exit(f'''
                The variable {k}={v} in {EXPT_DEFAULT_CONFIG_FN} or {EXPT_CONFIG_FN} does not have
                a valid value. Possible values are:
                    {k} = {cfg_v[vkey]}''')

    #
    #-----------------------------------------------------------------------
    #
    # Print message indicating successful completion of script.
    #
    #-----------------------------------------------------------------------
    #
    print_info_msg(f'''
        ========================================================================
        Function setup() in \"{os.path.basename(__file__)}\" completed successfully!!!
        ========================================================================''')
    
#
#-----------------------------------------------------------------------
#
# Call the function defined above.
#
#-----------------------------------------------------------------------
#
if __name__ == "__main__":
    setup()

