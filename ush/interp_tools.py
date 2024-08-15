import datetime as dt
import pandas as pd
import os
import fnmatch
import ESMF
import xarray as xr
import numpy as np
from netCDF4 import Dataset

#Create date range, this is later used to search for RAVE and HWP from previous 24 hours
def date_range(current_day, ebb_dcycle):
    print(f'Searching for interpolated RAVE for {current_day}')
    print('EBB CYCLE:',ebb_dcycle)
    
    fcst_datetime = dt.datetime.strptime(current_day, "%Y%m%d%H")
    
    if ebb_dcycle == 1:
       print('Find  RAVE for ebb_dcyc 1')
       fcst_dates = pd.date_range(start=fcst_datetime, periods=24, freq='H').strftime("%Y%m%d%H")
    else:   
       start_datetime = fcst_datetime - dt.timedelta(days=1, hours=1)
    
       fcst_dates = pd.date_range(start=start_datetime, periods=24, freq='H').strftime("%Y%m%d%H")

    print(f'Current cycle: {fcst_datetime}')
    return(fcst_dates)

# Check if interoplated RAVE is available for the previous 24 hours
def check_for_intp_rave(intp_dir, fcst_dates, rave_to_intp):
    intp_avail_hours = []
    intp_non_avail_hours = []
    # There are four situations here.
    #   1) the file is missing (interpolate a new file)
    #   2) the file is present (use it)
    #   3) there is a link, but it's broken (interpolate a new file)
    #   4) there is a valid link (use it)
    for date in fcst_dates:
        file_name = f'{rave_to_intp}{date}00_{date}59.nc'
        file_path = os.path.join(intp_dir, file_name)
        file_exists = os.path.isfile(file_path)
        is_link = os.path.islink(file_path)
        is_valid_link = is_link and os.path.exists(file_path)

        if file_exists or is_valid_link:
            print(f'RAVE interpolated file available for {file_name}')
            intp_avail_hours.append(date)
        else:
            print(f'Interpolated file non available, interpolate RAVE for {file_name}')
            intp_non_avail_hours.append(date)

    print(f'Available interpolated files for hours: {intp_avail_hours}, Non available interpolated files for hours: {intp_non_avail_hours}')
    
    inp_files_2use = len(intp_avail_hours) > 0

    return(intp_avail_hours, intp_non_avail_hours, inp_files_2use)

#Check if raw RAVE in intp_non_avail_hours list is available for interpolatation
def check_for_raw_rave(RAVE, intp_non_avail_hours, intp_avail_hours):
    rave_avail = []
    rave_avail_hours = []
    rave_nonavail_hours_test = []
    for date in intp_non_avail_hours:
        wildcard_name = f'*-3km*{date}*{date}59590*.nc'
        name_retro = f'*3km*{date}*{date}*.nc'
        matching_files = [f for f in os.listdir(RAVE) if fnmatch.fnmatch(f, wildcard_name) or fnmatch.fnmatch(f, name_retro)]
        print(f'Find raw RAVE: {matching_files}')
        if not matching_files:
            print(f'Raw RAVE non_available for interpolation {date}')
            rave_nonavail_hours_test.append(date)
        else:
            print(f'Raw RAVE available for interpolation {matching_files}')
            rave_avail.append(matching_files)
            rave_avail_hours.append(date)

    print(f"Raw RAVE available: {rave_avail_hours}, rave_nonavail_hours: {rave_nonavail_hours_test}")
    first_day = not rave_avail_hours and not intp_avail_hours

    print(f'FIRST DAY?: {first_day}')
    return(rave_avail, rave_avail_hours, rave_nonavail_hours_test, first_day)

#Create source and target fields
def creates_st_fields(grid_in, grid_out, intp_dir, rave_avail_hours):

    # Open datasets with context managers
    with xr.open_dataset(grid_in) as ds_in, xr.open_dataset(grid_out) as ds_out:
        tgt_area = ds_out['area']
        tgt_latt = ds_out['grid_latt']
        tgt_lont = ds_out['grid_lont']
        src_latt = ds_in['grid_latt']

        srcgrid = ESMF.Grid(np.array(src_latt.shape), staggerloc=[ESMF.StaggerLoc.CENTER, ESMF.StaggerLoc.CORNER], coord_sys=ESMF.CoordSys.SPH_DEG)
        tgtgrid = ESMF.Grid(np.array(tgt_latt.shape), staggerloc=[ESMF.StaggerLoc.CENTER, ESMF.StaggerLoc.CORNER], coord_sys=ESMF.CoordSys.SPH_DEG)

        srcfield = ESMF.Field(srcgrid, name='test', staggerloc=ESMF.StaggerLoc.CENTER)
        tgtfield = ESMF.Field(tgtgrid, name='test', staggerloc=ESMF.StaggerLoc.CENTER)

    print('Grid in and out files available. Generating target and source fields')
    return(srcfield, tgtfield, tgt_latt, tgt_lont, srcgrid, tgtgrid, src_latt, tgt_area)

#Define output and variable meta data
def create_emiss_file(fout, cols, rows):
    """Create necessary dimensions for the emission file."""
    fout.createDimension('t', None)
    fout.createDimension('lat', cols)
    fout.createDimension('lon', rows)
    setattr(fout, 'PRODUCT_ALGORITHM_VERSION', 'Beta')
    setattr(fout, 'TIME_RANGE', '1 hour')

def Store_latlon_by_Level(fout, varname, var, long_name, units, dim, fval, sfactor):
    """Store a 2D variable (latitude/longitude) in the file."""
    var_out = fout.createVariable(varname,   'f4', ('lat','lon'))
    var_out.units=units
    var_out.long_name=long_name
    var_out.standard_name=varname
    fout.variables[varname][:]=var
    var_out.FillValue=fval
    var_out.coordinates='geolat geolon'

def Store_by_Level(fout, varname, long_name, units, dim, fval, sfactor):
    """Store a 3D variable (time, latitude/longitude) in the file."""
    var_out = fout.createVariable(varname,   'f4', ('t','lat','lon'))
    var_out.units=units
    var_out.long_name = long_name
    var_out.standard_name=long_name
    var_out.FillValue=fval
    var_out.coordinates='t geolat geolon'

#create a dummy rave interpolated file if first day or regrider fails
def create_dummy(intp_dir, current_day, tgt_latt, tgt_lont, cols, rows):
    file_path = os.path.join(intp_dir, f'SMOKE_RRFS_data_{current_day}00.nc')
    dummy_file = np.zeros((cols, rows))  # Changed to 3D to match the '3D' dimensions
    with Dataset(file_path, 'w') as fout:
        create_emiss_file(fout, cols, rows)
        # Store latitude and longitude
        Store_latlon_by_Level(fout, 'geolat', tgt_latt, 'cell center latitude', 'degrees_north', '2D','-9999.f','1.f')
        Store_latlon_by_Level(fout, 'geolon', tgt_lont, 'cell center longitude', 'degrees_east', '2D','-9999.f','1.f')

        # Initialize and store each variable
        Store_by_Level(fout,'frp_davg','Daily mean Fire Radiative Power','MW','3D','0.f','1.f')
        fout.variables['frp_davg'][0, :, :] = dummy_file 
        Store_by_Level(fout,'ebb_rate','Total EBB emission','ug m-2 s-1','3D','0.f','1.f')
        fout.variables['ebb_rate'][0, :, :] = dummy_file
        Store_by_Level(fout,'fire_end_hr','Hours since fire was last detected','hrs','3D','0.f','1.f')
        fout.variables['fire_end_hr'][0, :, :] = dummy_file
        Store_by_Level(fout,'hwp_davg','Daily mean Hourly Wildfire Potential', 'none','3D','0.f','1.f')
        fout.variables['hwp_davg'][0, :, :] = dummy_file
        Store_by_Level(fout,'totprcp_24hrs','Sum of precipitation', 'm', '3D', '0.f','1.f') 
        fout.variables['totprcp_24hrs'][0, :, :] = dummy_file

    return "Emissions dummy file created successfully"

#generate regridder
def generate_regrider(rave_avail_hours, srcfield, tgtfield, weightfile, inp_files_2use, intp_avail_hours):
    print('Checking conditions for generating regridder.')
    use_dummy_emiss = len(rave_avail_hours) == 0 and len(intp_avail_hours) == 0
    regridder = None

    if not use_dummy_emiss:
        try:
            print('Generating regridder.')
            regridder = ESMF.RegridFromFile(srcfield, tgtfield, weightfile)
            print('Regridder generated successfully.')
        except ValueError as e:
            print(f'Regridder failed due to a ValueError: {e}.')
        except OSError as e:
            print(f'Regridder failed due to an OSError: {e}. Check if the weight file exists and is accessible.')
        except (FileNotFoundError, IOError, RuntimeError, TypeError, KeyError, IndexError, MemoryError) as e:
            print(f'Regridder failed due to corrupted file: {e}. Check if RAVE file has a different grid or format. ')
        except Exception as e:
            print(f'An unexpected error occurred while generating regridder: {e}.')
    else:
        use_dummy_emiss = True

    return(regridder, use_dummy_emiss)

#process RAVE available for interpolation
def interpolate_rave(RAVE, rave_avail, rave_avail_hours, use_dummy_emiss, vars_emis, regridder, 
                    srcgrid, tgtgrid, rave_to_intp, intp_dir, src_latt, tgt_latt, tgt_lont, cols, rows):
    for index, current_hour in enumerate(rave_avail_hours):
        file_name = rave_avail[index]
        rave_file_path = os.path.join(RAVE, file_name[0])  
        
        print(f"Processing file: {rave_file_path} for hour: {current_hour}")

        if not use_dummy_emiss and os.path.exists(rave_file_path):
            try:
                with xr.open_dataset(rave_file_path, decode_times=False) as ds_togrid:
                    try:
                        ds_togrid = ds_togrid[['FRP_MEAN', 'FRE']]
                    except KeyError as e:
                        print(f"Missing required variables in {rave_file_path}: {e}")
                        continue

                    output_file_path = os.path.join(intp_dir, f'{rave_to_intp}{current_hour}00_{current_hour}59.nc')
                    print('=============before regridding===========', 'FRP_MEAN')
                    print(np.sum(ds_togrid['FRP_MEAN'], axis=(1, 2)))

                    try:
                        with Dataset(output_file_path, 'w') as fout:
                            create_emiss_file(fout, cols, rows)
                            Store_latlon_by_Level(fout, 'geolat', tgt_latt, 'cell center latitude', 'degrees_north', '2D', '-9999.f', '1.f')
                            Store_latlon_by_Level(fout, 'geolon', tgt_lont, 'cell center longitude', 'degrees_east', '2D', '-9999.f', '1.f')

                            for svar in vars_emis:
                                try:
                                    srcfield = ESMF.Field(srcgrid, name=svar, staggerloc=ESMF.StaggerLoc.CENTER)
                                    tgtfield = ESMF.Field(tgtgrid, name=svar, staggerloc=ESMF.StaggerLoc.CENTER)
                                    src_rate = ds_togrid[svar].fillna(0)
                                    src_QA = xr.where(ds_togrid['FRE'] > 1000, src_rate, 0.0)
                                    srcfield.data[...] = src_QA[0, :, :]
                                    tgtfield = regridder(srcfield, tgtfield)

                                    if svar == 'FRP_MEAN':
                                        Store_by_Level(fout, 'frp_avg_hr', 'Mean Fire Radiative Power', 'MW', '3D', '0.f', '1.f')
                                        tgt_rate = tgtfield.data
                                        fout.variables['frp_avg_hr'][0, :, :] = tgt_rate
                                        print('=============after regridding===========' + svar)
                                        print(np.sum(tgt_rate))
                                    elif svar == 'FRE':
                                        Store_by_Level(fout, 'FRE', 'FRE', 'MJ', '3D', '0.f', '1.f')
                                        tgt_rate = tgtfield.data
                                        fout.variables['FRE'][0, :, :] = tgt_rate
                                except (ValueError, KeyError) as e:
                                    print(f"Error processing variable {svar} in {rave_file_path}: {e}")
                    except (OSError, IOError, RuntimeError, FileNotFoundError, TypeError, IndexError, MemoryError) as e:
                        print(f"Error creating or writing to NetCDF file {output_file_path}: {e}")
            except (OSError, IOError, RuntimeError, FileNotFoundError, TypeError, IndexError, MemoryError) as e:
                print(f"Error reading NetCDF file {rave_file_path}: {e}")
        else:
            print(f"File not found or dummy emissions required: {rave_file_path}")