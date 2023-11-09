replayerFile = "@CMAKE_BINARY_DIR@/scripts/libreplayer/replayer.py"
#execfile(createArgosFileName)
exec(compile(open(replayerFile, "rb").read(), replayerFile, 'exec'))

# read from 
typeFileAppend = "../type.txt"
if InputFolder[:-1] == "/" :
    typeFile = InputFolder + typeFileAppend
else :
    typeFile = InputFolder + "/" + typeFileAppend

with open(typeFile) as f:
    Experiment_type = f.readline().strip('\n')
print(Experiment_type)

# obstacles
scale = 5/1.5

# phase 1 : rec 8
gate_locations = [
#    x    y    z     rz  ry  rx  s1  s2     thick  payload  type
    [5,   0,   3.5,   0,  0,  0,  6, 10,    0.1,  100,  "circle"],
    [10,  0,   3.5,   0,  0,  0,  6, 10,    0.1,  100,  "circle"],

    [15,  3,   3.5,  20,  0,  0,  5,  5,    0.1,  101,  "rectangular"],
    [20,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"],

    [25,  4,   3.5,   0,  0,  0,  6,  None, 0.1,  102,  "triangle"],
    [30,  4,   3.5,   0,  0,  0,  5,  10,   0.1,  103,  "circle"],
    #[25,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"],
    #[30,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"],

    [35,  3,   3.5, -20,  0,  0,  5,  10,   0.1,  103,  "circle"],

    [15, -3,   3.5, -30,  0,  0,  3,  5,    0.1,  104,  "rectangular"],
    [18, -4,   3.5, -15,  0,  0,  3,  5,    0.1,  104,  "rectangular"],
    [21, -4.2, 3.5,   0,  0,  6,  3,  5,    0.1,  104,  "rectangular"],
    [24, -4.2, 3.5,   0,  0, 12,  3,  5,    0.1,  104,  "rectangular"],
    [27, -4.2, 3.5,   0,  0, 18,  3,  5,    0.1,  104,  "rectangular"],
    [30, -4.2, 3.5,   0,  0, 24,  3,  5,    0.1,  104,  "rectangular"],
    [33, -4,   3.5,  15, 10, 30,  3,  5,    0.1,  104,  "rectangular"],
    [36, -3,   3.5,  30, 10, 30,  3,  5,    0.1,  104,  "rectangular"],

    [41,  0,   3.5,   0,  0,  0,  6, 10,    0.1,  100,  "circle"],
]

if Experiment_type == "left" :
    os.system("echo left > type.txt")
    gate_locations[4] = [25,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"]
    gate_locations[5] = [30,  4,   3.5,   0,  0,  0,  5,  5,    0.1,  101,  "rectangular"]
else :
    os.system("echo right > type.txt")

id = 0
obstacle_xml = ""
for loc in gate_locations :
    id = id + 1
    if loc[10] == "circle" :
        obstacle_xml += generate_3D_circle_gate_xml(id,                     # id
                                                    loc[0]*scale, loc[1]*scale, loc[2]*scale, # position
                                                    loc[3], loc[4], loc[5], # orientation
                                                    loc[9],                 # payload
                                                    loc[6]*scale, loc[7], loc[8]*scale) # size x, knots, thickness
    if loc[10] == "triangle" :
        obstacle_xml += generate_3D_triangle_gate_xml(id,                     # id
                                                      loc[0]*scale, loc[1]*scale, loc[2]*scale, # position
                                                      loc[3], loc[4], loc[5], # orientation
                                                      loc[9],                 # payload
                                                      loc[6]*scale, loc[8]*scale)   # size x, thick ness
    if loc[10] == "rectangular" :
        obstacle_xml += generate_3D_rectangular_gate_xml(id,                     # id
                                                      loc[0]*scale, loc[1]*scale, loc[2]*scale, # position
                                                      loc[3], loc[4], loc[5], # orientation
                                                      loc[9],                 # payload
                                                      loc[6]*scale, loc[7]*scale, loc[8]*scale) # size x, size y, thickness


arena_size_xml = "{}, {}, {}".format(500, 100, 100)
arena_center_xml = "{},{},{}".format(200, 0, 25)

#----------------------------------------------------------------------------------------------
# generate argos file
generate_argos_file("@CMAKE_BINARY_DIR@/scripts/libreplayer/replayer_template.argos", 
                    "replay.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["OBSTACLES",         obstacle_xml],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "white", True)],
        ["ARENA_SIZE",        arena_size_xml], 
        ["ARENA_CENTER",      arena_center_xml], 
    ]
)

os.system("argos3 -c replay.argos")