createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

drone_locations = [
    [0,0,0],
    [0,1,0],
]

drone_xml = generate_drones(drone_locations, 1, 4.2)                  # from label 1 generate drone xml tags, communication range 4.2

obstacle_locations = [
    [0,0,0, 1],
]

obstacle_tagstr = ""
i = 1
for loc in obstacle_locations :
    obstacle_tagstr = obstacle_tagstr + generate_obstacle_xml(i, loc[0], loc[1], loc[2], loc[3])
    i = i + 1

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="false"

    pipuck_label="1, 200"

    safezone_drone_drone="3"
    dangerzone_drone="1"

    report_sight_rounds="2"

    driver_default_speed="0.5"
    driver_slowdown_zone="0.7"
    driver_stop_zone="0.15"
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
        ["DRONES",            drone_xml], 
        ["OBSTACLES",         obstacle_tagstr], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/code/drone.lua"
        ''' + parameters, {"velocity_mode":False})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

