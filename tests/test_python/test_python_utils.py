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
    def test_misc(self):
        self.assertEqual(uppercase("upper"), "UPPER")
        self.assertEqual(lowercase("LOWER"), "lower")
        # regex in file
        pattern = "^[ ]*<scheme>(lsm_ruc)<\/scheme>[ ]*$"
        FILE = f"{self.PATH}/../test_data/suite_FV3_GSD_SAR.xml"
        match = find_pattern_in_file(pattern, FILE)
        self.assertEqual(("lsm_ruc",), match)
        # regex in string
        with open(FILE) as f:
            content = f.read()
            find_pattern_in_str(pattern, content)
            self.assertEqual(("lsm_ruc",), match)

    def test_xml_parser(self):
        FILE = f"{self.PATH}/../test_data/suite_FV3_GSD_SAR.xml"
        tree = load_xml_file(FILE)
        self.assertTrue(has_tag_with_value(tree, "scheme", "lsm_ruc"))

    def test_check_for_preexist_dir_file(self):
        cmd_vrfy("mkdir -p test_data/dir")
        self.assertTrue(os.path.exists("test_data/dir"))
        check_for_preexist_dir_file("test_data/dir", "rename")
        dirs = glob.glob("test_data/dir_*")
        self.assertEqual(len(dirs), 1)
        rm_vrfy("-rf test_data/dir*")

    def test_check_var_valid_value(self):
        self.assertTrue(check_var_valid_value("rice", ["egg", "spam", "rice"]))

    def test_filesys_cmds(self):
        dPATH = f"{self.PATH}/test_data/dir"
        mkdir_vrfy(dPATH)
        self.assertTrue(os.path.exists(dPATH))
        cp_vrfy(f"{self.PATH}/misc.py", f"{dPATH}/miscs.py")
        self.assertTrue(os.path.exists(f"{dPATH}/miscs.py"))
        cmd_vrfy(f"rm -rf {dPATH}")
        self.assertFalse(os.path.exists("tt.py"))

    def test_run_command(self):
        self.assertEqual(run_command("echo hello"), (0, "hello", ""))

    def test_create_symlink_to_file(self):
        TARGET = f"{self.PATH}/test_python_utils.py"
        SYMLINK = f"{self.PATH}/test_data/test_python_utils.py"
        create_symlink_to_file(TARGET, SYMLINK)

    def test_define_macos_utilities(self):
        set_env_var("MYVAR", "MYVAL")
        val = os.getenv("MYVAR")
        self.assertEqual(val, "MYVAL")
        self.assertEqual(os.getenv("SED"), "gsed" if os.uname() == "Darwin" else "sed")

    def test_print_input_args(self):
        valid_args = {"arg1": 1, "arg2": 2, "arg3": 3, "arg4": 4}
        self.assertEqual(print_input_args(valid_args), 4)

    def test_import_vars(self):
        # test import
        global MYVAR
        set_env_var("MYVAR", "MYVAL")
        env_vars = ["PWD", "MYVAR"]
        import_vars(env_vars=env_vars)
        self.assertEqual(os.path.realpath(PWD), os.path.realpath(os.getcwd()))
        self.assertEqual(MYVAR, "MYVAL")
        # test export
        MYVAR = "MYNEWVAL"
        self.assertEqual(os.environ["MYVAR"], "MYVAL")
        export_vars(env_vars=env_vars)
        self.assertEqual(os.environ["MYVAR"], "MYNEWVAL")
        # test custom dictionary
        dictionary = {"Hello": "World!"}
        import_vars(dictionary=dictionary)
        self.assertEqual(Hello, "World!")
        # test array
        shell_str = '("1" "2") \n'
        v = str_to_list(shell_str)
        self.assertTrue(isinstance(v, list))
        self.assertEqual(v, [1, 2])
        shell_str = '( "1" "2" \n'
        v = str_to_list(shell_str)
        self.assertFalse(isinstance(v, list))

    def test_config_parser(self):
        cfg = {"HRS": ["1", "2"]}
        shell_str = cfg_to_shell_str(cfg)
        self.assertIn('HRS=( "1" "2" )\n', shell_str)
        # ini file
        cfg = load_ini_config(f"{self.PATH}/test_data/Externals.cfg")
        self.assertIn(
            "regional_workflow", get_ini_value(cfg, "regional_workflow", "repo_url")
        )

    def test_print_msg(self):
        self.assertEqual(print_info_msg("Hello World!", verbose=False), False)

    def setUp(self):
        """setUp is where we do preparation for running the unittests.
        If you need to download files for running test cases, prepare common stuff
        for all test cases etc, this is the best place to do it"""

        define_macos_utilities()
        set_env_var("DEBUG", "FALSE")
        self.PATH = os.path.dirname(__file__)


if __name__ == "__main__":
    unittest.main()
