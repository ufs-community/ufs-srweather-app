#!/bin/sh
#PBS -A XXXXXXXXX
#PBS -q regular
#PBS -l select=1:mpiprocs=24:ncpus=24
##PBS -l select=1:mpiprocs=1:ncpus=1 # USE FOR MET VERIFICATION
#PBS -l walltime=02:30:00
#PBS -N run_make_grid
#PBS -j oe -o /path/to/exptdir/log/run_make_grid.log # NEED TO SET
cd /path/to/exptdir # NEED TO SET
set -x
#
source /etc/profile.d/modules.sh
module load ncarenv/1.3
module load intel/19.0.2
module load mpt/2.19
module load ncarcompilers/0.5.0
module load netcdf/4.6.3

module use -a /glade/p/ral/jntp/GMTB/tools/modulefiles/intel-19.0.2/mpt-2.19
module load esmf/8.0.0
#
# Different modules are needed for the UFS_UTILS/mpi jobs... why are they using impi anyway???
## make_sfc_climo make_ics make_lbcs
#
##module load ncarenv/1.3
##module load intel/19.0.2
##module load ncarcompilers/0.5.0
##module load impi/2019.2.187
##module load netcdf/4.6.3
#
##module use -a /glade/p/ral/jntp/GMTB/tools/modulefiles/intel-19.0.2/impi-2019.2.187
##module load esmf/8.0.0_bs50
#
./run_make_grid.sh
#
#
# Additional modules are needed for MET verification jobs
#
#module use /glade/p/ral/jntp/MET/MET_releases/modulefiles
#module load met/10.0.0
#module load conda/latest
#conda activate /glade/p/ral/jntp/UFS_SRW_app/conda/python_graphics

#./run_pointvx.sh # Run grod-to-point deterministic vx
#./run_gridvx.sh # Run grid-stat deterministic vx
#./run_pointensvx.sh # Run grid-to-point ensemble/probabilsitic vx
#./rungridensvx.sh # Run grid-to-grid ensemble/probabilsitic vx
