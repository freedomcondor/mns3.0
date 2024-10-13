createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
customizeOpts = "t:"
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os
import math   # for pi sin cos

# drone and pipuck
arena_size = 50
arena_z_center = 10

n_drone = 5
drone_locations = generate_random_locations(
    n_drone,
    0, 0,     # origin location
    -5, 0.3,      # random x range
    -0.5, 0.5,       # random y range
    0.7, 1.0,    # near limit and far limit
    10000        # attempt count
)
drone_xml = generate_drones(drone_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10

n_pipuck = n_drone * 2 + 2
pipuck_locations = generate_slave_locations(
    n_pipuck,
    drone_locations,
    -5,  0.3,      # random x range
    -1,  1,       # random y range
    0.3, 0.7,    # near limit and far limit
    10000        # attempt count
)
pipuck_xml = generate_pipucks(pipuck_locations, 1, 10)    # from label 1 generate drone xml tags, communication range 10

#pipuck_xml += generate_pipuck_xml(10, 0, -4.0, 90)

block_xml = ""
block_xml += generate_block_xml(1, 0, 0, 0, 34, False)
block_xml += generate_block_xml(2, 0, 3, 0, 34, False)
block_xml += generate_block_xml(3, -3, 3, 0, 34, False)
block_xml += generate_block_xml(4, -3, 0, 0, 34, False)

#line_length = 8
#for i in range(0, line_length) :
#    block_xml += generate_block_xml(reference_length + i, 0, i * 1, 0, 34)

parameters = {
    "drone_real_noise"   :  "true",
    "drone_tag_detection_rate"  : 1.00,
    "drone_report_sight_rate"   : 1.00,
    "drone_default_start_height" : 2.5,
    "drone_default_height" : 2.5,

    "mode_2D"            :  "true",
    "mode_builderbot"    :  "true",

    "pipuck_label"       :  "1, 29",
    "obstacle_label"        :  "30, 34",

    "avoid_block_vortex"   :  "nil",

    "obstacle_unseen_count" : 0,

    "stabilizer_preference_brain"  : "drone1",
}

parameters_txt = generateParametersText(parameters)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],

        ["ARENA_SIZE",        str(arena_size)],
        ["ARENA_Z_CENTER",    str(arena_z_center)],

        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["BLOCKS",            block_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt, {"show_frustum":False, "show_tag_rays":False})],
        ["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/pipuck.lua"
        ''' + parameters_txt)],
        ["BLOCK_CONTROLLER", generate_block_controller('''
              script="@CMAKE_SOURCE_DIR@/scripts/libreplayer/dummy.lua"
        ''' + parameters_txt)],

        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "white")],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

