# Regional workflow

This is the community\_develop branch of the regional\_workflow used to run the stand-alone regional (SAR) version of FV3.

## Check out and build the regional workflow:

1. Check out the regional workflow external components:

`./manage_externals/checkout_externals`

This step will checkout EMC\_post, NEMSfv3gfs and its submodules, UFS\_UTILS\_chgres\_grib2 and UFS\_UTILS\_develop in the sorc directory.

2. Build the utilities, post and FV3:
```
cd sorc
./build_all.sh >& out.build_all &
```
NOTE: You must *not* have the conda module loaded for the build to succeed.

This step will also copy the executables to the `exec` directory and link the fix files.

4. Create a `config.sh` file in the `ush` directory (see Users Guide).

5. Set up your python environment; you will need python3, and it must have the 'PyYAML', 'Jinja2', and 'f90nml' packages installed

On some platforms this environment is already available with a few commands;For example, on Jet/Hera:
```
cd ush
module load contrib miniconda3
conda activate regional_workflow
```
on Cheyenne:
```
cd ush
ncar_pylib /glade/p/ral/jntp/UFS_CAM/ncar_pylib_20200427
```

6. Generate a workflow:
```
generate_FV3SAR_wflow.sh
```
This will create an experiment directory in `$EXPT_SUBDIR` with a rocoto xml file FV3SAR_wflow.xml. It will also output information specific to your experiment.

7. Launch and monitor the workflow:
```
module load rocoto/1.3.1`
cd $EXPTDIR
rocotorun -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
rocotostat -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
```
8.  For automatic resubmission of the workflow, the following can be added to your crontab:
```
*/3 * * * * cd $EXPTDIR && rocotorun -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
```
