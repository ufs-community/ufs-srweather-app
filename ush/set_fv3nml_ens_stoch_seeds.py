#!/usr/bin/env python3

"""
Updates stochastic physics parameters in the namelist based on user configuration settings.
"""

import argparse
import datetime as dt
import os
import sys
from textwrap import dedent

from uwtools.api.config import realize

from python_utils import (
    cfg_to_yaml_str,
    import_vars,
    load_shell_config,
    print_input_args,
    print_info_msg,
)


def set_fv3nml_ens_stoch_seeds(cdate, expt_config):
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
        cdate        the cycle
        expt_config  the in-memory dict representing the experiment configuration
    Returns:
        None
    """

    print_input_args(locals())

    fv3_nml_fn = expt_config["workflow"]["FV3_NML_FN"]
    verbose = expt_config["workflow"]["VERBOSE"]

    # set variables important to this function from the experiment definition
    import_vars(dictionary=expt_config["global"])
    # pylint: disable=undefined-variable

    #
    # -----------------------------------------------------------------------
    #
    # For a given cycle and member, generate a namelist file with unique
    # seed values.
    #
    # -----------------------------------------------------------------------
    #
    fv3_nml_ensmem_fp = f"{os.getcwd()}{os.sep}{fv3_nml_fn}"

    ensmem_num = int(os.environ["ENSMEM_INDX"])

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

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying seeds in '{fv3_nml_ensmem_fp}'
            has been set as follows:

            settings =\n\n

            {cfg_to_yaml_str(settings)}"""
        ),
        verbose=verbose,
    )
    realize(
        input_config=fv3_nml_ensmem_fp,
        input_format="nml",
        output_file=fv3_nml_ensmem_fp,
        output_format="nml",
        supplemental_configs=[settings],
        )

def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Creates stochastic seeds for an ensemble experiment."
    )

    parser.add_argument(
        "-c", "--cdate",
        dest="cdate",
        required=True,
        type=lambda d: dt.datetime.strptime(d, '%Y%m%d%H'),
        help="Date.",
    )

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
    set_fv3nml_ens_stoch_seeds(args.cdate, cfg)
