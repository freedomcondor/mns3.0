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
    Experiment_type = "cube_27"
    print("Experiment_type not provided: using default", Experiment_type)

import os

# drone and pipuck
n_drone_index = {
    "cube_27"       :    27,
    "cube_64"       :    64,
    "cube_125"      :   125,
    "cube_216"      :   216,
}

structure = Experiment_type
if structure not in n_drone_index :
    print("wrong experiment type provided, please choose among : ")
    for key in n_drone_index :
        print("    " + key)
    exit()

n_drone = n_drone_index[structure]

# calculate split
if n_drone == 27:
    n_drone_split_ranger = 8
elif n_drone == 64:
    n_drone_split_ranger = 27
elif n_drone == 125:
    n_drone_split_ranger = 64
elif n_drone == 216:
    n_drone_split_ranger = 125
elif n_drone == 512:
    n_drone_split_ranger = 216
else:
    n_drone_split_ranger = n_drone / 2

n_drone_split_main = n_drone - n_drone_split_ranger

# calculate side
n_side = n_drone ** (1.0/3)
n_side_split_ranger = n_drone_split_ranger ** (1.0/3)
n_side_split_main = 0
while ( (1.0/6)*n_side_split_main*(n_side_split_main+1)*(n_side_split_main+2) < n_drone_split_main ) :
	n_side_split_main = n_side_split_main + 1

L = 5

half_side_length = (n_side-1) * L * 0.5
half_side_length_split_ranger = (n_side_split_ranger-1) * L * 0.5
half_side_length_split_main = (n_side_split_main-1) * L * 0.5

arena_size = half_side_length_split_main * 6 + half_side_length * 6
arena_z_center = half_side_length * 2 - 2

A = half_side_length_split_ranger * 2 * 1.75
B = half_side_length_split_ranger * 2 * 1.75
if n_side_split_ranger == 2:
    B = B * 2
C = half_side_length_split_main * 2 * 1.75

H = (A + C + 3) * 0.5 


offset = -half_side_length * 4
yoffset = -half_side_length * 1
y_scale = 1.2
if n_drone == 512 :
    y_scale = 1.7
drone_locations = generate_random_locations(n_drone,
                                            offset -half_side_length,   yoffset-half_side_length,               # origin location
                                            offset -half_side_length*1.2, offset+half_side_length*1.2,       # random x range
                                            yoffset-half_side_length*y_scale, yoffset + half_side_length*y_scale,                     # random y range
                                            1.5, 3,           # near limit and far limit
                                            10000)              # attempt count

drone_xml = generate_drones(drone_locations, 1, 12)                  # from label 1 generate drone xml tags, communication range 4.2

obstacle_xml = ""

obstacle_xml += generate_3D_triangle_gate_xml(1,                    # id
                                              0, -H*0.5, H, # position
                                              0, 0, 0,              # orientation
                                              1001,                 # payload
                                              C, 0.2,          # size x, size y, thickness
                                              C+3, H*2)      

size_y = half_side_length_split_ranger*3 
obstacle_xml += generate_3D_rectangular_gate_xml(2,                    # id
                                                 0, H*0.5, H, # position
                                                 0, 0, 0,              # orientation
                                                 1002,                 # payload
                                                 A, B, 0.2,    # size x, size y, thickness
                                                 A+3, H*2)

parameters = generate3DdroneParameters()
parameters["n_drone"] = n_drone
parameters["n_left_drone"] = n_drone_split_ranger
parameters["base_height"] = H-C*0.25
parameters["drone_label"] = "1,500"
parameters["obstacle_label"] = "1000,1500"

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
        ["OBSTACLES",         obstacle_xml],
        ["DRONES",            drone_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt, {"velocity_mode":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True)],
    ]
)

os.system("echo " + structure + "> type.txt")
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
