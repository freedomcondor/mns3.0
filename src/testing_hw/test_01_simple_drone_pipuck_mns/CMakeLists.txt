configure_file( 00_simu.in.argos          code/00_simu.argos)
configure_file( generate_hw_argos.in.py   generate_hw_argos.py)

configure_file( drone.in.lua      code/drone.lua)
configure_file( pipuck.in.lua     code/pipuck.lua)
configure_file( morphology.lua    code/morphology.lua)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*.lua) # .lua is needed otherwise builderbot-utils will be included
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/code)