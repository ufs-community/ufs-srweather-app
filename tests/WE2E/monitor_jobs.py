#!/usr/bin/env python3

import os
import sys
import glob
import argparse
import logging
import subprocess
from textwrap import dedent
from datetime import datetime

sys.path.append("../../ush")

from generate_FV3LAM_wflow import generate_FV3LAM_wflow
from python_utils import (
    print_err_msg_exit,
    run_command,
    date_to_str,
    define_macos_utilities,
    create_symlink_to_file,
    check_for_preexist_dir_file,
    cfg_to_yaml_str,
    find_pattern_in_str,
    set_env_var,
    get_env_var,
    lowercase,
    load_config_file,
    cfg_to_yaml_str
)

from check_python_version import check_python_version


def monitor_jobs(expt_dict: dict, debug: bool) -> str:
    """Function to monitor and run jobs for the specified experiment using Rocoto

    Args:
        expt_dict (dict): A dictionary containing the information needed to run
                          one or more experiments. See example file monitor_jobs.yaml
        debug     (bool): Enable extra output for debugging
    Returns:
        monitor_file (str): The name of the file used for job monitoring (when script
                            is finish, this contains results/summary)

    """

    # Write monitor_file, which will contain information on each monitored experiment
    starttime = datetime.now()
    monitor_file = f'monitor_jobs_{starttime.strftime("%Y%m%d%H%M%S")}.yaml'
    logging.info(f"Writing information for all experiments to {monitor_file}")
    with open(monitor_file,"w") as f:
        f.write("### WARNING ###\n")
        f.write("### THIS FILE IS AUTO_GENERATED AND REGULARLY OVER-WRITTEN BY monitor_jobs.py\n")
        f.write("### EDITS MAY RESULT IN MISBEHAVIOR OF EXPERIMENTS RUNNING\n")
        f.writelines(cfg_to_yaml_str(expt_dict))

    # Perform initial setup for each experiment
    logging.info("Checking tests available for monitoring...")
    num_expts = 0
    print(expt_dict)
    for expt in expt_dict:
        logging.info(f"Starting experiment {expt} running")
        num_expts += 1
        subprocess.run(["rocotorun", f"-w {expt_dict[expt]['expt_dir']}/FV3LAM_wflow.xml", f"-d {expt_dict[expt]['expt_dir']}/FV3LAM_wflow.db", "-v 10"])

    endtime = datetime.now()
    total_walltime = endtime - starttime

    logging.info(f'All {num_expts} experiments finished in {str(total_walltime)}')

    return monitor_file

def setup_logging(logfile: str = "log.run_WE2E_tests", debug: bool = False) -> None:
    """
    Sets up logging, printing high-priority (INFO and higher) messages to screen, and printing all
    messages with detailed timing and routine info in the specified text file.
    """
    logging.getLogger().setLevel(logging.DEBUG)

    formatter = logging.Formatter("%(name)-16s %(levelname)-8s %(message)s")

    fh = logging.FileHandler(logfile, mode='w')
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(formatter)
    logging.getLogger().addHandler(fh)

    logging.debug(f"Finished setting up debug file logging in {logfile}")
    console = logging.StreamHandler()
    if debug:
       console.setLevel(logging.DEBUG)
    else:
       console.setLevel(logging.INFO)
    logging.getLogger().addHandler(console)
    logging.debug("Logging set up successfully")


if __name__ == "__main__":

    check_python_version()

    logfile='log.monitor_jobs'

    #Parse arguments
    parser = argparse.ArgumentParser(description="Script for monitoring and running jobs in a specified experiment, as specified in a yaml configuration file\n")

    parser.add_argument('yaml_file', type=str, help='YAML-format file specifying the information of jobs to be run; for an example file, see monitor_jobs.yaml', required=True)
    parser.add_argument('-d', '--debug', action='store_true', help='Script will be run in debug mode with more verbose output')

    args = parser.parse_args()

    setup_logging(logfile,args.debug)

    #NEED TO ADD LOGIC TO READ INPUT FILE HEREu

    #Call main function

    try:
        monitor_jobs(expt_dict, yaml_file, args.debug)
    except:
        logging.exception(
            dedent(
                f"""
                *********************************************************************
                FATAL ERROR:
                An error occurred. See the error message(s) printed below.
                For more detailed information, check the log file from the workflow
                generation script: {logfile}
                *********************************************************************\n
                """
            )
        )
