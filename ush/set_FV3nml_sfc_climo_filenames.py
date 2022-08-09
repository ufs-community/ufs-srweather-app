#!/usr/bin/env python3

import unittest
import os
import sys
import argparse
from textwrap import dedent

from python_utils import print_input_args, print_info_msg, print_err_msg_exit,\
                         check_var_valid_value,mv_vrfy,mkdir_vrfy,cp_vrfy,\
                         rm_vrfy,import_vars,set_env_var,load_shell_config,\
                         define_macos_utilities,find_pattern_in_str,cfg_to_yaml_str

from set_namelist import set_namelist

def set_FV3nml_sfc_climo_filenames():
    """
    This function sets the values of the variables in
    the forecast model's namelist file that specify the paths to the surface
    climatology files on the FV3LAM native grid (which are either pregenerated
    or created by the MAKE_SFC_CLIMO_TN task).  Note that the workflow
    generation scripts create symlinks to these surface climatology files
    in the FIXLAM directory, and the values in the namelist file that get
    set by this function are relative or full paths to these links.

    Args:
        None
    Returns:
        None
    """

    # import all environment variables
    import_vars()

    # The regular expression regex_search set below will be used to extract
    # from the elements of the array FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING
    # the name of the namelist variable to set and the corresponding surface
    # climatology field from which to form the name of the surface climatology file
    regex_search = "^[ ]*([^| ]+)[ ]*[|][ ]*([^| ]+)[ ]*$"

    # Set the suffix of the surface climatology files.
    suffix = "tileX.nc"

    # create yaml-complaint string
    settings = {}

    dummy_run_dir = os.path.join(EXPTDIR, "any_cyc")
    if DO_ENSEMBLE == "TRUE":
        dummy_run_dir += os.sep + "any_ensmem"

    namsfc_dict = {}
    for mapping in FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING:
        tup = find_pattern_in_str(regex_search, mapping)
        nml_var_name = tup[0]
        sfc_climo_field_name = tup[1]

        check_var_valid_value(sfc_climo_field_name, SFC_CLIMO_FIELDS)

        fp = os.path.join(FIXLAM, f'{CRES}.{sfc_climo_field_name}.{suffix}')
        if RUN_ENVIR != "nco":
            fp = os.path.relpath(os.path.realpath(fp), start=dummy_run_dir)

        namsfc_dict[nml_var_name] = fp
     
    settings['namsfc_dict'] = namsfc_dict
    settings_str = cfg_to_yaml_str(settings)


    print_info_msg(dedent(f'''
        The variable \"settings\" specifying values of the namelist variables
        has been set as follows:
        
        settings =\n\n''') + settings_str, verbose=VERBOSE)

    # Rename the FV3 namelist and call set_namelist
    fv3_nml_base_fp = f'{FV3_NML_FP}.base' 
    mv_vrfy(f'{FV3_NML_FP} {fv3_nml_base_fp}')

    try:
        set_namelist(["-q", "-n", fv3_nml_base_fp, "-u", settings_str, "-o", FV3_NML_FP])
    except:
        print_err_msg_exit(dedent(f'''
            Call to python script set_namelist.py to set the variables in the FV3
            namelist file that specify the paths to the surface climatology files
            failed.  Parameters passed to this script are:
              Full path to base namelist file:
                fv3_nml_base_fp = \"{fv3_nml_base_fp}\"
              Full path to output namelist file:
                FV3_NML_FP = \"{FV3_NML_FP}\"
              Namelist settings specified on command line (these have highest precedence):\n
                settings =\n\n''') + settings_str)

    rm_vrfy(f'{fv3_nml_base_fp}')

def parse_args(argv):
    """ Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Set surface climatology fields.'
    )

    parser.add_argument('-p', '--path-to-defns',
                        dest='path_to_defns',
                        required=True,
                        help='Path to var_defns file.')

    return parser.parse_args(argv)

if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    cfg = load_shell_config(args.path_to_defns)
    import_vars(dictionary=cfg)
    set_FV3nml_sfc_climo_filenames()

class Testing(unittest.TestCase):
    def test_set_FV3nml_sfc_climo_filenames(self):
        set_FV3nml_sfc_climo_filenames()
    def setUp(self):
        define_macos_utilities();
        set_env_var('DEBUG',True)
        set_env_var('VERBOSE',True)
        USHDIR = os.path.dirname(os.path.abspath(__file__))
        EXPTDIR = os.path.join(USHDIR, "test_data", "expt");
        FIXLAM = os.path.join(EXPTDIR, "fix_lam")
        mkdir_vrfy("-p",FIXLAM)
        cp_vrfy(os.path.join(USHDIR,f'templates{os.sep}input.nml.FV3'), \
                os.path.join(EXPTDIR,'input.nml'))
        set_env_var("USHDIR",USHDIR)
        set_env_var("EXPTDIR",EXPTDIR)
        set_env_var("FIXLAM",FIXLAM)
        set_env_var("DO_ENSEMBLE",False)
        set_env_var("CRES","C3357")
        set_env_var("RUN_ENVIR","nco")
        set_env_var("FV3_NML_FP",os.path.join(EXPTDIR,"input.nml"))

        FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING=[
            "FNALBC  | snowfree_albedo",
            "FNALBC2 | facsf",
            "FNTG3C  | substrate_temperature",
            "FNVEGC  | vegetation_greenness",
            "FNVETC  | vegetation_type",
            "FNSOTC  | soil_type",
            "FNVMNC  | vegetation_greenness",
            "FNVMXC  | vegetation_greenness",
            "FNSLPC  | slope_type",
            "FNABSC  | maximum_snow_albedo"
        ]
        SFC_CLIMO_FIELDS=[
            "facsf",
            "maximum_snow_albedo",
            "slope_type",
            "snowfree_albedo",
            "soil_type",
            "substrate_temperature",
            "vegetation_greenness",
            "vegetation_type"
        ]
        set_env_var("FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING",
                     FV3_NML_VARNAME_TO_SFC_CLIMO_FIELD_MAPPING)
        set_env_var("SFC_CLIMO_FIELDS",SFC_CLIMO_FIELDS)

