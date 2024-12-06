#!/usr/bin/env python3

"""
Creates a UFS configuration file for the FV3 forecast model(s) from a template.
"""

import argparse
import os
import sys
from textwrap import dedent
from uwtools.api.template import render

from python_utils import (
    flatten_dict,
    load_yaml_config,
    print_info_msg,
)

def create_ufs_configure_file(run_dir,cfg):
    """ Creates a UFS configuration file in the specified run directory

    Args:
        run_dir: run directory
        cfg: dictionary of config settings
    Returns:
        True
    """

    # pylint: disable=undefined-variable

    # Set necessary variables for each coupled configuration

    atm_end = str(int(cfg["PE_MEMBER01"]) - int(cfg["FIRE_NUM_TASKS"]) -1)
    aqm_end = str(int(cfg["LAYOUT_X"]) * int(cfg["LAYOUT_Y"]) - 1)
    fire_start = str(int(cfg["PE_MEMBER01"]) - int(cfg["FIRE_NUM_TASKS"]))
    fire_end = str(int(cfg["PE_MEMBER01"]) - 1)

    atm_petlist_bounds = f'0 {atm_end}'
    if cfg["CPL_AQM"]:
        earth_component_list = 'ATM AQM'
        aqm_petlist_bounds = f'0 {aqm_end}'
        atm_omp_num_threads_line = ''
        atm_diag_line = ''
        runseq = [ f"  @{cfg['DT_ATMOS']}\n",
                   "    ATM phase1\n",
                   "    ATM -> AQM\n",
                   "    AQM\n",
                   "    AQM -> ATM\n",
                   "    ATM phase2\n",
                   "  @" ]
    elif cfg["UFS_FIRE"]:
        earth_component_list = 'ATM FIRE'
        atm_omp_num_threads_line = \
            f"\nATM_omp_num_threads:            {cfg['OMP_NUM_THREADS_RUN_FCST']}"
        atm_diag_line = ''
        fire_petlist_bounds = f'{fire_start} {fire_end}'
        runseq = [ f"  @{cfg['DT_ATMOS']}\n",
                   "    ATM -> FIRE\n",
                   "    FIRE -> ATM :remapmethod=conserve\n",
                   "    ATM\n",
                   "    FIRE\n",
                   "  @" ]
    else:
        earth_component_list = 'ATM'
        atm_omp_num_threads_line = \
            f"\nATM_omp_num_threads:            {cfg['OMP_NUM_THREADS_RUN_FCST']}"
        atm_diag_line = '  Diagnostic = 0'
        runseq = [ "  ATM" ]

    if cfg["PRINT_ESMF"]:
        logkindflag = 'ESMF_LOGKIND_MULTI'
    else:
        logkindflag = 'ESMF_LOGKIND_MULTI_ON_ERROR'
    #
    #-----------------------------------------------------------------------
    #
    # Create a UFS configuration file in the specified run directory.
    #
    #-----------------------------------------------------------------------
    #
    print_info_msg(f'''
        Creating a ufs.configure file (\"{cfg["UFS_CONFIG_FN"]}\") in the specified
        run directory (run_dir):
          {run_dir=}''', verbose=cfg["VERBOSE"])
    #
    # Set output file path
    #
    ufs_config_fp = os.path.join(run_dir, cfg["UFS_CONFIG_FN"])
    #
    #-----------------------------------------------------------------------
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the jinja variables in the template
    # model_configure file should be set to.
    #
    #-----------------------------------------------------------------------
    #
    settings = {
      "ufs_fire": cfg["UFS_FIRE"],
      "logKindFlag": logkindflag,
      "EARTH_cl": earth_component_list,
      "ATM_pb": atm_petlist_bounds,
      "ATM_omp_num_threads_line": atm_omp_num_threads_line,
      "ATM_diag_line": atm_diag_line,
      "runseq": runseq,
      "AQM_pb": "",
      "FIRE_pb": "",
      "dt_atmos": cfg["DT_ATMOS"],
      "print_esmf": cfg["PRINT_ESMF"],
      "cpl_aqm": cfg["CPL_AQM"]
    }
    if cfg["CPL_AQM"]:
        settings["AQM_pb"] = aqm_petlist_bounds
    if cfg["UFS_FIRE"]:
        settings["FIRE_pb"] = fire_petlist_bounds

    print_info_msg(
        dedent(
            f"""
            The variable \"settings\" specifying values to be used in the \"{cfg["UFS_CONFIG_FN"]}\"
            file has been set as follows:\n
            {settings=}\n\n"""
        ), verbose=cfg["VERBOSE"]
    )
    #
    #-----------------------------------------------------------------------
    #
    # Call the uwtools "render" function to fill in jinja expressions contained in the UFS Configure
    # file template with the values from the settings variable to create ufs.configure file for this
    # experiment
    #
    #-----------------------------------------------------------------------
    #
    render(
        input_file = cfg["UFS_CONFIG_TMPL_FP"],
        output_file = ufs_config_fp,
        values_src = settings,
        )
    return True

def _parse_args(argv):
    """ Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Creates UFS configuration file.'
    )

    parser.add_argument("-r", "--run-dir",
                        dest="run_dir",
                        required=True,
                        help="Run directory.")

    parser.add_argument("-p", "--path-to-defns",
                        dest="path_to_defns",
                        required=True,
                        help="Path to var_defns file.")

    return parser.parse_args(argv)

if __name__ == "__main__":
    args = _parse_args(sys.argv[1:])
    conf = load_yaml_config(args.path_to_defns)
    confg = flatten_dict(conf)
    create_ufs_configure_file(run_dir=args.run_dir,cfg=confg)
