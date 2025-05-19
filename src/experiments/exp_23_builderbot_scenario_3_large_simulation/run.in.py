createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
customizeOpts = "t:"
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os
import math   # for pi sin cos

# drone and pipuck
arena_size = 50
arena_z_center = 10

n_drone = 4
drone_locations = generate_random_locations(
    n_drone,
    -2.5, 0,     # origin location
    -5, -1,      # random x range
    -1,  5,       # random y range
    0.7, 1.0,    # near limit and far limit
    10000        # attempt count
)
drone_xml = generate_drones(drone_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10

n_pipuck = 24
pipuck_locations = generate_random_locations(
    n_pipuck,
    -2, 0,       # origin location
    -5, -1,      # random x range
    -1, 5,       # random y range
    0.3, 1.0,    # near limit and far limit
    10000        # attempt count
)
pipuck_xml = generate_pipucks(pipuck_locations, 1, 10)    # from label 1 generate drone xml tags, communication range 10

pipuck_xml += generate_pipuck_xml(100, 0, -3.0, 90)

border  = generate_line_locations(25, 3, -3, 3, 5)
block_xml = generate_blocks(border, 101, 234)

#line_length = 8
#for i in range(0, line_length) :
#    block_xml += generate_block_xml(reference_length + i, 0, i * 1, 0, 34)

parameters = {
    "drone_real_noise"   :  "true",
    "drone_tag_detection_rate"  : 0.90,
    "drone_report_sight_rate"   : 0.9,
    "drone_default_height" : 2.5,
    "dangerzone_drone"   :   1.0,

    "mode_2D"            :  "true",
    "mode_builderbot"    :  "true",

    "pipuck_label"       :  "1, 100",
    "block_label"        :  "230, 234",

    "avoid_block_vortex"   :  "nil",
#    "avoid_speed_scalar"   :  0.20,

    "obstacle_block_type" :  234,
    "reference_block_type" : 232,

    "obstacle_unseen_count" : 0,

    "stabilizer_preference_brain"  : "pipuck1",
    "special_pipuck"               :  "pipuck100",
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

        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True, "white")],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

