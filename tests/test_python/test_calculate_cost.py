""" Tests for calculate_cost.py"""

#pylint: disable=invalid-name
import os
import unittest

from calculate_cost import calculate_cost

class Testing(unittest.TestCase):
    """ Define the tests"""
    def test_calculate_cost(self):
        """ Test that the function returns the expected value for a
        given config file."""
        test_dir = os.path.dirname(os.path.abspath(__file__))
        USHdir = os.path.join(test_dir, "..", "..", "ush")
        params = calculate_cost(os.path.join(USHdir, 'config.community.yaml'))
        self.assertCountEqual(params, [150, 28689, 150, 28689])
