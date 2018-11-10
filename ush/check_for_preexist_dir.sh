function check_for_preexist_dir() {

  dir=$1
  preexisting_dir_method=$2
#
# Check if dir already exists.  If so, act depending on the value of 
# preexisting_dir_method.
#
  if [ -d $dir ]; then

    case $preexisting_dir_method in
#
# If preexisting_dir_method is set to "delete", we remove the preexist-
# ing directory in order to be able to create a new one (the creation of
# a new directory is performed in another script).
#
    "delete")
#
      rm -rf $dir
#
      if [ $? -ne 0 ]; then
        echo
        echo "Error from function $0:  Cannot remove existing directory:"
        echo "  dir = $dir"
        echo "Returning with nonzero status."
        return 1
      fi
      ;;
#
# If preexisting_dir_method is set to "rename", we move the preexisting
# directory in order to be able to create a new one (the creation of a
# new directory is performed in another script).
#
    "rename")
#
      i=1
      old_indx=$( printf "%03d" "$i" )
      old_dir=${dir}_old${old_indx}
      while [ -d ${old_dir} ]; do
        i=$[$i+1]
        old_indx=$( printf "%03d" "$i" )
        old_dir=${dir}_old${old_indx}
      done
#
      echo
      echo "Directory already exists:"
      echo "  dir = \"$dir\""
      echo "Moving (renaming) preexisting directory to:"
      echo "  old_dir = \"$old_dir\""
      mv $dir $old_dir
#
      if [ $? -ne 0 ]; then
        echo
        echo "Error from function $0:  Cannot move (rename) existing directory:"
        echo "  dir = $dir"
        echo "  old_dir = $old_dir"
        echo "Returning with nonzero status."
        return 1
      fi
      ;;
#
# If preexisting_dir_method is set to "quit", we simply exit with a non-
# zero status.  Note that "exit" is different than "return" because it
# will cause the calling script (in which this file/function is sourced)
# to stop execution.
#
    "quit")
#
      echo
      echo "Error from function $0:  Directory already exists:"
      echo "  dir = $dir"
      echo "Returning with nonzero status."
      exit 1
      ;;
#
# If preexisting_dir_method is set to a disallowed value, we simply exit
# with a nonzero status.  Note that "exit" is different than "return" 
# because it will cause the calling script (in which this file/function
# is sourced) to stop execution.
#
    *)
#
      echo
      echo "Error from function $0:  Disallowed value for \"preexisting_dir_method\":"
      echo "  preexisting_dir_method = $preexisting_dir_method"
      echo "Allowed values are:  \"delete\"  \"rename\"  \"quit\""
      echo "Exiting with nonzero status."
      exit 1
      ;;
#
    esac
  
  fi

}


