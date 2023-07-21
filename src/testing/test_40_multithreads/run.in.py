createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck

#structure_config = ["morphology_2",      2]
#structure_config = ["morphology_4",      4]
#structure_config = ["morphology_8",      8]
#structure_config = ["morphology_12",     12]
#structure_config = ["morphology_12_rec", 12]
#structure_config = ["morphology_12_tri", 12]
structure_config = ["morphology_20",     20]

structure = structure_config[0]
n = structure_config[1]

drone_locations = generate_random_locations(n,                  # total number
                                            0, 0,               # origin location
                                            -1.5, 1.5,          # random x range
                                            -1.5, 1.5,          # random y range
                                            0.5, 1.5)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1, 3)              # from label 1 generate drone xml tags, with wifi range 3m

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="false"

    drone_label="1, 20"
    obstacle_label="100, 100"

    drone_default_start_height="3.0"
    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="true"

    driver_default_speed="0.5"
    driver_slowdown_zone="0.7"
    driver_stop_zone="0.15"

    structure={}
'''.format(structure)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["DRONES",            drone_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters)],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", True)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
