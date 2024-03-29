include(ExternalProject)

# Options
option(BUILD_UFS "Build UFS weather model" ON)
option(BUILD_UFS_UTILS "Build UFS utilities" ON)
option(BUILD_UPP "Build UPP" ON)

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
      set(CCPP_SUITES "FV3_GFS_v15p2,FV3_GFS_v16,FV3_GFS_v17_p8")
    else()
      set(CCPP_SUITES "FV3_GFS_v15p2,FV3_GFS_v16,FV3_GFS_v17_p8,FV3_RRFS_v1beta,FV3_HRRR,FV3_RAP,FV3_GFS_v15_thompson_mynn_lam3km,FV3_WoFS_v0")
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
    "-DBUILD_TESTING=OFF"
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

  ExternalProject_Add(UPP
    DEPENDS ${UFS_DEPEND}
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/UPP
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/UPP
    INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -Dexec_dir=${CMAKE_INSTALL_BINDIR}
    BUILD_ALWAYS TRUE
    STEP_TARGETS build
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
      CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR}
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
      CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR} -DBUILD_POST_STAT=${BUILD_POST_STAT}
      BUILD_ALWAYS TRUE
    )
  endif()
endif()

# add custom target for separate build and install
foreach(i ${TARGET_LIST})
    list(APPEND BUILD_LIST "${i}-build")
endforeach()

add_custom_target(pbuild DEPENDS ${BUILD_LIST})
