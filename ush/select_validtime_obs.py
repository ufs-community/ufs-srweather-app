import os, shutil
import datetime
import glob
import argparse
import bisect

def select_validtime_obs(valid_time, outdir, source, product, window=900, level='', debug=False):
    """Identifies the observation file closest to the valid time of the forecast.
    For observation types with irregular observation times (MRMS, GOES), obs
    files do not always exactly match the valid time. This script is used to identify and rename
    these files to match the valid time of the forecast.

    Returns:
        string: The staged filename
        
    Raises: 
        FileNotFoundError: If no valid file was found within "window" seconds of the valid 
                           time of the forecast

    """

    # Copy and unzip MRMS files that are closest to top of hour
    # Done every hour on a 20-minute lag

    YYYY = int(valid_time[0:4])
    MM = int(valid_time[4:6])
    DD = int(valid_time[6:8])
    HH = int(valid_time[8:19])

    valid = datetime.datetime(YYYY, MM, DD, HH, 0, 0)
    valid_str = valid.strftime("%Y%m%d")

    print(f"Pulling MRMS product {product} for valid time: {valid_time}")

    # Set up working directory

    if not os.path.exists(outdir):
        os.makedirs(outdir)

    # Sort list of files for each MRMS product
    if debug:
        print(f"Valid date: {valid_str}")
    search_path = os.path.join(source, product + "*.gz")
    file_list = [f for f in glob.glob(search_path)]
    if debug:
        print(f"Files found: \n{file_list}")
    time_list = [file_list[x][-24:-9] for x in range(len(file_list))]
    int_list = [
        int(time_list[x][0:8] + time_list[x][9:15]) for x in range(len(time_list))
    ]
    int_list.sort()
    datetime_list = [
        datetime.datetime.strptime(str(x), "%Y%m%d%H%M%S") for x in int_list
    ]

    # Find the MRMS file closest to the valid time
    i = bisect.bisect_left(datetime_list, valid)
    closest_timestamp = min(
        datetime_list[max(0, i - 1) : i + 2], key=lambda date: abs(valid - date)
    )

    # Check to make sure closest file is within +/- window seconds of top of the hour
    difference = abs(closest_timestamp - valid)
    if difference.total_seconds() <= window:
        filename1 = f"{product}{level}{closest_timestamp.strftime('%Y%m%d-%H%M%S')}.grib2.gz"
        filename2 = f"{product}{level}{valid.strftime('%Y%m%d-%H')}0000.grib2.gz"
        origfile = os.path.join(source, filename1)
        target = os.path.join(outdir, filename2)

        if debug:
            print(f"Moving file {origfile} to {target}")
        shutil.move(origfile,target)
        
    else:
        raise FileNotFoundError(f"Did not find a valid file within {window} seconds of {valid}")

    return target

if __name__ == "__main__":
    #Parse input arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--valid_time', type=str, required=True,
                        help='Valid time (in string format YYYYMMDDHH) to find MRMS data for')
    parser.add_argument('-o', '--outdir', type=str, required=True,
                        help='Destination directory for extracted MRMS data; data will be placed in `dest/YYYYMMDD`')
    parser.add_argument('-s', '--source', type=str, required=True,
                        help='Source directory where zipped MRMS data is found')
    parser.add_argument('-p', '--product', type=str, required=True, choices=['MergedReflectivityQCComposite', 'EchoTop'],
                        help='Name of MRMS product')
    parser.add_argument('-w', '--window', type=int, help='Time in seconds to check for obs file +/- the valid time',
                        default=900)
    parser.add_argument('-l', '--level', type=str, help='MRMS product level')
    parser.add_argument('-d', '--debug', action='store_true', help='Add additional debug output')
    args = parser.parse_args()

    #Consistency checks

    staged_file = mrms_pull_topofhour(**vars(args))
    print (f'Staged file: {staged_file}')
