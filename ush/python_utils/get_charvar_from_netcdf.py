#!/usr/bin/env python3

import os
from .print_msg import print_err_msg_exit
from .run_command import run_command

def get_charvar_from_netcdf(nc_file, nc_var_name):
    """ Searches NetCDF file and extract a scalar variable

    Args:
        nc_file: Path to netCDF file
        nc_var_name: name of the scalar variable
    Returns:
        value of the variable
    """
    
    SED = os.getenv('SED')

    cmd = f"ncdump -v {nc_var_name} {nc_file} | \
            {SED} -r -e '1,/data:/d' \
                   -e '/^[ ]*'{nc_var_name}'/d' \
                   -e '/^}}$/d' \
                   -e 's/.*\"(.*)\".*/\\1/' \
                   -e '/^$/d' \
                    "
    (ret,nc_var_value,_) = run_command(cmd)

    if ret != 0:
        print_err_msg_exit(f'''
            Attempt to extract the value of the NetCDF variable spcecified by nc_var_name
            from the file specified by nc_file failed:
              nc_file = \"{nc_file}\"
              nc_var_name = \"{nc_var_name}\"''')

    if nc_var_value is None:
        print_err_msg_exit(f'''
            In the specified NetCDF file (nc_file), the specified variable (nc_var_name)
            was not found:
              nc_file = \"{nc_file}\"
              nc_var_name = \"{nc_var_name}\"
              nc_var_value = \"{nc_var_value}\"''')

    return nc_var_value

