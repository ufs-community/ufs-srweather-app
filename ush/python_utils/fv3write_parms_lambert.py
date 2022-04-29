#!/usr/bin/env python
#
# To use this tool, you should source the regional workflow environment
#    $> source env/wflow_xxx.env
# and activate pygraf (or any one with cartopy installation)
#    $> conda activate pygraf
#

import argparse

import cartopy.crs as ccrs

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#
# Main function to return parameters for the FV3 write component.
#

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Determine FV3 write component lat1/lon1 for Lamert Conformal map projection',
                                     epilog='''        ---- Yunheng Wang (2021-07-15).
                                            ''')
                                     #formatter_class=CustomFormatter)
    parser.add_argument('-v','--verbose', help='Verbose output',                        action="store_true")
    parser.add_argument('-ca','--ctrlat', help='Lambert Conformal central latitude',    type=float, default=38.5  )
    parser.add_argument('-co','--ctrlon', help='Lambert Conformal central longitude',   type=float, default=-97.5 )
    parser.add_argument('-s1','--stdlat1',help='Lambert Conformal standard latitude1',  type=float, default=38.5  )
    parser.add_argument('-s2','--stdlat2',help='Lambert Conformal standard latitude2',  type=float, default=38.5  )
    parser.add_argument('-nx',            help='number of grid in X direction',         type=int,   default=301   )
    parser.add_argument('-ny'            ,help='number of grid in Y direction',         type=int,   default=301   )
    parser.add_argument('-dx'            ,help='grid resolution in X direction (meter)',type=float, default=3000.0)
    parser.add_argument('-dy'            ,help='grid resolution in Y direction (meter)',type=float, default=3000.0)

    args = parser.parse_args()

    if args.verbose:
      print("Write component Lambert Conformal Parameters:")
      print(f"    cen_lat = {args.ctrlat}, cen_lon = {args.ctrlon}, stdlat1 = {args.stdlat1}, stdlat2 = {args.stdlat2}")
      print(f"    nx = {args.nx}, ny = {args.ny}, dx = {args.dx}, dy = {args.dy}")

    #-----------------------------------------------------------------------
    #
    # Lambert grid
    #
    #-----------------------------------------------------------------------

    nx1 = args.nx
    ny1 = args.ny
    dx1 = args.dx
    dy1 = args.dy

    ctrlat = args.ctrlat
    ctrlon = args.ctrlon

    xctr = (nx1-1)/2*dx1
    yctr = (ny1-1)/2*dy1

    carr= ccrs.PlateCarree()

    proj1=ccrs.LambertConformal(central_longitude=ctrlon, central_latitude=ctrlat,
                 false_easting=xctr, false_northing= yctr, secant_latitudes=None,
                 standard_parallels=(args.stdlat1, args.stdlat2), globe=None)

    lonlat1 = carr.transform_point(0.0,0.0,proj1)

    if args.verbose:
        print()
        print(f'    lat1 = {lonlat1[1]}, lon1 = {lonlat1[0]}')
        print('\n')

    #-----------------------------------------------------------------------
    #
    # Output write component parameters
    #
    #-----------------------------------------------------------------------

    print()
    print("output_grid:             'lambert_conformal'")
    print(f"cen_lat:                 {args.ctrlat}")
    print(f"cen_lon:                 {args.ctrlon}")
    print(f"stdlat1:                 {args.stdlat1}")
    print(f"stdlat2:                 {args.stdlat2}")
    print(f"nx:                      {args.nx}")
    print(f"ny:                      {args.ny}")
    print(f"dx:                      {args.dx}")
    print(f"dy:                      {args.dy}")
    print(f"lat1:                    {lonlat1[1]}")
    print(f"lon1:                    {lonlat1[0]}")
    print()

    # End of program
