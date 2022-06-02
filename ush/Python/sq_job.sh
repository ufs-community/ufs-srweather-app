#!/bin/sh

#SBATCH --account=an_account
#SBATCH --qos=batch
#SBATCH --ntasks=4
#SBATCH --time=0:20:00
#SBATCH --job-name="plot_allvars"
#SBATCH --out=plot_allvars.out

# Prior to submitting the script the following environment variables
# must be set using export or setenv
# HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
# EXPTDIR=/path-to/expt_dirs/your_experiment

cd ${HOMErrfs}/ush/Python
set -x
. /apps/lmod/lmod/init/sh

module purge
module load hpss

############
# Python environment for Jet and Hera
module use -a /contrib/miniconda3/modulefiles
module load miniconda3
conda activate pygraf

############
# Python environment for Orion
############
#module use -a /apps/contrib/miniconda3-noaa-gsl/modulefiles
#module load miniconda3
#conda activate pygraf

############
# Python environment for Gaea
############
#module use /lustre/f2/pdata/esrl/gsd/contrib/modulefiles
#module load miniconda3/4.8.3-regional-workflow

############
# Path to shape files
############
#Hera:
SHAPE_FILES=/scratch2/BMC/det/UFS_SRW_app/v1p0/fix_files/NaturalEarth
#Jet: 
#SHAPE_FILES=/lfs4/BMC/wrfruc/FV3-LAM/NaturalEarth
#Orion: 
#SHAPE_FILES=/work/noaa/gsd-fv3-dev/UFS_SRW_App/v1p0/fix_files/NaturalEarth
#Gaea: 
#SHAPE_FILES=/lustre/f2/pdata/esrl/gsd/ufs/NaturalEarth

export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}
export FCST_START=6
export FCST_END=${FCST_LEN_HRS}
export FCST_INC=6

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
