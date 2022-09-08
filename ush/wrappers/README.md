Each workflow task has a wrapper script to set environment variables and run the job script

The experiment-generation step MUST be done FIRST!  generate_FV3SAR_wflow.sh

There is an example batch-submit script for hera (Slurm) and cheyenne (PBS).  These examples set the build and run environment for hera or cheyenne, so that run-time libraries match the compiled libraries (i.e. netcdf, mpi). 

Users may either modify the one batch submit script as each task is submitted, or duplicate this batch wrapper for their system settings, for each task.  Alternatively, some batch systems allow users to specify most of the settings on the command line (with the sbatch or qsub command, for example).  This piece will be unique to your system - use the examples, but expect that you will need to change things!

Tasks with the same Stage level may be run concurrently (no dependency).

```

Stage/step      Task Run Script         #procs                  Wall clock time
                                        (on cheyenne, hera)
 =========       ===============         ======                  ===============
 1               run_get_ics.sh          1                       0:20 - depends on HPSS vs FTP vs staged-on-disk
 1               run_get_lbcs.sh         1                       0:20 - depends on HPSS vs FTP vs staged-on-disk
 1               run_make_grid.sh        24                      0:20
 2               run_make_orog.sh        24                      0:20
 3               run_make_sfc_climo.sh   48                      0:20
 4               run_make_ics.sh         48                      0:30
 4               run_make_lbcs.sh        48                      0:30
 5               run_fcst.sh             48                      2:30
 6               run_post.sh             48                      0:25 - 2min per output forecast hour

```

QuickStart:
1. clone, and build the ufs-srweather-app: https://github.com/ufs-community/ufs-srweather-app/wiki/Getting-Started
2. Generate an experiment configuration: https://github.com/ufs-community/ufs-srweather-app/wiki/Getting-Started
3. CD to the experiment directory
4. SET the environment variable EXPTDIR:  setenv EXPTDIR `pwd` //or// export EXPTDIR=`pwd`
5. COPY the wrapper scripts from the workflow directory:  cp ufs-srweather-app/regional-workflow/ush/wrappers/* .
6. Run each of the listed scripts, in the order given.  Scripts with the same stage-# may be run simultaneously.
 - On most HPC systems, you will need to submit a batch job to run the multi-processor jobs
 - On some HPC systems, you can run the first two jobs (serial) on a login node/command-line
 - Example scripts for Slurm (hera) and for PBS (cheyenne) are provided.  These will need to be adapted to your system
 - This batch-submit script is hard-coded per task, so will need to be modified or copied to run each task

 
