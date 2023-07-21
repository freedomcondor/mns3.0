createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck

# abuse experiment length for drone numbers
if Experiment_length == None :
    Experiment_length = 16
n_drone = Experiment_length
Experiment_length = n_drone * 200

# calculate side
n_side = n_drone ** (1.0/3)

L = 1.5

half_side_length = (n_side-1) * L * 0.5
if half_side_length == 0 :
    half_side_length = 1

arena_size = half_side_length * 30
arena_z_center = arena_size / 2 - 2

offset = 0
yoffset = 0
y_scale = 1.2
if n_drone == 512 :
    y_scale = 1.7
drone_locations = generate_random_locations(n_drone,
                                            offset -half_side_length,     yoffset-half_side_length,               # origin location
                                            offset -half_side_length*1.2, offset+half_side_length*1.2,       # random x range
                                            yoffset-half_side_length*y_scale, yoffset + half_side_length*y_scale,                     # random y range
                                            0.5, 1.5,           # near limit and far limit
                                            10000)              # attempt count

drone_xml = generate_drones(drone_locations, 1, 4.2)                  # from label 1 generate drone xml tags, communication range 4.2

obstacle_xml = ""

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="true"

    drone_label="1, 1000"

    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="false"

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
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
