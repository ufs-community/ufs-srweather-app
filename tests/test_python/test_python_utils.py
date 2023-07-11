#!/usr/bin/env python3

"""
Unit tests for python utilities.

To run them, issue the following command from the ush directory:
    python3 -m unittest -b python_utils/test_python_utils.py

All modules needed to build and run the regional_workflow need to be
loaded first before executing unit tests.

"""

#pylint: disable=invalid-name

import unittest
import glob
import tempfile
import os

import python_utils as util


class Testing(unittest.TestCase):
    """ Define the tests"""

    def test_case_handlers(self):
        """ Test that the case handling string manipulators work as
        expected. """
        self.assertEqual(util.uppercase("upper"), "UPPER")
        self.assertEqual(util.lowercase("LOWER"), "lower")

    def test_pattern_finding(self):
        """ Test that find_pattern_in_file can work with a string or a
        file path"""

        # Test given a file path
        pattern = "^[ ]*<scheme>(lsm_ruc)</scheme>[ ]*$"
        test_file = os.path.join(
           self.ushdir,
           "test_data",
           "suite_FV3_GSD_SAR.xml",
           )
        match = util.find_pattern_in_file(pattern, test_file)
        self.assertEqual(("lsm_ruc",), match)

        # Test given a string
        with open(test_file, encoding='utf-8') as file_:
            content = file_.read()

        util.find_pattern_in_str(pattern, content)
        self.assertEqual(("lsm_ruc",), match)

    def test_xml_parser(self):
        """ Given an input CCPP xml file, check that the XML is loaded
        as expected, and has a tag."""
        test_file = os.path.join(
              self.ushdir,
              "test_data",
              "suite_FV3_GSD_SAR.xml",
              )
        tree = util.load_xml_file(test_file)
        self.assertTrue(util.has_tag_with_value(tree, "scheme", "lsm_ruc"))

    def test_check_for_preexist_dir_file(self):
        """ Test that when an existing directory should be renamed, it
        still exists and that a new directory is made"""

        with tempfile.TemporaryDirectory(
            dir=os.path.abspath("."),
            prefix="preexist_space",
            ) as tmp_dir:

            # Check cmd_vrfy works
            existing_dir = os.path.join(tmp_dir, "dir")
            util.cmd_vrfy(f"mkdir -p {existing_dir}")
            self.assertTrue(os.path.exists(existing_dir))

            # Given a preexisting directory, move it and test that they both
            # exist.
            util.check_for_preexist_dir_file(existing_dir, "rename")
            dirs = glob.glob(f"{existing_dir}_*")
            self.assertEqual(len(dirs), 1)

            # Clean up the older version, and test rm_vrfy
            util.rm_vrfy(f"-rf {existing_dir}_*")
            dirs = glob.glob(f"{existing_dir}_*")
            self.assertEqual(len(dirs), 0)

    def test_check_var_valid_value(self):
        """ Test that a string is available in a given list. """
        self.assertTrue(util.check_var_valid_value("rice", ["egg", "spam", "rice"]))

    def test_filesys_cmds(self):
        """ Test the functions that perform filesystem commands"""

        with tempfile.TemporaryDirectory(
            dir=os.path.abspath("."),
            prefix="filesys_space",
            ) as tmp_dir:

            testable_path = os.path.join(
                tmp_dir,
                "dir",
                )

            # Make sure a desired path is created
            util.mkdir_vrfy(testable_path)
            self.assertTrue(os.path.exists(testable_path))

            # Make sure a file is copied
            util.cp_vrfy(f"{self.ushdir}/python_utils/misc.py", f"{testable_path}/miscs.py")
            self.assertTrue(os.path.exists(f"{testable_path}/miscs.py"))

            # Run a platform native command
            util.cmd_vrfy(f"rm -rf {testable_path}")

            self.assertFalse(os.path.exists(testable_path))

    def test_run_command(self):
        """ Test the return of the run_command task is as expected."""
        self.assertEqual(util.run_command("echo hello"), (0, "hello", ""))

    def test_create_symlink_to_file(self):
        """ Test that a simlink is created as expected."""

        target = f"{self.test_dir}/test_python_utils.py"
        with tempfile.TemporaryDirectory(
            dir=os.path.abspath("."),
            prefix="simlink_space",
            ) as tmp_dir:

            symlink = os.path.join(
                tmp_dir,
                "test_python_utils.py"
                )
            util.create_symlink_to_file(target, symlink)

    def test_define_macos_utilities(self):
        """ Test that environment setting and getting utils work. Also,
        that environment contains macos utilities (arranged in setUP)"""

        util.set_env_var("MACOS_TEST_VAR", "MYVAL")
        py_val = os.getenv("MACOS_TEST_VAR")
        srw_val = util.get_env_var("MACOS_TEST_VAR")

        # Validate the real env was set, and that the srw_supported
        # function retrieves the same value.
        self.assertEqual(py_val, "MYVAL")
        self.assertEqual(srw_val, "MYVAL")

        self.assertEqual(os.getenv("SED"), "gsed" if os.uname() == "Darwin" else "sed")

    def test_print_input_args(self):
        """ Test that print_input_args can count the args. """
        valid_args = {"arg1": 1, "arg2": 2, "arg3": 3, "arg4": 4}
        self.assertEqual(util.print_input_args(valid_args), 4)

    def test_import_vars(self):
        """ Test import/export vars."""
        # test import
        global IMPORT_TEST_VAR #pylint: disable=global-variable-undefined

        util.set_env_var("IMPORT_TEST_VAR", "MYVAL")
        env_vars = ["PWD", "IMPORT_TEST_VAR"]

        # Makes all environment variables available in local scope for
        # python
        util.import_vars(env_vars=env_vars)

        # assuming all environments already have $PWD set
        self.assertEqual(
            os.path.realpath(PWD), #pylint: disable=undefined-variable
            os.path.realpath(os.getcwd())
            )
        self.assertEqual(IMPORT_TEST_VAR, "MYVAL") #pylint: disable=used-before-assignment

        # test export
        IMPORT_TEST_VAR = "MYNEWVAL"
        self.assertEqual(os.environ["IMPORT_TEST_VAR"], "MYVAL")
        util.export_vars(env_vars=env_vars)
        self.assertEqual(os.environ["IMPORT_TEST_VAR"], "MYNEWVAL")

        # test custom dictionary
        dictionary = {"Hello": "World!"}
        util.import_vars(dictionary=dictionary)
        self.assertEqual(Hello, "World!") #pylint: disable=undefined-variable

    def test_str_to_list(self):
        """ Test transforming a string formatted like a list into a
        proper python list"""
        # string has closing bracket
        shell_str = '("1" "2") \n'
        v = util.str_to_list(shell_str)
        self.assertTrue(isinstance(v, list))
        self.assertEqual(v, [1, 2])

        # string does not have closing bracket
        shell_str = '( "1" "2" \n'
        v = util.str_to_list(shell_str)
        self.assertFalse(isinstance(v, list))

    def test_config_parser(self):
        """ Test loading different config files """
        cfg = {"HRS": ["1", "2"]}
        shell_str = util.cfg_to_shell_str(cfg)
        self.assertIn('HRS=( "1" "2" )\n', shell_str)
        # ini file
        file_path = os.path.join(
            self.ushdir,
            "python_utils",
            "test_data",
            "Externals.cfg",
            )
        cfg = util.load_ini_config(file_path)
        self.assertIn(
            "regional_workflow", util.get_ini_value(cfg, "regional_workflow", "repo_url")
        )

    def test_print_msg(self):
        """ Test that a bool is returned from print_info_msg"""
        self.assertEqual(util.print_info_msg("Hello World!", verbose=False), False)

    def setUp(self):
        """setUp is where we do preparation for running the unittests.
        If you need to download files for running test cases, prepare common stuff
        for all test cases etc, this is the best place to do it"""

        util.define_macos_utilities()
        util.set_env_var("DEBUG", "FALSE")
        self.test_dir = os.path.dirname(os.path.abspath(__file__))
        self.ushdir = os.path.join(self.test_dir, "..", "..", "ush")

if __name__ == "__main__":
    unittest.main()
