#!/bin/bash

export ECF_HOME="{{ ecf_home }}"
export ECF_DATA_ROOT="{{ ecf_data_root }}"
export ECF_OUTPUTDIR="{{ ecf_outputdir }}"
export ECF_COMDIR="{{ ecf_comdir }}"
export LFS_OUTPUTDIR="{{ lfs_outputdir }}"

mkdir -p $ECF_HOME
mkdir -p $ECF_DATA_ROOT
mkdir -p $ECF_OUTPUTDIR
mkdir -p $ECF_COMDIR
mkdir -p $LFS_OUTPUTDIR

ecflow_client --alter add variable EMC_USER chan-hoo.jeon /emc_aqm
ecflow_client --alter add variable ECF_INCLUDE {{ exptdir }}/ecf/include /emc_aqm

ecflow_client --alter add variable PDY {{ pdy }} /emc_aqm/primary/00
ecflow_client --alter add variable PDY {{ pdy }} /emc_aqm/primary/06
ecflow_client --alter add variable PDY {{ pdy }} /emc_aqm/primary/12
ecflow_client --alter add variable PDY {{ pdy }} /emc_aqm/primary/18

