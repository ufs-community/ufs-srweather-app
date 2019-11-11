# Regional workflow

This is the community\_develop branch of the regional\_workflow used to run the stand-alone regional (SAR) version of FV3.

## Check out and build the regional workflow:

1. Check out the regional workflow external components:

`./manage_externals/checkout_externals`

This step will checkout EMC\_post, NEMSfv3gfs and its submodules, UFS\_UTILS\_chgres\_grib2 and UFS\_UTILS\_develop in the sorc directory.

2. Build the utilities, post and FV3:
```
cd sorc
./build_all.sh
```
This step will also copy the executables to the `exec` directory and link the fix files.
4. Create a `config.sh` file in the `ush` directory (see Users Guide).
5. Generate a workflow:
```
cd ush
generate_FV3SAR_wflow.sh
```
This will create an experiment directory in `$EXPT_SUBDIR` with a rocoto xml file FV3SAR_wflow.xml. It will also output information specific to your experiment.

6. Launch and monitor the workflow:
```
module load rocoto/1.3.1`
cd $EXPTDIR
rocotorun -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
rocotostat -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
```
7.  For automatic resubmission of the workflow, the following can be added to your crontab:
```
*/3 * * * * cd $EXPTDIR && rocotorun -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
```
