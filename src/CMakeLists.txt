cmake_minimum_required(VERSION 2.8.12)
project(argos3_pipuck_ext)

# Use new policies introduced up to this version
cmake_policy(SET CMP0042 NEW)
cmake_policy(SET CMP0071 NEW)
set(OpenGL_GL_PREFERENCE "LEGACY")

# Make sure we are under Unix

if(NOT UNIX)
  add_subdirectory(testing)
  message("ARGoS compiles only under UNIX, sorry!")
  message("windows detected, generate only tests")
  return()
endif(NOT UNIX)

# Set CMAKE_APPLE_FLAG for MacOS

SET(CMAKE_APPLE_FLAG "false")
IF (APPLE)
	SET(CMAKE_APPLE_FLAG "true")
ENDIF(APPLE)

set(CMAKE_MACOSX_RPATH 0)
set(CMAKE_MODULE_PATH $ENV{CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)
include_directories(${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})

include(${CMAKE_SOURCE_DIR}/cmake/ARGoSBuildOptions.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/ARGoSBuildFlags.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/ARGoSBuildChecks.cmake)

add_library(my_extensions SHARED
  # add the debug actuator
  extensions/debug/debug_entity.h
  extensions/debug/debug_entity.cpp
  extensions/debug/debug_default_actuator.h
  extensions/debug/debug_default_actuator.cpp
  # add the extended pipuck model
  extensions/pipuck_ext/pipuck_ext_entity.h
  extensions/pipuck_ext/pipuck_ext_entity.cpp  
  extensions/pipuck_ext/dynamics3d_pipuck_ext_model.h
  extensions/pipuck_ext/dynamics3d_pipuck_ext_model.cpp
  # include the loop function
  extensions/my_loop_functions.h
  extensions/my_loop_functions.cpp)
target_link_libraries(my_extensions
  argos3core_${ARGOS_BUILD_FOR})
if(ARGOS_USE_DOUBLE)
  target_compile_definitions(my_extensions PUBLIC BT_USE_DOUBLE_PRECISION)
endif(ARGOS_USE_DOUBLE)

# replay loop function
add_library(replay_loop_functions SHARED
  # add the debug actuator
  extensions/debug/debug_entity.h
  extensions/debug/debug_entity.cpp
  extensions/debug/debug_default_actuator.h
  extensions/debug/debug_default_actuator.cpp
  # add the extended pipuck model
  extensions/pipuck_ext/pipuck_ext_entity.h
  extensions/pipuck_ext/pipuck_ext_entity.cpp
  extensions/pipuck_ext/dynamics3d_pipuck_ext_model.h
  extensions/pipuck_ext/dynamics3d_pipuck_ext_model.cpp
  # include the loop function
  extensions/replay_loop_functions.h
  extensions/replay_loop_functions.cpp
  # include qtopengl
  qtopengl_extensions/my_qtopengl_user_functions.h
  qtopengl_extensions/my_qtopengl_user_functions.cpp)
target_link_libraries(replay_loop_functions
  argos3core_${ARGOS_BUILD_FOR})
if(ARGOS_USE_DOUBLE)
  target_compile_definitions(replay_loop_functions PUBLIC BT_USE_DOUBLE_PRECISION)
endif(ARGOS_USE_DOUBLE)

if(ARGOS_QTOPENGL_FOUND)
  add_library(my_qtopengl_extensions SHARED
    qtopengl_extensions/my_qtopengl_user_functions.h
    qtopengl_extensions/my_qtopengl_user_functions.cpp
    qtopengl_extensions/qtopengl_pipuck_ext_models.h
    qtopengl_extensions/qtopengl_pipuck_ext.h
    qtopengl_extensions/qtopengl_pipuck_ext.cpp)
  target_link_libraries(my_qtopengl_extensions
    my_extensions)
endif(ARGOS_QTOPENGL_FOUND)

#create a logs folder for logs
make_directory(logs)
#add testing sub directory
add_subdirectory(testing)
#add experiments sub directory
add_subdirectory(experiments)
#add scripts sub directory
add_subdirectory(scripts)

#add copy floor 
configure_file( qtopengl_extensions/wood_floor.png     floor_texture/wood_floor.png    COPYONLY)
