#!/usr/bin/env python3

import os
import sys
import argparse
from textwrap import dedent

from python_utils import (
    print_input_args,
    print_info_msg,
    print_err_msg_exit,
    check_var_valid_value,
    mv_vrfy,
    mkdir_vrfy,
    cp_vrfy,
    rm_vrfy,
    import_vars,
    set_env_var,
    load_config_file,
    load_shell_config,
    flatten_dict,
    define_macos_utilities,
    find_pattern_in_str,
    cfg_to_yaml_str,
)



def set_FV3nml_sfc_climo_filenames(debug=False):
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

    # import all environment variables
    import_vars()

    # fixed file mapping variables
    fixed_cfg = load_config_file(os.path.join(PARMdir, "fixed_files_mapping.yaml"))
    IMPORTS = ["SFC_CLIMO_FIELDS", "FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING"]
    import_vars(dictionary=flatten_dict(fixed_cfg), env_vars=IMPORTS)

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
    for mapping in FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING:
        tup = find_pattern_in_str(regex_search, mapping)
        nml_var_name = tup[0]
        sfc_climo_field_name = tup[1]

        check_var_valid_value(sfc_climo_field_name, SFC_CLIMO_FIELDS)

        fp = os.path.join(FIXlam, f"{CRES}.{sfc_climo_field_name}.{suffix}")
        if RUN_ENVIR != "nco":
            fp = os.path.relpath(os.path.realpath(fp), start=dummy_run_dir)

        namsfc_dict[nml_var_name] = fp

    settings["namsfc_dict"] = namsfc_dict
    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying values of the namelist variables
            has been set as follows:\n
            settings =\n\n"""
        )
        + settings_str,
        verbose=debug,
    )

    # Update the namelist file
    try:
        with tempfile.NamedTemporaryFile(
            dir="./",
            mode="w+t",
            prefix="namelist_settings",
            suffix=".yaml") as tmpfile:
            tmpfile.write(cfg_to_yaml_str(settings))
            tmpfile.seek(0)
            subprocess.run(["uw config realize",
                "-i", FV3_NML_FP,
                "-o", FV3_NML_FP,
                "-v",
                "--values-file", tmpfile,
                ]
            )
    except:
        print_err_msg_exit(
            dedent(
                f"""
                Updating the FV3 namelist with paths to the surface climatology
                files failed.
                    Values to be updated:\n\n"""
            )
            + settings_str
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
    import_vars(dictionary=cfg)
    set_FV3nml_sfc_climo_filenames(args.debug)
