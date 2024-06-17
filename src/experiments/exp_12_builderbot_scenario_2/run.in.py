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

n_pipuck = 4
n_drone = 1
n_block = 3
arena_size = 50
arena_z_center = 10

pipuck_locations = generate_random_locations(n_pipuck,
                                             -1.0, 0,       # origin
                                             -3, 0,    # random x
                                             -3, 3,    # random y
                                             0.3, 0.5,   # near limit and far limit
                                             10000)      # attempt count

drone_locations = generate_random_locations(n_drone,
                                             0, 0,       # origin
                                             -3, 3,    # random x
                                             -3, 3,    # random y
                                             0.3, 0.5,   # near limit and far limit
                                             10000)      # attempt count

block_locations = generate_random_locations(n_block,
                                            1, 0,       # origin
                                            0, 10,    # random x
                                            -2, 2,    # random y
                                            0.7, 1.0,   # near limit and far limit
                                            10000)      # attempt count

#pipuck_xml = generate_pipuck_xml(10, 2, 0, 0) + generate_pipucks(pipuck_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10
pipuck_xml = generate_pipucks(pipuck_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10
drone_xml = generate_drones(drone_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10
#builderbot_xml = generate_builderbot_xml(11, 2, 0, 0)
builderbot_xml = ""

block_xml = generate_blocks(block_locations, 5, 33)  # from label 2 generate drone xml tags, type
block_xml = generate_block_xml(1, 0, -0.4, 0, 34) + block_xml
block_xml = generate_block_xml(2, 0, 0,    0, 34) + block_xml
block_xml = generate_block_xml(3, 0, 0.4, 0, 34) + block_xml
block_xml = generate_block_xml(4, 0, 0.8, 0, 34) + block_xml

obstacle_xml  = generate_obstacle_xml(1, 0, -0.7, 0, 30)
obstacle_xml += generate_obstacle_xml(2, 1.5, -0.7, 0, 30)
obstacle_xml += generate_obstacle_xml(3, 3, -0.7, 0, 30)

parameters = {
    "drone_real_noise"  :  "true",
    "drone_tag_detection_rate"  : 0.95,
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
    "reference_block_type"  : 30,

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

        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["BUILDERBOTS",       builderbot_xml], 
        ["BLOCKS",            block_xml], 
        ["OBSTACLES",         obstacle_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt)],
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

