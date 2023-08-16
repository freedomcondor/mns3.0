configure_file( drone.in.lua            simu_code/drone.lua)

configure_file( trussGenerator.lua      simu_code/trussGenerator.lua)
configure_file( morphology_12.lua       simu_code/morphology_12.lua)
configure_file( man.lua                 simu_code/man.lua)
configure_file( jet.lua                 simu_code/jet.lua)
configure_file( truck.lua               simu_code/truck.lua)

configure_file( vns_template.in.argos   simu_code/vns_template.argos)
configure_file( run.in.py               simu_code/run.py)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

add_subdirectory(script)