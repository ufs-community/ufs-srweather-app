#!/usr/bin/env python3

import os
import sys
import argparse
import unittest
from datetime import datetime
from textwrap import dedent

from python_utils import (
    import_vars,
    set_env_var,
    print_input_args,
    str_to_type,
    print_info_msg,
    print_err_msg_exit,
    lowercase,
    cfg_to_yaml_str,
    load_shell_config,
    flatten_dict,
)

from fill_jinja_template import fill_jinja_template


def update_restart_input_nml_file(
    fv_core_external_ic, fv_core_make_nh, fv_core_mountain, fv_core_na_init, fv_core_nggps_ic, fv_core_warm_start
):
    """Update the FV3 input.nml file for restart in the specified
    run directory

    Args:
        fv_core_external_ic : parameter external_ic
        fv_core_make_nh : parameter make_nh
        fv_core_mountain : parameter mountain
        fv_core_na_init : parameter na_init
        fv_core_nggps_ic : parameter nggps_ic
        fv_core_warm_start : parameter warm_start
    Returns:
        Boolean
    """

    print_input_args(locals())

    # import all environment variables
    import_vars()

    #
    # -----------------------------------------------------------------------
    #
    # Update the FV3 input.nml file for restart in the specified run directory.
    #
    # -----------------------------------------------------------------------
    #
    print_info_msg(
        f"""
        Updating the FV3 input.nml file in the specified run directory (run_dir):
          run_dir = '{run_dir}'""",
        verbose=VERBOSE,
    )
    #
    # Set parameters in the input.nml file
    #
    dot_fv_core_external_ic_dot=f".{lowercase(str(fv_core_external_ic))}."
    dot_fv_core_make_nh_dot=f".{lowercase(str(fv_core_make_nh))}."
    dot_fv_core_mountain_dot=f".{lowercase(str(fv_core_mountain))}."
    dot_fv_core_na_init_dot=f".{lowercase(str(fv_core_na_init))}."
    dot_fv_core_nggps_ic_dot=f".{lowercase(str(fv_core_nggps_ic))}."
    dot_fv_core_warm_start_dot=f".{lowercase(str(fv_core_warm_start))}."
    #
    # -----------------------------------------------------------------------
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the jinja variables in the template FV3
    # input.nml file should be set to.
    #
    # -----------------------------------------------------------------------
    #
    settings = {
        "fv_core_external_ic": dot_fv_core_external_ic_dot,
        "fv_core_make_nh": dot_fv_core_make_nh_dot,
        "fv_core_mountain": dot_fv_core_mountain_dot,
        "fv_core_na_init": dot_fv_core_na_init_dot,
        "fv_core_nggps_ic": dot_fv_core_nggps_ic_dot,
        "fv_core_warm_start": dot_fv_core_warm_start_dot,
    }

    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying values to be used in the FV3 'input.nml'
            file for restart has been set as follows:\n
            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )
    #
    # -----------------------------------------------------------------------
    #
    # Call a python script to generate the experiment's actual FV3 INPUT.NML
    # file from the template file.
    #
    # -----------------------------------------------------------------------
    #
    fv3_input_nml_fp = os.path.join(run_dir, "input.nml")

    try:
        fill_jinja_template(
            [
                "-q",
                "-u",
                settings_str,
                "-t",
                MODEL_CONFIG_TMPL_FP,
                "-o",
                model_config_fp,
            ]
        )
    except:
        print_err_msg_exit(
            dedent(
                f"""
                Call to python script fill_jinja_template.py to update the FV3 'input.nml'
                file for restart from a jinja2 template failed. Parameters passed to this script are:
                  Full path to output model config file:
                    fv3_input_nml_fp = '{fv3_input_nml_fp}'
                  Namelist settings specified on command line:\n
                    settings =\n\n"""
            )
            + settings_str
        )
        return False

    return True


def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Creates model configuration file.")

    parser.add_argument(
        "-r", "--run-dir", dest="run_dir", required=True, help="Run directory."
    )

    parser.add_argument(
        "-c",
        "--cdate",
        dest="cdate",
        required=True,
        help="Date string in YYYYMMDD format.",
    )

    parser.add_argument(
        "-f",
        "--fcst_len_hrs",
        dest="fcst_len_hrs",
        required=True,
        help="Forecast length in hours.",
    )

    parser.add_argument(
        "-s",
        "--sub-hourly-post",
        dest="sub_hourly_post",
        required=True,
        help="Set sub hourly post to either TRUE/FALSE by passing corresponding string.",
    )

    parser.add_argument(
        "-d",
        "--dt-subhourly-post-mnts",
        dest="dt_subhourly_post_mnts",
        required=True,
        help="Subhourly post minitues.",
    )

    parser.add_argument(
        "-t",
        "--dt-atmos",
        dest="dt_atmos",
        required=True,
        help="Forecast model's main time step.",
    )

    parser.add_argument(
        "-p",
        "--path-to-defns",
        dest="path_to_defns",
        required=True,
        help="Path to var_defns file.",
    )

    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    create_model_configure_file(
        run_dir=args.run_dir,
        cdate=str_to_type(args.cdate),
        fcst_len_hrs=str_to_type(args.fcst_len_hrs),
        sub_hourly_post=str_to_type(args.sub_hourly_post),
        dt_subhourly_post_mnts=str_to_type(args.dt_subhourly_post_mnts),
        dt_atmos=str_to_type(args.dt_atmos),
    )
