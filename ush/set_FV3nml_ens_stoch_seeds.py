#!/usr/bin/env python3

import os
import sys
import argparse
from textwrap import dedent
from datetime import datetime

from python_utils import (
    print_input_args,
    print_info_msg,
    print_err_msg_exit,
    date_to_str,
    mkdir_vrfy,
    cp_vrfy,
    cd_vrfy,
    str_to_type,
    import_vars,
    set_env_var,
    define_macos_utilities,
    cfg_to_yaml_str,
    load_shell_config,
    flatten_dict,
)

from set_namelist import set_namelist


def set_FV3nml_ens_stoch_seeds(cdate):
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

    #
    # -----------------------------------------------------------------------
    #
    # For a given cycle and member, generate a namelist file with unique
    # seed values.
    #
    # -----------------------------------------------------------------------
    #
    fv3_nml_ensmem_fp = f"{os.getcwd()}{os.sep}{FV3_NML_FN}"

    ensmem_num = int(ENSMEM_INDX)

    cdate_i = int(cdate.strftime("%Y%m%d%H"))

    settings = {}
    nam_stochy_dict = {}

    if DO_SPPT:
        iseed_sppt = cdate_i * 1000 + ensmem_num * 10 + 1
        nam_stochy_dict.update({"iseed_sppt": iseed_sppt})

    if DO_SHUM:
        iseed_shum = cdate_i * 1000 + ensmem_num * 10 + 2
        nam_stochy_dict.update({"iseed_shum": iseed_shum})

    if DO_SKEB:
        iseed_skeb = cdate_i * 1000 + ensmem_num * 10 + 3
        nam_stochy_dict.update({"iseed_skeb": iseed_skeb})

    settings["nam_stochy"] = nam_stochy_dict

    if DO_SPP:
        num_iseed_spp = len(ISEED_SPP)
        iseed_spp = [None] * num_iseed_spp
        for i in range(num_iseed_spp):
            iseed_spp[i] = cdate_i * 1000 + ensmem_num * 10 + ISEED_SPP[i]

        settings["nam_sppperts"] = {"iseed_spp": iseed_spp}
    else:
        settings["nam_sppperts"] = {}

    if DO_LSM_SPP:
        iseed_lsm_spp = cdate_i * 1000 + ensmem_num * 10 + 9

        settings["nam_sfcperts"] = {"iseed_lndp": [iseed_lsm_spp]}

    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying seeds in '{fv3_nml_ensmem_fp}'
            has been set as follows:

            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )

    try:
        set_namelist(
            ["-q", "-n", fv3_nml_ensmem_fp, "-u", settings_str, "-o", fv3_nml_ensmem_fp]
        )
    except:
        print_err_msg_exit(
            dedent(
                f"""
                Call to python script set_namelist.py to set the variables in the FV3
                namelist file that specify the paths to the surface climatology files
                failed.  Parameters passed to this script are:
                  Full path to base namelist file:
                    FV3_NML_FP = '{FV3_NML_FP}'
                  Full path to output namelist file:
                    fv3_nml_ensmem_fp = '{fv3_nml_ensmem_fp}'
                  Namelist settings specified on command line (these have highest precedence):\n
                    settings =\n\n"""
            )
            + settings_str
        )


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
    set_FV3nml_ens_stoch_seeds(str_to_type(args.cdate))
