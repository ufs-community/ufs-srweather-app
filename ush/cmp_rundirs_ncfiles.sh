#!/bin/sh -l

module load nccmp
#set -x
#
#-----------------------------------------------------------------------
#
# Define generic function to compare NetCDF files in two directories.
#
#-----------------------------------------------------------------------
#
function cmp_ncfiles_one_dir() {

  local dir1="$1"
  local dir2="$2"
  local subdir="$3"
  local fileext="$4"
  
  local fn=""
  local msg=""

  cd $dir1/$subdir

  for fn in *.$fileext; do
  
    if [ -f "$fn" ] && [ ! -h "$fn" ]; then
  
      printf "\nComparing file \"$fn\" in subdirectory \"$subdir\" ...\n"
      nccmp -d $fn $dir2/$subdir/$fn
#      nccmp -dS $fn $dir2/$subdir/$fn
#      nccmp -d -t 1e-3 $fn $dir2/$subdir/$fn
#      nccmp -d --precision='%g' $fn $dir2/$subdir/$fn
  
      if [ $? = 0 ]; then
        msg=$( printf "%s" "Files are identical." )
      elif [ $? = 1 ]; then
        msg=$( printf "%s" "===>>> FILES ARE DIFFERENT!!!" )
      else
        msg=$( printf "%s" "FATAL ERROR.  Exiting script." )
        exit 1
      fi

      printf "%s\n" "$msg"
  
    fi
  
  done

}
#
#-----------------------------------------------------------------------
#
# Get the two run directories to compare from command-line arguments.  
# Then compare NetCDF files in the run directories as well as in their
# INPUT subdirectories.
#
#-----------------------------------------------------------------------
#
rundir1="$1"
rundir2="$2"

printf "\n"
printf "%s\n" "rundir1 = \"$rundir1\""
printf "%s\n" "rundir2 = \"$rundir2\""

subdirs=("." "INPUT")

#set -x

for subdir in "${subdirs[@]}"; do

  msg=$( printf "%s" "Comparing files in subdirectory \"$subdir\" ..." )
  msglen=${#msg}
  printf "\n%s\n" "$msg"
  printf "%0.s=" $(seq 1 $msglen)
  printf "\n"

  cmp_ncfiles_one_dir "$rundir1" "$rundir2" "$subdir" "nc"

done



