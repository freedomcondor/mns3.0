configure_file( replay.in.py              replay.py )
configure_file( replayer_template.in.argos  replayer_template.argos )

# replay loop functions -----------------------------------------------------------------------
if(ARGOS_QTOPENGL_FOUND)
  # replay loop function
  add_library(exp_06_replay_loop_function SHARED
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
    ${CMAKE_CURRENT_SOURCE_DIR}/replay_loopfunction/color_replay_loop_functions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/replay_loopfunction/color_replay_loop_functions.cpp
    # include qtopengl
    ${CMAKE_SOURCE_DIR}/qtopengl_extensions/my_qtopengl_user_functions.h
    ${CMAKE_SOURCE_DIR}/qtopengl_extensions/my_qtopengl_user_functions.cpp)

  target_include_directories(exp_06_replay_loop_function PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/replay_loop_functions
    ${CMAKE_SOURCE_DIR}/extensions)

  target_link_libraries(exp_06_replay_loop_function
    argos3core_${ARGOS_BUILD_FOR})
  if(ARGOS_USE_DOUBLE)
    target_compile_definitions(exp_06_replay_loop_function PUBLIC BT_USE_DOUBLE_PRECISION)
  endif(ARGOS_USE_DOUBLE)

endif(ARGOS_QTOPENGL_FOUND)