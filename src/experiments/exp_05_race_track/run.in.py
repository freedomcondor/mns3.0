createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drones
scale = 5/1.5

drone_locations = generate_random_locations(20,                  # total number
                                            0, 0,             # origin location
                                            -1.5*scale, 1.5*scale,              # random x range
                                            -1.5*scale, 1.5*scale,              # random y range
                                            0.5*scale, 1.5*scale)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1, 12)                 # from label 1 generate drone xml tags

# obstacles

# phase 1 : rec 8
gate_locations = [
#    x    y    z     rz  ry  rx  s1  s2     thick  payload  type
    [5,   0,   3.5,   0,  0,  0,  6, 10,    0.1,  100,  "circle"],
    [10,  0,   3.5,   0,  0,  0,  6, 10,    0.1,  100,  "circle"],

    [15,  3,   3.5,  20,  0,  0,  5,  5,    0.1,  101,  "rectangular"],
    [20,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"],

    [25,  4,   3.5,   0,  0,  0,  6,  None, 0.1,  102,  "triangle"],
    [30,  4,   3.5,   0,  0,  0,  5,  10,   0.1,  103,  "circle"],
    #[25,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"],
    #[30,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"],

    [35,  3,   3.5, -20,  0,  0,  5,  10,   0.1,  103,  "circle"],

    [15, -3,   3.5, -30,  0,  0,  3,  5,    0.1,  104,  "rectangular"],
    [18, -4,   3.5, -15,  0,  0,  3,  5,    0.1,  104,  "rectangular"],
    [21, -4.2, 3.5,   0,  0,  6,  3,  5,    0.1,  104,  "rectangular"],
    [24, -4.2, 3.5,   0,  0, 12,  3,  5,    0.1,  104,  "rectangular"],
    [27, -4.2, 3.5,   0,  0, 18,  3,  5,    0.1,  104,  "rectangular"],
    [30, -4.2, 3.5,   0,  0, 24,  3,  5,    0.1,  104,  "rectangular"],
    [33, -4,   3.5,  15, 10, 30,  3,  5,    0.1,  104,  "rectangular"],
    [36, -3,   3.5,  30, 10, 30,  3,  5,    0.1,  104,  "rectangular"],

    [41,  0,   3.5,   0,  0,  0,  6, 10,    0.1,  100,  "circle"],
]

randomNumber = random.random()
if randomNumber < 0.5 :
    gate_locations[4] = [25,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"]
    gate_locations[5] = [30,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"]

id = 0
obstacle_xml = ""
for loc in gate_locations :
    id = id + 1
    if loc[10] == "circle" :
        obstacle_xml += generate_3D_circle_gate_xml(id,                     # id
                                                    loc[0]*scale, loc[1]*scale, loc[2]*scale, # position
                                                    loc[3], loc[4], loc[5], # orientation
                                                    loc[9],                 # payload
                                                    loc[6]*scale, loc[7], loc[8]*scale) # size x, knots, thickness
    if loc[10] == "triangle" :
        obstacle_xml += generate_3D_triangle_gate_xml(id,                     # id
                                                      loc[0]*scale, loc[1]*scale, loc[2]*scale, # position
                                                      loc[3], loc[4], loc[5], # orientation
                                                      loc[9],                 # payload
                                                      loc[6]*scale, loc[8]*scale)   # size x, thick ness
    if loc[10] == "rectangular" :
        obstacle_xml += generate_3D_rectangular_gate_xml(id,                     # id
                                                      loc[0]*scale, loc[1]*scale, loc[2]*scale, # position
                                                      loc[3], loc[4], loc[5], # orientation
                                                      loc[9],                 # payload
                                                      loc[6]*scale, loc[7]*scale, loc[8]*scale) # size x, size y, thickness

parameters = generate3DdroneParameters()
parameters['drone_label'] = "1, 20"
parameters['obstacle_label'] = "100, 110"
parameters['dangerzone_aerial_obstacle'] = 2
parameters['dangerzone_drone'] = 3.5
parameters_txt = generateParametersText(parameters)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],     # Inputseed is inherit from createArgosScenario.py
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["DRONES",            drone_xml], 
        ["OBSTACLES",         obstacle_xml],
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt, {"velocity_mode":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
