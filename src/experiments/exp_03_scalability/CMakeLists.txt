configure_file( drone.in.lua                simu_code/drone.lua)
configure_file( morphologyGenerateCube.lua  simu_code/morphologyGenerateCube.lua)
configure_file( morphologyGenerateTetrahedron.lua  simu_code/morphologyGenerateTetrahedron.lua)
configure_file( morphologyGenerateChain.lua simu_code/morphologyGenerateChain.lua)
configure_file( morphology_8.lua            simu_code/morphology_8.lua)

configure_file( vns_template.in.argos   simu_code/vns_template.argos)
configure_file( run.in.py               simu_code/run.py)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

add_subdirectory(script)