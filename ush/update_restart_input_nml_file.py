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
    run_dir, fv_core_external_ic, fv_core_make_nh, fv_core_mountain, fv_core_na_init, fv_core_nggps_ic, fv_core_warm_start
):
    """Update the FV3 input.nml file for restart in the specified
    run directory

    Args:
        run_dir: run directory
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
        "fv_core_na_init": fv_core_na_init,
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
    fv3_input_nml_tmpl_fp = os.path.join(run_dir, FV3_NML_TMPL_FN) 
    fv3_input_nml_fp = os.path.join(run_dir, FV3_NML_FN)

    try:
        fill_jinja_template(
            [
                "-q",
                "-u",
                settings_str,
                "-t",
                fv3_input_nml_tmpl_fp,
                "-o",
                fv3_input_nml_fp,
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
    parser = argparse.ArgumentParser(description="Update FV3 input.nml file for restart.")

    parser.add_argument(
        "-r", "--run_dir",
        dest="run_dir",
        required=True,
        help="Run directory."
    )

    parser.add_argument(
        "-a", "--fv_core_external_ic",
        dest="fv_core_external_ic",
        required=True,
        help="Parameter external_ic.",
    )

    parser.add_argument(
        "-b", "--fv_core_make_nh",
        dest="fv_core_make_nh",
        required=True,
        help="Parameter make_nh.",
    )

    parser.add_argument(
        "-c", "--fv_core_mountain",
        dest="fv_core_mountain",
        required=True,
        help="Parameter mountain.",
    )

    parser.add_argument(
        "-d", "--fv_core_na_init",
        dest="fv_core_na_init",
        required=True,
        help="Parameter na_init.",
    )

    parser.add_argument(
        "-e", "--fv_core_nggps_ic",
        dest="fv_core_nggps_ic",
        required=True,
        help="Parameter nggps_ic.",
    )

    parser.add_argument(
        "-f", "--fv_core_warm_start",
        dest="fv_core_warm_start",
        required=True,
        help="Parameter warm_start.",
    )

    parser.add_argument(
        "-p", "--path-to-defns",
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
    update_restart_input_nml_file(
        run_dir=args.run_dir,
        fv_core_external_ic=str_to_type(args.fv_core_external_ic),
        fv_core_make_nh=str_to_type(args.fv_core_make_nh),
        fv_core_mountain=str_to_type(args.fv_core_mountain),
        fv_core_na_init=str_to_type(args.fv_core_na_init),
        fv_core_nggps_ic=str_to_type(args.fv_core_nggps_ic),
        fv_core_warm_start=str_to_type(args.fv_core_warm_start),
    )
