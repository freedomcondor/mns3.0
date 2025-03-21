createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
customizeOpts = "t:"
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

#-----------------------------------------------------------
Experiment_type = None
for opt, value in optlist:
    if opt == "-t":
        Experiment_type = value
        print("Experiment_type provided: ", Experiment_type)
if Experiment_type == None :
    Experiment_type = "discrete"
    print("Experiment_type not provided: using default", Experiment_type)

if Experiment_type not in ["discrete", "continuous"]:
    print("wrong experiment type provided, please choose among : ")
    for key in ["discrete", "continuous"] :
        print("    " + key)
    exit()

#-----------------------------------------------------------
n_drone = 1

half_side_length = 10
race_length = 1500
arena_size_yz = half_side_length * 2
arena_z_center = arena_size_yz / 2 - 2
arena_size_x = half_side_length * 2 + race_length
arena_x_center = race_length / 2

drone_locations = generate_random_locations(n_drone,
                                            None, None,          # origin location
                                            -half_side_length, half_side_length,  # random x range
                                            -half_side_length, half_side_length, # random y range
                                            1, 3,           # near limit and far limit, it doesn't make sense in this case
                                            10000)              # attempt count

drone_xml = generate_drones(drone_locations, 1, 12)                  # from label 1 generate drone xml tags, communication range 4.2

parameters = generate3DdroneParameters()
parameters["experiment_type"] = Experiment_type
parameters["obstacle_label"] = "1,300"

parameters_txt = generateParametersText(parameters)

#-----------------------------------------------------------
block_distance = 10  # distance between each block in the X axis
num_blocks = 150     # number of blocks to generate
block_locations = [[i * block_distance, 0] for i in range(num_blocks)]

obstacles_xml = ""
for i in range(0, len(block_locations)):
    obstacles_xml += generate_obstacle_xml(i+1, block_locations[i][0], block_locations[i][1], 0, i+1)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],

        ["ARENA_SIZE_X",      str(arena_size_x)],
        ["ARENA_SIZE_YZ",     str(arena_size_yz)],
        ["ARENA_Z_CENTER",    str(arena_z_center)],
        ["ARENA_X_CENTER",    str(arena_x_center)],

        ["DRONES",            drone_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt,
            {   "ideal_mode":False,
                "velocity_mode":True,
                "show_frustum" :True,
                "show_tag_rays":True
            }
        )],

        ["OBSTACLES",         obstacles_xml], 

        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True, "white")],
    ]
)

import os
os.system("echo " + Experiment_type + "> type.txt")
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

