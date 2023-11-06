./manage_externals/checkout_externals

cd ..

module reset 

source versions/build.ver

module use $(realpath modulefiles)

module list

cd sorc

./devbuild.sh -p=wcoss2 -a=ATMAQ  |& tee buildup.log
