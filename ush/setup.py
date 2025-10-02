#!/usr/bin/env python3

"""
Read in the configuration YAMLs and prepare a self-consistent
experiment configuration file.
"""

# pylint: disable=too-many-lines, too-many-branches, logging-fstring-interpolation

import datetime
import logging
import os
import re
import sys
from io import StringIO
from pathlib import Path
from textwrap import dedent


from uwtools.api.config import get_ini_config, get_yaml_config, validate
from uwtools.api.template import render

from link_fix import link_fix
from python_utils import (
    dict_find,
    check_for_preexist_dir_file,
    has_tag_with_value,
    load_xml_file,
)

from set_cycle_and_obs_timeinfo import (
    set_cycle_dates,
    set_fcst_output_times_and_obs_days_all_cycles,
    set_rocoto_cycledefs_for_obs_days,
    check_temporal_consistency_cumul_fields,
    get_obs_retrieve_times_by_day,
)
from set_predef_grid_params import set_predef_grid_params
from set_gridparams_ESGgrid import set_gridparams_ESGgrid


def load_config_for_setup(ushdir, default_config_path, user_config_path):
    """Load in the default, machine, and user configuration files into
    Python dictionaries. Return the combined experiment dictionary.

    Args:
      ushdir             (str): Path to the ``ush`` directory for the SRW App
      default_config     (str): Path to ``config_defaults.yaml``
      user_config        (str): Path to the user-provided config YAML (usually named
                                ``config.yaml``)

    Returns:
        The combined, schema-checked experiment Config object.

    Raises:
        FileNotFoundError: If the user-provided configuration file or the machine file does not
                           exist.
        Exception: If (1) the user-provided configuration file cannot be loaded or (2) it contains
                   invalid sections/keys or (3) it does not contain mandatory information or (4)
                   an invalid datetime format is used.
    """

    ushdir = Path(ushdir)

    # Load the default and user configs.
    logging.debug(f"Loading config defaults file {default_config_path}")
    default_config = get_yaml_config(default_config_path)
    logging.debug("Read in the following values from config defaults file:\n")
    logging.debug(default_config)

    user_config = get_yaml_config(user_config_path)
    logging.debug(
        f"Read in the following values from YAML config file {user_config}:\n"
    )
    logging.debug(user_config)

    # Check user config against experiment schema
    schema = ushdir / "user.jsonschema"
    valid = validate(schema_file=schema, config_data=user_config)

    if not valid:
        logging.error("User configuration is not valid against schema")
        sys.exit(1)

    # Load the machine config file
    machine = user_config["user"]["MACHINE"].upper()
    user_config["user"]["MACHINE"] = machine

    machine_file = ushdir / "machine" / f"{machine.lower()}.yaml"

    if not machine_file.exists():
        raise FileNotFoundError(
            dedent(
                f"""
            The machine file {machine_file} does not exist.
            Check that you have specified the correct machine
            ({machine}) in your config file {user_config}"""
            )
        )
    logging.debug(f"Loading machine defaults file {machine_file}")
    machine_config = get_yaml_config(machine_file)

    # Load the fixed files configuration
    fix_file_config = get_yaml_config(
        ushdir.parent / "parm" / "fixed_files_mapping.yaml"
    )

    # Load the constants file
    constants = get_yaml_config(ushdir / "constants.yaml")

    # Load the rocoto workflow default file
    default_workflow = ushdir.parent / "parm" / "wflow" / "default_workflow.yaml"
    workflow_config = get_yaml_config(default_workflow)

    # Update default config with other loaded config file. Order matters.
    for cfg in (
        constants,
        workflow_config,
        machine_config,
        fix_file_config,
        user_config,
    ):
        default_config.update_from(cfg)

    # Set the path to the top-level ufs-srweather-app directory
    homedir = Path(__file__).parent.parent.resolve()
    default_config["user"]["HOMEdir"] = str(homedir)

    # Expand out the workflow tasks now that all settings have been applied
    taskgroups = default_config["workflow"]["taskgroups"]
    default_config["rocoto"]["tasks"] = {}
    for taskgroup in taskgroups:
        tasks = get_yaml_config(homedir / taskgroup)
        keep = {k: v for k, v in tasks.items() if not re.search(r"^default_*", k)}
        default_config["rocoto"]["tasks"].update(keep)

    # Update one more time in case there are user or machine settings to override the tasks
    for cfg in (machine_config, user_config):
        default_config.update_from(cfg)

    # Special logic if EXPT_BASEDIR is a relative path; see config_defaults.yaml for explanation
    expt_basedir = default_config["workflow"]["EXPT_BASEDIR"]
    if not expt_basedir:
        expt_basedir = homedir.parent / "expt_dirs" / expt_basedir
    elif expt_basedir[0] != "/":
        expt_basedir = homedir.parent / "expt_dirs" / expt_basedir
    default_config["workflow"]["EXPT_BASEDIR"] = str(Path(expt_basedir).resolve())

    # Dereference all Jinja expressions
    default_config.dereference(
        context={
            "today": datetime.date.today(),
            "timedelta": datetime.timedelta,
            **default_config,
            }
        )

    # Validate experiment config against schema
    schema = ushdir / "experiment.jsonschema"
    valid = validate(schema_file=schema, config_data=default_config)

    if not valid:
        logging.error("Experiment configuration is not valid against schema")
        sys.exit(1)

    return default_config


def set_srw_paths(expt_config):
    """
    Generates a dictionary of directories that describe the SRW App
    structure, i.e., where the SRW App is installed and the paths to
    external repositories managed via the ``manage_externals`` tool.

    Other paths for the SRW App are set as defaults in ``config_defaults.yaml``.

    Args:
        expt_config (dict): Contains the configuration settings for the user-defined experiment

    Returns:
        Dictionary of configuration settings and system paths as keys/values

    Raises:
        KeyError: If the external repository required is not listed in the externals
                  configuration file (e.g., ``Externals.cfg``)
        FileNotFoundError: If the ``ufs-weather-model`` code containing the FV3 source code has
                           not been cloned properly
    """

    # HOMEdir is the location of the SRW clone, one directory above ush/
    homedir = Path(expt_config["user"]["HOMEdir"])

    # Read Externals.cfg
    externals_config_fn = homedir / "Externals.cfg"
    externals_config = get_ini_config(externals_config_fn)

    # Get the base directory of the FV3 forecast model code.
    external_name = expt_config["workflow"]["FCST_MODEL"]
    property_name = "local_path"

    try:
        ufs_wthr_mdl_dir = externals_config[external_name][property_name]
    except KeyError:
        errmsg = dedent(
            f"""
            Externals configuration file {str(externals_config_fn)}
            does not contain '{external_name}'."""
        )
        raise ValueError(errmsg) from None

    # Check that the model code has been downloaded
    ufs_wthr_mdl_dir = homedir / ufs_wthr_mdl_dir
    if not ufs_wthr_mdl_dir.exists:
        raise FileNotFoundError(
            dedent(
                f"""
                The base directory in which the FV3 source code should be located
                (UFS_WTHR_MDL_DIR) does not exist:
                  UFS_WTHR_MDL_DIR = '{ufs_wthr_mdl_dir}'
                Please clone the external repository containing the code in this directory,
                build the executable, and then rerun the workflow."""
            )
        )

    return {
        "UFS_WTHR_MDL_DIR": (str(ufs_wthr_mdl_dir)),
    }


def setup(ushdir, user_config_fn="config.yaml", debug: bool = False):
    # pylint: disable=too-many-statements
    """Validates user-provided configuration settings and derives
    a secondary set of parameters needed to configure a Rocoto-based SRW App
    workflow. The secondary parameters are derived from a set of required
    parameters defined in ``config_defaults.yaml``, a user-provided
    configuration file (e.g., ``config.yaml``), or a YAML machine file.

    A set of global variable definitions is saved to the experiment
    directory as a bash configure file that is sourced by scripts at run
    time.

    Args:
        ushdir          (str): The full path of the ``ush/`` directory where this script
                               (``setup.py``) is located
        user_config_fn  (str): The name of a user-provided configuration YAML (usually
                               ``config.yaml``)
        debug          (bool): Enable extra output for debugging

    Returns:
        None

    Raises:
        ValueError: If checked configuration values are invalid (e.g., forecast length,
                    ``EXPTDIR`` path)
        FileExistsError: If ``EXPTDIR`` already exists, and ``PREEXISTING_DIR_METHOD`` is not
                         set to a compatible handling method
        FileNotFoundError: If the path to a particular file does not exist or if the file itself
                           does not exist at the expected path
        TypeError: If ``USE_CUSTOM_POST_CONFIG_FILE`` or ``USE_CRTM`` are set to true but no
                   corresponding custom configuration file or CRTM fix file directory is set
        KeyError: If an invalid value is provided (i.e., for ``GRID_GEN_METHOD``)
    """

    logger = logging.getLogger(__name__)

    # print message
    logger.info(
        f"""
        ========================================================================
        Starting function setup() in \"{os.path.basename(__file__)}\"...
        ========================================================================"""
    )

    # Create a dictionary of config options from defaults, machine, and
    # user config files.
    default_config_fp = os.path.join(ushdir, "config_defaults.yaml")
    user_config_fp = os.path.join(ushdir, user_config_fn)
    expt_config = load_config_for_setup(ushdir, default_config_fp, user_config_fp)

    # Load build settings as a dictionary; will be used later to make
    # sure the build is consistent with the user settings
    build_config_fp = Path(expt_config["user"]["EXECdir"], "build_settings.yaml")
    build_config = get_yaml_config(build_config_fp)
    logger.debug(f"Read build configuration from {build_config_fp}\n{build_config}")

    # Fail if build machine and config machine are inconsistent
    if build_config["Machine"].upper() != expt_config["user"]["MACHINE"]:
        logger.critical(
            "ERROR: Machine in build settings file != machine specified in config file"
        )
        logger.critical(f"build machine: {build_config['Machine']}")
        logger.critical(f"config machine: {expt_config['user']['MACHINE']}")
        raise ValueError("Check config settings for correct value for 'machine'")

    # Set up some paths relative to the SRW clone
    expt_config["user"].update(
        {
            "USHdir": ushdir,
            **set_srw_paths(expt_config),
        }
    )
    expt_config.dereference()

    #
    # -----------------------------------------------------------------------
    #
    # Validate the experiment configuration starting with the workflow,
    # then in rough order of the tasks in the workflow
    #
    # -----------------------------------------------------------------------
    #

    # Workflow
    workflow_config = expt_config["workflow"]

    workflow_id = workflow_config["WORKFLOW_ID"]
    logger.info(f"""WORKFLOW ID = {workflow_id}""")

    debug = workflow_config["DEBUG"]
    if debug:
        logger.info(
            """
            Setting VERBOSE to \"TRUE\" because DEBUG has been set to \"TRUE\"..."""
        )
        workflow_config["VERBOSE"] = True

    verbose = workflow_config["VERBOSE"]

    # The forecast length (in integer hours) cannot contain more than 3 characters.
    # Thus, its maximum value is 999.
    fcst_len_hrs_max = 999
    fcst_len_hrs = workflow_config["FCST_LEN_HRS"]
    if fcst_len_hrs > fcst_len_hrs_max:
        raise ValueError(
            f"""
            Forecast length is greater than maximum allowed length:
              FCST_LEN_HRS = {fcst_len_hrs}
              fcst_len_hrs_max = {fcst_len_hrs_max}"""
        )

    #
    # -----------------------------------------------------------------------
    #
    # Set the full path to the experiment directory.  Then check if it already
    # exists and if so, deal with it as specified by PREEXISTING_DIR_METHOD.
    #
    # -----------------------------------------------------------------------
    #

    # Update some paths that include EXPTDIR and EXPT_BASEDIR
    expt_config.dereference()
    exptdir = workflow_config["EXPTDIR"]
    preexisting_dir_method = workflow_config["PREEXISTING_DIR_METHOD"]
    try:
        check_for_preexist_dir_file(exptdir, preexisting_dir_method)
    except ValueError:
        logger.exception(
            f"""
            Check that the following values are valid:
            EXPTDIR {exptdir}
            PREEXISTING_DIR_METHOD {preexisting_dir_method}
            """
        )
        raise
    except FileExistsError:
        errmsg = dedent(
            f"""
            EXPTDIR ({exptdir}) exists, and PREEXISTING_DIR_METHOD = {preexisting_dir_method}

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
    # Set cron table entry for relaunching the workflow if
    # USE_CRON_TO_RELAUNCH is set to TRUE.
    #
    # -----------------------------------------------------------------------
    #
    if workflow_config["USE_CRON_TO_RELAUNCH"]:
        intvl_mnts = workflow_config["CRON_RELAUNCH_INTVL_MNTS"]
        launch_script_fn = workflow_config["WFLOW_LAUNCH_SCRIPT_FN"]
        launch_log_fn = workflow_config["WFLOW_LAUNCH_LOG_FN"]
        workflow_config["CRONTAB_LINE"] = (
            f"""*/{intvl_mnts} * * * * cd {exptdir} && """
            f"""./{launch_script_fn} called_from_cron="TRUE" >> ./{launch_log_fn} 2>&1"""
        )
    #
    # -----------------------------------------------------------------------
    #
    # Check user settings against platform settings
    #
    # -----------------------------------------------------------------------
    #

    # Before setting task flags, ensure we don't have any invalid rocoto tasks
    # (e.g. metatasks with no tasks, tasks with no associated commands)
    clean_rocoto_dict(expt_config["rocoto"]["tasks"])

    rocoto_config = expt_config["rocoto"]
    rocoto_tasks = rocoto_config["tasks"]
    run_make_grid = rocoto_tasks.get("task_make_grid") is not None
    run_make_orog = rocoto_tasks.get("task_make_orog") is not None
    run_make_sfc_climo = rocoto_tasks.get("task_make_sfc_climo") is not None

    # Also set some flags that will be needed later
    run_make_ics = dict_find(rocoto_tasks, "task_make_ics")
    run_make_lbcs = dict_find(rocoto_tasks, "task_make_lbcs")
    run_run_fcst = dict_find(rocoto_tasks, "task_run_fcst")
    run_any_coldstart_task = run_make_ics or \
                             run_make_lbcs or \
                             run_run_fcst
    run_run_post = dict_find(rocoto_tasks, "task_run_post")

    # Necessary tasks are turned on
    pregen_basedir = expt_config["platform"]["DOMAIN_PREGEN_BASEDIR"]
    if pregen_basedir is None and not (
        run_make_grid and run_make_orog and run_make_sfc_climo
    ):
        raise ValueError(
            f"""
            DOMAIN_PREGEN_BASEDIR must be set when any of the following
            tasks are not included in the workflow:
                RUN_MAKE_GRID = {run_make_grid}
                RUN_MAKE_OROG = {run_make_orog}
                RUN_MAKE_SFC_CLIMO = {run_make_sfc_climo}"""
        )

    # A batch system account is specified
    if expt_config["platform"]["WORKFLOW_MANAGER"] != "":
        if not expt_config["user"]["ACCOUNT"]:
            raise ValueError(
                dedent(
                    f"""
                  ACCOUNT must be specified in config or machine file if using a workflow manager.
                  WORKFLOW_MANAGER = {expt_config["platform"].get("WORKFLOW_MANAGER")}\n"""
                )
            )

    def _remove_tag(tasks, tag):
        """Remove the tag for all the tasks in the workflow"""

        if not isinstance(tasks, dict):
            return
        for task, task_settings in tasks.items():
            task_type = task.split("_", maxsplit=1)[0]
            if task_type == "task":
                task_settings.pop(tag, None)
            elif task_type == "metatask":
                _remove_tag(task_settings, tag)

    # Remove all memory tags for platforms that do not support them
    remove_memory = expt_config["platform"]["REMOVE_MEMORY"]
    if remove_memory:
        _remove_tag(rocoto_tasks, "memory")

    # Remove exclusive node usage if not in "platform".yaml
    exclusive = expt_config["platform"].get("EXCLUSIVE")
    if not exclusive:
        _remove_tag(rocoto_tasks, "exclusive")

    for part in ["PARTITION_HPSS", "PARTITION_DEFAULT", "PARTITION_FCST"]:
        partition = expt_config["platform"].get(part)
        if not partition:
            _remove_tag(rocoto_tasks, "partition")

    # When not running subhourly post, remove those tasks, if they exist
    if not expt_config["task_run_post"]["envvars"]["SUB_HOURLY_POST"]:
        post_meta = rocoto_tasks.get("metatask_run_ens_post", {})
        post_meta.pop("metatask_run_sub_hourly_post", None)
        post_meta.pop("metatask_sub_hourly_last_hour_post", None)

    date_first_cycl = workflow_config["DATE_FIRST_CYCL"]
    date_last_cycl = workflow_config["DATE_LAST_CYCL"]
    incr_cycl_freq = workflow_config["INCR_CYCL_FREQ"]

    date_first_cycl_dt = datetime.datetime.strptime(date_first_cycl, "%Y%m%d%H")
    date_last_cycl_dt = datetime.datetime.strptime(date_last_cycl, "%Y%m%d%H")
    cycl_intvl_dt = datetime.timedelta(hours=incr_cycl_freq)
    fcst_len_dt = datetime.timedelta(hours=fcst_len_hrs)
    #
    # -----------------------------------------------------------------------
    #
    # If running cycled experiments (AQM, for now), add a cycledef
    #
    # -----------------------------------------------------------------------
    #
    if expt_config["cpl_aqm_parm"]["CPL_AQM"]:
        date_second_cycle = date_first_cycl_dt + cycl_intvl_dt

        rocoto_config["cycledef"].append({
            "attrs": {"group": "cycled_from_second"},
            "spec": f"{date_second_cycle.strftime('%Y%m%d%H%S')} {date_last_cycl}00 {incr_cycl_freq}", # pylint: disable=line-too-long
            })
    #
    # -----------------------------------------------------------------------
    #
    # If running vx tasks, check and possibly reset values in expt_config
    # and rocoto_config.
    #
    # -----------------------------------------------------------------------
    #
    taskgroups = expt_config["workflow"]["taskgroups"]
    if any("verify" in fn for fn in taskgroups):
        #
        # -----------------------------------------------------------------------
        #
        # Set some variables needed for running checks on and creating new
        # (derived) configuration variables for the verification.
        #
        # -----------------------------------------------------------------------
        #
        vx_config = expt_config["verification"]
        vx_fcst_output_intvl_hrs = vx_config["VX_FCST_OUTPUT_INTVL_HRS"]
        vx_fcst_output_intvl_dt = datetime.timedelta(hours=vx_fcst_output_intvl_hrs)

        # Generate a list containing the starting times of the cycles.
        cycle_start_times = set_cycle_dates(
            date_first_cycl_dt, date_last_cycl_dt, cycl_intvl_dt, return_type="datetime"
        )

        # Call function that runs the consistency checks on the vx parameters.
        vx_config, _ = check_temporal_consistency_cumul_fields(
            vx_config, cycle_start_times, fcst_len_dt, vx_fcst_output_intvl_dt
        )

        vx_fcst_output_intvl_hrs = vx_config.get("VX_FCST_OUTPUT_INTVL_HRS")

        # To enable arithmetic with dates and times, convert various time
        # intervals from integer to datetime.timedelta objects.
        fcst_len_dt = datetime.timedelta(hours=fcst_len_hrs)
        vx_fcst_output_intvl_dt = datetime.timedelta(hours=vx_fcst_output_intvl_hrs)
        #
        # -----------------------------------------------------------------------
        #
        # Generate a list of forecast output times and a list of obs days (i.e.
        # days on which observations are needed to perform verification because
        # there is forecast output on those days) over all cycles, both for
        # instantaneous fields (e.g. T2m, REFC, RETOP) and for cumulative ones
        # (e.g. APCP).  Then add these lists to the dictionary containing workflow
        # configuration variables.  These will be needed in generating the ROCOTO
        # XML.
        #
        # -----------------------------------------------------------------------
        #
        (
            fcst_output_times_all_cycles,
            obs_days_all_cycles,
        ) = set_fcst_output_times_and_obs_days_all_cycles(
            cycle_start_times, fcst_len_dt, vx_fcst_output_intvl_dt
        )

        workflow_config["OBS_DAYS_ALL_CYCLES_INST"] = obs_days_all_cycles["inst"]
        workflow_config["OBS_DAYS_ALL_CYCLES_CUMUL"] = obs_days_all_cycles["cumul"]
        #
        # -----------------------------------------------------------------------
        #
        # Generate lists of ROCOTO cycledef strings corresonding to the obs days
        # for instantaneous fields and those for cumulative ones.  Then save the
        # lists of cycledefs in the dictionary containing values needed to
        # construct the ROCOTO XML.
        #
        # -----------------------------------------------------------------------
        #

        cycledefs_obs_days_inst = set_rocoto_cycledefs_for_obs_days(
            obs_days_all_cycles["inst"]
        )
        for spec in cycledefs_obs_days_inst:
            rocoto_config["cycledef"].append({
                "attrs": {"group": "cycledefs_obs_days_inst"},
                "spec": spec,
                })

        cycledefs_obs_days_cumul = set_rocoto_cycledefs_for_obs_days(
            obs_days_all_cycles["cumul"]
        )
        for spec in cycledefs_obs_days_cumul:
            rocoto_config["cycledef"].append({
                "attrs": {"group": "cycledefs_obs_days_cumul"},
                "spec": spec,
                })
        #
        # -----------------------------------------------------------------------
        #
        # Generate dictionary of dictionaries that, for each combination of obs
        # type needed and obs day, contains a string list of the times at which
        # that type of observation is needed on that day.  The elements of each
        # list are formatted as 'YYYYMMDDHH'.  This information is used by the
        # day-based get_obs tasks in the workflow to get obs only at those times
        # at which they are needed (as opposed to for the whole day).
        #
        # -----------------------------------------------------------------------
        #
        obs_retrieve_times_by_day = get_obs_retrieve_times_by_day(
            vx_config,
            cycle_start_times,
            fcst_len_dt,
            fcst_output_times_all_cycles,
            obs_days_all_cycles,
        )

        for obtype, obs_days_dict in obs_retrieve_times_by_day.items():
            for obs_day, obs_retrieve_times in obs_days_dict.items():
                array_name = "_".join(["OBS_RETRIEVE_TIMES", obtype, obs_day])
                vx_config[array_name] = obs_retrieve_times
        expt_config["verification"] = vx_config
        #
        # -----------------------------------------------------------------------
        #
        # Remove all verification (meta)tasks which are not needed for the specified
        # list of verification field groups.
        # Note that if the metatask specification depends on the field group, it
        # does not need to be listed here because those metatasks will be removed
        # later by clean_rocoto_dict()
        #
        # -----------------------------------------------------------------------
        #
        vx_field_groups_all_by_obtype = {}
        vx_metatasks_all_by_obtype = {}

        vx_field_groups_all_by_obtype["CCPA"] = ["APCP"]
        vx_metatasks_all_by_obtype["CCPA"] = [
            "task_get_obs_ccpa",
            "metatask_PcpCombine_APCP_all_accums_obs_CCPA",
            "metatask_PcpCombine_APCP_all_accums_all_mems",
            "metatask_GridStat_APCP_all_accums_all_mems",
            "metatask_GenEnsProd_EnsembleStat_APCP_all_accums",
            "metatask_GridStat_APCP_all_accums_ensmeanprob",
        ]

        vx_field_groups_all_by_obtype["NOHRSC"] = ["ASNOW"]
        vx_metatasks_all_by_obtype["NOHRSC"] = [
            "task_get_obs_nohrsc",
            "metatask_PcpCombine_ASNOW_all_accums_obs_NOHRSC",
            "metatask_PcpCombine_ASNOW_all_accums_all_mems",
            "metatask_GridStat_ASNOW_all_accums_all_mems",
            "metatask_GenEnsProd_EnsembleStat_ASNOW_all_accums",
            "metatask_GridStat_ASNOW_all_accums_ensmeanprob",
        ]

        vx_field_groups_all_by_obtype["MRMS"] = ["REFC", "RETOP"]
        vx_metatasks_all_by_obtype["MRMS"] \
        = ["task_get_obs_mrms",
           "metatask_GridStat_REFC_RETOP_all_mems"]

        vx_field_groups_all_by_obtype["NDAS"] = ["SFC", "UPA"]
        vx_metatasks_all_by_obtype["NDAS"] \
        = ["task_get_obs_ndas",
           "task_run_MET_Pb2nc_obs_NDAS",
           "metatask_PointStat_SFC_UPA_ensmeanprob"]

        vx_field_groups_all_by_obtype["AERONET"] = ["AOD"]
        vx_metatasks_all_by_obtype["AERONET"] \
        = ["task_get_obs_aeronet"]

        vx_field_groups_all_by_obtype["AIRNOW"] = ["PM25", "PM10"]
        vx_metatasks_all_by_obtype["AIRNOW"] \
        = ["task_get_obs_airnow"]

        # If there are no field groups specified for verification, remove those
        # tasks that are common to all observation types.
        vx_field_groups = vx_config["VX_FIELD_GROUPS"]
        if not vx_field_groups:
            metatask = "metatask_check_post_output_all_mems"
            rocoto_config["tasks"].pop(metatask)

        # If for a given obs type none of its field groups are specified for
        # verification, remove all vx metatasks for that obs type.
        for obtype, vx_tasks in vx_field_groups_all_by_obtype.items():
            vx_field_groups_crnt_obtype = list(set(vx_field_groups) & set(vx_tasks))
            if not vx_field_groups_crnt_obtype:
                for metatask in vx_metatasks_all_by_obtype[obtype]:
                    if metatask in rocoto_config["tasks"]:
                        logging.info(
                            dedent(
                                f"""
                            Removing verification (meta)task
                              "{metatask}"
                            from workflow since no field groups from observation type "{obtype}" are
                            specified for verification."""
                            )
                        )
                        rocoto_config["tasks"].pop(metatask)
        #
        # -----------------------------------------------------------------------
        #
        # If there are at least some field groups to verify, then make sure that
        # the base directories in which retrieved obs files will be placed are
        # distinct for the different obs types.
        #
        # -----------------------------------------------------------------------
        #
        if vx_field_groups:
            obtypes_all = ["CCPA", "NOHRSC", "MRMS", "NDAS"]
            obs_basedir_var_names = [f"{obtype}_OBS_DIR" for obtype in obtypes_all]
            obs_basedirs_dict = {key: vx_config[key] for key in obs_basedir_var_names}
            obs_basedirs_orig = list(obs_basedirs_dict.values())
            obs_basedirs_uniq = list(set(obs_basedirs_orig))
            if len(obs_basedirs_orig) != len(obs_basedirs_uniq):
                obs_locations = "\n".join([f"{v} = {p}" for v, p in obs_basedirs_dict.items()])
                msg = dedent(
                    f"""
                    The base directories for the obs files must be distinct, but at least two
                    are identical:
                    {obs_locations}

                    Modify these in the SRW App's user configuration file to make them distinct
                    and rerun.
                    """
                )
                logging.error(msg)
                raise ValueError(msg)

        #
        # -------------------------------------------------------------------
        #
        # Set dependencies for verification tasks that depend on post output
        #
        # -------------------------------------------------------------------
        #
        run_post = rocoto_config["tasks"].get("metatask_run_ens_post")
        run_vx_check = rocoto_config["tasks"].get("metatask_check_post_output_all_mems")
        if not run_post and run_vx_check:
            run_vx_check["task_check_post_output_mem#mem#"]["dependency"] = {
                "or": {
                    "and": {
                      "taskvalid": {"attrs": {"task": "run_fcst__mem#mem#"}},
                      "taskdep": {"attrs": {"task": "run_fcst__mem#mem#"}},
                    },
                    "not": {
                      "taskvalid": {"attrs": {"task": "run_fcst__mem#mem#"}},
                    },
                },
            }


    #
    # -----------------------------------------------------------------------
    #
    # ICS and LBCS settings and validation
    #
    # -----------------------------------------------------------------------
    #
    def _get_location(xcs, fmt, expt_cfg):
        ics_lbcs = expt_cfg.get("data", {}).get("ics_lbcs")
        if ics_lbcs is not None:
            loc = ics_lbcs.get(xcs)
            if not isinstance(loc, dict):
                return loc
            return loc.get(fmt, "")
        return ""

    # Get the paths to any platform-supported data streams
    get_extrn_ics = expt_config["task_get_extrn_ics"]["envvars"]
    extrn_mdl_sysbasedir_ics = _get_location(
        get_extrn_ics["EXTRN_MDL_NAME_ICS"],
        get_extrn_ics["FV3GFS_FILE_FMT_ICS"],
        expt_config,
    )
    get_extrn_ics["EXTRN_MDL_SYSBASEDIR_ICS"] = extrn_mdl_sysbasedir_ics

    get_extrn_lbcs = expt_config["task_get_extrn_lbcs"]["envvars"]
    extrn_mdl_sysbasedir_lbcs = _get_location(
        get_extrn_lbcs["EXTRN_MDL_NAME_LBCS"],
        get_extrn_lbcs["FV3GFS_FILE_FMT_LBCS"],
        expt_config,
    )
    get_extrn_lbcs["EXTRN_MDL_SYSBASEDIR_LBCS"] = extrn_mdl_sysbasedir_lbcs

    # remove the data key -- it's not needed beyond this point
    if "data" in expt_config:
        expt_config.pop("data")

    # Check for the user-specified directories for external model files if
    # USE_USER_STAGED_EXTRN_FILES is set to TRUE
    task_keys = zip(
        [get_extrn_ics, get_extrn_lbcs],
        ["EXTRN_MDL_SOURCE_BASEDIR_ICS", "EXTRN_MDL_SOURCE_BASEDIR_LBCS"],
    )

    for task, data_key in task_keys:
        use_staged_extrn_files = task["USE_USER_STAGED_EXTRN_FILES"]
        if use_staged_extrn_files:
            basedir = task[data_key]
            # Check for the base directory up to the first templated field.
            idx = basedir.find("$")
            if idx == -1:
                idx = len(basedir)

            if not os.path.exists(basedir[:idx]):
                raise FileNotFoundError(
                    f'''
                    The user-staged-data directory does not exist.
                    Please point to the correct path where your external
                    model files are stored.
                      {data_key} = \"{basedir}\"'''
                )

    # Make sure the vertical coordinate file and LEVP for both make_lbcs and make_ics is the same.
    make_ics_config = expt_config["task_make_ics"]["envvars"]
    make_lbcs_config = expt_config["task_make_ics"]["envvars"]
    if ics_vcoord := make_ics_config["VCOORD_FILE"] != (
        lbcs_vcoord := make_lbcs_config["VCOORD_FILE"]
    ):
        raise ValueError(
            f"""
             The VCOORD_FILE must be set to the same value for both the
             make_ics task and the make_lbcs task. They are currently
             set to:

             make_ics:
               VCOORD_FILE: {ics_vcoord}

             make_lbcs:
               VCOORD_FILE: {lbcs_vcoord}
             """
        )
    if ics_levp := make_ics_config["LEVP"] != (lbcs_levp := make_lbcs_config["LEVP"]):
        raise ValueError(
            f"""
             The number of vertical levels LEVP must be set to the same value for both the
             make_ics task and the make_lbcs tasks. They are currently set to:

             make_ics:
               LEVP: {ics_levp}

             make_lbcs:
               LEVP: {lbcs_levp}
             """
        )

    #
    # -----------------------------------------------------------------------
    #
    # Forecast settings
    #
    # -----------------------------------------------------------------------
    #

    expt_config.dereference()
    workflow_config = expt_config["workflow"]
    fcst_config = expt_config["task_run_fcst"]
    grid_config = expt_config["task_make_grid"]

    # Warn if user has specified a large timestep inappropriately
    ccpp_physics_suite = workflow_config["CCPP_PHYS_SUITE"]
    hires_ccpp_suites = ["FV3_RRFS_v1beta","FV3_WoFS_v0", "FV3_HRRR", "FV3_HRRR_gf", "RRFS_sas"]

    # Gather the pre-defined grid parameters, if needed
    if (predef_grid := workflow_config["PREDEF_GRID_NAME"]) != "":
        grid_params = set_predef_grid_params(
            ushdir,
            predef_grid,
            fcst_config["QUILTING"],
        )
        # Users like to change these variables, so don't overwrite them
        special_vars = ["DT_ATMOS", "LAYOUT_X", "LAYOUT_Y", "BLOCKSIZE"]
        for param, value in grid_params.items():
            if param in special_vars:
                param_val = fcst_config["envvars"].get(param)
                if param_val and isinstance(param_val, str) and "{{" not in param_val:
                    continue
                if isinstance(param_val, (int, float)):
                    continue
                # DT_ATMOS needs special treatment based on CCPP suite
                if param == "DT_ATMOS":
                    if (
                        ccpp_physics_suite in hires_ccpp_suites
                        and grid_params[param] > 40
                    ):
                        logger.warning(
                            dedent(
                                f"""
                            WARNING: CCPP suite {ccpp_physics_suite} requires short
                            time step regardless of grid resolution; setting DT_ATMOS to 40.\n
                            This value can be overwritten in the user config file.
                            """
                            )
                        )
                        fcst_config["envvars"][param] = 40
                    else:
                        fcst_config["envvars"][param] = value
                else:
                    fcst_config[param] = value
            elif param.startswith("WRTCMP"):
                if fcst_config[param] == "":
                    fcst_config[param] = value
            elif param == "GRID_GEN_METHOD":
                workflow_config[param] = value
            else:
                grid_config[param] = value

    run_envir = expt_config["user"]["RUN_ENVIR"]

    # Warn if user has specified a large timestep inappropriately
    if ccpp_physics_suite in hires_ccpp_suites:
        dt_atmos = fcst_config["envvars"]["DT_ATMOS"]
        if dt_atmos > 40:
            logger.warning(
                dedent(
                    f"""
                WARNING: CCPP suite {ccpp_physics_suite} requires short
                time step regardless of grid resolution. The user-specified value
                DT_ATMOS = {dt_atmos}
                may result in CFL violations or other errors!
                """
                )
            )

    # set varying forecast lengths only when fcst_len_hrs=-1
    if fcst_len_hrs == -1:
        fcst_len_cycl = workflow_config.get("FCST_LEN_CYCL")

        # Check that the number of entries divides into a day
        if 24 / incr_cycl_freq != len(fcst_len_cycl):
            # Also allow for the possibility that the user is running
            # cycles for less than a day:
            num_cycles = len(
                set_cycle_dates(date_first_cycl_dt, date_last_cycl_dt, cycl_intvl_dt)
            )

            if num_cycles != len(fcst_len_cycl):
                logger.error(
                    f""" The number of entries in FCST_LEN_CYCL does
              not divide evenly into a 24 hour day or the number of cycles
              in your experiment!
                FCST_LEN_CYCL = {fcst_len_cycl}
              """
                )
                raise ValueError

        # Build cycledef entries for the long forecasts
        # Short forecast cycles will be relevant to all intended
        # forecasts...after all, a 12 hour forecast also encompasses a 3
        # hour forecast, so the short ones will be consistent with the
        # existing default forecast cycledef

        # Reset the hours to the short forecast length
        workflow_config["FCST_LEN_HRS"] = min(fcst_len_cycl)

        # Find the entries that match the long forecast, and map them to
        # their time of day.
        long_fcst_len = max(fcst_len_cycl)
        long_indices = [i for i, x in enumerate(fcst_len_cycl) if x == long_fcst_len]
        long_cycles = [i * incr_cycl_freq for i in long_indices]

        # add one forecast entry per cycle per day
        for hour in long_cycles:
            first = date_first_cycl_dt.replace(hour=hour).strftime("%Y%m%d%H%S")
            last = date_last_cycl_dt.replace(hour=hour).strftime("%Y%m%d%H%S")
            spec = f"{first} {last} 24:00:00"

            rocoto_config["cycledef"].append(
                {"attrs": {"group": "long_forecast"}, "spec": spec}
            )

    # check the availability of restart intervals for restart capability of forecast
    do_fcst_restart = fcst_config["envvars"]["DO_FCST_RESTART"]
    lbc_spec_intvl_hrs = get_extrn_lbcs["LBC_SPEC_INTVL_HRS"]
    if do_fcst_restart:
        restart_interval = fcst_config["envvars"]["RESTART_INTERVAL"]
        restart_hrs = []
        if " " in str(restart_interval):
            restart_hrs = restart_interval.split()
        else:
            restart_hrs.append(str(restart_interval))

        for interval in restart_hrs:
            if int(interval) % lbc_spec_intvl_hrs != 0:
                raise ValueError(
                    f"""
                The restart interval is not divided by LBC_SPEC_INTVL_HRS:
                  RESTART_INTERVAL = {interval}
                  LBC_SPEC_INTVL_HRS = {lbc_spec_intvl_hrs}"""
                )

    #
    # -----------------------------------------------------------------------
    #
    # Set parameters according to the type of horizontal grid generation
    # method specified.
    #
    # -----------------------------------------------------------------------
    #

    grid_gen_method = workflow_config["GRID_GEN_METHOD"]
    if grid_gen_method == "ESGgrid":
        grid_params = set_gridparams_ESGgrid(
            lon_ctr=grid_config["ESGgrid_LON_CTR"],
            lat_ctr=grid_config["ESGgrid_LAT_CTR"],
            nx=grid_config["ESGgrid_NX"],
            ny=grid_config["ESGgrid_NY"],
            pazi=grid_config["ESGgrid_PAZI"],
            halo_width=grid_config["ESGgrid_WIDE_HALO_WIDTH"],
            delx=grid_config["ESGgrid_DELX"],
            dely=grid_config["ESGgrid_DELY"],
            constants=expt_config["constants"],
        )
        expt_config["grid_params"] = grid_params
    elif not run_any_coldstart_task:
        logger.warning("No coldstart tasks specified, not setting grid parameters")
    else:
        errmsg = dedent(
            f"""
            Valid value of GRID_GEN_METHOD is ESGgrid.
            The value provided is:
              GRID_GEN_METHOD = {grid_gen_method}
            """
        )
        raise KeyError(errmsg) from None

    # Check to make sure that mandatory forecast variables are set.
    global_sect = expt_config["global"]
    if run_run_fcst:
        vlist = [
            "LAYOUT_X",
            "LAYOUT_Y",
            "BLOCKSIZE",
        ]
        msg = "Mandatory variable task_run_fcst.{val} has not been set."
        for val in vlist:
            if not fcst_config.get(val):
                raise ValueError(msg.format(val=val))
        if not isinstance(fcst_config["envvars"]["DT_ATMOS"], int):
            raise ValueError(msg.format(val="envvars.DT_ATMOS"))

        # Check whether the forecast length (FCST_LEN_HRS) is evenly divisible
        # by the BC update interval (LBC_SPEC_INTVL_HRS). If so, generate an
        # array of forecast hours at which the boundary values will be updated.

        rem = fcst_len_hrs % lbc_spec_intvl_hrs
        if rem != 0 and fcst_len_hrs > 0:
            raise ValueError(
                f"""
                The forecast length (FCST_LEN_HRS) is not evenly divisible by the lateral
                boundary conditions update interval (LBC_SPEC_INTVL_HRS):
                  FCST_LEN_HRS = {fcst_len_hrs}
                  LBC_SPEC_INTVL_HRS = {lbc_spec_intvl_hrs}
                  rem = FCST_LEN_HRS%%LBC_SPEC_INTVL_HRS = {rem}"""
            )

    #
    # -----------------------------------------------------------------------
    #
    # Post-processing validation and settings
    #
    # -----------------------------------------------------------------------
    #

    # If using external CRTM fix files to allow post-processing of synthetic
    # satellite products from the UPP, make sure the CRTM fix file directory exists.
    if global_sect["USE_CRTM"]:
        crtm_dir = global_sect["CRTM_DIR"]
        if crtm_dir:
            crtm_dir = Path(crtm_dir)
        else:
            raise ValueError("CRTM_DIR is not set.")
        if not crtm_dir.exists():
            raise FileNotFoundError(
                dedent(
                    f"""
                The user-supplied CRTM fix file directory does not exist:
                CRTM_DIR = {str(crtm_dir)}
                """
                )
            )

    # If performing sub-hourly model output and post-processing, check that
    # the output interval DT_SUBHOURLY_POST_MNTS (in minutes) is specified
    # correctly.
    post_config = expt_config["task_run_post"]
    if post_config["envvars"]["SUB_HOURLY_POST"]:

        # Subhourly post should be set with minutes between 1 and 59 for
        # real subhourly post to be performed.
        dt_subhourly_post_mnts = post_config["envvars"]["DT_SUBHOURLY_POST_MNTS"]
        if dt_subhourly_post_mnts == 0:
            logger.warning(
                f"""
                When performing sub-hourly post (i.e. SUB_HOURLY_POST set to \"TRUE\"),
                DT_SUBHOURLY_POST_MNTS must be set to a value greater than 0; otherwise,
                sub-hourly output is not really being performed:
                  DT_SUBHOURLY_POST_MNTS = \"{dt_subhourly_post_mnts}\"
                Resetting SUB_HOURLY_POST to \"FALSE\".  If you do not want this, you
                must set DT_SUBHOURLY_POST_MNTS to something other than zero."""
            )
            post_config["SUB_HOURLY_POST"] = False

        if dt_subhourly_post_mnts < 1 or dt_subhourly_post_mnts > 59:
            raise ValueError(
                f'''
                When SUB_HOURLY_POST is set to \"TRUE\",
                DT_SUBHOURLY_POST_MNTS must be set to an integer between 1 and 59,
                inclusive but:
                  DT_SUBHOURLY_POST_MNTS = \"{dt_subhourly_post_mnts}\"'''
            )

        # Check that DT_SUBHOURLY_POST_MNTS (after converting to seconds) is
        # evenly divisible by the forecast model's main time step DT_ATMOS.
        dt_atmos = fcst_config["envvars"]["DT_ATMOS"]
        rem = dt_subhourly_post_mnts * 60 % dt_atmos
        if rem != 0:
            raise ValueError(
                f"""
                When SUB_HOURLY_POST is set to \"TRUE\") the post
                processing interval in seconds must be evenly divisible
                by the time step DT_ATMOS used in the forecast model,
                i.e. the remainder must be zero.  In this case, it is
                not:

                  DT_SUBHOURLY_POST_MNTS = \"{dt_subhourly_post_mnts}\"
                  DT_ATMOS = \"{dt_atmos}\"
                  remainder = (DT_SUBHOURLY_POST_MNTS*60) %% DT_ATMOS = {rem}

                Please reset DT_SUBHOURLY_POST_MNTS and/or DT_ATMOS so
                that this remainder is zero."""
            )

    # Make sure the post output domain is set
    predef_grid_name = workflow_config["PREDEF_GRID_NAME"]
    post_output_domain_name = post_config["envvars"]["POST_OUTPUT_DOMAIN_NAME"]

    if not post_output_domain_name:
        if not predef_grid_name and run_run_post:
            raise ValueError(
                f"""
                The domain name used in naming the run_post output files
                (POST_OUTPUT_DOMAIN_NAME) has not been set:
                POST_OUTPUT_DOMAIN_NAME = \"{post_output_domain_name}\"
                If this experiment is not using a predefined grid (i.e. if
                PREDEF_GRID_NAME is set to a null string), POST_OUTPUT_DOMAIN_NAME
                must be set in the configuration file (\"{user_config_fn}\"). """
            )
        post_output_domain_name = predef_grid_name

    #
    # -----------------------------------------------------------------------
    #
    # Set the output directory locations
    #
    # -----------------------------------------------------------------------
    #
    # Use env variables for NCO variables and create NCO directories
    workflow_manager = expt_config["platform"]["WORKFLOW_MANAGER"]
    if (
        run_envir == "nco"
        and workflow_manager == "rocoto"
        and global_sect["DO_ENSEMBLE"]
    ):
        # Update the rocoto string for the fcst output location if
        # running an ensemble in nco mode

        ptmp = expt_config["nco"]["PTMP"]
        envir = expt_config["nco"]["envir_default"]
        rocoto_config["entities"]["FCST_DIR"] = \
            f"{ptmp}/{envir}/tmp/run_fcst_mem#mem#.{{ workflow.WORKFLOW_ID }}_@Y@m@d@H"

    # create experiment dir
    Path(exptdir).mkdir(parents=True)

    # -----------------------------------------------------------------------
    #
    # The FV3 forecast model needs the following input files in the run
    # directory to start a forecast:
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
    # Note that the CCPP physics suite definition file does not have a
    # corresponding template file because it does not contain any values
    # that need to be replaced according to the experiment/workflow
    # configuration.  If using CCPP, this file simply needs to be copied
    # over from its location in the forecast model's directory structure
    # to the experiment directory.
    #
    # Below, we first set the names of the templates for the first six files
    # listed above.  We then set the full paths to these template files.
    # Note that some of these file names depend on the physics suite while
    # others do not.
    #
    # -----------------------------------------------------------------------
    #
    # Check for the CCPP_PHYSICS suite xml file
    ccpp_phys_suite_in_ccpp_fp = Path(workflow_config["CCPP_PHYS_SUITE_IN_CCPP_FP"])
    if not ccpp_phys_suite_in_ccpp_fp.exists():
        raise FileNotFoundError(
            f"""
            The CCPP suite definition file (CCPP_PHYS_SUITE_IN_CCPP_FP) does not exist
            in the local clone of the ufs-weather-model:
              CCPP_PHYS_SUITE_IN_CCPP_FP = '{str(ccpp_phys_suite_in_ccpp_fp)}'"""
        )

    # Check for the field dict file
    field_dict_in_uwm_fp = Path(workflow_config["FIELD_DICT_IN_UWM_FP"])
    if not field_dict_in_uwm_fp.exists():
        raise FileNotFoundError(
            f"""
            The field dictionary file (FIELD_DICT_IN_UWM_FP) does not exist
            in the local clone of the ufs-weather-model:
              FIELD_DICT_IN_UWM_FP = '{str(field_dict_in_uwm_fp)}'"""
        )

    #
    # -----------------------------------------------------------------------
    #
    # Check that the set of tasks to run in the workflow is internally
    # consistent.
    #
    # -----------------------------------------------------------------------
    #
    ens_vx_tasks = "verify_ens.yaml" in taskgroups
    # Get the value of the configuration flag for ensemble mode (DO_ENSEMBLE)
    # and ensure that it is set to True if ensemble vx tasks are included in
    # the workflow (or vice-versa).
    do_ensemble = global_sect["DO_ENSEMBLE"]
    if (not do_ensemble) and ens_vx_tasks:
        msg = dedent(
            f"""
              Ensemble verification can not be run unless running in ensemble mode:
                  DO_ENSEMBLE = \"{do_ensemble}\"
              Please set DO_ENSEMBLE to True or remove ensemble vx tasks from the
              workflow."""
        )
        raise ValueError(msg)

    #
    # -----------------------------------------------------------------------
    # NOTE: currently this is executed no matter what, should it be
    # dependent on the logic described below??
    # If not running the TN_MAKE_GRID, TN_MAKE_OROG, and/or TN_MAKE_SFC_CLIMO
    # tasks, create symlinks under the FIXlam directory to pregenerated grid,
    # orography, and surface climatology files.
    #
    # -----------------------------------------------------------------------
    #
    fixlam = workflow_config["FIXlam"]
    Path(fixlam).mkdir(parents=True)

    #
    # Use the pregenerated domain files if the tasks to generate them
    # are turned off. Link the files, and check that they all contain
    # the same resolution input.
    #

    # Flags for creating symlinks to pre-generated grid, orography, and sfc_climo files.
    # These consider dependencies of other tasks on each pre-processing task.
    fixed_files = expt_config["fixed_files"]

    task_defs = rocoto_config["tasks"]
    prep_tasks = ["GRID", "OROG", "SFC_CLIMO"]
    res_in_fixlam_filenames = None
    for prep_task in prep_tasks:
        res_in_fns = ""
        sect_key = f"task_make_{prep_task.lower()}"
        # If the user doesn't want to run the given task, link the fix
        # file from the staged files.
        if not task_defs.get(sect_key) and run_run_fcst:
            dir_key = f"{prep_task}_DIR"

            task_dir = Path(pregen_basedir, predef_grid)
            if not Path(task_dir).exists():
                msg = dedent(
                    f"""
                    The directory ({dir_key}) that should contain the pregenerated
                    {prep_task.lower()} files does not exist:
                      {dir_key} = \"{task_dir}\"
                    """
                )
                raise FileNotFoundError(msg)

            expt_config[sect_key][dir_key] = str(task_dir)
            msg = dedent(
                f"""
               {dir_key} will point to a location containing pre-generated files.
               Setting {dir_key} = {task_dir}
               """
            )
            logger.warning(msg)

            # Link the fix files and check that their resolution is
            # consistent
            res_in_fns = link_fix(
                verbose=verbose,
                file_group=prep_task.lower(),
                source_dir=task_dir,
                target_dir=workflow_config["FIXlam"],
                ccpp_phys_suite=ccpp_physics_suite,
                constants=expt_config["constants"],
                dot_or_uscore=workflow_config["DOT_OR_USCORE"],
                nhw=grid_params["NHW"],
                run_task=False,
                sfc_climo_fields=fixed_files["SFC_CLIMO_FIELDS"],
            )
            if not res_in_fixlam_filenames:
                res_in_fixlam_filenames = res_in_fns
            else:
                if res_in_fixlam_filenames != res_in_fns:
                    raise ValueError(
                        dedent(
                            f"""
                        The resolution of the pregenerated files for
                        {prep_task} do not match those that were alread
                        set:

                        Resolution in {prep_task}: {res_in_fns}
                        Resolution expected: {res_in_fixlam_filenames}
                        """
                        )
                    )

    workflow_config["RES_IN_FIXLAM_FILENAMES"] = res_in_fixlam_filenames
    if res_in_fixlam_filenames:
        workflow_config["CRES"] = f"C{res_in_fixlam_filenames}"
    elif cres := os.getenv("CRES"):
        workflow_config["CRES"] = cres

    #
    # -----------------------------------------------------------------------
    #
    # Turn off post task if it's not consistent with the forecast's
    # user-setting of WRITE_DOPOST
    #
    # -----------------------------------------------------------------------
    #
    if fcst_config["envvars"]["WRITE_DOPOST"]:
        # Turn off run_post
        task_name = "metatask_run_ens_post"
        removed_task = task_defs.pop(task_name, None)
        if removed_task:
            logger.warning(
                dedent(
                    f"""
                     Inline post is turned on, deactivating post-processing tasks:
                     Removing {task_name} from task definitions
                     list.
                     """
                )
            )

        # Check if SUB_HOURLY_POST is on
        if expt_config["task_run_post"]["envvars"]["SUB_HOURLY_POST"]:
            raise ValueError(
                """
                SUB_HOURLY_POST is NOT available with Inline Post yet."""
            )

    #
    # -----------------------------------------------------------------------
    #
    # Read CCPP suite definition file and perform actions based on its
    # contents as necessary
    #
    # -----------------------------------------------------------------------
    #

    if run_run_fcst or run_make_grid: # pylint: disable=too-many-nested-blocks
        ccpp_suite_xml = load_xml_file(workflow_config["CCPP_PHYS_SUITE_IN_CCPP_FP"])

        # For SPP stochastic physics, perturbations can only be applied with certain CCPP schemes:
        # MYNN PBL (pbl), MYNN SFC (sfc), Thompson MP (mp), RRTMG (rad), GSL GWD (gwd), and
        # GF (cu_deep).
        # Here we ensure that the specified schemes are available, and warn/fail if not as needed.
        # This loop also serves to check for invalid values in SPP_VAR_LIST

        spp_arrays = [
            "SPP_MAG_LIST",
            "SPP_LSCALE",
            "SPP_TSCALE",
            "SPP_SIGTOP1",
            "SPP_SIGTOP2",
            "SPP_STDDEV_CUTOFF",
            "ISEED_SPP",
        ]

        if global_sect.get("DO_SPP"):
            spp_valid_dict = {
                             'pbl': ['mynnedmf_wrapper'],
                             'sfc': ['mynnsfc_wrapper'],
                             'mp':  ['mp_thompson'],
                             'rad': ['rrtmg_sw', 'rrtmg_lw'],
                             'gwd': ['drag_suite'],
                             'cu_deep': ['cu_gf_driver'],
                             }
            for spp_var in global_sect["SPP_VAR_LIST"]:
                if spp_var not in spp_valid_dict:
                    msg = "Invalid SPP variable specified: {spp_var}\n"
                    msg += "Valid variables are: {spp_valid_dict.keys()}"
                    raise ValueError(msg)

            for key, value in spp_valid_dict.items():
                if key in global_sect["SPP_VAR_LIST"]:
                    if all(not has_tag_with_value(ccpp_suite_xml, "scheme", x) for x in value):
                        logger.warning(f"Selected CCPP suite ({ccpp_physics_suite})\n"\
                                       f"Does not have required scheme(s) {value}\n"\
                                       f"for {key} in SPP_VAR_LIST; removing {key}"\
                                         "and associated scaling factors")
                        index = global_sect["SPP_VAR_LIST"].index(key)
                        global_sect["SPP_VAR_LIST"].pop(index)
                        logging.debug("New scaling factor arrays:")
                        for array in spp_arrays:
                            global_sect[array].pop(index)
                            logging.debug(f"{array}={global_sect[array]}")

            if len(global_sect["SPP_VAR_LIST"]) == 0:
                msg = "SPP_VAR_LIST is empty and DO_SPP = True\n"
                msg += "Check your settings of CCPP_PHYS_SUITE and SPP_VAR_LIST"
                raise ValueError(msg)

        if global_sect.get("DO_LSM_SPP"):
            lsm_spp_valid = ["lsm_ruc", "lsm_noah"]
            if all(not has_tag_with_value(ccpp_suite_xml, "scheme", x) for x in lsm_spp_valid):
                msg = ( f"Selected CCPP suite ({workflow_config['CCPP_PHYS_SUITE']})\n"
                         "Does not have a supported surface scheme\n"
                         "Valid surface schemes are: {lsm_spp_valid}" )
                raise ValueError(msg)

        # If running with Noah or RUC-LSM SPP, set LNDP_TYPE to 2, otherwise set it to zero.
        if global_sect["DO_LSM_SPP"]:
            global_sect["LNDP_TYPE"] = 2
            global_sect["LNDP_MODEL_TYPE"] = 2
        else:
            global_sect["LNDP_TYPE"] = 0
            global_sect["LNDP_MODEL_TYPE"] = 0

        #
        # -----------------------------------------------------------------------
        #
        # If running with LSM SPP, confirm that each LSM SPP-related namelist
        # value contains the same number of entries as LSM_SPP_VAR_LIST
        #
        # -----------------------------------------------------------------------
        #
        lsm_spp_arrays = [
            "LSM_SPP_MAG_LIST",
            "LSM_SPP_LSCALE",
            "LSM_SPP_TSCALE",
        ]
        if global_sect["DO_LSM_SPP"]:
            if len(global_sect["LSM_SPP_VAR_LIST"]) > 5:
                raise ValueError(f"Too many LSM_SPP variables selected:\n"\
                                 f"({global_sect['LSM_SPP_VAR_LIST']=}),\n"\
                                  "Choose a subset of 5 or fewer valid variables.")

            for lsm_spp_var in lsm_spp_arrays:
                if len(global_sect[lsm_spp_var]) != len(global_sect["LSM_SPP_VAR_LIST"]):
                    raise ValueError(
                        f"""
                        All Noah or RUC-LSM SPP-related namelist variables (except ISEED_LSM_SPP)
                        must be of equal length to LSM_SPP_VAR_LIST; found mismatch:
                          LSM_SPP_VAR_LIST = {global_sect["LSM_SPP_VAR_LIST"]}
                          {lsm_spp_var} = {global_sect[lsm_spp_var]}
                          """
                    )








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
        if not global_sect.get("DO_SHUM"):
            global_sect["SHUM_MAG"] = -999.0
        if not global_sect.get("DO_SKEB"):
            global_sect["SKEB_MAG"] = -999.0
        if not global_sect.get("DO_SPPT"):
            global_sect["SPPT_MAG"] = -999.0
        #
        # -----------------------------------------------------------------------
        #
        # If running with SPP in MYNN PBL, MYNN SFC, GSL GWD, Thompson MP, or
        # RRTMG, count the number of entries in SPP_VAR_LIST to correctly set
        # N_VAR_SPP, otherwise set it to zero.
        #
        # -----------------------------------------------------------------------
        #
        if global_sect["DO_SPP"]:
            global_sect["N_VAR_SPP"] = len(global_sect["SPP_VAR_LIST"])
        else:
            global_sect["N_VAR_SPP"] = 0

        # Confirm that each SPP-related namelist value contains the same number of entries as
        # N_VAR_SPP (set above to be equal to the number of entries in SPP_VAR_LIST).

        if global_sect["DO_SPP"]:
            for spp_var in spp_arrays:
                if len(global_sect[spp_var]) != global_sect["N_VAR_SPP"]:
                    raise ValueError(
                        f"""
                        All MYNN PBL, MYNN SFC, GSL GWD, Thompson MP, or RRTMG SPP-related namelist
                        variables must be of equal length to SPP_VAR_LIST:
                          SPP_VAR_LIST (length {global_sect['N_VAR_SPP']})
                          {spp_var} (length {len(global_sect[spp_var])})
                        """
                    )

        # Need to track if we are using RUC LSM for the make_ics step
        workflow_config["SDF_USES_RUC_LSM"] = has_tag_with_value(
            ccpp_suite_xml, "scheme", "lsm_ruc"
        )

        # Thompson microphysics needs additional input files and namelist settings
        workflow_config["SDF_USES_THOMPSON_MP"] = has_tag_with_value(
            ccpp_suite_xml, "scheme", "mp_thompson"
        )

        if workflow_config["SDF_USES_THOMPSON_MP"]:

            logger.debug(f"Selected CCPP suite ({ccpp_physics_suite}) uses Thompson MP")
            logger.debug("Setting up links for additional fix files")

            # If the model ICs or BCs are not from RAP or HRRR, they will not contain aerosol
            # climatology data needed by the Thompson scheme, so we need to provide a separate file
            if get_extrn_ics["EXTRN_MDL_NAME_ICS"] not in [
                "HRRR",
                "RRFS",
                "RAP",
            ] or get_extrn_lbcs["EXTRN_MDL_NAME_LBCS"] not in ["HRRR", "RRFS", "RAP"]:
                fixed_files["THOMPSON_FIX_FILES"].append(
                    workflow_config["THOMPSON_MP_CLIMO_FN"]
                )

            # Add thompson-specific fix files to CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING and
            # FIXgsm_FILES_TO_COPY_TO_FIXam; see
            # parm/fixed_files_mapping.yaml for more info on these variables

            fixed_files["FIXgsm_FILES_TO_COPY_TO_FIXam"].extend(
                fixed_files["THOMPSON_FIX_FILES"]
            )

            for fix_file in fixed_files["THOMPSON_FIX_FILES"]:
                fixed_files["CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING"].append(
                    f"{fix_file} | {fix_file}"
                )

            logger.debug(
                f'New fix file list:\n{fixed_files["FIXgsm_FILES_TO_COPY_TO_FIXam"]=}'
            )
            logger.debug(
                f'New fix file mapping:\n{fixed_files["CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING"]=}'
            )

        # -----------------------------------------------------------------------
        #
        # Check that UFS FIRE settings are correct and consistent
        #
        # -----------------------------------------------------------------------
        fire_conf = expt_config["fire"]
        fire_conf_vars = fire_conf["envvars"]
        if fire_conf_vars["UFS_FIRE"]:
            if build_config["Application"] != "ATMF":
                raise ValueError(
                    ("UFS_FIRE == True but UFS SRW has not been built for fire coupling;",
                    "see users guide for details")
                )
            fire_input_file = Path(fire_conf_vars["FIRE_INPUT_DIR"], "geo_em.d01.nc")
            if not Path(fire_input_file).is_file():
                raise FileNotFoundError(
                    dedent(
                        f"""
                    The fire input file (geo_em.d01.nc) does not exist in the specified directory:
                    {fire_conf["FIRE_INPUT_DIR"]}
                    Check that the specified path is correct, and the file exists and is readable
                    """
                    )
                )
            # CCPP suite must have these schemes to work correctly with fire capability
            if not ( has_tag_with_value(ccpp_suite_xml, "scheme", "rrfs_smoke_wrapper") and
                     has_tag_with_value(ccpp_suite_xml, "scheme", "GFS_surface_composites_post") ):
                raise ValueError(dedent(
                      """
                      UFS_FIRE can only work with smoke-enabled CCPP suites, including
                      FV3_HRRR, FV3_HRRR_gf, and RRFS_sas""" ))
            if fire_conf["FIRE_NUM_TASKS"] < 1:
                raise ValueError("FIRE_NUM_TASKS must be > 0 if UFS_FIRE is True")
            if fire_conf["FIRE_NUM_TASKS"] > 1:
                raise ValueError("FIRE_NUM_TASKS > 1 not yet supported")

            if fire_conf["FIRE_NUM_IGNITIONS"] > 5:
                raise ValueError("Only 5 or fewer fire ignitions supported")

            if fire_conf["FIRE_NUM_IGNITIONS"] > 1:
                # These settings all need to be lists for multiple fire ignitions
                each_fire = [
                    "FIRE_IGNITION_ROS",
                    "FIRE_IGNITION_START_LAT",
                    "FIRE_IGNITION_START_LON",
                    "FIRE_IGNITION_END_LAT",
                    "FIRE_IGNITION_END_LON",
                    "FIRE_IGNITION_RADIUS",
                    "FIRE_IGNITION_START_TIME",
                    "FIRE_IGNITION_END_TIME",
                ]
                for setting in each_fire:
                    if (not isinstance(fire_conf[setting], list) or
                       len(fire_conf[setting]) != fire_conf["FIRE_NUM_IGNITIONS"]):
                        logger.critical(f"{fire_conf['FIRE_NUM_IGNITIONS']=}")
                        logger.critical(f"{fire_conf[setting]=}")
                        raise ValueError(
                            f"For FIRE_NUM_IGNITIONS > 1, {setting} must be a list of same length"
                        )

            if fire_conf["FIRE_ATM_FEEDBACK"] < 0.0:
                raise ValueError("FIRE_ATM_FEEDBACK must be 0 or greater")

            if fire_conf["FIRE_UPWINDING"] == 0 and fire_conf["FIRE_VISCOSITY"] == 0.0:
                raise ValueError("FIRE_VISCOSITY must be > 0.0 if FIRE_UPWINDING == 0")
        else:
            if fire_conf["FIRE_NUM_TASKS"] > 0:
                logger.warning("UFS_FIRE is not enabled; setting FIRE_NUM_TASKS = 0")
                fire_conf["FIRE_NUM_TASKS"] = 0
    #
    # -----------------------------------------------------------------------
    #
    # Generate var_defns.yaml file in the EXPTDIR. This file contains all
    # the user-specified settings from expt_config.
    #
    # -----------------------------------------------------------------------
    #

    expt_config.dereference()
    logger.debug(str(expt_config))

    global_var_defns_fp = workflow_config["GLOBAL_VAR_DEFNS_FP"]
    # print info message
    logger.info(
        f"""
        Generating the global experiment variable definitions file here:
          GLOBAL_VAR_DEFNS_FP = '{global_var_defns_fp}'
        For more detailed information, set DEBUG to 'TRUE' in the experiment
        configuration file ('{user_config_fn}')."""
    )

    # Final failsafe before writing rocoto yaml to ensure we don't have any invalid dicts
    # (e.g. metatasks with no tasks, tasks with no associated commands)
    clean_rocoto_dict(expt_config["rocoto"]["tasks"])
    expt_config.dereference()

    rocoto_yaml_fp = Path(workflow_config["ROCOTO_YAML_FP"])
    rocoto_yaml = get_yaml_config({"workflow": expt_config["rocoto"]})
    rocoto_yaml.dump(rocoto_yaml_fp)

    var_defns_cfg = get_yaml_config(config=expt_config.data)
    del var_defns_cfg["rocoto"]

    # Fixup a couple of data types:
    var_defns_cfg.dump(Path(global_var_defns_fp))

    # Run render on the Rocoto YAML to check for unrendered values.
    # Quit and report on any found.
    with StringIO() as buffer:
        logger = logging.getLogger()
        handler = logging.StreamHandler(buffer)
        handler.setLevel(logging.INFO)
        logger.addHandler(handler)
        xml_config_str = render(input_file=rocoto_yaml_fp, values_needed=True)
        values_needed = buffer.getvalue().split("\n")[1:]
        logger.removeHandler(handler)
    uwtags = ("!bool", "!float", "!int")
    not_rendered = any(v for v in values_needed if v.strip() != "jobname") or \
            any(tag in xml_config_str for tag in uwtags)
    if not_rendered:
        # Regex to match '{{' or '{%' but not '{{ jobname }}', as the rocoto
        # tool adds jobname for each task. Also matches UW-supported tags.
        pattern = r"({{(?! jobname )|{%.*?%})|!bool|!float|!int"
        line_not_ok = lambda l: any(m for m in re.finditer(pattern, l)) # pylint: disable=unnecessary-lambda-assignment
        unrendered_lines = "\n".join([l.strip() for l in xml_config_str.split("\n") if line_not_ok(l)]) # pylint: disable=line-too-long
        msg = f"""
        Jinja expressions remain in the XML configuration file.

        {str(rocoto_yaml_fp)}

        They include:

        {unrendered_lines}
        """
        raise ValueError(msg)

    # Generate a flag file for cold start
    if expt_config["workflow"].get("COLDSTART"):
        coldstart_date = var_defns_cfg["workflow"]["DATE_FIRST_CYCL"]
        fn_pass=f"task_skip_coldstart_{coldstart_date}.txt"
        Path(exptdir,fn_pass).touch()

    #
    # -----------------------------------------------------------------------
    #
    # Check validity of parameters in one place, here in the end.
    #
    # -----------------------------------------------------------------------
    #
    # Validate experiment config against schema
    schema = Path(ushdir) / "experiment.jsonschema"
    valid = validate(schema_file=schema, config_data=var_defns_cfg)

    if not valid:
        logging.error("Experiment configuration is not valid against schema")
        sys.exit(1)

    return expt_config


def clean_rocoto_dict(rocotodict):
    """Removes any invalid entries from ``rocotodict``. Examples of invalid entries are:

    1. A task dictionary containing no "command" key
    2. A metatask definition dependent on a variable with no entries
    3. A metatask dictionary containing no task dictionaries

    Args:
        rocotodict (dict): A dictionary containing Rocoto workflow settings
    """


    # Loop 1: search for tasks with no command key, iterating over metatasks, and popping metatasks
    # with var keys having empty values
    for key in list(rocotodict.keys()):
        if key.split("_", maxsplit=1)[0] == "metatask":
            clean_rocoto_dict(rocotodict[key])
            # After checking for metatasks with no command key, now check for empty var entries
            if rocotodict.get(key).get('var'):
                for varkey in list(rocotodict[key]['var'].keys()):
                    if not rocotodict[key]['var'][varkey]:
                        popped = rocotodict.pop(key)
                        logging.warning(f"Invalid metatask {key} removed due to empty/unset var:")
                        logging.warning(f"{varkey}")
                        logging.debug(f"Removed entry:\n{popped}")
                        break

        elif key.split("_", maxsplit=1)[0] in ["task"]:
            if not rocotodict[key].get("command"):
                popped = rocotodict.pop(key)
                logging.warning(
                    f"Invalid task {key} removed due to empty/unset run command"
                )
                logging.debug(f"Removed entry:\n{popped}")

    # Loop 2: search for metatasks with no tasks in them
    for key in list(rocotodict.keys()):
        if key.split("_", maxsplit=1)[0] == "metatask":
            valid = False
            for key2 in list(rocotodict[key].keys()):
                if key2.split("_", maxsplit=1)[0] == "metatask":
                    clean_rocoto_dict(rocotodict[key][key2])
                    # After above recursion, any nested empty metatasks will have popped themselves
                    if rocotodict[key].get(key2):
                        valid = True
                elif key2.split("_", maxsplit=1)[0] == "task":
                    valid = True
            if not valid:
                popped = rocotodict.pop(key)
                logging.warning(f"Invalid/empty metatask {key} removed")
                logging.debug(f"Removed entry:\n{popped}")


#
# -----------------------------------------------------------------------
#
# Call the function defined above.
#
# -----------------------------------------------------------------------
#
if __name__ == "__main__":
    USHDIR = Path(__file__).resolve().parent.as_posix()
    setup(USHDIR)
