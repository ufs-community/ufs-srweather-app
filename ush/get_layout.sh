#!/bin/bash -f
###########################################################
# get layout for given nx and ny
# INPUT: nx, ny, number of cpu to be used (optional).
# Output: suggested nx, ny, layout_x, layout_y
# email to: Linlin.Pan@noaa.gov for any questions.
#
###########################################################
if [ "$#" -lt 2 ]; then
    echo "You must enter number of grid points in x and y directions"
    exit
else
   nx=$1
   ny=$2
   echo "nx= $nx, ny= $ny"
fi

if [ "$#" -eq 3 ]; then
   nlayout=$3
   echo "ncups= $nlayout"
   layout_x=$(echo "sqrt($nlayout*$nx/$ny)" |bc )
   if [ $layout_x -gt $nx ]; then
      $layout_x=$nx
   fi
# using even number
   if [ $((layout_x%2)) -gt 0 ] ; then
     if [ $nx -gt $ny ] ; then
      layout_x=$((layout_x+1))
     else
      layout_x=$((layout_x-1))
     fi
   fi
   if [ $layout_x -eq 0 ] ; then 
      layout_x=2
   fi
   if [ $layout_x -gt 24 ]; then
      layout_x=24
   fi
# get layout_y
   layout_y=$((nlayout/layout_x))
   if [ $((layout_y%2)) -gt 0 ] ; then
    layout_y=$((layout_y+1)) 
   fi
   if [ $layout_y -gt 24 ] && [ $layout_x -ne 24 ] ; then
      layout_y=24
      layout_x=$((nlayout/layout_y))
      if [ $((layout_x%2)) -gt 0 ] ; then
       layout_x=$((layout_x+1)) 
      fi
   fi
   if [ $nx -gt $ny ] && [ $layout_x -lt $layout_y ] ; then
      temp=$layout_x
      layout_x=$layout_y
      layout_y=$temp
   fi
# get nx, ny
   if [ $((nx%layout_x)) -gt 0 ] ; then
    nx=$((nx/layout_x*layout_x+layout_x))
   else
    nx=$((nx/layout_x*layout_x))
   fi
   if [ $((ny%layout_y)) -gt 0 ] ; then
     ny=$((ny/layout_y*layout_y+layout_y))
   else
     ny=$((ny/layout_y*layout_y))
   fi
   echo "suggested layout_x= $layout_x, layout_y $layout_y, and total = $((layout_x*layout_y))"
   echo "suggested nx= $nx, ny= $ny"
   exit
fi

nxy=$((nx * ny))

if [ $nxy -le 22000 ]; then # 22000 is from predefined HRRR 25km domain 
   layout_x=2
   layout_y=2
   nx=$((nx+nx%2))
   ny=$((ny+ny%2))

elif [ $nxy -gt 22000 ] && [ $nxy -le 81900 ]; then #81900 is obtained from predefined HRRR 13km domain
   nlayout=$(((4+96*nxy/81900)))
   layout_x=$(echo "sqrt($nlayout)" |bc )
   if [ $layout_x -gt $nx ]; then
      $layout_x=$nx
   fi
   if [ $((layout_x%2)) -gt 0 ] ; then
     if [ $nx -gt $ny ] ; then
      layout_x=$((layout_x+1))
     else
      layout_x=$((layout_x-1))
     fi
   fi
   layout_y=$((nlayout/layout_x))
   if [ $((layout_y%2)) -gt 0 ] ; then
    layout_y=$((layout_y+1)) 
   fi
   if [ $((nx%layout_x)) -gt 0 ] ; then
    nx=$((nx/layout_x*layout_x+layout_x))
   else
    nx=$((nx/layout_x*layout_x))
   fi
   if [ $((ny%layout_y)) -gt 0 ] ; then
     ny=$((ny/layout_y*layout_y+layout_y))
   else
     ny=$((ny/layout_y*layout_y))
   fi

elif [ $nxy -gt 81900 ]; then
   nlayout=$(((100+716*nxy/1747872)))  # 1747872 is obtained from predefined HRRR 3km domain.
   layout_x=$(echo "sqrt($nlayout)" |bc )
   if [ $layout_x -gt $nx ]; then
      $layout_x=$nx
   fi
   if [ $layout_x -gt 24 ] ; then
      layout_x=24
      layout_y=$((nlayout/layout_x))
      layout_y=$((layout_y+layout_y%2))
      if [ $nx -gt $ny ] && [ $layout_x -lt $layout_y ]; then
         layout_x=$layout_y
         layout_y=24
      fi
   else
      layout_y=$((nlayout/layout_x))
      layout_y=$((layout_y+layout_y%2))
      if [ $nx -gt $ny ] && [ $layout_x -lt $layout_y ]; then
	 temp=$layout_x
         layout_x=$layout_y
         layout_y=$temp
      fi
   fi
   if [ $((nx%layout_x)) -gt 0 ] ; then
    nx=$((nx/layout_x*layout_x+layout_x))
   else
    nx=$((nx/layout_x*layout_x))
   fi
   if [ $((ny%layout_y)) -gt 0 ] ; then
     ny=$((ny/layout_y*layout_y+layout_y))
   else
     ny=$((ny/layout_y*layout_y))
   fi
else
  echo "Error: nxy=  $nxy "
  exit
fi

echo "suggested layout_x= $layout_x, layout_y=$layout_y, total= $((layout_x*layout_y))"
echo "suggested nx= $nx, ny= $ny"
