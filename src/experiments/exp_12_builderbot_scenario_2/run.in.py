createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
customizeOpts = "t:"
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

Experiment_type = None
for opt, value in optlist:
    if opt == "-t":
        Experiment_type = value
        print("Experiment_type provided: ", Experiment_type)
if Experiment_type == None :
    Experiment_type = "no_builderbot"
    print("Experiment_type not provided: using default", Experiment_type)

import os

# drone and pipuck

if Experiment_type != "no_builderbot" and Experiment_type != "builderbot" :
    print("wrong experiment type provided, please choose no_builderbot or builderbot")
    exit()

n_pipuck = 3
n_drone = 1
arena_size = 50
arena_z_center = 10

pipuck_locations = generate_random_locations(n_pipuck,
                                             -0.5, -0.05,       # origin
                                             -0.8, -0.5,    # random x
                                             -0.65, 0.65,    # random y
                                             0.3, 0.5,   # near limit and far limit
                                             10000)      # attempt count

'''
n_block = 2
block_locations = generate_random_locations(n_block,
                                            0.5, 0,       # origin
                                            0.2, 0.8,    # random x
                                            -0.7, 0.7,    # random y
                                            0.3, 0.5,   # near limit and far limit
                                            10000)      # attempt count
'''

#pipuck_xml = generate_pipuck_xml(10, 2, 0, 0) + generate_pipucks(pipuck_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10
pipuck_xml = generate_pipucks(pipuck_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10

drone_xml  = generate_drone_xml(1, -0.4, 0, 1.7, 90, 10, True)  # from label 1 generate drone xml tags, communication range 10
drone_xml += generate_drone_xml(2, 0.4, 0, 1.7, 90, 10, True)  # from label 1 generate drone xml tags, communication range 10

builderbot_xml = generate_builderbot_xml(11, 2, 0, 0)

#block_xml  = generate_blocks(block_locations, 10, 33)  # from label 2 generate drone xml tags, type
block_xml  = generate_block_xml(10, 0.5, -0.2, 0, 33)
block_xml += generate_block_xml(1, -0.2, 0.45, 0, 34)
block_xml += generate_block_xml(3, -0.2, 0, 0, 34)
block_xml += generate_block_xml(4, -0.2,-0.45, 0, 34)

block_xml += generate_block_xml(5,-0.8, -0.6, 0, 32)
block_xml += generate_block_xml(6,-0.2, -0.6, 0, 32)
block_xml += generate_block_xml(7, 0.2, -0.6, 0, 32)
block_xml += generate_block_xml(8, 0.8, -0.6, 0, 32)

parameters = {
    "drone_real_noise"  :  "true",
    "drone_tag_detection_rate"  : 0.90,
    "drone_report_sight_rate"   : 0.8,

    "mode_2D"           :  "true",
    "mode_builderbot"   :  "true",

    "pipuck_label"      :  "1, 10",
    "builderbot_label"  :  "11, 15",
    "block_label"       :  "30, 34",

    "driver_stop_zone"  :  0.01,
    "driver_arrive_zone" : 0.1,

    "avoid_block_vortex"  :  "nil",
    "dangerzone_pipuck" :  0.20,
    "dangerzone_block"  :  0.20,

    "line_block_type"      :  34,
    "obstacle_block_type"  :  33,
    "reference_block_type"  : 32,

    "stabilizer_preference_brain" : "pipuck1",
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
        ["REAL_SCENARIO",     generate_builderbot_real_scenario_object()],

        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["BUILDERBOTS",       builderbot_xml], 
        ["BLOCKS",            block_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt, {"show_frustum":False, "show_tag_rays":True})],
        ["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/pipuck.lua"
        ''' + parameters_txt)],
        ["BUILDERBOT_CONTROLLER", generate_builderbot_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/builderbot.lua"
        ''' + parameters_txt)],
        ["BLOCK_CONTROLLER", generate_block_controller('''
              script="@CMAKE_SOURCE_DIR@/scripts/libreplayer/dummy.lua"
        ''' + parameters_txt)],

        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True, "white")],
    ]
)

os.system("echo " + Experiment_type + "> type.txt")
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

