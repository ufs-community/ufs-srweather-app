#!/bin/sh
set -xeu

source ./machine-setup.sh > /dev/null 2>&1

pwd=$(pwd -P)

# prepare fixed data directories

RGNL_WFLOW_DIR=$( pwd )/..
cd ${RGNL_WFLOW_DIR}
mkdir -p fix/fix_fv3
cd fix

if [ ${target} == "theia" ]; then

    ln -sfn /scratch4/NCEPDEV/global/save/glopara/git/fv3gfs/fix/fix_am fix_am

elif [ ${target} == "hera" ]; then

    ln -sfn /scratch1/NCEPDEV/global/glopara/fix/fix_am fix_am

elif [[ ${target} == "wcoss_dell_p3" || ${target} == "wcoss" ||  ${target} == "wcoss_cray" ]]; then

    ln -sfn /gpfs/dell2/emc/modeling/noscrub/emc.campara/fix_fv3cam fix_am

elif [ ${target} == "odin" ]; then

    ln -sfn /scratch/ywang/fix/theia_fix/fix_am fix_am

elif [ ${target} == "cheyenne" ]; then

    ln -sfn /glade/p/ral/jntp/GMTB/FV3GFS_V1_RELEASE/fix/fix_am fix_am

elif [ ${target} == "jet" ]; then

    ln -sfn /lfs3/projects/hpc-wof1/ywang/regional_fv3/fix/fix_am fix_am

else

    echo "Unknown target " ${target}
    exit 1

fi

exit
