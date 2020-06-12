# UFS Short-Range Weather Application

The UFS Short-Range Weather Application (UFS SR Wx App) provides an end-to-end system to run
pre-processing tasks, the regional UFS Weather Model, and the Unified Post Processor (UPP). 

For the most up-to-date instructions on how to clone the repository, build the code, and run the workflow, see:

https://github.com/ufs-community/ufs-srweather-app/wiki

## 1. Check out the code:

```
   git clone https://github.com/ufs-community/ufs-srweather-app.git
   cd ufs-srweather-app
```

**Note:  On Jet and Hera miniconda3 CAN NOT be loaded for running manage_externals or building the executables in Step 2.  On Hera and Jet, unload this module:**

```
   module unload miniconda3
```

On cheyenne, use ``deactivate`` to remove NPL (NCAR Package Library) from your environment.

```
   ./manage_externals/checkout_externals
```

## 2. Build the executables:

```
   cd ufs-srweather-app/src
```

Run the build script:

```
   ./build_all.sh >& build.out &
```

If this step is successful, there should be fourteen executables in ``ufs-srweather-app/exec`` and an executable for the model ``ufs-srweather-app/src/ufs_weather_model/tests/fv3.exe``.

## 3. Generate the workflow experiment:

```
   cd ufs-srweather-app/regional_workflow/ush
   cp config.community.sh config.sh
```
  
Edit ``config.sh`` to use an account you can charge to ``ACCOUNT``, and the name of the experiment ``EXPT_SUBDIR``.  For Cheyenne, the following parameters should be set:

```
MACHINE="cheyenne"
QUEUE_DEFAULT="regular"
QUEUE_HPSS="regular"
QUEUE_FCST="regular"
DATE_FIRST_CYCL="20190901"
DATE_LAST_CYCL="20190901"
CYCL_HRS=( "18" )
```
and the following should be added to your path on Cheyenne:

```
PATH=$PATH:/glade/p/ral/jntp/tools/rocoto/rocoto-1.3.1/bin:/glade/p/ral/jntp/GMTB/tools/NCEPLIBS-ufs-v1.0.0/intel-19.0.5/mpt-2.19/bin
```
Load the appropriate python environment for the workflow.  The workflow requires python 3, with the packages 'PyYAML', 'Jinja2', and 'f90nml' available. On Jet, Hera, and Cheyenne, this python environment has already been set up, and can be activated in the following way on Jet and Hera:

```
   module use -a /contrib/miniconda3/modulefiles
   module load miniconda3
   conda activate regional_workflow
```

On Cheyenne:

```
   module load ncarenv
   ncar_pylib /glade/p/ral/jntp/UFS_CAM/ncar_pylib_20200427
```
Then generate the workflow:
   
```
   ./generate_FV3SAR_wflow.sh
```

## 4. Run the workflow:

```
   cd ufs-srweather-app/../expt_dirs/$EXPT_SUBDIR
   rocotorun -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
   rocotostat -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
```

For automatic resubmission of the workflow (every 3 minutes), the following line can be added to the user's crontab (use "crontab -e" to edit the cron table):

```
   */3 * * * * cd /glade/p/ral/jntp/$USER/expt_dirs/test_community && /glade/p/ral/jntp/tools/rocoto/rocoto-1.3.1/bin/rocotorun -w FV3SAR_wflow.xml -d FV3SAR_wflow.db -v 10
```
