""" Tests for get_crontab_contents.py"""

import unittest

from python_utils import define_macos_utilities
from get_crontab_contents import get_crontab_contents

class Testing(unittest.TestCase):
    """ Define the tests"""
    def test_get_crontab_contents(self):
        """ Call the function and make sure it doesn't fail. """
        crontab_cmd, _ = get_crontab_contents(called_from_cron=True,machine="HERA",debug=True)
        self.assertEqual(crontab_cmd, "crontab")

    def setUp(self):
        define_macos_utilities()
