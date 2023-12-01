createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

n_drone = Experiment_length
Experiment_length = None

# calculate side
n_side = n_drone ** (1.0/3)
L = 5

half_side_length = (n_side-1) * L * 0.5 * 2

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
                                            #offset -half_side_length*x_scale, yoffset -half_side_length*y_scale,          # origin location
                                            0, 0,          # origin location
                                            offset -half_side_length*x_scale, offset  +half_side_length*x_scale,      # random x range
                                            yoffset-half_side_length*y_scale, yoffset + half_side_length*y_scale, # random y range
                                            near_limit, far_limit,           # near limit and far limit
                                            10000)              # attempt count

drone_xml =  generate_drones(drone_locations, 1, 12)                 # from label 1 generate drone xml tags

parameters = generate3DdroneParameters()
parameters_txt = generateParametersText(parameters)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["ARENA_SIZE",        str(arena_size)],
        ["ARENA_Z_CENTER",    str(arena_z_center)],
        ["DRONES",            drone_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt, {"ideal_mode":False, "velocity_mode":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "white")],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
