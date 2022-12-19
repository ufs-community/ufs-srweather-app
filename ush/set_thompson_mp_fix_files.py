#!/usr/bin/env python3

import os
import unittest
from textwrap import dedent

from python_utils import (
    log_info,
    list_to_str,
    print_input_args,
    define_macos_utilities,
    load_xml_file,
    has_tag_with_value,
)


def set_thompson_mp_fix_files(
    ccpp_phys_suite_fp, thompson_mp_climo_fn, link_thompson_climo
):
    """Function that first checks whether the Thompson
    microphysics parameterization is being called by the selected physics
    suite.  If not, it sets the output variable whose name is specified by
    output_varname_sdf_uses_thompson_mp to "FALSE" and exits.  If so, it
    sets this variable to "TRUE" and modifies the workflow arrays
    FIXgsm_FILES_TO_COPY_TO_FIXam and CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING
    to ensure that fixed files needed by the Thompson microphysics
    parameterization are copied to the FIXam directory and that appropriate
    symlinks to these files are created in the run directories.

    Args:
        ccpp_phys_suite_fp: full path to CCPP physics suite
        thompson_mp_climo_fn: netcdf file for thompson microphysics
        link_thompson_climo: whether to use the thompson climo file
    Returns:
        boolean: sdf_uses_thompson_mp
    """

    print_input_args(locals())

    #
    # -----------------------------------------------------------------------
    #
    # Check the suite definition file to see whether the Thompson microphysics
    # parameterization is being used.
    #
    # -----------------------------------------------------------------------
    #
    tree = load_xml_file(ccpp_phys_suite_fp)
    sdf_uses_thompson_mp = has_tag_with_value(tree, "scheme", "mp_thompson")
    #
    # -----------------------------------------------------------------------
    #
    # If the Thompson microphysics parameterization is being used, then...
    #
    # -----------------------------------------------------------------------
    #
    mapping = []
    thompson_mp_fix_files = []
    if sdf_uses_thompson_mp:
        #
        # -----------------------------------------------------------------------
        #
        # Append the names of the fixed files needed by the Thompson microphysics
        # parameterization to the workflow array FIXgsm_FILES_TO_COPY_TO_FIXam,
        # and append to the workflow array CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING
        # the mappings between these files and the names of the corresponding
        # symlinks that need to be created in the run directories.
        #
        # -----------------------------------------------------------------------
        #
        thompson_mp_fix_files = [
            "CCN_ACTIVATE.BIN",
            "freezeH2O.dat",
            "qr_acr_qg.dat",
            "qr_acr_qs.dat",
            "qr_acr_qgV2.dat",
            "qr_acr_qsV2.dat",
        ]

        if link_thompson_climo:
            thompson_mp_fix_files.append(thompson_mp_climo_fn)

        for fix_file in thompson_mp_fix_files:
            mapping.append(f"{fix_file} | {fix_file}")

    return sdf_uses_thompson_mp, mapping, thompson_mp_fix_files


class Testing(unittest.TestCase):
    def test_set_thompson_mp_fix_files(self):
        USHdir = os.path.dirname(os.path.abspath(__file__))
        uses_thompson, _, _ = set_thompson_mp_fix_files(
            f"{USHdir}{os.sep}test_data{os.sep}suite_FV3_GSD_SAR.xml",
            "Thompson_MP_MONTHLY_CLIMO.nc",
            False,
        )
        self.assertEqual(True, uses_thompson)
