#!/usr/bin/env bash

#for machine in derecho gaea gaea-c6 hera.gnu.com hera.intel.nco hercules jet orion; do 
  #if [[ $machine != 'gaea-c6' ]] && [[ $machine != 'orion' ]]; then
  #echo grid_SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_WoFS_v0 >> ../tests/WE2E/machine_suites/coverage.${machine}
  #echo "##### $machine ####"
  #fi
  #wc -l ../tests/WE2E/machine_suites/coverage.${machine} | awk '{print $1}'
  #cat ../tests/WE2E/machine_suites/coverage.${machine}
  #echo ""
#done

:<<'END'
declare platform
if [[ "${SRW_PLATFORM}" =~ ^(az|g|p)clusternoaa ]]; then
    platform='noaacloud'
else
    platform="${SRW_PLATFORM}"
fi

// Update coverage suites to include skill-score we2e test
                                def platform = env.SRW_PLATFORM
                                def coverage_test_name = platform

                                if (single_test == 'coverage') {
                                   if (platform == 'hera') {
                                       coverage_test_name = 'hera.${env.SRW_COMPILER}.*'
                                   }
                                   if (platform == 'pclusternoaav2use1') {
                                       coverage_test_name = "noaacloud.aws"
                                   }
                                   if (platform == 'azclusternoaav2use1') {
                                       coverage_test_name = 'noaacloud.azure'
                                   }
                                   if (platform == 'gclusternoaav2usc1') {
                                       coverage_test_name = 'noaacloud.gcp'
                                   }
                                   if (platform != 'orion') {
                                       sh "echo grid_SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_WoFS_v0 >> ${WORKSPACE}/${SRW_PLATFORM}/tests/WE2E/machine_suites/coverage.${coverage_test_name}"
                                   }
                                }

END

function create_noaacloud_coverage () {

	mv tests/WE2E/machine_suites/coverage.noaacloud.$delete_1 tests/WE2E/machine_suites/coverage.noaacloud.$delete_1-og
	mv tests/WE2E/machine_suites/coverage.noaacloud.$delete_2 tests/WE2E/machine_suites/coverage.noaacloud.$delete_2-og
	mv tests/WE2E/machine_suites/coverage.noaacloud.$keep tests/WE2E/machine_suites/coverage.noaacloud
}


if [[ "${SRW_WE2E_SINGLE_TEST}" == 'coverage' ]]; then
     
    # Update noaacloud coverage suite
    if [[ "${SRW_PLATFORM}" == 'pclusternoaav2use1' ]]; then
	delete_1='azure'
	delete_2='gcp'
	keep='aws'
	create_noaacloud_coverage
    fi
    if [[ "${SRW_PLATFORM}" == 'azclusternoaav2use1' ]]; then
	delete_1='aws'
	delete_2='gcp'
	keep='azure'
	create_noaacloud_coverage
    fi
    if [[ "${SRW_PLATFORM}" == 'gclusternoaav2usc1' ]]; then
	delete_1='aws'
	delete_2='azure'
	keep='gcp'
	create_noaacloud_coverage
    fi

    # Add skill-score WE2E test to coverage suites
    if [[ "${SRW_PLATFORM}" == 'hera' ]]; then
        coverage_test_name = "hera.${SRW_COMPILER}.*"
    else 
        coverage_test_name="${SRW_PLATFORM}"
    fi
    if [[ "${SRW_PLATFORM}" != 'orion' ]]; then 
	   echo grid_SUBCONUS_Ind_3km_ics_FV3GFS_lbcs_FV3GFS_suite_WoFS_v0 >> tests/WE2E/machine_suites/coverage.${coverage_test_name}
    fi
fi
