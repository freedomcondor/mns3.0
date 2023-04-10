configure_file( drone.in.lua      simu_code/drone.lua)
configure_file( morphology_2.lua    simu_code/morphology_2.lua)
configure_file( morphology_4.lua    simu_code/morphology_4.lua)
configure_file( morphology_8.lua    simu_code/morphology_8.lua)
configure_file( morphology_12.lua    simu_code/morphology_12.lua)
configure_file( morphology_12_rec.lua    simu_code/morphology_12_rec.lua)
configure_file( morphology_12_tri.lua    simu_code/morphology_12_tri.lua)
configure_file( morphology_20.lua    simu_code/morphology_20.lua)

configure_file( vns_template.in.argos      simu_code/vns_template.argos)
configure_file( run.in.py                  simu_code/run.py)

configure_file( run_test.in.sh             run_test.sh)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu_code)