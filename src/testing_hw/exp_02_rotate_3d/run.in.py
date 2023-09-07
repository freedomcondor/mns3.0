createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

drone_locations = [
    [2,0],
    [-2,-1.2],
    [-2,1.2],
]

drone_xml = generate_drones(drone_locations, 1, 10)                  # from label 1 generate drone xml tags, communication range 4.2

base   = [-5, 2.5]
offset = [1.23, -1.23]

obstacle_locations = []
for i in range(0, 9) :
    for j in range(0, 5) :
        x = base[0] + i * offset[0]
        y = base[1] + j * offset[1]
        id = i * 5 + j
        obstacle_locations.append([x, y, 0, id])

obstacle_tagstr = ""
i = 0
for loc in obstacle_locations :
    obstacle_tagstr = obstacle_tagstr + generate_obstacle_xml(i, loc[0], loc[1], loc[2], loc[3])
    i = i + 1

parameters = '''
    mode_2D="true"
    drone_real_noise="true"
    drone_tilt_sensor="false"

    obstacle_label="0, 200"

    safezone_drone_drone="10.0"
    dangerzone_drone="2.0"
    deadzone_drone="1.5"

    second_report_sight="true"

    driver_default_speed="0.1"
    driver_slowdown_zone="0.3"
    driver_stop_zone="0.05"
    driver_arrive_zone="0.5"

    drone_velocity_mode="false"
'''

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos",
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["REAL_SCENARIO",     generate_real_scenario_object()],
        ["DRONES",            drone_xml],
        ["OBSTACLES",         obstacle_tagstr],
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/code/drone.lua"
        ''' + parameters, {"velocity_mode":False})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

