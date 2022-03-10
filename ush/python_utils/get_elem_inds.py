#!/usr/bin/env python3

from .change_case import lowercase
from .check_var_valid_value import check_var_valid_value

def get_elem_inds(arr, match, ret_type):
    """ Function that returns indices of elements of array
    that match a given string

    Args:
        arr: the list
        match: element to match (case insenensitive)
        ret_type: the return type can be any of [ 'first', 'last', 'all' ]
    Returns:
        A list of indices
    """
    ret_type = lowercase(ret_type)
    check_var_valid_value(ret_type, ['first', 'last', 'all'])

    if ret_type == 'first':
        for i,e in enumerate(arr):
            if e == match:
                return i
    elif ret_type == 'last':
        for i in range(len(arr)-1, -1, -1):
            if arr[i] == match:
                return i
    else:
        return [i for i,e in enumerate(arr) if e == match]
    
