#./app_build.sh -p=wcoss2 --clean

./app_build.sh -p=wcoss2 -a=ATMAQ  --extrn |& tee buildup.log

#./app_build.sh -p=wcoss2 -a=ATMAQ --build-type=DEBUG |& tee build_debug.log
