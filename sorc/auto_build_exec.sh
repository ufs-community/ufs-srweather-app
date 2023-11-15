
#./app_build.sh -p=wcoss2 --clean

#./app_build.sh -p=wcoss2 -a=ATMAQ --build-type=DEBUG

./app_build.sh -p=wcoss2 -a=ATMAQ  --extrn |& tee buildup.log
