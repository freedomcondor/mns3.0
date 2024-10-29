import os
import string
import re

usage="[usage for replay] example: python3 replay.py -i logs -d -g\n -d to draw debug arrows\n -g to draw virtual frame and goal"
print(usage)

if 'customizeOpts' not in locals():
    customizeOpts = ""
customizeOpts = "i:gdtk:e:" + customizeOpts
createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

#----------------------------------------------------------------------------------------------
# parse customize opts
InputFolder = None
DrawGoalFlag = None
DrawDebugArrowsFlag = None
DrawTrackFlag = None
DrawTrackKeyFrame = None
DrawTrackEveryXStep = None
for opt, value in optlist:
    if opt == "-i":
        InputFolder = value
        print("Inputseed provided:", InputFolder)
    elif opt == "-g":
        DrawGoalFlag = True
        print("DrawGoalFlag provided:", DrawGoalFlag)
    elif opt == "-d":
        DrawDebugArrowsFlag = True
        print("DrawDebugArrowsFlag provided:", DrawDebugArrowsFlag)
    elif opt == "-t":
        DrawTrackFlag = True
        print("DrawTrackFlag provided:", DrawTrackFlag)
    elif opt == "-k":
        DrawTrackKeyFrame = value
        print("DrawTrackKeyFrame provided:", DrawTrackKeyFrame)
    elif opt == "-e":
        DrawTrackEveryXStep = value
        print("DrawTrackEveryXStep provided:", DrawTrackEveryXStep)
    elif opt == "-h":
        print(usage)
        exit()

if InputFolder == None :
    InputFolder = "./logs"
    print("InputFolder not provided, using:", InputFolder)

if DrawGoalFlag == None :
    DrawGoalFlag = False
    print("DrawGoalFlag not provided, do not draw by default, use -g to enable.")

if DrawDebugArrowsFlag == None :
    DrawDebugArrowsFlag = False
    print("DrawDebugArrowsFlag not provided, do not draw by default, use -d to enable.")

if DrawTrackFlag == None :
    DrawTrackFlag = False
    print("DrawTrackFlag not provided, do not draw by default, use -t to enable.")

if DrawTrackEveryXStep == None :
    DrawTrackEveryXStep = 1
    print("DrawTrackEveryXStep not provided, draw every step by default, use -e to specify.")

#----------------------------------------------------------------------------------------------
# read InputFolder and extract .log
def findRobotLogs(path, robotType) :
    robotNames = []
    robotTypes = []
    for folder in os.walk(path) :
        if folder[0] == path :
            for file in folder[2] :
                name = file.split(".",2)[0]
                ext  = file.split(".",2)[1]
                if ext != "log" :
                    continue
                name_head = name.rstrip(string.digits)
                if robotType == "ALL" :
                    if name_head == "drone" or name_head == "pipuck" or name_head == "obstacle" or name_head == "target":
                        robotNames.append(name)
                else :
                    if name_head == robotType :
                        robotNames.append(name)

    return robotNames

robotNames = findRobotLogs(InputFolder, "drone")
drone_xml = ""
for robotName in robotNames:
    id = re.findall(r'\d+', robotName)[0]
    drone_xml += generate_drone_xml(id, 0, 0, 0, 0)

robotNames = findRobotLogs(InputFolder, "pipuck")
pipuck_xml = ""
for robotName in robotNames:
    id = re.findall(r'\d+', robotName)[0]
    pipuck_xml += generate_pipuck_xml(id, 0, 0, 0)

#----------------------------------------------------------------------------------------------
# write input folder to file so that replay_loop_functions can read it
InputFolderNameFile = open("replay_input_folder.txt", "w")
InputFolderNameFile.write(InputFolder + "\n")
InputFolderNameFile.write(str(DrawGoalFlag) + "\n")
InputFolderNameFile.write(str(DrawDebugArrowsFlag) + "\n")
InputFolderNameFile.write(str(DrawTrackFlag) + "\n")
InputFolderNameFile.write(str(DrawTrackKeyFrame) + "\n")
InputFolderNameFile.write(str(DrawTrackEveryXStep) + "\n")
InputFolderNameFile.close()


#----------------------------------------------------------------------------------------------
# arena size
arena_size_xml="200,200,200"
arena_center_xml="0,0,95"

'''
#----------------------------------------------------------------------------------------------
# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/replayer_template.argos",
                    "replay.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["DRONES",            drone_xml],
        ["PIPUCKS",           pipuck_xml],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, True)],
        ["ARENA_SIZE",        arena_size_xml],
        ["ARENA_CENTER",      arena_center_xml],
    ]
)

os.system("argos3 -c replay.argos")
'''