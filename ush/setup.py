#!/usr/bin/env python3

import os
import sys
import datetime
import traceback
from textwrap import dedent
from logging import getLogger

from python_utils import (
    log_info,
    cd_vrfy,
    mkdir_vrfy,
    rm_vrfy,
    check_var_valid_value,
    lowercase,
    uppercase,
    check_for_preexist_dir_file,
    flatten_dict,
    update_dict,
    import_vars,
    get_env_var,
    load_config_file,
    cfg_to_shell_str,
    cfg_to_yaml_str,
    load_shell_config,
    load_ini_config,
    get_ini_value,
)

from set_cycle_dates import set_cycle_dates
from set_predef_grid_params import set_predef_grid_params
from set_ozone_param import set_ozone_param
from set_gridparams_ESGgrid import set_gridparams_ESGgrid
from set_gridparams_GFDLgrid import set_gridparams_GFDLgrid
from link_fix import link_fix
from check_ruc_lsm import check_ruc_lsm
from set_thompson_mp_fix_files import set_thompson_mp_fix_files


def setup():
    """Function that sets a secondary set
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
      Dictionary of settings
    """

    logger = getLogger(__name__)
    global USHdir
    USHdir = os.path.dirname(os.path.abspath(__file__))
    cd_vrfy(USHdir)

    # print message
    log_info(
        f"""
        ========================================================================
        Starting function setup() in '{os.path.basename(__file__)}'...
        ========================================================================"""
    )
    #
    # -----------------------------------------------------------------------
    #
    # Step-1 of config
    # ================
    # Load the configuration file containing default values for the experiment.
    #
    # -----------------------------------------------------------------------
    #
    EXPT_DEFAULT_CONFIG_FN = "config_defaults.yaml"
    cfg_d = load_config_file(os.path.join(USHdir, EXPT_DEFAULT_CONFIG_FN))
    import_vars(
        dictionary=flatten_dict(cfg_d),
        env_vars=[
            "EXPT_CONFIG_FN",
            "EXTRN_MDL_NAME_ICS",
            "EXTRN_MDL_NAME_LBCS",
            "FV3GFS_FILE_FMT_ICS",
            "FV3GFS_FILE_FMT_LBCS",
        ],
    )

    # Load the user config file, then ensure all user-specified
    # variables correspond to a default value.
    if not os.path.exists(EXPT_CONFIG_FN):
        raise FileNotFoundError(
            f"User config file not found: EXPT_CONFIG_FN = {EXPT_CONFIG_FN}"
        )

    try:
        cfg_u = load_config_file(os.path.join(USHdir, EXPT_CONFIG_FN))
    except:
        errmsg = dedent(
            f"""\n
            Could not load YAML config file:  {EXPT_CONFIG_FN}
            Reference the above traceback for more information.
            """
        )
        raise Exception(errmsg)

    cfg_u = flatten_dict(cfg_u)
    for key in cfg_u:
        if key not in flatten_dict(cfg_d):
            raise Exception(
                dedent(
                    f"""
                    User-specified variable "{key}" in {EXPT_CONFIG_FN} is not valid.
                    Check {EXPT_DEFAULT_CONFIG_FN} for allowed user-specified variables.\n"""
                )
            )

    # Mandatory variables *must* be set in the user's config; the default value is invalid
    mandatory = ["MACHINE"]
    for val in mandatory:
        if val not in cfg_u:
            raise Exception(
                f"Mandatory variable '{val}' not found in user config file {EXPT_CONFIG_FN}"
            )

    import_vars(
        dictionary=cfg_u,
        env_vars=[
            "MACHINE",
            "EXTRN_MDL_NAME_ICS",
            "EXTRN_MDL_NAME_LBCS",
            "FV3GFS_FILE_FMT_ICS",
            "FV3GFS_FILE_FMT_LBCS",
        ],
    )
    #
    # -----------------------------------------------------------------------
    #
    # Step-2 of config
    # ================
    # Source machine specific config file to set default values
    #
    # -----------------------------------------------------------------------
    #
    global MACHINE, EXTRN_MDL_SYSBASEDIR_ICS, EXTRN_MDL_SYSBASEDIR_LBCS
    MACHINE_FILE = os.path.join(USHdir, "machine", f"{lowercase(MACHINE)}.yaml")
    if not os.path.exists(MACHINE_FILE):
        raise FileNotFoundError(
            dedent(
                f"""
                The machine file {MACHINE_FILE} does not exist.
                Check that you have specified the correct machine ({MACHINE}) in your config file {EXPT_CONFIG_FN}"""
            )
        )
    machine_cfg = load_config_file(MACHINE_FILE)

    # ics and lbcs
    def get_location(xcs, fmt):
        if ("data" in machine_cfg) and (xcs in machine_cfg["data"]):
            v = machine_cfg["data"][xcs]
            if not isinstance(v, dict):
                return v
            else:
                return v[fmt]
        else:
            return ""

    EXTRN_MDL_SYSBASEDIR_ICS = get_location(EXTRN_MDL_NAME_ICS, FV3GFS_FILE_FMT_ICS)
    EXTRN_MDL_SYSBASEDIR_LBCS = get_location(EXTRN_MDL_NAME_LBCS, FV3GFS_FILE_FMT_LBCS)

    # remove the data key and provide machine specific default values for cfg_d
    if "data" in machine_cfg:
        machine_cfg.pop("data")
    machine_cfg.update(
        {
            "EXTRN_MDL_SYSBASEDIR_ICS": EXTRN_MDL_SYSBASEDIR_ICS,
            "EXTRN_MDL_SYSBASEDIR_LBCS": EXTRN_MDL_SYSBASEDIR_LBCS,
        }
    )
    machine_cfg = flatten_dict(machine_cfg)
    update_dict(machine_cfg, cfg_d)

    #
    # -----------------------------------------------------------------------
    #
    # Step-3 of config
    # ================
    # Source user config. This overrides previous two configs
    #
    # -----------------------------------------------------------------------
    #
    update_dict(cfg_u, cfg_d)

    # Now that all 3 config files have their contribution in cfg_d
    # import its content to python globals()
    import_vars(dictionary=flatten_dict(cfg_d))

    # make machine name uppercase
    MACHINE = uppercase(MACHINE)

    # Load fixed-files mapping file
    cfg_f = load_config_file(
        os.path.join(USHdir, os.pardir, "parm", "fixed_files_mapping.yaml")
    )
    import_vars(dictionary=flatten_dict(cfg_f))
    cfg_d.update(cfg_f)

    # Load constants file and save its contents to a variable for later
    cfg_c = load_config_file(os.path.join(USHdir, CONSTANTS_FN))
    import_vars(dictionary=flatten_dict(cfg_c))
    cfg_d.update(cfg_c)

    #
    # -----------------------------------------------------------------------
    #
    # Generate a unique number for this workflow run. This may be used to
    # get unique log file names for example
    #
    # -----------------------------------------------------------------------
    #
    global WORKFLOW_ID
    WORKFLOW_ID = "id_" + str(int(datetime.datetime.now().timestamp()))
    cfg_d["workflow"]["WORKFLOW_ID"] = WORKFLOW_ID
    log_info(f"""WORKFLOW ID = {WORKFLOW_ID}""")

    #
    # -----------------------------------------------------------------------
    #
    # If PREDEF_GRID_NAME is set to a non-empty string, set or reset parameters
    # according to the predefined domain specified.
    #
    # -----------------------------------------------------------------------
    #

    if PREDEF_GRID_NAME:
        params_dict = set_predef_grid_params(
            PREDEF_GRID_NAME,
            QUILTING,
            DT_ATMOS,
            LAYOUT_X,
            LAYOUT_Y,
            BLOCKSIZE,
        )
        import_vars(dictionary=params_dict)

    #
    # -----------------------------------------------------------------------
    #
    # Make sure different variables are set to their corresponding valid value
    #
    # -----------------------------------------------------------------------
    #
    global VERBOSE
    if DEBUG and not VERBOSE:
        log_info(
            """
            Resetting VERBOSE to 'TRUE' because DEBUG has been set to 'TRUE'..."""
        )
        VERBOSE = True

    #
    # -----------------------------------------------------------------------
    #
    # Set magnitude of stochastic ad-hoc schemes to -999.0 if they are not
    # being used. This is required at the moment, since "do_shum/sppt/skeb"
    # does not override the use of the scheme unless the magnitude is also
    # specifically set to -999.0.  If all "do_shum/sppt/skeb" are set to
    # "false," then none will run, regardless of the magnitude values.
    #
    # -----------------------------------------------------------------------
    #
    global SHUM_MAG, SKEB_MAG, SPPT_MAG
    if not DO_SHUM:
        SHUM_MAG = -999.0
    if not DO_SKEB:
        SKEB_MAG = -999.0
    if not DO_SPPT:
        SPPT_MAG = -999.0
    #
    # -----------------------------------------------------------------------
    #
    # If running with SPP in MYNN PBL, MYNN SFC, GSL GWD, Thompson MP, or
    # RRTMG, count the number of entries in SPP_VAR_LIST to correctly set
    # N_VAR_SPP, otherwise set it to zero.
    #
    # -----------------------------------------------------------------------
    #
    global N_VAR_SPP
    N_VAR_SPP = 0
    if DO_SPP:
        N_VAR_SPP = len(SPP_VAR_LIST)
    #
    # -----------------------------------------------------------------------
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
    # -----------------------------------------------------------------------
    #
    global N_VAR_LNDP, LNDP_TYPE, LNDP_MODEL_TYPE, FHCYC_LSM_SPP_OR_NOT
    N_VAR_LNDP = 0
    LNDP_TYPE = 0
    LNDP_MODEL_TYPE = 0
    FHCYC_LSM_SPP_OR_NOT = 0
    if DO_LSM_SPP:
        N_VAR_LNDP = len(LSM_SPP_VAR_LIST)
        LNDP_TYPE = 2
        LNDP_MODEL_TYPE = 2
        FHCYC_LSM_SPP_OR_NOT = 999
    #
    # -----------------------------------------------------------------------
    #
    # If running with SPP, confirm that each SPP-related namelist value
    # contains the same number of entries as N_VAR_SPP (set above to be equal
    # to the number of entries in SPP_VAR_LIST).
    #
    # -----------------------------------------------------------------------
    #
    if DO_SPP:
        if (
            (len(SPP_MAG_LIST) != N_VAR_SPP)
            or (len(SPP_LSCALE) != N_VAR_SPP)
            or (len(SPP_TSCALE) != N_VAR_SPP)
            or (len(SPP_SIGTOP1) != N_VAR_SPP)
            or (len(SPP_SIGTOP2) != N_VAR_SPP)
            or (len(SPP_STDDEV_CUTOFF) != N_VAR_SPP)
            or (len(ISEED_SPP) != N_VAR_SPP)
        ):
            raise Exception(
                f"""
                All MYNN PBL, MYNN SFC, GSL GWD, Thompson MP, or RRTMG SPP-related namelist
                variables set in {EXPT_CONFIG_FN} must be equal in number of entries to what is
                found in SPP_VAR_LIST:
                  SPP_VAR_LIST (length {len(SPP_VAR_LIST)})
                  SPP_MAG_LIST (length {len(SPP_MAG_LIST)})
                  SPP_LSCALE (length {len(SPP_LSCALE)})
                  SPP_TSCALE (length {len(SPP_TSCALE)})
                  SPP_SIGTOP1 (length {len(SPP_SIGTOP1)})
                  SPP_SIGTOP2 (length {len(SPP_SIGTOP2)})
                  SPP_STDDEV_CUTOFF (length {len(SPP_STDDEV_CUTOFF)})
                  ISEED_SPP (length {len(ISEED_SPP)})
                """
            )
    #
    # -----------------------------------------------------------------------
    #
    # If running with LSM SPP, confirm that each LSM SPP-related namelist
    # value contains the same number of entries as N_VAR_LNDP (set above to
    # be equal to the number of entries in LSM_SPP_VAR_LIST).
    #
    # -----------------------------------------------------------------------
    #
    if DO_LSM_SPP:
        if (
            (len(LSM_SPP_MAG_LIST) != N_VAR_LNDP)
            or (len(LSM_SPP_LSCALE) != N_VAR_LNDP)
            or (len(LSM_SPP_TSCALE) != N_VAR_LNDP)
        ):
            raise Exception(
                f"""
                All Noah or RUC-LSM SPP-related namelist variables (except ISEED_LSM_SPP)
                set in {EXPT_CONFIG_FN} must be equal in number of entries to what is found in
                SPP_VAR_LIST:
                  LSM_SPP_VAR_LIST (length {len(LSM_SPP_VAR_LIST)})
                  LSM_SPP_MAG_LIST (length {len(LSM_SPP_MAG_LIST)})
                  LSM_SPP_LSCALE (length {len(LSM_SPP_LSCALE)})
                  LSM_SPP_TSCALE (length {len(LSM_SPP_TSCALE)})
                """
            )
    #
    # The current script should be located in the ush subdirectory of the
    # workflow directory.  Thus, the workflow directory is the one above the
    # directory of the current script.
    #
    HOMEdir = os.path.abspath(os.path.dirname(__file__) + os.sep + os.pardir)

    #
    # -----------------------------------------------------------------------
    #
    # Set the base directories in which codes obtained from external reposi-
    # tories (using the manage_externals tool) are placed.  Obtain the rela-
    # tive paths to these directories by reading them in from the manage_ex-
    # ternals configuration file.  (Note that these are relative to the lo-
    # cation of the configuration file.)  Then form the full paths to these
    # directories.  Finally, make sure that each of these directories actu-
    # ally exists.
    #
    # -----------------------------------------------------------------------
    #
    mng_extrns_cfg_fn = os.path.join(HOMEdir, "Externals.cfg")
    try:
        mng_extrns_cfg_fn = os.readlink(mng_extrns_cfg_fn)
    except:
        pass
    cfg = load_ini_config(mng_extrns_cfg_fn)

    #
    # Get the base directory of the FV3 forecast model code.
    #
    external_name = FCST_MODEL
    property_name = "local_path"

    try:
        UFS_WTHR_MDL_DIR = get_ini_value(cfg, external_name, property_name)
    except KeyError:
        errmsg = dedent(
            f"""
            Externals configuration file {mng_extrns_cfg_fn}
            does not contain '{external_name}'."""
        )
        raise Exception(errmsg) from None

    UFS_WTHR_MDL_DIR = os.path.join(HOMEdir, UFS_WTHR_MDL_DIR)
    if not os.path.exists(UFS_WTHR_MDL_DIR):
        raise FileNotFoundError(
            dedent(
                f"""
                The base directory in which the FV3 source code should be located
                (UFS_WTHR_MDL_DIR) does not exist:
                  UFS_WTHR_MDL_DIR = '{UFS_WTHR_MDL_DIR}'
                Please clone the external repository containing the code in this directory,
                build the executable, and then rerun the workflow."""
            )
        )
    #
    # Define some other useful paths
    #
    global SCRIPTSdir, JOBSdir, SORCdir, PARMdir, MODULESdir
    global EXECdir, PARMdir, FIXdir, VX_CONFIG_DIR, METPLUS_CONF, MET_CONFIG, ARL_NEXUS_DIR

    SCRIPTSdir = os.path.join(HOMEdir, "scripts")
    JOBSdir = os.path.join(HOMEdir, "jobs")
    SORCdir = os.path.join(HOMEdir, "sorc")
    PARMdir = os.path.join(HOMEdir, "parm")
    MODULESdir = os.path.join(HOMEdir, "modulefiles")
    EXECdir = os.path.join(HOMEdir, EXEC_SUBDIR)
    VX_CONFIG_DIR = PARMdir
    METPLUS_CONF = os.path.join(PARMdir, "metplus")
    MET_CONFIG = os.path.join(PARMdir, "met")
    ARL_NEXUS_DIR = os.path.join(HOMEdir, "sorc/arl_nexus")

    #
    # -----------------------------------------------------------------------
    #
    # Source the machine config file containing architechture information,
    # queue names, and supported input file paths.
    #
    # -----------------------------------------------------------------------
    #
    global FIXgsm, FIXaer, FIXlut, TOPO_DIR, SFC_CLIMO_INPUT_DIR, DOMAIN_PREGEN_BASEDIR
    global RELATIVE_LINK_FLAG, WORKFLOW_MANAGER, NCORES_PER_NODE, SCHED, QUEUE_DEFAULT
    global QUEUE_HPSS, QUEUE_FCST, PARTITION_DEFAULT, PARTITION_HPSS, PARTITION_FCST

    RELATIVE_LINK_FLAG = "--relative"

    # Mandatory variables *must* be set in the user's config or the machine file; the default value is invalid
    mandatory = [
        "NCORES_PER_NODE",
        "FIXgsm",
        "FIXaer",
        "FIXlut",
        "TOPO_DIR",
        "SFC_CLIMO_INPUT_DIR",
    ]
    globalvars = globals()
    for val in mandatory:
        # globals() returns dictionary of global variables
        if not globalvars[val]:
            raise Exception(
                dedent(
                    f"""
                    Mandatory variable '{val}' not found in:
                    user config file {EXPT_CONFIG_FN}
                                  OR
                    machine file {MACHINE_FILE} 
                    """
                )
            )

    #
    # -----------------------------------------------------------------------
    #
    # Set the names of the build and workflow module files (if not
    # already specified by the user).  These are the files that need to be
    # sourced before building the component SRW App codes and running various
    # workflow scripts, respectively.
    #
    # -----------------------------------------------------------------------
    #
    global WFLOW_MOD_FN, BUILD_MOD_FN, BUILD_VER_FN, RUN_VER_FN
    machine = lowercase(MACHINE)
    WFLOW_MOD_FN = WFLOW_MOD_FN or f"wflow_{machine}"
    BUILD_MOD_FN = BUILD_MOD_FN or f"build_{machine}_{COMPILER}"
    BUILD_VER_FN = BUILD_VER_FN or f"build.ver.{machine}"
    RUN_VER_FN = RUN_VER_FN or f"run.ver.{machine}"
    #
    # -----------------------------------------------------------------------
    #
    # Calculate a default value for the number of processes per node for the
    # RUN_FCST_TN task.  Then set PPN_RUN_FCST to this default value if
    # PPN_RUN_FCST is not already specified by the user.
    #
    # -----------------------------------------------------------------------
    #
    global PPN_RUN_FCST, PPN_NEXUS_EMISSION, PPN_POINT_SOURCE
    ppn_run_fcst_default = NCORES_PER_NODE // OMP_NUM_THREADS_RUN_FCST
    PPN_RUN_FCST = PPN_RUN_FCST or ppn_run_fcst_default

    ppn_nexus_emission_default = NCORES_PER_NODE // OMP_NUM_THREADS_NEXUS_EMISSION
    PPN_NEXUS_EMISSION = PPN_NEXUS_EMISSION or ppn_nexus_emission_default

    ppn_point_source_default = NCORES_PER_NODE // OMP_NUM_THREADS_POINT_SOURCE
    PPN_POINT_SOURCE = PPN_POINT_SOURCE or ppn_point_source_default
    #
    # -----------------------------------------------------------------------
    #
    # If we are using a workflow manager check that the ACCOUNT variable is
    # not empty.
    #
    # -----------------------------------------------------------------------
    #
    if WORKFLOW_MANAGER is not None:
        if not ACCOUNT:
            raise Exception(
                dedent(
                    f"""
                    ACCOUNT must be specified in config or machine file if using a workflow manager.
                    WORKFLOW_MANAGER = {WORKFLOW_MANAGER}\n"""
                )
            )
    #
    # -----------------------------------------------------------------------
    #
    # Set the grid type (GTYPE).  In general, in the FV3 code, this can take
    # on one of the following values: "global", "stretch", "nest", and "re-
    # gional".  The first three values are for various configurations of a
    # global grid, while the last one is for a regional grid.  Since here we
    # are only interested in a regional grid, GTYPE must be set to "region-
    # al".
    #
    # -----------------------------------------------------------------------
    #
    global TILE_RGNL, GTYPE
    GTYPE = "regional"
    TILE_RGNL = "7"

    # USE_MERRA_CLIMO must be True for the physics suite FV3_GFS_v15_thompson_mynn_lam3km"
    global USE_MERRA_CLIMO
    if CCPP_PHYS_SUITE == "FV3_GFS_v15_thompson_mynn_lam3km":
        USE_MERRA_CLIMO = True

    # Make sure RESTART_INTERVAL is set to an integer value

    if not isinstance(RESTART_INTERVAL, int):
        raise Exception(
            f"\nRESTART_INTERVAL = {RESTART_INTERVAL}, must be an integer value\n"
        )

    # Check that input dates are in a date format
    # get dictionary of all variables
    allvars = dict(globals())
    allvars.update(locals())
    dates = ["DATE_FIRST_CYCL", "DATE_LAST_CYCL"]
    for val in dates:
        if not isinstance(allvars[val], datetime.date):
            raise Exception(
                dedent(
                    f"""
                    Date variable {val}={allvars[val]} is not in a valid date format

                    For examples of valid formats, see the users guide.
                    """
                )
            )

    # If using a custom post configuration file, make sure that it exists.
    if USE_CUSTOM_POST_CONFIG_FILE:
        try:
            # os.path.exists returns exception if passed an empty string or None, so use "try/except" as a 2-for-1 error catch
            if not os.path.exists(CUSTOM_POST_CONFIG_FP):
                raise
        except:
            raise FileNotFoundError(
                dedent(
                    f"""
                    USE_CUSTOM_POST_CONFIG_FILE has been set, but the custom post configuration file
                    CUSTOM_POST_CONFIG_FP = {CUSTOM_POST_CONFIG_FP}
                    could not be found."""
                )
            ) from None

    # If using external CRTM fix files to allow post-processing of synthetic
    # satellite products from the UPP, make sure the CRTM fix file directory exists.
    if USE_CRTM:
        try:
            # os.path.exists returns exception if passed an empty string or None, so use "try/except" as a 2-for-1 error catch
            if not os.path.exists(CRTM_DIR):
                raise
        except:
            raise FileNotFoundError(
                dedent(
                    f"""
                    USE_CRTM has been set, but the external CRTM fix file directory:
                    CRTM_DIR = {CRTM_DIR}
                    could not be found."""
                )
            ) from None

    # The forecast length (in integer hours) cannot contain more than 3 characters.
    # Thus, its maximum value is 999.
    fcst_len_hrs_max = 999
    if FCST_LEN_HRS > fcst_len_hrs_max:
        raise ValueError(
            f"""
            Forecast length is greater than maximum allowed length:
              FCST_LEN_HRS = {FCST_LEN_HRS}
              fcst_len_hrs_max = {fcst_len_hrs_max}"""
        )
    #
    # -----------------------------------------------------------------------
    #
    # Check whether the forecast length (FCST_LEN_HRS) is evenly divisible
    # by the BC update interval (LBC_SPEC_INTVL_HRS). If so, generate an
    # array of forecast hours at which the boundary values will be updated.
    #
    # -----------------------------------------------------------------------
    #
    rem = FCST_LEN_HRS % LBC_SPEC_INTVL_HRS

    if rem != 0:
        raise Exception(
            f"""
            The forecast length (FCST_LEN_HRS) is not evenly divisible by the lateral
            boundary conditions update interval (LBC_SPEC_INTVL_HRS):
              FCST_LEN_HRS = {FCST_LEN_HRS}
              LBC_SPEC_INTVL_HRS = {LBC_SPEC_INTVL_HRS}
              rem = FCST_LEN_HRS%%LBC_SPEC_INTVL_HRS = {rem}"""
        )
    #
    # -----------------------------------------------------------------------
    #
    # Set the array containing the forecast hours at which the lateral
    # boundary conditions (LBCs) need to be updated.  Note that this array
    # does not include the 0-th hour (initial time).
    #
    # -----------------------------------------------------------------------
    #
    global LBC_SPEC_FCST_HRS
    LBC_SPEC_FCST_HRS = [
        i
        for i in range(
            LBC_SPEC_INTVL_HRS, LBC_SPEC_INTVL_HRS + FCST_LEN_HRS, LBC_SPEC_INTVL_HRS
        )
    ]
    cfg_d["task_make_lbcs"]["LBC_SPEC_FCST_HRS"] = LBC_SPEC_FCST_HRS
    #
    # -----------------------------------------------------------------------
    #
    # Check to make sure that various computational parameters needed by the
    # forecast model are set to non-empty values.  At this point in the
    # experiment generation, all of these should be set to valid (non-empty)
    # values.
    #
    # -----------------------------------------------------------------------
    #
    # get dictionary of all variables
    allvars = dict(globals())
    allvars.update(locals())
    vlist = ["DT_ATMOS", "LAYOUT_X", "LAYOUT_Y", "BLOCKSIZE", "EXPT_SUBDIR"]
    for val in vlist:
        if not allvars[val]:
            raise Exception(f"\nMandatory variable '{val}' has not been set\n")

    #
    # -----------------------------------------------------------------------
    #
    # If performing sub-hourly model output and post-processing, check that
    # the output interval DT_SUBHOURLY_POST_MNTS (in minutes) is specified
    # correctly.
    #
    # -----------------------------------------------------------------------
    #
    global SUB_HOURLY_POST

    if SUB_HOURLY_POST:
        #
        # Check that DT_SUBHOURLY_POST_MNTS is between 0 and 59, inclusive.
        #
        if DT_SUBHOURLY_POST_MNTS < 0 or DT_SUBHOURLY_POST_MNTS > 59:
            raise ValueError(
                f"""
                When performing sub-hourly post (i.e. SUB_HOURLY_POST set to 'TRUE'),
                DT_SUBHOURLY_POST_MNTS must be set to an integer between 0 and 59,
                inclusive but in this case is not:
                  SUB_HOURLY_POST = '{SUB_HOURLY_POST}'
                  DT_SUBHOURLY_POST_MNTS = '{DT_SUBHOURLY_POST_MNTS}'"""
            )
        #
        # Check that DT_SUBHOURLY_POST_MNTS (after converting to seconds) is
        # evenly divisible by the forecast model's main time step DT_ATMOS.
        #
        rem = DT_SUBHOURLY_POST_MNTS * 60 % DT_ATMOS
        if rem != 0:
            raise ValueError(
                f"""
                When performing sub-hourly post (i.e. SUB_HOURLY_POST set to 'TRUE'),
                the time interval specified by DT_SUBHOURLY_POST_MNTS (after converting
                to seconds) must be evenly divisible by the time step DT_ATMOS used in
                the forecast model, i.e. the remainder (rem) must be zero.  In this case,
                it is not:
                  SUB_HOURLY_POST = '{SUB_HOURLY_POST}'
                  DT_SUBHOURLY_POST_MNTS = '{DT_SUBHOURLY_POST_MNTS}'
                  DT_ATMOS = '{DT_ATMOS}'
                  rem = (DT_SUBHOURLY_POST_MNTS*60) %% DT_ATMOS = {rem}
                Please reset DT_SUBHOURLY_POST_MNTS and/or DT_ATMOS so that this remainder
                is zero."""
            )
        #
        # If DT_SUBHOURLY_POST_MNTS is set to 0 (with SUB_HOURLY_POST set to
        # True), then we're not really performing subhourly post-processing.
        # In this case, reset SUB_HOURLY_POST to False and print out an
        # informational message that such a change was made.
        #
        if DT_SUBHOURLY_POST_MNTS == 0:
            logger.warning(
                f"""
                When performing sub-hourly post (i.e. SUB_HOURLY_POST set to 'TRUE'),
                DT_SUBHOURLY_POST_MNTS must be set to a value greater than 0; otherwise,
                sub-hourly output is not really being performed:
                  SUB_HOURLY_POST = '{SUB_HOURLY_POST}'
                  DT_SUBHOURLY_POST_MNTS = '{DT_SUBHOURLY_POST_MNTS}'
                Resetting SUB_HOURLY_POST to 'FALSE'.  If you do not want this, you
                must set DT_SUBHOURLY_POST_MNTS to something other than zero."""
            )
            SUB_HOURLY_POST = False
    #
    # -----------------------------------------------------------------------
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
    # -----------------------------------------------------------------------
    #
    global EXPT_BASEDIR
    if (not EXPT_BASEDIR) or (EXPT_BASEDIR[0] != "/"):
        if not EXPT_BASEDIR:
            EXPT_BASEDIR = ""
        EXPT_BASEDIR = os.path.join(HOMEdir, "..", "expt_dirs", EXPT_BASEDIR)
    try:
        EXPT_BASEDIR = os.path.realpath(EXPT_BASEDIR)
    except:
        pass
    EXPT_BASEDIR = os.path.abspath(EXPT_BASEDIR)

    mkdir_vrfy(f" -p '{EXPT_BASEDIR}'")

    #
    # -----------------------------------------------------------------------
    #
    # Set the full path to the experiment directory.  Then check if it already
    # exists and if so, deal with it as specified by PREEXISTING_DIR_METHOD.
    #
    # -----------------------------------------------------------------------
    #
    global EXPTDIR
    EXPTDIR = os.path.join(EXPT_BASEDIR, EXPT_SUBDIR)
    try:
        check_for_preexist_dir_file(EXPTDIR, PREEXISTING_DIR_METHOD)
    except ValueError:
        logger.exception(
            f"""
            Check that the following values are valid:
            EXPTDIR {EXPTDIR}
            PREEXISTING_DIR_METHOD {PREEXISTING_DIR_METHOD}
            """
        )
        raise
    except FileExistsError:
        errmsg = dedent(
            f"""
            EXPTDIR ({EXPTDIR}) already exists, and PREEXISTING_DIR_METHOD = {PREEXISTING_DIR_METHOD}

            To ignore this error, delete the directory, or set 
            PREEXISTING_DIR_METHOD = delete, or
            PREEXISTING_DIR_METHOD = rename
            in your config file.
            """
        )
        raise FileExistsError(errmsg) from None
    #
    # -----------------------------------------------------------------------
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
    # FIXlam:
    # This is the directory that will contain the fixed files or symlinks to
    # the fixed files containing the grid, orography, and surface climatology
    # on the native FV3-LAM grid.
    #
    # POST_OUTPUT_DOMAIN_NAME:
    # The PREDEF_GRID_NAME is set by default.
    #
    # -----------------------------------------------------------------------
    #
    global LOGDIR, FIXam, FIXclim, FIXlam
    global POST_OUTPUT_DOMAIN_NAME
    global COMIN_BASEDIR, COMOUT_BASEDIR

    global OPSROOT, COMROOT, PACKAGEROOT, DATAROOT, DCOMROOT, DBNROOT, EXTROOT
    global SENDECF, SENDDBN, SENDDBN_NTC, SENDCOM, SENDWEB
    global KEEPDATA, MAILTO, MAILCC

    # Stuff to import from parent shell environment
    IMPORTS = [
        "OPSROOT",
        "COMROOT",
        "PACKAGEROOT",
        "DATAROOT",
        "DCOMROOT",
        "DBNROOT",
        "SENDECF",
        "SENDDBN",
        "SENDDBN_NTC",
        "SENDCOM",
        "SENDWEB",
        "KEEPDATA",
        "MAILTO",
        "MAILCC",
    ]
    import_vars(env_vars=IMPORTS)

    # Main directory locations
    if RUN_ENVIR == "nco":

        OPSROOT = (
            os.path.abspath(f"{EXPT_BASEDIR}{os.sep}..{os.sep}nco_dirs")
            if OPSROOT is None
            else OPSROOT
        )
        if COMROOT is None:
            COMROOT = os.path.join(OPSROOT, "com")
        if PACKAGEROOT is None:
            PACKAGEROOT = os.path.join(OPSROOT, "packages")
        if DATAROOT is None:
            DATAROOT = os.path.join(OPSROOT, "tmp")
        if DCOMROOT is None:
            DCOMROOT = os.path.join(OPSROOT, "dcom")
        EXTROOT = os.path.join(OPSROOT, "ext")

        COMIN_BASEDIR = os.path.join(COMROOT, NET, model_ver)
        COMOUT_BASEDIR = os.path.join(COMROOT, NET, model_ver)

        LOGDIR = os.path.join(OPSROOT, "output")

    else:

        COMIN_BASEDIR = EXPTDIR
        COMOUT_BASEDIR = EXPTDIR
        OPSROOT = EXPTDIR
        COMROOT = EXPTDIR
        PACKAGEROOT = EXPTDIR
        DATAROOT = EXPTDIR
        DCOMROOT = EXPTDIR
        EXTROOT = EXPTDIR

        LOGDIR = os.path.join(EXPTDIR, "log")

    if DBNROOT is None:
        DBNROOT = None
    if SENDECF is None:
        SENDECF = False
    if SENDDBN is None:
        SENDDBN = False
    if SENDDBN_NTC is None:
        SENDDBN_NTC = False
    if SENDCOM is None:
        SENDCOM = False
    if SENDWEB is None:
        SENDWEB = False
    if KEEPDATA is None:
        KEEPDATA = True

    # create NCO directories
    if RUN_ENVIR == "nco":
        mkdir_vrfy(f" -p '{OPSROOT}'")
        mkdir_vrfy(f" -p '{COMROOT}'")
        mkdir_vrfy(f" -p '{PACKAGEROOT}'")
        mkdir_vrfy(f" -p '{DATAROOT}'")
        mkdir_vrfy(f" -p '{DCOMROOT}'")
        mkdir_vrfy(f" -p '{EXTROOT}'")
    if DBNROOT is not None:
        mkdir_vrfy(f" -p '{DBNROOT}'")

    #
    # -----------------------------------------------------------------------
    #
    #
    # If POST_OUTPUT_DOMAIN_NAME has not been specified by the user, set it
    # to PREDEF_GRID_NAME (which won't be empty if using a predefined grid).
    # Then change it to lowercase.  Finally, ensure that it does not end up
    # getting set to an empty string.
    #
    # -----------------------------------------------------------------------
    #
    POST_OUTPUT_DOMAIN_NAME = POST_OUTPUT_DOMAIN_NAME or PREDEF_GRID_NAME

    if type(POST_OUTPUT_DOMAIN_NAME) != int:
        POST_OUTPUT_DOMAIN_NAME = lowercase(POST_OUTPUT_DOMAIN_NAME)

    if POST_OUTPUT_DOMAIN_NAME is None:
        if PREDEF_GRID_NAME is None:
            raise Exception(
                f"""
                The domain name used in naming the run_post output files
                (POST_OUTPUT_DOMAIN_NAME) has not been set:
                POST_OUTPUT_DOMAIN_NAME = '{POST_OUTPUT_DOMAIN_NAME}'
                If this experiment is not using a predefined grid (i.e. if
                PREDEF_GRID_NAME is set to a null string), POST_OUTPUT_DOMAIN_NAME
                must be set in the configuration file ('{EXPT_CONFIG_FN}'). """
            )
    #
    # -----------------------------------------------------------------------
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
    # -----------------------------------------------------------------------
    #
    global DATA_TABLE_TMPL_FN, DIAG_TABLE_TMPL_FN, FIELD_TABLE_TMPL_FN, MODEL_CONFIG_TMPL_FN, NEMS_CONFIG_TMPL_FN
    global DATA_TABLE_TMPL_FP, DIAG_TABLE_TMPL_FP, FIELD_TABLE_TMPL_FP, MODEL_CONFIG_TMPL_FP, NEMS_CONFIG_TMPL_FP
    global FV3_NML_BASE_SUITE_FP, FV3_NML_YAML_CONFIG_FP, FV3_NML_BASE_ENS_FP
    global AQM_RC_TMPL_FN, AQM_RC_TMPL_FP

    dot_ccpp_phys_suite_or_null = f".{CCPP_PHYS_SUITE}"

    # Names of input files that the forecast model (ufs-weather-model) expects
    # to read in.  These should only be changed if the input file names in the
    # forecast model code are changed.
    # ----------------------------------
    DATA_TABLE_FN = "data_table"
    DIAG_TABLE_FN = "diag_table"
    FIELD_TABLE_FN = "field_table"
    MODEL_CONFIG_FN = "model_configure"
    NEMS_CONFIG_FN = "nems.configure"
    AQM_RC_FN = "aqm.rc"
    #----------------------------------

    DATA_TABLE_TMPL_FN = DATA_TABLE_TMPL_FN or DATA_TABLE_FN
    DIAG_TABLE_TMPL_FN = (
        f"{DIAG_TABLE_TMPL_FN or DIAG_TABLE_FN}{dot_ccpp_phys_suite_or_null}"
    )
    FIELD_TABLE_TMPL_FN = (
        f"{FIELD_TABLE_TMPL_FN or FIELD_TABLE_FN}{dot_ccpp_phys_suite_or_null}"
    )
    MODEL_CONFIG_TMPL_FN = MODEL_CONFIG_TMPL_FN or MODEL_CONFIG_FN
    NEMS_CONFIG_TMPL_FN = NEMS_CONFIG_TMPL_FN or NEMS_CONFIG_FN
    AQM_RC_TMPL_FN = AQM_RC_TMPL_FN or AQM_RC_FN

    DATA_TABLE_TMPL_FP = os.path.join(PARMdir, DATA_TABLE_TMPL_FN)
    DIAG_TABLE_TMPL_FP = os.path.join(PARMdir, DIAG_TABLE_TMPL_FN)
    FIELD_TABLE_TMPL_FP = os.path.join(PARMdir, FIELD_TABLE_TMPL_FN)
    FV3_NML_BASE_SUITE_FP = os.path.join(PARMdir, FV3_NML_BASE_SUITE_FN)
    FV3_NML_YAML_CONFIG_FP = os.path.join(PARMdir, FV3_NML_YAML_CONFIG_FN)
    FV3_NML_BASE_ENS_FP = os.path.join(EXPTDIR, FV3_NML_BASE_ENS_FN)
    MODEL_CONFIG_TMPL_FP = os.path.join(PARMdir, MODEL_CONFIG_TMPL_FN)
    NEMS_CONFIG_TMPL_FP = os.path.join(PARMdir, NEMS_CONFIG_TMPL_FN)
    AQM_RC_TMPL_FP = os.path.join(PARMdir, AQM_RC_TMPL_FN)
    #
    # -----------------------------------------------------------------------
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
    # -----------------------------------------------------------------------
    #
    global CCPP_PHYS_SUITE_FN, CCPP_PHYS_SUITE_IN_CCPP_FP, CCPP_PHYS_SUITE_FP
    CCPP_PHYS_SUITE_FN = f"suite_{CCPP_PHYS_SUITE}.xml"
    CCPP_PHYS_SUITE_IN_CCPP_FP = os.path.join(
        UFS_WTHR_MDL_DIR, "FV3", "ccpp", "suites", CCPP_PHYS_SUITE_FN
    )
    CCPP_PHYS_SUITE_FP = os.path.join(EXPTDIR, CCPP_PHYS_SUITE_FN)
    if not os.path.exists(CCPP_PHYS_SUITE_IN_CCPP_FP):
        raise FileNotFoundError(
            f"""
            The CCPP suite definition file (CCPP_PHYS_SUITE_IN_CCPP_FP) does not exist
            in the local clone of the ufs-weather-model:
              CCPP_PHYS_SUITE_IN_CCPP_FP = '{CCPP_PHYS_SUITE_IN_CCPP_FP}'"""
        )
    #
    # -----------------------------------------------------------------------
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
    # -----------------------------------------------------------------------
    #
    global FIELD_DICT_FN, FIELD_DICT_IN_UWM_FP, FIELD_DICT_FP
    FIELD_DICT_FN = "fd_nems.yaml"
    FIELD_DICT_IN_UWM_FP = os.path.join(
        UFS_WTHR_MDL_DIR, "tests", "parm", FIELD_DICT_FN
    )
    FIELD_DICT_FP = os.path.join(EXPTDIR, FIELD_DICT_FN)
    if not os.path.exists(FIELD_DICT_IN_UWM_FP):
        raise FileNotFoundError(
            f"""
            The field dictionary file (FIELD_DICT_IN_UWM_FP) does not exist
            in the local clone of the ufs-weather-model:
              FIELD_DICT_IN_UWM_FP = '{FIELD_DICT_IN_UWM_FP}'"""
        )
    #
    # -----------------------------------------------------------------------
    #
    # Call the function that sets the ozone parameterization being used and
    # modifies associated parameters accordingly.
    #
    # -----------------------------------------------------------------------
    #

    OZONE_PARAM = set_ozone_param(
        CCPP_PHYS_SUITE_IN_CCPP_FP,
        CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING,
        FIXgsm_FILES_TO_COPY_TO_FIXam,
        VERBOSE=VERBOSE,
    )

    #
    # -----------------------------------------------------------------------
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
    # -----------------------------------------------------------------------
    #
    global DATA_TABLE_FP, FIELD_TABLE_FP, FV3_NML_FN, FV3_NML_FP, NEMS_CONFIG_FP
    DATA_TABLE_FP = os.path.join(EXPTDIR, DATA_TABLE_FN)
    FIELD_TABLE_FP = os.path.join(EXPTDIR, FIELD_TABLE_FN)
    FV3_NML_FN = os.path.splitext(FV3_NML_BASE_SUITE_FN)[0]
    FV3_NML_FP = os.path.join(EXPTDIR, FV3_NML_FN)
    NEMS_CONFIG_FP = os.path.join(EXPTDIR, NEMS_CONFIG_FN)
    #
    # -----------------------------------------------------------------------
    #
    # If USE_USER_STAGED_EXTRN_FILES is set to TRUE, make sure that the user-
    # specified directories under which the external model files should be
    # located actually exist.
    #
    # -----------------------------------------------------------------------
    #
    if USE_USER_STAGED_EXTRN_FILES:
        # Check for the base directory up to the first templated field.
        idx = EXTRN_MDL_SOURCE_BASEDIR_ICS.find("$")
        if idx == -1:
            idx = len(EXTRN_MDL_SOURCE_BASEDIR_ICS)

        if not os.path.exists(EXTRN_MDL_SOURCE_BASEDIR_ICS[:idx]):
            raise FileNotFoundError(
                f"""
                The directory (EXTRN_MDL_SOURCE_BASEDIR_ICS) in which the user-staged
                external model files for generating ICs should be located does not exist:
                  EXTRN_MDL_SOURCE_BASEDIR_ICS = '{EXTRN_MDL_SOURCE_BASEDIR_ICS}'"""
            )

        idx = EXTRN_MDL_SOURCE_BASEDIR_LBCS.find("$")
        if idx == -1:
            idx = len(EXTRN_MDL_SOURCE_BASEDIR_LBCS)

        if not os.path.exists(EXTRN_MDL_SOURCE_BASEDIR_LBCS[:idx]):
            raise FileNotFoundError(
                f"""
                The directory (EXTRN_MDL_SOURCE_BASEDIR_LBCS) in which the user-staged
                external model files for generating LBCs should be located does not exist:
                  EXTRN_MDL_SOURCE_BASEDIR_LBCS = '{EXTRN_MDL_SOURCE_BASEDIR_LBCS}'"""
            )
    #
    # -----------------------------------------------------------------------
    #
    # If DO_ENSEMBLE, set the names of the ensemble members; these will be
    # used to set the ensemble member directories.  Also, set the full path
    # to the FV3 namelist file corresponding to each ensemble member.
    #
    # -----------------------------------------------------------------------
    #
    global NDIGITS_ENSMEM_NAMES, ENSMEM_NAMES, FV3_NML_ENSMEM_FPS, NUM_ENS_MEMBERS
    NDIGITS_ENSMEM_NAMES = 0
    ENSMEM_NAMES = []
    FV3_NML_ENSMEM_FPS = []
    if DO_ENSEMBLE:
        NDIGITS_ENSMEM_NAMES = len(str(NUM_ENS_MEMBERS))
        fmt = f"0{NDIGITS_ENSMEM_NAMES}d"
        for i in range(NUM_ENS_MEMBERS):
            ENSMEM_NAMES.append(f"mem{fmt}".format(i + 1))
            FV3_NML_ENSMEM_FPS.append(
                os.path.join(EXPTDIR, f"{FV3_NML_FN}_{ENSMEM_NAMES[i]}")
            )

    # Set the full path to the forecast model executable.
    global FV3_EXEC_FP
    FV3_EXEC_FP = os.path.join(EXECdir, FV3_EXEC_FN)
    #
    # -----------------------------------------------------------------------
    #
    # Set the full path to the script that can be used to (re)launch the
    # workflow.  Also, if USE_CRON_TO_RELAUNCH is set to TRUE, set the line
    # to add to the cron table to automatically relaunch the workflow every
    # CRON_RELAUNCH_INTVL_MNTS minutes.  Otherwise, set the variable con-
    # taining this line to a null string.
    #
    # -----------------------------------------------------------------------
    #
    global WFLOW_LAUNCH_SCRIPT_FP, WFLOW_LAUNCH_LOG_FP, CRONTAB_LINE
    WFLOW_LAUNCH_SCRIPT_FP = os.path.join(USHdir, WFLOW_LAUNCH_SCRIPT_FN)
    WFLOW_LAUNCH_LOG_FP = os.path.join(EXPTDIR, WFLOW_LAUNCH_LOG_FN)
    if USE_CRON_TO_RELAUNCH:
        CRONTAB_LINE = (
            f"""*/{CRON_RELAUNCH_INTVL_MNTS} * * * * cd {EXPTDIR} && """
            f"""./{WFLOW_LAUNCH_SCRIPT_FN} called_from_cron="TRUE" >> ./{WFLOW_LAUNCH_LOG_FN} 2>&1"""
        )
    else:
        CRONTAB_LINE = ""
    #
    # -----------------------------------------------------------------------
    #
    # Set the full path to the script that, for a given task, loads the
    # necessary module files and runs the tasks.
    #
    # -----------------------------------------------------------------------
    #
    global LOAD_MODULES_RUN_TASK_FP
    LOAD_MODULES_RUN_TASK_FP = os.path.join(USHdir, "load_modules_run_task.sh")

    global RUN_TASK_MAKE_GRID, RUN_TASK_MAKE_OROG, RUN_TASK_MAKE_SFC_CLIMO
    global RUN_TASK_VX_GRIDSTAT, RUN_TASK_VX_POINTSTAT, RUN_TASK_VX_ENSGRID, RUN_TASK_VX_ENSPOINT

    # Fix file location
    if RUN_TASK_MAKE_GRID:
        FIXdir = EXPTDIR
    else:
        FIXdir = os.path.join(HOMEdir, "fix")

    FIXam = os.path.join(FIXdir, "fix_am")
    FIXclim = os.path.join(FIXdir, "fix_clim")
    FIXlam = os.path.join(FIXdir, "fix_lam")

    # Ensemble verification can only be run in ensemble mode
    if (not DO_ENSEMBLE) and (RUN_TASK_VX_ENSGRID or RUN_TASK_VX_ENSPOINT):
        raise Exception(
            f"""
            Ensemble verification can not be run unless running in ensemble mode:
               DO_ENSEMBLE = '{DO_ENSEMBLE}'
               RUN_TASK_VX_ENSGRID = '{RUN_TASK_VX_ENSGRID}'
               RUN_TASK_VX_ENSPOINT = '{RUN_TASK_VX_ENSPOINT}'"""
        )

    #
    # -----------------------------------------------------------------------
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
    # ----------------------------------------------------------------------
    #
    global GRID_DIR, OROG_DIR, SFC_CLIMO_DIR

    if DOMAIN_PREGEN_BASEDIR is None:
        RUN_TASK_MAKE_GRID = True
        RUN_TASK_MAKE_OROG = True
        RUN_TASK_MAKE_SFC_CLIMO = True

    #
    # If RUN_TASK_MAKE_GRID is set to False, the workflow will look for
    # the pregenerated grid files in GRID_DIR.  In this case, make sure that
    # GRID_DIR exists.  Otherwise, set it to a predefined location under the
    # experiment directory (EXPTDIR).
    #
    if not RUN_TASK_MAKE_GRID:
        if GRID_DIR is None:
            GRID_DIR = os.path.join(DOMAIN_PREGEN_BASEDIR, PREDEF_GRID_NAME)

            msg = dedent(
                f"""
                GRID_DIR not specified!
                Setting GRID_DIR = {GRID_DIR}
                """
            )
            logger.warning(msg)

        if not os.path.exists(GRID_DIR):
            raise FileNotFoundError(
                f"""
                The directory (GRID_DIR) that should contain the pregenerated grid files
                does not exist:
                  GRID_DIR = '{GRID_DIR}'"""
            )
    else:
        GRID_DIR = os.path.join(EXPTDIR, "grid")
    #
    # If RUN_TASK_MAKE_OROG is set to False, the workflow will look for
    # the pregenerated orography files in OROG_DIR.  In this case, make sure
    # that OROG_DIR exists.  Otherwise, set it to a predefined location under
    # the experiment directory (EXPTDIR).
    #
    if not RUN_TASK_MAKE_OROG:
        if OROG_DIR is None:
            OROG_DIR = os.path.join(DOMAIN_PREGEN_BASEDIR, PREDEF_GRID_NAME)

            msg = dedent(
                f"""
                OROG_DIR not specified!
                Setting OROG_DIR = {OROG_DIR}
                """
            )
            logger.warning(msg)

        if not os.path.exists(OROG_DIR):
            raise FileNotFoundError(
                f"""
                The directory (OROG_DIR) that should contain the pregenerated orography
                files does not exist:
                  OROG_DIR = '{OROG_DIR}'"""
            )
    else:
        OROG_DIR = os.path.join(EXPTDIR, "orog")
    #
    # If RUN_TASK_MAKE_SFC_CLIMO is set to False, the workflow will look
    # for the pregenerated surface climatology files in SFC_CLIMO_DIR.  In
    # this case, make sure that SFC_CLIMO_DIR exists.  Otherwise, set it to
    # a predefined location under the experiment directory (EXPTDIR).
    #
    if not RUN_TASK_MAKE_SFC_CLIMO:
        if SFC_CLIMO_DIR is None:
            SFC_CLIMO_DIR = os.path.join(DOMAIN_PREGEN_BASEDIR, PREDEF_GRID_NAME)

            msg = dedent(
                f"""
                SFC_CLIMO_DIR not specified!
                Setting SFC_CLIMO_DIR ={SFC_CLIMO_DIR}
                """
            )
            logger.warning(msg)

        if not os.path.exists(SFC_CLIMO_DIR):
            raise FileNotFoundError(
                f"""
                The directory (SFC_CLIMO_DIR) that should contain the pregenerated surface
                climatology files does not exist:
                  SFC_CLIMO_DIR = '{SFC_CLIMO_DIR}'"""
            )
    else:
        SFC_CLIMO_DIR = os.path.join(EXPTDIR, "sfc_climo")

    #
    # -----------------------------------------------------------------------
    #
    # Set EXTRN_MDL_LBCS_OFFSET_HRS, which is the number of hours to shift
    # the starting time of the external model that provides lateral boundary
    # conditions.
    #
    # -----------------------------------------------------------------------
    #
    global EXTRN_MDL_LBCS_OFFSET_HRS
    if EXTRN_MDL_NAME_LBCS == "RAP":
        EXTRN_MDL_LBCS_OFFSET_HRS = EXTRN_MDL_LBCS_OFFSET_HRS or "3"
    else:
        EXTRN_MDL_LBCS_OFFSET_HRS = EXTRN_MDL_LBCS_OFFSET_HRS or "0"

    #
    # -----------------------------------------------------------------------
    #
    # Set parameters according to the type of horizontal grid generation
    # method specified.  First consider GFDL's global-parent-grid based
    # method.
    #
    # -----------------------------------------------------------------------
    #
    global LON_CTR, LAT_CTR, NX, NY, NHW, STRETCH_FAC

    if GRID_GEN_METHOD == "GFDLgrid":
        grid_params = set_gridparams_GFDLgrid(
            lon_of_t6_ctr=GFDLgrid_LON_T6_CTR,
            lat_of_t6_ctr=GFDLgrid_LAT_T6_CTR,
            res_of_t6g=GFDLgrid_NUM_CELLS,
            stretch_factor=GFDLgrid_STRETCH_FAC,
            refine_ratio_t6g_to_t7g=GFDLgrid_REFINE_RATIO,
            istart_of_t7_on_t6g=GFDLgrid_ISTART_OF_RGNL_DOM_ON_T6G,
            iend_of_t7_on_t6g=GFDLgrid_IEND_OF_RGNL_DOM_ON_T6G,
            jstart_of_t7_on_t6g=GFDLgrid_JSTART_OF_RGNL_DOM_ON_T6G,
            jend_of_t7_on_t6g=GFDLgrid_JEND_OF_RGNL_DOM_ON_T6G,
            RUN_ENVIR=RUN_ENVIR,
            VERBOSE=VERBOSE,
        )
    #
    # -----------------------------------------------------------------------
    #
    # Now consider Jim Purser's map projection/grid generation method.
    #
    # -----------------------------------------------------------------------
    #
    elif GRID_GEN_METHOD == "ESGgrid":
        grid_params = set_gridparams_ESGgrid(
            lon_ctr=ESGgrid_LON_CTR,
            lat_ctr=ESGgrid_LAT_CTR,
            nx=ESGgrid_NX,
            ny=ESGgrid_NY,
            pazi=ESGgrid_PAZI,
            halo_width=ESGgrid_WIDE_HALO_WIDTH,
            delx=ESGgrid_DELX,
            dely=ESGgrid_DELY,
        )
    #
    # -----------------------------------------------------------------------
    #
    # Otherwise
    #
    # -----------------------------------------------------------------------
    #
    else:
        grid_params = {
            "LON_CTR": LON_CTR,
            "LAT_CTR": LAT_CTR,
            "NX": NX,
            "NY": NY,
            "NHW": NHW,
            "STRETCH_FAC": STRETCH_FAC,
        }

    # Extract the basic grid params from the dictionary
    (LON_CTR, LAT_CTR, NX, NY, NHW, STRETCH_FAC) = (
        grid_params[k] for k in ["LON_CTR", "LAT_CTR", "NX", "NY", "NHW", "STRETCH_FAC"]
    )

    # grid params
    cfg_d["grid_params"] = grid_params

    #
    # -----------------------------------------------------------------------
    #
    # Create a new experiment directory. For platforms with no workflow
    # manager we need to create LOGDIR as well, since it won't be created
    # later at runtime.
    #
    # -----------------------------------------------------------------------
    #
    mkdir_vrfy(f" -p '{EXPTDIR}'")
    mkdir_vrfy(f" -p '{LOGDIR}'")
    #
    # -----------------------------------------------------------------------
    # NOTE: currently this is executed no matter what, should it be dependent on the logic described below??
    # If not running the MAKE_GRID_TN, MAKE_OROG_TN, and/or MAKE_SFC_CLIMO
    # tasks, create symlinks under the FIXlam directory to pregenerated grid,
    # orography, and surface climatology files.  In the process, also set
    # RES_IN_FIXLAM_FILENAMES, which is the resolution of the grid (in units
    # of number of grid points on an equivalent global uniform cubed-sphere
    # grid) used in the names of the fixed files in the FIXlam directory.
    #
    # -----------------------------------------------------------------------
    #
    mkdir_vrfy(f" -p '{FIXlam}'")
    RES_IN_FIXLAM_FILENAMES = ""
    #
    # -----------------------------------------------------------------------
    #
    # If the grid file generation task in the workflow is going to be skipped
    # (because pregenerated files are available), create links in the FIXlam
    # directory to the pregenerated grid files.
    #
    # -----------------------------------------------------------------------
    #

    # link fix files
    res_in_grid_fns = ""
    if not RUN_TASK_MAKE_GRID:

        res_in_grid_fns = link_fix(globals(), file_group="grid")

        RES_IN_FIXLAM_FILENAMES = res_in_grid_fns
    #
    # -----------------------------------------------------------------------
    #
    # If the orography file generation task in the workflow is going to be
    # skipped (because pregenerated files are available), create links in
    # the FIXlam directory to the pregenerated orography files.
    #
    # -----------------------------------------------------------------------
    #
    res_in_orog_fns = ""
    if not RUN_TASK_MAKE_OROG:

        res_in_orog_fns = link_fix(globals(), file_group="orog")

        if not RES_IN_FIXLAM_FILENAMES and (res_in_orog_fns != RES_IN_FIXLAM_FILENAMES):
            raise Exception(
                f"""
                The resolution extracted from the orography file names (res_in_orog_fns)
                does not match the resolution in other groups of files already consi-
                dered (RES_IN_FIXLAM_FILENAMES):
                  res_in_orog_fns = {res_in_orog_fns}
                  RES_IN_FIXLAM_FILENAMES = {RES_IN_FIXLAM_FILENAMES}"""
            )
        else:
            RES_IN_FIXLAM_FILENAMES = res_in_orog_fns
    #
    # -----------------------------------------------------------------------
    #
    # If the surface climatology file generation task in the workflow is
    # going to be skipped (because pregenerated files are available), create
    # links in the FIXlam directory to the pregenerated surface climatology
    # files.
    #
    # -----------------------------------------------------------------------
    #
    res_in_sfc_climo_fns = ""
    if not RUN_TASK_MAKE_SFC_CLIMO:

        res_in_sfc_climo_fns = link_fix(globals(), file_group="sfc_climo")

        if RES_IN_FIXLAM_FILENAMES and res_in_sfc_climo_fns != RES_IN_FIXLAM_FILENAMES:
            raise Exception(
                f"""
                The resolution extracted from the surface climatology file names (res_-
                in_sfc_climo_fns) does not match the resolution in other groups of files
                already considered (RES_IN_FIXLAM_FILENAMES):
                  res_in_sfc_climo_fns = {res_in_sfc_climo_fns}
                  RES_IN_FIXLAM_FILENAMES = {RES_IN_FIXLAM_FILENAMES}"""
            )
        else:
            RES_IN_FIXLAM_FILENAMES = res_in_sfc_climo_fns
    #
    # -----------------------------------------------------------------------
    #
    # The variable CRES is needed in constructing various file names.  If
    # not running the make_grid task, we can set it here.  Otherwise, it
    # will get set to a valid value by that task.
    #
    # -----------------------------------------------------------------------
    #
    global CRES
    CRES = ""
    if not RUN_TASK_MAKE_GRID:
        CRES = f"C{RES_IN_FIXLAM_FILENAMES}"

    global RUN_TASK_RUN_POST
    if WRITE_DOPOST:
        # Turn off run_post
        if RUN_TASK_RUN_POST:
            logger.warning(
                dedent(
                    f"""
                    Inline post is turned on, deactivating post-processing tasks:
                    RUN_TASK_RUN_POST = False
                    """
                )
            )
            RUN_TASK_RUN_POST = False

        # Check if SUB_HOURLY_POST is on
        if SUB_HOURLY_POST:
            raise Exception(
                f"""
                SUB_HOURLY_POST is NOT available with Inline Post yet."""
            )
    #
    # -----------------------------------------------------------------------
    #
    # Calculate PE_MEMBER01.  This is the number of MPI tasks used for the
    # forecast, including those for the write component if QUILTING is set
    # to True.
    #
    # -----------------------------------------------------------------------
    #
    global PE_MEMBER01
    PE_MEMBER01 = LAYOUT_X * LAYOUT_Y
    if QUILTING:
        PE_MEMBER01 = PE_MEMBER01 + WRTCMP_write_groups * WRTCMP_write_tasks_per_group

    if VERBOSE:
        log_info(
            f"""
            The number of MPI tasks for the forecast (including those for the write
            component if it is being used) are:
              PE_MEMBER01 = {PE_MEMBER01}""",
            verbose=VERBOSE,
        )
    #
    # -----------------------------------------------------------------------
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
    # -----------------------------------------------------------------------
    #
    global NNODES_RUN_FCST, NNODES_POINT_SOURCE
    NNODES_RUN_FCST = (PE_MEMBER01 + PPN_RUN_FCST - 1) // PPN_RUN_FCST
    NNODES_POINT_SOURCE = ((LAYOUT_X * LAYOUT_Y) + PPN_POINT_SOURCE -1) // PPN_POINT_SOURCE

    #
    # -----------------------------------------------------------------------
    #
    # Call the function that checks whether the RUC land surface model (LSM)
    # is being called by the physics suite and sets the workflow variable
    # SDF_USES_RUC_LSM to True or False accordingly.
    #
    # -----------------------------------------------------------------------
    #
    global SDF_USES_RUC_LSM
    SDF_USES_RUC_LSM = check_ruc_lsm(ccpp_phys_suite_fp=CCPP_PHYS_SUITE_IN_CCPP_FP)
    #
    # -----------------------------------------------------------------------
    #
    # Set the name of the file containing aerosol climatology data that, if
    # necessary, can be used to generate approximate versions of the aerosol
    # fields needed by Thompson microphysics.  This file will be used to
    # generate such approximate aerosol fields in the ICs and LBCs if Thompson
    # MP is included in the physics suite and if the exteranl model for ICs
    # or LBCs does not already provide these fields.  Also, set the full path
    # to this file.
    #
    # -----------------------------------------------------------------------
    #
    THOMPSON_MP_CLIMO_FN = "Thompson_MP_MONTHLY_CLIMO.nc"
    THOMPSON_MP_CLIMO_FP = os.path.join(FIXam, THOMPSON_MP_CLIMO_FN)
    #
    # -----------------------------------------------------------------------
    #
    # Call the function that, if the Thompson microphysics parameterization
    # is being called by the physics suite, modifies certain workflow arrays
    # to ensure that fixed files needed by this parameterization are copied
    # to the FIXam directory and appropriate symlinks to them are created in
    # the run directories.  This function also sets the workflow variable
    # SDF_USES_THOMPSON_MP that indicates whether Thompson MP is called by
    # the physics suite.
    #
    # -----------------------------------------------------------------------
    #
    SDF_USES_THOMPSON_MP = set_thompson_mp_fix_files(
        EXTRN_MDL_NAME_ICS,
        EXTRN_MDL_NAME_LBCS,
        CCPP_PHYS_SUITE,
        CCPP_PHYS_SUITE_IN_CCPP_FP,
        THOMPSON_MP_CLIMO_FN,
        CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING,
        FIXgsm_FILES_TO_COPY_TO_FIXam,
    )

    # global variable definition file path
    global GLOBAL_VAR_DEFNS_FP
    GLOBAL_VAR_DEFNS_FP = os.path.join(EXPTDIR, GLOBAL_VAR_DEFNS_FN)

    #
    # -----------------------------------------------------------------------
    #
    # Append additional variable definitions (and comments) to the variable
    # definitions file.  These variables have been set above using the vari-
    # ables in the default and local configuration scripts.  These variables
    # are needed by various tasks/scripts in the workflow.
    #
    # -----------------------------------------------------------------------
    #
    settings = {
        #
        # -----------------------------------------------------------------------
        #
        # Full path to workflow (re)launch script, its log file, and the line
        # that gets added to the cron table to launch this script if the flag
        # USE_CRON_TO_RELAUNCH is set to 'TRUE'.
        #
        # -----------------------------------------------------------------------
        #
        "WFLOW_LAUNCH_SCRIPT_FP": WFLOW_LAUNCH_SCRIPT_FP,
        "WFLOW_LAUNCH_LOG_FP": WFLOW_LAUNCH_LOG_FP,
        "CRONTAB_LINE": CRONTAB_LINE,
        #
        # -----------------------------------------------------------------------
        #
        # Directories.
        #
        # -----------------------------------------------------------------------
        #
        "HOMEdir": HOMEdir,
        "USHdir": USHdir,
        "SCRIPTSdir": SCRIPTSdir,
        "JOBSdir": JOBSdir,
        "SORCdir": SORCdir,
        "PARMdir": PARMdir,
        "MODULESdir": MODULESdir,
        "EXECdir": EXECdir,
        "FIXdir": FIXdir,
        "FIXam": FIXam,
        "FIXclim": FIXclim,
        "FIXlam": FIXlam,
        "FIXgsm": FIXgsm,
        "FIXaer": FIXaer,
        "FIXlut": FIXlut,
        "VX_CONFIG_DIR": VX_CONFIG_DIR,
        "METPLUS_CONF": METPLUS_CONF,
        "MET_CONFIG": MET_CONFIG,
        "UFS_WTHR_MDL_DIR": UFS_WTHR_MDL_DIR,
        "SFC_CLIMO_INPUT_DIR": SFC_CLIMO_INPUT_DIR,
        "TOPO_DIR": TOPO_DIR,
        "ARL_NEXUS_DIR": ARL_NEXUS_DIR,
        "EXPTDIR": EXPTDIR,
        "GRID_DIR": GRID_DIR,
        "OROG_DIR": OROG_DIR,
        "SFC_CLIMO_DIR": SFC_CLIMO_DIR,
        "NDIGITS_ENSMEM_NAMES": NDIGITS_ENSMEM_NAMES,
        "ENSMEM_NAMES": ENSMEM_NAMES,
        "FV3_NML_ENSMEM_FPS": FV3_NML_ENSMEM_FPS,
        #
        # -----------------------------------------------------------------------
        #
        # Files.
        #
        # -----------------------------------------------------------------------
        #
        "GLOBAL_VAR_DEFNS_FP": GLOBAL_VAR_DEFNS_FP,
        "DATA_TABLE_FN": DATA_TABLE_FN,
        "DIAG_TABLE_FN": DIAG_TABLE_FN,
        "FIELD_TABLE_FN": FIELD_TABLE_FN,
        "MODEL_CONFIG_FN": MODEL_CONFIG_FN,
        "NEMS_CONFIG_FN": NEMS_CONFIG_FN,
        "AQM_RC_FN": AQM_RC_FN,
        "DATA_TABLE_TMPL_FN": DATA_TABLE_TMPL_FN,
        "DIAG_TABLE_TMPL_FN": DIAG_TABLE_TMPL_FN,
        "FIELD_TABLE_TMPL_FN": FIELD_TABLE_TMPL_FN,
        "MODEL_CONFIG_TMPL_FN": MODEL_CONFIG_TMPL_FN,
        "NEMS_CONFIG_TMPL_FN": NEMS_CONFIG_TMPL_FN,
        "AQM_RC_TMPL_FN": AQM_RC_TMPL_FN,
        "DATA_TABLE_TMPL_FP": DATA_TABLE_TMPL_FP,
        "DIAG_TABLE_TMPL_FP": DIAG_TABLE_TMPL_FP,
        "FIELD_TABLE_TMPL_FP": FIELD_TABLE_TMPL_FP,
        "FV3_NML_BASE_SUITE_FP": FV3_NML_BASE_SUITE_FP,
        "FV3_NML_YAML_CONFIG_FP": FV3_NML_YAML_CONFIG_FP,
        "FV3_NML_BASE_ENS_FP": FV3_NML_BASE_ENS_FP,
        "MODEL_CONFIG_TMPL_FP": MODEL_CONFIG_TMPL_FP,
        "NEMS_CONFIG_TMPL_FP": NEMS_CONFIG_TMPL_FP,
        "AQM_RC_TMPL_FP": AQM_RC_TMPL_FP,
        "CCPP_PHYS_SUITE_FN": CCPP_PHYS_SUITE_FN,
        "CCPP_PHYS_SUITE_IN_CCPP_FP": CCPP_PHYS_SUITE_IN_CCPP_FP,
        "CCPP_PHYS_SUITE_FP": CCPP_PHYS_SUITE_FP,
        "FIELD_DICT_FN": FIELD_DICT_FN,
        "FIELD_DICT_IN_UWM_FP": FIELD_DICT_IN_UWM_FP,
        "FIELD_DICT_FP": FIELD_DICT_FP,
        "DATA_TABLE_FP": DATA_TABLE_FP,
        "FIELD_TABLE_FP": FIELD_TABLE_FP,
        "FV3_NML_FN": FV3_NML_FN,  # This may not be necessary...
        "FV3_NML_FP": FV3_NML_FP,
        "NEMS_CONFIG_FP": NEMS_CONFIG_FP,
        "FV3_EXEC_FP": FV3_EXEC_FP,
        "LOAD_MODULES_RUN_TASK_FP": LOAD_MODULES_RUN_TASK_FP,
        "THOMPSON_MP_CLIMO_FN": THOMPSON_MP_CLIMO_FN,
        "THOMPSON_MP_CLIMO_FP": THOMPSON_MP_CLIMO_FP,
        #
        # -----------------------------------------------------------------------
        #
        # Flag for creating relative symlinks (as opposed to absolute ones).
        #
        # -----------------------------------------------------------------------
        #
        "RELATIVE_LINK_FLAG": RELATIVE_LINK_FLAG,
        #
        # -----------------------------------------------------------------------
        #
        # Parameters that indicate whether or not various parameterizations are
        # included in and called by the physics suite.
        #
        # -----------------------------------------------------------------------
        #
        "SDF_USES_RUC_LSM": SDF_USES_RUC_LSM,
        "SDF_USES_THOMPSON_MP": SDF_USES_THOMPSON_MP,
        #
        # -----------------------------------------------------------------------
        #
        # Grid configuration parameters needed regardless of grid generation
        # method used.
        #
        # -----------------------------------------------------------------------
        #
        "GTYPE": GTYPE,
        "TILE_RGNL": TILE_RGNL,
        "RES_IN_FIXLAM_FILENAMES": RES_IN_FIXLAM_FILENAMES,
        #
        # If running the make_grid task, CRES will be set to a null string during
        # the grid generation step.  It will later be set to an actual value after
        # the make_grid task is complete.
        #
        "CRES": CRES,
        #
        # -----------------------------------------------------------------------
        #
        # Name of the ozone parameterization.  The value this gets set to depends
        # on the CCPP physics suite being used.
        #
        # -----------------------------------------------------------------------
        #
        "OZONE_PARAM": OZONE_PARAM,
        #
        # -----------------------------------------------------------------------
        #
        # Computational parameters.
        #
        # -----------------------------------------------------------------------
        #
        "PE_MEMBER01": PE_MEMBER01,
        #
        # -----------------------------------------------------------------------
        #
        # IF DO_SPP is set to "TRUE", N_VAR_SPP specifies the number of physics
        # parameterizations that are perturbed with SPP.  If DO_LSM_SPP is set to
        # "TRUE", N_VAR_LNDP specifies the number of LSM parameters that are
        # perturbed.  LNDP_TYPE determines the way LSM perturbations are employed
        # and FHCYC_LSM_SPP_OR_NOT sets FHCYC based on whether LSM perturbations
        # are turned on or not.
        #
        # -----------------------------------------------------------------------
        #
        "N_VAR_SPP": N_VAR_SPP,
        "N_VAR_LNDP": N_VAR_LNDP,
        "LNDP_TYPE": LNDP_TYPE,
        "LNDP_MODEL_TYPE": LNDP_MODEL_TYPE,
        "FHCYC_LSM_SPP_OR_NOT": FHCYC_LSM_SPP_OR_NOT,
    }

    # write derived settings
    cfg_d["derived"] = settings

    #
    # -----------------------------------------------------------------------
    #
    # NCO specific settings
    #
    # -----------------------------------------------------------------------
    #
    settings = {
        "COMIN_BASEDIR": COMIN_BASEDIR,
        "COMOUT_BASEDIR": COMOUT_BASEDIR,
        "OPSROOT": OPSROOT,
        "COMROOT": COMROOT,
        "PACKAGEROOT": PACKAGEROOT,
        "DATAROOT": DATAROOT,
        "DCOMROOT": DCOMROOT,
        "DBNROOT": DBNROOT,
        "EXTROOT": EXTROOT,
        "SENDECF": SENDECF,
        "SENDDBN": SENDDBN,
        "SENDDBN_NTC": SENDDBN_NTC,
        "SENDCOM": SENDCOM,
        "SENDWEB": SENDWEB,
        "KEEPDATA": KEEPDATA,
        "MAILTO": MAILTO,
        "MAILCC": MAILCC,
    }

    cfg_d["nco"].update(settings)
    #
    # -----------------------------------------------------------------------
    #
    # Now write everything to var_defns.sh file
    #
    # -----------------------------------------------------------------------
    #

    # update dictionary with globals() values
    update_dict(globals(), cfg_d)

    # print content of var_defns if DEBUG=True
    all_lines = cfg_to_yaml_str(cfg_d)
    log_info(all_lines, verbose=DEBUG)

    # print info message
    log_info(
        f"""
        Generating the global experiment variable definitions file specified by
        GLOBAL_VAR_DEFNS_FN:
          GLOBAL_VAR_DEFNS_FN = '{GLOBAL_VAR_DEFNS_FN}'
        Full path to this file is:
          GLOBAL_VAR_DEFNS_FP = '{GLOBAL_VAR_DEFNS_FP}'
        For more detailed information, set DEBUG to 'TRUE' in the experiment
        configuration file ('{EXPT_CONFIG_FN}')."""
    )

    with open(GLOBAL_VAR_DEFNS_FP, "a") as f:
        f.write(cfg_to_shell_str(cfg_d))

    #
    # -----------------------------------------------------------------------
    #
    # Check validity of parameters in one place, here in the end.
    #
    # -----------------------------------------------------------------------
    #

    # loop through cfg_d and check validity of params
    cfg_v = load_config_file("valid_param_vals.yaml")
    cfg_d = flatten_dict(cfg_d)
    for k, v in cfg_d.items():
        if v == None:
            continue
        vkey = "valid_vals_" + k
        if (vkey in cfg_v) and not (v in cfg_v[vkey]):
            raise Exception(
                f"""
                The variable {k}={v} in {EXPT_DEFAULT_CONFIG_FN} or {EXPT_CONFIG_FN}
                does not have a valid value. Possible values are:
                    {k} = {cfg_v[vkey]}"""
            )

    # add LOGDIR and return flat dict
    cfg_d.update({"LOGDIR": LOGDIR})
    return cfg_d


#
# -----------------------------------------------------------------------
#
# Call the function defined above.
#
# -----------------------------------------------------------------------
#
if __name__ == "__main__":
    setup()
