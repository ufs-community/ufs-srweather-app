#!/usr/bin/env python3

"""
Function to create a NEMS configuration file for the FV3 forecast
model(s) from a template.
"""

import os
import sys
import argparse
import tempfile
from textwrap import dedent

from python_utils import (
    import_vars,
    print_input_args,
    print_info_msg,
    cfg_to_yaml_str,
    load_shell_config,
    flatten_dict,
)

# These come from ush/python_utils/workflow-tools
from scripts.templater import set_template

def create_nems_configure_file(run_dir):
    """ Creates a nems configuration file in the specified
    run directory

    Args:
        run_dir: run directory
    Returns:
        Boolean
    """

    print_input_args(locals())

    #import all environment variables
    import_vars()

    # pylint: disable=undefined-variable

    #
    #-----------------------------------------------------------------------
    #
    # Create a NEMS configuration file in the specified run directory.
    #
    #-----------------------------------------------------------------------
    #
    print_info_msg(f'''
        Creating a nems.configure file (\"{NEMS_CONFIG_FN}\") in the specified 
        run directory (run_dir):
          run_dir = \"{run_dir}\"''', verbose=VERBOSE)
    #
    # Set output file path
    #
    nems_config_fp = os.path.join(run_dir, NEMS_CONFIG_FN)
    pe_member01_m1 = str(int(PE_MEMBER01)-1)
    #
    #-----------------------------------------------------------------------
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the jinja variables in the template
    # model_configure file should be set to.
    #
    #-----------------------------------------------------------------------
    #
    settings = {
      "dt_atmos": DT_ATMOS,
      "print_esmf": PRINT_ESMF,
      "cpl_aqm": CPL_AQM,
      "pe_member01_m1": pe_member01_m1,
      "atm_omp_num_threads": OMP_NUM_THREADS_RUN_FCST,
    }
    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable \"settings\" specifying values to be used in the \"{NEMS_CONFIG_FN}\"
            file has been set as follows:\n
            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )
    #
    #-----------------------------------------------------------------------
    #
    # Call a python script to generate the experiment's actual NEMS_CONFIG_FN
    # file from the template file.
    #
    #-----------------------------------------------------------------------
    #
    # Store the settings in a temporary file
    with tempfile.NamedTemporaryFile(dir="./",
                                     mode="w+t",
                                     prefix="nems_config_settings",
                                     suffix=".yaml") as tmpfile:
        tmpfile.write(settings_str)
        tmpfile.seek(0)

        set_template(["-c", tmpfile.name, "-i", NEMS_CONFIG_TMPL_FP, "-o", nems_config_fp])
    return True

def parse_args(argv):
    """ Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Creates NEMS configuration file.'
    )

    parser.add_argument("-r", "--run-dir",
                        dest="run_dir",
                        required=True,
                        help="Run directory.")

    parser.add_argument("-p", "--path-to-defns",
                        dest="path_to_defns",
                        required=True,
                        help="Path to var_defns file.")

    return parser.parse_args(argv)

if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    create_nems_configure_file(
        run_dir=args.run_dir,
    )
