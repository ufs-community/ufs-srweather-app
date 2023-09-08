#!/usr/bin/env python3
"""
A collection of utilities used by the various WE2E scripts
"""
import os
import re
import sys
import logging
import subprocess
import sqlite3
import glob
from textwrap import dedent
from datetime import datetime
from contextlib import closing
from multiprocessing import Pool

sys.path.append("../../ush")

from calculate_cost import calculate_cost
from python_utils import (
    cfg_to_yaml_str,
    flatten_dict,
    load_config_file,
    load_shell_config
)

REPORT_WIDTH = 100
EXPT_COLUMN_WIDTH = 65
TASK_COLUMN_WIDTH = 40
def print_WE2E_summary(expts_dict: dict, debug: bool = False):
    """Function that creates a summary for the specified experiment

    Args:
        expts_dict (dict): A dictionary containing the information needed to run
                           one or more experiments. See example file WE2E_tests.yaml
        debug      (bool): [optional] Enable extra output for debugging

    Returns:
        None
    """

    # Create summary table as list of strings
    summary = []
    summary.append('-'*REPORT_WIDTH)
    summary.append(f'Experiment name {" "*(EXPT_COLUMN_WIDTH-17)} | Status    | Core hours used ')
    summary.append('-'*REPORT_WIDTH)
    total_core_hours = 0
    statuses = []
    expt_details = []
    for expt in expts_dict:
        statuses.append(expts_dict[expt]["status"])
        ch = 0
        expt_details.append('')
        expt_details.append('-'*REPORT_WIDTH)
        expt_details.append(f'Detailed summary of experiment {expt}')
        expt_details.append(f"in directory {expts_dict[expt]['expt_dir']}")
        expt_details.append(f'{" "*TASK_COLUMN_WIDTH}| Status    | Walltime   | Core hours used')
        expt_details.append('-'*REPORT_WIDTH)

        for task in expts_dict[expt]:
            # Skip non-task entries
            if task in ["expt_dir","status","start_time","walltime"]:
                continue
            status = expts_dict[expt][task]["status"]
            walltime = expts_dict[expt][task]["walltime"]
            expt_details.append(f'{task[:TASK_COLUMN_WIDTH]:<{TASK_COLUMN_WIDTH}s}  {status:<12s} {walltime:>10.1f}')
            if "core_hours" in expts_dict[expt][task]:
                task_ch = expts_dict[expt][task]["core_hours"]
                ch += task_ch
                expt_details[-1] = f'{expt_details[-1]}  {task_ch:>13.2f}'
            else:
                expt_details[-1] = f'{expt_details[-1]}            -'
        expt_details.append('-'*REPORT_WIDTH)
        expt_details.append(f'Total {" "*(TASK_COLUMN_WIDTH - 6)}  {statuses[-1]:<12s} {" "*11} {ch:>13.2f}')
        summary.append(f'{expt[:EXPT_COLUMN_WIDTH]:<{EXPT_COLUMN_WIDTH}s}  {statuses[-1]:<12s}  {ch:>13.2f}')
        total_core_hours += ch
    if "ERROR" in statuses:
        total_status = "ERROR"
    elif "RUNNING" in statuses:
        total_status = "RUNNING"
    elif "QUEUED" in statuses:
        total_status = "QUEUED"
    elif "DEAD" in statuses:
        total_status = "DEAD"
    elif "COMPLETE" in statuses:
        total_status = "COMPLETE"
    else:
        total_status = "UNKNOWN"
    summary.append('-'*REPORT_WIDTH)
    summary.append(f'Total {" "*(EXPT_COLUMN_WIDTH - 6)}  {total_status:<12s}  {total_core_hours:>13.2f}')

    # Print summary to screen
    for line in summary:
        print(line)

    # Print summary and details to file
    summary_file = os.path.join(os.path.dirname(expts_dict[expt]["expt_dir"]),
                                f'WE2E_summary_{datetime.now().strftime("%Y%m%d%H%M%S")}.txt')
    print(f"\nDetailed summary written to {summary_file}\n")

    with open(summary_file, 'w', encoding="utf-8") as f:
        for line in summary:
            f.write(f"{line}\n")
        f.write("\nDetailed summary of each experiment:\n")
        for line in expt_details:
            f.write(f"{line}\n")

def create_expts_dict(expt_dir: str) -> dict:
    """
    Function takes in a directory, searches that directory for subdirectories containing
    experiments, and creates a skeleton dictionary that can be filled out by update_expt_status()

    Args:
        expt_dir (str): Experiment directory

    Returns:
        dict: Experiment dictionary
    """
    contents = sorted(os.listdir(expt_dir))

    expts_dict=dict()
    for item in contents:
        # Look for FV3LAM_wflow.xml to indicate directories with experiments in them
        fullpath = os.path.join(expt_dir, item)
        if not os.path.isdir(fullpath):
            continue
        xmlfile = os.path.join(expt_dir, item, 'FV3LAM_wflow.xml')
        if os.path.isfile(xmlfile):
            expts_dict[item] = dict()
            expts_dict[item].update({"expt_dir": os.path.join(expt_dir,item)})
            expts_dict[item].update({"status": "CREATED"})
        else:
            logging.debug(f'Skipping directory {item}, experiment XML file not found')
            continue
        #Update the experiment dictionary
        logging.debug(f"Reading status of experiment {item}")
        update_expt_status(expts_dict[item],item,True,False,False)
    summary_file = f'WE2E_tests_{datetime.now().strftime("%Y%m%d%H%M%S")}.yaml'

    return summary_file, expts_dict

def calculate_core_hours(expts_dict: dict) -> dict:
    """
    Function takes in an experiment dictionary, reads the var_defns file for necessary information,
    and calculates the core hours used by each task, updating expts_dict with this info

    Args:
        expts_dict (dict): A dictionary containing the information needed to run
                           one or more experiments. See example file WE2E_tests.yaml

    Returns:
        dict: Experiments dictionary updated with core hours
    """

    for expt in expts_dict:
        # Read variable definitions file
        vardefs_file = os.path.join(expts_dict[expt]["expt_dir"],"var_defns.sh")
        if not os.path.isfile(vardefs_file):
            logging.warning(f"\nWARNING: For experiment {expt}, variable definitions file")
            logging.warning(f"{vardefs_file}\ndoes not exist!\n\nDropping experiment from summary")
            continue
        logging.debug(f'Reading variable definitions file {vardefs_file}')
        vardefs = load_shell_config(vardefs_file)
        vdf = flatten_dict(vardefs)
        cores_per_node = vdf["NCORES_PER_NODE"]
        for task in expts_dict[expt]:
            # Skip non-task entries
            if task in ["expt_dir","status","start_time","walltime"]:
                continue
            # Cycle is last 12 characters, task name is rest (minus separating underscore)
            taskname = task[:-13]
            # Handle task names that have ensemble and/or fhr info appended with regex
            taskname = re.sub('_mem\d{3}', '', taskname)
            taskname = re.sub('_f\d{3}', '', taskname)
            nnodes_var = f'NNODES_{taskname.upper()}'
            if nnodes_var in vdf:
                nnodes = vdf[nnodes_var]
                # Users are charged for full use of nodes, so core hours = CPN * nodes * time in hrs
                core_hours = cores_per_node * nnodes * expts_dict[expt][task]['walltime'] / 3600
                expts_dict[expt][task]['exact_count'] = True
            else:
                # If we can't find the number of nodes, assume full usage (may undercount)
                core_hours = expts_dict[expt][task]['cores'] * \
                             expts_dict[expt][task]['walltime'] / 3600
                expts_dict[expt][task]['exact_count'] = False
            expts_dict[expt][task]['core_hours'] = round(core_hours,2)
    return expts_dict


def write_monitor_file(monitor_file: str, expts_dict: dict):
    try:
        with open(monitor_file,"w", encoding="utf-8") as f:
            f.write("### WARNING ###\n")
            f.write("### THIS FILE IS AUTO_GENERATED AND REGULARLY OVER-WRITTEN BY WORKFLOW SCRIPTS\n")
            f.write("### EDITS MAY RESULT IN MISBEHAVIOR OF EXPERIMENTS RUNNING\n")
            f.writelines(cfg_to_yaml_str(expts_dict))
    except KeyboardInterrupt:
        logging.warning("\nRefusing to interrupt during file write; try again\n")
        write_monitor_file(monitor_file,expts_dict)
    except:
        logging.fatal("\n********************************\n")
        logging.fatal(f"WARNING WARNING WARNING\n")
        logging.fatal("Failure occurred while writing monitor file {monitor_file}")
        logging.fatal("File may be corrupt or invalid for re-run!!")
        logging.fatal("\n********************************\n")
        raise


def update_expt_status(expt: dict, name: str, refresh: bool = False, debug: bool = False,
                       submit: bool = True) -> dict:
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
    ERROR:   Could not read the rocoto database file. This will require manual intervention to
             solve, so we will no longer monitor this experiment.
             This status may also appear if we fail to read the rocoto database file.
    RUNNING: One or more jobs are at status RUNNING, and the rest are either status QUEUED,
             SUBMITTED, or SUCCEEDED. This is a normal state; we will continue to monitor this
             experiment.
    QUEUED:  One or more jobs are at status QUEUED, and some others may be at status SUBMITTED or
             SUCCEEDED.
             This is a normal state; we will continue to monitor this experiment.
    SUCCEEDED: All jobs are status SUCCEEDED; we will monitor for one more cycle in case there are
             unsubmitted jobs remaining.
    COMPLETE:All jobs are status SUCCEEDED, and we have monitored this job for an additional cycle
             to ensure there are no un-submitted jobs. We will no longer monitor this experiment.

    Args:
        expt    (dict): A dictionary containing the information for an individual experiment, as
                        described in the main monitor_jobs() function.
        name     (str): Name of the experiment; used for logging only
        refresh (bool): If true, this flag will check an experiment status even if it is listed
                        as DEAD, ERROR, or COMPLETE. Used for initial checks for experiments
                        that may have been restarted.
        debug   (bool): Will capture all output from rocotorun. This will allow information such
                        as job cards and job submit messages to appear in the log files, but can
                        slow down the process drastically.
        submit  (bool): In addition to reading the rocoto database, script will advance the
                        workflow by calling rocotorun. If simply generating a report, set this
                        to False

    Returns:
        dict: The updated experiment dictionary.
    """

    #If we are no longer tracking this experiment, return unchanged
    if (expt["status"] in ['DEAD','ERROR','COMPLETE']) and not refresh:
        return expt
    # Update experiment, read rocoto database
    rocoto_db = f"{expt['expt_dir']}/FV3LAM_wflow.db"
    rocoto_xml = f"{expt['expt_dir']}/FV3LAM_wflow.xml"
    if submit:
        if refresh:
            logging.debug(f"Updating database for experiment {name}")
        if debug:
            rocotorun_cmd = ["rocotorun", f"-w {rocoto_xml}", f"-d {rocoto_db}", "-v 10"]
            p = subprocess.run(rocotorun_cmd, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True)
            logging.debug(p.stdout)

            #Run rocotorun again to get around rocotobqserver proliferation issue
            p = subprocess.run(rocotorun_cmd, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True)
            logging.debug(p.stdout)
        else:
            rocotorun_cmd = ["rocotorun", f"-w {rocoto_xml}", f"-d {rocoto_db}"]
            subprocess.run(rocotorun_cmd)
            #Run rocotorun again to get around rocotobqserver proliferation issue
            subprocess.run(rocotorun_cmd)

    logging.debug(f"Reading database for experiment {name}, updating experiment dictionary")
    try:
        # This section of code queries the "job" table of the rocoto database, returning a list
        # of tuples containing the taskname, cycle, and state of each job respectively
        with closing(sqlite3.connect(rocoto_db)) as connection:
            with closing(connection.cursor()) as cur:
                db = cur.execute('SELECT taskname,cycle,state,cores,duration from jobs').fetchall()
    except:
        # Some platforms (including Hera) can have a problem with rocoto jobs not submitting
        # properly due to build-ups of background processes. This will resolve over time as
        # rocotorun continues to be called, so let's only treat this as an error if we are
        # past the first initial iteration of job submissions
        if not refresh:
            logging.warning(f"Unable to read database {rocoto_db}\nCan not track experiment {name}")
            expt["status"] = "ERROR"

        return expt

    for task in db:
        # For each entry from rocoto database, store that task's info under a dictionary key named
        # TASKNAME_CYCLE; Cycle comes from the database in Unix Time (seconds), so convert to
        # human-readable
        cycle = datetime.utcfromtimestamp(task[1]).strftime('%Y%m%d%H%M')
        if f"{task[0]}_{cycle}" not in expt:
            expt[f"{task[0]}_{cycle}"] = dict()
        expt[f"{task[0]}_{cycle}"]["status"] = task[2]
        expt[f"{task[0]}_{cycle}"]["cores"] = task[3]
        expt[f"{task[0]}_{cycle}"]["walltime"] = task[4]

    statuses = list()
    for task in expt:
        # Skip non-task entries
        if task in ["expt_dir","status","start_time","walltime"]:
            continue
        statuses.append(expt[task]["status"])

    if "DEAD" in statuses:
        still_live = ["RUNNING", "SUBMITTING", "QUEUED", "FAILED"]
        if any(status in still_live for status in statuses):
            logging.debug(f'DEAD job in experiment {name}; continuing to track until all jobs are '\
                           'complete')
            expt["status"] = "DYING"
        else:
            expt["status"] = "DEAD"
            return expt
    elif "RUNNING" in statuses:
        expt["status"] = "RUNNING"
    elif "QUEUED" in statuses:
        expt["status"] = "QUEUED"
    elif "FAILED" in statuses or "SUBMITTING" in statuses:
        # Job in "FAILED" status means it will be retried
        expt["status"] = "SUBMITTING"
    elif "SUCCEEDED" in statuses:
        # If all task statuses are "SUCCEEDED", set the experiment status to "SUCCEEDED". This
        # will trigger a final check using rocotostat to make sure there are no remaining un-
        # started tests.
        expt["status"] = "SUCCEEDED"
    elif expt["status"] == "CREATED":
        # Some platforms (including Hera) can have a problem with rocoto jobs not submitting
        # properly due to build-ups of background processes. This will resolve over time as
        # rocotorun continues to be called, so let's only print this warning message if we
        # are past the first initial iteration of job submissions
        if not refresh:
            logging.warning(dedent(
                f"""WARNING:Tasks have not yet been submitted for experiment {name};
                it could be that your jobs are being throttled at the system level.

                If you continue to see this message, there may be an error with your
                experiment configuration, such as an incorrect queue or account number.

                You can use ctrl-c to pause this script and inspect log files.
                """))
    else:
        logging.fatal("Some kind of horrible thing has happened")
        raise ValueError(dedent(
              f"""Some kind of horrible thing has happened to the experiment status
              for experiment {name}
              status is {expt["status"]}
              all task statuses are {statuses}"""))

    # Final check for experiments where all tasks are "SUCCEEDED"; since the rocoto database does
    # not include info on jobs that have not been submitted yet, use rocotostat to check that
    # there are no un-submitted jobs remaining.
    if expt["status"] in ["SUCCEEDED","STALLED","STUCK"]:
        expt = compare_rocotostat(expt,name)

    return expt

def update_expt_status_parallel(expts_dict: dict, procs: int, refresh: bool = False,
                                debug: bool = False) -> dict:
    """
    This function updates an entire set of experiments in parallel, drastically speeding up
    the process if given enough parallel processes. Given a dictionary of experiments, it will
    pass each individual experiment dictionary to update_expt_status() to be updated, making use
    of the python multiprocessing starmap functionality to achieve this in parallel

    Args:
        expts_dict (dict): A dictionary containing information for all experiments
        procs       (int): The number of parallel processes
        refresh    (bool): "Refresh" flag to pass to update_expt_status()
        debug      (bool): Will capture all output from rocotorun. This will allow information such
                           as job cards and job submit messages to appear in the log files, but can
                           slow down the process drastically.

    Returns:
        dict: The updated dictionary of experiment dictionaries
    """

    args = []
    # Define a tuple of arguments to pass to starmap
    for expt in expts_dict:
        args.append( (expts_dict[expt],expt,refresh,debug) )

    # call update_expt_status() in parallel
    with Pool(processes=procs) as pool:
        output = pool.starmap(update_expt_status, args)

    # Update dictionary with output from all calls to update_expt_status()
    i = 0
    for expt in expts_dict:
        expts_dict[expt] = output[i]
        i += 1

    return expts_dict



def print_test_info(txtfile: str = "WE2E_test_info.txt") -> None:
    """Prints a pipe ( | ) delimited text file containing summaries of each test defined by a
    config file in test_configs/*

    Args:
        txtfile (str): File name for test details file
    """

    testfiles = glob.glob('test_configs/**/config*.yaml', recursive=True)
    testdict = dict()
    links = dict()
    for testfile in testfiles:
        # Calculate relative cost of test based on config settings using legacy script
        cost_array = calculate_cost(testfile)
        cost = cost_array[1] / cost_array[3]
        #Decompose full file path into relevant bits
        pathname, filename = os.path.split(testfile)
        testname = filename[7:-5]
        dirname = os.path.basename(os.path.normpath(pathname))
        if os.path.islink(testfile):
            if dirname == "default_configs":
                # Don't document default configs since they are not traditional tests
                # (and so don't follow the standard format)
                continue
            targettestfile = os.readlink(testfile)
            targetfilename = os.path.basename(targettestfile)
            targettestname = targetfilename[7:-5]
            links[testname] = (testname, dirname, targettestname)
        else:
            testdict[testname] = load_config_file(testfile)
            testdict[testname]["directory"] = dirname
            testdict[testname]["cost"] = cost
            #Calculate number of forecasts for a cycling run
            if testdict[testname]['workflow']["DATE_FIRST_CYCL"] != \
                    testdict[testname]['workflow']["DATE_LAST_CYCL"]:
                begin = datetime.strptime(testdict[testname]['workflow']["DATE_FIRST_CYCL"],
                                          '%Y%m%d%H')
                end = datetime.strptime(testdict[testname]['workflow']["DATE_LAST_CYCL"],
                                        '%Y%m%d%H')
                diff = end - begin
                diffh = diff.total_seconds() // 3600
                nf = diffh // testdict[testname]['workflow']["INCR_CYCL_FREQ"]
                testdict[testname]["num_fcsts"] = nf
            else:
                testdict[testname]["num_fcsts"] = 1

    # For each found link, add its info to the appropriate test dictionary entry
    for key, link in links.items():
        alt_testname, alt_dirname, link_name = link
        testdict[link_name]["alternate_name"] = alt_testname
        testdict[link_name]["alternate_directory_name"] = alt_dirname

    # Print the file
    with open(txtfile, 'w', encoding="utf-8") as f:
        # Field delimiter character
        d = "\" | \""
        txt_output = ['"Test Name']
        txt_output.append(f'(Subdirectory){d}Alternate Test Names')
        txt_output.append(f'(Subdirectories){d}Test Purpose/Description{d}Relative Cost of Running Dynamics')
        txt_output.append(f'(1 corresponds to running a 6-hour forecast on the RRFS_CONUS_25km predefined grid using the default time step){d}PREDEF_GRID_NAME{d}CCPP_PHYS_SUITE{d}EXTRN_MDL_NAME_ICS{d}EXTRN_MDL_NAME_LBCS{d}DATE_FIRST_CYCL{d}DATE_LAST_CYCL{d}INCR_CYCL_FREQ{d}FCST_LEN_HRS{d}DT_ATMOS{d}LBC_SPEC_INTVL_HRS{d}NUM_ENS_MEMBERS')

        for line in txt_output:
            f.write(f"{line}\n")
        for expt in testdict:
            f.write(f"\"{expt}\n(")
            f.write(f"{testdict[expt]['directory']}){d}")
            if "alternate_name" in testdict[expt]:
                f.write(f"{testdict[expt]['alternate_name']}\n"\
                        f"({testdict[expt]['alternate_directory_name']}){d}")
            else:
                f.write(f"{d}\n")
            desc = testdict[expt]['metadata']['description'].splitlines()
            for line in desc[:-1]:
                f.write(f"    {line}\n")
            f.write(f"    {desc[-1]}")
            #Write test relative cost and number of test forecasts (for cycling runs)
            f.write(f"{d}'{round(testdict[expt]['cost'],2)}{d}'{round(testdict[expt]['num_fcsts'])}")
            # Bundle various variables with their corresponding sections for more compact coding
            key_pairs = [ ('workflow', 'PREDEF_GRID_NAME'),
                          ('workflow', 'CCPP_PHYS_SUITE'),
                          ('task_get_extrn_ics', 'EXTRN_MDL_NAME_ICS'),
                          ('task_get_extrn_lbcs', 'EXTRN_MDL_NAME_LBCS'),
                          ('workflow', 'DATE_FIRST_CYCL'),
                          ('workflow', 'DATE_LAST_CYCL'),
                          ('workflow', 'INCR_CYCL_FREQ'),
                          ('workflow', 'FCST_LEN_HRS'),
                          ('task_run_fcst', 'DT_ATMOS'),
                          ('task_get_extrn_lbcs', 'LBC_SPEC_INTVL_HRS'),
                          ('global', 'NUM_ENS_MEMBERS') ]

            for key1, key2 in key_pairs:
                f.write(f"{d}{testdict[expt].get(key1, {}).get(key2, '')}")
            f.write("\n")


def compare_rocotostat(expt_dict,name):
    """Reads the dictionary showing the location of a given experiment, runs a `rocotostat` command
    to get the full set of tasks for the experiment, and compares the two to see if there are any
    unsubmitted tasks remaining.
    """

    # Call rocotostat and store output
    rocoto_db = f"{expt_dict['expt_dir']}/FV3LAM_wflow.db"
    rocoto_xml = f"{expt_dict['expt_dir']}/FV3LAM_wflow.xml"
    rocotorun_cmd = ["rocotostat", f"-w {rocoto_xml}", f"-d {rocoto_db}", "-v 10"]
    p = subprocess.run(rocotorun_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    rsout = p.stdout

    # Parse each line of rocotostat output, extracting relevant information
    untracked_tasks = []
    for line in rsout.split('\n'):
        # Skip blank lines and dividing lines of '=====...'
        if not line:
            continue
        if line[0] == '=':
            continue
        line_array = line.split()
        # Skip header lines
        if line_array[0] == 'CYCLE':
            continue
        # We should now just have lines describing jobs, in the form:
        # line_array = ['cycle','task','jobid','status','exit status','num tries','walltime']

        # As defined in update_expt_status(), the "task names" in the dictionary are a combination
        # of the task name and cycle
        taskname = f'{line_array[1]}_{line_array[0]}'

        # If we're already tracking this task, continue
        if expt_dict.get(taskname):
            continue

        # Otherwise, extract information into dictionary of untracked tasks
        untracked_tasks.append(taskname)

    if untracked_tasks:
        # We want to give this a couple loops before reporting that it is "stuck"
        if expt_dict['status'] == 'SUCCEEDED':
            expt_dict['status'] = 'STALLED'
        elif expt_dict['status'] == 'STALLED':
            expt_dict['status'] = 'STUCK'
        elif expt_dict['status'] == 'STUCK':
            msg = f"WARNING: For experiment {name}, there are jobs that are not being submitted:"
            for ut in untracked_tasks:
                msg += ut
            msg = msg + f"""WARNING: For experiment {name},
                there are some jobs that are not being submitted.
                It could be that your jobs are being throttled at the system level, or
                some task dependencies have not been met.

                If you continue to see this message, there may be an error with your
                experiment configuration.

                You can use ctrl-c to pause this script and inspect log files.
                """
            logging.warning(dedent(msg))
        else:
            logging.fatal("Some kind of horrible thing has happened")
            raise ValueError(dedent(
                  f"""Some kind of horrible thing has happened to the experiment status
                  for experiment {name}
                  status is {expt_dict["status"]}
                  untracked tasknames are {untracked_tasks}"""))
    else:
        expt_dict["status"] = "COMPLETE"

    return expt_dict
