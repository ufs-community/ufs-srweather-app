#!/bin/sh

# Edit script to modify all config.sh variables based on those defined in the Rocoto workflow

# Copy template config.sh file to ush directory

cp ${templates}/config.sh ${TMPDIR}/config.sh

#Use sed to set all environment variables in config.sh

sed -i -r -e "s/^(\s*machine=)(.*)(#.*)/\1$machine\ \3/" ${TMPDIR}/config.sh 
sed -i -r -e "s?^(\s*BASEDIR=)(.*)(#.*)?\1$BASEDIR\ \3?" ${TMPDIR}/config.sh
sed -i -r -e "s?^(\s*TMPDIR=)(.*)(#.*)?\1$TMPDIR\ \3?" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*fcst_len_hrs=)(.*)(#.*)/\1$fcst_len_hrs\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*BC_interval_hrs=)(.*)(#.*)/\1$BC_interval_hrs\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*gtype=)(.*)(#.*)/\1$gtype\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*RES=)(.*)(#.*)/\1$RES\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*stretch_fac=)(.*)(#.*)/\1$stretch_fac\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*lon_tile6_ctr=)(.*)(#.*)/\1$lon_tile6_ctr\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*lat_tile6_ctr=)(.*)(#.*)/\1$lat_tile6_ctr\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*refine_ratio=)(.*)(#.*)/\1$refine_ratio\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*istart_nest_tile6=)(.*)(#.*)/\1$istart_nest_tile6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*iend_nest_tile6=)(.*)(#.*)/\1$iend_nest_tile6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*jstart_nest_tile6=)(.*)(#.*)/\1$jstart_nest_tile6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*jend_nest_tile6=)(.*)(#.*)/\1$jend_nest_tile6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*title=)(.*)(#.*)/\1$title\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*predef_rgnl_domain=)(.*)(#.*)/\1$predef_rgnl_domain\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*layout_x=)(.*)(#.*)/\1$layout_x\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*layout_y=)(.*)(#.*)/\1$layout_y\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*ncores_per_node=)(.*)(#.*)/\1$ncores_per_node\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*quilting=)(.*)(#.*)/\1$quilting\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*print_esmf=)(.*)(#.*)/\1$print_esmf\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*write_groups=)(.*)(#.*)/\1$write_groups\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*write_tasks_per_group=)(.*)(#.*)/\1$write_tasks_per_group\ \3/" ${TMPDIR}/config.sh
