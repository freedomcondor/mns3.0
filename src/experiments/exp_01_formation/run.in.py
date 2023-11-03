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
    Experiment_type = "polyhedron_12"
    print("Experiment_type not provided: using default", Experiment_type)

import os

# drone and pipuck

n_drone_index = {
    "polyhedron_12" :    12,
    "polyhedron_20" :    20,
    "cube_27"       :    27,
    "cube_64"       :    64,
    "cube_125"      :   125,
    "screen_64"     :    64,
    "donut_64"      :    64,
    "donut_48"      :    48,
    "cube_216"      :   216,
    "cube_512"      :   512,
    "cube_1000"     :  1000,
}

structure = Experiment_type
if structure not in n_drone_index :
    print("wrong experiment type provided, please choose among : ")
    for key in n_drone_index :
        print("    " + key)
    exit()

n_drone = n_drone_index[structure]

# calculate side
n_side = n_drone ** (1.0/3)
L = 5

half_side_length = (n_side-1) * L * 0.5

arena_size = half_side_length * 30
arena_z_center = arena_size / 2 - 2

offset = 0
yoffset = 0
x_scale = 1.2
y_scale = 1.2
near_limit = 1.5
far_limit = 3
if n_drone == 512 :
    y_scale = 1.5
if n_drone == 1000 :
    near_limit = 1.25
drone_locations = generate_random_locations(n_drone,
                                            offset -half_side_length*x_scale, yoffset -half_side_length*y_scale,          # origin location
                                            offset -half_side_length*x_scale, offset  +half_side_length*x_scale,      # random x range
                                            yoffset-half_side_length*y_scale, yoffset + half_side_length*y_scale, # random y range
                                            near_limit, far_limit,           # near limit and far limit
                                            10000)              # attempt count

drone_xml = generate_drones(drone_locations, 1, 12)                  # from label 1 generate drone xml tags, communication range 4.2

parameters = generate3DdroneParameters()
parameters["structure"] = structure

if n_drone == 1000 :
    parameters["drone_flight_preparation_state_duration"] = 50

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
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt, {"ideal_mode":False, "velocity_mode":True})],

        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "white")],
    ]
)

os.system("echo " + structure + "> type.txt")
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

