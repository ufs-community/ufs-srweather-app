import os, shutil
from datetime import datetime
import glob
import argparse

def select_validtime_obs(valid_time, outdir, source, in_template, out_template, window=900, debug=False):
    """Identifies the observation file closest to the valid time of the forecast.
    For observation types with irregular observation times (MRMS, GOES), obs
    files do not always exactly match the valid time. This script is used to identify and rename
    these files to match the valid time of the forecast.

    The "template" variables represent special templates for the expected filename of the
    observation containing a date/time string (in_template) and the output filename. The date/time
    template should be contained in brackets [] and using expected python date codes. For example,
    MRMS echo top files are named like

        EchoTop_18_00.50_20240111-000034.grib2.gz

    where the date and time of the observation file is 2024-01-11, 00:00:34. The "in_template"
    for this observation type should therefore be:

        EchoTop_18_00.50_[%Y%m%d-%H%M%S].grib2.gz

    Globbables are allowed for "in_template" but not "out_template". For example, GOES AOD files
    have names like

        OR_ABI-L2-AODF-M6_G16_s20240180620209_e20240180629517_c20240180630532.nc

    where the filenames contain multiple date strings and other information that may change for
    different data sources. For this specific filename, a valid "in_template" would be

        OR_ABI-L2-AODF_[%Y%j%H%M%S]*.nc

    Be sure that any "in_template" value can be unambiguously globbed, otherwise unexpected results
    may occur.



    Returns:
        string: The staged filename
        
    Raises: 
        FileNotFoundError: If no valid file was found within "window" seconds of the valid 
                           time of the forecast

    """

    # Copy and unzip MRMS files that are closest to top of hour
    # Done every hour on a 20-minute lag

    valid = datetime.strptime(valid_time,"%Y%m%d%H")

    print(f"Searching for observation file {in_template} for valid time: {valid_time}")

    # Split in_template around date

    template_start, template = in_template.split('[')
    date_template, template_end = template.split(']')

    # Set up working directory

    if not os.path.exists(outdir):
        os.makedirs(outdir)

    # Sort list of files
    file_list = [f for f in glob.glob(os.path.join(source, f'{template_start}*{template_end}'))]
    if debug:
        print(f"Valid date: {valid}")
        print(f"Searching list of files:\n{file_list}")

    # Find the length of the date string given the input template
    lendate = len(datetime.now().strftime(date_template))
    time_list=[]
    i=0
    for afile in file_list:
        datestring=os.path.basename(file_list[i])[len(template_start):len(template_start)+lendate]
        print(f"Extracting time from {datestring} with template {date_template}")
        time_list.append(datetime.strptime(datestring,date_template))
        i+=1
    # Find the file closest to the valid time
    closest_timestamp = min(
        time_list, key=lambda date: abs(valid - date)
    )

    # Check to make sure closest file is within +/- window seconds of top of the hour
    difference = abs(closest_timestamp - valid)
    if difference.total_seconds() <= window:
        filename1 = f"{template_start}{closest_timestamp.strftime(date_template)}{template_end}"
        filename2 = datetime.strftime(valid,out_template)
        origfile = glob.glob(os.path.join(source, filename1))[0]
        target = os.path.join(outdir, filename2)
        if debug:
            print(f"Time difference between valid time ({valid})")
            print(f"and closest file {filename1} is {difference.total_seconds()} seconds")

        print(f"Moving file {origfile} to {target}")
        shutil.move(origfile,target)
        
    else:
        raise FileNotFoundError(f"Did not find a valid file within {window} seconds of {valid}")

    return target

if __name__ == "__main__":
    #Parse input arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--valid_time', type=str, required=True,
                        help='Valid time (in string format YYYYMMDDHH) to find obs data for')
    parser.add_argument('-o', '--outdir', type=str, required=True,
                        help='Destination directory for obs file`')
    parser.add_argument('-s', '--source', type=str, required=True,
                        help='Source directory where input obs files are found')
    parser.add_argument('-it', '--in_template', type=str, required=True,
                        help='Template for input filename; see docstring for details')
    parser.add_argument('-ot', '--out_template', type=str, required=True,
                        help='Template for outpu filename; see docstring for details')
    parser.add_argument('-w', '--window', type=int, help='Time in seconds to check for obs file +/- the valid time',
                        default=900)
    parser.add_argument('-d', '--debug', action='store_true', help='Add additional debug output')
    args = parser.parse_args()

    #Consistency checks

    staged_file = select_validtime_obs(**vars(args))
    print (f'Staged file: {staged_file}')
