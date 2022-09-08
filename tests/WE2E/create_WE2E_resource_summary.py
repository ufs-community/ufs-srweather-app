'''
Generate a summary of resources used for the WE2E test suite.

Examples:

    To print usage

      python create_WE2E_resource_summary.py
      python create_WE2E_resource_summary.py -h

    To print a report for all the experiments in an experiment directory

      python create_WE2E_resource_summary.py -e /path/to/expt_dir

    To print a report for all the grid_* and nco_* experiments.

      python create_WE2E_resource_summary.py -e /path/to/expt_dir \
        -n 'grid*' 'nco*'

    To compute a total estimated cost for all experiments on instances that are
    $0.15 per core hour.

      python create_WE2E_resource_summary.py -e /path/to/expt_dir -c $0.15

Information about the output summary.

 - The core hours are an underestimate in many cases.
   - Multiple tries are not captured.
   - The use of a portion of a node or instance is not known. If the whole node
     is used, but isn't reflected in the core count, the cores are not counted.
     Partition information is not stored in the database, so mapping to a given
     node type becomes ambiguous.

     For example, jobs that request 4 nodes with 2 processors per node with an
     --exclusive flag will underestimate the total core hour usage by a factor
     of 20 when using a 40 processor node.

 - When computing cost per job, it will also provide an underestimate for the
   reasons listed above.
 - Only one cost will be applied across all jobs. Rocoto jobs do not store
   partition information in the job table, so was not included as an option here.

'''

import argparse
import glob
import os
import sys
import sqlite3

REPORT_WIDTH = 110

def parse_args(argv):


    '''
    Function maintains the arguments accepted by this script. Please see
    Python's argparse documenation for more information about settings of each
    argument.
    '''

    parser = argparse.ArgumentParser(
        description="Generate a usage report for a set of SRW experiments."
        )

    parser.add_argument(
        '-e', '--expt_path',
        help='The path to the directory containing the experiment \
        directories',
        )
    parser.add_argument(
        '-n', '--expt_names',
        default=['*'],
        help='A list of experiments to generate the report for. Wildcards \
        accepted by glob.glob may be used. If not provided, a report will be \
        generated for all experiments in the expt_path that have a Rocoto \
        database',
        nargs='*',
        )

    # Optional
    parser.add_argument(
        '-c', '--cost_per_core_hour',
        help='Provide the cost per core hour for the instance type used. \
        Only supports homogenous clusters.',
        type=float,
        )

    return parser.parse_args(argv)

def get_workflow_info(db_path):

    ''' Given the path to a Rocoto database, return the total number of tasks,
    core hours and wall time for the workflow. '''

    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # jobs schema is:
    # (id INTEGER PRIMARY KEY, jobid VARCHAR(64), taskname VARCHAR(64), cycle
    # DATETIME, cores INTEGER, state VARCHAR(64), native_state VARCHAR[64],
    # exit_status INTEGER, tries INTEGER, nunknowns INTEGER, duration REAL)
    #
    # an example:
    # 5|66993580|make_sfc_climo|1597017600|48|SUCCEEDED|COMPLETED|0|1|0|83.0
    try:
        cur.execute('SELECT cores, duration from jobs')
    except sqlite3.OperationalError:
        return 0, 0, 0

    workflow_info = cur.fetchall()

    core_hours = 0
    wall_time = 0
    ntasks = 0
    for cores, duration in workflow_info:
        core_hours += cores * duration / 3600
        wall_time += duration / 60
        ntasks += 1

    return ntasks, core_hours, wall_time


def fetch_expt_summaries(expts):

    ''' Get the important information from the database of each experiment, and
    return a list, sorted by experiment name. '''

    summaries = []
    for expt in expts:
        test_name = expt.split('/')[-1]
        db_path = os.path.join(expt, 'FV3LAM_wflow.db')
        if not os.path.exists(db_path):
            print(f'No FV3LAM_wflow.db exists for expt: {test_name}')
            continue
        ntasks, core_hours, wall_time = get_workflow_info(db_path)
        summaries.append((test_name, ntasks, core_hours, wall_time))

    return sorted(summaries)

def generate_report(argv):

    ''' Given user arguments, print a summary of the requested experiments'
    usage information, including cost (if requested). '''

    cla = parse_args(argv)

    experiments = []
    for expt in cla.expt_names:
        experiments.extend(glob.glob(
            os.path.join(cla.expt_path, expt)
            ))

    header = f'{" "*60} Core Hours  |  Run Time (mins)'
    if cla.cost_per_core_hour:
        header = f'{header}  |  Est. Cost ($) '

    print('-'*REPORT_WIDTH)
    print('-'*REPORT_WIDTH)
    print(header)
    print('-'*REPORT_WIDTH)

    total_ch = 0
    total_cost = 0
    for name, ntasks, ch, wt in fetch_expt_summaries(experiments):
        line = f'{name[:60]:<60s} {ch:^12.2f} {wt:^20.1f}'
        if cla.cost_per_core_hour:
            cost = ch * cla.cost_per_core_hour
            line = f'{line}   ${cost:<.2f}'
            total_cost += cost
        total_ch += ch
        print(line)

    print('-'*REPORT_WIDTH)
    print(f'TOTAL CORE HOURS: {total_ch:6.2f}')
    if cla.cost_per_core_hour:
        print(f'TOTAL COST: ${cla.cost_per_core_hour * total_ch:6.2f}')

    print('*'*REPORT_WIDTH)
    print('WARNING: This data reflects only the job information from the last',
          'logged try. It does not account for the use \n of an entire node, only', 
          'the actual cores requested. It may provide an underestimate of true compute usage.')
    print('*'*REPORT_WIDTH)


if __name__ == "__main__":
    generate_report(sys.argv[1:])
