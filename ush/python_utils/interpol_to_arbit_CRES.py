#!/usr/bin/env python3

def interpol_to_arbit_CRES(RES, RES_array, prop_array):
    """ Function to interpolate (or extrapolate) a grid cell size-dependent property
    to an arbitrary cubed-sphere resolution using arrays that specify a set of property
    values for a corresponding set of resolutions

    Args:
        RES: The cubed-sphere resolution at which to find the value of a property.
            This is in units of number of cells (in either of the two horizontal
            directions) on any one of the tiles of a cubed-sphere grid.

        RES_array: The name of the array containing the cubed-sphere resolutions for
            which corresponding property values are given (in prop_array).  These
            are assumed to be given from smallest to largest.
 
        prop_array: The name of the array containing the values of the property corres-
            ponding to the cubed-sphere resolutions in RES_array.
    Returns:
        Interpolated (extrapolated) property value
    """

    num_valid_RESes = len(RES_array)
    i_min = 0
    i_max = num_valid_RESes - 1 

    if RES <= RES_array[i_min]:
        prop = prop_array[i_min]
    elif RES > RES_array[i_max]:
        prop = prop_array[i_max]
    else:
        for i in range(0,num_valid_RESes-1):
            if RES > RES_array[i] and RES <= RES_array[i+1]:
                RES1 = RES_array[i]
                RES2 = RES_array[i+1]
                prop1 = prop_array[i]
                prop2 = prop_array[i+1]
                m_slope = (prop2 - prop1) / (RES2 - RES1)
                y_intcpt = (RES2 * prop1 - RES1 * prop2) / (RES2 - RES1)
                prop = m_slope * RES + y_intcpt

    return prop

