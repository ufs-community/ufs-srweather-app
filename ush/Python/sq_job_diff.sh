#!/bin/sh

#SBATCH --account=an_account
#SBATCH --qos=batch
#SBATCH --ntasks=8
#SBATCH --time=0:30:00
#SBATCH --job-name="plot_allvars_diff"
#SBATCH --out=plot_allvars.out

# Prior to submitting the script the following environment variables
# must be set using export or setenv
# HOMErrfs=/path-to/ufs-srweather-app/regional_workflow
# EXPTDIR1=/path-to/expt_dirs/your_experiment1
# EXPTDIR2=/path-to/expt_dirs/your_experiment2

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
#module use -a /apps/contrib/miniconda3-noaa-gsl/modulefiles
#module load miniconda3
#conda activate pygraf

############
# Path to shape files
############
#Hera:
SHAPE_FILES=/scratch2/NCEPDEV/fv3-cam/Chan-hoo.Jeon/tools/NaturalEarth
#Jet: 
#Orion: 
#SHAPE_FILES=/home/chjeon/tools/NaturalEarth
#Gaea: 

export GLOBAL_VAR_DEFNS_FP="${EXPTDIR}/var_defns.sh"
source ${GLOBAL_VAR_DEFNS_FP}
export CDATE=${DATE_FIRST_CYCL}${CYCL_HRS}
export FCST_START=6
export FCST_END=${FCST_LEN_HRS}
export FCST_INC=3

# Usage statement:	Make sure all the necessary modules can be imported.
#                       Seven command line arguments are needed:
#                       1. Cycle date/time in YYYYMMDDHH format
#                       2. Starting forecast hour
#                       3. Ending forecast hour
#                       4. Forecast hour increment
#                       5. EXPT_DIR_1: Experiment 1 directory
#                          -Postprocessed data should be found in the directory:
#                            EXPT_DIR_1/YYYYMMDDHH/postprd/
#                       6. EXPT_DIR_2: Experiment 2 directory
#                          -Postprocessed data should be found in the directory:
#                            EXPT_DIR_2/YYYYMMDDHH/postprd/
#                       7. CARTOPY_DIR:  Base directory of cartopy shapefiles
#                          -File structure should be:
#                            CARTOPY_DIR/shapefiles/natural_earth/cultural/*.shp

python plot_allvars_diff.py ${CDATE} ${FCST_START} ${FCST_END} ${FCST_INC} ${EXPTDIR1} ${EXPTDIR2} ${SHAPE_FILES}
