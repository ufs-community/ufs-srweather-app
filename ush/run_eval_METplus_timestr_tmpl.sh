#!/usr/bin/env bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
#OBS_DIR="/scratch2/BMC/fv3lam/Gerard.Ketefian/AGILE/expt_dirs/get_obs_hpss.do_vx_det.singlecyc.init_00z_fcstlen_36hr.winter_wx.SRW/obs_data/ccpa"
#OBS_CCPA_APCP_FN_TEMPLATE="{valid?fmt=%Y%m%d}/ccpa.t{valid?fmt=%H}z.01h.hrap.conus.gb2"

#USHdir="/scratch2/BMC/fv3lam/Gerard.Ketefian/AGILE/ufs-srweather-app/ush"
#yyyymmdd_task="20230217"
#lhr="22"
#METplus_timestr_tmpl="/scratch2/BMC/fv3lam/Gerard.Ketefian/AGILE/expt_dirs/get_obs_hpss.do_vx_det.singlecyc.init_00z_fcstlen_36hr.winter_wx.SRW/obs_data/ccpa/{valid?fmt=%Y%m%d}/ccpa.t{valid?fmt=%H}z.01h.hrap.conus.gb2"

#USHdir="/scratch2/BMC/fv3lam/Gerard.Ketefian/AGILE/ufs-srweather-app/ush"; yyyymmdd_task="20230217"; lhr="22"; METplus_timestr_tmpl="/scratch2/BMC/fv3lam/Gerard.Ketefian/AGILE/expt_dirs/get_obs_hpss.do_vx_det.singlecyc.init_00z_fcstlen_36hr.winter_wx.SRW/obs_data/ccpa/{valid?fmt=%Y%m%d}/ccpa.t{valid?fmt=%H}z.01h.hrap.conus.gb2"
set -u
. $USHdir/source_util_funcs.sh
eval_METplus_timestr_tmpl \
  init_time="${yyyymmdd_task}00" \
  fhr="${lhr}" \
  METplus_timestr_tmpl="${METplus_timestr_tmpl}" \
  outvarname_evaluated_timestr="fp_proc"
echo "${fp_proc}"

#  METplus_timestr_tmpl="${OBS_DIR}/${OBS_CCPA_APCP_FN_TEMPLATE}" \
