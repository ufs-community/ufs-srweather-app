import argparse
import glob
from pathlib import Path

import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from matplotlib.path import Path as mplPath
import matplotlib.patches as mpatches
import numpy as np

def read_latlon_file(filename):
    lats, lons = [], []
    with open(filename, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) == 2:
                lat, lon = map(float, parts)
                lats.append(lat)
                lons.append(lon)
    return lats, lons

def is_near_pole(lats, threshold=80):
    return any(lat >= threshold or lat <= -threshold for lat in lats)

def plot_points_on_map(lats, lons, output_file='map.png', threshold=80):
    if not lats or not lons:
        print(f"Skipping {output_file}: no data points.")
        return
    near_pole = is_near_pole(lats, threshold)
    if near_pole:
        # Use AzimuthalEquidistant centered on the North or South Pole
        pole_lat = 90 if max(lats) >= threshold else -90
        projection = ccrs.AzimuthalEquidistant(central_latitude=pole_lat, central_longitude=0)
        extent = None  # Let cartopy handle it
        print("Using AzimuthalEquidistant projection (polar view)")
    else:
        # Default to PlateCarree
        projection = ccrs.PlateCarree()
        extent = [min(lons)-1, max(lons)+1, min(lats)-1, max(lats)+1]
        print("Using PlateCarree projection")

    fig = plt.figure(figsize=(8, 8) if near_pole else (10, 6))
    ax = plt.axes(projection=projection)

    if near_pole:
        if max(lats) >= threshold:
            lat0 = 90
            lat1 = min(lats)
        else:
            lat0 = -90
            lat1 = max(lats)
        ax.set_extent([-180, 180, lat1, lat0], crs=ccrs.PlateCarree())
    else:
        ax.set_extent([min(lons)-1, max(lons)+1, min(lats)-1, max(lats)+1], crs=ccrs.PlateCarree())

    ax.add_feature(cfeature.COASTLINE)
    ax.add_feature(cfeature.BORDERS, linestyle=':')
    ax.add_feature(cfeature.STATES, linewidth=0.5)
    ax.gridlines(draw_labels=True)

    ax.scatter(lons, lats, color='red', marker='o', s=20, transform=ccrs.PlateCarree())

    plt.title('Lat-Lon Points on Map')
    print(f"Saving map to {output_file}")
    plt.savefig(output_file, bbox_inches='tight')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
                     description="Plots METplus polyfiles on a map")

    parser.add_argument('-i', '--input_file', default='latlon.txt',
                        help='Name of METplus polyfile')
    parser.add_argument('-t', '--threshold', default=80, help='Threshold +/- latitude; if there are plot points closer to the pole than this latitude, a polar projection will be used')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Script will be run in debug mode with more verbose output')
    pargs = parser.parse_args()

    for polyfile in list(glob.glob(pargs.input_file)):

        output_file = Path(polyfile).stem
        lats, lons = read_latlon_file(polyfile)
        plot_points_on_map(lats, lons, output_file, pargs.threshold)
