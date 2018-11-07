#!/bin/sh

# Edit script to modify all config.sh variables based on those defined in the Rocoto workflow

# Copy template config.sh file to ush directory

cp ${templates}/config.sh ${TMPDIR}/config.sh

#Use sed to set all environment variables in config.sh

sed -i -r -e "s/^(\s*MACHINE=)(.*)(#.*)/\1$MACHINE\ \3/" ${TMPDIR}/config.sh 
sed -i -r -e "s?^(\s*BASEDIR=)(.*)(#.*)?\1$BASEDIR\ \3?" ${TMPDIR}/config.sh
sed -i -r -e "s?^(\s*TMPDIR=)(.*)(#.*)?\1$TMPDIR\ \3?" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*fcst_len_hrs=)(.*)(#.*)/\1$fcst_len_hrs\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*BC_update_intvl_hrs=)(.*)(#.*)/\1$BC_update_intvl_hrs\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*gtype=)(.*)(#.*)/\1$gtype\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*RES=)(.*)(#.*)/\1$RES\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*stretch_fac=)(.*)(#.*)/\1$stretch_fac\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*lon_ctr_T6=)(.*)(#.*)/\1$lon_ctr_T6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*lat_ctr_T6=)(.*)(#.*)/\1$lat_ctr_T6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*refine_ratio=)(.*)(#.*)/\1$refine_ratio\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*istart_rgnl_T6=)(.*)(#.*)/\1$istart_rgnl_T6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*iend_rgnl_T6=)(.*)(#.*)/\1$iend_rgnl_T6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*jstart_rgnl_T6=)(.*)(#.*)/\1$jstart_rgnl_T6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*jend_rgnl_T6=)(.*)(#.*)/\1$jend_rgnl_T6\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*run_title=)(.*)(#.*)/\1$run_title\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*predef_rgnl_domain=)(.*)(#.*)/\1$predef_rgnl_domain\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*layout_x=)(.*)(#.*)/\1$layout_x\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*layout_y=)(.*)(#.*)/\1$layout_y\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*ncores_per_node=)(.*)(#.*)/\1$ncores_per_node\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*quilting=)(.*)(#.*)/\1$quilting\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*print_esmf=)(.*)(#.*)/\1$print_esmf\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*write_groups=)(.*)(#.*)/\1$write_groups\ \3/" ${TMPDIR}/config.sh
sed -i -r -e "s/^(\s*write_tasks_per_group=)(.*)(#.*)/\1$write_tasks_per_group\ \3/" ${TMPDIR}/config.sh
