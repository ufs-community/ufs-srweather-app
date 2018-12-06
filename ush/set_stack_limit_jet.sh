#!/bin/sh -l

#
# Set the stack limit as high as possible.
#
if [[ $( ulimit -s ) != unlimited ]] ; then
  for try_limit in 20000 18000 12000 9000 6000 3000 1500 1000 800 ; do
    if [[ ! ( $( ulimit -s ) -gt $(( try_limit * 1000 )) ) ]] ; then
      ulimit -s $(( try_limit * 1000 ))
    else
      break
    fi
  done
fi

