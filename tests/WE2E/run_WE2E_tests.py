#!/usr/bin/env python3

import os
import sys
import glob
import argparse
import logging
from textwrap import dedent
from datetime import datetime, timedelta

sys.path.append("../../ush")

from python_utils import (
    print_err_msg_exit,
    cp_vrfy,
    cd_vrfy,
    rm_vrfy,
    ln_vrfy,
    mkdir_vrfy,
    mv_vrfy,
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


def run_we2e_tests(HOMEdir, args) -> None:
    """Function to run the WE2E tests selected by the user

    Args:
        HOMEdir  (str): The full path of the top-level app directory
        args : The argparse.Namespace object containing command-line arguments
    Returns:
        None
    """

    # Set up logging to write to screen and logfile
    setup_logging(debug=args.debug)

    # Check python version and presence of some non-standard packages
    check_python_version()

    # Set some important directories
    USHdir=HOMEdir + '/ush'

    testfilename='machine_suites/test'
    logging.info(f"reading test file name {testfilename}")
    user_spec_tests = list(open(testfilename))

    logging.info("Checking that all tests are valid")
    testfiles = glob.glob('test_configs/**/config*.yaml', recursive=True)
    tests_to_run=[]
    for test in user_spec_tests:
        match=False
        #Search for exact config file name to avoid accidental partial matches
        test_config='config.' + test.rstrip() + '.yaml'
        for testfile in testfiles:
            if test_config in testfile:
                logging.debug(f"found test {test}")
                match=True
                tests_to_run.append(testfile)
        if not match:
            print_err_msg_exit(f"Could not find test {test}")

    pretty_list = "\n".join(str(x) for x in tests_to_run)
    logging.info(f'Will run {len(tests_to_run)} tests:\n{pretty_list}')

    #Load default and machine-specific values
    config_defaults = load_config_file(USHdir + '/config_defaults.yaml')
    machine_defaults = load_config_file(USHdir + '/machine/' + args.machine + '.yaml')

    for test in tests_to_run:
        #Starting with test yaml template, fill in user-specified and machine- and 
        # test-specific options, then write resulting complete config.yaml
        logging.debug(f"For test {os.path.basename(test)}, constructing config.yaml")
        test_cfg = load_config_file(test)

        test_cfg['user'].update({"machine": args.machine})
        test_cfg['user'].update({"account": args.account})
        test_cfg['user'].update({"compiler": args.compiler})
        test_cfg['user'].update({"BUILD_MOD_FN": args.modulefile})


        logging.debug(cfg_to_yaml_str(test_cfg))
        with open(USHdir + "/config.yaml","w+") as f:
            f.writelines(cfg_to_yaml_str(test_cfg))

    logging.info("calling script that monitors rocoto jobs, prints summary")


def setup_logging(logfile: str = "log.run_WE2E_tests", debug: bool = False) -> None:
    """
    Sets up logging, printing high-priority (INFO and higher) messages to screen, and printing all
    messages with detailed timing and routine info in the specified text file.
    """
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(name)-16s %(levelname)-8s %(message)s",
        filename=logfile,
        filemode="w",
    )
    logging.debug(f"Finished setting up debug file logging in {logfile}")
    console = logging.StreamHandler()
    if debug:
       console.setLevel(logging.DEBUG)
    else:
       console.setLevel(logging.INFO)
    logging.getLogger().addHandler(console)
    logging.debug("Logging set up successfully")


if __name__ == "__main__":

    #Get the "Home" directory, two levels above this one
    HOMEdir=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    logfile='log.run_WE2E_tests'

    #Parse arguments
    parser = argparse.ArgumentParser()
    optional = parser._action_groups.pop() # Edited this line
    required = parser.add_argument_group('required arguments')

    parser.add_argument('-d', '--debug', action='store_true', help='Script will be run in debug mode with more verbose output')
    required.add_argument('-m', '--machine', type=str, help='Machine name; see ush/machine/ for valid values', required=True)
    required.add_argument('-a', '--account', type=str, help='Account name for running submitted jobs', required=True)
    parser.add_argument('-c', '--compiler', type=str, help='Compiler used for building the app', default='intel')
    parser.add_argument('-mf', '--modulefile', type=str, help='Modulefile used for building the app')

    parser._action_groups.append(optional)

    args = parser.parse_args()

    #Set defaults that need other argument values
    if args.modulefile is None:
        args.modulefile = f'build_{args.machine}_{args.compiler}'

    #Call main function

    try:
        run_we2e_tests(HOMEdir,args)
    except:
        logging.exception(
            dedent(
                f"""
                *********************************************************************
                FATAL ERROR:
                Experiment generation failed. See the error message(s) printed below.
                For more detailed information, check the log file from the workflow
                generation script: {logfile}
                *********************************************************************\n
                """
            )
        )
