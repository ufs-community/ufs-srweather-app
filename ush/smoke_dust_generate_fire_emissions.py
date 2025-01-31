#!/usr/bin/env python3

#########################################################################
#                                                                       #
# Python script for fire emissions preprocessing from RAVE FRP and FRE  #
# (Li et al.,2022).                                                     #
# johana.romero-alvarez@noaa.gov                                        #
#                                                                       #
#########################################################################

import sys
import os
import smoke_dust_fire_emiss_tools as femmi_tools
import smoke_dust_hwp_tools as hwp_tools
import smoke_dust_interp_tools as i_tools


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Workflow
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
def generate_emiss_workflow(
    staticdir: str,
    ravedir: str,
    intp_dir: str,
    predef_grid: str,
    ebb_dcycle_flag: str,
    restart_interval: str,
    persistence: str,
) -> None:
    """
    Prepares fire-related ICs. This is the main function that handles data movement and interpolation.

    Args:
        staticdir: Path to fix files for the smoke and dust component
        ravedir: Path to the directory containing RAVE fire data files (hourly). This is typically the working directory (DATA)
        intp_dir: Path to interpolated RAVE data files from the previous cycles (DATA_SHARE)
        predef_grid: If ``RRFS_NA_3km``, use pre-defined grid dimensions
        ebb_dcycle_flag: Select the EBB cycle to run. Valid values are ``"1"`` or ``"2"``
        restart_interval: Indicates if restart files should be copied. The actual interval values are not used
        persistence: If ``TRUE``, use satellite observations from the previous day. Otherwise, use observations from the same day.
    """

    # ----------------------------------------------------------------------
    # Import envs from workflow and get the pre-defined grid
    # Set variable names, constants and unit conversions
    # Set predefined grid
    # Set directories
    # ----------------------------------------------------------------------

    beta = 0.3
    fg_to_ug = 1e6
    to_s = 3600
    current_day = os.environ["CDATE"]
    #   nwges_dir = os.environ.get("NWGES_DIR")
    nwges_dir = os.environ["DATA"]
    vars_emis = ["FRP_MEAN", "FRE"]
    cols, rows = (2700, 3950) if predef_grid == "RRFS_NA_3km" else (1092, 1820)
    print("PREDEF GRID", predef_grid, "cols,rows", cols, rows)
    # used later when working with ebb_dcyle 1 or 2
    ebb_dcycle = int(ebb_dcycle_flag)
    print(
        "WARNING, EBB_DCYCLE set to",
        ebb_dcycle,
        "and persistence=",
        persistence,
        "if persistence is false, emissions comes from same day satellite obs",
    )

    print("CDATE:", current_day)
    print("DATA:", nwges_dir)

    # This is used later when copying the rrfs restart file
    restart_interval_list = [float(num) for num in restart_interval.split()]
    len_restart_interval = len(restart_interval_list)

    # Setting the directories
    veg_map = staticdir + "/veg_map.nc"
    RAVE = ravedir
    rave_to_intp = predef_grid + "_intp_"
    grid_in = staticdir + "/grid_in.nc"
    weightfile = staticdir + "/weight_file.nc"
    grid_out = staticdir + "/ds_out_base.nc"
    hourly_hwpdir = os.path.join(nwges_dir, "RESTART")

    # ----------------------------------------------------------------------
    # Workflow
    # ----------------------------------------------------------------------

    # ----------------------------------------------------------------------
    # Sort raw RAVE, create source and target filelds, and compute emissions
    # ----------------------------------------------------------------------
    fcst_dates = i_tools.date_range(current_day, ebb_dcycle, persistence)
    intp_avail_hours, intp_non_avail_hours, inp_files_2use = (
        i_tools.check_for_intp_rave(intp_dir, fcst_dates, rave_to_intp)
    )
    rave_avail, rave_avail_hours, rave_nonavail_hours_test, first_day = (
        i_tools.check_for_raw_rave(RAVE, intp_non_avail_hours, intp_avail_hours)
    )
    srcfield, tgtfield, tgt_latt, tgt_lont, srcgrid, tgtgrid, src_latt, tgt_area = (
        i_tools.creates_st_fields(grid_in, grid_out)
    )

    if not first_day:
        regridder, use_dummy_emiss = i_tools.generate_regridder(
            rave_avail_hours, srcfield, tgtfield, weightfile, intp_avail_hours
        )
        if use_dummy_emiss:
            print("RAVE files corrupted, no data to process")
            i_tools.create_dummy(intp_dir, current_day, tgt_latt, tgt_lont, cols, rows)
        else:
            i_tools.interpolate_rave(
                RAVE,
                rave_avail,
                rave_avail_hours,
                use_dummy_emiss,
                vars_emis,
                regridder,
                srcgrid,
                tgtgrid,
                rave_to_intp,
                intp_dir,
                tgt_latt,
                tgt_lont,
                cols,
                rows,
            )

            if ebb_dcycle == 1:
                print("Processing emissions forebb_dcyc 1")
                frp_avg_reshaped, ebb_total_reshaped = femmi_tools.averaging_FRP(
                    ebb_dcycle,
                    fcst_dates,
                    cols,
                    rows,
                    intp_dir,
                    rave_to_intp,
                    veg_map,
                    tgt_area,
                    beta,
                    fg_to_ug,
                    to_s,
                )
                femmi_tools.produce_emiss_24hr_file(
                    frp_avg_reshaped,
                    nwges_dir,
                    current_day,
                    tgt_latt,
                    tgt_lont,
                    ebb_total_reshaped,
                    cols,
                    rows,
                )
            elif ebb_dcycle == 2:
                print("Restart dates to process", fcst_dates)
                hwp_avail_hours, hwp_non_avail_hours = hwp_tools.check_restart_files(
                    hourly_hwpdir, fcst_dates
                )
                restart_avail, restart_nonavail_hours_test = (
                    hwp_tools.copy_missing_restart(
                        nwges_dir,
                        hwp_non_avail_hours,
                        hourly_hwpdir,
                        len_restart_interval,
                    )
                )
                hwp_ave_arr, xarr_hwp, totprcp_ave_arr, xarr_totprcp = (
                    hwp_tools.process_hwp(
                        fcst_dates, hourly_hwpdir, cols, rows, intp_dir, rave_to_intp
                    )
                )
                frp_avg_reshaped, ebb_total_reshaped = femmi_tools.averaging_FRP(
                    ebb_dcycle,
                    fcst_dates,
                    cols,
                    rows,
                    intp_dir,
                    rave_to_intp,
                    veg_map,
                    tgt_area,
                    beta,
                    fg_to_ug,
                    to_s,
                )
                # Fire end hours processing
                te = femmi_tools.estimate_fire_duration(
                    intp_dir, fcst_dates, current_day, cols, rows, rave_to_intp
                )
                fire_age = femmi_tools.save_fire_dur(cols, rows, te)
                # produce emiss file
                femmi_tools.produce_emiss_file(
                    xarr_hwp,
                    frp_avg_reshaped,
                    totprcp_ave_arr,
                    xarr_totprcp,
                    nwges_dir,
                    current_day,
                    tgt_latt,
                    tgt_lont,
                    ebb_total_reshaped,
                    fire_age,
                    cols,
                    rows,
                )
            else:
                raise NotImplementedError(f"ebb_dcycle={ebb_dcycle}")
    else:
        print("First day true, no RAVE files available. Use dummy emissions file")
        i_tools.create_dummy(intp_dir, current_day, tgt_latt, tgt_lont, cols, rows)


if __name__ == "__main__":
    print("")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("Welcome to interpolating RAVE and processing fire emissions!")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("")
    generate_emiss_workflow(
        sys.argv[1],
        sys.argv[2],
        sys.argv[3],
        sys.argv[4],
        sys.argv[5],
        sys.argv[6],
        sys.argv[7],
    )
    print("")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("Successful Completion. Bye!")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("")
