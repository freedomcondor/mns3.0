createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
customizeOpts = "t:"
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

Experiment_type = None
for opt, value in optlist:
    if opt == "-t":
        Experiment_type = value
        print("Experiment_type provided: ", Experiment_type)
if Experiment_type == None :
    Experiment_type = "polyhedron_12"
    print("Experiment_type not provided: using default", Experiment_type)

import os

# drone and pipuck

n_drone_index = {
    "polyhedron_12" :    12,
    "polyhedron_20" :    20,
    "cube_27"       :    27,
    "cube_64"       :    64,
    "cube_125"      :   125,
    "screen_64"     :    64,
    "donut_64"      :    64,
}

structure = Experiment_type
if structure not in n_drone_index :
    print("wrong experiment type provided, please choose among : ")
    for key in n_drone_index :
        print("    " + key)
    exit()

n_drone = n_drone_index[structure]

# calculate side
n_side = n_drone ** (1.0/3)
L = 1.5

half_side_length = (n_side-1) * L * 0.5

arena_size = half_side_length * 30
arena_z_center = arena_size / 2 - 2

offset = 0
yoffset = 0
y_scale = 1.2
if n_drone == 512 :
    y_scale = 1.7
drone_locations = generate_random_locations(n_drone,
                                            offset -half_side_length,         yoffset -half_side_length,          # origin location
                                            offset -half_side_length*1.2,     offset  +half_side_length*1.2,      # random x range
                                            yoffset-half_side_length*y_scale, yoffset + half_side_length*y_scale, # random y range
                                            0.5, 1.5,           # near limit and far limit
                                            10000)              # attempt count

drone_xml = generate_drones(drone_locations, 1, 4.2)                  # from label 1 generate drone xml tags, communication range 4.2

parameters = '''
    mode_2D="false"
    drone_real_noise="false"
    drone_tilt_sensor="false"

    drone_label="1, 200"

    safezone_drone_drone="3"
    dangerzone_drone="1"

    second_report_sight="true"

    driver_default_speed="0.5"
    driver_slowdown_zone="0.7"
    driver_stop_zone="0.15"
    driver_arrive_zone="0.5"

    structure={}
    drone_velocity_mode="true"
'''.format(structure)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/simu_code/vns_template.argos", 
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["DRONES",            drone_xml], 
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu_code/drone.lua"
        ''' + parameters, {"velocity_mode":True})],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False)],
    ]
)

os.system("echo " + structure + "> type.txt")
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)

