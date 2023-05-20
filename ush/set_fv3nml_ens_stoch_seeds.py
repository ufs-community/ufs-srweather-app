#!/usr/bin/env python3

"""
Defines the function that sets the stochastic seed for each ensemble
member in the namelist.
"""

import os
import sys
import argparse
from textwrap import dedent

from python_utils import (
    print_input_args,
    print_info_msg,
    str_to_type,
    import_vars,
    cfg_to_yaml_str,
    load_shell_config,
    flatten_dict,
)

# These come from ush/python_utils/uwtools
from scripts.set_config import create_config_obj
from uwtools import exceptions


def set_fv3nml_ens_stoch_seeds(cdate):
    """
    This function, for an ensemble-enabled experiment
    (i.e. for an experiment for which the workflow configuration variable
    DO_ENSEMBLE has been set to "TRUE"), creates new namelist files with
    unique stochastic "seed" parameters, using a base namelist file in the
    ${EXPTDIR} directory as a template. These new namelist files are stored
    within each member directory housed within each cycle directory. Files
    of any two ensemble members differ only in their stochastic "seed"
    parameter values.  These namelist files are generated when this file is
    called as part of the TN_RUN_FCST task.

    Args:
        cdate
    Returns:
        None
    """

    print_input_args(locals())

    # import all environment variables
    import_vars()

    # pylint: disable=undefined-variable

    #
    # -----------------------------------------------------------------------
    #
    # For a given cycle and member, generate a namelist file with unique
    # seed values.
    #
    # -----------------------------------------------------------------------
    #
    fv3_nml_ensmem_fp = f"{os.getcwd()}{os.sep}{FV3_NML_FN}_base"

    ensmem_num = ENSMEM_INDX

    cdate_i = int(cdate.strftime("%Y%m%d%H"))

    settings = {}
    nam_stochy_dict = {}


    seed = lambda x: cdate_i * 1000 + ensmem_num * 10 + x
    if DO_SPPT:
        nam_stochy_dict.update({"iseed_sppt": seed(1)})

    if DO_SHUM:
        nam_stochy_dict.update({"iseed_shum": seed(2)})

    if DO_SKEB:
        nam_stochy_dict.update({"iseed_skeb": seed(3)})

    settings["nam_stochy"] = nam_stochy_dict

    if DO_SPP:
        spp_seed_list = [seed(spp_seed) for spp_seed in ISEED_SPP]
        settings["nam_sppperts"] = {"iseed_spp": spp_seed_list}

    if DO_LSM_SPP:
        settings["nam_sppperts"] = {"iseed_lndp": [seed(9)]}

    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying seeds in '{FV3_NML_FP}'
            has been set as follows:

            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )

    try:
        create_config_obj(
            ["-i", FV3_NML_FP,
             "-o", fv3_nml_ensmem_fp],
            config_dict=settings,
        )
    except exceptions.UWConfigError as e:
        sys.exit(e)

def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Creates stochastic seeds for an ensemble experiment."
    )

    parser.add_argument("-c", "--cdate", dest="cdate", required=True, help="Date.")

    parser.add_argument(
        "-p",
        "--path-to-defns",
        dest="path_to_defns",
        required=True,
        help="Path to var_defns file.",
    )

    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    set_fv3nml_ens_stoch_seeds(str_to_type(args.cdate))
