#
set(file_sh ${CMAKE_CURRENT_BINARY_DIR}/path.sh)
set(path "${CMAKE_INSTALL_PREFIX}/bin:$ENV{PATH}")
file(WRITE ${file_sh} "#!/usr/bin/env bash\n")
file(APPEND ${file_sh} "export PATH=\"${path}\"")
execute_process(COMMAND chmod a+x ${file_sh} RESULT_VARIABLE res)

# TODO add a more meaningful test? or not ...
add_test ( test_fcst
           ${CMAKE_CURRENT_SOURCE_DIR}/run_fcst.sh )
