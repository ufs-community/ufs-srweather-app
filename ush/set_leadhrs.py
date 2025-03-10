#!/usr/bin/env python3
import argparse
import os
from eval_metplus_timestr_tmpl import eval_metplus_timestr_tmpl

def set_leadhrs(date_init, lhr_min, lhr_max, lhr_intvl, base_dir, time_lag, fn_template, num_missing_files_max,
                skip_check_files=False, verbose=False):
    """
    Creates a list of lead hours based on the provided range and interval, 
    checks for the existence of corresponding files, and returns a list 
    of lead hours for which files exist. If too many files are missing, it fails with an exception.

    Args:
        date_init             (str): Date string for initial time in YYYYMMDD[mmss] format, where
                                     minutes and seconds are optional.
        lhr_min               (int): Minimum lead hour to check
        lhr_max               (int): Maximum lead hour to check
        lhr_intvl             (int): Interval between lead hours
        base_dir              (str): Base directory for forecast/observation file
        time_lag              (int): Hours of time lag for a time-lagged ensemble member
        fn_template           (str): The METplus filename template for finding the files
        verbose              (bool): By default this script only outputs the list of forecast hours
                                     (for easier parsing from bash contexts). Set the verbose flag
                                     to True for additional debugging output.
        num_missing_files_max (int): If more files than this value are not found, raise exception
        skip_check_files     (bool): If true, return the list of forecast hours, skipping the file check
    Returns:
        A list of forecast hours where files were found
    """

    # Step 1: Generate lead hours without filtering for missing files
    lhrs_list = list(range(lhr_min, lhr_max + 1, lhr_intvl))
    if verbose:
        print(f"Initial set of lead hours (relative to {date_init}): {lhrs_list}")

    if skip_check_files:
        return lhrs_list

    # Since calls to this script from bash do not allow us to print to screen,
    # save alerts about missing files and only print in case of an exception
    errmsg=''

    # Step 2: Loop through lead hours and check for corresponding file existence
    final_list = []
    num_missing_files = 0
    for lhr in lhrs_list:

        # Evaluate the METplus timestring template for the current lead hour
        fn = eval_metplus_timestr_tmpl(date_init, lhr, time_lag, fn_template, verbose=False)

        # Get the full path and check if the file exists
        fp = os.path.join(base_dir, fn)
        if os.path.isfile(fp):
            if verbose:
                print(f"Found file for lead hour {lhr} (relative to {date_init}): {fp}")
            final_list.append(lhr)
        else:
            num_missing_files += 1
            newerrmsg = f"File for lead hour {lhr} (relative to {date_init}) is MISSING: {fp}"
            if verbose:
                print(newerrmsg)
            else:
                errmsg = "\n".join([errmsg, newerrmsg])

    if verbose:
        print(f"Final set of lead hours relative to {date_init}: {final_list}")

    # Step 3: Check if the number of missing files exceeds the maximum allowed
    if num_missing_files > num_missing_files_max:
        raise Exception(f"{errmsg}\nNumber of missing files ({num_missing_files}) exceeds maximum allowed ({num_missing_files_max}).")

    return final_list

if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Print a list of forecast hours in bash-readable comma-separated format such that there is a corresponding file (can be observations or forecast files) for each list entry.",
    )
    parser.add_argument("-v", "--verbose", help="Verbose output", action="store_true")
    parser.add_argument("-d", "--date_init", help="Initial date in YYYYMMDDHH[mmss] format", type=str, default='')
    parser.add_argument("-min", "--lhr_min", help="Minimum lead hour to check", type=int, required=True)
    parser.add_argument("-max", "--lhr_max", help="Maximum lead hour to check", type=int, required=True)
    parser.add_argument("-int", "--lhr_intvl", help="Interval between lead hours", type=int, required=True)
    parser.add_argument("-tl", "--time_lag", help="Hours of time lag for a time-lagged ensemble member", type=int, default=0)
    parser.add_argument("-bd", "--base_dir", help="Base directory for forecast/observation file", type=str, default='')
    parser.add_argument("-ft", "--fn_template", help="Template for file names to search; see ??? for details on template settings", type=str, default='')
    parser.add_argument("-n", "--num_missing_files_max", type=int, default=5,
                        help="Number of missing files to tolerate; if more files than this number can not be found, raise an exception")
    parser.add_argument("-s", "--skip_check_files", action="store_true",
                        help="Flag to skip file check and just return the list of lead hours") 

    args = parser.parse_args()

    #Consistency checks
    if not args.skip_check_files and not args.date_init:
        raise argparse.ArgumentTypeError('--date_init must be specified unless --skip_check_files is specified')

    leadhr_list = set_leadhrs(**vars(args))
    # If called from command line, we want to print a bash-parsable list
    print(', '.join(str(x) for x in leadhr_list))
