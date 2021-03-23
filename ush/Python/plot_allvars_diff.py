################################################################################
####  Python Script Documentation Block
#
# Script name:       	plot_allvars_diff.py
# Script description:  	Generates difference plots from FV3-LAM post processed
#                       grib2 output over the CONUS
#
# Authors:  Ben Blake		Org: NOAA/NWS/NCEP/EMC		Date: 2020-08-24
#           David Wright 	Org: University of Michigan
#
# Instructions:		Make sure all the necessary modules can be imported.
#                       Seven command line arguments are needed:
#                       1. Cycle date/time in YYYYMMDDHH format
#                       2. Starting forecast hour
#                       3. Ending forecast hour
#                       4. Forecast hour increment
#                       5. EXPT_DIR_1: Experiment 1 directory
#                          -Postprocessed data should be found in the directory:
#                            EXPT_DIR_1/YYYYMMDDHH/postprd/
#                       6. EXPT_DIR_2: Experiment 2 directory
#                          -Postprocessed data should be found in the directory:
#                            EXPT_DIR_2/YYYYMMDDHH/postprd/
#                       7. CARTOPY_DIR:  Base directory of cartopy shapefiles
#                          -Shapefiles cannot be directly downloaded to NOAA
#                            machines from the internet, so shapefiles need to
#                            be downloaded if geopolitical boundaries are
#                            desired on the maps.
#                          -File structure should be:
#                            CARTOPY_DIR/shapefiles/natural_earth/cultural/*.shp
#                          -More information regarding files needed to setup
#                            display maps in Cartopy, see SRW App Users' Guide
#
#           		To create plots for forecast hours 20-24 from 5/7 00Z
#                        cycle with hourly output:
#                          python plot_allvars_diff.py 2020050700  20 24 1 \
#                          /path/to/expt_dir_1 /path/to/expt_dir_2 \
#                          /path/to/base/cartopy/maps
#
#                       The variable domains in this script can be set to either
#                         'conus' for a CONUS map or 'regional' where the map
#                         is defined from variables in the grib2 files
#
################################################################################

#-------------Import modules --------------------------#
import pygrib
import cartopy.crs as ccrs
from cartopy.mpl.gridliner import LONGITUDE_FORMATTER, LATITUDE_FORMATTER
import cartopy.feature as cfeature
import matplotlib
matplotlib.use('Agg')
import io
import matplotlib.pyplot as plt
import dateutil.relativedelta, dateutil.parser
from PIL import Image
from matplotlib.gridspec import GridSpec
import numpy as np
import time,os,sys,multiprocessing
import multiprocessing.pool
from scipy import ndimage
import pyproj
import argparse
import cartopy

#--------------Define some functions ------------------#

def ndate(cdate,hours):
   if not isinstance(cdate, str):
     if isinstance(cdate, int):
       cdate=str(cdate)
     else:
       sys.exit('NDATE: Error - input cdate must be string or integer.  Exit!')
   if not isinstance(hours, int):
     if isinstance(hours, str):
       hours=int(hours)
     else:
       sys.exit('NDATE: Error - input delta hour must be a string or integer.  Exit!')

   indate=cdate.strip()
   hh=indate[8:10]
   yyyy=indate[0:4]
   mm=indate[4:6]
   dd=indate[6:8]
   #set date/time field
   parseme=(yyyy+' '+mm+' '+dd+' '+hh)
   datetime_cdate=dateutil.parser.parse(parseme)
   valid=datetime_cdate+dateutil.relativedelta.relativedelta(hours=+hours)
   vyyyy=str(valid.year)
   vm=str(valid.month).zfill(2)
   vd=str(valid.day).zfill(2)
   vh=str(valid.hour).zfill(2)
   return vyyyy+vm+vd+vh


def clear_plotables(ax,keep_ax_lst,fig):
  #### - step to clear off old plottables but leave the map info - ####
  if len(keep_ax_lst) == 0 :
    print("clear_plotables WARNING keep_ax_lst has length 0. Clearing ALL plottables including map info!")
  cur_ax_children = ax.get_children()[:]
  if len(cur_ax_children) > 0:
    for a in cur_ax_children:
      if a not in keep_ax_lst:
       # if the artist isn't part of the initial set up, remove it
        a.remove()


def compress_and_save(filename):
  #### - compress and save the image - ####
  ram = io.BytesIO()
  plt.savefig(ram, format='png', bbox_inches='tight', dpi=150)
  ram.seek(0)
  im = Image.open(ram)
  im2 = im.convert('RGB')#.convert('P', palette=Image.ADAPTIVE)
  im2.save(filename, format='PNG')

def cmap_t2m():
 # Create colormap for 2-m temperature
 # Modified version of the ncl_t2m colormap
    r=np.array([255,128,0,  70, 51, 0,  255,0, 0,  51, 255,255,255,255,255,171,128,128,36,162,255])
    g=np.array([0,  0,  0,  70, 102,162,255,92,128,185,255,214,153,102,0,  0,  0,  68, 36,162,255])
    b=np.array([255,128,128,255,255,255,255,0, 0,  102,0,  112,0,  0,  0,  56, 0,  68, 36,162,255])
    xsize=np.arange(np.size(r))
    r = r/255.
    g = g/255.
    b = b/255.
    red = []
    green = []
    blue = []
    for i in range(len(xsize)):
        xNorm=np.float(i)/(np.float(np.size(r))-1.0)
        red.append([xNorm,r[i],r[i]])
        green.append([xNorm,g[i],g[i]])
        blue.append([xNorm,b[i],b[i]])
    colorDict = {"red":red, "green":green, "blue":blue}
    cmap_t2m_coltbl = matplotlib.colors.LinearSegmentedColormap('CMAP_T2M_COLTBL',colorDict)
    return cmap_t2m_coltbl


def cmap_q2m():
 # Create colormap for 2-m dew point temperature
    r=np.array([255,179,96,128,0, 0,  51, 0,  0,  0,  133,51, 70, 0,  128,128,180])
    g=np.array([255,179,96,128,92,128,153,155,155,255,162,102,70, 0,  0,  0,  0])
    b=np.array([255,179,96,0,  0, 0,  102,155,255,255,255,255,255,128,255,128,128])
    xsize=np.arange(np.size(r))
    r = r/255.
    g = g/255.
    b = b/255.
    red = []
    green = []
    blue = []
    for i in range(len(xsize)):
        xNorm=np.float(i)/(np.float(np.size(r))-1.0)
        red.append([xNorm,r[i],r[i]])
        green.append([xNorm,g[i],g[i]])
        blue.append([xNorm,b[i],b[i]])
    colorDict = {"red":red, "green":green, "blue":blue}
    cmap_q2m_coltbl = matplotlib.colors.LinearSegmentedColormap('CMAP_Q2M_COLTBL',colorDict)
    cmap_q2m_coltbl.set_over(color='deeppink')
    return cmap_q2m_coltbl


def rotate_wind(true_lat,lov_lon,earth_lons,uin,vin,proj,inverse=False):
  #  Rotate winds from LCC relative to earth relative (or vice-versa if inverse==true)
  #   This routine is vectorized and *should* work on any size 2D vg and ug arrays.
  #   Program will quit if dimensions are too large.
  #
  # Input args:
  #  true_lat = True latitidue for LCC projection (single value in degrees)
  #  lov_lon  = The LOV value from grib (e.g. - -95.0) (single value in degrees)
  #              Grib doc says: "Lov = orientation of the grid; i.e. the east longitude value of
  #                              the meridian which is parallel to the Y-axis (or columns of the grid)
  #                              along which latitude increases as the Y-coordinate increases (the
  #                              orientation longitude may or may not appear on a particular grid).
  #
  #  earth_lons = Earth relative longitudes (can be an array, in degrees)
  #  uin, vin     = Input winds to rotate
  #
  # Returns:
  #  uout, vout = Output, rotated winds
  #-----------------------------------------------------------------------------------------------------

  # Get size and length of input u winds, if not 2d, raise an error
  q=np.shape(uin)
  ndims=len(q)
  if ndims > 2:
    # Raise error and quit!
    raise SystemExit("Input winds for rotation have greater than 2 dimensions!")
  if lov_lon > 0.: lov_lon=lov_lon-360.
  dtr=np.pi/180.0             # Degrees to radians

  if not isinstance(inverse, bool):
    raise TypeError("**kwarg inverse must be of type bool.")

  # Compute rotation constant which is also
  # known as the Lambert cone constant.  In the case
  # of a polar stereographic projection, this is one.
  # See the following pdf for excellent documentation
  # http://www.dtcenter.org/met/users/docs/write_ups/velocity.pdf
  if proj.lower()=='lcc':
    rotcon_p=np.sin(true_lat*dtr)
  elif proj.lower() in ['stere','spstere', 'npstere']:
    rotcon_p=1.0
  else:
    raise SystemExit("Unsupported map projection: "+proj.lower()+" for wind rotation.")

  angles = rotcon_p*(earth_lons-lov_lon)*dtr
  sinx2 = np.sin(angles)
  cosx2 = np.cos(angles)

  # Steps below are elementwise products, not matrix mutliplies
  if inverse==False:
    # Return the earth relative winds
    uout = cosx2*uin+sinx2*vin
    vout =-sinx2*uin+cosx2*vin
  elif inverse==True:
    # Return the grid relative winds
    uout = cosx2*uin-sinx2*vin
    vout = sinx2*uin+cosx2*vin

  return uout,vout


#-------------Start of script -------------------------#

# Define required positional arguments
parser = argparse.ArgumentParser()
parser.add_argument("Cycle date/time in YYYYMMDDHH format")
parser.add_argument("Starting forecast hour")
parser.add_argument("Ending forecast hour")
parser.add_argument("Forecast hour increment")
parser.add_argument("Path to experiment 1 directory")
parser.add_argument("Path to experiment 2 directory")
parser.add_argument("Path to base directory of cartopy shapefiles")
args = parser.parse_args()

# Read date/time, forecast hour, and directory paths from command line
ymdh = str(sys.argv[1])
ymd = ymdh[0:8]
year = int(ymdh[0:4])
month = int(ymdh[4:6])
day = int(ymdh[6:8])
hour = int(ymdh[8:10])
cyc = str(hour).zfill(2)
print(year, month, day, hour)

# Define the range of forecast hours to create plots for
start_fhr = int(sys.argv[2])
end_fhr = int(sys.argv[3])
increment_fhr = int(sys.argv[4])
if (start_fhr == end_fhr) or (increment_fhr == 0):
  fhours = [start_fhr]
else:
  num = int(((end_fhr - start_fhr) / increment_fhr) + 1)
  fhours = np.linspace(start_fhr,end_fhr,num,dtype='int')
print(fhours)

EXPT_DIR_1 = str(sys.argv[5])
EXPT_DIR_2 = str(sys.argv[6])
CARTOPY_DIR = str(sys.argv[7])

# Loop over forecast hours
for fhr in fhours:
  fhour = str(fhr).zfill(3)
  print('Working on forecast hour '+fhour)
  itime = ymdh
  vtime = ndate(itime,int(fhr))


# Define the location of the input files
  data1 = pygrib.open(EXPT_DIR_1+'/'+ymdh+'/postprd/rrfs.t'+cyc+'z.bgdawpf'+fhour+'.tm00.grib2')
  data2 = pygrib.open(EXPT_DIR_2+'/'+ymdh+'/postprd/rrfs.t'+cyc+'z.bgdawpf'+fhour+'.tm00.grib2')

# Get the lats and lons
  grids = [data1, data2]
  lats = []
  lons = []
  lats_shift = []
  lons_shift = []

  for data in grids:
    # Unshifted grid for contours and wind barbs
    lat, lon = data[1].latlons()
    lats.append(lat)
    lons.append(lon)

    # Shift grid for pcolormesh
    lat1 = data[1]['latitudeOfFirstGridPointInDegrees']
    lon1 = data[1]['longitudeOfFirstGridPointInDegrees']
    try:
        nx = data[1]['Nx']
        ny = data[1]['Ny']
    except:
        nx = data[1]['Ni']
        ny = data[1]['Nj']
    dx = data[1]['DxInMetres']
    dy = data[1]['DyInMetres']
    pj = pyproj.Proj(data[1].projparams)
    llcrnrx, llcrnry = pj(lon1,lat1)
    llcrnrx = llcrnrx - (dx/2.)
    llcrnry = llcrnry - (dy/2.)
    x = llcrnrx + dx*np.arange(nx)
    y = llcrnry + dy*np.arange(ny)
    x,y = np.meshgrid(x,y)
    lon, lat = pj(x, y, inverse=True)
    lats_shift.append(lat)
    lons_shift.append(lon)

# Unshifted lat/lon arrays grabbed directly using latlons() method
  lat = lats[0]
  lon = lons[0]
  lat2 = lats[1]
  lon2 = lons[1]

# Shifted lat/lon arrays for pcolormesh
  lat_shift = lats_shift[0]
  lon_shift = lons_shift[0]
  lat2_shift = lats_shift[1]
  lon2_shift = lons_shift[1]

  Lat0 = data1[1]['LaDInDegrees']
  Lon0 = data1[1]['LoVInDegrees']
  print(Lat0)
  print(Lon0)

# Specify plotting domains
# User can add domains here, just need to specify lat/lon information below
# (if dom == 'conus' block)
  domains=['conus']    # Other option is 'regional'

###################################################
# Read in all variables and calculate differences #
###################################################
  t1a = time.perf_counter()

# Sea level pressure
  slp_1 = data1.select(name='Pressure reduced to MSL')[0].values * 0.01
  slpsmooth_1 = ndimage.filters.gaussian_filter(slp_1, 13.78)
  slp_2 = data2.select(name='Pressure reduced to MSL')[0].values * 0.01
  slpsmooth_2 = ndimage.filters.gaussian_filter(slp_2, 13.78)
  slp_diff = slp_2 - slp_1

# 2-m temperature
  tmp2m_1 = data1.select(name='2 metre temperature')[0].values
  tmp2m_1 = (tmp2m_1 - 273.15)*1.8 + 32.0
  tmp2m_2 = data2.select(name='2 metre temperature')[0].values
  tmp2m_2 = (tmp2m_2 - 273.15)*1.8 + 32.0
  tmp2m_diff = tmp2m_2 - tmp2m_1

# 2-m dew point temperature
  dew2m_1 = data1.select(name='2 metre dewpoint temperature')[0].values
  dew2m_1 = (dew2m_1 - 273.15)*1.8 + 32.0
  dew2m_2 = data2.select(name='2 metre dewpoint temperature')[0].values
  dew2m_2 = (dew2m_2 - 273.15)*1.8 + 32.0
  dew2m_diff = dew2m_2 - dew2m_1

# 10-m wind speed
  uwind_1 = data1.select(name='10 metre U wind component')[0].values * 1.94384
  vwind_1 = data1.select(name='10 metre V wind component')[0].values * 1.94384
  uwind_2 = data2.select(name='10 metre U wind component')[0].values * 1.94384
  vwind_2 = data2.select(name='10 metre V wind component')[0].values * 1.94384
# Rotate winds from grid relative to Earth relative
  uwind_1, vwind_1 = rotate_wind(Lat0,Lon0,lon,uwind_1,vwind_1,'lcc',inverse=False)
  uwind_2, vwind_2 = rotate_wind(Lat0,Lon0,lon2,uwind_2,vwind_2,'lcc',inverse=False)
  wspd10m_1 = np.sqrt(uwind_1**2 + vwind_1**2)
  wspd10m_2 = np.sqrt(uwind_2**2 + vwind_2**2)
  wspd10m_diff = wspd10m_2 - wspd10m_1

# Surface-based CAPE
  cape_1 = data1.select(name='Convective available potential energy',typeOfLevel='surface')[0].values
  cape_2 = data2.select(name='Convective available potential energy',typeOfLevel='surface')[0].values
  cape_diff = cape_2 - cape_1

# Surface-based CIN
  cin_1 = data1.select(name='Convective inhibition',typeOfLevel='surface')[0].values
  cin_2 = data2.select(name='Convective inhibition',typeOfLevel='surface')[0].values
  cin_diff = cin_2 - cin_1

# 500 mb height, wind, vorticity
  z500_1 = data1.select(name='Geopotential Height',level=500)[0].values * 0.1
  z500_1 = ndimage.filters.gaussian_filter(z500_1, 6.89)
  z500_2 = data2.select(name='Geopotential Height',level=500)[0].values * 0.1
  z500_2 = ndimage.filters.gaussian_filter(z500_2, 6.89)
  z500_diff = z500_2 - z500_1
  vort500_1 = data1.select(name='Absolute vorticity',level=500)[0].values * 100000
  vort500_1 = ndimage.filters.gaussian_filter(vort500_1,1.7225)
  vort500_1[vort500_1 > 1000] = 0	# Mask out undefined values on domain edge
  vort500_2 = data2.select(name='Absolute vorticity',level=500)[0].values * 100000
  vort500_2 = ndimage.filters.gaussian_filter(vort500_2,1.7225)
  vort500_2[vort500_2 > 1000] = 0	# Mask out undefined values on domain edge
  u500_1 = data1.select(name='U component of wind',level=500)[0].values * 1.94384
  u500_2 = data2.select(name='U component of wind',level=500)[0].values * 1.94384
  v500_1 = data1.select(name='V component of wind',level=500)[0].values * 1.94384
  v500_2 = data2.select(name='V component of wind',level=500)[0].values * 1.94384
# Rotate winds from grid relative to Earth relative
  u500_1, v500_1 = rotate_wind(Lat0,Lon0,lon,u500_1,v500_1,'lcc',inverse=False)
  u500_2, v500_2 = rotate_wind(Lat0,Lon0,lon2,u500_2,v500_2,'lcc',inverse=False)

# 250 mb winds
  u250_1 = data1.select(name='U component of wind',level=250)[0].values * 1.94384
  u250_2 = data2.select(name='U component of wind',level=250)[0].values * 1.94384
  v250_1 = data1.select(name='V component of wind',level=250)[0].values * 1.94384
  v250_2 = data2.select(name='V component of wind',level=250)[0].values * 1.94384
# Rotate winds from grid relative to Earth relative
  u250_1, v250_1 = rotate_wind(Lat0,Lon0,lon,u250_1,v250_1,'lcc',inverse=False)
  u250_2, v250_2 = rotate_wind(Lat0,Lon0,lon2,u250_2,v250_2,'lcc',inverse=False)
  wspd250_1 = np.sqrt(u250_1**2 + v250_1**2)
  wspd250_2 = np.sqrt(u250_2**2 + v250_2**2)
  wspd250_diff = wspd250_2 - wspd250_1

# Total precipitation
  qpf_1 = data1.select(name='Total Precipitation',lengthOfTimeRange=fhr)[0].values * 0.0393701
  qpf_2 = data2.select(name='Total Precipitation',lengthOfTimeRange=fhr)[0].values * 0.0393701
  qpf_diff = qpf_2 - qpf_1

# Composite reflectivity
  refc_1 = data1.select(name='Maximum/Composite radar reflectivity')[0].values
  refc_2 = data2.select(name='Maximum/Composite radar reflectivity')[0].values

  if (fhr > 0):
# Max/Min Hourly 2-5 km Updraft Helicity
    maxuh25_1 = data1.select(stepType='max',parameterName="199",topLevel=5000,bottomLevel=2000)[0].values
    maxuh25_2 = data2.select(stepType='max',parameterName="199",topLevel=5000,bottomLevel=2000)[0].values
    minuh25_1 = data1.select(stepType='min',parameterName="200",topLevel=5000,bottomLevel=2000)[0].values
    minuh25_2 = data2.select(stepType='min',parameterName="200",topLevel=5000,bottomLevel=2000)[0].values
    maxuh25_1[maxuh25_1 < 10] = 0
    maxuh25_2[maxuh25_2 < 10] = 0
    minuh25_1[minuh25_1 > -10] = 0
    minuh25_2[minuh25_2 > -10] = 0
    uh25_1 = maxuh25_1 + minuh25_1
    uh25_2 = maxuh25_2 + minuh25_2
    uh25_diff = uh25_2 - uh25_1


  t2a = time.perf_counter()
  t3a = round(t2a-t1a, 3)
  print(("%.3f seconds to read all messages") % t3a)


########################################
#    START PLOTTING FOR EACH DOMAIN    #
########################################

  def main():

    # Number of processes must coincide with the number of domains to plot
    #pool = multiprocessing.Pool(len(domains))
    #pool.map(plot_all,domains)

    # To avoid import multiprocessing recursively on MacOS/Windows etc.
    # Anyway since we only have one domain for SRW application
    for dom in domains:
        plot_all(dom)

  def plot_all(dom):

    t1dom = time.perf_counter()

  # Map corners for each domain
    if dom == 'conus':
      llcrnrlon = -120.5
      llcrnrlat = 21.0
      urcrnrlon = -64.5
      urcrnrlat = 49.0
      lat_0 = 35.4
      lon_0 = -97.6
      extent=[llcrnrlon-3,urcrnrlon-6,llcrnrlat-1,urcrnrlat+2]
    elif dom == 'regional':
      llcrnrlon = np.min(lon)
      llcrnrlat = np.min(lat)
      urcrnrlon = np.max(lon)
      urcrnrlat = np.max(lat)
      lat_0 = Lat0
      lon_0 = Lon0
      extent=[llcrnrlon,urcrnrlon,llcrnrlat-1,urcrnrlat]


  # create figure and axes instances
    fig = plt.figure(figsize=(10,10))
    gs = GridSpec(9,9,wspace=0.0,hspace=0.0)

  # Define where Cartopy Maps are located
    cartopy.config['data_dir'] = CARTOPY_DIR

    back_res='50m'
    back_img='on'

  # set up the map background with cartopy
    myproj=ccrs.LambertConformal(central_longitude=lon_0, central_latitude=lat_0, false_easting=0.0,
                            false_northing=0.0, secant_latitudes=None, standard_parallels=None,
                            globe=None)
    ax1 = fig.add_subplot(gs[0:4,0:4], projection=myproj)
    ax2 = fig.add_subplot(gs[0:4,5:], projection=myproj)
    ax3 = fig.add_subplot(gs[5:,1:8], projection=myproj)
    ax1.set_extent(extent)
    ax2.set_extent(extent)
    ax3.set_extent(extent)

    fline_wd = 0.5  # line width
    falpha = 0.3    # transparency

  # natural_earth
#    land=cfeature.NaturalEarthFeature('physical','land',back_res,
#                      edgecolor='face',facecolor=cfeature.COLORS['land'],
#                      alpha=falpha)
    lakes=cfeature.NaturalEarthFeature('physical','lakes',back_res,
                      edgecolor='blue',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)
    coastline=cfeature.NaturalEarthFeature('physical','coastline',
                      back_res,edgecolor='blue',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)
    states=cfeature.NaturalEarthFeature('cultural','admin_1_states_provinces',
                      back_res,edgecolor='black',facecolor='none',
                      linewidth=fline_wd,linestyle=':',alpha=falpha)
    borders=cfeature.NaturalEarthFeature('cultural','admin_0_countries',
                      back_res,edgecolor='red',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)

  # All lat lons are earth relative, so setup the associated projection correct for that data
    transform = ccrs.PlateCarree()

  # high-resolution background images
    if back_img=='on':
       img = plt.imread(CARTOPY_DIR+'/raster_files/NE1_50M_SR_W.tif')
       ax1.imshow(img, origin='upper', transform=transform)
       ax2.imshow(img, origin='upper', transform=transform)
       ax3.imshow(img, origin='upper', transform=transform)

#  ax.add_feature(land)
    ax1.add_feature(lakes)
    ax1.add_feature(states)
    ax1.add_feature(borders)
    ax1.add_feature(coastline)
    ax2.add_feature(lakes)
    ax2.add_feature(states)
    ax2.add_feature(borders)
    ax2.add_feature(coastline)
    ax3.add_feature(lakes)
    ax3.add_feature(states)
    ax3.add_feature(borders)
    ax3.add_feature(coastline)

# Map/figure has been set up here, save axes instances for use again later
    keep_ax_lst_1 = ax1.get_children()[:]
    keep_ax_lst_2 = ax2.get_children()[:]
    keep_ax_lst_3 = ax3.get_children()[:]

# colors for difference plots, only need to define once
    diffcolors = ['blue','#1874CD','dodgerblue','deepskyblue','turquoise','white','white','#EEEE00','#EEC900','darkorange','orangered','red']


################################
  # Plot SLP
################################
    t1 = time.perf_counter()
    print(('Working on slp for '+dom))

    units = 'mb'
    clevs = [976,980,984,988,992,996,1000,1004,1008,1012,1016,1020,1024,1028,1032,1036,1040,1044,1048,1052]
    clevsdiff = [-12,-10,-8,-6,-4,-2,0,2,4,6,8,10,12]
    cm = plt.cm.Spectral_r
    cmdiff = matplotlib.colors.ListedColormap(diffcolors)
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
    normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

    cs1_a = ax1.pcolormesh(lon_shift,lat_shift,slp_1,transform=transform,cmap=cm,norm=norm)
    cbar1 = plt.colorbar(cs1_a,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=5)
    cs1_b = ax1.contour(lon_shift,lat_shift,slpsmooth_1,np.arange(940,1060,4),colors='black',linewidths=1.25,transform=transform)
    plt.clabel(cs1_b,np.arange(940,1060,4),inline=1,fmt='%d',fontsize=6)
    ax1.text(.5,1.03,'FV3-LAM SLP ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=8,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs2_a = ax2.pcolormesh(lon2_shift,lat2_shift,slp_2,transform=transform,cmap=cm,norm=norm)
    cbar2 = plt.colorbar(cs2_a,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar2.set_label(units,fontsize=6)
    cbar2.ax.tick_params(labelsize=5)
    cs2_b = ax2.contour(lon2_shift,lat2_shift,slpsmooth_2,np.arange(940,1060,4),colors='black',linewidths=1.25,transform=transform)
    plt.clabel(cs2_b,np.arange(940,1060,4),inline=1,fmt='%d',fontsize=6)
    ax2.text(.5,1.03,'FV3-LAM-2 SLP ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=8,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs = ax3.pcolormesh(lon2_shift,lat2_shift,slp_diff,transform=transform,cmap=cmdiff,norm=normdiff)
    cs.cmap.set_under('darkblue')
    cs.cmap.set_over('darkred')
    cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar3.set_label(units,fontsize=6)
    cbar3.ax.tick_params(labelsize=5)
    ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM SLP ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/slp_diff_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot slp for: '+dom) % t3)


#################################
  # Plot 2-m T
#################################
    t1 = time.perf_counter()
    print(('Working on t2m for '+dom))

  # Clear off old plottables but keep all the map info
    cbar1.remove()
    cbar2.remove()
    cbar3.remove()
    clear_plotables(ax1,keep_ax_lst_1,fig)
    clear_plotables(ax2,keep_ax_lst_2,fig)
    clear_plotables(ax3,keep_ax_lst_3,fig)

    units = '\xb0''F'
    clevs = np.linspace(-16,134,51)
    clevsdiff = [-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6]
#  cm = plt.cm.Spectral_r
    cm = cmap_t2m()
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
    normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

    cs_1 = ax1.pcolormesh(lon_shift,lat_shift,tmp2m_1,transform=transform,cmap=cm,norm=norm)
    cs_1.cmap.set_under('white')
    cs_1.cmap.set_over('white')
    cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,ticks=[-16,-4,8,20,32,44,56,68,80,92,104,116,128],extend='both')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=5)
    ax1.text(.5,1.03,'FV3-LAM 2-m Temperature ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs_2 = ax2.pcolormesh(lon2_shift,lat2_shift,tmp2m_2,transform=transform,cmap=cm,norm=norm)
    cs_2.cmap.set_under('white')
    cs_2.cmap.set_over('white')
    cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,ticks=[-16,-4,8,20,32,44,56,68,80,92,104,116,128],extend='both')
    cbar2.set_label(units,fontsize=6)
    cbar2.ax.tick_params(labelsize=5)
    ax2.text(.5,1.03,'FV3-LAM-2 2-m Temperature ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs = ax3.pcolormesh(lon2_shift,lat2_shift,tmp2m_diff,transform=transform,cmap=cmdiff,norm=normdiff)
    cs.cmap.set_under('darkblue')
    cs.cmap.set_over('darkred')
    cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar3.set_label(units,fontsize=6)
    cbar3.ax.tick_params(labelsize=6)
    ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM 2-m Temperature ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/2mt_diff_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot 2mt for: '+dom) % t3)


#################################
  # Plot 2-m Dew Point
#################################
    t1 = time.perf_counter()
    print(('Working on 2mdew for '+dom))

  # Clear off old plottables but keep all the map info
    cbar1.remove()
    cbar2.remove()
    cbar3.remove()
    clear_plotables(ax1,keep_ax_lst_1,fig)
    clear_plotables(ax2,keep_ax_lst_2,fig)
    clear_plotables(ax3,keep_ax_lst_3,fig)

    units = '\xb0''F'
    clevs = np.linspace(-5,80,35)
    clevsdiff = [-12,-10,-8,-6,-4,-2,0,2,4,6,8,10,12]
    cm = cmap_q2m()
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
    normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

    cs_1 = ax1.pcolormesh(lon_shift,lat_shift,dew2m_1,transform=transform,cmap=cm,norm=norm)
    cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=6)
    ax1.text(.5,1.03,'FV3-LAM 2-m Dew Point Temperature ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs_2 = ax2.pcolormesh(lon2_shift,lat2_shift,dew2m_2,transform=transform,cmap=cm,norm=norm)
    cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar2.set_label(units,fontsize=6)
    cbar2.ax.tick_params(labelsize=6)
    ax2.text(.5,1.03,'FV3-LAM-2 2-m Dew Point Temperature ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs = ax3.pcolormesh(lon2_shift,lat2_shift,dew2m_diff,transform=transform,cmap=cmdiff,norm=normdiff)
    cs.cmap.set_under('darkblue')
    cs.cmap.set_over('darkred')
    cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar3.set_label(units,fontsize=6)
    cbar3.ax.tick_params(labelsize=6)
    ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM 2-m Dew Point Temperature ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/2mdew_diff_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot 2mdew for: '+dom) % t3)


#################################
  # Plot 10-m WSPD
#################################
    t1 = time.perf_counter()
    print(('Working on 10mwspd for '+dom))

  # Clear off old plottables but keep all the map info
    cbar1.remove()
    cbar2.remove()
    cbar3.remove()
    clear_plotables(ax1,keep_ax_lst_1,fig)
    clear_plotables(ax2,keep_ax_lst_2,fig)
    clear_plotables(ax3,keep_ax_lst_3,fig)

    units = 'kts'
  # Places a wind barb every ~180 km, optimized for CONUS domain
    skip = round(177.28*(dx/1000.)**-.97)
    print('skipping every '+str(skip)+' grid points to plot')
    barblength = 4

    clevs = [5,10,15,20,25,30,35,40,45,50,55,60]
    clevsdiff = [-12,-10,-8,-6,-4,-2,0,2,4,6,8,10,12]
    colorlist = ['turquoise','dodgerblue','blue','#FFF68F','#E3CF57','peru','brown','crimson','red','fuchsia','DarkViolet']
    cm = matplotlib.colors.ListedColormap(colorlist)
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
    normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

    cs_1 = ax1.pcolormesh(lon_shift,lat_shift,wspd10m_1,transform=transform,cmap=cm,vmin=5,norm=norm)
    cs_1.cmap.set_under('white',alpha=0.)
    cs_1.cmap.set_over('black')
    cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,ticks=clevs,extend='max')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=6)
    ax1.barbs(lon_shift[::skip,::skip],lat_shift[::skip,::skip],uwind_1[::skip,::skip],vwind_1[::skip,::skip],length=barblength,linewidth=0.5,color='black',transform=transform)
    ax1.text(.5,1.03,'FV3-LAM 10-m Winds ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs_2 = ax2.pcolormesh(lon2_shift,lat2_shift,wspd10m_2,transform=transform,cmap=cm,vmin=5,norm=norm)
    cs_2.cmap.set_under('white',alpha=0.)
    cs_2.cmap.set_over('black')
    cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,ticks=clevs,extend='max')
    cbar2.set_label(units,fontsize=6)
    cbar2.ax.tick_params(labelsize=6)
    ax2.barbs(lon2_shift[::skip,::skip],lat2_shift[::skip,::skip],uwind_2[::skip,::skip],vwind_2[::skip,::skip],length=barblength,linewidth=0.5,color='black',transform=transform)
    ax2.text(.5,1.03,'FV3-LAM-2 10-m Winds ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs = ax3.pcolormesh(lon2_shift,lat2_shift,wspd10m_diff,transform=transform,cmap=cmdiff,norm=normdiff)
    cs.cmap.set_under('darkblue')
    cs.cmap.set_over('darkred')
    cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar3.set_label(units,fontsize=6)
    cbar3.ax.tick_params(labelsize=6)
    ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM 10-m Winds ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/10mwind_diff_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot 10mwspd for: '+dom) % t3)


#################################
  # Plot Surface-Based CAPE/CIN
#################################
    t1 = time.perf_counter()
    print(('Working on surface-based CAPE/CIN for '+dom))

  # Clear off old plottables but keep all the map info
    cbar1.remove()
    cbar2.remove()
    cbar3.remove()
    clear_plotables(ax1,keep_ax_lst_1,fig)
    clear_plotables(ax2,keep_ax_lst_2,fig)
    clear_plotables(ax3,keep_ax_lst_3,fig)

    units = 'J/kg'
    clevs = [100,250,500,1000,1500,2000,2500,3000,3500,4000,4500,5000]
    clevs2 = [-2000,-500,-250,-100,-25]
    clevsdiff = [-2000,-1500,-1000,-500,-250,-100,0,100,250,500,1000,1500,2000]
    colorlist = ['blue','dodgerblue','cyan','mediumspringgreen','#FAFAD2','#EEEE00','#EEC900','darkorange','crimson','darkred','darkviolet']
    cm = matplotlib.colors.ListedColormap(colorlist)
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
    normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

    cs_1 = ax1.pcolormesh(lon_shift,lat_shift,cape_1,transform=transform,cmap=cm,vmin=100,norm=norm)
    cs_1.cmap.set_under('white',alpha=0.)
    cs_1.cmap.set_over('black')
    cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,ticks=clevs,extend='max')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=4)
    cs_1b = ax1.contourf(lon_shift,lat_shift,cin_1,clevs2,colors='none',hatches=['**','++','////','..'],transform=transform)
    ax1.text(.5,1.05,'FV3-LAM Surface-Based CAPE (shaded) and CIN (hatched) ('+units+') \n <-500 (*), -500<-250 (+), -250<-100 (/), -100<-25 (.) \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs_2 = ax2.pcolormesh(lon2_shift,lat2_shift,cape_2,transform=transform,cmap=cm,vmin=100,norm=norm)
    cs_2.cmap.set_under('white',alpha=0.)
    cs_2.cmap.set_over('black')
    cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,ticks=clevs,extend='max')
    cbar2.set_label(units,fontsize=6)
    cbar2.ax.tick_params(labelsize=4)
    cs_2b = ax2.contourf(lon2_shift,lat2_shift,cin_2,clevs2,colors='none',hatches=['**','++','////','..'],transform=transform)
    ax2.text(.5,1.05,'FV3-LAM-2 Surface-Based CAPE (shaded) and CIN (hatched) ('+units+') \n <-500 (*), -500<-250 (+), -250<-100 (/), -100<-25 (.) \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs = ax3.pcolormesh(lon2_shift,lat2_shift,cape_diff,transform=transform,cmap=cmdiff,norm=normdiff)
    cs.cmap.set_under('darkblue')
    cs.cmap.set_over('darkred')
    cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar3.set_label(units,fontsize=6)
    cbar3.ax.tick_params(labelsize=6)
    ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM Surface-Based CAPE ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/sfcape_diff_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot surface-based CAPE/CIN for: '+dom) % t3)


#################################
  # Plot 500 mb HGT/WIND/VORT
#################################
    t1 = time.perf_counter()
    print(('Working on 500 mb Hgt/Wind/Vort for '+dom))

  # Clear off old plottables but keep all the map info
    cbar1.remove()
    cbar2.remove()
    cbar3.remove()
    clear_plotables(ax1,keep_ax_lst_1,fig)
    clear_plotables(ax2,keep_ax_lst_2,fig)
    clear_plotables(ax3,keep_ax_lst_3,fig)

    units = 'x10${^5}$ s${^{-1}}$'
    skip = round(177.28*(dx/1000.)**-.97)
    print('skipping every '+str(skip)+' grid points to plot')
    barblength = 4

    vortlevs = [16,20,24,28,32,36,40]
    clevsdiff = [-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6]
    colorlist = ['yellow','gold','goldenrod','orange','orangered','red']
    cm = matplotlib.colors.ListedColormap(colorlist)
    norm = matplotlib.colors.BoundaryNorm(vortlevs, cm.N)
    normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

    cs1_a = ax1.pcolormesh(lon_shift,lat_shift,vort500_1,transform=transform,cmap=cm,norm=norm)
    cs1_a.cmap.set_under('white')
    cs1_a.cmap.set_over('darkred')
    cbar1 = plt.colorbar(cs1_a,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,ticks=vortlevs,extend='both')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=6)
    ax1.barbs(lon_shift[::skip,::skip],lat_shift[::skip,::skip],u500_1[::skip,::skip],v500_1[::skip,::skip],length=barblength,linewidth=0.5,color='steelblue',transform=transform)
    cs1_b = ax1.contour(lon_shift,lat_shift,z500_1,np.arange(486,600,6),colors='black',linewidths=1,transform=transform)
    plt.clabel(cs1_b,np.arange(486,600,6),inline_spacing=1,fmt='%d',fontsize=8)
    ax1.text(.5,1.03,'FV3-LAM 500 mb Heights (dam), Winds (kts), and $\zeta$ ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=8,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs2_a = ax2.pcolormesh(lon2_shift,lat2_shift,vort500_2,transform=transform,cmap=cm,norm=norm)
    cs2_a.cmap.set_under('white')
    cs2_a.cmap.set_over('darkred')
    cbar2 = plt.colorbar(cs2_a,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,ticks=vortlevs,extend='both')
    cbar2.set_label(units,fontsize=6)
    cbar2.ax.tick_params(labelsize=6)
    ax2.barbs(lon2_shift[::skip,::skip],lat2_shift[::skip,::skip],u500_2[::skip,::skip],v500_2[::skip,::skip],length=barblength,linewidth=0.5,color='steelblue',transform=transform)
    cs2_b = ax2.contour(lon2_shift,lat2_shift,z500_2,np.arange(486,600,6),colors='black',linewidths=1,transform=transform)
    plt.clabel(cs2_b,np.arange(486,600,6),inline_spacing=1,fmt='%d',fontsize=8)
    ax2.text(.5,1.03,'FV3-LAM-2 500 mb Heights (dam), Winds (kts), and $\zeta$ ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=8,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs = ax3.pcolormesh(lon2_shift,lat2_shift,z500_diff,transform=transform,cmap=cmdiff,norm=normdiff)
    cs.cmap.set_under('darkblue')
    cs.cmap.set_over('darkred')
    cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar3.set_label(units,fontsize=6)
    cbar3.ax.tick_params(labelsize=6)
    ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM 500-mb Heights (dam) \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/500_diff_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot 500 mb Hgt/Wind/Vort for: '+dom) % t3)


#################################
  # Plot 250 mb WIND
#################################
    t1 = time.perf_counter()
    print(('Working on 250 mb WIND for '+dom))

  # Clear off old plottables but keep all the map info
    cbar1.remove()
    cbar2.remove()
    cbar3.remove()
    clear_plotables(ax1,keep_ax_lst_1,fig)
    clear_plotables(ax2,keep_ax_lst_2,fig)
    clear_plotables(ax3,keep_ax_lst_3,fig)

    units = 'kts'
    skip = round(177.28*(dx/1000.)**-.97)
    print('skipping every '+str(skip)+' grid points to plot')
    barblength = 4

    clevs = [50,60,70,80,90,100,110,120,130,140,150]
    clevsdiff = [-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30]
    colorlist = ['turquoise','deepskyblue','dodgerblue','#1874CD','blue','beige','khaki','peru','brown','crimson']
    cm = matplotlib.colors.ListedColormap(colorlist)
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
    normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

    cs_1 = ax1.pcolormesh(lon_shift,lat_shift,wspd250_1,transform=transform,cmap=cm,vmin=50,norm=norm)
    cs_1.cmap.set_under('white',alpha=0.)
    cs_1.cmap.set_over('red')
    cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,ticks=clevs,extend='max')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=6)
    ax1.barbs(lon_shift[::skip,::skip],lat_shift[::skip,::skip],u250_1[::skip,::skip],v250_1[::skip,::skip],length=barblength,linewidth=0.5,color='black',transform=transform)
    ax1.text(.5,1.03,'FV3-LAM 250 mb Winds ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs_2 = ax2.pcolormesh(lon2_shift,lat2_shift,wspd250_2,transform=transform,cmap=cm,vmin=50,norm=norm)
    cs_2.cmap.set_under('white',alpha=0.)
    cs_2.cmap.set_over('red')
    cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,ticks=clevs,extend='max')
    cbar2.set_label(units,fontsize=6)
    cbar2.ax.tick_params(labelsize=6)
    ax2.barbs(lon2_shift[::skip,::skip],lat2_shift[::skip,::skip],u250_2[::skip,::skip],v250_2[::skip,::skip],length=barblength,linewidth=0.5,color='black',transform=transform)
    ax2.text(.5,1.03,'FV3-LAM-2 250 mb Winds ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs = ax3.pcolormesh(lon2_shift,lat2_shift,wspd250_diff,transform=transform,cmap=cmdiff,norm=normdiff)
    cs.cmap.set_under('darkblue')
    cs.cmap.set_over('darkred')
    cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
    cbar3.set_label(units,fontsize=6)
    cbar3.ax.tick_params(labelsize=6)
    ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM 250-mb Winds ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/250wind_diff_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot 250 mb WIND for: '+dom) % t3)


#################################
  # Plot Total QPF
#################################
    if (fhr > 0):		# Do not make total QPF plot for forecast hour 0
      t1 = time.perf_counter()
      print(('Working on total qpf for '+dom))

    # Clear off old plottables but keep all the map info
      cbar1.remove()
      cbar2.remove()
      cbar3.remove()
      clear_plotables(ax1,keep_ax_lst_1,fig)
      clear_plotables(ax2,keep_ax_lst_2,fig)
      clear_plotables(ax3,keep_ax_lst_3,fig)

      units = 'in'
      clevs = [0.01,0.1,0.25,0.5,0.75,1,1.25,1.5,1.75,2,2.5,3,4,5,7,10,15,20]
      clevsdiff = [-3,-2.5,-2,-1.5,-1,-0.5,0,0.5,1,1.5,2,2.5,3]
      colorlist = ['chartreuse','limegreen','green','blue','dodgerblue','deepskyblue','cyan','mediumpurple','mediumorchid','darkmagenta','darkred','crimson','orangered','darkorange','goldenrod','gold','yellow']
      cm = matplotlib.colors.ListedColormap(colorlist)
      norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
      normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

      cs_1 = ax1.pcolormesh(lon_shift,lat_shift,qpf_1,transform=transform,cmap=cm,vmin=0.01,norm=norm)
      cs_1.cmap.set_under('white',alpha=0.)
      cs_1.cmap.set_over('pink')
      cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,extend='max')
      cbar1.set_label(units,fontsize=6)
      cbar1.ax.set_xticklabels([0.1,0.5,1,1.5,2,3,5,10,20])
      cbar1.ax.tick_params(labelsize=6)
      ax1.text(.5,1.03,'FV3-LAM '+fhour+'-hr Accumulated Precipitation ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

      cs_2 = ax2.pcolormesh(lon2_shift,lat2_shift,qpf_2,transform=transform,cmap=cm,vmin=0.01,norm=norm)
      cs_2.cmap.set_under('white',alpha=0.)
      cs_2.cmap.set_over('pink')
      cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,extend='max')
      cbar2.set_label(units,fontsize=6)
      cbar2.ax.set_xticklabels([0.1,0.5,1,1.5,2,3,5,10,20])
      cbar2.ax.tick_params(labelsize=6)
      ax2.text(.5,1.03,'FV3-LAM-2 '+fhour+'-hr Accumulated Precipitation ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

      cs = ax3.pcolormesh(lon2_shift,lat2_shift,qpf_diff,transform=transform,cmap=cmdiff,norm=normdiff)
      cs.cmap.set_under('darkblue')
      cs.cmap.set_over('darkred')
      cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
      cbar3.set_label(units,fontsize=6)
      cbar3.ax.tick_params(labelsize=6)
      ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM '+fhour+'-hr Accumulated Precipitation ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

      compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/qpf_diff_'+dom+'_f'+fhour+'.png')
      t2 = time.perf_counter()
      t3 = round(t2-t1, 3)
      print(('%.3f seconds to plot total qpf for: '+dom) % t3)


#################################
  # Plot Max/Min Hourly 2-5 km UH
#################################
# Do not make max/min hourly 2-5 km UH plot for forecast hour 0
      t1 = time.perf_counter()
      print(('Working on Max/Min Hourly 2-5 km UH for '+dom))

    # Clear off old plottables but keep all the map info
      cbar1.remove()
      cbar2.remove()
      cbar3.remove()
      clear_plotables(ax1,keep_ax_lst_1,fig)
      clear_plotables(ax2,keep_ax_lst_2,fig)
      clear_plotables(ax3,keep_ax_lst_3,fig)

      units = 'm${^2}$ s$^{-2}$'
      clevs = [-150,-100,-75,-50,-25,-10,0,10,25,50,75,100,150,200,250,300]
#   alternative colormap for just max UH if you don't want to plot the min UH too
#   colorlist = ['white','skyblue','mediumblue','green','orchid','firebrick','#EEC900','DarkViolet']
      colorlist = ['blue','#1874CD','dodgerblue','deepskyblue','turquoise','#E5E5E5','#E5E5E5','#EEEE00','#EEC900','darkorange','orangered','red','firebrick','mediumvioletred','darkviolet']
      cm = matplotlib.colors.ListedColormap(colorlist)
      cmdiff = matplotlib.colors.ListedColormap(diffcolors)
      norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
      normdiff = matplotlib.colors.BoundaryNorm(clevsdiff, cmdiff.N)

      cs_1 = ax1.pcolormesh(lon_shift,lat_shift,uh25_1,transform=transform,cmap=cm,norm=norm)
      cs_1.cmap.set_under('darkblue')
      cs_1.cmap.set_over('black')
      cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
      cbar1.set_label(units,fontsize=6)
      cbar1.ax.tick_params(labelsize=6)
      ax1.text(.5,1.03,'FV3-LAM 1-h Max/Min 2-5 km Updraft Helicity ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

      cs_2 = ax2.pcolormesh(lon2_shift,lat2_shift,uh25_2,transform=transform,cmap=cm,norm=norm)
      cs_2.cmap.set_under('darkblue')
      cs_2.cmap.set_over('black')
      cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
      cbar2.set_label(units,fontsize=6)
      cbar2.ax.tick_params(labelsize=6)
      ax2.text(.5,1.03,'FV3-LAM-2 1-h Max/Min 2-5 km Updraft Helicity ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

      cs = ax3.pcolormesh(lon2_shift,lat2_shift,uh25_diff,transform=transform,cmap=cmdiff,norm=normdiff)
      cs.cmap.set_under('darkblue')
      cs.cmap.set_over('darkred')
      cbar3 = plt.colorbar(cs,ax=ax3,orientation='horizontal',pad=0.05,shrink=0.6,extend='both')
      cbar3.set_label(units,fontsize=6)
      cbar3.ax.tick_params(labelsize=6)
      ax3.text(.5,1.03,'FV3-LAM-2 - FV3-LAM 1-h Max/Min 2-5 km Updraft Helicity ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

      compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/uh25_diff_'+dom+'_f'+fhour+'.png')
      t2 = time.perf_counter()
      t3 = round(t2-t1, 3)
      print(('%.3f seconds to plot Max/Min Hourly 2-5 km UH for: '+dom) % t3)


#################################
  # Plot composite reflectivity
#################################
    t1 = time.perf_counter()
    print(('Working on composite reflectivity for '+dom))

  # Clear off old plottables but keep all the map info
    cbar1.remove()
    cbar2.remove()
    cbar3.remove()
    clear_plotables(ax1,keep_ax_lst_1,fig)
    clear_plotables(ax2,keep_ax_lst_2,fig)
    clear_plotables(ax3,keep_ax_lst_3,fig)

    units = 'dBZ'
    clevs = np.linspace(5,70,14)
    clevsdiff = [20,1000]
    colorlist = ['turquoise','dodgerblue','mediumblue','lime','limegreen','green','#EEEE00','#EEC900','darkorange','red','firebrick','darkred','fuchsia']
    cm = matplotlib.colors.ListedColormap(colorlist)
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

    cs_1 = ax1.pcolormesh(lon_shift,lat_shift,refc_1,transform=transform,cmap=cm,vmin=5,norm=norm)
    cs_1.cmap.set_under('white',alpha=0.)
    cs_1.cmap.set_over('black')
    cbar1 = plt.colorbar(cs_1,ax=ax1,orientation='horizontal',pad=0.05,shrink=0.6,ticks=clevs,extend='max')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=6)
    ax1.text(.5,1.03,'FV3-LAM Composite Reflectivity ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax1.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    cs_2 = ax2.pcolormesh(lon2_shift,lat2_shift,refc_2,transform=transform,cmap=cm,vmin=5,norm=norm)
    cs_2.cmap.set_under('white',alpha=0.)
    cs_2.cmap.set_over('black')
    cbar2 = plt.colorbar(cs_2,ax=ax2,orientation='horizontal',pad=0.05,shrink=0.6,ticks=clevs,extend='max')
    cbar2.set_label(units,fontsize=6)
    cbar2.ax.tick_params(labelsize=6)
    ax2.text(.5,1.03,'FV3-LAM-2 Composite Reflectivity ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax2.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    csdiff = ax3.contourf(lon_shift,lat_shift,refc_1,clevsdiff,colors='red',transform=transform)
    csdiff2 = ax3.contourf(lon2_shift,lat2_shift,refc_2,clevsdiff,colors='dodgerblue',transform=transform)
    ax3.text(.5,1.03,'FV3-LAM (red) and FV3-LAM-2 (blue) Composite Reflectivity > 20 ('+units+') \n initialized: '+itime+' valid: '+vtime+' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax3.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save(EXPT_DIR_1+'/'+ymdh+'/postprd/refc_diff_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot composite reflectivity for: '+dom) % t3)


######################################################

    t3dom = round(t2-t1dom, 3)
    print(("%.3f seconds to plot all variables for: "+dom) % t3dom)
    plt.clf()

######################################################

  main()

