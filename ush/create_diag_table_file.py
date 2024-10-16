#!/usr/bin/env python3

"""
Creates a ``diag_table`` file for the FV3 model using a template
"""
import argparse
import os
import sys
from textwrap import dedent
from uwtools.api.template import render

from python_utils import (
    cfg_to_yaml_str,
    flatten_dict,
    import_vars,
    load_yaml_config,
    print_info_msg,
    print_input_args,
)


def create_diag_table_file(run_dir):
    """Creates an FV3 diagnostic table (``diag_table``) file for each cycle to be run

    Args:
        run_dir (str): Run directory
    Returns:
        True
    """

    print_input_args(locals())

    # import all environment variables
    import_vars()

    #pylint: disable=undefined-variable
    # create a diagnostic table file within the specified run directory
    print_info_msg(
        f"""
        Creating a diagnostics table file ('{DIAG_TABLE_FN}') in the specified
        run directory...

          run_dir = '{run_dir}'""",
        verbose=VERBOSE,
    )

    diag_table_fp = os.path.join(run_dir, DIAG_TABLE_FN)

    print_info_msg(
        f"""
        Using the template diagnostics table file:

            diag_table_tmpl_fp = {DIAG_TABLE_TMPL_FP}

        to create:

            diag_table_fp = '{diag_table_fp}'""",
        verbose=VERBOSE,
    )

    settings = {"starttime": CDATE, "cres": CRES, "additional_entries": ""}
    if UFS_FIRE:
        settings["additional_entries"] = \
                '"gfs_phys","fsmoke","fsmoke","fv3_history","all",.false.,"none",2'
    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying values to be used in the '{DIAG_TABLE_FN}'
            file has been set as follows:\n
            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )

    render(
        input_file = DIAG_TABLE_TMPL_FP,
        output_file = diag_table_fp,
        values_src = settings,
        )
    return True


def _parse_args(argv):
    """Parses command line arguments"""
    parser = argparse.ArgumentParser(description="Creates diagnostic table file.")

    parser.add_argument(
        "-r", "--run-dir", dest="run_dir", required=True, help="Run directory."
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
    args = _parse_args(sys.argv[1:])
    cfg = load_yaml_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    create_diag_table_file(args.run_dir)
