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
export FCST_INC=6

# Usage statement:	Make sure all the necessary modules can be imported.
#                       Six command line arguments are needed:
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

python plot_allvars.py ${CDATE} ${FCST_START} ${FCST_END} ${FCST_INC} ${EXPTDIR} ${SHAPE_FILES}
