#!/usr/bin/env python3

import os
import unittest
from textwrap import dedent

from python_utils import import_vars,export_vars,set_env_var,list_to_str,\
                         print_input_args, print_info_msg, print_err_msg_exit,\
                         define_macos_utilities,load_xml_file,has_tag_with_value,find_pattern_in_str

def set_ozone_param(ccpp_phys_suite_fp):
    """ Function that does the following:
    (1) Determines the ozone parameterization being used by checking in the
        CCPP physics suite XML.
   
    (2) Sets the name of the global ozone production/loss file in the FIXgsm
        FIXgsm system directory to copy to the experiment's FIXam directory.
   
    (3) Resets the last element of the workflow array variable
        FIXgsm_FILES_TO_COPY_TO_FIXam that contains the files to copy from
        FIXgsm to FIXam (this last element is initially set to a dummy 
        value) to the name of the ozone production/loss file set in the
        previous step.
   
    (4) Resets the element of the workflow array variable 
        CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING (this array contains the 
        mapping between the symlinks to create in any cycle directory and
        the files in the FIXam directory that are their targets) that 
        specifies the mapping for the ozone symlink/file such that the 
        target FIXam file name is set to the name of the ozone production/
        loss file set above.

    Args:
        ccpp_phys_suite_fp: full path to CCPP physics suite
    Returns:
        ozone_param: a string
    """

    print_input_args(locals())

    # import all environment variables
    import_vars()

    #
    #-----------------------------------------------------------------------
    #
    # Get the name of the ozone parameterization being used.  There are two
    # possible ozone parameterizations:  
    #
    # (1) A parameterization developed/published in 2015.  Here, we refer to
    #     this as the 2015 parameterization.  If this is being used, then we
    #     set the variable ozone_param to the string "ozphys_2015".
    #
    # (2) A parameterization developed/published sometime after 2015.  Here,
    #     we refer to this as the after-2015 parameterization.  If this is
    #     being used, then we set the variable ozone_param to the string 
    #     "ozphys".
    #
    # We check the CCPP physics suite definition file (SDF) to determine the 
    # parameterization being used.  If this file contains the line
    #
    #   <scheme>ozphys_2015</scheme>
    #
    # then the 2015 parameterization is being used.  If it instead contains
    # the line
    #
    #   <scheme>ozphys</scheme>
    #
    # then the after-2015 parameterization is being used.  (The SDF should
    # contain exactly one of these lines; not both nor neither; we check for 
    # this.)  
    #
    #-----------------------------------------------------------------------
    #
    tree = load_xml_file(ccpp_phys_suite_fp)
    ozone_param = ""
    if has_tag_with_value(tree, "scheme", "ozphys_2015"):
      fixgsm_ozone_fn="ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77"
      ozone_param = "ozphys_2015"
    elif has_tag_with_value(tree, "scheme", "ozphys"):
      fixgsm_ozone_fn="global_o3prdlos.f77"
      ozone_param = "ozphys"
    else:
      print_err_msg_exit(f'''
        Unknown or no ozone parameterization
        specified in the CCPP physics suite file (ccpp_phys_suite_fp):
          ccpp_phys_suite_fp = \"{ccpp_phys_suite_fp}\"
          ozone_param = \"{ozone_param}\"''')
    #
    #-----------------------------------------------------------------------
    #
    # Set the last element of the array FIXgsm_FILES_TO_COPY_TO_FIXam to the
    # name of the ozone production/loss file to copy from the FIXgsm to the
    # FIXam directory.
    #
    #-----------------------------------------------------------------------
    #
    i=len(FIXgsm_FILES_TO_COPY_TO_FIXam) - 1
    FIXgsm_FILES_TO_COPY_TO_FIXam[i]=f"{fixgsm_ozone_fn}"
    #
    #-----------------------------------------------------------------------
    #
    # Set the element in the array CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING that
    # specifies the mapping between the symlink for the ozone production/loss
    # file that must be created in each cycle directory and its target in the 
    # FIXam directory.  The name of the symlink is alrady in the array, but
    # the target is not because it depends on the ozone parameterization that 
    # the physics suite uses.  Since we determined the ozone parameterization
    # above, we now set the target of the symlink accordingly.
    #
    #-----------------------------------------------------------------------
    #
    ozone_symlink="global_o3prdlos.f77"
    fixgsm_ozone_fn_is_set=False
    regex_search="^[ ]*([^| ]*)[ ]*[|][ ]*([^| ]*)[ ]*$"
    num_symlinks=len(CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING)
    
    for i in range(num_symlinks):
      mapping=CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[i]
      symlink = find_pattern_in_str(regex_search, mapping)
      if symlink is not None:
        symlink = symlink[0]
      if symlink == ozone_symlink:
        regex_search="^[ ]*([^| ]+[ ]*)[|][ ]*([^| ]*)[ ]*$"
        mapping_ozone = find_pattern_in_str(regex_search, mapping)[0]
        mapping_ozone=f"{mapping_ozone}| {fixgsm_ozone_fn}"
        CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING[i]=f"{mapping_ozone}"
        fixgsm_ozone_fn_is_set=True
        break
    #
    #-----------------------------------------------------------------------
    #
    # If fixgsm_ozone_fn_is_set is set to True, then the appropriate element
    # of the array CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING was set successfully.
    # In this case, print out the new version of this array.  Otherwise, print
    # out an error message and exit.
    #
    #-----------------------------------------------------------------------
    #
    if fixgsm_ozone_fn_is_set:
    
      msg=dedent(f'''
        After setting the file name of the ozone production/loss file in the
        FIXgsm directory (based on the ozone parameterization specified in the
        CCPP suite definition file), the array specifying the mapping between
        the symlinks that need to be created in the cycle directories and the
        files in the FIXam directory is:
        
        ''')
      msg+=dedent(f'''
          CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING = {list_to_str(CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING)}
        ''')
      print_info_msg(msg,verbose=VERBOSE)
    
    else:
    
      print_err_msg_exit(f'''
        Unable to set name of the ozone production/loss file in the FIXgsm directory
        in the array that specifies the mapping between the symlinks that need to
        be created in the cycle directories and the files in the FIXgsm directory:
          fixgsm_ozone_fn_is_set = \"{fixgsm_ozone_fn_is_set}\"''')

    EXPORTS = ["CYCLEDIR_LINKS_TO_FIXam_FILES_MAPPING", "FIXgsm_FILES_TO_COPY_TO_FIXam"]
    export_vars(env_vars=EXPORTS)

    return ozone_param

class Testing(unittest.TestCase):
    def test_set_ozone_param(self):
        self.assertEqual( "ozphys_2015",
            set_ozone_param(ccpp_phys_suite_fp=f"test_data{os.sep}suite_FV3_GSD_SAR.xml") )
    def setUp(self):
        define_macos_utilities();
        set_env_var('DEBUG',True)
        set_env_var('VERBOSE',True)

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
