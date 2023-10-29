./manage_externals/checkout_externals

module purge

source versions/build.ver

module use $(realpath modulefiles)

module list

./devbuild.sh -p=wcoss2 -a=ATMAQ  |& tee buildup.log
