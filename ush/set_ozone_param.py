#!/usr/bin/env python3

import copy
import os
import unittest
from textwrap import dedent

from python_utils import (
    log_info,
    list_to_str,
    print_input_args,
    load_xml_file,
    has_tag_with_value,
    find_pattern_in_str,
)


def set_ozone_param(ccpp_phys_suite_fp, link_mappings):
    """Function that does the following:
    (1) Determines the ozone parameterization being used by checking in the
        CCPP physics suite XML.

    (2) Sets the name of the global ozone production/loss file in the FIXgsm
        FIXgsm system directory to copy to the experiment's FIXam directory.

    (3) Updates the symlink for the ozone file provided in link_mappings
        list to include the name of global ozone production/loss file.

    Args:
        ccpp_phys_suite_fp: full path to CCPP physics suite
        link_mappings: list of mappings between symlinks and their
                       target files for this experiment
    Returns:
        ozone_param: a string
        fixgsm_ozone_fn: a path to a fix file that should be used with
                        this experiment
        ozone_link_mappings: a list of mappings for the files needed for
                             this experiment

    """

    print_input_args(locals())

    #
    # -----------------------------------------------------------------------
    #
    # Get the name of the ozone parameterization being used.  There are two
    # possible ozone parameterizations:
    #
    # (1) A parameterization developed/published in 2015.  Here, we refer to
    #     this as the 2015 parameterization.  If this is being used, then we
    #     set the variable ozone_param to the string "ozphys_2015".
    #
    # (2) A parameterization developed/published sometime after 2015.  Here,
    #     we refer to this as the after-2015 parameterization.  If this is
    #     being used, then we set the variable ozone_param to the string
    #     "ozphys".
    #
    # We check the CCPP physics suite definition file (SDF) to determine the
    # parameterization being used.  If this file contains the line
    #
    #   <scheme>ozphys_2015</scheme>
    #
    # then the 2015 parameterization is being used.  If it instead contains
    # the line
    #
    #   <scheme>ozphys</scheme>
    #
    # then the after-2015 parameterization is being used.  (The SDF should
    # contain exactly one of these lines; not both nor neither; we check for
    # this.)
    #
    # -----------------------------------------------------------------------
    #
    tree = load_xml_file(ccpp_phys_suite_fp)
    ozone_param = ""
    if has_tag_with_value(tree, "scheme", "ozphys_2015"):
        fixgsm_ozone_fn = "ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77"
        ozone_param = "ozphys_2015"
    elif has_tag_with_value(tree, "scheme", "ozphys"):
        fixgsm_ozone_fn = "global_o3prdlos.f77"
        ozone_param = "ozphys"
    else:
        raise KeyError(
            f"Unknown or no ozone parameterization specified in the "
            "CCPP physics suite file '{ccpp_phys_suite_fp}'"
        )
    #
    # -----------------------------------------------------------------------
    #
    # Set the element in the array CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING that
    # specifies the mapping between the symlink for the ozone production/loss
    # file that must be created in each cycle directory and its target in the
    # FIXam directory.  The name of the symlink is already in the array, but
    # the target is not because it depends on the ozone parameterization that
    # the physics suite uses.  Since we determined the ozone parameterization
    # above, we now set the target of the symlink accordingly.

    #
    # -----------------------------------------------------------------------
    #
    # Set the mapping between the symlink and the target file we just
    # found. The link name is already in the list, but the target file
    # is not.
    #
    # -----------------------------------------------------------------------
    #

    ozone_symlink = "global_o3prdlos.f77"
    fixgsm_ozone_fn_is_set = False

    ozone_link_mappings = copy.deepcopy(link_mappings)
    for i, mapping in enumerate(ozone_link_mappings):
        symlink = mapping.split("|")[0]
        if symlink.strip() == ozone_symlink:
            ozone_link_mappings[i] = f"{symlink}| {fixgsm_ozone_fn}"
            fixgsm_ozone_fn_is_set = True
            break

    # Make sure the list has been updated
    if not fixgsm_ozone_fn_is_set:

        raise Exception(
            f"""
            Unable to set name of the ozone production/loss file in the FIXgsm directory
            in the array that specifies the mapping between the symlinks that need to
            be created in the cycle directories and the files in the FIXgsm directory:
              fixgsm_ozone_fn_is_set = '{fixgsm_ozone_fn_is_set}'"""
        )

    return ozone_param, fixgsm_ozone_fn, ozone_link_mappings


class Testing(unittest.TestCase):
    def test_set_ozone_param(self):
        USHdir = os.path.dirname(os.path.abspath(__file__))
        ozone_param, _, _ = set_ozone_param(
            f"{USHdir}{os.sep}test_data{os.sep}suite_FV3_GSD_SAR.xml",
            self.CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING,
        )
        self.assertEqual("ozphys_2015", ozone_param)

    def setUp(self):
        self.CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING = [
            "aerosol.dat                | global_climaeropac_global.txt",
            "co2historicaldata_2010.txt | fix_co2_proj/global_co2historicaldata_2010.txt",
            "co2historicaldata_2011.txt | fix_co2_proj/global_co2historicaldata_2011.txt",
            "co2historicaldata_2012.txt | fix_co2_proj/global_co2historicaldata_2012.txt",
            "co2historicaldata_2013.txt | fix_co2_proj/global_co2historicaldata_2013.txt",
            "co2historicaldata_2014.txt | fix_co2_proj/global_co2historicaldata_2014.txt",
            "co2historicaldata_2015.txt | fix_co2_proj/global_co2historicaldata_2015.txt",
            "co2historicaldata_2016.txt | fix_co2_proj/global_co2historicaldata_2016.txt",
            "co2historicaldata_2017.txt | fix_co2_proj/global_co2historicaldata_2017.txt",
            "co2historicaldata_2018.txt | fix_co2_proj/global_co2historicaldata_2018.txt",
            "co2historicaldata_2019.txt | fix_co2_proj/global_co2historicaldata_2019.txt",
            "co2historicaldata_2020.txt | fix_co2_proj/global_co2historicaldata_2020.txt",
            "co2historicaldata_2021.txt | fix_co2_proj/global_co2historicaldata_2021.txt",
            "co2historicaldata_glob.txt | global_co2historicaldata_glob.txt",
            "co2monthlycyc.txt          | co2monthlycyc.txt",
            "global_h2oprdlos.f77       | global_h2o_pltc.f77",
            "global_zorclim.1x1.grb     | global_zorclim.1x1.grb",
            "sfc_emissivity_idx.txt     | global_sfc_emissivity_idx.txt",
            "solarconstant_noaa_an.txt  | global_solarconstant_noaa_an.txt",
            "global_o3prdlos.f77        | ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77",
        ]
