#!/bin/sh
#PBS -A an_account 
#PBS -q regular
#PBS -l select=1:mpiprocs=24:ncpus=24
#PBS -l walltime=00:20:00
#PBS -N plot_allvars
#PBS -j oe -o plot_allvars.out 

# Prior to submitting the script the following environment variables
# must be set using export or setenv
# HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
# EXPTDIR=/path-to/expt_dirs/your_experiment

cd ${HOMErrfs}/ush/Python
set -x

source /etc/profile.d/modules.sh

############
# Python environment for Cheyenne 
############
ncar_pylib /glade/p/ral/jntp/UFS_SRW_app/ncar_pylib/python_graphics

############
# Path to shape files
############
#Cheyenne:
SHAPE_FILES=/glade/p/ral/jntp/UFS_SRW_app/tools/NaturalEarth

export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}
export FCST_START=3
export FCST_END=${FCST_LEN_HRS}
export FCST_INC=3

# Usage statement:      Make sure all the necessary modules can be imported.
#                       The following command line arguments are needed:
#                       1. Cycle date/time in YYYYMMDDHH format
#                       2. Starting forecast hour in HHH format
#                       3. Ending forecast hour in HHH format
#                       4. Forecast hour increment
#                       5. EXPT_DIR: Experiment directory
#                          -Postprocessed data should be found in the directory:
#                            EXPT_DIR/YYYYMMDDHH/postprd/
#                       6. CARTOPY_DIR:  Base directory of cartopy shapefiles
#                          -File structure should be:
#                            CARTOPY_DIR/shapefiles/natural_earth/cultural/*.shp
#                       7. POST_OUTPUT_DOMAIN_NAME:  Name of native domain
#                          used in forecast and in constructing the names
#                          of the post output files.


python plot_allvars.py ${CDATE} ${FCST_START} ${FCST_END} ${FCST_INC} \
                       ${EXPTDIR} ${SHAPE_FILES} ${POST_OUTPUT_DOMAIN_NAME}
