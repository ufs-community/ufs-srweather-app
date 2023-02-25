#!/usr/bin/env python3
"""
A collection of utilities used by the various WE2E scripts
"""
import os
import re
import sys
import argparse
import logging
import subprocess
import sqlite3
import time
from textwrap import dedent
from datetime import datetime
from contextlib import closing
from multiprocessing import Pool

sys.path.append("../../ush")

from python_utils import (
    cfg_to_yaml_str,
    flatten_dict,
    load_config_file,
    load_shell_config
)

from check_python_version import check_python_version

REPORT_WIDTH = 100

def print_WE2E_summary(expt_dict: dict, debug: bool = False):
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
    summary.append(f'Experiment name {" "*43} | Status    | Core hours used ')
    summary.append('-'*REPORT_WIDTH)
    total_core_hours = 0
    statuses = []
    expt_details = []
    for expt in expt_dict:
        statuses.append(expt_dict[expt]["status"])
        ch = 0
        expt_details.append('')
        expt_details.append('-'*REPORT_WIDTH)
        expt_details.append(f'Detailed summary of experiment {expt}')
        expt_details.append(f'{" "*40} | Status    | Walltime   | Core hours used')
        expt_details.append('-'*REPORT_WIDTH)

        for task in expt_dict[expt]:
            # Skip non-task entries
            if task in ["expt_dir","status"]:
                continue
            status = expt_dict[expt][task]["status"]
            walltime = expt_dict[expt][task]["walltime"]
            expt_details.append(f'{task[:40]:<40s}  {status:<12s} {walltime:>10.1f}')
            if "core_hours" in expt_dict[expt][task]:
                task_ch = expt_dict[expt][task]["core_hours"]
                ch += task_ch
                expt_details[-1] = f'{expt_details[-1]}  {task_ch:>13.2f}'
            else:
                expt_details[-1] = f'{expt_details[-1]}            -'
        expt_details.append('-'*REPORT_WIDTH)
        expt_details.append(f'Total {" "*34}  {statuses[-1]:<12s} {" "*11} {ch:>13.2f}')
        summary.append(f'{expt[:60]:<60s}  {statuses[-1]:<12s}  {ch:>13.2f}')
        total_core_hours += ch
    if "ERROR" in statuses:
        total_status = "ERROR"
    elif "DEAD" in statuses:
        total_status = "DEAD"
    elif "COMPLETE" in statuses:
        total_status = "COMPLETE"
    else:
        total_status = "UNKNOWN"
    summary.append('-'*REPORT_WIDTH)
    summary.append(f'Total {" "*54}  {total_status:<12s}  {total_core_hours:>13.2f}')

    # Print summary to screen
    for line in summary:
        print(line)

    # Print summary and details to file
    summary_file = f'WE2E_summary_{datetime.now().strftime("%Y%m%d%H%M%S")}.txt'
    print(f"\nDetailed summary written to {summary_file}\n")

    with open(summary_file, 'w') as f:
        for line in summary:
            f.write(f"{line}\n")
        f.write("\nDetailed summary of each experiment:\n")
        for line in expt_details:
            f.write(f"{line}\n")

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
            taskname = re.sub('_mem\d{3}', '', taskname)
            taskname = re.sub('_f\d{3}', '', taskname)
            nnodes_var = f'NNODES_{taskname.upper()}'
            if nnodes_var in vdf:
                nnodes = vdf[nnodes_var]
                # Users are charged for full use of nodes, so core hours are CPN * nodes * time in hrs
                core_hours = cores_per_node * nnodes * expt_dict[expt][task]['walltime'] / 3600
                expt_dict[expt][task]['exact_count'] = True
            else:
                # If we can't find the number of nodes, assume full usage (may undercount)
                core_hours = expt_dict[expt][task]['cores'] * expt_dict[expt][task]['walltime'] / 3600
                expt_dict[expt][task]['exact_count'] = False
            expt_dict[expt][task]['core_hours'] = round(core_hours,2)
    return expt_dict

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
            continue
        #Update the experiment dictionary
        logging.info(f"Reading status of experiment {item}")
        update_expt_status(expt_dict[item],item,True)
    summary_file = f'WE2E_tests_{datetime.now().strftime("%Y%m%d%H%M%S")}.yaml'

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
            taskname = re.sub('_mem\d{3}', '', taskname)
            taskname = re.sub('_f\d{3}', '', taskname)
            nnodes_var = f'NNODES_{taskname.upper()}'
            if nnodes_var in vdf:
                nnodes = vdf[nnodes_var]
                # Users are charged for full use of nodes, so core hours are CPN * nodes * time in hrs
                core_hours = cores_per_node * nnodes * expt_dict[expt][task]['walltime'] / 3600
                expt_dict[expt][task]['exact_count'] = True
            else:
                # If we can't find the number of nodes, assume full usage (may undercount)
                core_hours = expt_dict[expt][task]['cores'] * expt_dict[expt][task]['walltime'] / 3600
                expt_dict[expt][task]['exact_count'] = False
            expt_dict[expt][task]['core_hours'] = round(core_hours,2)
    return expt_dict


def write_monitor_file(monitor_file: str, expt_dict: dict):
    try:
        with open(monitor_file,"w") as f:
            f.write("### WARNING ###\n")
            f.write("### THIS FILE IS AUTO_GENERATED AND REGULARLY OVER-WRITTEN BY WORKFKLOW SCRIPTS\n")
            f.write("### EDITS MAY RESULT IN MISBEHAVIOR OF EXPERIMENTS RUNNING\n")
            f.writelines(cfg_to_yaml_str(expt_dict))
    except:
        logging.fatal("\n********************************\n")
        logging.fatal(f"WARNING WARNING WARNING\nFailure occurred while writing monitor file {monitor_file}")
        logging.fatal("File may be corrupt or invalid for re-run!!")
        logging.fatal("\n********************************\n")
        raise


def update_expt_status(expt: dict, name: str, refresh: bool = False) -> dict:
    """
    This function reads the dictionary showing the location of a given experiment, runs a
    `rocotorun` command to update the experiment (running new jobs and updating the status of
    previously submitted ones), and reads the rocoto database file to update the status of
    each job for that experiment in the experiment dictionary.

    The function then and uses a simple set of rules to combine the statuses of every task
    into a useful "status" for the whole experiment, and returns the updated experiment dictionary.

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

    Args:
        expt    (dict):    A dictionary containing the information for an individual experiment, as
                           described in the main monitor_jobs() function.
        name     (str):    Name of the experiment; used for logging only
        refresh (bool):    If true, this flag will check an experiment status even if it is listed
                           as DEAD, ERROR, or COMPLETE. Used for initial checks for experiments
                           that may have been restarted.
    Returns:
        dict: The updated experiment dictionary.
    """

    #If we are no longer tracking this experiment, return unchanged
    if (expt["status"] in ['DEAD','ERROR','COMPLETE']) and not refresh:
        return expt

    # Update experiment, read rocoto database
    rocoto_db = f"{expt['expt_dir']}/FV3LAM_wflow.db"
    rocotorun_cmd = ["rocotorun", f"-w {expt['expt_dir']}/FV3LAM_wflow.xml", f"-d {rocoto_db}", "-v 10"]
    p = subprocess.run(rocotorun_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    logging.debug(p.stdout)

    logging.debug(f"Reading database for experiment {name}, updating experiment dictionary")
    try:
        # This section of code queries the "job" table of the rocoto database, returning a list
        # of tuples containing the taskname, cycle, and state of each job respectively
        with closing(sqlite3.connect(rocoto_db)) as connection:
            with closing(connection.cursor()) as cur:
                db = cur.execute('SELECT taskname,cycle,state,cores,duration from jobs').fetchall()
    except:
        logging.warning(f"Unable to read database {rocoto_db}\nCan not track experiment {name}")
        expt["status"] = "ERROR"
        return expt

    for task in db:
        # For each entry from rocoto database, store that task's info under a dictionary key named TASKNAME_CYCLE
        # Cycle comes from the database in Unix Time (seconds), so convert to human-readable
        cycle = datetime.utcfromtimestamp(task[1]).strftime('%Y%m%d%H%M')
        if f"{task[0]}_{cycle}" not in expt:
            expt[f"{task[0]}_{cycle}"] = dict()
        expt[f"{task[0]}_{cycle}"]["status"] = task[2]
        expt[f"{task[0]}_{cycle}"]["cores"] = task[3]
        expt[f"{task[0]}_{cycle}"]["walltime"] = task[4]

    #Run rocotorun again to get around rocotobqserver proliferation issue
    p = subprocess.run(rocotorun_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    logging.debug(p.stdout)

    statuses = list()
    for task in expt:
        # Skip non-task entries
        if task in ["expt_dir","status"]:
            continue
        statuses.append(expt[task]["status"])

    if "DEAD" in statuses:
        still_live = ["RUNNING", "SUBMITTING", "QUEUED"]
        if any(status in still_live for status in statuses):
            logging.debug(f'DEAD job in experiment {name}; continuing to track until all jobs are complete')
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

def update_expt_status_parallel(expt_dict: dict, procs: int) -> dict:
    """
    This function updates an entire set of experiments in parallel, drastically speeding up
    the process if given enough parallel processes. Given an experiment dictionary, it will
    output the updated dictionary.

    parallelizes the call to update_expt_status across the given number of processes.
    Making use of the python multiprocessing starmap functionality, takes

    Args:
        expt_dict (dict): A dictionary containing information for all experiments
        procs     (int): The number of parallel processes

    Returns:
        dict: The updated dictionary of experiment dictionaries
    """

    args = []
    # Define a tuple of arguments to pass to starmap
    for expt in expt_dict:
        args.append( (expt_dict[expt],expt,True) )

    # call update_expt_status() in parallel
    with Pool(processes=procs) as pool:
        output = pool.starmap(update_expt_status, args)

    # Update dictionary with output from all calls to update_expt_status()
    i = 0
    for expt in expt_dict:
         expt_dict[expt] = output[i]
         i += 1

    return expt_dict
