""" Tests for create_diag_table_file.py """

#pylint: disable=invalid-name
import os
import unittest

from python_utils import set_env_var

from create_diag_table_file import create_diag_table_file

class Testing(unittest.TestCase):
    """ Define the tests """
    def test_create_diag_table_file(self):
        """ Test that when called with user config settings, the
        function returns True """
        path = os.path.join(os.getenv("USHdir"), "test_data")
        self.assertTrue(create_diag_table_file(run_dir=path))

    def setUp(self):
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        PARMdir = os.path.join(USHdir, "..", "parm")
        diag_table_fn = "diag_table"
        diag_table_tmpl_fp = os.path.join(PARMdir, f"{diag_table_fn}.FV3_GFS_v15p2")
        set_env_var("DEBUG", True)
        set_env_var("VERBOSE", True)
        set_env_var("USHdir", USHdir)
        set_env_var("DIAG_TABLE_FN", diag_table_fn)
        set_env_var("DIAG_TABLE_TMPL_FP", diag_table_tmpl_fp)
        set_env_var("CRES", "C48")
        set_env_var("CDATE", "2021010106")
        set_env_var("UFS_FIRE", False)
