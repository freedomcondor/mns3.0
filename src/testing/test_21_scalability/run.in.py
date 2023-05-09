createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

n_drone = Experiment_length                # abuse experiment length for total number
half_side_length = n_drone ** (1/3) / 2 * 1.5

# drone and pipuck
drone_locations = generate_random_locations(n_drone,
                                            -half_side_length, -half_side_length,               # origin location
                                            -half_side_length-1, half_side_length+1,            # random x range
                                            -half_side_length-1, half_side_length+1,            # random y range
                                            0.5, 1.5,           # near limit and far limit
                                            10000)              # attempt count

drone_xml =  generate_drones(drone_locations, 1, 3.5)                 # from label 1 generate drone xml tags

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="false"

    drone_label="1, 1000"
    obstacle_label="100, 100"

    drone_default_start_height="3.0"
    safezone_drone_drone="3.5"
    dangerzone_drone="1"

    second_report_sight="true"

    driver_default_speed="0.5"
    driver_slowdown_zone="1.5"
    driver_stop_zone="0.15"

    drone_velocity_mode="true"

    n_drone="{}"
'''.format(n_drone)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str(501/5)],
        ["TOTALLENGTH",       str(0)],
        ["DRONES",            drone_xml], 
        #["OBSTACLES",         obstacle_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters, {"ideal_mode":False, "velocity_mode":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True)],
    ]
)

#os.system("timeout 3600 argos3 -c vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
