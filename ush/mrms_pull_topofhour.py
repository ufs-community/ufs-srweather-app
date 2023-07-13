import sys, os, shutil, subprocess
import datetime
import re, csv, glob
import bisect
import numpy as np

if __name__ == "__main__":
    # Copy and unzip MRMS files that are closest to top of hour
    # Done every hour on a 20-minute lag

    # Include option to define valid time on command line
    # Used to backfill verification
    # try:
    valid_time = str(sys.argv[1])

    YYYY = int(valid_time[0:4])
    MM = int(valid_time[4:6])
    DD = int(valid_time[6:8])
    HH = int(valid_time[8:19])

    valid = datetime.datetime(YYYY, MM, DD, HH, 0, 0)

    # except IndexError:
    #    valid_time = None

    # Default to current hour if not defined on command line
    # if valid_time is None:
    #    now  = datetime.datetime.utcnow()
    #    YYYY = int(now.strftime('%Y'))
    #    MM   = int(now.strftime('%m'))
    #    DD   = int(now.strftime('%d'))
    #    HH   = int(now.strftime('%H'))

    #    valid = datetime.datetime(YYYY,MM,DD,HH,0,0)
    #   valid_time = valid.strftime('%Y%m%d%H')

    print("Pulling " + valid_time + " MRMS data")

    # Set up working directory
    DATA_HEAD = str(sys.argv[2])
    MRMS_PROD_DIR = str(sys.argv[3])
    MRMS_PRODUCT = str(sys.argv[4])
    level = str(sys.argv[5])

    VALID_DIR = os.path.join(DATA_HEAD, valid.strftime("%Y%m%d"))
    if not os.path.exists(VALID_DIR):
        os.makedirs(VALID_DIR)

    # Sort list of files for each MRMS product
    print(valid.strftime("%Y%m%d"))
    search_path = (
        MRMS_PROD_DIR
        + "/"
        + valid.strftime("%Y%m%d")
        + "/"
        + MRMS_PRODUCT
        + "*.gz"
    )
    print(search_path)
    file_list = [f for f in glob.glob(search_path)]
    print(file_list)
    time_list = [file_list[x][-24:-9] for x in range(len(file_list))]
    print(file_list)
    int_list = [
        int(time_list[x][0:8] + time_list[x][9:15]) for x in range(len(time_list))
    ]
    int_list.sort()
    print(int_list)
    datetime_list = [
        datetime.datetime.strptime(str(x), "%Y%m%d%H%M%S") for x in int_list
    ]
    print(datetime_list)

    # Find the MRMS file closest to the valid time
    i = bisect.bisect_left(datetime_list, valid)
    closest_timestamp = min(
        datetime_list[max(0, i - 1) : i + 2], key=lambda date: abs(valid - date)
    )

    # Check to make sure closest file is within +/- 15 mins of top of the hour
    # Copy and rename the file for future ease
    difference = abs(closest_timestamp - valid)
    if difference.total_seconds() <= 900:
        filename1 = (
            MRMS_PRODUCT
            + level
            + closest_timestamp.strftime("%Y%m%d-%H%M%S")
            + ".grib2.gz"
        )
        filename2 = MRMS_PRODUCT + level + valid.strftime("%Y%m%d-%H") + "0000.grib2.gz"

        if valid.strftime("%Y%m%d") < "20200303":
            print(
                "cp "
                + MRMS_PROD_DIR
                + "/"
                + valid.strftime("%Y%m%d")
                + "/"
                + filename1
                + " "
                + VALID_DIR
                + "/"
                + filename2
            )

            os.system(
                "cp "
                + MRMS_PROD_DIR
                + "/"
                + valid.strftime("%Y%m%d")
                + "/"
                + filename1
                + " "
                + VALID_DIR
                + "/"
                + filename2
            )
            os.system("gunzip " + VALID_DIR + "/" + filename2)
        elif valid.strftime("%Y%m%d") >= "20200303":
            print(
                "cp "
                + MRMS_PROD_DIR
                + "/"
                + valid.strftime("%Y%m%d")
                + "/"
                + filename1
                + " "
                + VALID_DIR
                + "/"
                + filename2
            )

            os.system(
                "cp "
                + MRMS_PROD_DIR
                + "/"
                + valid.strftime("%Y%m%d")
                + "/upperair/mrms/conus/"
                + filename1
                + " "
                + VALID_DIR
                + "/"
                + filename2
            )
            os.system("gunzip " + VALID_DIR + "/" + filename2)
