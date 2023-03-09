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

obstacle_xml = generate_3D_rectangular_gate_xml(0, 0, 3,           # position
                                                10, 10, 10,        # orientation
                                                100,                 # payload
                                                1, 2, 0.1)       # size x, y, thickness

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="false"

    drone_label="1, 8"
    obstacle_label="100, 150"

    drone_default_start_height="2.0"
    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="true"
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
        ''' + parameters, True)],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
