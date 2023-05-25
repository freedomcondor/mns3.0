createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck

# abuse experiment length for drone numbers
if Experiment_length == None :
    Experiment_length = 27
n_drone = Experiment_length
Experiment_length = n_drone * 100

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

L = 1.5

half_side_length = (n_side-1) * L * 0.5
half_side_length_split_ranger = (n_side_split_ranger-1) * L * 0.5
half_side_length_split_main = (n_side_split_main-1) * L * 0.5

arena_size = half_side_length_split_main * 6 + half_side_length * 6
arena_z_center = half_side_length * 2 - 2

offset = -half_side_length * 4
drone_locations = generate_random_locations(n_drone,
                                            offset -half_side_length,   -half_side_length,               # origin location
                                            offset -half_side_length*1.2, offset+half_side_length*1.2,       # random x range
                                            -half_side_length*1.2, half_side_length*1.2,                     # random y range
                                            0.5, 1.5,           # near limit and far limit
                                            10000)              # attempt count

drone_xml = generate_drones(drone_locations, 1, 4.2)                  # from label 1 generate drone xml tags, communication range 4.2

obstacle_xml = ""

obstacle_xml += generate_3D_triangle_gate_xml(1,                    # id
                                              0, 0, half_side_length+1, # position
                                              0, 0, 0,              # orientation
                                              1001,                 # payload
                                              half_side_length_split_main*3, 0.2)       # size x, size y, thickness

size_y = half_side_length_split_ranger*3 
if n_side_split_ranger == 2:
    size_y = size_y * 2
obstacle_xml += generate_3D_rectangular_gate_xml(2,                    # id
                                                 0,
                                                 half_side_length_split_main*1.5 + half_side_length_split_ranger*1.5,
                                                 half_side_length + 1, # position
                                                 0, 0, 0,              # orientation
                                                 1002,                 # payload
                                                 half_side_length_split_ranger*3, size_y, 0.2)       # size x, size y, thickness

'''
obstacle_xml += generate_3D_rectangular_gate_xml(3,                    # id
                                                 half_side_length_split_main * 2.5,
                                                 0,
                                                 half_side_length+1, # position
                                                 0, 0, 0,              # orientation
                                                 1003,                 # payload
                                                 half_side_length*3, half_side_length*3, 0.2)       # size x, size y, thickness
'''



parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="true"

    drone_label="1, 1000"
    obstacle_label="1001, 1050"

    drone_default_start_height="3.0"
    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="true"

    driver_default_speed="0.5"
    driver_slowdown_zone="0.7"
    driver_stop_zone="0.15"
    driver_arrive_zone="0.7"

    n_drone="{}"

    drone_velocity_mode="true"
'''.format(n_drone)

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
        ''' + parameters, {"velocity_mode":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
