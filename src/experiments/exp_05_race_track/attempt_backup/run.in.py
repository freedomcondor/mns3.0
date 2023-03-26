createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drones

drone_locations = generate_random_locations(8,                  # total number
                                            0, 0,             # origin location
                                            -1.5, 1.5,              # random x range
                                            -1.5, 1.5,              # random y range
                                            0.5, 1.5)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags

drone_locations = generate_random_locations(4,                  # total number
                                            None, None,             # origin location
                                            12, 14,              # random x range
                                            4,  7,              # random y range
                                            0.5, 1.5)           # near limit and far limit
drone_xml += generate_drones(drone_locations, 9)                 # from label 1 generate drone xml tags
                                        
drone_locations = generate_random_locations(8,                  # total number
                                            None, None,             # origin location
                                            30,  33,              # random x range
                                            -1.5, 1.5,              # random y range
                                            0.5, 1.5)           # near limit and far limit
drone_xml += generate_drones(drone_locations, 13)                 # from label 1 generate drone xml tags

# obstacles

# phase 1 : rec 8
gate_rec_locations = [
    [3,         0,         2.5,    0,  0, 10],
    [6,         0,         2.5,    0,  0, 20],
    [9.095,     1.0,       2.5,    30, 15, 30],
    [11.0,      3.0,       2.5,    40, 28, 35],
]

id = 0
obstacle_xml = ""
for loc in gate_rec_locations :
    id = id + 1
    obstacle_xml += generate_3D_rectangular_gate_xml(id,                     # id
                                                  loc[0], loc[1], loc[2], # position
                                                  loc[3], loc[4], loc[5], # orientation
                                                  101,                    # payload
                                                  3, 4, 0.1)              # size x, y, thickness

# station 1 :
gate_station_locations = [
    [15,     5,     2.5,    0, 0, 0],
]
loc = gate_station_locations[0]
obstacle_xml += generate_3D_circle_gate_xml(14,                     # id
                                            loc[0], loc[1], loc[2], # position
                                            loc[3], loc[4], loc[5], # orientation
                                            100,                    # payload
                                            4, 10, 0.1)              # size x, knots, thickness

# phase 2:  12
gate_12_locations = [
    [18,     5,     2.7,    0, -10, 0,     "circle"],
    [21,     4.5,   3.5,    -20, -20, 0,   "circle"],
    [24,     3.0,   4.5,    -25, -15, 0,   "rectangular"],
    [28,     1.5,   4.5,    -30, 0, 0,     "triangle"],
]

id = 14
for loc in gate_12_locations :
    id = id + 1
    if loc[6] == "circle" :
        obstacle_xml += generate_3D_circle_gate_xml(id,                     # id
                                                    loc[0], loc[1], loc[2], # position
                                                    loc[3], loc[4], loc[5], # orientation
                                                    102,                    # payload
                                                    4, 10, 0.1)              # size x, knots, thickness
    if loc[6] == "triangle" :
        obstacle_xml += generate_3D_triangle_gate_xml(id,                     # id
                                                      loc[0], loc[1], loc[2], # position
                                                      loc[3], loc[4], loc[5], # orientation
                                                      103,                    # payload
                                                      6, 0.1)              # size x, knots, thickness
    if loc[6] == "rectangular" :
        obstacle_xml += generate_3D_rectangular_gate_xml(id,                     # id
                                                      loc[0], loc[1], loc[2], # position
                                                      loc[3], loc[4], loc[5], # orientation
                                                      104,                    # payload
                                                      4, 4, 0.1)              # size x, knots, thickness

# station 2 :
gate_station_locations = [
    [32,     0,     4.0,    0, 0, 0],
]
loc = gate_station_locations[0]
obstacle_xml += generate_3D_circle_gate_xml(19,                     # id
                                            loc[0], loc[1], loc[2], # position
                                            loc[3], loc[4], loc[5], # orientation
                                            100,                    # payload
                                            6, 10, 0.1)              # size x, knots, thickness

# phase 2:  20
gate_20_locations = [
    [36,     0,     4.0,    0, 0, 45,     "circle"],
    [38,     0,     4.0,    0, 0, 90,     "circle"],
    [40,     0,     4.0,    0, 0, 45,     "circle"],
    [42,     0,     4.0,    0, 0, 0,     "circle"],
    [44,     0,     4.0,    0, 0, -45,     "circle"],
    [46,     0,     4.0,    0, 0, -90,     "circle"],
    [48,     0,     4.0,    0, 0, -40,     "circle"],
    [50,     0,     4.0,    0, 0, 0,     "circle"],
]

id = 19
for loc in gate_20_locations :
    id = id + 1
    obstacle_xml += generate_3D_circle_gate_xml(id,                     # id
                                                loc[0], loc[1], loc[2], # position
                                                loc[3], loc[4], loc[5], # orientation
                                                102,                    # payload
                                                6, 10, 0.1)              # size x, knots, thickness


parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="false"

    drone_label="1, 20"
    obstacle_label="100, 110"

    drone_default_start_height="3.0"
    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="true"

    driver_default_speed="0.5"
    driver_slowdown_zone="0.7"
    driver_stop_zone="0.15"
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
        ''' + parameters, False, False)],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
