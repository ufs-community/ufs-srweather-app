#!/usr/bin/env python3

"""
Unit tests for python utilities.

To run them, issue the following command from the ush directory:
    python3 -m unittest -b python_utils/test_python_utils.py

All modules needed to build and run the regional_workflow need to be
loaded first before executing unit tests.

"""

import unittest
import glob
import os

from python_utils import *

class Testing(unittest.TestCase):
    def test_change_case(self):
        self.assertEqual( uppercase('upper'), 'UPPER' )
        self.assertEqual( lowercase('LOWER'), 'lower' )
    def test_check_for_preexist_dir_file(self):
        cmd_vrfy('mkdir -p test_data/dir')
        self.assertTrue( os.path.exists('test_data/dir') )
        check_for_preexist_dir_file('test_data/dir', 'rename')
        dirs = glob.glob('test_data/dir_*')
        self.assertEqual( len(dirs), 1)
        rm_vrfy('-rf test_data/dir*')
    def test_check_var_valid_value(self):
        self.assertTrue( check_var_valid_value('rice', [ 'egg', 'spam', 'rice' ]) )
    def test_count_files(self):
        (_,target_cnt,_) = run_command('ls -l *.py | wc -l')
        cnt = count_files('py')
        self.assertEqual(cnt, int(target_cnt))
    def test_filesys_cmds(self):
        dPATH=f'{self.PATH}/test_data/dir'
        mkdir_vrfy(dPATH)
        self.assertTrue( os.path.exists(dPATH) )
        cp_vrfy(f'{self.PATH}/change_case.py', f'{dPATH}/change_cases.py')
        self.assertTrue( os.path.exists(f'{dPATH}/change_cases.py') )
        cmd_vrfy(f'rm -rf {dPATH}')
        self.assertFalse( os.path.exists('tt.py') )
    def test_get_charvar_from_netcdf(self):
        FILE=f'{self.PATH}/test_data/sample.nc'
        val = get_charvar_from_netcdf(FILE, 'pressure')
        self.assertTrue( val and (val.split()[0], '955.5,'))
    def test_run_command(self):
        self.assertEqual( run_command('echo hello'), (0, 'hello', '') )
    def test_get_elem_inds(self):
        arr = [ 'egg', 'spam', 'egg', 'rice', 'egg']
        self.assertEqual( get_elem_inds(arr, 'egg', 'first' ) , 0 )
        self.assertEqual( get_elem_inds(arr, 'egg', 'last' ) , 4 )
        self.assertEqual( get_elem_inds(arr, 'egg', 'all' ) , [0, 2, 4] )
    def test_get_manage_externals_config_property(self):
        self.assertIn( \
            'regional_workflow',
            get_manage_externals_config_property( \
                f'{self.PATH}/test_data/Externals.cfg',
                'regional_workflow',
                'repo_url'))
    def test_interpol_to_arbit_CRES(self):
        RES = 800
        RES_array = [ 5, 25, 40, 60, 80, 100, 400, 700, 1000, 1500, 2800, 3000 ]
        prop_array = [ 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.65, 0.7, 1.0, 1.1, 1.2, 1.3 ]
        prop = interpol_to_arbit_CRES(RES, RES_array, prop_array)
        self.assertAlmostEqual(prop, 0.8)
    def test_create_symlink_to_file(self):
        TARGET = f'{self.PATH}/test_python_utils.py'
        SYMLINK = f'{self.PATH}/test_data/test_python_utils.py'
        create_symlink_to_file(TARGET,SYMLINK)
    def test_define_macos_utilities(self):
        set_env_var('MYVAR','MYVAL')
        val = os.getenv('MYVAR')
        self.assertEqual(val,'MYVAL')
        self.assertEqual(os.getenv('SED'),
            'gsed' if os.uname() == 'Darwin' else 'sed')
    def test_process_args(self):
        valid_args = [ "arg1", "arg2", "arg3", "arg4" ]
        values = process_args( valid_args,
                arg2 = "bye", arg3 = "hello",
                arg4 = ["this", "is", "an", "array"] )
        self.assertEqual(values,
            {'arg1': None,
             'arg2': 'bye',
             'arg3': 'hello',
             'arg4': ['this', 'is', 'an', 'array']} )
    def test_print_input_args(self):
        valid_args = { "arg1":1, "arg2":2, "arg3":3, "arg4":4 }
        self.assertEqual( print_input_args(valid_args), 4 )
    def test_import_vars(self):
        #test import
        global MYVAR
        set_env_var("MYVAR","MYVAL")
        env_vars = ["PWD", "MYVAR"]
        import_vars(env_vars=env_vars)
        self.assertEqual( PWD, os.getcwd() )
        self.assertEqual(MYVAR,"MYVAL")
        #test export
        MYVAR="MYNEWVAL"
        self.assertEqual(os.environ['MYVAR'],'MYVAL')
        export_vars(env_vars=env_vars)
        self.assertEqual(os.environ['MYVAR'],'MYNEWVAL')
        #test custom dictionary
        dictionary = { "Hello": "World!" }
        import_vars(dictionary=dictionary)
        self.assertEqual( Hello, "World!" )
    def test_config_parser(self):
        cfg = { "HRS": [ "1", "2" ] }
        shell_str = cfg_to_shell_str(cfg)
        self.assertEqual( shell_str, 'HRS=( "1" "2" )\n')
    def test_print_msg(self):
        self.assertEqual( print_info_msg("Hello World!", verbose=False), False)
    def setUp(self):
        """ setUp is where we do preparation for running the unittests.
        If you need to download files for running test cases, prepare common stuff
        for all test cases etc, this is the best place to do it """
        define_macos_utilities();
        set_env_var('DEBUG','FALSE')
        self.PATH = os.path.dirname(__file__)
        
if __name__ == '__main__':
    unittest.main()

