#!/usr/bin/env python3

import copy
import os
from textwrap import dedent

from python_utils import (
    print_input_args,
    load_xml_file,
    has_tag_with_value,
)


def set_ozone_param(ccpp_phys_suite_fp, link_mappings):
    """Function that does the following:
    (1) Determines the ozone parameterization being used by checking in the
        CCPP physics suite XML.

    (2) Sets the name of the global ozone production/loss file in the FIXgsm
        FIXgsm system directory to copy to the experiment's FIXam directory.

    (3) Updates the symlink for the ozone file provided in link_mappings
        dict to include the name of global ozone production/loss file.

    Args:
        ccpp_phys_suite_fp: full path to CCPP physics suite
        link_mappings: list of mappings between symlinks and their
                       target files for this experiment. Each mapping is
                       a dict.
    Returns:
        ozone_param: a string
        fixgsm_ozone_fn: a path to a fix file that should be used with
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

    # Set the target file we just found
    for mapping in link_mappings:
        if "global_o3prdlos.f77" in mapping:
            mapping["global_o3prdlos.f77"] = fixgsm_ozone_fn

    return ozone_param, fixgsm_ozone_fn
