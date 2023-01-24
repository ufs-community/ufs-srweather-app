#!/usr/bin/env python3

import os
import sys
import glob
import argparse
import logging
import subprocess
import sqlite3
import time
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


def monitor_jobs(expt_dict: dict, monitor_file: str = '', debug: bool = False) -> str:
    """Function to monitor and run jobs for the specified experiment using Rocoto

    Args:
        expt_dict   (dict): A dictionary containing the information needed to run
                            one or more experiments. See example file monitor_jobs.yaml
        monitor_file (str): [optional]
        debug       (bool): [optional] Enable extra output for debugging
    Returns:
        monitor_file (str): The name of the file used for job monitoring (when script
                            is finish, this contains results/summary)

    """

    starttime = datetime.now()
    # Write monitor_file, which will contain information on each monitored experiment
    if not monitor_file:
        monitor_file = f'monitor_jobs_{starttime.strftime("%Y%m%d%H%M%S")}.yaml'
        logging.info(f"Writing information for all experiments to {monitor_file}")

    write_monitor_file(monitor_file,expt_dict)

    # Perform initial setup for each experiment
    logging.info("Checking tests available for monitoring...")
    num_expts = 0
    for expt in expt_dict:
        logging.info(f"Starting experiment {expt} running")
        num_expts += 1
        rocoto_db = f"{expt_dict[expt]['expt_dir']}/FV3LAM_wflow.db"
        subprocess.run(["rocotorun", f"-w {expt_dict[expt]['expt_dir']}/FV3LAM_wflow.xml", f"-d {rocoto_db}"])
        logging.debug(f"Reading database for experiment {expt}, populating experiment dictionary")
        try:
            db = sqlite_read(rocoto_db,'SELECT taskname,cycle,state from jobs')
        except:
            logging.warning(f"Unable to read database {rocoto_db}\nWill not track experiment {expt}")
            expt_dict[expt]["status"] = "ERROR"
            num_expts -= 1
            continue
        for task in db:
            # For each entry from rocoto database, store that under a dictionary key named TASKNAME_CYCLE
            # Cycle comes from the database in Unix Time (seconds), so convert to human-readable
            cycle = datetime.utcfromtimestamp(task[1]).strftime('%Y%m%d%H%M')
            expt_dict[expt][f"{task[0]}_{cycle}"] = task[2]
        expt_dict[expt] = update_expt_status(expt_dict[expt], expt)
        #Run rocotorun again to get around rocotobqserver proliferation issue
        subprocess.run(["rocotorun", f"-w {expt_dict[expt]['expt_dir']}/FV3LAM_wflow.xml", f"-d {rocoto_db}"])

    write_monitor_file(monitor_file,expt_dict)

    logging.info(f'Setup complete; monitoring {num_expts} experiments')

    #Make a copy of experiment dictionary; will use this copy to monitor active experiments
    running_expts = expt_dict.copy()

    i = 0
    while running_expts:
        i += 1
        for expt in running_expts.copy():
            logging.debug(f"Updating status of {expt}")
            rocoto_db = f"{running_expts[expt]['expt_dir']}/FV3LAM_wflow.db"
            try:
                db = sqlite_read(rocoto_db,'SELECT taskname,cycle,state from jobs')
            except:
                logging.warning(f"Unable to read database {rocoto_db}\nWill not track experiment {expt}")
                expt_dict[expt]["status"] = "ERROR"
                continue
            # Run "rocotorun" here to give the database time to be fully written
            subprocess.run(["rocotorun", f"-w {expt_dict[expt]['expt_dir']}/FV3LAM_wflow.xml", f"-d {rocoto_db}"])
            #Run rocotorun again to get around rocotobqserver proliferation issue
            subprocess.run(["rocotorun", f"-w {expt_dict[expt]['expt_dir']}/FV3LAM_wflow.xml", f"-d {rocoto_db}"])
            for task in db:
                # For each entry from rocoto database, store that under a dictionary key named TASKNAME_CYCLE
                # Cycle comes from the database in Unix Time (seconds), so convert to human-readable
                cycle = datetime.utcfromtimestamp(task[1]).strftime('%Y%m%d%H%M')
                expt_dict[expt][f"{task[0]}_{cycle}"] = task[2]
            expt_dict[expt] = update_expt_status(expt_dict[expt], expt)
            running_expts[expt] = expt_dict[expt]
            if running_expts[expt]["status"] in ['DEAD','ERROR','COMPLETE']: 
                logging.info(f'Experiment {expt} is {running_expts[expt]["status"]}; will no longer monitor.')
                running_expts.pop(expt)
                continue
            logging.debug(f'Experiment {expt} status is {expt_dict[expt]["status"]}')


        write_monitor_file(monitor_file,expt_dict)
        endtime = datetime.now()
        total_walltime = endtime - starttime

        logging.debug(f"Finished loop {i}\nWalltime so far is {str(total_walltime)}")
        
        #Slow things down just a tad between loops so experiments behave better
        time.sleep(5)


    endtime = datetime.now()
    total_walltime = endtime - starttime

    logging.info(f'All {num_expts} experiments finished in {str(total_walltime)}')

    return monitor_file


def update_expt_status(expt: dict, name: str) -> dict:
    """
    This function reads the dictionary showing the status of a given experiment (as read from the
    rocoto database file) and uses a simple set of rules to combine the statuses of every task into 
    a useful "status" for the whole experiment.

    Experiment "status" levels explained:
    CREATED: The experiments have been created, but the monitor script has not yet processed them.
             This is immediately overwritten at the beginning of the "monitor_jobs" function, so we
             should never see this status in this function. Including just for completeness sake.
    SUBMITTING: All jobs are in status SUBMITTING or SUCCEEDED. This is a normal state; we will 
             continue to monitor this experiment.
    DYING:   One or more tasks have died (status "DEAD"), so this experiment has had an error.
             We will continue to monitor this experiment until all tasks are either status DEAD or
             status SUCCEEDED (see next entry).
    DEAD:    One or more tasks are at status DEAD, and the rest are either DEAD or SUCCEEDED. We
             will no longer monitor this experiment.
    ERROR:   One or more tasks are at status UNKNOWN, meaning that rocoto has failed to track the
             job associated with that task. This will require manual intervention to solve, so we
             will no longer monitor this experiment.
             This status may also appear if we fail to read the rocoto database file.
    RUNNING: One or more jobs are at status RUNNING, and the rest are either status QUEUED, SUBMITTED,
             or SUCCEEDED. This is a normal state; we will continue to monitor this experiment.
    QUEUED:  One or more jobs are at status QUEUED, and some others may be at status SUBMITTED or
             SUCCEEDED.
             This is a normal state; we will continue to monitor this experiment.
    SUCCEEDED: All jobs are status SUCCEEDED; we will monitor for one more cycle in case there are
             unsubmitted jobs remaining.
    COMPLETE:All jobs are status SUCCEEDED, and we have monitored this job for an additional cycle
             to ensure there are no un-submitted jobs. We will no longer monitor this experiment.
    """

    #If we are no longer tracking this experiment, return unchanged
    if expt["status"] in ['DEAD','ERROR','COMPLETE']:
        return expt
    statuses = list()
    for task in expt:
        # Skip non-task entries
        if task in ["expt_dir","status"]:
            continue
        statuses.append(expt[task])

    if "DEAD" in statuses:
        if ( "RUNNING" in statuses ) or ( "SUBMITTING" in statuses ) or ( "QUEUED" in statuses ):
            expt["status"] = "DYING"
        else:
            expt["status"] = "DEAD"
        return expt

    if "UNKNOWN" in statuses:
        expt["status"] = "ERROR" 

    if "RUNNING" in statuses:
        expt["status"] = "RUNNING"
    elif "QUEUED" in statuses:
        expt["status"] = "QUEUED"
    elif "SUBMITTING" in statuses:
        expt["status"] = "SUBMITTING"
    elif "SUCCEEDED" in statuses:
        if expt["status"] == "SUCCEEDED":
            expt["status"] = "COMPLETE"
        else:
            expt["status"] = "SUCCEEDED"
    else:
        logging.fatal("Some kind of horrible thing has happened")
        raise ValueError(dedent(f"""Some kind of horrible thing has happened to the experiment status
              for experiment {name}
              status is {expt["status"]}
              all task statuses are {statuses}"""))

    return expt


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

    parser.add_argument('-y', '--yaml_file', type=str, help='YAML-format file specifying the information of jobs to be run; for an example file, see monitor_jobs.yaml', required=True)
    parser.add_argument('-d', '--debug', action='store_true', help='Script will be run in debug mode with more verbose output')

    args = parser.parse_args()

    setup_logging(logfile,args.debug)

    expt_dict = load_config_file(args.yaml_file)

    #Call main function

    try:
        monitor_jobs(expt_dict,args.yaml_file, args.debug)
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
