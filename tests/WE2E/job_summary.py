#!/usr/bin/env python3

import os
import sys
import argparse
import logging
import subprocess
import sqlite3
import time
from textwrap import dedent
from datetime import datetime
from contextlib import closing

sys.path.append("../../ush")

from python_utils import (
    load_config_file,
    cfg_to_yaml_str
)

from check_python_version import check_python_version

from monitor_jobs import update_expt_status

def print_job_summary(expt_dict: dict, debug: bool = False):
    """Function that creates a summary for the specified experiment

    Args:
        expt_dict   (dict): A dictionary containing the information needed to run
                            one or more experiments. See example file monitor_jobs.yaml
        debug       (bool): [optional] Enable extra output for debugging
    Returns:
        None
    """

    # Perform initial setup for each experiment
    for expt in expt_dict:
        print("\n======================================")
        print(f'Checking workflow status of experiment "{expt}" ...')
        update_expt_status(expt_dict[expt],expt)
        print(f"Workflow status:  {expt_dict[expt]['status']}")
        print("======================================")

def create_expt_dict(expt_dir: str) -> dict:
    """
    Function takes in a directory, searches that directory for subdirectories containing
    experiments, and creates a skeleton dictionary that can be filled out by update_expt_status()

    Args:
        expt_dir   (str) : Experiment directory
    Returns:
        dict : Experiment dictionary
    """
    contents = os.listdir(expt_dir)

    expt_dict=dict()
    for item in contents:
        # Look for FV3LAM_wflow.xml to indicate directories with experiments in them
        if os.path.isfile(os.path.join(expt_dir, item, 'FV3LAM_wflow.xml')):
            expt_dict[item] = dict()
            expt_dict[item].update({"expt_dir": os.path.join(expt_dir,item)})
            expt_dict[item].update({"status": "CREATED"})

    return expt_dict


def setup_logging(debug: bool = False) -> None:
    """
    Sets up logging, printing high-priority (INFO and higher) messages to screen, and printing all
    messages with detailed timing and routine info in the specified text file.
    """
    logging.getLogger().setLevel(logging.DEBUG)

    console = logging.StreamHandler()
    if debug:
        console.setLevel(logging.DEBUG)
    else:
        console.setLevel(logging.INFO)
    logging.getLogger().addHandler(console)
    logging.debug("Logging set up successfully")


if __name__ == "__main__":

    check_python_version()

    #Parse arguments
    parser = argparse.ArgumentParser(description="Script for creating a job summary printed to screen and a file, either from a yaml experiment file created by monitor_jobs() or from a provided directory of experiments\n")

    req = parser.add_mutually_exclusive_group(required=True)
    req.add_argument('-y', '--yaml_file', type=str, help='YAML-format file specifying the information of jobs to be summarized; for an example file, see monitor_jobs.yaml')
    req.add_argument('-e', '--expt_dir', type=str, help='The full path of an experiment directory, containing one or more subdirectories with UFS SRW App experiments in them')
    parser.add_argument('-d', '--debug', action='store_true', help='Script will be run in debug mode with more verbose output')

    args = parser.parse_args()

    setup_logging(args.debug)

    # Set up dictionary of experiments
    if args.expt_dir:
        expt_dict = create_expt_dict(args.expt_dir)
    elif args.yaml_file:
        expt_dict = load_config_file(args.yaml_file)
    else:
        raise ValueError(f'Bad arguments; run {__file__} -h for more information')

    #Call main function
    print_job_summary(expt_dict, args.debug)

