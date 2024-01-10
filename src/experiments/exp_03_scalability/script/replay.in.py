replayerFile = "@CMAKE_BINARY_DIR@/scripts/libreplayer/replayer.py"
customizeOpts = "q:"
#execfile(createArgosFileName)
exec(compile(open(replayerFile, "rb").read(), replayerFile, 'exec'))

# check -r option for headless record for argos track plot
argos_track_record_frame_rate = None
for opt, value in optlist:
    if opt == "-q":
        argos_track_record_frame_rate = value
        print("ARGoS Track Record Frame provided: ", argos_track_record_frame_rate)
if argos_track_record_frame_rate == None :
    argos_track_record_frame_rate = 0
    print("ARGoS Track Record flag not provided, default 0, use -q to specify a number")

# read from inputfolder and check drone numbers
robotNames = findRobotLogs(InputFolder, "drone") 
n_drone = len(robotNames)
print("drone number: ", n_drone)

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

L = 5

half_side_length = (n_side-1) * L * 0.5
half_side_length_split_ranger = (n_side_split_ranger-1) * L * 0.5
half_side_length_split_main = (n_side_split_main-1) * L * 0.5

arena_size = half_side_length_split_main * 6 + half_side_length * 6
arena_z_center = half_side_length * 2 - 2

A = half_side_length_split_ranger * 2 * 1.75
B = half_side_length_split_ranger * 2 * 1.75
if n_side_split_ranger == 2:
    B = B * 2
C = half_side_length_split_main * 2 * 1.75

H = (A + C + 3) * 0.5 

obstacle_xml = ""

obstacle_xml += generate_3D_triangle_gate_xml(1,                    # id
                                              0, -H*0.5, H, # position
                                              0, 0, 0,              # orientation
                                              1001,                 # payload
                                              C, 0.2,          # size x, size y, thickness
                                              C+3, H*2)      

size_y = half_side_length_split_ranger*3 
obstacle_xml += generate_3D_rectangular_gate_xml(2,                    # id
                                                 0, H*0.5, H, # position
                                                 0, 0, 0,              # orientation
                                                 1002,                 # payload
                                                 A, B, 0.2,    # size x, size y, thickness
                                                 A+3, H*2)

arena_size_xml = "{}, {}, {}".format(arena_size, arena_size, arena_size)
arena_center_xml = "0,0,{}".format(arena_z_center)

#-- grabbing options ------------------------------------------------------
HEADLESS_GRABBING_FLAG = "false"
HEADLESS_FRAME_RATE = 0
if argos_track_record_frame_rate != 0 :
    HEADLESS_GRABBING_FLAG = "true"
    HEADLESS_FRAME_RATE = argos_track_record_frame_rate

#----------------------------------------------------------------------------------------------
# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/track_argos_template.argos",
                    "replay.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["OBSTACLES",         obstacle_xml],
#        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "white", True)],
        ["ARENA_SIZE",        arena_size_xml], 
        ["ARENA_CENTER",      arena_center_xml], 

        ["LIBRARY_DIR",                  "@CMAKE_BINARY_DIR@"],
        ["HEADLESS_GRABBING_FLAG",       HEADLESS_GRABBING_FLAG],
        ["HEADLESS_FRAME_RATE",          str(HEADLESS_FRAME_RATE)],
    ]
)

os.system("argos3 -c replay.argos")