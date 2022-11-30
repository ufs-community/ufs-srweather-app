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

    config_default_file = USHdir + '/config_defaults.yaml'
    logging.debug(f"Loading config defaults file {config_default_file}")
    config_defaults = load_config_file(config_default_file)

    machine_file = USHdir + '/machine/' + args.machine + '.yaml'
    logging.debug(f"Loading machine defaults file {machine_file}")
    machine_defaults = load_config_file(machine_file)

    for test in tests_to_run:
        #Starting with test yaml template, fill in user-specified and machine- and 
        # test-specific options, then write resulting complete config.yaml
        test_name = os.path.basename(test)
        logging.debug(f"For test {test_name}, constructing config.yaml")
        test_cfg = load_config_file(test)

        test_cfg['user'].update({"machine": args.machine})
        test_cfg['user'].update({"account": args.account})
        if args.run_envir is not None:
            test_cfg['user'].update({"RUN_ENVIR": args.run_envir})
        # if platform section was not in input config, initialize as empty dict
        if 'platform' not in test_cfg:
            test_cfg['platform'] = dict()
        test_cfg['platform'].update({"BUILD_MOD_FN": args.modulefile})
        test_cfg['workflow'].update({"compiler": args.compiler})
        if args.expt_basedir:
            test_cfg['workflow'].update({"EXPT_BASEDIR": args.expt_basedir})
        test_cfg['workflow'].update({"EXPT_SUBDIR": test_name})
        if args.exec_subdir:
            test_cfg['workflow'].update({"EXEC_SUBDIR": args.exec_subdir})
        if args.use_cron_to_relaunch:
            test_cfg['workflow'].update({"USE_CRON_TO_RELAUNCH": args.use_cron_to_relaunch})
        if args.cron_relaunch_intvl_mnts:
            test_cfg['workflow'].update({"CRON_RELAUNCH_INTVL_MNTS": args.cron_relaunch_intvl_mnts})
        if args.debug_tests:
            test_cfg['workflow'].update({"DEBUG": args.debug_tests})
        if args.verbose_tests:
            test_cfg['workflow'].update({"VERBOSE": args.verbose_tests})

        logging.debug(f"Overwriting WE2E-test-specific settings for test \n{test_name}\n")

#        if 'task_get_extrn_ics' in test_cfg:
#            check_task_get_extrn_ics(test_cfg,machine_defaults)
#        if 'task_get_extrn_lbcs' in test_cfg:
#            check_task_get_extrn_lbcs(test_cfg,machine_defaults)

        logging.debug(f"Writing updated config.yaml for test {test_name}\nbased on specified command-line arguments:\n")
        logging.debug(cfg_to_yaml_str(test_cfg))
        with open(USHdir + "/config.yaml","w+") as f:
            f.writelines(cfg_to_yaml_str(test_cfg))

        logging.debug(f"Calling workflow generation function for test {test_name}\n")

    logging.info("calling script that monitors rocoto jobs, prints summary")

def check_task_get_extrn_ics(cfg: dict, mach: dict) -> None:
    """
    Function for checking and overwriting various settings in task_get_extrn_ics section of test config yaml

    Args:
        cfg  : Dictionary loaded from test config file
        mach : Dictionary loaded from machine settings file
    Returns:
        None
    """

    # If EXTRN_MDL_SYSBASEDIR_ICS not specified, do nothing and return
    if 'EXTRN_MDL_SYSBASEDIR_ICS' not in cfg['task_get_extrn_ics']:
        return

    # If EXTRN_MDL_SYSBASEDIR_ICS is "set_to_non_default_location_in_testing_script", replace with test value from machine file
    if cfg['task_get_extrn_ics']['EXTRN_MDL_SYSBASEDIR_ICS'] == "set_to_non_default_location_in_testing_script":
        if 'TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS' in mach['platform']:
            if os.path.isdir(mach['platform']['TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS']):
                raise FileNotFoundError(f"Non-default input file location TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS from machine file does not exist or is not a directory")
            cfg['task_get_extrn_ics']['EXTRN_MDL_SYSBASEDIR_ICS'] = mach['platform']['TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS']
        else:
            raise KeyError(f"Non-default input file location TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS not set in machine file")

def check_task_get_extrn_lbcs(cfg: dict, mach: dict) -> None:
    """
    Function for checking and overwriting various settings in task_get_extrn_lbcs section of test config yaml

    Args:
        cfg  : Dictionary loaded from test config file
        mach : Dictionary loaded from machine settings file
    Returns:
        None
    """

    # If EXTRN_MDL_SYSBASEDIR_LBCS not specified, do nothing and return
    if 'EXTRN_MDL_SYSBASEDIR_LBCS' not in cfg['task_get_extrn_lbcs']:
        return

    # If EXTRN_MDL_SYSBASEDIR_LBCS is "set_to_non_default_location_in_testing_script", replace with test value from machine file
    if cfg['task_get_extrn_lbcs']['EXTRN_MDL_SYSBASEDIR_LBCS'] == "set_to_non_default_location_in_testing_script":
        if 'TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS' in mach['platform']:
            if os.path.isdir(mach['platform']['TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS']):
                raise FileNotFoundError(f"Non-default input file location TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS from machine file does not exist or is not a directory")
            cfg['task_get_extrn_lbcs']['EXTRN_MDL_SYSBASEDIR_LBCS'] = mach['platform']['TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS']
        else:
            raise KeyError(f"Non-default input file location TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS not set in machine file")


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
    parser = argparse.ArgumentParser(epilog="For more information about config arguments (denoted in CAPS), see ush/config_defaults.yaml\n")
    optional = parser._action_groups.pop() # Edited this line
    required = parser.add_argument_group('required arguments')

    parser.add_argument('-d', '--debug', action='store_true', help='Script will be run in debug mode with more verbose output')
    required.add_argument('-m', '--machine', type=str, help='Machine name; see ush/machine/ for valid values', required=True)
    required.add_argument('-a', '--account', type=str, help='Account name for running submitted jobs', required=True)
    parser.add_argument('-c', '--compiler', type=str, help='Compiler used for building the app', default='intel')
    parser.add_argument('--modulefile', type=str, help='Modulefile used for building the app')
    parser.add_argument('--run_envir', type=str, help='Overrides RUN_ENVIR variable to a new value ( "nco" or "community" ) for all experiments')
    parser.add_argument('--expt_basedir', type=str, help='Explicitly set EXPT_BASEDIR for all experiments')
    parser.add_argument('--exec_subdir', type=str, help='Explicitly set EXEC_SUBDIR for all experiments')
    parser.add_argument('use_cron_to_relaunch', action='store_true', help='Explicitly set USE_CRON_TO_RELAUNCH for all experiments')
    parser.add_argument('--cron_relaunch_intvl_mnts', type=str, help='Overrides CRON_RELAUNCH_INTVL_MNTS for all experiments')
    parser.add_argument('--debug_tests', action='store_true', help='Explicitly set DEBUG=TRUE for all experiments')
    parser.add_argument('--verbose_tests', action='store_true', help='Explicitly set VERBOSE=TRUE for all experiments')
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
