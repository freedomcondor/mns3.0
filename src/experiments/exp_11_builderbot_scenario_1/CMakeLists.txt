configure_file( drone.in.lua            simu_code/drone.lua)
configure_file( drone.in.lua            hw_code/drone.lua)
configure_file( pipuck.in.lua           simu_code/pipuck.lua)
configure_file( pipuck.in.lua           hw_code/pipuck.lua)
configure_file( builderbot.in.lua       simu_code/builderbot.lua)
configure_file( builderbot.in.lua       hw_code/builderbot.lua)

configure_file( vns_template.in.argos   simu_code/vns_template.argos)
configure_file( run.in.py               simu_code/run.py)

configure_file( generate_hw_argos.in.py generate_hw_argos.py)

file(GLOB MY_PUBLIC_HEADERS morphologies/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw_code)