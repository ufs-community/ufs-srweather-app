#!/bin/sh
#SBATCH -e /scratch1/BMC/gmtb/Laurie.Carson/expt_dirs/test_2/log/run_make_grid.log
#SBATCH --account=gmtb
#SBATCH --qos=batch
#SBATCH --ntasks=48
#SBATCH --time=20
#SBATCH --job-name="run_make_grid"
cd /scratch1/BMC/gmtb/Laurie.Carson/expt_dirs/test_2
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
