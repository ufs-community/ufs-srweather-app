#!/usr/bin/env python3

import os
import sys
import argparse
import unittest
from datetime import datetime
from textwrap import dedent

from python_utils import import_vars, set_env_var, print_input_args, str_to_type, \
                         print_info_msg, print_err_msg_exit, lowercase, cfg_to_yaml_str, \
                         load_shell_config

from fill_jinja_template import fill_jinja_template

def create_model_configure_file(cdate,run_dir,sub_hourly_post,dt_subhourly_post_mnts,dt_atmos):
    """ Creates a model configuration file in the specified
    run directory

    Args:
        cdate: cycle date
        run_dir: run directory
        sub_hourly_post
        dt_subhourly_post_mnts
        dt_atmos
    Returns:
        Boolean
    """

    print_input_args(locals())

    #import all environment variables
    import_vars()
    
    #
    #-----------------------------------------------------------------------
    #
    # Create a model configuration file in the specified run directory.
    #
    #-----------------------------------------------------------------------
    #
    print_info_msg(f'''
        Creating a model configuration file (\"{MODEL_CONFIG_FN}\") in the specified
        run directory (run_dir):
          run_dir = \"{run_dir}\"''', verbose=VERBOSE)
    #
    # Extract from cdate the starting year, month, day, and hour of the forecast.
    #
    yyyy=cdate.year
    mm=cdate.month
    dd=cdate.day
    hh=cdate.hour
    #
    # Set parameters in the model configure file.
    #
    dot_quilting_dot=f".{lowercase(str(QUILTING))}."
    dot_print_esmf_dot=f".{lowercase(str(PRINT_ESMF))}."
    dot_cpl_dot=f".{lowercase(str(CPL))}."
    dot_write_dopost=f".{lowercase(str(WRITE_DOPOST))}."
    #
    #-----------------------------------------------------------------------
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the jinja variables in the template 
    # model_configure file should be set to.
    #
    #-----------------------------------------------------------------------
    #
    settings = {
      'PE_MEMBER01': PE_MEMBER01,
      'print_esmf': dot_print_esmf_dot,
      'start_year': yyyy,
      'start_month': mm,
      'start_day': dd,
      'start_hour': hh,
      'nhours_fcst': FCST_LEN_HRS,
      'dt_atmos': DT_ATMOS,
      'cpl': dot_cpl_dot,
      'atmos_nthreads': OMP_NUM_THREADS_RUN_FCST,
      'restart_interval': RESTART_INTERVAL,
      'write_dopost': dot_write_dopost,
      'quilting': dot_quilting_dot,
      'output_grid': WRTCMP_output_grid
    }
    #
    # If the write-component is to be used, then specify a set of computational
    # parameters and a set of grid parameters.  The latter depends on the type
    # (coordinate system) of the grid that the write-component will be using.
    #
    if QUILTING:
        settings.update({
          'write_groups': WRTCMP_write_groups,
          'write_tasks_per_group': WRTCMP_write_tasks_per_group,
          'cen_lon': WRTCMP_cen_lon,
          'cen_lat': WRTCMP_cen_lat,
          'lon1': WRTCMP_lon_lwr_left,
          'lat1': WRTCMP_lat_lwr_left
        })
    
        if WRTCMP_output_grid == "lambert_conformal":
          settings.update({
            'stdlat1': WRTCMP_stdlat1,
            'stdlat2': WRTCMP_stdlat2,
            'nx': WRTCMP_nx,
            'ny': WRTCMP_ny,
            'dx': WRTCMP_dx,
            'dy': WRTCMP_dy,
            'lon2': "",
            'lat2': "",
            'dlon': "",
            'dlat': "",
          })
        elif WRTCMP_output_grid == "regional_latlon" or \
             WRTCMP_output_grid == "rotated_latlon":
          settings.update({
            'lon2': WRTCMP_lon_upr_rght,
            'lat2': WRTCMP_lat_upr_rght,
            'dlon': WRTCMP_dlon,
            'dlat': WRTCMP_dlat,
            'stdlat1': "",
            'stdlat2': "",
            'nx': "",
            'ny': "",
            'dx': "",
            'dy': ""
          })
    #
    # If sub_hourly_post is set to "TRUE", then the forecast model must be 
    # directed to generate output files on a sub-hourly interval.  Do this 
    # by specifying the output interval in the model configuration file 
    # (MODEL_CONFIG_FN) in units of number of forecat model time steps (nsout).  
    # nsout is calculated using the user-specified output time interval 
    # dt_subhourly_post_mnts (in units of minutes) and the forecast model's 
    # main time step dt_atmos (in units of seconds).  Note that nsout is 
    # guaranteed to be an integer because the experiment generation scripts 
    # require that dt_subhourly_post_mnts (after conversion to seconds) be 
    # evenly divisible by dt_atmos.  Also, in this case, the variable output_fh 
    # [which specifies the output interval in hours; 
    # see the jinja model_config template file] is set to 0, although this 
    # doesn't matter because any positive of nsout will override output_fh.
    #
    # If sub_hourly_post is set to "FALSE", then the workflow is hard-coded 
    # (in the jinja model_config template file) to direct the forecast model 
    # to output files every hour.  This is done by setting (1) output_fh to 1 
    # here, and (2) nsout to -1 here which turns off output by time step interval.
    #
    # Note that the approach used here of separating how hourly and subhourly
    # output is handled should be changed/generalized/simplified such that 
    # the user should only need to specify the output time interval (there
    # should be no need to specify a flag like sub_hourly_post); the workflow 
    # should then be able to direct the model to output files with that time 
    # interval and to direct the post-processor to process those files 
    # regardless of whether that output time interval is larger than, equal 
    # to, or smaller than one hour.
    #
    if sub_hourly_post:
        nsout=(dt_subhourly_post_mnts*60) // dt_atmos
        output_fh=0
    else:
        output_fh=1
        nsout=-1

    settings.update({
      'output_fh': output_fh,
      'nsout': nsout
    })

    settings_str = cfg_to_yaml_str(settings)
    
    print_info_msg(dedent(f'''
        The variable \"settings\" specifying values to be used in the \"{MODEL_CONFIG_FN}\"
        file has been set as follows:
        #-----------------------------------------------------------------------
        settings =\n''') + settings_str,verbose=VERBOSE)
    #
    #-----------------------------------------------------------------------
    #
    # Call a python script to generate the experiment's actual MODEL_CONFIG_FN
    # file from the template file.
    #
    #-----------------------------------------------------------------------
    #
    model_config_fp=os.path.join(run_dir, MODEL_CONFIG_FN)

    try:
        fill_jinja_template(["-q", "-u", settings_str, "-t", MODEL_CONFIG_TMPL_FP, "-o", model_config_fp])
    except:
        print_err_msg_exit(f'''
            Call to python script fill_jinja_template.py to create a \"{MODEL_CONFIG_FN}\"
            file from a jinja2 template failed.  Parameters passed to this script are:
              Full path to template rocoto XML file:
                MODEL_CONFIG_TMPL_FP = \"{MODEL_CONFIG_TMPL_FP}\"
              Full path to output rocoto XML file:
                model_config_fp = \"{model_config_fp}\"
              Namelist settings specified on command line:
                settings =
            {settings_str}''')
        return False

    return True

def parse_args(argv):
    """ Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Creates model configuration file.'
    )

    parser.add_argument('-r', '--run-dir',
                        dest='run_dir',
                        required=True,
                        help='Run directory.')

    parser.add_argument('-c', '--cdate',
                        dest='cdate',
                        required=True,
                        help='Date string in YYYYMMDD format.')

    parser.add_argument('-s', '--sub-hourly-post',
                        dest='sub_hourly_post',
                        required=True,
                        help='Set sub hourly post to either TRUE/FALSE by passing corresponding string.')

    parser.add_argument('-d', '--dt-subhourly-post-mnts',
                        dest='dt_subhourly_post_mnts',
                        required=True,
                        help='Subhourly post minitues.')

    parser.add_argument('-t', '--dt-atmos',
                        dest='dt_atmos',
                        required=True,
                        help='Forecast model\'s main time step.')

    parser.add_argument('-p', '--path-to-defns',
                        dest='path_to_defns',
                        required=True,
                        help='Path to var_defns file.')

    return parser.parse_args(argv)

if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    import_vars(dictionary=cfg)
    create_model_configure_file( \
        run_dir = args.run_dir, \
        cdate = str_to_type(args.cdate), \
        sub_hourly_post = str_to_type(args.sub_hourly_post), \
        dt_subhourly_post_mnts = str_to_type(args.dt_subhourly_post_mnts), \
        dt_atmos = str_to_type(args.dt_atmos) )

class Testing(unittest.TestCase):
    def test_create_model_configure_file(self):
        path = os.path.join(os.getenv('USHDIR'), "test_data")
        self.assertTrue(\
                create_model_configure_file( \
                      run_dir=path,
                      cdate=datetime(2021,1,1),
                      sub_hourly_post=True,
                      dt_subhourly_post_mnts=4,
                      dt_atmos=1) )
    def setUp(self):
        USHDIR = os.path.dirname(os.path.abspath(__file__))
        MODEL_CONFIG_FN='model_configure'
        MODEL_CONFIG_TMPL_FP = os.path.join(USHDIR, "templates", MODEL_CONFIG_FN)

        set_env_var('DEBUG',True)
        set_env_var('VERBOSE',True)
        set_env_var('QUILTING',True)
        set_env_var('PRINT_ESMF',True)
        set_env_var('CPL',True)
        set_env_var('WRITE_DOPOST',True)
        set_env_var("USHDIR",USHDIR)
        set_env_var('MODEL_CONFIG_FN',MODEL_CONFIG_FN)
        set_env_var("MODEL_CONFIG_TMPL_FP",MODEL_CONFIG_TMPL_FP)
        set_env_var('PE_MEMBER01',24)
        set_env_var('FCST_LEN_HRS',72)
        set_env_var('DT_ATMOS',1)
        set_env_var('OMP_NUM_THREADS_RUN_FCST',1)
        set_env_var('RESTART_INTERVAL',4)

        set_env_var('WRTCMP_write_groups',1)
        set_env_var('WRTCMP_write_tasks_per_group',2)
        set_env_var('WRTCMP_output_grid',"lambert_conformal")
        set_env_var('WRTCMP_cen_lon',-97.5)
        set_env_var('WRTCMP_cen_lat',35.0)
        set_env_var('WRTCMP_stdlat1',35.0)
        set_env_var('WRTCMP_stdlat2',35.0)
        set_env_var('WRTCMP_nx',199)
        set_env_var('WRTCMP_ny',111)
        set_env_var('WRTCMP_lon_lwr_left',-121.23349066)
        set_env_var('WRTCMP_lat_lwr_left',23.41731593)
        set_env_var('WRTCMP_dx',3000.0)
        set_env_var('WRTCMP_dy',3000.0)

