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

# Build in this subdirectory.
#add_subdirectory(src)

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
  DESTINATION bin)

#####
# Create 'ufs_srweather_app_meta.h' include file.
#####
configure_file(
  ufs_srweather_app_meta.h.in
  ufs_srweather_app_meta.h @ONLY)

FILE(COPY "${CMAKE_CURRENT_BINARY_DIR}/ufs_srweather_app_meta.h" DESTINATION include)

add_subdirectory(src)
