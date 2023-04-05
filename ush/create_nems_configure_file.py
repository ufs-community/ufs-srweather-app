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
    try:
        fill_jinja_template(["-q", "-u", settings_str, "-t", NEMS_CONFIG_TMPL_FP, "-o", nems_config_fp])
    except:
        print_err_msg_exit(
            dedent(
                f"""
            Call to python script fill_jinja_template.py to create the nems.configure
            file from a jinja2 template failed.  Parameters passed to this script are:
              Full path to template nems.configure file:
                NEMS_CONFIG_TMPL_FP = \"{NEMS_CONFIG_TMPL_FP}\"
              Full path to output nems.configure file:
                nems_config_fp = \"{nems_config_fp}\"
              Namelist settings specified on command line:\n
                settings =\n\n"""
            )
            + settings_str
        )
        return False

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


