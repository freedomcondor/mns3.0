# loop functions -----------------------------------------------------------------------
add_library(exp_08_fault_tolerance_loop_function SHARED
  # add the debug actuator
  ${CMAKE_SOURCE_DIR}/extensions/debug/debug_entity.h
  ${CMAKE_SOURCE_DIR}/extensions/debug/debug_entity.cpp
  ${CMAKE_SOURCE_DIR}/extensions/debug/debug_default_actuator.h
  ${CMAKE_SOURCE_DIR}/extensions/debug/debug_default_actuator.cpp
  # add the extended pipuck model
  ${CMAKE_SOURCE_DIR}/extensions/pipuck_ext/pipuck_ext_entity.h
  ${CMAKE_SOURCE_DIR}/extensions/pipuck_ext/pipuck_ext_entity.cpp  
  ${CMAKE_SOURCE_DIR}/extensions/pipuck_ext/dynamics3d_pipuck_ext_model.h
  ${CMAKE_SOURCE_DIR}/extensions/pipuck_ext/dynamics3d_pipuck_ext_model.cpp
  # include the loop function
  ${CMAKE_CURRENT_SOURCE_DIR}/loopfunction/loop_functions.h
  ${CMAKE_CURRENT_SOURCE_DIR}/loopfunction/loop_functions.cpp)

target_include_directories(exp_08_fault_tolerance_loop_function PUBLIC
  ${CMAKE_SOURCE_DIR}/extensions)

target_link_libraries(exp_08_fault_tolerance_loop_function
  argos3core_${ARGOS_BUILD_FOR})
if(ARGOS_USE_DOUBLE)
  target_compile_definitions(exp_08_fault_tolerance_loop_function PUBLIC BT_USE_DOUBLE_PRECISION)
endif(ARGOS_USE_DOUBLE)

# lua files -----------------------------------------------------------------------
configure_file( drone.in.lua                simu_code/drone.lua)

configure_file( vns_template.in.argos       simu_code/vns_template.argos)
configure_file( run.in.py                   simu_code/run.py)

file(GLOB MY_PUBLIC_HEADERS morphologies/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

add_subdirectory(script)