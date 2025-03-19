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

arena_size = 50
arena_z_center = 10

n_drone = 6
drone_locations = generate_random_locations(
    n_drone,
    -2.5, 0,     # origin location
    -3, -1,      # random x range
    -1, 1,       # random y range
    0.7, 1.5,    # near limit and far limit
    10000        # attempt count
)
drone_xml = generate_drones(drone_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10

n_pipuck = 8
pipuck_locations = generate_random_locations(
    n_pipuck,
    -2, 0,       # origin location
    -3, -1,      # random x range
    -1, 1,       # random y range
    0.3, 0.5,    # near limit and far limit
    10000        # attempt count
)
pipuck_xml = generate_pipucks(pipuck_locations, 1, 10)    # from label 1 generate drone xml tags, communication range 10

pipuck_group_2_locations = [
    [2.0, -0.75],
    [2.0, -0.25],
    [2.0,  0.25],
    [2.0,  0.75],
#    [2.5, -0.75],
#    [2.5, -0.25],
#    [2.5,  0.25],
#    [2.5,  0.75],
]
pipuck_xml += generate_pipucks(pipuck_group_2_locations, 13, 10)    # from label 1 generate drone xml tags, communication range 10

builderbot_xml = generate_builderbot_xml(21, 2.25, 0, 0)

n_block = 20
center_block_type = 32
usual_block_type = 34
pickup_block_type = 33
border_block_type = 31

block_locations = generate_random_locations(
    n_block,
    0, 0.5,     # origin location
    -2, 2,      # random x range
    -2, 2,       # random y range
    0.7, 1.5,    # near limit and far limit
    10000        # attempt count
)

block_xml = generate_blocks(block_locations, 33, usual_block_type)  # from label 33 generate drone xml tags, type

if Experiment_type == "builderbot" :
    block_xml = generate_block_xml(31, 1.0, 0, 0, center_block_type) + block_xml
    block_xml = generate_block_xml(32, -0.5, 0, 0, pickup_block_type, False) + block_xml
else :
    block_xml = generate_block_xml(31, 0, 0, 0, center_block_type, False) + block_xml

length = 3.5
margin = 0.2
border  = generate_line_locations(25, -length,        -length+margin, -length,        length-margin)
border += generate_line_locations(25, -length+margin, length,         length-margin,  length)
border += generate_line_locations(25,  length,        length-margin,  length,         -length+margin)
border += generate_line_locations(25,  length-margin, -length,        -length+margin, -length)

block_xml += generate_blocks(border, 60, border_block_type)  # from label 3 generate drone xml tags, type

parameters = {
#    "drone_real_noise"  :  "true",
#    "drone_tag_detection_rate"  : 0.90,
#    "drone_report_sight_rate"   : 0.9,
	"obstacle_match_distance" : 0.10,
	"obstacle_unseen_count" : 1,

    "mode_2D"            :  "true",
    "mode_builderbot"    :  "true",
    "drone_default_height" : 2,

    "pipuck_label"       :  "1, 20",
    "builderbot_label"   :  "21, 29",
    "block_label"        :  "30, 100",

    "avoid_block_vortex"   :  "nil",
#    "avoid_speed_scalar"   :  0.20,
    "driver_slowdown_zone" :  0.15,
    "driver_stop_zone"     :  0.03,
    "driver_default_speed" : 0.03,

    "dangerzone_pipuck"  :  0.30,
    "dangerzone_block"   :  0.30,
    "dangerzone_drone"   :  0.5,
    "safezone_default"   :  3.0,   # for recruit builderbot

    "center_block_type" :  center_block_type,
    "usual_block_type"  :  usual_block_type,
    "pickup_block_type" :  pickup_block_type,
    "border_block_type" :  border_block_type,

    "n_pipuck" :  n_pipuck,
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
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt, {"show_frustum":False, "show_tag_rays":False})],
        ["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/pipuck.lua"
        ''' + parameters_txt)],
        ["BUILDERBOT_CONTROLLER", generate_builderbot_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/builderbot.lua"
        ''' + parameters_txt)],
        ["BLOCK_CONTROLLER", generate_block_controller('''
              script="@CMAKE_SOURCE_DIR@/scripts/libreplayer/dummy.lua"
        ''' + parameters_txt)],

        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "white")],
    ]
)

os.system("echo " + Experiment_type + "> type.txt")
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

