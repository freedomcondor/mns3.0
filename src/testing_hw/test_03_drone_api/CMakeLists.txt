configure_file( vns_template.in.argos   vns_template.argos)
configure_file( drone.in.lua            code/drone.lua)
configure_file( run.in.py               run.py)
configure_file( generate_hw_argos.in.py generate_hw_argos.py)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*.lua)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/code)
