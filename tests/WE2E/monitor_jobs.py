#!/usr/bin/env python3

import sys
import argparse
import logging
import time
from textwrap import dedent
from datetime import datetime

sys.path.append("../../ush")

from python_utils import load_config_file

from check_python_version import check_python_version

from utils import calculate_core_hours, write_monitor_file, update_expt_status,\
                  update_expt_status_parallel, print_WE2E_summary

def monitor_jobs(expts_dict: dict, monitor_file: str = '', procs: int = 1,
                 mode: str = 'continuous', debug: bool = False) -> str:
    """Function to monitor and run jobs for the specified experiment using Rocoto

    Args:
        expts_dict  (dict): A dictionary containing the information needed to run
                            one or more experiments. See example file monitor_jobs.yaml
        monitor_file (str): [optional]
        mode         (str): [optional] Mode of job monitoring
                            continuous (default): monitor jobs continuously until complete
                            advance:
        debug       (bool): [optional] Enable extra output for debugging

    Returns:
        str: The name of the file used for job monitoring (when script is finished, this
             contains results/summary)
    """
    monitor_start = datetime.now()
    # Write monitor_file, which will contain information on each monitored experiment
    monitor_start_string = monitor_start.strftime("%Y%m%d%H%M%S")
    if not monitor_file:
        monitor_file = f'WE2E_tests_{monitor_start_string}.yaml'
    logging.info(f"Writing information for all experiments to {monitor_file}")

    write_monitor_file(monitor_file,expts_dict)

    # Perform initial setup for each experiment
    logging.info("Checking tests available for monitoring...")

    if procs > 1:
        print(f'Starting experiments in parallel with {procs} processes')
        expts_dict = update_expt_status_parallel(expts_dict, procs, True, debug)
    else:
        for expt in expts_dict:
            logging.info(f"Starting experiment {expt} running")
            expts_dict[expt] = update_expt_status(expts_dict[expt], expt, True, debug)

    write_monitor_file(monitor_file,expts_dict)

    if mode != 'continuous':
        logging.debug("All experiments have been updated")
        return monitor_file
    else:
        logging.debug("Continuous mode: will monitor jobs until all are complete")

    logging.info(f'Setup complete; monitoring {len(expts_dict)} experiments')
    logging.info('Use ctrl-c to pause job submission/monitoring')

    #Make a copy of experiment dictionary; will use this copy to monitor active experiments
    running_expts = expts_dict.copy()

    i = 0
    while running_expts:
        i += 1
        if procs > 1:
            expts_dict = update_expt_status_parallel(expts_dict, procs)
        else:
            for expt in running_expts.copy():
                expts_dict[expt] = update_expt_status(expts_dict[expt], expt)

        for expt in running_expts.copy():
            running_expts[expt] = expts_dict[expt]
            if running_expts[expt]["status"] in ['DEAD','ERROR','COMPLETE']:
                # If start_time is in dictionary, compute total walltime
                walltimestr = ''
                if running_expts[expt].get("start_time",{}) and not running_expts[expt].get("walltime",{}):
                    end = datetime.now()
                    start = datetime.strptime(running_expts[expt]["start_time"],'%Y%m%d%H%M%S')
                    walltime = end - start
                    walltimestr = f'Took {str(walltime)}; '
                    running_expts[expt]["walltime"] = str(walltime)

                logging.info(f'Experiment {expt} is {running_expts[expt]["status"]}')

                # If failures, check how many experiments were successful
                if debug:
                    if running_expts[expt]["status"] != "COMPLETE":
                        i=j=0
                        for task in running_expts[expt]:
                            # Skip non-task entries
                            if task in ["expt_dir","status","start_time","walltime"]:
                                continue
                            j+=1
                            if running_expts[expt][task]["status"] == "SUCCEEDED":
                                i+=1
                        logging.debug(f'{i} of {j} tasks were successful')
                logging.info(f'{walltimestr}will no longer monitor.')
                running_expts.pop(expt)
                continue
            logging.debug(f'Experiment {expt} status is {expts_dict[expt]["status"]}')

        write_monitor_file(monitor_file,expts_dict)
        endtime = datetime.now()
        total_walltime = endtime - monitor_start

        logging.debug(f"Finished loop {i}")
        logging.debug(f"Walltime so far is {str(total_walltime)}")
        #Slow things down just a tad between loops so experiments behave better
        time.sleep(5)

    logging.info(f'All {len(expts_dict)} experiments finished')
    logging.info('Calculating core-hour usage and printing final summary')

    # Calculate core hours and update yaml
    expts_dict = calculate_core_hours(expts_dict)
    write_monitor_file(monitor_file,expts_dict)

    #Call function to print summary
    print_WE2E_summary(expts_dict, debug)

    return monitor_file


def setup_logging(logfile: str = "log.run_WE2E_tests", debug: bool = False) -> None:
    """
    Sets up logging, printing high-priority (INFO and higher) messages to screen, and printing all
    messages with detailed timing and routine info in the specified text file.
    """
    logging.getLogger().setLevel(logging.DEBUG)

    formatter = logging.Formatter("%(name)-16s %(levelname)-8s %(message)s")

    fh = logging.FileHandler(logfile, mode='a')
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
    parser = argparse.ArgumentParser(description="Script for monitoring and running jobs in a "\
                                                 "specified experiment, as specified in a yaml "\
                                                 "configuration file\n")

    parser.add_argument('-y', '--yaml_file', type=str,
                        help='YAML-format file specifying the information of jobs to be run; '\
                             'for an example file, see monitor_jobs.yaml', required=True)
    parser.add_argument('-p', '--procs', type=int,
                        help='Run resource-heavy tasks (such as calls to rocotorun) in parallel, '\
                             'with provided number of parallel tasks', default=1)
    parser.add_argument('-m', '--mode', type=str, default='continuous',
                        choices=['continuous','advance'],
                        help='continuous: script will run continuously until all experiments are'\
                             'finished.'\
                             'advance: will only advance each experiment one step')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Script will be run in debug mode with more verbose output')

    args = parser.parse_args()

    setup_logging(logfile,args.debug)

    expts_dict = load_config_file(args.yaml_file)

    if args.procs < 1:
        raise ValueError('You can not have less than one parallel process; select a valid value for --procs')

    #Call main function

    try:
        monitor_jobs(expts_dict=expts_dict,monitor_file=args.yaml_file,procs=args.procs,
                     mode=args.mode,debug=args.debug)
    except KeyboardInterrupt:
        logging.info("\n\nUser interrupted monitor script; to resume monitoring jobs run:\n")
        logging.info(f"{__file__} -y={args.yaml_file} -p={args.procs}\n")
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
