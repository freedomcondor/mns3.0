createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck

n_drone = Experiment_length   # abuse experiment length for drone numbers
n_side = n_drone ** (1/3)
half_side_length = n_side * 0.5 * 1.5

offset = - n_side * 2

drone_locations = generate_random_locations(n_drone,
                                            offset - half_side_length, -half_side_length,               # origin location
                                            offset -half_side_length-1, half_side_length+1,            # random x range
                                            offset -half_side_length-1, half_side_length+1,            # random y range
                                            0.5, 1.5,           # near limit and far limit
                                            10000)              # attempt count

drone_xml = generate_drones(drone_locations, 1, 4.2)                 # from label 1 generate drone xml tags, communication range 4.2

obstacle_xml = generate_3D_rectangular_gate_xml(1,                     # id
                                                offset + half_side_length + 3, 0, half_side_length + 2, # position
                                                0, 0, 0, # orientation
                                                1001,                 # payload
                                                n_side, 4, 0.1) # size x, knots, thickness

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="true"

    drone_label="1, 1000"

    drone_default_start_height="3.0"
    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="true"

    driver_default_speed="0.5"
    driver_slowdown_zone="0.7"
    driver_stop_zone="0.15"

    n_drone="{}"
'''.format(n_drone)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["OBSTACLES",         obstacle_xml],
        ["DRONES",            drone_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters)],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
