# This is the main cmake file for ufs-srweather-app.

cmake_minimum_required(VERSION 3.15)

# Set the project name and version.
project(ufs-srweather-app VERSION 1.0 LANGUAGES C CXX Fortran)

find_package(MPI REQUIRED COMPONENTS C CXX Fortran)

# Set extended version info.
SET(SRWA_VERSION_MAJOR 1)
SET(SRWA_VERSION_MINOR 0)
SET(SRWA_VERSION_PATCH 0)
SET(SRWA_VERSION_NOTE "-development")
SET(SRWA_VERSION ${SRWA_VERSION_MAJOR}.${SRWA_VERSION_MINOR}.${SRWA_VERSION_PATCH}${SRWA_VERSION_NOTE})

# A function used to create autotools-style 'yes/no' definitions.
# If a variable is set, it 'yes' is returned. Otherwise, 'no' is
# returned.
#
# Also creates a version of the ret_val prepended with 'NC',
# when feature is true, which is used to generate ufs_srweather_app_meta.h.
FUNCTION(is_disabled feature ret_val)
  IF(${feature})
    SET(${ret_val} "no" PARENT_SCOPE)
  ELSE()
    SET(${ret_val} "yes" PARENT_SCOPE)
    SET("SRWA_${ret_val}" 1 PARENT_SCOPE)
  ENDIF(${feature})
ENDFUNCTION()

# A function used to create autotools-style 'yes/no' definitions.
# If a variable is set, it 'yes' is returned. Otherwise, 'no' is
# returned.
#
# Also creates a version of the ret_val prepended with 'NC',
# when feature is true, which is used to generate ufs_srweather_app_meta.h.
FUNCTION(is_enabled feature ret_val)
  IF(${feature})
    SET(${ret_val} "yes" PARENT_SCOPE)
    SET("SRWA_${ret_val}" 1 PARENT_SCOPE)
  ELSE()
    SET(${ret_val} "no" PARENT_SCOPE)
    SET("SRWA_${ret_val}" 0 PARENT_SCOPE)
  ENDIF(${feature})
ENDFUNCTION()

# Turn on testing.
enable_testing()
include(CTest)

# Default bin directory
if(NOT DEFINED CMAKE_INSTALL_BINDIR)
    set(CMAKE_INSTALL_BINDIR bin)
endif()

#####
# Configure and print the ufs-srweather-app.settings file.
#####

# Determine the configure date.
IF(DEFINED ENV{SOURCE_DATE_EPOCH})
  EXECUTE_PROCESS(
    COMMAND "date" "-u" "-d" "@$ENV{SOURCE_DATE_EPOCH}"
    OUTPUT_VARIABLE CONFIG_DATE
    )
ELSE()
  EXECUTE_PROCESS(
    COMMAND date
    OUTPUT_VARIABLE CONFIG_DATE
    )
ENDIF()
IF(CONFIG_DATE)
        string(STRIP ${CONFIG_DATE} CONFIG_DATE)
ENDIF()

# Get system configuration, Use it to determine osname, os release, cpu. These
# will be used when committing to CDash.
find_program(UNAME NAMES uname)
IF(UNAME)
  macro(getuname name flag)
    exec_program("${UNAME}" ARGS "${flag}" OUTPUT_VARIABLE "${name}")
  endmacro(getuname)
  getuname(osname -s)
  getuname(osrel  -r)
  getuname(cpu    -m)
ENDIF()

# Set variables.
SET(host_cpu "${cpu}")
SET(host_vendor "${osname}")
SET(host_os "${osrel}")
SET(abs_top_builddir "${CMAKE_CURRENT_BINARY_DIR}")
SET(abs_top_srcdir "${CMAKE_CURRENT_SOURCE_DIR}")

SET(CC_VERSION "${CMAKE_C_COMPILER}")

# Set values for .settings file.
SET(CFLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE}}")
SET(CPPFLAGS "${CMAKE_CPP_FLAGS} ${CMAKE_CPP_FLAGS_${CMAKE_BUILD_TYPE}}")
SET(LDFLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS_${CMAKE_BUILD_TYPE}}")
SET(prefix ${CMAKE_INSTALL_PREFIX})

# Determine output yes/no values.
is_disabled(BUILD_SHARED_LIBS enable_static)
is_enabled(BUILD_SHARED_LIBS enable_shared)
is_enabled(STATUS_PARALLEL HAS_PARALLEL)

# Generate file from template.
CONFIGURE_FILE("${CMAKE_CURRENT_SOURCE_DIR}/ufs_srweather_app.settings.in"
  "${CMAKE_CURRENT_BINARY_DIR}/ufs_srweather_app.settings"
  @ONLY)

# Read in settings file, print out.
# Avoid using system-specific calls so that this
# might also work on Windows.
FILE(READ "${CMAKE_CURRENT_BINARY_DIR}/ufs_srweather_app.settings"
  UFS-SRWEATHER-APP_SETTINGS)
MESSAGE(${UFS-SRWEATHER-APP_SETTINGS})

# Install ufs_srweather_app.settings file into same location
# as the app.
INSTALL(FILES "${CMAKE_BINARY_DIR}/ufs_srweather_app.settings"
  DESTINATION ${CMAKE_INSTALL_BINDIR})

#####
# Create 'ufs_srweather_app_meta.h' include file.
#####
configure_file(
  ufs_srweather_app_meta.h.in
  ufs_srweather_app_meta.h @ONLY)

FILE(COPY "${CMAKE_CURRENT_BINARY_DIR}/ufs_srweather_app_meta.h" DESTINATION include)

add_custom_target(build DEPENDS pbuild)

include(ExternalProject)

# Options
option(BUILD_UFS "Build UFS weather model" ON)
option(BUILD_UFS_UTILS "Build UFS utilities" ON)
option(BUILD_UPP "Build UPP" ON)
option(BUILD_GSI "Build GSI" OFF)
option(BUILD_RRFS_UTILS "Build RRFS utilities" OFF)

message(STATUS "BUILD_UFS ............... ${BUILD_UFS}")
message(STATUS "BUILD_UFS_UTILS ......... ${BUILD_UFS_UTILS}")
message(STATUS "BUILD_UPP ............... ${BUILD_UPP}")
message(STATUS "BUILD_NEXUS ............. ${BUILD_NEXUS}")
message(STATUS "BUILD_AQM_UTILS ......... ${BUILD_AQM_UTILS}")

# Set dependency of ufs weather model only for coupled model
if (NOT APP)
  set(UFS_DEPEND "")
else()
  if (BUILD_UFS)
    set(UFS_DEPEND "ufs-weather-model")
  else()
    set(UFS_DEPEND "")
  endif()
endif()

# Build UFS weather model
if (BUILD_UFS)
  list(APPEND TARGET_LIST ufs-weather-model)

  if(NOT CCPP_SUITES)
    if(CPL_AQM)
      set(CCPP_SUITES "FV3_GFS_v16")
    else()
      set(CCPP_SUITES "FV3_GFS_2017_gfdlmp,FV3_GFS_2017_gfdlmp_regional,FV3_GFS_v15p2,FV3_GFS_v16,FV3_GFS_v17_p8,FV3_RRFS_v1beta,FV3_HRRR,FV3_GFS_v15_thompson_mynn_lam3km,FV3_WoFS_v0")
    endif()
  endif()
  
  if(NOT APP)
    set(APP "ATM")
  endif()
  
  if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "RELEASE")
  endif()
  
  list(APPEND UFS_WEATHER_MODEL_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DCCPP_SUITES=${CCPP_SUITES}"
    "-DCMAKE_C_COMPILER=${MPI_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER=${MPI_CXX_COMPILER}"
    "-DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_MODULE_PATH=${MAPL_ROOT}/share/MAPL/cmake"
    "-DNETCDF_DIR=$ENV{NETCDF}"
    "-D32BIT=ON"
    "-DINLINE_POST=ON"
    "-DAPP=${APP}"
  )
  
  string(TOUPPER "${CMAKE_BUILD_TYPE}" TOUPPER_CMAKE_BUILD_TYPE)
  if (TOUPPER_CMAKE_BUILD_TYPE MATCHES "DEBUG")
    list(APPEND UFS_WEATHER_MODEL_ARGS "-DDEBUG=ON")
  endif()
  
  if (BUILD_OPTIONS)
    string(REPLACE "," ";" BUILD_OPTIONS "${BUILD_OPTIONS}")
    foreach (option_on IN ITEMS ${BUILD_OPTIONS})
      list(APPEND UFS_WEATHER_MODEL_ARGS "-D${option_on}=ON")
    endforeach()
  endif()
  
  if (DISABLE_OPTIONS)
    string(REPLACE "," ";" DISABLE_OPTIONS "${DISABLE_OPTIONS}")
    foreach (option_off IN ITEMS ${DISABLE_OPTIONS})
      list(APPEND UFS_WEATHER_MODEL_ARGS "-D${option_off}=OFF")
    endforeach()
  endif()

  ExternalProject_Add(ufs-weather-model
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/ufs-weather-model
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ufs-weather-model
    INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    CMAKE_ARGS ${UFS_WEATHER_MODEL_ARGS}
    INSTALL_COMMAND mkdir -p ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR} && cp ${CMAKE_CURRENT_BINARY_DIR}/ufs-weather-model/src/ufs-weather-model-build/ufs_model ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}
    BUILD_ALWAYS TRUE
    STEP_TARGETS build
    )
endif()

# Build UFS utilities
if(BUILD_UFS_UTILS)
  list(APPEND TARGET_LIST UFS_UTILS)

  list(APPEND UFS_UTILS_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    "-DBUILD_TESTING=OFF"
    "-DFRENCTOOLS=OFF"
    "-DICEBLEND=OFF"
    "-DSNOW2MDL=OFF"
    "-DGCYCLE=OFF"
    "-DGRIDTOOLS=OFF"
    "-DOROG_MASK_TOOLS=OFF"
    "-DSFC_CLIMO_GEN=OFF"
    "-DVCOORD_GEN=OFF"
    "-DFVCOMTOOLS=OFF"
    "-DGBLEVENTS=OFF"
    "-DOCEAN_MERGE=OFF"
    "-DCPLD_GRIDGEN=OFF"
    "-DWEIGHT_GEN=OFF"
  )

  ExternalProject_Add(UFS_UTILS
    DEPENDS ${UFS_DEPEND}
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/UFS_UTILS
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/UFS_UTILS
    INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    CMAKE_ARGS ${UFS_UTILS_ARGS}
    BUILD_ALWAYS TRUE
    STEP_TARGETS build
    )
endif()

# Build UPP
if (BUILD_UPP)
  list(APPEND TARGET_LIST UPP)

  list(APPEND UPP_ARGS
    "-DBUILD_WITH_IFI=OFF"
    "-DBUILD_WITH_GTG=OFF"
    "-DBUILD_WITH_WRFIO=ON"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  )
    
  ExternalProject_Add(UPP
    DEPENDS ${UFS_DEPEND}
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/UPP
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/UPP
    INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} ${UPP_ARGS} -Dexec_dir=${CMAKE_INSTALL_BINDIR}
    BUILD_ALWAYS TRUE
    STEP_TARGETS build
    )
endif()

# Build GSI
if (BUILD_GSI)
  list(APPEND TARGET_LIST GSI)

  ExternalProject_Add(GSI
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/GSI
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/gsi
    INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DGSI_MODE=Regional -DENKF_MODE=FV3REG
    BUILD_ALWAYS TRUE
    STEP_TARGETS build
    )
endif()

# Build rrfs_utl
if (BUILD_RRFS_UTILS)
  list(APPEND TARGET_LIST RRFS_UTILS)

  ExternalProject_Add(RRFS_UTILS
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/rrfs_utl
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/rrfs_utl
    INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    BUILD_ALWAYS TRUE
    STEP_TARGETS build
    DEPENDS GSI
    )
endif()

if (CPL_AQM)
  if (BUILD_NEXUS)
    list(APPEND TARGET_LIST NEXUS)

    ExternalProject_Add(arl_nexus
      DEPENDS ${UFS_DEPEND}
      PREFIX ${CMAKE_CURRENT_BINARY_DIR}/arl_nexus
      SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/arl_nexus
      INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
      CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      BUILD_ALWAYS TRUE
    )
  endif()

  if (BUILD_AQM_UTILS)
    list(APPEND TARGET_LIST AQM_UTILS)

    ExternalProject_Add(AQM-utils
      DEPENDS ${UFS_DEPEND}
      PREFIX ${CMAKE_CURRENT_BINARY_DIR}/AQM-utils
      SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/AQM-utils
      INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
      CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR} -DBUILD_POST_STAT=${BUILD_POST_STAT} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      BUILD_ALWAYS TRUE
    )
  endif()
endif()

# add custom target for separate build and install
foreach(i ${TARGET_LIST})
    list(APPEND BUILD_LIST "${i}-build")
endforeach()

add_custom_target(pbuild DEPENDS ${BUILD_LIST})
