#!/usr/bin/env python3
# pylint: disable=logging-fstring-interpolation

import os
import sys
import glob
import argparse
import logging
from textwrap import dedent
from datetime import datetime

sys.path.insert(1, "../../ush")

from generate_FV3LAM_wflow import generate_FV3LAM_wflow
from python_utils import (
    cfg_to_yaml_str,
    load_config_file,
)

from check_python_version import check_python_version

from monitor_jobs import monitor_jobs, write_monitor_file
from utils import print_test_info

def run_we2e_tests(homedir, args) -> None:
    """Runs the Workflow End-to-End (WE2E) tests selected by the user

    Args:
        homedir (str): The full path to the top-level application directory
        args    (argparse.Namespace): Command-line arguments

    Returns:
        None
    """

    # Set up logging to write to screen and logfile
    setup_logging(debug=args.debug)

    # Set some important directories
    ushdir=os.path.join(homedir,'ush')

    # Set some variables based on input arguments
    run_envir = args.run_envir
    machine = args.machine.lower()

    # Check for invalid input
    if run_envir:
        if run_envir not in ['nco', 'community']:
            raise KeyError(f"Invalid 'run_envir' provided: {run_envir}")

    alltests = glob.glob('test_configs/**/config*.yaml', recursive=True)
    testdirs = next(os.walk('test_configs'))[1]
    # If args.tests is a list of length more than one, we assume it is a list of test names
    if len(args.tests) > 1:
        tests_to_check=args.tests
        logging.debug(f"User specified a list of tests:\n{tests_to_check}")
    else:
        #First see if args.tests is a valid test name
        user_spec_tests = args.tests
        logging.debug(f'Checking if {user_spec_tests} is a valid test name')
        match = check_test(user_spec_tests[0])
        if match:
            tests_to_check = user_spec_tests
        else:
            # If not a valid test name, check if it is a test suite
            logging.debug(f'Checking if {user_spec_tests} is a valid test suite')
            if user_spec_tests[0] == 'all':
                tests_to_check = []
                for f in alltests:
                    filename = os.path.basename(f)
                    # We just want the test name in this list, so cut out the
                    # "config." prefix and ".yaml" extension
                    if len(filename) > 12:
                        if filename[:7] == "config." and filename[-5:] == ".yaml":
                            tests_to_check.append(filename[7:-5])
                        else:
                            logging.debug(f"Skipping non-test file {filename}")
                    else:
                        logging.debug(f"Skipping non-test file {filename}")
                logging.debug(f"Will check all tests:\n{tests_to_check}")
            elif user_spec_tests[0] in ['fundamental', 'comprehensive', 'coverage']:
                # I am writing this section of code under protest; we should use args.run_envir to
                # check for run_envir-specific files!
                prefix = f"machine_suites/{user_spec_tests[0]}"
                testfilename = f"{prefix}.{machine}.{args.compiler}.nco"
                if not os.path.isfile(testfilename):
                    testfilename = f"{prefix}.{machine}.{args.compiler}.com"
                    if not os.path.isfile(testfilename):
                        testfilename = f"{prefix}.{machine}.{args.compiler}"
                        if not os.path.isfile(testfilename):
                            testfilename = f"{prefix}.{machine}"
                            if not os.path.isfile(testfilename):
                                testfilename = f"machine_suites/{user_spec_tests[0]}"
                    else:
                        if not run_envir:
                            run_envir = 'community'
                            logging.debug(f'{testfilename} exists for this platform and run_envir'\
                                           'has not been specified\n'\
                                           'Setting run_envir = {run_envir} for all tests')
                logging.debug(f"Reading test file: {testfilename}")
                with open(testfilename, encoding="utf-8") as f:
                    tests_to_check = [x.rstrip() for x in f]
                logging.debug(f"Will check {user_spec_tests[0]} tests:\n{tests_to_check}")
            elif user_spec_tests[0] in testdirs:
                # If a subdirectory under test_configs/ is specified, run all tests in that directory
                logging.debug(f"{user_spec_tests[0]} is one of the testing directories:\n{testdirs}")
                logging.debug(f"Will run all tests in test_configs/{user_spec_tests[0]}")
                tests_in_dir = glob.glob(f'test_configs/{user_spec_tests[0]}/config*.yaml', recursive=True)
                tests_to_check = []
                for f in tests_in_dir:
                    filename = os.path.basename(f)
                    # We just want the test name in this list, so cut out the
                    # "config." prefix and ".yaml" extension
                    if len(filename) > 12:
                        if filename[:7] == "config." and filename[-5:] == ".yaml":
                            tests_to_check.append(filename[7:-5])
                        else:
                            logging.debug(f"Skipping non-test file {filename}")
                    else:
                        logging.debug(f"Skipping non-test file {filename}")
            else:
                # If we have gotten this far then the only option left for user_spec_tests is a
                # file containing test names
                logging.debug(f'Checking if {user_spec_tests} is a file containing test names')
                if os.path.isfile(user_spec_tests[0]):
                    with open(user_spec_tests[0], encoding="utf-8") as f:
                        tests_to_check = [x.rstrip() for x in f]
                else:
                    raise FileNotFoundError(dedent(f"""
                    The specified 'tests' argument '{user_spec_tests}'
                    does not appear to be a valid test name, a valid test suite, a subdirectory
                    under test_configs/, or a file containing valid test names.

                    Check your inputs and try again.
                    """))


    logging.info("Checking that all tests are valid")

    tests_to_run=check_tests(tests_to_check)

    pretty_list = "\n".join(str(x) for x in tests_to_run)
    logging.info(f'Will run {len(tests_to_run)} tests:\n{pretty_list}')

    config_default_file = os.path.join(ushdir,'config_defaults.yaml')
    logging.debug(f"Loading config defaults file {config_default_file}")
    config_defaults = load_config_file(config_default_file)

    machine_file = os.path.join(ushdir, 'machine', f'{machine}.yaml')
    logging.debug(f"Loading machine defaults file {machine_file}")
    machine_defaults = load_config_file(machine_file)

    # Set up dictionary for job monitoring yaml
    if args.launch != "cron":
        monitor_yaml = dict()

    for test in tests_to_run:
        #Starting with test yaml template, fill in user-specified and machine- and
        # test-specific options, then write resulting complete config.yaml
        starttime = datetime.now()
        starttime_string = starttime.strftime("%Y%m%d%H%M%S")
        test_name = os.path.basename(test).split('.')[1]
        logging.debug(f"For test {test_name}, constructing config.yaml")
        test_cfg = load_config_file(test)

        if test_cfg.get('user') is None:
            test_cfg['user'] = {}
        test_cfg['user'].update({"MACHINE": machine})
        test_cfg['user'].update({"ACCOUNT": args.account})
        if run_envir:
            test_cfg['user'].update({"RUN_ENVIR": run_envir})
        # if platform section was not in input config, initialize as empty dict
        if 'platform' not in test_cfg:
            test_cfg['platform'] = dict()
        test_cfg['platform'].update({"BUILD_MOD_FN": args.modulefile})
        test_cfg['workflow'].update({"COMPILER": args.compiler})
        if args.expt_basedir:
            test_cfg['workflow'].update({"EXPT_BASEDIR": args.expt_basedir})
        test_cfg['workflow'].update({"EXPT_SUBDIR": test_name})
        if args.exec_subdir:
            test_cfg['workflow'].update({"EXEC_SUBDIR": args.exec_subdir})
        if args.launch == "cron":
            test_cfg['workflow'].update({"USE_CRON_TO_RELAUNCH": True})
        if args.cron_relaunch_intvl_mnts:
            test_cfg['workflow'].update({"CRON_RELAUNCH_INTVL_MNTS": args.cron_relaunch_intvl_mnts})
        if args.debug_tests:
            test_cfg['workflow'].update({"DEBUG": args.debug_tests})
        if args.verbose_tests:
            test_cfg['workflow'].update({"VERBOSE": args.verbose_tests})

        logging.debug(f"Overwriting WE2E-test-specific settings for test \n{test_name}\n")

        if 'task_get_extrn_ics' in test_cfg:
            test_cfg['task_get_extrn_ics'] = check_task_get_extrn_bcs(test_cfg,machine_defaults,
                                                                      config_defaults,"ics")
        if 'task_get_extrn_lbcs' in test_cfg:
            test_cfg['task_get_extrn_lbcs'] = check_task_get_extrn_bcs(test_cfg,machine_defaults,
                                                                       config_defaults,"lbcs")

        if 'verification' in test_cfg:
            # This section checks if we are doing verification on a machine with staged verification
            # obs. If so, and if the config file does not explicitly set the observation locations,
            # fill these in with defaults from the machine files
            obs_vars = ['CCPA_OBS_DIR','MRMS_OBS_DIR','NDAS_OBS_DIR','NOHRSC_OBS_DIR']
            for obvar in obs_vars:
                mach_path = machine_defaults['platform'].get('TEST_'+obvar)
                if not test_cfg['verification'].get(obvar) and mach_path:
                    logging.debug(f'Setting {obvar} = {mach_path} from machine file')
                    test_cfg['verification'][obvar] = mach_path

        if args.compiler == "gnu":
            # 2D decomposition doesn't work with GNU compilers.  Deactivate 2D decomposition for GNU
            if 'task_run_post' in test_cfg:
                test_cfg['task_run_post'].update({"NUMX": 1})
                logging.info(f"NUMX has been reset to 1 due to issues encountered with GNU compilers")
            if 'task_run_fcst' in test_cfg:
                test_cfg['task_run_fcst'].update({"ITASKS": 1})
                logging.info(f"ITASKS has been reset to 1 due to issues encountered with GNU compilers")

        logging.debug(f"Writing updated config.yaml for test {test_name}\n"\
                       "based on specified command-line arguments:\n")
        logging.debug(cfg_to_yaml_str(test_cfg))
        with open(os.path.join(ushdir,"config.yaml"),"w", encoding="utf-8") as f:
            f.writelines(cfg_to_yaml_str(test_cfg))

        logging.info(f"Calling workflow generation function for test {test_name}\n")
        if args.quiet:
            console_handler = logging.getLogger().handlers[1]
            console_handler.setLevel(logging.WARNING)
        expt_dir = generate_FV3LAM_wflow(ushdir,logfile=f"{ushdir}/log.generate_FV3LAM_wflow",
                                         debug=args.debug)
        if args.quiet:
            if args.debug:
                console_handler.setLevel(logging.DEBUG)
            else:
                console_handler.setLevel(logging.INFO)
        logging.info(f"Workflow for test {test_name} successfully generated in\n{expt_dir}\n")
        # If this job is not using crontab, we need to add an entry to monitor.yaml
        if 'USE_CRON_TO_RELAUNCH' not in test_cfg['workflow']:
            test_cfg['workflow'].update({"USE_CRON_TO_RELAUNCH": False})
        if not test_cfg['workflow']['USE_CRON_TO_RELAUNCH']:
            logging.debug(f'Creating entry for job {test_name} in job monitoring dict')
            workflow_id = f'{test_name}_{starttime_string}'
            monitor_yaml[workflow_id] = dict()
            monitor_yaml[workflow_id].update({"expt_dir": expt_dir})
            monitor_yaml[workflow_id].update({"status": "CREATED"})
            monitor_yaml[workflow_id].update({"start_time": starttime_string})
            # Make WORKFLOW_ID actually mean something
            test_cfg['workflow'].update({"WORKFLOW_ID": workflow_id})

    if args.launch != "cron":
        monitor_file = f'WE2E_tests_{starttime_string}.yaml'
        write_monitor_file(monitor_file,monitor_yaml)
        logging.info("All experiments have been generated;")
        logging.info(f"Experiment file {monitor_file} created")
        if args.launch == "python":
            write_monitor_file(monitor_file,monitor_yaml)
            logging.debug("calling function that monitors jobs, prints summary")
            try:
                monitor_file = monitor_jobs(monitor_yaml, monitor_file=monitor_file, procs=args.procs,
                                            debug=args.debug)
            except KeyboardInterrupt:
                logging.info("\n\nUser interrupted monitor script; to resume monitoring jobs run:\n")
                logging.info(f"./monitor_jobs.py -y={monitor_file} -p={args.procs}\n")
        else:
            logging.info("To automatically run and monitor experiments, use:\n")
            logging.info(f"./monitor_jobs.py -y={monitor_file}\n")
    else:
        logging.info("All experiments have been generated; using cron to submit workflows")
        logging.info("To view running experiments in cron try `crontab -l`")


def check_tests(tests: list) -> list:
    """
    Checks that all tests in a provided list of tests are valid

    Args:
        tests (list): List of potentially valid test names

    Returns:
        tests_to_run: List of configuration files corresponding to test names
    """

    testfiles = glob.glob('test_configs/**/config*.yaml', recursive=True)
    # Check that there are no duplicate test filenames
    testfilenames=[]
    for testfile in testfiles:
        if os.path.basename(testfile) in testfilenames:
            duplicates = glob.glob('test_configs/**/' + os.path.basename(testfile), recursive=True)
            raise Exception(dedent(f"""
                            Found duplicate test file names:
                            {duplicates}
                            Ensure that each test file name under the test_configs/ directory
                            is unique.
                            """))
        testfilenames.append(os.path.basename(testfile))
    tests_to_run=[]
    for test in tests:
        # Skip blank/empty testnames; this avoids failure if newlines or spaces are included
        if not test or test.isspace():
            continue
        # Skip if string has an octothorpe
        if '#' in test:
            logging.debug(f"Assuming line is a comment due to presence of '#' character:\n{test}")
            continue
        match = check_test(test)
        if not match:
            raise Exception(f"Could not find test {test}")
        tests_to_run.append(match)
    # Because some test files are symlinked to other tests, check that we don't
    # include the same test twice
    for testfile in tests_to_run.copy():
        if os.path.islink(testfile):
            if os.path.realpath(testfile) in tests_to_run:
                logging.warning(dedent(f"""WARNING: test file {testfile} is a symbolic link to a
                                test file ({os.path.realpath(testfile)}) that is also included in
                                the test list. Only the latter test will be run."""))
                tests_to_run.remove(testfile)
    if len(tests_to_run) != len(set(tests_to_run)):
        logging.warning("\nWARNING: Duplicate test names were found in list. "\
                        "Removing duplicates and continuing.\n")
        tests_to_run = list(set(tests_to_run))
    return tests_to_run



def check_test(test: str) -> str:
    """
    Checks that a string corresponds to a valid test name

    Args:
        test (str): Potential test name

    Returns:
        config: Name of the test configuration file (empty string if no test file is found)
    """
    # potential test files
    testfiles = glob.glob('test_configs/**/config*.yaml', recursive=True)
    # potential test file for input test name
    test_config=f'config.{test.strip()}.yaml'
    config = ''
    for testfile in testfiles:
        if test_config in testfile:
            logging.debug(f"found test {test}, testfile {testfile}")
            config = os.path.abspath(testfile)
    return config


def check_task_get_extrn_bcs(cfg: dict, mach: dict, dflt: dict, ics_or_lbcs: str = "") -> dict:
    """
    Checks and updates various settings in the ``task_get_extrn_ics`` or 
    ``task_get_extrn_lbcs`` section of the test's configuration YAML file

    Args:
        cfg         (dict): Contents loaded from test configuration file
        mach        (dict): Contents loaded from machine settings file
        dflt        (dict): Contents loaded from default configuration file (``config_defaults.yaml``)
        ics_or_lbcs (str): Perform checks for either the ICs task or the LBCs task. Valid values: ``"ics"`` | ``"lbcs"``

    Returns:
        cfg_bcs: Updated dictionary for ``task_get_extrn_[ics|lbcs]`` section of test configuration file
    """

    if ics_or_lbcs not in ["lbcs", "ics"]:
        raise ValueError("ics_or_lbcs must be set to 'lbcs' or 'ics'")

    #Make our lives easier by shortening some dictionary calls
    cfg_bcs = cfg[f'task_get_extrn_{ics_or_lbcs}']

    # If the task is turned off explicitly, do nothing and return
    # To turn off that task, taskgroups is included without the
    # coldstart group, or task_get_extrn_{ics_or_lbcs} is included
    # without a value
    taskgroups = cfg.get('rocoto', {}).get('taskgroups')
    if taskgroups is not None and "coldstart.yaml" not in taskgroups:
        return cfg_bcs
    rocoto_tasks = cfg.get('rocoto', {}).get('tasks',{})
    if rocoto_tasks.get(f"task_get_extrn_{ics_or_lbcs}", "NA") is None:
        return cfg_bcs

    I_OR_L = ics_or_lbcs.upper()

    # If USE_USER_STAGED_EXTRN_FILES not specified or false, do nothing and return
    if not cfg_bcs.get('USE_USER_STAGED_EXTRN_FILES'):
        logging.debug('USE_USER_STAGED_EXTRN_FILES not specified or False in '\
                      f'task_get_extrn_{ics_or_lbcs} section of config')
        return cfg_bcs

    # If EXTRN_MDL_SYSBASEDIR_* is "set_to_non_default_location_in_testing_script", replace with
    # test value from machine file
    if cfg_bcs.get(f'EXTRN_MDL_SYSBASEDIR_{I_OR_L}') == \
                    "set_to_non_default_location_in_testing_script":
        if f'TEST_ALT_EXTRN_MDL_SYSBASEDIR_{I_OR_L}' in mach['platform']:
            if os.path.isdir(mach['platform'][f'TEST_ALT_EXTRN_MDL_SYSBASEDIR_{I_OR_L}']):
                raise FileNotFoundError("Non-default input file location "\
                                        f"TEST_ALT_EXTRN_MDL_SYSBASEDIR_{I_OR_L} from machine "\
                                        "file does not exist or is not a directory")
            cfg_bcs[f'EXTRN_MDL_SYSBASEDIR_{I_OR_L}'] = \
                    mach['platform'][f'TEST_ALT_EXTRN_MDL_SYSBASEDIR_{I_OR_L}']
        else:
            raise KeyError("Non-default input file location "\
                           f"TEST_ALT_EXTRN_MDL_SYSBASEDIR_{I_OR_L} not set in machine file")
        return cfg_bcs

    # Because USE_USER_STAGED_EXTRN_FILES is true, only look on disk, and ensure the staged data
    # directory exists
    cfg['platform']['EXTRN_MDL_DATA_STORES'] = "disk"
    if 'TEST_EXTRN_MDL_SOURCE_BASEDIR' not in mach['platform']:
        raise KeyError("TEST_EXTRN_MDL_SOURCE_BASEDIR, the directory for staged test data,"\
                       "has not been specified in the machine file for this platform")
    if not os.path.isdir(mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']):
        raise FileNotFoundError(dedent(
                f"""The directory for staged test data specified in this platform's machine file
                TEST_EXTRN_MDL_SOURCE_BASEDIR = {mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}
                does not exist."""))

    # Different input data types have different directory structures; set data dir accordingly
    if cfg_bcs[f'EXTRN_MDL_NAME_{I_OR_L}'] == 'FV3GFS':
        if f'FV3GFS_FILE_FMT_{I_OR_L}' not in cfg_bcs:
            cfg_bcs[f'FV3GFS_FILE_FMT_{I_OR_L}'] = \
                    dflt[f'task_get_extrn_{ics_or_lbcs}'][f'FV3GFS_FILE_FMT_{I_OR_L}']
        cfg_bcs[f'EXTRN_MDL_SOURCE_BASEDIR_{I_OR_L}'] = \
                os.path.join(f"{mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}",
                f"{cfg_bcs[f'EXTRN_MDL_NAME_{I_OR_L}']}",f"{cfg_bcs[f'FV3GFS_FILE_FMT_{I_OR_L}']}",
                f"${{yyyymmddhh}}")
    else:
        cfg_bcs[f'EXTRN_MDL_SOURCE_BASEDIR_{I_OR_L}'] = \
                os.path.join(f"{mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}",
                f"{cfg_bcs[f'EXTRN_MDL_NAME_{I_OR_L}']}/${{yyyymmddhh}}")

    return cfg_bcs

def setup_logging(logfile: str = "log.run_WE2E_tests", debug: bool = False) -> None:
    """
    Sets up logging, prints high-priority (INFO and higher) messages to screen, and prints all
    messages with detailed timing and routine info to the specified text file.

    Args:
        logfile  (str): Name of the test logging file (default: ``log.run_WE2E_tests``)
        debug   (bool): Set to True for more detailed output/information
    Returns:
        None
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

    # Check python version and presence of some non-standard packages
    check_python_version()

    #Get the "Home" directory, two levels above this one
    homedir=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    LOGFILE='log.run_WE2E_tests'

    #Parse arguments
    ap = argparse.ArgumentParser(epilog="For more information about config arguments (denoted "\
                                            "in CAPS), see ush/config_defaults.yaml\n")
    # Create a group for optional arguments so they can be listed after required args
    optional = ap._action_groups.pop()
    required = ap.add_argument_group('required arguments')

    required.add_argument('-m', '--machine', type=str,
                          help='Machine name; see ush/machine/ for valid values', required=True)
    required.add_argument('-a', '--account', type=str,
                          help='Account name for running submitted jobs', required=True)
    required.add_argument('-t', '--tests', type=str, nargs="*",
                          help="""Can be one of three options (in order of priority):
    1. A test name or list of test names.
    2. A test suite name ("fundamental", "comprehensive", "coverage", or "all")
    3. The name of a file (full or relative path) containing a list of test names.
    """, required=True)

    ap.add_argument('-c', '--compiler', type=str,
                    help='Compiler used for building the app', default='intel')
    ap.add_argument('-d', '--debug', action='store_true',
                    help='Script will be run in debug mode with more verbose output. ' +
                         'WARNING: increased verbosity may run very slow on some platforms')
    ap.add_argument('-q', '--quiet', action='store_true',
                    help='Suppress console output from workflow generation; this will help '\
                         'keep the screen uncluttered')
    ap.add_argument('-p', '--procs', type=int,
                    help='Run resource-heavy tasks (such as calls to rocotorun) in parallel, '\
                         'with provided number of parallel tasks', default=1)
    ap.add_argument('-l', '--launch', type=str, choices=['python', 'cron', 'none'],
                    help='Method for launching jobs. Valid values are:\n'\
                         ' python: [default] Monitor and launch experiments using monitor_jobs.py\n'
                         ' cron:   Launch expts using ush/launch_FV3LAM_wflow.sh from crontab\n'\
                         ' none:   Do not launch experiments; only create experiment directories',
                         default="python")


    ap.add_argument('--modulefile', type=str, help='Modulefile used for building the app')
    ap.add_argument('--run_envir', type=str,
                    help='Overrides RUN_ENVIR variable to a new value ("nco" or "community") '\
                         'for all experiments', default='')
    ap.add_argument('--expt_basedir', type=str,
                    help='Explicitly set EXPT_BASEDIR for all experiments')
    ap.add_argument('--exec_subdir', type=str,
                    help='Explicitly set EXEC_SUBDIR for all experiments')
    ap.add_argument('--use_cron_to_relaunch', action='store_true',
                    help='DEPRECATED; DO NOT USE. See "launch" option.')
    ap.add_argument('--cron_relaunch_intvl_mnts', type=int,
                    help='Overrides CRON_RELAUNCH_INTVL_MNTS for all experiments')
    ap.add_argument('--print_test_info', action='store_true',
                    help='Create a "WE2E_test_info.txt" file summarizing each test prior to'\
                         'starting experiment')
    ap.add_argument('--debug_tests', action='store_true',
                    help='Explicitly set DEBUG=TRUE for all experiments')
    ap.add_argument('--verbose_tests', action='store_true',
                    help='Explicitly set VERBOSE=TRUE for all experiments')

    ap._action_groups.append(optional)

    args = ap.parse_args()

    # Exit for deprecated options
    if args.use_cron_to_relaunch:
        raise ValueError("\nWARNING: The argument --use_cron_to_relaunch has been superseded by "\
                        "--launch=cron\nPlease update your workflow accordingly")

    #Set defaults that need other argument values
    if args.modulefile is None:
        args.modulefile = f'build_{args.machine.lower()}_{args.compiler}'
    if args.procs < 1:
        raise argparse.ArgumentTypeError('You can not have less than one parallel process; select a valid value '\
                         'for --procs')
    if not args.tests:
        raise argparse.ArgumentTypeError('The --tests argument can not be empty')

    # Print test details (if requested)
    if args.print_test_info:
        print_test_info()
    #Call main function

    try:
        run_we2e_tests(homedir,args)
    except:
        logging.exception(
            dedent(
                f"""
                *********************************************************************
                FATAL ERROR:
                Experiment generation failed. See the error message(s) printed below.
                For more detailed information, check the log file from the workflow
                generation script: {LOGFILE}
                *********************************************************************\n
                """
            )
        )
