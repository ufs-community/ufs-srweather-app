#!/bin/sh -l

module load nccmp
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
 
    fn1="$fn" 
    if [ -f "$fn1" ] && [ ! -L "$fn1" ]; then  # Check if regular file and not a symlink.

      fn2="$dir2/$subdir/$fn"
      if [ -e "$fn2" ]; then  # Check if file exists.

        if [ -f "$fn2" ] && [ ! -L "$fn2" ]; then  # Check if regular file and not a symlink.
  
          printf "\nComparing file \"$fn\" in subdirectory \"$subdir\" ...\n"
          nccmp -d $fn1 $fn2
#          nccmp -dS $fn1 $fn2
#          nccmp -d -t 1e-3 $fn1 $fn2
#          nccmp -d --precision='%g10.5' $fn1 $fn2
  
          if [ $? = 0 ]; then
            msg=$( printf "%s" "Files are identical." )
          elif [ $? = 1 ]; then
            msg=$( printf "%s" "===>>> FILES ARE DIFFERENT!!!" )
          else
            msg=$( printf "%s" "FATAL ERROR.  Exiting script." )
            exit 1
          fi
    
          printf "%s\n" "$msg"
  
        else
          printf "\n%s\n" "File \"$fn\" in \"$dir2/$subdir\" is a symbolic link.  Skipping."
        fi

      else
        printf "\n%s\n" "File \"$fn\" does not exist in \"$dir2/$subdir\"."
        printf "\n%s\n" "Exiting script."
        exit 1
      fi
        
    else
      printf "\n%s\n" "File \"$fn\" in \"$dir1/$subdir\" is a symbolic link.  Skipping."
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
#set -x

rundir1="$( readlink -f $1 )"
rundir2="$( readlink -f $2 )"

printf "\n"
printf "%s\n" "rundir1 = \"$rundir1\""
printf "%s\n" "rundir2 = \"$rundir2\""

subdirs=("INPUT" ".")

for subdir in "${subdirs[@]}"; do

  msg=$( printf "%s" "Comparing files in subdirectory \"$subdir\" ..." )
  msglen=${#msg}
  printf "\n%s\n" "$msg"
  printf "%0.s=" $(seq 1 $msglen)
  printf "\n"

  cmp_ncfiles_one_dir "$rundir1" "$rundir2" "$subdir" "nc"

done



