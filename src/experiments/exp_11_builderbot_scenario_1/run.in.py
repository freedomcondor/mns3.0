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

drone_xml  = generate_drone_xml(1, -0.4, 0, 1.7, 90, 10, True)  # from label 1 generate drone xml tags, communication range 10
drone_xml += generate_drone_xml(2, 0.4, 0, 1.7, 90, 10, True)  # from label 1 generate drone xml tags, communication range 10

pipuck_locations = [
    [-0.75, 0.6],
    [-0.75, 0.3],
    [-0.75, 0.05],
    [-0.75,-0.3],
#    [-0.75,-0.6],
#    [-0.45, 0.6],
#    [-0.45, 0.3],
#    [-0.45, 0.03  ],
#    [-0.45,-0.3],
#    [-0.45,-0.6],
]

pipuck_xml = generate_pipuck_xml(10, 0.8, -0.3, 0) + generate_pipucks(pipuck_locations, 1, 10)  # from label 1 generate drone xml tags, communication range 10

builderbot_xml = generate_builderbot_xml(11, 0.8, 0.3, 0)

block_locations = [
    [-0.15, 0.4],
    [0.25, 0.2],
    [0.35,-0.2],
    [-0.15,-0.4],
#    [ 0.15, 0.6],
#    [ 0.15, 0.2],
#    [ 0.15,-0.2],
#    [ 0.15,-0.6],
]

block_xml = generate_blocks(block_locations, 3, 33)  # from label 3 generate drone xml tags, type
block_xml = generate_block_xml(1, 0, 0, 0, 34) + block_xml
#block_xml = generate_block_xml(2, 1, 1, 0, 32) + block_xml

parameters = {
    "drone_real_noise"  :  "true",
    "drone_tag_detection_rate"  : 1.00,
    "drone_report_sight_rate"   : 0.8,

    "mode_2D"            :  "true",
    "mode_builderbot"    :  "true",

    "pipuck_label"       :  "1, 10",
    "builderbot_label"   :  "11, 15",
    "block_label"        :  "30, 34",

    "avoid_block_vortex"   :  "nil",
#    "avoid_speed_scalar"   :  0.20,
    "driver_slowdown_zone" :  0.15,
    "driver_stop_zone"     :  0.03,
    "driver_default_speed" : 0.03,

    "dangerzone_pipuck"  :  0.25,
    "dangerzone_block"   :  0.25,

    "center_block_type" :  34,
    "usual_block_type"  :  33,
    "pickup_block_type" :  32,

    "special_pipuck"    :  "pipuck10",
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
        ''' + parameters_txt, {"show_frustum":True, "show_tag_rays":True})],
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

