#!/usr/bin/env python3

"""
Set up a namelist that points to the appropriate surface climatology
files.
"""

import os
import sys
import argparse
from textwrap import dedent

from python_utils import (
    print_info_msg,
    check_var_valid_value,
    mv_vrfy,
    rm_vrfy,
    import_vars,
    load_config_file,
    load_shell_config,
    flatten_dict,
    find_pattern_in_str,
    cfg_to_yaml_str,
)

# These come from ush/python_utils/uwtools
from scripts.set_config import create_config_file
from uwtools import exceptions


def set_fv3nml_sfc_climo_filenames():
    """
    This function sets the values of the variables in
    the forecast model's namelist file that specify the paths to the surface
    climatology files on the FV3LAM native grid (which are either pregenerated
    or created by the TN_MAKE_SFC_CLIMO task).  Note that the workflow
    generation scripts create symlinks to these surface climatology files
    in the FIXlam directory, and the values in the namelist file that get
    set by this function are relative or full paths to these links.

    Args:
        None
    Returns:
        None
    """

    # import all environment variables
    import_vars()

    # pylint: disable=undefined-variable

    # fixed file mapping variables
    fixed_cfg = load_config_file(os.path.join(PARMdir, "fixed_files_mapping.yaml"))
    fixed_cfg = fixed_cfg.get("fixed_files")

    # Set the suffix of the surface climatology files.
    suffix = "tileX.nc"

    # create yaml-compliant string
    settings = {}

    dummy_run_dir = os.path.join(EXPTDIR, "any_cyc")
    if DO_ENSEMBLE == "TRUE":
        os.path.join(dummy_run_dir, "any_ensmem")

    namsfc_dict = {}
    # mapping_list is a list of single dictionaries
    SFC_CLIMO_FIELDS = fixed_cfg.get('SFC_CLIMO_FIELDS')
    mapping_list = fixed_cfg.get('FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING')
    for mapping in mapping_list:
        nml_var_name, sfc_climo_field_name = list(mapping.items())[0]
        check_var_valid_value(sfc_climo_field_name, SFC_CLIMO_FIELDS)

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
        verbose=VERBOSE,
    )

    # Rename the FV3 namelist and update namelist values
    fv3_nml_base_fp = f"{FV3_NML_FP}.bk"
    mv_vrfy(f"{FV3_NML_FP} {fv3_nml_base_fp}")

    try:
        create_config_file(
            [
                "-i", fv3_nml_base_fp,
                "--input_file_type", "F90",
                "-o", FV3_NML_FP,
                "--output_file_type", "F90",
            ],
            config_dict=settings,
        )
    except exceptions.UWConfigError as e:
        sys.exit(e)

    rm_vrfy(f"{fv3_nml_base_fp}")


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

    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    set_fv3nml_sfc_climo_filenames()
