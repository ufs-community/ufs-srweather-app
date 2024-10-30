import sys, os, shutil, subprocess
import datetime
import glob
import argparse
import bisect
import shutil
import gzip

def mrms_pull_topofhour(valid_time, outdir, source, product, level=None, add_vdate_subdir=True, debug=False):
    """Identifies the MRMS file closest to the valid time of the forecast. 
    METplus is configured to look for a MRMS composite reflectivity file 
    for the valid time of the forecast being verified; since MRMS composite 
    reflectivity files do not always exactly match the valid time, this 
    script is used to identify and rename the MRMS composite reflectivity 
    file to match the valid time of the forecast. 

    Returns:
        None
        
    Raises: 
        FileNotFoundError: If no valid file was found within 15 minutes of the valid 
                           time of the forecast

    """

    # Level is determined by MRMS product; set if not provided
    if level is None:
        if product == "MergedReflectivityQCComposite":
            level = "_00.50_"
        elif product == "EchoTop":
            level = "_18_00.50_"
        else:
            raise Exception("This should never have happened")

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

    valid_str_or_empty = ''
    if add_vdate_subdir:
        valid_str_or_empty = valid_str

    dest_dir = os.path.join(outdir, valid_str_or_empty)
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)

    # Sort list of files for each MRMS product
    if debug:
        print(f"Valid date: {valid_str}")
    search_path = os.path.join(source, valid_str_or_empty, product + "*.gz")
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

    # Check to make sure closest file is within +/- 15 mins of top of the hour
    difference = abs(closest_timestamp - valid)
    if difference.total_seconds() <= 900:
        filename1 = f"{product}{level}{closest_timestamp.strftime('%Y%m%d-%H%M%S')}.grib2.gz"
        filename2 = f"{product}{level}{valid.strftime('%Y%m%d-%H')}0000.grib2"
        origfile = os.path.join(source, valid_str_or_empty, filename1)
        target = os.path.join(dest_dir, filename2)

        if debug:
            print(f"Unzipping file {origfile} to {target}")

        
        # Unzip file to target location
        with gzip.open(origfile, 'rb') as f_in:
            with open(target, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
    else:
        raise FileNotFoundError(f"Did not find a valid file within 15 minutes of {valid}")
 
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
    parser.add_argument('-l', '--level', type=str, help='MRMS product level',
                        choices=['_00.50_','_18_00.50_'])
    parser.add_argument('--add_vdate_subdir', default=True, required=False, action=argparse.BooleanOptionalAction,
                        help='Flag to add valid-date subdirectory to source and destination directories')
    parser.add_argument('-d', '--debug', action='store_true', help='Add additional debug output')
    args = parser.parse_args()

    #Consistency checks

    mrms_pull_topofhour(**vars(args))
