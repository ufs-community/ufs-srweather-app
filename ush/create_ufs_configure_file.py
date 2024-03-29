#!/usr/bin/env python3

"""
Function to create a UFS configuration file for the FV3 forecast
model(s) from a template.
"""

import argparse
import os
import sys
import tempfile
from subprocess import STDOUT, CalledProcessError, check_output
from textwrap import dedent

from python_utils import (
    cfg_to_yaml_str,
    flatten_dict,
    import_vars,
    load_shell_config,
    print_info_msg,
    print_input_args,
)

def create_ufs_configure_file(run_dir,cfg):
    """ Creates a ufs configuration file in the specified
    run directory

    Args:
        run_dir: run directory
        cfg: dictionary of config settings
    Returns:
        Boolean
    """

    # pylint: disable=undefined-variable

    # Set necessary variables for each coupled configuration

    atm_end = str(int(cfg["PE_MEMBER01"]) - int(cfg["FIRE_NUM_TASKS"]) -1)
    fire_start = str(int(cfg["PE_MEMBER01"]) - int(cfg["FIRE_NUM_TASKS"]))
    fire_end = str(int(cfg["PE_MEMBER01"]) - 1)

    if cfg["CPL_AQM"]:
        EARTH_component_list = 'ATM AQM'
        ATM_petlist_bounds = '-1 -1'
        ATM_omp_num_threads_line = ''
        ATM_diag_line = ''
        runseq = [ f"  @{cfg['DT_ATMOS']}\n",
                   "    ATM phase1\n",
                   "    ATM -> AQM\n",
                   "    AQM\n",
                   "    AQM -> ATM\n",
                   "    ATM phase2\n",
                   "  @" ]
    elif cfg["UFS_FIRE"]:
        EARTH_component_list = 'ATM FIRE'
        ATM_petlist_bounds = f'0 {atm_end}'
        ATM_omp_num_threads_line = ''
        ATM_diag_line = ''
        FIRE_petlist_bounds = f'{fire_start} {fire_end}'
        runseq = [ f"  @{cfg['DT_ATMOS']}\n",
                   "    ATM -> FIRE\n",
                   "    FIRE -> ATM :remapmethod=conserve\n",
                   "    ATM\n",
                   "    FIRE\n",
                   "  @" ]
    else:
        EARTH_component_list = 'ATM'
        ATM_petlist_bounds = f'0 {atm_end}'
        ATM_omp_num_threads_line = \
            f"\nATM_omp_num_threads:            {cfg['OMP_NUM_THREADS_RUN_FCST']}"
        ATM_diag_line = '  Diagnostic = 0'
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
      "cpl_aqm": cfg["CPL_AQM"],
      "ufs_fire": cfg["UFS_FIRE"],
      "logKindFlag": logkindflag,
      "EARTH_cl": EARTH_component_list,
      "ATM_pb": ATM_petlist_bounds,
      "ATM_omp_num_threads_line": ATM_omp_num_threads_line,
      "ATM_diag_line": ATM_diag_line,
      "runseq": runseq,
      "FIRE_pb": ""
      "dt_atmos": DT_ATMOS,
      "print_esmf": PRINT_ESMF,
      "cpl_aqm": CPL_AQM
    }
    if cfg["UFS_FIRE"]:
        settings["FIRE_pb"] = FIRE_petlist_bounds

    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable \"settings\" specifying values to be used in the \"{cfg["UFS_CONFIG_FN"]}\"
            file has been set as follows:\n
            settings =\n\n"""
        )
        + settings_str,
        verbose=cfg["VERBOSE"],
    )
    #
    #-----------------------------------------------------------------------
    #
    # Call set_template function from workflow_tools to fill in jinja template
    # to create ufs.configure file for this experiment
    #
    #-----------------------------------------------------------------------

    # Store the settings in a temporary file; hopefully soon workflow tools will be able
    # to accept a dictionary as an argument directly
    with tempfile.NamedTemporaryFile(dir="./",
                                     mode="w+t",
                                     prefix="ufs_config_settings",
                                     suffix=".yaml") as tmpfile:
        tmpfile.write(settings_str)
        tmpfile.seek(0)

        cmd = " ".join(["uw template render",
            "-i", cfg["UFS_CONFIG_TMPL_FP"],
            "-o", ufs_config_fp,
            "-v",
            "--values-file", tmpfile.name,
            ]
        )

        indent = "  "
        output = ""
        try:
            output = check_output(cmd, encoding="utf=8", shell=True,
                    stderr=STDOUT, text=True)
        except CalledProcessError as e:
            output = e.output
            print(f"Failed with status: {e.returncode}")
            sys.exit(1)
        finally:
            print("Output:")
            for line in output.split("\n"):
                print(f"{indent * 2}{line}")
    return True

def parse_args(argv):
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
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    create_ufs_configure_file(run_dir=args.run_dir,cfg=cfg)
