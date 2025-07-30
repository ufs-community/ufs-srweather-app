#!/bin/bash
  
cd ${PYGRAF_DIR}
python3 -u create_graphics.py maps -d ${VX_FCST_INPUT_BASEDIR}/${PDY}${cyc} -f 0 ${FCST_LEN_HRS} --file_type prs --file_tmpl "hrrr.t${cyc}z.wrfprsf{FCST_TIME:02d}.grib2" --images image_lists/hrrr_smoke.yml hourly -m "${CAPTION}" -n $nprocs -o $OUTDIR -s ${PDY}${cyc} -r ${RESOLUTION}

