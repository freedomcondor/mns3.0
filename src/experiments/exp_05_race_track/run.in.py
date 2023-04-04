createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drones

drone_locations = generate_random_locations(20,                  # total number
                                            0, 0,             # origin location
                                            -1.5, 1.5,              # random x range
                                            -1.5, 1.5,              # random y range
                                            0.5, 1.5)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags

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

id = 0
obstacle_xml = ""
for loc in gate_locations :
    id = id + 1
    if loc[10] == "circle" :
        obstacle_xml += generate_3D_circle_gate_xml(id,                     # id
                                                    loc[0], loc[1], loc[2], # position
                                                    loc[3], loc[4], loc[5], # orientation
                                                    loc[9],                 # payload
                                                    loc[6], loc[7], loc[8]) # size x, knots, thickness
    if loc[10] == "triangle" :
        obstacle_xml += generate_3D_triangle_gate_xml(id,                     # id
                                                      loc[0], loc[1], loc[2], # position
                                                      loc[3], loc[4], loc[5], # orientation
                                                      loc[9],                 # payload
                                                      loc[6],       loc[8])   # size x, knots, thickness
    if loc[10] == "rectangular" :
        obstacle_xml += generate_3D_rectangular_gate_xml(id,                     # id
                                                      loc[0], loc[1], loc[2], # position
                                                      loc[3], loc[4], loc[5], # orientation
                                                      loc[9],                 # payload
                                                      loc[6], loc[7], loc[8]) # size x, knots, thickness

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="true"

    drone_label="1, 20"
    obstacle_label="100, 110"

    drone_default_start_height="3.0"
    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="true"

    driver_default_speed="0.5"
    driver_slowdown_zone="0.7"
    driver_stop_zone="0.15"
    driver_arrive_zone="1.0"
'''

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["DRONES",            drone_xml], 
        ["OBSTACLES",         obstacle_xml],
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters)],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
