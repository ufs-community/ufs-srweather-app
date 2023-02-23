#!/usr/bin/env python3

import os
import sys
import argparse
import logging
import re
import subprocess
import sqlite3
import time
from textwrap import dedent
from datetime import datetime
from contextlib import closing

sys.path.append("../../ush")

from python_utils import (
    cfg_to_yaml_str,
    flatten_dict,
    load_config_file,
    load_shell_config
)

from check_python_version import check_python_version

from monitor_jobs import update_expt_status, write_monitor_file

REPORT_WIDTH = 110

def print_job_summary(expt_dict: dict, debug: bool = False):
    """Function that creates a summary for the specified experiment

    Args:
        expt_dict   (dict): A dictionary containing the information needed to run
                            one or more experiments. See example file monitor_jobs.yaml
        debug       (bool): [optional] Enable extra output for debugging
    Returns:
        None
    """

    # Create summary table as list of strings
    summary = []
    summary.append('-'*REPORT_WIDTH)
    summary.append(f'Experiment name {" "*44} | Status    | Core hours used ')
    # Flag for tracking if "cores per node" is in dictionary
    summary.append('-'*REPORT_WIDTH)
    for expt in expt_dict:
        status = expt_dict[expt]["status"]
        ch = 0
        for task in expt_dict[expt]:
            if "core_hours" in expt_dict[expt][task]:
                ch += expt_dict[expt][task]["core_hours"]
        summary.append(f'{expt[:60]:<60s} {status:^12s} {ch:^12.2f}')

    # Print summary to screen
    for line in summary:
        print(line)


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
        fullpath = os.path.join(expt_dir, item)
        if not os.path.isdir(fullpath):
            continue
        xmlfile = os.path.join(expt_dir, item, 'FV3LAM_wflow.xml')
        if os.path.isfile(xmlfile):
            expt_dict[item] = dict()
            expt_dict[item].update({"expt_dir": os.path.join(expt_dir,item)})
            expt_dict[item].update({"status": "CREATED"})
        else:
            logging.debug(f'Skipping directory {item}, experiment XML file not found')
        #Update the experiment dictionary
        logging.info(f"Reading status of experiment {item}")
        update_expt_status(expt_dict[item],item,True)
    summary_file = f'job_summary_{datetime.now().strftime("%Y%m%d%H%M%S")}.yaml'

    return summary_file, expt_dict

def calculate_core_hours(expt_dict: dict) -> dict:
    """
    Function takes in an experiment dictionary, reads the var_defns file for necessary information,
    and calculates the core hours used by each task, updating expt_dict with this info

    Args:
        expt_dict (dict) : Experiment dictionary
    Returns:
        dict : Experiment dictionary updated with core hours
    """

    for expt in expt_dict:
        # Read variable definitions file
        vardefs = load_shell_config(os.path.join(expt_dict[expt]["expt_dir"],"var_defns.sh"))
        vdf = flatten_dict(vardefs)
        cores_per_node = vdf["NCORES_PER_NODE"]
        for task in expt_dict[expt]:
            # Skip non-task entries
            if task in ["expt_dir","status"]:
                continue
            # Cycle is last 12 characters, task name is rest (minus separating underscore)
            taskname = task[:-13]
            # Handle task names that have ensemble and/or fhr info appended with regex
            print(taskname)
            taskname = re.sub('_mem\d{3}', '', taskname)
            taskname = re.sub('_f\d{3}', '', taskname)
            print(taskname)
            nnodes = vdf[f'NNODES_{taskname.upper()}']
            # Users are charged for full use of nodes, so core hours are CPN * nodes * time in hrs
            core_hours = cores_per_node * nnodes * expt_dict[expt][task]['walltime'] / 3600
            expt_dict[expt][task]['core_hours'] = round(core_hours,2)
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

    yaml_file = args.yaml_file

    # Set up dictionary of experiments
    if args.expt_dir:
        yaml_file, expt_dict = create_expt_dict(args.expt_dir)
    elif args.yaml_file:
        expt_dict = load_config_file(args.yaml_file)
    else:
        raise ValueError(f'Bad arguments; run {__file__} -h for more information')

    # Calculate core hours and update yaml
    expt_dict = calculate_core_hours(expt_dict)
    write_monitor_file(yaml_file,expt_dict)

    #Call function to print summary
    print_job_summary(expt_dict, args.debug)

