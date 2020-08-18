#!/usr/bin/env python

import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
from matplotlib.path import Path
import matplotlib.patches as patches
import numpy as np

#### User-defined variables


# Computational grid definitions
ESGgrid_LON_CTR=-153.0
ESGgrid_LAT_CTR=61.0
ESGgrid_DELX=3000.0
ESGgrid_DELY=3000.0
ESGgrid_NX=1344
ESGgrid_NY=1152

# Write component grid definitions

WRTCMP_nx=1340
WRTCMP_ny=1132
WRTCMP_lon_lwr_left=151.5
WRTCMP_lat_lwr_left=42.360
WRTCMP_dx=ESGgrid_DELX
WRTCMP_dy=ESGgrid_DELY

# Plot-specific definitions

plot_res='i' # background map resolution

#Note: Resolution can be 'c' (crude), 'l' (low), 'i' (intermediate), 'h' (high), or 'f' (full)
#      To plot maps with higher resolution than low,
#      you will need to download and install the basemap-data-hires package


#### END User-defined variables



ESGgrid_width  = ESGgrid_NX * ESGgrid_DELX
ESGgrid_height = ESGgrid_NY * ESGgrid_DELY

big_grid_width=np.ceil(ESGgrid_width*1.25)
big_grid_height=np.ceil(ESGgrid_height*1.25)

WRTCMP_width  = WRTCMP_nx * WRTCMP_dx
WRTCMP_height = WRTCMP_ny * WRTCMP_dy

fig = plt.figure()

#ax1 = plt.axes
ax1 = plt.subplot2grid((1,1), (0,0))

map1 = Basemap(projection='gnom', resolution=plot_res, lon_0 = ESGgrid_LON_CTR, lat_0 = ESGgrid_LAT_CTR, 
               width = big_grid_width, height=big_grid_height)

map1.drawmapboundary(fill_color='#9999FF')
map1.fillcontinents(color='#ddaa66',lake_color='#9999FF')
map1.drawcoastlines()

map2 = Basemap(projection='gnom', lon_0 = ESGgrid_LON_CTR, lat_0 = ESGgrid_LAT_CTR, 
               width = ESGgrid_width, height=ESGgrid_height)

#map2.drawmapboundary(fill_color='#9999FF')
#map2.fillcontinents(color='#ddaa66',lake_color='#9999FF')
#map2.drawcoastlines()


map3 = Basemap(llcrnrlon= WRTCMP_lon_lwr_left, llcrnrlat=WRTCMP_lat_lwr_left, width=WRTCMP_width, height=WRTCMP_height,
             resolution=plot_res, projection='lcc', lat_0 = ESGgrid_LAT_CTR, lon_0 = ESGgrid_LON_CTR)

#map3.drawmapboundary(fill_color='#9999FF')
#map3.fillcontinents(color='#ddaa66',lake_color='#9999FF',alpha=0.5)
#map3.drawcoastlines()


#Draw gnomonic compute grid rectangle:

lbx1, lby1 = map1(*map2(map2.xmin, map2.ymin, inverse= True))
ltx1, lty1 = map1(*map2(map2.xmin, map2.ymax, inverse= True))
rtx1, rty1 = map1(*map2(map2.xmax, map2.ymax, inverse= True))
rbx1, rby1 = map1(*map2(map2.xmax, map2.ymin, inverse= True))

verts1 = [
    (lbx1, lby1), # left, bottom
    (ltx1, lty1), # left, top
    (rtx1, rty1), # right, top
    (rbx1, rby1), # right, bottom
    (lbx1, lby1), # ignored
    ]

codes2 = [Path.MOVETO,
         Path.LINETO,
         Path.LINETO,
         Path.LINETO,
         Path.CLOSEPOLY,
         ]

path = Path(verts1, codes2)
patch = patches.PathPatch(path, facecolor='r', lw=2,alpha=0.5)
ax1.add_patch(patch)


#Draw lambert write grid rectangle:

# Define a function to get the lambert points in the gnomonic space

def get_lambert_points(gnomonic_map, lambert_map,pps):
    print("Hello from a function")
    
    # This function takes the lambert domain we have defined, lambert_map, as well as 
    # pps (the number of points to interpolate and draw for each side of the lambert "rectangle"), 
    # and returns an array of two lists: one a list of tuples of the 4*ppf + 4 vertices mapping the approximate shape 
    # of the lambert domain on the gnomonic map, the other a list of "draw" instructions to be used by
    # the PathPatch function
    
    # pps is recommended 10 or less due to time of calculation
    
    # Start array with bottom left point, "MOVETO" instruction
    vertices = [gnomonic_map(*lambert_map(lambert_map.xmin, lambert_map.ymin, inverse= True))]
    instructions = [Path.MOVETO]
    
    # Next generate the rest of the left side
    lefty = np.linspace(lambert_map.ymin, lambert_map.ymax, num=pps+1, endpoint=False)
    
    for y in lefty[1:]:
        vertices.append(tuple(gnomonic_map(*lambert_map(lambert_map.xmin, y, inverse= True))))
        instructions.append(Path.LINETO)
        
    # Next generate the top of the domain
    topx = np.linspace(lambert_map.xmin, lambert_map.xmax, num=pps+1, endpoint=False)
    
    for x in topx:
        vertices.append(tuple(gnomonic_map(*lambert_map(x, lambert_map.ymax, inverse= True))))
        instructions.append(Path.LINETO)

    # Next generate the right side of the domain
    righty = np.linspace(lambert_map.ymax, lambert_map.ymin, num=pps+1, endpoint=False)
    
    for y in righty:
        vertices.append(tuple(gnomonic_map(*lambert_map(lambert_map.xmax, y, inverse= True))))
        instructions.append(Path.LINETO)

        
    # Finally generate the bottom of the domain
    bottomx = np.linspace(lambert_map.xmax, lambert_map.xmin, num=pps+1, endpoint=False)
    
    for x in bottomx:
        vertices.append(tuple(gnomonic_map(*lambert_map(x, lambert_map.ymin, inverse= True))))
        instructions.append(Path.LINETO)

    # Need to replace final instruction with Path.CLOSEPOLY
    instructions[-1] = Path.CLOSEPOLY

    print ("vertices=",vertices)
    print ("instructions=",instructions)

    return vertices,instructions

# Call the function we just defined to generate a polygon roughly approximating the lambert "rectangle" in gnomonic space

verts3,codes3=get_lambert_points(map1, map3,10)

# Now draw!

path = Path(verts3, codes3)
patch = patches.PathPatch(path, facecolor='w', lw=2,alpha=0.5)
ax1.add_patch(patch)


plt.show()


