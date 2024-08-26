#!/usr/bin/env python3
"""
Function that creates the config file for running AQM.
"""

import argparse
import os
import sys
from textwrap import dedent
from uwtools.api.template import render

from python_utils import (
    cfg_to_yaml_str,
    flatten_dict,
    import_vars,
    load_yaml_config,
    print_info_msg,
    print_input_args,
    str_to_type,
)

def create_aqm_rc_file(cdate, run_dir, init_concentrations):
    """ Creates an aqm.rc file in the specified run directory

    Args:
        cdate: cycle date
        run_dir: run directory
        init_concentrations
    Returns:
        Boolean
    """

    print_input_args(locals())

    #import all environment variables
    import_vars()
    #pylint: disable=undefined-variable

    #
    #-----------------------------------------------------------------------
    #
    # Create the aqm.rc file in the specified run directory.
    #
    #-----------------------------------------------------------------------
    #
    print_info_msg(f'''
        Creating the aqm.rc file (\"{AQM_RC_FN}\") in the specified
        run directory (run_dir):
          run_dir = \"{run_dir}\"''', verbose=VERBOSE)
    #
    # Set output file path
    #
    aqm_rc_fp=os.path.join(run_dir, AQM_RC_FN)
    #
    # Extract from cdate the starting year, month, and day of the forecast.
    #
    yyyymmdd=cdate.strftime('%Y%m%d')
    mm=f"{cdate.month:02d}" # pylint: disable=invalid-name
    hh=f"{cdate.hour:02d}" # pylint: disable=invalid-name
    #
    # Set parameters in the aqm.rc file.
    #
    aqm_rc_bio_file_fp=os.path.join(FIXaqm,"bio", AQM_BIO_FILE)

    # Fire config
    aqm_rc_fire_file_fp=os.path.join(
        COMIN,
        f"{AQM_FIRE_FILE_PREFIX}_{yyyymmdd}_t{hh}z{AQM_FIRE_FILE_SUFFIX}"
        )

    # Dust config
    aqm_rc_dust_file_fp=os.path.join(
            FIXaqm,"dust",
            f"{AQM_DUST_FILE_PREFIX}_{PREDEF_GRID_NAME}{AQM_DUST_FILE_SUFFIX}",
            )

    # Canopy config
    aqm_rc_canopy_file_fp=os.path.join(
        FIXaqm,"canopy",PREDEF_GRID_NAME,
        f"{AQM_CANOPY_FILE_PREFIX}.{mm}{AQM_CANOPY_FILE_SUFFIX}",
        )
    #
    #-----------------------------------------------------------------------
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the jinja variables in the template
    # AQM_RC_TMPL_FN file should be set to.
    #
    #-----------------------------------------------------------------------
    #
    settings = {
        "do_aqm_dust": DO_AQM_DUST,
        "do_aqm_canopy": DO_AQM_CANOPY,
        "do_aqm_product": DO_AQM_PRODUCT,
        "ccpp_phys_suite": CCPP_PHYS_SUITE,
        "init_concentrations": init_concentrations,
        "aqm_rc_bio_file_fp": aqm_rc_bio_file_fp,
        "fixaqm": FIXaqm,
        "aqm_rc_fire_file_fp": aqm_rc_fire_file_fp,
        "aqm_rc_fire_frequency": AQM_RC_FIRE_FREQUENCY,
        "aqm_rc_dust_file_fp": aqm_rc_dust_file_fp,
        "aqm_rc_canopy_file_fp": aqm_rc_canopy_file_fp,
        "aqm_rc_product_fn": AQM_RC_PRODUCT_FN,
        "aqm_rc_product_frequency": AQM_RC_PRODUCT_FREQUENCY
    }
    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable \"settings\" specifying values to be used in the \"{AQM_RC_FN}\"
            file has been set as follows:\n
            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )
    #
    #-----------------------------------------------------------------------
    #
    # Call a python script to generate the experiment's actual AQM_RC_FN
    # file from the template file.
    #
    #-----------------------------------------------------------------------
    #
    render(
        input_file = AQM_RC_TMPL_FP,
        output_file = aqm_rc_fp,
        values_src = settings,
    )
    return True

def parse_args(argv):
    """ Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Creates aqm.rc file.")

    parser.add_argument("-r", "--run-dir",
                        dest="run_dir",
                        required=True,
                        help="Run directory.")

    parser.add_argument("-c", "--cdate",
                        dest="cdate",
                        required=True,
                        help="Date string in YYYYMMDD format.")

    parser.add_argument("-i", "--init_concentrations",
                        dest="init_concentrations",
                        required=True,
                        help="Flag for initial concentrations.")

    parser.add_argument("-p", "--path-to-defns",
                        dest="path_to_defns",
                        required=True,
                        help="Path to var_defns file.")

    return parser.parse_args(argv)

if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    cfg = load_yaml_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    create_aqm_rc_file(
        run_dir=args.run_dir,
        cdate=str_to_type(args.cdate),
        init_concentrations=str_to_type(args.init_concentrations),
    )
