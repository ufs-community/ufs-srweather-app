#!/bin/bash

set -eu

ECF_DIR=$(pwd)

# Function that loop over forecast cycles and
# creates link between the master and target
function link_master_to_cyc_2d(){
  tmpl=$1  # Name of the master template
  cycs=$2  # Array of cycles
  for cyc in ${cycs[@]}; do
    cycchar=$(printf %02d $cyc)
    master=${tmpl}_master.ecf
    target=${tmpl}_${cycchar}.ecf
    rm -f $target
    ln -sf $master $target
  done
}
function link_master_to_cyc_3d(){
  tmpl=$1  # Name of the master template
  cycs=$2  # Array of cycles
  for cyc in ${cycs[@]}; do
    cycchar=$(printf %03d $cyc)
    master=${tmpl}_master.ecf
    target=${tmpl}_f${cycchar}.ecf
    rm -f $target
    ln -sf $master $target
  done
}

# AQM post
cd $ECF_DIR/post
echo "Linking AQM post ..."
cyc=$(seq 0 72)
link_master_to_cyc_3d "jaqm_post" "$cyc"
# AQM nexus_emission
cd $ECF_DIR/nexus
echo "Linking AQM nexus_emission ..."
cyc=$(seq 0 5)
link_master_to_cyc_2d "jaqm_nexus_emission" "$cyc"
