#!/usr/bin/env python3

import os
import sys
import argparse
import unittest
from textwrap import dedent

from python_utils import import_vars, set_env_var, print_input_args, \
                         print_info_msg, print_err_msg_exit, cfg_to_yaml_str, \
                         load_shell_config

from fill_jinja_template import fill_jinja_template

def create_diag_table_file(run_dir):
    """ Creates a diagnostic table file for each cycle to be run

    Args:
        run_dir: run directory
    Returns:
        Boolean
    """

    print_input_args(locals())

    #import all environment variables
    import_vars()
    
    #create a diagnostic table file within the specified run directory
    print_info_msg(f'''
        Creating a diagnostics table file (\"{DIAG_TABLE_FN}\") in the specified
        run directory...
        
          run_dir = \"{run_dir}\"''', verbose=VERBOSE)

    diag_table_fp = os.path.join(run_dir, DIAG_TABLE_FN)

    print_info_msg(f'''
        
        Using the template diagnostics table file:
        
            diag_table_tmpl_fp = {DIAG_TABLE_TMPL_FP}
        
        to create:
        
            diag_table_fp = \"{diag_table_fp}\"''', verbose=VERBOSE)

    settings = {
       'starttime': CDATE,
       'cres': CRES
    }
    settings_str = cfg_to_yaml_str(settings)

    #call fill jinja
    try:
        fill_jinja_template(["-q", "-u", settings_str, "-t", DIAG_TABLE_TMPL_FP, "-o", diag_table_fp])
    except:
        print_err_msg_exit(f'''
            !!!!!!!!!!!!!!!!!
            
            fill_jinja_template.py failed!
            
            !!!!!!!!!!!!!!!!!''')
        return False
    return True

def parse_args(argv):
    """ Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Creates diagnostic table file.'
    )

    parser.add_argument('-r', '--run-dir',
                        dest='run_dir',
                        required=True,
                        help='Run directory.')

    parser.add_argument('-p', '--path-to-defns',
                        dest='path_to_defns',
                        required=True,
                        help='Path to var_defns file.')

    return parser.parse_args(argv)

if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    import_vars(dictionary=cfg)
    create_diag_table_file(args.run_dir)

class Testing(unittest.TestCase):
    def test_create_diag_table_file(self):
        path = os.path.join(os.getenv('USHDIR'), "test_data")
        self.assertTrue(create_diag_table_file(run_dir=path))
    def setUp(self):
        USHDIR = os.path.dirname(os.path.abspath(__file__))
        DIAG_TABLE_FN="diag_table"
        DIAG_TABLE_TMPL_FP = os.path.join(USHDIR,"templates",f"{DIAG_TABLE_FN}.FV3_GFS_v15p2")
        set_env_var('DEBUG',True)
        set_env_var('VERBOSE',True)
        set_env_var("USHDIR",USHDIR)
        set_env_var("DIAG_TABLE_FN",DIAG_TABLE_FN)
        set_env_var("DIAG_TABLE_TMPL_FP",DIAG_TABLE_TMPL_FP)
        set_env_var("CRES","C48")
        set_env_var("CDATE","2021010106")

