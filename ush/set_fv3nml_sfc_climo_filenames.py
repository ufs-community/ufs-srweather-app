#!/usr/bin/env python3

"""
Update filenames for surface climotology files in the namelist.
"""

import argparse
import os
import re
import sys
from textwrap import dedent

from uwtools.api.config import get_yaml_config, realize

from python_utils import (
    cfg_to_yaml_str,
    check_var_valid_value,
    flatten_dict,
    import_vars,
    load_shell_config,
    print_info_msg,
)

VERBOSE = os.environ.get("VERBOSE", "true")

NEEDED_VARS = [
    "CRES",
    "DO_ENSEMBLE",
    "EXPTDIR",
    "FIXlam",
    "FV3_NML_FP",
    "PARMdir",
    "RUN_ENVIR",
    ]


# pylint: disable=undefined-variable

def set_fv3nml_sfc_climo_filenames(config, debug=False):
    """
    This function sets the values of the variables in
    the forecast model's namelist file that specify the paths to the surface
    climatology files on the FV3LAM native grid (which are either pregenerated
    or created by the TN_MAKE_SFC_CLIMO task).  Note that the workflow
    generation scripts create symlinks to these surface climatology files
    in the FIXlam directory, and the values in the namelist file that get
    set by this function are relative or full paths to these links.

    Args:
        debug   (bool): Enable extra output for debugging
    Returns:
        None
    """

    import_vars(dictionary=config, env_vars=NEEDED_VARS)

    fixed_cfg = get_yaml_config(os.path.join(PARMdir, "fixed_files_mapping.yaml"))["fixed_files"]

    # The regular expression regex_search set below will be used to extract
    # from the elements of the array FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING
    # the name of the namelist variable to set and the corresponding surface
    # climatology field from which to form the name of the surface climatology file
    regex_search = "^[ ]*([^| ]+)[ ]*[|][ ]*([^| ]+)[ ]*$"

    # Set the suffix of the surface climatology files.
    suffix = "tileX.nc"

    # create yaml-compliant string
    settings = {}

    dummy_run_dir = os.path.join(EXPTDIR, "any_cyc")
    if DO_ENSEMBLE == "TRUE":
        dummy_run_dir += os.sep + "any_ensmem"

    namsfc_dict = {}
    for mapping in fixed_cfg["FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING"]:
        nml_var_name, sfc_climo_field_name = re.search(regex_search, mapping).groups()

        check_var_valid_value(sfc_climo_field_name, fixed_cfg["SFC_CLIMO_FIELDS"])

        file_path = os.path.join(FIXlam, f"{CRES}.{sfc_climo_field_name}.{suffix}")
        if RUN_ENVIR != "nco":
            file_path = os.path.relpath(os.path.realpath(file_path), start=dummy_run_dir)

        namsfc_dict[nml_var_name] = file_path

    settings["namsfc_dict"] = namsfc_dict
    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying values of the namelist variables
            has been set as follows:\n
            settings =

            {settings_str}
            """
        ),
        verbose=debug,
    )

    realize(
        input_config=FV3_NML_FP,
        input_format="nml",
        output_file=FV3_NML_FP,
        output_format="nml",
        supplemental_configs=[settings],
        )

def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Set surface climatology fields.")

    parser.add_argument(
        "-p",
        "--path-to-defns",
        dest="path_to_defns",
        required=True,
        help="Path to var_defns file.",
    )
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Script will be run in debug mode with more verbose output')

    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    set_fv3nml_sfc_climo_filenames(cfg, args.debug)
