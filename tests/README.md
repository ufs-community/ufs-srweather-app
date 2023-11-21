# Test directory for the UFS Short-Range Weather Application

## Build tests

### Description

The build.sh script builds the executables for the UFS Short-Range Weather Application (SRW App)
for the current code in the users ufs-srweather-app directory.  It consists of the following steps:

* Build all of the executables for the supported compilers on the given machine

* Check for the existence of all executables

* Print out a PASS/FAIL message

Currently, the following configurations are supported:

Machine     | Derecho | Cheyenne    | Hera   | Jet    | Orion  | wcoss2  |
------------|---------|-------------|--------|--------|--------|---------|
Compiler(s) | Intel   | Intel, GNU  | Intel  | Intel  | Intel  | Intel   |

The CMake build is done in the ``build_${compiler}`` directory.
The executables for each build are installed under the ``bin_${compiler}`` directory.

NOTE:  To run the regional workflow using these executables, the ``EXECDIR`` variable in the
``${HOMEdir}/ush/setup.py`` file must be set to the
appropiate directory, for example:  ``EXECDIR="${HOMEdir}/bin_intel/bin"``,
where ``${HOMEdir}`` is the top-level directory of the cloned ufs-srweather-app repository.

### Usage

To run the tests, specify the machine name on the command line, for example:

On cheyenne:

```
cd tests
./build.sh cheyenne >& build.out &
```

Check the ``${HOMEdir}/tests/build_test$PID.out`` file for PASS/FAIL.

## Unit tests

The unit tests in the test_python/ directory test various parts of the workflow written in Python

### Set PYTHONPATH

First, you will need to set the PYTHONPATH environment variable to include the ush/ directory and
a few of the workflow-tools subdirectories. From the top level of the ufs-srweather-app clone
run the following command:

```
export PYTHONPATH=$(pwd)/ush:$(pwd)/ush/python_utils/workflow-tools:$(pwd)/ush/python_utils/workflow-tools/src
```

### Set up HPSS tests

Second, you will need to set up your environment for the HPSS tests, depending on your platform. If
on Jet or Hera, you should load the hpss module, so that the HPSS tests can load data from HPSS:

```
module load hpss
```

If on another platform without HPSS access, disable the HPSS tests by setting the following
variable:

```
export CI=true
```

### Run unit tests

After those prep steps, you can run the unit tests with the following command (from the top-level
UFS SRW directory):

```
python3 -m unittest -b tests/test_python/*.py
```
