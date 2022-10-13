#!/usr/bin/env python3

import os
import sys
import platform
import subprocess
import unittest
from multiprocessing import Process
from textwrap import dedent
from datetime import datetime, timedelta

from python_utils import (
    print_info_msg,
    print_err_msg_exit,
    import_vars,
    cp_vrfy,
    cd_vrfy,
    rm_vrfy,
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
)

from setup import setup
from set_FV3nml_sfc_climo_filenames import set_FV3nml_sfc_climo_filenames
from get_crontab_contents import add_crontab_line
from fill_jinja_template import fill_jinja_template
from set_namelist import set_namelist


def python_error_handler():
    """Error handler for missing packages"""

    print_err_msg_exit(
        """
        Errors found: check your python environment

        Instructions for setting up python environments can be found on the web:
        https://github.com/ufs-community/ufs-srweather-app/wiki/Getting-Started
        """,
        stack_trace=False,
    )


# Check for non-standard python packages
try:
    import jinja2
    import yaml
    import f90nml
except ImportError as error:
    print_info_msg(error.__class__.__name__ + ": " + str(error))
    python_error_handler()


def generate_FV3LAM_wflow():
    """Function to setup a forecast experiment and create a workflow
    (according to the parameters specified in the config file

    Args:
        None
    Returns:
        None
    """

    print(
        dedent(
            """
        ========================================================================
        ========================================================================

        Starting experiment generation...

        ========================================================================
        ========================================================================"""
        )
    )

    # set USHdir
    USHdir = os.path.dirname(os.path.abspath(__file__))

    # check python version
    major, minor, patch = platform.python_version_tuple()
    if int(major) < 3 or int(minor) < 6:
        print_info_msg(
            f"""

            Error: python version must be 3.6 or higher
            python version: {major}.{minor}"""
        )

    # define macros
    define_macos_utilities()

    #
    # -----------------------------------------------------------------------
    #
    # Source the file that defines and then calls the setup function.  The
    # setup function in turn first sources the default configuration file
    # (which contains default values for the experiment/workflow parameters)
    # and then sources the user-specified configuration file (which contains
    # user-specified values for a subset of the experiment/workflow parame-
    # ters that override their default values).
    #
    # -----------------------------------------------------------------------
    #
    setup()

    # import all environment variables
    import_vars()

    #
    # -----------------------------------------------------------------------
    #
    # Set the full path to the experiment's rocoto workflow xml file.  This
    # file will be placed at the top level of the experiment directory and
    # then used by rocoto to run the workflow.
    #
    # -----------------------------------------------------------------------
    #
    WFLOW_XML_FP = os.path.join(EXPTDIR, WFLOW_XML_FN)

    #
    # -----------------------------------------------------------------------
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the jinja variables in the template rocoto
    # XML should be set to.  These values are set either in the user-specified
    # workflow configuration file (EXPT_CONFIG_FN) or in the setup.sh script
    # sourced above.  Then call the python script that generates the XML.
    #
    # -----------------------------------------------------------------------
    #
    if WORKFLOW_MANAGER == "rocoto":

        template_xml_fp = os.path.join(PARMdir, WFLOW_XML_FN)

        print_info_msg(
            f'''
            Creating rocoto workflow XML file (WFLOW_XML_FP) from jinja template XML
            file (template_xml_fp):
              template_xml_fp = \"{template_xml_fp}\"
              WFLOW_XML_FP = \"{WFLOW_XML_FP}\"'''
        )

        ensmem_indx_name = ""
        uscore_ensmem_name = ""
        slash_ensmem_subdir = ""
        if DO_ENSEMBLE:
            ensmem_indx_name = "mem"
            uscore_ensmem_name = f"_mem#{ensmem_indx_name}#"
            slash_ensmem_subdir = f"/mem#{ensmem_indx_name}#"

        #
        # Call the python script to generate the experiment's actual XML file
        # from the jinja template file.
        #
        try:
            fill_jinja_template(
                ["-q", "-u", settings_str, "-t", template_xml_fp, "-o", WFLOW_XML_FP]
            )
        except:
            print_err_msg_exit(
                dedent(
                    f"""
                Call to python script xml_creator.py to create a rocoto workflow
                XML failed.  Parameters passed to this script are:
                    WFLOW_XML_FP = \"{WFLOW_XML_FP}\"
                  Entities:\n
                    entities =\n\n"""
                )
                + '\n'.join([f"{key}: {value}" for key, value in entities.items()]),
            )
    #
    # -----------------------------------------------------------------------
    #
    # Create a symlink in the experiment directory that points to the workflow
    # (re)launch script.
    #
    # -----------------------------------------------------------------------
    #
    print_info_msg(
        f'''
        Creating symlink in the experiment directory (EXPTDIR) that points to the
        workflow launch script (WFLOW_LAUNCH_SCRIPT_FP):
          EXPTDIR = \"{EXPTDIR}\"
          WFLOW_LAUNCH_SCRIPT_FP = \"{WFLOW_LAUNCH_SCRIPT_FP}\"''',
        verbose=VERBOSE,
    )

    create_symlink_to_file(
        WFLOW_LAUNCH_SCRIPT_FP, os.path.join(EXPTDIR, WFLOW_LAUNCH_SCRIPT_FN), False
    )
    #
    # -----------------------------------------------------------------------
    #
    # If USE_CRON_TO_RELAUNCH is set to TRUE, add a line to the user's cron
    # table to call the (re)launch script every CRON_RELAUNCH_INTVL_MNTS mi-
    # nutes.
    #
    # -----------------------------------------------------------------------
    #
    if USE_CRON_TO_RELAUNCH:
        add_crontab_line()
    #
    # -----------------------------------------------------------------------
    #
    # Create the FIXam directory under the experiment directory.  In NCO mode,
    # this will be a symlink to the directory specified in FIXgsm, while in
    # community mode, it will be an actual directory with files copied into
    # it from FIXgsm.
    #
    # -----------------------------------------------------------------------
    #

    #
    # Symlink fix files
    #
    if SYMLINK_FIX_FILES:

        print_info_msg(
            f'''
            Symlinking fixed files from system directory (FIXgsm) to a subdirectory (FIXam):
              FIXgsm = \"{FIXgsm}\"
              FIXam = \"{FIXam}\"''',
            verbose=VERBOSE,
        )

        ln_vrfy(f'''-fsn "{FIXgsm}" "{FIXam}"''')
    #
    # Copy relevant fix files.
    #
    else:

        print_info_msg(
            f'''
            Copying fixed files from system directory (FIXgsm) to a subdirectory (FIXam):
              FIXgsm = \"{FIXgsm}\"
              FIXam = \"{FIXam}\"''',
            verbose=VERBOSE,
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
        print_info_msg(
            f'''
            Copying MERRA2 aerosol climatology data files from system directory
            (FIXaer/FIXlut) to a subdirectory (FIXclim) in the experiment directory:
              FIXaer = \"{FIXaer}\"
              FIXlut = \"{FIXlut}\"
              FIXclim = \"{FIXclim}\"''',
            verbose=VERBOSE,
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
    print_info_msg(
        f"""
        Copying templates of various input files to the experiment directory...""",
        verbose=VERBOSE,
    )

    print_info_msg(
        f"""
        Copying the template data table file to the experiment directory...""",
        verbose=VERBOSE,
    )
    cp_vrfy(DATA_TABLE_TMPL_FP, DATA_TABLE_FP)

    print_info_msg(
        f"""
        Copying the template field table file to the experiment directory...""",
        verbose=VERBOSE,
    )
    cp_vrfy(FIELD_TABLE_TMPL_FP, FIELD_TABLE_FP)

    print_info_msg(
        f"""
        Copying the template NEMS configuration file to the experiment directory...""",
        verbose=VERBOSE,
    )
    cp_vrfy(NEMS_CONFIG_TMPL_FP, NEMS_CONFIG_FP)
    #
    # Copy the CCPP physics suite definition file from its location in the
    # clone of the FV3 code repository to the experiment directory (EXPT-
    # DIR).
    #
    print_info_msg(
        f"""
        Copying the CCPP physics suite definition XML file from its location in
        the forecast model directory sturcture to the experiment directory...""",
        verbose=VERBOSE,
    )
    cp_vrfy(CCPP_PHYS_SUITE_IN_CCPP_FP, CCPP_PHYS_SUITE_FP)
    #
    # Copy the field dictionary file from its location in the
    # clone of the FV3 code repository to the experiment directory (EXPT-
    # DIR).
    #
    print_info_msg(
        f"""
        Copying the field dictionary file from its location in the forecast
        model directory sturcture to the experiment directory...""",
        verbose=VERBOSE,
    )
    cp_vrfy(FIELD_DICT_IN_UWM_FP, FIELD_DICT_FP)
    #
    # -----------------------------------------------------------------------
    #
    # Set parameters in the FV3-LAM namelist file.
    #
    # -----------------------------------------------------------------------
    #
    print_info_msg(
        f'''
        Setting parameters in weather model's namelist file (FV3_NML_FP):
        FV3_NML_FP = \"{FV3_NML_FP}\"'''
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
    # NOTE:
    # May want to remove kice from FV3.input.yml (and maybe input.nml.FV3).
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
    settings["fv_core_nml"] = {
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
    }
    settings["gfs_physics_nml"] = {
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
    }
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

    print_info_msg(
        dedent(
            f"""
            The variable \"settings\" specifying values of the weather model's
            namelist variables has been set as follows:

            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )
    #
    # -----------------------------------------------------------------------
    #
    # Call the set_namelist.py script to create a new FV3 namelist file (full
    # path specified by FV3_NML_FP) using the file FV3_NML_BASE_SUITE_FP as
    # the base (i.e. starting) namelist file, with physics-suite-dependent
    # modifications to the base file specified in the yaml configuration file
    # FV3_NML_YAML_CONFIG_FP (for the physics suite specified by CCPP_PHYS_SUITE),
    # and with additional physics-suite-independent modificaitons specified
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
        print_err_msg_exit(
            dedent(
                f"""
            Call to python script set_namelist.py to generate an FV3 namelist file
            failed.  Parameters passed to this script are:
              Full path to base namelist file:
                FV3_NML_BASE_SUITE_FP = \"{FV3_NML_BASE_SUITE_FP}\"
              Full path to yaml configuration file for various physics suites:
                FV3_NML_YAML_CONFIG_FP = \"{FV3_NML_YAML_CONFIG_FP}\"
              Physics suite to extract from yaml configuration file:
                CCPP_PHYS_SUITE = \"{CCPP_PHYS_SUITE}\"
              Full path to output namelist file:
                FV3_NML_FP = \"{FV3_NML_FP}\"
              Namelist settings specified on command line:\n
                settings =\n\n"""
            )
            + settings_str
        )
    #
    # If not running the MAKE_GRID_TN task (which implies the workflow will
    # use pregenerated grid files), set the namelist variables specifying
    # the paths to surface climatology files.  These files are located in
    # (or have symlinks that point to them) in the FIXlam directory.
    #
    # Note that if running the MAKE_GRID_TN task, this action usually cannot
    # be performed here but must be performed in that task because the names
    # of the surface climatology files depend on the CRES parameter (which is
    # the C-resolution of the grid), and this parameter is in most workflow
    # configurations is not known until the grid is created.
    #
    if not RUN_TASK_MAKE_GRID:

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
    cp_vrfy(os.path.join(USHdir, EXPT_CONFIG_FN), EXPTDIR)
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

    print_info_msg(
        f"""
        ========================================================================
        ========================================================================

        Experiment generation completed.  The experiment directory is:

          EXPTDIR=\"{EXPTDIR}\"

        ========================================================================
        ========================================================================
        """
    )
    #
    # -----------------------------------------------------------------------
    #
    # If rocoto is required, print instructions on how to load and use it
    #
    # -----------------------------------------------------------------------
    #
    if WORKFLOW_MANAGER == "rocoto":

        print_info_msg(
            f"""
            To launch the workflow, first ensure that you have a compatible version
            of rocoto available. For most pre-configured platforms, rocoto can be
            loaded via a module:

              > module load rocoto

            For more details on rocoto, see the User's Guide.

            To launch the workflow, first ensure that you have a compatible version
            of rocoto loaded.  For example, to load version 1.3.1 of rocoto, use

              > module load rocoto/1.3.1

            (This version has been tested on hera; later versions may also work but
            have not been tested.)

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

            For automatic resubmission of the workflow (say every 3 minutes), the
            following line can be added to the user's crontab (use \"crontab -e\" to
            edit the cron table):

            */{CRON_RELAUNCH_INTVL_MNTS} * * * * cd {EXPTDIR} && ./launch_FV3LAM_wflow.sh called_from_cron=\"TRUE\"
            """
        )
    #
    # If necessary, run the NOMADS script to source external model data.
    #
    if NOMADS:
        print("Getting NOMADS online data")
        print(f"NOMADS_file_type= {NOMADS_file_type}")
        cd_vrfy(EXPTDIR)
        NOMADS_script = os.path.join(USHdir, "NOMADS_get_extrn_mdl_files.h")
        run_command(
            f"""{NOMADS_script} {date_to_str(DATE_FIRST_CYCL,format="%Y%m%d")} \
                      {date_to_str(DATE_FIRST_CYCL,format="%H"} {NOMADS_file_type} {FCST_LEN_HRS} {LBC_SPEC_INTVL_HRS}"""
        )


#
# -----------------------------------------------------------------------
#
# Start of the script that will call the experiment/workflow generation
# function defined above.
#
# -----------------------------------------------------------------------
#
if __name__ == "__main__":
    #
    # -----------------------------------------------------------------------
    #
    # Set directories.
    #
    # -----------------------------------------------------------------------
    #
    USHdir = os.path.dirname(os.path.abspath(__file__))
    #
    # Set the name of and full path to the temporary file in which we will
    # save some experiment/workflow variables.  The need for this temporary
    # file is explained below.
    #
    tmp_fn = "tmp"
    tmp_fp = os.path.join(USHdir, tmp_fn)
    rm_vrfy("-f", tmp_fp)
    #
    # Set the name of and full path to the log file in which the output from
    # the experiment/workflow generation function will be saved.
    #
    log_fn = "log.generate_FV3LAM_wflow"
    log_fp = os.path.join(USHdir, log_fn)
    rm_vrfy("-f", log_fp)
    #
    # Call the generate_FV3LAM_wflow function defined above to generate the
    # experiment/workflow.  Note that we pipe the output of the function
    # (and possibly other commands) to the "tee" command in order to be able
    # to both save it to a file and print it out to the screen (stdout).
    # The piping causes the call to the function (and the other commands
    # grouped with it using the curly braces, { ... }) to be executed in a
    # subshell.  As a result, the experiment/workflow variables that the
    # function sets are not available outside of the grouping, i.e. they are
    # not available at and after the call to "tee".  Since some of these va-
    # riables are needed after the call to "tee" below, we save them in a
    # temporary file and read them in outside the subshell later below.
    #
    def workflow_func():
        retval = 1
        generate_FV3LAM_wflow()
        retval = 0
        run_command(f'''echo "{EXPTDIR}" >> "{tmp_fp}"''')
        run_command(f'''echo "{retval}" >> "{tmp_fp}"''')

    # create tee functionality
    tee = subprocess.Popen(["tee", log_fp], stdin=subprocess.PIPE)
    os.dup2(tee.stdin.fileno(), sys.stdout.fileno())
    os.dup2(tee.stdin.fileno(), sys.stderr.fileno())

    # create workflow process
    p = Process(target=workflow_func)
    p.start()
    p.join()

    #
    # Read in experiment/workflow variables needed later below from the tem-
    # porary file created in the subshell above containing the call to the
    # generate_FV3LAM_wflow function.  These variables are not directly
    # available here because the call to generate_FV3LAM_wflow above takes
    # place in a subshell (due to the fact that we are then piping its out-
    # put to the "tee" command).  Then remove the temporary file.
    #
    (_, exptdir, _) = run_command(f'''sed "1q;d" "{tmp_fp}"''')
    (_, retval, _) = run_command(f''' sed "2q;d" "{tmp_fp}"''')
    if retval:
        retval = int(retval)
    else:
        retval = 1
    rm_vrfy(tmp_fp)
    #
    # If the call to the generate_FV3LAM_wflow function above was success-
    # ful, move the log file in which the "tee" command saved the output of
    # the function to the experiment directory.
    #
    if retval == 0:
        mv_vrfy(log_fp, exptdir)
    #
    # If the call to the generate_FV3LAM_wflow function above was not suc-
    # cessful, print out an error message and exit with a nonzero return
    # code.
    #
    else:
        print_err_msg_exit(
            f"""
            Experiment generation failed.  Check the log file from the ex-
            periment/workflow generation script in the file specified by log_fp:
              log_fp = \"{log_fp}\"
            Stopping."""
        )

class Testing(unittest.TestCase):
    def test_generate_FV3LAM_wflow(self):

        # run workflows in separate process to avoid conflict
        def workflow_func():
            generate_FV3LAM_wflow()

        def run_workflow():
            p = Process(target=workflow_func)
            p.start()
            p.join()
            exit_code = p.exitcode
            if exit_code != 0:
                sys.exit(exit_code)

        USHdir = os.path.dirname(os.path.abspath(__file__))
        SED = get_env_var("SED")

        # community test case
        cp_vrfy(f"{USHdir}/config.community.yaml", f"{USHdir}/config.yaml")
        run_command(f"""{SED} -i 's/MACHINE: hera/MACHINE: linux/g' {USHdir}/config.yaml""")
        run_workflow()

        # nco test case
        set_env_var("OPSROOT", f"{USHdir}/../../nco_dirs")
        cp_vrfy(f"{USHdir}/config.nco.yaml", f"{USHdir}/config.yaml")
        run_command(f"""{SED} -i 's/MACHINE: hera/MACHINE: linux/g' {USHdir}/config.yaml""")
        run_workflow()

    def setUp(self):
        define_macos_utilities()
        set_env_var("DEBUG", False)
        set_env_var("VERBOSE", False)
