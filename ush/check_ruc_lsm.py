#!/usr/bin/env python3

import os
import unittest

from python_utils import set_env_var, print_input_args, \
                         load_xml_file, has_tag_with_value

def check_ruc_lsm(ccpp_phys_suite_fp):
    """ This file defines a function that checks whether the RUC land surface
    model (LSM) parameterization is being called by the selected physics suite.

    Args:
        ccpp_phys_suite_fp: full path to CCPP physics suite xml file
    Returns:
        Boolean
    """

    print_input_args(locals())

    tree = load_xml_file(ccpp_phys_suite_fp)
    has_ruc = has_tag_with_value(tree, "scheme", "lsm_ruc")
    return has_ruc

class Testing(unittest.TestCase):
    def test_check_ruc_lsm(self):
        self.assertTrue( check_ruc_lsm(ccpp_phys_suite_fp=f"test_data{os.sep}suite_FV3_GSD_SAR.xml") )
    def setUp(self):
        set_env_var('DEBUG',True)

