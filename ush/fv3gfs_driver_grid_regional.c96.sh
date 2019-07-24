#!/bin/sh
#
# ----IMPORTANT INFORMATION FOR RUNNING THIS SCRIPT----
# On Theia all other batch commands must be commented out.
#
#----WCOSS DELL JOBCARD
#BSUB /bin/sh
#BSUB -P FV3GFS-T2O
#BSUB -n 1
#BSUB -R span[ptile=1]
#BSUB -o log.grid.regional_C96.%J
#BSUB -e log.grid.regional_C96.%J
#BSUB -J grid_fv3
#BSUB -q debug
#BSUB -W 00:30
#----WCOSS_CRAY JOBCARD
##BSUB -L /bin/sh
##BSUB -P FV3GFS-T2O
##BSUB -oo log.grid.%J
##BSUB -eo log.grid.%J
##BSUB -J grid_fv3
##BSUB -q debug
##BSUB -M 2400
##BSUB -W 00:30
##BSUB -extsched 'CRAYLINUX[]'
#
#----THEIA SLURM JOBCARD
#SBATCH -N 1 --ntasks-per-node=24
#SBATCH -t 0:30:00
#SBATCH -A fv3-cam
#SBATCH -J fv3_grid_driver
#SBATCH -q debug
#SBATCH -o log.grid.regional_C96.%j
#SBATCH -e log.grid.regional_C96.%j
#SBATCH --exclusive
#SBATCH -D.
set -ax

machine=DELL
export machine=${machine:-WCOSS_C}

ulimit -a
ulimit -s unlimited

#-----------------------------
# Makes FV3 cubed-sphere grid
#-----------------------------

#----------------------------------------------------------------

export USER=$LOGNAME 
export res=96	 	   # resolution of tile: 48, 96, 192, 384, 96, 1152, 3072
#
# Even though the name of this script suggests creating the grid and orography
# for a regional run, it can be used for any gype below. If the gtype is nest
# then for running on the Dell,change #BSUB -n 1 to #BSUB -n 4. This allows the
# generation of the orography for the nest to run multiple copies at the same 
# time
#
export gtype=regional      # grid type: uniform, stretch, nest or regional

#----------------------------------------------------------------
# The orography code runs with threads.  On Cray, the code is
# optimized for six threads.  Do not change.
#----------------------------------------------------------------

export OMP_STACKSIZE=2048m

if [ $machine = WCOSS_C ]; then
 set +x
 . $MODULESHOME/init/sh
 module load PrgEnv-intel cfp-intel-sandybridge/1.1.0
 module list
 set -x
 export NODES=1
 export APRUN="aprun -n 1 -N 1 -j 1 -d 1 -cc depth"
 export KMP_AFFINITY=disabled
 export home_dir=$LS_SUBCWD/..
 export topo=/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/fv3gfs/fix/fix_orog
 export TMPDIR=/gpfs/hps3/ptmp/$LOGNAME/fv3_grid.$gtype
elif [ $machine = DELL ]; then
 set +x
 . /usrx/local/prod/lmod/lmod/init/sh
 module load EnvVars/1.0.2 settarg/7.7 lsf/10.1 prod_envir/1.0.2 mktgs/1.0
 module use -a /usrx/local/dev/modulefiles
 module load git/2.14.3
 module load ips/18.0.1.163
 module load impi/18.0.1
 module load NetCDF/4.5.0
 module load HDF5-serial/1.10.1
 module load CFP/2.0.1
 module list
 set -x
 export KMP_AFFINITY=disabled
 export home_dir=$LS_SUBCWD/..
 export topo=/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/fv3gfs/fix/fix_orog
 export TMPDIR=/gpfs/dell3/ptmp/$LOGNAME/fv3_grid.$gtype
 export APRUN=time
elif [ $machine = THEIA ]; then
 . /apps/lmod/lmod/init/sh
 set +x
 module purge
 module load intel/16.1.150
 module load impi
 module load hdf5/1.8.14
 module load netcdf/4.3.0
 module list
 export APRUN=time
 export home_dir=$PBS_O_WORKDIR/..
 export home_dir=$SLURM_SUBMIT_DIR/..
 export topo=/scratch4/NCEPDEV/global/save/glopara/git/fv3gfs/fix/fix_orog
 export TMPDIR=/scratch3/NCEPDEV/stmp1/$LOGNAME/fv3_grid.$gtype
 set -x
fi
#----------------------------------------------------------------

export OMP_NUM_THREADS=6
export script_dir=$home_dir/ush
export exec_dir=$home_dir/exec
export out_dir=$home_dir/fix/fix_fv3/C${res}

#
#remove TMPDIR to make sure no files remain from previous runs
#
if [ -d $TMPDIR ]; then rm -rf $TMPDIR; fi
mkdir -p $out_dir $TMPDIR
cd $TMPDIR ||exit 8

#----------------------------------------------------------------
if [ $gtype = uniform ];  then
  echo "creating uniform ICs"
elif [ $gtype = stretch ]; then
  export stetch_fac=1.5   # Stretching factor for the grid
  export target_lon=-97.5 # center longitude of the highest resolution tile
  export target_lat=35.5  # center latitude of the highest resolution tile
  export title=c96s		  # identifier based on refined location
  echo "creating stretched grid"
elif [ $gtype = nest ] || [ $gtype = regional ]; then
  export stetch_fac=1.5          # Stretching factor for the grid
  export stretch_fac=1.5          # Stretching factor for the grid
  export target_lon=-97.5        # center longitude of the highest resolution tile
  export target_lat=35.5         # center latitude of the highest resolution tile
  export refine_ratio=3          # Specify the refinement ratio for nest grid
  export istart_nest=27          # Specify the starting i-direction index of nest grid in parent tile supergrid(Fortran index)
  export jstart_nest=37          # Specify the starting j-direction index of nest grid in parent tile supergrid(Fortran index)
  export iend_nest=166           # Specify the ending i-direction index of nest grid in parent tile supergrid(Fortran index)
  export jend_nest=164           # Specify the ending j-direction index of nest grid in parent tile supergrid(Fortran index)
  export halo=3                  # halo size to be used in the atmosphere cubic sphere model for the grid tile.
  export halop1=4                # halo size that will be used for the orography and grid tile in chgres
  export halo0=0                 # no halo, used to shave the filtered orography for use in the model
  export title=c96r              # identifier based on nest location
  if [ $gtype = nest ];then
   echo "creating nested grid"
  else
   echo "creating regional grid"
  fi
else
  echo "Error: please specify grid type with 'gtype' as uniform, stretch, nest or regional"
fi

#----------------------------------------------------------------
#filter_topo parameters. C192->50km, C384->25km, C96->13km, C1152->8.5km, C3072->3.2km
if [ $res -eq 48 ]; then 
 export cd4=0.12;  export max_slope=0.12; export n_del2_weak=4;   export peak_fac=1.1  
elif [ $res -eq 96 ]; then 
 export cd4=0.12;  export max_slope=0.12; export n_del2_weak=8;   export peak_fac=1.1  
elif [ $res -eq 192 ]; then 
 export cd4=0.15;  export max_slope=0.12; export n_del2_weak=12;  export peak_fac=1.05  
elif [ $res -eq 384 ]; then 
 export cd4=0.15;  export max_slope=0.12; export n_del2_weak=12;  export peak_fac=1.0  
elif [ $res -eq 768 ]; then 
 export cd4=0.15;  export max_slope=0.12; export n_del2_weak=16;   export peak_fac=1.0  
elif [ $res -eq 1152 ]; then 
 export cd4=0.15;  export max_slope=0.16; export n_del2_weak=20;   export peak_fac=1.0  
elif [ $res -eq 3072 ]; then 
 export cd4=0.15;  export max_slope=0.30; export n_del2_weak=24;   export peak_fac=1.0  
else
 echo "grid C$res not supported, exit"
 exit
fi

#----------------------------------------------------------------
# Make grid and orography

if [ $gtype = uniform ];  then
  export ntiles=6
  export name=C${res}
  export grid_dir=$TMPDIR/$name/grid
  export orog_dir=$TMPDIR/$name/orog
  export filter_dir=$TMPDIR/$name/filter_topo
  mkdir -p $grid_dir $orog_dir $filter_dir

  echo 
  echo "............ execute fv3gfs_make_grid.sh ................."
  $script_dir/fv3gfs_make_grid.sh $res $grid_dir $script_dir
#
  echo "Begin uniform orography generation at `date`"
#
#on WCOSS and WCOSS_C use cfp to run multiple tiles simulatneously for the orography
#
if [ $machine = WCOSS_C ]; then
#
#create input files for cfp in order to run multiple tiles of the orography simulataneously
#
  export APRUN=time
  echo "$script_dir/fv3gfs_make_orog.sh $res 3 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 6 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 1 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 2 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 4 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 5 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1

  aprun -j 1 -n 4 -N 4 -d 6 -cc depth cfp $TMPDIR/orog.file1
  rm $TMPDIR/orog.file1
elif [ $machine = THEIA ]; then
  for tile in 1 2 3 4 5 6 ; do
    echo
    echo "............ execute fv3gfs_make_orog.sh for tile $tile .................."
    $script_dir/fv3gfs_make_orog.sh $res $tile $grid_dir $orog_dir $script_dir $topo $TMPDIR
  done
fi
  echo "End uniform orography generation at `date`"
#
  echo 
  echo "............ execute fv3gfs_filter_topo.sh .............."
  $script_dir/fv3gfs_filter_topo.sh $res $grid_dir $orog_dir $filter_dir $cd4 $peak_fac $max_slope $n_del2_weak $script_dir $gtype
  echo "Grid and orography files are now prepared for uniform grid"

elif [ $gtype = stretch ]; then
  export ntiles=6
  export rn=$( echo "$stretch_fac * 10" | bc | cut -c1-2 )
  export name=C${res}r${rn}_${title}
  export grid_dir=$TMPDIR/${name}/grid
  export orog_dir=$TMPDIR/$name/orog
  export filter_dir=$TMPDIR/${name}/filter_topo
  mkdir -p $grid_dir $orog_dir $filter_dir

  echo 
  echo "............ execute fv3gfs_make_grid.sh ................."
  $script_dir/fv3gfs_make_grid.sh $res $grid_dir $stretch_fac $target_lon $target_lat $script_dir
#
  echo "Begin stretch orography generation at `date`"
#
#on WCOSS and WCOSS_C use cfp to run multiple tiles simulatneously for the orography
#
if [ $machine = WCOSS_C ]; then
#
#create input files for cfp in order to run multiple tiles of the orography simulataneously
#
  export APRUN=time
  echo "$script_dir/fv3gfs_make_orog.sh $res 1 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 3 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 4 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 5 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 2 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 6 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1

  aprun -j 1 -n 4 -N 4 -d 6 -cc depth cfp $TMPDIR/orog.file1
  rm $TMPDIR/orog.file1
elif [ $machine = THEIA ]; then
  for tile in 1 2 3 4 5 6 ; do
    echo
    echo "............ execute fv3gfs_make_orog.sh for tile $tile .................."
    $script_dir/fv3gfs_make_orog.sh $res $tile $grid_dir $orog_dir $script_dir $topo $TMPDIR
  done
fi
  echo "End stretch orography generation at `date`"
#
  echo 
  echo "............ execute fv3gfs_filter_topo.sh .............."
  $script_dir/fv3gfs_filter_topo.sh $res $grid_dir $orog_dir $filter_dir $cd4 $peak_fac $max_slope $n_del2_weak $script_dir $gtype
  echo "Grid and orography files are now prepared for stretched grid"

elif [ $gtype = nest ]; then
  export ntiles=7
  export rn=$( echo "$stretch_fac * 10" | bc | cut -c1-2 )
  export name=C${res}r${rn}n${refine_ratio}_${title}
  export grid_dir=$TMPDIR/${name}/grid
  export orog_dir=$TMPDIR/$name/orog
  export filter_dir=$orog_dir   # nested grid topography will be filtered online
  mkdir -p $grid_dir $orog_dir $filter_dir

  echo 
  echo "............ execute fv3gfs_make_grid.sh ................."
  $script_dir/fv3gfs_make_grid.sh $res $grid_dir $stretch_fac $target_lon $target_lat $refine_ratio $istart_nest $jstart_nest $iend_nest $jend_nest $halo $script_dir

  echo "Begin stretch nest orography generation at `date`"
#
#on WCOSS and WCOSS_C use cfp to run multiple tiles simulatneously for the orography
#
if [ $machine = WCOSS_C ]; then
#
#create input files for cfp in order to run multiple tiles of the orography simulataneously
#
  export APRUN=time
  echo "$script_dir/fv3gfs_make_orog.sh $res 1 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 3 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 4 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 2 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 5 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 6 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 7 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1

  aprun -j 1 -n 4 -N 4 -d 6 -cc depth cfp $TMPDIR/orog.file1
  rm $TMPDIR/orog.file1
 elif [ $machine = DELL ]; then
  echo "$script_dir/fv3gfs_make_orog.sh $res 1 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 3 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 4 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 2 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 5 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 6 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  echo "$script_dir/fv3gfs_make_orog.sh $res 7 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1
  mpirun cfp $TMPDIR/orog.file1
  rm $TMPDIR/orog.file1
 elif [ $machine = THEIA ]; then
  for tile in 1 2 3 4 5 6 7; do
    echo
    echo "............ execute fv3gfs_make_orog.sh for tile $tile .................."
    $script_dir/fv3gfs_make_orog.sh $res $tile $grid_dir $orog_dir $script_dir $topo $TMPDIR
  done
 fi
  echo "Grid and orography files are now prepared for nested grid"
elif [ $gtype = regional ]; then
#
# we are now creating only 1 tile and it is tile 7
#
export ntiles=1
tile=7
set +x # don't echo all the computation to figure out how many points to add/subtract from start/end nest values
#
# number of parent points
#
nptsx=`expr $iend_nest - $istart_nest + 1`
nptsy=`expr $jend_nest - $jstart_nest + 1`
#
#number of compute grid points
#
npts_cgx=`expr $nptsx  \* $refine_ratio / 2`
npts_cgy=`expr $nptsy  \* $refine_ratio / 2`

#
# figure out how many columns/rows to add in each direction so we have at least 5 halo points
# for make_hgrid and the orography program
#
index=0
add_subtract_value=0
while (test "$index" -le "0")
 do
  add_subtract_value=`expr $add_subtract_value + 1`
  iend_nest_halo=`expr $iend_nest + $add_subtract_value`
  istart_nest_halo=`expr $istart_nest - $add_subtract_value`
  newpoints_i=`expr $iend_nest_halo - $istart_nest_halo + 1`
  newpoints_cg_i=`expr $newpoints_i  \* $refine_ratio / 2`
  diff=`expr $newpoints_cg_i - $npts_cgx`
  if [ $diff -ge 10 ]; then 
   index=`expr $index + 1`
  fi
 done
jend_nest_halo=`expr $jend_nest + $add_subtract_value`
jstart_nest_halo=`expr $jstart_nest - $add_subtract_value`

echo "================================================================================== "
echo "For refine_ratio= $refine_ratio" 
echo " iend_nest= $iend_nest iend_nest_halo= $iend_nest_halo istart_nest= $istart_nest istart_nest_halo= $istart_nest_halo"
echo " jend_nest= $jend_nest jend_nest_halo= $jend_nest_halo jstart_nest= $jstart_nest jstart_nest_halo= $jstart_nest_halo"
echo "================================================================================== "
set -x
#
# we are now creating only 1 tile and it is tile 7
#
  export ntiles=1
  tile=7
  export rn=$( echo "$stretch_fac * 10" | bc | cut -c1-2 )
  export name=C${res}r${rn}n${refine_ratio}_${title}
  export grid_dir=$TMPDIR/${name}/grid
  export orog_dir=$TMPDIR/$name/orog
  export filter_dir=$orog_dir   # nested grid topography will be filtered online
  mkdir -p $grid_dir $orog_dir $filter_dir

  echo
  echo "............ execute fv3gfs_make_grid.sh ................."
  $script_dir/fv3gfs_make_grid.sh $res $grid_dir $stretch_fac $target_lon $target_lat $refine_ratio $istart_nest_halo $jstart_nest_halo $iend_nest_halo $jend_nest_halo $halo $script_dir

  echo "Begin regional orography generation at `date`"
#
#on WCOSS and WCOSS_C use cfp to run multiple tiles simulatneously for the orography
#for now we only have one tile but in the future we will have more
#
if [ $machine = WCOSS_C ]; then
#
#create input files for cfp in order to run multiple tiles of the orography simulataneously
#
  export APRUN=time
  echo "$script_dir/fv3gfs_make_orog.sh $res 7 $grid_dir $orog_dir $script_dir $topo $TMPDIR " >>$TMPDIR/orog.file1

  aprun -j 1 -n 4 -N 4 -d 6 -cc depth cfp $TMPDIR/orog.file1
  rm $TMPDIR/orog.file1
elif [ $machine = DELL ]; then
    echo
    echo "............ execute fv3gfs_make_orog.sh for tile $tile .................."
    $script_dir/fv3gfs_make_orog.sh $res $tile $grid_dir $orog_dir $script_dir $topo $TMPDIR
elif [ $machine = THEIA ]; then
####################### for tile in 1 2 3 4 5 6 7; do
    echo
    echo "............ execute fv3gfs_make_orog.sh for tile $tile .................."
    $script_dir/fv3gfs_make_orog.sh $res $tile $grid_dir $orog_dir $script_dir $topo $TMPDIR
######################  done
fi
  echo
  echo "............ execute fv3gfs_filter_topo.sh .............."
  $script_dir/fv3gfs_filter_topo.sh $res $grid_dir $orog_dir $filter_dir $cd4 $peak_fac $max_slope $n_del2_weak $script_dir $gtype
  echo
  echo "............ execute shave to reduce grid and orography files to required compute size .............."
  cd $filter_dir
#
# shave the orography file and then the grid file, the echo creates the input file that contains the number of required points
# in x and y and the input and output file names.This first run of shave uses a halo of 4. This is necessary so that chgres will create BC's 
# with 4 rows/columns which is necessary for pt.
#
echo $npts_cgx $npts_cgy $halop1 \'$filter_dir/oro.C${res}.tile${tile}.nc\' \'$filter_dir/oro.C${res}.tile${tile}.shave.nc\' >input.shave.orog
echo $npts_cgx $npts_cgy $halop1 \'$filter_dir/C${res}_grid.tile${tile}.nc\' \'$filter_dir/C${res}_grid.tile${tile}.shave.nc\' >input.shave.grid
if [ $machine = WCOSS_C ]; then
  aprun -n 1 -N 1 -j 1 -d 1 -cc depth $exec_dir/shave.x <input.shave.orog
  aprun -n 1 -N 1 -j 1 -d 1 -cc depth $exec_dir/shave.x <input.shave.grid
elif [ $machine = THEIA ] || [ $machine = DELL ]; then
  time $exec_dir/shave.x <input.shave.orog
  time $exec_dir/shave.x <input.shave.grid
fi
#
echo "Grid and orography files are now prepared for regional grid"
fi
#----------------------------------------------------------------
echo 
echo "--------------------------------------------------"

if [ $gtype = regional ]; then
 cp $filter_dir/oro.C${res}.tile${tile}.shave.nc $out_dir/C${res}_oro_data.tile${tile}.halo${halop1}.nc
 cp $filter_dir/C${res}_grid.tile${tile}.shave.nc  $out_dir/C${res}_grid.tile${tile}.halo${halop1}.nc
#
# Now shave the orography file with no halo and then the grid file with a halo of 3. This is necessary for running the model.
#
echo $npts_cgx $npts_cgy $halo0 \'$filter_dir/oro.C${res}.tile${tile}.nc\' \'$filter_dir/oro.C${res}.tile${tile}.shave.nc\' >input.shave.orog.halo$halo0
echo $npts_cgx $npts_cgy $halo \'$filter_dir/C${res}_grid.tile${tile}.nc\' \'$filter_dir/C${res}_grid.tile${tile}.shave.nc\' >input.shave.grid.halo$halo
if [ $machine = WCOSS_C ]; then
  aprun -n 1 -N 1 -j 1 -d 1 -cc depth $exec_dir/shave.x <input.shave.orog.halo$halo0
  aprun -n 1 -N 1 -j 1 -d 1 -cc depth $exec_dir/shave.x <input.shave.grid.halo$halo
elif [ $machine = THEIA ] || [ $machine = DELL ]; then
  time $exec_dir/shave.x <input.shave.orog.halo$halo0
  time $exec_dir/shave.x <input.shave.grid.halo$halo
fi
#
# copy the shaved files with the halo of 3 required for the model run
#
 cp $filter_dir/oro.C${res}.tile${tile}.shave.nc $out_dir/C${res}_oro_data.tile${tile}.halo${halo0}.nc
 cp $filter_dir/C${res}_grid.tile${tile}.shave.nc  $out_dir/C${res}_grid.tile${tile}.halo${halo}.nc
else
tile=1
while [ $tile -le $ntiles ]; do
 cp $filter_dir/oro.C${res}.tile${tile}.nc $out_dir/C${res}_oro_data.tile${tile}.nc
 cp $grid_dir/C${res}_grid.tile${tile}.nc  $out_dir/C${res}_grid.tile${tile}.nc
 tile=`expr $tile + 1 `
done
fi
#cp $filter_dir/C${res}_mosaic.nc $out_dir/grid_spec.nc
#cp $filter_dir/C${res}_mosaic.nc $out_dir/C${res}_mosaic.nc
cp $grid_dir/C${res}_mosaic.nc $out_dir/C${res}_mosaic.nc

exit
