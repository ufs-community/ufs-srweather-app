function check_for_preexist_dir {

  dir=$1
  preexisting_dir_method=$2

  if [ -d $dir ]; then

    case $preexisting_dir_method in
#
    "overwrite")
      rm -rf $dir
      ;;
#
    "rename")
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
      echo
      echo "  dir = \"$dir\""
      echo
      echo "Moving (renaming) preexisting directory to:"
      echo
      echo "  old_dir = \"$old_dir\""
      echo
      mv $dir $old_dir
      ;;
#
    "quit")
      echo
      echo "Error from function $0:  Directory already exists:"
      echo "  dir = $dir"
      echo "Exiting function with nonzero status."
      exit 1
      ;;
#
    *)
      echo
      echo "Error from function $0:  Disallowed value for \"preexisting_dir_method\":"
      echo "  preexisting_dir_method = $preexisting_dir_method"
      echo "Allowed values are:  \"overwrite\"  \"rename\"  \"quit\""
      echo "Exiting function with nonzero status."
      exit 1
      ;;
#
    esac
  
  fi

}


