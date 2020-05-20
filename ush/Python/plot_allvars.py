################################################################################
####  Python Script Documentation Block
#                      
# Script name:       	plot_allvars.py
# Script description:  	Generates plots from FV3SAR post processed grib2 output
#			over the CONUS
#
# Author:   Ben Blake	Org: NOAA/NWS/NCEP/EMC		Date: 2020-05-07
#
# Instructions:		Make sure all the necessary modules can be imported.
#                       Two command line arguments are needed:
#                       1. Cycle date/time in YYYYMMDDHH format
#                       2. Forecast hour
#
#                       Define the path to the grib2 file on line 219.
#
#           		To create plots for forecast hour 24 from 5/7 00Z cycle:
#                       python plot_allvars.py 2020050700 24
#
################################################################################

#-------------Import modules --------------------------#
import pygrib
import matplotlib
matplotlib.use('Agg')
import io
import matplotlib.pyplot as plt
import dateutil.relativedelta, dateutil.parser
from PIL import Image
from matplotlib.gridspec import GridSpec
from mpl_toolkits.basemap import Basemap, maskoceans
import numpy as np
import time,os,sys,multiprocessing
import multiprocessing.pool
from scipy import ndimage
from netCDF4 import Dataset
import pyproj


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
#  ram = io.StringIO()
  ram = io.BytesIO()
  plt.savefig(ram, format='png', bbox_inches='tight', dpi=150)
  ram.seek(0)
  im = Image.open(ram)
  im2 = im.convert('RGB').convert('P', palette=Image.ADAPTIVE)
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
              
# Read date/time and forecast hour from command line
ymdh = str(sys.argv[1])
ymd = ymdh[0:8]
year = int(ymdh[0:4])
month = int(ymdh[4:6])
day = int(ymdh[6:8])
hour = int(ymdh[8:10])
cyc = str(hour).zfill(2)
print(year, month, day, hour)

fhr = int(sys.argv[2])
fhour = str(fhr).zfill(2)
print('fhour '+fhour)
itime = ymdh
vtime = ndate(itime,int(fhr))

# Define the input files
#data1 = pygrib.open('/gpfs/dell2/ptmp/Benjamin.Blake/fv3sarx/fv3sarx.'+str(ymd)+'/'+cyc+'/fv3sar.t'+cyc+'z.conus.f'+fhour+'.grib2')

# Get the lats and lons
grids = [data1]
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

# Shifted lat/lon arrays for pcolormesh
lat_shift = lats_shift[0]
lon_shift = lons_shift[0]

Lat0 = data1[1]['LaDInDegrees']
Lon0 = data1[1]['LoVInDegrees']
print(Lat0)
print(Lon0)

# Specify plotting domains
# User can add domains here, just need to specify lat/lon information below (see line 382)
domains=['conus']

###################################################
# Read in all variables and calculate differences #
###################################################
t1a = time.perf_counter()

# Sea level pressure
slp = data1.select(name='Pressure reduced to MSL')[0].values * 0.01
slpsmooth = ndimage.filters.gaussian_filter(slp, 13.78)

# 2-m temperature
tmp2m = data1.select(name='2 metre temperature')[0].values
tmp2m = (tmp2m - 273.15)*1.8 + 32.0

# 2-m dew point temperature
dew2m = data1.select(name='2 metre dewpoint temperature')[0].values
dew2m = (dew2m - 273.15)*1.8 + 32.0

# 10-m wind speed
uwind = data1.select(name='10 metre U wind component')[0].values * 1.94384
vwind = data1.select(name='10 metre V wind component')[0].values * 1.94384
# Rotate winds from grid relative to Earth relative
uwind, vwind = rotate_wind(Lat0,Lon0,lon,uwind,vwind,'lcc',inverse=False)
wspd10m = np.sqrt(uwind**2 + vwind**2)

# Surface-based CAPE
cape = data1.select(name='Convective available potential energy',typeOfLevel='surface')[0].values

# Surface-based CIN
cin = data1.select(name='Convective inhibition',typeOfLevel='surface')[0].values

# 500 mb height, wind, vorticity
z500 = data1.select(name='Geopotential Height',level=500)[0].values * 0.1
z500 = ndimage.filters.gaussian_filter(z500, 6.89)
vort500 = data1.select(name='Absolute vorticity',level=500)[0].values * 100000
vort500 = ndimage.filters.gaussian_filter(vort500,1.7225)
vort500[vort500 > 1000] = 0	# Mask out undefined values on domain edge
u500 = data1.select(name='U component of wind',level=500)[0].values * 1.94384
v500 = data1.select(name='V component of wind',level=500)[0].values * 1.94384
# Rotate winds from grid relative to Earth relative
u500, v500 = rotate_wind(Lat0,Lon0,lon,u500,v500,'lcc',inverse=False)

# 250 mb winds
u250 = data1.select(name='U component of wind',level=250)[0].values * 1.94384
v250 = data1.select(name='V component of wind',level=250)[0].values * 1.94384
# Rotate winds from grid relative to Earth relative
u250, v250 = rotate_wind(Lat0,Lon0,lon,u250,v250,'lcc',inverse=False)
wspd250 = np.sqrt(u250**2 + v250**2)

# Total precipitation
qpf = data1.select(name='Total Precipitation',lengthOfTimeRange=fhr)[0].values * 0.0393701

# Composite reflectivity
refc = data1.select(name='Maximum/Composite radar reflectivity')[0].values 

if (fhr > 0):
# Max/Min Hourly 2-5 km Updraft Helicity
  maxuh25 = data1.select(stepType='max',parameterName="199",topLevel=5000,bottomLevel=2000)[0].values
  minuh25 = data1.select(stepType='min',parameterName="200",topLevel=5000,bottomLevel=2000)[0].values
  maxuh25[maxuh25 < 10] = 0
  minuh25[minuh25 > -10] = 0
  uh25 = maxuh25 + minuh25


t2a = time.perf_counter()
t3a = round(t2a-t1a, 3)
print(("%.3f seconds to read all messages") % t3a)


########################################
#    START PLOTTING FOR EACH DOMAIN    #
########################################

def main():

  # Number of processes must coincide with the number of domains to plot
  pool = multiprocessing.Pool(len(domains))
  pool.map(plot_all,domains)

def plot_all(dom):

  t1dom = time.perf_counter()
  print(('Working on '+dom))

  # create figure and axes instances
  fig = plt.figure()
  gs = GridSpec(4,4,wspace=0.0,hspace=0.0)
  ax = fig.add_subplot(gs[:,:])

  # Map corners for each domain
  if dom == 'conus':
    llcrnrlon = -120.5
    llcrnrlat = 21.0 
    urcrnrlon = -64.5
    urcrnrlat = 49.0
    lat_0 = 35.4
    lon_0 = -97.6

  # Create basemap instance and set the dimensions
  m = Basemap(ax=ax,projection='gnom',lat_0=lat_0,lon_0=lon_0,\
              llcrnrlat=llcrnrlat, urcrnrlat=urcrnrlat,\
              llcrnrlon=llcrnrlon, urcrnrlon=urcrnrlon,\
              resolution='l')
  m.fillcontinents(color='LightGrey',zorder=0)
  m.drawcoastlines(linewidth=0.75)
  m.drawstates(linewidth=0.5)
  m.drawcountries(linewidth=0.5)
# parallels = np.arange(0.,90.,10.)
# m.drawparallels(parallels,labels=[1,0,0,0],fontsize=6)
# meridians = np.arange(180.,360.,10.)
# m.drawmeridians(meridians,labels=[0,0,0,1],fontsize=6)
  x,y = m(lon,lat)
  x_shift,y_shift   = m(lon_shift,lat_shift)
 
  # Map/figure has been set up here, save axes instances for use again later
  keep_ax_lst = ax.get_children()[:]


################################
  # Plot SLP
################################
  t1 = time.perf_counter()
  print(('Working on slp for '+dom))

  units = 'mb'
  clevs = [976,980,984,988,992,996,1000,1004,1008,1012,1016,1020,1024,1028,1032,1036,1040,1044,1048,1052]
  clevsdif = [-12,-10,-8,-6,-4,-2,0,2,4,6,8,10,12]
  cm = plt.cm.Spectral_r
  norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

  xmin, xmax = ax.get_xlim()
  ymin, ymax = ax.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs1_a = m.pcolormesh(x_shift,y_shift,slpsmooth,cmap=cm,norm=norm,ax=ax)  
  cbar1 = m.colorbar(cs1_a,ax=ax,location='bottom',pad=0.05,extend='both')
  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  cs1_b = m.contour(x,y,slpsmooth,np.arange(940,1060,4),colors='black',linewidths=1.25,ax=ax)
  plt.clabel(cs1_b,np.arange(940,1060,4),inline=1,fmt='%d',fontsize=8)
  ax.text(.5,1.03,'FV3SAR SLP ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

  compress_and_save('compareslp_'+dom+'_f'+fhour+'.png')
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
  clear_plotables(ax,keep_ax_lst,fig)

  units = '\xb0''F'
  clevs = np.linspace(-16,134,51)
  cm = cmap_t2m()
  norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

  xmin, xmax = ax.get_xlim()
  ymin, ymax = ax.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs_1 = m.pcolormesh(x_shift,y_shift,tmp2m,cmap=cm,norm=norm,ax=ax)
  cs_1.cmap.set_under('white')
  cs_1.cmap.set_over('white')
  cbar1 = m.colorbar(cs_1,ax=ax,location='bottom',pad=0.05,ticks=[-16,-4,8,20,32,44,56,68,80,92,104,116,128],extend='both')
  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  ax.text(.5,1.03,'FV3SAR 2-m Temperature ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

  compress_and_save('compare2mt_'+dom+'_f'+fhour+'.png')
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
  clear_plotables(ax,keep_ax_lst,fig)

  units = '\xb0''F'
  clevs = np.linspace(-5,80,35)
  cm = cmap_q2m()
  norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

  xmin, xmax = ax.get_xlim()
  ymin, ymax = ax.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs_1 = m.pcolormesh(x_shift,y_shift,dew2m,cmap=cm,norm=norm,ax=ax)
  cbar1 = m.colorbar(cs_1,ax=ax,location='bottom',pad=0.05,extend='both')
  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  ax.text(.5,1.03,'FV3SAR 2-m Dew Point Temperature ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

  compress_and_save('compare2mdew_'+dom+'_f'+fhour+'.png')
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
  clear_plotables(ax,keep_ax_lst,fig)

  units = 'kts'
  skip = 50
  barblength = 4

  clevs = [5,10,15,20,25,30,35,40,45,50,55,60]
  colorlist = ['turquoise','dodgerblue','blue','#FFF68F','#E3CF57','peru','brown','crimson','red','fuchsia','DarkViolet']
  cm = matplotlib.colors.ListedColormap(colorlist)
  norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

  # Rotate winds to gnomonic projection
  urot, vrot = m.rotate_vector(uwind,vwind,lon,lat)

  xmin, xmax = ax.get_xlim()
  ymin, ymax = ax.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs_1 = m.pcolormesh(x_shift,y_shift,wspd10m,cmap=cm,vmin=5,norm=norm,ax=ax)
  cs_1.cmap.set_under('white',alpha=0.)
  cs_1.cmap.set_over('black')
  cbar1 = m.colorbar(cs_1,ax=ax,location='bottom',pad=0.05,ticks=clevs,extend='max')
  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  m.barbs(lon[::skip,::skip],lat[::skip,::skip],urot[::skip,::skip],vrot[::skip,::skip],latlon=True,length=barblength,linewidth=0.5,color='black',ax=ax)
  ax.text(.5,1.03,'FV3SAR 10-m Winds ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))
    
  compress_and_save('compare10mwind_'+dom+'_f'+fhour+'.png')
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
  clear_plotables(ax,keep_ax_lst,fig)

  units = 'J/kg'
  clevs = [100,250,500,1000,1500,2000,2500,3000,3500,4000,4500,5000]
  clevs2 = [-2000,-500,-250,-100,-25]
  colorlist = ['blue','dodgerblue','cyan','mediumspringgreen','#FAFAD2','#EEEE00','#EEC900','darkorange','crimson','darkred']
  cm = matplotlib.colors.ListedColormap(colorlist)
  norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

  xmin, xmax = ax.get_xlim()
  ymin, ymax = ax.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs_1 = m.pcolormesh(x_shift,y_shift,cape,cmap=cm,vmin=100,norm=norm,ax=ax)
  cs_1.cmap.set_under('white',alpha=0.)
  cs_1.cmap.set_over('darkviolet')
  cbar1 = m.colorbar(cs_1,ax=ax,location='bottom',pad=0.05,ticks=clevs,extend='max')
  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  cs_1b = m.contourf(x,y,cin,clevs2,colors='none',hatches=['**','++','////','..'],ax=ax)
  ax.text(.5,1.05,'FV3SAR Surface-Based CAPE (shaded) and CIN (hatched) ('+units+') \n <-500 (*), -500<-250 (+), -250<-100 (/), -100<-25 (.) \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

  compress_and_save('comparesfcape_'+dom+'_f'+fhour+'.png')
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
  clear_plotables(ax,keep_ax_lst,fig)

  units = 'x10${^5}$ s${^{-1}}$'
  skip = 70
  barblength = 4

  vortlevs = [16,20,24,28,32,36,40]
  colorlist = ['yellow','gold','goldenrod','orange','orangered','red']
  cm = matplotlib.colors.ListedColormap(colorlist)
  norm = matplotlib.colors.BoundaryNorm(vortlevs, cm.N)

  # Rotate winds to gnomonic projection
  urot, vrot = m.rotate_vector(u500,v500,lon,lat)

  xmin, xmax = ax.get_xlim()
  ymin, ymax = ax.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs1_a = m.pcolormesh(x_shift,y_shift,vort500,cmap=cm,norm=norm,ax=ax)
  cs1_a.cmap.set_under('white')
  cs1_a.cmap.set_over('darkred')
  cbar1 = m.colorbar(cs1_a,ax=ax,location='bottom',pad=0.05,ticks=vortlevs,extend='both')
  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  m.barbs(lon[::skip,::skip],lat[::skip,::skip],urot[::skip,::skip],vrot[::skip,::skip],latlon=True,length=barblength,linewidth=0.5,color='steelblue',ax=ax)
  cs1_b = m.contour(x,y,z500,np.arange(486,600,6),colors='black',linewidths=1,ax=ax)
  plt.clabel(cs1_b,np.arange(486,600,6),inline_spacing=1,fmt='%d',fontsize=6)
  ax.text(.5,1.03,'FV3SAR 500 mb Heights (dam), Winds (kts), and $\zeta$ ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

  compress_and_save('compare500_'+dom+'_f'+fhour+'.png')
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
  clear_plotables(ax,keep_ax_lst,fig)

  units = 'kts'
  skip = 70
  barblength = 4

  clevs = [50,60,70,80,90,100,110,120,130,140,150]
  colorlist = ['turquoise','deepskyblue','dodgerblue','#1874CD','blue','beige','khaki','peru','brown','crimson']
  cm = matplotlib.colors.ListedColormap(colorlist)
  norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

  # Rotate winds to gnomonic projection
  urot, vrot = m.rotate_vector(u250,v250,lon,lat)

  xmin, xmax = ax.get_xlim()
  ymin, ymax = ax.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs_1 = m.pcolormesh(x_shift,y_shift,wspd250,cmap=cm,vmin=50,norm=norm,ax=ax)
  cs_1.cmap.set_under('white',alpha=0.)
  cs_1.cmap.set_over('red')
  cbar1 = m.colorbar(cs_1,ax=ax,location='bottom',pad=0.05,ticks=clevs,extend='max')
  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  m.barbs(lon[::skip,::skip],lat[::skip,::skip],urot[::skip,::skip],vrot[::skip,::skip],latlon=True,length=barblength,linewidth=0.5,color='black',ax=ax)
  ax.text(.5,1.03,'FV3SAR 250 mb Winds ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

  compress_and_save('compare250wind_'+dom+'_f'+fhour+'.png')
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
    clear_plotables(ax,keep_ax_lst,fig)

    units = 'in'
    clevs = [0.01,0.1,0.25,0.5,0.75,1,1.25,1.5,1.75,2,2.5,3,4,5,7,10,15,20]
    clevsdif = [-3,-2.5,-2,-1.5,-1,-0.5,0,0.5,1,1.5,2,2.5,3]
    colorlist = ['chartreuse','limegreen','green','blue','dodgerblue','deepskyblue','cyan','mediumpurple','mediumorchid','darkmagenta','darkred','crimson','orangered','darkorange','goldenrod','gold','yellow']  
    cm = matplotlib.colors.ListedColormap(colorlist)
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

    xmin, xmax = ax.get_xlim()
    ymin, ymax = ax.get_ylim()
    xmax = int(round(xmax))
    ymax = int(round(ymax))

    cs_1 = m.pcolormesh(x_shift,y_shift,qpf,cmap=cm,vmin=0.01,norm=norm,ax=ax)
    cs_1.cmap.set_under('white',alpha=0.)
    cs_1.cmap.set_over('pink')
    cbar1 = m.colorbar(cs_1,ax=ax,location='bottom',pad=0.05,ticks=clevs,extend='max')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.set_xticklabels(clevs)
    cbar1.ax.tick_params(labelsize=6)
    ax.text(.5,1.03,'FV3SAR '+fhour+'-hr Accumulated Precipitation ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save('compareqpf_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot total qpf for: '+dom) % t3)


#################################
  # Plot composite reflectivity
#################################
  t1 = time.perf_counter()
  print(('Working on composite reflectivity for '+dom))

  # Clear off old plottables but keep all the map info
  cbar1.remove()
  clear_plotables(ax,keep_ax_lst,fig)

  units = 'dBZ'
  clevs = np.linspace(5,70,14)
  clevsdif = [20,1000]
  colorlist = ['turquoise','dodgerblue','mediumblue','lime','limegreen','green','#EEEE00','#EEC900','darkorange','red','firebrick','darkred','fuchsia']
  cm = matplotlib.colors.ListedColormap(colorlist)
  norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)
  
  xmin, xmax = ax.get_xlim()
  ymin, ymax = ax.get_ylim()
  xmax = int(round(xmax))
  ymax = int(round(ymax))

  cs_1 = m.pcolormesh(x_shift,y_shift,refc,cmap=cm,vmin=5,norm=norm,ax=ax)
  cs_1.cmap.set_under('white',alpha=0.)
  cs_1.cmap.set_over('black')
  cbar1 = m.colorbar(cs_1,ax=ax,location='bottom',pad=0.05,ticks=clevs,extend='max')
  cbar1.set_label(units,fontsize=6)
  cbar1.ax.tick_params(labelsize=6)
  ax.text(.5,1.03,'FV3SAR Composite Reflectivity ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

  compress_and_save('comparerefc_'+dom+'_f'+fhour+'.png')
  t2 = time.perf_counter()
  t3 = round(t2-t1, 3)
  print(('%.3f seconds to plot composite reflectivity for: '+dom) % t3)


#################################
  # Plot Max/Min Hourly 2-5 km UH
#################################
  if (fhr > 0):		# Do not make max/min hourly 2-5 km UH plot for forecast hour 0 	
    t1 = time.perf_counter()
    print(('Working on Max/Min Hourly 2-5 km UH for '+dom))

    # Clear off old plottables but keep all the map info
    cbar1.remove()
    clear_plotables(ax,keep_ax_lst,fig)

    units = 'm${^2}$ s$^{-2}$'
    clevs = [-150,-100,-75,-50,-25,-10,0,10,25,50,75,100,150,200,250,300]
#   alternative colormap for just max UH if you don't want to plot the min UH too
#   colorlist = ['white','skyblue','mediumblue','green','orchid','firebrick','#EEC900','DarkViolet']
    colorlist = ['blue','#1874CD','dodgerblue','deepskyblue','turquoise','#E5E5E5','#E5E5E5','#EEEE00','#EEC900','darkorange','orangered','red','firebrick','mediumvioletred','darkviolet']
    cm = matplotlib.colors.ListedColormap(colorlist)
    norm = matplotlib.colors.BoundaryNorm(clevs, cm.N)

    xmin, xmax = ax.get_xlim()
    ymin, ymax = ax.get_ylim()
    xmax = int(round(xmax))
    ymax = int(round(ymax))

    cs_1 = m.pcolormesh(x_shift,y_shift,uh25,cmap=cm,norm=norm,ax=ax)
    cs_1.cmap.set_under('darkblue')
    cs_1.cmap.set_over('black')
    cbar1 = m.colorbar(cs_1,ax=ax,location='bottom',pad=0.05,extend='both')
    cbar1.set_label(units,fontsize=6)
    cbar1.ax.tick_params(labelsize=6)
    ax.text(.5,1.03,'FV3SAR 1-h Max/Min 2-5 km Updraft Helicity ('+units+') \n initialized: '+itime+' valid: '+vtime + ' (f'+fhour+')',horizontalalignment='center',fontsize=6,transform=ax.transAxes,bbox=dict(facecolor='white',alpha=0.85,boxstyle='square,pad=0.2'))

    compress_and_save('compareuh25_'+dom+'_f'+fhour+'.png')
    t2 = time.perf_counter()
    t3 = round(t2-t1, 3)
    print(('%.3f seconds to plot Max/Min Hourly 2-5 km UH for: '+dom) % t3)


######################################################

  t3dom = round(t2-t1dom, 3)
  print(("%.3f seconds to plot all variables for: "+dom) % t3dom)
  plt.clf()

######################################################

main()

