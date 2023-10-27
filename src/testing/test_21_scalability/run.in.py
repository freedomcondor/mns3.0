createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

n_drone = Experiment_length                # abuse experiment length for total number
half_side_length = n_drone ** (1/3) / 2 * 5

arena_size = half_side_length * 30
arena_z_center = arena_size / 2 - 2

# drone and pipuck
drone_locations = generate_random_locations(n_drone,
                                            -half_side_length, -half_side_length,               # origin location
                                            -half_side_length-1, half_side_length+1,            # random x range
                                            -half_side_length-1, half_side_length+1,            # random y range
                                            1.5, 3,           # near limit and far limit
                                            10000)              # attempt count

drone_xml =  generate_drones(drone_locations, 1, 12)                 # from label 1 generate drone xml tags

parameters = generate3DdroneParameters()
parameters["n_drone"] = n_drone

parameters_txt = generateParametersText(parameters)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
#        ["TOTALLENGTH",       str(501/5)],
        ["TOTALLENGTH",       str(0)],
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["DRONES",            drone_xml], 
        #["OBSTACLES",         obstacle_xml], 
        ["ARENA_SIZE",        str(arena_size)],
        ["ARENA_Z_CENTER",    str(arena_z_center)],
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters_txt, {"ideal_mode":False, "velocity_mode":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

#os.system("timeout 3600 argos3 -c vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
