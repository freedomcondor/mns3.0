createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck

n_drone = 100

# calculate side
n_side = n_drone ** (1.0/3)

L = 5

half_side_length = (n_side-1) * L * 0.5

arena_size = half_side_length * 30
arena_z_center = arena_size / 2 - 2

offset = 0
yoffset = 0
y_scale = 1.2
drone_locations = generate_random_locations(n_drone,
                                            offset -half_side_length,     yoffset,          # origin location
                                            offset -half_side_length*1.2, offset+half_side_length*1.2,       # random x range
                                            yoffset-half_side_length*1.2, yoffset+half_side_length*1.2,      # random y range
                                            1.5, 3,             # near limit and far limit
                                            10000)              # attempt count

reinforce_offset = [60, -25]
dis = 2
reinforce_drone_locations = []
for i in range(0, 5) :
    for j in range(0, 6) :
        reinforce_drone_locations.append([reinforce_offset[0] + i * dis, reinforce_offset[1] + j * dis, 0])
'''
reinforce_drone_locations = generate_random_locations(30,
                                            reinforce_offset + offset -half_side_length,     yoffset,          # origin location
                                            reinforce_offset + offset -half_side_length*1.2, reinforce_offset + offset+half_side_length*1.2,       # random x range
                                            yoffset-half_side_length*1.2, yoffset+half_side_length*1.2,      # random y range
                                            1.5, 3,             # near limit and far limit
                                            10000)              # attempt count
'''

drone_xml = generate_drones(drone_locations, 1, 12)                  # from label 1 generate drone xml tags, communication range 4.2

drone_xml += generate_drones(reinforce_drone_locations, 101, 12)                  # from label 1 generate drone xml tags, communication range 4.2

parameters = generate3DdroneParameters()
parameters['driver_default_speed'] = 0.5
parameters['driver_slowdown_zone'] = 5.0
parameters['driver_stop_zone'] = 0.3
parameters['driver_arrive_zone'] = 3.0
parameters['dangerzone_drone'] = 3.0
parameters['dangerzone_aerial_obstacle'] = 3.0
parameters['drone_flight_preparation_state_duration'] = 30

parameters['n_drone'] = n_drone
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
        ''' + parameters_txt, {"velocity_mode":True})],
#       ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "50,50,50,0")],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
