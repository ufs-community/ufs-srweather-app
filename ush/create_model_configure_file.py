#!/usr/bin/env python3
"""
Create a model_configure file for the FV3 forecast model from a
template.
"""
import argparse
import os
import sys
import tempfile
from textwrap import dedent
from subprocess import STDOUT, CalledProcessError, check_output

from python_utils import (
    cfg_to_yaml_str,
    flatten_dict,
    import_vars,
    load_shell_config,
    lowercase,
    print_info_msg,
    print_input_args,
    str_to_type,
)


def create_model_configure_file(
    cdate, fcst_len_hrs, fhrot, run_dir, sub_hourly_post, dt_subhourly_post_mnts, dt_atmos
    ): #pylint: disable=too-many-arguments
    """Creates a model configuration file in the specified
    run directory

    Args:
        cdate: cycle date
        fcst_len_hrs: forecast length in hours
        fhrot: forecast hour at restart
        run_dir: run directory
        sub_hourly_post
        dt_subhourly_post_mnts
        dt_atmos
    Returns:
        Boolean
    """

    print_input_args(locals())

    # import all environment variables
    import_vars()

    # pylint: disable=undefined-variable

    #
    # -----------------------------------------------------------------------
    #
    # Create a model configuration file in the specified run directory.
    #
    # -----------------------------------------------------------------------
    #
    print_info_msg(
        f"""
        Creating a model configuration file ('{MODEL_CONFIG_FN}') in the specified
        run directory (run_dir):
          run_dir = '{run_dir}'""",
        verbose=VERBOSE,
    )
    #
    # -----------------------------------------------------------------------
    #
    # Create a multiline variable that consists of a yaml-compliant string
    # specifying the values that the jinja variables in the template
    # model_configure file should be set to.
    #
    # -----------------------------------------------------------------------
    #
    settings = {
        "start_year": cdate.year,
        "start_month": cdate.month,
        "start_day": cdate.day,
        "start_hour": cdate.hour,
        "nhours_fcst": fcst_len_hrs,
        "fhrot": fhrot,
        "dt_atmos": DT_ATMOS,
        "restart_interval": RESTART_INTERVAL,
        "itasks": ITASKS,
        "write_dopost": f".{lowercase(str(WRITE_DOPOST))}.",
        "quilting": f".{lowercase(str(QUILTING))}.",
        "output_grid": WRTCMP_output_grid,
    }
    #
    # If the write-component is to be used, then specify a set of computational
    # parameters and a set of grid parameters.  The latter depends on the type
    # (coordinate system) of the grid that the write-component will be using.
    #
    if QUILTING:
        settings.update(
            {
                "write_groups": WRTCMP_write_groups,
                "write_tasks_per_group": WRTCMP_write_tasks_per_group,
                "cen_lon": WRTCMP_cen_lon,
                "cen_lat": WRTCMP_cen_lat,
                "lon1": WRTCMP_lon_lwr_left,
                "lat1": WRTCMP_lat_lwr_left,
            }
        )

        if WRTCMP_output_grid == "lambert_conformal":
            settings.update(
                {
                    "stdlat1": WRTCMP_stdlat1,
                    "stdlat2": WRTCMP_stdlat2,
                    "nx": WRTCMP_nx,
                    "ny": WRTCMP_ny,
                    "dx": WRTCMP_dx,
                    "dy": WRTCMP_dy,
                    "lon2": "",
                    "lat2": "",
                    "dlon": "",
                    "dlat": "",
                }
            )
        elif (
            WRTCMP_output_grid in ("regional_latlon", "rotated_latlon")
        ):
            settings.update(
                {
                    "lon2": WRTCMP_lon_upr_rght,
                    "lat2": WRTCMP_lat_upr_rght,
                    "dlon": WRTCMP_dlon,
                    "dlat": WRTCMP_dlat,
                    "stdlat1": "",
                    "stdlat2": "",
                    "nx": "",
                    "ny": "",
                    "dx": "",
                    "dy": "",
                }
            )
    #
    # If not using the write-component (aka quilting), set those variables
    # needed for quilting to None so that it gets rendered in the template appropriately.
    #
    else:
        settings.update(
            {
                "write_groups": None,
                "write_tasks_per_group": None,
                "cen_lon": None,
                "cen_lat": None,
                "lon1": None,
                "lat1": None,
                "stdlat1": None,
                "stdlat2": None,
                "nx": None,
                "ny": None,
                "dx": None,
                "dy": None,
                "lon2": None,
                "lat2": None,
                "dlon": None,
                "dlat": None,
            }
        )
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
        nsout = (dt_subhourly_post_mnts * 60) // dt_atmos
        output_fh = 0
    else:
        output_fh = 1
        nsout = -1

    settings.update({"output_fh": output_fh, "nsout": nsout})

    settings_str = cfg_to_yaml_str(settings)

    print_info_msg(
        dedent(
            f"""
            The variable 'settings' specifying values to be used in the '{MODEL_CONFIG_FN}'
            file has been set as follows:\n
            settings =\n\n"""
        )
        + settings_str,
        verbose=VERBOSE,
    )
    #
    # -----------------------------------------------------------------------
    #
    # Call a python script to generate the experiment's actual MODEL_CONFIG_FN
    # file from the template file.
    #
    # -----------------------------------------------------------------------
    #
    model_config_fp = os.path.join(run_dir, MODEL_CONFIG_FN)

    with tempfile.NamedTemporaryFile(dir="./",
                                     mode="w+t",
                                     suffix=".yaml",
                                     prefix="model_config_settings.") as tmpfile:
        tmpfile.write(settings_str)
        tmpfile.seek(0)
        cmd = " ".join(["uw template render",
            "-i", MODEL_CONFIG_TMPL_FP,
            "-o", model_config_fp,
            "-v",
            "--values-file", tmpfile.name,
            ]
        )
        indent = "  "
        output = ""
        try:
            output = check_output(cmd, encoding="utf=8", shell=True,
                    stderr=STDOUT, text=True)
        except CalledProcessError as e:
            output = e.output
            print(f"Failed with status: {e.returncode}")
            sys.exit(1)
        finally:
            print("Output:")
            for line in output.split("\n"):
                print(f"{indent * 2}{line}")
    return True


def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Creates model configuration file.")

    parser.add_argument(
        "-r", "--run-dir", dest="run_dir", required=True, help="Run directory."
    )

    parser.add_argument(
        "-c",
        "--cdate",
        dest="cdate",
        required=True,
        help="Date string in YYYYMMDD format.",
    )

    parser.add_argument(
        "-f",
        "--fcst_len_hrs",
        dest="fcst_len_hrs",
        required=True,
        help="Forecast length in hours.",
    )

    parser.add_argument(
        "-b",
        "--fhrot",
        dest="fhrot",
        required=True,
        help="Forecast hour at restart.",
    )

    parser.add_argument(
        "-s",
        "--sub-hourly-post",
        dest="sub_hourly_post",
        required=True,
        help="Set sub hourly post to either TRUE/FALSE by passing corresponding string.",
    )

    parser.add_argument(
        "-d",
        "--dt-subhourly-post-mnts",
        dest="dt_subhourly_post_mnts",
        required=True,
        help="Subhourly post minitues.",
    )

    parser.add_argument(
        "-t",
        "--dt-atmos",
        dest="dt_atmos",
        required=True,
        help="Forecast model's main time step.",
    )

    parser.add_argument(
        "-p",
        "--path-to-defns",
        dest="path_to_defns",
        required=True,
        help="Path to var_defns file.",
    )

    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    cfg = flatten_dict(cfg)
    import_vars(dictionary=cfg)
    create_model_configure_file(
        run_dir=args.run_dir,
        cdate=str_to_type(args.cdate),
        fcst_len_hrs=str_to_type(args.fcst_len_hrs),
        fhrot=str_to_type(args.fhrot),
        sub_hourly_post=str_to_type(args.sub_hourly_post),
        dt_subhourly_post_mnts=str_to_type(args.dt_subhourly_post_mnts),
        dt_atmos=str_to_type(args.dt_atmos),
    )
