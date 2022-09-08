#!/bin/sh
#SBATCH -e /path/to/exptdir/log/run_make_grid.log # NEED TO SET
#SBATCH --account=XXXXXXXXX
#SBATCH --qos=batch
#SBATCH --ntasks=48
##SBATCH --ntasks=1 # USE FOR MET VERIFICATION 
#SBATCH --time=20
#SBATCH --job-name="run_make_grid"
cd /path/to/exptdir # NEED TO SET
set -x
. /apps/lmod/lmod/init/sh

module purge
module load hpss

module load intel/18.0.5.274
module load impi/2018.0.4
module load wgrib2
############
# use this netcdf for most of the tasks
module load netcdf/4.7.0
############

############
# use this version for make_sfc_climo, make_ics and make_lbcs
#module load netcdf/4.6.1
############

module load hdf5/1.10.5

############
# use this for the forecast model
#module use -a /scratch1/NCEPDEV/nems/emc.nemspara/soft/modulefiles
#module load hdf5_parallel/1.10.6
#module load netcdf_parallel/4.7.4
#module load esmf/8.0.0_ParallelNetCDF
############


module use -a /contrib/miniconda3/modulefiles
module load miniconda3
conda activate regional_workflow

./run_make_grid.sh
#
#
# Additional modules are needed for MET verification jobs
#
#module use -a /contrib/anaconda/modulefiles
#module load intel/18.0.5.274
#module load anaconda/latest
#module use -a /contrib/met/modulefiles/
#module load met/10.0.0

#./run_pointvx.sh # Run grod-to-point deterministic vx
#./run_gridvx.sh # Run grid-stat deterministic vx
#./run_pointensvx.sh # Run grid-to-point ensemble/probabilsitic vx
#./run_gridensvx.sh # Run grid-to-grid ensemble/probabilsitic vx
