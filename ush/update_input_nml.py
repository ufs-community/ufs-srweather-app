#!/usr/bin/env python3

"""
Set AQM-specific namelist settingSet AQM-specific namelist settingss
"""

import os
import sys
import argparse
from textwrap import dedent

from python_utils import (
    import_vars,
    print_input_args,
    print_info_msg,
    cfg_to_yaml_str,
    load_shell_config,
    flatten_dict,
)

from set_namelist import set_namelist


def update_input_nml(run_dir):
    """Update the FV3 input.nml file in the specified run directory

    Args:
        run_dir: run directory
    Returns:
        Boolean
    """

    print_input_args(locals())

    # import all environment variables
    import_vars(env_vars=('VERBOSE', 'FV3_NML_FN'))

    #
    # -----------------------------------------------------------------------
    #
    # Update the FV3 input.nml file in the specified run directory.
    #
    # -----------------------------------------------------------------------
    #
    print_info_msg(
        f"""
        Updating the FV3 input.nml file in the specified run directory (run_dir):
          run_dir = '{run_dir}'""",
          verbose=VERBOSE, # pylint: disable=undefined-variable
    )
    #
    # -----------------------------------------------------------------------
    #
    # Set new values of the specific parameters to be updated.
    #
    # -----------------------------------------------------------------------
    #
    settings = {}

    # For restart run
    if args.restart:
        settings["fv_core_nml"] = {
            "external_ic": False,
            "make_nh": False,
            "mountain": True,
            "na_init": 0,
            "nggps_ic": False,
            "warm_start": True,
        }

        settings["gfs_physics_nml"] = {
            "nstf_name": [2, 0, 0, 0, 0],
        }

    # For AQM_NA_13km domain for air quality modeling
    if args.aqm_na_13km:
        settings["fv_core_nml"] = {
            "k_split": 1,
            "n_split": 8,
        }


    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying values to be used in the FV3 'input.nml'
            file for restart has been set as follows:\n
            settings =

            {settings_str}

            """
        ),
        verbose=VERBOSE, # pylint: disable=undefined-variable
    )
    #
    # -----------------------------------------------------------------------
    #
    # Call a python script to update the experiment's actual FV3 INPUT.NML
    # file for restart.
    #
    # -----------------------------------------------------------------------
    #
    fv3_input_nml_fp = os.path.join(run_dir, FV3_NML_FN) # pylint: disable=undefined-variable

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

    parser.add_argument(
        "--restart",
        action='store_true',
        help='Update for restart')

    parser.add_argument(
        "--aqm_na_13km", 
        action='store_true',
        help='Update for AQM_NA_13km in air quality modeling')

    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    update_input_nml(
        run_dir=args.run_dir,
    )
