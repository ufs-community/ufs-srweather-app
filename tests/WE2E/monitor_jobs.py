#!/usr/bin/env python3

import os
import sys
import glob
import argparse
import logging
import subprocess
import sqlite3
from textwrap import dedent
from datetime import datetime
from contextlib import closing
from collections import namedtuple

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

    write_monitor_file(monitor_file,expt_dict)

    # Perform initial setup for each experiment
    logging.info("Checking tests available for monitoring...")
    num_expts = 0
    print(expt_dict)
    for expt in expt_dict:
        logging.debug(f"Starting experiment {expt} running")
        num_expts += 1
        rocoto_db = f"{expt_dict[expt]['expt_dir']}/FV3LAM_wflow.db"
        subprocess.run(["rocotorun", f"-w {expt_dict[expt]['expt_dir']}/FV3LAM_wflow.xml", f"-d {rocoto_db}", "-v 10"])
        logging.debug(f"Reading database for experiment {expt}, populating experiment dictionary")
        try:
            db = sqlite_read(rocoto_db,'SELECT taskname,cycle,state from jobs')
        except:
            logging.warning(f"Unable to read database {rocoto_db}\nWill not track experiment {expt}")
            expt_dict[expt]["status"] = "ERROR"
            continue
        for task in db:
            # For each entry from rocoto database, store that under a dictionary key named TASKNAME_CYCLE
            # Cycle comes from the database in Unix Time (seconds), so convert to human-readable
            cycle = datetime.utcfromtimestamp(task[1]).strftime('%Y%m%d%H%M')
            expt_dict[expt][f"{task[0]}_{cycle}"] = task[2]
#        expt_dict[expt] = update_expt_status(expt_dict[expt]["status"])

    write_monitor_file(monitor_file,expt_dict)


    endtime = datetime.now()
    total_walltime = endtime - starttime

    logging.info(f'All {num_expts} experiments finished in {str(total_walltime)}')

    return monitor_file


def update_expt_status(expt_dict: dict) -> dict:
    """
    This function reads the dictionary showing the status of a given experiment (as read from the
    rocoto database file) and uses a simple set of rules to combine the statuses of every task into 
    a useful "status" for the whole experiment.

    Experiment "status" levels explained:
    CREATED: The experiments have been created, but the monitor script has not yet processed them.
             This is immediately overwritten at the beginning of the "monitor_jobs" function, so we
             should never see this status in this function. Including just for completeness sake.
    SUBMITTING: All jobs are in status SUBMITTING. This is a normal state; we will continue to
             monitor this experiment.
    ERROR:   One or more tasks have died (status "DEAD"), so this experiment has had an error.
             We will continue to monitor this experiment until all tasks are either status DEAD or
             status SUCCEEDED (see next entry).
    DEAD:    One or more tasks are at status DEAD, and the rest are either DEAD or SUCCEEDED. We
             will no longer monitor this experiment.
    UNKNOWN: One or more tasks are at status UNKNOWN, meaning that rocoto has failed to track the
             job associated with that task. This will require manual intervention to solve, so we
             will no longer monitor this experiment.
    RUNNING: One or more jobs are at status RUNNING, and the rest are either status QUEUED or
             SUCCEEDED. This is a normal state; we will continue to monitor this experiment.
    QUEUED:  One or more jobs are at status QUEUED, and some others may be at status SUCCEEDED.
             This is a normal state; we will continue to monitor this experiment.
    SUCCEEDED: All jobs are status SUCCEEDED; we will monitor for one more cycle in case there are
             unsubmitted jobs remaining.
    COMPLETE:All jobs are status SUCCEEDED, and we have monitored this job for an additional cycle
             to ensure there are no un-submitted jobs. We will no longer monitor this experiment.
    """

#    for task in expt_dict:
#        if expt_dict


def write_monitor_file(monitor_file: str, expt_dict: dict):
    try:
        with open(monitor_file,"w") as f:
            f.write("### WARNING ###\n")
            f.write("### THIS FILE IS AUTO_GENERATED AND REGULARLY OVER-WRITTEN BY monitor_jobs.py\n")
            f.write("### EDITS MAY RESULT IN MISBEHAVIOR OF EXPERIMENTS RUNNING\n")
            f.writelines(cfg_to_yaml_str(expt_dict))
    except:
        logging.fatal("\n********************************\n")
        logging.fatal(f"WARNING WARNING WARNING\nFailure occurred while writing monitor file {monitor_file}")
        logging.fatal("File may be corrupt or invalid for re-run!!")
        logging.fatal("\n********************************\n")
        raise

def sqlite_read(db: str, ex: str) -> list:
#    # Create Named Tuple for better data organization
#    Task = namedtuple("taskname","cycle","state")

    with closing(sqlite3.connect(db)) as connection:
        with closing(connection.cursor()) as cur:
            db = cur.execute(ex).fetchall()
    return db


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
