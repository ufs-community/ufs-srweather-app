#!/usr/bin/env python3

"""
Function to create a diag_table file for the FV3 model using a
template.
"""
import argparse
import os
import sys
import tempfile
from subprocess import STDOUT, CalledProcessError, check_output
from textwrap import dedent

from python_utils import (
    import_vars,
    print_input_args,
    print_info_msg,
    cfg_to_yaml_str,
    load_shell_config,
    flatten_dict,
)


def create_diag_table_file(run_dir):
    """Creates a diagnostic table file for each cycle to be run

    Args:
        run_dir: run directory
    Returns:
        Boolean
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

    settings = {"starttime": CDATE, "cres": CRES}
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

    with tempfile.NamedTemporaryFile(dir="./",
                                     mode="w+t",
                                     prefix="aqm_rc_settings",
                                     suffix=".yaml") as tmpfile:
        tmpfile.write(settings_str)
        tmpfile.seek(0)
        cmd = " ".join(["uw template render",
            "-i", DIAG_TABLE_TMPL_FP,
            "-o", diag_table_fp,
            "-v",
            "--values-file", tmpfile.name,
            ]
        )
        indent = "  "
        output = ""
        logfunc = logging.info
        try:
            output = check_output(cmd, encoding="utf=8", shell=True,
                    stderr=STDOUT, text=True)
        except CalledProcessError as e:
            logfunc = logging.error
            output = e.output
            logging.exception("Failed with status: %s", e.returncode)
            raise
        finally:
            logfunc("Output:")
            for line in output.split("\n"):
                logfunc("%s%s", indent * 2, line)
    return True


def parse_args(argv):
    """Parse command line arguments"""
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
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    create_diag_table_file(args.run_dir)
