#!/usr/bin/env python3

import os
import sys
import glob
import argparse
import logging
from textwrap import dedent

sys.path.append("../../ush")

from generate_FV3LAM_wflow import generate_FV3LAM_wflow
from python_utils import (
    cfg_to_yaml_str,
    load_config_file,
)

from check_python_version import check_python_version

from monitor_jobs import monitor_jobs


def run_we2e_tests(homedir, args) -> None:
    """Function to run the WE2E tests selected by the user

    Args:
        homedir  (str): The full path of the top-level app directory
        args : The argparse.Namespace object containing command-line arguments
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
                alltests = glob.glob('test_configs/**/config*.yaml', recursive=True)
                tests_to_check = []
                for f in alltests:
                    filename = os.path.basename(f)
                    # We just want the test namein this list, so cut out the "config." prefix and ".yaml" extension
                    tests_to_check.append(filename[7:-5])
                logging.debug(f"Will check all tests:\n{tests_to_check}")
            elif user_spec_tests[0] in ['fundamental', 'comprehensive']:
                # I am writing this section of code under protest; we should use args.run_envir to check for run_envir-specific files!
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
                            logging.debug(f'{testfilename} exists for this platform and run_envir has not been specified'\
                                           'Setting run_envir = {run_envir} for all tests')
                else:
                    if not run_envir:
                        run_envir = 'nco'
                        logging.debug(f'{testfilename} exists for this platform and run_envir has not been specified'\
                                       'Setting run_envir = {run_envir} for all tests')
                logging.debug(f"Reading test file: {testfilename}")
                with open(testfilename) as f:
                    tests_to_check = [x.rstrip() for x in f]
                logging.debug(f"Will check {user_spec_tests[0]} tests:\n{tests_to_check}")
            else:
                # If we have gotten this far then the only option left for user_spec_tests is a file containing test names
                logging.debug(f'Checking if {user_spec_tests} is a file containing test names')
                if os.path.isfile(user_spec_tests[0]):
                    with open(user_spec_tests[0]) as f:
                        tests_to_check = [x.rstrip() for x in f]
                else:
                    raise FileNotFoundError(dedent(f"""
                    The specified 'tests' argument '{user_spec_tests}'
                    does not appear to be a valid test name, a valid test suite, or a file containing valid test names.

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
    if not args.use_cron_to_relaunch:
        monitor_yaml = dict()

    for test in tests_to_run:
        #Starting with test yaml template, fill in user-specified and machine- and
        # test-specific options, then write resulting complete config.yaml
        test_name = os.path.basename(test).split('.')[1]
        logging.debug(f"For test {test_name}, constructing config.yaml")
        test_cfg = load_config_file(test)

        test_cfg['user'].update({"MACHINE": machine})
        test_cfg['user'].update({"ACCOUNT": args.account})
        if run_envir:
            test_cfg['user'].update({"RUN_ENVIR": run_envir})
            if run_envir == "nco":
                if 'nco' not in test_cfg:
                    test_cfg['nco'] = dict()
                test_cfg['nco'].update({"model_ver": "we2e"})
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
        if args.use_cron_to_relaunch:
            test_cfg['workflow'].update({"USE_CRON_TO_RELAUNCH": args.use_cron_to_relaunch})
        if args.cron_relaunch_intvl_mnts:
            test_cfg['workflow'].update({"CRON_RELAUNCH_INTVL_MNTS": args.cron_relaunch_intvl_mnts})
        if args.debug_tests:
            test_cfg['workflow'].update({"DEBUG": args.debug_tests})
        if args.verbose_tests:
            test_cfg['workflow'].update({"VERBOSE": args.verbose_tests})

        logging.debug(f"Overwriting WE2E-test-specific settings for test \n{test_name}\n")

        if 'task_get_extrn_ics' in test_cfg:
            logging.debug(test_cfg['task_get_extrn_ics'])
            test_cfg['task_get_extrn_ics'] = check_task_get_extrn_ics(test_cfg,machine_defaults,config_defaults)
            logging.debug(test_cfg['task_get_extrn_ics'])
        if 'task_get_extrn_lbcs' in test_cfg:
            logging.debug(test_cfg['task_get_extrn_lbcs'])
            test_cfg['task_get_extrn_lbcs'] = check_task_get_extrn_lbcs(test_cfg,machine_defaults,config_defaults)
            logging.debug(test_cfg['task_get_extrn_lbcs'])

        if 'verification' in test_cfg:
            logging.debug(test_cfg['verification'])
            test_cfg['verification'] = check_task_verification(test_cfg,machine_defaults,config_defaults)
            logging.debug(test_cfg['verification'])

        logging.debug(f"Writing updated config.yaml for test {test_name}\nbased on specified command-line arguments:\n")
        logging.debug(cfg_to_yaml_str(test_cfg))
        with open(ushdir + "/config.yaml","w") as f:
            f.writelines(cfg_to_yaml_str(test_cfg))

        logging.info(f"Calling workflow generation function for test {test_name}\n")
        if args.quiet:
            console_handler = logging.getLogger().handlers[1]
            console_handler.setLevel(logging.WARNING)
        expt_dir = generate_FV3LAM_wflow(ushdir,logfile=f"{ushdir}/log.generate_FV3LAM_wflow",debug=args.debug)
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
            monitor_yaml[test_name] = dict()
            monitor_yaml[test_name].update({"expt_dir": expt_dir})
            monitor_yaml[test_name].update({"status": "CREATED"})

    if not args.use_cron_to_relaunch:
        logging.info("calling function that monitors jobs, prints summary")
        monitor_file = monitor_jobs(monitor_yaml, debug=args.debug)

        logging.info("All experiments are complete")
        logging.info(f"Summary of results available in {monitor_file}")





def check_tests(tests: list) -> list:
    """
    Function for checking that all tests in a provided list of tests are valid

    Args:
        tests        : List of potentially valid test names
    Returns:
        tests_to_run : List of config files corresponding to test names
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
        match = check_test(test)
        if not match:
            raise Exception(f"Could not find test {test}")
        tests_to_run.append(match)
    # Because some test files are symlinks to other tests, check that we don't
    # include the same test twice
    for testfile in tests_to_run.copy():
        if os.path.islink(testfile):
            if os.path.realpath(testfile) in tests_to_run:
                logging.warning(dedent(f"""WARNING: test file {testfile} is a symbolic link to a
                                test file ({os.path.realpath(testfile)}) that is also included in the
                                test list. Only the latter test will be run."""))
                tests_to_run.remove(testfile)
    if len(tests_to_run) != len(set(tests_to_run)):
        logging.warning("\nWARNING: Duplicate test names were found in list. Removing duplicates and continuing.\n")
        tests_to_run = list(set(tests_to_run))
    return tests_to_run



def check_test(test: str) -> str:
    """
    Function for checking that a string corresponds to a valid test name

    Args:
        test (str) : String of potential test name
    Returns:
        str        : File name of test config file (empty string if no test file found)
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


def check_task_get_extrn_ics(cfg: dict, mach: dict, dflt: dict) -> dict:
    """
    Function for checking and updating various settings in task_get_extrn_ics section of test config yaml

    Args:
        cfg  : Dictionary loaded from test config file
        mach : Dictionary loaded from machine settings file
        dflt : Dictionary loaded from default config file
    Returns:
        cfg_ics : Updated dictionary for task_get_extrn_ics section of test config
    """

    #Make our lives easier by shortening some dictionary calls
    cfg_ics = cfg['task_get_extrn_ics']

    # If RUN_TASK_GET_EXTRN_ICS is explicitly set to false, do nothing and return
    if 'workflow_switches' in cfg:
        if 'RUN_TASK_GET_EXTRN_ICS' in cfg['workflow_switches']:
            if cfg['workflow_switches']['RUN_TASK_GET_EXTRN_ICS'] is False:
                return cfg_ics

    # If USE_USER_STAGED_EXTRN_FILES not specified or false, do nothing and return
    if not cfg_ics.get('USE_USER_STAGED_EXTRN_FILES'):
        logging.debug(f'USE_USER_STAGED_EXTRN_FILES not specified or False in task_get_extrn_ics section of config')
        return cfg_ics

    # If EXTRN_MDL_SYSBASEDIR_ICS is "set_to_non_default_location_in_testing_script", replace with test value from machine file
    if cfg_ics.get('EXTRN_MDL_SYSBASEDIR_ICS') == "set_to_non_default_location_in_testing_script":
        if 'TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS' in mach['platform']:
            if os.path.isdir(mach['platform']['TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS']):
                raise FileNotFoundError(f"Non-default input file location TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS from machine file does not exist or is not a directory")
            cfg_ics['EXTRN_MDL_SYSBASEDIR_ICS'] = mach['platform']['TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS']
        else:
            raise KeyError(f"Non-default input file location TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS not set in machine file")
        return cfg_ics

    # Because USE_USER_STAGED_EXTRN_FILES is true, only look on disk, and ensure the staged data directory exists
    cfg['platform']['EXTRN_MDL_DATA_STORES'] = "disk"
    if 'TEST_EXTRN_MDL_SOURCE_BASEDIR' not in mach['platform']:
        raise KeyError("TEST_EXTRN_MDL_SOURCE_BASEDIR, the directory for staged test data,"\
                       "has not been specified in the machine file for this platform")
    if not os.path.isdir(mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']):
        raise FileNotFoundError(dedent(f"""The directory for staged test data specified in this platform's machine file
                                TEST_EXTRN_MDL_SOURCE_BASEDIR = {mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}
                                does not exist."""))

    # Different input data types have different directory structures, so set the data directory accordingly
    if cfg_ics['EXTRN_MDL_NAME_ICS'] == 'FV3GFS':
        if 'FV3GFS_FILE_FMT_ICS' not in cfg_ics:
            cfg_ics['FV3GFS_FILE_FMT_ICS'] = dflt['task_get_extrn_ics']['FV3GFS_FILE_FMT_ICS']
        cfg_ics['EXTRN_MDL_SOURCE_BASEDIR_ICS'] = f"{mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}/"\
                                                  f"{cfg_ics['EXTRN_MDL_NAME_ICS']}/{cfg_ics['FV3GFS_FILE_FMT_ICS']}/${{yyyymmddhh}}"
    else:
        cfg_ics['EXTRN_MDL_SOURCE_BASEDIR_ICS'] = f"{mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}/"\
                                                  f"{cfg_ics['EXTRN_MDL_NAME_ICS']}/${{yyyymmddhh}}"

    return cfg_ics

def check_task_get_extrn_lbcs(cfg: dict, mach: dict, dflt: dict) -> dict:
    """
    Function for checking and updating various settings in task_get_extrn_lbcs section of test config yaml

    Args:
        cfg  : Dictionary loaded from test config file
        mach : Dictionary loaded from machine settings file
        dflt : Dictionary loaded from default config file
    Returns:
        cfg_lbcs : Updated dictionary for task_get_extrn_lbcs section of test config
    """

    #Make our lives easier by shortening some dictionary calls
    cfg_lbcs = cfg['task_get_extrn_lbcs']

    # If RUN_TASK_GET_EXTRN_LBCS is explicitly set to false, do nothing and return
    if 'workflow_switches' in cfg:
        if 'RUN_TASK_GET_EXTRN_LBCS' in cfg['workflow_switches']:
            if cfg['workflow_switches']['RUN_TASK_GET_EXTRN_LBCS'] is False:
                return cfg_lbcs

    # If USE_USER_STAGED_EXTRN_FILES not specified or false, do nothing and return
    if not cfg_lbcs.get('USE_USER_STAGED_EXTRN_FILES'):
        logging.debug(f'USE_USER_STAGED_EXTRN_FILES not specified or False in task_get_extrn_lbcs section of config')
        return cfg_lbcs

    # If EXTRN_MDL_SYSBASEDIR_LBCS is "set_to_non_default_location_in_testing_script", replace with test value from machine file
    if cfg_lbcs.get('EXTRN_MDL_SYSBASEDIR_LBCS') == "set_to_non_default_location_in_testing_script":
        if 'TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS' in mach['platform']:
            if os.path.isdir(mach['platform']['TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS']):
                raise FileNotFoundError(f"Non-default input file location TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS from machine file does not exist or is not a directory")
                cfg_lbcs['EXTRN_MDL_SYSBASEDIR_LBCS'] = mach['platform']['TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS']
        else:
            raise KeyError(f"Non-default input file location TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS not set in machine file")
        return cfg_lbcs

    # Because USE_USER_STAGED_EXTRN_FILES is true, only look on disk, and ensure the staged data directory exists
    cfg['platform']['EXTRN_MDL_DATA_STORES'] = "disk"
    if 'TEST_EXTRN_MDL_SOURCE_BASEDIR' not in mach['platform']:
        raise KeyError("TEST_EXTRN_MDL_SOURCE_BASEDIR, the directory for staged test data,"\
                       "has not been specified in the machine file for this platform")
    if not os.path.isdir(mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']):
        raise FileNotFoundError(dedent(f"""The directory for staged test data specified in this platform's machine file
                                TEST_EXTRN_MDL_SOURCE_BASEDIR = {mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}
                                does not exist."""))

    # Different input data types have different directory structures, so set the data directory accordingly
    if cfg_lbcs['EXTRN_MDL_NAME_LBCS'] == 'FV3GFS':
        if 'FV3GFS_FILE_FMT_LBCS' not in cfg_lbcs:
            cfg_lbcs['FV3GFS_FILE_FMT_LBCS'] = dflt['task_get_extrn_lbcs']['FV3GFS_FILE_FMT_LBCS']
        cfg_lbcs['EXTRN_MDL_SOURCE_BASEDIR_LBCS'] = f"{mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}/"\
                                                    f"{cfg_lbcs['EXTRN_MDL_NAME_LBCS']}/{cfg_lbcs['FV3GFS_FILE_FMT_LBCS']}/${{yyyymmddhh}}"
    else:
        cfg_lbcs['EXTRN_MDL_SOURCE_BASEDIR_LBCS'] = f"{mach['platform']['TEST_EXTRN_MDL_SOURCE_BASEDIR']}/"\
                                                    f"{cfg_lbcs['EXTRN_MDL_NAME_LBCS']}/${{yyyymmddhh}}"

    return cfg_lbcs

def check_task_verification(cfg: dict, mach: dict, dflt: dict) -> dict:
    """
    Function for checking and updating various settings in verification section of test config yaml

    Args:
        cfg  : Dictionary loaded from test config file
        mach : Dictionary loaded from machine settings file
        dflt : Dictionary loaded from default config file
    Returns:
        cfg_vx : Updated dictionary for verification section of test config
    """

    # Make our lives easier by shortening some dictionary calls
    if 'verification' in cfg:
        cfg_vx = cfg['verification']
    else:
        cfg_vx = dict()

    # If VX_FCST_INPUT_BASEDIR is already explicitly set in the test configuration
    # dictionary, keep that value and just return.
    if 'VX_FCST_INPUT_BASEDIR' in cfg_vx:
        return cfg_vx

    # Attempt to obtain the values of RUN_TASK_RUN_FCST, WRITE_DO_POST, and RUN_TASK_RUN_POST
    # from the test configuration dictionary.  If not available there, get them from the default 
    # configuration dictionary.
    flags = {'RUN_TASK_RUN_FCST': False, 'WRITE_DOPOST': False, 'RUN_TASK_RUN_POST': False}
    for section in ['workflow_switches', 'task_run_fcst']:
        for flag in flags:
            if (section in cfg) and (flag in cfg[section]):
                flags[flag] = cfg[section][flag]
            elif flag in dflt[section]:
                flags[flag] = dflt[section][flag]

    # If UPP is going to be run (either in-line or as a separate set of tasks), set the
    # VX_FCST_INPUT_BASEDIR to the default directory for the experiment.  Otherwise, set
    # it to the value of TEST_VX_FCST_INPUT_BASEDIR in the machine file.
    if (flags['RUN_TASK_RUN_FCST'] and flags['WRITE_DOPOST']) or flags['RUN_TASK_RUN_POST']:
        cfg_vx['VX_FCST_INPUT_BASEDIR'] = dflt['workflow']['EXPTDIR']
    else:
        if 'TEST_VX_FCST_INPUT_BASEDIR' in mach['platform']:
            cfg_vx['VX_FCST_INPUT_BASEDIR'] = mach['platform']['TEST_VX_FCST_INPUT_BASEDIR']
        else:
            raise KeyError(f"Non-default forecast file location for verification (TEST_VX_FCST_INPUT_BASEDIR) not set in machine file")

    return cfg_vx

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

    # Check python version and presence of some non-standard packages
    check_python_version()

    #Get the "Home" directory, two levels above this one
    homedir=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    logfile='log.run_WE2E_tests'

    #Parse arguments
    parser = argparse.ArgumentParser(epilog="For more information about config arguments (denoted in CAPS), see ush/config_defaults.yaml\n")
    optional = parser._action_groups.pop() # Create a group for optional arguments so they can be listed after required args
    required = parser.add_argument_group('required arguments')

    required.add_argument('-m', '--machine', type=str, help='Machine name; see ush/machine/ for valid values', required=True)
    required.add_argument('-a', '--account', type=str, help='Account name for running submitted jobs', required=True)
    required.add_argument('-t', '--tests', type=str, nargs="*", help="""Can be one of three options (in order of priority):
    1. A test name or list of test names.
    2. A test suite name ("fundamental", "comprehensive", or "all")
    3. The name of a file (full or relative path) containing a list of test names.
    """, required=True)

    parser.add_argument('-c', '--compiler', type=str, help='Compiler used for building the app', default='intel')
    parser.add_argument('-d', '--debug', action='store_true', help='Script will be run in debug mode with more verbose output')
    parser.add_argument('-q', '--quiet', action='store_true', help='Suppress console output from workflow generation; this will help keep the screen uncluttered')


    parser.add_argument('--modulefile', type=str, help='Modulefile used for building the app')
    parser.add_argument('--run_envir', type=str, help='Overrides RUN_ENVIR variable to a new value ( "nco" or "community" ) for all experiments', default='')
    parser.add_argument('--expt_basedir', type=str, help='Explicitly set EXPT_BASEDIR for all experiments')
    parser.add_argument('--exec_subdir', type=str, help='Explicitly set EXEC_SUBDIR for all experiments')
    parser.add_argument('--use_cron_to_relaunch', action='store_true', help='Explicitly set USE_CRON_TO_RELAUNCH for all experiments; this option disables the "monitor" script functionality')
    parser.add_argument('--cron_relaunch_intvl_mnts', type=str, help='Overrides CRON_RELAUNCH_INTVL_MNTS for all experiments')
    parser.add_argument('--debug_tests', action='store_true', help='Explicitly set DEBUG=TRUE for all experiments')
    parser.add_argument('--verbose_tests', action='store_true', help='Explicitly set VERBOSE=TRUE for all experiments')

    parser._action_groups.append(optional)

    args = parser.parse_args()

    #Set defaults that need other argument values
    if args.modulefile is None:
        args.modulefile = f'build_{args.machine.lower()}_{args.compiler}'

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
                generation script: {logfile}
                *********************************************************************\n
                """
            )
        )
