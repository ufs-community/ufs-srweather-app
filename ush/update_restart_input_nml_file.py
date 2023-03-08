#!/usr/bin/env python3

import os
import sys
import argparse
import unittest
from textwrap import dedent

from python_utils import (
    import_vars,
    print_input_args,
    print_info_msg,
    print_err_msg_exit,
    cfg_to_yaml_str,
    load_shell_config,
    flatten_dict,
)


def update_restart_input_nml_file(run_dir):
    """Update the FV3 input.nml file for restart in the specified
    run directory

    Args:
        run_dir: run directory
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
    # -----------------------------------------------------------------------
    #
    # Set parameters in fv_core_nml for restart
    #
    # -----------------------------------------------------------------------
    #
    settings = {}
    settings["fv_core_nml"] = {
        "external_ic": false,
        "make_nh": false,
        "mountain": true,
        "na_init": 0,
        "nggps_ic": false,
        "warm_start": true,
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
    # Call a python script to update the experiment's actual FV3 INPUT.NML
    # file for restart.
    #
    # -----------------------------------------------------------------------
    #
    fv3_input_nml_fp = os.path.join(run_dir, FV3_NML_FN)

    try:
        set_namelist(
            [
                "-q",
                "-n",
                fv3_input_nml_fp,
                "-u",
                settings_str,
                "-o",
                fv3_input_nml_fp,
            ]
        )
    except:
        logging.exception(
            dedent(
                f"""
                Call to python script set_namelist.py to generate an FV3 namelist file
                failed.  Parameters passed to this script are:
                  Full path to base namelist file:
                    fv3_input_nml_fp = '{fv3_input_nml_fp}'
                  Full path to output namelist file:
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
    )
