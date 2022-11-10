#!/usr/bin/env python3

import os
import sys
import glob
import unittest
import logging
from textwrap import dedent
from datetime import datetime, timedelta

sys.path.append("../../ush")

from python_utils import (
    print_err_msg_exit,
    log_info,
    import_vars,
    export_vars,
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
)

from check_python_version import check_python_version


def run_we2e_tests() -> None:
    """Function to run the WE2E tests selected by the user

    Args:
        None
    Returns:
        None
    """

    # Set up logging to write to screen and logfile
    setup_logging()

    # Check python version and presence of some non-standard packages
    check_python_version()

    testfilename='machine_suites/comprehensive'
    log_info(f"reading test file name {testfilename}")
    user_spec_tests = list(open(testfilename))

    log_info("Checking that all tests are valid")
    testfiles = glob.glob('test_configs/**/config*.yaml', recursive=True)
    tests_to_run=[]
    for test in user_spec_tests:
        match=False
        #Search for exact config file name to avoid accidental partial matches
        test_config='config.' + test.rstrip() + '.yaml'
        for testfile in testfiles:
            if test_config in testfile:
                log_info(f"found test {test}",False)
                match=True
                tests_to_run.append(testfile)
        if not match:
            print_err_msg_exit(f"Could not find test {test}")

    pretty_list = "\n".join(str(x) for x in tests_to_run)
    log_info(f'Will run {len(tests_to_run)} tests:\n{pretty_list}')

    log_info("calling script that monitors rocoto jobs, prints summary")


def setup_logging(logfile: str = "log.run_WE2E_tests") -> None:
    """
    Sets up logging, printing high-priority (INFO and higher) messages to screen, and printing all
    messages with detailed timing and routine info in the specified text file.
    """
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(name)-22s %(levelname)-8s %(message)s",
        filename=logfile,
        filemode="w",
    )
    logging.debug(f"Finished setting up debug file logging in {logfile}")
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    logging.getLogger().addHandler(console)
    logging.debug("Logging set up successfully")


if __name__ == "__main__":

    logfile='log.run_WE2E_tests'
    try:
        run_we2e_tests()
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
