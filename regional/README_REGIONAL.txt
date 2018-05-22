This file accompanies the guidlines in google document,
https://docs.google.com/document/d/1KkL3mHnDGKHwjpBV98QLYRWtxGKEUWuqy5cy5udZct0/edit#heading=h.9vqatrumwnqq

How to build, configure and run regional FV3
--------------------------------------------

Let "TOP_DIR" be the Home of the "fvsgfs" checkout.

1) Building preprocessing and model code

  $> cd ${TOP_DIR}/regional
  $> ./build_regional

2) There are THREE steps to run a regional FV3 simulation. A job template
   is provided for each step in ${TOP_DIR}/regional/templates.

  2-1. Run the Grid driver to prepare simulation domain and process static
       field including orography etc. (see run_grid_C96.job).

  2-2. Generate initial input data and boundary data files using chgres
       (see script run_chgres_C96.sh).

  2-3. Run the regional FV3 forecast (see script run_fv3.sh).

The first step 2-1 is only required to run once for each grid. You should
modify the job script (run_grid_C96.job) base on your settings and then submit
it using either "qsub" or "sbatch" based on the platform you are running.

The second (2-2) and third (2-3) steps should be run in sequence for each
new case. Script "run_fv3.sh" will handle it automatically.

In "run_fv3.sh" and "run_chgres.sh", users should specify

  o the event date/time (eventdate),
  o the working directory (WORKDIR, or WRK_DIR),
  o the FV3GFS directory (FV3DIR, or TOP_DIR).
  o the directory for FV3 static datasets ("FIXDIR", or FIX_DIR)

In all job scripts in regional/templates (*.job), users should modify the
job card at the very begining of each file for their specific platform.

