#!/usr/bin/env python3

import os
import sys
import subprocess
import unittest
import logging
from multiprocessing import Process
from textwrap import dedent
from datetime import datetime, timedelta

from python_utils import (
    log_info,
    import_vars,
    export_vars,
    load_config_file,
    update_dict,
    cp_vrfy,
    ln_vrfy,
    mkdir_vrfy,
    mv_vrfy,
    run_command,
    date_to_str,
    define_macos_utilities,
    create_symlink_to_file,
    check_for_preexist_dir_file,
    cfg_to_yaml_str,
    find_pattern_in_str,
    set_env_var,
    get_env_var,
    lowercase,
    flatten_dict,
)

from setup import setup
from set_FV3nml_sfc_climo_filenames import set_FV3nml_sfc_climo_filenames
from get_crontab_contents import add_crontab_line
from fill_jinja_template import fill_jinja_template
from set_namelist import set_namelist
from check_python_version import check_python_version


def generate_FV3LAM_wflow(ushdir, logfile: str = "log.generate_FV3LAM_wflow", debug: bool = False) -> str:
    """Function to setup a forecast experiment and create a workflow
    (according to the parameters specified in the config file)

    Args:
        ushdir  (str) : The full path of the ush/ directory where this script is located
        logfile (str) : The name of the file where logging is written
        debug   (bool): Enable extra output for debugging
    Returns:
        EXPTDIR (str) : The full path of the directory where this experiment has been generated
    """

    # Set up logging to write to screen and logfile
    setup_logging(logfile, debug)

    # Check python version and presence of some non-standard packages
    check_python_version()

    # Note start of workflow generation
    log_info(
        """
        ========================================================================
        Starting experiment generation...
        ========================================================================"""
    )

    # The setup function reads the user configuration file and fills in
    # non-user-specified values from config_defaults.yaml
    expt_config = setup(ushdir,debug=debug)

    verbose = expt_config["workflow"]["VERBOSE"]
    #
    # -----------------------------------------------------------------------
    #
    # Set the full path to the experiment's rocoto workflow xml file.  This
    # file will be placed at the top level of the experiment directory and
    # then used by rocoto to run the workflow.
    #
    # -----------------------------------------------------------------------
    #
    wflow_xml_fn = expt_config["workflow"]["WFLOW_XML_FN"]
    wflow_xml_fp = os.path.join(
        expt_config["workflow"]["EXPTDIR"],
        wflow_xml_fn,
    )
    #
    # -----------------------------------------------------------------------
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the jinja variables in the template rocoto
    # XML should be set to.  These values are set either in the user-specified
    # workflow configuration file (EXPT_CONFIG_FN) or in the setup() function
    # called above.  Then call the python script that generates the XML.
    #
    # -----------------------------------------------------------------------
    #
    if expt_config["platform"]["WORKFLOW_MANAGER"] == "rocoto":

        template_xml_fp = os.path.join(
            expt_config["user"]["PARMdir"],
            wflow_xml_fn,
        )
        global_var_defns_fp = expt_config["workflow"]["GLOBAL_VAR_DEFNS_FP"]

        log_info(
            f"""
            Creating rocoto workflow XML file (WFLOW_XML_FP):
              WFLOW_XML_FP = '{wflow_xml_fp}'"""
        )

        #
        # Call the python script to generate the experiment's XML file
        #
        rocoto_yaml_fp = expt_config["workflow"]["ROCOTO_YAML_FP"]
        args = ["-o", wflow_xml_fp,
                "-t", template_xml_fp,
                "-c", rocoto_yaml_fp ]
        if not debug:
            args.append("-q")

        try:
            fill_jinja_template(args)
        except:
            raise Exception(
                dedent(
                    f"""
                    Call to fill_jinja_template failed.
                    """
                )
            )
    #
    # -----------------------------------------------------------------------
    #
    # Create a symlink in the experiment directory that points to the workflow
    # (re)launch script.
    #
    # -----------------------------------------------------------------------
    #
    exptdir = expt_config["workflow"]["EXPTDIR"]
    wflow_launch_script_fp = expt_config["workflow"]["WFLOW_LAUNCH_SCRIPT_FP"]
    wflow_launch_script_fn = expt_config["workflow"]["WFLOW_LAUNCH_SCRIPT_FN"]
    log_info(
        f"""
        Creating symlink in the experiment directory (EXPTDIR) that points to the
        workflow launch script (WFLOW_LAUNCH_SCRIPT_FP):
          EXPTDIR = '{exptdir}'
          WFLOW_LAUNCH_SCRIPT_FP = '{wflow_launch_script_fp}'""",
        verbose=verbose,
    )

    create_symlink_to_file(
        wflow_launch_script_fp, os.path.join(exptdir, wflow_launch_script_fn), False
    )
    #
    # -----------------------------------------------------------------------
    #
    # If USE_CRON_TO_RELAUNCH is set to TRUE, add a line to the user's
    # cron table to call the (re)launch script every
    # CRON_RELAUNCH_INTVL_MNTS minutes.
    #
    # -----------------------------------------------------------------------
    #
    # From here on out, going back to setting variables for everything
    # in the flattened expt_config dictionary
    # TODO: Reference all these variables in their respective
    # dictionaries, instead.
    import_vars(dictionary=flatten_dict(expt_config))
    export_vars(source_dict=flatten_dict(expt_config))

    if USE_CRON_TO_RELAUNCH:
        add_crontab_line()

    #
    # Copy or symlink fix files
    #
    if SYMLINK_FIX_FILES:

        log_info(
            f"""
            Symlinking fixed files from system directory (FIXgsm) to a subdirectory (FIXam):
              FIXgsm = '{FIXgsm}'
              FIXam = '{FIXam}'""",
            verbose=verbose,
        )

        ln_vrfy(f"""-fsn '{FIXgsm}' '{FIXam}'""")
    else:

        log_info(
            f"""
            Copying fixed files from system directory (FIXgsm) to a subdirectory (FIXam):
              FIXgsm = '{FIXgsm}'
              FIXam = '{FIXam}'""",
            verbose=verbose,
        )

        check_for_preexist_dir_file(FIXam, "delete")
        mkdir_vrfy("-p", FIXam)
        mkdir_vrfy("-p", os.path.join(FIXam, "fix_co2_proj"))

        num_files = len(FIXgsm_FILES_TO_COPY_TO_FIXam)
        for i in range(num_files):
            fn = f"{FIXgsm_FILES_TO_COPY_TO_FIXam[i]}"
            cp_vrfy(os.path.join(FIXgsm, fn), os.path.join(FIXam, fn))
    #
    # -----------------------------------------------------------------------
    #
    # Copy MERRA2 aerosol climatology data.
    #
    # -----------------------------------------------------------------------
    #
    if USE_MERRA_CLIMO:
        log_info(
            f"""
            Copying MERRA2 aerosol climatology data files from system directory
            (FIXaer/FIXlut) to a subdirectory (FIXclim) in the experiment directory:
              FIXaer = '{FIXaer}'
              FIXlut = '{FIXlut}'
              FIXclim = '{FIXclim}'""",
            verbose=verbose,
        )

        check_for_preexist_dir_file(FIXclim, "delete")
        mkdir_vrfy("-p", FIXclim)

        if SYMLINK_FIX_FILES:
            ln_vrfy("-fsn", os.path.join(FIXaer, "merra2.aerclim*.nc"), FIXclim)
            ln_vrfy("-fsn", os.path.join(FIXlut, "optics*.dat"), FIXclim)
        else:
            cp_vrfy(os.path.join(FIXaer, "merra2.aerclim*.nc"), FIXclim)
            cp_vrfy(os.path.join(FIXlut, "optics*.dat"), FIXclim)
    #
    # -----------------------------------------------------------------------
    #
    # Copy templates of various input files to the experiment directory.
    #
    # -----------------------------------------------------------------------
    #
    log_info(
        f"""
        Copying templates of various input files to the experiment directory...""",
        verbose=verbose,
    )

    log_info(
        f"""
        Copying the template data table file to the experiment directory...""",
        verbose=verbose,
    )
    cp_vrfy(DATA_TABLE_TMPL_FP, DATA_TABLE_FP)

    log_info(
        f"""
        Copying the template field table file to the experiment directory...""",
        verbose=verbose,
    )
    cp_vrfy(FIELD_TABLE_TMPL_FP, FIELD_TABLE_FP)

    log_info(
        f"""
        Copying the template NEMS configuration file to the experiment directory...""",
        verbose=verbose,
    )
    cp_vrfy(NEMS_CONFIG_TMPL_FP, NEMS_CONFIG_FP)
    #
    # Copy the CCPP physics suite definition file from its location in the
    # clone of the FV3 code repository to the experiment directory (EXPT-
    # DIR).
    #
    log_info(
        f"""
        Copying the CCPP physics suite definition XML file from its location in
        the forecast model directory structure to the experiment directory...""",
        verbose=verbose,
    )
    cp_vrfy(CCPP_PHYS_SUITE_IN_CCPP_FP, CCPP_PHYS_SUITE_FP)
    #
    # Copy the field dictionary file from its location in the
    # clone of the FV3 code repository to the experiment directory (EXPT-
    # DIR).
    #
    log_info(
        f"""
        Copying the field dictionary file from its location in the forecast
        model directory structure to the experiment directory...""",
        verbose=verbose,
    )
    cp_vrfy(FIELD_DICT_IN_UWM_FP, FIELD_DICT_FP)
    #
    # -----------------------------------------------------------------------
    #
    # Set parameters in the FV3-LAM namelist file.
    #
    # -----------------------------------------------------------------------
    #
    log_info(
        f"""
        Setting parameters in weather model's namelist file (FV3_NML_FP):
        FV3_NML_FP = '{FV3_NML_FP}'"""
    )
    #
    # Set npx and npy, which are just NX plus 1 and NY plus 1, respectively.
    # These need to be set in the FV3-LAM Fortran namelist file.  They represent
    # the number of cell vertices in the x and y directions on the regional
    # grid.
    #
    npx = NX + 1
    npy = NY + 1
    #
    # For the physics suites that use RUC LSM, set the parameter kice to 9,
    # Otherwise, leave it unspecified (which means it gets set to the default
    # value in the forecast model).
    #
    kice = None
    if SDF_USES_RUC_LSM:
        kice = 9
    #
    # Set lsoil, which is the number of input soil levels provided in the
    # chgres_cube output NetCDF file.  This is the same as the parameter
    # nsoill_out in the namelist file for chgres_cube.  [On the other hand,
    # the parameter lsoil_lsm (not set here but set in input.nml.FV3 and/or
    # FV3.input.yml) is the number of soil levels that the LSM scheme in the
    # forecast model will run with.]  Here, we use the same approach to set
    # lsoil as the one used to set nsoill_out in exregional_make_ics.sh.
    # See that script for details.
    #
    # NOTE:
    # May want to remove lsoil from FV3.input.yml (and maybe input.nml.FV3).
    # Also, may want to set lsm here as well depending on SDF_USES_RUC_LSM.
    #
    lsoil = 4
    if (EXTRN_MDL_NAME_ICS == "HRRR" or EXTRN_MDL_NAME_ICS == "RAP") and (
        SDF_USES_RUC_LSM
    ):
        lsoil = 9
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the namelist variables that are physics-
    # suite-independent need to be set to.  Below, this variable will be
    # passed to a python script that will in turn set the values of these
    # variables in the namelist file.
    #
    # IMPORTANT:
    # If we want a namelist variable to be removed from the namelist file,
    # in the "settings" variable below, we need to set its value to the
    # string "null".  This is equivalent to setting its value to
    #    !!python/none
    # in the base namelist file specified by FV3_NML_BASE_SUITE_FP or the
    # suite-specific yaml settings file specified by FV3_NML_YAML_CONFIG_FP.
    #
    # It turns out that setting the variable to an empty string also works
    # to remove it from the namelist!  Which is better to use??
    #
    settings = {}
    settings["atmos_model_nml"] = {
        "blocksize": BLOCKSIZE,
        "ccpp_suite": CCPP_PHYS_SUITE,
    }

    fv_core_nml_dict = {}
    fv_core_nml_dict.update({
        "target_lon": LON_CTR,
        "target_lat": LAT_CTR,
        "nrows_blend": HALO_BLEND,
        #
        # Question:
        # For a ESGgrid type grid, what should stretch_fac be set to?  This depends
        # on how the FV3 code uses the stretch_fac parameter in the namelist file.
        # Recall that for a ESGgrid, it gets set in the function set_gridparams_ESGgrid(.sh)
        # to something like 0.9999, but is it ok to set it to that here in the
        # FV3 namelist file?
        #
        "stretch_fac": STRETCH_FAC,
        "npx": npx,
        "npy": npy,
        "layout": [LAYOUT_X, LAYOUT_Y],
        "bc_update_interval": LBC_SPEC_INTVL_HRS,
    })
    if ( CCPP_PHYS_SUITE == "FV3_GFS_2017_gfdl_mp" or
         CCPP_PHYS_SUITE == "FV3_GFS_2017_gfdlmp_regional" or
         CCPP_PHYS_SUITE == "FV3_GFS_v15p2" ):
        if CPL_AQM:
            fv_core_nml_dict.update({
                "dnats": 5
            })
        else:
            fv_core_nml_dict.update({
                "dnats": 1
            })
    elif CCPP_PHYS_SUITE == "FV3_GFS_v16":   
        if CPL_AQM:
            fv_core_nml_dict.update({
                "hord_tr": 8,
                "dnats": 5,
                "nord": 2
            })
        else:
            fv_core_nml_dict.update({
                "dnats": 1
            })
    elif CCPP_PHYS_SUITE == "FV3_GFS_v17_p8":
        if CPL_AQM:
            fv_core_nml_dict.update({
                "dnats": 4
            })
        else:
            fv_core_nml_dict.update({
                "dnats": 0
            })

    settings["fv_core_nml"] = fv_core_nml_dict

    gfs_physics_nml_dict = {}
    gfs_physics_nml_dict.update({
        "kice": kice or None,
        "lsoil": lsoil or None,
        "do_shum": DO_SHUM,
        "do_sppt": DO_SPPT,
        "do_skeb": DO_SKEB,
        "do_spp": DO_SPP,
        "n_var_spp": N_VAR_SPP,
        "n_var_lndp": N_VAR_LNDP,
        "lndp_type": LNDP_TYPE,
        "fhcyc": FHCYC_LSM_SPP_OR_NOT,
    })
    if CPL_AQM:
        gfs_physics_nml_dict.update({
            "cplaqm": True,    
            "cplocn2atm": False,
            "fscav_aero": ["aacd:0.0", "acet:0.0", "acrolein:0.0", "acro_primary:0.0", "ald2:0.0", 
                           "ald2_primary:0.0", "aldx:0.0", "benzene:0.0", "butadiene13:0.0", "cat1:0.0", 
                           "cl2:0.0", "clno2:0.0", "co:0.0", "cres:0.0", "cron:0.0", 
                           "ech4:0.0", "epox:0.0", "eth:0.0", "etha:0.0", "ethy:0.0", 
                           "etoh:0.0", "facd:0.0", "fmcl:0.0", "form:0.0", "form_primary:0.0", 
                           "gly:0.0", "glyd:0.0", "h2o2:0.0", "hcl:0.0", "hg:0.0", 
                           "hgiigas:0.0", "hno3:0.0", "hocl:0.0", "hono:0.0", "hpld:0.0", 
                           "intr:0.0", "iole:0.0", "isop:0.0", "ispd:0.0", "ispx:0.0", 
                           "ket:0.0", "meoh:0.0", "mepx:0.0", "mgly:0.0", "n2o5:0.0", 
                           "naph:0.0", "no:0.0", "no2:0.0", "no3:0.0", "ntr1:0.0", 
                           "ntr2:0.0", "o3:0.0", "ole:0.0", "opan:0.0", "open:0.0", 
                           "opo3:0.0", "pacd:0.0", "pan:0.0", "panx:0.0", "par:0.0", 
                           "pcvoc:0.0", "pna:0.0", "prpa:0.0", "rooh:0.0", "sesq:0.0", 
                           "so2:0.0", "soaalk:0.0", "sulf:0.0", "terp:0.0", "tol:0.0", 
                           "tolu:0.0", "vivpo1:0.0", "vlvoo1:0.0", "vlvoo2:0.0", "vlvpo1:0.0", 
                           "vsvoo1:0.0", "vsvoo2:0.0", "vsvoo3:0.0", "vsvpo1:0.0", "vsvpo2:0.0", 
                           "vsvpo3:0.0", "xopn:0.0", "xylmn:0.0", "*:0.2" ]
        })
    settings["gfs_physics_nml"] = gfs_physics_nml_dict

    #
    # Add to "settings" the values of those namelist variables that specify
    # the paths to fixed files in the FIXam directory.  As above, these namelist
    # variables are physcs-suite-independent.
    #
    # Note that the array FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING contains
    # the mapping between the namelist variables and the names of the files
    # in the FIXam directory.  Here, we loop through this array and process
    # each element to construct each line of "settings".
    #
    dummy_run_dir = os.path.join(EXPTDIR, "any_cyc")
    if DO_ENSEMBLE:
        dummy_run_dir = os.path.join(dummy_run_dir, "any_ensmem")

    regex_search = "^[ ]*([^| ]+)[ ]*[|][ ]*([^| ]+)[ ]*$"
    num_nml_vars = len(FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING)
    namsfc_dict = {}
    for i in range(num_nml_vars):

        mapping = f"{FV3_NML_VARNAME_TO_FIXam_FILES_MAPPING[i]}"
        tup = find_pattern_in_str(regex_search, mapping)
        nml_var_name = tup[0]
        FIXam_fn = tup[1]

        fp = '""'
        if FIXam_fn:
            fp = os.path.join(FIXam, FIXam_fn)
            #
            # If not in NCO mode, for portability and brevity, change fp so that it
            # is a relative path (relative to any cycle directory immediately under
            # the experiment directory).
            #
            if RUN_ENVIR != "nco":
                fp = os.path.relpath(os.path.realpath(fp), start=dummy_run_dir)
        #
        # Add a line to the variable "settings" that specifies (in a yaml-compliant
        # format) the name of the current namelist variable and the value it should
        # be set to.
        #
        namsfc_dict[nml_var_name] = fp
    #
    # Add namsfc_dict to settings
    #
    settings["namsfc"] = namsfc_dict
    #
    # Use netCDF4 when running the North American 3-km domain due to file size.
    #
    if PREDEF_GRID_NAME == "RRFS_NA_3km":
        settings["fms2_io_nml"] = {"netcdf_default_format": "netcdf4"}
    #
    # Add the relevant tendency-based stochastic physics namelist variables to
    # "settings" when running with SPPT, SHUM, or SKEB turned on. If running
    # with SPP or LSM SPP, set the "new_lscale" variable.  Otherwise only
    # include an empty "nam_stochy" stanza.
    #
    nam_stochy_dict = {}
    if DO_SPPT:
        nam_stochy_dict.update(
            {
                "iseed_sppt": ISEED_SPPT,
                "new_lscale": NEW_LSCALE,
                "sppt": SPPT_MAG,
                "sppt_logit": SPPT_LOGIT,
                "sppt_lscale": SPPT_LSCALE,
                "sppt_sfclimit": SPPT_SFCLIMIT,
                "sppt_tau": SPPT_TSCALE,
                "spptint": SPPT_INT,
                "use_zmtnblck": USE_ZMTNBLCK,
            }
        )

    if DO_SHUM:
        nam_stochy_dict.update(
            {
                "iseed_shum": ISEED_SHUM,
                "new_lscale": NEW_LSCALE,
                "shum": SHUM_MAG,
                "shum_lscale": SHUM_LSCALE,
                "shum_tau": SHUM_TSCALE,
                "shumint": SHUM_INT,
            }
        )

    if DO_SKEB:
        nam_stochy_dict.update(
            {
                "iseed_skeb": ISEED_SKEB,
                "new_lscale": NEW_LSCALE,
                "skeb": SKEB_MAG,
                "skeb_lscale": SKEB_LSCALE,
                "skebnorm": SKEBNORM,
                "skeb_tau": SKEB_TSCALE,
                "skebint": SKEB_INT,
                "skeb_vdof": SKEB_VDOF,
            }
        )

    if DO_SPP or DO_LSM_SPP:
        nam_stochy_dict.update({"new_lscale": NEW_LSCALE})

    settings["nam_stochy"] = nam_stochy_dict
    #
    # Add the relevant SPP namelist variables to "settings" when running with
    # SPP turned on.  Otherwise only include an empty "nam_sppperts" stanza.
    #
    nam_sppperts_dict = {}
    if DO_SPP:
        nam_sppperts_dict = {
            "iseed_spp": ISEED_SPP,
            "spp_lscale": SPP_LSCALE,
            "spp_prt_list": SPP_MAG_LIST,
            "spp_sigtop1": SPP_SIGTOP1,
            "spp_sigtop2": SPP_SIGTOP2,
            "spp_stddev_cutoff": SPP_STDDEV_CUTOFF,
            "spp_tau": SPP_TSCALE,
            "spp_var_list": SPP_VAR_LIST,
        }

    settings["nam_sppperts"] = nam_sppperts_dict
    #
    # Add the relevant LSM SPP namelist variables to "settings" when running with
    # LSM SPP turned on.
    #
    nam_sfcperts_dict = {}
    if DO_LSM_SPP:
        nam_sfcperts_dict = {
            "lndp_type": LNDP_TYPE,
            "lndp_model_type": LNDP_MODEL_TYPE,
            "lndp_tau": LSM_SPP_TSCALE,
            "lndp_lscale": LSM_SPP_LSCALE,
            "iseed_lndp": ISEED_LSM_SPP,
            "lndp_var_list": LSM_SPP_VAR_LIST,
            "lndp_prt_list": LSM_SPP_MAG_LIST,
        }

    settings["nam_sfcperts"] = nam_sfcperts_dict

    settings_str = cfg_to_yaml_str(settings)

    log_info(
        f"""
        The variable 'settings' specifying values of the weather model's
        namelist variables has been set as follows:\n""",
        verbose=verbose,
    )
    log_info("\nsettings =\n\n" + settings_str, verbose=verbose)
    #
    # -----------------------------------------------------------------------
    #
    # Call the set_namelist.py script to create a new FV3 namelist file (full
    # path specified by FV3_NML_FP) using the file FV3_NML_BASE_SUITE_FP as
    # the base (i.e. starting) namelist file, with physics-suite-dependent
    # modifications to the base file specified in the yaml configuration file
    # FV3_NML_YAML_CONFIG_FP (for the physics suite specified by CCPP_PHYS_SUITE),
    # and with additional physics-suite-independent modifications specified
    # in the variable "settings" set above.
    #
    # -----------------------------------------------------------------------
    #
    try:
        set_namelist(
            [
                "-q",
                "-n",
                FV3_NML_BASE_SUITE_FP,
                "-c",
                FV3_NML_YAML_CONFIG_FP,
                CCPP_PHYS_SUITE,
                "-u",
                settings_str,
                "-o",
                FV3_NML_FP,
            ]
        )
    except:
        logging.exception(
            dedent(
                f"""
                Call to python script set_namelist.py to generate an FV3 namelist file
                failed.  Parameters passed to this script are:
                  Full path to base namelist file:
                    FV3_NML_BASE_SUITE_FP = '{FV3_NML_BASE_SUITE_FP}'
                  Full path to yaml configuration file for various physics suites:
                    FV3_NML_YAML_CONFIG_FP = '{FV3_NML_YAML_CONFIG_FP}'
                  Physics suite to extract from yaml configuration file:
                    CCPP_PHYS_SUITE = '{CCPP_PHYS_SUITE}'
                  Full path to output namelist file:
                    FV3_NML_FP = '{FV3_NML_FP}'
                  Namelist settings specified on command line:\n
                    settings =\n\n"""
            )
            + settings_str
        )
    #
    # If not running the TN_MAKE_GRID task (which implies the workflow will
    # use pregenerated grid files), set the namelist variables specifying
    # the paths to surface climatology files.  These files are located in
    # (or have symlinks that point to them) in the FIXlam directory.
    #
    # Note that if running the TN_MAKE_GRID task, this action usually cannot
    # be performed here but must be performed in that task because the names
    # of the surface climatology files depend on the CRES parameter (which is
    # the C-resolution of the grid), and this parameter is in most workflow
    # configurations is not known until the grid is created.
    #
    if not expt_config['rocoto']['tasks'].get('task_make_grid'):

        set_FV3nml_sfc_climo_filenames()

    #
    # -----------------------------------------------------------------------
    #
    # To have a record of how this experiment/workflow was generated, copy
    # the experiment/workflow configuration file to the experiment directo-
    # ry.
    #
    # -----------------------------------------------------------------------
    #
    cp_vrfy(os.path.join(ushdir, EXPT_CONFIG_FN), EXPTDIR)

    #
    # -----------------------------------------------------------------------
    #
    # For convenience, print out the commands that need to be issued on the
    # command line in order to launch the workflow and to check its status.
    # Also, print out the line that should be placed in the user's cron table
    # in order for the workflow to be continually resubmitted.
    #
    # -----------------------------------------------------------------------
    #
    if WORKFLOW_MANAGER == "rocoto":
        wflow_db_fn = f"{os.path.splitext(WFLOW_XML_FN)[0]}.db"
        rocotorun_cmd = f"rocotorun -w {WFLOW_XML_FN} -d {wflow_db_fn} -v 10"
        rocotostat_cmd = f"rocotostat -w {WFLOW_XML_FN} -d {wflow_db_fn} -v 10"

        log_info(
            f"""
            To launch the workflow, change location to the experiment directory
            (EXPTDIR) and issue the rocotrun command, as follows:

              > cd {EXPTDIR}
              > {rocotorun_cmd}

            To check on the status of the workflow, issue the rocotostat command
            (also from the experiment directory):

              > {rocotostat_cmd}

            Note that:

            1) The rocotorun command must be issued after the completion of each
               task in the workflow in order for the workflow to submit the next
               task(s) to the queue.

            2) In order for the output of the rocotostat command to be up-to-date,
               the rocotorun command must be issued immediately before issuing the
               rocotostat command.

            For automatic resubmission of the workflow (say every {CRON_RELAUNCH_INTVL_MNTS} minutes), the
            following line can be added to the user's crontab (use 'crontab -e' to
            edit the cron table):

            */{CRON_RELAUNCH_INTVL_MNTS} * * * * cd {EXPTDIR} && ./launch_FV3LAM_wflow.sh called_from_cron="TRUE"
            """
        )

    # If we got to this point everything was successful: move the log file to the experiment directory.
    mv_vrfy(logfile, EXPTDIR)

    return EXPTDIR


def setup_logging(logfile: str = "log.generate_FV3LAM_wflow", debug: bool = False) -> None:
    """
    Sets up logging, printing high-priority (INFO and higher) messages to screen, and printing all
    messages with detailed timing and routine info in the specified text file.
    
    If debug = True, print all messages to both screen and log file.
    """
    logging.getLogger().setLevel(logging.DEBUG)

    formatter = logging.Formatter("%(name)-22s %(levelname)-8s %(message)s")

    fh = logging.FileHandler(logfile, mode='w')
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(formatter)
    logging.getLogger().addHandler(fh)
    logging.debug(f"Finished setting up debug file logging in {logfile}")

    # If there are already multiple handlers, that means generate_FV3LAM_workflow was called from another function.
    # In that case, do not change the console (print-to-screen) logging.
    if len(logging.getLogger().handlers) > 1:
        return

    console = logging.StreamHandler()
    if debug:
        console.setLevel(logging.DEBUG)
    else:
        console.setLevel(logging.INFO)
    logging.getLogger().addHandler(console)
    logging.debug("Logging set up successfully")


if __name__ == "__main__":

    USHdir = os.path.dirname(os.path.abspath(__file__))
    wflow_logfile = f"{USHdir}/log.generate_FV3LAM_wflow"

    # Call the generate_FV3LAM_wflow function defined above to generate the
    # experiment/workflow.
    try:
        expt_dir = generate_FV3LAM_wflow(USHdir, wflow_logfile)
    except:
        logging.exception(
            dedent(
                f"""
                *********************************************************************
                FATAL ERROR:
                Experiment generation failed. See the error message(s) printed below.
                For more detailed information, check the log file from the workflow
                generation script: {wflow_logfile}
                *********************************************************************\n
                """
            )
        )
        raise
    
    # Note workflow generation completion
    log_info(
        f"""
        ========================================================================
        ========================================================================

        Experiment generation completed.  The experiment directory is:

          EXPTDIR='{EXPTDIR}'

        ========================================================================
        ========================================================================
        """
    )


class Testing(unittest.TestCase):
    def test_generate_FV3LAM_wflow(self):

        # run workflows in separate process to avoid conflict between community and nco settings
        def run_workflow(USHdir, logfile):
            p = Process(target=generate_FV3LAM_wflow, args=(USHdir, logfile))
            p.start()
            p.join()
            exit_code = p.exitcode
            if exit_code != 0:
                sys.exit(exit_code)

        USHdir = os.path.dirname(os.path.abspath(__file__))
        logfile = "log.generate_FV3LAM_wflow"
        SED = get_env_var("SED")

        # community test case
        cp_vrfy(f"{USHdir}/config.community.yaml", f"{USHdir}/config.yaml")
        run_command(
            f"""{SED} -i 's/MACHINE: hera/MACHINE: linux/g' {USHdir}/config.yaml"""
        )
        run_workflow(USHdir, logfile)

        # nco test case
        nco_test_config = load_config_file(f"{USHdir}/config.nco.yaml")
        # Since we don't have a pre-gen grid dir on a generic linux
        # platform, turn the make_* tasks on for this test.
        cfg_updates = {
            "user": {
                "MACHINE": "linux",
            },
            "rocoto": {
                "tasks": {
                    "taskgroups": \
                        '\'{{ ["parm/wflow/prep.yaml","parm/wflow/coldstart.yaml", "parm/wflow/post.yaml"]|include }}\''
                },
            },
        }
        update_dict(cfg_updates, nco_test_config)

        with open(f"{USHdir}/config.yaml", "w") as cfg_file:
            cfg_file.write(cfg_to_yaml_str(nco_test_config))

        run_workflow(USHdir, logfile)

    def setUp(self):
        define_macos_utilities()
        set_env_var("DEBUG", False)
        set_env_var("VERBOSE", False)
