replayerFile = "@CMAKE_BINARY_DIR@/scripts/libreplayer/replayer.py"
#execfile(createArgosFileName)
customizeOpts = "q:c:"
exec(compile(open(replayerFile, "rb").read(), replayerFile, 'exec'))

# check -r option for headless record for argos track plot
argos_track_record_frame_rate = None
camera_point = None
for opt, value in optlist:
    if opt == "-q":
        argos_track_record_frame_rate = value
        print("ARGoS Track Record Frame provided: ", argos_track_record_frame_rate)
    elif opt == "-c":
        camera_point = value
        print("Camera point provided: ", camera_point)
if argos_track_record_frame_rate == None :
    argos_track_record_frame_rate = 0
    print("ARGoS Track Record flag not provided, default 0, use -q to specify a number")
if camera_point == None :
    camera_point = '''position="-31.8851,-39.3,48.4403"look_at="13.8916,20.4892,-2.69511"'''
    print("ARGoS Track Record flag not provided, default 0, use -q to specify a number")

# read from 
typeFileAppend = "../type.txt"
if InputFolder[:-1] == "/" :
    typeFile = InputFolder + typeFileAppend
else :
    typeFile = InputFolder + "/" + typeFileAppend

with open(typeFile) as f:
    Experiment_type = f.readline().strip('\n')
print(Experiment_type)

if Experiment_type == "left" :
    os.system("echo left > type.txt")
else :
    os.system("echo right > type.txt")

arena_size_xml = "{}, {}, {}".format(500, 500, 100)
arena_center_xml = "{},{},{}".format(0, 0, 25)

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
#        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "white", True)],
        ["ARENA_SIZE",        arena_size_xml], 
        ["ARENA_CENTER",      arena_center_xml], 

        ["LIBRARY_DIR",                  "@CMAKE_BINARY_DIR@"],
        ["HEADLESS_GRABBING_FLAG",       HEADLESS_GRABBING_FLAG],
        ["HEADLESS_FRAME_RATE",          str(HEADLESS_FRAME_RATE)],

        ["CAMERA_POINT",          str(camera_point)],
    ]
)

os.system("argos3 -c replay.argos")