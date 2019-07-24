.. _running_fv3sar_workflow:

****************************
Running the FV3SAR Workflow
****************************
The steps described in this section assume the config.sh file
has been created following the steps outlined in 
section :ref:`config_fv3sar_workflow`.  In this section, the run and
work directories will be created and a script to run the rocoto
workflow will be generated to run the FV3SAR.

1. Create the run and work directories and a rocoto workflow XML
   for your experiment by running ``generate_FV3SAR_wflow.sh`` in
   the ``fv3sar_wflow/ush directory``:

.. code-block:: console

   % cd $BASEDIR/fv3sar_workflow/ush
   % generate_FV3SAR_wflow.sh

This will create a run directory and a work directory, and it will
put the rocoto workflow XML (called ``FV3SAR_wflow.xml``) in the
run directory.  Towards the end of the output that ``generate_FV3SAR_wflow.sh``
generates, you'll find the locations of the run and work directories
(``RUNDIR=...`` and ``WORKDIR=...``).  Note that the workflow always
creates the run directory as a subdirectory under ``$BASEDIR/run_dirs``,
and it creates the work directory as a subdirectory under ``$TMPDIR``.

The output from ``generate_FV3SAR_wflow.sh`` will contain the commands
you can use to launch the workflow and check on its status (also discussed
in the next step below).  It will also contain the line you need to add
to your crontab (using the command ``"crontab -e"``) in order to continuously
resubmit the workflow to the queue.

2. Regardless of whether or not you added an entry to your crontab for automatic
   resubmission, you can go to the run directory and launch the rocoto workflow
   as follows (assuming you've already loaded rocoto using ``"module load rocoto"``):

.. code-block:: console

   % cd $RUNDIR
   % rocotorun -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10

This will launch the first task in the workflow if it's the first time you're
issuing it.  If it's not the first time, it will launch the next task if it
has completed the current one, relaunch the current one if it failed (and
if the number of times you’ve tried to launch the task hasn’t yet exceeded
the maxtries value defined for the task in the workflow XML), or do nothing
if the current one is still running.  After issuing this command, you can 
check on the status of the workflow using:

.. code-block:: console

   % rocotostat -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10

This will generate a table similar to the following:

.. code-block:: console

            CYCLE                TASK                JOBID       STATE     EXIT STATUS  TRIES  DURATION
     ==================================================================================================
     201806040000      make_grid_orog  druby://tfe05:33377  SUBMITTING               -      0       0.0
     201806040000       get_GFS_files                    -           -               -      -         -
     201806040000    make_surf_IC_BC0                    -           -               -      -         -
     201806040000   make_BC1_to_BCend                    -           -               -      -         -
     201806040000               stage                    -           -               -      -         -
     201806040000          run_FV3SAR                    -           -               -      -         -
     201806040000             post_00                    -           -               -      -         -
     201806040000             post_01                    -           -               -      -         -
     201806040000             post_02                    -           -               -      -         -
     201806040000             post_03                    -           -               -      -         -
     201806040000             post_04                    -           -               -      -         -
     201806040000             post_05                    -           -               -      -         -
     201806040000             post_06                    -           -               -      -         -

Note that you first have to issue the ``rocotorun`` command above in order to get
updated results from the ``rocotostat`` command.  Since it's inconvenient to have
to keep issuing the ``rocotorun`` command to keep the workflow moving along
(i.e. in order to launch the next task if the current one has completed, etc),
you can modify your crontab as described at the end of the output from
``generate_FV3SAR_wflow.sh`` in order to automatically relaunch the workflow with
some specified frequency (e.g. every 3 minutes).

If all goes well, the workflow should step through all the tasks and finish.  The
workflow will have completed when the ``rocotostat`` command generates a table in
which the ``STATE`` for all tasks is ``SUCCEEDED``, something like this:

.. code-block:: console

            CYCLE                TASK        JOBID      STATE   EXIT STATUS         TRIES   DURATION
     ===============================================================================================
     201806040000      make_grid_orog    36437677   SUCCEEDED             0             1      262.0
     201806040000       get_GFS_files    36437726   SUCCEEDED             0             1       71.0
     201806040000    make_surf_IC_BC0    36437730   SUCCEEDED             0             1      293.0
     201806040000   make_BC1_to_BCend    36437731   SUCCEEDED             0             1      242.0
     201806040000               stage    36437765   SUCCEEDED             0             1       38.0
     201806040000          run_FV3SAR    36437802   SUCCEEDED             0             1     1653.0
     201806040000             post_00    36438577   SUCCEEDED             0             1      309.0
     201806040000             post_01    36438624   SUCCEEDED             0             1      294.0
     201806040000             post_02    36438696   SUCCEEDED             0             1      319.0
     201806040000             post_03    36438705   SUCCEEDED             0             1      288.0
     201806040000             post_04    36438441   SUCCEEDED             0             2      293.0
     201806040000             post_05    36438808   SUCCEEDED             0             1      313.0
     201806040000             post_06    36438809   SUCCEEDED             0             1      304.0

If a job fails, you can find the log file for the job under the run directory
in ``$RUNDIR/log``.  Each job will have its own log.  This directory will also
have the overall log file for the workflow called ``FV3_$CDATE.log``, where
``CDATE`` is the starting date of the forecast that you set in ``config.sh``.

================================
Comparing run output to baseline
================================

.. warning::
   The this section is specific to the NOAA HPC machine theia.

Baseline runs have been created for both the RAP and HRRR domains.  The run
directories for these are at the following locations:

RAP:
``/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_baseline_runs/run_dirs/C384_S0p63_RR3_RAP``

HRRR:
``/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_baseline_runs/run_dirs/C384_S1p65_RR5_HRRR``

These baselines have been generated using code from the specific commits of the
``NEMSfv3gfs`` repo and its submodules (``FV3``, ``FMS``, and ``NEMS``) mentioned
above (i.e. the ones for which all tasks in the workflows for both the RAP and
HRRR domains complete successfully).  Thus, your runs should match these baselines
(assuming you passed the argument ``"hash"`` to the checkout script ``checkout_NEMSfv3gfs.sh``
described above).  As described next, you can use the script ``cmp_rundirs_ncfiles.sh``
to compare your runs to the baselines.

The script ``cmp_rundirs_ncfiles.sh`` in the ``ush`` directory compares the NetCDF
files in two specified run directories and their ``INPUT`` subdirectories.  Run it as follows:

.. code-block:: console

   % cd $BASEDIR/fv3sar_workflow/ush
   % ./cmp_rundirs_ncfiles.sh "$rundir1" "$rundir2"

Here, ``rundir1`` and ``rundir2`` are the two run directories you want to compare.
Thus, for example, to compare your RAP run to the baseline, you would use your run
directory for ``rundir1`` and the baseline RAP directory listed above for ``rundir2``
(or vice versa).

Below is sample output from running the ``cmp_rundirs_ncfiles.sh`` script to compare
a RAP run to the baseline.  You can see that all NetCDF files in the INPUT subdirectory
and the main run directory are identical to their counterparts in the baseline except
for the file ``C384_mosaic.nc``.  This is normal because this file contains variables
that contain the full paths to grid files in the run or work directories, and those
full paths will be different because the two run or work directories are different.

.. code-block:: console

   % ./cmp_rundirs_ncfiles.sh /scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test /scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_baseline_runs/run_dirs/C384_S0p63_RR3_RAP

   rundir1 = "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test"
   rundir2 = "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_baseline_runs/run_dirs/C384_S0p63_RR3_RAP"

   Comparing files in subdirectory "INPUT" ...
   ===========================================

   Comparing file "C384_grid.tile7.halo3.nc" in subdirectory "INPUT" ...
   Files are identical.

   Comparing file "C384_grid.tile7.halo4.nc" in subdirectory "INPUT" ...
   Files are identical.

   File "C384_grid.tile7.nc" in "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test/INPUT" is a symbolic link.  Skipping.

   Comparing file "C384_mosaic.nc" in subdirectory "INPUT" ...
   DIFFER : VARIABLE : gridlocation : POSITION : [34] : VALUES : F <> r
   ===>>> FILES ARE DIFFERENT!!!

   Comparing file "C384_oro_data.tile7.halo0.nc" in subdirectory "INPUT" ...
   Files are identical.

   Comparing file "C384_oro_data.tile7.halo4.nc" in subdirectory "INPUT" ...
   Files are identical.

   Comparing file "gfs_bndy.tile7.000.nc" in subdirectory "INPUT" ...
   Files are identical.

   Comparing file "gfs_bndy.tile7.006.nc" in subdirectory "INPUT" ...
   Files are identical.

   Comparing file "gfs_ctrl.nc" in subdirectory "INPUT" ...
   Files are identical.

   File "gfs_data.nc" in "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test/INPUT" is a symbolic link.  Skipping.

   Comparing file "gfs_data.tile7.nc" in subdirectory "INPUT" ...
   Files are identical.

   File "grid_spec.nc" in "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test/INPUT" is a symbolic link.  Skipping.

   File "grid.tile7.halo4.nc" in "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test/INPUT" is a symbolic link.  Skipping.

   File "oro_data.nc" in "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test/INPUT" is a symbolic link.  Skipping.

   File "oro_data.tile7.halo4.nc" in "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test/INPUT" is a symbolic link.  Skipping.

   File "sfc_data.nc" in "/scratch3/BMC/fim/Gerard.Ketefian/FV3SAR_test_gsk/run_dirs/C384_S0p63_RR3_RAP_my_test/INPUT" is a symbolic link.  Skipping.


   Comparing file "sfc_data.tile7.nc" in subdirectory "INPUT" ...
   Files are identical.

   Comparing files in subdirectory "." ...
   =======================================

   Comparing file "atmos_static.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "dynf000.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "dynf001.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "dynf002.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "dynf003.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "dynf004.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "dynf005.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "dynf006.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "grid_spec.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "phyf000.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "phyf001.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "phyf002.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "phyf003.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "phyf004.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "phyf005.nc" in subdirectory "." ...
   Files are identical.

   Comparing file "phyf006.nc" in subdirectory "." ...
   Files are identical.

