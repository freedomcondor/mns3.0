configure_file( drone.in.lua               simu_code/drone.lua)
configure_file( complexTrussGenerator.lua  simu_code/complexTrussGenerator.lua)
configure_file( manGenerator.lua           simu_code/manGenerator.lua)
configure_file( truckGenerator.lua         simu_code/truckGenerator.lua)
configure_file( sphere20Generator.lua      simu_code/sphere20Generator.lua)
configure_file( morphologyGenerateSpineSphere.lua      simu_code/morphologyGenerateSpineSphere.lua)

configure_file( vns_template.in.argos      simu_code/vns_template.argos)
configure_file( run.in.py                  simu_code/run.py)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

add_subdirectory(scripts)