import os
import numpy as np
import xarray as xr
from datetime import datetime
from netCDF4 import Dataset
import interp_tools as i_tools

#Compute average FRP from raw RAVE for the previous 24 hours 
def averaging_FRP(ebb_dcycle, fcst_dates, cols, rows, intp_dir, rave_to_intp, veg_map, tgt_area, beta, fg_to_ug, to_s):
    base_array = np.zeros((cols*rows))
    frp_daily = base_array
    ebb_smoke_total = []
    ebb_smoke_hr = []
    frp_avg_hr = []

    try:
        ef_map = xr.open_dataset(veg_map)
        emiss_factor = ef_map.emiss_factor.values
        target_area = tgt_area.values
    except (FileNotFoundError, IOError, OSError, RuntimeError, ValueError, TypeError, KeyError, IndexError, MemoryError) as e:
        print(f"Error loading vegetation map: {e}")
        return np.zeros((cols, rows)), np.zeros((cols, rows))

    num_files = 0
    for cycle in fcst_dates:
        try:
            file_path = os.path.join(intp_dir, f'{rave_to_intp}{cycle}00_{cycle}59.nc')
            if os.path.exists(file_path):
                try:
                    with xr.open_dataset(file_path) as nc:
                        open_fre = nc.FRE[0, :, :].values
                        open_frp = nc.frp_avg_hr[0, :, :].values
                        num_files += 1
                        if ebb_dcycle == 1:
                            print('Processing emissions for ebb_dcyc 1')
                            print(file_path)
                            frp_avg_hr.append(open_frp)
                            ebb_hourly = (open_fre * emiss_factor * beta * fg_to_ug) / (target_area * to_s)
                            ebb_smoke_total.append(np.where(open_frp > 0, ebb_hourly, 0))
                        else:
                            print('Processing emissions for ebb_dcyc 2')
                            ebb_hourly = open_fre * emiss_factor * beta * fg_to_ug / target_area
                            ebb_smoke_total.append(np.where(open_frp > 0, ebb_hourly, 0).ravel())
                            frp_daily += np.where(open_frp > 0, open_frp, 0).ravel()
                except (FileNotFoundError, IOError, OSError, RuntimeError, ValueError, TypeError, KeyError, IndexError, MemoryError) as e:
                    print(f"Error processing NetCDF file {file_path}: {e}")
                    if ebb_dcycle == 1:
                       frp_avg_hr.append(np.zeros((cols, rows)))
                       ebb_smoke_total.append(np.zeros((cols, rows)))
            else:
                if ebb_dcycle == 1:
                   frp_avg_hr.append(np.zeros((cols, rows)))
                   ebb_smoke_total.append(np.zeros((cols, rows)))
        except Exception as e:
            print(f"Error processing cycle {cycle}: {e}")
            if ebb_dcycle == 1:
                frp_avg_hr.append(np.zeros((cols, rows)))
                ebb_smoke_total.append(np.zeros((cols, rows)))

    if num_files > 0:
        if ebb_dcycle == 1:
            frp_avg_reshaped = np.stack(frp_avg_hr, axis=0)
            ebb_total_reshaped = np.stack(ebb_smoke_total, axis=0)
        else:
            summed_array = np.sum(np.array(ebb_smoke_total), axis=0)
            num_zeros = len(ebb_smoke_total) - np.sum([arr == 0 for arr in ebb_smoke_total], axis=0)
            safe_zero_count = np.where(num_zeros == 0, 1, num_zeros)
            result_array = [summed_array[i] / 2 if safe_zero_count[i] == 1 else summed_array[i] / safe_zero_count[i] for i in range(len(safe_zero_count))]
            result_array = np.array(result_array)
            result_array[num_zeros == 0] = summed_array[num_zeros == 0]
            ebb_total = result_array.reshape(cols, rows)
            ebb_total_reshaped = ebb_total / 3600
            temp_frp = [frp_daily[i] / 2 if safe_zero_count[i] == 1 else frp_daily[i] / safe_zero_count[i] for i in range(len(safe_zero_count))]
            temp_frp = np.array(temp_frp)
            temp_frp[num_zeros == 0] = frp_daily[num_zeros == 0]
            frp_avg_reshaped = temp_frp.reshape(cols, rows)
    else:
        if ebb_dcycle == 1:
            frp_avg_reshaped = np.zeros((24, cols, rows))
            ebb_total_reshaped = np.zeros((24, cols, rows))
        else:
            frp_avg_reshaped = np.zeros((cols, rows))
            ebb_total_reshaped = np.zeros((cols, rows))

    return(frp_avg_reshaped, ebb_total_reshaped)

def estimate_fire_duration(intp_avail_hours, intp_dir, fcst_dates, current_day, cols, rows, rave_to_intp):
    # There are two steps here.
    #   1) First day simulation no RAVE from previous 24 hours available (fire age is set to zero)
    #   2) previus files are present (estimate fire age as the difference between the date of the current cycle and the date whe the fire was last observed whiting 24 hours)
    t_fire = np.zeros((cols, rows))

    for date_str in fcst_dates:
        try:
            date_file = int(date_str[:10])
            print('Date processing for fire duration', date_file)
            file_path = os.path.join(intp_dir, f'{rave_to_intp}{date_str}00_{date_str}59.nc')

            if os.path.exists(file_path):
                try:
                    with xr.open_dataset(file_path) as open_intp:
                        FRP = open_intp.frp_avg_hr[0, :, :].values
                        dates_filtered = np.where(FRP > 0, date_file, 0)
                        t_fire = np.maximum(t_fire, dates_filtered)
                except (FileNotFoundError, IOError, OSError,RuntimeError,ValueError, TypeError, KeyError, IndexError, MemoryError) as e:
                    print(f"Error processing NetCDF file {file_path}: {e}")
        except Exception as e:
            print(f"Error processing date {date_str}: {e}")

    t_fire_flattened = t_fire.flatten()
    t_fire_flattened = [int(i) if i != 0 else 0 for i in t_fire_flattened]

    try:
        fcst_t = datetime.strptime(current_day, '%Y%m%d%H')
        hr_ends = [datetime.strptime(str(hr), '%Y%m%d%H') if hr != 0 else 0 for hr in t_fire_flattened]
        te = [(fcst_t - i).total_seconds() / 3600 if i != 0 else 0 for i in hr_ends]
    except ValueError as e:
        print(f"Error processing forecast time {current_day}: {e}")
        te = np.zeros((rows, cols))

    return(te)

def save_fire_dur(cols, rows, te):
    fire_dur = np.array(te).reshape(cols, rows)
    return(fire_dur)

def produce_emiss_24hr_file(ebb_dcycle, frp_reshaped, intp_dir, current_day, tgt_latt, tgt_lont, ebb_smoke_reshaped, cols, rows):
    file_path = os.path.join(intp_dir, f'SMOKE_RRFS_data_{current_day}00.nc')
    with Dataset(file_path, 'w') as fout:
        i_tools.create_emiss_file(fout, cols, rows)
        i_tools.Store_latlon_by_Level(fout, 'geolat', tgt_latt, 'cell center latitude', 'degrees_north', '2D', '-9999.f', '1.f')
        i_tools.Store_latlon_by_Level(fout, 'geolon', tgt_lont, 'cell center longitude', 'degrees_east', '2D', '-9999.f', '1.f')

        i_tools.Store_by_Level(fout,'frp_avg_hr','mean Fire Radiative Power','MW','3D','0.f','1.f')
        fout.variables['frp_avg_hr'][:, :, :] = frp_reshaped
        i_tools.Store_by_Level(fout,'ebb_smoke_hr','EBB emissions','ug m-2 s-1','3D','0.f','1.f')
        fout.variables['ebb_smoke_hr'][:, :, :] = ebb_smoke_reshaped

def produce_emiss_file(xarr_hwp, frp_avg_reshaped, totprcp_ave_arr, xarr_totprcp, intp_dir, current_day, tgt_latt, tgt_lont, ebb_tot_reshaped, fire_age, cols, rows):
    # Ensure arrays are not negative or NaN
    frp_avg_reshaped = np.clip(frp_avg_reshaped, 0, None)
    frp_avg_reshaped = np.nan_to_num(frp_avg_reshaped)

    ebb_tot_reshaped = np.clip(ebb_tot_reshaped, 0, None)
    ebb_tot_reshaped = np.nan_to_num(ebb_tot_reshaped)

    fire_age = np.clip(fire_age, 0, None)
    fire_age = np.nan_to_num(fire_age)

    # Filter HWP Prcp arrays to be non-negative and replace NaNs
    filtered_hwp = xarr_hwp.where(frp_avg_reshaped > 0, 0).fillna(0)
    filtered_prcp = xarr_totprcp.where(frp_avg_reshaped > 0, 0).fillna(0)

    # Filter based on ebb_rate
    ebb_rate_threshold = 0  # Define an appropriate threshold if needed
    mask = (ebb_tot_reshaped > ebb_rate_threshold)

    filtered_hwp = filtered_hwp.where(mask, 0).fillna(0)
    filtered_prcp = filtered_prcp.where(mask, 0).fillna(0)
    frp_avg_reshaped = frp_avg_reshaped * mask
    ebb_tot_reshaped = ebb_tot_reshaped * mask
    fire_age = fire_age * mask

    # Produce emiss file
    file_path = os.path.join(intp_dir, f'SMOKE_RRFS_data_{current_day}00.nc')

    try:
        with Dataset(file_path, 'w') as fout:
            i_tools.create_emiss_file(fout, cols, rows)
            i_tools.Store_latlon_by_Level(fout, 'geolat', tgt_latt, 'cell center latitude', 'degrees_north', '2D', '-9999.f', '1.f')
            i_tools.Store_latlon_by_Level(fout, 'geolon', tgt_lont, 'cell center longitude', 'degrees_east', '2D', '-9999.f', '1.f')

            print('Storing different variables')
            i_tools.Store_by_Level(fout, 'frp_davg', 'Daily mean Fire Radiative Power', 'MW', '3D', '0.f', '1.f')
            fout.variables['frp_davg'][0, :, :] = frp_avg_reshaped
            i_tools.Store_by_Level(fout, 'ebb_rate', 'Total EBB emission', 'ug m-2 s-1', '3D', '0.f', '1.f')
            fout.variables['ebb_rate'][0, :, :] = ebb_tot_reshaped
            i_tools.Store_by_Level(fout, 'fire_end_hr', 'Hours since fire was last detected', 'hrs', '3D', '0.f', '1.f')
            fout.variables['fire_end_hr'][0, :, :] = fire_age
            i_tools.Store_by_Level(fout, 'hwp_davg', 'Daily mean Hourly Wildfire Potential', 'none', '3D', '0.f', '1.f')
            fout.variables['hwp_davg'][0, :, :] = filtered_hwp
            i_tools.Store_by_Level(fout, 'totprcp_24hrs', 'Sum of precipitation', 'm', '3D', '0.f', '1.f')
            fout.variables['totprcp_24hrs'][0, :, :] = filtered_prcp

        print("Emissions file created successfully")
        return "Emissions file created successfully"

    except (OSError, IOError) as e:
        print(f"Error creating or writing to NetCDF file {file_path}: {e}")
        return f"Error creating or writing to NetCDF file {file_path}: {e}"

    return "Emissions file created successfully"
