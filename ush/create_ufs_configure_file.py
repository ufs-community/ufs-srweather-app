#!/usr/bin/env python3

"""
Creates a UFS configuration file for the FV3 forecast model(s) from a template.
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

def create_ufs_configure_file(run_dir):
    """ Creates a UFS configuration file in the specified run directory

    Args:
        run_dir (str): Run directory
    Returns:
        True
    """

    print_input_args(locals())

    #import all environment variables
    import_vars()

    # pylint: disable=undefined-variable

    #
    #-----------------------------------------------------------------------
    #
    # Create a UFS configuration file in the specified run directory.
    #
    #-----------------------------------------------------------------------
    #
    print_info_msg(f'''
        Creating a ufs.configure file (\"{UFS_CONFIG_FN}\") in the specified
        run directory (run_dir):
          run_dir = \"{run_dir}\"''', verbose=VERBOSE)
    #
    # Set output file path
    #
    ufs_config_fp = os.path.join(run_dir, UFS_CONFIG_FN)
    pe_member01_m1 = str(int(PE_MEMBER01)-1)
    aqm_pe_member01_m1 = str(int(LAYOUT_X*LAYOUT_Y)-1)
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
      "aqm_pe_member01_m1": aqm_pe_member01_m1,
      "atm_omp_num_threads": OMP_NUM_THREADS_RUN_FCST,
    }
    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable \"settings\" specifying values to be used in the \"{UFS_CONFIG_FN}\"
            file has been set as follows:\n
            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )
    #
    #-----------------------------------------------------------------------
    #
    # Call a python script to generate the experiment's actual UFS_CONFIG_FN
    # file from the template file.
    #
    #-----------------------------------------------------------------------
    #
    render(
        input_file = UFS_CONFIG_TMPL_FP,
        output_file = ufs_config_fp,
        values_src = settings,
        )
    return True

def _parse_args(argv):
    """ Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Creates UFS configuration file.'
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
    args = _parse_args(sys.argv[1:])
    cfg = load_yaml_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    create_ufs_configure_file(
        run_dir=args.run_dir,
    )
