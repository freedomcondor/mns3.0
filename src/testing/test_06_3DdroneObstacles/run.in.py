createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck
drone_locations = generate_random_locations(8,                  # total number
                                            0, 0,             # origin location
                                            -1, 1,              # random x range
                                            -1, 1,              # random y range
                                            0.5, 1.5)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags

gate_locations = [
    [3,         0,         2.5,    0, 0, 0],
    [6,         0,         2.5,    0, 0, 0],
    [9.095,     1.0,       2.5,    30, 0, 0],
    [11.31,     3.615,     2.5,    60, 0, 0],
    [12.2,      6.2,       2.5,    90, 0, 0],
    [12.2,      9,         2.5,    90, 10, 0],
    [12.2,      12,        2.5,    90, 20, 0],
    [12.2,      15,        2.5,    90, 30, 0],
    [12.2,      18,        3.0,    90, 30, 10],
    [12.2,      21,        4.0,    90, 20, 20],
    [11.2,      23,        5.0,    120, 10, 20],
    [9.2,       24,        6.0,    150, 10, 20],
    [6.7,       24,        7.0,    180, 20, 10],
    [3.7,       24,        8.0,    180, 20, 0],
]

#obstacle_xml = ""
obstacle_xml = generate_3D_triangle_gate_xml(1,
                                             -5,0,3,                  # position
                                             0,0,0,                  # orientation
                                             100,                    # payload
                                             5, 0.1)                 # size x, thickness

obstacle_xml += generate_3D_circle_gate_xml(1,
                                            -7,0,3,                  # position
                                            0,0,0,                  # orientation
                                            100,                    # payload
                                            5, 10, 0.1)                 # size x, knots, thickness

id = 0
for loc in gate_locations :
    id = id + 1
    obstacle_xml += generate_3D_rectangular_gate_xml(id,                     # id
                                                     loc[0], loc[1], loc[2], # position
                                                     loc[3], loc[4], loc[5], # orientation
                                                     100,                    # payload
                                                     3, 4, 0.1)              # size x, y, thickness

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="false"

    drone_label="1, 8"
    obstacle_label="100, 150"

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
        ''' + parameters, {"show_tag_rays":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
