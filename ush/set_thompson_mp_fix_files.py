#!/usr/bin/env python3

import os
import unittest
from textwrap import dedent

from python_utils import import_vars,export_vars,set_env_var,list_to_str,\
                         print_input_args,print_info_msg, print_err_msg_exit,\
                         define_macos_utilities,load_xml_file,has_tag_with_value

def set_thompson_mp_fix_files(ccpp_phys_suite_fp, thompson_mp_climo_fn):
    """ Function that first checks whether the Thompson
    microphysics parameterization is being called by the selected physics
    suite.  If not, it sets the output variable whose name is specified by
    output_varname_sdf_uses_thompson_mp to "FALSE" and exits.  If so, it 
    sets this variable to "TRUE" and modifies the workflow arrays
    FIXgsm_FILES_TO_COPY_TO_FIXam and CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING
    to ensure that fixed files needed by the Thompson microphysics
    parameterization are copied to the FIXam directory and that appropriate
    symlinks to these files are created in the run directories.

    Args:
        ccpp_phys_suite_fp: full path to CCPP physics suite
        thompson_mp_climo_fn: netcdf file for thompson microphysics
    Returns:
        boolean: sdf_uses_thompson_mp
    """

    print_input_args(locals())

    # import all environment variables
    import_vars()

    #
    #-----------------------------------------------------------------------
    #
    # Check the suite definition file to see whether the Thompson microphysics
    # parameterization is being used.
    #
    #-----------------------------------------------------------------------
    #
    tree = load_xml_file(ccpp_phys_suite_fp)
    sdf_uses_thompson_mp = has_tag_with_value(tree, "scheme", "mp_thompson")
    #
    #-----------------------------------------------------------------------
    #
    # If the Thompson microphysics parameterization is being used, then...
    #
    #-----------------------------------------------------------------------
    #
    if sdf_uses_thompson_mp:
    #
    #-----------------------------------------------------------------------
    #
    # Append the names of the fixed files needed by the Thompson microphysics
    # parameterization to the workflow array FIXgsm_FILES_TO_COPY_TO_FIXam, 
    # and append to the workflow array CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING 
    # the mappings between these files and the names of the corresponding 
    # symlinks that need to be created in the run directories.
    #
    #-----------------------------------------------------------------------
    #
        thompson_mp_fix_files=[
          "CCN_ACTIVATE.BIN",
          "freezeH2O.dat",
          "qr_acr_qg.dat",
          "qr_acr_qs.dat",
          "qr_acr_qgV2.dat",
          "qr_acr_qsV2.dat"
        ]
    
        if (EXTRN_MDL_NAME_ICS  != "HRRR" and EXTRN_MDL_NAME_ICS  != "RAP") or \
           (EXTRN_MDL_NAME_LBCS != "HRRR" and EXTRN_MDL_NAME_LBCS != "RAP"):
          thompson_mp_fix_files.append(thompson_mp_climo_fn)
    
        FIXgsm_FILES_TO_COPY_TO_FIXam.extend(thompson_mp_fix_files)
    
        for fix_file in thompson_mp_fix_files:
          mapping=f"{fix_file} | {fix_file}"
          CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING.append(mapping)
    
        msg=dedent(f'''
            Since the Thompson microphysics parameterization is being used by this 
            physics suite (CCPP_PHYS_SUITE), the names of the fixed files needed by
            this scheme have been appended to the array FIXgsm_FILES_TO_COPY_TO_FIXam, 
            and the mappings between these files and the symlinks that need to be 
            created in the cycle directories have been appended to the array
            CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING.  After these modifications, the 
            values of these parameters are as follows:
            
            ''')
        msg+=dedent(f'''
                CCPP_PHYS_SUITE = \"{CCPP_PHYS_SUITE}\"
            
                FIXgsm_FILES_TO_COPY_TO_FIXam = {list_to_str(FIXgsm_FILES_TO_COPY_TO_FIXam)}
            ''')
        msg+=dedent(f'''
                CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING = {list_to_str(CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING)}
            ''')
        print_info_msg(msg)

        EXPORTS = [ "CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING", "FIXgsm_FILES_TO_COPY_TO_FIXam" ]
        export_vars(env_vars=EXPORTS)

    return sdf_uses_thompson_mp

class Testing(unittest.TestCase):
    def test_set_thompson_mp_fix_files(self):
        self.assertEqual( True,
            set_thompson_mp_fix_files(ccpp_phys_suite_fp=f"test_data{os.sep}suite_FV3_GSD_SAR.xml",
                thompson_mp_climo_fn="Thompson_MP_MONTHLY_CLIMO.nc") )
    def setUp(self):
        define_macos_utilities();
        set_env_var('DEBUG',True)
        set_env_var('VERBOSE',True)
        set_env_var('EXTRN_MDL_NAME_ICS',"FV3GFS")
        set_env_var('EXTRN_MDL_NAME_LBCS',"FV3GFS")
        set_env_var('CCPP_PHYS_SUITE',"FV3_GSD_SAR")

        CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING = [
            "aerosol.dat                | global_climaeropac_global.txt",
            "co2historicaldata_2010.txt | fix_co2_proj/global_co2historicaldata_2010.txt",
            "co2historicaldata_2011.txt | fix_co2_proj/global_co2historicaldata_2011.txt",
            "co2historicaldata_2012.txt | fix_co2_proj/global_co2historicaldata_2012.txt",
            "co2historicaldata_2013.txt | fix_co2_proj/global_co2historicaldata_2013.txt",
            "co2historicaldata_2014.txt | fix_co2_proj/global_co2historicaldata_2014.txt",
            "co2historicaldata_2015.txt | fix_co2_proj/global_co2historicaldata_2015.txt",
            "co2historicaldata_2016.txt | fix_co2_proj/global_co2historicaldata_2016.txt",
            "co2historicaldata_2017.txt | fix_co2_proj/global_co2historicaldata_2017.txt",
            "co2historicaldata_2018.txt | fix_co2_proj/global_co2historicaldata_2018.txt",
            "co2historicaldata_2019.txt | fix_co2_proj/global_co2historicaldata_2019.txt",
            "co2historicaldata_2020.txt | fix_co2_proj/global_co2historicaldata_2020.txt",
            "co2historicaldata_2021.txt | fix_co2_proj/global_co2historicaldata_2021.txt",
            "co2historicaldata_glob.txt | global_co2historicaldata_glob.txt",
            "co2monthlycyc.txt          | co2monthlycyc.txt",
            "global_h2oprdlos.f77       | global_h2o_pltc.f77",
            "global_zorclim.1x1.grb     | global_zorclim.1x1.grb",
            "sfc_emissivity_idx.txt     | global_sfc_emissivity_idx.txt",
            "solarconstant_noaa_an.txt  | global_solarconstant_noaa_an.txt",
            "global_o3prdlos.f77        | ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77"]

        FIXgsm_FILES_TO_COPY_TO_FIXam = [
            "global_glacier.2x2.grb",
            "global_maxice.2x2.grb",
            "RTGSST.1982.2012.monthly.clim.grb",
            "global_snoclim.1.875.grb",
            "CFSR.SEAICE.1982.2012.monthly.clim.grb",
            "global_soilmgldas.t126.384.190.grb",
            "seaice_newland.grb",
            "global_climaeropac_global.txt",
            "fix_co2_proj/global_co2historicaldata_2010.txt",
            "fix_co2_proj/global_co2historicaldata_2011.txt",
            "fix_co2_proj/global_co2historicaldata_2012.txt",
            "fix_co2_proj/global_co2historicaldata_2013.txt",
            "fix_co2_proj/global_co2historicaldata_2014.txt",
            "fix_co2_proj/global_co2historicaldata_2015.txt",
            "fix_co2_proj/global_co2historicaldata_2016.txt",
            "fix_co2_proj/global_co2historicaldata_2017.txt",
            "fix_co2_proj/global_co2historicaldata_2018.txt",
            "fix_co2_proj/global_co2historicaldata_2019.txt",
            "fix_co2_proj/global_co2historicaldata_2020.txt",
            "fix_co2_proj/global_co2historicaldata_2021.txt",
            "global_co2historicaldata_glob.txt",
            "co2monthlycyc.txt",
            "global_h2o_pltc.f77",
            "global_hyblev.l65.txt",
            "global_zorclim.1x1.grb",
            "global_sfc_emissivity_idx.txt",
            "global_solarconstant_noaa_an.txt",
            "geo_em.d01.lat-lon.2.5m.HGT_M.nc",
            "HGT.Beljaars_filtered.lat-lon.30s_res.nc",
            "ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77"]

        set_env_var('CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING', CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING)
        set_env_var('FIXgsm_FILES_TO_COPY_TO_FIXam', FIXgsm_FILES_TO_COPY_TO_FIXam)

